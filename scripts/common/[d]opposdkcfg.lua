local cfg = {}
cfg.upName = "oppo"
cfg.support_takingdata = true

local cjson = json

require "common.func"
require "common.const"
local netClient = require "net.netClient"
local i18n = require "res.i18n"
local player = require "data.player"
local userdata = require "data.userdata"

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


cfg.init = nil

cfg.login = function(params, callback)
    addWaitNet()
    local txparams = {
        which = "oppo",
    }
    local txparamsstr = jsonEncode(txparams)
    SDKHelper:getInstance():login(txparamsstr, function(xdata)
        --tablePrint(__data)
        print("oppo sdklogin：", xdata)
        local __data = jsonDecode(xdata)
        tablePrint(__data)
        if __data and __data.errcode and __data.errcode ~= 0 then
            showToast("登录失败")
            schedule(director:getRunningScene(), 1, function()
                replaceScene(require("ui.login.home").create())
            end)
        else
            local jparams = {
                token = __data.token,
                ssoid = __data.ssoid
            }
            local jsonstr = jsonEncode(jparams)
            local nparams = {
                sid = 0,
                jsonStr = jsonstr,
                platform = "oppo"
            }
            print("oppo jsonstr:", nparams.jsonStr)
            netClient:thirdlogin(nparams, function(nData)
                tablePrint(nData)
                if callback then
                    callback(nData)
                end
            end)
        end
    end)
end

cfg.logout = function(params, callback)
end

cfg.exit = function(params, callback)
    SDKHelper:getInstance():exitGame("", function(pdata)
        if callback then
            callback()
        end
    end)
end

cfg.pay = function(params, callback)
    -- get order
    local oparams = {
        productId = params.productId,
        type = 6,
    }
    addWaitNet()
    getOrder(oparams, function(__data)
        tablePrint(__data)
        local netOrder = jsonDecode(__data.order_info)
        local txParams = {
            order = netOrder.partnerOrder,
            amount = netOrder.price,
            attach = netOrder.attach,
            callbackUrl = netOrder.notifyUrl,
            productName = "游戏礼包",
            productDesc= "游戏礼包",
        }
        --require("data.takingdata").onChargeReq(txParams.order, params.productId, netOrder.price/100, "CNY", 0, "third")
        local paramStr = jsonEncode(txParams)
        SDKHelper:getInstance():pay(paramStr, function(pdata)
            --tablePrint(pdata)
            local tdata = jsonDecode(pdata)
            if not tdata or not tdata.errcode or tdata.errcode ~= 0 then
                --if tdata and tdata.desc then
                --    showToast(tdata.desc)
                --else
                --    showToast("支付失败")
                --end
                if callback then
                    callback()
                end
                return
            end
            showToast("支付成功.")
            --require("data.takingdata").onChargeSuc(txParams.order)
            local gParams = {
                sid = player.sid,
                orderid = netOrder.partnerOrder or "",
                appsflyer = HHUtils:getAppsFlyerId(),
                advertising = HHUtils:getAdvertisingId(),
            }
            netClient:gpay(gParams, function(gdata)
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
