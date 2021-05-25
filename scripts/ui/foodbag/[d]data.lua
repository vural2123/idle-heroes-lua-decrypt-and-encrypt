-- heros info

local heros = { arr = {} }

require "common.func"
local cfghero = require "config.hero"

function heros.isValid(id)
	local hero = cfghero[id]
	if hero and hero.maxStar and hero.maxStar >= 3 and hero.maxStar <= 6 and ((hero.showInGuide and hero.showInGuide > 0) or hero.isPuppet) then
		if hero.maxStar > 5 then
			if require("data.player").isMod(1) then
				return false
			end
		end
		return true
	end
	return false
end

function heros.getTotalFood()
	local count = 0
	for _, v in pairs(heros.arr) do
		count = count + v.count
	end
	return count
end

function heros.matchFood(heroId, fodderReqId, mustMarked)
	if heroId == fodderReqId then
		return true
	end
	if (fodderReqId % 100) == 99 and (not mustMarked or heros.hasFlag(heroId, 1)) then
		local h = cfghero[heroId]
		if h then
			local reqStar = math.floor(fodderReqId / 1000)
			local reqFaction = math.floor(fodderReqId / 100) % 10
			if reqFaction ~= 9 and h.group ~= reqFaction then
				return false
			end
			if h.maxStar ~= reqStar then
				return false
			end
			return true
		end
	end
	return false
end

function heros.matchHero(heroId, wake, fodderReqId, mustMarked)
	if heroId == fodderReqId then
		if not wake or wake == 4 then
			return true
		end
		return false
	end
	if (fodderReqId % 100) == 99 and (not mustMarked or heros.hasFlag(heroId, 1)) then
		local h = cfghero[heroId]
		if h then
			local reqStar = math.floor(fodderReqId / 1000)
			local reqFaction = math.floor(fodderReqId / 100) % 10
			if reqFaction ~= 9 and h.group ~= reqFaction then
				return false
			end
			local haveStar = h.maxStar
			if haveStar == 10 then
				haveStar = 999
				if wake then
					haveStar = wake + 6
				end
			elseif haveStar == 6 then
				haveStar = 6
				if wake then
					haveStar = wake + 6
				end
			end
			if haveStar ~= reqStar then
				return false
			end
			return true
		end
	end
	return false
end

local function sortForDecompose(a, b)
	if a.hid >= 0 and b.hid >= 0 and a.id ~= b.id then
		return a.id < b.id
	end
	local alock = 0
	local block = 0
	if a.lock and a.lock ~= 0 then
		alock = 1
	end
	if b.lock and b.lock ~= 0 then
		block = 1
	end
	if alock ~= block then
		return alock < block
	end
	if a.level ~= b.level then
		return a.level < b.level
	end
	local awake = 0
	local bwake = 0
	if a.wake then awake = a.wake end
	if b.wake then bwake = b.wake end
	if awake ~= bwake then
		return awake < bwake
	end
	if a.hid < 0 and b.hid < 0 then
		return b.hid < a.hid
	end
	return a.hid < b.hid
end

local function sortForHost(a, b)
	return sortForDecompose(b, a)
end

local function sortForDecomposeShow(a, b)
	local aid = a.id
	local bid = b.id
	if aid and bid and aid ~= bid then
		return aid < bid
	end
	local alock = 0
	local block = 0
	if a.lock and a.lock ~= 0 then
		alock = 1
	end
	if b.lock and b.lock ~= 0 then
		block = 1
	end
	if alock ~= block then
		return alock < block
	end
	if a.level ~= b.level then
		return a.level < b.level
	end
	local awake = 0
	local bwake = 0
	if a.wake then awake = a.wake end
	if b.wake then bwake = b.wake end
	if awake ~= bwake then
		return awake < bwake
	end
	return a.hid < b.hid
end

local function sortForHostShow(a, b)
	return sortForDecomposeShow(b, a)
end

function heros.sortList(herolist, isHost)
	if not herolist or #herolist < 1 then return end
	if isHost then
		table.sort(herolist, sortForHost)
	else
		table.sort(herolist, sortForDecompose)
	end
end

function heros.sortListShow(herolist, isHost)
	if not herolist or #herolist < 1 then return end
	if isHost then
		table.sort(herolist, sortForHostShow)
	else
		table.sort(herolist, sortForDecomposeShow)
	end
end

