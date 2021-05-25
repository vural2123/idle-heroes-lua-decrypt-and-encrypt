local cfg = {}
cfg.upName = "chudong"
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


cfg.init = nil

cfg.login = function(params, callback)
    addWaitNet()
    cfg.logout()
    SDKHelper:getInstance():login("", function(xdata)
        --tablePrint(__xdata)
        print("sdklogin：", xdata)
        local __data = jsonDecode(xdata)
        if __data and __data.errcode and __data.errcode ~= 0 then
            delWaitNet()
            showToast(__data.desc or "登录失败")
            schedule(director:getRunningScene(), 1, function()
                replaceScene(require("ui.login.home").create())
            end)
        else
            local jparams = {
                uid = __data.uid,
                username = __data.username,
                signkey = __data.signkey,
            }
            local jsonstr = jsonEncode(jparams)
            local nparams = {
                sid = 0,
            }
            nparams["jsonStr"] = jsonstr
            nparams["platform"] = "chudong"
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

cfg.exit = function(params, callback)
    SDKHelper:getInstance():exitGame("", function(pdata)
        print("exitGame data:", pdata)
        if callback then
            callback()
        end
    end)
end

cfg.pay = function(params, callback)
    -- get order
    local oparams = {
        productId = params.productId,
        type = 23,
    }
    addWaitNet()
    getOrder(oparams, function(__data)
        schedule(director:getRunningScene(), 2, function()
            delWaitNet()
        end)
        tablePrint(__data)
        local netOrder = jsonDecode(__data.order_info)
        local ucParams = {
            productId = netOrder.productId .. "",
            productName = netOrder.productName,
            amount = netOrder.amount or "100000",
            num = netOrder.num or "1",
            zone = player.sid .. "",
            zoneName = "S" .. player.sid,
            roleName = player.name or "",
            roleId = (player.uid or "") .. "",
            callBackInfo = netOrder.callBackInfo or "",
        }
        require("data.takingdata").onChargeReq(ucParams.callBackInfo, oparams.productId, ucParams.amount/100, "CNY", 0, "third")
        local paramStr = jsonEncode(ucParams)
        SDKHelper:getInstance():pay(paramStr, function(pdata)
            --tablePrint(pdata)
            local tdata = jsonDecode(pdata)
            if not tdata or not tdata.errcode or tdata.errcode ~= 0 then
                delWaitNet()
                if tdata.errcode == -1 then
                    showToast("支付失败")
                elseif tdata.errcode == -2 then
                    showToast("支付取消")
                end
                if callback then
                    callback()
                end
                return
            end
            require("data.takingdata").onChargeSuc(ucParams.callBackInfo)
            --showToast("支付成功.")
            local gParams = {
                sid = player.sid,
                orderid = netOrder.cp_order_id or "",
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

cfg.submitRoleData = function(params, callback)
    local sparams = {
        roleid = (player.uid or "") .. "",
        rolelevel = player.lv() .. "",
        rolename = player.name or "",
        role_vip = player.vipLv() .. "",
        zoneid = player.sid .. "",
        zonename = "S" .. player.sid,
    }
    local paramStr = jsonEncode(sparams)
    SDKHelper:getInstance():submitRoleData(paramStr, function(xdata)
    end)
end


return cfg
