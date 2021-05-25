--[[
TcpAgent说明:
1.TcpAgent 只允许使用单例， 请使用 TcpAgent:getInstance() 获取对象实例;
2.TcpAgent 请在脚本开始的时候 使用TcpAgent:connect( host, port )和服务器
  建立长连接，中途断线会自动重连；
3.如果需要关闭长连接， 使用 TcpAgent:close(  )；
4.如果需要重新建立其他服务器的连接，请先close再connect；
5.发送请求使用 TcpAgent:send( __data )
6.测试当前是否有连接 使用 TcpAgent:isConnected()
7.逻辑部分 注册的 回调事件，确定以后不使用时，应当及时取消；
8.其他为说明函数为内部使用函数，外部不要调用.
author: chockly@126.com 2014-5-26
]]--

cc.net = require("framework.cc.net.init")
cc.utils = require("framework.cc.utils.init")

require "pack"
--require "bit"
local ByteArray=require("framework.cc.utils.ByteArray")

local EventProtocol = require("framework.api.EventProtocol")

local scheduler = require("framework.scheduler")

local TcpAgent = {}
--[[
在这里添加 app 需要注册的回调事件名称, 命名规则为 EVENT_CMD_TYPE数值_CMD数值
这样命名的好处是 解析协议头部后, 可以根据头部type和cmd值, 直接构造事件名称 来分
发事件
]]--
TcpAgent.FIRST_FIELD_LEN = 2  --协议第一个字段字节长度
TcpAgent.MAX_TYPE_NUM = 100   --协议使用的最大type值
TcpAgent.MAX_CMD_NUM = 1000   --协议使用的最大cmd值
TcpAgent.NOT_CONNECTED = "NOT_CONNECTED"
TcpAgent.EVENT_CONNECTED = "EVENT_CONNECTED"
TcpAgent.EVENT_ERROR = "EVENT_ERROR"

TcpAgent.EVENT_CMD_2_1 = "EVENT_CMD_2_1"  -- proto_register 
TcpAgent.EVENT_CMD_2_2 = "EVENT_CMD_2_2"  -- proto_get_salt 
TcpAgent.EVENT_CMD_2_3 = "EVENT_CMD_2_3"  -- proto_login 
TcpAgent.EVENT_CMD_3_1 = "EVENT_CMD_3_1"  -- proto_auth
TcpAgent.EVENT_CMD_3_2 = "EVENT_CMD_3_2"  -- proto_comm
TcpAgent.EVENT_CMD_4_1 = "EVENT_CMD_4_1"  -- proto_hook
--[[
]]--

local _ba = ByteArray.new(ByteArray.ENDIAN_BIG)
local _auto_reconnect = false

--local function readHeader(obj)
--    local rcv_len = obj:readUShort()            -- 2
--    --local rcv_len = obj:readUInt()
--    local rcv_uid = obj:readUInt()              -- 4
--    local rcv_type = obj:readUByte()            -- 1
--    local rcv_cmd = obj:readUByte()             -- 1
--    local rcv_sid = obj:readUByte()            -- 1
--    local rcv_reserved = obj:readUByte()        -- 1
--    return rcv_len, rcv_uid, rcv_type, rcv_cmd, rcv_sid, rcv_reserved
--end

local function readHeader(obj)
    local rcv_len = obj:readUShort()            -- 2
    local rcv_type = obj:readUByte()            -- 1
    local rcv_cmd = obj:readUByte()             -- 1
    print("rcv_len:", rcv_len)
    print("rcv_type:", rcv_type)
    print("rcv_cmd:", rcv_cmd)
    return rcv_len, rcv_type, rcv_cmd
end

function TcpAgent:new( o )
	o = o or {}
	o = EventProtocol.extend(o)
	setmetatable(o, self)
	self.__index = self
	self._isConnected = false
	self._last_isCompleted = true
	self._last_pos = 0
	self._last_need_len = 0
    self._last_data = nil
    self.__data = {} 
	return o
end

function TcpAgent:getInstance(  )
	if self._instance == nil then
		self._instance = self:new()
	end
	return self._instance
