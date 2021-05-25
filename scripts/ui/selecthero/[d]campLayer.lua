-- 阵营buff

local ui = {}

require "common.const"
require "common.func"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local audio = require "res.audio"
local heros = require "data.heros"
local i18n = require "res.i18n"
local cfgcamp = require "config.camp"
local cfghero = require "config.hero"
local heros = require "data.heros"
local DHComponents  = require("dhcomponents.DroidhangComponents")

-- 背景框大小
local BG_WIDTH   = 600
local BG_HEIGHT  = 100

-- 1-6 是纯色光环
local Blend = 7             --混色ID
local JusticeAndEvil = 8    --正邪ID
local Ruin = 9              --毁灭ID
local Redemption = 10       --救赎ID
local Justice = 11          --正义ID
local Evil = 12             --邪恶ID
local Pollute = 13          --污染ID
local Shackles = 14         --束魂ID
local LifeDeath = 15        --生死ID
local OldEnemy = 16         --宿敌ID



--[[
1 幽暗  
2 堡垒  
3 深渊 
4 森林 
5 暗影
6 光明
]]
--从大到小排列
ui.BuffTable = {} 
ui.BuffTable[1]                = {1,1,1,1,1,1}
ui.BuffTable[2]                = {2,2,2,2,2,2}
ui.BuffTable[3]                = {3,3,3,3,3,3}
ui.BuffTable[4]                = {4,4,4,4,4,4}
ui.BuffTable[5]                = {5,5,5,5,5,5}
ui.BuffTable[6]                = {6,6,6,6,6,6}
ui.BuffTable[Blend]            = {6,5,4,3,2,1}
ui.BuffTable[JusticeAndEvil]   = {6,6,6,5,5,5}
ui.BuffTable[Ruin]             = {5,5,3,3,1,1}
ui.BuffTable[Redemption]       = {6,6,4,4,2,2}
ui.BuffTable[Justice]          = {4,4,4,2,2,2}
ui.BuffTable[Evil]             = {3,3,3,1,1,1}
ui.BuffTable[Pollute]          = {4,4,4,3,3,3}
ui.BuffTable[Shackles]         = {3,3,3,2,2,2}
ui.BuffTable[LifeDeath]        = {4,4,4,1,1,1}
ui.BuffTable[OldEnemy]         = {2,2,2,1,1,1}

function ui.create()
    ui.obj = {}
    ui.obj.widget = {}

    ui.obj.widget.layer = CCLayer:create()
    ui.obj.widget.layer:setContentSize(CCSize(BG_WIDTH,BG_HEIGHT))
    ui.obj.widget.layer:setAnchorPoint(0,0.5)


        --添加滚动容器
    ui.obj.widget.scroll = CCScrollView:create()
    ui.obj.widget.scroll:setAnchorPoint(CCPoint(0,0))
    ui.obj.widget.scroll:setDirection(kCCScrollViewDirectionHorizontal)
    ui.obj.widget.scroll:setViewSize(CCSize(745,100))
    ui.obj.widget.scroll:setContentSize(CCSize(1030,100))
    ui.obj.widget.scroll:setCascadeOpacityEnabled(true)
    ui.obj.widget.scroll:setPosition(30,0)
    ui.obj.widget.scroll:getContainer():setCascadeOpacityEnabled(true)
    ui.obj.widget.layer:addChild(ui.obj.widget.scroll)

    --读取表格内容
    ui.obj.widget.icon = {}
    for i = #cfgcamp, 1, -1 do
        local cfg = cfgcamp[i]

        local iconBg = img.createUISprite("battlebuff_"..i..".png")
        iconBg:setPosition(65*(i-1),20)
        iconBg:setTouchEnabled(true)
        iconBg:setTouchSwallowEnabled(false)
        ui.obj.widget.scroll:addChild(iconBg)
        local size = iconBg:getContentSize()

        ui.obj.widget.icon[i] = json.create(json.ui.campbuff[i])
        ui.obj.widget.icon[i]:setScale(0.72)
        ui.obj.widget.icon[i]:setPosition(65*(i-1)+size.width/2,20+size.height/2)
        ui.obj.widget.icon[i]:setVisible(false)
        ui.obj.widget.icon[i]:playAnimation("animation", -1)
        ui.obj.widget.scroll:addChild(ui.obj.widget.icon[i])
        
        --local iconTips
        --iconTips.bg:setAnchorPoint(ccp(0, 0))
        --iconTips:setVisible(false)
        --DHComponents:mandateNode(iconTips   ,"yw_campbuff_iconTips")
        
        local function onTouch(eventType, x, y)
            if eventType == "began" then
                iconTips = require("ui.tips.campbuff").create(i)
                ui.obj.widget.layer:getParent():getParent():addChild(iconTips)
            elseif eventType == "moved" then
                --暂时不作为
            else
                if iconTips and not tolua.isnull(iconTips) then
                    iconTips:removeFromParentAndCleanup(false)
                end
            end
            return true
        end
        iconBg:registerScriptTouchHandler(onTouch)
    end

    return ui.obj.widget
end

--部分界面使用的接口，用于自动跳转到亮起的buff图标位置
function ui.autoJumpScroll(isAutoScroll,key)
    if isAutoScroll == nil or isAutoScroll == false then
        return
    end

    if key > 11 then
        ui.obj.widget.scroll:setContentOffset(CCPoint(745-1030, 0))
    else
        ui.obj.widget.scroll:setContentOffset(CCPoint(0, 0))
    end
end

--传入英雄ID，返回当前列表可组成的光环阵容ID
function ui.checkUpdateForHeroids(heroids,isAutoScroll)
    --判断是否装满
    for i=1, 6 do 
        print(heroids[i])
        if heroids[i] == nil or heroids[i] <= 0 then
            return -1
        end
    end

    --排序
    local sortHeroids = tablecp(heroids)
    table.sort(sortHeroids , function(a , b)
        return cfghero[a].group > cfghero[b].group
    end)

    --阵营判断
    for key,val in pairs(ui.BuffTable) do
        local BuffTableItem = ui.BuffTable[key]
        for i=1, 6 do
            if BuffTableItem[i] ~=  tonumber(cfghero[sortHeroids[i]].group) then
                break
            end

            if i == 6 then
                ui.autoJumpScroll(isAutoScroll,key)
                return key
            end
        end 
    end
    return -1
end   


--传入当前上阵的列表，返回当前列表可组成的光环阵容ID
--[[
function ui.checkUpdate(hids)
    --判断是否装满
    for i=1, 6 do 
        if hids[i] == nil or hids[i] <= 0 or heros.find(hids[i]) == nil then
            return -1
        end
    end

    --排序
    local sortHids = tablecp(hids)
    table.sort(sortHids , function(a , b)
        return cfghero[heros.find(a).id].group > cfghero[heros.find(b).id].group
    end)

    --阵营判断
    for key,val in pairs(ui.BuffTable) do
        local BuffTableItem = ui.BuffTable[key]
        for i=1, 6 do
            if BuffTableItem[i] ~=  tonumber(cfghero[(heros.find(sortHids[i])).id].group) then
                break
            end

            if i == 6 then
                return key
            end
        end 
    end

    return -1
end]]

return ui
