-- 月礼包

local ui = {}

require "common.const"
require "common.func"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local audio = require "res.audio"
local i18n = require "res.i18n"
local cfgstore = require "config.store"
local activitydata = require "data.activity"

function ui.create()
    local layer = CCLayer:create()

    local status = ui.getActivityStatus()
    local cfgs, cfgsInStore = ui.getConfigs(status)

    img.unload(img.packedOthers.ui_activity_weekly_gift)
    img.unload(img.packedOthers.ui_activity_weekly_gift_cn)
    if i18n.getCurrentLanguage() == kLanguageChinese then
        img.load(img.packedOthers.ui_activity_weekly_gift_cn)
    else
        img.load(img.packedOthers.ui_activity_weekly_gift)
    end

    -- bg
    local bg
    if i18n.getCurrentLanguage() == kLanguageKorean then
        bg = img.createUISprite("activity_monthly_gift_kr.png")
    elseif i18n.getCurrentLanguage() == kLanguageChineseTW then
        bg = img.createUISprite("activity_monthly_gift_tw.png")
    elseif i18n.getCurrentLanguage() == kLanguageJapanese then
        bg = img.createUISprite("activity_monthly_gift_jp.png")
    elseif i18n.getCurrentLanguage() == kLanguageRussian then
        bg = img.createUISprite("activity_monthly_gift_ru.png")
    else
        bg = img.createUISprite(img.ui.activity_monthly_gift)
    end
    bg:setScale(view.minScale)
    bg:setPosition(scalep(638, 413))
    layer:addChild(bg)

    -- cd
    local cdContainer = CCSprite:create()
    cdContainer:setScale(view.minScale)
    cdContainer:setAnchorPoint(ccp(1, 0.5))
    cdContainer:setPosition(scalep(906, 361))
    layer:addChild(cdContainer)
    local cdText = lbl.createFont2(16, i18n.global.activity_reset_in.string, lbl.whiteColor)
    cdText:setAnchorPoint(ccp(0, 0.5))
    cdText:setPosition(0, 5)
    cdContainer:addChild(cdText)
    local cdClock = lbl.createFont2(16, "000:00:00", ccc3(0xbd, 0xf6, 0x44))
    cdClock:setAnchorPoint(ccp(0, 0.5))
    cdClock:setPosition(cdText:boundingBox():getMaxX()+10, 5)
    cdContainer:addChild(cdClock)
    cdContainer:setContentSize(CCSize(cdClock:boundingBox():getMaxX(), 10))

    -- scroll
    local VIEW_W, VIEW_H = 564, 276
    local scroll = CCScrollView:create()
    scroll:ignoreAnchorPointForPosition(false)
    scroll:setDirection(kCCScrollViewDirectionVertical)
    scroll:setViewSize(CCSize(VIEW_W, VIEW_H))
    scroll:setScale(view.minScale)
    scroll:setPosition(scalep(638, 197))
    layer:addChild(scroll)
    --drawBoundingbox(layer, scroll)

    local BOX_W, BOX_H = 542, 92
    local container = CCLayer:create()
    local currentY
    for i, st in ipairs(status) do
        local cfg, cfgInStore = cfgs[i], cfgsInStore[i]
        -- box 
        local x, y = VIEW_W/2, -3-(i-1)*(BOX_H+1)
        local box = img.createUI9Sprite(img.ui.bottom_border_2)
        box:setPreferredSize(CCSize(BOX_W, BOX_H))
        box:setAnchorPoint(ccp(0.5, 1))
        box:setPosition(x, y)
        container:addChild(box)
        currentY = box:boundingBox():getMinY()

        -- icons
        ui.addRewardIcons(layer, container, cfg.rewards, 57, y-44, 60)

        -- limit
        local limitLabel
        if st.limits > 0 then
            limitLabel = lbl.createFont1(14, i18n.global.limitact_limit.string .. st.limits, ccc3(0x73, 0x3b, 0x05))
            limitLabel:setPosition(468, y-19)
            container:addChild(limitLabel)
        end
    
        -- exp
        local expText = lbl.createFont1(14, "VIP EXP", ccc3(0x73, 0x3b, 0x05))
        expText:setPosition(337, y-33)
        container:addChild(expText)
        local expLabel = lbl.createFont1(20, "+" .. cfgInStore.vipExp, ccc3(0x9c, 0x45, 0x2d))
        expLabel:setPosition(337, y-55)
        container:addChild(expLabel)

        -- buyBtn
        local buyBtn0 = img.createLogin9Sprite(img.login.button_9_small_gold)
        buyBtn0:setPreferredSize(CCSize(128, 46))
        local buyBtn = SpineMenuItem:create(json.ui.button, buyBtn0)
        buyBtn:setPosition(468, y-52)
        local buyBtnLbl = lbl.createFontTTF(16, ui.getPrice(cfgInStore, st.id), ccc3(0x73, 0x3b, 0x05))
        buyBtnLbl:setPosition(136/2, 46/2)
        buyBtn0:addChild(buyBtnLbl)
        local buyMenu = CCMenu:createWithItem(buyBtn)
        buyMenu:setPosition(0, 0)
        container:addChild(buyMenu)
        if st.limits <= 0 then
            setShader(buyBtn, SHADER_GRAY, true)
            buyBtn:setEnabled(false)
        end
        buyBtn:registerScriptTapHandler(function()
            audio.play(audio.button)
            addWaitNet().setTimeout(60)
            require("common.iap").pay(cfgInStore.payId, function(reward)
                delWaitNet()
                if reward then
                    require("data.bag").addRewards(reward)
                    st.limits = st.limits - 1
                    if st.limits <= 0 then
                        setShader(buyBtn, SHADER_GRAY, true)
                        buyBtn:setEnabled(false)
                        limitLabel:setVisible(false)
                    else
                        limitLabel:setString("LIMIT: " .. st.limits)
                    end
                    local rw = tablecp(reward)
                    arrayfilter(rw.items, function(t)
                        return t.id ~= ITEM_ID_VIP_EXP
                    end)
                    layer:addChild(require("ui.reward").createFloating(rw), 1000)
                end
            end)
        end)
    end

    -- scroll content height
    local height = -currentY + 3 
    if height < VIEW_H then
        height = VIEW_H 
    end
    container:setPosition(0, height)
    scroll:setContentSize(CCSize(VIEW_W, height))
    scroll:addChild(container)
    scroll:setContentOffset(ccp(0, VIEW_H-height))

    local function onUpdate(ticks)
        if status[1] and (cdClock.cd == nil or cdClock.cd > 0) then
            local cd = status[1].cd - (os.time() - activitydata.pull_time) 
            if cd < 0 then            
                cd = 0   
            end
            if cdClock.cd ~= cd then
                cdClock.cd = cd    
                cdClock:setString(time2string(cd))
            end
        end
    end
    layer:scheduleUpdateWithPriorityLua(onUpdate, 0)

    require("ui.activity.ban").addBan(layer, scroll)
    layer:setTouchSwallowEnabled(false)

    return layer
