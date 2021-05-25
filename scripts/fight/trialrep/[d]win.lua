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
local cfgwavetrial = require "config.wavetrial"

function ui.create(video)
    local layer = require("fight.base.win").create()

    layer.addRewardIcons(video.reward)

    layer.addOkButton(function()
        require("fight.trialrep.loading").backToUI(video)
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
