
-- braveshop infos

local braveshop = {}

local cfgbraveshop = require "config.bravemarket"

function braveshop.compareMarket(a, b)
    local rank1, rank2 = cfgbraveshop[a.id].sort, cfgbraveshop[b.id].sort
    return rank1 < rank2
end

function braveshop.init(__data)
    braveshop.goods = __data.item
    for i = 1, #braveshop.goods do
        braveshop.goods[i]._id = i
    end
    table.sort(braveshop.goods, braveshop.compareMarket)
end

return braveshop
