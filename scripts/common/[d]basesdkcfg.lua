local cfg = {}

local cjson = json

require "common.func"
require "common.const"
local netClient = require "net.netClient"
local i18n = require "res.i18n"
local player = require "data.player"
local userdata = require "data.userdata"

function cfg.jsonEncode(params)
    --local cjson = require "cjson"
    print("--------------------------before jsonEncode--------------------")
    local ret =  cjson.encode(params)
    print("--------------------------after jsonEncode--------------------")
    print("ret:", ret)
    return ret
end

function cfg.jsonDecode(params)
    --local cjson = require "cjson"
    print("--------------------------before jsonDecode--------------------")
    print("ret:", params)
    local ret = cjson.decode(params)
    print("--------------------------after jsonDecode--------------------")
    return ret
end

return cfg
