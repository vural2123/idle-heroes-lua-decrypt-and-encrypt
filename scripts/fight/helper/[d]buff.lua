-- buff的一些帮助函数

local helper = {}

require "common.func"
require "common.const"
local cfgbuff = require "config.buff"

local dots = {BUFF_DOT, BUFF_DOT_FIRE, BUFF_DOT_POISON, BUFF_DOT_BLOOD, BUFF_DOT_THU, BUFF_DOT_SHADOWF, BUFF_DOT_BLAST, BUFF_ATK_TRUEHURT}
local dmgs = { BUFF_HURT, BUFF_TRUE_HURT, }
local heals = { BUFF_HEAL, }
local controls = {BUFF_STUN, BUFF_STONE, BUFF_ICE, BUFF_FORBID, BUFF_WEAK, BUFF_FEAR, BUFF_HPBELOW_FEAR, BUFF_WIND} 
local roots = { BUFF_STUN, BUFF_STONE, BUFF_ICE, } 
local impresses = {BUFF_RIMPRESS, BUFF_CIMPRESS, BUFF_FIMPRESS, BUFF_OIMPRESS, BUFF_KIMPRESS, BUFF_SIMPRESS, BUFF_BALANCE, BUFF_CUREPRESS, BUFF_SEEDPRESS, "decShield"}
local impressesB = {"cImpressB", "rImpressB", "balanceB", "curepressB", "seedpressB"}

function helper.id(name)
    if name then
        return buffname2id(name)
    end
    return nil
end

function helper.name(id)
    if id and cfgbuff[id] then
        return cfgbuff[id].name 
    end
    return nil
end

function helper.isAttrib(name)
    return require("fight.helper.attr").isAttrib(name)
end

function helper.isAttribId(id)
    return cfgbuff[id] and helper.isAttrib(cfgbuff[id].name)
end

function helper.isDot(name)
    return arraycontains(dots, name)
end

function helper.isDotId(id)
    return cfgbuff[id] and arraycontains(dots, cfgbuff[id].name)
end

function helper.isDmg(name)
    return arraycontains(dmgs, name)
end

function helper.isDmgId(id)
    return cfgbuff[id] and arraycontains(dmgs, cfgbuff[id].name)
end

function helper.isHeal(name)
    return arraycontains(heals, name)
end

function helper.isHealId(id)
    return cfgbuff[id] and arraycontains(heals, cfgbuff[id].name)
end

function helper.isControl(name)
    return arraycontains(controls, name)
end

function helper.isControlId(id)
    return cfgbuff[id] and arraycontains(controls, cfgbuff[id].name)
end

function helper.isImpress(name)
    return arraycontains(impresses, name)
end

function helper.isImpressB(name)
    return arraycontains(impressesB, name)
end

function helper.isImpressId(id)
    return cfgbuff[id] and arraycontains(impresses, cfgbuff[id].name)
end

function helper.isRoot(name)
    return arraycontains(roots, name)
end

function helper.isRootId(id)
    return cfgbuff[id] and arraycontains(roots, cfgbuff[id].name)
end

-- 添加buff
function helper.add(unit, id, value)
    if true then  -- 印记类可叠加
        for ii=1,#unit.buffs do
            local _b = unit.buffs[ii]
            if _b.id == id then
                _b.count = (_b.count or 1) + 1
                return
            end
        end
        -- 没找到
        unit.buffs[#unit.buffs+1] = { id = id, name = cfgbuff[id].name, value = value or 0, count = 1 }
    elseif not arraycontains(helper.states(unit), cfgbuff[id].name) then
        unit.buffs[#unit.buffs+1] = { id = id, name = cfgbuff[id].name, value = value or 0 }
    end
end

-- 移除buff，属性类只能移除同向的（正或负）
function helper.del(unit, id, value)
    for i, b in ipairs(unit.buffs) do
        if b.id == id and (not helper.isAttrib(b.name) or b.value * value > 0) then
            if b.count and b.count > 0 then   -- 叠加类印记buff
                b.count = b.count - 1 
                if b.name == BUFF_CIMPRESS or b.name == BUFF_CUREPRESS then b.count = 0 end   -- 暴击印记全部触发移除
                if b.count <= 0 then
                    table.remove(unit.buffs, i)
                    return
                end
            else
                table.remove(unit.buffs, i)
            end
            return
        end
    end
end

-- 清除所有buff
function helper.clear(unit)
    unit.buffs = {}
end

-- 返回所有控制技名字
function helper.controls()
    return controls
end

-- 返回所有印记技名字
function helper.impresses()
    return impresses 
end

-- 返回单位当前所有状态
function helper.states(unit)
    local states = {}
    if unit.buffs then
        for _, b in ipairs(unit.buffs) do
            if arraycontains(controls, b.name) and not arraycontains(states, b.name) then
                states[#states+1] = b.name
            elseif arraycontains(impresses, b.name) and not arraycontains(states, b.name) then
                states[#states+1] = b.name
            end
        end
    end
    return states
end

-- 单位是不是被强控
function helper.isRooted(unit)
    if unit.buffs then
        for _, b in ipairs(unit.buffs) do
            if arraycontains(roots, b.name) then
                return true
            end
        end
    end
    return false
end

return helper
