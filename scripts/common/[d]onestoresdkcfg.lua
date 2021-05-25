local cfg = {}
cfg.upName = "onestore"

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
    --if true then
    --    callback(jsonEncode({
    --        tid = "DH" .. getMilliSecond(),
    --    }))
    --    return
    --end
    params.sid = player.sid
    params.storeid = params.productId
    params.device_info = HHUtils:getAdvertisingId() or ""
    params.body = params.body or "游戏礼包"
    params.subject = "游戏礼包"
    netClient:gorder(params, function(__data)
        --tablePrint(__data)
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

local function processPrice()
    local cfgstore = require "config.store"
    for id, cfg in ipairs(cfgstore) do
        cfg.price = cfg.krPrice
        cfg.priceCn = cfg.krPrice
        cfg.priceStr = cfg.priceKrStr
        cfg.priceCnStr = cfg.priceKrStr
    end
end

cfg.init = function()
    processPrice()
    SDKHelper:getInstance():initGame("", function(pdata)
        print("initGame:", pdata)
        local params = {
            sid = player.sid,
        }
        netClient:oneforum(params, function(__data)
            tbl2string(__data)
        end)
    end)
end

cfg.login = nil

cfg.logout = function(params, callback)
    SDKHelper:getInstance():logout("", function(xdata)
        schedule(director:getRunningScene(), function()
            replaceScene(require("ui.login.home").create())
        end)
    end)
end

cfg.exit = nil

local function getSku(productId)
    local cfgstore = require "config.store"
    for id, cfg in ipairs(cfgstore) do
        if id == productId then
            return cfg.pid
        end
    end
    return nil
end

local function getPrice(productId)
    local cfgstore = require "config.store"
    for id, cfg in ipairs(cfgstore) do
        if id == productId then
            return "" .. cfg.krPrice
        end
    end
    return "0"
end

local function trackPayment(money)
    HHUtils:trackPaymentAppsFlyer(tonumber(money), "USD")
end

local updateReceipts = {}
local function handleUpdateReceipts(pdata)
end

local function fullfill(receiptid)
    SDKHelper:getInstance():submitRoleData(receiptid, function(pdata)
    end)
end

local checking = nil

cfg.initGame = nil

cfg.pay = function(params, callback)
    local sku = getSku(params.productId)
    print("get sku:", sku)
    if not sku then
        delWaitNet()
        showToast("get sku failed.")
        return
    end
    -- get order
    local oparams = {
        productId = params.productId,
        pid = sku,
        type = 25,
    }
    addWaitNet()
    getOrder(oparams, function(__data)
        tablePrint(__data)
        local netOrder = jsonDecode(__data.order_info)
        --local netOrder = jsonDecode(__data)
        local ucParams = {
            tid = netOrder.cpOrderId,
            pid = oparams.pid,
        }
        local paramStr = jsonEncode(ucParams)
        SDKHelper:getInstance():pay(paramStr, function(pdata)
            local tdata = jsonDecode(pdata)
            tablePrint(tdata)
            if not tdata or not tdata.errcode or tdata.errcode ~= 0 then
                --showToast("支付界面被关闭")
                if callback then
                    callback()
                end
                return
            end
            --showToast("支付成功.")
            local gParams = {
                sid = player.sid,
                orderid = ucParams.tid,
                txid = tdata.txid,
                productid = tdata.sign,
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
                    --fullfill(tdata.receiptid)
                    if gdata.reward and ((gdata.reward.equips and #gdata.reward.equips > 0) 
                        or (gdata.reward.items and #gdata.reward.items > 0)) then
                        -- 首充礼包状态
                        require("data.activity").pay()
                    end
                    --trackPayment(getPrice(params.productId))
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
