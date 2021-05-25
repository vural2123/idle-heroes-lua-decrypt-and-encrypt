--
-- Created by IntelliJ IDEA.
-- User: Kunkka
-- Date: 5/12/17
-- Time: 13:46
-- To change this template use File | Settings | File Templates.
--

local sdk = {}

function sdk:login_hw(callback)
    print("lua start login")
    -- hw
    SDKHelper:getInstance():login("", function(str)
        print(str)
        local ret = json.decode(str)
        if ret.errcode and ret.errcode == 0 then
            local appId = ret.appId
            local ts = ret.ts
            local playerId = ret.playerId
            local sign = ret.sign
            local playerId = ret.playerId
            -- TODO:
            -- verify through server
            callback(true)
        else
            -- fail
            callback(false)
        end
    end)
end

function sdk:login_uc(callback)
    print("lua start login")
    SDKHelper:getInstance():login("", function(str)
        print(str)
        local ret = json.decode(str)
        if ret.errcode and ret.errcode == 0 then
            local sid = ret.sid
            -- TODO:
            -- verify through server
            callback(true)
        else
            -- fail
            callback(false)
        end
    end)
end

function sdk:pay_hw(callback)
    print("lua start pay")
    -- hw
    local params = {
        price = 0.01,
        productName = "sb",
        productDesc = "sxxx",
        requestId = "xxxyyy",
        sign = "omg",
    }
    SDKHelper:getInstance():pay(json.encode(params), function(str)
        print(str)
        local ret = json.decode(str)
        if ret.errcode and ret.errcode == 0 then
            local sign = ret.sign
            local noSigna = ret.noSigna
            -- TODO:
            -- verify through server

            callback(true)
        else
            -- fail
            callback(false)
        end
    end)
end

function sdk:pay_uc(callback)
    print("lua start pay")
    -- hw
    local params = {
        price = 0.01,
        callback_info = "sb",
        notify_url = "sxxx",
        order_id = "order_id",
        account_id = "account_id",
        signType = "signType",
        sign = "omg",
    }
    SDKHelper:getInstance():pay(json.encode(params), function(str)
        print(str)
        local ret = json.decode(str)
        if ret.errcode and ret.errcode == 0 then
            local orderId = ret.orderId
            local orderAmount = ret.orderAmount
            local payWay = ret.payWay
            -- TODO:
            -- verify through server

            callback(true)
        else
            -- fail
            callback(false)
        end
    end)
end

function sdk:exitGame(callback)
    print("lua exitGame")
end

return sdk