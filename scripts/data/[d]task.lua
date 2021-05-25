local task = {}

local dailytask = require "config.dailytask"
local player = require "data.player"
local i18n = require "res.i18n"
local bagdata = require "data.bag"
local NetClient = require "net.netClient"
netClient = NetClient:getInstance()

local TaskType = {
    MIDAS = 1,
    FRIEND_HEART = 2,
    CASINO= 3,
    HERO_TASK = 4,
    FORGE = 5,
    BASIC_SUMMON = 6,
    SENIOR_SUMMON = 7,
    ARENA = 8,
    HOOK_GET = 9,
    --GUILD_SIGN = 10,
    CHALLENGE = 11,
    ALL = 99,
}
task.TaskType = TaskType

task.tasks = {}
task.expire = 0
task.is_pulled = false
task.pull_time = os.time()
local OK = 0
local ERROR = -1
local TIMEOUT = -100
local total_taskId = TaskType.ALL

function task.initFromCfg()
    task.tasks = {}
    for idx,o_task in pairs(dailytask) do
        local _task = clone(o_task)
        _task.id = idx
        _task.count = 0
        _task.is_claim = 0
        _task.total = _task.completeValue
        task.tasks[idx] = _task
    end
end

function task.findFromCfgById(_id)
    for idx,_task in pairs(dailytask) do
        if idx == _id then
            return clone(_task)
        end
    end
end

function task.findFromDataById(_id)
    for idx,_task in pairs(task.tasks) do
        if _task.id == _id then
            return _task
        end
    end
end

function task.unlockTask(_taskid)
    if not task.tasks[_taskid] then
        local tmp_task = task.findFromCfgById(_taskid)
        if tmp_task then
            tmp_task.id = _taskid
            tmp_task.count = 0
            tmp_task.is_claim = 0
            tmp_task.total = tmp_task.completeValue
            task.tasks[_taskid] = tmp_task
        end
    end
end

function task.getTotalTaskId()
    return total_taskId
end

local function delTaskByTaskId(taskid)
    for idx,__ in pairs(task.tasks) do
        if idx == taskid then
            task.tasks[idx] = nil
            break
        end
    end
end

function task.setCD(_cd)
    task.cd = _cd or 0
end

function task.getCD()
    return task.cd or 0
end

function task.refresh()
    task.syncInit()
    task.cd = 3600 * 24
    task.pull_time = os.time()
end

function task.syncInit(obj)
    task.pull_time = os.time()
    task.initFromCfg()
    -- 屏蔽所有未开放功能
    -- 有未开放功能时屏蔽所有任务
    local any_unlock = false
    if player.lv() < UNLOCK_SMITH_LEVEL then
        delTaskByTaskId(TaskType.FORGE)
        any_unlock = true
    end
    if player.lv() < UNLOCK_MIDAS_LEVEL then
        delTaskByTaskId(TaskType.MIDAS)
        any_unlock = true
    end
    if player.lv() < UNLOCK_CASINO_LEVEL then
        delTaskByTaskId(TaskType.CASINO)
        any_unlock = true
    end
    if player.lv() < UNLOCK_ARENA_LEVEL then
        delTaskByTaskId(TaskType.ARENA)
        any_unlock = true
    end
    if player.lv() < UNLOCK_CHALLENGE_LEVEL then
        delTaskByTaskId(TaskType.CHALLENGE)
        any_unlock = true
    end
    --if player.lv() < UNLOCK_GUILD_LEVEL then
    --    delTaskByTaskId(TaskType.GUILD_SIGN)
    --    any_unlock = true
    --end
    if player.lv() < UNLOCK_TAVERN_LEVEL then
        delTaskByTaskId(TaskType.HERO_TASK)
        any_unlock = true
    end
    if not any_unlock then
        print("=================unlockTask all==================")
        task.unlockTask(TaskType.ALL)
    else
        print("=================lockTask all==================")
        delTaskByTaskId(TaskType.ALL)
    end

    if not obj or not obj.tasks then return end
    local completed = 0
    for ii=1,#obj.tasks do
        local tid = obj.tasks[ii].id
        local d_task = task.findFromDataById(tid)
        if d_task then
            d_task.is_claim = obj.tasks[ii].is_claim
            d_task.count = obj.tasks[ii].count
            if d_task.count >= d_task.completeValue then
                d_task.count = d_task.completeValue
                d_task.isCompleted = true
                completed = completed + 1
            else
                d_task.isCompleted = false
            end
        end
    end
    
    task.checkAll()
