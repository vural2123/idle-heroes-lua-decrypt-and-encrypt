 -- data.chat
local chat = {}

local player = require "data.player"
local NetClient = require "net.netClient"
local netClient = NetClient:getInstance()

function chat.getChannels()
	local i18n = require "res.i18n"
	local chn = {}
	chn[1] = {
		id = 1,
		label = "English",
		speaklv = true,
		speaktime = true,
	}
	chn[2] = {
		id = 2,
		label = i18n.global.chat_tab_guild.string,
		reddot = true,
		isguild = true,
	}
	chn[3] = {
		id = 3,
		label = i18n.global.chat_tab_recruit.string,
		nosend = true,
	}
	chn[5] = {
		id = 5,
		label = "中文",
		speaklv = true,
		speaktime = true,
	}
	chn[6] = {
		id = 6,
		label = "International",
		speaklv = true,
		speaktime = true,
	}
	return chn
end

local is_inited = false
local is_synced = false

local function initMsg()
    if is_inited then return end
	local channels = {}
	local templ = chat.getChannels()
	for _, v in pairs(templ) do
		channels[v.id] = {
			new_msgs = {},
			old_msgs = {},
			proto = v,
		}
	end
    chat.channels = channels
    is_inited = true
end
initMsg()

function chat.getChannel(chn)
	if chat.channels then return chat.channels[chn] end
	return nil
end

function chat.isSynced()
	return is_synced
end

function chat.synced()
	is_synced = true
end

function chat.deSync()
	is_synced = false
    is_inited = false
end

function chat.getSpeakLv()
	local lv = chat.speaklv
	if not lv or lv <= 0 then lv = 15 end
	return lv
end

function chat.getSpeakCd()
	local cd = chat.speakcd
	if not cd or cd <= 0 then cd = 30 end
	return cd
end

function chat.sync(callback)
    initMsg()
	chat.speaklv = nil
	chat.speakcd = nil
    local params = {
        sid = player.sid,
    }
    netClient:sync_chat(params, function(__data)
		if __data.speaklv and __data.speaklv > 0 then
			chat.speaklv = __data.speaklv
		end
		if __data.speakcd and __data.speakcd > 0 then
			chat.speakcd = __data.speakcd
		end
		if callback then
			callback(__data)
		end
	end)
end

function chat.send(params, callback)
    netClient:chat(params, callback)
end

function chat.showRedDot(chn, ignore)
	if not chn then
		local channels = chat.getChannels()
		for _, v in pairs(channels) do
			if (not ignore or v.id ~= ignore) and v.reddot then
				local chan = chat.getChannel(v.id)
				if chan and #chan.new_msgs > 0 then
					return true
				end
			end
		end
		return false
	end
	
	local chan = chat.getChannel(chn)
	if chan and chan.reddot and #chan.new_msgs > 0 then
		return true
	end
	
	return false
end

local function msgSort(obj1, obj2)
    if obj1.time < obj2.time then
        return true
    else
        return false
    end
end

--[[function chat.world.add(obj)
    if not chat.world then
        chat.world = {}
    end
    chat.world[#chat.world+1] = obj
    table.sort(chat.world, msgSort)
end--]]

-- 如果消息达到60条就删除最早30条
function chat.delOld(tbl)
    if #tbl >= 60 then
        for ii=1,30 do
            table.remove(tbl, 1)
        end
    end
end

--[[function chat.addMsg(tbl, _msg)
    if not tbl then
        tbl = {}
    end
    tbl[#tbl+1] = _msg
    chat.delOld(tbl)
    table.sort(tbl, msgSort)
end--]]

function chat.getMsg(chn)
	local chan = chat.getChannel(chn)
	if chan and chan.old_msgs then return chan.old_msgs end
	return {}
end

function chat.fetchMsg(chn)
	local chan = chat.getChannel(chn)
	if chan and chan.new_msgs and #chan.new_msgs > 0 then
		local tmp_obj = chan.new_msgs
		chan.new_msgs = {}
		for _, v in ipairs(tmp_obj) do
			chan.old_msgs[#chan.old_msgs + 1] = v
		end
		chat.delOld(chan.old_msgs)
		return tmp_obj
	end
	return nil
end

local function onMsg(msgObj)
    local chn = msgObj.type
	if chn >= 100 then
		-- implement custom stuff here like showToast etc.
		return
	end
	
	local chan = chat.getChannel(chn)
	if chan then
		chan.new_msgs[#chan.new_msgs + 1] = msgObj
		chat.delOld(chan.new_msgs)
		return
	end
end

function chat.addMsgs(msglist)
    if not msglist or #msglist == 0 then return end
    for ii=1,#msglist do
        onMsg(msglist[ii])
    end
end

function chat.registEvent()
    netClient:registChatEvent(onMsg)
end

return chat
