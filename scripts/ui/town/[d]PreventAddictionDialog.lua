local ui = {}

require "common.const"
require "common.func"

local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local i18n = require "res.i18n"
local audio = require "res.audio"
local data = require "data.preventaddiction"

local BG_WIDTH = 436
local BG_HEIGHT = 300

function ui.create(parentLayer)

    local layer = CCLayer:create()

    -- dark bg
    local darkBg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    layer:addChild(darkBg)

    -- bg
    local bg = img.createLogin9Sprite(img.login.dialog)
    bg:setPreferredSize(CCSize(BG_WIDTH, BG_HEIGHT))
    bg:setScale(view.minScale)
    bg:setPosition(scalep(480, 314))
    layer:addChild(bg)

    -- closeBtn
    local closeBtn0 = img.createLoginSprite(img.login.button_close)
    local closeBtn = SpineMenuItem:create(json.ui.button, closeBtn0)
    closeBtn:setPosition(BG_WIDTH - 30, BG_HEIGHT - 30)
    local closeMenu = CCMenu:createWithItem(closeBtn)
    closeMenu:setPosition(0, 0)
    bg:addChild(closeMenu)
    closeBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer.onAndroidBack()
    end)

    local adult = data.getAdult()
    local totalTime = data.getTotalTime()

    local des = nil
    if adult == 0 then

        if totalTime >= data.FIVE_HOUR then
            des = i18n.global.idcard_verify_des_five_hour.string
        elseif totalTime >= data.THREE_HOUR then
            des = i18n.global.idcard_verify_des_three_hour.string
        end

        local okBtn0 = img.createLogin9Sprite(img.login.button_9_small_gold)
        okBtn0:setPreferredSize(CCSize(160, 50))
        local okBtn = SpineMenuItem:create(json.ui.button, okBtn0)
        local okSize = okBtn:getContentSize()
        okBtn:setPosition(BG_WIDTH / 2, 76)

        local okText = i18n.global.go_idcard_verify.string
        local okLabel = lbl.createFont1(16, okText, ccc3(0x73, 0x3b, 0x05))
        okLabel:setPosition(okSize.width / 2, okSize.height / 2)
        okBtn0:addChild(okLabel)
        local okMenu = CCMenu:createWithItem(okBtn)
        okMenu:setPosition(0, 0)
        bg:addChild(okMenu)
        okBtn:registerScriptTapHandler(function()
            audio.play(audio.button)
            layer:removeFromParent()

            parentLayer:addChild(require("ui.town.IdCardVerifyDialog").create(), 1000)
        end)

    elseif adult == 2 then
        if totalTime >= data.FIVE_HOUR then
            des = i18n.global.prevent_addiction_des_five_hour.string
        elseif totalTime >= data.THREE_HOUR then
            des = i18n.global.prevent_addiction_des_three_hour.string
        end
    end

    local desParams = { font = 1, size = 18, text = des, color = ccc3(0x71, 0x3f, 0x16), width = 369, align = kCCTextAlignmentLeft }

    local desLabel = lbl.createMix(desParams)
    desLabel:setAnchorPoint(ccp(0.5, 1))
    desLabel:setPosition(BG_WIDTH / 2, 202)
    bg:addChild(desLabel)

    if totalTime >= data.FIVE_HOUR then
        data.setDialogShowTime(data.MAX_HOUR)
    elseif totalTime >= data.THREE_HOUR then
        data.setDialogShowTime(data.FIVE_HOUR)
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