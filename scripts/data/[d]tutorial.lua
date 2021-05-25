-- 新手引导的数据

local tutorial = {}

require "common.const"
require "common.func"
local cfgtutorial = require "config.tutorial"

-- 教程依赖条件：必须项、可选项
local REQUIRED = 1
local OPTIONAL = 2

-- config.tutorial中所有教程名字，有序
local names

-- config.tutorial中，每个教程可能有多个step
-- eg: name为summon的教程需要4个step, 那么stepNums["summon"] = 4
local stepNums

-- 标志位，指示某个教程已完成到第几个step
-- eg: name为summon的教程已完成到第3个step，则stepFlags["summon"] = 3
local stepFlags

-- config.tutorial中，每个教程对应多个step，每个step对应多个id
-- eg: name为summon, step 2对应id 4,5,6, 那么idMap["summon"][2] = { 4, 5, 6 }
local idMap

-- config.tutorial中，每个教程对应多个step，每个step可能对应一个服务器状态位
-- eg: name为summon, step 2对应服务器状态位的第10位, 那么bitMap["summon"][2] = 10
local bitMap

-- 一个教程是不是强制引导
-- eg: name为summon的教程为强制引导，那么forced["summon"] = true
local forced

-- 服务器状态位 eg: { 1, 0, 0, 1, 1, 1, 0, 0, ... }
local serverBits

-- curIds: 当前正在进行中的教程id执行序列
-- curOffset: 指向curIds的偏移量，表示进行到了第几个id
local curIds, curOffset

local recordFlag

