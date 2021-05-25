local ui = {}

require "common.const"
require "common.func"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local audio = require "res.audio"
local i18n = require "res.i18n"
local player = require "data.player"
local net = require "net.netClient"
local cfghero = require "config.hero"

-- 背景框大小
local BG_WIDTH   = 574
local BG_HEIGHT  = 460

function ui.create(heroData, preHero)
    local layer = CCLayer:create()
    -- dark bg
    local darkbg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    layer:addChild(darkbg)

    tbl2string(preHero)
    local id = heroData.id
    local exstar = heroData.wake
    -- bg
    local bg = img.createUI9Sprite(img.ui.tips_bg)
    bg:setPreferredSize(CCSize(BG_WIDTH, BG_HEIGHT))
    bg:setScale(0.1*view.minScale)
    bg:setPosition(scalep(960/2, 576/2-15))
    bg:runAction(CCEaseBackOut:create(CCScaleTo:create(0.3, 1.0*view.minScale)))
    layer:addChild(bg)
    
    local ltitlebg = img.createUISprite(img.ui.hero_up_titlebg)
    ltitlebg:setAnchorPoint(1, 0.5)
    ltitlebg:setPosition(BG_WIDTH/2, BG_HEIGHT-15)
    bg:addChild(ltitlebg, 1)
    local rtitlebg = img.createUISprite(img.ui.hero_up_titlebg)
    rtitlebg:setAnchorPoint(0, 0.5)
    rtitlebg:setPosition(BG_WIDTH/2, BG_HEIGHT-15)
    rtitlebg:setFlipX(true)
    bg:addChild(rtitlebg)
    local titlelbl = lbl.createFont2(24, i18n.global.hero_wake_tips_title.string, ccc3(0xfa, 0xd8, 0x69))
    titlelbl:setPosition(ltitlebg:getContentSize().width, ltitlebg:getContentSize().height/2+12)
    ltitlebg:addChild(titlelbl)

    -- heroicon
    local heroraw = img.createUISprite(img.ui.hero_btn_raw)
    heroraw:setScale(0.45)
    heroraw:setPosition(BG_WIDTH/2, 360)
    bg:addChild(heroraw)
    -- lefthero
    local lheadbg = img.createHeroHead(preHero.id, heroData.lv, true, true, exstar-1, nil, nil, nil, heroData.hskills)
    lheadbg:setScale(0.8)
    lheadbg:setPosition(BG_WIDTH/2-90, 360)
    bg:addChild(lheadbg)
    -- righthero
    local rheadbg = img.createHeroHead(heroData.id, heroData.lv, true, true, exstar, nil, nil, nil, heroData.hskills)
    rheadbg:setScale(0.8)
    rheadbg:setPosition(BG_WIDTH/2+90, 360)
    bg:addChild(rheadbg)

    -- vtitle
    local infobg1 = img.createUISprite(img.ui.guild_vtitle_bg)
    infobg1:setPosition(BG_WIDTH/2, 290)
    bg:addChild(infobg1)
    local info1 = lbl.createFont1(16, i18n.global.hero_wake_attr_up.string, ccc3(0xeb, 0xaa, 0x5e))
    info1:setPosition(infobg1:getContentSize().width/2, infobg1:getContentSize().height/2)
    infobg1:addChild(info1)

    local helper = require "fight.helper.attr"
    local preData = nil
    if heroData.wake < 4 then
        preData = helper.attr(heroData, heroData.star, heroData.lv, heroData.wake-1)
    else
        preData = helper.attr(preHero, preHero.star, preHero.lv, preHero.wake)
    end
    local aftData = helper.attr(heroData, heroData.star, heroData.lv, heroData.wake)

    local lbllv = lbl.createMixFont1(18, i18n.global.hero_wake_level_up.string, ccc3(0xfd, 0xeb, 0x87))
    lbllv:setAnchorPoint(1, 0.5)
    lbllv:setPosition(162, 252)
    bg:addChild(lbllv)
    local lvraw = img.createUISprite(img.ui.hero_btn_raw)
    lvraw:setScale(0.42)
    lvraw:setPosition(326, 252)
    bg:addChild(lvraw)
    local lvMax = cfghero[heroData.id]["starLv" .. (heroData.star + 1)] or cfghero[heroData.id].maxLv
    if heroData.wake and heroData.wake >= 4 and player.isSeasonal() then
        lvMax = 290
    elseif heroData.wake and heroData.wake < 4 then
        lvMax = lvMax + heroData.wake*20
    end
    local lv1 = lbl.createMixFont1(18, lvMax-20, ccc3(255,246,223))
    lv1:setPosition(226, 252)
    bg:addChild(lv1)
    local lv2 = lbl.createMixFont1(18, lvMax, ccc3(255,246,223))
    lv2:setPosition(426, 252)
    bg:addChild(lv2)
    if heroData.wake == 4 then
        lv1:setString(lvMax-50)
    end

    local lblhealth = lbl.createMixFont1(18, i18n.global.hero_info_health.string, ccc3(0xfd, 0xeb, 0x87))
    lblhealth:setAnchorPoint(1, 0.5)
    lblhealth:setPosition(162, 222)
    bg:addChild(lblhealth)
    local healthraw = img.createUISprite(img.ui.hero_btn_raw)
    healthraw:setScale(0.42)
    healthraw:setPosition(326, 222)
    bg:addChild(healthraw)
    local hp1 = lbl.createMixFont1(18, preData.hp, ccc3(255,246,223))
    hp1:setPosition(226, 222)
    bg:addChild(hp1)
    local hp2 = lbl.createMixFont1(18, aftData.hp, ccc3(255,246,223))
    hp2:setPosition(426, 222)
    bg:addChild(hp2)

    local lblatt = lbl.createMixFont1(18, i18n.global.hero_info_attack.string, ccc3(0xfd, 0xeb, 0x87))
    lblatt:setAnchorPoint(1, 0.5)
    lblatt:setPosition(162, 192)
    bg:addChild(lblatt)
    local attraw = img.createUISprite(img.ui.hero_btn_raw)
    attraw:setScale(0.42)
    attraw:setPosition(326, 192)
    bg:addChild(attraw)
    local atk1 = lbl.createMixFont1(18, preData.atk, ccc3(255,246,223))
    atk1:setPosition(226, 192)
    bg:addChild(atk1)
    local atk2 = lbl.createMixFont1(18, aftData.atk, ccc3(255,246,223))
    atk2:setPosition(426, 192)
    bg:addChild(atk2)

    -- skill
    local infobg2 = img.createUISprite(img.ui.guild_vtitle_bg)
    infobg2:setPosition(BG_WIDTH/2, 170-16)
    bg:addChild(infobg2)
    local info2 = lbl.createFont1(16, i18n.global.hero_wake_skill_up.string, ccc3(0xeb, 0xaa, 0x5e))
    info2:setPosition(infobg2:getContentSize().width/2, infobg2:getContentSize().height/2)
    infobg2:addChild(info2)

    local skillraw = img.createUISprite(img.ui.hero_btn_raw)
    skillraw:setScale(0.75)
    skillraw:setPosition(BG_WIDTH/2, 165-16-65)
    bg:addChild(skillraw)

    -- skill
    local skillId1 = cfghero[id].actSkillId
    if exstar-1 > 0 and exstar < 4 then
        skillId1 = cfghero[id].disillusSkill[exstar-1].disi[1]
    end
    local skillId2 = cfghero[id].actSkillId
    if exstar < 4 then
        if skillId1 ~= cfghero[id].disillusSkill[exstar].disi[1] then
            skillId2 = cfghero[id].disillusSkill[exstar].disi[1]
        end
        if skillId1 == skillId2 then
            for i=1, 3 do
                if exstar-1 > 0 then
                    skillId1 = cfghero[id].disillusSkill[exstar-1].disi[i+1]
                else
                    skillId1 = cfghero[id]["pasSkill" .. i .. "Id"]
                end
                if skillId1 ~= cfghero[id].disillusSkill[exstar].disi[i+1] then
                    skillId2 = cfghero[id].disillusSkill[exstar].disi[i+1]
                    break
                end
            end
        end
    end
	
	if heroData and heroData.hskills then
		
	else
		local skillIconBg1 = img.createUISprite(img.ui.hero_skill_bg)
		skillIconBg1:setScale(0.9)
		skillIconBg1:setPosition(BG_WIDTH/2-90, 165-16-65)
		bg:addChild(skillIconBg1, 100)
		local skillIcon1 = img.createSkill(skillId1)
		skillIcon1:setPosition(skillIconBg1:getContentSize().width/2, skillIconBg1:getContentSize().height/2)
		skillIconBg1:addChild(skillIcon1)

		local skillIconBg2 = img.createUISprite(img.ui.hero_skill_bg)
		skillIconBg2:setScale(0.9)
		skillIconBg2:setPosition(BG_WIDTH/2+90, 165-16-65)
		bg:addChild(skillIconBg2, 100)
		local skillIcon2 = img.createSkill(skillId2)
		skillIcon2:setPosition(skillIconBg2:getContentSize().width/2, skillIconBg2:getContentSize().height/2)
		skillIconBg2:addChild(skillIcon2)

		if exstar < 4 then
			local skillLB1 = img.createUISprite(img.ui.hero_skilllevel_bg)
			skillLB1:setPosition(skillIconBg1:getContentSize().width-15, skillIconBg1:getContentSize().height-15)
			skillIconBg1:addChild(skillLB1)
			local skilllab1 = lbl.createFont1(18, "2", ccc3(255, 246, 223))
			skilllab1:setPosition(skillLB1:getContentSize().width/2, skillLB1:getContentSize().height/2)
			skillLB1:addChild(skilllab1)
			local skillLB2 = img.createUISprite(img.ui.hero_skilllevel_bg)
			skillLB2:setPosition(skillIconBg2:getContentSize().width-15, skillIconBg2:getContentSize().height-15)
			skillIconBg2:addChild(skillLB2)
			local skilllab2 = lbl.createFont1(18, "3", ccc3(255, 246, 223))
			skilllab2:setPosition(skillLB2:getContentSize().width/2, skillLB2:getContentSize().height/2)
			skillLB2:addChild(skilllab2)
		end
	end

    -- closeBtn
    local closeBtn0 = img.createUISprite(img.ui.close)
    local closeBtn = SpineMenuItem:create(json.ui.button, closeBtn0)
    closeBtn:setPosition(BG_WIDTH-23, BG_HEIGHT-26)
    local closeMenu = CCMenu:createWithItem(closeBtn)
    closeMenu:setPosition(0, 0)
    bg:addChild(closeMenu)
    closeBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer.onAndroidBack()
    end)

    addBackEvent(layer)

    function layer.onAndroidBack()
        layer:removeFromParent()
    end

    layer:registerScriptHandler(function(event)
        if event == "enter" then
            layer.notifyParentLock()
        elseif event == "exit" then
            layer.notifyParentUnlock()
        end
    end)

    layer:setTouchEnabled(true)
    layer:setTouchSwallowEnabled(true)

    return layer
end

return ui
