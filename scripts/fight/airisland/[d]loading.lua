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
local cfgfloatland = require "config.floatland"
local herosdata = require "data.heros"
local player = require "data.player"

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
        replaceScene(require("fight.airisland.video").create(video))
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
            --if require("data.player").uid == video.uid then
            --    replaceScene(require("ui.town.main").create({from_layer = "frdboss_self"}))
            --else
                --replaceScene(require("ui.town.main").create({from_layer = "airisland"}))
            local params = {
                sid = player.sid,
                pos = 0,
            }
            addWaitNet()
            netClient:island_land(params, function(__data)
                delWaitNet()
        
                tbl2string(__data)
                local airData = require "data.airisland"
                airData.setLandData(__data)
                replaceScene(require("ui.airisland.fightmain").create())
            end)
            --end
        end)
    else
        --if require("data.player").uid == video.uid then
        --    replaceScene(require("ui.town.main").create({from_layer = "frdboss_self"}))
        --else
        --    replaceScene(require("ui.town.main").create({from_layer = "frdboss_other"}))
        --end
        local params = {
            sid = player.sid,
            pos = 0,
        }
        addWaitNet()
        netClient:island_land(params, function(__data)
            delWaitNet()
    
            tbl2string(__data)
            local airData = require "data.airisland"
            airData.setLandData(__data)
            replaceScene(require("ui.airisland.fightmain").create())
        end)
        --replaceScene(require("ui.town.main").create({from_layer = "airisland"}))
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

-- 取得资源
function ui.getMapAndHeroIds(video)
    local mapId = cfgfloatland[video.stage].map
	local heroIds, pets, skins = require("fight.helper.ccamp").getResources(video)
    return mapId, heroIds, pets, skins
end

return ui
