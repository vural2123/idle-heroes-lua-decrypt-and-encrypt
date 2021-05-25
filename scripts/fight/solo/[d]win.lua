-- 胜利结算

local ui = {}

require "common.const"
require "common.func"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local i18n = require "res.i18n"
local audio = require "res.audio"
local herosdata = require "data.heros"

function ui.create(video)
    local layer = require("fight.base.win").create()

    video.noscore = true
    --layer.addVsScores(video)
    ui.addVsInfo(layer, video)

    layer.addOkButton(function()
        if video.auto then
            ui.backToUI(layer, video)
        else
            require("fight.solo.loading").backToUI(video)
        end
    end)

    if video.hurts and #video.hurts > 0 then
        layer.addHurtsButton(video.atk.camp, video.def.camp, video.hurts, video)
    end

    return layer
end

function ui.addVsInfo(layer, video)
    local vs = img.createUISprite(img.ui.fight_pay_vs)
    vs:setScale(view.minScale)
    vs:setPosition(scalep(480, 300))
    layer.content:addChild(vs)

    local function addInfo(info, win, isAttacker, x)
        local y = 303
        --local head = img.createPlayerHead(info.logo, info.lv)
        local head = img.createHeroHead(info.id, info.lv, info.group, info.star, info.wake, nil, nil, nil, info.hskills)
        head:setScale(view.minScale)
        head:setPosition(scalep(x, y))
        head:setCascadeOpacityEnabled(true)
        layer.content:addChild(head, 1)
        if win and not isAttacker then
            setShader(head, SHADER_GRAY, true)
        elseif not win and isAttacker then
            setShader(head, SHADER_GRAY, true)
        end
    end

    addInfo(video.atk.camp[1], video.win, true, 480-150)
    addInfo(video.def.camp[1], video.win, false, 480+150)
end

function ui.backToUI(layer, video)
    layer:removeFromParentAndCleanup(true)
    if video.callback then
        video.callback()
    end
end

return ui
