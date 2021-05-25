local helper = {}

require "common.func"
local hHelper = require "fight.helper.hero"

function helper.processCamp(video, camp, sourceType, targetType)
	-- sourceType
	-- 1 = normal, 1-12 are units, 13-14 are pets
	-- 2 = pvp, atk and def already have camps but we must remove the pet and put it in pet slot
	
	-- targetType
	-- 1 = normal video.atk.camp, video.atk.pet, video.def.camp, video.def.pet
	
	if not sourceType then sourceType = 1 end
	if not targetType then targetType = 1 end
	if not camp then camp = video.camp end
	
	if not video.atk then
		video.atk = { camp = {} }
	elseif not video.atk.camp then
		video.atk.camp = {}
	end
	if not video.def then
		video.def = { camp = {} }
	elseif not video.def.camp then
		video.def.camp = {}
	end
	
	if sourceType == 1 then
		for _, v in pairs(camp) do
			if v.pos <= 6 then
				video.atk.camp[#video.atk.camp + 1] = v
				v.isAttacker = true
			elseif v.pos <= 12 then
				video.def.camp[#video.def.camp + 1] = v
			elseif v.pos == 13 then
				video.atk.pet = v
				v.isPet = true
				v.isAttacker = true
			elseif v.pos == 14 then
				video.def.pet = v
				v.isPet = true
			end
		end
	elseif sourceType == 2 then
		camp = {}
		local rem = nil
		for _, v in pairs(video.atk.camp) do
			if v.pos == 7 then
				rem = _
				video.atk.pet = v
				v.isPet = true
			end
			v.isAttacker = true
			local cv = clone(v)
			if cv.isPet then cv.pos = 13 end
			camp[#camp + 1] = cv
		end
		if rem then
			table.remove(video.atk.camp, rem)
		end
		rem = nil
		for _, v in pairs(video.def.camp) do
			if v.pos == 7 then
				rem = _
				video.def.pet = v
				v.isPet = true
			end
			local cv = clone(v)
			if cv.isPet then cv.pos = 14 else cv.pos = cv.pos + 6 end
			camp[#camp + 1] = cv
		end
		if rem then
			table.remove(video.def.camp, rem)
		end
	end
	
	if not video.camp then
		video.camp = camp
	end
end

function helper.getResources(video)
	local heroIds = {}
	local pets = {}
	local skins = {}
	
	for _, v in pairs(video.camp) do
		if v.isPet then
			pets[#pets + 1] = v
		else
			if v.skin and v.skin > 0 then
				skins[#skins + 1] = v.skin
			end
			heroIds[#heroIds + 1] = v.id
		end
	end
	return heroIds, pets, skins
end

function helper.getVideoAndUnits(video)
	local attackers = {}
	local defenders = {}
	for i, h in ipairs(video.camp) do
		if not h.isPet then
			local pos = h.pos
			local side = nil
			local size = "small"
			if h.extraflags and bit.band(h.extraflags, 1) ~= 0 then
				size = "large"
			end
			if h.isAttacker then
				if pos >= 7 then pos = pos - 6 end
				side = "attacker"
			else
				if pos <= 6 then pos = pos + 6 end
				side = "defender"
			end
			local hpp = nil
			if h.hpp then
				hpp = h.hpp
			elseif h.hp then
				hpp = h.hp
			end
			local unit = hHelper.createHero({
				id = h.id, heroId = h.id, lv = h.lv, hp = hpp, ep = h.energy, size = size, skin = h.skin, pos = pos, side = side, wake = h.wake, star = h.star
			})
			if h.isAttacker then
				attackers[#attackers + 1] = unit
			else
				defenders[#defenders + 1] = unit
			end
		end
	end
	return video, attackers, defenders
end

return helper