local empty = {}

require "common.func"
require "common.const"
local view = require "common.view"
local player = require "data.player"
local net = require "net.netClient"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local audio = require "res.audio"
local i18n = require "res.i18n"

--[[
params = {
    text = "mail",
    scale = 1, 小龙的缩放大小 
    size = 16, 字体大小
    color = ccc3(0x73, 0x3b, 0x05) 字体颜色
    width = 200 文本宽度
}
--]]

function empty.create(params)
    local spriteBox = CCSprite:create()
    spriteBox:setContentSize(CCSize(400, 200))

    local lblsize = params.size or 18 
    local lbltext = params.text or ""
    local lblcolor = params.color or ccc3(0x73, 0x3b, 0x05)
    local lblwidth = params.width or 400
    local dragonScale = params.scale or 1 

    local dragonicon = img.createUISprite(img.ui.mail_icon_nomail)
    dragonicon:setPosition(200, 120)
    dragonicon:setScale(dragonScale)
    spriteBox:addChild(dragonicon)
    

    --local label = lbl.createMixFont1(lblsize, lbltext, lblcolor)
    local label = lbl.createMix({
        font = 1, size = lblsize, text = lbltext, color = lblcolor,
        width =  lblwidth, align = kCCTextAlignmentLeftt
    })
    label:setPosition(200, 40)
    spriteBox:addChild(label)

    return spriteBox
end

return empty
