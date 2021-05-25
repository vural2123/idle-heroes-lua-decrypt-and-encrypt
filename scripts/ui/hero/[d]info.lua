local info = {}

require "common.func"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local i18n = require "res.i18n"
local audio = require "res.audio"
local net = require "net.netClient"
local cfghero = require "config.hero"
local cfgequip = require "config.equip"
local cfgexphero = require "config.exphero"
local cfgskill = require "config.skill"
local heros = require "data.heros"
local bag = require "data.bag"
local player = require "data.player"
local cfgtalen = require "config.talen"

local showHeroLayer
local showBoardLayer
local heroData 

local function GetGoldCost(forLevel)
    if not cfgexphero[forLevel] then
        return 999
    end
    local gold = cfgexphero[forLevel].needGold
    if player.isSeasonal() then
        gold = math.ceil(gold / 2)
    end
    return gold
end

local function GetSpiritCost(forLevel)
	if not cfgexphero[forLevel] then
		return 999
	end
	local spirit = cfgexphero[forLevel].needExp
	return spirit
end

local function createEvolve(heroData, callback)
    local layer = CCLayerColor:create(ccc4(0, 0, 0, 255 * 0.8))

    local board = img.createLogin9Sprite(img.login.dialog)
    board:setPreferredSize(CCSize(648, 500))
    board:setScale(view.minScale)
    board:setPosition(scalep(480, 288))
    layer:addChild(board)

    local btnCloseSprite = img.createUISprite(img.ui.close)
    local btnClose = SpineMenuItem:create(json.ui.button, btnCloseSprite)
    btnClose:setPosition(621, 473)
    local menuClose = CCMenu:createWithItem(btnClose)
    menuClose:setPosition(0, 0)
    board:addChild(menuClose)
    btnClose:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer:removeFromParentAndCleanup(true)
    end)

    local title = lbl.createFont1(24, i18n.global.hero_advance.string, ccc3(0xe6, 0xd0, 0xae))
    title:setPosition(324, 472)
    board:addChild(title, 1)
    local titleShade = lbl.createFont1(24, i18n.global.hero_advance.string, ccc3(0x59, 0x30, 0x1b))
    titleShade:setPosition(324, 470)
    board:addChild(titleShade)

    local attrBg = img.createUI9Sprite(img.ui.hero_evolve_cost_bg)
    attrBg:setPreferredSize(CCSize(344, 200))
    attrBg:setAnchorPoint(ccp(0, 0))
    attrBg:setPosition(36, 180)
    board:addChild(attrBg)

    local skillBg = img.createUI9Sprite(img.ui.select_hero_buff_bg)
    skillBg:setPreferredSize(CCSize(222, 200))
    skillBg:setAnchorPoint(ccp(0, 0))
    skillBg:setPosition(391, 180)
    board:addChild(skillBg, 100)

    local helper = require "fight.helper.attr"
    local preData = helper.attr(heroData, heroData.star)
    local aftData = helper.attr(heroData, heroData.star + 1)
    local coin = 0
    local evolve = 0
    if bag.items.find(ITEM_ID_COIN) then
        coin = bag.items.find(ITEM_ID_COIN).num
    end
    if bag.items.find(ITEM_ID_EVOLVE_EXP) then
        evolve = bag.items.find(ITEM_ID_EVOLVE_EXP).num
    end
    local coinCost, evolveCost = cfghero[heroData.id]["starExp" .. (heroData.star + 1)][2], cfghero[heroData.id]["starExp" .. (heroData.star + 1)][1] 

    -- evolve bg
    local evolve_bg = img.createUI9Sprite(img.ui.main_coin_bg)
    evolve_bg:setPreferredSize(CCSizeMake(174, 40))
    evolve_bg:setAnchorPoint(CCPoint(0, 0.5))
    evolve_bg:setPosition(CCPoint(340, 500-82))
    board:addChild(evolve_bg)
    -- evolve icon
    local evolve_coin = img.createItemIcon(ITEM_ID_EVOLVE_EXP)
    evolve_coin:setScale(0.6)
    evolve_coin:setPosition(CCPoint(5, evolve_bg:getContentSize().height/2+2))
    evolve_bg:addChild(evolve_coin)
    -- lbl evolve
    local lbl_evolve = lbl.createFont2(16, evolve, ccc3(255, 246, 223))
    lbl_evolve:setPosition(CCPoint(evolve_bg:getContentSize().width/2-10, evolve_bg:getContentSize().height/2+3))
    evolve_bg:addChild(lbl_evolve)
    -- coin bg
    local coin_bg = img.createUI9Sprite(img.ui.main_coin_bg)
    coin_bg:setPreferredSize(CCSizeMake(174, 40))
    coin_bg:setAnchorPoint(CCPoint(1, 0.5))
    coin_bg:setPosition(CCPoint(310, 500-82))
    board:addChild(coin_bg)
    -- coin icon
    local icon_coin = img.createItemIcon2(ITEM_ID_COIN)
    icon_coin:setPosition(CCPoint(5, coin_bg:getContentSize().height/2+2))
    coin_bg:addChild(icon_coin)
    -- lbl coin
    local coin_num = bag.coin()
    local lbl_coin = lbl.createFont2(16, num2KM(coin_num), ccc3(255, 246, 223))
    lbl_coin:setPosition(CCPoint(coin_bg:getContentSize().width/2-10, coin_bg:getContentSize().height/2+3))
    coin_bg:addChild(lbl_coin)
    lbl_coin.num = coin_num

    local DATA = {
        [1] = { title = i18n.global.hero_info_level.string, pre = cfghero[heroData.id]["starLv" .. (heroData.star + 1)], aft = cfghero[heroData.id]["starLv" .. (heroData.star + 2)] or cfghero[heroData.id].maxLv },
        [2] = { title = i18n.global.hero_info_power.string, pre = math.floor(preData.power), aft = math.floor(aftData.power) },
        [3] = { title = i18n.global.hero_info_health.string, pre = math.floor(preData.hp), aft = math.floor(aftData.hp) },
        [4] = { title = i18n.global.hero_info_attack.string, pre = math.floor(preData.atk), aft = math.floor(aftData.atk) },
        [5] = { title = i18n.global.hero_info_armor.string, pre = math.floor(preData.arm), aft = math.floor(aftData.arm) },
    }
   
    for i=1, 5 do
        local showTitle = lbl.createFont2(18, DATA[i].title, ccc3(0xfd, 0xeb, 0x87))
        showTitle:setAnchorPoint(ccp(1, 0.5))
        showTitle:setPosition(90, 203 - 33 * i)
        attrBg:addChild(showTitle)

        local showPre = lbl.createFont2(18, DATA[i].pre, ccc3(255, 246, 223))
        showPre:setPosition(143, 203 - 33 * i)
        attrBg:addChild(showPre)

        local showArrow = img.createUISprite(img.ui.arrow)
        showArrow:setPosition(219, 203 - 33 * i)
        attrBg:addChild(showArrow)

        local showAft = lbl.createFont2(18, DATA[i].aft, ccc3(0x9d, 0xf4, 0x26))
        showAft:setPosition(286, 203 - 33 * i)
        attrBg:addChild(showAft)
    end

    local skillId 
    for i=1, 3 do
        if cfghero[heroData.id]["pasTier" .. i] == (heroData.star + 1) then
            skillId = cfghero[heroData.id]["pasSkill" .. i .. "Id"]
        end
    end
	
	if cfghero[heroData.id].maxStar >= 6 and player.isMod(1) then
		skillId = nil
	end
	
    --local skillTitle = lbl.createFont1(20, i18n.global.hero_unlock.string, ccc3(0x94, 0x62, 0x42))
    --skillTitle:setPosition(111, 165)
    --skillBg:addChild(skillTitle)

    local skillIconBg
    local skillTips
    if skillId then
        local skillTitle = lbl.createFont1(20, i18n.global.hero_unlock.string, ccc3(0x94, 0x62, 0x42))
        skillTitle:setPosition(111, 165)
        skillBg:addChild(skillTitle)

        skillIconBg = img.createUISprite(img.ui.hero_skill_bg)
        skillIconBg:setPosition(111, 86)
        skillBg:addChild(skillIconBg)

        local skillIcon = img.createSkill(skillId)
        skillIcon:setPosition(skillIconBg:getContentSize().width/2, skillIconBg:getContentSize().height/2)
        skillIconBg:addChild(skillIcon)
    
        if cfgskill[skillId].skiL then
            local skillLB = img.createUISprite(img.ui.hero_skilllevel_bg)
            skillLB:setPosition(skillIconBg:getContentSize().width-15, skillIconBg:getContentSize().height-15)
            skillIconBg:addChild(skillLB)
            local skilllab = lbl.createFont1(18, cfgskill[skillId].skiL, ccc3(255, 246, 223))
            skilllab:setPosition(skillLB:getContentSize().width/2, skillLB:getContentSize().height/2)
            skillLB:addChild(skilllab)
        end
        
        skillTips = require("ui.tips.skill").create(skillId)
        skillTips:setAnchorPoint(ccp(1, 0))
        skillTips:setPosition(skillIconBg:boundingBox():getMaxX(), skillIconBg:boundingBox():getMaxY())
        skillBg:addChild(skillTips)
        skillTips:setVisible(false)
    end

    local coinBg = img.createUI9Sprite(img.ui.hero_evolve_cost_bg)
    coinBg:setPreferredSize(CCSize(178, 33))
    coinBg:setAnchorPoint(ccp(0, 0))
    coinBg:setPosition(136, 123)
    board:addChild(coinBg)

    local evolveBg = img.createUI9Sprite(img.ui.hero_evolve_cost_bg)
    evolveBg:setPreferredSize(CCSize(178, 33))
    evolveBg:setAnchorPoint(ccp(0, 0))
    evolveBg:setPosition(342, 123)
    board:addChild(evolveBg)

    local coinIcon = img.createItemIcon2(ITEM_ID_COIN)
    coinIcon:setPosition(10, 17)
    coinBg:addChild(coinIcon)

    local evolveIcon = img.createItemIcon(ITEM_ID_EVOLVE_EXP)
    evolveIcon:setScale(0.6)
    evolveIcon:setPosition(10, 17)
    evolveBg:addChild(evolveIcon)

    local showCoin = lbl.createFont2(16, num2KM(coinCost), ccc3(255, 246, 223))
    showCoin:setAnchorPoint(ccp(0, 0.5))
    showCoin:setPosition(40, 16)
    coinBg:addChild(showCoin)
    if coinCost > coin_num then 
        showCoin:setColor(ccc3(0xff, 0x2c, 0x2c))
    end

    local showEvolve = lbl.createFont2(16, num2KM(evolveCost), ccc3(255, 246, 223))
    showEvolve:setAnchorPoint(ccp(0, 0.5))
    showEvolve:setPosition(40, 16)
    evolveBg:addChild(showEvolve)
    if evolveCost > evolve then 
        showEvolve:setColor(ccc3(0xff, 0x2c, 0x2c))
    end

    local btnEvolveSp = img.createLogin9Sprite(img.login.button_9_small_gold)
    btnEvolveSp:setPreferredSize(CCSize(175, 70))
    local labEvolve = lbl.createFont1(20, i18n.global.hero_advance.string, ccc3(0x73, 0x3b, 0x05))
    labEvolve:setPosition(btnEvolveSp:getContentSize().width/2, btnEvolveSp:getContentSize().height/2)
    btnEvolveSp:addChild(labEvolve)

    local btnEvolve = SpineMenuItem:create(json.ui.button, btnEvolveSp)
    local menuEvolve = CCMenu:createWithItem(btnEvolve)
    btnEvolve:setAnchorPoint(ccp(0.5, 0))
    btnEvolve:setPosition(648/2, 35)
    menuEvolve:setPosition(0, 0)
    board:addChild(menuEvolve)

    local function onEvolve()
        if layer and not tolua.isnull(layer) then
            layer:runAction(CCRemoveSelf:create())

            local animLayer = CCLayer:create()
            layer:getParent():addChild(animLayer, 10000)

            json.load(json.ui.hero_et)
            local animStar = DHSkeletonAnimation:createWithKey(json.ui.hero_et)
            animStar:scheduleUpdateLua()
            animStar:setScale(view.minScale)
            animStar:setPosition(scalep(480, 288))
            if skillId then
                animStar:playAnimation("animation")
                animStar:appendNextAnimation("loop", -1)
            else
                animStar:playAnimation("animation2")
                animStar:appendNextAnimation("loop2", -1)
            end
            animLayer:addChild(animStar)

            local title 
            if i18n.getCurrentLanguage() == kLanguageChinese 
                    or i18n.getCurrentLanguage() == kLanguageChineseTW then
                title = img.createUISprite(img.ui.language_advance_cn)
            elseif i18n.getCurrentLanguage() == kLanguageEnglish then
                title = img.createUISprite(img.ui.language_advance_us)
            else
                title = lbl.createFont3(30, i18n.global.hero_advance.string, ccc3(0xff, 0xcc, 0x33))
            end
            animStar:addChildFollowSlot("code_title",title)

            --showTextLayer:setCascadeOpacityEnabled(true)

            for i=1, 5 do
                local textNode = CCNode:create()
                textNode:setCascadeOpacityEnabled(true)
                animStar:addChildFollowSlot("code_text"..i,textNode)

                local showTitle = lbl.createFont2(18, DATA[i].title, ccc3(0xfd, 0xeb, 0x87))
                showTitle:setAnchorPoint(ccp(0, 0.5))
                --showTitle:setPosition(-160, 144 - 30 * i)
                showTitle:setPositionX(-160)
                textNode:addChild(showTitle)
                showTitle:setCascadeOpacityEnabled(true)

                local showPre = lbl.createFont2(18, DATA[i].pre, ccc3(255, 246, 223))
                --showPre:setPosition(-35, 144 - 30 * i)
                showPre:setPositionX(-35)
                textNode:addChild(showPre)
                showPre:setCascadeOpacityEnabled(true)

                local showAft = lbl.createFont2(18, DATA[i].aft, ccc3(0x9d, 0xf4, 0x26))
                --showAft:setPosition(140, 144 - 30 * i)
                showAft:setPositionX(140)
                textNode:addChild(showAft)
                showAft:setCascadeOpacityEnabled(true)
            end

            local showSkillLayer = CCLayer:create()
            animStar:addChildFollowSlot("code_icon", showSkillLayer)
            showSkillLayer:setCascadeOpacityEnabled(true)

            local showTextLayer = CCNode:create()
            animStar:addChild(showTextLayer)

            if skillId then
                local skillTitle = lbl.createMixFont2(20, i18n.global.hero_advance_unlock_skill.string)
                skillTitle:setPosition(0, -104)
                showTextLayer:addChild(skillTitle)
                skillTitle:setCascadeOpacityEnabled(true)

                local skillIconBg = img.createUISprite(img.ui.hero_skill_bg)
                skillIconBg:setPosition(0, 0)
                showSkillLayer:addChild(skillIconBg)
                skillIconBg:setCascadeOpacityEnabled(true)

                local skillIcon = img.createSkill(skillId)
                skillIcon:setPosition(skillIconBg:getContentSize().width/2, skillIconBg:getContentSize().height/2)
                skillIconBg:addChild(skillIcon)
                skillIcon:setCascadeOpacityEnabled(true)

                local skillName = lbl.createMixFont1(18, i18n.skill[skillId].skillName, ccc3(0xac, 0xed, 0x3a))
                skillName:setPosition(0, -224)
                showTextLayer:addChild(skillName)
                skillName:setCascadeOpacityEnabled(true)

                -- local skillText = lbl.createMixFont1(18, i18n.skill[skillId].desc, ccc3(0xff, 0xfb, 0xdc))
                -- skillText:setPosition(0, -249)
                -- showTextLayer:addChild(skillText)
                -- skillText:setCascadeOpacityEnabled(true)
            end
            
            local tick = 0
            animLayer:registerScriptTouchHandler(function()
                if tick >= 90 then
                    animLayer:removeFromParentAndCleanup(true)
                end
                return true 
            end)
            animLayer:setTouchEnabled(true)
            
            animLayer:scheduleUpdateWithPriorityLua(function() 
                tick = tick + 1 
                if tick > 300 then
                    tick = 300
                end
            end)
        end
    end

    btnEvolve:registerScriptTapHandler(function()
        disableObjAWhile(btnEvolve)
        if evolve < evolveCost then
            showToast(i18n.global.toast_hero_need_evolve.string)
            return
        elseif coin < coinCost then
            showToast(i18n.global.toast_hero_need_coin.string)
            return
        elseif heroData.lv < cfghero[heroData.id]["starLv" .. (heroData.star + 1)] then
            showToast(i18n.global.toast_hero_need_lvup.string)
            return
        end
        
        local params = {
            sid = player.sid,
            hid = heroData.hid,
            type = 2,
        }
        addWaitNet()
        net:hero_up(params, function(__data)
            delWaitNet()

            if __data.status < 0 then
                showToast("status:" .. __data.status)
                return
            end
            
            audio.play(audio.hero_advance)
            bag.items.sub({ id = ITEM_ID_EVOLVE_EXP, num = evolveCost })
            bag.items.sub({ id = ITEM_ID_COIN, num = coinCost })
            heroData.star = heroData.star + 1
            onEvolve() 
            callback()
        end)
    end)
        
    local function onTouch(eventType, x, y)
        if eventType == "began" or eventType == "moved" then
            if skillTips and skillIconBg:boundingBox():containsPoint(skillBg:convertToNodeSpace(ccp(x, y))) then
                skillTips:setVisible(true)
            end
        elseif skillTips then
            skillTips:setVisible(false)
        end
        return true
    end

    layer:registerScriptTouchHandler(onTouch)
    layer:setTouchEnabled(true)

    board:setScale(0.5*view.minScale)
    local anim_arr = CCArray:create()
    anim_arr:addObject(CCScaleTo:create(0.15, 1*view.minScale, 1*view.minScale))
    anim_arr:addObject(CCDelayTime:create(0.15))
    anim_arr:addObject(CCCallFunc:create(function()
    
    end))
    board:runAction(CCSequence:create(anim_arr))

    return layer
