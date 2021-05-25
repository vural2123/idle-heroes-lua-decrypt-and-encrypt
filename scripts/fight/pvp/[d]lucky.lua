-- 三抽一

local ui = {}

require "common.const"
require "common.func"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local i18n = require "res.i18n"
local audio = require "res.audio"

function ui.create(rewards, index, animts)
    local layer = CCLayer:create()

    -- dark bg
    local darkbg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    layer:addChild(darkbg)

    -- box
    local boxes = {}
    local xy = { { 480-200, 288 }, { 480, 288 }, { 480+200, 288 } }
    for i = 1, 3 do
        boxes[i] = json.create(json.ui.pvp_choujiang)
        boxes[i]:setScale(view.minScale)
        boxes[i]:setPosition(scalep(xy[i][1], xy[i][2]))
        if i == 2 then
            boxes[i]:playAnimation("birth")
            boxes[i]:appendNextAnimation("loop", -1)
        else
            boxes[i]:setVisible(false)
        end

        layer:addChild(boxes[i])
    end

    -- 初始效果


    -- 选中第s个
    local function onSelect(s)
        local things = {}
        for i, r in ipairs(rewards) do
            things[i] = rewards[i]
        end
        if index ~= s then
            local tmp = things[index]
            things[index] = things[s]
            things[s] = tmp
        end
        for i, thing in ipairs(things) do
            local icon, kind, t
            if thing.equips and #thing.equips > 0 then
                kind = "equip"
                t = thing.equips[1]
                icon = img.createEquip(t.id, t.num)
            else
                kind = "item"
                t = thing.items[1]
                icon = img.createItem(t.id, t.num)
            end
            icon:setCascadeOpacityEnabled(true)
            local btn = SpineMenuItem:create(json.ui.button, icon)
            btn:setCascadeOpacityEnabled(true)
            local menu = CCMenu:createWithItem(btn)
            menu:setCascadeOpacityEnabled(true)
            menu:ignoreAnchorPointForPosition(false)
            boxes[i]:addChildFollowSlot("code_gear", menu)
            schedule(boxes[i], op3(i == s, 0, 1), function()
                boxes[i]:clearNextAnimation()
                boxes[i]:playAnimation(op3(i == s, "click", "notclick"))
                boxes[i]:registerAnimation(op3(i == s, "end_loop2", "end_loop"), -1)
            end)
            btn:registerScriptTapHandler(function()
                audio.play(audio.button)
                if kind == "equip" then
                    layer:addChild(require("ui.tips.equip").createForShow(t), 1000)
                else
                    layer:addChild(require("ui.tips.item").createForShow(t), 1000)
                end
            end)
        end
        audio.play(audio.battle_card_reward)
    end

    addBackEvent(layer)

    function layer.onAndroidBack()
    end

    layer:registerScriptHandler(function(event)
        if event == "enter" then
            layer.notifyParentLock()
        elseif event == "exit" then
            layer.notifyParentUnlock()
        end
    end)

    local state = "selected"
    onSelect(2)
    schedule(layer, 1.5, function()
        if state == "selected" then
            state = "removed"
            layer:removeFromParent()
        end
    end)

    local function onTouch(eventType, x, y)
        if eventType == "began" then   
            return true
        elseif eventType == "moved" then
            return 
        else 
            if state == "unselected" then
                for i, box in ipairs(boxes) do
                    if box:getAabbBoundingBox():containsPoint(ccp(x, y)) then
                        state = "selected"
                        onSelect(i)
                        break
                    end
                end
            elseif state == "selected" then
                state = "removed"
                layer:removeFromParent()
            end
        end
    end

    layer:registerScriptTouchHandler(onTouch)
    layer:setTouchEnabled(true)
    layer:setTouchSwallowEnabled(true)

    return layer
end

return ui 
