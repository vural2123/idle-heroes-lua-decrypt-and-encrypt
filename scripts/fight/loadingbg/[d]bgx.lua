-- loading bg 

local ui = {}

require "common.const"
require "common.func"
local view = require "common.view"
local img = require "res.img"
local json = require "res.json"
local lbl = require "res.lbl"
local audio = require "res.audio"
local i18n = require "res.i18n"

function ui.create()
    local layer = CCLayer:create()

    -- bg
	local bg = img.createUISprite(img.ui.fight_load_1_bg)
    bg:setScaleX(1280 / bg:getContentSize().width * view.minScale)
    bg:setScaleY(768/576*view.minScale)
    bg:setPosition(view.midX, view.midY)
    layer:addChild(bg)

    -- fg
    local fg = img.createUISprite(img.ui.fight_load_1_fg)
    fg:setScale(view.minScale)
    fg:setPosition(scalep(480, 300))
    layer:addChild(fg)

    -- progress bg
    local progressBg = img.createUISprite(img.ui.fight_load_bar_bg)
    progressBg:setScale(view.minScale)
    progressBg:setPosition(scalep(480, 129))
    layer:addChild(progressBg)  

    -- progress fg
    local progress0 = img.createUISprite(img.ui.fight_load_bar_fg)
    local progress = createProgressBar(progress0)
    progress:setScale(view.minScale)
    progress:setPosition(progressBg:getPosition())
    layer:addChild(progress)  

    -- progress light    
    local light = img.createUISprite(img.ui.fight_load_bar_light)
    light:setScale(view.minScale)
    light:setAnchorPoint(ccp(1, 0.5))
    light:setPositionY(progress:getPositionY())
    light:setVisible(false)   
    layer:addChild(light)

    -- label
    local label = lbl.createFont2(17, "", lbl.whiteColor, true)
    label:setPosition(progress:getPositionX(), progress:getPositionY()+7*view.minScale)
    layer:addChild(label)
                             
    -- 设置进度条末端光点位置 
    function layer.setPercentageForProgress(percentage)
        progress:setPercentage(percentage)
        label:setString(math.floor(percentage) .. "%")
        local rect = progress:boundingBox()
        light:setVisible(percentage > 10 and percentage < 95)
        light:setPositionX(rect:getMinX() + rect.size.width*percentage/100)
    end

    -- 提示文本
    local hint = lbl.createMix({
        font = 2, size = 17, text = "", color = lbl.whiteColor, minScale = true,
        width = 800, align = kCCTextAlignmentCenter
    })
    hint:setPosition(view.midX, scaley(43))
    layer:addChild(hint)

    function layer.setHint(text)
        if not tolua.isnull(hint) then
            hint:setString(text)
        end
    end

    return layer
end

return ui
