local ui = {}

require "common.const"
require "common.func"
local view = require "common.view"
local img = require "res.img"
local json = require "res.json"
local audio = require "res.audio"
local cfghero = require "config.hero"
local cfgbuff = require "config.buff"
local cfgskill = require "config.skill"
local cfgstage = require "config.stage"
local cfgmons = require "config.monster"
local fHelper = require "fight.helper.fx"
local hHelper = require "fight.helper.hero"
local hookdata = require "data.hook"

-- 记录进攻英雄id，防守怪物的英雄id，防守怪物在cfgstage.monsterShow中的索引
local atkIds, defId, defIdx

local xy = {
    { attacker = {328},           defender = {606} },
    { attacker = {390, 260},      defender = {687} },
    { attacker = {457, 323, 190}, defender = {713} },
    y = 280,
}

function ui.create()
    local layer = CCLayer:create()
    fHelper.addBox(layer)

    -- 已加载过资源的英雄id
    local loadedIds = {}

    -- 所有单位
    local units

    -- 刷新, refresh只是置标志位, refreshNow才是真正的刷新
    local needRefresh = false
    local hasBegan = false
    function layer.refresh()
        layer:setVisible(false)
        if hasBegan then
            needRefresh = true
        else
            layer.refreshNow()
        end
    end
    function layer.refreshNow()
        needRefresh = false
        if units then
            for _, u in ipairs(units) do
                u.card:removeFromParent()
                u.card = nil
            end
        end
        units = {}
        atkIds, defId, defIdx = ui.refreshIds(atkIds, defId, defIdx)
        if atkIds and defId and defIdx then
            local newIds = ui.mergeIds(atkIds, {defId})
            local diffIds = ui.diffIds(loadedIds, newIds)
            loadedIds = newIds
            hasBegan = true
            schedule(layer, function()
                layer.loadAllResources(diffIds, function()
                    if needRefresh then
                        layer.refreshNow()
                    else
                        layer:setVisible(true)
                        layer.addUnits(atkIds, defId)
                    end
                end)
            end)
        end
    end
    layer.refreshNow()

    -- 添加怪物
    function layer.addUnits(atkIds, defId)
        for i, id in ipairs(atkIds) do
            layer.addUnit(id, "attacker", i)
        end
        layer.addUnit(defId, "defender", 1)
        local t = 0.8
        for _, u in ipairs(units) do
            u.card:runAction(CCFadeIn:create(t))
        end
        schedule(layer, t, layer.nextAction)
    end

    -- 添加怪物
    function layer.addUnit(id, side, i)
        local box = CCSprite:create()
        box:setPosition(xy[#atkIds][side][i], xy.y)
        layer.box:addChild(box, 4-i)
        local card = json.createSpineHero(id)
        card:setScale(op3(side == "attacker", 0.4, 0.5))
        card:setFlipX(side ~= "attacker")
        box:addChild(card)
        units[#units+1] = {
            heroId = id,
            box = box,
            card = card,
            size = "small",
            pos = op3(side == "attacker", i, i+6),
            side = side,
            hp = op3(side == "attacker", 100, math.random(5, 10)),
            atkId = cfghero[id].atkId,
        }
    end

    -- 下一动作
    function layer.nextAction()
        if needRefresh then
            layer.refreshNow()
            return
        end
        local actor, actee = ui.nextActorAndActee(units)
        local action = cfghero[actor.heroId].atkId
        local tActor, tNext = fHelper.playActor(layer, actor, action, {actee})
        schedule(layer, tActor, function()
            fHelper.playActee(layer, actor, actee, action, buffname2id(BUFF_HURT))
            if actee.side == "defender" then
                actee.hp = actee.hp -1
            end
            if actee.hp == 0 then
                actee.card:runAction(createSequence({
                    CCCallFunc:create(function()
                        actee.card:playAnimation("dead")
                    end),
                    CCDelayTime:create(actee.card:getAnimationTime("dead")),
                    CCFadeOut:create(0.3),
                    CCRemoveSelf:create(),
                }))
                schedule(layer, 3, layer.nextDefender)
            else
                schedule(layer, tNext, layer.nextAction)
            end
        end)
    end

    -- 生成下一个防守方
    function layer.nextDefender()
        table.remove(units, #units)
        local stage = hookdata.getHookStage()
        local mons = cfgstage[stage].monsterShow
        defIdx = op3(defIdx+1 > #mons, 1, defIdx+1)
        defId = mons[defIdx]
        local newIds = ui.mergeIds(atkIds, {defId})
        local diffIds = ui.diffIds(loadedIds, newIds)
        loadedIds = newIds
        schedule(layer, function()
            layer.loadAllResources(diffIds, function()
                layer.addUnit(defId, "defender", 1)
                for _, u in ipairs(units) do
                    u.hasActed = false 
                end
                local t = 0.8
                local def = units[#units]
                def.card:runAction(CCFadeIn:create(t))
                schedule(layer, t, layer.nextAction)
            end)
        end)
    end

    -- 加载资源
    local imgList, jsonList = {}, {}
    function layer.loadAllResources(heroIds, onFinish)
        if #heroIds == 0 then 
            onFinish() 
            return
        end
        imgList = arraymerge(imgList, img.getLoadListForFight(nil, heroIds, true))
        jsonList = arraymerge(jsonList, json.getLoadListForFight(heroIds, true))
        local sum, num = #imgList, 0
        img.loadAsync(imgList, function()
            num = num + 1
            if num == sum and not tolua.isnull(layer) then
                json.loadAll(jsonList)
                schedule(layer, onFinish)
            end
        end)
    end

    -- 卸载资源
    function layer.unloadAllResources()
        json.unloadAll(jsonList)
        img.unloadList(imgList)
    end

    return layer
end

function ui.refreshIds(atkIds, defId, defIdx)
    local ids = hookdata.getIDS()
    local stage = hookdata.getHookStage()
    local cfg = cfgstage[stage]

    if stage == 0 or ids == nil or #ids == 0 then 
        return 
    end

    local atkValid = atkIds ~= nil
    if atkIds then
        for _, id in ipairs(atkIds) do
            if not arraycontains(ids, id) then
                atkValid = false
                break
            end
        end
        if atkValid and #atkIds < #ids then
            atkValid = false
        end
    end
    if not atkValid then
        -- 挂机阵容中选3个作为进攻方
        if #ids < 3 then
            atkIds = arraycp(ids)
        else
            local i = math.random(1, #ids)
            atkIds = {
                ids[i],
                op3(i+1 > #ids, ids[i+1-#ids], ids[i+1]),
                op3(i+2 > #ids, ids[i+2-#ids], ids[i+2]),
            }
        end
        -- 排序，战士刺客靠前站
        table.sort(atkIds, function(id1, id2)
            local job1, job2 = cfghero[id1].job, cfghero[id2].job
            if job1 == 1 and job2 ~= 1 then
                return true
            elseif job1 ~= 1 and job2 == 1 then
                return false
            end
            if job1 == 4 and job2 ~= 4 then
                return true
            elseif job1 ~= 4 and job2 == 4 then
                return false
            end
            return job1 < job2
        end)
    end

    local defValid = false
    if defId and defIdx then
        local m = cfg.monsterShow[defIdx]
        if m and m == defId then
            defValid = true
        end
    end
    if not defValid then
        -- stage的怪物中选1个作为防守方
        defIdx = math.random(1, #cfg.monsterShow)
        defId = cfg.monsterShow[defIdx]
    end

    return atkIds, defId, defIdx
end

function ui.mergeIds(ids1, ids2)
    local ids = arraycp(ids1)
    for _, id in ipairs(ids2) do
        if not arraycontains(ids, id) then
            ids[#ids+1] = id
        end
    end
    return ids
end

function ui.diffIds(oldIds, newIds)
    local ids = {}
    for _, id in ipairs(newIds) do
        if not arraycontains(oldIds, id) then
            ids[#ids+1] = id
        end
    end
    return ids
end

function ui.nextActorAndActee(units)
    local actor, actee
    for _, u in ipairs(units) do
        if not u.hasActed then
            actor = u
            break
        end
    end
    if not actor then 
        for _, u in ipairs(units) do
            u.hasActed = false
        end
        actor = units[1]
    end
    actor.hasActed = true
    if actor.side == "attacker" then
        actee = units[#units]
    else
        actee = units[math.random(1, #units-1)]
    end
    return actor, actee
end

return ui
