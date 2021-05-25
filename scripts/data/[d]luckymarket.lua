-- luckymarket infos

local luckymarket = {}

function luckymarket.init(__data, isNewFresh)
    luckymarket.goods = __data.goods
    if isNewFresh then
        luckymarket.refresh = __data.cd + os.time()
    end
end

return luckymarket
