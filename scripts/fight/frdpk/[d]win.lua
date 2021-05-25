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
local net = require "net.netClient"
local petBattle = require "ui.pet.petBattle"
local player = require "data.player"

function ui.create(video)
    local layer = require("fight.base.win").create()

    video.noscore = true
    layer.addVsScores(video)

    local function nexthandler()
        local params = video.curparams
        petBattle.addPetData(params.camp)
        addWaitNet()
        net:frd_pk(params, function(__data)
            tbl2string(__data)
            delWaitNet()

            if __data.status == -1 then
                showToast(i18n.global.toast_arena_nocamp.string)
                return
            end
            if __data.status < 0 then
                showToast("status:" .. __data.status)
                return 
            end

            local curvideo = __data.video
            curvideo.atk.name = player.name
            curvideo.atk.lv = player.lv()
            curvideo.atk.logo = player.logo
           
            local tmp = curvideo.def.camp 
            curvideo.def = {}
            curvideo.def = clone(video.info)
            curvideo.def.camp = tmp

			require ("fight.helper.ccamp").processCamp(curvideo, nil, 2)
            
            --[[video.from_layer = {
                from_layer = "frdpk"
            }--]]
			curvideo.from_layer = video.from_layer

            curvideo.curparams = params
            curvideo.info = video.info
            replaceScene(require("fight.frdpk.loading").create(curvideo))
        end)
    end

    layer.addOkNextButton(function()
        require("fight.frdpk.loading").backToUI(video)
    end, function()
        require("fight.frdpk.loading").backToNext(video, nexthandler)
    end, "frdpk")

    if video.hurts and #video.hurts > 0 then
        layer.addHurtsButton(video.atk.camp, video.def.camp, video.hurts, video)
    end

    return layer
end

return ui
