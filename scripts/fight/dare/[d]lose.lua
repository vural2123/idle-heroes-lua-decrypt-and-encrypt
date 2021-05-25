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
local cfgdarestage = require "config.darestage"

function ui.create(video)
    local layer = require("fight.base.lose").create()

    --[[layer.addEnhanceGuide({
        backToSmith = function()
            require("fight.dare.loading").backToSmith(video)
        end,
        backToHero = function()
            require("fight.dare.loading").backToHero(video)
        end,
        backToSummon = function()
            require("fight.dare.loading").backToSummon(video)
        end,
    })--]]

    layer.addOkButton(function()
        --require("fight.dare.loading").backToUI(video)
		replaceScene(require("ui.town.main").create({from_layer="dareStage", type=video.type}))
    end)

    return layer
end

return ui
