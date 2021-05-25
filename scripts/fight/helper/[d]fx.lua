-- 战斗中特效播放的一些帮助函数

local helper = {}

require "common.const"
require "common.func"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local audio = require "res.audio"
local i18n = require "res.i18n"
local cfgfx = require "config.fx"
local cfghero = require "config.hero"
local cfgpet = require "config.pet"
local cfgskill = require "config.skill"
local cfgbuff = require "config.buff"
local progressbar = require "ui.progressbar"
local bHelper = require "fight.helper.buff"
local hHelper = require "fight.helper.hero"
local userdata = require "data.userdata"
local fxfix = require "fight.helper.fxfix"
local particle = require "res.particle"

local UNIT_XY = {{306,162},{326,280},{176, 70},{110,162},{110,280},{176,350}}
local BOSS_XY = {{320,200},{320,200},{120, 90},{120,200},{120,200},{170,265}}
local UNIT_ZORDERS = {10,6,12,8,4,2}
local UNIT_SCALE = { small = 0.5, large = 0.7 }
local FX_SCALE = { small = 1, large = 0.7/0.5 }
local DURATION_BULLET = 0.2
local MAX_BUFF_ICON = 8
local BUFF_XY = {
    small = { { -27, 10 }, {  -9, 10 }, {   9, 10 }, { 27, 10 }, { -27, 28 }, {  -9, 28 }, {   9, 28 }, { 27, 28 }, },
    large = { { -51, 10 }, { -33, 10 }, { -15, 10 }, {  3, 10 }, { -51, 28 }, { -33, 28 }, { -15, 28 }, {  3, 28 }, }
}

local spd_factor = 1.2   -- 调整战斗速度的比例

-- 技能转变后的攻击技能
local chSkls = {}
local function getChSkls()
    for _k, _v in pairs(cfgskill) do
        if cfgskill[_k].effect and cfgskill[_k].effect[1].type == "changeCombat" then
            chSkls[cfgskill[_k].effect[1].num] = true
        end
    end
end
getChSkls()

-- 是否是该英雄的觉醒技能
local function isDisi(heroId, sklId)
    local disillusSkill = cfghero[heroId].disillusSkill
    if not disillusSkill then return false end
    for ii=1,#disillusSkill do
        if disillusSkill[ii].disi then
            for jj=1,#disillusSkill[ii].disi do
                if disillusSkill[ii].disi[jj] == sklId then
                    return true
                end
            end
        end
    end
    return false
end

-- 是否是该英雄的被动技能
local function isPasSkill(heroId, sklId)
    local pasSkills = { "pasSkill1Id", "pasSkill2Id", "pasSkill3Id" }
    for ii=1,#pasSkills do
        if cfghero[heroId][pasSkills[ii]] == sklId then
            return true
        end
    end
    return false
end

-- 战斗中各种东西的容器
function helper.addBox(layer)
    local fx = json.create(json.fight.shake)
    fx:setScale(view.minScale)
    fx:setPosition(view.midX, view.midY)
    layer:addChild(fx)
    layer.shakeFx = fx
    local box = CCSprite:create()
    box:setContentSize(CCSize(view.logical.w, view.logical.h))
    fx:addChildFollowSlot("code_bg", box)
    layer.box = box
end

-- 添加战斗地图
function helper.addMap(layer, mapId)
    local bg, fg = img.createFightMap(mapId)
    bg:setPosition(480, 576)
    bg:setScale(view.maxScale / view.minScale)
    bg:setAnchorPoint(ccp(0.5, 1))
    layer.box:addChild(bg, -10)

    autoLayoutShift(bg, true, false, false, false)

    fg:setAnchorPoint(ccp(0.5, 0))
    fg:setPosition(480, 0)
    fg:setScale(view.maxScale / view.minScale)
    layer.box:addChild(fg, 100)

    autoLayoutShift(fg, false, true, false, false)

    layer.mapBg = bg
    layer.mapFg = fg
    local banner = img.createUISprite(img.ui.fight_top_banner)
    banner:setScaleX(view.physical.w / banner:getContentSize().width / view.minScale)
    banner:setAnchorPoint(ccp(0.5, 1))
    banner:setPosition(480, 576)
    layer.box:addChild(banner)

    autoLayoutShift(banner, true, false)
end

-- 添加pet单位
-- side :attacker or defender:
function helper.addPet(layer, pet, side)
    local petid = pet.id
    json.load(json.ui.pet_fx)
    local animAll = json.create(json.ui.pet_fx)
    animAll:setPosition(ccp(480, 288))
    animAll:setVisible(false)
    animAll:setFlipX(side ~= "attacker")
    layer.box:addChild(animAll, 1000)
    animAll:setCascadeOpacityEnabled(true)
    local petName = cfgpet[petid].petBody
    petName = string.sub(petName, 5, -2)
    json.load(json.ui["spine_" .. petName .. "_" .. (pet.star+1)])
    local animPet = json.create(json.ui["spine_" .. petName .. "_" .. (pet.star+1)])
    animAll:addChildFollowSlot("code_pet", animPet)
    animAll.pet = pet
    animAll.animPet = animPet
    if not layer.pets then
        layer.pets = {}
    end
    layer.pets[side] = animAll
end

-- 添加pet能量条
function helper.addPetEp(layer)
    local pgb_bg = img.createUISprite(img.ui.fight_pet_ep_bg)
    pgb_bg:setPosition(ccp(480, 20))
    pgb_bg:setCascadeOpacityEnabled(true)
    --pgb_bg:setVisible(false)
    layer.box:addChild(pgb_bg, 1000)
    local pgb_fg = img.createUISprite(img.ui.fight_pet_ep_fg)
    local pgb = progressbar.create(pgb_fg)
    pgb:setPosition(pgb_bg:getContentSize().width/2, pgb_bg:getContentSize().height/2-1)
    pgb.setPercentageOnly(0)
    pgb_bg:addChild(pgb)
    local pgb_w = pgb_fg:getContentSize().width

    local epfx = json.create(json.ui.exp_battle)
    epfx:setPosition(ccp(0, pgb:getContentSize().height/2))
    pgb:addChild(epfx)
    local epfx2 = json.create(json.ui.exp_battle2)
    epfx2:setPosition(ccp(pgb_w/2, pgb:getContentSize().height/2))
    pgb:addChild(epfx2)
    layer.pet_ep_bg = pgb_bg
    layer.pet_ep = pgb
    layer.pet_epfx = epfx
    layer.pet_epfx2 = epfx2
    pgb.setPercentageHandler(function(percentage)
        if percentage>= 100 then
            epfx:setPositionX(pgb_w/2)
            epfx:playAnimation("animation2", -1)
        else
            epfx:setPositionX(percentage*pgb_w/100)
            epfx:playAnimation("animation", -1)
        end
    end)
    function pgb.updateEp(percentage)
        if percentage <= 0 then
            epfx:setVisible(false)
        else
            epfx:setVisible(true)
        end
        pgb.scalePercentageOnly(percentage)
    end
    pgb.updateEp(0)

    autoLayoutShift(pgb_bg)
