cc.net = require("framework.cc.net.init")
cc.utils = require("framework.cc.utils.init")

require "protocol.dr2_login_pb"
require "protocol.dr2_comm_pb"
require "protocol.dr2_logic_pb"
require "pack"
--require "bit"
require "common.func"
require "common.const"
local i18n = require "res.i18n"
local eventName = require "net.eventName"
local protoParser = require "net.protoParser"
local protoGenerator = require "net.protoGenerator"
local ByteArray=require("framework.cc.utils.ByteArray")
local EventProtocol = require("framework.api.EventProtocol")
local TcpAgent = require("net.dhTcpAgent")

local NET_OK = 0
local NET_ERROR = 1

local NetClient = {}

local net_rid = 100

NetClient.__timer = {}

local _base_module_name = "dr2_comm_pb"
local modules = {}
modules[_base_module_name] = dr2_comm_pb
modules["dr2_login_pb"] = dr2_login_pb
modules["dr2_logic_pb"] = dr2_logic_pb

-- init
EventProtocol.extend(NetClient)

function NetClient:new( o )
	o = o or {}
	o = EventProtocol.extend(o)
	setmetatable(o, self)
	self.__index = self
	return o
end

function NetClient:inceRid()
    net_rid = net_rid + 1
    if net_rid > 10000 then
        net_rid = 100
    end
end

-- 网络问题对话框 开关
-- default disable popReconnectDialog
function NetClient:setDialogEnable(_enable)
    self._enable_dialog = _enable
end
NetClient:setDialogEnable(false)

function NetClient:setTimer(o)
    if not NetClient.__timer then
        NetClient.__timer = {}
    end
    NetClient.__timer[o] = os.time()
end

function NetClient:isTimeout(o)
    if os.time() - NetClient.__timer[o] > NET_TIMEOUT then
        print(o .. " is timeout.")
        return true
    else
        return false
    end
    return true
end

function NetClient:getInstance(  )
	if 1 then return NetClient end
    if self._instance == nil then
		self._instance = self:new()
	end
	return self._instance
end

function NetClient:isConnected()
    if not self._tcpAgent then
        return false
    end
    return self._tcpAgent:isConnected()
end

local function pack_proto_data(params) 
    local _ba = ByteArray.new(ByteArray.ENDIAN_BIG)
    _ba:setPos(1)
    local _proto_data = params.data
    local _proto_len = string.len(_proto_data)
    local _data_len = CONFIG_PROTOCOL_HEADER_EXCEPT_FIRST_LEN + _proto_len
    _ba:writeUShort(_data_len)          -- 2
    --_ba:writeUInt(params.id)            -- 4
    _ba:writeUByte(params.group)        -- 1
    _ba:writeUByte(params.cmd)          -- 1
    _ba:writeUShort(params.sid)         -- 2
    _ba:writeBuf(_proto_data)
    params = nil
    return _ba
end

local function get_proto_string(__data)
    local _ba = ByteArray.new(ByteArray.ENDIAN_BIG)
    _ba:setPos(1)
    local tmp_data = string.sub(__data, 1, CONFIG_PROTOCOL_HEADER_LEN_RECV)
    _ba:writeBuf(tmp_data)
    _ba:setPos(1)
    local rcv_len = _ba:readUShort()        -- 2
    local rcv_type = _ba:readUByte()        -- 1
    local rcv_cmd = _ba:readUByte()         -- 1
    local _proto_string = string.sub(__data, CONFIG_PROTOCOL_HEADER_LEN_RECV+1, -1)
    __data = nil
    _ba = nil
    return _proto_string, rcv_len, rcv_type, rcv_cmd 
end

local function removeEventByName(selfObj, event_name)
    if selfObj._tcpAgent then
        selfObj._tcpAgent:removeAllEventListenersForEvent(event_name)
    end
end

local function addEventListener(selfObj, event_name, _handler)
    if not selfObj._tcpAgent then return end
    return selfObj._tcpAgent:addEventListener(event_name, _handler)
end

