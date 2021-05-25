local cfg = {}
cfg.upName = "samsung"
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

--cfg.fpage = "fwufan.png"

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


cfg.init = function()
    local params = {
        server_id = player.sid,
        role_name = player.name,
    }
    local jsonstr = jsonEncode(params)
    SDKHelper:getInstance():initGame(jsonstr, function(xdata)
            
    end)
end

cfg.login = function(params, callback)
    addWaitNet()
    cfg.logout()
    SDKHelper:getInstance():login("", function(xdata)
        --tablePrint(__xdata)
        print("sdklogin：", xdata)
        local __data = jsonDecode(xdata)
        if __data and __data.errcode and __data.errcode ~= 0 then
            delWaitNet()
            --showToast(__data.errcode)
            showToast(__data.desc or "登录失败")
            schedule(director:getRunningScene(), 1, function()
                replaceScene(require("ui.login.home").create())
            end)
        else
            local jparams = {
                token = __data.signValue,
                --token = __data.token,
            }
            local jsonstr = jsonEncode(jparams)
            local nparams = {
                sid = 0,
            }
            nparams["jsonStr"] = jsonstr
            nparams["platform"] = "samsung"
            netClient:thirdlogin(nparams, function(nData)
                tablePrint(nData)
                delWaitNet()
                if callback then
                    callback(nData)
                end
            end)
        end
    end)
end

cfg.logout = function(params, callback)
    SDKHelper:getInstance():logout("", function(xdata)
        schedule(director:getRunningScene(), function()
            replaceScene(require("ui.login.home").create())
        end)
    end)
end

--cfg.exit = nil
cfg.exit = function(params, callback)
    SDKHelper:getInstance():exitGame("", function(pdata)
        print("exitGame data:", pdata)
        local __data = jsonDecode(pdata)
        if __data and __data.errcode == 1 then  -- 放弃退出
            return
        end
        if callback then
            callback()
        end
    end)
end

cfg.pay = function(params, callback)
    -- get order
    local oparams = {
        productId = params.productId,
        type = 28,
    }
    addWaitNet()
    getOrder(oparams, function(__data)
        tablePrint(__data)
        local netOrder = jsonDecode(__data.order_info)
        local wfParams = {
            app_name = "放置奇兵",
            app_order_id = netOrder.app_order_id,
            product_name = netOrder.product_name,
            productId = netOrder.productId .. "",
            --pa_open_id = netOrder.pa_open_id,
            --notifyUrl = netOrder.notifyUrl,
            money_amount = netOrder.money_amount,
            --ext = netOrder.ext or "",
            --role_id = (player.uid or "") .. "",
            --role_name = player.name or "",
            --server_id = player.sid .. "",
            transid = netOrder.transid,
            appid = netOrder.appid,
            price = netOrder.price,
            cpOrderId = netOrder.cpOrderId,
        }
        
        require("data.takingdata").onChargeReq(wfParams.app_order_id, netOrder.productId, netOrder.money_amount, "CNY", 0, "third")
        --local paramStr = jsonEncode(wfParams)
        local paramStr = "transid=" .. netOrder.transid .. "&appid=" .. netOrder.appid
        print("paramStr", paramStr)
        SDKHelper:getInstance():pay(paramStr, function(pdata)
            --tablePrint(pdata)
            local tdata = jsonDecode(pdata)
            if not tdata or not tdata.errcode or tdata.errcode ~= 0 then
                --showToast("支付界面被关闭")
                if callback then
                    callback()
                end
                return
            end
            require("data.takingdata").onChargeSuc(netOrder.app_order_id)
            --showToast("支付成功.")
            local gParams = {
                sid = player.sid,
                orderid = netOrder.app_order_id or "",
                appsflyer = HHUtils:getAppsFlyerId(),
                advertising = HHUtils:getAdvertisingId(),
            }
            -- 延迟0.5s 等待后端支付通知到达
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
    -- pay
    -- verify
end

return cfg
