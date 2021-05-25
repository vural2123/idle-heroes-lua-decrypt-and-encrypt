-- 录像

local ui = {}

require "common.const"
require "common.func"
local view = require "common.view"
local audio = require "res.audio"
local hHelper = require "fight.helper.hero"
local fHelper = require "fight.helper.fx"

function ui.create(video)
    local layer = require("fight.base.video").create("solo")

    fHelper.addMap(layer, MAP_ID_ARENA)
    fHelper.addHelpButton(layer)
    fHelper.addSkipButton(layer)
    fHelper.addSpeedButton(layer)
    fHelper.addRoundLabel(layer)
    if video.atk and video.atk.pet then
        fHelper.addPetEp(layer)
    end
    layer.playBGM(audio.arena_bg)
    --layer.addPlayerName(replaceInvalidChars(video.atker.name), 
    --                    replaceInvalidChars(video.defender.name))

    -- override
    function layer.getVideoAndUnits()
        local attackers = {}
        for i, h in pairs(video.atk.camp) do
            attackers[i] = hHelper.createHero({
                id = h.id, lv = h.lv, pos = h.pos or 1, star = h.star, side = "attacker", ep = h.mp, 
                hp = h.hp, wake = h.wake, skin = h.skin,
            })
        end
        local defenders = {}                -- 在外部把monster转换成hero
        for i, h in pairs(video.def.camp) do
            defenders[i] = hHelper.createHero({
                id = h.id, lv = h.lv, pos = 6+h.pos, star = h.star, side = "defender", hp = h.hp, 
                wake = h.wake, skin = h.skin,
            })
        end
        -- 处理宝物带来的初始能量
        hHelper.processTreasureEp(attackers)
		hHelper.processTreasureEp(defenders)
        return video, attackers, defenders
    end

    -- override
    function layer.onVideoFrame(frame)
        fHelper.setRoundLabel(layer, frame.tid)
    end

    layer.startFight()

    return layer
end

return ui
