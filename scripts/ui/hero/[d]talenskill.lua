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
local cfgtalen = require "config.talen"

-- 背景框大小
local BG_WIDTH   = 684
local BG_HEIGHT  = 545

local function isSelected(skillId, hid, cparam)
	if cparam then
		if cparam.skills then
			for _, v in pairs(cparam.skills) do
				if v == skillId then return true end
			end
		end
		return false
	end
	return heros.isHeroSkill(hid, skillId)
end

local function getSkill(idx, hid, cparam)
	if cparam then
		if cparam.skills and cparam.skills[idx] then
			return cparam.skills[idx]
		end
		return 0
	end
	return heros.getHeroSkill(hid, idx)
end

function ui.create(lv, idx, hid, callback, cparam)
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
	
	local iconBgs = {}

    local function createItem(_idx)
        local item = nil
        local selected = isSelected(_idx + 6100, hid, cparam)
        if not selected and _idx == 0 then
            local curSel = getSkill(idx, hid, cparam)
            if not curSel or curSel == 0 then selected = true end
        end
        if selected then
            item = img.createUI9Sprite(img.ui.item_yellow)
        else
            item = img.createUI9Sprite(img.ui.botton_fram_2)
        end

        item:setPreferredSize(CCSizeMake(216, 96))
        local item_w = item:getContentSize().width
        local item_h = item:getContentSize().height

        local skillId = 6100 + _idx
        local skillIconBg = img.createUISprite(img.ui.hero_skill_bg)
        skillIconBg:setPosition(50, item:getContentSize().height/2)
        item:addChild(skillIconBg)
        local skillIcon = img.createSkill(skillId)
        skillIcon:setPosition(skillIconBg:getContentSize().width/2, skillIconBg:getContentSize().height/2)
        skillIconBg:addChild(skillIcon)
		skillIconBg:setScale(0.8)
		
		local skillTips = require("ui.tips.skill").create(skillId)
        --skillTips:setAnchorPoint(ccp(1, 0))
        skillTips:setPosition(bg:getContentSize().width/2, bg:getContentSize().height/2)
        bg:addChild(skillTips)
        skillTips:setVisible(false)
		
		skillIconBg.ctips = skillTips
		iconBgs[#iconBgs + 1] = skillIconBg

        --[[local showText = lbl.createMix({
            font = 1, size = 16, text = i18n.skill[skillId].desc, width = 474 - 128 , color = ccc3(0x72, 0x48, 0x35), align = kCCTextAlignmentLeft 
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
        item:addChild(showTitle)--]]

        if (lv < idx) or selected then
            if not selected then
                setShader(skillIcon, SHADER_GRAY, true)
            end

            --[[local talenUnlockLab = lbl.createMixFont1(16, string.format(i18n.global.talen_lv_unlock.string, _idx), ccc3(0xd4, 0x00, 0x00))
            talenUnlockLab:setAnchorPoint(ccp(0, 1))
            talenUnlockLab:setPosition(125, showText:boundingBox():getMinY() - 12)
            item:addChild(talenUnlockLab)--]]
            if selected then
                local selectIcon = img.createUISprite(img.ui.hook_btn_sel)
                selectIcon:setPosition(item_w - 50, math.max(item_h/2 - 20, 45))
                item:addChild(selectIcon)
            end
        else
            -- button
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
				if cparam then
					cparam.callback(idx, _idx + 6100)
					layer.onAndroidBack()
					return
				end
                local params = {
                    sid = player.sid + 0x100,
                    hid = hid,
                    source = { idx, _idx }
                }
                addWaitNet()
                net:hero_talen(params, function(__data)
                    delWaitNet()
                    if __data.status < 0 then
                        showToast("status: " .. __data.status)
                        return
                    end
                    if _idx ~= 0 then
                        heros.setHeroSkill(hid, idx, _idx + 6100)
                    else
                        heros.setHeroSkill(hid, idx, 0)
                    end
                    if callback then callback() end
                    layer.onAndroidBack()
                end)
            end)
        end

        return item
    end
	
	local realWidth = 216
	local realHeight = 96
	local itemWidth = 226
	local itemHeight = 100
	
	local actualCount = 0
	for i=0, 900 do
		local cf = cfgskill[6100 + i]
		if not cf then break end
		if not cf.disabled then actualCount = actualCount + 1 end
    end
	
	local gridHeight = (math.floor((actualCount - 1) / 3) + 1) * itemHeight

    local scroll = createScroll()
    scroll:setAnchorPoint(CCPoint(0, 0))
    scroll:setPosition(CCPoint(2, 7))
	scroll:setContentSize(CCSize(680, gridHeight))
    bg:addChild(scroll)

	local added = 0
	
	local function getPosObj()
		local offx = added % 3
		local x = offx * itemWidth + math.floor((itemWidth - realWidth) / 2)
		local y = gridHeight - (math.floor(added / 3) + 1) * itemHeight + math.floor((itemHeight - realHeight) / 2)
		if offx == 0 then
			x = x + 4
		elseif offx == 2 then
			x = x - 4
		end
		return x, y
	end
	
	for i=0, 900 do
		local cf = cfgskill[6100 + i]
		if not cf then break end
        if not cf.disabled then
            local tmp_item = createItem(i)
            tmp_item:setAnchorPoint(ccp(0, 0))
			local x, y = getPosObj()
            tmp_item:setPosition(x, y)
			scroll:getContainer():addChild(tmp_item)
			added = added + 1
            --scroll.addItem(tmp_item)
        end
    end

    --scroll.setOffsetBegin()
	scroll:setContentOffset(ccp(0, 468 - gridHeight))

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
	
	local prevTips = nil
	
	local function onTouch(eventType, x, y)
		local chosenTips = nil
        if eventType == "began" or eventType == "moved" then
			for _, v in ipairs(iconBgs) do
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
		end
        return true
    end

	layer:registerScriptTouchHandler(onTouch)
    layer:setTouchEnabled(true)
    layer:setTouchSwallowEnabled(true)

    return layer
end

return ui
