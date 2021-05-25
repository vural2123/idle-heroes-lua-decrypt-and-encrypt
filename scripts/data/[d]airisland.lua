local airisland = {}

local cfghero 	 = require "config.hero"
local cfgMonster = require "config.monster"
local cfgSpk     = require "config.spk"
local cfgSpkWave = require "config.spkwave"
local cfgMonster = require "config.monster"
local cfgDrug    = require "config.spkdrug"
local cfgTrader  = require "config.spktrader"
local heros 	 = require "data.heros"
local userdata   = require "data.userdata"
local airConf    = require "config.homeworld"

function airisland.setCount()
    airisland.count = 0
end

function airisland.initRedDot(reddot)
    airisland.reddot = bit.band(0x08, reddot)
    local isShow = airisland.reddot ~= 0 and true or false

    airisland.setShowRed(isShow)
end

function airisland.setData(data)
    airisland.data = data
    airisland.fullBuilds = 0
    if airisland.data and airisland.data.mine then
        for k,v in pairs(airisland.data.mine) do
            local limit = airConf[v.id].max
            if v.val >= limit then
                airisland.fullBuilds = airisland.fullBuilds + 1
            end
        end
    end
    airisland.setShowRed(airisland.fullBuilds > 0 and true or false)
end

function airisland.setShowRed(isShow)
    airisland.isShow = isShow or false
end

-- 每次矿物收获时调用一次
function airisland.getOutPut()
    airisland.fullBuilds = airisland.fullBuilds - 1
    airisland.setShowRed(airisland.fullBuilds > 0 and true or false)
end

function airisland.showRedDot()
    return airisland.isShow
end

function airisland.setLandData(data)
    airisland.data.land = data
    for i = 1,27 do
        if data.land[i] then
            if data.land[i].cd == nil then
                airisland.data.land.land[i].cd = nil
            else
                airisland.data.land.land[i].cd = data.land[i].cd  + os.time()   
            end
        end
    end
end

function airisland.calVit(num)
   airisland.data.vit.vit = num 
end

function airisland.changeVit(num)
   airisland.data.vit.vit = airisland.data.vit.vit + num 
end

return airisland
