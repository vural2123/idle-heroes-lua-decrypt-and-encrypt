-- heros info

local heros = {}

require "common.func"
local cfghero = require "config.hero"
local cfgexphero = require "config.exphero"
local achieveData = require "data.achieve"
local activitydata = require "data.activity"
local attrHelper = require "fight.helper.attr"
local bag = require "data.bag"

function heros.gethskills(hid, h)
    if not h then h = heros.find(hid) end
    if not h then return {} end
    local skillId = {}
    if h.hskills and #h.hskills > 0 then
        local index = 1
        while index < #h.hskills do
            if h.hskills[i] ~= 0 then skillId[#skillId + 1] = { id = h.hskills[index], lock = h.hskills[index + 1] } end
            index = index + 2
        end
    elseif h.wake == nil or h.wake >= 4 then
        if cfghero[h.id].actSkillId then
            skillId[#skillId + 1] = { id = cfghero[h.id].actSkillId, lock = 0 }
        end
        for i=1, 6 do
            if cfghero[h.id]["pasSkill" .. i .. "Id"] then
                skillId[#skillId + 1] = { id = cfghero[h.id]["pasSkill" .. i .. "Id"], lock = cfghero[h.id]["pasTier" .. i] }
            end
        end
    else
        if cfghero[h.id].disillusSkill[h.wake].disi[1] then
            skillId[#skillId + 1] = { id = cfghero[h.id].disillusSkill[h.wake].disi[1], lock = 0 }
        end
        for i=1, 6 do
            if cfghero[h.id].disillusSkill[h.wake].disi[i+1] then
                skillId[#skillId + 1] = { id = cfghero[h.id].disillusSkill[h.wake].disi[i+1], lock = cfghero[h.id]["pasTier" .. i] }
            end
        end
    end
    return skillId
end

-- param: array pb_hero
function heros.init(pbs)
    arrayclear(heros)
    if not pbs then return end
    for i, pb in ipairs(pbs) do
        local h = tablecp(pb)
        heros.adapt(h)
        heros[#heros+1] = h
    end
end

function heros.adaptreplace(srep)
    heros.treehid = nil
    heros.treeid = nil
    if not srep then return end
    local i = 1
    local endn = #srep
    local t, h
    while i < endn do
        t = srep[i]
        if t == 1 then
            h = heros.find(srep[i + 1])
            if h then
                h.offered = srep[i + 2]
            end
        elseif t == 2 then
            heros.treehid = srep[i + 1]
            heros.treeid = srep[i + 2]
        end
        i = i + 3
    end
end

function heros.checkskin(hid, data)
	if not data and hid then
		data = heros.find(hid)
	end
	if data then
		if data.star == 6 and data.wake and data.wake >= 7 and data.equips then
			local cfgequip = require "config.equip"
			local player = require "data.player"
			local headData = require "data.head"
			for _, v in pairs(data.equips) do
				local vid = v
				local eq = cfgequip[vid]
				if eq and eq.pos and eq.pos == 7 and eq.powerful and eq.powerful ~= 0 then
					vid = eq.powerful
					eq = cfgequip[vid]
				end
				if eq and eq.pos and eq.pos == 7 then
					if not player.skinicons then player.skinicons = {} end
					if not player.skinicons[vid] then
						player.skinicons[vid] = 2
						headData.forceRed = true
					end
				end
			end
		end
	end
end

function heros.adapt(h)
    local cfg = cfghero[h.id]
    h.equips = h.equips or {}
    h.lv = h.lv or 1
    h.star = h.star or 0
    if h.visit == nil then h.visit = false end

    -- return {hp,atk,arm,spd,hit,miss,crit,critTime,sklP,decDmg,free,trueAtk,brk,power}
    function h.attr(loadout)
        return attrHelper.attr(h, nil, nil, nil, nil, loadout)
    end

    return h
end

-- param: pb_hero
function heros.add(pb, skipAchi)
    local h = tablecp(pb)
    heros.adapt(h)
    heros[#heros+1] = h

    --if cfghero[h.id].qlt >= QUALITY_5 then
    --    if cfghero[h.id].group == GROUP_5 then
    --        activitydata.gotDarkHero()
    --    end

    --    if cfghero[h.id].group == GROUP_6 then
    --        activitydata.gotLightHero()
    --    end
    --end

    if skipAchi then return end

    if cfghero[h.id].qlt == GROUP_4 then
        achieveData.add(ACHIEVE_TYPE_GET_HERO_STAR4, 1) 
    end
    
    if cfghero[h.id].qlt == GROUP_5 then
        achieveData.add(ACHIEVE_TYPE_GET_HERO_STAR5, 1) 
    end
    
    if cfghero[h.id].qlt == GROUP_6 then
        achieveData.add(ACHIEVE_TYPE_GET_HERO_STAR6, 1) 
    end
    
    local herobook = require "data.herobook"
    herobook.add(h.id)
end

function heros.addAll(pbs)
    for i, pb in ipairs(pbs) do
        heros.add(pb)
    end
end

function heros.find(hid)
    for i, h in ipairs(heros) do
        if h.hid == hid then
            return h, i
        end
    end
end

function heros.getHeroSkill(hid, nr)
    local h = heros.find(hid)
    if h and h.skills then return h.skills[nr] or 0 end
    return 0
end
function heros.setHeroSkill(hid, nr, skill)
    local h = heros.find(hid)
    if h then
        if not h.skills then h.skills = {} end
        h.skills[nr] = skill
    end
end
function heros.isHeroSkill(hid, skill)
    local h = heros.find(hid)
    if h and h.skills then
        for _, v in pairs(h.skills) do
            if v == skill then return true end
        end
    end
end

function heros.changeID(hid, id)
    for i, h in ipairs(heros) do
        if h.hid == hid then
            heros[i].id = id
            local herobook = require "data.herobook"
            herobook.add(id)
            return
        end
    end
end

-- 觉醒数据变化
function heros.wakeUp(hid, id)
    for i, h in ipairs(heros) do
        if h.hid == hid then
            if heros[i].wake == nil then
                -- hp,atk,arm,spd
                heros[i].wake = 1
            else
                local oldwake = heros[i].wake
                local newwake = oldwake + 1
                if oldwake == 3 and require("data.player").isSeasonal() then newwake = 7 end
                heros[i].wake = newwake
                if oldwake < 4 and newwake >= 4 then
                    heros[i].id = cfghero[id].nId
                    local herobook = require "data.herobook"
                    herobook.add(heros[i].id)
                end
            end
            --heros[i].attr().atk = cfghero[heros[i].id].disillusGrow[heros[i].wake].disiG[1]
            --heros[i].attr().hp = cfghero[heros[i].id].disillusGrow[heros[i].wake].disiG[2]
            --heros[i].attr().arm = cfghero[heros[i].id].disillusGrow[heros[i].wake].disiG[3]
            --heros[i].attr().spd = cfghero[heros[i].id].disillusGrow[heros[i].wake].disiG[4]
			heros.checkskin(hid)
            return
        end
    end
end

-- 十星置换用
function heros.tenchange(tenherodata, id)
    local cfglifechange = require "config.lifechange"
    for i, h in ipairs(heros) do
        if h.hid == tenherodata.hid then
            heros[i].id = cfglifechange[id].nId
            local herobook = require "data.herobook"
            herobook.add(heros[i].id)
        end
    end
end

function heros.findById(id)
    local rt = {}
    for i, h in ipairs(heros) do
        if h.id == id then
            rt[#rt+1] = h
        end
    end

    return rt
end

function heros.del(hid, notReturnEquip)
    for i, h in ipairs(heros) do
        if h.hid == hid then
            if not notReturnEquip then
                for j, v in ipairs(h.equips) do
                    bag.equips.returnbag({ id = v, num = 1}) 
                end
            end
            table.remove(heros, i)
            return h
        end
    end
end

function heros.power(hid, loadout)
    return heros.find(hid).attr(loadout).power
end

-- 仅英雄图鉴调用, true表示来自图鉴
function heros.maxAttr(id)
    return attrHelper.attr({id = id}, cfghero[id].qlt, cfghero[id].maxLv, nil, true)
end

function heros.decompose(hids)
    local exp, evolve, rune = 0, 0, 0
    for i, v in ipairs(hids) do
		if v >= 0 then
			heroData = heros.find(v)
			if heroData then
				exp = exp + cfghero[heroData.id].xpBase + 0.65 * cfgexphero[heroData.lv].allExp
				evolve = evolve + cfghero[heroData.id].tierBase
				for i=1, heroData.star do
					evolve = evolve + 0.7 * cfghero[heroData.id]["starExp" .. i][1]
				end
				rune = rune + cfghero[heroData.id].rune
			end
		else
			local cf = cfghero[-v]
			if cf then
				exp = exp + cf.xpBase + 0.65 * cfgexphero[1].allExp
				evolve = evolve + cf.tierBase
				rune = rune + cf.rune
			end
		end
    end
    return exp, evolve, rune
end

function heros.decomposeForwake(hids)
    local exp = 0
    for i, v in ipairs(hids) do
		if v >= 0 then
			heroData = heros.find(v)
			if heroData then
				exp = exp + cfghero[heroData.id].xpBase + cfgexphero[heroData.lv].allExp
			end
		else
			local cf = cfghero[-v]
			if cf then
				exp = exp + cf.xpBase + cfgexphero[1].allExp
			end
		end
    end
    return exp
end

function heros.decomposeFortenchange(hids)
    local exp, evolve, rune = 0, 0, 0
    for i, v in ipairs(hids) do
        heroData = heros.find(v)
        if heroData then
            exp = exp + cfghero[heroData.id].xpBase + cfgexphero[heroData.lv].allExp
            evolve = evolve + cfghero[heroData.id].tierBase
            for i=1, heroData.star do
                evolve = evolve + cfghero[heroData.id]["starExp" .. i][1]
            end
            rune = rune + cfghero[heroData.id].rune
        end
    end
    return exp, evolve, rune
end

-- 1 竞技场 2 英雄锁定
function heros.setFlag(hids, flagId)
    for i, v in ipairs(hids) do
        local heroData = heros.find(hids[i])
        if heroData then
            if not heroData.flag then heroData.flag = 0 end
            if bit.band(heroData.flag, flagId) == 0 then
                heroData.flag = heroData.flag + flagId
            end
        end
    end
end

-- 设置英雄皮肤是否隐藏
function heros.setVisit(hid, flag)
    local heroData = heros.find(hid)
    heroData.visit = flag
end

function heros.print()
    print("--------------- heros --------------- {")
    for i, h in ipairs(heros) do
        print("id:", h.id, "hid:", h.hid, "lv:", h.lv, "star:", h.star, 
              "wake:", h.wake, "flag:", h.flag, "equips:" , table.concat(h.equips, ","))
    end
    print("--------------- heros --------------- }")
end

return heros


