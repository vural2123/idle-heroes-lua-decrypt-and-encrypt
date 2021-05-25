local arena = {}

local net = require "net.netClient"
local player = require "data.player"

arena.rivals = {}

local net = require "net.netClient"

function arena.init(__data)
    arena.status = __data.status
    --arena.season_cd = os.time() + __data.season_cd 
    arena.score = __data.self.score
    arena.power = __data.self.power
    arena.rank = __data.self.rank
    arena.trank = __data.self.trank
    arena.tscore = __data.self.tscore

    arena.members = nil
    arena.rivals = {}
    arena.fight = __data.self.fight or 0

    arena.camp = __data.self.camp
    if arena.camp then
        local hids = {}
        for i = 1, 18 do
            hids[i] = 0
        end
        for i, v in ipairs(arena.camp) do
            if v.pos<=18 then
                hids[v.pos] = v.hid
            else
                hids[v.pos] = v.id
            end
        end
        local userdata = require "data.userdata"

        --require("ui.pet.petBattle3v3").getNowSele(hids)
        --print("加入宠物信息")
        --tablePrint(hids)
        userdata.setSquadArena3v3Def(hids)
    end
end

function arena.initTime(__data)
    arena.season_cd = os.time() + __data.season_cd 
end

function arena.refresh()
    local riv = {}

    if not arena.rivals then arena.rivals = {} end

    for i=1, #arena.rivals do
        for j=i+1, #arena.rivals do
            if arena.rivals[i].score > arena.rivals[j].score then
                arena.rivals[i], arena.rivals[j] = arena.rivals[j], arena.rivals[i]
            end
        end
    end

    for i=1, #arena.rivals do
        local idx = #arena.rivals - i + 1
        if not arena.rivals[idx].isUsed then
            riv[#riv + 1] = arena.rivals[idx]
            arena.rivals[idx].isUsed = true
        end
        if #riv >= 2 then
            break
        end
    end

    for i=1, #arena.rivals do
        if not arena.rivals[i].isUsed then
            riv[#riv + 1] = arena.rivals[i]
            arena.rivals[i].isUsed = true
        end
        if #riv >= 3 then
            return riv
        end       
    end

    for i=1, #arena.rivals do
        local idx = #arena.rivals - i + 1
        if not arena.rivals[idx].isUsed then
            riv[#riv + 1] = arena.rivals[idx]
            arena.rivals[idx].isUsed = true
        end
        if #riv >= 3 then
            return riv
        end
    end

    --for i, v in ipairs(arena.rivals) do
    --    if not v.isUsed then
    --        riv[#riv + 1] = v
    --        v.isUsed = true
    --    end
    --    if #riv >= 3 then
    --        return riv
    --    end
    --end

    if #riv == #arena.rivals and #riv > 0 then
        return riv 
    elseif #riv < 2 then
        return {}
    end

    return riv
end

function arena.update(score)
    arena.score = score
    if arena.tscore < arena.score then
        arena.tscore = arena.score
    end
    --local achieveData = require "data.achieve"
    --achieveData.set(ACHIEVE_TYPE_ARENA_SCORE, arena.tscore)
end

return arena
