local herotask = {}

function herotask.init(__data)
    tbl2string(__data)
    herotask.tasks = __data.tasks or {}
    if __data.cd then
        herotask.cd = __data.cd + os.time()
    end

    for i,v in ipairs(herotask.tasks) do
        v.cd = v.cd + os.time()
    end
end

function herotask.checkPull()
    if not herotask.cd or herotask.cd <= os.time() then
        return true
    end
    return false
end

function herotask.changeLock(tid)
    for i, v in ipairs(herotask.tasks) do
        if v.tid == tid then
            if v.lock and v.lock == 1 then
                herotask.tasks[i].lock = 0
            else
                herotask.tasks[i].lock = 1
            end
            break
        end
    end
end

function herotask.sortTask()
    local tasks = {}
    
    --print("#tasks", #tasks)
    for i, v in ipairs(herotask.tasks) do
        if not v.heroes then
            tasks[#tasks + 1] = v
        end
    end
    --print("#herotask.tasks", #herotask.tasks)
    for i, v in ipairs(herotask.tasks) do
        if v.heroes and v.cd and v.cd <= os.time() then
            tasks[#tasks + 1] = v
        end
    end
    --print("#tasks", #tasks)
    for i, v in ipairs(herotask.tasks) do
        if v.cd and v.cd > os.time() then
            tasks[#tasks + 1] = v
        end
    end
    --print("#tasks", #tasks)
    herotask.tasks = tasks
end

function herotask.del(tid)
    local tasks = {}
    for i, v in ipairs(herotask.tasks) do
        if v.tid ~= tid then
            tasks[#tasks + 1] = v
        end
    end
    herotask.tasks = tasks
end

function herotask.add(task)
    local tasks = {}
    tasks[#tasks + 1] = task
    for i, v in ipairs(herotask.tasks) do
        tasks[#tasks + 1] = v
    end
    herotask.tasks = tasks
end

function herotask.showRedDot()
    if herotask.tasks then
        for i,v in ipairs(herotask.tasks) do
            if v.heroes and v.cd <= os.time() then
                return true
            end
        end
    end

    return false
end

return herotask
