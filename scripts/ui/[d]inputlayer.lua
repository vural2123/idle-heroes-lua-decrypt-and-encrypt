-- layer for input 

local inputlayer = {}

require "common.func"
local view = require "common.view"
local i18n = require "res.i18n"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local audio = require "res.audio"

local edit_txt_color = ccc3(0x42, 0x24, 0x06)
local edit_txt_placeholder_color = ccc3(0x61, 0x61, 0x61)

function inputlayer.create(callback, default_str, uiParams)
    local maxLen = uiParams and uiParams.maxLen or 140
    local layer = CCLayer:create()

    local is_end = false

    -- dark bg
    local darkbg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    layer:addChild(darkbg)

    -- backBtn
    local backBtn0 = img.createUISprite(img.ui.back)
    local backBtn = HHMenuItem:create(backBtn0)
    backBtn:setScale(view.minScale)
    backBtn:setPosition(scalep(44, 540))
    local backMenu = CCMenu:createWithItem(backBtn)
    backMenu:setPosition(0, 0)
    layer:addChild(backMenu)
    layer.back = backBtn
    local function backEvent()
        layer.edit_box:unregisterScriptEditBoxHandler()
        layer:removeFromParentAndCleanup(true)
    end
    backBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        backEvent()
    end)
    function layer.onAndroidBack()
        backEvent()
    end

    local edit_box_0 = img.createLogin9Sprite(img.login.input_border)
    local edit_box = CCEditBox:create(CCSizeMake(view.physical.w-160*view.minScale-view.minX, 40*view.minScale), edit_box_0)
    edit_box:setMaxLength(maxLen)
    edit_box:setFont("", 16*view.minScale)
    edit_box:setInputFlag(kEditBoxInputFlagInitialCapsSentence)
    edit_box:setReturnType(kKeyboardReturnTypeDone)
    edit_box:setAnchorPoint(CCPoint(0,0))
    edit_box:setPosition(CCPoint(view.minX+10*view.minScale,view.midY+150*view.minScale))
    edit_box:setFontColor(edit_txt_color)
    edit_box:setPlaceholderFontColor(edit_txt_placeholder_color)
    layer:addChild(edit_box, 10000)
    layer.edit_box = edit_box
    if default_str then
        edit_box:setText(default_str)
    end

    local function onConfirm()
        local _str = edit_box:getText()
        if callback then
            callback(_str)
        end
        is_end = true
    end

    -- btn_confirm
    local btn_confirm0 = img.createLogin9Sprite(img.login.button_9_small_gold)
    btn_confirm0:setPreferredSize(CCSizeMake(115, 45))
    local lbl_confirm = lbl.createFont1(18, i18n.global.dialog_button_confirm.string, ccc3(0x73, 0x3b, 0x05))
    lbl_confirm:setPosition(CCPoint(btn_confirm0:getContentSize().width/2,
                    btn_confirm0:getContentSize().height/2))
    btn_confirm0:addChild(lbl_confirm)
    local btn_confirm = SpineMenuItem:create(json.ui.button, btn_confirm0)
    btn_confirm:setScale(view.minScale)
    btn_confirm:setAnchorPoint(CCPoint(0.5,0.5))
    btn_confirm:setPosition(CCPoint(edit_box:boundingBox():getMaxX()+65*view.minScale,
                    edit_box:boundingBox():getMinY()+18*view.minScale))
    local btn_confirm_menu = CCMenu:createWithItem(btn_confirm)
    btn_confirm_menu:setPosition(CCPoint(0,0))
    layer:addChild(btn_confirm_menu)
    btn_confirm:registerScriptTapHandler(function()
        audio.play(audio.button)
        onConfirm()
    end)

    edit_box:registerScriptEditBoxHandler(function(eventType)
        print("eventType:", eventType)
        if eventType == "returnSend" then
        elseif eventType == "return" then
        elseif eventType == "returnDone" then
            onConfirm()
        elseif eventType == "began" then
        elseif eventType == "changed" then
        elseif eventType == "ended" then
        end
    end)

    layer:setTouchEnabled(true)
    layer:setTouchSwallowEnabled(true)

    local function onUpdate(ticks)
        if true == is_end then
            layer:removeFromParentAndCleanup(true)
        end
    end
    layer:scheduleUpdateWithPriorityLua(onUpdate, 0)
        
    addBackEvent(layer)

    local function onEnter()
        print("onEnter")
        layer.notifyParentLock()
    end
    local function onExit()
        layer.notifyParentUnlock()
    end
    layer:registerScriptHandler(function(event)
        if event == "enter" then
            onEnter()
        elseif event == "exit" then
            onExit()
        end
    end)

    return layer
end

return inputlayer
