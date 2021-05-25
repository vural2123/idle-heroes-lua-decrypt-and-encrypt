local pubs = {}

local cjson = json
local i18n = require "res.i18n"
local userdata = require "data.userdata"

local DELIMITER = "|||||"

function pubs.init()
    local s = userdata.getString(userdata.keys.notice)
    local ss = string.split(s, DELIMITER)
    if #ss == 3 then
        local l = tonumber(ss[1], 10)
        local v = tonumber(ss[2], 10)
        local p = ss[3]
        local c = i18n.getCurrentLanguage()
        if l and v and p ~= "" and l == c then
            pubs.language = l
            pubs.vsn = v
            pubs.pub = p
            return true
        end
    end
    return false
end

function pubs.getPub()
    if pubs.pub or pubs.init() then
        local tpub = cjson.decode(pubs.pub)
        if tpub and tpub.pub then
            return tpub.pub
        end
    end
    return {}
end

function pubs.save(lang, vsn, pub)
    pubs.language = lang
    pubs.vsn = vsn
    pubs.pub = pub
    local s = table.concat({ lang, vsn, pub }, DELIMITER)
    userdata.setString(userdata.keys.notice, s)
end

function pubs.print()
    print("----- pubs ----- {")
    print("language", pubs.language)
    print("vsn", pubs.vsn)
    print("pub", pubs.pub)
    print("----- pubs ----- }")
end

return pubs
