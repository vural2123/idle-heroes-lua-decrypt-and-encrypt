
-- heromarket infos

local heromarket = {}

local cfgheromarket = require "config.heromarket"

function cfgguildMarket(a, b)
    local rank1, rank2 = cfgheromarket[a.id].rank, cfgheromarket[b.id].rank
    if rank1 < rank2 then
        return true
    elseif rank1 > rank2 then
        return false
    end
end

function heromarket.getMaxPage()
    --if heromarket.goods == nil or #heromarket.goods == 0 then return 0 end
    local maxPage = math.floor((#heromarket.goods-1)/8)+1
    return maxPage 
end

function heromarket.init(__data)
    heromarket.goods = __data.item
    heromarket.pull_time = os.time()
    for i = 1, #heromarket.goods do
        heromarket.goods[i]._id = i
    end
    table.sort(heromarket.goods, cfgguildMarket)
end

function heromarket.rm(pos)
    for i=1,#heromarket.goods do
        if i == pos then
            table.remove(heromarket.goods, pos)
            break
        end
    end
end

return heromarket