function NetClient:newConnect(__data, callback)
    self.connect_callback = callback
    self._tcpAgent = TcpAgent:new()
    self._tcpAgent:removeAllEventListenersForEvent(TcpAgent.EVENT_CONNECTED)
    self._tcpAgent:removeAllEventListenersForEvent(cc.net.SocketTCP.EVENT_CLOSED)
    self._tcpAgent:removeAllEventListenersForEvent(TcpAgent.EVENT_ERROR)
    self._statusHandle = addEventListener(self, TcpAgent.EVENT_CONNECTED, handler(self, self.onStatus))
    self._closedHandle = addEventListener(self, cc.net.SocketTCP.EVENT_CLOSED, handler(self, self.onClosed))
    self._errorHandle = addEventListener(self, TcpAgent.EVENT_ERROR, handler(self, self.onError))
	if not self._tcpAgent:isConnected() then
		self._tcpAgent:connect(__data.host, __data.port)
	end
end

function NetClient:getRIp()
    if self._tcpAgent and self._tcpAgent.r_ip then
        return self._tcpAgent.r_ip
    end
    return " no ip"
end

function NetClient:Event(event_name, __data, callback)
    removeEventByName(self, event_name)
    if not self.handlers then
        self.handlers = {}
    end
    if not self.callbacks then
        self.callbacks = {}
    end
    if not self._tcpAgent then return end
    self.handlers[event_name] = self._tcpAgent:addEventListener(event_name, handler(self, __data.event_callback))
    if callback then
        self.callbacks[event_name] = callback
    else
        self.callbacks[event_name] = nil
    end
    if event_name == "EVENT_CMD_18_3" then   -- 支付协议的包体撑爆了协议头部2字节
        local t_proto_gen_method = protoGenerator["pay"]
        local _proto_data = t_proto_gen_method(__data)
        local limit_size = 1024*7
        local _proto_len = string.len(_proto_data)
        local pack_count = math.floor(((_proto_len +limit_size-1)/limit_size))
        for ii=1,pack_count do
            local params = {}
            local start_i = 1+(ii-1)*limit_size
            local end_i = ii*limit_size
            if end_i > _proto_len then
                end_i = _proto_len
            end
            local pay2_params = {
                data = tostring(string.sub(_proto_data, 1+(ii-1)*limit_size, ii*limit_size))
            }
            if ii < pack_count then
                pay2_params.left = 1
            else
                pay2_params.left = 0
            end
            local _proto_data2 = __data.proto_gen_method(pay2_params)
            local params = {}
            params.data = _proto_data2
            --params.id = __data.cid
            params.group = __data.group
            params.cmd = __data.cmd
            params.sid = __data.sid
            params.reserved = __data.reserved or 0
            local _ba = pack_proto_data(params)
            self:send(_ba)
            self:setTimer(event_name)
        end
    else
        local _proto_data = __data.proto_gen_method(__data)
        local params = {}
        params.data = _proto_data
        --params.id = __data.cid
        params.group = __data.group
        params.cmd = __data.cmd
        params.sid = __data.sid
        params.reserved = __data.reserved or 0
        local _ba = pack_proto_data(params)
        self:send(_ba)
        self:setTimer(event_name)
    end
end

function NetClient:RegEvent(event_name, event_callback, callback)
    removeEventByName(self, event_name)
    if not self.handlers then
        self.handlers = {}
    end
    if not self.callbacks then
        self.callbacks = {}
    end
    if not self._tcpAgent then return end
    self.handlers[event_name] = self._tcpAgent:addEventListener(event_name, handler(self, event_callback))
    if callback then
        self.callbacks[event_name] = callback
    else
        self.callbacks[event_name] = nil
    end
end

function NetClient:onEvent(event_name, __event, protoObj, parseMethod)
    if NetClient:isTimeout(event_name) then return end
    CCLuaLog("get " .. event_name .. " data. start to parse ...:") 
    local _proto_string = get_proto_string(__event.data)
    protoObj:ParseFromString(_proto_string)
    local __data = parseMethod(protoObj)
    if self.extra_callback then
        self.extra_callback({name=event_name, data=__event.data})
    end
    if self.callbacks[event_name] then
        self.callbacks[event_name](__data)
    end
end

