local guild = {}

local guildexp = require "config.guildexp"
local cfgguildFlag = require "config.guildflag"
local i18n = require "res.i18n"
local player = require "data.player"
local NetClient = require "net.netClient"
local netClient = NetClient:getInstance()

local TITLE = {
    RESIDENT = 0,
    OFFICER = 1,
    PRESIDENT = 2,
}
guild.TITLE = TITLE

guild.CREATE_COST = 500
guild.NAME_COST = 1000   -- 改公会名字的价值
guild.is_init = false   -- 判定是否需要同步数据
guild.SIGN_EXP = 30  
guild.SIGN_COIN = 50  

local flags = {
}
local function initFlag()
    for ii=1,#cfgguildFlag do
        flags[ii] = ii
    end
end
initFlag()
guild.flags = flags

function guild.init(__data)
    --if guild.is_init then
    --    return
    --end
    guild.last_pull = os.time()
    guild.guildObj = clone(__data.guild)
    guild.members = clone(__data.members)
    player.gid = guild.guildObj.id
    guild.sign_cd = __data.sign_cd or os.time()
    guild.appliers_count = __data.appliers_count or 0
    guild.is_init = true
end

function guild.deInit()
    guild.is_init = false
end

function guild.IsInit()
    return guild.is_init
end

function guild.self()
    if not guild.members then return nil end
    for ii=1,#guild.members do
        if guild.members[ii].uid == player.uid then
            return guild.members[ii]
        end
    end
    return nil
end

function guild.selfTitle()
    local selfObj = guild.self()
    if selfObj then
        return selfObj.title
    end
    return TITLE.RESIDENT
end

function guild.removeMemByUid(_uid)
    if not guild.members or #guild.members == 0 then return end
    for ii=1,#guild.members do
        if guild.members[ii].uid == _uid then
            table.remove(guild.members, ii)
            return
        end
    end
end

-- config file guildexp.lua has no item guildexp[0]
function guild.Lv(exp)
    exp = exp or guild.guildObj.exp
    for ii=1,#guildexp do
        if exp < guildexp[ii].allExp then
            return ii-1
        end
    end
    return #guildexp
end

function guild.maxMember(exp)
    local lv = guild.Lv(exp)
    return guildexp[lv].member
end

function guild.maxOffical(exp)
    --local lv = guild.Lv(exp)
    --return guildexp[lv].officialMaxNum
    return 4
end

function guild.lvReward(exp)
    local lv = guild.Lv(exp)
    return guildexp[lv].registerReward
end

function guild.upLvExp(exp)
    local lv = guild.Lv(exp)
    if lv >= #guildexp then
        lv = #guildexp - 1
        --return guildexp[lv].allExp - guildexp[lv-1].allExp
    end
    return guildexp[lv+1].allExp - guildexp[lv].allExp
    --if lv == 1 then
    --    return guildexp[1].needExp
    --end
    --return guildexp[lv].allExp - guildexp[lv-1].allExp
    --if lv == #guildexp then
    --    return guildexp[lv].needExp - guildexp[lv-1].needExp
    --end
    --return guildexp[lv+1].needExp - guildexp[lv].needExp
end

function guild.curLvExp(exp)
    exp = exp or guild.guildObj.exp
    local lv = guild.Lv(exp)
    if lv <= 1 then
        return exp
    end
    local curLvExp = exp - guildexp[lv].allExp
    if curLvExp > guild.upLvExp(exp) then
        curLvExp = guild.upLvExp(exp)
    end
    return curLvExp
end

function guild.addExp(_exp)
    if not guild.guildObj then return end      -- 还未同步
    guild.guildObj.exp = guild.guildObj.exp or 0
    guild.guildObj.exp = guild.guildObj.exp + _exp
end

function guild.getTitleStr(_title)
    if _title == TITLE.RESIDENT then
        return i18n.global.guild_title_resident.string
    elseif _title == TITLE.OFFICER then
        return i18n.global.guild_title_officer.string
    elseif _title == TITLE.PRESIDENT then
        return i18n.global.guild_title_president.string
    end
end

function guild.mem_sort(obj1, obj2)
    return obj1.title > obj2.title
end

function guild.showRedDot()
    if not player.gid or player.gid <= 0 then
        return false
    end
    -- 磨坊订单
    local gmill = require "data.guildmill"
    if gmill.showRedDot() then return true end
    if not guild.guildObj then
        return false
    end
    if guild.showRedDotApply() then
        return true
    end
    return false
end

function guild.showRedDotApply()
    if guild.selfTitle() > TITLE.RESIDENT then
        if guild.appliers_count and guild.appliers_count > 0 then
            return true
        end
    end
    return false
end

function guild.deApplyCount()
    if guild.appliers_count and guild.appliers_count > 0 then
        guild.appliers_count = guild.appliers_count - 1
    end
end

function guild.setApplyCount(_count)
    guild.appliers_count = _count
end

function guild.Listen()
    netClient:registGuildEvent(function(__data)
        print("guild notify --------------------")
        tbl2string(__data)
        if not guild.appliers_count then
            guild.appliers_count = 0
        end
        guild.deInit()
        local gtype = __data.type
        if gtype == 1 then   -- new applier
            guild.appliers_count = guild.appliers_count + 1
        elseif gtype == 2 then   -- accept applier
            guild.appliers_count = guild.appliers_count - 1
            if __data.uid and __data.uid == player.uid then
                player.gid = 2  -- just make it sync
            end
        elseif gtype == 3 then   -- refuse applier
            guild.appliers_count = guild.appliers_count - 1
        elseif gtype == 4 then   -- be OFFICER 
            if __data.uid and __data.uid == player.uid then
                guild.self().title = TITLE.OFFICER
            end
            guild.deInit()
        elseif gtype == 5 then   -- benot OFFICER 
            if __data.uid and __data.uid == player.uid then
                guild.self().title = TITLE.RESIDENT
            end
            guild.deInit()
        elseif gtype == 6 then   -- be PRESIDENT
            if __data.uid and __data.uid == player.uid then
                guild.self().title = TITLE.PRESIDENT
            end
            guild.deInit()
        elseif gtype == 7 then   -- somebody sign 
            guild.addExp(guild.SIGN_EXP)
        elseif gtype == 8 then   -- somebody be chased
            guild.deInit()
            if __data.uid and __data.uid == player.uid then
                player.gid = 0
            end
        end
    end)
end

function guild.onlineStatus(diff)
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
		elseif diff < 3600 * 24 * 2 then
			if i18n.getCurrentLanguage() == kLanguageEnglish then
				return i18n.global.guild_mem_status_1d.string
			end
            return string.format(i18n.global.guild_mem_status_nd.string, math.floor(diff/(3600*24)))
        --elseif diff < 3600 * 24 * 10 then
		else
            return string.format(i18n.global.guild_mem_status_nd.string, math.floor(diff/(3600*24)))
        --else
        --    return i18n.global.guild_mem_status_10d.string
        end
    end
end

return guild

