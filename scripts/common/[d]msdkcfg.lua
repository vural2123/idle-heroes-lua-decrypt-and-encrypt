local cfg = {}
cfg.upName = "msdk"
cfg.support_takingdata = true

local cjson = json

require "common.func"
require "common.const"
local netClient = require "net.netClient"
local i18n = require "res.i18n"
local player = require "data.player"
local userdata = require "data.userdata"

local director = CCDirector:sharedDirector()

local bcfg = require "common.basesdkcfg"

local function popReLogin()
    local params = {
        title = "",
        body = "登录过期，需要重新登录",
        btn_count = 1,
        btn_text = {
            [1] = "确定",
        },
        selected_btn = 0,
        callback = function(data)
            if data.selected_btn == 1 then
                data.button:setEnabled(false)
                local lparams = {
                    which = "logout",
                }
                local lparamStr = cjson.encode(lparams)
                SDKHelper:getInstance():login(lparamStr, function(data)
                    print("msdk cfg logout data:", data)
                    local director = CCDirector:sharedDirector()
                    schedule(director:getRunningScene(), function()
                        --replaceScene(require("ui.login.home").create())
                        require("ui.login.home").goUpdate(layer, getVersion())
                    end)
                end)
            end
        end,
    }
    local dialog = require "ui.dialog"
    local d = dialog.create(params)
    function d.onAndroidBack()
        -- disable android back
    end
    local scene = director:getRunningScene()
    scene:addChild(d, 10000000)
end

local function getOrder(params, callback)
    local cfgstore = require "config.store"
    params.sid = player.sid
    params.storeid = params.productId
    params.device_info = HHUtils:getAdvertisingId() or ""
    params.body = params.body or "游戏礼包"
    params.subject = "游戏礼包"
    if cfgstore[params.productId] then
        params.body = cfgstore[params.productId].commodityName
        params.subject = cfgstore[params.productId].commodityName
    end
    netClient:gorder(params, function(__data)
        tablePrint(__data)
        if __data.status ~= 0 then
            delWaitNet()
            --showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
            popReLogin()
            return
        end
        if callback then
            callback(__data)
        end
    end)
end

local jsonEncode = bcfg.jsonEncode
local jsonDecode = bcfg.jsonDecode

local loginJson = {}

cfg.login = function(params, callback)
    loginJson = {}
    local whichtx = userdata.getString(userdata.keys.txwhich, "wx")
    addWaitNet()
    local txparams = {
        which = whichtx,
    }
    local txparamsstr = jsonEncode(txparams)
    print("msdk login, param is ", whichtx)
    cfg.initGame("")
    cfg.logout("false")
    SDKHelper:getInstance():login(txparamsstr, function(xdata)
        --tablePrint(__data)
        print("tx sdklogin：", xdata)
        local __data = jsonDecode(xdata)
        tablePrint(__data)
        delWaitNet()

        if __data and __data.errcode and __data.errcode ~= 0 then
            showToast("登录失败")
            schedule(director:getRunningScene(), 1, function()
                replaceScene(require("ui.login.home").create())
            end)
        else
            showToast("登录成功")
            loginJson = __data
            if loginJson["platform"] then
                whichtx = loginJson["platform"]
                userdata.setString(userdata.keys.txwhich, whichtx)
            end
            local jparams = {
                platform = whichtx,
                openkey = __data.accessToken,
                accessToken = __data.accessToken,
                openid = __data.openid,
                pf = __data.pf,
                pfkey = __data.pf_key,
                paytoken = __data.payToken,
            }
            local jsonstr = jsonEncode(jparams)
            local nparams = {
                sid = 0,
                jsonStr = jsonstr,
                platform = "msdk"
            }
            print("tx22222 jsonstr:", nparams.jsonStr)
            netClient:thirdlogin(nparams, function(nData)
                delWaitNet()
                print("tx login finish, data is:")
                tablePrint(nData)
                if callback then
                    callback(nData)
                end
            end)
        end
    end)
end