function NetClient:onPushEvent(event_name, __event, protoObj, parseMethod)
    CCLuaLog("get " .. event_name .. " data. start to parse ...:") 
    local _proto_string = get_proto_string(__event.data)
    protoObj:ParseFromString(_proto_string)
    local __data = parseMethod(protoObj)
    if self.callbacks[event_name] then
        self.callbacks[event_name](__data)
    end
end

-- 为每个事件增加额外监听回调，可覆盖callback
--   callback({name=event.name, data=event.data})
function NetClient:regExtraListener(callback)
    self.extra_callback = callback
end

--[[
connect 注册回调事件, 并检查连接
__data = {host, port}
]]--
function NetClient:connect( __data, callback )
	self.connect_callback = callback
	if not self._tcpAgent then
        self._tcpAgent = TcpAgent:getInstance()
        self._tcpAgent:removeAllEventListenersForEvent(TcpAgent.EVENT_CONNECTED)
        self._tcpAgent:removeAllEventListenersForEvent(cc.net.SocketTCP.EVENT_CLOSED)
        self._tcpAgent:removeAllEventListenersForEvent(TcpAgent.EVENT_ERROR)
		self._statusHandle = addEventListener(self, TcpAgent.EVENT_CONNECTED, handler(self, self.onStatus))
        self._closedHandle = addEventListener(self, cc.net.SocketTCP.EVENT_CLOSED, handler(self, self.onClosed))
		self._errorHandle = addEventListener(self, TcpAgent.EVENT_ERROR, handler(self, self.onError))
	end
	if not self._tcpAgent:isConnected() then
		self._tcpAgent:connect(__data.host, __data.port)
	end
end

function NetClient:send( _ba )
    if not self._tcpAgent then
        print("_tcpAgent false.")
        return
    end
    if self._enable_dialog and not self:isConnected() then
        popReconnectDialog()
        return
    end
    self._tcpAgent:send(_ba:getPack())
    _ba = nil
    self:inceRid()
    return
end

function NetClient:close(callback)
    if callback then
        self.self_close_callback = callback
    else
        self.self_close_callback = nil
    end
    print("client close socket.")
    if self._tcpAgent then
        self.is_self_close = true
        self._tcpAgent:close()
        --self._tcpAgent = nil
    else
        if self.self_close_callback then
            self.self_close_callback()
        end
    end
end

function NetClient:onStatus( __event )
    print("socket status: " .. __event.name)
    print("onstatus eventname: " .. __event.name)
    if __event.name == TcpAgent.EVENT_CONNECTED then
        CCLuaLog("connected to server.")
        self.is_self_close = nil
        if not self._tcpAgent then return end
        self._tcpAgent:removeEventListener(TcpAgent.EVENT_CONNECTED, self._statusHandle)
        __data = {status=0}
        self.connect_callback(__data)
    end
end

-- app由后台切入时注册该事件，以对断网做处理
function NetClient:registForegroundListener(handler)
    self.foreground_listener = handler
end

function NetClient:unregistForegroundListener()
    if self.foreground_listener then
        self.foreground_listener = nil
    end
end

function NetClient:onClosed( __event )
	print("event name: " .. __event.name)
    self._tcpAgent = nil
    if self.foreground_listener and self._enable_dialog then
        self.foreground_listener()
        return
    end
    if self.is_newconn and (not self.is_self_close) then
        delWaitNet()
        showToast(i18n.global.error_account_passwd.string)
        self.is_newconn = nil
        return
    end
    if self._enable_dialog and not self.is_self_close then
        popReconnectDialog(i18n.global.error_server_close.string)
    else
        if self.self_close_callback then
            self.self_close_callback()
        end
    end
end

function NetClient:onError( __event )
	print("socket error: " .. __event.error)
	print("onError eventname: " .. __event.name)
end

-- init net commands
local cmds = eventName.cmds
local function generatorMethod(params)
    protoGenerator[params.cmd] = function(__data)
        __data.module_name = params.module_name
        __data.class_name = params.req_name
        return protoGenerator.genProtoData(__data)
    end
