-- 加载界面

local ui = {}

require "common.func"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local i18n = require "res.i18n"
local json = require "res.json"
local audio = require "res.audio"
local cfgmons = require "config.monster"
local cfgdarestage = require "config.darestage"
local herosdata = require "data.heros"

local memflag = false
-- 进战斗的loading
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
        replaceScene(require("fight.dare.video").create(video))
    end)

    return layer
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
            replaceScene(require("ui.town.main").create({from_layer="dareStage", type=video.type}))
        end)
    else
        replaceScene(require("ui.town.main").create({from_layer="dareStage", type=video.type}))
    end
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

-- 返回到铁匠铺
function ui.backToSmith(video)
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
            replaceScene(require("ui.smith.main").create())
        end)
    else
        replaceScene(require("ui.smith.main").create())
    end
end

-- 返回到英雄面板
function ui.backToHero(video)
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
            replaceScene(require("ui.herolist.main").create())
        end)
    else
        replaceScene(require("ui.herolist.main").create())
    end
end

-- 返回到召唤
function ui.backToSummon(video)
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
            replaceScene(require("ui.summon.main").create())
        end)
    else
        replaceScene(require("ui.summon.main").create())
    end
end

-- 取得资源
function ui.getMapAndHeroIds(video)
    local mapId = cfgdarestage[video.stage].map
    local heroIds, pets, skins = require("fight.helper.ccamp").getResources(video)
    return mapId, heroIds, pets, skins
end

return ui
