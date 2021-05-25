local m = {}

m.eventName = {
    ["10_4_star"] = "10_4_star",
    ["20_4_star"] = "20_4_star",
    ["s1lv3_map"] = "s1lv3_map",
    ["s1lv4_map"] = "s1lv4_map",
    ["10_hs"] = "10_hs",
    ["lv5_to"] = "lv5_to",
    ["lv10_to"] = "lv10_to",
    ["lv15_to"] = "lv15_to",
    ["lv5_bt"] = "lv5_bt",
    ["lv10_bt"] = "lv10_bt",
    ["2_5_star"] = "2_5_star",
    ["10_altar"] = "10_altar",
    ["20_altar"] = "20_altar",
    ["5_lv31"] = "5_lv31",
    ["10_cc"] = "10_cc",
    ["10_bs"] = "10_bs",
    ["1200p_ccl"] = "1200p_ccl",
    ["10_ccl"] = "10_ccl",
    ["20_Green_equip"] = "20_Green_equip",
    ["10_4_star_Tavern"] = "10_4_star_Tavern",
    ["5_Marauders"] = "5_Marauders",
    ["5_star_cc"] = "5_star_cc",
}

local achieveMap = {
    ["101"] = m.eventName["10_4_star"],
    ["102"] = m.eventName["20_4_star"],
    ["403"] = m.eventName["s1lv3_map"],
    ["404"] = m.eventName["s1lv4_map"],
}

function m.report(ename)
    if APP_CHANNEL and APP_CHANNEL ~= "" then
        return
    end
    if not ename or ename == "" then return end
    HHUtils:trackDHAppsFlyer(ename, "1", "1")
end

function m.addAchieve(completeType, num)
    local achieveData = require"data.achieve"
    local count = 0
    if achieveData.achieveInfos[completeType] and achieveData.achieveInfos[completeType].num then
        count = achieveData.achieveInfos[completeType].num
    end
    local pre_num = count - num
    local ename = ""
    if completeType == ACHIEVE_TYPE_GET_HERO_STAR4 then
        if pre_num < 10 and count >= 10 then
            ename = m.eventName["10_4_star"]
        elseif pre_num < 20 and count >= 20 then
            ename = m.eventName["20_4_star"]
        end
    elseif completeType == ACHIEVE_TYPE_GET_HERO_STAR5 then
        if pre_num < 2 and count >= 2 then
            ename = m.eventName["2_5_star"]
        end
    elseif completeType == ACHIEVE_TYPE_DECOMPOSE_HERO then
        if pre_num < 10 and count >= 10 then
            ename = m.eventName["10_altar"]
        elseif pre_num < 20 and count >= 20 then
            ename = m.eventName["20_altar"]
        end
    elseif completeType == ACHIEVE_TYPE_ARENA_ATTACK then
        if pre_num < 10 and count >= 10 then
            ename = m.eventName["10_ccl"]
        end
    elseif completeType == ACHIEVE_TYPE_GET_EQUIP_GREEN then
        if pre_num < 20 and count >= 20 then
            ename = m.eventName["20_Green_equip"]
        end
    elseif completeType == ACHIEVE_TYPE_COMPLETE_HEROTASK4 then
        if pre_num < 10 and count >= 10 then
            ename = m.eventName["10_4_star_Tavern"]
        end
    elseif completeType == ACHIEVE_TYPE_CASINO then
        if pre_num < 1 and count >= 1 then
            ename = m.eventName["5_star_cc"]
        end
    elseif completeType == ACHIEVE_TYPE_BRAVE then
        if pre_num < 5 and count >= 5 then
            ename = m.eventName["lv5_bt"]
        elseif pre_num < 10 and count >= 10 then
            ename = m.eventName["lv10_bt"]
        end
    end
    if ename and ename ~= "" then
        m.report(ename)
    end
end

function m.setAchieve(completeType, num)
    local ename = ""
    if completeType == ACHIEVE_TYPE_PASS_FORT then
        if num == 3 then
            ename = m.eventName["s1lv3_map"]
        elseif num == 4 then
            ename = m.eventName["s1lv4_map"]
        end
    elseif completeType == 6001 then
        if num == 5 then
            ename = m.eventName["lv5_to"]
        elseif num == 10 then
            ename = m.eventName["lv10_to"]
        elseif num == 15 then
            ename = m.eventName["lv15_to"]
        end
    end
    if ename and ename ~= "" then
        m.report(ename)
    end
end

return m