end

-- 更新pet能量条
function helper.updatePetEp(layer, percentage)
    if not layer.pet_ep or tolua.isnull(layer.pet_ep) then return end
    if percentage <= 0 then
        layer.pet_epfx2:playAnimation("animation2", 1)
    end
    layer.pet_ep.updateEp(percentage)
end

-- 更新pet能量条
function helper.addPetEpDelta(layer, percentage)
    if not layer.pet_ep or tolua.isnull(layer.pet_ep) then return end
    local old = layer.pet_ep:getPercentage()
    local new = old + percentage
    if new >= 100 then
        new = 100
    end
    layer.pet_ep.updateEp(new)
end

-- 添加战斗单位
function helper.addUnit(layer, unit)
    -- 将角色动画、血条等都塞到这个box里
    local box = CCSprite:create()
    box:setPosition(helper.getUnitPosition(unit))
    box:setCascadeOpacityEnabled(true)
    box:setVisible(false)
    unit.zOrder = helper.getUnitZOrder(unit)
    layer.box:addChild(box, unit.zOrder)
    unit.box = box

    -- 角色动画
    local cardBox = CCSprite:create()
    box:addChild(cardBox)
    local card
    if unit.skin then
        --local sHeroId = require("config.equip")[unit.skin].heroBody
        card = json.createSpineHeroSkin(unit.skin)
    else
        card = json.createSpineHero(unit.heroId)
    end
    card:setVisible(false)
    card:setFlipX(unit.side ~= "attacker")
    card:setScale(helper.getUnitScale(unit))
    cardBox:addChild(card)
    unit.card = card

    -- hp bg
    local hpBg = img.createUISprite(img.ui.fight_hp_bg[unit.size])
    local hpBgSize = hpBg:getContentSize()
    local rect = card:getAabbBoundingBox()
    local midX, maxY = rect:getMidX(), rect:getMaxY()
    hpBg:setPosition(box:convertToNodeSpace(ccp(midX, maxY)))
    hpBg:setCascadeOpacityEnabled(true)
    box:addChild(hpBg)
    unit.hpBg = hpBg

    -- hp fx
    local hpFx0 = img.createUISprite(img.ui.fight_hp_fx[unit.size])
    local hpFx = progressbar.create(hpFx0)
    hpFx:setPosition(hpBgSize.width/2, hpBgSize.height/2)
    hpFx.setPercentageOnly(unit.hp)
    hpBg:addChild(hpFx)
    unit.hpFx = hpFx

    -- hp fg
    local hpFg0 = img.createUISprite(img.ui.fight_hp_fg[unit.size])
    local hpFg = progressbar.create(hpFg0)
    hpFg:setPosition(hpBgSize.width/2, hpBgSize.height/2)
    hpFg.setPercentageOnly(unit.hp)
    hpBg:addChild(hpFg)
    unit.hpFg = hpFg

    -- ep bg
    local epBg = img.createUISprite(img.ui.fight_ep_bg[unit.size])
    local epBgSize = epBg:getContentSize()
    epBg:setPosition(hpBg:getPositionX(), hpBg:getPositionY()-6)
    epBg:setCascadeOpacityEnabled(true)
    box:addChild(epBg)
    unit.epBg = epBg

    -- ep fg
    local epFg0 = img.createUISprite(img.ui.fight_ep_fg[unit.size])
    local epFg = progressbar.create(epFg0)
    epFg:setPosition(epBgSize.width/2, epBgSize.height/2)
    epFg.setPercentageOnly(unit.ep)
    epFg:setVisible(unit.ep < 100)
    epBg:addChild(epFg)
    unit.epFg = epFg

    -- ep full
    local epFull0 = img.createUISprite(img.ui.fight_ep_full[unit.size])
    local epFull = json.create(json.ui.bt_tiao)
    epFull:setPosition(epBgSize.width/2, epBgSize.height/2)
    epFull:setVisible(unit.ep >= 100)
    epFull:addChildFollowSlot(op3(unit.size == "small", "code_normal", "code_boss"), epFull0)
    epFull:playAnimation(op3(unit.size == "small", "normal", "boss"), -1)
    epBg:addChild(epFull)
    unit.epFull = epFull

    -- group
    local group = img.createUISprite(img.ui["fight_group_" .. unit.group])
    group:setPosition(hpBg:boundingBox():getMinX()-9, hpBg:getPositionY())
    box:addChild(group)

    -- lv
    local lv = lbl.createFont2(16, unit.lv)
    lv:setAnchorPoint(ccp(1, 0.5))
    lv:setPosition(hpBg:boundingBox():getMinX()-20, hpBg:getPositionY())
    box:addChild(lv)
end

-- 删除战斗单位
function helper.delUnit(unit)
    unit.box:removeFromParent()
    unit.fadeout = nil
end

-- 战斗单位的位置
function helper.getUnitPosition(unit)
    local xy = op3(unit.size == "small", UNIT_XY, BOSS_XY)
    if unit.side == "attacker" then
        return ccp(xy[unit.pos][1], xy[unit.pos][2])
    end
    return ccp(960-xy[unit.pos-6][1], xy[unit.pos-6][2])
end

-- 战斗单位的层级
function helper.getUnitZOrder(unit)
    if unit.side == "attacker" then
        return UNIT_ZORDERS[unit.pos]
    end
    return UNIT_ZORDERS[unit.pos-6]
end

-- 战斗单位的缩放
function helper.getUnitScale(unit)
    return UNIT_SCALE[unit.size]
end

