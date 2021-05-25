local achieve = {}

local cfgachieve = require "config.achievement"

function achieve.clear()
    achieve.achieveInfos = nil
end

function achieve.init(data)
    local achieveInfos = {}
    local ids = data.id or {}
    for _, v in pairs(cfgachieve) do
        if v.isBornAchieve > 0 then
            achieveInfos[v.completeType] = {
                id = _,
                num = data.num[v.completeType],
                isComplete = false,
            }
        end
    end

    local hash = {}
    for i, v in ipairs(ids) do
        hash[v] = true
    end

    for i, v in ipairs(achieveInfos) do
        for j=1, 200 do
            if cfgachieve[v.id].nextAchieveId == 0 or (not hash[v.id]) then
                if hash[v.id] then
                    v.isComplete = true 
                end
                break
            else
                v = {
                    id = cfgachieve[v.id].nextAchieveId,
                    num = data.num[i],
                    isComplete = false,
                }
                achieveInfos[i] = v
            end
        end
    end

    achieve.achieveInfos = achieveInfos
end

function achieve.claim(id)
    local achieveInfos = achieve.achieveInfos 
    if cfgachieve[id].nextAchieveId == 0 then
        achieveInfos[cfgachieve[id].completeType].isComplete = true
    else
        achieveInfos[cfgachieve[id].completeType] = {
            num = achieveInfos[cfgachieve[id].completeType].num,
            isComplete = false,
            id = cfgachieve[id].nextAchieveId,
        }
    end
end

function achieve.add(completeType, num)
    if achieve and achieve.achieveInfos and achieve.achieveInfos[completeType] and achieve.achieveInfos[completeType].num then
        achieve.achieveInfos[completeType].num = achieve.achieveInfos[completeType].num + num
    end
    require("data.appsflyer").addAchieve(completeType, num)
end

function achieve.addCasino(bagdata)
    if not bagdata then return end
    if not bagdata.items or #bagdata.items <= 0 then return end
    local cfgitem = require"config.item"
    local count = 0
    for ii=1,#bagdata.items do
        local tmp_id = bagdata.items[ii].id
        local tmp_item = cfgitem[tmp_id]
        if not tmp_item then return end
        if tmp_item.type == ITEM_KIND_HERO_PIECE and tmp_item.qlt == QUALITY_5 then
            count = count + 1
        end
    end
    achieve.add(ACHIEVE_TYPE_CASINO, count)
end

function achieve.set(completeType, num)
    if achieve and achieve.achieveInfos then
        achieve.achieveInfos[completeType].num = num
    end
    require("data.appsflyer").setAchieve(completeType, num)
end

function achieve.showRedDot()
    if achieve and achieve.achieveInfos then
        for i, v in ipairs(achieve.achieveInfos) do
            if v.num >= cfgachieve[v.id].completeValue and (not v.isComplete) then
                return true
            end
        end
    end
    return false
end

return achieve
