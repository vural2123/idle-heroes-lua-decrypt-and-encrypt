local head = {}

require "common.const"
require "common.func"
local cfghead = require "config.head"
local cfghero = require "config.hero"
local herobook = require "data.herobook"

-- item <--> head map
local ITEM_HEAD = {
    [ITEM_ID_SP_FIGHT] = 51,
    [ITEM_ID_SP_FIGHT2] = 53,
    [ITEM_ID_SP_WINNER_HEAD] = 52,
    [ITEM_ID_SP_LOVER_HEAD] = 54,
    [ITEM_ID_SP_F3V3_HEAD_1] = 59,
    [ITEM_ID_SP_F3V3_HEAD_2] = 58,
    [ITEM_ID_SP_F3V3_HEAD_3] = 57,
    [ITEM_ID_SP_F3V3_HEAD_4] = 56,
    [ITEM_ID_SP_F3V3_HEAD_5] = 55,
    [ITEM_ID_SP_WARM] = 60,
    [ITEM_ID_SP_FIGHT3] = 61,
    [ITEM_ID_SP_WARM2] = 62,
    [ITEM_ID_SP_FIGHT4] = 63,
    [ITEM_ID_SP_WARM3] = 64,
    [ITEM_ID_SP_WARM4] = 65,
    [ITEM_ID_SP_FIRSTYEAR] = 66,
    [ITEM_ID_SP_FIGHT5] = 67,
    [ITEM_ID_SP_WARM5] = 68,
    [ITEM_ID_SP_FIGHT6] = 74,
    [ITEM_ID_SP_LOVE] = 75,
    [ITEM_ID_SP_FIGHT7] = 76,
    [ITEM_ID_SP_RABBIT] = 92,
    [ITEM_ID_SP_BEAR] = 93,
    [ITEM_ID_SP_FIGHT8] = 94,
    [ITEM_ID_SP_SUB] = 95,
    [ITEM_ID_SP_HW] = 96,
    [ITEM_ID_SP_FIGHT9] = 97,
    [ITEM_ID_SP_VPLI1] = 98,
    [ITEM_ID_SP_MASK] = 99,
    [ITEM_ID_SP_FIGHT10] = 100,
    [ITEM_ID_SP_CHRISTMAS] = 101,
    [ITEM_ID_SP_FIGHT11] = 110,
    [ITEM_ID_SP_NEWYEAR1] = 111,
    [ITEM_ID_SP_FIGHT12] = 112,
    [ITEM_ID_SP_FIGHT13] = 113,
    [ITEM_ID_SP_FIGHT14] = 119,
    [ITEM_ID_SP_FIGHT15] = 120,
    [ITEM_ID_SP_DEMON] = 121,
    [ITEM_ID_SP_FIGHT16] = 122,
    [ITEM_ID_SP_FIGHT17] = 123,
    [ITEM_ID_SP_FIGHT18] = 124,
	[ITEM_ID_SP_MOONCAKE] = 125,
	[ITEM_ID_SP_AFRICA1] = 126,
	[ITEM_ID_SP_AFRICA2] = 127,
	[ITEM_ID_SP_AFRICA3] = 128,
	[ITEM_ID_SP_HALLOMAS] = 129,
	[ITEM_ID_SP_THANK] = 177,
	[ITEM_ID_SP_CHRISTMAS2] = 180,
	[ITEM_ID_SP_NEW_YEAR] = 185,
	[ITEM_ID_SP_CHINESE_NEW_YEAR] = 191,
	[ITEM_ID_SP_FLOWER_CIRCLE] = 194,
    [8801] = 236,
    [8802] = 237,
    [8803] = 238,
    [8804] = 239,
    [8805] = 240,
    [8806] = 241,
    [8807] = 242,
    [8808] = 243,
    [8809] = 244,
    [8810] = 245,
    [8811] = 246,
    [8812] = 247,
    [8813] = 248,
    [8814] = 249,
    [8815] = 250,
}

function head.getHeadIdByItemId(item_id)
    return ITEM_HEAD[item_id]
end

function head.getItemhead()
    return ITEM_HEAD
end

function head.init()
    arrayclear(head)
    for _, cfg in ipairs(cfghead) do
        head[#head + 1] = { iconId = cfg.iconId }
    end
    for _, id in ipairs(herobook) do
        if cfghero[id].qlt >= QUALITY_4 then
            head[#head + 1] = { iconId = id }
        end
    end
end

-- param: hero id
function head.add(id)
    local iconId = cfghero[id].heroCard
    if not head.contains(iconId) then
        head[#head + 1] = { iconId = id, isNew = true }
    end
end

function head.contains(iconId) 
    for _, info in ipairs(head) do
        if info.iconId == iconId then
            return true
        end
    end
    return false
end

function head.showRedDot()
	if head.forceRed then return true end
    for i = 1, #head do
        if head[i].isNew then
            return true
        end
    end
    return false
end

return head
