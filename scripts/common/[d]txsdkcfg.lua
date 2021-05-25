local cfg = {}
cfg.upName = "tx"
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

local function getOrder(params, callback)
    params.sid = player.sid
    params.storeid = params.productId
    params.device_info = HHUtils:getAdvertisingId() or ""
    params.body = params.body or "游戏礼包"
    params.subject = "游戏礼包"
    netClient:gorder(params, function(__data)
        tablePrint(__data)
        if __data.status ~= 0 then
            delWaitNet()
            showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
            return
        end
        if callback then
            callback(__data)
        end
    end)
end

local jsonEncode = bcfg.jsonEncode
local jsonDecode = bcfg.jsonDecode

cfg.login = function(params, callback)
    local whichtx = userdata.getString(userdata.keys.txwhich, "qq")
    addWaitNet()
    local txparams = {
        which = whichtx,
    }
    local txparamsstr = jsonEncode(txparams)
    print("tx sdk login, param is ", whichtx)
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
            local jparams = {
                platform = whichtx,
                openkey = __data.openkey,
                openid = __data.openid,
                pf = __data.pf,
                pfkey = __data.pf_key,
                paytoken = __data.payToken,
            }
            local jsonstr = jsonEncode(jparams)
            local nparams = {
                sid = 0,
                jsonStr = jsonstr,
                platform = "tx"
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

cfg.logout = function(params, callback)
    SDKHelper:getInstance():logout(params, function(xdata)
        schedule(director:getRunningScene(), function()
            replaceScene(require("ui.login.home").create())
        end)
    end)
end

cfg.pay = function(params, callback)
    -- get order
    local oparams = {
        productId = params.productId,
        type = 5,
        body = userdata.getString(userdata.keys.txwhich, "qq")
    }
    getOrder(oparams, function(__data)
        print("tx pay, order info is:")
        tablePrint(__data)
        local netOrder = jsonDecode(__data.order_info)
        local txParams = {
            --zoneId = player.sid,
            zoneId = "1",
            saveValue = netOrder.price,
            isCanChange = false,
            ysdkExtInfo = "";
        }
        require("data.takingdata").onChargeReq(netOrder.id, params.productId, netOrder.price/10, "CNY", 0, "third")
        local paramStr = jsonEncode(txParams)
        SDKHelper:getInstance():pay(paramStr, function(pdata)
            print("pay data:", pdata)
            local tdata = jsonDecode(pdata)
            if not tdata or not tdata.errcode or tdata.errcode ~= 0 then
                if tdata and tdata.desc then
                    --showToast(tdata.desc)
                    showToast("支付失败")
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
                orderid = netOrder.id or "",
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
                    showToast(i18n.global.error_server_status_wrong.string .. tostring(gdata.status))
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
