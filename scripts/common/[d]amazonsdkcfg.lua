local cfg = {}
cfg.upName = "amazon"

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

local login_error = "refresh"         -- 强制授权登陆

cfg.login = function(params, callback)
    addWaitNet()
    cfg.logout()
    cfg.initGame()
    SDKHelper:getInstance():login(login_error, function(xdata)
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
                token = __data.token,
            }
            local jsonstr = jsonEncode(jparams)
            local nparams = {
                sid = 0,
            }
            nparams["jsonStr"] = jsonstr
            nparams["platform"] = "amazon"
            netClient:thirdlogin(nparams, function(nData)
                tablePrint(nData)
                if not nData or nData.status ~= 0 then
                    login_error = "refresh"
                else
                    login_error = ""
                end
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

cfg.exit = nil

local function getSku(productId)
    local cfgstore = require "config.store"
    for id, cfg in ipairs(cfgstore) do
        if id == productId then
            return cfg.payId
        end
    end
    return nil
end

local function getPrice(productId)
    local cfgstore = require "config.store"
    for id, cfg in ipairs(cfgstore) do
        if id == productId then
            return "" .. cfg.price
        end
    end
    return "0"
end

local function trackPayment(money)
    HHUtils:trackPaymentAppsFlyer(tonumber(money), "USD")
end

local updateReceipts = {}
local amazon_userid = ""
local function handleUpdateReceipts(pdata)
    if not pdata or string.trim(pdata) == "" then
        return
    end
    local tdata = jsonDecode(pdata)
    local rts = tdata.receiptids or ""
    amazon_userid = tdata.userid
    local arr = string.split(rts, "|")
    for _, rt in ipairs(arr) do
        local tmpObj = string.trim(rt)
        updateReceipts[#updateReceipts+1] = tmpObj
    end
end

local function fullfill(receiptid)
    SDKHelper:getInstance():submitRoleData(receiptid, function(pdata)
    end)
end

local checking = nil
cfg.checkRts = function()
    if checking then return end
    if #updateReceipts < 1 then 
        checking = nil
        return 
    end
    checking = true
    local rts_cp = arraycp(updateReceipts)
    local vParams = {
        sid = player.sid,
        receiptid = updateReceipts,
        userid = amazon_userid,
    }
    netClient:amznpay(vParams, function(vdata)
        tbl2string(vdata)
        for ii=1,#rts_cp do
            fullfill(rts_cp[ii])
        end
        if vdata.money then
            trackPayment(vdata.money)
        end
    end)
    arrayclear(updateReceipts)
    updateReceipts = {}
end

cfg.initGame = function()
    SDKHelper:getInstance():initGame("", function(pdata)
        print("rts:", pdata)
        handleUpdateReceipts(pdata)
    end)
end

cfg.pay = function(params, callback)
    -- get order
    --local oparams = {
    --    productId = params.productId,
    --    type = 24,
    --}
    local sku = getSku(params.productId)
    if not sku then
        delWaitNet()
        showToast("get sku failed.")
        return
    end
    addWaitNet()
    local ucParams = {
        sku = sku,
    }
    local paramStr = jsonEncode(ucParams)
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
        --showToast("支付成功.")
        local gParams = {
            sid = player.sid,
            orderid = tdata.receiptid,
            userid = tdata.userid,
            productid = "" .. params.productId,
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
                fullfill(tdata.receiptid)
                if gdata.reward and ((gdata.reward.equips and #gdata.reward.equips > 0) 
                    or (gdata.reward.items and #gdata.reward.items > 0)) then
                    -- 首充礼包状态
                    require("data.activity").pay()
                end
                trackPayment(getPrice(params.productId))
                if callback then
                    callback(gdata.reward)
                end
            end)
        end)
    end)
    -- pay
    -- verify
end


return cfg
