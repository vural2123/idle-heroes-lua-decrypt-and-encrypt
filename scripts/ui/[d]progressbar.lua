-- 自定义进度条，具有渐进伸缩的功能

local bar = {}

require "common.func"
local view = require "common.view"
local img = require "res.img"

function bar.create(sprite)
    local progress = createProgressBar(sprite)

    -- 当前等级，当前百分比，目标等级，目标百分比
    local curLv, curPct, aimLv, aimPct

    -- 设置等级和百分比
    function progress.setLvAndPercentage(l, p)
        curLv = l
        curPct = p
        aimLv = l
        aimPct = p
        progress:setPercentage(p)
    end

    -- 设置渐进动画的目标等级和百分比，进度条将会渐进动画到目标值
    function progress.scaleLvAndPercentage(l, p)
        aimLv = l
        aimPct = p
    end

    -- 只设置百分比，不需要等级功能的时候使用该函数
    function progress.setPercentageOnly(p)
        progress.setLvAndPercentage(0, p)
    end

    -- 只设置渐进动画的目标百分比，不需要等级功能的时候使用该函数
    function progress.scalePercentageOnly(p)
        progress.scaleLvAndPercentage(0, p)
    end

    -- 回调，当进度条渐进动画到两端时（即百分比为0或者100），说明要跨到下一等级了，
    -- 将会触发该回调，回调格式为：lvHandler(要进入的等级)
    local lvHander
    function progress.setLvHandler(h)
        lvHander = h
    end

    -- 进度条渐进动画运动时将会触发该回调，回调格式为：percentageHandler(percentage)
    local pctHander
    function progress.setPercentageHandler(h)
        pctHander = h
    end

    -- 该函数执行渐进效果，每帧渐进数个百分比
    local function onUpdate(ticks)
        local step = ticks * 60 -- cocos2dx是每秒60帧，相当于1帧step=1
        if curLv and curPct and not (floateq(curLv,aimLv) and floateq(curPct,aimPct)) then
            local lvChange
            if aimLv < curLv then
                -- 跨等级，5倍速
                curPct = curPct - 5 * step
                if curPct < 0 then
                    curLv = curLv - 1
                    curPct = 100 + curPct
                    lvChange = true
                end
            elseif aimLv > curLv then
                -- 跨等级，5倍速
                curPct = curPct + 5 * step
                if curPct >= 100 then
                    curLv = curLv + 1
                    curPct = curPct - 100
                    lvChange = true
                end
            else 
                -- 同等级，根据差距决定倍速
                if math.abs(curPct - aimPct) > 50 then
                    -- 差距大于50%，使用5倍速
                    step = step * 5
                elseif math.abs(curPct - aimPct) > 20 then
                    -- 差距大于20%，使用2倍速
                    step = step * 2
                else 
                    -- 差距低于20%，使用1倍速
                end
                if aimPct < curPct then
                    curPct = curPct - step
                    if curPct < aimPct then
                        curPct = aimPct
                    end
                elseif aimPct > curPct then
                    curPct = curPct + step
                    if curPct > aimPct then
                        curPct = aimPct
                    end
                end
            end
            if lvChange and lvHander then
                lvHander(curLv)
            end
            if progress:getPercentage() ~= curPct then
                progress:setPercentage(curPct)
                if pctHander then
                    pctHander(curPct)
                end
            end
        end
    end

    progress:scheduleUpdateWithPriorityLua(onUpdate, 0)

    return progress
end

return bar 