end

function TcpAgent:isConnected(  )
	return self._isConnected
end

function TcpAgent:setAutoReconnect( value )
    if type(value) == type(true) then
        _auto_reconnect = value
    end
end

local function isIPv6Now(host)
    if device.platform == "ios" then
        local socket = require "socket"
        local addrinfo, err = socket.dns.getaddrinfo(host)
        print("isIPv6Now  error:", err)
        if addrinfo and addrinfo[1] and addrinfo[1].family == "inet6" then
            return true
        end
    end
    return false
end

local function getaddrinfo(host, callback)
    if device.platform == "ios" then
        print("------------ios")
        dhutil:getHostIpAddress(callback, host)
    else
        return callback({[1]={status=0, ip=host, ipType=0}})
    end
end

function TcpAgent:connect( host, port )
	if host then 
		self._host = host 
		print("self host:" .. self._host)
	end
	if port and type(port)=="number" then
	 	self._port = port 
	 	print("self port:" .. self._port)
	 end
	print("host:" .. (self._host or "") .. " port:" .. (self._port or 0))

    if not self._socket then
		self._socket = cc.net.SocketTCP.new(self._host, self._port, _auto_reconnect)
		self._socket:addEventListener(cc.net.SocketTCP.EVENT_CONNECTED, handler(self, self.onConnected))
		self._socket:addEventListener(cc.net.SocketTCP.EVENT_CLOSE, handler(self, self.onClose))
		self._socket:addEventListener(cc.net.SocketTCP.EVENT_CLOSED, handler(self, self.onClosed))
		self._socket:addEventListener(cc.net.SocketTCP.EVENT_CONNECT_FAILURE, handler(self, self.onConnectFailure))
		self._socket:addEventListener(cc.net.SocketTCP.EVENT_DATA, handler(self, self.onData))
	end
    print("to get addr_info --------")
    --local tipv6 = isIPv6Now(host)
    local function tryGetAddrInfo()
        if self.tryScheduler then
            scheduler.unscheduleGlobal(self.tryScheduler)
            self.tryScheduler = nil
        end
        getaddrinfo(host, function(addr_info)
            print("get addr_info below:")
            tbl2string(addr_info)
            local addr_ip = host
            local ipv6 = false
            if addr_info and #addr_info > 0 then
                for ii=1,#addr_info do
                    if addr_info[ii].status ~= 0 then  -- 所有status值都一样，只要不为0，说明dns解析错误
                        if addr_info[ii].status and host then
                            reportException("DNS Error", "dns status:" .. addr_info[ii].status .. " host:" .. host)
                        end
                        print("DNS error. host:", host)
                        self.tryScheduler = scheduler.scheduleGlobal(tryGetAddrInfo, 0.5)
                        return
                    elseif addr_info[ii].ipType == 1 then  -- 找到第一个推荐ipv6
                        addr_ip = addr_info[ii].ip
                        ipv6 = true
                        --reportException("DNS Find ipv6", "host:" .. host .. " ip:" .. addr_ip)
                        print("DNS find ipv6. ip:", addr_ip)
                        self._socket:connect(addr_ip, self._port, _auto_reconnect, ipv6)
                        self.r_ip = addr_ip
                        break
                    else
                        --reportException("DNS ipType 0", "dns: status 0, ipType 0 ip " .. addr_info[ii].ip)
                    end
                end
                -- 没有找到ipv6，尝试ipv4
                if not ipv6 then
                    --reportException("DNS not Find ipv6", "no ipv6 response, try ipv4")
                    for ii=1,#addr_info do
                        if addr_info[ii].ipType == 0 then
                            addr_ip = addr_info[ii].ip
                            ipv6 = false
                            --reportException("try ipv4", "host:" .. host .. " ip:" .. addr_ip)
                            self._socket:connect(addr_ip, self._port, _auto_reconnect, ipv6)
                            self.r_ip = addr_ip
                            break
                        end
                    end
                end
            else
                --reportException("DNS Error", "dns nil")
                self.tryScheduler = scheduler.scheduleGlobal(tryGetAddrInfo, 0.5)
                return
            end
        end)
    end
    tryGetAddrInfo()
