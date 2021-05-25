local data = {}

data.appstore_productid = nil

function data.onAppStore(productid)
    print("get appstore_productid:", productid)
    if not productid or productid == "" then
        return
    end
    data.appstore_productid = productid
    --data.payAppStore()
end

function data.payAppStore()
    print("call payAppStore")
    if not data.appstore_productid then
        return
    end
    local cfgstore = require "config.store"
    local shopData = require "data.shop"
    local pos = 0
    -- 是否已购买月卡
    -- 是否订阅中
    if data.appstore_productid == cfgstore[6].payId then  -- mcard
        pos = 6
        if shopData.pay and shopData.pay[6] ~= 0 then
            showToast("you have already purchased crazy gift package")
            return
        end
    elseif data.appstore_productid == cfgstore[32].payId then  -- minicard
        pos = 32
        if shopData.pay and shopData.pay[32] ~= 0 then
            showToast("you have already purchased mini crazy gift package")
            return
        end
    elseif data.appstore_productid == cfgstore[33].payId then  -- subscribe
        pos = 33
        if shopData.pay and shopData.pay[33] ~= 0 then
            showToast("you have already subscribed weekly extra gold")
            return
        end
    end
    -- goto pay
    local waitnet = addWaitNet()
    waitnet.setTimeout(120)
    require("common.iap").pay(data.appstore_productid, function(conquest)
        delWaitNet()
        if conquest then
            shopData.setPay(pos, 1)
            if pos == 33 then
                shopData.addSubHead()
            end
            require("data.bag").addRewards(conquest)
            local rewards = require "ui.reward"
            CCDirector:sharedDirector():getRunningScene():addChild(rewards.createFloating(conquest), 100000)
        end
    end)
end

function data.checkAppStore()
    if require("data.tutorial").exists() then
        --认为有教程进行中
        return
    end
    if DHPayment:getInstance().listenAppStore then
        DHPayment:getInstance():listenAppStore(data.onAppStore)
    end
end

return data
