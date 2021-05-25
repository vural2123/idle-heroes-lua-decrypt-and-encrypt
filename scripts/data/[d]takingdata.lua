local m = {}

local function isSupport()
    if not APP_CHANNEL or APP_CHANNEL == "" then
        return false
    else
        local sdkcfg = require"common/sdkcfg"
        if not sdkcfg[APP_CHANNEL] then
            return false
        elseif sdkcfg[APP_CHANNEL].support_takingdata then
            return true
        else
            return false
        end
    end
    return false
end

function m.statAccount(_type, paramStr)
    if not isSupport() then
        return
    end
    HHUtils:statAccount(_type, paramStr)
end

function m.onChargeReq(orderId, iapId, currencyAmount, currencyType, virtualCurrencyAmount, paymentType)
    if not isSupport() then
        return
    end
    orderId = orderId or ""
    iapId = iapId or ""
    currencyAmount = "" .. (currencyAmount or "0")
    currencyAmount = math.floor(currencyAmount)
    currencyType = "CNY"
    virtualCurrencyAmount = 0
    paymentType = "third"
    HHUtils:onChargeReq(orderId, iapId, currencyAmount, currencyType, virtualCurrencyAmount, paymentType)
end

function m.onChargeSuc(orderId)
    if not isSupport() then
        return
    end
    orderId = orderId or ""
    HHUtils:onChargeSuc(orderId)
end

function m.statAccount(_type, paramStr)
    if not isSupport() then
        return
    end
    HHUtils:statAccount(_type, paramStr)
end

function m.onCustom(paramStr)
    if not isSupport() then
        return
    end
    HHUtils:onCustom(paramStr)
end


function m.onVirtual(num, event)
    if not isSupport() then
        return
    end
    HHUtils:onVirtual(num, event)
end

function m.onMission(mission, way)
    if not isSupport() then
        return
    end
    HHUtils:onMission(mission, way)
end

function m.onItem(num, price, name)
    if not isSupport() then
        return
    end
    HHUtils:onItem(num, price, name)
end

return m
