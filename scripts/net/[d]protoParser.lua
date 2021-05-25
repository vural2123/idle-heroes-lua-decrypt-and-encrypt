-- protoParser

local protoParser = {}

local descriptor = require "descriptor"
local FieldDescriptor = descriptor.FieldDescriptor

function protoParser.parsePbPlayer(obj)
    local data = {}
    if not obj then return data end
    data.name = obj.name
    data.logo = obj.logo
    if obj:HasField("gid") then
        data.gid = obj.gid
    end
    if obj:HasField("gname") then
        data.gname = obj.gname
    end
    return data
end

function protoParser.parsePbItem(obj)
    local data = {}
    if not obj then return data end
    data.id = obj.id
    data.num = obj.num
    return data
end

function protoParser.parsePbBag(obj)
    local data = {}
    if not obj then return data end
    if obj.items then
        data.items = {}
        for ii=1,#obj.items do
            data.items[ii] = protoParser.parsePbItem(obj.items[ii])
        end
    end
    if obj.equips then
        data.equips = {}
        for ii=1,#obj.equips do
            data.equips[ii] = protoParser.parsePbEquip(obj.equips[ii])
        end
    end
    return data
end

function protoParser.parsePbGacha(obj)
    print("gacha.item", obj.item, "gacha.gem", obj.gem)
    local data = {}
    if not obj then return data end
    data.item = obj.item
    data.gem = obj.gem
    return data
end

function protoParser.parsePbServer(obj)
    local data = {}
    if not obj then return data end
    data.id = obj.id
    data.ip = obj.ip
    data.port = obj.port
    data.name = obj.name
    data.status = obj.status
    data.language = obj.language
    if obj:HasField("nickname") then
        data.nickname = obj.nickname
    end
    return data
end

function protoParser.parsePbrspEcho(obj)
    local data = {}
    if not obj then return data end
    data.echo = obj.echo
    return data
end

function protoParser.parsePbrspReg(obj)
    local data = {}
    if not obj then return data end
    data.status = obj.status
    if obj:HasField("uid") then
        data.uid = obj.uid
    end
    if obj:HasField("account") then
        data.account = obj.account
    end
    if obj:HasField("password") then
        data.password = obj.password
    end
    return data
end

function protoParser.parsePbrspSalt(obj)
    local data = {}
    if not obj then return data end
    data.status = obj.status
    if obj:HasField("salt") then
        data.salt = obj.salt
    end
    if obj:HasField("uid") then
        data.uid = obj.uid
    end
    return data
end

function protoParser.parsePbrspLogin(obj)
    local data = {}
    if not obj then return data end
    data.status = obj.status
    if obj:HasField("session") then
        data.session = obj.session
    end
    if obj:HasField("sid") then
        data.sid = obj.sid
    end
    if obj:HasField("is_formal") then
        data.is_formal = obj.is_formal
    end
    return data
end

function protoParser.parsePbrspAuth(obj)
    local data = {}
    if not obj then return data end
    data.status = obj.status
    if obj:HasField("cid") then
        data.cid = obj.cid
    end
    return data
end

function protoParser.parsePbrspSync(obj)
    local data = {}
    if not obj then return data end
    data.status = obj.status
    if obj:HasField("player") then
        data.player = protoParser.parsePbPlayer(obj.player)
    end
    if obj:HasField("bag") then
        data.bag = protoParser.parsePbBag(obj.bag)
    end
    if obj.heroes then
        data.heroes = {}
        for ii=1,#obj.heroes do
            data.heroes[ii] = protoParser.parsePbHero(obj.heroes[ii])
        end
    end
    if obj:HasField("gacha") then
        data.gacha = protoParser.parsePbGacha(obj.gacha)
    end
    if obj.hero_ids then
        data.hero_ids = {}
        for ii=1,#obj.hero_ids do
            data.hero_ids[ii] = obj.hero_ids[ii]
        end
    end
    if obj.mails then
        data.mails = {}
        for ii=1,#obj.mails do
            data.mails[ii] = protoParser.parsePbMail(obj.mails[ii])
        end
    end
    return data
end

function protoParser.parsePbrspGacha(obj)
    local data = {}
    if not obj then return data end
    data.status = obj.status
    if obj:HasField("gem") then
        data.gem = obj.gem
    end
    if obj.heroes then
        data.heroes = {}
        for ii=1,#obj.heroes do
            data.heroes[ii] = protoParser.parsePbHero(obj.heroes[ii])
        end
    end
    if obj.items then
        data.items = {}
        for ii=1,#obj.items do
            data.items[ii] = protoParser.parsePbItem(obj.items[ii])
        end
    end
    return data
end

function protoParser.parsePbMail(obj)
    local data = {}
    if not obj then return data end
    data.mid = obj.mid
    data.id = obj.id
    data.flag = obj.flag
    data.send_time = obj.send_time
    if obj:HasField("title") then
        data.title = obj.title
    end
    if obj:HasField("from") then
        data.from = obj.from
    end
    if obj:HasField("content") then
        data.content = obj.content
    end
    if obj:HasField("affix") then
        data.affix = protoParser.parsePbBag(obj.affix)
    end
    return data
end

function protoParser.parsePbrspOpMail(obj)
    local data = {}
    if not obj then return data end
    data.status = obj.status
    if obj:HasField("affix") then
        data.affix = protoParser.parsePbBag(obj.affix)
    end
    return data
end

local _obj2Tbl
_obj2Tbl = function(data, msg)
    for field, value in msg:ListFields() do
        local name = field.name
        -- array
        if field.label == FieldDescriptor.LABEL_REPEATED then
            if not data[name] then data[name] = {} end
            for idx, k in ipairs(value) do
                if field.type == FieldDescriptor.TYPE_MESSAGE then
                    data[name][idx] = {}
                    _obj2Tbl(data[name][idx], k)
                else
                    data[name][idx] = k
                end
            end
        -- msg
        elseif field.type == FieldDescriptor.TYPE_MESSAGE then
            if not data[name] then data[name] = {} end
            _obj2Tbl(data[name], value)
        -- plain field
        else
            data[name] = value
        end
    end
end

function protoParser.obj2Tbl(obj)
    local data = {}
    if not obj then return data end
    _obj2Tbl(data, obj)
    return data
end

return protoParser
