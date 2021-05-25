local brave = {}

function brave.init(__data)
    arrayclear(brave)
    tbl2string(__data)
    brave.isPull = true
    brave.status = __data.status
    brave.cd = __data.cd + os.time()
    brave.enemys = {}
    brave.reddot = 0
    if __data.nodes then
        brave.nodes = __data.nodes
    else
        brave.nodes = nil
    end
    if brave.status == 0 then
        brave.id = __data.id
        brave.stage = __data.stage
        brave.enemys[brave.stage] = __data.enemy
        brave.heros = __data.team or {}
    end
end

function brave.initRedDot(reddot)
    brave.reddot = bit.band(0x01, reddot)
end

function brave.showRedDot()
    if brave.reddot and brave.reddot == 1 then
        return true
    end
    return false
end

function brave.clear()
    arrayclear(brave)
    brave.isPull = false
end

return brave
