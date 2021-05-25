require "common.const"
require "common.func"
local cfghero = require "config.hero"
local cfgskill = require "config.skill"
local cfgfx = require "config.fx"
local cfgbuff = require "config.buff"

local imgc = {}

local function addEffectToList(effId, fxNames, isJson)
	if not effId or effId == 0 then return end
	local fxc = cfgfx[effId]
	if not fxc then return end
	
	if fxc.name then
		fxNames[fxc.name] = true
	end
	if not isJson and fxc.resName then
		fxNames[fxc.resName] = true
	end
end

local function addSkillToList(skillDone, skillId, fxNames, isJson)
	if not skillId or skillId == 0 then return end
	if skillDone[skillId] then return end
	skillDone[skillId] = true
	local sk = cfgskill[skillId]
	if not sk then return end
	
	if sk.effect then
		for _, v in ipairs(sk.effect) do
			if v.type == "changeCombat" then
				addSkillToList(skillDone, v.num, fxNames, isJson)
			end
			local bid = buffname2id(v.type)
			if bid then
				local buf = cfgbuff[bid]
				if buf and buf.fx then
					for _, fx in ipairs(buf.fx) do
						addEffectToList(fx, fxNames, isJson)
                    end
                end
			end
		end
	end
	
	if sk.effect2 then
		for _, v in ipairs(sk.effect2) do
			if v.type == "changeCombat" then
				addSkillToList(skillDone, v.num, fxNames, isJson)
			end
			local bid = buffname2id(v.type)
			if bid then
				local buf = cfgbuff[bid]
				if buf and buf.fx then
					for _, fx in ipairs(buf.fx) do
						addEffectToList(fx, fxNames, isJson)
                    end
                end
			end
		end
	end
	
	for _, f in ipairs({"fxSelf","fxMain1","fxMain2","fxHurt1","fxHurt2"}) do
		local fxes = sk[f]
		if fxes then
			for _, fx in ipairs(fxes) do
				addEffectToList(fx, fxNames, isJson)
			end
		end
	end
	
	if sk.coSkill then
		addSkillToList(skillDone, sk.coSkill, fxNames, isJson)
	end
end

function imgc.getLoadListForFight(mapId, heroIds, hook, extraSkills, packedUnit)
    local loadlist = {}
	
	local baseDir = "images/"
	local mapDir = "maps/"
	
    -- ????, ?????????map_[mapId]_a.png, map_[mapId]_b.png??
    if mapId then
        for _, s in ipairs({"a", "b"}) do
            local name = string.format("%s%smap_%02d_%s.png", baseDir, mapDir, mapId, s)
            local path = CCFileUtils:sharedFileUtils():fullPathForFilename(name)
            if CCFileUtils:sharedFileUtils():isFileExist(path) then
                loadlist[#loadlist+1] = { texture = name, frame = name }
            end
        end
    end
    -- ????
    for _, id in ipairs(heroIds) do
        local unitResId = cfghero[id].heroBody
        loadlist[#loadlist+1] = {
            texture = baseDir .. packedUnit[unitResId] .. ".png",
            plist = baseDir .. packedUnit[unitResId] .. ".plist"
        }
    end
    -- ??????
    local fxNames = {}
    -- config.fx?id?2?3???,????,2?????buff,3????????
    if not hook then
        for id, cfg in pairs(cfgfx) do
            local pre = string.sub(id, 1, 1)
            if pre == "2" or pre == "3" then
                fxNames[cfg.name] = true
            end
        end
    end
    -- ???????
    local skArray 
    if hook then
        skArray = {"atkId"}
    else
        skArray = {"atkId","actSkillId","pasSkill1Id","pasSkill2Id","pasSkill3Id"}
    end
	local skillDone = {}
    for _, id in pairs(heroIds) do
        for _, s in ipairs(skArray) do
            local sk = cfghero[id][s]
            if sk then
				addSkillToList(skillDone, sk, fxNames, nil)
            end
        end
        -- ????????????
        if cfghero[id].disillusSkill then
            local cfgdisillusSkill = cfghero[id].disillusSkill
            for ii =1,#cfgdisillusSkill do
                local cfgdisi = cfgdisillusSkill[ii].disi
                for jj=1,#cfgdisi do
                    local sk = cfgdisi[jj]
					addSkillToList(skillDone, sk, fxNames, nil)
                end
            end
        end
    end
    -- ????
    if extraSkills then
        for i=1, #extraSkills do
			addSkillToList(skillDone, extraSkills[i], fxNames, nil)
        end
    end
    local pngNames = tablecp(fxNames)
    for fxName, _ in pairs(fxNames) do
        if fxName:endwith("_start") then
            pngNames[fxName:sub(1, -7)] = true
        elseif fxName:endwith("_loop") then
            pngNames[fxName:sub(1, -6)] = true
        elseif fxName:endwith("_end") then
            pngNames[fxName:sub(1, -5)] = true
        end
    end
    pngNames["common"] = true
    -- ??????????????png?plist
    for name, _ in pairs(pngNames) do
        local i = 1
        while true do
            local texture = baseDir .. "spine_fight_" .. name .. "_" .. i .. ".png"
            local plist = baseDir .. "spine_fight_" .. name .. "_" .. i .. ".plist"
            local fullpath = CCFileUtils:sharedFileUtils():fullPathForFilename(texture)
            if CCFileUtils:sharedFileUtils():isFileExist(fullpath) then
                loadlist[#loadlist+1] = { texture = texture, plist = plist }
                i = i + 1
            else 
                break
            end
        end
    end

    return loadlist
end

function imgc.getLoadListForFightJson(heroIds, hook, extraSkills, unit, fight)
    local loadlist = {}
    -- ????
    for _, id in ipairs(heroIds) do
        local unitResId = cfghero[id].heroBody
        loadlist[#loadlist+1] = unit[unitResId]
        if cfghero[id].anims then
            for i =1,#cfghero[id].anims do
                local jsonname = "spinejson/unit/" .. cfghero[id].anims[i] .. ".json"
                loadlist[#loadlist+1] = jsonname
            end
        end
    end

    -- ??????
    local fxNames = {}
    -- config.fx?id?2?3???,????,2?????buff,3????????
    if not hook then
        for id, cfg in pairs(cfgfx) do
            local pre = string.sub(id, 1, 1)
            if pre == "2" or pre == "3" then
                fxNames[cfg.name] = true
            end
        end
    end
    -- ???????
    local skArray 
    if hook then
        skArray = {"atkId"}
    else
        skArray = {"atkId","actSkillId","pasSkill1Id","pasSkill2Id","pasSkill3Id"}
    end
	local skillDone = {}
    for _, id in pairs(heroIds) do
        for _, s in ipairs(skArray) do
            local sk = cfghero[id][s]
            if sk then
				addSkillToList(skillDone, sk, fxNames, true)
            end
        end
    end
    -- ??????????????json
    if extraSkills then
        for i=1, #extraSkills do
			addSkillToList(skillDone, extraSkills[i], fxNames, true)
        end
    end
    for fxName, _ in pairs(fxNames) do
        loadlist[#loadlist+1] = "spinejson/fight/" .. fxName .. ".json"
    end
    -- ??
    for _, p in pairs(fight) do
        loadlist[#loadlist+1] = p
    end

    return loadlist
end

return imgc