-- 播放特效
-- actor只有在是子弹和激光特效时需要
function helper.play(layer, fxId, unit, actor)
    local cfg = cfgfx[fxId]
    local loop = cfg.loop or 1
    local fx, duration
    -- 创建
    if cfg.kind == 1 then -- spine
        fx = json.create(json.keyForFight(cfg.name))
        fx:playAnimation("animation", loop)
        duration = fx:getAnimationTime("animation") * loop
    elseif cfg.kind == 2 then -- 序列帧
        fx = CCSprite:create()
        local sequence = img.createFxSequence(fxId)
        duration = cfg.duration * loop
        sequence:setLoops(loop)
        fx:runAction(CCAnimate:create(sequence))
    elseif cfg.kind == 3 then -- 粒子
        fx = particle.create(cfg.name)
        duration = cfg.duration
        fx:setDuration(duration)
    end
    -- 子弹类存留时间
    if cfg.bullet then
        duration = cfg.duration or DURATION_BULLET
    end
    -- 自动删除
    if not cfg.retain then
        schedule(fx, duration, function()
            fx:removeFromParent()
        end)
    end
    -- 水平和垂直翻转
    if unit.side == "attacker" and not cfg.bind then
        fx:setFlipX(true)
    end
    if fxId == 5521 or fxId == 5731 then
        fx:setFlipX(false)
    end
    -- 设置位置和缩放
    if cfg.aoe then -- AOE
        fx:setPosition(ccp(480, 288))
        layer.box:addChild(fx, cfg.zOrder)
    elseif cfg.bullet then
        local rect1 = actor.card:getAabbBoundingBox()
        local x1 = op3(actor.side == "attacker", rect1:getMaxX(), rect1:getMinX())
        local y1 = rect1:getMidY()
        local rect2 = unit.card:getAabbBoundingBox()
        local x2, y2 = rect2:getMidX(), rect2:getMidY()
        local p1 = layer.box:convertToNodeSpace(ccp(x1, y1))
        local p2 = layer.box:convertToNodeSpace(ccp(x2, y2))
        x1, y1, x2, y2 = p1.x, p1.y, p2.x, p2.y
        local rotate = degree(math.abs(x2-x1), math.abs(y2-y1)) * op3((x2-x1)*(y2-y1) > 0, -1, 1)
        fx:setPosition(ccp(x1, y1))
        fx:setScale(FX_SCALE[actor.size])
        fx:setRotation(rotate)
        fx:runAction(CCMoveTo:create(duration, ccp(x1+(x2-x1)*0.8, y1+(y2-y1)*0.8)))
        layer.box:addChild(fx, cfg.zOrder)
    elseif cfg.laser then
        local p = actor.card:getBonePositionRelativeToWorld("code_fx")
        local x1, y1 = p.x, p.y
        if fxId == 5521 or fxId == 5731 then
            local rect1 = actor.card:getAabbBoundingBox()
            x1, y1 = rect1:getMidX(), rect1:getMidY()
        end
        local rect2 = unit.card:getAabbBoundingBox()
        local x2, y2 = rect2:getMidX(), rect2:getMidY()
        local p1 = layer.box:convertToNodeSpace(ccp(x1, y1))
        local p2 = layer.box:convertToNodeSpace(ccp(x2, y2))
        x1, y1, x2, y2 = p1.x, p1.y, p2.x, p2.y
        local fxWidth = fx:getAabbBoundingBox().size.width
        local rotate = degree(math.abs(x2-x1), math.abs(y2-y1)) * op3((x2-x1)*(y2-y1) > 0, -1, 1)
        fx:setPosition(ccp(x1, y1))
        fx:setScaleX(ccpDistance(ccp(x1,y1), ccp(x2,y2)) / fxWidth)
        fx:setScaleY(FX_SCALE[actor.size])
        fx:setRotation(rotate)
        layer.box:addChild(fx, cfg.zOrder)
    else -- cfg.position指定位置
        local rect = unit.card:getAabbBoundingBox()
        local x, y
        if cfg.position == 1 then
            x, y = rect:getMidX(), rect:getMaxY()
        elseif cfg.position == 2 or cfg.position == nil then
            x, y = rect:getMidX(), rect:getMidY()
        elseif cfg.position == 3 then
            x, y = rect:getMidX(), rect:getMinY()
        elseif cfg.position == 4 then
            local p = unit.card:getBonePositionRelativeToWorld("code_fx")
            x, y = p.x, p.y
        end
        if cfg.bind == 1 then
            fx:setPosition(unit.card:convertToNodeSpace(ccp(x, y)))
            fx:setScale(FX_SCALE[unit.size] / UNIT_SCALE[unit.size])
            unit.card:addChild(fx, cfg.zOrder)
        else
            fx:setPosition(layer.box:convertToNodeSpace(ccp(x, y)))
            fx:setScale(FX_SCALE[unit.size])
            layer.box:addChild(fx, cfg.zOrder)
        end
    end

    return fx, duration
end

-- 特殊特效 5520
function helper.playFx5520(layer, fxIds, units, actor)
    local fxId = fxIds[1]
    helper.play(layer, fxId, units[1], actor)
    if #units > 1 then
        local t_time = 0.5
        for ii=2,#units do
            schedule(layer, t_time * (ii-1), function()
                helper.play(layer, fxIds[2], units[ii], units[ii-1])
                helper.play(layer, fxIds[3], units[ii], units[ii-1])
            end)
        end
    end
end

-- 多个单位上播多个特效
function helper.playAll(layer, fxIds, units, actor)
    if fxIds and fxIds[1] == 5520 then
        helper.playFx5520(layer, fxIds, units, actor)
        return
    elseif fxIds and fxIds[1] == 5730 then
        helper.playFx5520(layer, fxIds, units, actor)
        return
    end
    if fxIds and #fxIds > 0 and units and #units > 0 then
        for _, fxId in ipairs(fxIds) do
            if cfgfx[fxId].aoe then
                helper.play(layer, fxId, units[1])
            else
                for _, unit in ipairs(units) do
                    helper.play(layer, fxId, unit, actor)
                end
            end
        end
    end
end

-- 返回攻击者出手动作到被攻击者受伤动作的时间
function helper.getHurtTime(actor, cfg)
    local tHurt = 0
    local fxId
    if cfg.fxMain1 then
        fxId = cfg.fxMain1[1]
    elseif cfg.fxMain2 then
        fxId = cfg.fxMain2[1]
    elseif cfg.fxSelf then
        fxId = cfg.fxSelf[1]
    end
    if fxId then
        if cfgfx[fxId].bullet then
            tHurt = cfgfx[fxId].duration or DURATION_BULLET-0.03
        else
            local cache = DHSkeletonDataCache:getInstance()
            local key = json.keyForFight(cfgfx[fxId].name)
            tHurt = cache:getEventTime(key, "animation", "hit")
        end
    end

    return tHurt
end

-- 返回受击特效开始到受击事件点的时间 和 总时间
function helper.getFxHurtTime(cfg)
    if true then return 0,0 end   -- 节奏变慢，暂时还原
    -- 如果受击有事件
    local tHurt = 0
    local tDuration = 0
    local fxId = nil
    if cfg.fxHurt1 then
        fxId = cfg.fxHurt1[1]
        if not cfgfx[fxId] then return tHurt end
        local cache = DHSkeletonDataCache:getInstance()
        local key = json.keyForFight(cfgfx[fxId].name)
        tHurt = tHurt + cache:getEventTime(key, "animation", "hit")
        tDuration = cache:getAnimationTime(key, "animation")
    end
    return tHurt, tDuration
end

