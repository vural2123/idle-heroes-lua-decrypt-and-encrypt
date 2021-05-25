-- 忘记密码

local ui = {}

require "common.const"
require "common.func"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local audio = require "res.audio"
local i18n = require "res.i18n"

-- 背景框大小
local BG_WIDTH   = 666
local BG_HEIGHT  = 415

function ui.create()
    local layer = CCLayer:create()

    -- dark bg
    local darkbg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    layer:addChild(darkbg)

    -- bg
    local bg = img.createLogin9Sprite(img.login.tips_bg)
    bg:setPreferredSize(CCSize(BG_WIDTH, BG_HEIGHT))
    bg:setScale(view.minScale * 0.1)
    bg:setAnchorPoint(ccp(0.5,0.5))
    bg:setPosition(view.midX, view.midY)
    bg:runAction(CCEaseBackOut:create(CCScaleTo:create(0.3, view.minScale)))
    layer:addChild(bg)
    
    -- closeBtn
    local closeBtn0 = img.createLoginSprite(img.login.button_close)
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
    local title = lbl.createFont1(24, i18n.global.forget_password_title.string, ccc3(0xff, 0xe3, 0x86))
    title:setPosition(BG_WIDTH/2, BG_HEIGHT-36)
    bg:addChild(title)

    -- line
    local line = img.createLoginSprite(img.login.help_line)
    line:setScaleX(610/line:getContentSize().width)
    line:setPosition(BG_WIDTH/2, BG_HEIGHT-64)
    bg:addChild(line)

    -- desc
    local desc = lbl.createMix({
        font = 1, size = 16, text = i18n.global.forget_password_text.string, 
        color = ccc3(0xfe, 0xeb, 0xca), width = 610, align = kCCTextAlignmentLeft
    })
    desc:setAnchorPoint(ccp(0, 1))
    desc:setPosition(30, BG_HEIGHT-90)
    bg:addChild(desc)

    -- email
    local email = lbl.createMixFont1(16,".resetpassword email", ccc3(0x3e, 0x85, 0xf8))
    email:setAnchorPoint(ccp(0, 1))
    email:setPosition(30, desc:boundingBox():getMinY()-8)
    bg:addChild(email)

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
