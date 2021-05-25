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

    video.noscore = true
    --layer.addVsScores(video)
    require("fight.solo.win").addVsInfo(layer, video)

    layer.addOkButton(function()
        if video.auto then
            require("fight.solo.win").backToUI(layer, video)
        else
            require("fight.solo.loading").backToUI(video)
        end
    end)

    if video.hurts and #video.hurts > 0 then
        layer.addHurtsButton(video.atk.camp, video.def.camp, video.hurts, video)
    end

    return layer
end

return ui
