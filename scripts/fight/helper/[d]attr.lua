-- 计算英雄的详细属性和战斗力

local helper = {}

require "common.func"
require "common.const"
local cfghero = require "config.hero"
local cfgbuff = require "config.buff"
local cfgequip = require "config.equip"
local cfgtalen = require "config.talen"
local cfgskill = require "config.skill"
local bagdata = require "data.bag"
local gskillData = require "data.gskill"

local names = {
    BUFF_ATK, BUFF_ATK_P, BUFF_ARM, BUFF_ARM_P, BUFF_HP, BUFF_HP_P, BUFF_SPD, 
    BUFF_HIT, BUFF_MISS,  BUFF_CRIT, BUFF_CRIT_TIME, BUFF_SKL_P, BUFF_DEC_DMG, 
    BUFF_FREE, BUFF_TRUE_ATK, BUFF_BRK,
}

local isPercent = {}
local isReduction = {}

local jobBuff = {
    zsHpPO = BUFF_HP_P,
    zsAtkPO = BUFF_ATK_P,
    zsCritO = BUFF_CRIT,
    zsMissO = BUFF_MISS,
    zsSklPO = BUFF_SKL_P,
    zsSpdO = BUFF_SPD,

    fsHpPO = BUFF_HP_P,
    fsAtkPO = BUFF_ATK_P,
    fsCritO = BUFF_CRIT,
    fsHitO = BUFF_HIT,
    fsSklPO = BUFF_SKL_P,
    fsSpdO = BUFF_SPD,

    ckHpPO = BUFF_HP_P,
    ckCritTimeO = BUFF_CRIT_TIME,
    ckCritO = BUFF_CRIT,
    ckBrkO = BUFF_BRK,
    ckSklPO = BUFF_SKL_P,
    ckSpdO = BUFF_SPD,
    ckAtkPO = BUFF_ATK_P,

    yxHpPO = BUFF_HP_P,
    yxAtkPO = BUFF_ATK_P,
    yxMissO = BUFF_MISS,
    yxHitO = BUFF_HIT,
    yxSklPO = BUFF_SKL_P,
    yxSpdO = BUFF_SPD,

    msHpPO = BUFF_HP_P,
    msMissO = BUFF_MISS,
    msCritO = BUFF_CRIT,
    msSpdO = BUFF_SPD,
    msSklPO = BUFF_SKL_P,
    msAtkPO = BUFF_ATK_P,
}

function helper.jobBuff(_b)
    return jobBuff[_b]
end

function helper.init()
    if #isPercent == 0 then
        for _, name in ipairs(names) do
            local id = buffname2id(name)
            if cfgbuff[id].isPercent == 2 then
                isPercent[name] = true 
            end
        end
    end
	
	if #isReduction == 0 then
		isReduction[BUFF_DEC_DMG] = true
	end
end

