local frdarena = {}

local net = require "net.netClient"
local netClient = net:getInstance()
local player = require "data.player"

frdarena.rivals = {}

function frdarena.init(__data)
    frdarena.team = __data.team
    frdarena.camp = __data.camp
    frdarena.trank = nil 
    if __data.team and __data.team.enggy_cd then
        frdarena.team.pull_ecd_time = os.time()
    end

    frdarena.teams = nil
    frdarena.rivals = {}
    frdarena.showapplyRed = false
    frdarena.showinvitRed = false
    frdarena.refreshOwner = false
end

function frdarena.refTeam(__data)
    frdarena.team = __data.team
    frdarena.camp = __data.camp
end

function frdarena.initTime(__data)
    frdarena.season_cd = os.time() + __data.season_cd 
end

function frdarena.refresh()
    local riv = {}
    for i=1, #frdarena.rivals do
        for j=i+1, #frdarena.rivals do
            if frdarena.rivals[i].score > frdarena.rivals[j].score then
                frdarena.rivals[i], frdarena.rivals[j] = frdarena.rivals[j], frdarena.rivals[i]
            end
        end
    end

    for i=1, #frdarena.rivals do
        local idx = #frdarena.rivals - i + 1
        if not frdarena.rivals[idx].isUsed then
            riv[#riv + 1] = frdarena.rivals[idx]
            frdarena.rivals[idx].isUsed = true
        end
        if #riv >= 2 then
            break
        end
    end

    for i=1, #frdarena.rivals do
        if not frdarena.rivals[i].isUsed then
            riv[#riv + 1] = frdarena.rivals[i]
            frdarena.rivals[i].isUsed = true
        end
        if #riv >= 3 then
            return riv
        end       
    end

    for i=1, #frdarena.rivals do
        local idx = #frdarena.rivals - i + 1
        if not frdarena.rivals[idx].isUsed then
            riv[#riv + 1] = frdarena.rivals[idx]
            frdarena.rivals[idx].isUsed = true
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

    if #riv == #frdarena.rivals and #riv > 0 then
        return riv 
    elseif #riv < 2 then
        return {}
    end
    return riv
end

function frdarena.setdissmiss()
    frdarena.team = nil
end

function frdarena.setLeader(uid)
    frdarena.refreshOwner = true
    frdarena.team.leader = uid
end

function frdarena.jointeam(obg)
    frdarena.team = {}
    frdarena.team = obg
end

function frdarena.addTeammate(obj)
    if not frdarena.team.mbrs then
        frdarena.team.mbrs = {}
    end
    for i=1, #frdarena.team.mbrs do
        if frdarena.team.mbrs[i] == obj then
            return
        end
    end
    frdarena.team.mbrs[#frdarena.team.mbrs + 1] = obj
end

function frdarena.delTeammate(obj)
    if frdarena.team.mbrs == nil then 
        return
    end
    for i=1, #frdarena.team.mbrs do
        if frdarena.team.mbrs[i].uid == obj.uid then
            table.remove(frdarena.team.mbrs, i)
            break
        end
    end
end

function frdarena.submit()
    --frdarena.team.rank = 1000
    --frdarena.team.score = 1000
    frdarena.team.reg = true
end

-- 如果消息达到60条就删除最早30条
function frdarena.delOld(tbl)
    if #tbl >= 60 then
        for ii=1,30 do
            table.remove(tbl, 1)
        end
    end
end

function onFrdarena(data)
    tbl2string(data)
	if data.invited and data.invited >= 2 then return end

    if data.owner or data.dismiss or data.leave or data.agree_invite or data.submit or data.kicked or data.agreed then
        local params = {
            sid = player.sid        
        }
        net:gpvp_sync(params, function(__data)
            tbl2string(__data)
            frdarena.refTeam(__data)
            if data.owner then
                frdarena.refreshOwner = true
            end
        end)
    elseif data.invited then
        frdarena.showinvitRed = true
    elseif data.apply then
        frdarena.showapplyRed = true
    end
end

function frdarena.registEvent()
    netClient:registFrdarenaEvent(onFrdarena)
end

return frdarena