end

function info.create(heroData, superlayer)
    local layer = CCLayer:create()

    local lvMax = cfghero[heroData.id]["starLv" .. (heroData.star + 1)] or cfghero[heroData.id].maxLv
    if heroData.wake  then
        if heroData.wake < 4 then
            lvMax = lvMax + heroData.wake*20
        end
        if heroData.wake >= 5 then
            lvMax = cfgtalen[heroData.wake-4].addMaxLv
        end
    end

    local board = img.createUI9Sprite(img.ui.hero_bg)
    board:setAnchorPoint(ccp(0, 0))
    board:setPreferredSize(CCSize(428, 503))
    board:setPosition(465, 35 - 20)
    layer:addChild(board)

    json.load(json.ui.hero_up)
    local animLv = DHSkeletonAnimation:createWithKey(json.ui.hero_up)
    animLv:scheduleUpdateLua()
    animLv:setPosition(230, 160)
    layer:addChild(animLv, 100)

    local function onLvUp(attr, nattr)
        local stat = {
            [1] = { num = nattr.atk - attr.atk, title = i18n.global.hero_detail_1.string },
            [2] = { num = nattr.hp - attr.hp, title = i18n.global.hero_detail_2.string },
            [3] = { num = nattr.arm - attr.arm, title = i18n.global.hero_detail_3.string },
            [4] = { num = nattr.spd - attr.spd, title = i18n.global.hero_detail_4.string },
        }
        local showStat = {}
        for i, v in ipairs(stat) do
            if v.num > 0 then
                showStat[#showStat + 1] = v.title .. "     +" .. v.num
            end
        end

        local showLayer = CCLayer:create()
        layer:addChild(showLayer)
        for i, v in ipairs(showStat) do
            json.load(json.ui.hero_numbers)
            local anim = DHSkeletonAnimation:createWithKey(json.ui.hero_numbers)
            anim:scheduleUpdateLua()
            anim:setPosition(230, 230 + i * 24)
            anim:playAnimation("up")
            showLayer:addChild(anim)

            local shownum = lbl.createMixFont2(16, v, ccc3(0xa5, 0xfd, 0x47))
            anim:addChildFollowSlot("code_numbers", shownum)
        end
        showLayer:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(2), CCRemoveSelf:create()))
    end

    local title = lbl.createFont1(24, i18n.global.hero_title_hero.string, ccc3(0xe6, 0xd0, 0xae))
    title:setPosition(214, 474)
    board:addChild(title, 1)
    local titleShade = lbl.createFont1(24, i18n.global.hero_title_hero.string, ccc3(0x59, 0x30, 0x1b))
    titleShade:setPosition(214, 472)
    board:addChild(titleShade)

    local powerIcon = img.createUISprite(img.ui.power_icon)
    powerIcon:setScale(0.48)
    powerIcon:setAnchorPoint(ccp(0, 0))
    powerIcon:setPosition(47, 408)
    board:addChild(powerIcon)

    local titleLv = lbl.createFont1(20, "LV : ", ccc3(0x93, 0x3a, 0x36))
    titleLv:setAnchorPoint(ccp(0, 0.5))
    titleLv:setPosition(264, powerIcon:boundingBox():getMidY())
    board:addChild(titleLv)

    local showPower = lbl.createFont1(22, heros.power(heroData.hid), ccc3(0x51, 0x27, 0x12))
    showPower:setAnchorPoint(ccp(0, 0.5))
    showPower:setPosition(powerIcon:boundingBox():getMaxX() + 8, powerIcon:boundingBox():getMidY())
    board:addChild(showPower)

    local showLv = lbl.createFont1(22, heroData.lv .. "/" .. lvMax, ccc3(0x51, 0x27, 0x12))
    showLv:setAnchorPoint(ccp(0, 0.5))
    showLv:setPosition(titleLv:boundingBox():getMaxX() + 8, titleLv:boundingBox():getMidY())
    board:addChild(showLv)

    local scale = showPower:getScale()
    
    local fgLine = img.createUI9Sprite(img.ui.hero_panel_fgline)
    fgLine:setPreferredSize(CCSize(356, 4))
    fgLine:setPosition(214, 401)
    board:addChild(fgLine)

    local function updatePowerAndLv()
        lvMax = cfghero[heroData.id]["starLv" .. (heroData.star + 1)] or cfghero[heroData.id].maxLv
        if heroData.wake then
            if heroData.wake < 4 then
                lvMax = lvMax + heroData.wake*20
            end
            if heroData.wake >= 5 then
                lvMax = cfgtalen[heroData.wake-4].addMaxLv
            end
        end
        if showPower and not tolua.isnull(showPower) then
            showPower:setString(heros.power(heroData.hid))
            showPower:runAction(CCSequence:createWithTwoActions(CCScaleTo:create(0.2, 1.2 * scale), CCScaleTo:create(0.2, 1 * scale)))
        end
        if showLv and not tolua.isnull(showLv) then
            showLv:setString(heroData.lv .. "/" .. lvMax)
            showLv:runAction(CCSequence:createWithTwoActions(CCScaleTo:create(0.2, 1.2 * scale), CCScaleTo:create(0.2, 1 * scale)))
        end
    end


    local function updateState()
        local showUpdateLayer = CCLayer:create()
        board:addChild(showUpdateLayer)

        local titleEvolve = lbl.createFont1(18, i18n.global.hero_title_evolve.string, ccc3(0x73, 0x3b, 0x05))
        titleEvolve:setAnchorPoint(ccp(1, 0.5))
        titleEvolve:setPosition(110, 367)
        showUpdateLayer:addChild(titleEvolve)

        local titleExp = lbl.createFont1(18, i18n.global.hero_title_exp.string, ccc3(0x73, 0x3b, 0x05))
        titleExp:setAnchorPoint(ccp(1, 0.5))
        titleExp:setPosition(110, 316)
        showUpdateLayer:addChild(titleExp)

        local btnLvUpSprite = img.createUISprite(img.ui.hero_btn_lvup)
        local btnStarUpSprite = img.createUISprite(img.ui.hero_btn_lvup)
        if heroData.lv < lvMax then
            --btnStarUpSprite:setOpacity(120)
        end
        if heroData.lv >= lvMax then
            btnLvUpSprite:setVisible(false)
        
            if heroData.star < cfghero[heroData.id].qlt then
                local showRed = img.createUISprite(img.ui.main_red_dot)
                showRed:setPosition(btnStarUpSprite:getContentSize().width - 5, btnStarUpSprite:getContentSize().height - 5)
                btnStarUpSprite:addChild(showRed)
            end
        end
		--setShader(btnStarUpSprite, SHADER_INJURED, true)
        local Lvup = nil
        local expCostBg = nil 
        local expIcon = nil
        local goldIcon = nil
        local showCostExp = nil
        local showCostGold = nil
        if heroData.lv < lvMax then
            expCostBg = img.createUI9Sprite(img.ui.hero_lv_cost_bg)
            expCostBg:setPreferredSize(CCSize(208, 40))
            expCostBg:setAnchorPoint(ccp(0, 0.5))
            expCostBg:setPosition(titleExp:boundingBox():getMaxX() + 12, titleExp:boundingBox():getMidY())
            showUpdateLayer:addChild(expCostBg)

            expIcon = img.createItemIcon(ITEM_ID_HERO_EXP)
            expIcon:setScale(0.4)
            expIcon:setAnchorPoint(ccp(0, 0.5))
            expIcon:setPosition(11, 20)
            expCostBg:addChild(expIcon)

            goldIcon = img.createItemIcon(ITEM_ID_COIN)
            goldIcon:setScale(0.4)
            goldIcon:setAnchorPoint(ccp(0, 0.5))
            goldIcon:setPosition(99, 20)
            expCostBg:addChild(goldIcon)

			local spiritNeed = GetSpiritCost(heroData.lv + 1)
            showCostExp = lbl.createFont2(16, spiritNeed)
            showCostExp:setAnchorPoint(ccp(0, 0.5))
            showCostExp:setPosition(expIcon:boundingBox():getMaxX() + 6, 20)
            expCostBg:addChild(showCostExp)
            if spiritNeed > 100000 then
                showCostExp:setString((tostring(math.ceil(spiritNeed/1000)) .. "k"))
            end

            local goldNeed = GetGoldCost(heroData.lv + 1)
            showCostGold = lbl.createFont2(16, goldNeed)
            showCostGold:setAnchorPoint(ccp(0, 0.5))
            showCostGold:setPosition(goldIcon:boundingBox():getMaxX() + 6, 20)
            expCostBg:addChild(showCostGold)
            if goldNeed > 100000 then
                showCostGold:setString((tostring(math.ceil(goldNeed/1000)) .. "k"))
            end

            local exp = 0
            local coin = 0
            if bag.items.find(ITEM_ID_HERO_EXP) then
                exp = bag.items.find(ITEM_ID_HERO_EXP).num
            end
            if bag.items.find(ITEM_ID_COIN) then
                coin = bag.items.find(ITEM_ID_COIN).num
            end
            
            if exp < spiritNeed then
                showCostExp:setColor(ccc3(0xff, 0x2c, 0x2c))
            end 
            if coin < goldNeed then
                showCostGold:setColor(ccc3(0xff, 0x2c, 0x2c))
            end
            
            if require("data.tutorial").exists() then
                local btnLvUpSprite1 = img.createUISprite(img.ui.hero_btn_lvup)
                local btnLvUp = SpineMenuItem:create(json.ui.button, btnLvUpSprite1)
                local menuLvUp = CCMenu:createWithItem(btnLvUp)
                btnLvUp:setPosition(369, titleExp:boundingBox():getMidY())
                menuLvUp:setPosition(0, 0)
                showUpdateLayer:addChild(menuLvUp)
                btnLvUp:registerScriptTapHandler(function()
                    Lvup()
                end)
            else
                btnLvUpSprite:setPosition(369, titleExp:boundingBox():getMidY())
                showUpdateLayer:addChild(btnLvUpSprite)
            end
        else
            local img_maxlv = img.ui.hero_maxlv
            if i18n.getCurrentLanguage() == kLanguageChinese  then
                img_maxlv = img.ui.hero_maxlv_cn
            elseif i18n.getCurrentLanguage() == kLanguageChineseTW then
                img_maxlv = img.ui.hero_maxlv_tw
            elseif i18n.getCurrentLanguage() == kLanguageJapanese then
                img_maxlv = img.ui.hero_maxlv_jp
            elseif i18n.getCurrentLanguage() == kLanguageRussian then
                img_maxlv = img.ui.hero_maxlv_ru
            elseif i18n.getCurrentLanguage() == kLanguageKorean then
                img_maxlv = img.ui.hero_maxlv_kr
            end
            local showMaxLv = img.createUISprite(img_maxlv)
            showMaxLv:setAnchorPoint(ccp(0, 0.5))
            showMaxLv:setPosition(titleExp:boundingBox():getMaxX() + 12, titleExp:boundingBox():getMidY())
            showUpdateLayer:addChild(showMaxLv)
        end
        
        for i=1, cfghero[heroData.id].qlt do
            local showStar
            if i <= heroData.star then
                showStar = img.createUISprite(img.ui.hero_star1)
            else
                showStar = img.createUISprite(img.ui.hero_star0)
            end
            showStar:setAnchorPoint(ccp(0, 0.5))
            showStar:setPosition(titleExp:boundingBox():getMaxX() + 12 + (i-1) * 32, titleEvolve:boundingBox():getMidY())
            showUpdateLayer:addChild(showStar)
        end
        local btnStarUp = nil

        if (heroData.star < cfghero[heroData.id].qlt and heroData.lv >= lvMax) or heroData.lv < lvMax then
            btnStarUp = SpineMenuItem:create(json.ui.button, btnStarUpSprite)
            local menuStarUp = CCMenu:createWithItem(btnStarUp)
            btnStarUp:setAnchorPoint(ccp(0, 0.5))
            btnStarUp:setPosition(346, titleEvolve:boundingBox():getMidY())
            menuStarUp:setPosition(0, 0)
            showUpdateLayer:addChild(menuStarUp)
            btnStarUp:registerScriptTapHandler(function()
                audio.play(audio.button)
                if heroData.lv >= lvMax then
                    superlayer:addChild(createEvolve(heroData, function()
                        showUpdateLayer:runAction(CCRemoveSelf:create())
                        updatePowerAndLv()
                        updateState()
                    end), 10000)
                else
					local goldNeed = GetGoldCost(heroData.lv + 1)
					local spiritNeed = GetGoldCost(heroData.lv + 1)
					local exp = 0
					local coin = 0
					if bag.items.find(ITEM_ID_HERO_EXP) then
						exp = bag.items.find(ITEM_ID_HERO_EXP).num
					end
					if bag.items.find(ITEM_ID_COIN) then
						coin = bag.items.find(ITEM_ID_COIN).num
					end
					if exp < spiritNeed then
						showToast(i18n.global.toast_hero_need_exp.string)
						return
					elseif coin < goldNeed then
						showToast(i18n.global.toast_hero_need_coin.string)
						return
					end
					local params = {
						sid = player.sid,
						hid = heroData.hid,
						type = 3,
					}
					addWaitNet()
					net:hero_up(params, function(__data)
						delWaitNet()

						if __data.status <= 0 then
							showToast("status:" .. __data.status)
							return
						end
						
						audio.play(audio.hero_lv_up)
						local attr = heroData.attr()

						for i = 1, __data.status do
							local spiritNeed = GetSpiritCost(heroData.lv + 1)
							local goldNeed = GetGoldCost(heroData.lv + 1)
							bag.items.sub({ id = ITEM_ID_HERO_EXP, num = spiritNeed })
							bag.items.sub({ id = ITEM_ID_COIN, num = goldNeed })
							heroData.lv = heroData.lv + 1
						end
						
						local nattr = heroData.attr()
						onLvUp(attr, nattr)

						animLv:playAnimation("animation", 1)
						showUpdateLayer:runAction(CCRemoveSelf:create())
						updatePowerAndLv()
						updateState()
					end)
                end
            end)
        end

        ---- show Attribute
        local attriBg = img.createUI9Sprite(img.ui.hero_attribute_lab_frame)
        attriBg:setPreferredSize(CCSize(366, 141))
        attriBg:setAnchorPoint(ccp(0.5, 0))
        attriBg:setPosition(214, 138)
        showUpdateLayer:addChild(attriBg)

        local showTitle = lbl.createFont1(18, i18n.global["hero_job_" .. cfghero[heroData.id].job].string, ccc3(0x94, 0x62, 0x42))
        showTitle:setPosition(182 + 2, 117)
        attriBg:addChild(showTitle)

        local showJob = img.createUISprite(img.ui["job_" .. cfghero[heroData.id].job])
        showJob:setPosition(showTitle:boundingBox():getMinX() - 25, 117)
        attriBg:addChild(showJob)

        local btnInfoSprite = img.createUISprite(img.ui.btn_detail)
        local btnInfo = SpineMenuItem:create(json.ui.button, btnInfoSprite)
        btnInfo:setScale(0.9)
        local menuInfo = CCMenu:createWithItem(btnInfo)
        btnInfo:setPosition(332 + 2, 115)
        menuInfo:setPosition(0, 0)
        attriBg:addChild(menuInfo)
        btnInfo:registerScriptTapHandler(function()
            audio.play(audio.button)
            board:addChild(require("ui.tips.attrdetail").create(heroData.attr()), 100)
        end)

        local attrData = heroData.attr()
        local attriInfo = {
            [1] = { icon = img.ui.hero_attr_hp , num = attrData.hp },
            [2] = { icon = img.ui.hero_attr_atk , num = attrData.atk },
            [3] = { icon = img.ui.hero_attr_def , num = attrData.arm },
            [4] = { icon = img.ui.hero_attr_spd , num = attrData.spd },
        }

        local showNum = {}
        for i=1, 4 do
            local eachBg = img.createUI9Sprite(img.ui.hero_icon_bg)
            eachBg:setPreferredSize(CCSize(80, 80))
            eachBg:setAnchorPoint(ccp(0, 0))
            eachBg:setPosition(87 * i - 76 + 2, 12)
            attriBg:addChild(eachBg)
        
            local icon = img.createUISprite(attriInfo[i].icon)
            icon:setPosition(40, 50)
            eachBg:addChild(icon)
        
            showNum[i] = lbl.createFont1(16, math.floor(attriInfo[i].num), ccc3(0x6f, 0x4c, 0x38))
            showNum[i]:setPosition(40, 20)
            eachBg:addChild(showNum[i])
        end

        local skillId = heros.gethskills(0, heroData)

        local showSkill = {}
        local skillTips = {}
        for i, v in ipairs(skillId) do
            showSkill[i] = img.createUISprite(img.ui.hero_skill_bg)
            showSkill[i]:setPosition(78 + 90 * ( i - 1 ), 77)
            showUpdateLayer:addChild(showSkill[i])

            local skillIcon = img.createSkill(v.id, v.lock)
            skillIcon:setPosition(showSkill[i]:getContentSize().width/2, showSkill[i]:getContentSize().height/2)
            showSkill[i]:addChild(skillIcon)
            if cfgskill[v.id].skiL then
                local skillLB = img.createUISprite(img.ui.hero_skilllevel_bg)
                skillLB:setPosition(showSkill[i]:getContentSize().width-15, showSkill[i]:getContentSize().height-15)
                showSkill[i]:addChild(skillLB)
                local skilllab = lbl.createFont1(18, cfgskill[v.id].skiL, ccc3(255, 246, 223))
                skilllab:setPosition(skillLB:getContentSize().width/2-1, skillLB:getContentSize().height/2+1)
                skillLB:addChild(skilllab)
            end

            local lock = v.lock
            if heroData.star >= v.lock then lock = 0 end
            skillTips[i] = require("ui.tips.skill").create(v.id, lock)
            skillTips[i]:setAnchorPoint(ccp(1, 0))
            skillTips[i]:setPosition(409, showSkill[i]:boundingBox():getMaxY() + 10)
            showUpdateLayer:addChild(skillTips[i])
            skillTips[i]:setVisible(false)

            if heroData.star < v.lock then
                setShader(skillIcon, SHADER_GRAY, true)
            end
        end
        
        local function updateAttrAndLvm()
            if heroData.lv < lvMax then
				local spiritNeed = GetSpiritCost(heroData.lv + 1)
                showCostExp:setString(spiritNeed)
                if spiritNeed > 100000 then
                    showCostExp:setString((tostring(math.ceil(spiritNeed/1000)) .. "k"))
                end
                local goldNeed = GetGoldCost(heroData.lv + 1)
                showCostGold:setString(goldNeed)
                if goldNeed > 100000 then
                    showCostGold:setString((tostring(math.ceil(goldNeed/1000)) .. "k"))
                end
                local exp = 0
                local coin = 0
                if bag.items.find(ITEM_ID_HERO_EXP) then
                    exp = bag.items.find(ITEM_ID_HERO_EXP).num
                end
                if bag.items.find(ITEM_ID_COIN) then
                    coin = bag.items.find(ITEM_ID_COIN).num
                end
                if exp < spiritNeed then
                    showCostExp:setColor(ccc3(0xff, 0x2c, 0x2c))
                end 
                if coin < goldNeed then
                    showCostGold:setColor(ccc3(0xff, 0x2c, 0x2c))
                end
            else
                local img_maxlv = img.ui.hero_maxlv
                if i18n.getCurrentLanguage() == kLanguageChinese then
                    img_maxlv = img.ui.hero_maxlv_cn
                elseif i18n.getCurrentLanguage() == kLanguageChineseTW then
                    img_maxlv = img.ui.hero_maxlv_tw
                elseif i18n.getCurrentLanguage() == kLanguageJapanese then
                    img_maxlv = img.ui.hero_maxlv_jp
                elseif i18n.getCurrentLanguage() == kLanguageRussian then
                    img_maxlv = img.ui.hero_maxlv_ru
                elseif i18n.getCurrentLanguage() == kLanguageKorean then
                    img_maxlv = img.ui.hero_maxlv_kr
                end
                local showMaxLv = img.createUISprite(img_maxlv)
                showMaxLv:setAnchorPoint(ccp(0, 0.5))
                showMaxLv:setPosition(titleExp:boundingBox():getMaxX() + 12, titleExp:boundingBox():getMidY())
                showUpdateLayer:addChild(showMaxLv)
                showCostExp:setVisible(false)
                showCostGold:setVisible(false)
                expCostBg:setVisible(false) 
                expIcon:setVisible(false)
                goldIcon:setVisible(false)
            end
        
            if heroData.lv >= lvMax then 
                if btnLvUpSprite and not tolua.isnull(btnLvUpSprite) then 
                    btnLvUpSprite:setVisible(false)
                    btnLvUpSprite:removeFromParent()
                    btnLvUpSprite = nil
                end
            end
            if (heroData.star < cfghero[heroData.id].qlt and heroData.lv >= lvMax) or heroData.lv < lvMax then
                if btnStarUpSprite and not tolua.isnull(btnStarUpSprite) then 
                    btnStarUpSprite:setVisible(false)
                    btnStarUpSprite:removeFromParent()
                    btnStarUpSprite = nil
                end
                btnStarUpSprite = img.createUISprite(img.ui.hero_btn_lvup)
				--setShader(btnStarUpSprite, SHADER_INJURED, true)

				if heroData.star < cfghero[heroData.id].qlt and heroData.lv >= lvMax then
					local showRed = img.createUISprite(img.ui.main_red_dot)
					showRed:setPosition(btnStarUpSprite:getContentSize().width - 5, btnStarUpSprite:getContentSize().height - 5)
					btnStarUpSprite:addChild(showRed)
				end
                btnStarUp = SpineMenuItem:create(json.ui.button, btnStarUpSprite)
                local menuStarUp = CCMenu:createWithItem(btnStarUp)
                btnStarUp:setAnchorPoint(ccp(0, 0.5))
                btnStarUp:setPosition(346, titleEvolve:boundingBox():getMidY())
                menuStarUp:setPosition(0, 0)
                showUpdateLayer:addChild(menuStarUp)
                btnStarUp:registerScriptTapHandler(function()
                    audio.play(audio.button)
                    if heroData.lv >= lvMax then
                        superlayer:addChild(createEvolve(heroData, function()
                            if showUpdateLayer and not tolua.isnull(showUpdateLayer) then 
                                showUpdateLayer:runAction(CCRemoveSelf:create())
                                updatePowerAndLv()
                                updateState()
                            end
                        end), 10000)
                    else 
                        local goldNeed = GetGoldCost(heroData.lv + 1)
						local spiritNeed = GetGoldCost(heroData.lv + 1)
						local exp = 0
						local coin = 0
						if bag.items.find(ITEM_ID_HERO_EXP) then
							exp = bag.items.find(ITEM_ID_HERO_EXP).num
						end
						if bag.items.find(ITEM_ID_COIN) then
							coin = bag.items.find(ITEM_ID_COIN).num
						end
						if exp < spiritNeed then
							showToast(i18n.global.toast_hero_need_exp.string)
							return
						elseif coin < goldNeed then
							showToast(i18n.global.toast_hero_need_coin.string)
							return
						end
						local params = {
							sid = player.sid,
							hid = heroData.hid,
							type = 3,
						}
						addWaitNet()
						net:hero_up(params, function(__data)
							delWaitNet()

							if __data.status <= 0 then
								showToast("status:" .. __data.status)
								return
							end
							
							audio.play(audio.hero_lv_up)
							local attr = heroData.attr()

							for i = 1, __data.status do
								local spiritNeed = GetSpiritCost(heroData.lv + 1)
								local goldNeed = GetGoldCost(heroData.lv + 1)
								bag.items.sub({ id = ITEM_ID_HERO_EXP, num = spiritNeed })
								bag.items.sub({ id = ITEM_ID_COIN, num = goldNeed })
								heroData.lv = heroData.lv + 1
							end
							
							local nattr = heroData.attr()
							onLvUp(attr, nattr)

							animLv:playAnimation("animation", 1)
							updatePowerAndLv()
							updateAttrAndLvm()
						end)
                    end
                end)
            end

            attrData = heroData.attr()
            attriInfo = {
                [1] = { icon = img.ui.hero_attr_hp , num = attrData.hp },
                [2] = { icon = img.ui.hero_attr_atk , num = attrData.atk },
                [3] = { icon = img.ui.hero_attr_def , num = attrData.arm },
                [4] = { icon = img.ui.hero_attr_spd , num = attrData.spd },
            }
            for i=1,4 do
                showNum[i]:setString(math.floor(attriInfo[i].num))
            end
        end

        function Lvup()
            local exp = 0
            local coin = 0
            local goldNeed = GetGoldCost(heroData.lv + 1)
			local spiritNeed = GetSpiritCost(heroData.lv + 1)
            if bag.items.find(ITEM_ID_HERO_EXP) then
                exp = bag.items.find(ITEM_ID_HERO_EXP).num
            end
            if bag.items.find(ITEM_ID_COIN) then
                coin = bag.items.find(ITEM_ID_COIN).num
            end
            if heroData.lv >= lvMax then
                showToast(i18n.global.toast_hero_need_starup.string)
                return
            elseif exp < spiritNeed then
                showToast(i18n.global.toast_hero_need_exp.string)
                return
            elseif coin < goldNeed then
                showToast(i18n.global.toast_hero_need_coin.string)
                return
            end
            audio.play(audio.hero_lv_up)

            require("data.tutorial").goNext("hero", 2, true) 
            require("data.tutorial").goNext("hero", 1, true) 
            bag.items.sub({ id = ITEM_ID_HERO_EXP, num = spiritNeed })
            bag.items.sub({ id = ITEM_ID_COIN, num = goldNeed })
            local attr = heroData.attr() 
            heroData.lv = heroData.lv + 1
            local nattr = heroData.attr()
            onLvUp(attr, nattr)

            animLv:playAnimation("animation", 1)
            updatePowerAndLv()
            updateAttrAndLvm()

            local params = {
                sid = player.sid,
                hid = heroData.hid,
                type = 1,
            }
            net:hero_up(params, function(__data)
                if __data.status < 0 then
                    showToast("status:" .. __data.status)
                    return
                end
                tbl2string(__data)
            end)
        end

        local scheduler = nil
        local myupdate = nil 
        scheduler = CCDirector:sharedDirector():getScheduler()
        local timer = 0
        local function onTouch(eventType, x, y)
            local point = showUpdateLayer:convertToNodeSpace(ccp(x, y))
            for i, v in ipairs(showSkill) do
                if v:boundingBox():containsPoint(point) then
                    skillTips[i]:setVisible(true)
                else
                    skillTips[i]:setVisible(false)
                end
            end

            local function onUpdate(ticks)
                if btnLvUpSprite == nil and myupdate then
                    scheduler:unscheduleScriptEntry(myupdate)
                    myupdate = nil
                end
                Lvup()
                timer = timer + ticks
                if timer >= 30 and myupdate then
                    scheduler:unscheduleScriptEntry(myupdate)
                    myupdate = nil
                end
            end
            if eventType == "began" and btnLvUpSprite and not tolua.isnull(btnLvUpSprite) and btnLvUpSprite:boundingBox():containsPoint(point) then
                playAnimTouchBegin(btnLvUpSprite)
                Lvup()
                myupdate = scheduler:scheduleScriptFunc(onUpdate, 0.2, false)
            end
            if myupdate and eventType ~= "began" then
                if btnLvUpSprite and not tolua.isnull(btnLvUpSprite) then
                    playAnimTouchEnd(btnLvUpSprite)
                end
                scheduler:unscheduleScriptEntry(myupdate) 
                myupdate = nil
            end
            if eventType ~= "began" and eventType ~= "moved" then
                for i, v in ipairs(skillTips) do
                    v:setVisible(false)
                end
            end
            return true
        end

        showUpdateLayer:registerScriptTouchHandler(onTouch)
        showUpdateLayer:setTouchEnabled(true)
        showUpdateLayer:setTouchSwallowEnabled(false)
    end
   
    updateState()
    return layer
end

return info 
