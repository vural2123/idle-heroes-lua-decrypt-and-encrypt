local friend = {}

local i18n = require "res.i18n"
local NetClient = require "net.netClient"
local netClient = NetClient:getInstance()

local friendsList = {}
local friendsApply = {}
local friendsRecmd = {}

local is_inited = false

local function initMsg()
    if is_inited then return end
    friend.list ={
        new_msgs = {},
        old_msgs = {},
    }
    friend.apply ={
        new_msgs = {},
        old_msgs = {},
    }
    friend.loved ={
        new_msgs = {},
        old_msgs = {},
    }
    is_inited = true
end
initMsg()

function friend.compareFrd(a, b)
	local ab = a.boss or 0
	local bb = b.boss or 0
	
	if ab == 0 and bb ~= 0 then
		return false
	elseif ab ~= 0 and bb == 0 then
		return true
	end
	
    if ab > bb then
		return true
	elseif ab < bb then
		return false
	end
	
	ab = a.last or 0
	bb = b.last or 0
	if ab == 0 and bb ~= 0 then
		return true
	elseif ab ~= 0 and bb == 0 then
		return false
	end
	
	return ab > bb
end

function friend.init(__data)
    --tbl2string(__data)
    friend.love = __data.love
    friend.cd = __data.cd + os.time()
    friendsList = __data.friends
    friendsApply = __data.apply
    friendsRecmd = __data.recmd
    if friendsList then
        table.sort(friendsList, friend.compareFrd)
    end
    friend.friends = {
        friendsList = friendsList,
        friendsApply = friendsApply,
        friendsRecmd = friendsRecmd
    }
end

function friend.onlineStatus(diff)
    if diff <= 0 then
        return i18n.global.guild_mem_status_online.string
    else
        if diff < 60 then
            return i18n.global.arena_records_times.string
        elseif diff < 3600 then
            local mm = math.floor((diff%3600)/60)
            if i18n.getCurrentLanguage() == kLanguageGerman then
               return string.format(i18n.global.arena_records_minutes.string, mm)  
            end
            return mm .. i18n.global.arena_records_minutes.string
        elseif diff < 3600 * 24 then
            local hh = math.floor(diff/3600)
            --local mm = math.floor((diff%3600)/60)
            --return string.format(i18n.global.guild_mem_status_hm.string, hh, mm)
            if i18n.getCurrentLanguage() == kLanguageGerman then
               return string.format(i18n.global.arena_records_hours.string, hh)  
            end
            return hh .. i18n.global.arena_records_hours.string
        --elseif diff < 3600 * 24 * 10 then
		else
			local amtd = math.floor(diff/(3600*24))
			if amtd == 1 and i18n.getCurrentLanguage() == kLanguageEnglish then
				return i18n.global.guild_mem_status_1d.string
			end
			return string.format(i18n.global.guild_mem_status_nd.string, amtd)
        --else
        --    return i18n.global.guild_mem_status_10d.string
        end
    end
end

function friend.showRedDot()
    if #friend.list.new_msgs > 0 then
        return true
    end
    if #friend.apply.new_msgs > 0 then
        return true
    end
    if #friend.loved.new_msgs > 0 then
        return true
    end
    return false
end

function friend.showListRedDot()
    if friendsList == nil then return false end
    for i=1,#friendsList do
        if friendsList[i].flag == 2 or friendsList[i].flag == 3 then
            return true
        end
    end
    return false
end

function friend.showApplyRedDot()
    if friendsApply == nil then return false end
    if #friendsApply > 0 then
        return true
    end
    return false
end

-- 如果消息达到60条就删除最早30条
function friend.delOld(tbl)
    if #tbl >= 60 then
        for ii=1,30 do
            table.remove(tbl, 1)
        end
    end
end

