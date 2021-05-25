local gskill = {}

local cfgguildskill = require "config.guildskill"

local SkillType = {
    JOB1 = 1,
    JOB2 = 2,
    JOB3 = 3,
    JOB4 = 4,
    JOB5 = 5,
}
gskill.SkillType = SkillType

local jobs = {}
gskill.jobs = jobs

local function ssort(a, b)
    return a.idx < b.idx
end

function gskill.init()
    jobs = {}
    gskill.jobs = jobs
    for idx,skill in pairs(cfgguildskill) do
        cfgguildskill[idx].idx = idx
        cfgguildskill[idx].lv = 0
        local stype = cfgguildskill[idx].type
        if not jobs[stype] then
            jobs[stype] = {}
        end
        local _tbl = jobs[stype]
        _tbl[#_tbl+1] = cfgguildskill[idx]
    end
    for ii=1,5 do
        table.sort(jobs[ii], ssort)
    end
end

function gskill.initCode(code)
    code = code or 0
    gskill.code = code
end

-- -b: 1, 2, 4, 8, 16
function gskill.getCode(_b)
    if not gskill.code then return 0 end
    if _b == bit.band(_b, gskill.code) then return 1 end 
    return 0
end

function gskill.setCode(_b)
    if not gskill.code then 
        gskill.code = _b
        return
    end
    if _b == bit.band(_b, gskill.code) then 
        return
    end 
    gskill.code = gskill.code + _b
end

function gskill.resetJob(which)
    for k,v in ipairs(gskill.jobs[which]) do
        gskill.jobs[which][k].lv = 0
    end
    gskill.setCode(math.pow(2, which-1))
end

function gskill.sync(skls)
    gskill.init()
    if not skls or #skls <= 0 then return end
    for ii=1,#skls do
        cfgguildskill[skls[ii].id].lv = skls[ii].lv
    end
end

function gskill.isLearned(which)
    if not which then return false end
    local t_id = which*1000 + 101
    if not cfgguildskill[t_id] then return false end
    if cfgguildskill[t_id].lv > 0 then return true end
    return false
end

function gskill.isLighten(_id)
    if not cfgguildskill[_id].preSkl then return true end
    local _pre_id = cfgguildskill[_id].preSkl
    if cfgguildskill[_pre_id].lv and cfgguildskill[_pre_id].lv >= cfgguildskill[_id].lvReq then
        return true
    end
    return false
end

function gskill.testLock(_id)
    if not cfgguildskill[_id].preSkl then return false end
    local _pre_id = cfgguildskill[_id].preSkl
    if cfgguildskill[_pre_id].lv and cfgguildskill[_pre_id].lv == cfgguildskill[_id].lvReq then
        return true
    end
    return false
end

function gskill.isFull(skillObj)
    return skillObj.lv >= skillObj.lvMax
end

function gskill.getBuffs(skillObj)
    local buffs = {}
    local base_buffs = {}
    local base_effects = skillObj.baseEffect
    for ii=1,#base_effects do
        local _n, _v = buffString(base_effects[ii].type, base_effects[ii].num)
        base_buffs[ii] = {}
        base_buffs[ii].name = _n
        base_buffs[ii].value = _v
    end
    if skillObj.lv <= 0 then
        buffs = base_buffs
        for ii=1,#buffs do
            buffs[ii].gvalue = buffs[ii].value
            buffs[ii].value = 0
        end
    else
        local effects = skillObj.growEffect
        for ii=1,#effects do
            local _n, _v = buffString(effects[ii].type, base_effects[ii].num+effects[ii].num*(skillObj.lv-1))
            buffs[ii] = {}
            buffs[ii].name = _n
            buffs[ii].value = _v
            if gskill.isFull(skillObj) then
                buffs[ii].gvalue = nil
            else
                local g_n, g_v = buffString(effects[ii].type, base_effects[ii].num+effects[ii].num*(skillObj.lv-0))
                buffs[ii].gvalue = g_v
            end
        end
    end
    return buffs
end

function gskill.getBuffsEffects(skillObj)
    local buffs = {}
    local base_buffs = {}
    local base_effects = skillObj.baseEffect
    for ii=1,#base_effects do
        --local _n, _v = buffString(base_effects[ii].type, base_effects[ii].num)
        base_buffs[ii] = {}
        base_buffs[ii].type= base_effects[ii].type
        base_buffs[ii].num = base_effects[ii].num
    end
    if skillObj.lv <= 0 then
        buffs = base_buffs
        for ii=1,#buffs do
            buffs[ii].num = 0
        end
    else
        local effects = skillObj.growEffect
        for ii=1,#effects do
            buffs[ii] = {}
            buffs[ii].type = effects[ii].type
            buffs[ii].num = base_effects[ii].num+effects[ii].num*(skillObj.lv-1)
        end
    end
    return buffs
end

function gskill.getCost(skillObj)
    local coin_cost, gcoin_cost = 0, 0
    if skillObj.lv <= 0 then
        coin_cost = skillObj.baseGold
        gcoin_cost = skillObj.baseGuildCoin
    else
        coin_cost = skillObj.baseGold + (skillObj.lv-0)*skillObj.growGold
        gcoin_cost = skillObj.baseGuildCoin + (skillObj.lv-0)*skillObj.growGuildCoin
    end
    return coin_cost, gcoin_cost
end

return gskill