function helper.attr(hero, star, lv, wake, isHeroBook, loadout)
    star = star or hero.star
    lv = lv or hero.lv
    wake = wake or hero.wake

    helper.init()

    local cfg = clone(cfghero[hero.id])

    -- 英雄自身属性
    local cfggrowhp = cfg.growHp
    local cfggrowatk = cfg.growAtk
    local cfggrowarm = cfg.growArm
    local cfggrowspd = cfg.growSpd

    if wake and wake ~= 0 and wake < 4 then
        cfggrowhp = cfg.disillusGrow[wake].disiG[2]
        cfggrowatk = cfg.disillusGrow[wake].disiG[1]
        cfggrowarm = cfg.disillusGrow[wake].disiG[3]
        cfggrowspd = cfg.disillusGrow[wake].disiG[4]
        cfg.pasSkill = cfg.disillusSkill[wake].disi[1]
        cfg.pasSkill1Id = cfg.disillusSkill[wake].disi[2]
        cfg.pasSkill2Id = cfg.disillusSkill[wake].disi[3]
        cfg.pasSkill3Id = cfg.disillusSkill[wake].disi[4]
    end
    if hero and not isHeroBook then
        for i=1, 3 do
            cfg["pasTier" .. i] = nil
            cfg["pasSkill" .. i .. "Id"] = nil
        end
        local hskills = (require "data.heros").gethskills(0, hero)
        if hskills then
            local six = 1
            while six < #hskills do
                cfg["pasSkill" .. six .. "Id"] = hskills[six + 1].id
                cfg["pasTier" .. six] = hskills[six + 1].lock
                six = six + 1
            end
        end
    end
    local base = {
        hp = (cfg.baseHp + (lv-1) * cfggrowhp) * (1 + star * 0.2),
        atk = (cfg.baseAtk + (lv-1) * cfggrowatk) * (1 + star * 0.2),
        arm = cfg.baseArm + (lv-1) * cfggrowarm,
        spd = (cfg.baseSpd + (lv-1) * cfggrowspd) * (1 + star * 0.1),
    }

    -- 装备属性
    local extra = {}
	local extra2 = {}

    local function addAttr(name, value)
        if isPercent[name] or isReduction[name] then
            if extra[name] then
                extra[name][#extra[name]+1] = value
            else
                extra[name] = { value }
            end
        else
            extra[name] = (extra[name] or 0) + value
        end
    end
	
	local function addPass(id, ignoreNotAttrPas, collectStats)
		local sk = cfgskill[id]
		if not sk then return false end
		local did = false
		if sk.attrPas or ignoreNotAttrPas then
			did = true
			for _, b in ipairs(sk.effect) do
				local bt = b.type
				if not collectStats or (bt ~= BUFF_HP_P and bt ~= BUFF_ATK_P and bt ~= BUFF_ARM_P) then
					addAttr(bt, b.num)
				elseif extra2[bt] then
					extra2[bt] = extra2[bt] + b.num
				else
					extra2[bt] = b.num
				end
			end
		end
		if sk.coSkill then
			if addPass(sk.coSkill, false, collectStats) then
				did = true
			end
		end
		return did
	end
	
	local stand = nil
	if loadout and hero.hid then
		for pos, vu in pairs(loadout.stand) do
			if vu.hid == hero.hid then
				stand = vu
				break
			end
		end
	end

    -- 赋能属性
    if wake and wake > 4 then
        local talenAttr = cfgtalen[wake-4].base
        if talenAttr then
            for i=1,#talenAttr do
                addAttr(talenAttr[i].type, talenAttr[i].num)
            end
        end
		local tskills = hero.skills
		if stand then tskills = stand.skills end
        -- 附能永久属性被动技能
		if tskills then
			for _, pasSkill in pairs(tskills) do
				if pasSkill and pasSkill ~= 0 and pasSkill ~= 6100 then
					addPass(pasSkill, false, false)
				end
			end
		end
        for i = 1, #cfgtalen[wake-4].talenSkills do
            local pasSkill = cfgtalen[wake-4].talenSkills[i]
            if cfgskill[pasSkill].trigger == 23 then 
                for _, b in ipairs(cfgskill[pasSkill].effect) do
                    addAttr(b.type, b.num)
                end
            end
        end
    end

    -- 特殊power
    local otherPower = 0
	
	local hequips = {}
	if hero.equips then
		hequips = clone(hero.equips)
	end
	if stand then
		for i=1, #hequips do
			local eqid = hequips[i]
			local cf = cfgequip[eqid]
			if not cf or cf.pos <= 4 or cf.pos == 6 then
				hequips[i] = 0
			end
		end
		if stand.equips then
			for i=1, #stand.equips do
				local eqid = stand.equips[i]
				local cf = cfgequip[eqid]
				if cf then
					hequips[#hequips + 1] = eqid
				end
			end
		end
	end

    if hequips then
        local suits = {}
        for _, id in ipairs(hequips) do
			if id ~= 0 then
				local cfg = cfgequip[id]
				if cfg.power then
					otherPower = otherPower + cfg.power
				else
					-- 固定属性
					for i = 1, 3 do
						local attr = cfg["base" .. i]
						if attr then
							addAttr(attr.type, attr.num)
						end
					end
					-- 激活属性
					if (cfg.job and arraycontains(cfg.job, cfghero[hero.id].job))
						or (cfg.group and cfg.group == cfghero[hero.id].group) then
						for i = 1, 3 do
							local attr = cfg["act" .. i]
							if attr then
								addAttr(attr.type, attr.num)
							end
						end
					end
					-- 套装
					if cfg.form then
						local suit
						for _, s in ipairs(suits) do
							if arrayequal(s.form, cfg.form) then
								suit = s
								break
							end
						end
						if suit then
							suit.num = suit.num + 1
						else
							suits[#suits+1] = {
								form = cfg.form,
								id = id,
								num = 1,
							}
						end
					end
				end
			end
        end
        -- 套装属性
        for _, suit in ipairs(suits) do
            if suit.num > 1 then
                for i = 1, suit.num-1 do
                    local attr = cfgequip[suit.id]["suit" .. i] 
                    if attr then
                        addAttr(attr.type, attr.num)
                    end
                end
            end
        end
    end

    -- 整合
    local function v(name, nameP)
		if isReduction[name] then
			local np = 1
			if extra[name] then
				for _, p in ipairs(extra[name]) do
					np = np * ((1000 - p) / 1000)
				end
			end
			return math.floor((1 - np) * 1000 + 0.5)
		end
        local n = math.floor(base[name] or 0) + math.floor(extra[name] or 0)
        if nameP and extra[nameP] then
            for _, p in ipairs(extra[nameP]) do
                n = n + math.floor(n * p)
            end
        end
		if nameP and extra2[nameP] then
			n = n + math.floor(n * extra2[nameP])
		end
        return n
    end
	
    -- 公会科技
    local function calGskill()
        for ii=1,#gskillData.jobs[cfg.job] do
            local effects = gskillData.getBuffsEffects(gskillData.jobs[cfg.job][ii])
            if effects then
                for jj=1,#effects do
                    addAttr(jobBuff[effects[jj].type], effects[jj].num)
                end
            end
        end
    end
    if not isHeroBook then
        calGskill()
    end

    -- 计算
    local function calculate(power)
        local attribs = {
            hp = v(BUFF_HP, BUFF_HP_P),
            atk = v(BUFF_ATK, BUFF_ATK_P),
            arm = v(BUFF_ARM, BUFF_ARM_P),
            spd = v(BUFF_SPD),
            hit = v(BUFF_HIT),
            miss = v(BUFF_MISS),
            crit = v(BUFF_CRIT),
            critTime = v(BUFF_CRIT_TIME),
            sklP = v(BUFF_SKL_P),
            decDmg = v(BUFF_DEC_DMG),
            free = v(BUFF_FREE),
            trueAtk = v(BUFF_TRUE_ATK),
            brk = v(BUFF_BRK),
            power = power,
        }

        if not power then
            attribs.power = attribs.atk + attribs.arm + math.floor(attribs.hp/6) + attribs.hit 
                          + attribs.miss + attribs.crit + attribs.critTime 
                          + attribs.sklP + --[[attribs.decDmg*2 + --]]attribs.trueAtk*2
                          + otherPower
        end
        return attribs
    end

    -- 先计算一遍power: 只考虑人物属性和装备属性
    local attribs = calculate()

    -- 考虑永久属性被动技能
    local refresh
    for i = 1, 3 do
        local pasTier = cfg["pasTier" .. i]
        if not pasTier or star < pasTier then
            break
        end
        local pasSkill = cfg["pasSkill" .. i .. "Id"]
        if pasSkill then
			if addPass(pasSkill, false, true) then
				if not refresh then refresh = true end
			end
        end
    end


    -- 考虑水晶 和 宝物
    if hequips then
        for _, id in ipairs(hequips) do
			if id ~= 0 then
				local cfg = cfgequip[id]
				if cfg.power then
					for i = 1, 3 do
						local attr = cfg["base" .. i]
						if attr then
							addAttr(attr.type, attr.num)
							if not refresh then refresh = true end
						end
					end

					-- 激活属性
					if (cfg.job and arraycontains(cfg.job, cfghero[hero.id].job))
						or (cfg.group and cfg.group == cfghero[hero.id].group) then
						for i = 1, 3 do
							local attr = cfg["act" .. i]
							if attr then
								addAttr(attr.type, attr.num)
								if not refresh then refresh = true end
							end
						end
					end
				end
			end
        end
    end

    if refresh then
        return calculate(attribs.power)
    end
    return attribs
end

function helper.equipPower(id)
    local cfg = cfgequip[id]
    if cfg.power then
        return cfg.power
    end
    local v = {
        [BUFF_ATK] = 0,
        [BUFF_ARM] = 0,
        [BUFF_HP] = 0,
    }
    for i = 1, 3 do
        local attr = cfg["base" .. i]
        if attr then
            v[attr.type] = v[attr.type] + attr.num
        end
    end
    return math.floor(v[BUFF_ATK] + v[BUFF_ARM] + math.floor(v[BUFF_HP]/6))
end

function helper.isAttrib(name)
    return arraycontains(names, name)
end

return helper
