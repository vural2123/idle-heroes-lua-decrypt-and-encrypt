-- usefull when showing simple info

local toast = {}

require "common.func"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"

function toast.create(text)
    local layer = CCLayer:create()

    -- label
    local label = lbl.createMixFont1(16, text, ccc3(0xff, 0xfb, 0xd9))
    local size = label:boundingBox().size

    -- bg
    local bg = img.createLogin9Sprite(img.login.toast_bg)
    local bgsize = CCSize(op3(size.width>360, size.width+120, 480), size.height+45)
    bg:setCascadeOpacityEnabled(true)
    bg:setPreferredSize(bgsize)
    bg:setPosition(view.midX, view.midY)
    bg:setScale(0.1 * view.minScale)
    bg:runAction(CCEaseBackOut:create(CCScaleTo:create(0.3, view.minScale)))
    layer:addChild(bg)
    label:setPosition(bgsize.width/2, bgsize.height/2)
    bg:addChild(label)

    layer:runAction(createSequence({
        CCDelayTime:create(2),
        CCTargetedAction:create(bg, CCFadeOut:create(0.1)),
        CCRemoveSelf:create(),
    }))

    return layer 
end

return toast 
