local gboss = {}
local cfgguildboss = require "config.guildboss"

gboss.pull_time = os.time()
local items_per_page = 8

function gboss.sync(data)
    gboss.pull_time = os.time()
    gboss.id = data.id
    gboss.cd = data.cd
    gboss.hpp = data.hpp
    gboss.fights = data.fights
end

function gboss.addBossExp(bossid)
    (require"data.guild").addExp(cfgguildboss[bossid].guildExp)
end

function gboss.getPages()
    return math.floor((#cfgguildboss+items_per_page-1)/items_per_page)
end

function gboss.getCurPage()
    local cur_page = math.floor((gboss.id+items_per_page-1)/items_per_page)
    if cur_page > gboss.getPages() then
        return gboss.getPages()
    end
    return cur_page
end

function gboss.addPlainReward(bid)
    (require"data.bag").addRewards(reward2Pbbag(cfgguildboss[bid].reward))
end

return gboss
