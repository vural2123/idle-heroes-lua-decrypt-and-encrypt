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
local cfgfrdstage = require "config.friendstage"
local net = require "net.netClient"
local bag = require "data.bag"
local petBattle = require "ui.pet.petBattle"
local player = require "data.player"

function ui.create(video)
    local layer = require("fight.base.lose").create()

    local cfg = cfgfrdstage[video.stage]

    local friendboss = require "data.friendboss"
    local function nexthandler()
        local params = friendboss.video.curparams
        petBattle.addPetData(params.camp)
        addWaitNet()
        net:frd_boss_fight(params, function(__data)
            delWaitNet()

            tbl2string(__data)
            local friend = require "data.friend"
            if __data.status == -1 then
                showToast(i18n.global.friendboss_no_enegy.string)
                return
            elseif __data.status == -5 then
                showToast(i18n.global.event_processing.string)
                return
            end
            if __data.status == -3 then
                showToast(i18n.global.friendboss_boss_die.string)
                if pUid == player.uid then
                    friendboss.upscd()
                else
                    friend.changebossst(pUid, false)
                end
                return
            end
            if __data.status < 0 then
                showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                return
            end
			if __data.status > 0 then
				friend.bossdead(pUid)
			end

            local curvideo = clone(__data)
            if curvideo.rewards and video.select then
                bag.addRewards(curvideo.rewards[curvideo.select])
            end
            curvideo.uid = params.uid
            curvideo.stage = friendboss.video.stage
            curvideo.curparams = params
            friendboss.delEnegy()
            if __data.win then
                if pUid == player.uid then
                    friendboss.upscd()
                else
                    friend.changebossst(pUid, false)
                end
            end

            require ("fight.helper.ccamp").processCamp(curvideo)

            friendboss.video = clone(curvideo)
            replaceScene(require("fight.frdboss.loading").create(curvideo))
        end)
    end

    if friendboss.enegy > 0 then
        layer.addOkNextButton(function()
            require("fight.frdboss.loading").backToUI(video)
        end, function()
            require("fight.frdboss.loading").backToNext(video, nexthandler)
        end)
    else
        layer.addOkButton(function()
            require("fight.frdboss.loading").backToUI(video)
        end)
    end

    if video.hurts and #video.hurts > 0 then
        local camp = {}
        for i, m in ipairs(cfg.monster) do
            camp[#camp+1] = { kind = "mons", id = m, pos = cfg.stand[i] }
        end
        layer.addHurtsButton(video.camp, camp, video.hurts, video)
        require("fight.frdboss.win").addScoreAndHurtsSum(layer, video.hurts, cfg)
    end

    if video.rewards and video.select then
        layer:addChild(require("fight.pvp.lucky").create(video.rewards, video.select), 10)
    end

    return layer
end

return ui
