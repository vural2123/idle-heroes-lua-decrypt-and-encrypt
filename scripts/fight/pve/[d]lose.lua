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
local cfgstage = require "config.stage"

function ui.create(video)
    local layer = require("fight.base.lose").create()

	if not video.isBatch then
		layer.addEnhanceGuide({
			backToSmith = function()
				require("fight.pve.loading").backToSmith(video)
			end,
			backToHero = function()
				require("fight.pve.loading").backToHero(video)
			end,
			backToSummon = function()
				require("fight.pve.loading").backToSummon(video)
			end,
		})
	end

    layer.addOkButton(function()
		if video.isBatch then
			replaceScene(require("ui.hook.map").create({ win = false }))
		else
			require("fight.pve.loading").backToUI(video)
		end
    end)

    if video.hurts and #video.hurts > 0 then
        local camp = {}
        local cfg = cfgstage[video.stage]
        for i, m in ipairs(cfg.monster) do
            camp[#camp+1] = { kind = "mons", id = m, pos = cfg.stand[i] }
        end
        layer.addHurtsButton(video.camp, camp, video.hurts, video)
    end

    return layer
end

return ui
