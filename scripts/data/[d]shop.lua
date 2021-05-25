-- gacha infos

local shop = {}
local cjson = json

require "common.const"
require "common.func"

local isread6 = false
local isread32 = false

function shop.init(pay)
    if pay then
        tbl2string(pay)
        shop.pay = pay 
    end
    if device.platform ~= "android" then return end
    if APP_CHANNEL and APP_CHANNEL ~= "" then return end
    --shop.getSkus()
end

local skuDetails = {}
local did_getSku = false

local function coupSkuArray(skuArray)
    if not skuArray or #skuArray==0 then return end
    for ii=1,#skuArray do
        skuDetails[skuArray[ii].mSku] = clone(skuArray[ii])
    end
    local cfgstore = require "config.store"
    skuDetails["com.droidhang.ad.diamond36"] = {mPrice = cfgstore[33].priceStr}
    if skuDetails["com.droidhang.ad.diamond2"] then
        local _sku = skuDetails["com.droidhang.ad.diamond2"]
        local mPrice = _sku.mPrice
        if not mPrice or mPrice == "" then return end
        for _, _v in ipairs({9,14,16,27,33}) do
            skuDetails["com.droidhang.ad.diamond" .. _v] = {mPrice = mPrice}
        end
    end
    if skuDetails["com.droidhang.ad.diamond3"] then
        local _sku = skuDetails["com.droidhang.ad.diamond3"]
        local mPrice = _sku.mPrice
        if not mPrice or mPrice == "" then return end
        for _, _v in ipairs({10,13,15,17,23,28,35}) do
            skuDetails["com.droidhang.ad.diamond" .. _v] = {mPrice = mPrice}
        end
        -- subs
        local npos = string.find(mPrice, "[0-9.]")
        if not npos then return end
        local price_num = string.sub(mPrice, npos, -1)
        local price_str = string.sub(mPrice, 1, npos-1)
        if not price_num or not price_str then return end
        skuDetails["com.droidhang.ad.diamond36"].mPrice = price_str .. (price_num/10)
    end
    if skuDetails["com.droidhang.ad.diamond4"] then
        local _sku = skuDetails["com.droidhang.ad.diamond4"]
        local mPrice = _sku.mPrice
        if not mPrice or mPrice == "" then return end
        for _, _v in ipairs({18,24}) do
            skuDetails["com.droidhang.ad.diamond" .. _v] = {mPrice = mPrice}
        end
    end
    if skuDetails["com.droidhang.ad.diamond5"] then
        local _sku = skuDetails["com.droidhang.ad.diamond5"]
        local mPrice = _sku.mPrice
        if not mPrice or mPrice == "" then return end
        for _, _v in ipairs({12,20,25,30}) do
            skuDetails["com.droidhang.ad.diamond" .. _v] = {mPrice = mPrice}
        end
    end
    if skuDetails["com.droidhang.ad.diamond6"] then
        local _sku = skuDetails["com.droidhang.ad.diamond6"]
        local mPrice = _sku.mPrice
        if not mPrice or mPrice == "" then return end
        for _, _v in ipairs({22,32}) do
            skuDetails["com.droidhang.ad.diamond" .. _v] = {mPrice = mPrice}
        end
    end
    if skuDetails["com.droidhang.ad.diamond11"] then
        local _sku = skuDetails["com.droidhang.ad.diamond11"]
        local mPrice = _sku.mPrice
        if not mPrice or mPrice == "" then return end
        for _, _v in ipairs({19,29}) do
            skuDetails["com.droidhang.ad.diamond" .. _v] = {mPrice = mPrice}
        end
    end
    if skuDetails["com.droidhang.ad.diamond21"] then
        local _sku = skuDetails["com.droidhang.ad.diamond21"]
        local mPrice = _sku.mPrice
        if not mPrice or mPrice == "" then return end
        for _, _v in ipairs({26,31}) do
            skuDetails["com.droidhang.ad.diamond" .. _v] = {mPrice = mPrice}
        end
    end
end

local function dhGetSkuDetail(itemType, skus, skuHandler, isFinal)
    DHPayment:getInstance():getSkuDetails(itemType, skus, function(status, __data)
        if not status or status ~= "0" then
            return
        end
        local skuArray = cjson.decode(__data)
        if skuHandler then
            skuHandler(skuArray)
        end
    end)
end

function shop.getSkus()
    if did_getSku then return end
    did_getSku = true
    local sku_ids = {2,3,4,5,6,7,8,11,21}
    local skus1 = {}
    for ii=1,#sku_ids do
        skus1[#skus1+1] = "com.droidhang.ad.diamond" .. sku_ids[ii]
    end
    --local skus2 = {}
    --for ii=21,35 do
    --    skus2[#skus2+1] = "com.droidhang.ad.diamond" .. ii
    --end
    --local skus3 = {}
    --for ii=36,36 do
    --    skus3[#skus3+1] = "com.droidhang.ad.diamond" .. ii
    --end
    if DHPayment.getSkuDetails then
        DHPayment:getInstance():getSkuDetails("inapp", cjson.encode(skus1), function(status, __data)
            if not status or status ~= "0" then
                return
            end
            local skuArray = cjson.decode(__data)
            coupSkuArray(skuArray)
        end)
        --schedule(CCDirector:sharedDirector():getRunningScene(), 3, function()
        --    DHPayment:getInstance():getSkuDetails("inapp", cjson.encode(skus2), function(status, __data)
        --        if not status or status ~= "0" then
        --            return
        --        end
        --        local skuArray = cjson.decode(__data)
        --        coupSkuArray(skuArray)
        --    end)
        --end)
        --schedule(CCDirector:sharedDirector():getRunningScene(), 6, function()
        --    DHPayment:getInstance():getSkuDetails("subs", cjson.encode(skus3), function(status, __data)
        --        if not status or status ~= "0" then
        --            return
        --        end
        --        local skuArray = cjson.decode(__data)
        --        coupSkuArray(skuArray)
        --    end)
        --end)
    end
end

function shop.getPrice(pid, default)
    if device.platform ~= "android" then return default end
    if APP_CHANNEL and APP_CHANNEL ~= "" then return default end
    local cfgstore = require "config.store"
    if not cfgstore[pid] then return default end
    if not skuDetails[cfgstore[pid].payId] then return default end
    return skuDetails[cfgstore[pid].payId].mPrice or default
end

function shop.getPriceByPayId(payId, default)
    if device.platform ~= "android" then return default end
    if APP_CHANNEL and APP_CHANNEL ~= "" then return default end
    if not skuDetails[payId] then return default end
    return skuDetails[payId].mPrice or default
end

function shop.showRedDot()
    if not isread6 and shop.pay[6] and shop.pay[6] == 0 then
        return true
    end
    return false
end

function shop.showRedDot2()
    if not isread32 and shop.pay[32] == 0 then
        return true
    end
    return false
end

function shop.read6()
    isread6 = true
end

function shop.read32()
    isread32 = true
end

function shop.showSub()
    if not APP_CHANNEL or APP_CHANNEL == "" then
        return true
    end
    return false
end

function shop.setPay(pos, value)
    value = value or 1
    if not shop.pay then
        shop.pay = {}
    end
    shop.pay[pos] = value
end

function shop.addSubHead()
    local bag = require"data.bag"
    bag.items.add({id=ITEM_ID_SP_SUB, num=10})
end

function shop.print()
    print("--------- shop --------- {")
    print("pay:", shop.pay)
    print("--------- shop --------- }")
end

return shop
