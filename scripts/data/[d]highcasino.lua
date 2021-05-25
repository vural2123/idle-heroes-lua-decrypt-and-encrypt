local casino = {}

local bagdata = require "data.bag"
local player = require "data.player"
local NetClient = require "net.netClient"
local netClient = NetClient:getInstance()

casino.COST_PER_CHIP = 50

function casino.pull(param, callback)
    netClient:pull_casino(param, callback)
end

function casino.msg(param, callback)
    netClient:casino_msg(param, callback)
end

function casino.draw(param, callback)
    netClient:casino_draw(param, callback)
end

function casino.ids2Pbbag(ids)
    local _pbbag = {
        items = {},
        equips = {}
    }
    if not ids or #ids <= 0 then return _pbbag end
    for ii=1,#ids do
        local _idx = ids[ii]
        local p_tbl = nil
        if casino.items[_idx].type ==  1 then  -- item
            p_tbl = _pbbag.items
        elseif casino.items[_idx].type ==  2 then  -- item
            p_tbl = _pbbag.equips
        end
        if p_tbl then
            local tmp_item = clone(casino.items[_idx])
            tmp_item.num = tmp_item.count
            p_tbl[#p_tbl+1] = tmp_item 
        end
    end
    return _pbbag
end

function casino.buy(param, callback)
    netClient:casino_buy(param, callback)
end

function casino.getChips()
    local _chips = bagdata.items.find(ITEM_ID_ADVANCED_CHIP)
    if _chips then
        return _chips.num
    end
    return 0
end

function casino.addChips(_count)
    local _chips = bagdata.items.find(ITEM_ID_ADVANCED_CHIP)
    if _chips then
        _chips.num = _chips.num + _count
        if _chips.num < 0 then
            _chips.num = 0
        end
    else
        bagdata.items.add({id=ITEM_ID_ADVANCED_CHIP, num=_count})
    end
end

function casino.subChips(_count)
    casino.addChips(0-_count)
end

function casino.getRateById(_id, _type)
    if not casino.items or #casino.items <= 0 then return 0 end
    local self_weight = 0
    local total_weight = 0
    for ii=1,#casino.items do
        total_weight = total_weight + (casino.items[ii].weight or 2000)
        if casino.items[ii].id == _id and casino.items[ii].type == _type then
            self_weight = casino.items[ii].weight or 0
        end
    end
    return 100.0 * self_weight / total_weight
end

function casino.init(__data)
    casino.last_pull = os.time()
    casino.last_force_pull = os.time()
    casino.items = __data.items
    casino.cd = __data.cd % 0x1000000
    casino.stack = math.floor(__data.cd / 0x1000000)
    casino.force_cd = __data.force_cd
    casino.msgs = __data.msgs
end

return casino
