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
local _x_f = 20
local _y_f = 15
local xy = {
    { attacker = {{x=645+_x_f, y=260+_y_f}},           defender = {{x=765+_x_f, y=260+_y_f}} },
    { attacker = {{x=630+_x_f, y=240+_y_f}, {x=660+_x_f, y=280+_y_f}},      
        defender = {{x=785+_x_f, y=240+_y_f},{x=755+_x_f, y=280+_y_f}} },
    y = 260,
}

function ui.create(params)
    local layer = CCLayer:create()
    fHelper.addBox(layer)

    -- 已加载过资源的英雄id
    local loadedIds = {}

    -- 所有单位
    local units = {}
    units.atk_units = {}
    units.def_units = {}

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
        units.atk_units = {}
        units.def_units = {}
        atkIds, defIds = ui.refreshIds(params)
        if atkIds and defIds then
            local newIds = ui.mergeIds(atkIds, defIds)
            local diffIds = ui.diffIds(loadedIds, newIds)
            loadedIds = newIds
            hasBegan = true
            schedule(layer, function()
                layer.loadAllResources(diffIds, function()
                    if needRefresh then
                        layer.refreshNow()
                    else
                        layer:setVisible(true)
                        layer.addUnits(atkIds, defIds)
                    end
                end)
            end)
        end
    end
    layer.refreshNow()

    -- 添加怪物
    function layer.addUnits(atkIds, defIds)
        for i, id in ipairs(atkIds) do
            layer.addUnit(id, "attacker", i)
        end
        for i, id in ipairs(defIds) do
            layer.addUnit(id, "defender", i)
        end
        local t = 0.8
        for _, u in ipairs(units) do
            u.card:runAction(CCFadeIn:create(t))
        end
        schedule(layer, t, layer.nextAction)
    end

    -- 添加怪物
    function layer.addUnit(id, side, i)
        local box = CCSprite:create()
        local _pos
        if side == "attacker" then
            _pos = xy[#atkIds][side][i]
        else
            _pos = xy[#defIds][side][i]
        end
        box:setPosition(_pos.x, _pos.y)
        layer.box:addChild(box, 4-i)
        local card = json.createSpineHero(id)
        card:setScale(op3(side == "attacker", 0.3, 0.3))
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
        print("add unit --------------------", side)
        if side == "attacker" then
            units.atk_units[#units.atk_units+1] = units[#units]
        else
            print("add def_units-------------------------")
            units.def_units[#units.def_units+1] = units[#units]
        end
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
                --actee.hp = actee.hp -1
            end
            if actee.hp == 0 then
                --actee.card:runAction(createSequence({
                --    CCCallFunc:create(function()
                --        actee.card:playAnimation("dead")
                --    end),
                --    CCDelayTime:create(actee.card:getAnimationTime("dead")),
                --    CCFadeOut:create(0.3),
                --    CCRemoveSelf:create(),
                --}))
                --schedule(layer, 3, layer.nextDefender)
                schedule(layer, tNext, layer.nextAction)
            else
                schedule(layer, tNext, layer.nextAction)
            end
        end)
    end

    -- 生成下一个防守方
    function layer.nextDefender()
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

    local function onExit()
        layer.unloadAllResources()
    end
    layer:registerScriptHandler(function(event)
        if event == "enter" then
        elseif event == "exit" then
            onExit()
        end
    end)

    layer:setTouchEnabled(true)
    layer:setTouchSwallowEnabled(false)

    return layer
end

function ui.refreshIds(params)
    if not params or not params.atkIds or not params.defIds then
        return
    end
    local ids = params.atkIds

    if ids == nil or #ids == 0 then 
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
        -- 进攻阵容中选2个作为进攻方
        if #ids < 2 then
            atkIds = arraycp(ids)
        else
            local i = math.random(1, #ids)
            atkIds = {
                ids[i],
                op3(i+1 > #ids, ids[i+1-#ids], ids[i+1]),
            }
        end
        -- 排序，战士刺客靠前站
        ui.jobSort(atkIds)
    end

    local ids = params.defIds

    if ids == nil or #ids == 0 then 
        return 
    end

    local defValid = defIds ~= nil
    if defIds then
        for _, id in ipairs(defIds) do
            if not arraycontains(ids, id) then
                defValid = false
                break
            end
        end
        if defValid and #defIds < #ids then
            defValid = false
        end
    end
    if not defValid then
        -- 防守阵容中选2个作为进攻方
        if #ids < 2 then
            defIds = arraycp(ids)
        else
            local i = math.random(1, #ids)
            defIds = {
                ids[i],
                op3(i+1 > #ids, ids[i+1-#ids], ids[i+1]),
            }
        end
        -- 排序，战士刺客靠前站
        ui.jobSort(defIds)
    end


    return atkIds, defIds
end

-- 排序，战士刺客靠前站
function ui.jobSort(array)
    table.sort(array, function(id1, id2)
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
    local atk_units = units.atk_units
    local def_units = units.def_units
    if actor.side == "attacker" then
        actee = def_units[math.random(1, #def_units)]
    else
        actee = atk_units[math.random(1, #atk_units)]
    end
    return actor, actee
end

return ui