end

local ids = {}
function ui.getAllIds()
    if #ids == 0 then
        for k, v in pairs(activitydata.IDS) do
            if k:beginwith("MONTHLY_GIFT") then
                ids[#ids+1] = v.ID
            end
        end
    end
    return ids
end

function ui.getActivityStatus()
    local all = {}
    for _, id in ipairs(ui.getAllIds()) do
        local status = activitydata.getStatusById(id)
        if status then
            status.read = 1
            all[#all+1] = status
        end
    end
    table.sort(all, function(a, b)
        if a.limits > 0 and b.limits <= 0 then
            return true
        elseif a.limits <= 0 and b.limits > 0 then
            return false
        else
            return a.id < b.id
        end
    end)
    return all
end

function ui.showRedDot()
    for _, id in ipairs(ui.getAllIds()) do
        local status = activitydata.getStatusById(id)
        if status and status.limits > 0 and status.read == 0 then
            return true
        end
    end
    return false
end

function ui.getPrice(configInStore)
    local cfgprice = configInStore.priceStr
    if isAmazon() then
    elseif APP_CHANNEL and APP_CHANNEL ~= "" then
        cfgprice = configInStore.priceCnStr
    elseif i18n.getCurrentLanguage() == kLanguageChinese then
        cfgprice = configInStore.priceCnStr
    end
    local shopData = require"data.shop"
    cfgprice = shopData.getPriceByPayId(configInStore.payId, cfgprice)
    return cfgprice
end

function ui.getConfigs(status)
    local cfgInActivity, cfgInStore = {}, {}
    for _, s in ipairs(status) do
        cfgInActivity[#cfgInActivity+1] = s.cfg
        for _, cfg in pairs(cfgstore) do
            if cfg.activity == s.id then
                cfgInStore[#cfgInStore+1] = cfg 
                break
            end
        end
    end
    return cfgInActivity, cfgInStore
end

function ui.addRewardIcons(layer, container, rewards, x, y, offset)
    for i, r in ipairs(rewards) do
        local t = { id = r.id, num = r.num }
        local icon
        if r.type == 1 then
            icon = img.createItem(t.id, t.num)
        else
            icon = img.createEquip(t.id, t.num)
        end
        icon:setCascadeOpacityEnabled(true)
        local btn = SpineMenuItem:create(json.ui.button, icon)
        btn:setScale(0.65)
        btn:setCascadeOpacityEnabled(true)
        btn:setPosition(x+(i-1)*offset, y)
        local menu = CCMenu:createWithItem(btn)
        menu:setPosition(0, 0)
        menu:setCascadeOpacityEnabled(true)
        container:addChild(menu)
        btn:registerScriptTapHandler(function()
            audio.play(audio.button)
            if r.type == 1 then
                layer:addChild(require("ui.tips.item").createForShow(t), 1000)
            else
                layer:addChild(require("ui.tips.equip").createForShow(t), 1000)
            end
        end)
    end
end

return ui
