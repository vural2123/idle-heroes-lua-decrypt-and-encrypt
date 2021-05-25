local guildmill = {}

local player = require "data.player"
local NetClient = require "net.netClient"
local netClient = NetClient:getInstance()

function guildmill.initorder(__data)
    guildmill.lv = __data.mill_lv
    guildmill.reddot = 0
    --guildmill.enegy = __data.enegy
    --guildmill.porder = __data.porder
    if __data.orders then
        guildmill.pull_ocd_time = {}
        guildmill.order = __data.orders
        for i=1,#guildmill.order do 
            guildmill.pull_ocd_time[i] = os.time()
        end
    else
        guildmill.order = nil
    end
    if __data.ecd then
        guildmill.pull_ecd_time = os.time()
        guildmill.ecd = __data.ecd
    else
        guildmill.ecd = nil
    end
end

--function guildmill.setOrdercd(ordercd)
--    guildmill.pull_ocd_time = os.time()
--    guildmill.order = {}
--    guildmill.order.cd = ordercd
--end

function guildmill.initRedDot(reddot)
    if player.lv() >= UNLOCK_GUILD_LEVEL then
        guildmill.reddot = bit.band(0x04, reddot)
    end
end

function guildmill.showRedDot()
    --if guildmill.order and #guildmill.order > 0 then 
    --    for i=1,#guildmill.order do
    --        if guildmill.order[i].cd == 0 then
    --            return true
    --        end
    --    end
    --end

	if guildmill.reddot and guildmill.reddot ~= 0 then
        return true
    end
    return false
end

function guildmill.sortOrder()
    local orders = {}
    for i, v in ipairs(guildmill.order) do
        if v.cd and v.cd == 0 then
            orders[#orders + 1] = v
        end
    end

    for i, v in ipairs(guildmill.order) do
        if v.cd == nil then
            orders[#orders + 1] = v
        end
    end

    for i, v in ipairs(guildmill.order) do
        if v.cd and v.cd > 0 then
            orders[#orders + 1] = v
        end
    end
    guildmill.order = orders
end

function guildmill.initupgrade(__data)
    guildmill.coin = __data.coin
    local cfgmilllv = require "config.milllv"
    for i=1, guildmill.lv do
        guildmill.coin = guildmill.coin - cfgmilllv[i].gold
    end
end

function guildmill.donatecoin(type)
    local coin = 100000
    if type == 2 then
        coin = 1000000
    end
    guildmill.coin = guildmill.coin + coin
    local cfgmilllv = require "config.milllv"
    if guildmill.coin >= cfgmilllv[guildmill.lv+1].gold then
        guildmill.lv = guildmill.lv + 1
        guildmill.coin = guildmill.coin - cfgmilllv[guildmill.lv].gold
    end
end

function guildmill.addEnegy()
    local bag = require "data.bag"
    bag.items.add({id = ITEM_ID_BREAD, num = 1})
    if bag.items.find(ITEM_ID_BREAD).num == 10 then
        guildmill.ecd = nil    
    end
end

return guildmill
