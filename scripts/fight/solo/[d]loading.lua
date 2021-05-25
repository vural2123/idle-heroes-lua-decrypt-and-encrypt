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
        replaceScene(require("fight.solo.video").create(video))
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
            require("ui.solo.main").refreshFightData(video.data)
            replaceScene(require("ui.solo.main").create(video.from_layer))
        end)
    else
        require("ui.solo.main").refreshFightData(video.data)
        replaceScene(require("ui.solo.main").create(video.from_layer))
    end
end

-- 取得资源
function ui.getMapAndHeroIds(video)
    local mapId, heroIds, pets = MAP_ID_ARENA, {}, {}
    local skins = {}
    for _, h in pairs(video.atk.camp) do
        --heroIds[#heroIds+1] = herosdata.find(h.hid).id
        if h.skin then
            skins[#skins+1] = h.skin
        end
        heroIds[#heroIds+1] = h.id
    end
    if video.atk and video.atk.pet then
        pets[#pets+1] = video.atk.pet
    end
    for _, h in pairs(video.def.camp) do
        if h.skin then
            skins[#skins+1] = h.skin
        end
        heroIds[#heroIds+1] = h.id
    end
    return mapId, heroIds, pets, skins
end

return ui
