--[[
SchedulerUtil
Auth:cm_wang
cocos2dx-lua has only sample interface to use scheduler, make some utils to easily use them
]]

local SchedulerUtil = {}
local director = cc.Director:sharedDirector()
local scheduler = director:getScheduler()

function SchedulerUtil:init()
    self.scheduleIdMap = {}
end

function SchedulerUtil:unscheduleAll()
    for scheduleId, _ in pairs(self.scheduleIdMap) do
        scheduler:unscheduleScriptEntry(scheduleId)
    end
    self.scheduleIdMap = {}
end

function SchedulerUtil:unscheduleGlobal(scheduleId)
    if not self.scheduleIdMap[scheduleId] then
        return
    end
	scheduler:unscheduleScriptEntry(scheduleId)
end

function SchedulerUtil:scheduleUpdateGlobal(listener)
    return self:scheduleGlobal(listener, 0)
end

function SchedulerUtil:scheduleGlobal(listener, interval)
	local scheduleId = scheduler:scheduleScriptFunc(listener, interval, false)
    self.scheduleIdMap[scheduleId] = true
	return scheduleId
end

function SchedulerUtil:performWithDelayGlobal(listener, time)
    local timer = 0
    local scheduleId
    local function update(dt)
        timer = timer + dt
        if timer >= time then
            scheduler:unscheduleScriptEntry(scheduleId)
            listener()
        end
    end

    scheduleId = self:scheduleUpdateGlobal(update)
    return scheduleId
end

SchedulerUtil:init()

return SchedulerUtil

