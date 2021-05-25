-- reward animation

local reward = {}

require "common.func"
local view = require "common.view"
local img = require "res.img"
local json = require "res.json"
local lbl = require "res.lbl"
local i18n = require "res.i18n"
local audio = require "res.audio"
local cfgitem = require "config.item"
local cfgequip = require "config.equip"
local tipsequip = require "ui.tips.equip"
local tipsitem = require "ui.tips.item"

--[[
local param =  {
    count = 1,
    callback = func,
}
--]]

function reward.showRewardForbraveBox(pbbag)
    local layer = reward.createLayer()    
    -- local title1 = reward.setTitle(i18n.global.reward_will_get.string)
    -- layer.aniReward:addChildFollowSlot("code_reward_text", title1)
    -- local title2 = reward.setTitle(i18n.global.reward_will_get.string)
    -- layer.aniReward:addChildFollowSlot("code_reward_text2", title2)
    local title 
    if i18n.getCurrentLanguage() == kLanguageChinese then
        title = img.createUISprite(img.ui.language_reward_cn)
    elseif i18n.getCurrentLanguage() == kLanguageEnglish then
        title = img.createUISprite(img.ui.language_reward_us)
    else
        title = lbl.createFont2(36, i18n.global.reward_will_get.string)
    end
    layer.aniReward:addChildFollowSlot("code_reward_text", title)
    
    schedule(layer, 1, function()
        layer.confirmBtn:setVisible(true)
    end)

    json.load(json.ui.reward_particle)
    local aniRewardTitle = DHSkeletonAnimation:createWithKey(json.ui.reward_particle)
    aniRewardTitle:setScale(view.minScale)
    aniRewardTitle:scheduleUpdateLua()
    aniRewardTitle:playAnimation("play", -1)
    aniRewardTitle:setPosition(scalep(480, 288))
    layer:addChild(aniRewardTitle)
    
    --local pbbag = {}
    --local equips = {}
    --local items = {}
    --pbbag.equips = equips
    --pbbag.items = items
    --for i=1,#pbbag.equips do
    --    local eq = pbbag.equips[i]
    --    equips[#equips+1] = eq
    --end
    --for i=1,#pbbag.items do
    --    local item = pbbag.items[i]
    --    items[#items+1] = item
    --end
    
    local itemslayer = reward.showItems(pbbag)
    layer:addChild(itemslayer,1)
    
    return layer
end

-- 神器升至满级提示
function reward.showRewardFortreasure(eq)
    local layer = reward.createLayer()    
    -- local title1 = reward.setTitle(i18n.global.treasure_levelup_full.string)
    -- layer.aniReward:addChildFollowSlot("code_reward_text", title1)
    -- local title2 = reward.setTitle(i18n.global.treasure_levelup_full.string)
    -- layer.aniReward:addChildFollowSlot("code_reward_text2", title2)

    local title 
    if i18n.getCurrentLanguage() == kLanguageChinese then
        title = img.createUISprite(img.ui.language_reward_cn)
    elseif i18n.getCurrentLanguage() == kLanguageEnglish then
        title = img.createUISprite(img.ui.language_reward_us)
    else
        title = lbl.createFont2(36, i18n.global.reward_will_get.string)
    end
    layer.aniReward:addChildFollowSlot("code_reward_text", title)
    
    schedule(layer, 1, function()
        layer.confirmBtn:setVisible(true)
    end)

    json.load(json.ui.reward_particle)
    local aniRewardTitle = DHSkeletonAnimation:createWithKey(json.ui.reward_particle)
    aniRewardTitle:setScale(view.minScale)
    aniRewardTitle:scheduleUpdateLua()
    aniRewardTitle:playAnimation("play", -1)
    aniRewardTitle:setPosition(scalep(480, 288))
    layer:addChild(aniRewardTitle)
    
    local pbbag = {}
    local equips = {}
    local items = {}
    pbbag.equips = equips
    equips[#equips+1] = eq
    
    local itemslayer = reward.showItems(pbbag)
    layer:addChild(itemslayer,1)
    
    return layer
end

-- param为赌场奖励再抽一次的信息
function reward.showReward(pbbag, param, up, speedMult)
    local layer = reward.createLayer()    
	
	if not speedMult then speedMult = 1 end

    -- local title1 = reward.setTitle(i18n.global.reward_will_get.string)
    -- layer.aniReward:addChildFollowSlot("code_reward_text", title1)
    -- local title2 = reward.setTitle(i18n.global.reward_will_get.string)
    -- layer.aniReward:addChildFollowSlot("code_reward_text2", title2)

    local title 
    if i18n.getCurrentLanguage() == kLanguageChinese then
        title = img.createUISprite(img.ui.language_reward_cn)
    elseif i18n.getCurrentLanguage() == kLanguageEnglish then
        title = img.createUISprite(img.ui.language_reward_us)
    else
        title = lbl.createFont2(36, i18n.global.reward_will_get.string)
    end
    layer.aniReward:addChildFollowSlot("code_reward_text", title)
    title:setPositionX(4)

    json.load(json.ui.reward_particle)
    local aniRewardTitle = DHSkeletonAnimation:createWithKey(json.ui.reward_particle)
    aniRewardTitle:setScale(view.minScale)
    aniRewardTitle:scheduleUpdateLua()
    aniRewardTitle:playAnimation("play", -1)
    aniRewardTitle:setPosition(scalep(480, 288))
    layer:addChild(aniRewardTitle)

    local itemslayer = reward.showItems(pbbag, speedMult)
    layer:addChild(itemslayer,1)

    -- 1=0.6s 10 = 3s
    local allnum = 0
    if pbbag.items then
        allnum = allnum + #pbbag.items
    end
    if pbbag.equips then
        allnum = allnum + #pbbag.equips
    end

    local time = (0.3 + 0.2 * allnum) / speedMult
    
    if param then
        local times = i18n.global.casino_btn_10time.string
        if param and param.count == 1 then
            --time = 0.6
            times = i18n.global.casino_btn_1time.string
        end

        local casino1 = img.createUI9Sprite(img.ui.btn_1)
        casino1:setPreferredSize(CCSizeMake(172,72))
        local casinoLab = lbl.createFont1(18, times, ccc3(0x73, 0x3b, 0x05))
        casinoLab:setPosition(CCPoint(casino1:getContentSize().width/2+20, 
                                        casino1:getContentSize().height/2-2))
        casino1:addChild(casinoLab)
        local casinoBtn = SpineMenuItem:create(json.ui.button, casino1)
        casinoBtn:setScale(view.minScale)
        casinoBtn:setPosition(scalep(960/2+130, 576-496))
        casinoBtn:setVisible(false)
        layer.casinoBtn = casinoBtn
        
        local casinoMenu = CCMenu:createWithItem(casinoBtn)
        casinoMenu:setPosition(0, 0)
        layer:addChild(casinoMenu)

        local costLab = lbl.createFont2(16, tostring(param.count), ccc3(255, 246, 223))
        costLab:setPosition(CCPoint(41, 28))
        casino1:addChild(costLab, 2)

        -- icon1
        local icon1 = nil
        if up then
            icon1 = img.createItemIcon(ITEM_ID_ADVANCED_CHIP)
        else
            icon1 = img.createItemIcon(ITEM_ID_CHIP)
        end
        icon1:setScale(0.5)
        icon1:setPosition(CCPoint(41, 36))
        casino1:addChild(icon1)

        casinoBtn:registerScriptTapHandler(function()
            audio.play(audio.button)
            layer:removeFromParentAndCleanup(true)
            param.callback()
        end)

        layer.confirmBtn:setPosition(scalep(960/2-130, 576-496))
    end

    schedule(layer, time, function()
        layer.confirmBtn:setVisible(true)
        if param then
            layer.casinoBtn:setVisible(true)
        end    
    end)

    return layer
end

function reward.showItems(pbbag, speedMult)
    local layer = CCLayer:create()
	
	if not speedMult then speedMult = 1 end

    local gridWidth = 102 
    local function getPosition(i, rewardNum)
        if rewardNum <= 5 then
            y = 576-295
        elseif i <= 5 then
            y = 576-245
        else
            y = 576-352
        end

        if rewardNum%5 == 0 then
            x = 278
        elseif rewardNum%5 == 4 then
            x = 278 + gridWidth/2
        elseif rewardNum%5 == 3 then
            x = 278 + gridWidth
        elseif rewardNum%5 == 2 then
            x = 278 + gridWidth*3/2
        elseif rewardNum%5 == 1  then
            x = 278 + gridWidth*2
        end
        x = x + gridWidth*((i-1)%5)
        return x, y
    end
   
    local icons = {}
    local cur = 1
    local time = 0.2
    layer.tipsTag = false
    layer.allnum = 0
    if pbbag.items then
        layer.allnum = layer.allnum + #pbbag.items
    end
    if pbbag.equips then
        layer.allnum = layer.allnum + #pbbag.equips
    end
    if pbbag.equips then
        for i, pb in ipairs(pbbag.equips) do
            schedule(layer, time / speedMult, function()
                local x, y = getPosition(cur, layer.allnum)
                json.load(json.ui.equip_in)
                local aniEquipin = DHSkeletonAnimation:createWithKey(json.ui.equip_in)
                aniEquipin:setScale(view.minScale)
                aniEquipin:scheduleUpdateLua()
                aniEquipin:setPosition(scalep(x, y))
				aniEquipin:setTimeScale(speedMult)
                layer:addChild(aniEquipin)
                if pb.cool then
                    audio.play(audio.casino_get_nb)
                    aniEquipin:playAnimation("good")

                    schedule(layer ,1.5 / speedMult , function()
                        aniEquipin:playAnimation("loop", -1) 
                    end)
                else
                    audio.play(audio.casino_get_common)
                    aniEquipin:playAnimation("normal")
                end
                local icon = img.createEquip(pb.id, pb.num)
                icons[cur] = CCMenuItemSprite:create(icon, nil)
                icons[cur].menu = CCMenu:createWithItem(icons[cur])
                icons[cur].menu:ignoreAnchorPointForPosition(false)
                aniEquipin:addChildFollowSlot("code_equip", icons[cur].menu)

                icons[cur]:registerScriptTapHandler(function()
                    if not layer.tipsTag then
                        layer.tipsTag = true
                        layer.tips = tipsequip.createForShow(pb)
                        layer:addChild(layer.tips, 100)
                        layer.tips.setClickBlankHandler(function()
                            layer.tips:removeFromParent()
                            layer.tipsTag = false
                        end)
                    end
                end)
                cur = cur + 1
            end)
            if pb.cool then
                time = time + 0.66
            else
                time = time + 0.2
            end
        end 
    end
    if pbbag.items then
        for i, pb in ipairs(pbbag.items) do
            schedule(layer, time / speedMult, function()
                local x, y = getPosition(cur, layer.allnum)
                json.load(json.ui.equip_in)
                local aniEquipin = DHSkeletonAnimation:createWithKey(json.ui.equip_in)
                aniEquipin:setScale(view.minScale)
                aniEquipin:scheduleUpdateLua()
                aniEquipin:setPosition(scalep(x, y))
				aniEquipin:setTimeScale(speedMult)
                layer:addChild(aniEquipin)
                if pb.cool then
                    audio.play(audio.casino_get_nb)
                    aniEquipin:playAnimation("good")
                    schedule(layer ,1.5 / speedMult , function()
                        aniEquipin:playAnimation("loop", -1) 
                    end)
                else
                    audio.play(audio.casino_get_common)
                    aniEquipin:playAnimation("normal")
                end
                local icon = img.createItem(pb.id, pb.num)
                icons[cur] = CCMenuItemSprite:create(icon, nil)
                icons[cur].menu = CCMenu:createWithItem(icons[cur])
                icons[cur].menu:ignoreAnchorPointForPosition(false)
                aniEquipin:addChildFollowSlot("code_equip", icons[cur].menu)
                icons[cur]:registerScriptTapHandler(function()
                    if not layer.tipsTag then
                        layer.tipsTag = true
                        layer.tips = tipsitem.createForShow(pb)
                        layer:addChild(layer.tips, 100)
                        layer.tips.setClickBlankHandler(function()
                            layer.tips:removeFromParent()
                            layer.tipsTag = false
                        end)
                    end
                end)
                cur = cur + 1
            end)
            if pb.cool then
                time = time + 0.66
            else
                time = time + 0.2
            end
        end
    end
    
    return layer
end


function reward.createRewardForSmith1(equip)
    local layer = reward.createLayer()
    layer.tipsTag = false
    schedule(layer, 1, function()
        layer.confirmBtn:setVisible(true)
    end)

    json.load(json.ui.reward_particle)
    local aniRewardTitle = DHSkeletonAnimation:createWithKey(json.ui.reward_particle)
    aniRewardTitle:setScale(view.minScale)
    aniRewardTitle:scheduleUpdateLua()
    aniRewardTitle:playAnimation("play", -1)
    aniRewardTitle:setPosition(scalep(480, 288))
    layer:addChild(aniRewardTitle)
    
    local title1 = reward.setTitle(i18n.global.reward_successful.string)
    layer.aniReward:addChildFollowSlot("code_reward_text", title1)
    local title2 = reward.setTitle(i18n.global.reward_successful.string)
    layer.aniReward:addChildFollowSlot("code_reward_text2", title2)

    schedule(layer, 0.4, function()
        json.load(json.ui.equip_in)
        local aniEquipin = DHSkeletonAnimation:createWithKey(json.ui.equip_in)
        aniEquipin:setScale(view.minScale)
        aniEquipin:scheduleUpdateLua()
        aniEquipin:setPosition(scalep(480, 576-275))
        layer:addChild(aniEquipin)
        if cfgequip[equip.id].qlt >= 5 then
            aniEquipin:playAnimation("good")
            schedule(layer ,1.5 , function()
                aniEquipin:playAnimation("loop", -1) 
            end)
        else
            aniEquipin:playAnimation("normal")
        end
        local icon = img.createEquip(equip.id, equip.num)
        local iconBtn = CCMenuItemSprite:create(icon, nil)
        --iconBtn:setScale(view.minScale) 
        --iconBtn:setPosition(scalep(480, 576-275))
        local iconMenu = CCMenu:createWithItem(iconBtn)
        --iconMenu:setPosition(0, 0)
        --layer:addChild(iconMenu)
        iconMenu:ignoreAnchorPointForPosition(false)
        aniEquipin:addChildFollowSlot("code_equip", iconMenu)
        iconBtn:registerScriptTapHandler(function()
            if not layer.tipsTag then
                layer.tipsTag = true
                layer.tips = tipsequip.createForShow(equip)
                layer:addChild(layer.tips, 100)
                layer.tips.setClickBlankHandler(function()
                    layer.tips:removeFromParent()
                    layer.tipsTag = false
                end)
            end
        end)
    end)
    return layer
end

function reward.createLayer()
    local layer = CCLayer:create()
    
    --dark bg
    local darkbg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    layer:addChild(darkbg)
    
    img.load(img.packedOthers.spine_ui_blacksmith_1)
    img.load(img.packedOthers.spine_ui_blacksmith_2)
    json.load(json.ui.reward)
    local aniReward = DHSkeletonAnimation:createWithKey(json.ui.reward)
    aniReward:setScale(view.minScale)
    aniReward:scheduleUpdateLua()
    aniReward:playAnimation("reward")
    aniReward:setPosition(scalep(480, 288))
    layer.aniReward = aniReward
    layer:addChild(aniReward)

    local lefFrame = img.createUISprite(img.ui.reward_frame)
    aniReward:addChildFollowSlot("code_reward_01_2_left", lefFrame)
    local rigFrame = img.createUISprite(img.ui.reward_frame)
    aniReward:addChildFollowSlot("code_reward_01_2_right", rigFrame)

    --local rewardBg = img.createUISprite(img.ui.casino_reward_bg)
    --aniReward:addChildFollowSlot("code_reward_01", rewardBg)

    local titleStr = reward.title

    -- confirm btn
    local confirm = img.createUI9Sprite(img.ui.btn_1)
    confirm:setPreferredSize(CCSizeMake(172,72))
    local confirmLab = lbl.createFont1(18, i18n.global.summon_comfirm.string, ccc3(0x73, 0x3b, 0x05))
    confirmLab:setPosition(CCPoint(confirm:getContentSize().width/2, 
                                    confirm:getContentSize().height/2-2))
    confirm:addChild(confirmLab)
    local confirmBtn = SpineMenuItem:create(json.ui.button, confirm)
    confirmBtn:setScale(view.minScale)
    confirmBtn:setPosition(scalep(960/2, 576-496))
    confirmBtn:setVisible(false)
    layer.confirmBtn = confirmBtn
    
    local confirmMenu = CCMenu:createWithItem(confirmBtn)
    confirmMenu:setPosition(0, 0)
    layer:addChild(confirmMenu)

    confirmBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer:removeFromParentAndCleanup(true)
    end)

    layer:setTouchEnabled(true)

    function layer.onAndroidBack()
        audio.play(audio.button)
        img.unload(img.packedOthers.spine_ui_blacksmith_1)
        img.unload(img.packedOthers.spine_ui_blacksmith_2)
        layer:removeFromParentAndCleanup(true)
    end

    addBackEvent(layer)

    local function onEnter()
        layer.notifyParentLock()
    end

    local function onExit()
        layer.notifyParentUnlock()
    end

    layer:registerScriptHandler(function(event)
        if event == "enter" then
            onEnter()
        elseif event == "exit" then
            onExit()        
        end
    end)

    return layer
end

function reward.setTitle(title)
    local titleLabel = lbl.createFont2(30, title, ccc3(0xff, 0xe1, 0x6b))
    --titleLabel:setScale(view.minScale)
    --titleLabel:setPosition(scalep(480, 576-116))

    return titleLabel
end

function reward.playEquipsAni(pb, delaytime, cur)
    local upDuration = 0.8
    local fadeoutDuration = 0.8
    local icons = {}
    local board = img.createLogin9Sprite(img.login.toast_bg)
    board:setPreferredSize(CCSize(300, 64))
    board:setScale(view.minScale)
    board:setVisible(false)
    board:setPosition(CCPoint(view.physical.w/2, view.physical.h/2 + 100*view.minScale))
    board:setCascadeOpacityEnabled(true)
    
    local icon = img.createEquip(pb.id, pb.num)
    icon:setScale(0.6)
    icon:setPosition(board:getContentSize().width/4, board:getContentSize().height/2)
    board:addChild(icon)
    
    -- name
    local name = lbl.createMixFont1(16, i18n.equip[pb.id].name, ccc3(255, 246, 223))
    name:setAnchorPoint(ccp(0, 0.5))
    name:setPosition(board:getContentSize().width/2.5, board:getContentSize().height/2)
    board:addChild(name)
    
    local arr = CCArray:create()
    arr:addObject(CCDelayTime:create(delaytime))
    arr:addObject(CCCallFunc:create(function()
        board:setVisible(true)
    end))
    arr:addObject(CCMoveBy:create(upDuration, CCPoint(0, 54*view.minScale)))
    if reward.allnum ~= 1 and cur ~= reward.allnum then
        arr:addObject(CCMoveBy:create(0.1,CCPoint(0, 54*view.minScale)))
    end
    arr:addObject(CCFadeOut:create(fadeoutDuration))

    board:runAction(CCSequence:create(arr))

    return board
end

function reward.playItemsAni(pb, delaytime, cur)
    local upDuration = 0.8
    local fadeoutDuration = 0.8
    local icons = {}
    local board = img.createLogin9Sprite(img.login.toast_bg)
    board:setPreferredSize(CCSize(300, 64))
    board:setScale(view.minScale)
    board:setPosition(CCPoint(view.physical.w/2, view.physical.h/2 + 100*view.minScale))
    board:setVisible(false)
    board:setCascadeOpacityEnabled(true)
    
    -- 空岛战体力的特殊处理
    local icon 
    if pb.id == 4302 then
        icon = img.createUISprite(img.ui.grid)
        local size = icon:getContentSize()
        local iconImg = img.createItemIconForId(4302)
        iconImg:setPosition(size.width/2, size.height/2)
        iconImg:setScale(1 / 0.6)
        icon:addChild(iconImg)
        local l = lbl.createFont2(14, convertItemNum(pb.num))
        l:setAnchorPoint(ccp(1, 0))
        l:setPosition(74, 6)
        icon:addChild(l)
        icon:setCascadeOpacityEnabled(true)
    else
        icon = img.createItem(pb.id, pb.num)
    end
    icon:setScale(0.6)
    icon:setPosition(board:getContentSize().width/4, board:getContentSize().height/2)
    board:addChild(icon)

    -- name
    -- 空岛战体力的特殊处理
    local nameStr = pb.id == 4302 and i18n.global.airisland_stamina.string or i18n.item[pb.id].name
    local name = lbl.createMixFont1(16, nameStr, ccc3(255, 246, 223))
    name:setAnchorPoint(ccp(0, 0.5))
    name:setPosition(board:getContentSize().width/2.5, board:getContentSize().height/2)
    board:addChild(name)
    
    local arr = CCArray:create()
    arr:addObject(CCDelayTime:create(delaytime))
    arr:addObject(CCCallFunc:create(function()
        board:setVisible(true)
    end))
    arr:addObject(CCMoveBy:create(upDuration, CCPoint(0, 54*view.minScale)))
    if reward.allnum ~= 1 and cur ~= reward.allnum then
        arr:addObject(CCMoveBy:create(0.1, CCPoint(0, 54*view.minScale)))
    end
    arr:addObject(CCFadeOut:create(fadeoutDuration))

    board:runAction(CCSequence:create(arr))

    return board
end

-- 奖励以向上漂浮的方式展示
function reward.createFloating(pbbag)
    local layer = CCLayer:create()
    local delaytime = 0
    local cur = 1
    reward.allnum = 0
    if pbbag.items then
        reward.allnum = reward.allnum + #pbbag.items
    end
    if pbbag.equips then
        reward.allnum = reward.allnum + #pbbag.equips
    end
    if pbbag.equips then
        for i, pb in ipairs(pbbag.equips) do
            layer:addChild(reward.playEquipsAni(pb, delaytime, cur))
            delaytime = delaytime + 0.8
            cur = cur + 1
        end
    end
    if pbbag.items then
        for i, pb in ipairs(pbbag.items) do
            layer:addChild(reward.playItemsAni(pb, delaytime, cur))
            delaytime = delaytime + 0.8
            cur = cur + 1
        end
    end
    return layer
end

return reward
