
local ui = {}

require "common.func"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local i18n = require "res.i18n"
local audio = require "res.audio"
local net = require "net.netClient"
local heros = require "data.heros"
local cfghero = require "config.hero"
local cfgequip = require "config.equip"
local bag = require "data.bag"
local player = require "data.player"
local petBattle = require "ui.pet.petBattle"
local data = require "ui.loadout.data"

local HERO_COUNT = 6
local EQUIP_COUNT = 5
local SKILL_COUNT = 3

local function initHerolistData(params)	
    local herolist = {}
	local tmpheros = clone(heros) -- clone because we are taking the heroInfo references but we need copied
    for i, v in ipairs(tmpheros) do
        if params.group then
            if cfghero[v.id].group == params.group then
                herolist[#herolist + 1] = v
            else
                for j=1, HERO_COUNT  do
                    if params.content.stand[j] and params.content.stand[j].hid == v.hid then
                        herolist[#herolist + 1] = v
                    end
                end
            end
        else
            herolist[#herolist + 1] = v
        end
    end

    for i, v in ipairs(herolist) do
        v.isUsed = false
    end

    table.sort(herolist, compareHero)

    local whitelist = {}
	for _, v in pairs(params.content.stand) do
		whitelist[#whitelist + 1] = v.hid
	end
    local tlist = herolistless(herolist, whitelist)
    return tlist
end

local function getStandCount(stand)
	local ss = 0
	if stand then
		for i=1, 6 do
			if stand[i] then ss = ss + 1 end
		end
	end
	return ss
end

local function onHadleBattle(layer, params)
    if getStandCount(params.content.stand) == 0 then
        showToast(i18n.global.toast_selhero_needhero.string)
        return
    end
	
	local checkError = data.checkValidMulti({ params.content })
	if not checkError or checkError ~= 0 then
		data.showValidError(checkError)
		return
	end
	
	local ashids = data.pack(params.content)
	local nparams = {
		sid = player.sid + 0x200,
		hid = 0,
		equips = ashids,
	}
	addWaitNet()
	net:wear(nparams, function(__data)
		delWaitNet()
		tbl2string(__data)

		if __data.status < 0 then
			showToast("status:" .. __data.status)
			return 
		end
		
		layer:removeFromParentAndCleanup(true)
		if params.callback then
			params.callback(params.content)
		end
	end)
end

local function createEquipLayer(params, unitPos, eqPos, onWear)
    local layer = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))

	local heroData = heros.find(params.content.stand[unitPos].hid)
    local equips = {}
	local all = data.getAllEquipsChoice(params.content, unitPos)
    for id, num in pairs(all) do
        local cf = cfgequip[id]
		if cf and cf.pos == eqPos and cf.lv <= heroData.lv and num > 0 then
			equips[#equips + 1] = { id = id, num = num }
		end
    end

    table.sort(equips, compareEquip)

    local board = img.createLogin9Sprite(img.login.dialog)
    board:setPreferredSize(CCSize(644, 484))
    board:setScale(view.minScale)
    board:setPosition(view.midX, view.midY)
    layer:addChild(board)

    local innerBg = img.createUI9Sprite(img.ui.bag_btn_inner_bg)
    innerBg:setPreferredSize(CCSize(591, 374))
    innerBg:setAnchorPoint(ccp(0, 0))
    innerBg:setPosition(27, 37)
    board:addChild(innerBg)

    if #equips == 0 then
        if eqPos == EQUIP_POS_TREASURE then
            local empty = require("ui.empty").create({ text = i18n.global.empty_treasure.string })
            empty:setPosition(innerBg:getContentSize().width/2, innerBg:getContentSize().height/2)
            innerBg:addChild(empty)
        else
            local empty = require("ui.empty").create({ text = i18n.global.empty_wear.string })
            empty:setPosition(innerBg:getContentSize().width/2, innerBg:getContentSize().height/2)
            innerBg:addChild(empty)
        end
    end
    
    local btnCloseSprite = img.createUISprite(img.ui.close)
    local btnClose = SpineMenuItem:create(json.ui.button, btnCloseSprite)
    btnClose:setPosition(621, 458)
    local menuClose = CCMenu:createWithItem(btnClose)
    menuClose:setPosition(0, 0)
    board:addChild(menuClose)
    btnClose:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer:removeFromParentAndCleanup(true)
    end)

    local Height = 92 * (#equips/6 + 1) 
    local scroll = CCScrollView:create()
    scroll:setDirection(kCCScrollViewDirectionVertical)
    scroll:setAnchorPoint(ccp(0, 0))
    scroll:setPosition(12, 14)
    scroll:setViewSize(CCSize(573, 348))
    scroll:setContentSize(CCSize(573, Height))
    scroll:setContentOffset(ccp(0, 348 - Height))
    innerBg:addChild(scroll)

    local showEquips = {}
    for i,v in ipairs(equips) do
        local x, y = (i - math.ceil(i/6) * 6 + 6) * 92 - 81, math.ceil(i/6) * 92 
        showEquips[i] = img.createEquip(v.id, v.num)
        showEquips[i]:setAnchorPoint(ccp(0, 0))
        showEquips[i]:setPosition(x, Height - y - 4)
        scroll:getContainer():addChild(showEquips[i])
    end

    local lasty
    local function onTouchBegin(x, y)
        lasty = y
        return true 
    end

    local function onTouchMoved(x, y)
        return true
    end

    local function onTouchEnd(x, y)
        local point = scroll:getContainer():convertToNodeSpace(ccp(x, y))
        local pointOnBoard = board:convertToNodeSpace(ccp(x, y))
        if math.abs(y - lasty) > 10 or not innerBg:boundingBox():containsPoint(pointOnBoard) then
            return true
        end

        for i, v in ipairs(showEquips) do
            if v:boundingBox():containsPoint(point) then
				if equips[i].num > 0 then
					local oldEquips = params.content.stand[unitPos].equips
					local newEquips = {}
					if oldEquips then
						for _, id in ipairs(oldEquips) do
							local cf = cfgequip[id]
							if cf and cf.pos ~= eqPos then
								newEquips[#newEquips + 1] = id
							end
						end
					end
					newEquips[#newEquips + 1] = equips[i].id
					params.content.stand[unitPos].equips = newEquips
					onWear()
					if layer and not tolua.isnull(layer) then
						layer:removeFromParentAndCleanup(true)
					end
				else
					showToast(i18n.global.empty_equips.string)
				end
				break
            end
        end 
        
        return true
    end

    local function onTouch(eventType, x, y)
        if eventType == "began" then
            return onTouchBegin(x, y)        
        elseif eventType == "moved" then
            return onTouchMoved(x, y)
        else
            return onTouchEnd(x, y)
        end
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

function ui.create(params)
    local layer = CCLayer:create()
	
	local darkbg = CCLayerColor:create(ccc4(0, 0, 0, 0))
    layer:addChild(darkbg)

    local board = img.createLogin9Sprite(img.login.dialog)
	local extraHeight = 140
	local extraHalf = math.floor(extraHeight / 2)
    board:setPreferredSize(CCSize(825, 410 + extraHeight))
    board:setScale(view.minScale)
    board:setPosition(view.midX, view.midY)
    layer:addChild(board)

    local btnCloseSprite = img.createUISprite(img.ui.close)
    local btnClose = SpineMenuItem:create(json.ui.button, btnCloseSprite)
    btnClose:setPosition(800, 385 + extraHeight)
    local menuClose = CCMenu:createWithItem(btnClose)
    menuClose:setPosition(0, 0)
    board:addChild(menuClose)
    btnClose:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer:removeFromParentAndCleanup(true)
    end)

    local title = lbl.createFont1(26, i18n.global.select_hero_title.string, ccc3(0xe6, 0xd0, 0xae))
    title:setPosition(413, 382 + extraHeight)
    board:addChild(title, 1)

    local titleShade = lbl.createFont1(26, i18n.global.select_hero_title.string, ccc3(0x59, 0x30, 0x1b))
    titleShade:setPosition(413, 380 + extraHeight)
    board:addChild(titleShade)

    local heroCampBg = img.createUI9Sprite(img.ui.select_hero_camp_bg)
    heroCampBg:setPreferredSize(CCSize(770, 260 + extraHeight))
	heroCampBg:setAnchorPoint(ccp(0.5, 0))
    heroCampBg:setPosition(414, 32) --235 + extraHeight)
    board:addChild(heroCampBg, 1)
	
	local choiceHeight = 60
	local choiceIconBg = img.createUI9Sprite(img.ui.herolist_withouthero_bg)
	choiceIconBg:setPreferredSize(CCSize(choiceHeight, choiceHeight))
	choiceIconBg:setAnchorPoint(ccp(0.5, 0))
	choiceIconBg:setPosition(70, 32 + 260 + extraHeight + 2)
	board:addChild(choiceIconBg)
	
	local choiceIcon = nil
	
	local function updateChoiceIcon()
		if choiceIcon then
			choiceIcon:removeFromParent()
			choiceIcon = nil
		end
		choiceIcon = img.createPlayerHeadById(params.content.icon)
		choiceIcon:setPosition(choiceIconBg:getContentSize().width/2, choiceIconBg:getContentSize().height/2)
		choiceIcon:setScale(choiceHeight/106)
		choiceIconBg:addChild(choiceIcon)
	end
	
	local showName = string.format(i18n.global.loadout_name.string, params.content.id)
	local showLoad = lbl.createMixFont1(20, showName, ccc3(0x94, 0x62, 0x42))
	showLoad:setAnchorPoint(ccp(0, 0.5))
	showLoad:setPosition(choiceIconBg:getPositionX() + choiceHeight / 2 + 20, choiceIconBg:getPositionY() + choiceHeight / 2)
	board:addChild(showLoad)
	
	updateChoiceIcon()

    --[[local heroSkillBg = img.createUI9Sprite(img.ui.select_hero_buff_bg)
    heroSkillBg:setPreferredSize(CCSize(769, 76))
    heroSkillBg:setPosition(414, 75)
    board:addChild(heroSkillBg)

    local campWidget = require("ui.selecthero.campLayer").create()
    board:addChild(campWidget.layer,20)
    campWidget.layer:setPosition(CCPoint(11,35))--]]

    --[[local btnBattleSprite = img.createLogin9Sprite(img.login.button_9_small_gold)
    btnBattleSprite:setPreferredSize(CCSize(110, 78))
    local btnBattleIcon = img.createUISprite(img.ui.select_hero_btn_icon)
    btnBattleIcon:setPosition(btnBattleSprite:getContentSize().width/2, btnBattleSprite:getContentSize().height/2)
    btnBattleSprite:addChild(btnBattleIcon)

    local btnBattle = SpineMenuItem:create(json.ui.button, btnBattleSprite)
    btnBattle:setPosition(708, 211 + extraHeight)
    local menuBattle = CCMenu:createWithItem(btnBattle)
    menuBattle:setPosition(0, 0)
    board:addChild(menuBattle, 1)--]]

    local selectTeamBg = img.createUI9Sprite(img.ui.select_tab_tab_bg)
    selectTeamBg:setPreferredSize(CCSize(759, 37))
	selectTeamBg:setAnchorPoint(ccp(0.5, 0))
    selectTeamBg:setPosition(385, heroCampBg:getContentSize().height - 47)
    heroCampBg:addChild(selectTeamBg)

    local showPowerBg = img.createUISprite(img.ui.select_hero_power_bg)
    showPowerBg:setAnchorPoint(ccp(0, 0.5))
    showPowerBg:setPosition(0, 19)
    selectTeamBg:addChild(showPowerBg)

    local powerIcon = img.createUISprite(img.ui.power_icon)
    powerIcon:setScale(0.46)
    powerIcon:setPosition(27, 21)
    showPowerBg:addChild(powerIcon)

    local showPower = lbl.createFont2(20, "0")
    showPower:setAnchorPoint(ccp(0, 0.5))
    showPower:setPosition(powerIcon:boundingBox():getMaxX() + 15, powerIcon:boundingBox():getMidY())
    showPowerBg:addChild(showPower)

    --[[local labFront = lbl.createFont1(18, i18n.global.select_hero_front.string, ccc3(0x4e, 0x30, 0x18))
    labFront:setAnchorPoint(ccp(0.5, 0.5))
    labFront:setPosition(122, 135)
    heroCampBg:addChild(labFront)

    local labBehind = lbl.createFont1(18, i18n.global.select_hero_behind.string, ccc3(0x4e, 0x30, 0x18))
    labBehind:setAnchorPoint(ccp(0.5, 0.5))
    labBehind:setPosition(415, 135)
    heroCampBg:addChild(labBehind)--]]
	
	local padHeight = 8
	local iconHeight = 84
	local equipHeight = 70
	local itemHeight = iconHeight + padHeight * 2
	
	local scroll_params = {
		width = heroCampBg:getContentSize().width - 16,
		height = heroCampBg:getContentSize().height - 60,
	}
	local scrollmain = require("ui.lineScroll").create(scroll_params)
	scrollmain:setAnchorPoint(ccp(0, 0))
    scrollmain:setPosition(8, 8)
	scrollmain:setContentSize(CCSize(scroll_params.width, itemHeight * 6))
    heroCampBg:addChild(scrollmain)
	
	local baseHeroBg = {}
	local baseEquipBg = {}
	local baseSkillBg = {}
    local showHeros = {}
	local showEquips = {}
	local showSkills = {}
	local headIcons = {}
    local herolist = initHerolistData(params)
	
	for i=1, HERO_COUNT do
		baseEquipBg[i] = {}
		baseSkillBg[i] = {}
		showEquips[i] = {}
		showSkills[i] = {}
	end
	
	local function getPos(pos, index)
		local ypos = (HERO_COUNT - pos) * itemHeight + padHeight
		local xpos = 8
		if index <= 1 then
		elseif index <= EQUIP_COUNT + 1 then
			xpos = xpos + 24 + (index - 1) * (equipHeight + 12)
			ypos = ypos + (iconHeight - equipHeight) / 2 + 2
		else
			xpos = xpos + 36 + (EQUIP_COUNT + 1) * (equipHeight + 12)
			xpos = xpos + (index - 7) * 75
			ypos = ypos + (iconHeight - 60) / 2 + 2
		end
		return xpos, ypos
	end
	
	local function createItem(pos)
		local xpos, ypos = getPos(pos, 1)
		baseHeroBg[pos] = img.createUI9Sprite(img.ui.herolist_withouthero_bg)
        baseHeroBg[pos]:setPreferredSize(CCSize(iconHeight, iconHeight))
        baseHeroBg[pos]:setPosition(xpos, ypos)
        scrollmain:addChild(baseHeroBg[pos])
		
		local showAdd2 = img.createUISprite(img.ui.hero_equip_add)
		showAdd2:setPosition(baseHeroBg[pos]:getContentSize().width - 25, 25)
		baseHeroBg[pos]:addChild(showAdd2)
		showAdd2:runAction(CCRepeatForever:create(CCSequence:createWithTwoActions(CCFadeOut:create(1), CCFadeIn:create(1))))
		baseHeroBg[pos].showAdd = showAdd2
		
		xpos, ypos = getPos(pos, 2)
		local heroSkillBg1 = img.createUI9Sprite(img.ui.select_hero_buff_bg)
		heroSkillBg1:setPreferredSize(CCSize((equipHeight + 16) * EQUIP_COUNT - 24, equipHeight + 8))
		heroSkillBg1:setPosition(xpos - 8, ypos - 8)
		scrollmain:addChild(heroSkillBg1)
		
		xpos, ypos = getPos(pos, 7)
		local heroSkillBg2 = img.createUI9Sprite(img.ui.select_hero_buff_bg)
		heroSkillBg2:setPreferredSize(CCSize((75 + 0) * SKILL_COUNT - 12, equipHeight - 6))
		heroSkillBg2:setPosition(xpos - 4, ypos - 4)
		scrollmain:addChild(heroSkillBg2)
		
		for i=1, EQUIP_COUNT do
			local equipBg = img.createUISprite(img.ui.grid)
			baseEquipBg[pos][i] = equipBg
			--equipBg:setPreferredSize(CCSize(equipHeight, equipHeight))
			equipBg:setScale(equipHeight/94)
			xpos, ypos = getPos(pos, i + 1)
			equipBg:setPosition(xpos, ypos)
			scrollmain:addChild(equipBg)
			
			local showAdd = img.createUISprite(img.ui.hero_equip_add)
			showAdd:setPosition(equipBg:getContentSize().width - 25, 25)
			equipBg:addChild(showAdd)
			showAdd:runAction(CCRepeatForever:create(CCSequence:createWithTwoActions(CCFadeOut:create(1), CCFadeIn:create(1))))
			equipBg.showAdd = showAdd
		end
		
		for i=1, SKILL_COUNT do
			local skillIconBg = img.createUISprite(img.ui.hero_skill_bg)
			skillIconBg:setScale(0.65)
			baseSkillBg[pos][i] = skillIconBg
			local xpos, ypos = getPos(pos, i + 1 + 5)
			skillIconBg:setPosition(xpos, ypos)
			scrollmain:addChild(skillIconBg)
			
			--setShader(skill1IconBg, SHADER_GRAY, true)
			local showLock = img.createUISprite(img.ui.devour_icon_lock)
			showLock:setPosition(skillIconBg:getContentSize().width/2, skillIconBg:getContentSize().height/2)
			skillIconBg:addChild(showLock, 1)
			showLock:setVisible(false)
			skillIconBg.showLock = showLock
			
			local showAdd = img.createUISprite(img.ui.hero_equip_add)
			showAdd:setPosition(skillIconBg:getContentSize().width - 25, 25)
			skillIconBg:addChild(showAdd, 1)
			showAdd:runAction(CCRepeatForever:create(CCSequence:createWithTwoActions(CCFadeOut:create(1), CCFadeIn:create(1))))
			skillIconBg.showAdd = showAdd
		end
	end
	
	for i=1, HERO_COUNT do
		createItem(i)
	end
	
	local function updateSlot(pos)
		if showHeros[pos] then
			showHeros[pos]:removeFromParent()
			showHeros[pos] = nil
		end
		for _, v in pairs(showEquips[pos]) do
			v:removeFromParent()
		end
		showEquips[pos] = {}
		for _, v in pairs(showSkills[pos]) do
			v:removeFromParent()
		end
		showSkills[pos] = {}
		
		for i=1, EQUIP_COUNT do
			baseEquipBg[pos][i].showAdd:setVisible(false)
		end
		for i=1, SKILL_COUNT do
			baseSkillBg[pos][i].showAdd:setVisible(false)
			baseSkillBg[pos][i].showLock:setVisible(false)
		end
		
		local stand = params.content.stand[pos]
		local heroInfo = nil
		if stand then heroInfo = heros.find(stand.hid) end
		if not heroInfo then
			stand = nil
			params.content.stand[pos] = nil
		end
		if stand then
			baseHeroBg[pos].showAdd:setVisible(false)
			local petId = params.content.petID
			if petId and petId <= 0 then petId = nil end
			local param = {
				id = heroInfo.id,
				lv = heroInfo.lv,
				showGroup = true,
				showStar = 3,
				wake = heroInfo.wake,
				orangeFx = nil,
				petID = petId,
				hskills = heroInfo.hskills,
				hid = heroInfo.hid,
				--skin = nil,
			}
			showHeros[pos] = img.createHeroHeadByParam(param)
			showHeros[pos]:setScale(iconHeight/94)
			local xpos, ypos = getPos(pos, 1)
			showHeros[pos]:setPosition(xpos, ypos)
			scrollmain:addChild(showHeros[pos])
			
			for i=1, EQUIP_COUNT do
				local equipId = nil
				local wantPos = i
				if wantPos == 5 then wantPos = 6 end
				if stand.equips then
					for _, v in ipairs(stand.equips) do
						local cf = cfgequip[v]
						if cf and cf.pos == wantPos then
							equipId = v
							break
						end
					end
				end
				if equipId then
					local equipIcon = img.createEquip(equipId)
					equipIcon:setScale(equipHeight/74)
					equipIcon:setPosition(baseEquipBg[pos][i]:getContentSize().width/2, baseEquipBg[pos][i]:getContentSize().height/2)
					baseEquipBg[pos][i]:addChild(equipIcon)
					showEquips[pos][i] = equipIcon
				else
					baseEquipBg[pos][i].showAdd:setVisible(true)
				end
			end
			
			for i=1, SKILL_COUNT do
				local skillId = 6100
				if stand.skills and stand.skills[i] then
					skillId = stand.skills[i]
					if skillId == 0 then skillId = 6100 end
				end
				local skillIcon = img.createSkill(skillId)
				skillIcon:setPosition(baseSkillBg[pos][i]:getContentSize().width/2, baseSkillBg[pos][i]:getContentSize().height/2)
				baseSkillBg[pos][i]:addChild(skillIcon)
				showSkills[pos][i] = skillIcon
				
				if not heroInfo.wake or heroInfo.wake < 4 + i then
					setShader(skillIcon, SHADER_GRAY, true)
					baseSkillBg[pos][i].showLock:setVisible(true)
				elseif skillId == 6100 then
					baseSkillBg[pos][i].showAdd:setVisible(true)
				end
			end
		else
			baseHeroBg[pos].showAdd:setVisible(true)
		end
	end
	
	local function updateSlots()
		for i=1, HERO_COUNT do
			updateSlot(i)
		end
	end
	
	scrollmain:setContentOffset(ccp(0, scroll_params.height - itemHeight * HERO_COUNT))

    local function petCallBack()
		params.content.petID = petBattle.getNowSele() or -1
        updateSlots()
    end
	
    local spPet = img.createLogin9Sprite(img.login.button_9_small_purple)
    spPet:setPreferredSize(CCSizeMake(150, 46))
    local spIcon = img.createUISprite(img.ui.pet_leg)
    spPet:addChild(spIcon)
    local btnLal = lbl.createFont1(16, i18n.global.pet_battle_btn_lal.string, ccc3(0x5c, 0x19, 0x8e))
    spPet:addChild(btnLal)

    local btnPet = SpineMenuItem:create(json.ui.button, spPet)
    require("dhcomponents.DroidhangComponents"):mandateNode(btnPet,"yw_petBattle_btnPet")
    require("dhcomponents.DroidhangComponents"):mandateNode(spIcon,"yw_petBattle_spIcon")
    require("dhcomponents.DroidhangComponents"):mandateNode(btnLal,"yw_petBattle_btnLal")

    local menuPet = CCMenu:createWithItem(btnPet)
    menuPet:setPosition(0, 0)
    selectTeamBg:addChild(menuPet,1)
    btnPet:registerScriptTapHandler(function()
        btnPet:setEnabled(false)
        disableObjAWhile(btnPet)
        audio.play(audio.button)
        petBattle.create(layer, petCallBack)
    end)
	
	local btnOk, btnOkMenu = require("ui.custom").createButton(1, i18n.global.dialog_button_confirm.string, 150, 46, false)
	btnOk:setPosition(684 - 150 - 16, 17)
	selectTeamBg:addChild(btnOkMenu, 1)
	btnOk:registerScriptTapHandler(function()
		audio.play(audio.button)
		onHadleBattle(layer, params)
	end)
	
	local herolistMode = false
    
    local herolistBg = img.createUI9Sprite(img.ui.tips_bg)
    herolistBg:setPreferredSize(CCSize(957, 112))
    herolistBg:setScale(view.minScale)
    herolistBg:setAnchorPoint(ccp(0.5, 1))
    herolistBg:setPosition(view.midX, view.minY + 112 * view.minScale)
	herolistBg:setVisible(false)
    layer:addChild(herolistBg)

    SCROLLVIEW_WIDTH = 943 - 150
    SCROLLVIEW_HEIGHT = 112
    SCROLLCONTENT_WIDTH = #herolist * 90 + 8

    local scroll = CCScrollView:create()
    scroll:setDirection(kCCScrollViewDirectionHorizontal)
    scroll:setAnchorPoint(ccp(0, 0))
    scroll:setPosition(7, 0)
    scroll:setViewSize(CCSize(SCROLLVIEW_WIDTH, SCROLLVIEW_HEIGHT))
    scroll:setContentSize(CCSizeMake(SCROLLCONTENT_WIDTH, SCROLLVIEW_HEIGHT))
    herolistBg:addChild(scroll)

    local btnFilterSprite = img.createLogin9Sprite(img.login.button_9_small_gold)
    btnFilterSprite:setPreferredSize(CCSize(130, 70))
    local btnFilterIcon = lbl.createFont1(20, i18n.global.selecthero_btn_hero.string, ccc3(0x73, 0x3b, 0x05)) 
    btnFilterIcon:setPosition(btnFilterSprite:getContentSize().width/2, btnFilterSprite:getContentSize().height/2)
    btnFilterSprite:addChild(btnFilterIcon)

    local btnFilter = SpineMenuItem:create(json.ui.button, btnFilterSprite)
    btnFilter:setPosition(873, 56)
    local menuFilter = CCMenu:createWithItem(btnFilter)
    menuFilter:setPosition(0, 0)
    herolistBg:addChild(menuFilter, 1)
    
    local filterBg = img.createUI9Sprite(img.ui.tips_bg)
    filterBg:setPreferredSize(CCSize(122, 458))
    filterBg:setScale(view.minScale)
    filterBg:setAnchorPoint(ccp(1, 0))
    filterBg:setPosition(scalep(938, 110))
    layer:addChild(filterBg)

    local showHeroLayer = CCLayer:create()
    scroll:getContainer():addChild(showHeroLayer)

    --local iconBgBatch = img.createBatchNodeForUI(img.ui.herolist_head_bg)
    --scroll:getContainer():addChild(iconBgBatch, 1)
    --local groupBgBatch = img.createBatchNodeForUI(img.ui.herolist_group_bg)
    --scroll:getContainer():addChild(groupBgBatch , 3)
    --local starBatch = img.createBatchNodeForUI(img.ui.star_s)
    --scroll:getContainer():addChild(starBatch, 3)
    --blackBatch = CCNode:create()
    --scroll:getContainer():addChild(blackBatch, 4)
    --selectBatch = img.createBatchNodeForUI(img.ui.hook_btn_sel)
    --scroll:getContainer():addChild(selectBatch, 5)
    
    local selectBatch
    local blackBatch
    local function createHerolist()
        showHeroLayer:removeAllChildrenWithCleanup(true)
        arrayclear(headIcons)

        scroll:setContentSize(CCSizeMake(#herolist * 90 + 8, SCROLLVIEW_HEIGHT))
        scroll:setContentOffset(ccp(0, 0))
        local iconBgBatch = img.createBatchNodeForUI(img.ui.herolist_head_bg)
        showHeroLayer:addChild(iconBgBatch, 1)
        local iconBgBatch1 = img.createBatchNodeForUI(img.ui.hero_star_ten_bg)
        showHeroLayer:addChild(iconBgBatch1, 1)
        local groupBgBatch = img.createBatchNodeForUI(img.ui.herolist_group_bg)
        showHeroLayer:addChild(groupBgBatch , 3)
        local starBatch = img.createBatchNodeForUI(img.ui.star_s)
        showHeroLayer:addChild(starBatch, 3)
        local star10Batch = img.createBatchNodeForUI(img.ui.hero_star_ten)
        showHeroLayer:addChild(star10Batch, 3)
        local star1Batch = img.createBatchNodeForUI(img.ui.hero_star_orange)
        showHeroLayer:addChild(star1Batch, 3)
        blackBatch = CCNode:create()
        showHeroLayer:addChild(blackBatch, 5)
        selectBatch = img.createBatchNodeForUI(img.ui.hook_btn_sel)
        showHeroLayer:addChild(selectBatch, 5)

        for i=1, #herolist do
            local x, y = 45 + (i-1) * 90 + 8, 56 
       
            local qlt = cfghero[herolist[i].id].maxStar
            local heroBg = nil
            if qlt == 10 then
                heroBg = img.createUISprite(img.ui.hero_star_ten_bg)
                heroBg:setPosition(x, y)
                heroBg:setScale(0.92)
                iconBgBatch1:addChild(heroBg)
                json.load(json.ui.lv10_framefx)
            else
                heroBg = img.createUISprite(img.ui.herolist_head_bg)
                heroBg:setScale(0.92)
                heroBg:setPosition(x, y)
                iconBgBatch:addChild(heroBg)
            end

			local h = heros.find(herolist[i].hid)
			local cparam = {
				id = h.id,
				lv = h.lv,
				showGroup = true,
				showStar = true,
				wake = h.wake,
				hskills = h.hskills,
				hid = herolist[i].hid,
				--skin = nil,
			}
			headIcons[i] = img.createHeroHeadByParam(cparam)
            headIcons[i]:setScale(0.92)
            headIcons[i]:setPosition(x, y)
            showHeroLayer:addChild(headIcons[i], 2)
        end
    end
	
	local function selectIconCallback(icon)
		params.content.icon = icon
		updateChoiceIcon()
	end

    --local iconBuff
    --local iconTips 
    local function checkUpdate()
        local power = 0
		for i=1, 6 do
			if params.content.stand[i] then
				power = power + heros.power(params.content.stand[i].hid, params.content)
			end
		end

        showPower:setString(power)
		
        --[[if heroSkillBg:getChildByTag(1) then
            heroSkillBg:removeChildByTag(1)
        end

        for i=1, #require("ui.selecthero.campLayer").BuffTable do
            campWidget.icon[i]:setVisible(false)
        end
        
        local heroids = {}
		for i=1, 6 do 
			heroids[i] = nil
			local s = params.content.stand[i]
			if s then
				local h = heros.find(s.hid)
				if h then
					heroids[i] = h.id
				end
			end
		end

        local showIcon = require("ui.selecthero.campLayer").checkUpdateForHeroids(heroids,true)

        if showIcon ~= -1 then
            campWidget.icon[showIcon]:setVisible(true)
        end--]]
    end

    local function onMoveUp(pos, tpos, isNotCallBack)
        checkUpdate()
        if not isNotCallBack then
			updateSlot(tpos)
        end

        local blackBoard = CCLayerColor:create(ccc4(0, 0, 0, 120))
        blackBoard:setContentSize(CCSize(84, 84))
        blackBoard:setPosition(headIcons[pos]:getPositionX() - 42, headIcons[pos]:getPositionY() - 42)
        blackBatch:addChild(blackBoard, 0, pos)

        local selectIcon = img.createUISprite(img.ui.hook_btn_sel)
        selectIcon:setPosition(headIcons[pos]:getPositionX(), headIcons[pos]:getPositionY())
        selectBatch:addChild(selectIcon, 0, pos)
    end

    local function moveUp(pos)
        local tpos
        for i=1, HERO_COUNT do
            if not params.content.stand[i] then
                tpos = i
                break
            end
        end
		
		if tpos and not herolist[pos].isUsed then
            herolist[pos].isUsed = true
			params.content.stand[tpos] = {
				hid = herolist[pos].hid,
				equips = {},
				skills = {},
			}
            
            --[[local worldbpos = scroll:getContainer():convertToWorldSpace(ccp(headIcons[pos]:getPositionX(), headIcons[pos]:getPositionY()))
            local realbpos = board:convertToNodeSpace(worldbpos)
            local worldepos = heroCampBg:convertToWorldSpace(ccp(baseHeroBg[tpos]:getPositionX(), baseHeroBg[tpos]:getPositionY()))
            local realepos = board:convertToNodeSpace(worldepos)
            local param = {
                id = herolist[pos].id,
                --lv = herolist[pos].lv,
                --showGroup = true,
                --showStar = nil,
                --wake = nil,
                --orangeFx = nil,
                --petID = petBattle.getNowSele(),
                --hid = herolist[pos].hid
            }
            local tempHero = img.createHeroHeadByParam(param)
            tempHero:setScale(0.92)
            tempHero:setPosition(realbpos)
            board:addChild(tempHero, 100)
            
            local arr = CCArray:create()
            arr:addObject(CCMoveTo:create(0.1, realepos))
            local act1 = CCSpawn:create(arr)
            tempHero:runAction(CCSequence:createWithTwoActions(act1, CCCallFunc:create(function() 
                tempHero:removeFromParentAndCleanup(true)
                onMoveUp(pos, tpos)
            end)))--]]
			onMoveUp(pos, tpos)
        else
            if tpos then
                showToast(i18n.global.toast_selhero_selected.string)
            else
                showToast(i18n.global.toast_selhero_already.string)
            end
        end
    end

    local function onMoveDown(pos, tpos)
        checkUpdate()
		updateSlot(pos)
        blackBatch:removeChildByTag(tpos)
        selectBatch:removeChildByTag(tpos)
    end

    local function moveDown(pos)
        local tpos
        for i, v in ipairs(herolist) do
            if params.content.stand[pos] and params.content.stand[pos].hid == v.hid then
                tpos = i
                break
            end
        end

        if tpos then
            herolist[tpos].isUsed = false
			params.content.stand[pos] = nil
			
			--[[local worldbpos = heroCampBg:convertToWorldSpace(ccp(baseHeroBg[pos]:getPositionX(), baseHeroBg[pos]:getPositionY()))
            local realbpos = board:convertToNodeSpace(worldbpos)
            local worldepos = scroll:getContainer():convertToWorldSpace(ccp(headIcons[tpos]:getPositionX(), headIcons[tpos]:getPositionY()))
            local realepos = board:convertToNodeSpace(worldepos)
            local param = {
                id = herolist[tpos].id,
                --lv = herolist[tpos].lv,
                --showGroup = true,
                --showStar = nil,
                --wake = nil,
                --orangeFx = nil,
                --petID = petBattle.getNowSele(),
                --hid = herolist[tpos].hid
            }
            local tempHero = img.createHeroHeadByParam(param)
            tempHero:setPosition(realbpos)
            tempHero:setScale(0.92)
            board:addChild(tempHero, 100)
            
            local arr = CCArray:create()
            arr:addObject(CCMoveTo:create(0.1, realepos))
            local act1 = CCSpawn:create(arr)
            tempHero:runAction(CCSequence:createWithTwoActions(act1, CCCallFunc:create(function() 
                tempHero:removeFromParentAndCleanup(true)
                onMoveDown(pos, tpos)
            end)))--]]
			onMoveDown(pos, tpos)
        end
    end

    local lastx
	local lasty
    local preSelect
    local function onTouchBegin(x, y)
		preSelect = nil
        lastx = x
		lasty = y
		
        --[[local point = scrollmain:getContainer():convertToNodeSpace(ccp(x, y))
        for i=1, HERO_COUNT do
            if params.content.stand[i] and showHeros[i] and showHeros[i]:boundingBox():containsPoint(point) then
                preSelect = i
				break
            end
        end--]]
        
        return true 
    end

    local function onTouchMoved(x, y)
        --[[local point = scrollmain:getContainer():convertToNodeSpace(ccp(x, y))
       
        if preSelect and math.abs(y - lasty) >= 10 then
            showHeros[preSelect]:setPosition(point)
            showHeros[preSelect]:setZOrder(1)
        end--]]
        
        return true
    end

    local function onTouchEnd(x, y)
        if not scroll or tolua.isnull(scroll) then
            return
        end
	
		local rpoint = board:convertToNodeSpace(ccp(x, y))
        local point = scrollmain:getContainer():convertToNodeSpace(ccp(x, y))
        local pointOnScroll = scroll:getContainer():convertToNodeSpace(ccp(x, y))

		local disabledJustNow = false
		if herolistMode and not herolistBg:boundingBox():containsPoint(ccp(x, y)) then
			herolistMode = false
			disabledJustNow = true
			herolistBg:setVisible(false)
			filterBg:setVisible(false)
		end

        if herolistMode and math.abs(x - lastx) < 10 then
            for i,v in ipairs(headIcons) do
                if v:boundingBox():containsPoint(pointOnScroll) then
                    audio.play(audio.button)
                    moveUp(i)
					return true
                end
            end
        end
		if math.abs(y - lasty) < 10 then
			if choiceIconBg:boundingBox():containsPoint(rpoint) then
				audio.play(audio.button)
				layer:addChild(require("ui.player.changehead").create(params.content.icon, selectIconCallback), 1000)
				return true
			end
			for i=1,HERO_COUNT do
                if params.content.stand[i] and showHeros[i] then
					local heroInfo = heros.find(params.content.stand[i].hid)
					if showHeros[i]:boundingBox():containsPoint(point) then
						audio.play(audio.button)
						if disabledJustNow or herolistMode then
							moveDown(i)
							herolistMode = true
							herolistBg:setVisible(true)
						else
							herolistMode = true
							herolistBg:setVisible(true)
						end
						return true
					end
					for j=1,EQUIP_COUNT do
						if baseEquipBg[i][j]:boundingBox():containsPoint(point) then
							audio.play(audio.button)
							local eqPos = j
							if eqPos == 5 then eqPos = 6 end
							local thisIdx = i
							layer:addChild(createEquipLayer(params, i, eqPos, function()
								updateSlot(thisIdx)
								checkUpdate()
							end), 1000)
							return true
						end
					end
					for j=1,SKILL_COUNT do
						if heroInfo and heroInfo.wake and heroInfo.wake >= 4 + j and baseSkillBg[i][j]:boundingBox():containsPoint(point) then
							audio.play(audio.button)
							local thisIdx = i
							local cparam = {
								skills = params.content.stand[i].skills,
								callback = function(jpos, skillId)
									if params.content.stand[thisIdx] then
										local st = params.content.stand[thisIdx]
										if not st.skills then
											st.skills = {}
										end
										if skillId == 6100 then
											skillId = 0
										end
										st.skills[jpos] = skillId
										updateSlot(thisIdx)
										checkUpdate()
									end
								end,
							}
							layer:addChild(require("ui.hero.talenskill").create(heroInfo.wake - 4, j, nil, nil, cparam), 1000)
							return true
						end
					end
				elseif baseHeroBg[i]:boundingBox():containsPoint(point) then
					if not herolistMode then
						herolistMode = true
						herolistBg:setVisible(true)
						return true
					end
                end
            end
		end
 
        if not preSelect or math.abs(y - lasty) < 10 then
            return true
        end

        for i=1, HERO_COUNT do
            if baseHeroBg[i]:boundingBox():containsPoint(point) then
                if math.abs(showHeros[preSelect]:getPositionX() - baseHeroBg[i]:getPositionX()) < 33
                    and math.abs(showHeros[preSelect]:getPositionY() - baseHeroBg[i]:getPositionY()) < 33 then
                    params.content.stand[preSelect], params.content.stand[i] = params.content.stand[i], params.content.stand[preSelect]
					updateSlot(preSelect)
					updateSlot(i)
					return true
                end
            end
        end      
       
		showHeros[preSelect]:setPosition(baseHeroBg[preSelect]:getPosition())
		showHeros[preSelect]:setZOrder(0)
        return true
    end

    local function onTouch(eventType, x, y)
        if eventType == "began" then
            return onTouchBegin(x, y)        
        elseif eventType == "moved" then
            return onTouchMoved(x, y)
        else
            return onTouchEnd(x, y)
        end
    end

    layer:registerScriptTouchHandler(onTouch)
    layer:setTouchEnabled(true)

    --[[btnBattle:registerScriptTapHandler(function()
        audio.play(audio.fight_start_button)
        onHadleBattle(params)
    end)--]]

    local function initLoad()
        updateSlots()

        for i,v in ipairs(herolist) do
            for j=1, 6 do
                if params.content.stand[j] and v.hid == params.content.stand[j].hid then
                    onMoveUp(i, j, true)
                    herolist[i].isUsed = true
                end
            end
        end
    end
    createHerolist()
    initLoad()

    local function onEnter()
    
    end

    local function onExit()

    end

    layer:registerScriptHandler(function(event)
        if event == "enter" then
            onEnter()
        elseif event == "exit" then

        end
    end)
    
    --[[local anim_duration = 0.2
    board:setPosition(CCPoint(view.midX, view.minY+576*view.minScale))
    board:runAction(CCMoveTo:create(anim_duration, CCPoint(view.midX, view.minY+130*view.minScale)))
    herolistBg:runAction(CCMoveTo:create(anim_duration, CCPoint(view.midX, view.minY+123*view.minScale)))
    darkbg:runAction(CCFadeTo:create(anim_duration, POPUP_DARK_OPACITY))--]]

    local group
    local btnGroupList = {}
    for i=1, 6 do
        local btnGroupSpriteFg = img.createUISprite(img.ui["herolist_group_" .. i])
        local btnGroupSpriteBg = img.createUISprite(img.ui.herolist_group_bg)
        btnGroupSpriteFg:setPosition(btnGroupSpriteBg:getContentSize().width/2, btnGroupSpriteBg:getContentSize().height/2 + 2)
        btnGroupSpriteBg:addChild(btnGroupSpriteFg)
        btnGroupList[i] = HHMenuItem:createWithScale(btnGroupSpriteBg, 1)
        local btnGroupMenu = CCMenu:createWithItem(btnGroupList[i])
        btnGroupMenu:setPosition(0, 0)
        filterBg:addChild(btnGroupMenu, 10)
        btnGroupList[i]:setPosition(61, 52 + 70 * (i - 1))
        
        local showSelect = img.createUISprite(img.ui.herolist_select_icon)
        showSelect:setPosition(btnGroupList[i]:getContentSize().width/2, btnGroupList[i]:getContentSize().height/2 + 2)
        btnGroupList[i]:addChild(showSelect)
        btnGroupList[i].showSelect = showSelect
        showSelect:setVisible(false)

        btnGroupList[i]:registerScriptTapHandler(function()
            audio.play(audio.button)
            for j=1, 6 do
                btnGroupList[j]:unselected()
                btnGroupList[j].showSelect:setVisible(false)
            end
            if not group or i ~= group then
                group = i
                btnGroupList[i]:selected()
                btnGroupList[i].showSelect:setVisible(true)
            else
                group = nil
            end

			params.group = group
            herolist = initHerolistData(params)
            createHerolist()

            for i,v in ipairs(herolist) do
                for j=1, 6 do
                    if params.content.stand[j] and v.hid == params.content.stand[j].hid then
                        onMoveUp(i, j, true)
                        herolist[i].isUsed = true
                    end
                end
            end
        end)
    end

    filterBg:setVisible(false)
    btnFilter:registerScriptTapHandler(function()
        if filterBg:isVisible() == true then
            filterBg:setVisible(false)
        else
            filterBg:setVisible(true)
        end
    end)

    return layer
end

return ui
