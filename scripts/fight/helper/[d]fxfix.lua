-- 战斗中特效播放的一些帮助函数

require "common.const"
require "common.func"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local i18n = require "res.i18n"
local cfgfx = require "config.fx"
local cfghero = require "config.hero"
local cfgskill = require "config.skill"

local skilltypes = {}
local ispass = {}
local isdisi = {}
local skilltohero = {}
local helper = {}

local function addSkillToHero(heroId, skillId)
	if skillId == 0 then return end
	local ls = skilltohero[skillId]
	if not ls then
		skilltohero[skillId] = { heroId }
		return
	end
	for i=1, #ls do
		if ls[i] == heroId then return end
	end
	ls[#ls + 1] = heroId
end

local function initdata()
	for id, v in pairs(cfgskill) do
		if v.kind == 1 then -- active
			if id >= 1000 and id < 3000 then
				skilltypes[id] = 2 -- active skill
			else
				skilltypes[id] = 1 -- normal attack
			end
		elseif v.kind == 2 then
			skilltypes[id] = 3 -- passive skill
		end
	end
	for id, v in pairs(cfghero) do
		if v.pasSkill1Id then
			ispass[v.pasSkill1Id] = true
			addSkillToHero(id, v.pasSkill1Id)
		end
		if v.pasSkill2Id then
			ispass[v.pasSkill2Id] = true
			addSkillToHero(id, v.pasSkill2Id)
		end
		if v.pasSkill3Id then
			ispass[v.pasSkill3Id] = true
			addSkillToHero(id, v.pasSkill3Id)
		end
		if v.atkId then
			addSkillToHero(id, v.atkId)
		end
		if v.actSkillId then
			addSkillToHero(id, v.actSkillId)
		end
		local disillusSkill = v.disillusSkill
		if disillusSkill then
			for ii=1,#disillusSkill do
				if disillusSkill[ii].disi then
					for jj=1,#disillusSkill[ii].disi do
						local nix = disillusSkill[ii].disi[jj]
						if nix then
							isdisi[nix] = true
							addSkillToHero(id, nix)
						end
					end
				end
			end
		end
	end
end
initdata()

function helper.isPasSkill(sklId)
	local r = ispass[sklId]
	if not r then r = false end
	return r
end

function helper.isDisi(sklId)
	local r = isdisi[sklId]
	if not r then r = false end
	return r
end

function helper.processSkinFx(cfg, actor, skillId)
	if not actor or not actor.skin then
        return
    end
	
	local herols = skilltohero[skillId]
	if not herols then return end
	
	local found = false
	for i=1, #herols do
		if herols[i] == actor.id then
			found = true
			break
		end
	end
	
	if found == true then
		local cfgequip = require "config.equip"
		local cfgskin = cfgequip[actor.skin]
		if not cfgskin then return end
		for _, f in ipairs({"fxSelf","fxMain1","fxMain2","fxHurt1","fxHurt2"}) do
			if cfgskin[f] then
				cfg[f] = cfgskin[f]
			end
		end
	end
end

function helper.isAttackOfAnyKind(heroId, skillId)
	local r = skilltypes[skillId]
	if r and (r == 1 or r == 2) then
		return true
	end
	if helper.isDisi(skillId) then
		return true
	end
	if helper.isPasSkill(skillId) then
		return true
	end
	return false
end

function helper.isAttack(heroId, skillId)
	local r = skilltypes[skillId]
	if r and r == 1 then
		return true
	end
	return false
end

function helper.isSkill(heroId, skillId)
	local r = skilltypes[skillId]
	if r and r == 2 then
		return true
	end
	return false
end

function helper.getExtraSkills(video, videos, idx)
	if videos and idx then
		if idx == 1 then return videos.hskills end
		if idx == 2 then return videos.hskills1 end
		if ifx == 3 then return videos.hskills2 end
		return nil
	end
	if video then
		return video.hskills
	end
	return nil
end

return helper