end

function task.checkLv()
    if player.lv() >= UNLOCK_SMITH_LEVEL then
        task.unlockTask(TaskType.FORGE)
    end
    if player.lv() >= UNLOCK_MIDAS_LEVEL then
        task.unlockTask(TaskType.MIDAS)
    end
    if player.lv() >= UNLOCK_CASINO_LEVEL then
        task.unlockTask(TaskType.CASINO)
    end
    if player.lv() >= UNLOCK_ARENA_LEVEL then
        task.unlockTask(TaskType.ARENA)
    end
    if player.lv() >= UNLOCK_CHALLENGE_LEVEL then
        task.unlockTask(TaskType.CHALLENGE)
    end
    --if player.lv() >= UNLOCK_GUILD_LEVEL then
    --    task.unlockTask(TaskType.GUILD_SIGN)
    --end
    if player.lv() >= UNLOCK_TAVERN_LEVEL then
        task.unlockTask(TaskType.HERO_TASK)
        task.unlockTask(TaskType.ALL)
    else
        return
    end
end

-- 检查总任务进度
function task.checkAll()
    task.checkLv()
    local a_task = task.findFromDataById(TaskType.ALL)
    if not a_task then return end
    local completed = 0
    local task_count = 0
    for k, v in pairs(TaskType) do
        if v ~= TaskType.ALL then
            task_count = task_count + 1
            if not task.tasks[v] then
                return
            elseif task.tasks[v].count < task.tasks[v].total then
            else
                completed = completed + 1
            end
        end
    end
    a_task.count = completed
    a_task.total = task_count
    if a_task.count >= a_task.total then
        a_task.count = a_task.total
    end
end

local function sortValue(_obj)
    if _obj.id == total_taskId then
        return 20000
    elseif _obj.is_claim == 1 then
        return 10000 + _obj.id
    elseif _obj.count < _obj.total then
        return 5000 + _obj.id
    else
        return _obj.id
    end
end

function task.sort(a, b)
    return sortValue(a) < sortValue(b)
    --if a.is_claim == 0 and b.is_claim == 0 and a.id == total_taskId then
    --    return false 
    --elseif a.is_claim == 0 and b.is_claim == 0 and b.id == total_taskId then
    --    return true
    --elseif a.is_claim == 0 and a.count >= a.total and b.is_claim == 0 and b.count >= b.total then
    --    return a.id < b.id
    --elseif a.is_claim == 0 and a.count >= a.total and b.is_claim == 0 and b.count < b.total then
    --    return true
    --elseif a.is_claim == 0 and a.count < a.total and b.is_claim == 0 and b.count < b.total then
    --    return a.id < b.id
    --elseif a.is_claim == 0 and b.is_claim == 1 then
    --    return true
    --elseif a.is_claim == 1 and b.is_claim == 1 then
    --    return a.id < b.id
    --else 
    --    return false
    --end
end

function task.getTask()
    return task.tasks
end

function task.increment(typeId, count)
    task.checkLv()
    --print("tasks Type, count:", typeId, count)
    count = count or 1
    local is_it_completed = false
    local d_task = task.findFromDataById(typeId)
    if not d_task then return end
    d_task.count = d_task.count + count
    if d_task.count >= d_task.total then
        d_task.count = d_task.total
        d_task.isCompleted = true
    end
    task.checkAll()
    return is_it_completed
end

function task.showRedDot()
    if player.lv() < UNLOCK_TASK_LEVEL then return false end
    for idx,__ in pairs(task.tasks) do
        if true==task.tasks[idx].isCompleted and 0==task.tasks[idx].is_claim then
            return true
        end
    end
    return false
end

function task.claim(params, callback)
    netClient:task_claim(params, callback)
end

function task.claim_del(obj, callback)
    tbl2string(obj)
    local params = {
        sid = player.sid,
        id = obj.id,
    }
    addWaitNet()
    netClient:task_claim(params, function(__data)
        tbl2string(__data)
        delWaitNet()
        if __data.status ~= 0 then
            showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
            if callback then
                callback(ERROR)
            end
            return
        end
        local tmp_bag = reward2Pbbag(obj.reward)
        bagdata.addRewards(tmp_bag)
        --showToast(i18n.global.dailytask_claim_ok.string)
        obj.is_claim = 1 
        if callback then
            callback(OK, tmp_bag)
        end
    end)
end

return task