-- pet 出场特效
local petAnimName = {
    ["wolf1"] = "blue_low",
    ["wolf2"] = "blue_low",
    ["wolf3"] = "blue",
    ["wolf4"] = "blue",
    ["fox1"] = "purple_low",
    ["fox2"] = "purple_low",
    ["fox3"] = "purple",
    ["fox4"] = "purple",
    ["dragon1"] = "red2_low",
    ["dragon2"] = "red2_low",
    ["dragon3"] = "red",
    ["dragon4"] = "red",
    ["eagle1"] = "yellow_low",
    ["eagle2"] = "yellow_low",
    ["eagle3"] = "yellow",
    ["eagle4"] = "yellow",
    ["deer1"] = "green_low",
    ["deer2"] = "green_low",
    ["deer3"] = "green",
    ["deer4"] = "green",
    ["viper1"] = "purple_low",
    ["viper2"] = "purple_low",
    ["viper3"] = "purple",
    ["viper4"] = "purple",
    ["stone1"] = "red2_low",
    ["stone2"] = "red2_low",
    ["stone3"] = "red",
    ["stone4"] = "red",
    ["ice1"] = "blue_low",
    ["ice2"] = "blue_low",
    ["ice3"] = "blue",
    ["ice4"] = "blue",
}
function helper.playPetAppearance(layer, side)
    local tPet = 0
    if not layer.pets or not layer.pets[side] then return tPet end
    if not layer.pets[side].pet then return tPet end
    local petInfo = layer.pets[side].pet
    local petid = petInfo.id
    local petName = cfgpet[petid].petBody
    petName = string.sub(petName, 5, -2)
    local animName = petAnimName[petName .. (petInfo.star+1)]
    tPet = layer.pets[side]:getAnimationTime(animName)
    layer.pets[side]:setVisible(true)
    if layer.pets[side].animPet then
        layer.pets[side].animPet:playAnimation("animation")
    end
    layer.pets[side]:playAnimation(animName)
    return tPet
end

-- 处理皮肤特效
local function processSkinFx(cfg, actor)
    if not actor or not actor.skin then
        return
    end
    local cfgequip = require "config.equip"
    local cfgskin = cfgequip[actor.skin]
    if not cfgskin then return end
    for _, f in ipairs({"fxSelf","fxMain1","fxMain2","fxHurt1","fxHurt2"}) do
        if cfgskin[f] then
            cfg[f] = cfgskin[f]
        end
    end
end

