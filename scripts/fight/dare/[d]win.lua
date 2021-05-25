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
local cfgdarestage = require "config.darestage"
local daredata = require "data.dare"
local net = require "net.netClient"
local bag = require "data.bag"
local petBattle = require "ui.pet.petBattle"

function ui.create(video)
    local layer = require("fight.base.win").create()

	local mapequips, mapitems = {}, {}
	for i=1, #video.stages do
		local cfg = cfgdarestage[video.stages[i]]
		for _, r in ipairs(cfg.reward) do
			if r.type == 1 then
				mapitems[r.id] = (mapitems[r.id] or 0) + r.num
			else
				mapequips[r.id] = (mapequips[r.id] or 0) + r.num
			end
		end
	end
	
	local items = {}
	local equips = {}
	for _, v in pairs(mapitems) do
		items[#items + 1] = { id = _, num = v }
	end
	for _, v in pairs(mapequips) do
		equips[#equips + 1] = { id = _, num = v }
	end

	layer.addOkButton(function()
		--require("fight.dare.loading").backToUI(video)
		replaceScene(require("ui.town.main").create({from_layer="dareStage", type=video.type}))
	end)

    layer.addRewardIcons({equips = equips, items = items})

    return layer
end

return ui
