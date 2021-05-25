-- 出售的tips

local tips = {}

require "common.func"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local audio = require "res.audio"
local cfgequip = require "config.equip"
local cfgitem = require "config.item"
local i18n = require "res.i18n"

local TIPS_WIDTH = 360
local TIPS_HEIGHT = 345

-- kind = "equip" | "item"
-- thing = { id, num } 可为equip或item
-- handler = function(thing)
function tips.create(kind, thing, handler)
    local layer = CCLayer:create()

    local price
    if kind == "equip" then
        price = cfgequip[thing.id].price
    else
        price = cfgitem[thing.id].recoveryPrice
    end

    -- tips背景
    local bg = img.createUI9Sprite(img.ui.tips_bg)
    bg:setPreferredSize(CCSize(TIPS_WIDTH, TIPS_HEIGHT))
    bg:setScale(view.minScale)
    bg:setPosition(view.physical.w/2, view.physical.h/2)
    layer:addChild(bg)

    -- name
    local nameText, nameColor
    if kind == "equip" then
        nameText = i18n.equip[thing.id].name
        nameColor = lbl.qualityColors[cfgequip[thing.id].qlt]
    else
        nameText = i18n.item[thing.id].name
        nameColor = lbl.qualityColors[cfgitem[thing.id].qlt]
    end
    local name = lbl.createMix({
        font = 1, size = 18, text = nameText, color = nameColor,
        width = LABEL_WIDTH, align = kCCTextAlignmentLeft,
    })
    name:setPosition(TIPS_WIDTH/2, TIPS_HEIGHT - 30)
    bg:addChild(name)

    -- icon
    local icon
    if kind == "equip" then
        icon = img.createEquip(thing.id)
    else
        icon = img.createItem(thing.id)
    end
    icon:setPosition(TIPS_WIDTH/2, TIPS_HEIGHT - 97)
    bg:addChild(icon)

    -- sub button
    local subBtn0 = img.createUISprite(img.ui.tips_sell_sub)
    local subBtn = SpineMenuItem:create(json.ui.button, subBtn0)
    subBtn:setPosition(TIPS_WIDTH/2 - 82, TIPS_HEIGHT - 177)
    local subMenu = CCMenu:createWithItem(subBtn)
    subMenu:setPosition(0, 0)
    bg:addChild(subMenu)

    -- add button
    local addBtn0 = img.createUISprite(img.ui.tips_sell_add)
    local addBtn = SpineMenuItem:create(json.ui.button, addBtn0)
    addBtn:setPosition(TIPS_WIDTH/2 + 82, TIPS_HEIGHT - 177)
    local addMenu = CCMenu:createWithItem(addBtn)
    addMenu:setPosition(0, 0)
    bg:addChild(addMenu)

    -- input box
    local inputBoxBg = img.createLogin9Sprite(img.login.input_border)
    local inputBox = CCEditBox:create(CCSize(90*view.minScale, 35*view.minScale), inputBoxBg)
    inputBox:setInputMode(kEditBoxInputModeNumeric)
    inputBox:setReturnType(kKeyboardReturnTypeDone)
    inputBox:setFont("", 14*view.minScale)
    inputBox:setFontColor(ccc3(0x42, 0x24, 0x06))
    inputBox:setText(tostring(thing.num))
    inputBox:setPosition(scalep(480, 285))
    inputBox.num = thing.num
    layer:addChild(inputBox, 1)

    -- sell button
    local sellBtn0 = img.createLogin9Sprite(img.login.button_9_small_gold)
    sellBtn0:setPreferredSize(CCSize(138, 47))
    local sellBtn = SpineMenuItem:create(json.ui.button, sellBtn0)
    local sellBtnSize = sellBtn:getContentSize()
    sellBtn:setPosition(TIPS_WIDTH/2, TIPS_HEIGHT - 289)
    local sellLabel = lbl.createFont1(18, i18n.global.tips_gift.string, ccc3(0x73, 0x3b, 0x05))
    sellLabel:setPosition(sellBtnSize.width/2, sellBtnSize.height/2)
    sellBtn0:addChild(sellLabel)
    local sellMenu = CCMenu:createWithItem(sellBtn)
    sellMenu:setPosition(0, 0)
    bg:addChild(sellMenu)
    sellBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        if handler then
            handler({ id = thing.id, num = inputBox.num })
        end
    end)

    subBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        if inputBox.num > 1 then
            inputBox.num = inputBox.num - 1
            inputBox:setText(tostring(inputBox.num))
        end
    end)

    addBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        if inputBox.num < thing.num then
            inputBox.num = inputBox.num + 1
            inputBox:setText(tostring(inputBox.num))
        end
    end)

    inputBox:registerScriptEditBoxHandler(function(event)
        if event == "changed"or event == "ended" then
            local num = checkint(string.trim(inputBox:getText()))
            if num < 1 then
                num = 1
            elseif num > thing.num then
                num = thing.num
            end
            inputBox.num = num
            inputBox:setText(tostring(inputBox.num))
        end
    end)

    -- 点击空白区域的回调
    local clickBlankHandler
    function layer.setClickBlankHandler(handler)
        clickBlankHandler = handler
    end

    local beginx, beginy
    local function onTouch(eventType, x, y)
        if eventType == "began" then   
            beginx, beginy = x, y
            return true
        elseif eventType == "moved" then
            return 
        else
            if not bg:boundingBox():containsPoint(ccp(x, y)) 
                and not bg:boundingBox():containsPoint(ccp(beginx, beginy)) then
                layer.onAndroidBack()
            end
            return
        end
    end

    addBackEvent(layer)

    function layer.onAndroidBack()
        if clickBlankHandler then
            clickBlankHandler()
        else
            layer:removeFromParent()
        end
    end

    layer:registerScriptHandler(function(event)
        if event == "enter" then
            layer.notifyParentLock()
        elseif event == "exit" then
            layer.notifyParentUnlock()
        end
    end)

    layer:registerScriptTouchHandler(onTouch)
    layer:setTouchEnabled(true)
    layer:setTouchSwallowEnabled(true)

    return layer
end

return tips
