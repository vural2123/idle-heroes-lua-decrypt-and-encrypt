-- bag info

local bag = {}

local equips = {}
local items = {}

bag.equips = equips
bag.items = items 

require "common.const"
require "common.func"
local cfgequip = require "config.equip"
local cfghero = require "config.hero"

-- 各种货币的id
local CURRENCY_IDS = {
    ITEM_ID_COIN, ITEM_ID_GEM, 
    ITEM_ID_PLAYER_EXP, ITEM_ID_VIP_EXP, ITEM_ID_HERO_EXP,
    ITEM_ID_GUILD_COIN, ITEM_ID_LUCKY_COIN, ITEM_ID_RUNE_COIN, ITEM_ID_SMITH_CRYSTAL, 
    ITEM_ID_ENCHANT, ITEM_ID_LOVE, ITEM_ID_GACHA, ITEM_ID_SUPERGACHA, 
    ITEM_ID_ENERGY, ITEM_ID_BRAVE, ITEM_ID_ARENA_SHOP, ITEM_ID_BREAD,
    ITEM_ID_PET_DEVIL, ITEM_ID_PET_CHAOS, ITEM_ID_BUILD_STONE,
}

-- param: pb_bag
function bag.init(pb)
    if not pb then return end
    equips.init(pb.equips)
    items.init(pb.items)
end