end

function TcpAgent:onConnected( __event )
	print("connected to " .. self._host .. " " .. self._port)
	self._isConnected = true
	self:dispatchEvent({name=TcpAgent.EVENT_CONNECTED, error=0})
end

function TcpAgent:onClose( __event )
	--print("socket close.")
end

function TcpAgent:onClosed( __event )
	print("socket closed.")
	self._isConnected = false
	self:dispatchEvent({name=cc.net.SocketTCP.EVENT_CLOSED, error=-1})
	--self._socket = nil
end

function TcpAgent:onConnectFailure( __event )
	--print("socket connect failed. retry ...")
    --self:connect(self._host, self._port, _auto_reconnect)
end

function TcpAgent:onData( __event )
	print("TcpAgent got data, len:", string.len(__event.data))
	self:parseHeader(__event.data)
end

function TcpAgent:parseHeader( __data )
	local data_len = string.len(__data)
    print("start to parse header ... data len:" .. data_len)
	local toPos = 1
    local rcv_len, rcv_type, rcv_cmd
	-- if last data not completed
	if not self._last_isCompleted then
		toPos = self._last_pos + 1
		if data_len == self._last_need_len then
			_ba:setPos(toPos)
			--_ba:writeBuf(__data)
			_ba:setPos(1)
			--rcv_len = _ba:readUShort()
			--rcv_uid = _ba:readUInt()
			--rcv_type = _ba:readUByte()
			--rcv_cmd = _ba:readUByte()
			--rcv_irid = _ba:readUShort()
			rcv_len, rcv_type, rcv_cmd = readHeader(_ba)
			if not self:isValideHeader(rcv_type, rcv_cmd) then return end
			event_name = "EVENT_CMD_" .. rcv_type .. "_" .. rcv_cmd
			--self:dispatchEvent({name=TcpAgent.EVENT_CMD_2_1, data=__data, error=0})
			self.__data[#self.__data+1] = __data
            local _dispatch_data = nil
            if #self.__data > 0 then
                _dispatch_data = table.concat(self.__data)
            end
			self._last_isCompleted = true
			self._last_pos = 0
			self._last_need_len = 0
            self.__data = {}
            self:dispatchEvent({name=event_name, data=_dispatch_data, error=0})
			return
		elseif data_len < self._last_need_len then
			_ba:setPos(toPos)
			--_ba:writeBuf(__data)
			self._last_pos = toPos + data_len - 1
			self._last_need_len = self._last_need_len - data_len
			self._last_isCompleted = false
            self.__data[#self.__data+1] = __data
            return
		elseif data_len > self._last_need_len then
			--local tmp_data = string.sub(__data, 1, data_len)
			_ba:setPos(toPos)
			--_ba:writeBuf(tmp_data)
			_ba:setPos(1)
			rcv_len, rcv_type, rcv_cmd = readHeader(_ba)
			if not self:isValideHeader(rcv_type, rcv_cmd) then return end
			event_name = "EVENT_CMD_" .. rcv_type .. "_" .. rcv_cmd
			--self:dispatchEvent({name=TcpAgent.EVENT_CMD_2_1, data=__data, error=0})
			self.__data[#self.__data+1] = string.sub(__data, 1, self._last_need_len)
            local _dispatch_data = nil
            if #self.__data > 0 then
                _dispatch_data = table.concat(self.__data)
            end
			local remain_data = string.sub(__data, self._last_need_len+1, -1)
			self._last_isCompleted = true
			self._last_pos = 0
			self._last_need_len = 0
            self.__data = {}
            self:dispatchEvent({name=event_name, data=_dispatch_data, error=0})
			-- process remain data
			return self:parseHeader(remain_data)
		end
	-- last data is completed
	else 
		if #self.__data > 0 and #self.__data[1] < CONFIG_PROTOCOL_HEADER_LEN_RECV then
            self.__data[1] = self.__data[1] .. __data
        --elseif #self.__data > 0 and #self.__data[1] >= CONFIG_PROTOCOL_HEADER_LEN_RECV then
        else
            self.__data[#self.__data+1] = __data
        end
        if #self.__data[1] < CONFIG_PROTOCOL_HEADER_LEN_RECV then
            return
        end
        _ba:setPos(toPos)
		_ba:writeBuf(string.sub(self.__data[1], 1, CONFIG_PROTOCOL_HEADER_LEN_RECV))
		_ba:setPos(1)
		rcv_len, rcv_type, rcv_cmd = readHeader(_ba)
		if not self:isValideHeader(rcv_type, rcv_cmd) then return end
		-- check is complete data 
        data_len = #self.__data[1]
		if rcv_len + TcpAgent.FIRST_FIELD_LEN == data_len  then
			event_name = "EVENT_CMD_" .. rcv_type .. "_" .. rcv_cmd
			--self:dispatchEvent({name=TcpAgent.EVENT_CMD_2_1, data=__data, error=0})
            local _dispatch_data = nil
            if #self.__data > 0 then
                _dispatch_data = table.concat(self.__data)
            end
			self._last_isCompleted = true
			self._last_pos = 0
			self._last_need_len = 0
			self._last_data = nil
			self.__data = {}
			self:dispatchEvent({name=event_name, data=_dispatch_data, error=0})
            return
		elseif rcv_len + TcpAgent.FIRST_FIELD_LEN > data_len then
			self._last_pos = data_len
			self._last_need_len = rcv_len + TcpAgent.FIRST_FIELD_LEN - data_len
			self._last_isCompleted = false
            --self._last_data = __data
			return
		elseif rcv_len + TcpAgent.FIRST_FIELD_LEN < data_len then
			--dispatch_data = string.sub(self.__data[1], 1, rcv_len+TcpAgent.FIRST_FIELD_LEN)
			event_name = "EVENT_CMD_" .. rcv_type .. "_" .. rcv_cmd
			--self:dispatchEvent({name=TcpAgent.EVENT_CMD_2_1, data=__data, error=0})
            local _dispatch_data = string.sub(self.__data[1], 1, rcv_len+TcpAgent.FIRST_FIELD_LEN)
			self._last_isCompleted = true
			self._last_pos = 0
			self._last_need_len = 0
            self._last_data = nil
			-- process remain data
			local remain_data = string.sub(self.__data[1], rcv_len+TcpAgent.FIRST_FIELD_LEN+1, -1)
            self.__data = {}
			self:dispatchEvent({name=event_name, data=_dispatch_data, error=0})
            return self:parseHeader(remain_data)
		end
	end
	
end

function TcpAgent:send( __data )
	if (not self._socket) or (not self._isConnected) then
		print("connect first please.")
		self:dispatchEvent({name=TcpAgent.NOT_CONNECTED})
		return
	end
	self._socket:send(__data)
	print("TcpAgent:send")
end

function TcpAgent:close(  )
	--self._socket:close()
	self._socket:disconnect()
end

function TcpAgent:isValideHeader( _type, _cmd )
    local rcv_type = _type
    local rcv_cmd = _cmd
	if rcv_type < 0 or rcv_type > self.MAX_TYPE_NUM then
		print("bad header type: " .. rcv_type)
		--reset buffer
        self:resetBuff()
        self._last_isCompleted = true
        self._last_pos = 0
        self._last_need_len = 0
        self.__data = {}
		self:dispatchEvent({name=TcpAgent.EVENT_ERROR, error=1})
		return false
	end
	if rcv_cmd < 0 or rcv_cmd > self.MAX_CMD_NUM then
		print("bad header cmd: " .. rcv_cmd)
		--reset buffer
		self:resetBuff()
        self._last_isCompleted = true
        self._last_pos = 0
        self._last_need_len = 0
        self.__data = {}
		self:dispatchEvent({name=TcpAgent.EVENT_ERROR, error=1})
		return false
	end
	return true
end

function TcpAgent:resetBuff(  )
	self._last_isCompleted = true
	self._last_pos = 0
	self._last_need_len = 0
    self._last_data = nil
end

return TcpAgent