function friend.addMsg(tbl, _msg)
    if not tbl then
        tbl = {}
    end
    tbl[#tbl+1] = _msg
    friend.delOld(tbl)
    --table.sort(tbl, msgSort)
end

function friend.addLove(num)
    friend.love = friend.love + num
end

function friend.changebossst(uid, flag)
	if not flag then flag = 0 end

    if not friendsList then
        friendsList = {}
        friend.friends.friendsList = friendsList
    end
    for i=1, #friendsList do
        if friendsList[i].uid == uid then
            friendsList[i].boss = flag
            table.sort(friendsList, friend.compareFrd)
            return
        end
    end
end

function friend.bossdead(uid)
	if not friendsList then return end
	for i=1, #friendsList do
		if friendsList[i].uid == uid then
			if friendsList[i].boss and friendsList[i].boss > 0 then
				friendsList[i].boss = -friendsList[i].boss
				table.sort(friendsList, friend.compareFrd)
			end
			return
		end
	end
end

function friend.addFriendsList(obj)
    if not friendsList then
        friendsList = {}
        friend.friends.friendsList = friendsList
    end
    for i=1, #friendsList do
        if friendsList[i] == obj then
            return
        end
    end
    friendsList[#friendsList + 1] = obj
end

function friend.addFriendsRecmd(obj)
    if not friendsRecmd then
        friendsRecmd = {}
        friend.friends.friendsRecmd = friendsRecmd
    end
    friendsRecmd[#friendsRecmd + 1] = obj
end

function friend.addFriendsApply(obj)
    if not friendsApply then
        friendsApply = {}
        friend.friends.friendsApply = friendsApply
    end
    friendsApply[#friendsApply + 1] = obj
    if #friendsApply > 10 then
        table.remove(friendsApply, 1)
    end
end

function friend.delFriendsList(obj)
    if friendsList == nil then 
        return
    end

    for i=1, #friendsList do
        if friendsList[i] == obj then
            table.remove(friendsList, i)
            break
        end
    end
end 

function friend.addfriends(__data)
     if __data.friends then
        for i=1,#__data.friends do
            addFriendsList(__data.friends[i])
        end
     end
     if __data.apply then
        for i=1,#__data.apply do
            addFriendsApply(__data.apply[i])
        end
     end
     if __data.recmd then
        for i=1,#__data.recmd do
            addFriendsRecmd(__data.recmd[i])
        end
     end
end

function friend.delFriendsApply(obj)
    for i=1,#friendsApply do
        if friendsApply[i] == obj then
            table.remove(friendsApply, i)
            break
        end
    end
end

function friend.delFriendsRecmd(obj)
    for i=1,#friendsRecmd do
        if friendsRecmd[i] == obj then
            table.remove(friendsRecmd, i)
            break
        end
    end
end

function friend.getFriendsList()
    return friendsList
end

function friend.getFriendsApply()
    return friendsApply
end

function friend.getFriendsRecmd()
    return friendsRecmd
end

function friend.fetchListMsg()
    if #friend.list.new_msgs <= 0 then
        return nil
    end
    local tmp_obj = friend.list.new_msgs[1]
    friend.addMsg(friend.list.old_msgs, tmp_obj)
    table.remove(friend.list.new_msgs, 1)
    return tmp_obj
end

function friend.fetchLovedMsg()
    if #friend.loved.new_msgs <= 0 then
        return nil
    end
    local tmp_obj = friend.loved.new_msgs[1]
    friend.addMsg(friend.loved.old_msgs, tmp_obj)
    table.remove(friend.loved.new_msgs, 1)
    return tmp_obj
end

function friend.fetchApplyMsg()
    if #friend.apply.new_msgs <= 0 then
        return nil
    end
    local tmp_obj = friend.apply.new_msgs[1]
    friend.addMsg(friend.apply.old_msgs, tmp_obj)
    table.remove(friend.apply.new_msgs, 1)
    return tmp_obj
end

local function onFriends(data)
    cclog("onFriends data")
    tbl2string(data)

    if data.add then
        friend.addMsg(friend.list.new_msgs, data)
        friend.addFriendsList(data.add)
    end
    if data.love then
        friend.addMsg(friend.loved.new_msgs, data)
        for i=1, #friendsList do
            if friendsList[i].uid == data.love then
                friendsList[i].flag = friendsList[i].flag + 2
                break
            end
        end
    end
    if data.apply then
        friend.addMsg(friend.apply.new_msgs, data)
        friend.addFriendsApply(data.apply)
    end
    if data.del then
        for i=1, #friendsList do
            if friendsList[i].uid == data.del then
                friend.delFriendsList(friendsList[i])
                break
            end
        end
    end
end

function friend.registEvent()
    netClient:registFriendsEvent(onFriends)
end

return friend