-- param: array pb_equip
function equips.init(pbs)
    arrayclear(equips)
    if not pbs then return end
    for i, pb in ipairs(pbs) do
        local e = tablecp(pb)
        e.attr = e.attr or {}
        equips[#equips+1] = e
    end
end

-- param: pb_equip
function equips.add(pb)
    assert(pb.id and pb.num, "id or num nil")
    local e = equips.find(pb.id)
    if e then
        e.num = e.num + pb.num
        e.showRedDot = true
    else
        equips[#equips+1] = { id = pb.id, num = pb.num, showRedDot = true }
    end

    if cfgequip[pb.id].pos == EQUIP_POS_SKIN then
        return
    end

    local achieveData = require "data.achieve"
    if cfgequip[pb.id].qlt == QUALITY_4 then
        achieveData.add(ACHIEVE_TYPE_GET_EQUIP_GREEN, pb.num)
    end

    if cfgequip[pb.id].qlt == QUALITY_5 then
        achieveData.add(ACHIEVE_TYPE_GET_EQUIP_RED, pb.num)
    end

    if cfgequip[pb.id].qlt == QUALITY_6 then
        achieveData.add(ACHIEVE_TYPE_GET_EQUIP_ORANGE, pb.num)
    end
end

function equips.returnbag(pb)
    assert(pb.id and pb.num, "id or num nil")
    local e = equips.find(pb.id)
    if cfgequip[pb.id].pos ~= EQUIP_POS_JADE then
        if e then
            e.num = e.num + pb.num
            e.showRedDot = true
        else
            equips[#equips+1] = { id = pb.id, num = pb.num, showRedDot = true }
        end
    end
end

-- param: array pb_equip
function equips.addAll(pbs)
    if not pbs then return end
    for i, pb in ipairs(pbs) do
        equips.add(pb)
    end
end

function equips.sub(pb)
    assert(pb.id and pb.num, "id or num nil")
    local e, i = equips.find(pb.id)
    if e and e.num >= pb.num then
        e.num = e.num - pb.num
        if e.num == 0 then
            table.remove(equips, i)
        end
        return e
    end
end

function equips.find(id)
    for i, e in ipairs(equips) do
        if e.id == id then
            return e, i
        end
    end
end

function equips.del(id)
    for i, e in ipairs(equips) do
        if e.id == id then
            table.remove(equips, i)
            return e
        end
    end
end

function equips.count(id)
    local e = equips.find(id)
    if e then
        return e.num
    end
    return 0
end

function equips.skin(group)
    local eqs = {}
    for i,eq in ipairs(equips) do
        if cfgequip[eq.id].pos == EQUIP_POS_SKIN then
            if not group or cfghero[cfgequip[eq.id].heroId[1]].group == group then
				eqs[#eqs+1] = clone(eq)
				eqs[#eqs].flag = true
            end
        end
    end
    --for _, v in ipairs(heros) do
    --    if not group or cfghero[v.id].group == group then
    --        for i, vv in ipairs(v.equips) do
    --            if cfgequip[vv].pos == 7 then
    --                eqs[#eqs+1].id = vv
    --                eqs[#eqs+1].num = 1
    --                eqs[#eqs].flag = false
    --            end
    --        end
    --    end
    --end
    return eqs
end

function equips.print()
    print("--------- equips --------- {")
    for _, e in ipairs(equips) do
        print("id:", e.id, "num:", e.num)
    end
    print("--------- equips --------- }")
end

-- param: array pb_item
function items.init(pbs)
    arrayclear(items)
    for _, id in ipairs(CURRENCY_IDS) do
        items[#items+1] = { id = id, num = 0 }
    end
    items.addAll(pbs)
end

-- param: pb_item
function items.add(pb)
    assert(pb.id and pb.num, "id or num nil")
    if pb.num == 0 then return end
    local t = items.find(pb.id)
    if t then
        t.num = t.num + pb.num
    else 
        t = { id = pb.id, num = pb.num }
        items[#items+1] = t
    end

    local player = require "data.player"
    if t.id == ITEM_ID_PLAYER_EXP and t.num > player.maxExp() then
        t.num = player.maxExp()
    elseif t.id == ITEM_ID_VIP_EXP and t.num > player.maxVipExp() then
        t.num = player.maxVipExp()
    elseif t.id == ITEM_ID_LOVE and t.num > 1000 then
        if pb.num > 1000 then
            t.num = pb.num
        elseif t.num-pb.num > 1000 then
            t.num = t.num-pb.num
        else
            t.num = 1000
        end
    end

    local achieveData = require "data.achieve"
    if t.id == ITEM_ID_PLAYER_EXP then
        achieveData.set(ACHIEVE_TYPE_PLAYER_LV, player.lv())
    end
    if t.id == ITEM_ID_VIP_EXP then
        achieveData.set(ACHIEVE_TYPE_VIP_LV, player.vipLv())
    end
end

function items.sub(pb)
    assert(pb.id and pb.num, "id or num nil")
    local t, i = items.find(pb.id)
    if t and t.num >= pb.num then
        t.num = t.num - pb.num
        if t.num == 0 and not arraycontains(CURRENCY_IDS, pb.id) then
            table.remove(items, i)
        end
        return t
    end
end

-- param: array pb_item
function items.addAll(pbs)
    if not pbs then return end
    for i, pb in ipairs(pbs) do
        items.add(pb)
    end
end

function items.del(id)
    for i, t in ipairs(items) do
        if t.id == id then
            table.remove(items, i)
            return t
        end
    end
end

function items.find(id)
    for i, t in ipairs(items) do
        if t.id == id then
            return t, i
        end
    end
end

function items.print()
    print("--------- items --------- {")
    for _, t in ipairs(items) do
        print("id:", t.id, "num:", t.num)
    end
    print("--------- items --------- }")
end

function bag.coin()
    return items.find(ITEM_ID_COIN).num
end
function bag.addCoin(num)
    items.add({ id = ITEM_ID_COIN, num = num })
end
function bag.subCoin(num)
    items.sub({ id = ITEM_ID_COIN, num = num })
end

function bag.devil()
    return items.find(ITEM_ID_PET_DEVIL).num
end
function bag.addDevil(num)
    items.add({ id = ITEM_ID_PET_DEVIL, num = num })
end
function bag.subDevil(num)
    items.sub({ id = ITEM_ID_PET_DEVIL, num = num })
end


function bag.chaos()
    return items.find(ITEM_ID_PET_CHAOS).num
end
function bag.addChaos(num)
    items.add({ id = ITEM_ID_PET_CHAOS, num = num })
end
function bag.subChaos(num)
    items.sub({ id = ITEM_ID_PET_CHAOS, num = num })
end



function bag.gem()
    return items.find(ITEM_ID_GEM).num
end
function bag.addGem(num)
    items.add({ id = ITEM_ID_GEM, num = num })
end

function bag.subGem(num)
    items.sub({ id = ITEM_ID_GEM, num = num })
end

function bag.addRewards(rewards)
    if not rewards then return end
    if rewards.equips then bag.equips.addAll(rewards.equips) end
    if rewards.items then bag.items.addAll(rewards.items) end
    processSpecialHead(rewards.items)
end

-- 要在背包图标上显示红点，返回true；否则false
function bag.showRedDot()
    --[[local cfgitem = require "config.item"
    for _, t in ipairs(bag.items) do
        -- 有可合成的英雄碎片
        if cfgitem[t.id] and cfgitem[t.id].heroCost and cfgitem[t.id].type == ITEM_KIND_HERO_PIECE and t.num >= cfgitem[t.id].heroCost.count then
            return true
        end
        if cfgitem[t.id] and cfgitem[t.id].treasureCost and cfgitem[t.id].type == ITEM_KIND_TREASURE_PIECE and t.num >= cfgitem[t.id].treasureCost.count then
            return true
        end
    end--]]
    return false
end

function bag.print()
    print("---------------- bag ---------------- {")
    equips.print()
    items.print()
    print("---------------- bag ---------------- }")
end

return bag 


