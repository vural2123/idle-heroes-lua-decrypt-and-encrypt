local activitylimit = {}

local player = require "data.player"
local NetClient = require "net.netClient"
local netClient = NetClient:getInstance()
local cfglimitgift = require "config.limitgift"
local cfgactivity = require "config.activity"

-- test data
activitylimit.pull_time = os.time()

local IDS = {
    GRADE_24 = { ID = 21,     pull = true },
    GRADE_32 = { ID = 22,     pull = true },
    GRADE_48 = { ID = 23,     pull = true },
    GRADE_58 = { ID = 24,     pull = true },
    GRADE_78 = { ID = 25,     pull = true },
    LEVEL_3_15 = { ID = 31,     pull = true },
    SUMMON_4 = { ID = 41,     pull = true },
    SUMMON_5 = { ID = 42,     pull = true },
}

activitylimit.IDS = IDS

local activitylimit_data = nil

-- 初始化，pb为proto_get_activitylimit_status_back
function activitylimit.init(pb)
    activitylimit_data = pb.status
    activitylimit.pull_time = os.time()
    -- 有倒计时的活动 初始化做红点标记
    if activitylimit_data then
        for ii=1,#activitylimit_data do
			local cur = activitylimit_data[ii]
            if cur.id <= 3 then
                
            elseif cur.cd and cur.cd > 0 and cur.cd < 4838400 then -- has cd but less than 2 months
                cur.read = 0
            end
			if not cur.cfg then
				cur.cfg = cfgactivity[cur.id]
			end
        end
    end
end

function activitylimit.showLimit()
--[[    local activity = require "data.activity" 
    if activitylimit_data and #activitylimit_data > 0 then
        for i=1, #activitylimit_data do
            if activitylimit_data[i].status == 0 then
                return true
            end
        end
    end
    local fpay_status = activity.getStatusById(activity.IDS.FIRST_PAY.ID)
    if fpay_status and fpay_status.status ~= 2 and fpay_status.cd ~= 0 then
        return true
    end
    local sccasino_status = activity.getStatusById(activity.IDS.SCORE_CASINO.ID)
    if sccasino_status and sccasino_status.cd ~= 0 then
        return true
    end
    local scfight_status = activity.getStatusById(activity.IDS.SCORE_FIGHT.ID)
    if scfight_status and scfight_status.cd ~= 0 then
        return true
    end
    local valuepack_status = activity.getStatusById(activity.IDS.VP_1.ID)
    if valuepack_status and valuepack_status.cd ~= 0 then
        return true
    end
    local tarven_status = activity.getStatusById(activity.IDS.SCORE_TARVEN_4.ID)
    if tarven_status and tarven_status.cd ~= 0 then
        return true
    end
    local summon_status = activity.getStatusById(activity.IDS.SCORE_SUMMON.ID)
    if summo_status and summo_status.cd ~= 0 then
        return true
    end
    local crushing1_status = activity.getStatusById(activity.IDS.CRUSHING_SPACE_1.ID)
    if crushing1_status and crushing1_status.cd ~= 0 then
        return true
    end
    local crushing2_status = activity.getStatusById(activity.IDS.CRUSHING_SPACE_2.ID)
    if crushing2_status and crushing2_status.cd ~= 0 then
        return true
    end
    local crushing3_status = activity.getStatusById(activity.IDS.CRUSHING_SPACE_3.ID)
    if crushing3_status and crushing3_status.cd ~= 0 then
        return true
    end
    local fish_status = activity.getStatusById(activity.IDS.FISHBABY_1.ID)
    if fish_status and fish_status.cd ~= 0 then
        return true
    end
    local follow_status = activity.getStatusById(activity.IDS.FOLLOW.ID)
    if follow_status and follow_status.cd ~= 0 then
        return true
    end
    local spesummon_status = activity.getStatusById(activity.IDS.SCORE_SPESUMMON.ID)
    if spesummo_status and spesummo_status.cd ~= 0 then
        return true
    end
    local tenchange_status = activity.getStatusById(activity.IDS.TENCHANGE.ID)
    if tenchange_status and tenchange_status.cd ~= 0 then
        return true
    end
    local christmas_status = activity.getStatusById(activity.IDS.CHRISTMAS_1.ID)
    if christmas_status and christmas_status.cd ~= 0 then
        return true
    end
    local asylum_status = activity.getStatusById(activity.IDS.ASYLUM_1.ID)
    if asylum_status and asylum_status.cd ~= 0 then
        return true
    end
    local newyear_status = activity.getStatusById(activity.IDS.NEWYEAR.ID)
    if ewyear_status and ewyear_status.cd ~= 0 then
        return true
    end
    return false
    --]]
    return true
