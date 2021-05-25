local info = {}

require "common.func"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local i18n = require "res.i18n"
local audio = require "res.audio"

function info.create()
    local layer = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))

    local board = img.createUI9Sprite(img.ui.tips_bg)
    board:setPreferredSize(CCSize(660, 412))
    board:setScale(view.minScale * 0.1)
    board:setPosition(view.midX, view.midY)
    board:runAction(CCEaseBackOut:create(CCScaleTo:create(0.3, view.minScale)))
    layer:addChild(board)

    local btnCloseSprite = img.createUISprite(img.ui.close)
    local btnClose = SpineMenuItem:create(json.ui.button, btnCloseSprite)
    btnClose:setPosition(643, 390)
    local menuClose = CCMenu:createWithItem(btnClose)
    menuClose:setPosition(0, 0)
    board:addChild(menuClose)
    btnClose:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer:removeFromParentAndCleanup(true)
    end)

    local standBg = img.createUI9Sprite(img.ui.tutorial_stand_info_bg)
    standBg:setPreferredSize(CCSize(593, 155))
    standBg:setAnchorPoint(ccp(0.5, 0))
    standBg:setPosition(322, 115)
    board:addChild(standBg)

    local showTitle = lbl.createMixFont1(24, i18n.global.tutorial_stand_title.string, ccc3(0xf0, 0xd5, 0x7e))
    showTitle:setPosition(322, 370)
    board:addChild(showTitle)
   
    local showText = lbl.createMix({ font = 1, size = 16, width = 593, align = kCCTextAlignmentLeft,
        text = i18n.global.tutorial_stand_text.string
    })
    showText:setAnchorPoint(ccp(0, 1))
    showText:setPosition(37, 333)
    board:addChild(showText)

    local titleFront = lbl.createMixFont1(16, i18n.global.select_hero_front.string)
    titleFront:setPosition(116, 123)
    standBg:addChild(titleFront)

    for i=1, 2 do
        local showDef = img.createUISprite(img.ui.tutorial_icon_def)
        showDef:setAnchorPoint(ccp(0, 0.5))
        showDef:setPosition(51 + 73 * (i - 1), 67)
        standBg:addChild(showDef)
    end

    local iconAdd = img.createUISprite(img.ui.tutorial_icon_add)
    iconAdd:setPosition(232, 67)
    standBg:addChild(iconAdd)

    local titleBehind = lbl.createMixFont1(16, i18n.global.select_hero_behind.string)
    titleBehind:setPosition(415, 123)
    standBg:addChild(titleBehind)

    for i=1, 4 do
        local showAtk = img.createUISprite(img.ui.tutorial_icon_atk)
        showAtk:setAnchorPoint(ccp(0, 0.5))
        showAtk:setPosition(282 + 71 * (i - 1), 67)
        standBg:addChild(showAtk)
    end

    local iconDef = img.createUISprite(img.ui.tutorial_icon_def)
    iconDef:setScale(0.75) 
    iconDef:setPosition(127, 63)
    board:addChild(iconDef)

    local txtDef = lbl.createMixFont1(18, i18n.global.tutorial_stand_defhero.string)
    txtDef:setAnchorPoint(ccp(0, 0.5)) 
    txtDef:setPosition(iconDef:boundingBox():getMaxX() + 10, iconDef:boundingBox():getMidY())
    board:addChild(txtDef)

    local iconAtk = img.createUISprite(img.ui.tutorial_icon_atk)
    iconAtk:setScale(0.75) 
    iconAtk:setPosition(403, 63)
    board:addChild(iconAtk)

    local txtAtk = lbl.createMixFont1(18, i18n.global.tutorial_stand_atkhero.string)
    txtAtk:setAnchorPoint(ccp(0, 0.5)) 
    txtAtk:setPosition(iconAtk:boundingBox():getMaxX() + 10, iconDef:boundingBox():getMidY())
    board:addChild(txtAtk)

    layer:registerScriptTouchHandler(function() return true end)
    layer:setTouchEnabled(true)

    return layer
end

return info
