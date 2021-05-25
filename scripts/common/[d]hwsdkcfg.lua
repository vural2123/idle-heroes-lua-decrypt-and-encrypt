local cfg = {}
cfg.upName = "hw"
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
local jsonEncode = bcfg.jsonEncode
local jsonDecode = bcfg.jsonDecode

local function getOrder(params, callback)
    params.sid = player.sid
    params.storeid = params.productId
    params.subject = "游戏礼包"
    params.body = "游戏礼包"
    params.device_info = HHUtils:getAdvertisingId() or ""
    params.extInfo = jsonEncode({is_new="1"})
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

cfg.login = function(params, callback)
    --cfg.logout()
    SDKHelper:getInstance():login("", function(xdata)
        --tablePrint(__data)
        print("sdklogin：", xdata)
        local __data = jsonDecode(xdata)
        if not __data or not __data.errcode or __data.errcode ~= 0 then
            delWaitNet()
            if __data and __data.errcode then
                if __data.errcode == 3 or __data.errcode == 7 or __data.errcode == 10 then
                    showToast("请安装或更新游戏中心")
                else
                    showToast("请重新登录")
                end
            else
                showToast("请重新登录")
            end
            schedule(director:getRunningScene(), 1, function()
                replaceScene(require("ui.login.home").create())
            end)
        else
            local hparams = {
                gameAuthSign = __data.sign,
                playerId = __data.playerId,
                playerLevel = __data.playerLevel,
                appId = __data.appId,
                ts = __data.ts,
                is_new = "1",
            }
            local jsonstr = jsonEncode(hparams)
            local nparams = {}
            nparams["jsonStr"] = jsonstr
            nparams["sid"] = 0
            nparams["platform"] = "hw"
            print("----------------------hw params---------------------")
            tablePrint(nparams)
            print("----------------------hw params---------------------")
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
        schedule(director:getRunningScene(), function()
            replaceScene(require("ui.login.home").create())
        end)
    end)
end

cfg.pay = function(params, callback)
    -- get order
    local oparams = {
        productId = params.productId,
        type = 4,
    }
    addWaitNet()
    getOrder(oparams, function(__data)
        tablePrint(__data)
        local netOrder = jsonDecode(__data.order_info)
        local txParams = {
            price = netOrder.amount,
            productName = netOrder.productName,
            productDesc = netOrder.productDesc,
            requestId = netOrder.requestId or "",
            --userName = netOrder.userName or "",
            --userID = netOrder.userID or "",
            userName = netOrder.merchantName or "",
            userID = netOrder.merchantId or "",
            sdkChannel = netOrder.sdkChannel or "",
            serviceCatalog = netOrder.serviceCatalog or "",
            extReserved = netOrder.extReserved or "",
            url = netOrder.url or "",
            applicationID = netOrder.applicationID or "",
            sign = netOrder.sign or "",
        }
        require("data.takingdata").onChargeReq(txParams.requestId, oparams.productId, txParams.price, "CNY", 0, "third")
        local paramStr = jsonEncode(txParams)
        SDKHelper:getInstance():pay(paramStr, function(pdata)
            print("hw pay ret:", pdata)
            local tdata = jsonDecode(pdata)
            if not tdata or not tdata.errcode or tdata.errcode ~= 0 then
                if tdata and tdata.desc then
                    showToast(tdata.desc)
                else
                    showToast("支付失败")
                end
                if callback then
                    callback()
                end
                return
            end
            require("data.takingdata").onChargeSuc(txParams.requestId)
            showToast("支付成功.")
            local gParams = {
                sid = player.sid,
                orderid = netOrder.requestId or "",
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

cfg.submitRoleData = function(params, callback)
    local sparams = {
        role_name= params.roleName .. "",
        role_level= checkint(params.roleLevel),
        server_name = params.zoneName .. "",
        party_name = player.gname or "",
    }
    local paramStr = jsonEncode(sparams)
    SDKHelper:getInstance():submitRoleData(paramStr, function(xdata)
    end)
end

return cfg
