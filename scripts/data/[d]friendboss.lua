local friendboss = {}

local NetClient = require "net.netClient"
local netClient = NetClient:getInstance()
local player = require "data.player"

function friendboss.init(__data)
    print("**** frdboss ****")
    tbl2string(__data)
    friendboss.pull_time = os.time()
    friendboss.enegy = __data.tl
    friendboss.video = {}
    if __data.tcd then
        friendboss.pull_tcd_time = os.time()
        friendboss.tcd = __data.tcd
    else
        friendboss.tcd = nil
    end
    if __data.scd then
        friendboss.pull_scd_time = os.time()
        friendboss.scd = __data.scd
    else
        friendboss.scd = nil
    end
    friendboss.ccd = __data.ccd
    friendboss.rcd = __data.rcd
end

function friendboss.delEnegy(num)
    if friendboss.enegy == 10 then
        friendboss.tcd = 2*3600
        friendboss.pull_tcd_time = os.time()
    end
    if num then
        friendboss.enegy = friendboss.enegy - num
    else
        friendboss.enegy = friendboss.enegy - 1
    end
end

function friendboss.addEnegy()
    friendboss.enegy = friendboss.enegy + 1
    if friendboss.enegy == 10 then
        friendboss.tcd = nil    
    end
end

function friendboss.upscd()
    friendboss.scd = 0 
    friendboss.pull_scd_time = os.time()
end

function friendboss.addscd()
    friendboss.scd = friendboss.scd + 8*3600
    friendboss.pull_scd_time = os.time()
end

local function onFriendsboss(data)
    print("onFriendsboss data")
    tbl2string(data)
    local friend = require "data.friend"
    friend.changebossst(data.uid, data.boss)
end

function friendboss.registEvent()
    netClient:registFriendsbossEvent(onFriendsboss)
end

function friendboss.showBossRedDot()
    if friendboss.scd and friendboss.scd == 0 and player.lv() >= 36 then
        return true
    end
    return false
end

return friendboss
