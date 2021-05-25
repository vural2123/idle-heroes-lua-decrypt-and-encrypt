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
local cfgbrokenboss= require "config.brokenboss"
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
        replaceScene(require("fight.broken.video").create(video))
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
            replaceScene(require("ui.town.main").create({from_layer = "brokenboss"}))
        end)
    else
        replaceScene(require("ui.town.main").create({from_layer = "brokenboss"}))
    end
end

-- 取得资源
function ui.getMapAndHeroIds(video)
    local mapId = cfgbrokenboss[video.stage].map
    local heroIds, pets, skins = require("fight.helper.ccamp").getResources(video)
    return mapId, heroIds, pets, skins
end

return ui
