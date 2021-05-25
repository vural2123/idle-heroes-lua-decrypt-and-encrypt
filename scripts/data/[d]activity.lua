local activity = {}

local player = require "data.player"
local NetClient = require "net.netClient"
local netClient = NetClient:getInstance()

-- test data
activity.pull_time = os.time()

local IDS = {
    FIRST_PAY        = { ID = 1,     pull = true },
    MONTH_LOGIN      = { ID = 2,     pull = true },
    MONTH_CARD       = { ID = 3,     pull = false },
    MINI_CARD        = { ID = 43,    pull = false },
    WEEKLY_GIFT      = { ID = 5,     pull = true },
    WEEKLY_GIFT_2    = { ID = 6,     pull = true },
    WEEKLY_GIFT_3    = { ID = 7,     pull = true },
    WEEKLY_GIFT_4    = { ID = 8,     pull = true },
    MONTHLY_GIFT     = { ID = 9,     pull = true },
    MONTHLY_GIFT_2   = { ID = 10,    pull = true },
    MONTHLY_GIFT_3   = { ID = 11,    pull = true },
    MONTHLY_GIFT_4   = { ID = 12,    pull = true },
    MONTHLY_GIFT_5   = { ID = 13,    pull = true },
    MONTHLY_GIFT_6   = { ID = 14,    pull = true },
    SUMMON_HERO_1    = { ID = 1511,   pull = true },
    SUMMON_HERO_2    = { ID = 1512,   pull = true },
    SUMMON_HERO_3    = { ID = 208,   pull = true },
    SUMMON_HERO_4    = { ID = 209,   pull = true },
    SUMMON_HERO_5    = { ID = 210,    pull = true },
    SUMMON_HERO_6    = { ID = 211,    pull = true },
    SCORE_SPESUMMON  = { ID = 1458,    pull = true },
    SCORE_CASINO     = { ID = 1485,    pull = true },
    SCORE_SUMMON     = { ID = 1521,    pull = true },
    SCORE_FIGHT      = { ID = 1540,    pull = true },
    SCORE_FIGHT2     = { ID = 1543,    pull = true },
    SCORE_FIGHT3     = { ID = 1544,    pull = true },
    SCORE_TARVEN_4   = { ID = 1486,    pull = true },
    SCORE_TARVEN_5   = { ID = 1487,    pull = true },
    SCORE_TARVEN_6   = { ID = 1488,    pull = true },
    SCORE_TARVEN_7   = { ID = 1489,    pull = true },
    CRUSHING_SPACE_1   = { ID = 1496,    pull = true },
    CRUSHING_SPACE_2   = { ID = 410,    pull = true },
    CRUSHING_SPACE_3   = { ID = 411,    pull = true },
    VP_1             = { ID = 1527,    pull = true },
    VP_2             = { ID = 1528,    pull = true },
    VP_3             = { ID = 1529,    pull = true },
    VP_4             = { ID = 1530,    pull = true },
    --VP_5             = { ID = 1510,    pull = true },
    --VP_6             = { ID = 1312,    pull = true },
    --VP_7             = { ID = 444,    pull = true },
    BLACKBOX_1       = { ID = 1466,    pull = true }, --春季礼盒
    BLACKBOX_2       = { ID = 1467,    pull = true },
    BLACKBOX_3       = { ID = 1468,    pull = true },
    BLACKBOX_4       = { ID = 1469,    pull = true },
    BLACKBOX_5       = { ID = 1470,    pull = true },
    FORGE_1          = { ID = 1523,    pull = true },  -- 6 stars
    FORGE_2          = { ID = 1522,    pull = true },  -- 5 stars
    EXCHANGE         = { ID = 1445,   pull = true },
    ICEBABY_1        = { ID = 977,   pull = true },       -- 甜心巧克力
    ICEBABY_2        = { ID = 978,   pull = true },
    ICEBABY_3        = { ID = 979,   pull = true },
    ICEBABY_4        = { ID = 980,   pull = true },
    ICEBABY_5        = { ID = 981,   pull = true },
    ICEBABY_6        = { ID = 982,   pull = true },
    ICEBABY_7        = { ID = 983,   pull = true },
    ICEBABY_8        = { ID = 182,   pull = true },
    SPRINGBABY_1        = { ID = 304,   pull = true },
    SPRINGBABY_2        = { ID = 305,   pull = true },
    SPRINGBABY_3        = { ID = 306,   pull = true },
    SPRINGBABY_4        = { ID = 307,   pull = true },
    SPRINGBABY_5        = { ID = 308,   pull = true },
    SPRINGBABY_6        = { ID = 309,   pull = true },
    SPRINGBABY_7        = { ID = 310,   pull = true },
    SPRINGBABY_8        = { ID = 311,   pull = true },
    CDKEY               = { ID = 20001,     pull = true },   -- 礼包兑换活动
    FISHBABY_1        = { ID = 1497,   pull = true },        -- 
    FISHBABY_2        = { ID = 1498,   pull = true },
    FISHBABY_3        = { ID = 1499,   pull = true },
    FISHBABY_4        = { ID = 999,   pull = true },
    FISHBABY_5        = { ID = 999,   pull = true },
    FISHBABY_6        = { ID = 999,   pull = true },
    FISHBABY_7        = { ID = 999,   pull = true },
    FISHBABY_8        = { ID = 999,   pull = true },
    FISHBABY_9        = { ID = 999,   pull = true },
    FISHBABY_10       = { ID = 999,   pull = true },
    FISHBABY_11       = { ID = 999,   pull = true },
    FISHBABY_12       = { ID = 425,   pull = true },
    FOLLOW            = { ID = 1386,   pull = true },
    AWAKING_GLORY_1   = { ID = 535,   pull = true },
    AWAKING_GLORY_2   = { ID = 536,   pull = true },
    HERO_SUMMON_1     = { ID = 1531,   pull = true },
    HERO_SUMMON_2     = { ID = 1532,   pull = true },
    HERO_SUMMON_3     = { ID = 1533,   pull = true },
    HERO_SUMMON_4     = { ID = 1534,   pull = true },
    HERO_SUMMON_5     = { ID = 1535,   pull = true },
    HERO_SUMMON_6     = { ID = 1536,   pull = true },
    HERO_SUMMON_7     = { ID = 1537,   pull = true },
    BIGFUSE         = { ID = 998,   pull = true },
    TENCHANGE         = { ID = 997,   pull = true },
    BLACKCARD         = { ID = 1307,   pull = true },
    CHRISTMAS_1        = { ID = 1313,   pull = true },        -- (兑换商店)古代石碑
    CHRISTMAS_2        = { ID = 1314,   pull = true },
    CHRISTMAS_3        = { ID = 1315,   pull = true },
    CHRISTMAS_4        = { ID = 1316,   pull = true },
    CHRISTMAS_5        = { ID = 1317,   pull = true },
    CHRISTMAS_6        = { ID = 1318,   pull = true },
    CHRISTMAS_7        = { ID = 1319,   pull = true },
    CHRISTMAS_8        = { ID = 1320,   pull = true },
    CHRISTMAS_9        = { ID = 1321,   pull = true },
    CHRISTMAS_10       = { ID = 1322,   pull = true },
    CHRISTMAS_11       = { ID = 1323,   pull = true },
    CHRISTMAS_12       = { ID = 1324,   pull = true },
    CHRISTMAS_13       = { ID = 1325,   pull = true },
    ASYLUM_1           = { ID = 1500,   pull = true },
    ASYLUM_2           = { ID = 1501,   pull = true },
    ASYLUM_3           = { ID = 1502,   pull = true },
    --ASYLUM_4           = { ID = 1348,   pull = true },
    --ASYLUM_5           = { ID = 1349,   pull = true },
    --ASYLUM_6           = { ID = 1350,   pull = true },
    NEWYEAR            = { ID = 1098,   pull = true }, -- 石像怪
    WEEKYEARBOX_1       = { ID = 1351,   pull = true }, -- 周年礼盒
    WEEKYEARBOX_2       = { ID = 1352,   pull = true }, -- 周年礼盒
    WEEKYEARBOX_3       = { ID = 1353,   pull = true }, -- 周年礼盒
    DWARF_1            = { ID = 1354,   pull = true }, -- 矮人祝福
    DWARF_2            = { ID = 1355,   pull = true }, 
    DWARF_3            = { ID = 1356,   pull = true }, 
}

