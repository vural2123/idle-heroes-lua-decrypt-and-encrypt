local loadout = { arr = {} }

require "common.func"
local cfghero = require "config.hero"
local cfgequip = require "config.equip"
local i18n = require "res.i18n"

--[[
local params = {
	id = 1, -- id of loadout
	icon = 18, -- icon of loadout
	stand = {
		[3] = { -- pos is 3
			hid = 1,
			equip = { 1200, 1300 },
			skills = { 6101, 6102 },
		}
	}
	petID = -1,
}
--]]

local g_equipMap = nil

local function getStandCount(stand)
	local ss = 0
	if stand then
		for i=1, 6 do
			if stand[i] then ss = ss + 1 end
		end
	end
	return ss
end

-- this returns ID not equip itself!!!
function loadout.getEquip(uid)
	if not g_equipMap then
		g_equipMap = {}
		for id, v in pairs(cfgequip) do
			if v.uid then
				g_equipMap[v.uid] = id
			end
		end
	end
	
	if uid then
		return g_equipMap[uid]
	end
	return nil
end

-- unpack is received from server
-- return instance, newIndex
function loadout.unpack(pbarr, index)
	local temp = pbarr[index]
	index = index + 1
	local v = {}
	v.stand = {}
	v.id = bit.brshift(temp, 26)
	v.icon = bit.band(bit.brshift(temp, 10), 0xFFFF)
	if v.icon >= 25536 and v.icon < 40000 then
		v.icon = v.icon + 40000
	end
	if v.icon == 0 then
		v.icon = 1101
	end
	v.petID = bit.band(bit.brshift(temp, 6), 0xF)
	if v.petID ~= 0 then
		v.petID = v.petID * 100 + 1
	end
	local hasmask = bit.band(temp, 0x3F)
	for i=1, 6 do
		local hasbit = bit.blshift(1, i - 1)
		if bit.band(hasmask, hasbit) ~= 0 then
			local s = {}
			s.skills = {}
			s.equips = {}
			local hid = pbarr[index]
			index = index + 1
			local skilldata = pbarr[index]
			index = index + 1
			for j=1, 3 do
				local skillId = bit.band(bit.brshift(skilldata, 10 * (j - 1)), 0x3FF)
				if skillId ~= 0 then
					skillId = skillId + 6100
					s.skills[j] = skillId
				end
			end
			s.hid = hid
			local equip1 = pbarr[index]
			index = index + 1
			local equip2 = pbarr[index]
			index = index + 1
			for j=1, 6 do -- equip!
				local ms
				if j <= 3 then ms = equip1 else ms = equip2 end
				ms = bit.brshift(ms, ((j - 1) % 3) * 10)
				ms = bit.band(ms, 0x3FF)
				if ms ~= 0 then
					local eqid = loadout.getEquip(ms)
					if eqid then
						s.equips[#s.equips + 1] = eqid
					end
				end
			end
			v.stand[i] = s
		end
	end
	return v, index
end

function loadout.pack(v)
	local pba = {}
	local data = bit.blshift(v.id, 26)
	local icon = v.icon
	if icon >= 0x10000 then
		icon = icon - 40000
	end
	icon = bit.blshift(icon, 10)
	data = bit.bor(data, icon)
	local pet = math.max(0, v.petID or 0)
	pet = math.floor(pet / 100)
	pet = bit.blshift(pet, 6)
	data = bit.bor(data, pet)
	local has = 0
	for i=1, 6 do
		if v.stand[i] then
			has = bit.bor(has, bit.blshift(1, i - 1))
		end
	end
	data = bit.bor(data, has)
	pba[#pba + 1] = data
	
	for i=1, 6 do
		local stand = v.stand[i]
		if stand then
			local hid = stand.hid
			local skilldata = 0
			local eqdata1 = 0
			local eqdata2 = 0
			for j=1, 3 do
				if stand.skills and stand.skills[j] then
					local skillId = stand.skills[j]
					if skillId >= 6100 and skillId < 7000 then
						skillId = skillId - 6100
						skillId = bit.blshift(skillId, (j - 1) * 10)
						skilldata = bit.bor(skilldata, skillId)
					end
				end
			end
			if stand.equips then
				local ix = 0
				for j=1, math.min(#stand.equips, 6) do
					local eqid = stand.equips[j]
					local cf = cfgequip[eqid]
					if cf and cf.uid and cf.uid > 0 then
						local uidmask = bit.blshift(cf.uid, (ix % 3) * 10)
						if ix < 3 then
							eqdata1 = bit.bor(eqdata1, uidmask)
						else
							eqdata2 = bit.bor(eqdata2, uidmask)
						end
						ix = ix + 1
					end
				end
			end
			pba[#pba + 1] = hid
			pba[#pba + 1] = skilldata
			pba[#pba + 1] = eqdata1
			pba[#pba + 1] = eqdata2
		end
	end
	
	return pba
end

function loadout.getStand(hid, loadoutid)
	local ld = loadout.get(loadoutid)
	if ld then
		for i=1, 6 do
			if ld.stand[i] and ld.stand[i].hid == hid then
				return ld.stand[i]
			end
		end
	end
end

function loadout.isEquipPos(pos)
	if pos >= 1 and pos <= 4 then return true end
	if pos == 6 then return true end
	return false
end

function loadout.getActualArti(hid, loadoutid)
	local eqarr = loadout.getActualEquips(hid, loadoutid)
	for _, v in ipairs(eqarr) do
		local cf = cfgequip[v]
		if cf and cf.pos == 6 then return v end
	end
end

function loadout.getActualEquips(hid, loadoutid)
	local eqmap = {}
	local heroData = require("data.heros").find(hid)
	local stand = loadout.getStand(hid, loadoutid)
	if heroData and heroData.equips then
		for _, eqid in ipairs(heroData.equips) do
			local cf = cfgequip[eqid]
			if cf then
				if not stand or not loadout.isEquipPos(cf.pos) then
					eqmap[cf.pos] = eqid
				end
			end
		end
	end
	if stand and stand.equips then
		for _, eqid in ipairs(stand.equips) do
			local cf = cfgequip[eqid]
			if cf then
				eqmap[cf.pos] = eqid
			end
		end
	end
	local eqarr = {}
	for pos, eqid in pairs(eqmap) do
		eqarr[#eqarr + 1] = eqid
	end
	return eqarr
end

function loadout.getActualSkills(hid, loadoutid)
	local skills = {}
	local stand = loadout.getStand(hid, loadoutid)
	if stand then
		for i=1, 3 do
			if stand.skills and stand.skills[i] then
				skills[i] = stand.skills[i]
			end
		end
		return skills
	end
	local heroData = require("data.heros").find(hid)
	if heroData and heroData.skills then
		for i=1, 3 do
			if heroData.skills and heroData.skills[i] then
				skills[i] = heroData.skills[i]
			end
		end
		return skills
	end
	return skills
end

function loadout.getAllEquips()
	local bag = require "data.bag"
	local heros = require "data.heros"
	local equips = {}
	if bag.equips then
		for _, v in ipairs(bag.equips) do
			equips[v.id] = (equips[v.id] or 0) + v.num
		end
	end
	for _, v in ipairs(heros) do
		if v.equips then
			for k, id in ipairs(v.equips) do
				equips[id] = (equips[id] or 0) + 1
			end
		end
	end
	return equips
end

function loadout.getAllEquipsChoice(content, unitPos)
	local all = loadout.getAllEquips()
	for _, v in pairs(content.stand) do
		if not unitPos or unitPos ~= _ then
			if v.equips then
				for _, id in ipairs(v.equips) do
					local has = all[id]
					if has and has > 0 then
						all[id] = has - 1
					end
				end
			end
		end
	end
	return all
end

function loadout.checkValid(id)
	local v = loadout.get(id)
	if not v then
		return 999
	end
	return loadout.checkValidMulti({ v })
end

local function checkSkin(heroId, equipId)
	local cf = cfgequip[equipId]
	if not cf or not cf.pos then return false end
	if cf.pos ~= 7 then return true end
	local ch = cfghero[heroId]
	if not ch or not cf.skinId then return false end
	for _, v in ipairs(cf.skinId) do
		if v == equipId then return true end
	end
	return false
end

function loadout.showValidError(code)
	if not code then
		showToast("error: failed to fail")
		return
	end
	
	if code == 999 then
		showToast("error: 999")
		return
	end
	
	if code == 1 then
		showToast(i18n.global.empty_herolist.string)
		return
	end
	
	if code == 2 then
		showToast(i18n.global.toast_selhero_selected.string)
		return
	end
	
	if code == 3 or code == 4 or code == 6 then
		showToast(i18n.global.empty_equips.string)
		return
	end
	
	if code == 5 then
		showToast(i18n.global.gskill_reset_learn.string)
		return
	end
	
	if code == 7 or code == 8 then
		showToast(i18n.global.pet_battle_doc.string)
		return
	end
	
	showToast("error: " .. code)
end

function loadout.checkValidMulti(instances)
	-- 0 = ok
	-- 1 = hero missing
	-- 2 = hero duplicate
	-- 3 = equip missing
	-- 4 = equip duplicate
	-- 5 = skill error
	-- 6 = skin error
	-- 7 = pet missing
	-- 8 = pet duplicate
	-- 999 = other error (completely missing loadout usually)
	local needEquip = {}
	local needHero = {}
	local needPet = {}
	local heros = require "data.heros"
	for _i, v in ipairs(instances) do
		if not v or not v.stand or getStandCount(v.stand) == 0 then return 999 end
		if v.petID then
			if needPet[v.petID] then return 8 end
			needPet[v.petID] = true
		end
		for _j, x in pairs(v.stand) do
			if needHero[x.hid] then return 2 end
			local reqWake = 0
			local highSkill = 0
			if x.skills then
				for i=1,3 do
					if x.skills[i] and x.skills[i] > 0 then
						highSkill = i
					end
				end
			end
			if highSkill > 0 then
				reqWake = 4 + highSkill
				local needSkills = {}
				for _l, z in pairs(x.skills) do
					if z ~= 6100 then
						if needSkills[z] then return 5 end
						needSkills[z] = true
					end
				end
			end
			
			local h = heros.find(x.hid)
			if not h then return 1 end
			if reqWake > 0 and (not h.wake or h.wake < reqWake) then return 5 end
			
			needHero[x.hid] = true
			if x.equips then
				for _k, y in ipairs(x.equips) do
					if not checkSkin(h.id, y) then return 6 end
					needEquip[y] = (needEquip[y] or 0) + 1
				end
			end
		end
	end
	
	local bag = require "data.bag"
	if bag.equips then
		local newNeed = {}
		for _, v in ipairs(bag.equips) do
			local need = needEquip[v.id]
			if need then
				newNeed[v.id] = need - v.num
			end
		end
		for k, v in pairs(newNeed) do
			if v > 0 then
				needEquip[k] = v
			else
				needEquip[k] = nil
			end
		end
	end
	
	for _, v in ipairs(heros) do
		if v.equips then
			for _i, x in ipairs(v.equips) do
				local need = needEquip[x]
				if need then
					need = need - 1
					if need > 0 then
						needEquip[x] = need
					else
						needEquip[x] = nil
					end
				end
			end
		end
	end
	
	for _, v in pairs(needEquip) do
		return 3
	end
	
	local petData = require "data.pet"
	
	for k, v in pairs(needPet) do
		if k > 0 then
			local pet = petData.getData(k)
			if not pet then return 7 end
		end
	end
	
	return 0
end

local SQUAD_TYPES = {
    [1] = "Normal",
    [2] = "Trial",
    [3] = "Arenaatk",
    [4] = "Arenadef",
    [5] = "FrdArena",
    [6] = "GuildBoss",
    [7] = "DailyFight",
    [8] = "Friend",
    [9] = "guildmill",
    [10] = "guildmilldef",
    [11] = "_GuildFight",
    [12] = "Frdpk",
    [13] = "Brokenboss",
    [14] = "Sweepforbrokenboss",
    [15] = "Arena3v3Def",
    [16] = "Arena3v3Atk",
    [17] = "Airisland",
    [18] = "Sweepforairisland",
    [19] = "GuildGray",
    [20] = "Sweepforfboss",
    [21] = "Sweepforcomisland",
    [22] = "FrdArenac",
    [23] = "Arenabatk",
    [24] = "Arenabdef",
}

function loadout.init(pbs, sline)
    loadout.arr = {}
	loadout.squad = {}
    if not pbs or #pbs == 0 then return end
	
	local idx = 1
	local cnt = #pbs
	
	for i=1, cnt do
		local val = pbs[i]
		if val < 0 then
			val = bit.band(val, 0x7FFFFFFF) + 0x80000000
			pbs[i] = val
		end
	end
	
	while idx <= cnt do
		local v, nextIdx = loadout.unpack(pbs, idx)
		idx = nextIdx
		loadout.add(v)
	end
	
	for i, name in pairs(SQUAD_TYPES) do
		local ss = sline[i]
		if ss and ss > 0 then
			loadout.squad[name] = ss
		end
	end
end

function loadout.getSquad(name)
	if loadout.squad then
		local sel = loadout.squad[name]
		if sel and sel > 0 then return sel end
	end
end

function loadout.setSquad(name, id)
	if not loadout.squad then return end
	if not id then id = 0 end
	if id > 0 then
		loadout.squad[name] = id
	else
		loadout.squad[name] = nil
	end
end

function loadout.get(id)
	if loadout.arr then
		return loadout.arr[id]
	end
	return nil
end

function loadout.del(id)
	if loadout.arr then
		loadout.arr[id] = nil
	end
end

function loadout.add(v)
	if not loadout.arr then
		loadout.arr = {}
	end
	loadout.arr[v.id] = v
end

return loadout
