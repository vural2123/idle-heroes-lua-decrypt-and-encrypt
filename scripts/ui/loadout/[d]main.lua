-- 展示皮肤

local ui = {}

require "common.const"
require "common.func"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local audio = require "res.audio"
local i18n = require "res.i18n"
local net = require "net.netClient"
local player = require "data.player"
local data = require "ui.loadout.data"
local cui = require "ui.custom"

-- 背景框大小
local BG_WIDTH   = 684
local BG_HEIGHT  = 545
local MAX_LOADOUT = 20

function ui.create(selected, callback)
    local layer = CCLayer:create()

    -- dark bg
    local darkbg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    layer:addChild(darkbg)
	
	local mustCallbackWithEdit = nil

    -- bg
    local bg = img.createUI9Sprite(img.ui.tips_bg)
    bg:setPreferredSize(CCSize(BG_WIDTH, BG_HEIGHT))
    bg:setScale(view.minScale * 0.1)
    bg:setAnchorPoint(ccp(0.5,0.5))
    bg:setPosition(view.midX, view.midY)
    bg:runAction(CCEaseBackOut:create(CCScaleTo:create(0.3, view.minScale)))
    layer:addChild(bg)
    
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

    -- title
    local title = i18n.global.select_hero_title.string
    local titleLabel = lbl.createMixFont1(24, title, ccc3(0xff, 0xe3, 0x86))
    titleLabel:setPosition(BG_WIDTH/2, BG_HEIGHT-36)
    bg:addChild(titleLabel)

    -- line
    local line = img.createUISprite(img.ui.help_line)
    line:setScaleX(627/line:getContentSize().width)
    line:setPosition(BG_WIDTH/2, BG_HEIGHT-64)
    bg:addChild(line)

    local function createScroll()
        local scroll_params = {
            width = 680,
            height = 468,
        }
        local lineScroll = require "ui.lineScroll"
        return lineScroll.create(scroll_params)
    end
	
	local iconBgs = {}
	local iconHeight = 80
	
	local useBtns = {}
	
	local function updateIconId(_idx, id)
		local bgc = iconBgs[_idx]
		if not bgc then return end
		if bgc.cicon then
			bgc.cicon:removeFromParent()
			bgc.cicon = nil
		end
		if id then
			local heroIcon = img.createPlayerHeadById(id)
			heroIcon:setPosition(bgc:getContentSize().width/2, bgc:getContentSize().height/2)
			heroIcon:setScale(iconHeight/102)
			bgc:addChild(heroIcon)
			bgc.cicon = heroIcon
		end
	end
	
	local function onEdited(content)
		local csc = 0
		for i=1, 6 do
			if content.stand[i] then
				csc = csc + 1
			end
		end
		if csc > 0 then
			data.add(content)
			if useBtns[content.id] then
				cui.setButtonEnabled(useBtns[content.id], true)
			end
			updateIconId(content.id, content.icon)
			if content.id == selected then
				mustCallbackWithEdit = selected
			end
		else
			data.del(content.id)
			if useBtns[content.id] then
				cui.setButtonEnabled(useBtns[content.id], false)
			end
			updateIconId(content.id, nil)
			if content.id == selected then
				mustCallbackWithEdit = 0
			end
		end
	end

    local function createItem(_idx)
		local item
        if selected and selected == _idx then
            item = img.createUI9Sprite(img.ui.item_yellow)
        else
            item = img.createUI9Sprite(img.ui.botton_fram_2)
        end
		local content = data.get(_idx)

        item:setPreferredSize(CCSizeMake(330, 96))
        local item_w = item:getContentSize().width
        local item_h = item:getContentSize().height

		local baseHeroBg = img.createUI9Sprite(img.ui.herolist_withouthero_bg)
        baseHeroBg:setPreferredSize(CCSize(iconHeight, iconHeight))
        baseHeroBg:setPosition(50, item:getContentSize().height/2)
        item:addChild(baseHeroBg)
		iconBgs[_idx] = baseHeroBg
		if content then
			updateIconId(_idx, content.icon)
		end

		if _idx == 0 then
			local showTitle = lbl.createMixFont1(20, i18n.global.none.string, ccc3(0x94, 0x62, 0x42))
			showTitle:setAnchorPoint(ccp(0, 0.5))
			showTitle:setPosition(25 + iconHeight, item:getContentSize().height/2)
			item:addChild(showTitle)
		end
		local thisIdx = _idx

		if selected and selected == _idx then
			local selectIcon = img.createUISprite(img.ui.hook_btn_sel)
			selectIcon:setPosition(item_w - 50, math.max(item_h/2 - 20, 45))
			item:addChild(selectIcon)
		else
            -- use button
            local btn_ch0 = img.createLogin9Sprite(img.login.button_9_small_gold)
            btn_ch0:setPreferredSize(CCSizeMake(90, 45))
            local lbl_btn_ch = lbl.createFont1(16, i18n.global.solo_use.string, ccc3(0x73, 0x3b, 0x05))
            lbl_btn_ch:setPosition(btn_ch0:getContentSize().width/2, btn_ch0:getContentSize().height/2)
            btn_ch0:addChild(lbl_btn_ch)
            local btn_ch = SpineMenuItem:create(json.ui.button, btn_ch0)
            btn_ch:setPosition(CCPoint(item_w - 65, item_h/2))
            local btn_ch_menu = CCMenu:createWithItem(btn_ch)
            btn_ch_menu:setPosition(CCPoint(0, 0))
            item:addChild(btn_ch_menu)
            btn_ch:registerScriptTapHandler(function()
                disableObjAWhile(btn_ch)
                audio.play(audio.button)
				local hadError = false
				if thisIdx > 0 then
					local errorCode = data.checkValid(thisIdx)
					if not errorCode or errorCode ~= 0 then
						hadError = true
						data.showValidError(errorCode)
					end
				end
				if not hadError then
					if callback then callback(thisIdx) end
					mustCallbackWithEdit = nil
					layer.onAndroidBack()
				end
            end)
			useBtns[_idx] = btn_ch
			if _idx > 0 and not content then
				cui.setButtonEnabled(btn_ch, false)
			end
		end
			
		-- edit button
		if _idx > 0 then
			local btn2_ch0 = img.createLogin9Sprite(img.login.button_9_small_gold)
			btn2_ch0:setPreferredSize(CCSizeMake(90, 45))
			local lbl_btn2_ch = lbl.createFont1(16, i18n.global.guild_memopt_dlg_title.string, ccc3(0x73, 0x3b, 0x05))
			lbl_btn2_ch:setPosition(btn2_ch0:getContentSize().width/2, btn2_ch0:getContentSize().height/2)
			btn2_ch0:addChild(lbl_btn2_ch)
			local btn2_ch = SpineMenuItem:create(json.ui.button, btn2_ch0)
			btn2_ch:setPosition(CCPoint(item_w - 65 - 90 - 10, item_h/2))
			local btn2_ch_menu = CCMenu:createWithItem(btn2_ch)
			btn2_ch_menu:setPosition(CCPoint(0, 0))
			item:addChild(btn2_ch_menu)
			local thisIdx = _idx
			btn2_ch:registerScriptTapHandler(function()
				disableObjAWhile(btn2_ch)
				audio.play(audio.button)
				local c2 = data.get(thisIdx)
				local lparams = {
					callback = onEdited,
				}
				if c2 then
					lparams.content = clone(c2)
				else
					lparams.content = {
						id = thisIdx,
						icon = 1101,
						stand = {},
						petID = -1,
					}
				end
				layer:addChild(require("ui.loadout.edit").create(lparams), 1000)
			end)
		end

        return item
    end
	
	local realWidth = 330
	local realHeight = 96
	local itemWidth = 340
	local itemHeight = 100
	
	local slotCount = MAX_LOADOUT
	local actualCount = slotCount + 1
	
	local gridHeight = (math.floor((actualCount - 1) / 2) + 1) * itemHeight

    local scroll = createScroll()
    scroll:setAnchorPoint(CCPoint(0, 0))
    scroll:setPosition(CCPoint(2, 7))
	scroll:setContentSize(CCSize(680, gridHeight))
    bg:addChild(scroll)

	local added = 0
	
	local function getPosObj()
		local offx = added % 2
		local x = offx * itemWidth + math.floor((itemWidth - realWidth) / 2)
		local y = gridHeight - (math.floor(added / 2) + 1) * itemHeight + math.floor((itemHeight - realHeight) / 2)
		if offx == 0 then
			x = x + 4
		elseif offx == 1 then
			x = x - 4
		end
		return x, y
	end
	
	-- slotCount and not actualCount because we start from 0
	for i=0, slotCount do
		local tmp_item = createItem(i)
		tmp_item:setAnchorPoint(ccp(0, 0))
		local x, y = getPosObj()
		tmp_item:setPosition(x, y)
		scroll:getContainer():addChild(tmp_item)
		added = added + 1
	end
	
	scroll:setContentOffset(ccp(0, 468 - gridHeight))

    addBackEvent(layer)

    function layer.onAndroidBack()
		if mustCallbackWithEdit and callback then
			callback(mustCallbackWithEdit)
			mustCallbackWithEdit = nil
		end
        layer:removeFromParent()
    end

    layer:registerScriptHandler(function(event)
        if event == "enter" then
            layer.notifyParentLock()
        elseif event == "exit" then
            layer.notifyParentUnlock()
        end
    end)
	
	--local prevTips = nil
	
	local function onTouch(eventType, x, y)
		--[[local chosenTips = nil
        if eventType == "began" or eventType == "moved" then
			for _, v in pairs(iconBgs) do
				if v.ctips and v:boundingBox():containsPoint(v:getParent():convertToNodeSpace(ccp(x, y))) then
					chosenTips = v.ctips
					break
				end
			end
        end
		if prevTips and chosenTips and prevTips == chosenTips then
		else
			if prevTips then
				prevTips:setVisible(false)
			end
			prevTips = chosenTips
			if prevTips then
				prevTips:setVisible(true)
			end
		end--]]
        return true
    end

	layer:registerScriptTouchHandler(onTouch)
    layer:setTouchEnabled(true)
    layer:setTouchSwallowEnabled(true)

    return layer
end

return ui
