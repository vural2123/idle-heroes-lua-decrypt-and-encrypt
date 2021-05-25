local ui = {}

require "common.func"
local view = require "common.view"
local i18n = require "res.i18n"
local lbl = require "res.lbl"
local img = require "res.img"
local audio = require "res.audio"
local json = require "res.json"
local cfghero = require "config.hero"
local cfgequip = require "config.equip"
local cfgskill = require "config.skill"
local cfglife = require "config.lifechange"
local player = require "data.player"
local activityData = require "data.activity"
local net = require "net.netClient"
local tipsequip = require "ui.tips.equip"
local tipsitem = require "ui.tips.item"
local herotips = require "ui.tips.hero"
local heros = require "data.heros"
local bag = require "data.bag"

local operData = {}
local fiveData = {}
local foodData = {}

local CURRENCY_ITEM = 168

local function getLeftWake()
	if player.isSeasonal() then
		return 4
	end
	return 7
end

local function getRightWake()
	return 4
end

local function getReqStone()
	if player.isSeasonal() then
		return 0
	end
	return 100
end

local function getFoodHeroCount()
	if player.isSeasonal() then
		return 0
	end
	return 2
end

local function getRightPickType()
	-- 0 can pick any active left or right, base hero will be always left
	-- 1 can't pick active at all, left active will be always, base hero will be always left
	-- 2 can pick either active, base hero will change to which active was picked
	return 2
end

local function isValidAugmentPrimaryHero(v)
	if not v.wake then
		return false
	end
	if player.isSeasonal() then
		if v.wake < 4 or v.wake > 7 then
			return false
		end
	else
		if v.wake ~= 7 then
			return false
		end
	end
	return true
end

local function isValidAugmentSecondaryHero(v, tendata)
	if not v.wake or (player.isSeasonal() and v.wake < 4) or (not player.isSeasonal() and v.wake ~= 4) then
		return false
	end
	if v.hid == tendata.hid or v.hskills then
		return false
	end
	return true
end

local function isValidAugmentTertiaryHero(v, fivedata)
	if player.isSeasonal() then return false end
	if not fivedata then
		return false
	end
	local h = cfghero[v.id]
	if not h or h.maxStar ~= 5 then
		return false
	end
	local life = cfglife[v.id]
	if not life or life.nId ~= fivedata.id then
		return false
	end
	return true
end

local function getPosOfObject(index)
	if index == 1 then
		return { x = index * 91 - 10, y = 170 }
	else
		return { x = index * 93, y = 170 }
	end
end

local function getPosOfUp(index)
	--return { x = index * 110, y = 319 }
	-- 94, 214, 334, 454
	return { x = math.floor(274 + (index - 2.5) * 120), y = 319 }
end

local function getPosOfPlus(index)
	local pos1 = getPosOfUp(index)
	local pos2 = getPosOfUp(index + 1)
	
	return { x = math.floor((pos2.x - pos1.x) / 2) + pos1.x, y = math.floor((pos2.y - pos1.y) / 2) + pos1.y }
end

local function getSkillCount()
	return 4
end

local function initHeros()
    local tmpheros = {}

    for i, v in ipairs(heros) do
        if isValidAugmentPrimaryHero(v) then
            tmpheros[#tmpheros + 1] = {
                hid = v.hid,
                id = v.id,
                lv = v.lv,
                wake = v.wake,
                star = v.star,
                isUsed = false,
                flag = v.flag or 0,
				hskills = v.hskills,
            }
        end
    end

    operData.heros = tmpheros
end

local function initfiveHeros(tendata)
    local tmpheros = {}

    for i, v in ipairs(heros) do
		if isValidAugmentSecondaryHero(v, tendata) then
            tmpheros[#tmpheros + 1] = {
                hid = v.hid,
                id = v.id,
                lv = v.lv,
                wake = v.wake,
                star = v.star,
                isUsed = false,
                flag = v.flag or 0,
				hskills = v.hskills,
            }
        end
    end

    fiveData.heros = tmpheros
end

local function initfoodHeros(fivedata)
    local tmpheros = {}

    for i, v in ipairs(heros) do
		if isValidAugmentTertiaryHero(v, fivedata) then
            tmpheros[#tmpheros + 1] = {
                hid = v.hid,
                id = v.id,
                lv = v.lv,
                wake = v.wake,
                star = v.star,
                isUsed = false,
                flag = v.flag or 0,
				hskills = v.hskills,
            }
        end
    end

    foodData.heros = tmpheros
end

