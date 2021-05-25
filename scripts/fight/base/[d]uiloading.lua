-- 加载ui界面资源

local ui = {}

require "common.func"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local i18n = require "res.i18n"
local json = require "res.json"
local audio = require "res.audio"

-- 退出战斗的loading
function ui.create()
    local bgIndex = math.random(3)
    if bgIndex == 2 then
        img.load(img.packedOthers.fightLoading[bgIndex])
    end

    local layer = require("fight.loadingbg.bg" .. bgIndex).create()

    local tipsIndex = math.random(#i18n.loadingtips)
    layer.setHint(i18n.loadingtips[tipsIndex].tips)

    -- 开始加载
    function layer.startLoading(mapId, heroIds, onFinish)
        --audio.stopBackgroundMusic()
        schedule(layer, function()
            --local imgList = img.getLoadListForFight(mapId, heroIds)
            --local jsonList = json.getLoadListForFight(heroIds)
            local imgList, jsonList = img.getLoadListForUI(), json.getLoadListForUI()
            layer.loadFight(imgList, jsonList, onFinish)
        end)
    end

    -- 加载UI资源
    local beginTime = os.time()
    function layer.loadFight(imgList, jsonList, onFinish)
        local sum, num = #imgList, 0
        img.loadAsync(imgList, function()
            num = num + 1
            if layer.setPercentageForProgress then
                layer.setPercentageForProgress(num/sum*100)
            end
            -- 图片加载完了，开始加载json
            if num == sum and not tolua.isnull(layer) then
                -- 至少在loading界面停留1s
                local delay = 0.01
                local endTime = os.time()
                if endTime - beginTime < 1 then
                    delay = 1 - (endTime - beginTime)
                end
                schedule(layer, delay, function()
                    json.loadAll(jsonList)
                    onFinish()
                end)
            end
            --CCTextureCache:sharedTextureCache():dumpCachedTextureInfo()
        end)
    end

    return layer
end

-- 卸载战斗资源
function ui.unloadFight(mapId, heroIds, extraSkills)
    local imgList = img.getLoadListForFight(mapId, heroIds, nil, extraSkills)
    local jsonList = json.getLoadListForFight(heroIds, nil, extraSkills)
    json.unloadAll(jsonList)
    img.unloadList(imgList)
    img.unloadAll(img.packedOthers.fightLoading)
    audio.playBackgroundMusic(audio.ui_bg)
    CCDirector:sharedDirector():getScheduler():setTimeScale(1)
end

function ui.unloadUIBeforFight()
    local imgList, jsonList = img.getLoadListForUI(), json.getLoadListForUI()
    json.unloadAll(jsonList)
    img.unloadList(imgList)
end

return ui