end
for _, params in ipairs(cmds) do
    generatorMethod(params)
    local event_callback_name = "on" .. params.cmd .. "Data"
    NetClient[params.cmd] = function(selfObj, __data, callback)
        __data.group = params.cmd_group
        __data.cmd = params.cmd_type
        __data.event_callback = selfObj[event_callback_name] 
        __data.proto_gen_method = protoGenerator[params.cmd]
        selfObj:Event(params.cmd_name, __data, callback)
    end
    NetClient[event_callback_name] = function(selfObj, __event)
        selfObj:onEvent(params.cmd_name, __event, modules[params.module_name][params.rsp_name](), protoParser.obj2Tbl)
    end
end

--[[
-- echo
-- __data = {cid, sid, [reverse]}
]]--
--function NetClient:echo( __data, callback )
--    __data.group = 0x01
--    __data.cmd = 0x01
--    __data.event_callback = self.onEchoData
--    __data.proto_gen_method = protoGenerator.genEchoData
--    self:Event(eventName.EVENT_CMD_1_1, __data, callback)
--end
--function NetClient:onEchoData( __event )
--    self:onEvent(eventName.EVENT_CMD_1_1, __event, dr2_login_pb.pbrsp_echo(), protoParser.parsePbrspEcho)
--end

--[[
-- heart_beat
-- __data = {cid, sid, [reverse]}
]]--
function NetClient:heart_beat( __data, callback )
    __data.group = 0x01
    __data.cmd = 0x01
    __data.event_callback = self.onHeart_beatData
    __data.proto_gen_method = protoGenerator.genEchoData
    self:Event(eventName.EVENT_CMD_1_1, __data, callback)
end
function NetClient:onHeart_beatData( __event )
    -- do nothing
    --self:onEvent(eventName.EVENT_CMD_1_1, __event, dr2_login_pb.pbrsp_echo(), protoParser.parsePbrspEcho)
end

--[[
-- reg
-- __data = {cid, sid}
]]--
--function NetClient:reg( __data, callback )
--    __data.group = 0x02
--    __data.cmd = 0x01
--    __data.event_callback = self.onRegData
--    __data.proto_gen_method = protoGenerator.genRegData
--    self:Event(eventName.EVENT_CMD_2_1, __data, callback)
--end
--function NetClient:onRegData( __event )
--    self:onEvent(eventName.EVENT_CMD_2_1, __event, dr2_login_pb.pbrsp_reg(), protoParser.parsePbrspReg)
--end

--[[
-- salt
-- __data = {cid, sid, account, [reverse]}
]]--
--function NetClient:salt( __data, callback )
--    __data.group = 0x02
--    __data.cmd = 0x02
--    __data.event_callback = self.onSaltData
--    __data.proto_gen_method = protoGenerator.genSaltData
--    self:Event(eventName.EVENT_CMD_2_2, __data, callback)
--end
--function NetClient:onSaltData( __event )
--    self:onEvent(eventName.EVENT_CMD_2_2, __event, dr2_login_pb.pbrsp_salt(), protoParser.parsePbrspSalt)
--end

--[[
-- login
-- __data = {cid, sid, checksum, [reverse]}
]]--
--function NetClient:login( __data, callback )
--    __data.group = 0x02
--    __data.cmd = 0x03
--    __data.event_callback = self.onLoginData
--    __data.proto_gen_method = protoGenerator.genLoginData
--    self:Event(eventName.EVENT_CMD_2_3, __data, callback)
--end
--function NetClient:onLoginData( __event )
--    self:onEvent(eventName.EVENT_CMD_2_3, __event, dr2_login_pb.pbrsp_login(), protoParser.parsePbrspLogin)
--end

--[[
-- auth
-- __data = {cid, sid, session, uid}
]]--
--function NetClient:auth( __data, callback )
--    __data.group = 0x03
--    __data.cmd = 0x01
--    __data.event_callback = self.onAuthData
--    __data.proto_gen_method = protoGenerator.genAuthData
--    self:Event(eventName.EVENT_CMD_3_1, __data, callback)
--end
--function NetClient:onAuthData( __event )
--    self:onEvent(eventName.EVENT_CMD_3_1, __event, dr2_logic_pb.pbrsp_auth(), protoParser.parsePbrspAuth)
--end

