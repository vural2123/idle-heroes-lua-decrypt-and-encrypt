local iap = {}

require "common.const"
require "common.func"

-- 拉取未完成帐单并与逻辑服进行校验
-- handler(reward) reward可能为nil
function iap.pull(handler)
    if APP_CHANNEL and APP_CHANNEL == "IAS" then
        handler()
    elseif isChannel() then
        handler()
    else
        DHPayment:getInstance():pull(function(status, purchases)
            print("iap pull {")
            print("status", status);
            if status ~= "ok" or #purchases == 0 then
                print("iap pull }")
                handler()
                return
            end
            iap.verify(purchases, function(reward)
                print("iap pull }")
                handler(reward)
            end)
        end)
    end
end

-- 检查是否能支付
function iap.pay(productId, handler)
    --if device.platform ~= "ios" then
    if APP_CHANNEL and APP_CHANNEL ~= "" then
        iap.rpay(productId, handler)
        return
    end
    local playerdata = require "data.player"
    local params = {
        sid = playerdata.sid,
        storeid = iap.convertId(productId),
    }
    local net = require "net.netClient"
    net:chpay(params, function(data)
        if data.status ~= 0 then
            delWaitNet()
            if data.status == -1 then
                local i18n = require "res.i18n"
                showToast(i18n.global.pay_ban.string)
                return
            elseif data.status == -2 then
                local i18n = require "res.i18n"
                showToast(i18n.global.toast_buy_herolist_full.string)
                return
            else
                local i18n = require "res.i18n"
                showToast(i18n.global.pay_ban2.string)
                return
            end
        else
            iap.rpay(productId, handler)
        end
    end)
end
-- 支付
-- handler(reward) reward可能为nil
function iap.rpay(productId, handler)
    local _productId = iap.convertId(productId)
    if APP_CHANNEL and APP_CHANNEL == "IAS" then
        delWaitNet()
        local payDlg = require("ui.payDlg")
        CCDirector:sharedDirector():getRunningScene():addChild(payDlg.create({productId=_productId, callback=handler}), 10000)
        return
    elseif isChannel() then
        --if true then
        --    delWaitNet()
        --    showToast("测试期间未开放充值")
        --    return
        --end
        local sdkcfg = require"common.sdkcfg"
        if sdkcfg[APP_CHANNEL] and sdkcfg[APP_CHANNEL].pay then
            sdkcfg[APP_CHANNEL].pay({productId=_productId}, handler)
        end
        return
    end
    local refId = productId
    if device.platform == "android" and refId and string.sub(refId, -3, -1) == "d36" then -- 订阅项
        refId = refId .. "_subs"
    end
    DHPayment:getInstance():pay(refId, function(status, purchase)
        print("iap pay {")
        print("status", status);
        if status ~= "ok" then
            print("iap pay }")
            handler()
            return
        end
        iap.verify({ purchase }, function(reward)
            print("iap pay }")
            handler(reward)
        end)
    end)
end

-- 与逻辑服进行校验
-- purchases: DHPayment:pull或DHPayment:pay的返回
-- handler(reward) reward可能为nil
function iap.verify(purchases, handler)
    -- 复制一遍，因为与逻辑服验证返回后purchases在C层内存可能已经被释放
    local purchasesCopy = {}
    -- 构建联网参数
    local playerdata = require "data.player"
    local params = {
        sid = playerdata.sid,
        order = {},
        id = {},
        token = {},
        package = purchases[1].packageName,
        platform = DHPayment:getInstance():getTypeString(),
        appsflyer = HHUtils:getAppsFlyerId(),
        advertising = HHUtils:getAdvertisingId(),
    }
    local anySub = nil
    for _, purchase in ipairs(purchases) do
        if string.sub(purchase.productId or "", -3, -1) == "d36" then
            anySub = true
        end
        print("iap verify: productId", purchase.productId, "orderId", purchase.orderId, "token", purchase.token)
        table.insert(params.order, purchase.orderId)
        table.insert(params.id, iap.convertId(purchase.productId))
        table.insert(params.token, purchase.token)
        table.insert(purchasesCopy, purchase:clone());
    end
    -- 联网
    local net = require "net.netClient"
    net:pay2(params, function(data)
        if data.status ~= 0 then
            -- 先消费购买项
            DHPayment:getInstance():consume(purchasesCopy, function()
                handler()
            end)
            return
        end

        if not data.reward and anySub then
            data.reward = {
                items = {
                    [1] = {id=ITEM_ID_SP_SUB, num=10}
                }
            }
        end
        
        -- 先消费购买项
        DHPayment:getInstance():consume(purchasesCopy, function()
            handler(data.reward)
        end)

        if data.reward and ((data.reward.equips and #data.reward.equips > 0) 
            or (data.reward.items and #data.reward.items > 0)) then
            -- 首充礼包状态
            require("data.activity").pay()
            -- track payment
            local money = 0
            local cfgstore = require "config.store"
            for _, id in ipairs(params.id) do
                money = money + cfgstore[id].price
            end
            if money > 0 then
                iap.track(money)
            end
        end
    end)
end

-- 从store表中找到对应的id
function iap.convertId(productId)
    local cfgstore = require "config.store"
    for id, cfg in ipairs(cfgstore) do
        if cfg.payId == productId then
            return id
        end
    end
    return nil
end

-- 支付上报
function iap.track(money)
    if APP_CHANNEL and APP_CHANNEL == "LT" then return end
    if DHPayment:getInstance():isReleasePayment() then
        HHUtils:trackPaymentFacebook(tonumber(money), "USD")
        --HHUtils:trackPaymentAppLovin(tonumber(money), "USD")
        --HHUtils:trackPaymentAppsFlyer(tonumber(money), "USD")
    end
end

return iap
