-- 录像

local ui = {}

require "common.const"
require "common.func"
local view = require "common.view"
local audio = require "res.audio"
local hHelper = require "fight.helper.hero"
local fHelper = require "fight.helper.fx"

function ui.create(videos, idx)
    -- 标记当前场次
    videos[idx].idx = idx
    local layer = require("fight.base.video").create("pvpf3")

    fHelper.addMap(layer, MAP_ID_ARENA)
    fHelper.addHelpButton(layer)
    fHelper.addSkipButton(layer)
    fHelper.addSpeedButton(layer)
    fHelper.addRoundLabel(layer)
    if videos[idx].atk and videos[idx].atk.pet then
        fHelper.addPetEp(layer)
    end
    layer.playBGM(audio.arena_bg)
    --layer.addPlayerName(replaceInvalidChars(video.atker.name), 
    --                    replaceInvalidChars(video.defender.name))

    -- override
    function layer.getVideoAndUnits()
        return require("fight.helper.ccamp").getVideoAndUnits(videos[idx])
    end

    -- override
    function layer.onVideoFrame(frame)
        fHelper.setRoundLabel(layer, frame.tid)
    end

    layer.startFight()

    return layer
end

return ui
