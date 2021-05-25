
-- guildmarket infos

local guildmarket = {}

local cfgguildmarket = require "config.guildstore"

function guildmarket.compareMarket(a, b)
    local rank1, rank2 = cfgguildmarket[a.id].sort, cfgguildmarket[b.id].sort
    return rank1 < rank2
end

function guildmarket.getMaxPage()
    --if heromarket.goods == nil or #heromarket.goods == 0 then return 0 end
    local maxPage = math.floor((#guildmarket.goods-1)/8)+1
    return maxPage 
end

function guildmarket.init(__data)
    guildmarket.goods = __data.item
    for i = 1, #guildmarket.goods do
        guildmarket.goods[i]._id = i
    end
    table.sort(guildmarket.goods, guildmarket.compareMarket)
end

return guildmarket
