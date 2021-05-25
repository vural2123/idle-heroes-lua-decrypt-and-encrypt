-- 英雄图鉴
local herobook = {}

require "common.const"
require "common.func"

local cfghero = require "config.hero"

function herobook.init(heroIds)
    arrayclear(herobook)
    local heroIds = heroIds or {}
    for _, id in ipairs(heroIds) do
        herobook[#herobook+1] = id
    end
    local headdata = require "data.head"
    headdata.init()
end

function herobook.add(id)
    if not arraycontains(herobook, id) then
        herobook[#herobook+1] = id
        if cfghero[id].qlt >= QUALITY_4 then
            local headdata = require "data.head"
            headdata.add(id)
        end
    end
end

function herobook.print()
    print("---------------- herobook ---------------- {")
    print("[", table.concat(herobook, " "), "]")
    print("---------------- herobook ---------------- }")
end

return herobook