local function createSelectBoard(callfunc, seltype)
    local layer = CCLayerColor:create(ccc4(0, 0, 0, 210))

    local headData = {}
	local xData = nil
	local selcount = 1

	if seltype == 1 then
		initHeros()
		xData = operData
	elseif seltype == 2 then
		xData = fiveData
	elseif seltype == 3 then
		selcount = getFoodHeroCount()
		xData = foodData
	end

	if xData and xData.heros then
		for i, v in ipairs(xData.heros) do
			headData[#headData + 1] = v
		end
	end

    table.sort(headData, function (a, b)
        if a.id ~= b.id then
            return a.id < b.id
		elseif a.lv ~= b.lv then
			return a.lv < b.lv
		else
			return a.hid < b.hid
        end
    end)

    local board = img.createUI9Sprite(img.ui.tips_bg)
    board:setPreferredSize(CCSize(520, 420))
    board:setScale(view.minScale)
    board:setPosition(view.midX, view.midY)
    layer:addChild(board)

    local showTitle = lbl.createFont1(20, i18n.global.heroforge_board_title.string, ccc3(0xff, 0xe3, 0x86))
    showTitle:setPosition(260, 386)
    board:addChild(showTitle)

    local showFgline = img.createUI9Sprite(img.ui.hero_enchant_info_fgline)
    showFgline:setPreferredSize(CCSize(453, 1))
    showFgline:setPosition(260, 354)
    board:addChild(showFgline)

    local tmpSelect = {}
    local showHeads = {}

    local function backEvent()
        layer:removeFromParentAndCleanup(true)
    end

    local btnCloseSp = img.createLoginSprite(img.login.button_close)
    local btnClose = SpineMenuItem:create(json.ui.button, btnCloseSp)
    btnClose:setPosition(495, 397)
    local menuClose = CCMenu:createWithItem(btnClose)
    menuClose:setPosition(0, 0)
    board:addChild(menuClose, 1000)
    btnClose:registerScriptTapHandler(function()
        audio.play(audio.button)
        backEvent()
    end)

    local height = 84 * math.ceil(#headData/5) 
    local scroll = CCScrollView:create()
    scroll:setDirection(kCCScrollViewDirectionVertical)
    scroll:setAnchorPoint(ccp(0, 0))
    scroll:setPosition(53, 113)
    scroll:setViewSize(CCSize(420, 225))
    scroll:setContentSize(CCSize(420, height+84))
    board:addChild(scroll)

    if #headData == 0 then
        local empty = require("ui.empty").create({ size = 16, text = i18n.global.empty_heromar.string, color = ccc3(255, 246, 223)})
        empty:setPosition(board:getContentSize().width/2, board:getContentSize().height/2)
        board:addChild(empty)
    end

    for i, v in ipairs(headData) do
        local x = math.ceil(i/5) 
        local y = i - (x - 1) * 5
        showHeads[i] = img.createHeroHead(v.id, v.lv, true, true, v.wake, nil, nil, nil, v.hskills)
        showHeads[i]:setScale(0.8)
        showHeads[i]:setAnchorPoint(ccp(0, 0))
        showHeads[i]:setPosition(2 + 84 * (y - 1), height - 84 * x - 5)
        scroll:getContainer():addChild(showHeads[i])
    
        if v.flag > 0 then
            local blackBoard = img.createUISprite(img.ui.hero_head_shade)
            blackBoard:setScale(88/94)
            blackBoard:setOpacity(120)
            blackBoard:setPosition(showHeads[i]:getContentSize().width/2, showHeads[i]:getContentSize().height/2)
            showHeads[i]:addChild(blackBoard, 101)
           
            local showLock = img.createUISprite(img.ui.devour_icon_lock)
            showLock:setPosition(showHeads[i]:getContentSize().width/2, showHeads[i]:getContentSize().height/2)
            showHeads[i]:addChild(showLock, 101)
        end
    end
    scroll:setContentOffset(ccp(0, 225 - height))

    local function onSelect(idx)
        if headData[idx].flag > 0 then
            local count = 0
            local text = ""
            if headData[idx].flag % 2 == 1 then
                text = text..i18n.global.toast_devour_arena.string
                count = count + 1
            end
            if math.floor((headData[idx].flag / 2)) % 2 == 1 then
                if count >= 1 then
                    text = text.."\n"
                end
                text = text..i18n.global.toast_devour_lock.string
                count = count + 1
            end
            if math.floor((headData[idx].flag / 4)) % 2 % 2 == 1 then
                if count >= 1 then
                    text = text.."\n"
                end
                text = text..i18n.global.toast_devour_3v3arena.string
                count = count + 1
            end
            if math.floor((headData[idx].flag / 8)) % 2 % 2 % 2 == 1 then
                if count >= 1 then
                    text = text.."\n"
                end
                text = text..i18n.global.toast_devour_frdarena.string
                count = count + 1
            end
            showToast(text)
            return
        end
        headData[idx].isUsed = true
        tmpSelect[#tmpSelect + 1] = headData[idx]
        local blackBoard = img.createUISprite(img.ui.hero_head_shade)
        blackBoard:setScale(88/94)
        blackBoard:setOpacity(120)
        blackBoard:setPosition(showHeads[idx]:getContentSize().width/2, showHeads[idx]:getContentSize().height/2)
        showHeads[idx]:addChild(blackBoard, 0, 1)

        local selectIcon = img.createUISprite(img.ui.hook_btn_sel)
        selectIcon:setPosition(blackBoard:getContentSize().width/2, blackBoard:getContentSize().height/2)
        blackBoard:addChild(selectIcon)       
    end
	
	local function clearSelect()
		for i, v in ipairs(headData) do
			if v.isUsed == true then
				v.isUsed = false
				if showHeads[i]:getChildByTag(1) then
					showHeads[i]:removeChildByTag(1)
				end
			end
		end
		tmpSelect = {}
	end

    local function onUnselect(idx)
        for i, v in ipairs(tmpSelect) do
            if v.hid == headData[idx].hid then
                tmpSelect[i], tmpSelect[#tmpSelect] = tmpSelect[#tmpSelect], tmpSelect[i]
                tmpSelect[#tmpSelect] = nil
                break
            end
        end
        headData[idx].isUsed = false
        if showHeads[idx]:getChildByTag(1) then
            showHeads[idx]:removeChildByTag(1)
        end
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
        local point = layer:convertToNodeSpace(ccp(x, y))
        local pointOnScroll = scroll:getContainer():convertToNodeSpace(ccp(x, y))

        if math.abs(y - lasty) > 10 then
            return
        end

        for i, v in ipairs(showHeads) do
            if v:boundingBox():containsPoint(pointOnScroll) then
				if headData[i].isUsed == true then
					onUnselect(i)
				elseif selcount == 1 and #tmpSelect == 1 then
					clearSelect()
					onSelect(i)
				elseif #tmpSelect < selcount then
					onSelect(i)
				end
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

    addBackEvent(layer)
    function layer.onAndroidBack()
        backEvent()
    end
    local function onEnter()
        print("onEnter")
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

    local btnSelectSp = img.createLogin9Sprite(img.login.button_9_small_gold)
    btnSelectSp:setPreferredSize(CCSize(150, 50))
    local labSelect = lbl.createFont1(16, i18n.global.heroforge_board_btn.string, ccc3(0x6a, 0x3d, 0x25))
    labSelect:setPosition(btnSelectSp:getContentSize().width/2, btnSelectSp:getContentSize().height/2)
    btnSelectSp:addChild(labSelect)

    local btnSelect = SpineMenuItem:create(json.ui.button, btnSelectSp)
    btnSelect:setPosition(260, 55)
    local menuSelect = CCMenu:createWithItem(btnSelect)
    menuSelect:setPosition(0, 0)
    board:addChild(menuSelect)

    btnSelect:registerScriptTapHandler(function()
        layer:removeFromParentAndCleanup(true)
        if tmpSelect and #tmpSelect ~= 0 then
            callfunc(tmpSelect)
        end
    end)

    board:setScale(0.5*view.minScale)
    local anim_arr = CCArray:create()
    anim_arr:addObject(CCScaleTo:create(0.15, view.minScale, view.minScale))
    anim_arr:addObject(CCDelayTime:create(0.15))
    anim_arr:addObject(CCCallFunc:create(function()
    
    end))
    board:runAction(CCSequence:create(anim_arr))

    return layer
end

local function createBoardForRewards(hid, reward)
    local heroData = heros.find(hid)

    local params = {}
    params.title = i18n.global.reward_will_get.string
    params.btn_count = 0

    local dialog = require("ui.dialog").create(params) 

    local back = img.createLogin9Sprite(img.login.button_9_small_gold)
    back:setPreferredSize(CCSize(153, 50))
    local comfirlab = lbl.createFont1(18, i18n.global.summon_comfirm.string, lbl.buttonColor)
    comfirlab:setPosition(CCPoint(back:getContentSize().width/2,
                                    back:getContentSize().height/2))
    back:addChild(comfirlab)
    local backBtn = SpineMenuItem:create(json.ui.button, back)
    backBtn:setPosition(CCPoint(dialog.board:getContentSize().width/2, 80))
    local menu = CCMenu:createWithItem(backBtn)
    menu:setPosition(0, 0)
    dialog.board:addChild(menu)

    dialog.board.tipsTag = false
    local hero = img.createHeroHeadByHid(hid)
    heroBtn = SpineMenuItem:create(json.ui.button, hero)
    heroBtn:setScale(0.85)
    heroBtn:setPosition(dialog.board:getContentSize().width/2, 185)

    local iconMenu = CCMenu:createWithItem(heroBtn)
    iconMenu:setPosition(0, 0)
    dialog.board:addChild(iconMenu)
    heroBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        local heroInfo = clone(heroData.attr())
        heroInfo.lv = heroData.lv
        heroInfo.star = heroData.star
        heroInfo.id = heroData.id
        heroInfo.wake = heroData.wake
		heroInfo.hskills = heroData.hskills
        local tips = herotips.create(heroInfo)
        dialog:addChild(tips, 1001)
    end)
    
    backBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        dialog:getParent():addChild((require"ui.hook.drops").create(reward, i18n.global.ui_decompose_preview.string), 1000)
        dialog:removeFromParentAndCleanup()
    end)
    dialog.setClickBlankHandler(function()
        dialog:getParent():addChild((require"ui.hook.drops").create(reward, i18n.global.ui_decompose_preview.string), 1000)
        dialog:removeFromParentAndCleanup()
    end)
    return dialog
end

local function updateBaseHero(temp_item, lherodata, rherodata, cont)
	local btype = getRightPickType()
	if cont.nineSp then
		cont.nineSp:removeFromParentAndCleanup()
		cont.nineSp = nil
	end
	local chosendata = nil
	if btype <= 1 then
		chosendata = lherodata
	else
		if cont.choice and #cont.choice > 0 and cont.choice[1] > 0 then
			if cont.choice[1] == 1 then
				chosendata = lherodata
			else
				chosendata = rherodata
			end
		end
	end
	if not chosendata then
		cont.nineSp = img.createHeroHead(9999, nil, true, false, 4)
		setShader(cont.nineSp, SHADER_GRAY, true)
	else
		cont.nineSp = img.createHeroHead(chosendata.id, nil, true, true, lherodata.wake, false, nil, nil, { 1101, 0 })
	end
	local ninePos = getPosOfObject(1)
	cont.nineSp:setPosition(ninePos.x, ninePos.y)
	temp_item:addChild(cont.nineSp)
end

local function selectSkillChoice(slot, index, cont)
	cont.choice[slot] = index
end

local function clearSkillsTemp(cont)
	if cont.things2 then
		for i=1, #cont.things2 do
			cont.things2[i]:setVisible(false)
		end
	end
	cont.things2 = {}
end

local function updateSkills(temp_item, lherodata, rherodata, cont)
	clearSkillsTemp(cont)
	
	if lherodata and getRightPickType() == 1 then
		cont.choice[1] = 1
	end
	
	local maxcount = getSkillCount()
	for i=1,maxcount do
		local showSkill = cont.skillbg[i]
		local choice = cont.choice[i]
		local skills = cont.skills1
		if i > 1 then
			skills = cont.skills2
		end
		local skillId = 0
		if choice > 0 then
			skillId = skills[choice]
		end
		if skillId > 0 and cfgskill[skillId] then
			local skillIcon = img.createSkill(skillId, 0)
			skillIcon:setPosition(showSkill:getContentSize().width/2, showSkill:getContentSize().height/2)
			showSkill:addChild(skillIcon)
			cont.things2[#cont.things2 + 1] = skillIcon
			--[[if cfgskill[skillId].skiL then
				local skillLB = img.createUISprite(img.ui.hero_skilllevel_bg)
				skillLB:setPosition(showSkill:getContentSize().width-15, showSkill:getContentSize().height-15)
				showSkill:addChild(skillLB)
				local skilllab = lbl.createFont1(18, cfgskill[skillId].skiL, ccc3(255, 246, 223))
				skilllab:setPosition(skillLB:getContentSize().width/2-1, skillLB:getContentSize().height/2+1)
				skillLB:addChild(skilllab)
			end--]]
			cont.plus[i]:setVisible(false)
		else
			cont.plus[i]:setVisible(true)
		end
	end
end

local function createSkillChoice(temp_item, lherodata, rherodata, cont)
	clearSkillsTemp(cont)
	cont.choice = {}
	cont.skills1 = {}
	cont.skills2 = {}
	
	if lherodata then
		local hskills = heros.gethskills(0, lherodata)
		for i=1, #hskills do
			if i == 1 then
				cont.skills1[#cont.skills1 + 1] = hskills[i].id
			else
				cont.skills2[#cont.skills2 + 1] = hskills[i].id
			end
		end
	end
	
	if rherodata then
		local hskills = heros.gethskills(0, rherodata)
		for i=1, #hskills do
			if i == 1 then
				cont.skills1[#cont.skills1 + 1] = hskills[i].id
			else
				cont.skills2[#cont.skills2 + 1] = hskills[i].id
			end
		end
	end
	
	local maxchoice = getSkillCount()
	
	if not cont.things then
		cont.things = {}
		cont.skillbg = {}
		cont.plus = {}
		for i=1, maxchoice do
			cont.choice[i] = 0
			
			local bpos = getPosOfObject(i + 1)
			
			local showSkill = img.createUISprite(img.ui.hero_skill_bg)
			showSkill:setPosition(bpos.x, bpos.y)
			temp_item:addChild(showSkill)
			cont.things[#cont.things + 1] = showSkill
			cont.skillbg[#cont.skillbg + 1] = showSkill
			
			local showAdd = img.createUISprite(img.ui.hero_equip_add)
			showAdd:setPosition(showSkill:getContentSize().width/2, showSkill:getContentSize().height/2)
			showSkill:addChild(showAdd)
			cont.plus[i] = showAdd
			--showAdd:runAction(CCRepeatForever:create(CCSequence:createWithTwoActions(CCFadeOut:create(1), CCFadeIn:create(1))))
		end
	else
		for i=1, maxchoice do
			cont.choice[i] = 0
		end
	end
	
	updateSkills(temp_item, lherodata, rherodata, cont)
end

function ui.create()
    local layer = CCLayer:create()

    local vps = {}
    for _, v in ipairs({ 998 }) do
        local tmp_status = activityData.getStatusById(v)
		if tmp_status then
			vps[#vps+1] = tmp_status
		end
    end

    local board = CCSprite:create()
    board:setContentSize(CCSizeMake(570, 438))
    board:setScale(view.minScale)
    board:setAnchorPoint(CCPoint(0, 0))
    board:setPosition(scalep(362, 60))
    layer:addChild(board)
    --drawBoundingbox(layer, board)
    local board_w = board:getContentSize().width
    local board_h = board:getContentSize().height

    local btnInfoSprite = img.createUISprite(img.ui.btn_help)
    local btnInfo = SpineMenuItem:create(json.ui.button, btnInfoSprite)
    btnInfo:setPosition(520, board_h-42)
    local menuInfo = CCMenu:createWithItem(btnInfo)
    menuInfo:setPosition(0, 0)
    board:addChild(menuInfo, 100)
    btnInfo:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer:getParent():getParent():addChild(require("ui.help").create(i18n.global.help_hskills.string, i18n.global.help_title.string), 1000)
    end)
	
	local extraHeight = 166 - 12
	local pushHeight = extraHeight

    local temp_item = img.createUI9Sprite(img.ui.bottom_border_2)
    temp_item:setPreferredSize(CCSizeMake(548, 265 + extraHeight))
    temp_item:setAnchorPoint(CCPoint(0.5, 1))
    temp_item:setPosition(CCPoint(board_w/2-10, board_h-12))
    board:addChild(temp_item)

    local tenflag = false
    local fiveflag = false
    local hostHid = 0
    local sacHid = 0
    local tenId = 0
    local fiveId = 0
    local tenheroData = nil
	local fiveheroData = nil
	local foodHid = {}
	
	local cont = {}
    
    -- lbl at the top
    local changetips = lbl.createMixFont1(16, i18n.global.tenchange_tips.string, ccc3(0x73, 0x3b, 0x05))
    changetips:setPosition(548/2, 238 + pushHeight)
    temp_item:addChild(changetips)
	
	-- plus icons between head icons
	for i=1, 3 do
		local hpos = getPosOfPlus(i)
		local plusIcon = img.createUISprite(img.ui.activity_ten_plus)
		plusIcon:setPosition(hpos.x, hpos.y)
		plusIcon:setScale(0.75)
		temp_item:addChild(plusIcon)
	end
	
	local spPos1 = getPosOfUp(1)
	local spPos2 = getPosOfUp(2)
	local spPos3 = getPosOfUp(3)
	local spPos4 = getPosOfUp(4)

    -- itemicon
    local spStoneBg = img.createUISprite(img.ui.grid)
    local spStone = img.createItemIcon(CURRENCY_ITEM)
    spStone:setPosition(spStoneBg:getContentSize().width/2, spStoneBg:getContentSize().height/2)
    spStoneBg:addChild(spStone)
    local btnSpStone = CCMenuItemSprite:create(spStoneBg, nil)
	btnSpStone:setScale(0.9)
    btnSpStone:setPosition(spPos4.x, spPos4.y)
    local menubtnSpStone = CCMenu:createWithItem(btnSpStone)
    menubtnSpStone:setPosition(0, 0)
    temp_item:addChild(menubtnSpStone)

    btnSpStone:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer:getParent():getParent():addChild(tipsitem.createForShow({id=CURRENCY_ITEM}), 1000)
    end)
    
    local stonenum = 0
    if bag.items.find(CURRENCY_ITEM) then
        stonenum = bag.items.find(CURRENCY_ITEM).num
    end

    local showStonenum = lbl.createFont2(16, string.format("%d/" .. getReqStone(), stonenum), ccc3(0xff, 0x74, 0x74))
    showStonenum:setPosition(spPos4.x, spPos4.y - 60)
    temp_item:addChild(showStonenum)

    if stonenum < getReqStone() then
        showStonenum:setColor(ccc3(0xff, 0x74, 0x74))
    else
        showStonenum:setColor(ccc3(0xff, 0xf7, 0xe5))
    end

    local showTennum = lbl.createFont2(16, "0/1", ccc3(0xff, 0x74, 0x74))
    showTennum:setPosition(spPos1.x, spPos1.y - 60)
    temp_item:addChild(showTennum)
    local showFivenum = lbl.createFont2(16, "0/1", ccc3(0xff, 0x74, 0x74))
    showFivenum:setPosition(spPos2.x, spPos2.y - 60)
    temp_item:addChild(showFivenum)
	local showFoodnum = lbl.createFont2(16, "0/" .. getFoodHeroCount(), ccc3(0xff, 0x74, 0x74))
    showFoodnum:setPosition(spPos3.x, spPos3.y - 60)
	if getFoodHeroCount() == 0 then
		showFoodnum:setColor(ccc3(0xff, 0xf7, 0xe5))
	end
    temp_item:addChild(showFoodnum)
	
    -- ten star
    local tenSp = nil
    local btnTenhero = nil
    local menuTenHero = nil
    local createBtnten = nil
    -- five
    local fiveSp = nil
    local btnFivehero = nil
    local menuFiveHero = nil
    local createBtnfive = nil
	-- food
    local foodSp = nil
    local btnFoodhero = nil
    local menuFoodHero = nil
    local createBtnfood = nil

    local function callfuncTen(herodatalist)
		if not herodatalist or #herodatalist ~= 1 then return end
		local herodata = herodatalist[1]
        if tenflag == false then
            tenflag = true
            clearShader(btnTenhero, true)
            showTennum:setString("1/1")
            showTennum:setColor(ccc3(0xff, 0xf7, 0xe5))
        end
        
        tenheroData = herodata
        tenId = herodata.id
        initfiveHeros(herodata)
        hostHid = herodata.hid

        menuTenHero:removeFromParentAndCleanup()
        menuTenHero = nil
        createBtnten(tenId, tenheroData.wake)

        fiveId = 0
		sacHid = 0
		fiveheroData = nil
		fiveflag = false
		showFivenum:setColor(ccc3(0xff, 0x74, 0x74))
        showFivenum:setString("0/1")
        menuFiveHero:removeFromParentAndCleanup()
        menuFiveHero = nil
        createBtnfive(9999, getRightWake())
		
		foodHid = {}
		showFoodnum:setString("0/" .. getFoodHeroCount())
		menuFoodHero:removeFromParentAndCleanup()
		menuFoodHero = nil
		createBtnfood()
    end

    createBtnten = function(id, tenwake)
		if tenwake == 4 then
            tenSp = img.createHeroHead(id, nil, true, false, tenwake, false) 
        else
            tenSp = img.createHeroHead(id, nil, true, true, tenwake, false) 
        end
        local bgSize = tenSp:getContentSize()
        if tenwake == 4 then
            local star = img.createUISprite(img.ui.hero_star_ten)
            star:setScale(0.75)
            star:setPosition(bgSize.width/2, 14)
            tenSp:addChild(star)
        end

        if id == 9999 then
            setShader(tenSp, SHADER_GRAY, true)
        end

        local icon = img.createUISprite(img.ui.hero_equip_add)
        icon:setPosition(tenSp:boundingBox():getMaxX()+23, tenSp:boundingBox():getMaxY() + 23)
        tenSp:addChild(icon)
        icon:runAction(CCRepeatForever:create(CCSequence:createWithTwoActions(
            CCFadeTo:create(0.5, 255 * 0.3), CCFadeTo:create(0.5, 255))))

        btnTenhero = CCMenuItemSprite:create(tenSp, nil)
        btnTenhero:setScale(0.9)
        btnTenhero:setPosition(spPos1.x, spPos1.y)
        menuTenHero = CCMenu:createWithItem(btnTenhero)
        menuTenHero:setPosition(0, 0)
        temp_item:addChild(menuTenHero)

        btnTenhero:registerScriptTapHandler(function()
            audio.play(audio.button)
            layer:getParent():getParent():addChild(createSelectBoard(callfuncTen, 1), 2000)
        end)
		
		local thdata = tenheroData
		if id == 9999 then
			thdata = nil
		end
		updateBaseHero(temp_item, thdata, fiveheroData, cont)
    end
    createBtnten(9999, getLeftWake())


    local function callfuncFive(herodatalist)
		if not herodatalist or #herodatalist ~= 1 then return end
		local herodata = herodatalist[1]
        if fiveflag == false then
            fiveflag = true
            clearShader(btnFivehero, true)
			showFivenum:setString("1/1")
			showFivenum:setColor(ccc3(0xff, 0xf7, 0xe5))
        end
		
		fiveheroData = herodata
        fiveId = herodata.id
        sacHid = herodata.hid
        
        menuFiveHero:removeFromParentAndCleanup()
        menuFiveHero = nil
        createBtnfive(fiveId, herodata.wake)
		
		foodHid = {}
		showFoodnum:setString("0/" .. getFoodHeroCount())
		menuFoodHero:removeFromParentAndCleanup()
		menuFoodHero = nil
		createBtnfood()
    end

    createBtnfive = function(id, tenwake)
		if tenwake == 4 then
            fiveSp = img.createHeroHead(id, nil, true, false, tenwake, false) 
        else
            fiveSp = img.createHeroHead(id, nil, true, true, tenwake, false) 
        end
        local fivebgSize = fiveSp:getContentSize()
        if id%100 == 99 then
            setShader(fiveSp, SHADER_GRAY, true)
        end
        if id ~= 9999 then
            local icon = img.createUISprite(img.ui.hero_equip_add)
            icon:setPosition(fiveSp:boundingBox():getMaxX()+23, fiveSp:boundingBox():getMaxY() + 23)
            fiveSp:addChild(icon)
            icon:runAction(CCRepeatForever:create(CCSequence:createWithTwoActions(
                CCFadeTo:create(0.5, 255 * 0.3), CCFadeTo:create(0.5, 255))))
        end
        btnFivehero = CCMenuItemSprite:create(fiveSp, nil)
        btnFivehero:setScale(0.9)
        btnFivehero:setPosition(spPos2.x, spPos2.y)
        menuFiveHero = CCMenu:createWithItem(btnFivehero)
        menuFiveHero:setPosition(0, 0)
        temp_item:addChild(menuFiveHero)

        btnFivehero:registerScriptTapHandler(function()
            audio.play(audio.button)
            if tenId == 0 then
                showToast(i18n.global.tenchange_toast_first.string)
                return
            end
            initfiveHeros(tenheroData)
            layer:getParent():getParent():addChild(createSelectBoard(callfuncFive, 2), 2000)
        end)
		
		createSkillChoice(temp_item, tenheroData, fiveheroData, cont)
    end
    createBtnfive(9999, getRightWake())
	
	
	local function callfuncFood(herodatalist)
		if not herodatalist then return end
		local foodflag = #foodHid == getFoodHeroCount()
		foodHid = {}
		for i, v in ipairs(herodatalist) do
			foodHid[#foodHid + 1] = v.hid
		end
		showFoodnum:setString(string.format("%d/" .. getFoodHeroCount(), #foodHid))
        if foodflag == false and #foodHid == getFoodHeroCount() then
            --clearShader(btnFoodhero, true)
			showFoodnum:setColor(ccc3(0xff, 0xf7, 0xe5))
		elseif foodflag == true and #foodHid ~= getFoodHeroCount() then
			showFoodnum:setColor(ccc3(0xff, 0x74, 0x74))
        end
		
		menuFoodHero:removeFromParentAndCleanup()
        menuFoodHero = nil
        createBtnfood()
    end

    createBtnfood = function()
		local id = 5999
		if fiveheroData and cfghero[fiveheroData.id] and cfghero[fiveheroData.id].fiveStarId then
			id = cfghero[fiveheroData.id].fiveStarId
		end
		foodSp = img.createHeroHead(id, nil, true, false, nil, false) 
        local fivebgSize = foodSp:getContentSize()
        if id%100 == 99 then
            setShader(foodSp, SHADER_GRAY, true)
        elseif getFoodHeroCount() > 0 then
            local icon = img.createUISprite(img.ui.hero_equip_add)
            icon:setPosition(foodSp:boundingBox():getMaxX()+23, foodSp:boundingBox():getMaxY() + 23)
            foodSp:addChild(icon)
            icon:runAction(CCRepeatForever:create(CCSequence:createWithTwoActions(
                CCFadeTo:create(0.5, 255 * 0.3), CCFadeTo:create(0.5, 255))))
        end
        btnFoodhero = CCMenuItemSprite:create(foodSp, nil)
        btnFoodhero:setScale(0.9)
        btnFoodhero:setPosition(spPos3.x, spPos3.y)
        menuFoodHero = CCMenu:createWithItem(btnFoodhero)
        menuFoodHero:setPosition(0, 0)
        temp_item:addChild(menuFoodHero)

        btnFoodhero:registerScriptTapHandler(function()
            audio.play(audio.button)
            if fiveId == 0 then
                showToast(i18n.global.tenchange_toast_first.string)
                return
            end
            initfoodHeros(fiveheroData)
            layer:getParent():getParent():addChild(createSelectBoard(callfuncFood, 3), 2000)
        end)
    end
    createBtnfood()

    local change = img.createLogin9Sprite(img.login.button_9_small_gold)
    change:setPreferredSize(CCSize(160, 52))
    local changelab = lbl.createFont1(18, i18n.global.heroforge_btn_text.string, lbl.buttonColor)
    changelab:setPosition(CCPoint(change:getContentSize().width/2,
                                    change:getContentSize().height/2))
    change:addChild(changelab)
    local changeBtn = SpineMenuItem:create(json.ui.button, change)
    changeBtn:setPosition(CCPoint(548/2, 55))
    local changeMenu = CCMenu:createWithItem(changeBtn)
    changeMenu:setPosition(0, 0)
    temp_item:addChild(changeMenu)
	
	json.load(json.ui.zhihuan_icon)

    local function createSurechange() 
        local params = {}
        params.title = "" 
        params.btn_count = 0
        local dialoglayer = require("ui.dialog").create(params) 

        local arrowSprite = img.createUISprite(img.ui.arrow)
        arrowSprite:setPosition(472/2, 180)
        dialoglayer.board:addChild(arrowSprite)
		
		local idten = tenheroData.id
		if getRightPickType() == 2 and cont.choice and #cont.choice > 0 and cont.choice[1] == 2 then
			idten = fiveheroData.id
		end

        local suretenSp = img.createHeroHead(idten, tenheroData.lv, true, true, tenheroData.wake, false, nil, nil, { 1101, 0 })
        local btnSureTenhero = CCMenuItemSprite:create(suretenSp, nil)
        btnSureTenhero:setPosition(472/2+100, 180)
        local menuSureTenHero = CCMenu:createWithItem(btnSureTenhero)
        menuSureTenHero:setPosition(0, 0)
        dialoglayer.board:addChild(menuSureTenHero)

        btnSureTenhero:registerScriptTapHandler(function()
            --audio.play(audio.button)
            --local sureheroData = heros.find(tenheroData.hid)
            --local heroInfo = clone(sureheroData.attr())
            --heroInfo.lv = sureheroData.lv
            --heroInfo.star = sureheroData.star
            --heroInfo.id = sureheroData.id
            --heroInfo.wake = sureheroData.wake
            --local tips = herotips.create(heroInfo)
            --dialoglayer:addChild(tips, 1001)
        end)

        local surefiveSp = img.createHeroHead(fiveheroData.id, fiveheroData.lv, true, true, fiveheroData.wake, false, nil, nil, fiveheroData.hskills) 
		setShader(surefiveSp, SHADER_GRAY, true)
        local btnSureFivehero = CCMenuItemSprite:create(surefiveSp, nil)
        btnSureFivehero:setPosition(472/2-100, 180)
		local delSprite = img.createUISprite(img.ui.mail_icon_del)
		delSprite:setPosition(18, 18) --(btnSureFivehero:getContentSize().width/2, btnSureFivehero:getContentSize().height/2)
		btnSureFivehero:addChild(delSprite)
        local menuSureFiveHero = CCMenu:createWithItem(btnSureFivehero)
        menuSureFiveHero:setPosition(0, 0)
        dialoglayer.board:addChild(menuSureFiveHero)

        btnSureFivehero:registerScriptTapHandler(function()
            --audio.play(audio.button)
        end)

        local btnYesSprite = img.createLogin9Sprite(img.login.button_9_small_gold)
        btnYesSprite:setPreferredSize(CCSize(153, 50))
        local btnYes = SpineMenuItem:create(json.ui.button, btnYesSprite)
        btnYes:setPosition(474/2+95, 80)
        local labYes = lbl.createFont1(18, i18n.global.dialog_button_confirm.string, ccc3(0x73, 0x3b, 0x05))
        labYes:setPosition(btnYes:getContentSize().width/2, btnYes:getContentSize().height/2)
        btnYesSprite:addChild(labYes)
        local menuYes = CCMenu:create()
        menuYes:setPosition(0, 0)
        menuYes:addChild(btnYes)
        dialoglayer.board:addChild(menuYes)

        local btnNoSprite = img.createLogin9Sprite(img.login.button_9_small_orange)
        btnNoSprite:setPreferredSize(CCSize(153, 50))
        local btnNo = SpineMenuItem:create(json.ui.button, btnNoSprite)
        btnNo:setPosition(474/2-95, 80)
        local labNo = lbl.createFont1(18, i18n.global.dialog_button_cancel.string, ccc3(0x73, 0x3b, 0x05))
        labNo:setPosition(btnNo:getContentSize().width/2, btnNo:getContentSize().height/2)
        btnNoSprite:addChild(labNo)
        local menuNo = CCMenu:create()
        menuNo:setPosition(0, 0)
        menuNo:addChild(btnNo)
        dialoglayer.board:addChild(menuNo)

        
        btnYes:registerScriptTapHandler(function()
            audio.play(audio.button)
			local parray = { sacHid }
			if foodHid then
				for i=1, #foodHid do
					parray[#parray + 1] = foodHid[i]
				end
			end
			if cont.choice then
				for i=1, #cont.choice do
					parray[#parray + 1] = cont.choice[i]
				end
			end
            local params = {
                sid = player.sid + 256,
                hostHid = hostHid,
                hids = parray
            }
            addWaitNet()
            net:hero_change(params, function(__data)
                delWaitNet()
                tbl2string(__data)
                if __data.status < 0 then
                    showToast("status:" .. __data.status)
                    return
                end
				
                local animZhihuan = DHSkeletonAnimation:createWithKey(json.ui.zhihuan_icon)
                animZhihuan:scheduleUpdateLua()
                animZhihuan:playAnimation("zhihuan")
                animZhihuan:setPosition(tenSp:boundingBox():getMidX(), tenSp:boundingBox():getMidY())
                tenSp:addChild(animZhihuan, 1001)

                local animZhihuanright = DHSkeletonAnimation:createWithKey(json.ui.zhihuan_icon)
                animZhihuanright:scheduleUpdateLua()
                animZhihuanright:playAnimation("zhihuan_right")
                animZhihuanright:setPosition(fiveSp:boundingBox():getMidX(), fiveSp:boundingBox():getMidY())
                fiveSp:addChild(animZhihuanright, 1001)

                local ban = CCLayer:create()
                ban:setTouchEnabled(true)
                ban:setTouchSwallowEnabled(true)
                layer:addChild(ban, 2000)
				if getReqStone() > 0 then
					bag.items.sub({id = CURRENCY_ITEM, num = getReqStone()})
				end

				local allFoods = { sacHid }
				if foodHid then
					for i, v in ipairs(foodHid) do
						allFoods[#allFoods + 1] = v
					end
				end
                local exp, evolve, rune = heros.decomposeFortenchange(allFoods)
                bag.items.add({ id = ITEM_ID_HERO_EXP, num = exp})
                bag.items.add({ id = ITEM_ID_EVOLVE_EXP, num = evolve})
                bag.items.add({ id = ITEM_ID_RUNE_COIN, num = rune})
                local reward = {items = {}, equips = {}}
                if exp > 0 then
                    table.insert(reward.items,{ id = ITEM_ID_HERO_EXP, num = exp})
                end
                if evolve > 0 then
                    table.insert(reward.items,{ id = ITEM_ID_EVOLVE_EXP, num = evolve})
                end
                if rune > 0 then
                    table.insert(reward.items,{ id = ITEM_ID_RUNE_COIN, num = rune})
                end

                for i, v in ipairs(allFoods) do
					local heroData = heros.find(v)
					if heroData then
						for j, k in ipairs(heroData.equips) do
							if cfgequip[k].pos == EQUIP_POS_JADE then
								bag.items.addAll(cfgequip[k].jadeUpgAll)
								if cfgequip[k].jadeUpgAll[1].num > 0 then
									table.insert(reward.items,{ id = cfgequip[k].jadeUpgAll[1].id, num = cfgequip[k].jadeUpgAll[1].num})
								end
								if cfgequip[k].jadeUpgAll[2].num > 0 then
									table.insert(reward.items,{ id = cfgequip[k].jadeUpgAll[2].id, num = cfgequip[k].jadeUpgAll[2].num})
								end
							else
								table.insert(reward.equips,{ id = k, num = 1})
							end
						end
					end
					heros.del(v)
                end

                local cTenheroData = heros.find(tenheroData.hid)
                local newskills = {}
				for i=1, #cont.choice do
					local hsk = cont.skills1
					if i > 1 then
						hsk = cont.skills2
					end
					newskills[#newskills + 1] = hsk[cont.choice[i]]
					newskills[#newskills + 1] = 0
				end
                --heros.tenchange(tenheroData, fiveId)
				cTenheroData.hskills = newskills
				if getRightPickType() == 2 and cont.choice[1] >= 2 then
					cTenheroData.id = fiveheroData.id
					if cTenheroData.equips then
						for _,v in ipairs(cTenheroData.equips) do
							if cfgequip[v].pos == EQUIP_POS_SKIN then
								bag.equips.returnbag({ id = v, num = 1})
								table.remove(cTenheroData.equips, _)
								break
							end
						end
					end
				end
                dialoglayer:removeFromParentAndCleanup(true)
                schedule(board, 2, function()
                    ban:removeFromParent()

                    layer:getParent():getParent():addChild(createBoardForRewards(hostHid, reward), 1002)

                    tenflag = false
                    fiveflag = false
                    hostHid = 0
                    sacHid = 0
                    fiveId = 0
					foodHid = {}
					fiveheroData = nil
                    --setShader(tenSp, SHADER_GRAY, true)
                    --setShader(fiveSp, SHADER_GRAY, true)
                    menuTenHero:removeFromParentAndCleanup()
                    menuTenHero = nil
                    createBtnten(9999, getLeftWake())
                    menuFiveHero:removeFromParentAndCleanup()
                    menuFiveHero = nil
                    createBtnfive(9999, getRightWake())
					menuFoodHero:removeFromParentAndCleanup()
                    menuFoodHero = nil
                    createBtnfood()
                    showTennum:setString("0/1")
                    showTennum:setColor(ccc3(0xff, 0xf7, 0xe5))
                    showFivenum:setString("0/1")
                    showFivenum:setColor(ccc3(0xff, 0xf7, 0xe5))
					if getFoodHeroCount() > 0 then
						showFoodnum:setString("0/" .. getFoodHeroCount())
						showFoodnum:setColor(ccc3(0xff, 0xf7, 0xe5))
					end
                    stonenum = stonenum - getReqStone()
                    if stonenum < getReqStone() then
                        showStonenum:setColor(ccc3(0xff, 0x74, 0x74))
                    end
                    showStonenum:setString(string.format("%d/" .. getReqStone(), stonenum))
                end)
            end)
        end)

        btnNo:registerScriptTapHandler(function()
            dialoglayer:removeFromParentAndCleanup(true)
            audio.play(audio.button)
        end)

        local function backEvent()
            dialoglayer:removeFromParentAndCleanup(true)
        end

        -- btn_close
        local btn_close0 = img.createUISprite(img.ui.close)
        local btn_close = SpineMenuItem:create(json.ui.button, btn_close0)
        --btn_close:setPosition(CCPoint(board_w-32, board_h-74))
        btn_close:setPosition(474-30, 327-28)
        local btn_close_menu = CCMenu:createWithItem(btn_close)
        btn_close_menu:setPosition(CCPoint(0, 0))
        dialoglayer.board:addChild(btn_close_menu, 100)
        btn_close:registerScriptTapHandler(function()
            audio.play(audio.button)
            backEvent()
        end)

        function dialoglayer.onAndroidBack()
            backEvent()
        end

        addBackEvent(dialoglayer)
        
        local function onEnter()
            dialoglayer.notifyParentLock()
        end

        local function onExit()
            dialoglayer.notifyParentUnlock()
        end

        dialoglayer:registerScriptHandler(function(event) 
            if event == "enter" then 
                onEnter()
            elseif event == "exit" then
                onExit()
            end
        end)
        return dialoglayer
    end

    changeBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        
		local foodCount = 0
		if foodHid then
			foodCount = #foodHid
		end
        if not tenheroData or not fiveheroData or not cont.choice or foodCount ~= getFoodHeroCount() then
            showToast(i18n.global.hero_wake_no_hero.string)
            return
        end
		
		for i=1, #cont.choice do
			if cont.choice[i] == 0 then
				showToast(i18n.global.hero_wake_no_hero.string)
				return
			end
		end

        local stonenum = 0
        if bag.items.find(CURRENCY_ITEM) then
            stonenum = bag.items.find(CURRENCY_ITEM).num
        end
        if stonenum < getReqStone() then
            showToast(i18n.global.tenchange_toast_noitem.string)
            return 
        end
        --[[if tenheroData.id == fiveId then
            showToast(i18n.global.tenchange_toast_nosamehero.string)
            return
        end--]]

        local dialog = createSurechange()
        layer:getParent():getParent():addChild(dialog, 300)
    end)
	
	local function onTouch(eventType, x, y)
		local point = temp_item:convertToNodeSpace(ccp(x, y))
		local selIndex = 0
		local skills = nil
		local choice = nil
		if eventType ~= "began" --[[and eventType ~= "moved"--]] then
		
		else
			for i=1,#cont.skillbg do
				local v = cont.skillbg[i]
				if v:boundingBox():containsPoint(point) then
					skills = cont.skills1
					if i > 1 then
						skills = cont.skills2
					end
					if skills and #skills ~= 0 then
						selIndex = i
						choice = {}
						if i > 1 then
							for j=2,#cont.choice do
								if cont.choice[j] > 0 then
									choice[#choice + 1] = cont.choice[j]
								end
							end
						else
							choice = {}
							if cont.choice[1] > 0 then
								choice[1] = cont.choice[1]
							end
						end
						break
					end
				end
			end
		end
		local minIndex = 0
		if getRightPickType() == 1 then
			minIndex = 1
		end
		if selIndex > minIndex then
			local curChoice = cont.choice[selIndex]
			layer:getParent():getParent():addChild(require("ui.activity.bigfuse_choice").create(skills, choice, curChoice, selIndex, function(__slot, __idx)
				selectSkillChoice(__slot, __idx, cont)
				updateSkills(temp_item, tenheroData, fiveheroData, cont)
				if __slot == 1 then
					updateBaseHero(temp_item, tenheroData, fiveheroData, cont)
				end
			end), 2000)
		end
		return true
	end

	temp_item:registerScriptTouchHandler(onTouch)
	temp_item:setTouchEnabled(true)
	temp_item:setTouchSwallowEnabled(false)

    return layer
end

return ui
