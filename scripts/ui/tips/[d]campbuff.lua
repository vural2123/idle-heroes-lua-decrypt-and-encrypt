-- 阵营buff

local ui = {}

require "common.const"
require "common.func"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local audio = require "res.audio"
local i18n = require "res.i18n"
local DHComponents  = require("dhcomponents.DroidhangComponents")

function ui.create(group)
    local layer = CCLayer:create()
    --layer:setContentSize(CCSize(396, 194))
    layer:setAnchorPoint(0.5,0.5)

	local cfg = nil
	if require("data.player").isSeasonal() then
		cfg = (require "config.camp2")[group]
	else
		cfg = (require "config.camp")[group]
	end
	
	local efcnt = #cfg.effect
	if efcnt < 2 then efcnt = 2 end
	local extrah = efcnt * 21
	local extrah2 = 0
	if efcnt > 2 then
		extrah2 = (efcnt - 2) * 21
	end
	
    -- bg
    local bg = img.createUI9Sprite(img.ui.tips_bg)
    bg:setAnchorPoint(0.5,0.5)
    bg:setScale(view.minScale)
    bg:setPosition(scalep(480, 288+60))
    layer:addChild(bg)
    layer.bg = bg
    
    -- icon
    local grid = img.createUISprite(img.ui.campbuff_grid)
    bg:addChild(grid)

    local icon = json.create(json.ui.campbuff[group])
    icon:playAnimation("animation", -1)
    icon:setScale(0.6)
    bg:addChild(icon)

    -- title
    local titleStr = i18n.global["hero_group_" .. group].string

    local title = lbl.createMix({font=2, size=24, text=titleStr, color=ccc3(0xff, 0xe4, 0x9c), pt={size=22}})
    title:setAnchorPoint(ccp(0, 0.5))
    bg:addChild(title)

    -- text
    local text = lbl.createMixFont1(16, i18n.global.fight_campbuff_text.string, lbl.whiteColor)
    text:setAnchorPoint(ccp(0, 0.5))
    bg:addChild(text)

    -- line
    local line = img.createUISprite(img.ui.hero_tips_fgline)
    line:setScaleX(350 / line:getContentSize().width)
    line:setAnchorPoint(ccp(0, 0.5))
    bg:addChild(line)

    -- desc
    local desc = lbl.createMix({
            font = 1, size = 16, text = i18n.global["camp_require_" .. group].string,
        color = lbl.whiteColor, width = 360, align = kCCTextAlignmentLeft,
    })
    desc:setAnchorPoint(ccp(0, 0))
    bg:addChild(desc)

    local currentY = desc:boundingBox():getMaxY() - 20
    print("currentY = "..currentY)

    bg:setPreferredSize(CCSize(410, 126 + extrah + currentY ))

    DHComponents:mandateNode(grid   ,"yw_campbuff_grid")
    DHComponents:mandateNode(icon   ,"yw_campbuff_icon")
    DHComponents:mandateNode(title  ,"yw_campbuff_title")
    DHComponents:mandateNode(text   ,"yw_campbuff_text")
    DHComponents:mandateNode(line   ,"yw_campbuff_line")
    DHComponents:mandateNode(desc   ,"yw_campbuff_desc")

    --自适应的修正偏移
    text:setPosition(text:getPositionX(),text:getPositionY() + currentY + extrah2)
    icon:setPosition(icon:getPositionX(),icon:getPositionY() + currentY + extrah2)
    title:setPosition(title:getPositionX(),title:getPositionY() + currentY + extrah2)
    grid:setPosition(grid:getPositionX(),grid:getPositionY() + currentY + extrah2)
    line:setPosition(line:getPositionX(),line:getPositionY() + currentY + extrah2)
	desc:setPosition(desc:getPositionX(), desc:getPositionY() + extrah2)

    -- attrib
    for i, b in ipairs(cfg.effect) do
        local n, v = buffString(b.type, b.num)
        local name = lbl.createMixFont1(16, n, ccc3(0xd4, 0xb3, 0x36))
        name:setAnchorPoint(ccp(0, 0.5))
        name:setPosition(22, 4 + 21 * i)
        bg:addChild(name)
        local value = lbl.createMixFont1(16, "+" .. v, lbl.whiteColor)
        value:setAnchorPoint(ccp(0, 0.5))
        value:setPosition(name:boundingBox():getMaxX()+20, 4 + 21 * i)
        bg:addChild(value)
    end

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
