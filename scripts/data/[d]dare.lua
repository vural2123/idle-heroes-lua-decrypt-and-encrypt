local dare = {}

local cfgdare = require "config.dare"

local Type = {
    COIN = 1,
    EXP = 2,
    SOUL = 3,
}
dare.Type = Type
local stage = {
    coin = {},
    exp = {},
    soul = {},
}
dare.stage = stage
dare.pull_time = os.time()

-- test data
--dare.cd = 1800
--dare.dares = {
--    [1] = {fight = 0, buy=0},
--    [2] = {fight = 0, buy=0},
--    [3] = {fight = 0, buy=0},
--}

local function init()
    for idx, item in pairs(cfgdare) do
        local ptbl
        if item.type == Type.COIN then
            ptbl = stage.coin
        elseif item.type == Type.EXP then
            ptbl = stage.exp
        elseif item.type == Type.SOUL then
            ptbl = stage.soul
        end
        item.idx = idx
        ptbl[#ptbl+1] = item
    end
end
init()

function dare.sort(a, b)
    return a.idx < b.idx
end

function dare.sync(data)
    dare.pulled = true
    dare.pull_time = os.time()
    dare.cd = data.cd
    dare.dares = data.dares
    dare.video = {}
end

function dare.reset()
    dare.pull_time = os.time()
    dare.cd = 3600 * 24
    for ii=1,3 do
        dare.dares[ii].fight = 0
        dare.dares[ii].buy = 0
    end
    dare.pulled =false
end

function dare.win(_type)
    if dare.dares and dare.dares[_type] then
        dare.dares[_type].fight = dare.dares[_type].fight + 1
    end
end

function dare.getStage(_type)
    if _type == Type.COIN then
        return dare.stage.coin
    elseif _type == Type.EXP then
        return dare.stage.exp
    elseif _type == Type.SOUL then
        return dare.stage.soul
    end
    return nil
end

function dare.getDare(_type)
    if _type == Type.COIN then
        return dare.dares[1]
    elseif _type == Type.EXP then
        return dare.dares[2]
    elseif _type == Type.SOUL then
        return dare.dares[3]
    end
end

return dare
