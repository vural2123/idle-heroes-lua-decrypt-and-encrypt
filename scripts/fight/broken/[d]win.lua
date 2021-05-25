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
local cfgbrokenboss= require "config.brokenboss"

function ui.create(video)
    local layer = require("fight.base.win").create()

    local cfg = cfgbrokenboss[video.stage]

    layer.addOkButton(function()
        require("fight.broken.loading").backToUI(video)
    end)

    if video.hurts and #video.hurts > 0 then
        local camp = {}
        for i, m in ipairs(cfg.monster) do
            camp[#camp+1] = { kind = "mons", id = m, pos = cfg.stand[i] }
        end
        layer.addHurtsButton(video.camp, camp, video.hurts, video)
        ui.addScoreAndHurtsSum(layer, video.hurts, cfg)
    end

    if video.rewards and video.select then
        layer:addChild(require("fight.pvp.lucky").create(video.rewards, video.select), 10)
    end

    return layer
end

function ui.addScoreAndHurtsSum(layer, hurts, cfg)
    local value = 0
    for _, h in ipairs(hurts) do
        if h.pos <= 6 then
            value = value + h.value
        end
    end
    --local text1 = lbl.createFont2(18, i18n.global.fight_pvp_score.string .. ":", ccc3(0xfc, 0xd7, 0x75), true)
    --text1:setAnchorPoint(ccp(1, 0.5))
    --text1:setPosition(scalep(480, 320))
    --layer.content:addChild(text1)
    --local num1 = lbl.createFont2(18, "+" .. math.ceil(value/cfg.coefficient), lbl.whiteColor, true)
    --num1:setAnchorPoint(ccp(0, 0.5))
    --num1:setPosition(scalep(490, 320))
    --layer.content:addChild(num1)
    local text2 = lbl.createFont2(18, i18n.global.fight_hurts_sum.string .. ":", ccc3(0xfc, 0xd7, 0x75), true)
    text2:setAnchorPoint(ccp(1, 0.5))
    text2:setPosition(scalep(480, 300))
    layer.content:addChild(text2)
    local num2 = lbl.createFont2(18, value, lbl.whiteColor, true)
    num2:setAnchorPoint(ccp(0, 0.5))
    num2:setPosition(scalep(490, 300))
    layer.content:addChild(num2)
end

return ui
