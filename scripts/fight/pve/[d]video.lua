-- 录像

local ui = {}

require "common.const"
require "common.func"
local view = require "common.view"
local audio = require "res.audio"
local hHelper = require "fight.helper.hero"
local fHelper = require "fight.helper.fx"
local cfgstage = require "config.stage"
local cfgmons = require "config.monster"

function ui.create(video)
    local layer = require("fight.base.video").create("pve")
    local stage = video.stage

    fHelper.addMap(layer, cfgstage[stage].map)
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

    local tutorialData = require("data.tutorial")
    local tutorialUI = require("ui.tutorial")

    if tutorialData.getVersion() == 1 then
        tutorialUI.show("fight.pve.video", layer)

        if require("data.tutorial").is("hook", 2) then 
            schedule(layer, 1, function()
                fHelper.popHelp(layer)
                require("data.tutorial").goNext("hook", 2) 
            end)
        else
            fHelper.addSkipButton(layer)
            fHelper.addHelpButton(layer)
            fHelper.addSpeedButton(layer, false)
        end
    else
        tutorialUI.setFightLayer(layer)
        schedule(layer, 0.1, function()
            tutorialUI.show("fight.pve.video", layer:getParent())
        end)

        if tutorialData.is("hook", 2) then 
            schedule(layer, 0.7, function()
                -- layer.isPaused = true --don't mask
                pauseSchedulerAndActions(layer)
            end)
        end

        fHelper.addSkipButton(layer)
        fHelper.addHelpButton(layer)
        fHelper.addSpeedButton(layer, false)
    end

    layer.startFight()

    return layer
end

return ui
