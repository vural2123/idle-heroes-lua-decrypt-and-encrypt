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

-- 把3v3video数组暂时存起来
local tmp_videos

local memflag = false
-- 进战斗的loading
-- idx 第idx场战斗
function ui.create(videos, idx)
    if not videos then
        videos = tmp_videos
    else
        tmp_videos = videos
    end
    local idx = idx or 1
    if videos[idx].wins and videos[idx].wins[idx] then
        videos[idx].win = videos[idx].wins[idx]
    end
    local layer = require("fight.base.loading").create()

    -- 普通结算界面不显示积分
    videos[idx].noscore = true

    if idx == 1 then
        memflag = false
        local fx = require "common.helper"
        if fx.isLowMem() then
            memflag = true
            require("fight.base.loading").unloadUIBeforFight()
        end
    end
    
    local mapId, heroIds, pets, skins = ui.getMapAndHeroIds(videos, idx)
    local params = {
        mapId = mapId,
        heroIds = heroIds,
        pets = pets,
        skins = skins,
		extraSkills = require("fight.helper.fxfix").getExtraSkills(nil, videos, idx),
    }
    layer.startLoadingWithParams(params, function()
        replaceScene(require("fight.pvpf3.video").create(videos, idx))
    end)

    return layer
end

-- 返回UI
function ui.backToUI(video, layer)
    local videos = tmp_videos
    if video and video.skip then
        videos = video.videos
    end
    local idx = video.idx
    local mapId, heroIds, pets, skins = ui.getMapAndHeroIds(videos, idx)
    local params = {
        mapId = mapId,
        heroIds = heroIds,
        pets = pets,
        skins = skins,
		extraSkills = require("fight.helper.fxfix").getExtraSkills(nil, videos, idx),
    }
    require("fight.base.loading").unloadFightWithParams(params)
    if #videos > idx then
        replaceScene(require("fight.pvpf3.loading").create(videos, idx+1))
    else
        if layer and not tolua.isnull(layer) then
            layer:addChild((require"fight.pvpf3.final").create(video), 1000)
        else  -- 不应该出现这种现象
            if memflag == true then
                local uilayer = require("fight.base.uiloading").create()
                replaceScene(uilayer)

                uilayer.startLoading(mapId, heroIds, function()
                    replaceScene(require("ui.frdarena.main").create(video.from_layer))
                end)
            else
                replaceScene(require("ui.frdarena.main").create(video.from_layer))
            end
        end
    end
end

-- 取得资源
function ui.getMapAndHeroIds(videos, idx)
    local mapId = MAP_ID_ARENA
    local heroIds, pets, skins = require("fight.helper.ccamp").getResources(videos[idx])
    return mapId, heroIds, pets, skins
end

return ui
