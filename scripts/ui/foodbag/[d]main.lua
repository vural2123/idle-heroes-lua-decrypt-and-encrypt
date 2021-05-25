local ui = {}

require "common.func"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local i18n = require "res.i18n"
local audio = require "res.audio"
local net = require "net.netClient"
local cfghero = require "config.hero"
local heros = require "data.heros"
local bag = require "data.bag"
local player = require "data.player"
local food = require "ui.foodbag.data"
local cfgvip = require "config.vip"

local function gatherAllPossible(reqId, isHost, allowHero, allowFood, selectedFull, selectedHere)
	local skipThis = {}
	local hereThis = {}
	for i, v in ipairs(selectedFull) do
		if skipThis[v] then
			skipThis[v] = skipThis[v] + 1
		else
			skipThis[v] = 1
		end
	end
	for i, v in ipairs(selectedHere) do
		if skipThis[v] then
			skipThis[v] = skipThis[v] - 1
			if skipThis[v] == 0 then
				skipThis[v] = nil
			end
		end
		if hereThis[v] then
			hereThis[v] = hereThis[v] + 1
		else
			hereThis[v] = 1
		end
	end
	return food.getBestFodder(reqId, 100, isHost, allowHero, allowFood, skipThis, 3, hereThis)
end

function ui.createSelectBoard(reqId, reqCount, isHost, allowHero, allowFood, selectedFull, selHere, callback)
    local layer = CCLayerColor:create(ccc4(0, 0, 0, 210))
	
	--if allowFood and isHost then allowFood = false end
	
	local headData = gatherAllPossible(reqId, isHost, allowHero, allowFood, selectedFull, selHere)
	
	local selectedHere = {}
	for i, v in pairs(selHere) do
		selectedHere[i] = v
	end
	
    local board = img.createUI9Sprite(img.ui.tips_bg)
    board:setPreferredSize(CCSize(520, 420))
    board:setScale(view.minScale)
    board:setPosition(scalep(480, 288))
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
        backEvent()
        audio.play(audio.button)
    end)

    local height = 84 * math.ceil(#headData/5) 
    local scroll = CCScrollView:create()
    scroll:setDirection(kCCScrollViewDirectionVertical)
    scroll:setAnchorPoint(ccp(0, 0))
    scroll:setPosition(53, 113)
    scroll:setViewSize(CCSize(420, 225))
    scroll:setContentSize(CCSize(420, height))
    board:addChild(scroll)
    
    if #headData == 0 then
        local empty = require("ui.empty").create({ size = 16, text = i18n.global.empty_heromar.string, color = ccc3(255, 246, 223)})
        empty:setPosition(board:getContentSize().width/2, board:getContentSize().height/2)
        board:addChild(empty)
    end
    for i, v in ipairs(headData) do
        local x = math.ceil(i/5) 
        local y = i - (x - 1) * 5
		
		local heroId = v.hid
		local heroHid = nil
		if heroId < 0 then
			heroId = -heroId
		else
			heroHid = heroId
			local heroFind = heros.find(heroId)
			heroId = heroFind.id
		end
		
        local param = {
            id = heroId,
            lv = v.level,
            showGroup = true,
            showStar = true,
            wake = v.wake,
            orangeFx = nil,
            petID = nil,
            hid = heroHid
        }
        showHeads[i] = img.createHeroHeadByParam(param)
        showHeads[i]:setScale(0.8)
        showHeads[i]:setAnchorPoint(ccp(0, 0))
        showHeads[i]:setPosition(2 + 84 * (y - 1), height - 84 * x - 5)
        scroll:getContainer():addChild(showHeads[i])
    
        if v.lock then
            local blackBoard = img.createUISprite(img.ui.hero_head_shade)
            blackBoard:setScale(88/94)
            blackBoard:setOpacity(120)
            blackBoard:setPosition(showHeads[i]:getContentSize().width/2, showHeads[i]:getContentSize().height/2)
            showHeads[i]:addChild(blackBoard)
           
            local showLock = img.createUISprite(img.ui.devour_icon_lock)
            showLock:setPosition(showHeads[i]:getContentSize().width/2, showHeads[i]:getContentSize().height/2)
            showHeads[i]:addChild(showLock)
        end
    end
    scroll:setContentOffset(ccp(0, 225 - height))
    
    local function onSelect(idx, dummy)
        if headData[idx].lock then
            showToast(i18n.global.toast_devour_lock.string)
            return
        end
		if not dummy then
			selectedHere[#selectedHere + 1] = headData[idx].hid
		end
		tmpSelect[idx] = true
		
        local blackBoard = img.createUISprite(img.ui.hero_head_shade)
        blackBoard:setScale(88/94)
        blackBoard:setOpacity(120)
        blackBoard:setPosition(showHeads[idx]:getContentSize().width/2, showHeads[idx]:getContentSize().height/2)
        showHeads[idx]:addChild(blackBoard, 0, 1)

        local selectIcon = img.createUISprite(img.ui.hook_btn_sel)
        selectIcon:setPosition(blackBoard:getContentSize().width/2, blackBoard:getContentSize().height/2)
        blackBoard:addChild(selectIcon)       
    end
   
    local function onUnselect(idx)
		if headData[idx].lock then
			return
		end
        for i, v in ipairs(selectedHere) do
            if v == headData[idx].hid then
                selectedHere[i], selectedHere[#selectedHere] = selectedHere[#selectedHere], selectedHere[i]
                selectedHere[#selectedHere] = nil
                break
            end
        end
        tmpSelect[idx] = nil
        if showHeads[idx]:getChildByTag(1) then
            showHeads[idx]:removeChildByTag(1)
        end
    end
	
	for i, v in ipairs(selectedHere) do
		for j, k in ipairs(headData) do
			if not k.lock and not tmpSelect[j] and k.hid == v then
				onSelect(j, true)
				break
			end
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
				if tmpSelect[i] then
					onUnselect(i)
				elseif reqCount == 1 and #selectedHere == 1 then
					local firstKey = nil
					for _, x in pairs(tmpSelect) do
						firstKey = _
						break
					end
					onUnselect(firstKey)
					onSelect(i)
				elseif #selectedHere < reqCount then
					onSelect(i)
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
		for i=1, #selHere do
			selHere[i] = nil
		end
		for i=1, #selectedHere do
			selHere[i] = selectedHere[i]
		end
        layer:removeFromParentAndCleanup(true)
		if callback then
			callback()
		end
    end)

    board:setScale(0.5)
    local anim_arr = CCArray:create()
    anim_arr:addObject(CCScaleTo:create(0.15, 1*view.minScale, 1*view.minScale))
    anim_arr:addObject(CCDelayTime:create(0.15))
    anim_arr:addObject(CCCallFunc:create(function()
    
    end))
    board:runAction(CCSequence:create(anim_arr))

    return layer
end

local function createBoardForRewards(hid, callback)
    local heroData = heros.find(hid)

    local params = {}
    params.title = i18n.global.reward_will_get.string
    params.btn_count = 0

    local dialog = require("ui.dialog").create(params) 

    local back = img.createLogin9Sprite(img.login.button_9_small_gold)
    back:setPreferredSize(CCSize(153, 50))
    local comfirlab = lbl.createFont1(22, i18n.global.summon_comfirm.string, lbl.buttonColor)
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
        local herotips = require "ui.tips.hero"
        local heroInfo = clone(heroData.attr())
        heroInfo.lv = heroData.lv
        heroInfo.star = heroData.star
        heroInfo.id = heroData.id
        local tips = herotips.create(heroInfo)
        dialog:addChild(tips, 1001)
    end)
    
    backBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        dialog:removeFromParentAndCleanup()
		if callback then
			callback()
		end
    end)
    dialog.setClickBlankHandler(function()
        dialog:removeFromParentAndCleanup()
		if callback then
			callback()
		end
    end)
    return dialog
end

function ui.createSettings(heroListEntry, vParent)
    local layer = CCLayer:create()
    local TIPS_WIDTH , TIPS_HEIGHT = 278, 250
	
	local lbls = {
		--lbl.createFont1(20, i18n.global.foodbag_generic_fodder.string, ccc3(255, 246, 223))
		lbl.createMix({ font = 1, size = 20, text = i18n.global.foodbag_generic_fodder.string, width = 500 , color = ccc3(255, 246, 223), align = kCCTextAlignmentRight })
	}
	local btns = { }
	if heroListEntry.count > 0 then
		btns[#btns + 1] = { lb = lbl.createFont1(16, i18n.global.foodbag_undo.string, ccc3(0x6a, 0x3d, 0x25)) }
		--btns[#btns + 1] = { lb = lbl.createFont1(16, i18n.global.foodbag_undo.string .. " (10)", ccc3(0x6a, 0x3d, 0x25)) }
	end
	
	local icons = {}
	local flagByIndex = { 1 }
	
	local max_width = 200
	for i, v in ipairs(lbls) do
		max_width = math.max(max_width, v:getContentSize().width)
	end
	
	local extraHeight = 50
	
	for _, lb in ipairs(btns) do
		local btnSelectSp = img.createLogin9Sprite(img.login.button_9_small_gold)
		btnSelectSp:setPreferredSize(CCSize(200, 50))
		local labSelect = lb.lb
		labSelect:setPosition(btnSelectSp:getContentSize().width/2, btnSelectSp:getContentSize().height/2)
		btnSelectSp:addChild(labSelect)

		local btnSelect = SpineMenuItem:create(json.ui.button, btnSelectSp)
		lb.btn = btnSelect
	end
	
    TIPS_WIDTH = max_width + 110
	TIPS_HEIGHT = 50 * #lbls + 70 * #btns + extraHeight
	
    local bg = img.createUI9Sprite(img.ui.tips_bg)
    bg:setPreferredSize(CCSize(TIPS_WIDTH, TIPS_HEIGHT))
    bg:setScale(view.minScale)
    bg:setPosition(scalep(553, 426))
    layer:addChild(bg)
	
	for i, b in ipairs(btns) do
		local ixr = #btns - i
		b.btn:setPosition(math.floor(TIPS_WIDTH / 2), 25 + math.floor(extraHeight / 2) + 70 * ixr)
		local menuSelect = CCMenu:createWithItem(b.btn)
		menuSelect:setPosition(0, 0)
		bg:addChild(menuSelect)
	end
	
	local function updateFlagByIndex(idx)
		icons[idx]:setVisible(bit.band(heroListEntry.flags, flagByIndex[idx]) ~= 0)
    end
	local function updateFlagAll()
		for i, _ in ipairs(lbls) do
			updateFlagByIndex(i)
		end
	end

	for i, v in ipairs(lbls) do
		v:setAnchorPoint(CCPoint(1, 0.5))
		v:setPosition(CCPoint(TIPS_WIDTH-105, TIPS_HEIGHT - i * 50))
		bg:addChild(v)
		
		local btn_check0 = img.createUISprite(img.ui.guildFight_tick_bg)
		local icon_sel = img.createUISprite(img.ui.hook_btn_sel)
		icon_sel:setScale(0.75)
		icon_sel:setAnchorPoint(CCPoint(0, 0))
		icon_sel:setPosition(CCPoint(2, 2))
		icons[#icons+1] = icon_sel
		btn_check0:addChild(icon_sel)
		local btn_check = SpineMenuItem:create(json.ui.button, btn_check0)
		btn_check:setPosition(CCPoint(TIPS_WIDTH-55, TIPS_HEIGHT - i * 50))
		local btn_check_menu = CCMenu:createWithItem(btn_check)
		btn_check_menu:setPosition(CCPoint(0, 0))
		bg:addChild(btn_check_menu)
		--btns[#btns + 1] = btn_check
		
		local curIdx = i
		btn_check:registerScriptTapHandler(function()
			audio.play(audio.button)
			local chatblocks
			local wantflags
			local curflags = food.getToggledFlags(heroListEntry.id, heroListEntry.flags)
			local st = bit.band(curflags, flagByIndex[curIdx])
			if st == 0 then
				chatblocks = 0x100 + flagByIndex[curIdx]
				wantflags = curflags + flagByIndex[curIdx]
			else
				chatblocks = 0x200 + flagByIndex[curIdx]
				wantflags = curflags - flagByIndex[curIdx]
			end
			local nparams = {
				sid = player.sid,
				hid = heroListEntry.id,
				lock = chatblocks,
			}
			addWaitNet()
			net:hero_lock(nparams, function(__data)
				delWaitNet()

				if __data.status < 0 then
					showToast("server status:" .. __data.status)
					return
				end
				
				wantflags = food.getToggledFlags(heroListEntry.id, wantflags)
				heroListEntry.flags = wantflags
				if vParent and vParent.lockc then
					vParent.lockc:setVisible(bit.band(wantflags, 1) == 0)
				end
				food.setFlag(heroListEntry.id, wantflags)
				updateFlagByIndex(curIdx)
			end)
		end)
	end

    updateFlagAll()
	
    local function backEvent()
        audio.play(audio.button)
        layer:removeFromParentAndCleanup(true)
    end
	
	if #btns >= 1 then
		--[[btns[1].btn:registerScriptTapHandler(function()
			local hconv = 1
			if heroListEntry.count < hconv then
				showToast(i18n.global.empty_heromar.string)
				return
			end
			
			if #heros + hconv > cfgvip[player.vipLv()].heroes + player.buy_hlimit*5 then
				showToast(i18n.global.summon_hero_full.string)
				return
			end
			
			local nparams = {
				sid = player.sid,
				hid = heroListEntry.id,
				lock = 17,
			}
			addWaitNet()
			net:hero_lock(nparams, function(__data)
				delWaitNet()

				if __data.status < 0 then
					showToast("server status:" .. __data.status)
					return
				end
				
				for i=1,hconv do
					local heroLv = 1
					local heroStar = 0
					if cfghero[heroListEntry.id].maxStar > 6 then
						heroLv = 100
						heroStar = 6
					end
					heros.add({ hid = __data.status + (i - 1), id = heroListEntry.id, lv = heroLv, star = heroStar }, true)
				end
				
				food.modCount(heroListEntry.id, -hconv)
				heroListEntry.count = heroListEntry.count - hconv
				local wantRefresh = false
				if vParent and vParent.lvc and heroListEntry.count > 0 then
					vParent.lvc:setString("" .. heroListEntry.count)
				else
					wantRefresh = true
				end
				
				layer:addChild(createBoardForRewards(__data.status, function()
					if wantRefresh then
						layer:getParent().needFresh = true
					end
					backEvent()
				end), 1001)
			end)
		end)--]]
		btns[1].btn:registerScriptTapHandler(function()
			local thing = { id = heroListEntry.id, num = heroListEntry.count }
			layer:addChild(require("ui.tips.summon").create("hero", thing, function(harg)
				local hconv = harg.num
				local hen = harg.id
				if heroListEntry.count < hconv then
					showToast(i18n.global.empty_heromar.string)
					return
				end
				
				if #heros + hconv > cfgvip[player.vipLv()].heroes + player.buy_hlimit*5 then
					showToast(i18n.global.summon_hero_full.string)
					return
				end
				
				local nparams = {
					sid = player.sid,
					hid = hen,
					lock = 0x800 + hconv,
				}
				addWaitNet()
				net:hero_lock(nparams, function(__data)
					delWaitNet()

					if __data.status < 0 then
						showToast("server status:" .. __data.status)
						return
					end
					
					for i=1,hconv do
						local heroLv = 1
						local heroStar = 0
						if cfghero[hen].maxStar > 6 then
							heroLv = 100
							heroStar = 6
						end
						heros.add({ hid = __data.status + (i - 1), id = hen, lv = heroLv, star = heroStar }, true)
					end
					
					food.modCount(hen, -hconv)
					heroListEntry.count = heroListEntry.count - hconv
					local wantRefresh = false
					if vParent and vParent.lvc and heroListEntry.count > 0 then
						vParent.lvc:setString("" .. heroListEntry.count)
					else
						wantRefresh = true
					end
					
					layer:addChild(createBoardForRewards(__data.status, function()
						if wantRefresh then
							layer:getParent().needFresh = true
						end
						backEvent()
					end), 1001)
				end)
			end), 1001)
		end)
	end
	
	--[[if #btns >= 2 then
		btns[2].btn:registerScriptTapHandler(function()
			local hconv = 10
			if heroListEntry.count < hconv then
				showToast(i18n.global.empty_heromar.string)
				return
			end
			
			if #heros + hconv > cfgvip[player.vipLv()].heroes + player.buy_hlimit*5 then
				showToast(i18n.global.summon_hero_full.string)
				return
			end
			
			local nparams = {
				sid = player.sid,
				hid = heroListEntry.id,
				lock = 21,
			}
			addWaitNet()
			net:hero_lock(nparams, function(__data)
				delWaitNet()

				if __data.status < 0 then
					showToast("server status:" .. __data.status)
					return
				end
				
				for i=1,hconv do
					local heroLv = 1
					local heroStar = 0
					if cfghero[heroListEntry.id].maxStar > 6 then
						heroLv = 100
						heroStar = 6
					end
					heros.add({ hid = __data.status + (i - 1), id = heroListEntry.id, lv = heroLv, star = heroStar }, true)
				end
				
				food.modCount(heroListEntry.id, -hconv)
				heroListEntry.count = heroListEntry.count - hconv
				local wantRefresh = false
				if vParent and vParent.lvc and heroListEntry.count > 0 then
					vParent.lvc:setString("" .. heroListEntry.count)
				else
					wantRefresh = true
				end
				
				layer:addChild(createBoardForRewards(__data.status, function()
					if wantRefresh then
						layer:getParent().needFresh = true
					end
					backEvent()
				end), 1001)
			end)
		end)
	end--]]

    addBackEvent(layer)
    function layer.onAndroidBack()
        backEvent()
    end
    -- touch event
    local touchbeginx, touchbeginy
    local isclick
    local function onTouchBegan(x, y)
        touchbeginx, touchbeginy = x, y
        isclick = true
        return true
    end
    local function onTouchMoved(x, y)
        if isclick and (math.abs(touchbeginx-x) > 10 or math.abs(touchbeginy-y) > 10) then
            isclick = false
        end
    end
    local function onTouchEnded(x, y)
        local p0 = layer:convertToNodeSpace(ccp(x, y))
        if not bg:boundingBox():containsPoint(p0) then
            backEvent()
        end
    end
    local function onTouch(eventType, x, y)
        if eventType == "began" then   
            return onTouchBegan(x, y)
        elseif eventType == "moved" then
            return onTouchMoved(x, y)
        else
            return onTouchEnded(x, y)
        end
    end
    layer:registerScriptTouchHandler(onTouch , false , -128 , false)

    layer:setTouchEnabled(true)
    layer:setTouchSwallowEnabled(true)
    return layer
end

local function sortForDisplay(herolist)
	table.sort(herolist, function(a,b)
		local at = cfghero[a.id].maxStar
		local bt = cfghero[b.id].maxStar
		if at ~= bt then
			return at > bt
		end
		at = cfghero[a.id].group
		bt = cfghero[b.id].group
		if at ~= bt then
			return at > bt
		end
		at = a.id
		bt = b.id
		return at > bt
	end)
end

function ui.create(params)
    local layer = CCLayer:create()

    layer.needFresh = false
    local params = params or {}

    local bg = img.createUISprite(img.ui.bag_bg)
    bg:setScale(view.minScale)
    bg:setPosition(view.midX, view.midY)
    layer:addChild(bg)
	
	local function createSurebuy()
		local params = {}
		params.btn_count = 0
		params.body = string.format(i18n.global.foodbag_mass.string, 20)
		local board_w = 474

		local dialoglayer = require("ui.dialog").create(params) 

		local btnYesSprite = img.createLogin9Sprite(img.login.button_9_small_gold)
		btnYesSprite:setPreferredSize(CCSize(153, 50))
		local btnYes = SpineMenuItem:create(json.ui.button, btnYesSprite)
		btnYes:setPosition(board_w/2+95, 100)
		local labYes = lbl.createFont1(18, i18n.global.board_confirm_yes.string, ccc3(0x73, 0x3b, 0x05))
		labYes:setPosition(btnYes:getContentSize().width/2, btnYes:getContentSize().height/2)
		btnYesSprite:addChild(labYes)
		local menuYes = CCMenu:create()
		menuYes:setPosition(0, 0)
		menuYes:addChild(btnYes)
		dialoglayer.board:addChild(menuYes)

		local btnNoSprite = img.createLogin9Sprite(img.login.button_9_small_gold)
		btnNoSprite:setPreferredSize(CCSize(153, 50))
		local btnNo = SpineMenuItem:create(json.ui.button, btnNoSprite)
		btnNo:setPosition(board_w/2-95, 100)
		local labNo = lbl.createFont1(18, i18n.global.board_confirm_no.string, ccc3(0x73, 0x3b, 0x05))
		labNo:setPosition(btnNo:getContentSize().width/2, btnNo:getContentSize().height/2)
		btnNoSprite:addChild(labNo)
		local menuNo = CCMenu:create()
		menuNo:setPosition(0, 0)
		menuNo:addChild(btnNo)
		dialoglayer.board:addChild(menuNo)

		btnYes:registerScriptTapHandler(function()
			local params = {
				sid = player.sid,
				hid = 0,
				lock = 19,
			}
			--tbl2string(params)
			addWaitNet()
			net:hero_lock(params, function(__data)
				delWaitNet()

				if __data.status < 0 then
					audio.play(audio.button)
					showToast("server status:" .. __data.status)
					return
				end
				
				if __data.status > 0 then
					local temhids = {}
					for _, v in ipairs(heros) do
						if v.lv == 1 and (not v.flag or bit.band(v.flag, 2) == 0) and not v.wake and food.isValid(v.id) then
							temhids[#temhids+1] = v.hid
						end
					end
					
					for _, v in ipairs(temhids) do
						local info = heros.del(v)
						food.modCount(info.id, 1)
						--[[for j, v in ipairs(info.equips) do
							local config = cfgequip[v]
							if config and config.pos ~= 5 then
								table.insert(reward.equips, { id = v, num = 1})
							end
						end--]]
					end
					
					dialoglayer:getParent().needFresh = true
				end
				audio.play(audio.button)
				dialoglayer:removeFromParentAndCleanup(true)
			end)
		end)
		btnNo:registerScriptTapHandler(function()
			dialoglayer:removeFromParentAndCleanup(true)
			audio.play(audio.button)
		end)

		local function diabackEvent()
			dialoglayer:removeFromParentAndCleanup(true)
		end

		function dialoglayer.onAndroidBack()
			diabackEvent()
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
	
    -- backBtn
    local btnBackSprite = img.createUISprite(img.ui.back)
    local btnBack = HHMenuItem:create(btnBackSprite)
    btnBack:setScale(view.minScale)
    btnBack:setPosition(scalep(35, 546))
    local menuBack = CCMenu:createWithItem(btnBack)
    menuBack:setPosition(0, 0)
    layer:addChild(menuBack, 1000)
    layer.back = btnBack
    btnBack:registerScriptTapHandler(function()
        audio.play(audio.button)
        if not params.back then
            replaceScene(require("ui.town.main").create())
        elseif params.back == "hook" then
            replaceScene(require("ui.hook.map").create())
        end
    end)

    autoLayoutShift(btnBack)

    local title = lbl.createFont3(30, i18n.global.herolist_title.string, ccc3(0xfa, 0xd8, 0x69))
    title:setScale(view.minScale)
    title:setPosition(scalep(480, 545))
    layer:addChild(title, 100)
    
    local showHeroLayer
    local model = params.model or "Hero"
    local sortType
    local group = params.group

    local board = img.createUISprite(img.ui.herolist_bg)
    board:setScale(view.minScale)
    board:setPosition(scalep(467, 272))
    --board:setPosition(view.midX - 15, view.midY - 20)
    layer:addChild(board)

    local btnHeroSprite0 = img.createUISprite(img.ui.herolist_tab_hero_nselect)
    local btnHeroSprite1 = img.createUISprite(img.ui.herolist_tab_hero_select)
    local btnHero = CCMenuItemSprite:create(btnHeroSprite0, btnHeroSprite1, btnHeroSprite0)
    local btnHeroMenu = CCMenu:createWithItem(btnHero)
    btnHero:setPosition(848, 318)
    btnHeroMenu:setPosition(0, 0)
    board:addChild(btnHeroMenu, 10)

    local btnBookSprite0 = img.createUISprite(img.ui.herolist_tab_book_nselect)
    local btnBookSprite1 = img.createUISprite(img.ui.herolist_tab_book_select)
    local btnBook = CCMenuItemSprite:create(btnBookSprite0, btnBookSprite1, btnBookSprite0)
    local btnBookMenu = CCMenu:createWithItem(btnBook)
    btnBook:setPosition(848, 195)
    btnBookMenu:setPosition(0, 0)
    board:addChild(btnBookMenu, 10)

    local btnGroupList = {}
    local getDataAndCreateList
    if model == "Hero" then
        btnHero:selected()
    else
        btnBook:selected()
    end
    btnHero:registerScriptTapHandler(function()
        audio.play(audio.button)
        if model ~= "Hero" then
            btnHero:setEnabled(false)
            btnBook:setEnabled(true)
            title:setString(i18n.global.herolist_title.string)
            btnHero:selected()
            btnBook:unselected()
            model = "Hero"
            if group then
                btnGroupList[group]:unselected()
                group = nil
            end
            getDataAndCreateList()
        end
    end)
    btnBook:registerScriptTapHandler(function()
        audio.play(audio.button)
        if model ~= "Book" then
            btnHero:setEnabled(true)
            btnBook:setEnabled(false)
            title:setString(i18n.global.herolist_title_herobook.string)
            btnHero:unselected()
            btnBook:selected()
            model = "Book"
            getDataAndCreateList()
        end
    end)

    for i=1, 6 do
        local btnGroupSpriteFg = img.createUISprite(img.ui["herolist_group_" .. i])
        local btnGroupSpriteBg = img.createUISprite(img.ui.herolist_group_bg)
        btnGroupSpriteFg:setPosition(btnGroupSpriteBg:getContentSize().width/2, btnGroupSpriteBg:getContentSize().height/2 + 2)
        btnGroupSpriteBg:addChild(btnGroupSpriteFg)
        btnGroupList[i] = HHMenuItem:createWithScale(btnGroupSpriteBg, 1)
        local btnGroupMenu = CCMenu:createWithItem(btnGroupList[i])
        btnGroupMenu:setPosition(0, 0)
        board:addChild(btnGroupMenu, 10)
        btnGroupList[i]:setPosition(183 + 66 * i, 460)
        
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

            getDataAndCreateList()
        end)
    end
    if group then
        btnGroupList[group]:selected()
        btnGroupList[group].showSelect:setVisible(true)
    end
	
	local btnInfoSprite = img.createUISprite(img.ui.btn_help)
    local btnInfo = SpineMenuItem:create(json.ui.button, btnInfoSprite)
    --btnInfo:setScale(view.minScale)
    btnInfo:setPosition(183 + 66 * 7, 470)
    local menuInfo = CCMenu:createWithItem(btnInfo)
    menuInfo:setPosition(0, 0)
    board:addChild(menuInfo, 102)
    btnInfo:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer:addChild(require("ui.help").create(i18n.global.help_foodbag.string, i18n.global.help_title.string), 1000)
    end)
	
	local arrowSprite = img.createUISprite(img.ui.arrow)
	arrowSprite:setPosition(183 + 66 * 7 + 50 + 50, 470)
	arrowSprite:setFlipX(true)
	board:addChild(arrowSprite, 100)
	
	local btnDetailSprite = img.createUISprite(img.ui.fight_hurts)
    local btnDetail = SpineMenuItem:create(json.ui.button, btnDetailSprite)
    btnDetail:setPosition(183 + 66 * 7 + 50, 470)
	--btnDetail:setScale(view.minScale)
    local menuDetail = CCMenu:createWithItem(btnDetail)
    menuDetail:setPosition(0, 0)
    board:addChild(menuDetail, 101)
	btnDetail:registerScriptTapHandler(function()
        audio.play(audio.button)
		arrowSprite:setVisible(false)
        layer:addChild(createSurebuy(), 1000)
    end)

    local function createHeroList(herolist)
        local layer = CCLayer:create()

        local SCROLLVIEW_WIDTH = 710
        local SCROLLVIEW_HEIGHT = 411
        local SCROLLCONTENT_HEIGHT = 23 + 101 * math.ceil(#herolist/7)
        
        local scroll = CCScrollView:create()
        scroll:setDirection(kCCScrollViewDirectionVertical)
        scroll:setAnchorPoint(ccp(0, 0))
        scroll:setPosition(66, 29)
        scroll:setViewSize(CCSize(SCROLLVIEW_WIDTH, SCROLLVIEW_HEIGHT))
        scroll:setContentSize(CCSize(SCROLLVIEW_WIDTH, SCROLLCONTENT_HEIGHT))
        scroll:setContentOffset(ccp(0, SCROLLVIEW_HEIGHT - SCROLLCONTENT_HEIGHT))
        layer:addChild(scroll)

        local iconBgBatch = img.createBatchNodeForUI(img.ui.herolist_head_bg)
        scroll:getContainer():addChild(iconBgBatch, 1)
        local iconBgBatch1 = img.createBatchNodeForUI(img.ui.hero_star_ten_bg)
        scroll:getContainer():addChild(iconBgBatch1, 1)
        local groupBgBatch = img.createBatchNodeForUI(img.ui.herolist_group_bg)
        scroll:getContainer():addChild(groupBgBatch , 3)
        local starBatch = img.createBatchNodeForUI(img.ui.star_s)
        scroll:getContainer():addChild(starBatch, 3)
        local star1Batch = img.createBatchNodeForUI(img.ui.hero_star_orange)
        scroll:getContainer():addChild(star1Batch, 3)
        local star10Batch = img.createBatchNodeForUI(img.ui.hero_star_ten)
        scroll:getContainer():addChild(star10Batch, 3)
        local blackBatch = img.createBatchNodeForUI(img.ui.hero_head_shade)
        scroll:getContainer():addChild(blackBatch, 5)

        local headIcons = {}
        local function createItem(i, v)
            local y, x = SCROLLCONTENT_HEIGHT - math.ceil( i / 7 ) * 101 + 40, ( i - math.ceil( i / 7 ) * 7 + 7 ) * 101 - 51
            local headBg = nil
            local qlt = cfghero[v.id].maxStar
            if qlt == 10 then
                headBg = img.createUISprite(img.ui.hero_star_ten_bg)
                headBg:setPosition(x, y)
                iconBgBatch1:addChild(headBg)

                json.load(json.ui.lv10_framefx)
                local aniten = DHSkeletonAnimation:createWithKey(json.ui.lv10_framefx)
                aniten:playAnimation("animation", -1)
                aniten:scheduleUpdateLua()
                aniten:setPosition(x, y)
                scroll:getContainer():addChild(aniten, 4)
            else
                headBg = img.createUISprite(img.ui.herolist_head_bg)
                headBg:setPosition(x, y)
                iconBgBatch:addChild(headBg)
            end
           
			headIcons[i] = img.createHeroHeadIcon(v.id)
			local groupBg = img.createUISprite(img.ui.herolist_group_bg)
			groupBg:setScale(0.42)
			groupBg:setPosition(x - 30, y + 29)
			groupBgBatch:addChild(groupBg)
	
			local groupIcon = img.createUISprite(img.ui["herolist_group_" .. cfghero[v.id].group])
			groupIcon:setScale(0.42)
			groupIcon:setPosition(x - 30, y + 30)
			scroll:getContainer():addChild(groupIcon, 3)

			local showLv = lbl.createFont2(16, v.count)
			showLv:setPosition(x + 26, y + 30)
			scroll:getContainer():addChild(showLv, 3)
			
			headIcons[i].lvc = showLv

			if qlt <= 5 then
				for i = qlt, 1, -1 do
					local star = img.createUISprite(img.ui.star_s)
					star:setPosition(x + (i-(qlt+1)/2)*12, y - 32)
					starBatch:addChild(star)
				end
			elseif qlt == 6 then
				local redstar = 1
				if v.wake then
					redstar = v.wake+1
				end
				for i = redstar, 1, -1 do
					local star = img.createUISprite(img.ui.hero_star_orange)
					star:setScale(0.75)
					star:setPosition(x + (i-(redstar+1)/2)*12, y - 30)
					star1Batch:addChild(star)
				end
			elseif qlt == 10 then
				local star = img.createUISprite(img.ui.hero_star_ten)
				--star:setScale(0.75)
				star:setPosition(x, y - 30)
				star10Batch:addChild(star)
			end
            headIcons[i]:setPosition(x, y)
			img.fixOfficialScale(headIcons[i], "hero", v.id)
            scroll:getContainer():addChild(headIcons[i], 2)
           
            if v.count == 0 then 
                local blackBoard = img.createUISprite(img.ui.hero_head_shade)
                blackBoard:setScale(90/94)
                blackBoard:setOpacity(120)
                blackBoard:setPosition(headIcons[i]:getPositionX(), headIcons[i]:getPositionY())
                blackBatch:addChild(blackBoard, 0, i)
            end
			
			local showLock = img.createUISprite(img.ui.devour_icon_lock)
			--showLock:setPosition(headIcons[i]:getContentSize().width/2, headIcons[i]:getContentSize().height/2)
			showLock:setPosition(9, headIcons[i]:getContentSize().height - 36)
			--showLock:setScale(0.5)
			showLock:setVisible(false)
			headIcons[i]:addChild(showLock)
			headIcons[i].lockc = showLock
			if v.flags and bit.band(v.flags, 1) ~= 1 then
				showLock:setVisible(true)
			end
        end

        local initShowCount = 60
        for i, v in ipairs(herolist) do
            if i > initShowCount then
                break
            end

            createItem(i, v)
        end

        local heroCount = #herolist
        local function showAfter()
            if initShowCount < heroCount then
                initShowCount = initShowCount + 1
                createItem(initShowCount, herolist[initShowCount])
                return true
            end
        end

        if heroCount == 0 then
            local empty = require("ui.empty").create({ text = i18n.global.empty_herolist.string , color = ccc3(0xd9, 0xbb, 0x9d)})
            empty:setPosition(board:getContentSize().width/2, board:getContentSize().height/2)
            layer:addChild(empty)
        elseif heroCount > initShowCount then
            layer:scheduleUpdateWithPriorityLua(function ( dt )
                if showAfter() then
                    if showAfter() then
                        showAfter()
                    end
                end
            end, 0)
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
            local pointOnBoard = layer:convertToNodeSpace(ccp(x, y))
            if math.abs(y - lasty) > 10 or not scroll:boundingBox():containsPoint(pointOnBoard) then
                return true
            end

            local point = scroll:getContainer():convertToNodeSpace(ccp(x, y))
            for i, v in ipairs(headIcons) do
                if v:boundingBox():containsPoint(point) then
                    audio.play(audio.button)
                    if model == "Hero" then
                        --bg:getParent():addChild(require("ui.hero.main").create(herolist[i].hid, group, herolist, i), 10000)
                    else
                        --bg:getParent():addChild(require("ui.herolist.herobook").create(herolist[i].id, nil, herolist, i), 10000)
                    end
					bg:getParent():addChild(ui.createSettings(herolist[i], v), 10000)
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

        return layer
    end

    function getDataAndCreateList()
        local herolist = {}
        if model == "Hero" then
            for id, v in pairs(food.arr) do
                if v.count > 0 and (not group or cfghero[id].group == group) then
                    herolist[#herolist + 1] = {
						id = id,
						count = v.count,
						flags = food.getToggledFlags(id, v.flags)
					}
                end
            end
        else
            if not group then
                group = 1
                btnGroupList[1]:selected()
                btnGroupList[1].showSelect:setVisible(true)
            end
            for id, v in pairs(food.arr) do
                if not group or cfghero[id].group == group then
                    herolist[#herolist + 1] = {
						id = id,
						count = v.count,
						flags = food.getToggledFlags(id, v.flags)
					}
                end
            end
        end
		sortForDisplay(herolist)
		
        if showHeroLayer then
            showHeroLayer:removeFromParentAndCleanup(true)
            showHeroLayer = nil
        end
        showHeroLayer = createHeroList(herolist)
        board:addChild(showHeroLayer)
    end
    getDataAndCreateList()

    layer:scheduleUpdateWithPriorityLua(function()
        if layer.needFresh == true then
            layer.needFresh = false
            getDataAndCreateList()
        end
    end)
    addBackEvent(layer)
    function layer.onAndroidBack()
        if not params.back then
            replaceScene(require("ui.town.main").create())
        elseif params.back == "hook" then
            replaceScene(require("ui.hook.map").create())
        end
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

    return layer
end

return ui
