-- 加载界面

local ui = {}

require "common.func"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local i18n = require "res.i18n"
local json = require "res.json"
local audio = require "res.audio"
local herosdata = require "data.heros"

-- 进战斗的loading
local memflag = false
function ui.create(video)
    local layer = require("fight.base.loading").create()
    memflag = false
    local fx = require "common.helper"
    if fx.isLowMem() then
        memflag = true
        require("fight.base.loading").unloadUIBeforFight()
    end

    local mapId, heroIds, pets, skins = ui.getMapAndHeroIds(video)
    local params = {
        mapId = mapId,
        heroIds = heroIds,
        pets = pets,
        skins = skins,
		extraSkills = require("fight.helper.fxfix").getExtraSkills(video),
    }
    layer.startLoadingWithParams(params, function()
        replaceScene(require("fight.frdpk.video").create(video))
    end)

    return layer
end

-- 直接开始下一场
function ui.backToNext(video, nexthandler)
    local mapId, heroIds, pets, skins = ui.getMapAndHeroIds(video)
    local params = {
        mapId = mapId,
        heroIds = heroIds,
        pets = pets,
        skins = skins,
		extraSkills = require("fight.helper.fxfix").getExtraSkills(video),
    }
    require("fight.base.loading").unloadFightWithParams(params)
    if memflag == true then
        local layer = require("fight.base.uiloading").create()
        replaceScene(layer)
        layer.startLoading(mapId, heroIds, function()
            nexthandler()
        end)
    else
        nexthandler()
    end
end

-- 返回UI
function ui.backToUI(video)
    local mapId, heroIds, pets, skins = ui.getMapAndHeroIds(video)
    local params = {
        mapId = mapId,
        heroIds = heroIds,
        pets = pets,
        skins = skins,
		extraSkills = require("fight.helper.fxfix").getExtraSkills(video),
    }
    require("fight.base.loading").unloadFightWithParams(params)
    if memflag == true then
        local layer = require("fight.base.uiloading").create()
        replaceScene(layer)
        layer.startLoading(mapId, heroIds, function()
			if video.from_layer and video.from_layer.from_layer == "guild" then
				replaceScene(require("ui.guild.main").create())
			else
				replaceScene(require("ui.town.main").create(video.from_layer))
			end
        end)
    else
		if video.from_layer and video.from_layer.from_layer == "guild" then
			replaceScene(require("ui.guild.main").create())
		else
			replaceScene(require("ui.town.main").create(video.from_layer))
		end
    end
end

-- 取得资源
function ui.getMapAndHeroIds(video)
    local mapId = MAP_ID_ARENA
    local heroIds, pets, skins = require("fight.helper.ccamp").getResources(video)
    return mapId, heroIds, pets, skins
end

return ui
