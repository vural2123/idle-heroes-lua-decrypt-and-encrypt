local cfg = {}
cfg.upName = "gameusdk"
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


cfg.init = nil

cfg.login = function(params, callback)
    addWaitNet().setTimeout(200)
    cfg.logout("")
    SDKHelper:getInstance():login("", function(xdata)
        --tablePrint(__xdata)
        print("sdklogin：", xdata)
        local __data = jsonDecode(xdata)
        if __data and __data.errcode and __data.errcode ~= 0 then
            delWaitNet()
            showToast("登录失败")
            schedule(director:getRunningScene(), 1, function()
                replaceScene(require("ui.login.home").create())
            end)
        else
            local jsonstr = jsonEncode({clientid=__data.clientid, pst=__data.pst})
            local nparams = {
                sid = 0,
            }
            nparams["jsonStr"] = jsonstr
            nparams["platform"] = "gameusdk"
            netClient:thirdlogin(nparams, function(nData)
                tablePrint(nData)
                cfg.need_submit = true
                delWaitNet()
                if callback then
                    callback(nData)
                end
            end)
        end
    end)
end

cfg.logout = function(params, callback)
    SDKHelper:getInstance():logout(params, function(xdata)
        replaceScene(require("ui.login.home").create())
    end)
end

cfg.pay = function(params, callback)
    -- get order
    local oparams = {
        productId = params.productId,
        type = 31,
    }
    addWaitNet().setTimeout(240)
    getOrder(oparams, function(__data)
        tablePrint(__data)
        local netOrder = jsonDecode(__data.order_info)
        local ucParams = {
            server_id = "" .. player.sid,
            server_name = "S" .. player.sid,
            role_id = "" .. player.uid,
            role_name = player.name,
            order_id = netOrder.order_no,
            price = "" .. netOrder.money,
            game_coin = "" .. netOrder.game_coin,
            productId = netOrder.product_id,
            productName = netOrder.subject,
            order_time = "" .. netOrder.time,
            ext = netOrder.ext,
            sign = netOrder.sign,
        }
        require("data.takingdata").onChargeReq(ucParams.order_id, params.productId, netOrder.price, "CNY", 0, "third")
        local paramStr = jsonEncode(ucParams)
        SDKHelper:getInstance():pay(paramStr, function(pdata)
            --tablePrint(pdata)
            local tdata = jsonDecode(pdata)
            if not tdata or not tdata.errcode or tdata.errcode ~= 0 then
                showToast("支付界面被关闭")
                if callback then
                    callback()
                end
                return
            end
            showToast("交易正在处理...")
            require("data.takingdata").onChargeSuc(ucParams.order_id)
            local gParams = {
                sid = player.sid,
                orderid = netOrder.order_no or "",
                appsflyer = HHUtils:getAppsFlyerId(),
                advertising = HHUtils:getAdvertisingId(),
            }
            -- 延迟0.5s 等待后端支付通知到达
            schedule(director:getRunningScene(), 5, function()
                netClient:gpay(gParams, function(gdata)
                    tablePrint(gdata)
                    delWaitNet()
                    if gdata.status ~= 0 then
                        showToast("订单异常，请确认支付完成了，联系客服")
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

cfg.exit = function(params, callback)
    SDKHelper:getInstance():exitGame("", function(pdata)
        print("exitGame data:", pdata)
        if callback then
            callback()
        end
    end)
end

cfg.submitRoleData = function(params, callback)
    if not params or params.stype ~= "enterServer" then return end
    local sparams = {
        data_type = "1001",
        role_id = params.roleId .. "",
        role_name = params.roleName .. "",
        role_lv = checkint(params.roleLevel),
        server_id = params.zoneId .. "",
        server_name = params.zoneName .. "",
        balance = (require"data.bag").gem() .. "",
        vip_lv = player.vipLv() .. "",
        party_name = player.gname or "None",
    }
    cfg.need_submit = nil
    local paramStr = jsonEncode(sparams)
    SDKHelper:getInstance():submitRoleData(paramStr, function(xdata)
    end)
    sparams.data_type = "1002"
    paramStr = jsonEncode(sparams)
    SDKHelper:getInstance():submitRoleData(paramStr, function(xdata)
    end)
    sparams.data_type = "1003"
    paramStr = jsonEncode(sparams)
    SDKHelper:getInstance():submitRoleData(paramStr, function(xdata)
    end)
    sparams.data_type = "1004"
    paramStr = jsonEncode(sparams)
    SDKHelper:getInstance():submitRoleData(paramStr, function(xdata)
    end)
end

return cfg
