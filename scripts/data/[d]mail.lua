 -- data.mail
local mail = {}

local cfgmail = require "config.mail"
local player = require "data.player"
local NetClient = require "net.netClient"
local netClient = NetClient:getInstance()

mail.TYPE = {
    AFFIX = 1,
    ACTIVITY = 2,
    GUILD = 3,
    SYS = 4,
    PLAYER = 5,
    LINK = 6,
    ALLPLAYER = 7,   --公会所有成员
    LINK2 = 8,
}

mail.is_running = false

local player_mails = {}
local sys_mails = {}

mail.mails = {
    player_mails = player_mails,
    sys_mails = sys_mails,
}

mail.not_reads = 0

function mail.showRedDot()
    if mail.mails and mail.mails.player_mails then
        local tmp_mails = mail.mails.player_mails
        for ii=1,#tmp_mails do
            if 0==tmp_mails[ii].flag then
                return true
            end
        end
    end
    if mail.mails and mail.mails.sys_mails then
        local tmp_mails = mail.mails.sys_mails
        for ii=1,#tmp_mails do
            if 0==tmp_mails[ii].flag then
                return true
            end
        end
    end
    return false
end

function mail.getTypeById(_id)
    if cfgmail[_id] then
        return cfgmail[_id].type
    else
        return nil
    end
end

-- for sort
local FLAGS = {
    [0] = 0,     -- 未读邮件
    [1] = 1,     -- 已读邮件
    [2] = 2,     -- 已领取邮件
}
local function mail_sort(obj1, obj2)
    if not obj1 and obj2 then
        return false
    elseif obj1 and not obj2 then
        return true
    elseif not obj1 and not obj2 then
        return true
    elseif FLAGS[obj1.flag] < FLAGS[obj2.flag] then
        return true
    elseif FLAGS[obj1.flag] > FLAGS[obj2.flag] then
        return false
    elseif FLAGS[obj1.flag] == FLAGS[obj2.flag] then
        if cfgmail[obj1.id].type < cfgmail[obj2.id].type then
            return true
        elseif cfgmail[obj1.id].type > cfgmail[obj2.id].type then
            return false
        elseif cfgmail[obj1.id].type == cfgmail[obj2.id].type then
            return obj1.send_time > obj2.send_time
        end
    end
end

local function addPlayerMail(obj)
    if not player_mails then
        player_mails = {}
    end
    player_mails[#player_mails + 1] = obj
    table.sort(player_mails, mail_sort)
end

local function addSysMail(obj)
    if not sys_mails then
        sys_mails = {}
    end
    sys_mails[#sys_mails + 1] = obj
    table.sort(sys_mails, mail_sort)
end

local function addMail(obj)
    if not obj then return end
    if not cfgmail[obj.id] then return end
    if cfgmail[obj.id].type == mail.TYPE.PLAYER then
        addPlayerMail(obj)
    elseif cfgmail[obj.id].type == mail.TYPE.ALLPLAYER then
        addPlayerMail(obj)
    else
        addSysMail(obj)
    end
end

function mail.addMails(objs)
    if not objs then return end
    for ii=1,#objs do
        addMail(objs[ii])
    end
end

function mail.delPlayer(obj)
    for ii=1, #player_mails do
        if player_mails[ii] == obj then
            table.remove(player_mails, ii)
            break
        end
    end
end

function mail.delSys(obj)
    for ii=1, #sys_mails do
        if sys_mails[ii] == obj then
            table.remove(sys_mails, ii)
            break
        end
    end
end

function mail.netDel(obj, callback)
    local params = {
        sid = player.sid,
        deletes = {[1]=obj.mid,}
    }
    netClient:op_mail(params, callback)
end

function mail.del(obj)
    if not obj then return end
    if cfgmail[obj.id].type == mail.TYPE.PLAYER then
        mail.delPlayer(obj)
    elseif cfgmail[obj.id].type == mail.TYPE.ALLPLAYER then
        mail.delPlayer(obj)
    else
        mail.delSys(obj)
    end
end

function mail.read(mid, callback)
    local params = {
        sid = player.sid,
        reads = {[1]=mid,}
    }
    netClient:op_mail(params, callback)
end

function mail.block(uid, callback)
    local params = {
        sid = player.sid,
        blocks = {[1]=uid,}
    }
    netClient:op_mail(params, callback)
end

function mail.affix(mids, callback)
    local params = {
        sid = player.sid,
        affixs = mids,
    }
    netClient:op_mail(params, callback)
end

function mail.flagByMids(mids)
    for ii=1,#mids do
        for jj=1,#sys_mails do
            if sys_mails[jj].mid == mids[ii] then
                sys_mails[jj].flag = 2
                break
            end
        end
    end
end

function mail.send(params, callback)
    netClient:send_mail(params, callback)
end

function mail.init(mailObjs)
    player_mails = {}
    sys_mails = {}
    mail.mails = {
        player_mails = player_mails,
        sys_mails = sys_mails,
    }
    mail.addMails(mailObjs)
end

function mail.getPlayerMails()
    table.sort(player_mails, mail_sort)
    return player_mails
end

function mail.getSysMails()
    table.sort(sys_mails, mail_sort)
    return sys_mails
end

local function onMail(data)
    cclog("onMail data")
    tbl2string(data)
    addMail(data)
end

local function onOpMail(data)
    cclog("onOpMail data")
    tbl2string(data)
end

function mail.registEvent()
    netClient:registMailEvent(onMail)
end

function mail.print()
    if mail.mails then
        tbl2string(mail.mails)
    end
end

return mail
