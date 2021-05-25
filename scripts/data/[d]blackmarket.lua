-- blackmarket infos

local blackmarket = {}

function blackmarket.init(__data, isNewFresh)
    local cfgblackmarket = require "config.blackmarket"
    blackmarket.goods = __data.goods
    if isNewFresh then
        local cd = __data.cd
        blackmarket.stack = math.floor(cd / 0x1000000)
        blackmarket.refresh = (cd % 0x1000000) + os.time()

    end
end

return blackmarket
