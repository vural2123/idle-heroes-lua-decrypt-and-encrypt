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
local cfgcamp = require "config.camp"

-- 背景框大小
local BG_WIDTH   = 666
local BG_HEIGHT  = 415

-- 滑动区域大小
local SCROLL_MARGIN_TOP     = 70
local SCROLL_MARGIN_BOTTOM  = 10
local SCROLL_VIEW_WIDTH     = BG_WIDTH
local SCROLL_VIEW_HEIGHT    = BG_HEIGHT - SCROLL_MARGIN_TOP - SCROLL_MARGIN_BOTTOM

function ui.create()
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
    local title = lbl.createFont1(24, i18n.global.camp_buff_title.string, ccc3(0xff, 0xe3, 0x86))
    title:setPosition(BG_WIDTH/2, BG_HEIGHT-36)
    bg:addChild(title)

    -- scroll
    local scroll = CCScrollView:create()
    scroll:setDirection(kCCScrollViewDirectionVertical)
    scroll:setViewSize(CCSize(SCROLL_VIEW_WIDTH, SCROLL_VIEW_HEIGHT))
    scroll:setPosition(0, SCROLL_MARGIN_BOTTOM)
    bg:addChild(scroll)

    local height
    local xy = { {105,12}, {105,-15} }
    for i = #cfgcamp, 1, -1 do
        local cfg = cfgcamp[i]
        local container = scroll:getContainer()
        -- icon
        local x, y = 44, 157*(#cfgcamp+1-i)
        local icon = json.create(json.ui.campbuff[i])
        icon:playAnimation("animation", -1)
        icon:setScale(0.72)
        icon:setPosition(x+28, y)
        container:addChild(icon)
        height = y + 53
        -- box
        local box = img.createUI9Sprite(img.ui.tutorial_stand_info_bg)
        box:setPreferredSize(CCSize(495, 70))
        box:setAnchorPoint(ccp(0, 0.5))
        box:setPosition(x+82, y)
        container:addChild(box)
        -- attrib
        for j, b in ipairs(cfg.effect) do
            local n, v = buffString(b.type, b.num)
            local name = lbl.createMixFont1(16, n, ccc3(0xff, 0xd9, 0x40))
            name:setAnchorPoint(ccp(0, 0.5))
            name:setPosition(x+xy[j][1], y+xy[j][2])
            container:addChild(name)
            local value = lbl.createMixFont1(16, "+" .. v, ccc3(0xfb, 0xfb, 0xfb))
            value:setAnchorPoint(ccp(0, 0.5))
            value:setPosition(name:boundingBox():getMaxX()+20, y+xy[j][2])
            container:addChild(value)
        end
        -- desc
        local desc = lbl.createMix({
            font = 1, size = 16, text = i18n.global["camp_require_" .. i].string,
            color = ccc3(0xfe, 0xeb, 0xca), width = 586, align = kCCTextAlignmentLeft,
        })
        desc:setAnchorPoint(ccp(0, 1))
        desc:setPosition(x-5, y-50)
        container:addChild(desc)
    end

    -- scroll content height
    scroll:setContentSize(CCSize(SCROLL_VIEW_WIDTH, height))
    scroll:setContentOffset(ccp(0, SCROLL_VIEW_HEIGHT-height))

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
