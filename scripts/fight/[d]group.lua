-- 阵营克制弹窗

local ui = {}

require "common.const"
require "common.func"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local i18n = require "res.i18n"
local audio = require "res.audio"

local BG_WIDTH   = 666
local BG_HEIGHT  = 415

-- onClose: 关闭弹窗时的回调, 可为nil
function ui.create(onClose)
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
    local title = lbl.createFont1(24, i18n.global.fight_group_title.string, ccc3(0xff, 0xe3, 0x86))
    title:setPosition(BG_WIDTH/2, BG_HEIGHT-36)
    bg:addChild(title)

    -- line
    local line = img.createUISprite(img.ui.help_line)
    line:setScaleX(610/line:getContentSize().width)
    line:setPosition(BG_WIDTH/2, BG_HEIGHT-64)
    bg:addChild(line)

    -- text
    local text = CCSprite:create()
    text:setPosition(BG_WIDTH/2, BG_HEIGHT-100)
    bg:addChild(text)
    local textX = 0
    for i = 1, 5 do
        local l
        if i == 2 or i == 4 then
            l = lbl.createMixFont1(18, i18n.global["fight_group_text" .. i].string, ccc3(0xcc, 0xff, 0x5f))
        else
            l = lbl.createMixFont1(18, i18n.global["fight_group_text" .. i].string, ccc3(0xfe, 0xeb, 0xca))
        end
        l:setAnchorPoint(ccp(0, 0.5))
        l:setPosition(textX, 5)
        text:addChild(l)
        textX = l:boundingBox():getMaxX()
    end
    text:setContentSize(textX, 10)

    -- image
    local hintImage = img.createUISprite(img.ui.fight_group_help)
    hintImage:setAnchorPoint(ccp(0.5, 1))
    hintImage:setPosition(BG_WIDTH/2, BG_HEIGHT-155)
    bg:addChild(hintImage)

    addBackEvent(layer)

    function layer.onAndroidBack()
        layer:removeFromParent()
        if onClose then
            onClose()
        end
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