-- 初始化
function tutorial.init(flag, flag2)
    recordFlag = flag

    --兼容老版本教程
    cfgtutorial = require "config.tutorial"
    UNLOCK_BLACKMARKET_LEVEL = 10

    if tutorial.getVersion() == 2 then
        flag = flag2
        cfgtutorial = require "config.tutorial_2"

        --去掉黑市解锁等级
        UNLOCK_BLACKMARKET_LEVEL = 1
    end

    names = {}
    stepNums = {}
    stepFlags = {}
    idMap = {}
    bitMap = {}
    forced = {}
    serverBits = tutorial.decodeServerBits(flag)
    curIds, curOffset = nil, nil
    -- 读表config.tutorial，初始化
    for id, t in ipairs(cfgtutorial) do
        -- names
        if not arraycontains(names, t.name) then
            names[#names+1] = t.name 
        end
        -- idMap
        if idMap[t.name] == nil then
            idMap[t.name] = {}
        end
        if idMap[t.name][t.step] == nil then
            idMap[t.name][t.step] = {}
        end
        table.insert(idMap[t.name][t.step], id)
        -- bitMap
        if t.bit then
            if bitMap[t.name] == nil then
                bitMap[t.name] = {}
            end
            if bitMap[t.name][t.step] == nil then
                bitMap[t.name][t.step] = t.bit
            end
        end
        -- stepNums
        if stepNums[t.name] == nil or stepNums[t.name] < t.step then
            stepNums[t.name] = t.step
        end
        -- forced
        if not forced[t.name] and t.forced == 1 then
            forced[t.name] = true
        end
    end
    -- stepFlags
    for _, name in ipairs(names) do
        local stepNum = stepNums[name]
        if not forced[name] and tutorial.validate(name) then
            -- 非强制引导满足条件时直接认为是已完成状态，考虑到切服或切帐号的需要
            stepFlags[name] = stepNum
        else
            local stepFlag = 0
            for n = stepNum, 1, -1 do
                if bitMap[name] and bitMap[name][n] and serverBits[bitMap[name][n]] == 1 then
                    stepFlag = n
                    break
                end
            end
            stepFlags[name] = stepFlag
        end
    end
end

function tutorial.getConfig()
    return cfgtutorial
end

function tutorial.getVersion()
    if recordFlag == 0 then
        return 2
    else
        return 1
    end
end

-- 检查一个教程是不是符合表config.tutorial中定义的触发条件：lv, stage
function tutorial.validate(name)
    local lv = require("data.player").lv()
    local hookdata = require("data.hook")
    local pveStage = hookdata.getPveStageId()
    local hookStage = hookdata.getHookStage()
    for step, ids in ipairs(idMap[name]) do
        for _, id in ipairs(ids) do
            if (cfgtutorial[id].lv and cfgtutorial[id].lv ~= lv)
                or (cfgtutorial[id].pveStage and cfgtutorial[id].pveStage ~= pveStage) 
                or (cfgtutorial[id].hookStage and cfgtutorial[id].hookStage ~= hookStage) then
                return false
            end
        end
    end
    return true
end

-- 解码服务端状态位
function tutorial.decodeServerBits(flag)
    local bits = {}
    if flag then
        while flag ~= 0 do
            bits[#bits+1] = bit.band(1, flag)
            flag = bit.brshift(flag, 1)
        end
    end
    return bits
end

-- 该step是否已完成
function tutorial.isFinished(name, step)
    step = step or 1
    return stepFlags[name] >= step
end

-- 设置该step教程已完成
function tutorial.finish(name, step)
    step = step or 1
    if tutorial.is(name, step) and not tutorial.isFinished(name, step) then
        stepFlags[name] = step
        cclog("tutorial.finish [%s]=%d", name, step)
    end
end

-- 返回当前可执行的教程id
-- layername: 参见config.tutorial的layer项
function tutorial.getExecuteId(layername)
    -- 如果当前执行id序列为空，则构建可执行的id序列
    if curIds == nil then
        for _, name in ipairs(names) do
            if not tutorial.isFinished(name, stepNums[name]) and tutorial.validate(name) then
                local ids = {}
                for step = 1, stepNums[name] do
                    -- 只有required的ids和未完成的step包含的ids，才将其加入执行序列中
                    for _, id in ipairs(idMap[name][step]) do
                        if cfgtutorial[id].condition == REQUIRED
                            or not tutorial.isFinished(name, step) then
                            table.insert(ids, id)
                        end
                    end
                end
                -- 有效的教程序列必须是：第一个id或第一个非optional的id匹配layername
                local offset
                if #ids > 0 and cfgtutorial[ids[1]].layer == layername then
                    offset = 1
                else
                    for i, id in ipairs(ids) do
                        if cfgtutorial[id].condition ~= OPTIONAL then
                            if cfgtutorial[id].layer == layername then
                                offset = i
                            end
                            break
                        end
                    end
                end
                -- 有效教程序列开始起动
                if offset then
                    curIds = ids
                    curOffset = offset
                    tutorial.printCurIds()
                    return curIds[curOffset]
                end
            end
        end
    end
    -- 匹配layername
    if curIds ~= nil and cfgtutorial[curIds[curOffset]].layer == layername then
        --tutorial.printCurIds()
        return curIds[curOffset]
    end
    return nil
end

-- 判断正在执行中的教程是不是name, step
function tutorial.is(name, step)
    step = step or 1
    if curIds and curOffset and curIds[curOffset] then
        local id = curIds[curOffset]
        return cfgtutorial[id].name == name and cfgtutorial[id].step == step
    end
    return false
end

-- 是否有教程进行中
function tutorial.exists()
    if curIds and curOffset and curIds[curOffset] then
        return true
    end
    return false
end

-- goNext时会调用的callback
local nextCallback
function tutorial.setNextCallback(callback)
    nextCallback = callback
end

-- 将curOffset指向curIds中的下一个教程id
function tutorial.goNext(name, step, finish)
    step = step or 1
    if tutorial.is(name, step) then
        local id = curIds[curOffset]
        local ids = idMap[name][step]
        -- 当前已是该step的最后一个id, 则设置该step完成
        if finish or ids[#ids] == id then   
            tutorial.finish(name, step)
        end
        -- 当前已是执行序列的最后一个id了，则可以清空该序列了
        if curOffset == #curIds then
            curIds, curOffset = nil, nil
        else
            -- 否则，将curOffset后移一位即可
            curOffset = curOffset + 1
        end
        -- 回调
        nextCallback()

        return true
    end
    return false
end

-- 打印函数，用于调试
function tutorial.print()
    print("--------- tutorial --------- {")
    print("names: ", table.concat(names, ","))
    local serverBitStr = {}
    for i, bit in ipairs(serverBits) do
        table.insert(serverBitStr, string.format("[%d]=%d", i, bit))
    end
    print("serverBits:", table.concat(serverBitStr, " "))
    local bitMapStr = {}
    for _, name in ipairs(names) do
        local bits = bitMap[name]
        if bits then
            for step, bit in ipairs(bits) do
                table.insert(bitMapStr, string.format("%s[%d]=%d", name, step, bit))
            end
        end
    end
    print("bitMap:", table.concat(bitMapStr, " "))
    local stepNumStr = {}
    for _, name in ipairs(names) do
        table.insert(stepNumStr, string.format("%s=%d", name, stepNums[name]))
    end
    print("stepNums:", table.concat(stepNumStr, " "))
    local stepFlagStr = {}
    for _, name in ipairs(names) do
        table.insert(stepFlagStr, string.format("%s=%d", name, stepFlags[name]))
    end
    print("stepFlags:", table.concat(stepFlagStr, " "))
    local forcedStr = {}
    for _, name in ipairs(names) do
        if forced[name] then
            table.insert(forcedStr, name)
        end
    end
    print("forced:", table.concat(forcedStr, ","))
    print("idMap:")
    for _, name in ipairs(names) do
        local stepIds = idMap[name]
        for step, ids in ipairs(stepIds) do
            cclog("    %s[%d] = {%s}", name, step, table.concat(ids, ","))
        end
    end
    print("--------- tutorial --------- }")
end

-- 打印当前的执行序列，用于调试
function tutorial.printCurIds()
    if curIds ~= nil then
        cclog("tutorial curIds = {%s}", table.concat(curIds, ","))
        cclog("tutorial curOffset = %d", curOffset)
    else
        print("tutorial curIds is nil!")
    end
end

--所有强制教程完成
function tutorial.isComplete()
    if not TUTORIAL_ENABLE then
        return true
    end

    for _, name in ipairs(names) do
        if forced[name] and not tutorial.isFinished(name, stepNums[name]) then
            return false
        end
    end
    return true
end

return tutorial


