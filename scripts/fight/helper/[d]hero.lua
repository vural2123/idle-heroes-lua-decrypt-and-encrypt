-- hero的一些帮助函数

local helper = {}

require "common.func"
require "common.const"
local cfghero = require "config.hero"
local cfgmons = require "config.monster"
local cfgskill = require "config.skill"
local cfgequip = require "config.equip"
local herosdata = require "data.heros"
local player = require "data.player"

function helper.createHero(param)
    local p = tablecp(param)
    if p.hid then
        local h = herosdata.find(p.hid)
        p.id = p.id or h.id
        p.lv = p.lv or h.lv
        p.star = p.star or h.star
        p.skin = getHeroSkin(p.hid)
    end
    return {
        kind = p.kind or "hero",
        hid = p.hid,
        id = p.id,
        heroId = p.heroId or p.id,
        lv = p.lv,
        hp = p.hp or 100,
        ep = p.ep or cfghero[p.id].energyBase or 0,
        group = p.group or cfghero[p.id].group,
        pos = p.pos,
        side = p.side or "attacker",
        size = p.size or "small",
        star = p.star or 0,
        buffs = p.buffs or {},
        stateFx = p.stateFx or {},
        atkId = p.atkId or helper.atkId(p.heroId or p.id, p.star or 0, p.wake),
        addHurtId = helper.addHurtId(p.heroId or p.id, p.star or 0),
        skin = p.skin,
    }
end

function helper.createMons(param)
    local cfg = cfgmons[param.id]
    return {
        kind = param.kind or "mons",
        id = param.id,
        heroId = param.heroId or cfg.heroLink,
        lv = param.lv or cfg.lvShow or cfg.lv,
        hp = param.hp or 100,
        ep = param.ep or cfghero[cfg.heroLink].energyBase or 0,
        group = param.group or cfghero[cfg.heroLink].group,
        pos = param.pos,
        side = param.side or "defender",
        size = param.size or op3(cfg.isBoss, "large", "small"),
        star = param.star or cfg.star,
        buffs = param.buffs or {},
        stateFx = param.stateFx or {},
        atkId = param.atkId or helper.atkId(param.heroId or cfg.heroLink, param.star or cfg.star, param.wake),
        addHurtId = helper.addHurtId(param.heroId or cfg.heroLink, param.star or cfg.star),
    }
end

-- 阵营克制
function helper.groupRestraint(actor, actee)
    if actor and actee then     
        local group1, group2 = actor.group, actee.group
        if (group1 == 1 and group2 == 2) or (group1 == 2 and group2 == 3)
            or (group1 == 3 and group2 == 4) or (group1 == 4 and group2 == 1) 
            or (group1 == 5 and group2 == 6) or (group1 == 6 and group2 == 5) then
            return true
        end
    end
    return false
end

-- 根据站位确定是不是敌人
function helper.isEnemy(a, b)
    return (a.pos <=6 and b.pos > 6) or (a.pos > 6 and b.pos <= 6)
end

-- 普攻id
function helper.atkId(id, star, wake)
    local cfg = clone(cfghero[id])
    if wake and wake < 4 and cfg.disillusSkill and cfg.disillusSkill[wake] and cfg.disillusSkill[wake].disi then
        cfg["pasSkill1Id"] = cfg.disillusSkill[wake].disi[2]
        cfg["pasSkill2Id"] = cfg.disillusSkill[wake].disi[3]
        cfg["pasSkill3Id"] = cfg.disillusSkill[wake].disi[4]
    end
    for i, n in ipairs({"pasSkill1Id", "pasSkill2Id", "pasSkill3Id"}) do
        local skId = cfg[n]
        local tier = cfg["pasTier" .. i]
        if skId and tier and star >= tier then
            for _, e in ipairs(cfgskill[skId].effect) do
                if e.type == BUFF_CHANGE_COMBAT then
                    return e.num
                end
            end
        end
    end
    return cfghero[id].atkId
end

-- 追加攻击id
function helper.addHurtId(id, star)
    for i, n in ipairs({"pasSkill1Id", "pasSkill2Id", "pasSkill3Id"}) do
        local skId = cfghero[id][n]
        local tier = cfghero[id]["pasTier" .. i]
        if skId and tier and star >= tier then
            for _, e in ipairs(cfgskill[skId].effect) do
                if e.type == BUFF_ADD_HURT then
                    return skId
                end
            end
        end
    end
end

-- 处理英雄携带宝物时提供的能量
function helper.processTreasureEpOne(unit, extraEnergy)
	if not unit then return end
	
	unit.ep = unit.ep or 0
	
    if unit.hid then
		local h = herosdata.find(unit.hid)
		if h and h.equips then
			for ii=1,#h.equips do
				local eid = h.equips[ii]
				local cfg = cfgequip[eid]
				if cfg and cfg.pos == EQUIP_POS_TREASURE then
					-- base1
					if cfg.base1 and cfg.base1["type"] and cfg.base1["type"] == "energy" then
						unit.ep = unit.ep + cfg.base1.num
					end
					-- base2
					if cfg.base2 and cfg.base2["type"] and cfg.base2["type"] == "energy" then
						unit.ep = unit.ep + cfg.base2.num
					end
					-- base3
					if cfg.base3 and cfg.base3["type"] and cfg.base3["type"] == "energy" then
						unit.ep = unit.ep + cfg.base3.num
					end
				end
			end
		end
	end
	
	if unit.id and unit.id == 75103 then -- baade
		unit.ep = unit.ep + 50
	end
	
	if extraEnergy then
		unit.ep = unit.ep + extraEnergy
	end
	
    if unit.ep > 100 then
        unit.ep = 100
    end
end
function helper.processTreasureEp(units)
    if not units or #units<= 0 then return end
	
	local extraEnergy = 0
	if #units >= 6 then
		local teamHero = {}
		for i=1, 6 do
			teamHero[#teamHero+1] = { heroId = units[i].heroId }
		end
		local camp = getCampBuff(teamHero)
		if camp > 0 then
			local cfgcamp = nil
			if player.isSeasonal() then
				cfgcamp = require ("config.camp2")
			else
				cfgcamp = require ("config.camp")
			end
			local cfg = cfgcamp[camp]
			if cfg and cfg.effect then
				for _, v in ipairs(cfg.effect) do
					if v.type == "energy" then
						extraEnergy = extraEnergy + v.num
					end
				end
			end
		end
	end
	
	for _, v in ipairs(units) do
		helper.processTreasureEpOne(v, extraEnergy)
    end
end

return helper
