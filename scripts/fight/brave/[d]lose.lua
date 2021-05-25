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

function ui.create(video)
    local layer = require("fight.base.lose").create()

    layer.addEnhanceGuide({
        backToSmith = function()
            require("fight.brave.loading").backToSmith(video)
        end,
        backToHero = function()
            require("fight.brave.loading").backToHero(video)
        end,
        backToSummon = function()
            require("fight.brave.loading").backToSummon(video)
        end,
    })

    layer.addOkButton(function()
        require("fight.brave.loading").backToUI(video)
    end)

    if video.hurts and #video.hurts > 0 then
        layer.addHurtsButton(video.atk.camp, video.def.camp, video.hurts, video)
    end

    return layer
end

return ui
