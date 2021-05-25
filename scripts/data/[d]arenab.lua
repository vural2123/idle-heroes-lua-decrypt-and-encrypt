local arena = {}

local net = require "net.netClient"
local player = require "data.player"

arena.rivals = {}

local net = require "net.netClient"

function arena.init(__data)
    --arena.season_cd = os.time() + __data.season_cd 
    --arena.daily_cd = os.time() + __data.daily_cd
    arena.members = nil
    arena.rivals = {}
    arena.fight = 0
    arena.tscore = 0
    if __data.self then
        arena.fight = __data.self.fight or 0
        arena.score = __data.self.score
        arena.power = __data.self.power
        arena.rank = __data.self.rank
        arena.trank = __data.self.trank
        arena.tscore = __data.self.tscore
        arena.win = __data.self.win
        arena.camp = __data.self.camp
    end
end

function arena.initTime(__data)
    arena.season_cd = os.time() + __data.season_cd
    arena.daily_cd = os.time() + __data.daily_cd
end

function arena.refresh()
    local riv = {}
	
	if #arena.rivals == 0 then
		return riv
	end
    
    for i=1, #arena.rivals do
		local r = arena.rivals[i]
        if not r.isUsed then
            riv[#riv + 1] = r
            r.isUsed = true
        end
        if #riv >= 3 then
            break
        end
    end
	
	if #riv < 3 then
		for i=1, #arena.rivals do
			arena.rivals[i].isUsed = false
		end
	end
	
	for i=1, #arena.rivals do
		local r = arena.rivals[i]
        if not r.isUsed then
            riv[#riv + 1] = r
            r.isUsed = true
        end
        if #riv >= 3 then
            break
        end
    end

    return riv
end

function arena.update(score)
    arena.score = score
    if arena.tscore < arena.score then
        arena.tscore = arena.score
    end
end

return arena
