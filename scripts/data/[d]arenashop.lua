-- arenashop infos

local arenashop = {}

local cfgarenashop = require "config.arenamarket"

function arenashop.compareMarket(a, b)
    local rank1, rank2 = cfgarenashop[a.id].sort, cfgarenashop[b.id].sort
    return rank1 < rank2
end

function arenashop.init(__data)
    arenashop.goods = __data.item
    for i = 1, #arenashop.goods do
        arenashop.goods[i]._id = i
    end
    table.sort(arenashop.goods, arenashop.compareMarket)
end

return arenashop
