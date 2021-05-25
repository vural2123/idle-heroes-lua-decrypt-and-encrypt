-- 失败结算

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
    local layer = require("fight.base.lose").create()

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
        require("fight.broken.win").addScoreAndHurtsSum(layer, video.hurts, cfg)
    end

    if video.rewards and video.select then
        layer:addChild(require("fight.pvp.lucky").create(video.rewards, video.select), 10)
    end

    return layer
end

return ui
