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
local cfgwavetrial = require "config.wavetrial"

function ui.create(video)
    local layer = require("fight.base.lose").create()

    layer.addEnhanceGuide({
        backToSmith = function()
            require("fight.trial.loading").backToSmith(video)
        end,
        backToHero = function()
            require("fight.trial.loading").backToHero(video)
        end,
        backToSummon = function()
            require("fight.trial.loading").backToSummon(video)
        end,
    })

    layer.addOkButton(function()
        require("fight.trial.loading").backToUI(video)
    end)

    if video.hurts and #video.hurts > 0 then
        local camp = {}
        local cfg = cfgwavetrial[video.stage]
        for i, m in ipairs(cfg.trial) do
            camp[#camp+1] = { kind = "mons", id = m, pos = cfg.stand[i] }
        end
        layer.addHurtsButton(video.camp, camp, video.hurts, video)
    end

    return layer
end

return ui
