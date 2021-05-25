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
local cfgskill = require "config.skill"
local net = require "net.netClient"
local player = require "data.player"
local heros = require "data.heros"

-- 背景框大小
local BG_WIDTH   = 684
local BG_HEIGHT  = 545

local function hasChSkl(skillId)
	local sk = cfgskill[skillId]
	if sk then
		if sk.effect then
			for i, v in ipairs(sk.effect) do
				if v.type == "changeCombat" then
					return true
				end
			end
		end
		if sk.effect2 then
			for i, v in ipairs(sk.effect2) do
				if v.type == "changeCombat" then
					return true
				end
			end
		end
	end
	return false
end

local function hasselgroup(all, sel, index, slot)
	local nowId = all[index]
	if not hasChSkl(nowId) then
		return false
	end
	for i=1, #sel do
		local ii = sel[i]
		if ii > 0 and slot ~= i then
			local skillId = all[ii]
			if hasChSkl(skillId) then
				return true
			end
		end
	end
	return false
end

local function getseltype(sel, cur, index)
	-- 0 = ok to select
	-- 1 = already selected here now
	-- 2 = selected elsewhere
	if cur == index then
		return 1
	end
	for i=1,#sel do
		if sel[i] == index then
			return 2
		end
	end
	return 0
end

-- skills = skill id array
-- sel = selected skills indices array
-- cur = the skill index that is selected in current slot
-- slot = current slot index
-- callback = function to run when choice is made
function ui.create(skills, sel, cur, slot, callback)
    local layer = CCLayer:create()

    -- dark bg
    local darkbg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    layer:addChild(darkbg)

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
    local title = i18n.global.hero_title_talenskill.string
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

    local function createItem(skillId, index)
        local item = nil
        local selected = getseltype(sel, cur, index)
		
		if selected == 0 and hasselgroup(skills, sel, index, slot) then
			selected = 3
		end
		
        if selected == 1 then
            item = img.createUI9Sprite(img.ui.item_yellow)
        else
            item = img.createUI9Sprite(img.ui.botton_fram_2)
        end

        item:setPreferredSize(CCSizeMake(627, 137))
        local item_w = item:getContentSize().width
        local item_h = item:getContentSize().height

        local skillIconBg = img.createUISprite(img.ui.hero_skill_bg)
        skillIconBg:setPosition(70, item:getContentSize().height/2)
        item:addChild(skillIconBg)
        local skillIcon = img.createSkill(skillId)
        skillIcon:setPosition(skillIconBg:getContentSize().width/2, skillIconBg:getContentSize().height/2)
        skillIconBg:addChild(skillIcon)
		
		local dtext = i18n.skill[skillId].desc
		if string.len(dtext) > 140 then
			dtext = string.sub(dtext, 1, 140) .. "..."
		end

        local showText = lbl.createMix({
            font = 1, size = 16, text = dtext, width = 474 - 128 , color = ccc3(0x72, 0x48, 0x35), align = kCCTextAlignmentLeft 
        })
        showText:setAnchorPoint(ccp(0, 1))
        showText:setPosition(125, 92)
        item:addChild(showText)

        local fgLine = img.createUI9Sprite(img.ui.gemstore_fgline)
        fgLine:setPreferredSize(CCSize(473, 2))
        fgLine:setAnchorPoint(0, 0.5)
        fgLine:setPosition(125, showText:boundingBox():getMaxY() + 8)
        item:addChild(fgLine)

        local showTitle = lbl.createMixFont1(20, i18n.skill[skillId].skillName , ccc3(0x94, 0x62, 0x42))
        showTitle:setAnchorPoint(ccp(0, 1))
        showTitle:setPosition(125, fgLine:boundingBox():getMaxY() + 12 + 21)
        item:addChild(showTitle)

        if selected ~= 0 then
            if selected >= 2 then
                setShader(skillIcon, SHADER_GRAY, true)
            end
			if selected ~= 3 then
				local selectIcon = img.createUISprite(img.ui.hook_btn_sel)
				selectIcon:setPosition(item_w - 50, item_h/2 - 20)
				item:addChild(selectIcon)
			end
        else
            -- button
            local btn_ch0 = img.createLogin9Sprite(img.login.button_9_small_gold)
            btn_ch0:setPreferredSize(CCSizeMake(118, 45))
            local lbl_btn_ch = lbl.createFont1(16, i18n.global.solo_use.string, ccc3(0x73, 0x3b, 0x05))
            lbl_btn_ch:setPosition(CCPoint(59, 23))
            btn_ch0:addChild(lbl_btn_ch)
            local btn_ch = SpineMenuItem:create(json.ui.button, btn_ch0)
            btn_ch:setPosition(CCPoint(item_w - 88, item_h/2 - 10))
            local btn_ch_menu = CCMenu:createWithItem(btn_ch)
            btn_ch_menu:setPosition(CCPoint(0, 0))
            item:addChild(btn_ch_menu)
			local argThing = index
            btn_ch:registerScriptTapHandler(function()
                audio.play(audio.button)
                if callback then callback(slot, argThing) end
                layer.onAndroidBack()
            end)
        end

        return item
    end

    local scroll = createScroll()
    scroll:setAnchorPoint(CCPoint(0, 0))
    scroll:setPosition(CCPoint(2, 7))
    bg:addChild(scroll)
    --board.scroll = scroll

    scroll.addSpace(4)
	for i=1,#skills do
		if i > 1 then scroll.addSpace(1) end
		local tmp_item = createItem(skills[i], i)
		tmp_item.ax = 0.5
		tmp_item.px = 340
		scroll.addItem(tmp_item)
    end

    scroll.setOffsetBegin()

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
