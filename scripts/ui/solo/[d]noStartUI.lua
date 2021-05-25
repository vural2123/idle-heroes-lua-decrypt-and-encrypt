-- 单挑赛未开始界面

local ui = {}

require "common.func"
local view      = require "common.view"
local img       = require "res.img"
local lbl       = require "res.lbl"
local json      = require "res.json"
local i18n      = require "res.i18n"
local audio     = require "res.audio"
local net       = require "net.netClient"
local heros     = require "data.heros"
local cfghero   = require "config.hero"
local bag       = require "data.bag"
local player    = require "data.player"
local soloData  = require "data.solo"

function ui.create()
	ui.widget = {}
    ui.data = {}

    --ui.data.countTime = params.cd
    -- 主层
   	ui.widget.layer = CCLayer:create()
    -- 骨骼节点
    ui.widget.spineNode = json.create(json.ui.solo)
    ui.widget.spineNode:setScale(view.minScale)
    ui.widget.spineNode:setPosition(view.midX, view.midY)
    ui.widget.layer:addChild(ui.widget.spineNode)
    ui.widget.spineNode:playAnimation("b_start")
    ui.widget.spineNode:registerLuaHandler(function (event)
        if event == "b_start" then
            ui.widget.spineNode:playAnimation("b_loop", -1)
        end
    end)
    -- 上方条骨骼
    ui.widget.upSpine = json.create(json.ui.solo_up)
    ui.widget.upSpine:setScale(view.minScale)
    ui.widget.upSpine:setPosition(view.midX,view.midY)
    ui.widget.layer:addChild(ui.widget.upSpine)
    ui.widget.upSpine:playAnimation("b_start")
    ui.widget.upSpine:appendNextAnimation("b_loop", -1)
    autoLayoutShift(ui.widget.upSpine,true)
    -- 下方条骨骼
    ui.widget.downSpine = json.create(json.ui.solo_down)
    ui.widget.downSpine:setScale(view.minScale)
    ui.widget.downSpine:setPosition(view.midX,view.midY)
    ui.widget.layer:addChild(ui.widget.downSpine)
    ui.widget.downSpine:playAnimation("b_start")
    ui.widget.downSpine:appendNextAnimation("b_loop", -1)
    autoLayoutShift(ui.widget.downSpine,false,true)
    -- 标题
    ui.widget.title = lbl.createFont2(24, i18n.global.solo_close.string, ccc3(250, 216, 105))
    ui.widget.upSpine:addChildFollowSlot("code_text", ui.widget.title)
    -- 底板节点
    ui.widget.boardNode = CCNode:create()
    ui.widget.downSpine:addChildFollowSlot("code_x",ui.widget.boardNode)
    -- 时钟动画
    ui.widget.clockSpine = json.create(json.ui.clock)
    ui.widget.clockSpine:playAnimation("animation",-1)
    ui.widget.boardNode:addChild(ui.widget.clockSpine)
    -- 倒计时标签
    ui.widget.countDownLabel = lbl.createFont2(14, ui.getTimeString(math.max(0,soloData.cd)), ccc3(0xc3,0xff,0x42))
    ui.widget.countDownLabel:setAnchorPoint(ccp(0,0.5))
    --ui.widget.spineNode:addChildFollowSlot("code_x", ui.widget.countDownLabel)
    ui.widget.boardNode:addChild(ui.widget.countDownLabel)
    ui.widget.countDownLabel:scheduleUpdateWithPriorityLua(ui.refreshTime, 0)
    -- 开启标签
    ui.widget.startLabel = lbl.createFont2(18, i18n.global.arena3v3_open_cd.string, ccc3(255, 246, 223))
    ui.widget.startLabel:setAnchorPoint(ccp(1,0.5))
    --ui.widget.spineNode:addChildFollowSlot("code_timertext", ui.widget.startLabel)
    ui.widget.boardNode:addChild(ui.widget.startLabel)
    
    -- 
    local intervalX = 2
    local clockWidth = 29
    local timeWidth = ui.widget.countDownLabel:boundingBox():getMaxX() - ui.widget.countDownLabel:boundingBox():getMinX()
    local startWidth = ui.widget.startLabel:boundingBox():getMaxX() - ui.widget.startLabel:boundingBox():getMinX()
    local totalWidth = clockWidth + timeWidth + startWidth + intervalX * 2
    ui.widget.countDownLabel:setPosition(ccp(totalWidth / 2 - timeWidth, 5))
    ui.widget.startLabel:setPosition(ccp(ui.widget.countDownLabel:getPositionX() - intervalX,6))
    ui.widget.clockSpine:setPosition(ccp(ui.widget.startLabel:getPositionX() - startWidth - 16,6))
    print("时钟长度"..ui.widget.clockSpine:getContentSize().width)
    print("时间标签长度"..timeWidth)
    print("开始标签长度"..startWidth)
    print("总长度"..totalWidth)
    -- drawBoundingbox(ui.widget.boardNode, ui.widget.countDownLabel)
    -- drawBoundingbox(ui.widget.boardNode, ui.widget.startLabel)

    -- 返回按钮
    ui.widget.backBtn = HHMenuItem:create(img.createUISprite(img.ui.back))
    ui.widget.backBtn:setScale(view.minScale)
    ui.widget.backBtn:setPosition(scalep(35, 540))
    local backMenu = CCMenu:createWithItem(ui.widget.backBtn)
    backMenu:setPosition(ccp(0, 0))
    ui.widget.layer:addChild(backMenu,1000)
    autoLayoutShift(ui.widget.backBtn,true,false,true,false)
    -- 排行榜按钮
    local rankImg = img.createUISprite(img.ui.btn_rank)
    ui.widget.rankBtn = SpineMenuItem:create(json.ui.button, rankImg)
    ui.widget.rankBtn:setScale(view.minScale)
    ui.widget.rankBtn:setPosition(scalep(865, 540))
    local rankMenu = CCMenu:createWithItem(ui.widget.rankBtn)
    rankMenu:setPosition(ccp(0, 0))
    ui.widget.layer:addChild(rankMenu,1000)
    autoLayoutShift(ui.widget.rankBtn,true,false,false,true)
    -- 帮助按钮
    local helpImg = img.createUISprite(img.ui.btn_help)
    ui.widget.helpBtn = SpineMenuItem:create(json.ui.button, helpImg)
    ui.widget.helpBtn:setScale(view.minScale)
    ui.widget.helpBtn:setPosition(scalep(920, 540))
    local helpMenu = CCMenu:createWithItem(ui.widget.helpBtn)
    helpMenu:setPosition(ccp(0, 0))
    ui.widget.layer:addChild(helpMenu,1000)
    autoLayoutShift(ui.widget.helpBtn,true,false,false,true)

    ui.btnCallBack()
    return ui.widget.layer