function heros.getBestFodder(reqId, count, isHost, allowHero, allowFood, notThis, mode, forceThis)
	local fodder = {}
	
	-- mode
	-- 1 = quick check if can fuse
	-- 2 = auto-fill fodder
	-- 3 = show select menu
	
	local allowLocked = false
	local mustMarked = false
	local isQuickCheck = false
	local absMax = 100
	local curc = 0
	
	if mode == 1 then
		allowLocked = true
		isQuickCheck = true
	elseif mode == 2 then
		mustMarked = true
	elseif mode == 3 then
		allowLocked = true
	end
	
	if isQuickCheck then
		absMax = count
	end
	
	if not notThis then
		notThis = {}
	end
	
	if not forceThis then
		forceThis = {}
	end
	
	local hbag = require("data.heros")
	if allowHero then
		for _, v in ipairs(hbag) do
			if heros.matchHero(v.id, v.wake, reqId, mustMarked) then
				local lock = nil
				if v.flag and v.flag > 0 then
					lock = 1
				end
				if (not lock or allowLocked) and (not v.hskills or allowLocked) and not notThis[v.hid] then
					fodder[curc + 1] = { hid = v.hid, id = v.id, level = v.lv, wake = v.wake, lock = lock }
					curc = curc + 1
					if curc >= absMax then
						break
					end
				end
			end
		end
	end
	
	if allowFood and curc < absMax then
		for id, v in pairs(heros.arr) do
			if v.count > 0 and heros.matchFood(id, reqId, mustMarked) then
				local dont = notThis[-id] or 0
				if dont < v.count then
					local want = math.min(v.count - dont, count)
					want = math.min(want, absMax - curc)
					for i=1, want do
						fodder[curc + 1] = { hid = -id, id = id, level = 0, wake = nil }
						curc = curc + 1
					end
					if curc >= absMax then
						break
					end
				end
			end
		end
	end
	
	if not isQuickCheck then
		if mode == 3 then
			heros.sortListShow(fodder, isHost)
		else
			heros.sortList(fodder, isHost)
		end
		
		if curc > count then
			local tfodder = {}
			for i=1, count do
				tfodder[i] = fodder[i]
			end
			fodder = tfodder
		end
		
		local forceCount = 0
		for _, v in pairs(forceThis) do
			forceCount = forceCount + 1
		end
		
		if forceCount > 0 then
			for _, v in ipairs(fodder) do
				local xcn = forceThis[v.hid]
				if xcn then
					if xcn == 1 then
						forceThis[v.hid] = nil
						forceCount = forceCount - 1
						if forceCount == 0 then break end
					else
						forceThis[v.hid] = xcn - 1
					end
				end
			end
			
			for hid, cnt in pairs(forceThis) do
				if hid < 0 then
					for i=1, cnt do
						fodder[#fodder + 1] = { hid = hid, id = -hid, level = 0, wake = nil }
					end
				else
					local hdat = hbag.find(hid)
					if hdat then
						local lock = nil
						--if hdat.flag and hdat.flag > 0 then lock = 1 end
						fodder[#fodder + 1] = { hid = hid, id = hdat.id, level = hdat.lv, wake = hdat.wake, lock = lock }
					end
				end
			end
		end
	end
	return fodder
end

function heros.appendNotThis(chosen, notThis, fromGetBest)
	if fromGetBest then
		for _, v in ipairs(chosen) do
			local hid = v.hid
			if hid >= 0 or not notThis[hid] then
				notThis[hid] = 1
			else
				notThis[hid] = notThis[hid] + 1
			end
		end
	else
		for _, hid in ipairs(chosen) do
			if hid >= 0 or not notThis[hid] then
				notThis[hid] = 1
			else
				notThis[hid] = notThis[hid] + 1
			end
		end
	end
end

function heros.init(pbs)
    heros.arr = {}
	
	for id, v in pairs(cfghero) do
		if heros.isValid(id) then
			heros.arr[id] = { count = 0, flags = 0 }
		end
	end
	
    if not pbs then return end
	local idx = 1
	local cnt = #pbs
	while idx + 2 <= cnt do
		local id = pbs[idx]
		local x = heros.arr[id]
		if x then
			x.count = pbs[idx + 1]
			x.flags = pbs[idx + 2]
		end
		idx = idx + 3
	end
end

function heros.modCount(id, amt)
	if not amt or amt == 0 then return end
	local h = heros.arr[id]
	if h then
		h.count = h.count + amt
	end
end

function heros.getCount(id)
	local h = heros.arr[id]
	if h then
		return h.count
	end
	return 0
end

function heros.modFlag(id, flag, yes)
	local flags = heros.getFlag(id)
	if yes then
		if bit.band(flags, flag) == 0 then
			flags = flags + flag
		end
	else
		if bit.band(flags, flag) == flag then
			flags = flags - flag
		end
	end
	heros.setFlag(id, flags)
end

function heros.getToggledFlags(id, flags)
	local cfg = cfghero[id]
	if cfg then
		--if cfg.maxStar < 5 or (cfg.maxStar == 5 and id >= 6000) then
		if cfg.isGenericFood then
			if bit.band(flags, 1) == 1 then
				flags = flags - 1
			else
				flags = flags + 1
			end
		end
	end
	return flags
end

function heros.setFlag(id, flag)
	local h = heros.arr[id]
	if h then
		h.flags = heros.getToggledFlags(id, flag)
	end
end

function heros.getFlag(id)
	local h = heros.arr[id]
	if h then
		return heros.getToggledFlags(id, h.flags)
	end
	return 0
end

function heros.hasFlag(id, flag)
	local flags = heros.getFlag(id)
	if bit.band(flags, flag) ~= 0 then
		return true
	end
	return false
end

return heros
