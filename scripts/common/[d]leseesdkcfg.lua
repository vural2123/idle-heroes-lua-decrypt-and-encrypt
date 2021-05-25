local cfg = {}

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
        which = "lesee",
    }
    local txparamsstr = jsonEncode(txparams)
    print("lesee进入login前的最后一步")
    SDKHelper:getInstance():login(txparamsstr, function(xdata)
        --解析数据
        local __data = jsonDecode(xdata)
        tablePrint(__data)
        if __data and __data.errcode and __data.errcode ~= 0 then
            showToast("login failed")
            return
        end
    
        local jparams = {
            accessToken = __data.accessToken,
        }
        print("lesee获得accessToken = "..__data.accessToken)
        local jsonstr = jsonEncode(jparams)
        local nparams = {
            sid = 0,
            jsonStr = jsonstr,
            platform = "lesee"
        }

        print("网络请求发起 = "..jsonstr)
        netClient:thirdlogin(nparams, function(nData)
            print("网络收到回信")
            --tablePrint(nData)
            if callback then
                callback(nData)
            end
        end)
    end)
end

cfg.logout = function(params, callback)
end

cfg.exit = nil

cfg.pay = function(params, callback)
    -- get order
    local oparams = {
        productId = params.productId,
        type = 13,
    }
    addWaitNet()
    getOrder(oparams, function(__data)
        tablePrint(__data)
        local netOrder = jsonDecode(__data.order_info)
        local txParams = {
            cpOrderId = netOrder.cpOrderId,
            cpUserInfo = netOrder.cpUserInfo,
            notifyurl = netOrder.notifyurl,
            price = netOrder.price,
        }
        local paramStr = jsonEncode(txParams)
        SDKHelper:getInstance():pay(paramStr, function(pdata)
            --tablePrint(pdata)
            local tdata = jsonDecode(pdata)
            if not tdata or not tdata.errcode or tdata.errcode ~= 0 then
                delWaitNet()
                showToast("pay failed:" + tdata.desc)
                if callback then
                    callback()
                end
                return
            end
            showToast("支付成功.")
            local gParams = {
                sid = player.sid,
                orderid = netOrder.cpOrderId or "",
                appsflyer = HHUtils:getAppsFlyerId(),
                advertising = HHUtils:getAdvertisingId(),
            }
             -- 延迟0.5s 等待后端支付通知到达
            local director = CCDirector:sharedDirector()
            schedule(director:getRunningScene(), 0.5, function()
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
    end)
end

return cfg
