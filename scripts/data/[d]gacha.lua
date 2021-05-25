-- gacha infos

local gacha = {}

require "common.const"
require "common.func"

-- param: pb_gacha
function gacha.init(pb)
    local now = os.time()
    gacha.item = pb.item + now
    gacha.gem = pb.gem + now
end

function gacha.initspacesummon(spaceid)
    gacha.spacesummon = spaceid
end

function gacha.print()
    print("--------- gacha --------- {")
    print("item:", gacha.item, "gem:", gacha.gem, "gachaspaceid:", gacha.spacesummon)
    print("--------- gahca --------- }")
end

function gacha.showRedDot()
    local now = os.time()
    if gacha.item == nil or gacha.gem == nil then
        return false
    end
    if now >= gacha.item or now >= gacha.gem then
        return true
    end
    return false
end

return gacha