end

-- 按钮回调
function ui.btnCallBack()
   -- 返回按钮
    ui.widget.backBtn:registerScriptTapHandler(function ()
        audio.play(audio.button)
        replaceScene(require("ui.town.main").create())
    end)
    -- 排行榜按钮
    ui.widget.rankBtn:registerScriptTapHandler(function ()
        audio.play(audio.button)
        -- 申请数据
        addWaitNet()
        local params = {sid = player.sid}
        print("排行榜发送数据")
        tablePrint(params)
        net:spk_rank(params,function (data)
            delWaitNet()
            print("我的uid:"..require("data.player").uid)
            print("排行榜返回数据")
            tablePrint(data)
            local rankUI = require("ui.solo.rankUI").create(data)
            ui.widget.layer:addChild(rankUI,99999)
        end)
    end)
    -- 规则按钮
    ui.widget.helpBtn:registerScriptTapHandler(function ()
        audio.play(audio.button)
        local helpUI = require("ui.help").create(i18n.global.solo_help.string)
        ui.widget.layer:addChild(helpUI,99999)
    end)
    -- 返回
    ui.widget.layer.onAndroidBack = function ()
        audio.play(audio.button)
        replaceScene(require("ui.town.main").create())
    end
    addBackEvent(ui.widget.layer)
end

-- 获取时间格式的字符串
function ui.getTimeString(time)
    local h = math.floor(time / 60 / 60)
    local m = math.floor(time / 60 % 60)
    local s = time - m * 60 - h * 60 * 60
    h = string.format("%02d",h)
    m = string.format("%02d",m)
    s = string.format("%02d",s)
    local timeStr = h ..":" ..m ..":" ..s
    return timeStr
end

-- 改变时间标签的显示
function ui.refreshTime()
    if soloData.cd then
        local time = math.max(0,soloData.cd - os.time())
        --print("时间为"..time)
        ui.widget.countDownLabel:setString(ui.getTimeString(time))
        if time == 0 then
            replaceScene(require("ui.town.main").create())
        end
     end 
end

-- 创建倒计时标签
function ui.createCountDownLabel()
    if ui.data.countTime then
        local label = lbl.createFont2(18, ui.getTimeString(ui.data.countTime), ccc3(0xc3,0xff,0x42))
        local delay = CCDelayTime:create(1)
        local callfunc = CCCallFunc:create(function ()
            if ui.data.countTime <= 0 then
                label:stopAllActions()
                replaceScene(require("ui.town.main").create())
            else
                ui.data.countTime = ui.data.countTime - 1
                label:setString(ui.getTimeString(ui.data.countTime))
            end
        end)
        local arr = CCArray:create()
        arr:addObject(delay)
        arr:addObject(callfunc)
        local sequence = CCSequence:create(arr)
        label:runAction(CCRepeatForever:create(sequence))
        return label
    end
end

return ui