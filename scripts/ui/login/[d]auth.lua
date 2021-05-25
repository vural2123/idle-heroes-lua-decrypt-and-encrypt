-- 用户认证

local auth = {}

require "common.const"
require "common.func"
local i18n = require "res.i18n"
local netClient = require "net.netClient"
local userdata = require "data.userdata"
local bcfg = require "common.basesdkcfg"
local jsonEncode = bcfg.jsonEncode
local jsonDecode = bcfg.jsonDecode

-- param: 可包含sid, account, password, new
-- setHint(text) setHint可为nil
-- onFinish(status, uid, sid) onFinish可为nil
--   status = "ok" | error-string
function auth.start(param, onFinish, setHint)
    param = param or {}
    local acct = param.account or userdata.getString(userdata.keys.account)
    local pswd = param.password or userdata.getEncryptString(userdata.keys.password)
    local net = op3(param.new, netClient:new(), netClient)
    local connect = op3(param.new, net.newConnect, net.connect)

    local m = {}

    function m.connect()
        m.setHint(i18n.global.connect_gate_server.string)
        local gate = require("ui.login.gate").get()
        connect(net, { host = gate.host, port = gate.port }, function()
            if acct == "" or pswd == "" then
                m.setHint(i18n.global.register_account.string)
                require "version"
                local osversion = ""
                if HHUtils.getOSVersion then
                    osversion = HHUtils:getOSVersion() or ""
                end
                local reg_params = {
                    sid = 0,
                    rdid = HHUtils:getAdvertisingId() or "",
                    appversion = VERSION_CODE,
                    osversion = osversion,
                }
                net:reg(reg_params, function(data)
                    m.setHint(i18n.global.register_account_ok.string)
                    acct = data.account
                    pswd = data.password
                    userdata.setString(userdata.keys.account, acct)
                    userdata.setEncryptString(userdata.keys.password, pswd)
                    userdata.setBool(userdata.keys.accountFormal, false)
                    m.salt()
                end)
            else
                m.salt()
            end
        end)
    end

    function m.thirdConnect()
        m.setHint(i18n.global.connect_gate_server.string)
        local gate = require("ui.login.gate").get()
        connect(net, { host = gate.host, port = gate.port }, function()
            m.thirdLogin()
        end)
    end

    function m.salt()
        m.setHint(i18n.global.auth_account.string)
        net:salt({ sid = 0, account = acct }, function(data)
            if data.status ~= 0 then
                if data.status == -1 then
                    m.setHint(i18n.global.error_account_passwd.string)
                    m.onFinish(i18n.global.error_account_passwd.string)
                else
                    m.setHint(i18n.global.auth_account_fail.string .. " salt:" .. data.status)
                    m.onFinish(i18n.global.auth_account_fail.string .. " salt:" .. data.status)
                end
                return
            end
            print("uid", data.uid)
            m.login(data.uid, data.salt)
        end)
    end

    function m.login(uid, salt)
        local checksum = crypto.md5(salt .. "rwmkxhgi6;578i650" .. pswd)
        local lParam = {
            sid = 0, 
            checksum = checksum,
            idfa = HHUtils:getAdvertisingId(),
            keychain = HHUtils:getUniqKC(),
            idfv = HHUtils:getUniqFv(),
        }
        net:login(lParam, function(data)
            if data.status ~= 0 then
                if data.status == -1 then
                    m.setHint(i18n.global.error_account_passwd.string)
                    m.onFinish(i18n.global.error_account_passwd.string)
                elseif data.status == -2 then
                    m.setHint(i18n.global.acct_ban.string)
                    m.onFinish(i18n.global.acct_ban.string)
                elseif data.status == -17 then
                    m.setHint("Permanently banned")
                    m.onFinish("Permanently banned")
                elseif data.status <= -18 then
                    local hourrem = -(data.status + 18)
                    local hourstr = "Temporarily banned / 暂时禁止 (" .. hourrem .. " hour / 小时)"
                    m.setHint(hourstr)
                    m.onFinish(hourstr)
                else
                    m.setHint(i18n.global.auth_account_fail.string .. " login:" .. data.status)
                    m.onFinish(i18n.global.auth_account_fail.string .. " login:" .. data.status)
                end
                return
            end
            if param and param.extra and param.extra.uid then  -- 切服，指定uid
                uid = param.extra.uid
            elseif data and data.uid then
                uid = data.uid
            end
            print("data.sid", data.sid)
            print("param.sid", param.sid)
            print("data.uid", data.uid)
            m.auth(uid, data.session, param.sid or data.sid)
        end)
    end

    function m.thirdLogin()
        local sdkcfg = require"common.sdkcfg"
        --if sdkcfg[APP_CHANNEL] and sdkcfg[APP_CHANNEL].init then
        --    sdkcfg[APP_CHANNEL].init({}, function(data)
        --    end)
        --end
        if sdkcfg[APP_CHANNEL] and sdkcfg[APP_CHANNEL].login then
            sdkcfg[APP_CHANNEL].login({}, function(data)
                if data.status == 0 then
                    userdata.createTs = data.createTs or 0
                    local uid = data.uid
                    if param and param.extra and param.extra.uid then  -- 切服，指定uid
                        uid = param.extra.uid
                    elseif data and data.uid then
                        uid = data.uid
                    end
                    m.auth(uid, data.session, param.sid or data.sid) 

                    local lParams = {
                        uid = "" .. uid,
                        acct = "" .. uid,
                        sid = "S" .. (param.sid or data.sid),
                    }
                    local paramStr = jsonEncode(lParams)
                    require("data.takingdata").statAccount(2, paramStr)
                elseif data.status == -2 then
                    m.setHint(i18n.global.acct_ban.string)
                    m.onFinish(i18n.global.acct_ban.string)
                else
                    m.setHint("login failed.")
                    m.onFinish("login failed.")
                end
            end)
        end
    end

    function m.auth(uid, session, sid)
        local userid = userdata.getString(userdata.keys.userid, "")
        local s_uid = uid or ""
        if userid and userid ~= "" and userid ~= ("" .. s_uid) then   --切账号清除缓存
            userdata.clearWhenSwitchAccount()
        end
        userdata.setString(userdata.keys.userid, s_uid)
        local envInfo = jsonEncode(getEnvInfo())
        local dids = jsonEncode(getDIDS())
        net:auth({ uid = uid, sid = sid, session = session, env = envInfo, ids = dids }, function(data)
            if data.status ~= 0 then
                if data.status == -2 then
                    m.setHint(i18n.global.error_server_maintain.string)
                    m.onFinish(i18n.global.error_server_maintain.string)
                else
                    m.setHint(i18n.global.auth_account_fail.string .. " auth:" .. data.status)
                    m.onFinish(i18n.global.auth_account_fail.string .. " auth:" .. data.status)
                end
                return
            end
            userdata.createTs = data.createTs or 0
            m.setHint(i18n.global.auth_account_ok.string)
            m.onFinish("ok", uid, sid)
        end)
    end

    function m.setHint(text)
        if setHint then
            setHint(text)
        end
    end

    function m.onFinish(status, uid, sid)
        if param.new then
            net:close(function()
                if onFinish then
                    onFinish(status, uid, sid)
                end
            end)
        else
            if onFinish then
                onFinish(status, uid, sid)
            end
        end
    end

    if not APP_CHANNEL or APP_CHANNEL == "" then
        m.connect()
    elseif APP_CHANNEL == "IAS" then
        m.connect()
    elseif APP_CHANNEL == "ONESTORE" then
        local sdkcfg = require"common.sdkcfg"
        if sdkcfg[APP_CHANNEL] and sdkcfg[APP_CHANNEL].init then
            sdkcfg[APP_CHANNEL].init()
        end
        m.connect()
    else
        m.thirdConnect()
    end
end

return auth