activity.IDS = IDS

local IDSKeys = {
    "FIRST_PAY",
    "MONTH_LOGIN",
    "MONTH_CARD",
    "MINI_CARD",
    "WEEKLY_GIFT",
    "WEEKLY_GIFT_2",
    "WEEKLY_GIFT_3",
    "WEEKLY_GIFT_4",
    "MONTHLY_GIFT",
    "MONTHLY_GIFT_2",
    "MONTHLY_GIFT_3",
    "MONTHLY_GIFT_4",
    "MONTHLY_GIFT_5",
    "MONTHLY_GIFT_6",
    "SUMMON_HERO_1",
    "SUMMON_HERO_2",
    "SUMMON_HERO_3",
    "SUMMON_HERO_4",
    "SUMMON_HERO_5",
    "SUMMON_HERO_6",
    "SCORE_SPESUMMON",
    "SCORE_CASINO",
    "SCORE_SUMMON",
    "SCORE_FIGHT",
    "SCORE_FIGHT2",
    "SCORE_FIGHT3",
    "SCORE_TARVEN_4",
    "SCORE_TARVEN_5",
    "SCORE_TARVEN_6",
    "SCORE_TARVEN_7",
    "CRUSHING_SPACE_1",
    "CRUSHING_SPACE_2",
    "CRUSHING_SPACE_3",
    "VP_1",
    "VP_2",
    "VP_3",
    "VP_4",
    "VP_5",
    "VP_6",
    "VP_7",
    "BLACKBOX_1",
    "BLACKBOX_2",
    "BLACKBOX_3",
    "BLACKBOX_4",
    "BLACKBOX_5",
    "FORGE_1",
    "FORGE_2",
    "EXCHANGE",
    "ICEBABY_1",
    "ICEBABY_2",
    "ICEBABY_3",
    "ICEBABY_4",
    "ICEBABY_5",
    "ICEBABY_6",
    "ICEBABY_7",
    "ICEBABY_8",
    "SPRINGBABY_1",
    "SPRINGBABY_2",
    "SPRINGBABY_3",
    "SPRINGBABY_4",
    "SPRINGBABY_5",
    "SPRINGBABY_6",
    "SPRINGBABY_7",
    "SPRINGBABY_8",
    "CDKEY",
    "FISHBABY_1",
    "FISHBABY_2",
    "FISHBABY_3",
    "FISHBABY_4",
    "FISHBABY_5",
    "FISHBABY_6",
    "FISHBABY_7",
    "FISHBABY_8",
    "FISHBABY_9",
    "FISHBABY_10",
    "FISHBABY_11",
    "FISHBABY_12",
    "FOLLOW",
    "AWAKING_GLORY_1",
    "AWAKING_GLORY_2",
    "HERO_SUMMON_1",
    "HERO_SUMMON_2",
    "HERO_SUMMON_3",
    "HERO_SUMMON_4",
    "HERO_SUMMON_5",
    "HERO_SUMMON_6",
    "HERO_SUMMON_7",
    "TENCHANGE",
    "BLACKCARD",
    "CHRISTMAS_1",
    "CHRISTMAS_2",
    "CHRISTMAS_3",
    "CHRISTMAS_4",
    "CHRISTMAS_5",
    "CHRISTMAS_6",
    "CHRISTMAS_7",
    "CHRISTMAS_8",
    "CHRISTMAS_9",
    "CHRISTMAS_10",
    "CHRISTMAS_11",
    "CHRISTMAS_12",
    "CHRISTMAS_13",
    "ASYLUM_1",
    "ASYLUM_2",
    "ASYLUM_3",
    "ASYLUM_4",
    "ASYLUM_5",
    "ASYLUM_6",
    "NEWYEAR",
    "DAILY_REWARD_MAIL",
    "WEEKYEARBOX_1",
    "WEEKYEARBOX_2",
    "WEEKYEARBOX_3",
    "DWARF_1",
    "DWARF_2",
    "DWARF_3",
    "DWARF_4",
    "DWARF_5",
    "BIGFUSE",
}