-- 行动方特效
function helper.playActor(layer, actor, actionId, actees1, actees2)
    local actName = "attack"
    -- 是否要播放攻击动作
    local attack = false
    if not actor.pet then
        if fxfix.isAttackOfAnyKind(actor.id, actionId) or chSkls[actionId] or actionId == actor.addHurtId then
            attack = true
        end
    end
    if actor and cfghero[actor.id] and cfghero[actor.id].actId == actionId then
        actName = "skill"
    end
    -- 各种事件时间
    local tAttack, tFxSelf, tFxMain, tHurt, tFxHurt = 0, 0, 0, 0, 0
    if attack then
        tAttack = actor.card:getAnimationTime(actName)
        tFxSelf = actor.card:getEventTime(actName, "fx")
        tFxMain = actor.card:getEventTime(actName, "hit")
        tFxMain = op3(tFxMain < tFxSelf, tFxSelf, tFxMain)
    end

    local cfg = clone(cfgskill[actionId])
    fxfix.processSkinFx(cfg, actor, actionId)

    local tFxHurtDuration = 0
    tHurt = tFxMain + helper.getHurtTime(actor, cfg)
    tFxHurt, tFxHurtDuration = helper.getFxHurtTime(cfg)

    -- 跳过去
    local tJump, tBack = 0, 0
    if attack and cfg.jump then
        tJump, tBack = 0.1, 0.05
        local z1 = actor.box:getZOrder()
        local z2 = (UNIT_ZORDERS[1]+UNIT_ZORDERS[2])/2
        local p1 = ccp(actor.box:getPositionX(), actor.box:getPositionY())
        local p2 = ccp(480, (UNIT_XY[1][2]+UNIT_XY[2][2])/2)
        if cfg.jump == 1 then
            local actee
            if actees1 and #actees1 > 0 then
                actee = actees1[1]
            elseif actees2 and #actees2 > 0 then
                actee = actees2[1]
            end
            if actee then
                z2 = actee.box:getZOrder()+1
                if actor.side == "attacker" then
                    p2 = ccp(actee.box:getPositionX()-120, actee.box:getPositionY())
                else
                    p2 = ccp(actee.box:getPositionX()+120, actee.box:getPositionY())
                end
            end
        end
        actor.box:runAction(createSequence({
            CCMoveTo:create(tJump, p2),
            CCCallFunc:create(function()
                layer.box:reorderChild(actor.box, z2)
            end),
            CCDelayTime:create(tAttack),
            CCCallFunc:create(function()
                layer.box:reorderChild(actor.box, z1)
            end),
            CCMoveTo:create(tBack, p1)
        }))
        tFxSelf = tFxSelf + tJump
        tFxMain = tFxMain + tJump
        tHurt = tHurt + tJump
    end

    -- 出手动作
    if attack then
        schedule(layer, tJump, function()
            actor.card:playAnimation(actName)
            actor.card:clearNextAnimation()
            actor.card:appendNextAnimation("stand", -1)
        end)
    end

    -- 播放特效
    schedule(layer, tFxSelf, function()
        helper.playAll(layer, cfg.fxSelf, {actor})
    end)
    schedule(layer, tFxMain, function()
        helper.playAll(layer, cfg.fxMain1, actees1, actor)
        helper.playAll(layer, cfg.fxMain2, actees2, actor)
    end)

    -- 抖屏
    if cfg.shakeScreen then
        schedule(layer, tHurt, function()
            layer.shakeFx:playAnimation(cfg.shakeScreen)
        end)
    end

    -- 已死亡的要淡出, 如果是pet, 忽略
    if not actor.pet and actor.hp == 0 then
        actor.card:runAction(CCFadeOut:create(0.3))
        schedule(actor.box, 0.3, function()
            actor.box:setVisible(false)
        end)
    end

    -- 播声音
    if cfgskill[actionId] and cfgskill[actionId].sound then
        schedule(layer, tFxMain, function()
            audio.playSkill(cfgskill[actionId].sound)
        end)
    end

    -- 下一轮攻击时间
    local tNext = (tJump + tAttack + tBack + 0.03) - tHurt + tFxHurtDuration
    if tNext < 0.45 then
        tNext = 0.45
    end

    if cfgskill[actionId].fxMain1 and cfgskill[actionId].fxMain1[1] == 5520 then
        tHurt = tHurt + 0.3 * (#actees1 - 1)
        tNext = tNext + 0.3 * (#actees1 - 1)
    end
    -- 返回值的时间用于啥时候开始结算伤害
    return tHurt, tNext, tFxHurt
end

-- 行动目标的特效
function helper.playActee(layer, actor, actee, actionId, buffId, miss)
    local cfg = clone(cfgskill[actionId])
    fxfix.processSkinFx(cfg, actor, actionId)
    local tFxHurt = helper.getFxHurtTime(cfg)
    local isEnemy = hHelper.isEnemy(actor, actee)
    if isEnemy then
        helper.playAll(layer, cfg.fxHurt1, {actee})
    elseif not miss then
        helper.playAll(layer, cfg.fxHurt2, {actee})
    end
    if isEnemy and not miss then
        schedule(layer, tFxHurt, function()
            actee.card:registerAnimation("hurt")
            -- 受伤shader
            actee.card:runAction(createSequence({
                CCCallFunc:create(function()
                    -- 石化时不用，否则shader冲突
                    if not arraycontains(bHelper.states(actee), BUFF_STONE) then
                        setShader(actee.card, SHADER_INJURED)
                    end
                end),
                CCDelayTime:create(5/30),
                CCCallFunc:create(function()
                    if not arraycontains(bHelper.states(actee), BUFF_STONE) then
                        clearShader(actee.card)
                    end
                end)
            }))
        end)
    end
end

-- 战斗单位进场 
function helper.playUnitComeIn(unit, isRevive)
    local t = 0.8
    unit.box:runAction(createSequence({ CCShow:create(), CCFadeIn:create(t) }))
    unit.hpFg:runAction(CCFadeIn:create(t))
    unit.hpFx:runAction(CCFadeIn:create(t))
    unit.epFg:runAction(CCFadeIn:create(t))
    unit.epFg:setVisible(true)
    if not isRevive then
        unit.card:runAction(createSequence({ CCShow:create(), CCFadeIn:create(t) }))
    end

    return t
end

-- buff生效时的特效
function helper.playBuffWork(layer, buffId, unit)
    local bname = cfgbuff[buffId].name
    -- 免疫冒文字提示
    if bname == BUFF_FREE then
        helper.playOneDamageNumber(layer, unit, { immune = true }, 0)
        return
    end
    -- 已有相同的控制类特效，不需要再播放
    local isControl = bHelper.isControl(bname)
    if isControl and unit.stateFx[bname] then
        return
    end
    -- 是否是印记
    local isImpress= bHelper.isImpress(bname)
    if isImpress and unit.stateFx[bname] then
        return
    end
    -- 播放buff特效
    local fxIds = cfgbuff[buffId].fx or {}
    for _, fxId in ipairs(fxIds) do
        local fx = helper.play(layer, fxId, unit)
        if fx and (isControl or isImpress) and cfgfx[fxId].retain then
            unit.stateFx[bname] = unit.stateFx[bname] or {}
            unit.stateFx[bname][#unit.stateFx[bname]+1] = fx
        end
    end
    if bHelper.isRoot(bname) then 
        unit.card:setPause(true)
    end
    if bname == BUFF_STONE then
        setShader(unit.card, SHADER_GRAY)
    end
end

-- 清除持久的buff特效(眩晕等）
function helper.clearBuffOff(unit)
    unit.card:setPause(bHelper.isRooted(unit))
    local states = bHelper.states(unit)
    if unit.stateFx[BUFF_STONE] and not arraycontains(states, BUFF_STONE) then
        clearShader(unit.card)
    end
    for _, bname in ipairs(bHelper.controls()) do
        if unit.stateFx[bname] and not arraycontains(states, bname) then
            for _, fx in ipairs(unit.stateFx[bname]) do
if not tolua.isnull(fx) then fx:removeFromParent() end
            end
            unit.stateFx[bname] = nil
        end
    end
    --移除印记类
    for _, bname in ipairs(bHelper.impresses()) do
        if unit.stateFx[bname] and not arraycontains(states, bname) then
            for _, fx in ipairs(unit.stateFx[bname]) do
if not tolua.isnull(fx) then fx:removeFromParent() end
            end
            unit.stateFx[bname] = nil
        end
    end
end

-- 死亡
function helper.playDead(unit, keepCorpse)
    if unit.hp == 0 and unit.card and not unit.fadeout then
        -- 清除其他特效状态
        helper.clear(unit)
        helper.clearBuffIcons(unit)
        -- 单位淡出
        local t = 0.3
        unit.box:runAction(CCFadeOut:create(t))
        unit.hpFg:runAction(CCFadeOut:create(t))
        unit.hpFx:runAction(CCFadeOut:create(t))
        unit.epFg:runAction(CCFadeOut:create(t))
        unit.card:playAnimation("dead")
        unit.card:clearNextAnimation()
        schedule(unit.card, unit.card:getAnimationTime("dead"), function()
            if not keepCorpse then
                unit.card:runAction(CCFadeOut:create(t))
                schedule(unit.box, t, function()
                    unit.box:setVisible(false)
                end)
            else
            end
        end)
        unit.fadeout = true
        ---- 隐藏橙卡特效
        --if unit.cardHead and unit.cardHead.orangeFx then
        --    unit.cardHead.orangeFx:setVisible(false)
        --end
    end
end

-- 复活, 逆播dead动画
function helper.playRevive(layer, unit)
    if unit and unit.revive_fx then
        unit.revive_fx:removeFromParent()
        unit.revive_fx = nil
    end
    local r_fx = cfgbuff[bHelper.id(BUFF_REVIVE)].fx
    if unit and unit.id and (unit.id == 5603 or  unit.id == 65613) then
        r_fx = {2033}
    end
    helper.playAll(layer, r_fx, {unit})
    helper.playUnitComeIn(unit, true)
    unit.card:setPlayBackwardsEnabled(true)
    unit.card:playAnimation("dead")
    unit.card:clearNextAnimation()
    schedule(unit.card, unit.card:getAnimationTime("dead"), function()
        unit.card:setPlayBackwardsEnabled(false)
        unit.card:playAnimation("stand", -1)
    end)
    unit.fadeout = nil
end

-- 清除持久特效
function helper.clear(unit)
    unit.card:setPause(false)
    clearShader(unit.card)
    for _, fxes in pairs(unit.stateFx) do
        for _, fx in ipairs(fxes) do
            fx:removeFromParent()
        end
    end
    unit.stateFx = {}
end

-- 先记录伤害数字，有多个数字时错开播放
function helper.recordDamageNumber(unit, result)
    unit.damageNumbers = unit.damageNumbers or {}
    unit.damageNumbers[#unit.damageNumbers+1] = result
end

-- 播放一个伤害或治疗数字特效
function helper.playOneDamageNumber(layer, unit, result, delay)
    --result.miss = op3(math.random()<0.1, true, false)
    --result.groupRestraint = op3(math.random()<0.5, true, false)
    --result.immune = op3(math.random()<0.1, true, false)
    --result.crit = op3(math.random()<0.2, true, false)
    --result.value = math.random(50, 100) * op3(math.random()<0.5, 1, -1)
    local numNode
    if result.miss then
        local miss_name = img.ui.fight_miss
        local miss_lgg = i18n.getLanguageShortName()
        if img.ui["fight_miss_" .. miss_lgg] then
            miss_name = img.ui["fight_miss_" .. miss_lgg]
        end
        numNode = img.createUISprite(miss_name)
    elseif result.immune then
        numNode = img.createUISprite(img.ui.fight_immune)
    else 
        numNode = helper.createDamageNumber(unit, result)
        numNode:setFlipX(unit.side == "attacker")
    end
    -- json动画
    local anim = json.create(json.ui.bt_numbers)
    anim:setVisible(false)
    layer.box:addChild(anim, 30)
    -- 决定要播放的动画名字
    local animationName
    if result.miss then
        animationName = "miss"
    elseif result.immune then
        animationName = "immune"
    elseif result.crit and result.value and result.value < 0 then
        animationName = "baoji"
    elseif result.crit and result.value and result.value > 0 then
        animationName = "zhiliao_b"
    elseif result.value and result.value > 0 then
        animationName = "zhiliao"
    elseif result.value and result.value < 0 and result.groupRestraint then
        animationName = "kezhi"
    else
        animationName = "normal"
    end
    -- 动画持续时间
    local duration = anim:getAnimationTime(animationName)
    -- 设置位置
    local rect = unit.card:getAabbBoundingBox()
    local p = ccp(rect:getMidX(), rect:getMidY())
    anim:setPosition(layer.box:convertToNodeSpace(p))
    anim:setFlipX(unit.side == "attacker")
    -- 播动画
    anim:addChildFollowSlot("code_" .. animationName, numNode)
    anim:runAction(createSequence({
        CCDelayTime:create(delay),
        CCShow:create(),
        CCCallFunc:create(function()
            anim:playAnimation(animationName, 1)
        end),
        CCDelayTime:create(duration),
        CCRemoveSelf:create()
    }))
end

-- 播放所有伤害或治疗数字特效
function helper.playAllDamageNumbers(layer, unit)
    if unit.damageNumbers == nil then
        return
    end
    -- 将多个result值累加得出总伤害值和总回血值
    -- 多个result值中只要有一个result.crit为true则总值的crit也为true
    -- 多个result值中只要有一个groupRestraint为true则总值的groupRestraint也为true
    local miss = false
    local value1, value2 = 0, 0
    local crit1, crit2 = false, false
    local groupRestraint1, groupRestraint2 = false, false
    for _, result in ipairs(unit.damageNumbers) do
        if result.miss then
            miss = true
        elseif result.value > 0 then
            if value1 >= 0 then
                value1 = value1 + result.value
                crit1 = crit1 or result.crit
            else
                value2 = value2 + result.value
                crit2 = crit2 or result.crit
            end
        elseif result.value < 0 then
            if value1 <= 0 then
                value1 = value1 + result.value
                crit1 = crit1 or result.crit
                groupRestraint1 = groupRestraint1 or result.groupRestraint
            else
                value2 = value2 + result.value
                crit2 = crit2 or result.crit
                groupRestraint2 = groupRestraint2 or result.groupRestraint
            end
        end
    end
    -- 错开播放数字
    local count = 0
    if miss then
        helper.playOneDamageNumber(layer, unit, { miss = true }, 0)
        count = count + 1
        -- 单位本身的miss效果
        --unit.card:registerAnimation("miss")
    end
    if value1 ~= 0 then
        local result = { value = value1, crit = crit1, groupRestraint = groupRestraint1 }
        helper.playOneDamageNumber(layer, unit, result, count*0.3)
        count = count + 1
    end
    if value2 ~= 0 then
        local result = { value = value2, crit = crit2, groupRestraint = groupRestraint2 }
        helper.playOneDamageNumber(layer, unit, result, count*0.3)
        count = count + 1
    end
    -- 清除数字记录
    unit.damageNumbers = nil
end

-- 创建伤害或治疗数字，用一个batchNode渲染
function helper.getDamageNumberString(value)
    if value == 0 then return "0" end
    local val = value
    if val < 0 then val = -val end
    if val < 1001 then
        return string.format("%+d", value)
    elseif val < 10000 then
        return string.format("%+.2f", value / 1000.0), "k"
    elseif val < 100000 then
        return string.format("%+.1f", value / 1000.0), "k"
    elseif val < 1000000 then
        return string.format("%+d", value / 1000.0), "k"
    elseif val < 10000000 then
        return string.format("%+.2f", value / 1000000.0), "m"
    elseif val < 100000000 then
        return string.format("%+.1f", value / 1000000.0), "m"
    elseif val < 1000000000 then
        return string.format("%+d", value / 1000000.0), "m"
    elseif val < 10000000000 then
        return string.format("%+.2f", value / 1000000000.0), "b"
    elseif val < 100000000000 then
        return string.format("%+.1f", value / 1000000000.0), "b"
	else
		return string.format("%+d", value / 1000000000.0), "b"
    end
end
function helper.createDamageNumber(unit, result)
    local batch = CCSprite:create()
    batch:setCascadeOpacityEnabled(true)
    -- 图片引用前缀
    local prefix
    if result.value > 0 then
        prefix = "fight_heal_num_"
    elseif result.crit then
        prefix = "fight_crit_num_"
    elseif result.groupRestraint then
        prefix = "fight_damage_num_"
    else 
        prefix = "fight_normal_num_"
    end
    -- 转化成字符串
    local str, strsym = helper.getDamageNumberString(result.value)
    -- 处理每个字符
    local singleWith = 27
    local singleHeight
    local pushPos = 0
    for i = 1, #str do
        local sprite
        if i == 1 then
            if result.value > 0 then
                sprite = img.createUISprite(img.ui[prefix .. "add"])
            else
                sprite = img.createUISprite(img.ui[prefix .. "minus"])
            end
            singleHeight = sprite:getContentSize().height
            sprite:setAnchorPoint(ccp(0, 0))
            sprite:setPosition(pushPos, 0)
            batch:addChild(sprite)
            pushPos = pushPos + singleWith
        elseif string.sub(str, i, i) == "." then
            if result.value > 0 then
                sprite = img.createUISprite(img.ui["fight_normal_num_minus"])
            else
                sprite = img.createUISprite(img.ui[prefix .. "minus"])
            end
            sprite:setAnchorPoint(ccp(0, 0))
            sprite:setPosition(pushPos + 2, -18)
            sprite:setScaleX(0.4)
            batch:addChild(sprite)
            pushPos = pushPos + singleWith - 10
        else
            sprite = img.createUISprite(img.ui[prefix .. string.sub(str, i, i)])
            sprite:setAnchorPoint(ccp(0, 0))
            sprite:setPosition(pushPos, 0)
            batch:addChild(sprite)
            pushPos = pushPos + singleWith
        end
    end
    if strsym then
        local showSym = img.createUISprite(img.ui["us_font_" .. strsym])
        showSym:setAnchorPoint(ccp(0, 0))
        showSym:setPosition(pushPos + 7, 0)
        batch:addChild(showSym)
        pushPos = pushPos + singleWith + 12
    end

    -- 大小
    local size = CCSize(pushPos, singleHeight)
    batch:setContentSize(size)
    batch:setAnchorPoint(ccp(0.5, 0.5))
    batch:setPosition(ccp(size.width/2, size.height/2))
    local container = CCSprite:create()
    container:setContentSize(batch:getContentSize())
    container:setCascadeOpacityEnabled(true)
    container:addChild(batch)

    return container
end

-- 统计唯一buff,返回新buff数组
local function statBuff(buffs)
    local sbuffs = {}
    for ii=1,#buffs do
        local b = buffs[ii]
        local t_key = ""
        if b.value and b.value < 0 then
            t_key = "bbN" .. b.id  -- 负向buff
        else
            t_key = "bbP" .. b.id  -- 正向buff
        end
        if sbuffs[t_key] then
            sbuffs[t_key].count = (sbuffs[t_key].count or 1) + 1
        else
            sbuffs[#sbuffs+1] = b
            sbuffs[t_key] = b
        end
    end
    return sbuffs
end

-- 刷新单位头上的buff图标
function helper.refreshBuffIcons(unit)
    -- buffIcons = {
    --     { id = 图标id, icon = 图标sprite },
    --     ...
    -- {
    if unit.buffIcons then
        -- 清除所有图标
        for _, ic in ipairs(unit.buffIcons) do
            ic.icon:removeFromParent()
        end
    end
    unit.buffIcons = {}
    if unit.hp == 0 then
        return
    end

    local t_buffs = statBuff(clone(unit.buffs))
    -- 反遍历buffs，因为图标只显示最新的几个
    for i = #t_buffs, 1, -1 do
        local b = t_buffs[i]
        local iconId = cfgbuff[b.id].icon1
        -- 有些图标有正负两种
        if cfgbuff[b.id].icon2 and b.value and b.value < 0 then
            iconId = cfgbuff[b.id].icon2
        end
        if iconId then
            -- 先判断是不是已存在
            local exists = false
            local t_icon = nil
            for _, ic in ipairs(unit.buffIcons) do
                if ic.id == iconId then
                    exists = true
                    t_icon = ic
                    if not t_icon.count then
                        t_icon.count = 1
                    else
                        t_icon.count = t_icon.count + 1
                    end
                    break
                end
            end
            -- 不存在则建新图标
            if not exists then
                local icon = img.createBuffWithNum(iconId)
                unit.box:addChild(icon, 1)
                table.insert(unit.buffIcons, 1, { id = iconId, icon = icon, count = 1 })
                -- 印记类数字层数
                if b.count and b.count > 1 then
                    icon.lbl:setString("" .. b.count)
                end
                -- 图标已达最大个数
                if #unit.buffIcons == MAX_BUFF_ICON then
                    break
                end
            else
                if cfgbuff[b.id].superpose then  -- 不显示叠加数字
                elseif b.count and b.count > 1 then
                --elseif t_icon and t_icon.count and t_icon.count > 1 then
                    t_icon.icon.lbl:setString("" .. b.count)
                end
            end
        end
    end
    -- 设置所有图标的位置
    if #unit.buffIcons > 0 then
        local x, y = unit.hpBg:getPositionX(), unit.hpBg:boundingBox():getMaxY()
        for i, ic in ipairs(unit.buffIcons) do
            ic.icon:setPosition(x + BUFF_XY[unit.size][i][1], y + BUFF_XY[unit.size][i][2])
        end
    end
end

-- 清除单位头上的buff图标
function helper.clearBuffIcons(unit)
    if unit.buffIcons then
        for _, ic in ipairs(unit.buffIcons) do
            ic.icon:removeFromParent()
        end
        unit.buffIcons = nil
    end
end

-- 战斗中的帮助按钮
function helper.addHelpButton(layer)
    -- button
    local btn0 = img.createUISprite(img.ui.btn_detail)
    local btn = SpineMenuItem:create(json.ui.button, btn0)
    btn:setPosition(27, 549)
    btn:registerScriptTapHandler(function()
        if not layer.isPaused and not layer.isEnd then
            audio.play(audio.button)
            helper.popHelp(layer)
            resumeSchedulerAndActions(btn)
        end
    end)
    local menu = CCMenu:createWithItem(btn)
    menu:setPosition(0, 0)
    layer.box:addChild(menu, 100)

    autoLayoutShift(btn)
end

-- 弹出战斗中帮助弹窗
function helper.popHelp(layer, onClose)
    layer.isPaused = true
    CCDirector:sharedDirector():getScheduler():setTimeScale(1)
    pauseSchedulerAndActions(layer)
    local pop = require("fight.group").create(function()
        layer.isPaused = false
        resumeSchedulerAndActions(layer)
        CCDirector:sharedDirector():getScheduler():setTimeScale(helper.getCurFightSpeed())
        if onClose then
            onClose()
        end
    end)
    layer:addChild(pop, 100)
end

-- 战斗中的跳过战斗按钮
function helper.addSkipButton(layer)
    -- button
    local btn0 = img.createUISprite(img.ui.fight_skip)
    local btn = SpineMenuItem:create(json.ui.button, btn0)
    btn:setPosition(917, 548)
    btn:registerScriptTapHandler(function()
        if not layer.isPaused and not layer.isEnd then
            audio.play(audio.button)
            helper.popSkip(layer)
            resumeSchedulerAndActions(btn)
        end
    end)
    local menu = CCMenu:createWithItem(btn)
    menu:setPosition(0, 0)
    layer.box:addChild(menu, 100)

    autoLayoutShift(btn, true, false, false, true)
end

-- 弹出战斗中跳过战斗弹窗
function helper.popSkip(layer)
    if layer.canSkip and not layer.canSkip() then
        showToast(string.format(i18n.global.func_need_lv.string, UNLOCK_FIGHT_SKIP_LEVEL))
        return
    end
    layer.isPaused = true
    CCDirector:sharedDirector():getScheduler():setTimeScale(1)
    pauseSchedulerAndActions(layer)
    --[[local pop = require("ui.dialog").create({
        title = i18n.global.fight_skip_title.string,
        body = i18n.global.fight_skip_text.string,
        btn_count = 2,
        btn_text = {
            [1] = i18n.global.dialog_button_cancel.string,
            [2] = i18n.global.dialog_button_confirm.string,
        },
        selected_btn = 0,
    })
    pop.setCallback(function(data)
        if data.selected_btn == 1 then
            pop.onAndroidBack()
        elseif data.selected_btn == 2 and layer.onSkip then
            layer.isPaused = false
            pop:removeFromParent()
            layer.onSkip()
        end
    end)
    function pop.onAndroidBack()
        layer.isPaused = false
        pop:removeFromParent()
        CCDirector:sharedDirector():getScheduler():setTimeScale(helper.getCurFightSpeed())
        resumeSchedulerAndActions(layer)
    end
    layer:addChild(pop, 100)
--]]
    layer.isPaused = false
    if layer.onSkip then
        layer.onSkip()
    else
        CCDirector:sharedDirector():getScheduler():setTimeScale(helper.getCurFightSpeed())
        resumeSchedulerAndActions(layer)
    end
end

-- 战斗中的加速按钮
function helper.addSpeedButton(layer, corner)
    local timeScale = userdata.getInt(userdata.keys.fightSpeed, 1)
    local spd = helper.getCurFightSpeed()
    local max = helper.getMaxFightSpeed()
    local pmax = helper.getPlayerMaxFightSpeed()
    -- button
    local labels = {}
    for i = 1, math.floor(pmax) do
        labels[#labels+1] = lbl.createFont2(20, "x" .. i, ccc3(0xff, 0xf7, 0xe5))
    end
    local container = img.createUISprite(img.ui.fight_speed_up)
    for i, label in ipairs(labels) do
        label:setPosition(60, 28)
        label:setVisible(i == math.floor(spd))
        container:addChild(label)
    end
    local btn = SpineMenuItem:create(json.ui.button, container)
    btn:setPosition(op3(corner, ccp(905, 548), ccp(829, 548)))
    btn:registerScriptTapHandler(function()
        audio.play(audio.button)
        if spd == pmax and pmax < max then
            showToast(i18n.global["fight_spd" .. (math.floor(spd)+1) .. "_vip"].string)
        end
        spd = op3(spd == pmax, 1*spd_factor, 2*spd_factor)
        CCDirector:sharedDirector():getScheduler():setTimeScale(spd)
        userdata.setInt(userdata.keys.fightSpeed, spd)
        for i, label in ipairs(labels) do
            label:setVisible(i == math.floor(spd))
        end
    end)
    local menu = CCMenu:createWithItem(btn)
    menu:setPosition(0, 0)
    layer.box:addChild(menu, 100)

    autoLayoutShift(btn, true, false, false, true)
end

-- 战斗回合
function helper.addRoundLabel(layer)
    local name = lbl.createFont2(16, i18n.global.fight_round.string, ccc3(0xff, 0xd4, 0x3c))
    name:setPosition(480, 563)
    layer.box:addChild(name, 100)
    local label = lbl.createFont3(26, "0")
    label:setPosition(480, 540)
    layer.box:addChild(label, 100)
    layer.roundLabel = label

    autoLayoutShift(name)
    autoLayoutShift(label)
end

-- 设置战斗回合
function helper.setRoundLabel(layer, num)
    if layer.roundLabel.num ~= num then
        layer.roundLabel:setString(num)
        layer.roundLabel.num = num 
    end
end

-- 最大播放速度
local maxFightSpeed
function helper.getMaxFightSpeed()
    if not maxFightSpeed then
        local cfgvip = require "config.vip"
        for i = 0, #cfgvip do
            local spd = cfgvip[i].speed
            if not maxFightSpeed or maxFightSpeed < spd then
                maxFightSpeed = spd
            end
        end
    end
    return maxFightSpeed * spd_factor
end

-- 玩家的最大播放速度
function helper.getPlayerMaxFightSpeed()
    local lv = require("data.player").vipLv()
    if require("data.player").lv() >= UNLOCK_FIGHT_SPEED_LEVEL then
        lv = 1      -- vip1可加速
    end
    local cfgvip = require "config.vip"
    return cfgvip[lv].speed * spd_factor
end

-- 当前的播放速度
function helper.getCurFightSpeed()
    local spd = userdata.getInt(userdata.keys.fightSpeed, 1*spd_factor)
    if spd < 1 * spd_factor then
        spd = 1 * spd_factor
    elseif spd > 2 * spd_factor then
        spd = 2 * spd_factor
    end
    local max = helper.getPlayerMaxFightSpeed()
    return op3(spd > max, max, spd)
end

-- 阵营buff展示
function helper.addCampBuff(layer, attackers, defenders)
    local function getGroup(units)
        if #units == 6 then
            local exists = {}
            for _, u in ipairs(units) do
                exists[u.group] = true
            end
            local len = tablelen(exists)
            if len == 1 then
                return units[1].group
            elseif len == 6 then
                return 7
            end
        end
    end
    for _, side in ipairs({"attacker", "defender"}) do
        -- slot
        local slot = img.createUISprite(img.ui.campbuff_slot)
        slot:setAnchorPoint(op3(side == "attacker", ccp(0, 0), ccp(1, 0)))
        slot:setPosition(op3(side == "attacker", ccp(0-49, 0), ccp(960+49, 0)))
        slot:setFlipX(side == "attacker")
        layer.box:addChild(slot, 100)
        -- grid
        local grid = img.createUISprite(img.ui.campbuff_grid)
        local size = grid:getContentSize()
        grid:setPosition(op3(side == "attacker", ccp(27, 28), ccp(960-27, 28)))
        layer.box:addChild(grid, 100)
        -- icon
        --local group = getGroup(op3(side == "attacker", attackers, defenders))
        local group = getCampBuff(op3(side == "attacker", attackers, defenders))
        local icon
        if group > 0 then
            icon = json.create(json.ui.campbuff[group])
            icon:playAnimation("animation", -1)
            icon:setScale(0.6)
        else
            icon = img.createUISprite(img.ui.campbuff_none)
        end
        icon:setPosition(size.width/2, size.height/2)
        grid:addChild(icon)
        -- handler
        local pop
        grid:setTouchEnabled(true)
        grid:registerScriptTouchHandler(function(event, x, y)
            if event == "began" then   
                audio.play(audio.button)
                if group > 0 and not pop then
                    pop = require("ui.tips.campbuff").create(group)
                    pop.bg:setPosition(op3(side == "attacker", scalep(245, 172), scalep(960-245, 172)))
                    layer:addChild(pop, 100)
                    return true
                end
                showToast(i18n.global.fight_no_campbuff.string)
                return false
            elseif event == "moved" then
                return 
            elseif pop then
                if not tolua.isnull(pop) then
                    pop:removeFromParent()
                end
                pop = nil
            end
        end)

        autoLayoutShift(grid)
        autoLayoutShift(slot)
    end
end

function helper.addBackgroundListner(node, _handler)
    if APP_CHANNEL and APP_CHANNEL ~= "" then return end
    if device.platform ~= "android" then return end -- gp
    local nc = CCNotificationCenter:sharedNotificationCenter()
    nc:unregisterScriptObserver(node, "APP_ENTER_BACKGROUND_EVENT")
    nc:registerScriptObserver(node, _handler, "APP_ENTER_BACKGROUND_EVENT")
end

function helper.addForegroundListner(node, _handler)
    if APP_CHANNEL and APP_CHANNEL ~= "" then return end
    if device.platform ~= "android" then return end -- gp
    local nc = CCNotificationCenter:sharedNotificationCenter()
    nc:unregisterScriptObserver(node, "APP_ENTER_FOREGROUND_EVENT")
    nc:registerScriptObserver(node, _handler, "APP_ENTER_FOREGROUND_EVENT")
end

function helper.removeBackAndForegroundListener(node)
    if APP_CHANNEL and APP_CHANNEL ~= "" then return end
    if device.platform ~= "android" then return end -- gp
    local nc = CCNotificationCenter:sharedNotificationCenter()
    nc:unregisterScriptObserver(node, "APP_ENTER_FOREGROUND_EVENT")
    nc:unregisterScriptObserver(node, "APP_ENTER_BACKGROUND_EVENT")
end

return helper