--[[
-- sync
-- __data = {cid, sid}
]]--
--function NetClient:sync( __data, callback )
--    __data.group = 0x03
--    __data.cmd = 0x02
--    __data.event_callback = self.onSyncData
--    __data.proto_gen_method = protoGenerator.genSyncData
--    self:Event(eventName.EVENT_CMD_3_2, __data, callback)
--end
--function NetClient:onSyncData( __event )
--    --self:onEvent(eventName.EVENT_CMD_3_2, __event, dr2_logic_pb.pbrsp_sync(), protoParser.parsePbrspSync)
--    self:onEvent(eventName.EVENT_CMD_3_2, __event, dr2_logic_pb.pbrsp_sync(), protoParser.obj2Tbl)
--end

--[[
-- gacha
-- __data = {cid, sid, type, free, [item=proto_item]}
]]--
--function NetClient:gacha( __data, callback )
--    __data.group = 0x04
--    __data.cmd = 0x01
--    __data.event_callback = self.onGachaData
--    __data.proto_gen_method = protoGenerator.genGachaData
--    self:Event(eventName.EVENT_CMD_4_1, __data, callback)
--end
--function NetClient:onGachaData( __event )
--    self:onEvent(eventName.EVENT_CMD_4_1, __event, dr2_logic_pb.pbrsp_gacha(), protoParser.parsePbrspGacha)
--end

function NetClient:onMailData( __event )
    self:onPushEvent(eventName.EVENT_CMD_5_0, __event, dr2_comm_pb.pb_mail(), protoParser.obj2Tbl)
end

function NetClient:registMailEvent(callback)
    self:RegEvent(eventName.EVENT_CMD_5_0, self.onMailData, callback)
end

function NetClient:onChatData( __event )
    self:onPushEvent(eventName.EVENT_CMD_7_0, __event, dr2_comm_pb.pb_chat(), protoParser.obj2Tbl)
end

function NetClient:registChatEvent(callback)
    self:RegEvent(eventName.EVENT_CMD_7_0, self.onChatData, callback)
end

function NetClient:onFriendsData( __event )
    self:onPushEvent(eventName.EVENT_CMD_10_4, __event, dr2_logic_pb.pbrsp_frd_notify(), protoParser.obj2Tbl)
end

function NetClient:onFriendsbossData( __event )
    self:onPushEvent(eventName.EVENT_CMD_23_6, __event, dr2_logic_pb.pbrsp_fboss_notify(), protoParser.obj2Tbl)
end

function NetClient:onFrdarenaData( __event )
    self:onPushEvent(eventName.EVENT_CMD_26_10, __event, dr2_logic_pb.pbrsp_gpvpteam_notify(), protoParser.obj2Tbl)
end

function NetClient:registFriendsEvent(callback)
    self:RegEvent(eventName.EVENT_CMD_10_4, self.onFriendsData, callback)
end

function NetClient:registFriendsbossEvent(callback)
    self:RegEvent(eventName.EVENT_CMD_23_6, self.onFriendsbossData, callback)
end

function NetClient:registFrdarenaEvent(callback)
    self:RegEvent(eventName.EVENT_CMD_26_10, self.onFrdarenaData, callback)
end

function NetClient:onGuildData( __event )
    self:onPushEvent(eventName.EVENT_CMD_13_0, __event, dr2_logic_pb.pbrsp_guild_notify(), protoParser.obj2Tbl)
end

function NetClient:registGuildEvent( callback )
    self:RegEvent(eventName.EVENT_CMD_13_0, self.onGuildData, callback)
end
--[[
-- op_mail
-- __data = {sid, reads=[int32], deletes=[int32], affix=int32}
]]--
--function NetClient:opMail( __data, callback )
--    __data.group = 0x05
--    __data.cmd = 0x01
--    __data.event_callback = self.onOpMailData
--    __data.proto_gen_method = protoGenerator.genOpMailData
--    self:Event(eventName.EVENT_CMD_5_1, __data, callback)
--end
--function NetClient:onOpMailData( __event )
--    self:onEvent(eventName.EVENT_CMD_5_1, __event, dr2_logic_pb.pbrsp_op_mail(), protoParser.parsePbrspOpMail)
--end


-------------------------------old below---------------------------
return NetClient
