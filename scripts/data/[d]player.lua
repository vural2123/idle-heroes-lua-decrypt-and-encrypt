-- player info

local player = {}

require "common.const"
require "common.func"
local cfgexpplayer = require "config.expplayer"
local cfgvip = require "config.vip"
local cfghero = require "config.hero"
local bagdata = require "data.bag"
local achievedata = require "data.achieve"

-- param: uid, sid, pb_player
function player.init(uid, sid, pb)
    -- uid
    player.uid = uid
    -- sid
    player.sid = sid

    if pb then
        -- 名字
        player.name = pb.name
        -- 头像
        player.logo = pb.logo
        -- 公会id
        player.gid = pb.gid or 0
        -- 公会名字
        player.gname = pb.gname
        -- 公会战排名级别
        player.final_rank = pb.final_rank
    end
end

-- 获取玩家经验
function player.exp()
    return bagdata.items.find(ITEM_ID_PLAYER_EXP).num
end

function player.isSeasonal(thesid)
    if not thesid then thesid = player.sid end
    if thesid == 2 then return true end
end

function player.maxLv()
    return #cfgexpplayer
end

function player.maxExp()
    return cfgexpplayer[#cfgexpplayer].allExp
end

-- 返回等级，该等级已有经验，该等级总共需要的经验。exp为nil则用自己的
function player.lv(exp)
    if not exp then
        local item = bagdata.items.find(ITEM_ID_PLAYER_EXP)
        if item then 
            exp = item.num
        else
            exp = 0
        end
    end
    if exp > player.maxExp() then
        return nil
    end
    for i = 1, player.maxLv() do
        if exp < cfgexpplayer[i].allExp then
            local curExp = exp - cfgexpplayer[i-1].allExp
            return i-1, curExp, cfgexpplayer[i].allExp - cfgexpplayer[i-1].allExp
        end
    end
    return player.maxLv()
end

function player.maxVipLv()
    return #cfgvip
end

function player.maxVipExp()
    return cfgvip[#cfgvip].exp
end

function player.isMod(id)
	if not id or id <= 0 or id > 24 then return false end
	local pepe = player.pepemod or 0
	local bitid = bit.blshift(1, id - 1)
	if bit.band(pepe, bitid) ~= 0 then
		return true
	else
		return false
	end
end

-- return lv, exp at this lv, exp len at this lv
function player.vipLv(exp)
    if not exp then
        local item = bagdata.items.find(ITEM_ID_VIP_EXP)
        if item then 
            exp = item.num
        else
            exp = 0
        end
    end
    if exp > player.maxVipExp() then
        return nil
    end
    for i = 0, player.maxVipLv() do
        if exp < cfgvip[i].exp then
            local curExp = exp - cfgvip[i-1].exp
            return i-1, curExp, cfgvip[i].exp - cfgvip[i-1].exp
        end
    end
    return player.maxVipLv()
end

function player.setHideVip(_b)
    player.hide_vip = _b
end

function player.print()
    print("--------------- player --------------- {")
    print("uid:", player.uid)
    print("sid:", player.sid)
    print("name:", player.name)
    print("logo:", player.logo)
    print("gid:", player.gid)
    print("gname:", player.gname)
    print("final_rank:", player.final_rank)
    print("hide_vip:", player.hide_vip)
    print("--------------- player --------------- }")
end

return player


