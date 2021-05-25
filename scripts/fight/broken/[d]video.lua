-- 录像

local ui = {}

require "common.const"
require "common.func"
local view = require "common.view"
local audio = require "res.audio"
local hHelper = require "fight.helper.hero"
local fHelper = require "fight.helper.fx"
local cfgbrokenboss= require "config.brokenboss"
local cfgmons = require "config.monster"

function ui.create(video)
    local layer = require("fight.base.video").create("broken")
    local cfg = cfgbrokenboss[video.stage]

    fHelper.addMap(layer, cfg.map)
    fHelper.addHelpButton(layer)
    fHelper.addSkipButton(layer)
    fHelper.addSpeedButton(layer)
    fHelper.addRoundLabel(layer)
    if video.atk and video.atk.pet then
        fHelper.addPetEp(layer)
    end
    layer.playBGM(audio.fight_bg[math.random(#audio.fight_bg)])

    -- override
    function layer.getVideoAndUnits()
        return require("fight.helper.ccamp").getVideoAndUnits(video)
    end

    -- override
    function layer.onVideoFrame(frame)
        fHelper.setRoundLabel(layer, frame.tid)
    end

    layer.startFight()

    return layer
end

return ui