cfg.initGame = function(params, callback)
    print("msdk common initGame data:", data)
    if data and data == "wxcall2" then
        userdata.setString(userdata.keys.txwhich, "wx")
        require("ui.login.home").goUpdate(layer, getVersion())
    elseif data and data == "qqcall2" then
        userdata.setString(userdata.keys.txwhich, "qq")
        require("ui.login.home").goUpdate(layer, getVersion())
    end
    local player = require"data.player"
    if player.uid and player.sid then  -- 在游戏内，不做处理
        return
    end
    --local data = cjson.decode(ldata)
    if data and data == "wxcall" then
        userdata.setString(userdata.keys.txwhich, "wx")
        require("ui.login.home").goUpdate(layer, getVersion())
    elseif data and data == "qqcall" then
        userdata.setString(userdata.keys.txwhich, "qq")
        require("ui.login.home").goUpdate(layer, getVersion())
    end
end

cfg.logout = function(params, callback)
    SDKHelper:getInstance():logout(params, function(xdata)
        local toaststr = "登录失败"
        if xdata and xdata == "2002" then
            toaststr = "登录授权失败"
        end
        local scheduler = require("framework.scheduler")
        scheduler.performWithDelayGlobal(function()
            showToast(toaststr)
        end, 1.0)
        replaceScene(require("ui.login.home").create())
    end)
end

cfg.pay = function(params, callback)
    -- get order
    local whichtx = userdata.getString(userdata.keys.txwhich, "wx")
    local oparams = {
        productId = params.productId,
        type = 26,
        body = userdata.getString(userdata.keys.txwhich, "wx"),
    }
    local extInfo = {
        openid = loginJson.openid,
        pf = loginJson.pf,
        pfKey = loginJson.pfKey,
        openkey = loginJson.accessToken,
        sub_platform = whichtx,
    }
    oparams.extInfo = jsonEncode(extInfo)
    getOrder(oparams, function(__data)
        print("tx pay, order info is:")
        tablePrint(__data)
        local netOrder = jsonDecode(__data.order_info)
        local txParams = {
            --zoneId = player.sid,
            zoneId = "1",
            userId = loginJson.openid,
            openKey = netOrder.token,
            pf = loginJson.pf,
            pfKey = loginJson.pfKey,
            saveValue = netOrder.price,
            url_params = netOrder.url_params,
            isCanChange = false,
            ysdkExtInfo = "";
        }
        require("data.takingdata").onChargeReq(netOrder.id, params.productId, netOrder.price/10, "CNY", 0, "third")
        local paramStr = jsonEncode(txParams)
        SDKHelper:getInstance():pay(paramStr, function(pdata)
            print("pay data:", pdata)
            local tdata = jsonDecode(pdata)
            if not tdata or not tdata.errcode or tdata.errcode ~= 0 then
                if tdata and tdata.errcode == "-1" then
                    --showToast(tdata.desc)
                    showToast("支付失败")
                elseif tdata and tdata.errcode == "-2" then
                    --showToast(tdata.desc)
                    showToast("支付取消")
                elseif tdata and tdata.errcode == "-3" then
                    --showToast("登录票据过期，请重新登录游戏")
                    --schedule(director:getRunningScene(), function()
                    --    replaceScene(require("ui.login.home").create())
                    --end)
                    popReLogin()
                    return
                else
                    showToast("支付失败")
                end
                if callback then
                    callback()
                end
                return
            end
            showToast("支付成功.")
            require("data.takingdata").onChargeSuc(netOrder.id)
            local gParams = {
                sid = player.sid,
                orderid = netOrder.cpOrderId or "",
                appsflyer = HHUtils:getAppsFlyerId(),
                advertising = HHUtils:getAdvertisingId(),
            }
            print("client gpay, param is:")
            tablePrint(gParams)
            netClient:gpay(gParams, function(gdata)
                print("client gpay back, data is:")
                tablePrint(gdata)
                delWaitNet()
                if gdata.status ~= 0 then
                    showToast("登录过期，请重新登录游戏")
                    schedule(director:getRunningScene(), function()
                        replaceScene(require("ui.login.home").create())
                    end)
                    return
                end
                if gdata.reward and ((gdata.reward.equips and #gdata.reward.equips > 0) 
                    or (gdata.reward.items and #gdata.reward.items > 0)) then
                    -- 首充礼包状态
                    require("data.activity").pay()
                end
                if callback then
                    callback(gdata.reward)
                end
            end)
        end)
    end)
end

return cfg
