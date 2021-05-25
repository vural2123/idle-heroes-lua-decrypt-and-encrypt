local ui = {}

require "common.const"
require "common.func"
require "framework.init"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local i18n = require "res.i18n"
local audio = require "res.audio"
local net = require "net.netClient"
local player = require "data.player"
local preventAddictionData = require "data.preventaddiction"

local BG_WIDTH = 494
local BG_HEIGHT = 369

function ui.create()

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

    local titleText = i18n.global.idcard_verify_title.string
    local title = lbl.createFont1(24, titleText, ccc3(0xe6, 0xd0, 0xae))
    title:setPosition(BG_WIDTH / 2, BG_HEIGHT - 30)

    local titleS = lbl.createFont1(24, titleText, ccc3(0x59, 0x30, 0x1b))
    titleS:setPosition(BG_WIDTH / 2, BG_HEIGHT - 32)
    bg:addChild(titleS)
    bg:addChild(title)

    -- closeBtn
    local closeBtn0 = img.createLoginSprite(img.login.button_close)
    local closeBtn = SpineMenuItem:create(json.ui.button, closeBtn0)
    closeBtn:setPosition(BG_WIDTH - 24, BG_HEIGHT - 24)
    local closeMenu = CCMenu:createWithItem(closeBtn)
    closeMenu:setPosition(0, 0)
    bg:addChild(closeMenu)
    closeBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer.onAndroidBack()
    end)

    local nameText = i18n.global.idcard_verify_name.string
    local nameLabel = lbl.createFont1(18, nameText, ccc3(113, 63, 22))
    nameLabel:setAnchorPoint(ccp(0, 0.5))
    nameLabel:setPosition(71, 264)
    bg:addChild(nameLabel)

    local idCardText = i18n.global.idcard_verify_number.string
    local idCardLabel = lbl.createFont1(18, idCardText, ccc3(113, 63, 22))
    idCardLabel:setAnchorPoint(ccp(0, 0.5))
    idCardLabel:setPosition(nameLabel:getPositionX(), 190)
    bg:addChild(idCardLabel)

    local nameBg = img.createLogin9Sprite(img.login.input_border)
    local nameEditBox = CCEditBox:create(CCSize(354 * view.minScale, 40 * view.minScale), nameBg)
    nameEditBox:setInputFlag(kEditBoxInputFlagInitialCapsSentence)
    nameEditBox:setReturnType(kKeyboardReturnTypeDone)
    if device.platform == "android" then
        nameEditBox:setFont("", 16 * view.minScale)
    elseif device.platform == "ios" then
        nameEditBox:setFont("", 14 * view.minScale)
    end
    nameEditBox:setFontColor(ccc3(0x0, 0x0, 0x0))
    nameEditBox:setPosition(scalep(480, 359))
    layer:addChild(nameEditBox, 1)

    local idCardBg = img.createLogin9Sprite(img.login.input_border)
    local idCardEditBox = CCEditBox:create(CCSize(354 * view.minScale, 40 * view.minScale), idCardBg)
    --idCardEditBox:setInputMode(kEditBoxInputModeDecimal)
    idCardEditBox:setReturnType(kKeyboardReturnTypeDone)
    if device.platform == "android" then
        idCardEditBox:setFont("", 16 * view.minScale)
    elseif device.platform == "ios" then
        idCardEditBox:setFont("", 14 * view.minScale)
    end
    idCardEditBox:setFontColor(ccc3(0x0, 0x0, 0x0))
    idCardEditBox:setPosition(scalep(480, 286))
    layer:addChild(idCardEditBox, 1)

    local okBtn0 = img.createLogin9Sprite(img.login.button_9_small_gold)
    okBtn0:setPreferredSize(CCSize(172, 50))

    local okBtn = SpineMenuItem:create(json.ui.button, okBtn0)
    local okSize = okBtn:getContentSize()
    okBtn:setPosition(BG_WIDTH / 2, 76)

    local okText = i18n.global.idcard_verify_confirm.string
    local okLabel = lbl.createFont1(16, okText, ccc3(0x73, 0x3b, 0x05))
    okLabel:setPosition(okSize.width / 2, okSize.height / 2)
    okBtn0:addChild(okLabel)

    local okMenu = CCMenu:createWithItem(okBtn)
    okMenu:setPosition(0, 0)
    bg:addChild(okMenu)

    okBtn:registerScriptTapHandler(function()
        audio.play(audio.button)

        local name = string.trim(nameEditBox:getText())
        local idCard = string.trim(idCardEditBox:getText())

        local params = {
            sid = player.sid,
            id = idCard,
            name = name,
        }

        local isDone = false
        addWaitNet(function()
            delWaitNet()
            isDone = true
            net:close()
            showToast(i18n.global.error_network_timeout.string)
        end)

        net:idcard_verify(params, function(result)
            delWaitNet()

            if isDone then
                return
            end

            isDone = true

            if result.status == 0 then
                showToast(i18n.global.idcard_verify_success_des.string)
                layer:removeFromParent()

                if result.adult then
                    preventAddictionData.setAdult(result.adult)
                end
            elseif result.status == -1 then
                --非法的身份证号码(格式)
                showToast(i18n.global.idcard_verify_failed_des.string)
            elseif result.status == -2 then
                --身份证验证不通过
                showToast(i18n.global.idcard_verify_failed_des.string)
            elseif result.status == -3 then
                --身份证号码和名字不一致
                showToast(i18n.global.idcard_verify_failed_des.string)
            else
                showToast(i18n.global.idcard_verify_failed_des.string)
            end
        end)
    end)

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