end

function activitylimit.addlimitAct(obj)
    if not activitylimit_data then
        activitylimit_data = {}
    end
    for i=1, #activitylimit_data do
        if activitylimit_data[i] == obj then
            return
        end
        if activitylimit_data[i].id == obj.id then
            activitylimit_data[i] = obj
            return 
        end
    end
    activitylimit_data[#activitylimit_data + 1] = obj
end

function activitylimit.GradeNotice(grade)
--[[    if grade == cfglimitgift[activitylimit.IDS.GRADE_24.ID].parameter then
        local actdata = {}
        actdata.id = activitylimit.IDS.GRADE_24.ID
        actdata.limits = cfglimitgift[activitylimit.IDS.GRADE_24.ID].buyTimes
        actdata.cd = cfglimitgift[activitylimit.IDS.GRADE_24.ID].lastHours*60*60
        actdata.status = 0
        actdata.read = 0
        activitylimit.addlimitAct(actdata)
    end
    if grade == cfglimitgift[activitylimit.IDS.GRADE_32.ID].parameter then
        local actdata = {}
        actdata.id = activitylimit.IDS.GRADE_32.ID
        actdata.limits = cfglimitgift[activitylimit.IDS.GRADE_32.ID].buyTimes
        actdata.cd = cfglimitgift[activitylimit.IDS.GRADE_32.ID].lastHours*60*60
        actdata.status = 0
        actdata.read = 0
        activitylimit.addlimitAct(actdata)
    end
    if grade == cfglimitgift[activitylimit.IDS.GRADE_48.ID].parameter then
        local actdata = {}
        actdata.id = activitylimit.IDS.GRADE_48.ID
        actdata.limits = cfglimitgift[activitylimit.IDS.GRADE_48.ID].buyTimes
        actdata.cd = cfglimitgift[activitylimit.IDS.GRADE_48.ID].lastHours*60*60
        actdata.status = 0
        actdata.read = 0
        activitylimit.addlimitAct(actdata)
    end
    if grade == cfglimitgift[activitylimit.IDS.GRADE_58.ID].parameter then
        local actdata = {}
        actdata.id = activitylimit.IDS.GRADE_58.ID
        actdata.limits = cfglimitgift[activitylimit.IDS.GRADE_58.ID].buyTimes
        actdata.cd = cfglimitgift[activitylimit.IDS.GRADE_58.ID].lastHours*60*60
        actdata.status = 0
        actdata.read = 0
        activitylimit.addlimitAct(actdata)
    end
    if grade == cfglimitgift[activitylimit.IDS.GRADE_78.ID].parameter then
        local actdata = {}
        actdata.id = activitylimit.IDS.GRADE_78.ID
        actdata.limits = cfglimitgift[activitylimit.IDS.GRADE_78.ID].buyTimes
        actdata.cd = cfglimitgift[activitylimit.IDS.GRADE_78.ID].lastHours*60*60
        actdata.status = 0
        actdata.read = 0
        activitylimit.addlimitAct(actdata)
    end

--]]
end

function activitylimit.LevelNotice(level)
--[[    local actdata = {}
    if level == cfglimitgift[activitylimit.IDS.LEVEL_3_15.ID].parameter then
        actdata.id = activitylimit.IDS.LEVEL_3_15.ID
        actdata.limits = cfglimitgift[activitylimit.IDS.LEVEL_3_15.ID].buyTimes
        actdata.cd = cfglimitgift[activitylimit.IDS.LEVEL_3_15.ID].lastHours*60*60
        actdata.status = 0
        actdata.read = 0
        activitylimit.addlimitAct(actdata)
    end
--]]
end

function activitylimit.summonNotice(star)
--[[    local actdata = {}
    if star == 4 then
        actdata.id = activitylimit.IDS.SUMMON_4.ID
        actdata.limits = cfglimitgift[activitylimit.IDS.SUMMON_4.ID].buyTimes
        actdata.cd = cfglimitgift[activitylimit.IDS.SUMMON_4.ID].lastHours*60*60
        actdata.status = 0
        actdata.read = 0
        actdata.next = cfglimitgift[activitylimit.IDS.SUMMON_4.ID].cd*3600
        activitylimit.addlimitAct(actdata)
    else
        actdata.id = activitylimit.IDS.SUMMON_5.ID
        actdata.limits = cfglimitgift[activitylimit.IDS.SUMMON_5.ID].buyTimes
        actdata.cd = cfglimitgift[activitylimit.IDS.SUMMON_5.ID].lastHours*60*60
        actdata.status = 0
        actdata.read = 0
        actdata.next = cfglimitgift[activitylimit.IDS.SUMMON_5.ID].cd*3600
        activitylimit.addlimitAct(actdata)
    end
--]]
end

--function activitylimit.summonFresh(star)
--    local actdata = {}
--    if star == 4 then
--        actdata.id = activitylimit.IDS.SUMMON_4.ID
--        actdata.limits = cfglimitgift[activitylimit.IDS.SUMMON_4.ID].buyTimes
--        actdata.cd = cfglimitgift[activitylimit.IDS.SUMMON_4.ID].lastHours*60*60
--        actdata.status = 0
--        actdata.read = 0
--        actdata.next = cfglimitgift[activitylimit.IDS.SUMMON_4.ID].cd*3600
--    else
--        actdata.id = activitylimit.IDS.SUMMON_5.ID
--        actdata.limits = cfglimitgift[activitylimit.IDS.SUMMON_5.ID].buyTimes
--        actdata.cd = cfglimitgift[activitylimit.IDS.SUMMON_5.ID].lastHours*60*60
--        actdata.status = 0
--        actdata.read = 0
--        actdata.next = cfglimitgift[activitylimit.IDS.SUMMON_5.ID].cd*3600
--    end
--end

function activitylimit.getStatusById(id)
    --if id >= activitylimit.IDS.GRADE_24.ID and then
    --    local monthloginData = require "data.monthlogin"
    --    if monthloginData.isEnd() then
    --        return { status = 1, }
    --    else
    --        return { status = 0, }
    --    end
    --elseif id == activitylimit.IDS.MONTH_CARD.ID then
    --    return {status=0}
    --end
    if not activitylimit_data then return nil end
    for ii=1,#activitylimit_data do
        if activitylimit_data[ii].id == id then
            return activitylimit_data[ii]
        end
    end
    return nil
end

function activitylimit.find(id)
	return activitylimit.getStatusById(id)
end

function activitylimit.showRedDot()
    if activitylimit_data and #activitylimit_data > 0 then
        for i=1, #activitylimit_data do
            if activitylimit_data[i].read and activitylimit_data[i].read == 0 then
                return true
            end
        end
    end
    local activity = require "data.activity" 
    if activity.showRedDotLimit() then
        return true
    end
    return false
end

function activitylimit.getPullIds()
    local ids = {}
    for _, info in pairs(activitylimit.IDS) do
        if info.pull then
            ids[#ids+1] = info.ID
        end
    end
    return ids
end

function activitylimit.pay()
    if not activitylimit_data then return end
    local tmp_status = activitylimit.getStatusById(IDS.FIRST_PAY.ID)
    if not tmp_status then return end
    if tmp_status.status == 0 then
        tmp_status.status = 1
    end
end


function activitylimit.anyNew()
    local monthloginData = require "data.monthlogin"
    if monthloginData.showRedDot() then return true end
    local shopData = require "data.shop"
    if shopData.showRedDot() then return true end
    if not activitylimit_data or #activitylimit_data == 0 then return false end
    for ii=1,#activitylimit_data do
        if activitylimit_data[ii].read and activitylimit_data[ii].read == 0 then
            return true
        end
    end
    return false
end

function activitylimit.setReadById(_id)
    if not activitylimit_data then return nil end
    local tmp_status = activitylimit.getStatusById(_id)
    if not tmp_status then
        print("can't find the activitylimit id:", _id)
        return 
    end
    if tmp_status.read and tmp_status.read == 0 then
        tmp_status.read = 1
        --local tmp_params = {
        --    id = _id,
        --}
        --netClient:set_activitylimit_read(tmp_params, function(__data)
        --    print("set read ok. id:", _id)
        --end)
    end
end

function activitylimit.print()
    print("--------- activitylimit --------- {")
    print("pull_time = ", activitylimit.pull_time)
    print("--- all status --- {")
    for _, info in pairs(activitylimit_data) do
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
    print("--- all status --- }")
    print("--------- activitylimit --------- }")
end

return activitylimit
