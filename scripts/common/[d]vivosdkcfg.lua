local cfg = {}
cfg.upName = "vivo"
cfg.support_takingdata = true

local cjson = json

require "common.func"
require "common.const"
local netClient = require "net.netClient"
local i18n = require "res.i18n"
local player = require "data.player"
local userdata = require "data.userdata"

local bcfg = require "common.basesdkcfg"

local ERR_MSG = {
    ["-1"] = "支付取消",
    ["-2"] = "其他错误",
    ["-3"] = "参数错误",
    ["-4"] = "支付结果请求超时",
    ["-5"] = "非足额支付（充值成功，未完成支付）",
    ["-6"] = "初始化失败",
    ["-7"] = "请重试",
}

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
        which = "vivo",
    }
    local txparamsstr = jsonEncode(txparams)
    cfg.logout()
    SDKHelper:getInstance():login(txparamsstr, function(xdata)
        print("vivo sdklogin：", xdata)
        local __data = jsonDecode(xdata)
        tablePrint(__data)
        if __data and __data.errcode and __data.errcode ~= 0 then
            delWaitNet()
            showToast("登录失败")
            schedule(director:getRunningScene(), 1, function()
                replaceScene(require("ui.login.home").create())
            end)
        else
            local jparams = {
                userName = __data.userName,
                openId = __data.openId,
                authToken = __data.authToken,
            }
            local jsonstr = jsonEncode(jparams)
            local nparams = {
                sid = 0,
                jsonStr = jsonstr,
                platform = "vivo"
            }
            print("vivo jsonstr:", nparams.jsonStr)
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
    SDKHelper:getInstance():logout("", function(xdata)
        schedule(director:getRunningScene(), function()
            replaceScene(require("ui.login.home").create())
        end)
    end)
end

cfg.pay = function(params, callback)
    -- get order
    local oparams = {
        productId = params.productId,
        type = 7,
    }
    addWaitNet()
    getOrder(oparams, function(__data)
        tablePrint(__data)
        local netOrder = jsonDecode(__data.order_info)
        local txParams = {
            productPrice = netOrder.productPrice,
            vivoSignature = netOrder.vivoSignature,
            productName = netOrder.productName,
            productDes = netOrder.productDes,
            transNo = netOrder.transNo,
            openId = netOrder.openId,
            extInfo = netOrder.extInfo or "",
        }
        require("data.takingdata").onChargeReq(txParams.transNo, params.productId, netOrder.productPrice/100, "CNY", 0, "third")
        local paramStr = jsonEncode(txParams)
        SDKHelper:getInstance():pay(paramStr, function(pdata)
            --tablePrint(pdata)
            local tdata = jsonDecode(pdata)
            if not tdata or not tdata.errcode or tdata.errcode ~= 0 then
                if ERR_MSG["" .. tdata.errcode] then
                    showToast(ERR_MSG["" .. tdata.errcode])
                else
                    showToast("支付失败:" + tdata.desc)
                end
                if callback then
                    callback()
                end
                delWaitNet()
                return
            end
            showToast("支付成功.")
            require("data.takingdata").onChargeSuc(netOrder.transNo)
            local gParams = {
                sid = player.sid,
                orderid = netOrder.orderid or "",
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

cfg.submitRoleData = function(params, callback)
    local sparams = {
        role_id = params.roleId .. "",
        name = params.roleName .. "",
        level = checkint(params.roleLevel),
        serverid = params.zoneId .. "",
        servername = params.zoneName .. "",
    }
    local paramStr = jsonEncode(sparams)
    SDKHelper:getInstance():submitRoleData(paramStr, function(xdata)
    end)
end

return cfg
