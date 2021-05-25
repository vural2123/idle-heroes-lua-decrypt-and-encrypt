-- 背包界面

local ui = {}

require "common.func"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"

function ui.create(backlayer, tagType)
    local layer = CCLayer:create()
    -- bg
    local bg = img.createUISprite(img.ui.bag_bg)
    bg:setScale(view.minScale)
    bg:setPosition(view.midX, view.midY)
    layer:addChild(bg)

    local mainui = require "ui.bag.mainui"
    layer:addChild(mainui.create(backlayer, tagType), 100)

    require("ui.tutorial").show("ui.bag.main", layer)

    return layer
end

return ui