function activity.initgrp(ls)
    ls = ls or {}
    local cur_i = 1
    local high_i = #ls
    local str_id = nil
    local num_id = nil
    local str_name = nil
    local pull_b = nil
    while cur_i < high_i do
        str_id = ls[cur_i]
        num_id = ls[cur_i + 1]
        str_name = IDSKeys[str_id] or "ERROR"
        pull_b = activity.IDS[str_name]
        if pull_b then
            pull_b = pull_b.pull or true
        else
            pull_b = true
        end
        activity.IDS[str_name] = { ID = num_id, pull = pull_b }
        cur_i = cur_i + 2
    end
end

local activity_data = nil

-- 初始化，pb为proto_get_activity_status_back
function activity.init(pb)
    activity_data = pb.status
    activity.redid = {}
    activity.limitRedid = {}
    activity.pull_time = os.time()
    
    if not activity_data then activity_data = {} end
    local cfgactivity = require "config.activity"
    
    if activity_data then
        for ii=1,#activity_data do
			local cur = activity_data[ii]
            if cur.id <= 3 then
                
            elseif cur.cd and cur.cd > 0 then
				if cur.cd < 4838400 then
					cur.read = 0
				end
                if not cur.status then
                    cur.status = 0
                end
            end
			if not cur.cfg then
				cur.cfg = cfgactivity[cur.id]
			end
        end
        for i=1,#activity_data do
            if activity_data[i].id == IDS.WEEKLY_GIFT.ID or activity_data[i].id == IDS.MONTHLY_GIFT.ID then
                activity.redid[#activity.redid+1] = activity_data[i]
            end
        end
        for i=1,#activity_data do
            if activity_data[i].id == IDS.SCORE_CASINO.ID or activity_data[i].id == IDS.SCORE_FIGHT.ID 
                or activity_data[i].id == IDS.VP_1.ID or activity_data[i].id == IDS.SCORE_TARVEN_4.ID
                or activity_data[i].id == IDS.FORGE_1.ID or activity_data[i].id == IDS.SUMMON_HERO_1.ID
                or activity_data[i].id == IDS.SCORE_SUMMON.ID or activity_data[i].id == IDS.CRUSHING_SPACE_1.ID
                or activity_data[i].id == IDS.CRUSHING_SPACE_2.ID or activity_data[i].id == IDS.CRUSHING_SPACE_3.ID 
                or activity_data[i].id == IDS.FISHBABY_1.ID or activity_data[i].id == IDS.FOLLOW.ID 
                or activity_data[i].id == IDS.SCORE_SPESUMMON.ID or activity_data[i].id == IDS.EXCHANGE.ID
                or activity_data[i].id == IDS.AWAKING_GLORY_1.ID or activity_data[i].id == IDS.HERO_SUMMON_1.ID
                or activity_data[i].id == IDS.TENCHANGE.ID or activity_data[i].id == IDS.BLACKCARD.ID
                or activity_data[i].id == IDS.CHRISTMAS_1.ID or activity_data[i].id == IDS.ASYLUM_1.ID 
                or activity_data[i].id == IDS.NEWYEAR.ID then
                activity.limitRedid[#activity.limitRedid+1] = activity_data[i]
            end
        end
    end
end

function activity.getStatusById(id)
    if id == activity.IDS.MONTH_LOGIN.ID then
        local monthloginData = require "data.monthlogin"
        if monthloginData.isEnd() then
            return { status = 1, }
        else
            return { status = 0, }
        end
    elseif id == activity.IDS.CDKEY.ID then
        if isAmazon() then
            return {status=1}
        elseif isChannel() then
            return {status=0}
        else
            return {status=1}
        end
    elseif id == activity.IDS.MONTH_CARD.ID then
        return {status=0}
    elseif id == activity.IDS.MINI_CARD.ID then
        return {status=0}
    elseif id == activity.IDS.FOLLOW.ID then
        if APP_CHANNEL and APP_CHANNEL == "MSDK" then
            return {status=1}
        end
    end
    if not activity_data then return nil end
    for ii=1,#activity_data do
        if activity_data[ii].id == id then
            return activity_data[ii]
        end
    end
    return nil
end

function activity.find(id)
	return activity.getStatusById(id)
end

function activity.getPullIds()
    local ids = {}
    for _, info in pairs(activity.IDS) do
        if info.pull then
            ids[#ids+1] = info.ID
        end
    end
    return ids
end

function activity.pay()
    if not activity_data then return end
    local tmp_status = activity.getStatusById(activity.IDS.FIRST_PAY.ID)
    if not tmp_status then return end
    if tmp_status.status == 0 then
        tmp_status.status = 1
    end
end

function activity.showRedDot()
    if not activity.redid or #activity.redid == 0 then return false end
    for ii=1,#activity.redid do
        if activity.redid[ii].read and activity.redid[ii].read == 0 then
            return true
        end
    end 
    return false
end

function activity.anyNew()
    local monthloginData = require "data.monthlogin"
    if monthloginData.showRedDot() then return true end
    local shopData = require "data.shop"
    if shopData.showRedDot() then return true end
    if shopData.showRedDot2() then return true end
    if activity.showRedDot() then
        return true
    end
    --if not activity_data or #activity_data == 0 then return false end
    --for ii=1,#activity_data do
    --    if cfgactivity[activity_data[ii].id].actType == 5 or cfgactivity[activity_data[ii].id].actType == 6 then 
    --        if activity_data[ii].and activity_data[ii].read and activity_data[ii].read == 0 then
    --            return true
    --        end
    --    end
    --end
    return false
end


function activity.showRedDotLimit()
    if not activity.limitRedid or #activity.limitRedid == 0 then return false end
    for ii=1,#activity.limitRedid do
        if activity.limitRedid[ii].read and activity.limitRedid[ii].read == 0 then
            return true
        end
    end 
    return false
end

function activity.setReadById(_id)
    if not activity_data then return nil end
    local tmp_status = activity.getStatusById(_id)
    if not tmp_status then
        print("can't find the activity id:", _id)
        return 
    end
    if tmp_status.read and tmp_status.read == 0 then
        tmp_status.read = 1
        --local tmp_params = {
        --    id = _id,
        --}
        --netClient:set_activity_read(tmp_params, function(__data)
        --    print("set read ok. id:", _id)
        --end)
    end
end

function checkIH()
end

function activity.addScore(id, count)
    count = count or 1
    local scoreStatus = activity.getStatusById(id)
    if scoreStatus and scoreStatus.limits then
        scoreStatus.limits = scoreStatus.limits + count
    end
    if not scoreStatus then return end
    if id == IDS.SCORE_FIGHT.ID then
        if scoreStatus.limits and scoreStatus.limits >= 30 then
            checkIH()
        end
    end
end

function activity.print()
    print("--------- activity --------- {")
    for _, info in pairs(activity_data) do
        local str = {}
        table.insert(str, string.format("id:%d", info.id))
        if info.status then
            table.insert(str, string.format("status:%d", info.status))
        end
        if info.cd then
            table.insert(str, string.format("cd:%d", info.cd))
        end
        if info.limits then
            table.insert(str, string.format("limits:%d", info.limits))
        end
        if info.read then
            table.insert(str, string.format("read:%d", info.read))
        end
        print(table.concat(str, " "))
    end
    print("--------- activity --------- }")
end

return activity
