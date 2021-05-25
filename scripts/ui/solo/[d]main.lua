-- 单挑赛主界面

local ui = {}

require "common.func"
local view       = require "common.view"
local img        = require "res.img"
local lbl        = require "res.lbl"
local json       = require "res.json"
local i18n       = require "res.i18n"
local audio      = require "res.audio"
local net        = require "net.netClient"
local heros      = require "data.heros"
local cfghero    = require "config.hero"
local cfgSpkWave = require "config.spkwave"
local cfgMonster = require "config.monster"
local cfgDrug    = require "config.spkdrug"
local cfgTrader  = require "config.spktrader"
local cfgSpk     = require "config.spk"
local cfgequip   = require "config.equip"
local bag        = require "data.bag"
local player     = require "data.player"
local soloData   = require "data.solo"
local spkConf    = require "config.spk"

math.randomseed(os.time())
function ui.create()
    ui.widget = {}
    ui.data = {}

    ui.isAllDie = false

    -- 标记是否是第一次进入界面
    ui.isFirst = true

    -- ui.data.maxClearNum = spkConf[#spkConf].wave
    ui.data.maxClearNum = 100
    ui.data.overNum = 500
    ui.data.lastSelected = 0  --开始点击是选中的按钮
    ui.widget.heroIcons = {}
    -- 主层
    ui.widget.layer = CCLayer:create()
    ui.widget.layer.mainUI = ui
    -- 触摸判断层
    ui.widget.touchLayer = CCLayer:create()
    ui.widget.touchLayer:setTouchEnabled(true)
    -- ui.widget.touchLayer:setPosition(scalep(0,0))
    -- ui.widget.touchLayer:setScale(view.minScale)
    ui.widget.layer:addChild(ui.widget.touchLayer)
    -- 骨骼节点
    ui.widget.spineNode = json.create(json.ui.solo)
    ui.widget.spineNode:setScale(view.minScale)
    ui.widget.spineNode:setPosition(view.midX, view.midY)
    ui.widget.layer:addChild(ui.widget.spineNode)
    --ui.widget.spineNode:playAnimation("animation")
    ui.widget.spineNode:registerAnimation("start")
    -- 上方条骨骼
    ui.widget.upSpine = json.create(json.ui.solo_up)
    ui.widget.upSpine:setScale(view.minScale)
    ui.widget.upSpine:setPosition(view.midX,view.midY)
    ui.widget.layer:addChild(ui.widget.upSpine)
    ui.widget.upSpine:playAnimation("start")
    autoLayoutShift(ui.widget.upSpine,true)
    -- 下方条骨骼
    ui.widget.downSpine = json.create(json.ui.solo_down)
    ui.widget.downSpine:setScale(view.minScale)
    ui.widget.downSpine:setPosition(view.midX,view.midY)
    ui.widget.layer:addChild(ui.widget.downSpine)
    ui.widget.downSpine:playAnimation("start")
    autoLayoutShift(ui.widget.downSpine,false,true)
    -- 左方条骨骼
    ui.widget.sideSpine = json.create(json.ui.solo_side)
    ui.widget.sideSpine:setScale(view.minScale)
    ui.widget.sideSpine:setPosition(view.midX,view.midY)
    ui.widget.layer:addChild(ui.widget.sideSpine)
    ui.widget.sideSpine:playAnimation("start")
    autoLayoutShift(ui.widget.sideSpine, false, false, true, false)
    -- 右方触摸区域
    ui.widget.objLayer = CCLayerColor:create(ccc4(0, 0, 0, 0))
    ui.widget.objLayer:setContentSize(120 ,170)
    ui.widget.objLayer:setPosition(ccp(220 , -150))
    ui.widget.spineNode:addChild(ui.widget.objLayer)
    local sprite = CCSprite:create()
    sprite:setContentSize(CCSize(120,170))
    ui.widget.objTouchBtn = SpineMenuItem:create(json.ui.button, sprite)
    --ui.widget.objTouchBtn:setScale(view.minScale)
    ui.widget.objTouchBtn:setPosition(ccp(60,85))
    local touchMenu = CCMenu:createWithItem(ui.widget.objTouchBtn)
    touchMenu:setPosition(0, 0)
    ui.widget.objLayer:addChild(touchMenu)
    -- 倒计时标签
    ui.widget.countDownLabel = lbl.createFont2(14, ui.getTimeString(math.max(0,soloData.cd - os.time())), ccc3(0xc3,0xff,0x42))
    print("时间为"..ui.getTimeString(math.max(0,soloData.cd)))
    ui.widget.countDownLabel:setAnchorPoint(ccp(1, 0.5))
    ui.widget.countDownLabel:setPosition(ccp(50, 225))
    ui.widget.spineNode:addChild(ui.widget.countDownLabel)
    autoLayoutShift(ui.widget.countDownLabel,true)
    ui.widget.countDownLabel:scheduleUpdateWithPriorityLua(ui.refreshTime, 0)
    -- 结束标签
    ui.widget.endLabel = lbl.createFont2(14, i18n.global.solo_end.string, ccc3(255, 255, 255))
    ui.widget.endLabel:setAnchorPoint(ccp(0, 0.5))
    ui.widget.endLabel:setPosition(ccp(-35,225))
    ui.widget.spineNode:addChild(ui.widget.endLabel)
    autoLayoutShift(ui.widget.endLabel,true)
    ui.beCenter(ui.widget.endLabel,ui.widget.countDownLabel)
    -- 出战英雄名称标签
    ui.widget.heroNameLabel = lbl.createFont2(18, "", ccc3(255, 255, 255))
    ui.widget.heroNameLabel:setVisible(false)
    ui.widget.spineNode:addChildFollowSlot("code_name",ui.widget.heroNameLabel)
    -- 出战英雄阵营图标
    ui.widget.heroGroupImg = img.createGroupIcon(1)
    ui.widget.heroGroupImg:setVisible(false)
    ui.widget.heroGroupImg:setScale(0.92 * 0.42)
    ui.widget.spineNode:addChildFollowSlot("code_circle",ui.widget.heroGroupImg)
    -- 出战英雄血条
    ui.widget.heroHpBar = ui.createStateBar("hp","large")
    ui.widget.heroHpBar:setVisible(false)
    ui.widget.spineNode:addChildFollowSlot("code_upperline",ui.widget.heroHpBar)
    -- 出战英雄能量条
    ui.widget.heroMpBar = ui.createStateBar("mp","large")
    ui.widget.heroMpBar:setVisible(false)
    ui.widget.spineNode:addChildFollowSlot("code_underline",ui.widget.heroMpBar)
    -- 波次标签
    -- ui.widget.waveLabel = lbl.createFont2(24, string.format(i18n.global.solo_wave.string, 1), ccc3(250, 216, 105))
    ui.widget.waveLabel = lbl.createFont2(24, "--", ccc3(250, 216, 105))
    ui.widget.upSpine:addChildFollowSlot("code_text", ui.widget.waveLabel)
    -- 速度buff条
    local speedLayer = CCLayer:create()
    ui.widget.speedBuffBar = ui.createBuff({name = "speed" , nowNum = 0, maxNum = 20})
    speedLayer:addChild(ui.widget.speedBuffBar)
    speedLayer:setPositionY(-5)
    ui.widget.spineNode:addChildFollowSlot("code_drug1",speedLayer)
    autoLayoutShift(ui.widget.speedBuffBar,false,true,true,false)
    -- 力量buff条
    local powerLayer = CCLayer:create()
    ui.widget.powerBuffBar = ui.createBuff({name = "power" , nowNum = 0, maxNum = 20})
    powerLayer:addChild(ui.widget.powerBuffBar)
    powerLayer:setPositionY(-5)
    ui.widget.spineNode:addChildFollowSlot("code_drug2",powerLayer)
    autoLayoutShift(ui.widget.powerBuffBar,false,true,true,false)
    -- 暴击buff条
    local critLayer = CCLayer:create()
    ui.widget.critBuffBar = ui.createBuff({name = "crit" , nowNum = 0, maxNum = 20})
    critLayer:addChild(ui.widget.critBuffBar)
    critLayer:setPositionY(-5)
    ui.widget.spineNode:addChildFollowSlot("code_drug3",critLayer)
    autoLayoutShift(ui.widget.critBuffBar,false,true,true,false)
    -- 天使药剂按钮
    ui.widget.angelBtn = ui.createDrugBtn("angel")
    ui.widget.sideSpine:addChildFollowSlot("1code_leftdrag1",ui.widget.angelBtn.menu)
    -- 恶魔药剂按钮
    ui.widget.evilBtn = ui.createDrugBtn("evil")
    ui.widget.sideSpine:addChildFollowSlot("1code_leftdrag2",ui.widget.evilBtn.menu)
    -- 牛奶药剂按钮
    ui.widget.milkBtn = ui.createDrugBtn("milk")
    ui.widget.sideSpine:addChildFollowSlot("1code_leftdrag3",ui.widget.milkBtn.menu)
    -- 天使药剂标签
    ui.widget.angelLabel = lbl.createFont2(14, #soloData.angel)
    ui.widget.angelLabel:setPosition(ccp(65,19))
    ui.widget.angelLabel:setScale(1 / ui.widget.angelBtn:getScale())
    ui.widget.angelBtn.img:addChild(ui.widget.angelLabel)
    -- 恶魔药剂标签
    ui.widget.evilLabel = lbl.createFont2(14, #soloData.evil)
    ui.widget.evilLabel:setPosition(ccp(65,19))
    ui.widget.evilLabel:setScale(1 / ui.widget.evilBtn:getScale())
    ui.widget.evilBtn.img:addChild(ui.widget.evilLabel)
    -- 牛奶药剂标签
    ui.widget.milkLabel = lbl.createFont2(14, #soloData.milk)
    ui.widget.milkLabel:setPosition(ccp(65,19))
    ui.widget.milkLabel:setScale(1 / ui.widget.milkBtn:getScale())
    ui.widget.milkBtn.img:addChild(ui.widget.milkLabel)
    -- 自动战斗按钮
    ui.widget.autoBtn = ui.createAutoBtn()
    local autoMenu = CCMenu:createWithItem(ui.widget.autoBtn)
    autoMenu:setCascadeOpacityEnabled(true)
    autoMenu:ignoreAnchorPointForPosition(false)
    ui.widget.spineNode:addChildFollowSlot("code_autofight",autoMenu)
    ui.widget.autoBtn:setPositionX(42)
    autoLayoutShift(ui.widget.autoBtn,false,true,false,true)
    -- 战斗按钮
    ui.widget.battleBtn = ui.createBattleBtn()
    local battleMenu = CCMenu:createWithItem(ui.widget.battleBtn)
    battleMenu:setCascadeOpacityEnabled(true)
    battleMenu:ignoreAnchorPointForPosition(false)
    ui.widget.spineNode:addChildFollowSlot("code_button",battleMenu)
    -- 返回按钮
    ui.widget.backBtn = HHMenuItem:create(img.createUISprite(img.ui.back))
    ui.widget.backBtn:setScale(view.minScale)
    ui.widget.backBtn:setPosition(scalep(35, 540))
    local backMenu = CCMenu:createWithItem(ui.widget.backBtn)
    backMenu:setPosition(ccp(0, 0))
    ui.widget.layer:addChild(backMenu,1000)
    autoLayoutShift(ui.widget.backBtn,true,false,true,false)
    -- 扫荡商人按钮
    local traderBtnImg = img.createUISprite(img.ui.solo_trader_btn)
    ui.widget.traderBtn = SpineMenuItem:create(json.ui.button, traderBtnImg)
    ui.widget.traderBtn:setScale(view.minScale)
    ui.widget.traderBtn:setPosition(scalep(810, 540))
    local traderMenu = CCMenu:createWithItem(ui.widget.traderBtn)
    traderMenu:setPosition(ccp(0, 0))
    ui.widget.layer:addChild(traderMenu,1000)
    local btnSpine = json.create(json.ui.solo_btn)
    btnSpine:playAnimation("animation", -1)
    btnSpine:setPosition(ui.widget.traderBtn:getContentSize().width / 2,ui.widget.traderBtn:getContentSize().height / 2)
    traderBtnImg:addChild(btnSpine)
    autoLayoutShift(ui.widget.traderBtn,true,false,false,true)
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

    ui.initHandle()
    ui.btnCallback()

    -- local rewards = {}
    -- for i=1,10 do
    --     local item = {}
    --     item.type = 1
    --     item.id = 1
    --     item.num = 1
    --     table.insert(rewards,item)
    -- end

    -- local bufs = {}

    -- for i=1,20 do
    --     bufs[i] = {}
    --     bufs[i].id = i
    --     bufs[i].num = i
    -- end

    -- local bufList = {}
    --                 for i,v in ipairs(bufs) do
    --                     -- for j=1,v.num do
    --                     --     local item = {}
    --                     --     item.type = 3
    --                     --     item.id = v.id
    --                     --     item.num = 1
    --                     --     table.insert(rewards,item)
    --                     -- end
    --                     if bufList[cfgDrug[v.id].iconId] then
    --                         bufList[cfgDrug[v.id].iconId].num = bufList[cfgDrug[v.id].iconId].num + v.num
    --                     else
    --                         bufList[cfgDrug[v.id].iconId] = {}
    --                         bufList[cfgDrug[v.id].iconId].id = v.id
    --                         bufList[cfgDrug[v.id].iconId].num = v.num
    --                     end
    --                 end
    --                 for k,v in pairs(bufList) do
    --                     local item = {}
    --                     item.type = 3
    --                     item.id = v.id
    --                     item.num = v.num
    --                     table.insert(rewards,item)
    --                 end

    -- for i=10,20 do
    --     local item = {}
    -- end
    -- local sweepUI = require("ui.solo.sweepUI").create(rewards,ui)
    -- ui.widget.layer:addChild(sweepUI,99999)

    return ui.widget.layer
end

-- 两个元素整体居中
function ui.beCenter(item1,item2) 
    local interval = 8
    local width1 = item1:boundingBox():getMaxX() - item1:boundingBox():getMinX()
    local width2 = item2:boundingBox():getMaxX() - item2:boundingBox():getMinX()
    local totalW = width1 + width2 + interval
    print("长度为"..totalW.." "..width1.." "..width2)
    item1:setPositionX(-totalW / 2)
    item2:setPositionX(totalW / 2)

    -- drawBoundingbox(item1:getParent(), item1)
    -- drawBoundingbox(item2:getParent(), item2)
end

-- 初始化数据
function ui.initData(data)
end

-- 初始化操作
function ui.initHandle()
    -- 是否未设置阵容
    if soloData.heroList == nil or #soloData.heroList == 0 then
        local selectUI = require("ui.solo.selectHeroes")
        selectUI.mainUI = ui
        ui.widget.selectLayer = selectUI.create()
        ui.widget.layer:addChild(ui.widget.selectLayer,99999)

        -- local bag = {}
        -- for i=1,30 do
        --     local item = {}
        --     item.type = 3
        --     item.id = 1
        --     item.num = 1
        --     table.insert(bag,item)
        -- end
        -- ui.widget.layer:removeChildByTag(10)
        -- local sweepLayer = require("ui.solo.sweepUI").create(bag,ui)
        -- ui.widget.layer:addChild(sweepLayer,999999,10)

        return 
    end
    -- 创建一个短暂的触摸吞噬层防止影响动画(start动画15帧)
    ui.createSwallowLayer(15 / 30)
    -- 添加出战英雄
    ui.addHeroIcon()
    -- 设置波次
    --ui.widget.waveLabel:setString(string.format(i18n.global.solo_wave.string, soloData.getWave()))

    -- 如果首次进来是商人,需要把波次显示减1
    if ui.isFirst and soloData.getTrader() then
        soloData.setWave(soloData.getWave() - 1) 
    end
    ui.isFirst = false

    local stageLevel = soloData.getStageLevel()
    stageLevel = stageLevel < 5 and stageLevel or 4
    --ui.widget.waveLabel:setString(i18n.global["solo_stage" .. stageLevel].string .. " "..string.format(i18n.global.solo_wave.string, (soloData.getWave() - 1) % ui.data.maxClearNum + 1))
    ui.widget.waveLabel:setString(i18n.global["solo_stage" .. stageLevel].string .. ":"..((soloData.getWave() - 1) % ui.data.maxClearNum + 1))

    -- 通关情况
    local isClear = ui.clearStage()
    if isClear then
        return
    end

    if soloData.getReward() then    -- 有宝箱
        print("宝箱不为空")
        ui.showRewardSpine()
        --ui.showRewardUI()
    elseif soloData.getBuf() then   -- 场上的是药水
        local bufID = soloData.getBufType()
        ui.setBattleBtnState(ui.widget.battleBtn,"disable")
        ui.showPotionSpine(bufID)
    elseif soloData.getTrader() then -- 场上的是商人
        local traderID = cfgTrader[soloData.getTrader()].Body
        ui.setBattleBtnState(ui.widget.battleBtn,"skip")
        ui.showTraderSpine(traderID)
    elseif soloData.getStage() then -- 场上的是Boss
        local bossID = cfgSpkWave[soloData.getStage()].show
        ui.showBossSpine(bossID)
    end
    -- 判断是否自动战斗
    local isAuto = soloData.getAutoState()
    if isAuto and ui.widget.autoBtn.state == "normal" then
        ui.changeAutoBtnState(ui.widget.autoBtn)
        if ui.widget.battleBtn.state == "fight" then
            ui.setBattleBtnState(ui.widget.battleBtn,"auto")
        end
    end
    -- 如果有选择出战英雄
    if soloData.getSelectOrder() and soloData.heroList[soloData.getSelectOrder()] and soloData.heroList[soloData.getSelectOrder()].hp > 0 then
        ui.selectHero(soloData.getSelectOrder())
        return
    end
    -- 没有选人的话默认第一个上阵
    for i,v in ipairs(soloData.heroList) do
        if v.hp > 0 then
            ui.selectHero(i)
            return
        end
    end
    -- 全部阵亡的情况
    ui.heroAllDie()
end

-- 刷新Boss
function ui.refreshBoss()
    -- if (soloData.getWave() - 1) % 100 + 1 > ui.data.maxClearNum then
    --     soloData.setWave(soloData.getWave() + 1) 
    --     ui.clearStage()
    --     return
    -- end
    --if math.floor(soloData.getWave() / ui.data.maxClearNum) > soloData.level then
    if soloData.getWave() >= ui.data.overNum then
        soloData.setWave(soloData.getWave() + 1) 
        ui.clearStage()
        return
    end

    --print("当前的波次"..soloData.getStage())

    soloData.setReward(nil)
    soloData.setTrader(nil)
    soloData.setBuf(nil)
    soloData.setWave(soloData.getWave() + 1)   
    --if math.floor(soloData.getWave() / ui.data.maxClearNum) > soloData.level then
        --ui.widget.waveLabel:setString(string.format(i18n.global.solo_wave.string, ui.data.maxClearNum ))
    if soloData.getWave() >= ui.data.overNum then
        local stageLevel = soloData.getStageLevel()
        --ui.widget.waveLabel:setString(i18n.global["solo_stage" .. stageLevel].string .." " .. string.format(i18n.global.solo_wave.string, ui.data.maxClearNum))
        ui.widget.waveLabel:setString(i18n.global["solo_stage" .. stageLevel].string ..":" .. ui.data.maxClearNum)
    else
        --ui.widget.waveLabel:setString(string.format(i18n.global.solo_wave.string, soloData.getWave()))
        local stageLevel = soloData.getStageLevel()
        --ui.widget.waveLabel:setString(i18n.global["solo_stage" .. stageLevel].string .." " .. string.format(i18n.global.solo_wave.string, (soloData.getWave() - 1) % ui.data.maxClearNum + 1))
        ui.widget.waveLabel:setString(i18n.global["solo_stage" .. stageLevel].string ..":" ..  ((soloData.getWave() - 1) % ui.data.maxClearNum + 1))
    end
    
    ui.widget.spineNode:removeChildFollowSlot("code_trader")
    ui.widget.spineNode:removeChildFollowSlot("code_drug")
    -- 重置按钮
    ui.setBattleBtnState(ui.widget.battleBtn,"fight")
    if ui.widget.autoBtn.state == "auto" then
        ui.setBattleBtnState(ui.widget.battleBtn,"auto")
        ui.widget.spineNode:registerAnimation("auto_fight",-1)
        ui.widget.autoSpine:registerAnimation("auto_fight",-1)
        ui.widget.autoSpine:setVisible(true)
    end
    -- 重置boss
    local bossList = soloData.convertBossInfo({})
    soloData.bossList = bossList
    -- 播放动画
    local id = cfgSpkWave[soloData.getStage()].show
    ui.showBossSpine(id)
end

-- 刷新界面
function ui.refreshUI(data)
    print("---------进入刷新函数 refreshUI")
    -- 失败分战斗回合和英雄死亡两种情况
    if not data.win then
        if data.mhpp then
            soloData.heroList[soloData.getSelectOrder()].hp = data.mhpp
        else
            soloData.heroList[soloData.getSelectOrder()].hp = 0
        end
        if data.menergy then
            soloData.heroList[soloData.getSelectOrder()].mp = data.menergy
        else
            soloData.heroList[soloData.getSelectOrder()].mp = 0
        end
        -- soloData.heroList[soloData.getSelectOrder()].hp = 0
        -- soloData.heroList[soloData.getSelectOrder()].mp = 0
        ui.setStateBar(ui.widget.heroIcons[soloData.getSelectOrder()].hpBar,soloData.heroList[soloData.getSelectOrder()].hp / 100)
        ui.setStateBar(ui.widget.heroIcons[soloData.getSelectOrder()].mpBar,soloData.heroList[soloData.getSelectOrder()].mp / 100)

        if soloData.heroList[soloData.getSelectOrder()].hp == 0 then
            ui.beGray(ui.widget.heroIcons[soloData.getSelectOrder()])
            clearShader(ui.widget.heroIcons[soloData.getSelectOrder()].hpBar,true)
            clearShader(ui.widget.heroIcons[soloData.getSelectOrder()].mpBar,true)
            soloData.setSelectOrder(nil)
        end

        -- ui.beGray(ui.widget.heroIcons[soloData.getSelectOrder()])
        -- clearShader(ui.widget.heroIcons[soloData.getSelectOrder()].hpBar,true)
        -- clearShader(ui.widget.heroIcons[soloData.getSelectOrder()].mpBar,true)
        -- soloData.setSelectOrder(nil)
        for i,v in ipairs(data.ehpp) do
            soloData.bossList[i].hp = v
        end
        for i,v in ipairs(soloData.heroList) do
            if v.hp >= 0 then
                ui.initHandle()
                return 
            end
        end
        ui.heroAllDie()
    else
        ui.widget.spineNode:unregisterAnimation("auto_fight")
        ui.widget.autoSpine:unregisterAnimation("auto_fight")
        ui.widget.autoSpine:setVisible(false)
        if data.mhpp then
            soloData.heroList[soloData.getSelectOrder()].hp = data.mhpp
        end
        if data.menergy then
            soloData.heroList[soloData.getSelectOrder()].mp = data.menergy
        end
        ui.setStateBar(ui.widget.heroIcons[soloData.getSelectOrder()].hpBar,soloData.heroList[soloData.getSelectOrder()].hp / 100)
        ui.setStateBar(ui.widget.heroIcons[soloData.getSelectOrder()].mpBar,soloData.heroList[soloData.getSelectOrder()].mp / 100)
        ui.selectHero(soloData.getSelectOrder())
        --ui.data.estage = data.nstage
        if data.buf then
            print("获得的药水id为"..data.buf)
            soloData.setStage(data.nstage)
            soloData.setBuf(data.buf)
            soloData.setReward(nil)
            soloData.setTrader(nil)
            ui.showPotionSpine(soloData.getBufType())
            if ui.widget.autoBtn.state == "auto" then
                --ui.changeAutoBtnState(ui.widget.autoBtn)
                ui.widget.spineNode:unregisterAnimation("auto_fight")
                ui.widget.autoSpine:unregisterAnimation("auto_fight")
                ui.widget.autoSpine:setVisible(false)
            end
            ui.setBattleBtnState(ui.widget.battleBtn,"fight")
        elseif data.seller then
            soloData.setTrader(data.seller)
            soloData.setReward(nil)
            soloData.setBuf(nil)
            local traderName = cfgTrader[data.seller].Body
            if ui.widget.autoBtn.state == "auto" then
                --ui.changeAutoBtnState(ui.widget.autoBtn)
                ui.widget.spineNode:unregisterAnimation("auto_fight")
                ui.widget.autoSpine:unregisterAnimation("auto_fight")
                ui.widget.autoSpine:setVisible(false)
            end
            ui.setBattleBtnState(ui.widget.battleBtn,"skip")
            ui.showTraderSpine(traderName)
        elseif data.reward then
            soloData.setReward(data.reward)
            soloData.setBuf(nil)
            soloData.setTrader(nil)
            soloData.setStage(data.nstage)
            ui.showRewardSpine()
            --ui.showRewardUI()
        end
        -- boss列表
        local bossList = soloData.convertBossInfo({})
        soloData.bossList = bossList
        ui.initHandle()
    end
end

-- 按钮的点击回调
function ui.btnCallback()
    addBackEvent(ui.widget.layer)
    local function onEnter()
        ui.widget.layer.notifyParentLock()
    end

    local function onExit()
        ui.widget.layer.notifyParentUnlock()
    end
    ui.widget.layer.onAndroidBack = function ()
        audio.play(audio.button)
        replaceScene(require("ui.town.main").create())
    end
    -- 主层
    ui.widget.layer:registerScriptHandler(function(event)
        if event == "enter" then 
            onEnter()
        elseif event == "exit" then
            onExit()
        elseif event == "cleanup" then

        end
    end)
    -- 返回按钮
    ui.widget.backBtn:registerScriptTapHandler(function ()
        audio.play(audio.button)
        replaceScene(require("ui.town.main").create())
    end)
    -- 扫荡商人列表
    ui.widget.traderBtn:registerScriptTapHandler(function ()
        audio.play(audio.button)
        ui.widget.traderBtn:setEnabled(false)
        local delay = CCDelayTime:create(0.8)
        local callfunc = CCCallFunc:create(function ()
            ui.widget.traderBtn:setEnabled(true)
        end)
        local sequence = CCSequence:createWithTwoActions(delay,callfunc)
        ui.widget.traderBtn:runAction(sequence)
        -- local traderUI = require("ui.solo.traderUI").create()
        -- ui.widget.layer:addChild(traderUI,99999)
        local traderClassifyUI = require("ui.solo.traderClassifyUI").create()
        ui.widget.layer:addChild(traderClassifyUI,99999)
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
        ui.widget.helpBtn:setEnabled(false)
        local delay = CCDelayTime:create(0.8)
        local callfunc = CCCallFunc:create(function ()
            ui.widget.helpBtn:setEnabled(true)
        end)
        local sequence = CCSequence:createWithTwoActions(delay,callfunc)
        ui.widget.helpBtn:runAction(sequence)
        local helpUI = require("ui.help").create(i18n.global.solo_help.string)
        ui.widget.layer:addChild(helpUI,99999)
    end)

    
    -- 药剂按钮
    local callBack 
    local size = ui.widget.angelBtn:getContentSize()
    -- 天使药剂按钮
    callBack = function () ui.addDrugTipUI("angel") end
    ui.widget.angelNode = ui.createTipBtn(275,288,ui.widget.angelBtn,"angel",callBack)
    ui.widget.angelNode:setContentSize(size)
    ui.widget.angelNode:setPosition(size.width / 2,size.height / 2)
    ui.widget.angelBtn:addChild(ui.widget.angelNode)
    -- 恶魔药剂
    callBack = function () ui.addDrugTipUI("evil") end
    ui.widget.evilNode = ui.createTipBtn(275,288,ui.widget.evilBtn,"evil",callBack)
    ui.widget.evilNode:setContentSize(size)
    ui.widget.evilNode:setPosition(size.width / 2,size.height / 2)
    ui.widget.evilBtn:addChild(ui.widget.evilNode)
    -- 牛奶药剂
    callBack = function () ui.addDrugTipUI("milk") end
    ui.widget.milkNode = ui.createTipBtn(275,288,ui.widget.milkBtn,"milk",callBack)
    ui.widget.milkNode:setContentSize(size)
    ui.widget.milkNode:setPosition(size.width / 2,size.height / 2)
    ui.widget.milkBtn:addChild(ui.widget.milkNode)

    -- -- 天使药剂按钮
    -- ui.widget.angelBtn:registerScriptTapHandler(function ()
    --     if not ui.isAllDie then
    --         ui.addDrugTipUI("angel")
    --     end
    -- end)
    -- -- 恶魔药剂按钮
    -- ui.widget.evilBtn:registerScriptTapHandler(function ()
    --     if not ui.isAllDie then
    --         ui.addDrugTipUI("evil")
    --     end
    -- end)
    -- -- 牛奶药剂按钮
    -- ui.widget.milkBtn:registerScriptTapHandler(function ()
    --     if not ui.isAllDie then
    --         ui.addDrugTipUI("milk")
    --     end
    -- end)

    -- 英雄图标点击
    ui.widget.touchLayer:registerScriptTouchHandler(ui.onTouch)
    -- 出战按钮
    ui.widget.battleBtn:registerScriptTapHandler(function ()
        audio.play(audio.button)
        if ui.widget.battleBtn.state == "fight" then
            -- 进入战斗场景
            addWaitNet()
            local params = {sid = player.sid,hid = soloData.heroList[soloData.getSelectOrder()].hid}
            print("手动战斗的数据")
            tablePrint(params)
            net:spk_fight(params, function (data) 
                delWaitNet()
                print("返回手动战斗信息")
                tbl2string(data)
                if data.status == 0 then
                    -- 地牢成就
                    if soloData.getWave() % 100 == 0 and data.win then
                        local achieveData = require "data.achieve"
                        achieveData.add(ACHIEVE_TYPE_SOLOPASS, 1) 
                    end
                    ui.storageReward(data.reward)
                    --ui.refreshFightData(data)
                    --replaceScene(require("ui.solo.main").create())
                    local video = clone(data)
                    video.data = data
                    video.stage = soloData.getStage()
                    video.atk =  {}
                    video.atk.camp = {
                        [1] = soloData.heroList[soloData.getSelectOrder()],
                    }
                    video.def =  {}
                    video.def.camp = soloData.getAliveBoss()
                    replaceScene(require("fight.solo.loading").create(video))
                end
            end)
        elseif ui.widget.battleBtn.state == "auto" then
            -- 自动战斗
            addWaitNet()
            local params = {sid = player.sid,hid = soloData.heroList[soloData.getSelectOrder()].hid}
            print("自动战斗数据")
            tablePrint(params)
            net:spk_fight(params, function (data) 
                delWaitNet()
                print("返回的自动战斗信息")
                tablePrint(data)
                if data.status == 0 then
                    -- 地牢成就
                    if soloData.getWave() % 100 == 0 and data.win then
                        local achieveData = require "data.achieve"
                        achieveData.add(ACHIEVE_TYPE_SOLOPASS, 1) 
                    end
                    ui.storageReward(data.reward)
                    local video = clone(data)
                    video.data = data
                    video.stage = soloData.getStage()
                    video.atk =  {}
                    video.atk.camp = {
                        [1] = soloData.heroList[soloData.getSelectOrder()],
                    }
                    video.def =  {}
                    video.def.camp = soloData.getAliveBoss()
                    video.auto = true
                    video.callback = function()
                        ui.endBossSpine(data)
                    end
                    if video.win then
                        ui.endBossSpine(data)
                    else
                        ui.widget.layer:addChild(require("fight.solo.lose").create(video), 1000)
                    end
                end
            end)
        elseif ui.widget.battleBtn.state == "skip" then
            -- 跳过
            -- 发送跳过操作
            addWaitNet()
            local params = {sid = player.sid ,skip = 1}
            print("发送的跳过信息")
            tablePrint(params)
            net:spk_buy(params, function (data)
                delWaitNet()
                print("返回的跳过信息")
                tablePrint(data)
                if data.status == 0 then
                    soloData.setStage(data.nstage)
                    ui.setBattleBtnState(ui.widget.battleBtn,"fight")
                    ui.endTraderSpine()      
                end
            end)
        end
    end)
    -- 自动按钮
    ui.widget.autoBtn:registerScriptTapHandler(function ()
        audio.play(audio.button)
        if ui.widget.autoBtn.state == "normal" and ui.widget.battleBtn.state == "fight" then
            --ui.widget.spineNode:registerAnimation("auto_fight",-1)
            ui.changeAutoBtnState(ui.widget.autoBtn)
            ui.setBattleBtnState(ui.widget.battleBtn,"auto")
        elseif ui.widget.autoBtn.state == "auto" and ui.widget.battleBtn.state == "auto" then
            --ui.widget.spineNode:unregisterAnimation("auto_fight")
            ui.widget.spineNode:registerAnimation("animation")
            ui.changeAutoBtnState(ui.widget.autoBtn)
            ui.setBattleBtnState(ui.widget.battleBtn,"fight")
        else
            ui.changeAutoBtnState(ui.widget.autoBtn)
        end
    end)
    -- 右方触摸区域
    ui.widget.objTouchBtn:registerScriptTapHandler(function ()
        -- 如果上阵的是buff药水根据不同
        if soloData.getBuf() then
            -- local bufID = soloData.getBufType()
            -- if bufID == "power" or bufID == "speed" or bufID == "crit" then
            --    ui.showDrugUI() 
            -- end
        -- 如果上阵的是商人
        elseif soloData.getTrader() then
            ui.showBuyUI()
        -- 如果上阵的是boss
        elseif soloData.getStage() then
            ui.showBossList()
        end
    end)
end

-- 添加英雄图标
function ui.addHeroIcon()
    for i=1,#soloData.heroList do
        if ui.widget.heroIcons[i] then
            return
        end
        ui.widget.heroIcons[i] = ui.createHeroIcon(soloData.heroList[i])
        ui.widget.downSpine:addChildFollowSlot("code_hero"..i,ui.widget.heroIcons[i])
    end
end

-- 创建一个药水按钮
function ui.createDrugBtn(drugType)
    local btnImg = img.createUISprite(img.ui.grid)
    local size = btnImg:getContentSize()
    local drugPath 
    if drugType == "milk" then
        drugPath = img.ui.solo_milk
    elseif drugType == "angel" then
        drugPath = img.ui.solo_angel_potion
    elseif drugType == "evil" then
        drugPath = img.ui.solo_evil_potion
    end
    local icon = img.createUISprite(drugPath)
    icon:setScale(0.9 / 1.5)
    icon:setPosition(btnImg:getContentSize().width / 2,btnImg:getContentSize().height / 2)
    btnImg:addChild(icon)
    local btn = SpineMenuItem:create(json.ui.button, btnImg)
    btn:setScale(1.5)
    local drugMenu = CCMenu:createWithItem(btn)
    drugMenu:setPosition(ccp(0,0))
    btn:setPosition(ccp(0,0))
    btn.menu = drugMenu
    btn.img = btnImg

    btn:setPositionY(1)

    return btn
end

-- 创建一个血条或蓝条(type种类："hp","mp";size种类："small","large")
function ui.createStateBar(type,size,percent)
    percent = percent or 100
    local bgStr = {hp = img.ui.fight_hp_bg[size], mp = img.ui.fight_ep_bg[size]}
    local fgStr = {hp = img.ui.fight_hp_fg[size], mp = img.ui.fight_ep_fg[size]}
    -- 底框
    local box = img.createUISprite(bgStr[type])
    box:setCascadeOpacityEnabled(true)
    -- 血条
    local bar = createProgressBar(img.createUISprite(fgStr[type]))
    bar:setAnchorPoint(ccp(0, 0.5))
    bar:setPositionX(box:getContentSize().width / 2 - bar:getContentSize().width / 2)
    bar:setPositionY(box:getContentSize().height / 2)
    box:addChild(bar)

    bar:setPercentage(percent)

    box.bar = bar
    box.type = type
    box.percent = percent

    return box
end

-- 直接设置血条或蓝条的状态
function ui.setStateBar(stateBar,ratio)
    stateBar.bar:stopAllActions()
    --stateBar.bar:setScaleX(ratio)
    ratio = ratio > 1 and 1 or ratio
    stateBar.bar:setPercentage(ratio * 100)
end

-- 改变血条或蓝条的状态
function ui.changeStateBar(stateBar,ratio,time)
    ratio = ratio > 1 and 1 or ratio
    time = time or 0.5
    local percent = stateBar.bar:getPercentage()
    local actionTimes = time / 0.01
    local deltaPercent = (ratio * 100 - percent) / actionTimes
    local delay = CCDelayTime:create(0.01)
    local callfunc = CCCallFunc:create(function ()
        percent = percent + deltaPercent
        stateBar.bar:setPercentage(percent)
    end)
    local sequence = CCSequence:createWithTwoActions(callfunc,delay)
    stateBar.bar:stopAllActions()
    stateBar.bar:runAction(CCRepeat:create(sequence,actionTimes))
end

-- 创建一个左侧buff条
function ui.createBuff(buffInfo)
    buffInfo.maxNum = buffInfo.maxNum or 20
    local name = buffInfo.name
    local iconList = {speed = img.ui.solo_speed_potion_small, power = img.ui.solo_power_potion_small, crit = img.ui.solo_crit_potion_small}
    local barList = {speed = img.ui.solo_speed_bar, power = img.ui.solo_power_bar, crit = img.ui.solo_crit_bar}

    local board = img.createUI9Sprite(img.ui.main_coin_bg)
    board:setPreferredSize(CCSize(182, 39))
    board:setAnchorPoint(ccp(0.5,1))
    -- 进度条
    local progressBar = createProgressBar(img.createUISprite(barList[name]))
    progressBar:setAnchorPoint(ccp(0, 0.5))
    progressBar:setPosition(ccp(8, board:getContentSize().height / 2 + 3))
    progressBar:setPercentage(buffInfo.nowNum / buffInfo.maxNum < 1 and buffInfo.nowNum / buffInfo.maxNum * 100 or 100)
    board:addChild(progressBar)

    -- 进度标签
    local progressLabel = lbl.createFont2(14, buffInfo.nowNum .."/" ..buffInfo.maxNum)
    progressLabel:setPosition(ccp(board:getContentSize().width / 2, board:getContentSize().height / 2 + 3))
    board:addChild(progressLabel)

    -- 隐藏的按钮
    -- local sprite = CCSprite:create()
    -- sprite:setContentSize(board:getContentSize())
    -- local iconBtn = SpineMenuItem:create(json.ui.button, sprite)
    -- iconBtn:setPosition(ccp(board:getContentSize().width / 2,board:getContentSize().height / 2))
    -- local touchMenu = CCMenu:createWithItem(iconBtn)
    -- touchMenu:setPosition(0, 0)
    -- board:addChild(touchMenu)
    -- iconBtn:registerScriptTapHandler(function ()
    --     --ui.showBuffIntro(name)
    -- end)

    -- 药剂特效
    local spineList = {speed = json.ui.solo_speed, power = json.ui.solo_power, crit = json.ui.solo_crit}
    local drugSpine = json.create(spineList[name])
    drugSpine:setPosition(8,board:getContentSize().height / 2 + 2)
    board:addChild(drugSpine)

    -- 图标
    local iconList = {speed = img.ui.solo_speed_potion_small, power = img.ui.solo_power_potion_small, crit = img.ui.solo_crit_potion_small}
    local codeList = {speed = "code_3702", power = "code_3802", crit = "code_3902"}
    local icon = img.createUISprite(iconList[name])
    drugSpine:addChildFollowSlot(codeList[name],icon)
    icon:setPositionY(1)
    local act = {speed = "1speed_click" , power = "2power_click", crit = "3cc_click"}
    drugSpine:playAnimation(act[name])
    drugSpine:stopAnimation()
    --     -- 速度图标
    -- ui.widget.speedIcon = img.createUISprite(img.ui.solo_speed_potion_small)
    -- ui.widget.spineNode:addChildFollowSlot("code_3702",ui.widget.speedIcon)
    -- ui.widget.speedIcon:setPositionY(-1)
    -- autoLayoutShift(ui.widget.speedIcon,false,true)
    -- -- 力量图标
    -- ui.widget.powerIcon = img.createUISprite(img.ui.solo_power_potion_small)
    -- ui.widget.spineNode:addChildFollowSlot("code_3802",ui.widget.powerIcon)
    -- ui.widget.powerIcon:setPositionY(-1)
    -- autoLayoutShift(ui.widget.powerIcon,false,true)
    -- -- 暴击图标
    -- ui.widget.critIcon = img.createUISprite(img.ui.solo_crit_potion_small)
    -- ui.widget.spineNode:addChildFollowSlot("code_3902",ui.widget.critIcon)
    -- ui.widget.critIcon:setPositionY(-1)
    -- autoLayoutShift(ui.widget.critIcon,false,true)

    -- local act = {speed = "1speed_click" , power = "2power_click", crit = "3cc_click"}
    -- drugSpine:playAnimation(act[name],-1)
    -- ui.widget.spineNode:registerAnimation(act[name],-1)

    local btn = ui.createTipBtn(174,233,board,name)
    btn:setContentSize(board:getContentSize())
    btn:setPosition(ccp(board:getContentSize().width / 2,board:getContentSize().height / 2))
    board:addChild(btn)

    board.name = name
    board.progressBar = progressBar
    board.progressLabel = progressLabel
    board.nowNum = buffInfo.nowNum
    board.maxNum = buffInfo.maxNum
    board.drugSpine = drugSpine

    return board
end

-- 创建一个用于显示药水弹窗的隐藏按钮
function ui.createTipBtn(posX,posY,parent,name,callback)
    local tipUI
    local btn = CCNode:create()
    btn:setTouchEnabled(true)
    btn:setContentSize(parent:getContentSize())
    btn:setAnchorPoint(ccp(0.5,0.5))
    btn:setPosition(ccp(parent:getContentSize().width / 2,parent:getContentSize().height / 2))
    btn:registerScriptTouchHandler(function (event,x,y)
        if event == "began" then
            print("aaaaaa")
            local point = btn:getParent():convertToNodeSpace(ccp(x, y))
            local rect = btn:boundingBox()
            if rect:containsPoint(point) then
                local delay = CCDelayTime:create(0.3)
                local callfunc = CCCallFunc:create(function()
                    tipUI = ui.showBuffIntro(name)
                    tipUI.bg:setPosition(scalep(posX,posY))
                    local size = tipUI.bg:getBoundingBox()
                    local posX1 = tipUI.bg:getPositionX()
                    tipUI.bg:setPositionX(math.max(size.width / 2,posX1))
                    if name == "angel" or name == "evil" or name == "milk" then
                        autoLayoutShift(tipUI.bg,false,false,true,false)
                    else
                        autoLayoutShift(tipUI.bg,false,true,false,false)
                    end
                end)
                local sequence = CCSequence:createWithTwoActions(delay,callfunc)
                btn:stopAllActions()
                btn:runAction(sequence)
                return true
            else
                return false
            end
        elseif event == "ended" then
            print("ended")
            btn:stopAllActions()
            if tipUI then
                tipUI:removeFromParent()
                tipUI = nil
            elseif callback then
                print("bbbbb")
                callback()
            end
        end
    end)
    return btn
end

-- 显示buff药水的介绍
function ui.showBuffIntro(name)
    local layer = CCLayer:create()
    layer:setTouchEnabled(true)
    -- 背景框
    local bg = img.createUI9Sprite(img.ui.tips_bg)
    bg:setPreferredSize(CCSizeMake(430, 166))
    bg:setScale(view.minScale)
    bg:setPosition(scalep(174,223))
    layer.bg = bg
    layer:addChild(bg)
    local bg_w = bg:getContentSize().width
    local bg_h = bg:getContentSize().height
    -- 横线
    local lineImg = img.createUI9Sprite(img.ui.hero_tips_fgline)
    lineImg:setPreferredSize(CCSize(378, 1))
    lineImg:setPosition(ccp(bg:getContentSize().width / 2, 86))
    bg:addChild(lineImg)
    -- 图标框
    local box = img.createUISprite(img.ui.grid)
    box:setScale(52 / box:getContentSize().width)
    --box:setPosition(ccp(,123))
    box:setAnchorPoint(ccp(0,1))
    --box:setPositionX((bg:getContentSize().width - 282) / 2)
    box:setPositionX(24)
    box:setPositionY(bg:getContentSize().height - box:getPositionX())
    bg:addChild(box)
    -- 图标
    local drugStr = {power = "solo_power_potion_small", speed = "solo_speed_potion_small", crit = "solo_crit_potion_small",
                     milk = "solo_milk", angel = "solo_angel_potion", evil = "solo_evil_potion"}
    local icon = img.createUISprite(img.ui[drugStr[name]])
    icon:setScale(1 / box:getScale())
    if name == "milk" or name == "angel" or name == "evil" then
        icon:setScale(1 / box:getScale() * 0.4)
    end
    icon:setPosition(box:getContentSize().width / 2,box:getContentSize().height / 2)
    box:addChild(icon)
    -- 名称标签
    local nameLabel = lbl.createFont1(22, i18n.global["solo_drugName_"..name].string ,ccc3(0xff, 0xe4, 0x9c))
    nameLabel:setAnchorPoint(ccp(0,0))
    nameLabel:setPosition(ccp(80,106))
    bg:addChild(nameLabel)
    -- 介绍标签
    local introLabel
    if name == "milk" or name == "evil" or name == "angel" then
        local addStr = i18n.global["solo_drugIntro_"..name].string
        introLabel = lbl.createMix({font=1, size=16, width=380, 
            text=addStr, color=ccc3(0xfb,0xfb,0xfb), align=kCCTextAlignmentLeft})
        --introLabel = lbl.createFont1(16, addStr ,ccc3(0xff, 0xfb, 0xec))
    else 
        local addNum = {power = 1.5, speed = 2, crit = 2}
        local drugNum = soloData.heroList[soloData.getSelectOrder()][name]
        local addStr = string.format(i18n.global["solo_drugIntro_"..name].string, addNum[name] * drugNum)
        introLabel = lbl.createMix({font=1, size=16, width=380, 
            text=addStr, color=ccc3(0xfb,0xfb,0xfb), align=kCCTextAlignmentLeft})
        --introLabel = lbl.createFont1(16, addStr ,ccc3(0xff, 0xfb, 0xec))
    end
    introLabel:setAnchorPoint(ccp(0,1))
    introLabel:setPosition(ccp((bg:getContentSize().width - 380) / 2,70))
    bg:addChild(introLabel)
    -- 隐藏的按钮
    local sprite = CCSprite:create()
    sprite:setContentSize(bg:getContentSize())
    local btn = SpineMenuItem:create(json.ui.button, sprite)
    btn:setPosition(ccp(bg:getContentSize().width / 2,bg:getContentSize().height / 2))
    local touchMenu = CCMenu:createWithItem(btn)
    touchMenu:setPosition(0, 0)
    bg:addChild(touchMenu)

    layer:registerScriptTouchHandler(function (event,x,y)
        if event == "began" then
            return true
        elseif event == "ended" then
            layer:removeFromParent()
        end
    end)

    ui.widget.layer:addChild(layer,99999)
    return layer
end

-- 改变buff药水的显示
function ui.changeBuffBarState(bar,heroInfo)
    print("buff名称"..bar.name)
    print("最大值:"..bar.maxNum)
    print("当前值"..heroInfo[bar.name])
    bar.nowNum = bar.maxNum > heroInfo[bar.name] and heroInfo[bar.name] or bar.maxNum
    bar.progressLabel:setString(bar.nowNum .."/" ..bar.maxNum)
    bar.progressBar:setPercentage(bar.nowNum / bar.maxNum * 100)
end

-- 创建自动出战按钮
function ui.createAutoBtn()
    -- 主按钮
    local btnImg = img.createUI9Sprite(img.ui.btn_1)
    btnImg:setPreferredSize(CCSizeMake(88, 80))
    local autoBtn = SpineMenuItem:create(json.ui.button, btnImg)
    -- 自动时图片
    local autoImg = img.createUI9Sprite(img.ui.btn_7)
    autoImg:setPreferredSize(CCSizeMake(88, 80))
    autoImg:setPosition(ccp(btnImg:getContentSize().width / 2,btnImg:getContentSize().height / 2))
    btnImg:addChild(autoImg)
    -- 自动时图标
    local autoIcon = img.createUISprite(img.ui.solo_auto_battle_change)
    autoIcon:setPosition(ccp(autoImg:getContentSize().width / 2,autoImg:getContentSize().height / 2 + 5))
    autoImg:addChild(autoIcon)
    -- 自动时标签
    local autoLabel = lbl.createFont1(12, i18n.global.solo_battle_manual.string ,ccc3(0x1d ,0x67 ,0x00))
    autoLabel:setPosition(ccp(autoImg:getContentSize().width / 2,autoImg:getContentSize().height / 2 - 20))
    autoImg:addChild(autoLabel)
    -- 正常时图片
    local normalImg = img.createUI9Sprite(img.ui.btn_1)
    normalImg:setPreferredSize(CCSizeMake(88, 80))
    normalImg:setPosition(ccp(btnImg:getContentSize().width / 2,btnImg:getContentSize().height / 2))
    btnImg:addChild(normalImg)
    -- 正常时图标
    local normalIcon = img.createUISprite(img.ui.solo_auto_battle_normal)
    normalIcon:setPosition(ccp(normalImg:getContentSize().width / 2,normalImg:getContentSize().height / 2 + 5))
    normalImg:addChild(normalIcon)
    -- 正常时标签
    local normalLabel = lbl.createFont1(12, i18n.global.solo_battle_auto.string ,ccc3(0x86 ,0x3b ,0x21))
    normalLabel:setPosition(ccp(normalImg:getContentSize().width / 2,normalImg:getContentSize().height / 2 - 20))
    normalImg:addChild(normalLabel)
    -- 自动战斗按钮特效
    ui.widget.autoSpine = json.create(json.ui.solo_auto)
    ui.widget.autoSpine:setPosition(ccp(btnImg:getContentSize().width / 2,btnImg:getContentSize().height / 2))
    btnImg:addChild(ui.widget.autoSpine)

    autoBtn.state = "normal"
    autoBtn.normalImg = normalImg
    autoBtn.label = label

    return autoBtn
end

-- 改变自动战斗按钮状态
function ui.changeAutoBtnState(btn)
    if btn.state == "normal" then
        btn.state = "auto"
        btn.normalImg:setVisible(false)
        soloData.setAutoState(true)
        if not soloData.getTrader() and not soloData.getReward() and not soloData.getBuf() then
            ui.widget.spineNode:registerAnimation("auto_fight",-1)
            ui.widget.autoSpine:registerAnimation("auto_fight",-1)
            ui.widget.autoSpine:setVisible(true)
        end
    else
        btn.state = "normal"
        btn.normalImg:setVisible(true)
        soloData.setAutoState(false)
        ui.widget.spineNode:unregisterAnimation("auto_fight")
        ui.widget.autoSpine:unregisterAnimation("auto_fight")
        ui.widget.autoSpine:setVisible(false)
    end
end

-- 创建中间的战斗按钮
function ui.createBattleBtn()
    -- 主按钮
    local battleImg = img.createUISprite(img.ui.solo_battle_btn)
    local battleBtn = SpineMenuItem:create(json.ui.button, battleImg)
    battleImg:setCascadeOpacityEnabled(true)
    battleBtn:setCascadeOpacityEnabled(true)
    -- 剑图标
    local redSword = img.createUISprite(img.ui.solo_sword_red)
    redSword:setPositionX(battleBtn:getContentSize().width / 2)
    redSword:setPositionY(battleBtn:getContentSize().height / 2)
    battleImg:addChild(redSword)
    local blueSword = img.createUISprite(img.ui.solo_sword_blue)
    blueSword:setPositionX(battleBtn:getContentSize().width / 2)
    blueSword:setPositionY(battleBtn:getContentSize().height / 2)
    battleImg:addChild(blueSword)
    -- 跳过按钮
    local skipImg = img.createUISprite(img.ui.solo_skip)
    skipImg:setPositionX(battleBtn:getContentSize().width / 2)
    skipImg:setPositionY(battleBtn:getContentSize().height / 2)
    skipImg:setVisible(false)
    battleImg:addChild(skipImg)
    -- 灰色按钮
    local grayImg = img.createUISprite(img.ui.solo_battle_btn_gray)
    grayImg:setPositionX(battleBtn:getContentSize().width / 2)
    grayImg:setPositionY(battleBtn:getContentSize().height / 2)
    grayImg:setVisible(false)
    battleImg:addChild(grayImg)

    battleBtn.state = "fight"
    battleBtn.battleImg = battleImg
    battleBtn.redSword = redSword
    battleBtn.blueSword = blueSword
    battleBtn.skipImg = skipImg
    battleBtn.grayImg = grayImg

    return battleBtn
end

-- 改变战斗按钮状态
function ui.setBattleBtnState(btn,state)
    btn.state = state
    if state == "fight" then
        clearShader(btn.battleImg,true)
        btn.redSword:setVisible(true)
        btn.blueSword:setVisible(true)
        btn.skipImg:setVisible(false)
        btn.grayImg:setVisible(false)
    elseif state == "auto" then
        clearShader(btn.battleImg,true)
        btn.redSword:setVisible(true)
        btn.blueSword:setVisible(true)
        btn.skipImg:setVisible(false)
        btn.grayImg:setVisible(false)
    elseif state == "disable" then
        clearShader(btn.battleImg, SHADER_GRAY, true)
        btn.redSword:setVisible(false)
        btn.blueSword:setVisible(false)
        btn.skipImg:setVisible(false)
        btn.grayImg:setVisible(true)
    elseif state == "skip" then
        clearShader(btn.battleImg,true)
        btn.redSword:setVisible(false)
        btn.blueSword:setVisible(false)
        btn.skipImg:setVisible(true)   
        btn.grayImg:setVisible(false)  
    end
end

-- 创建一个英雄图标
function ui.createHeroIcon(heroInfo)
    -- 背景框
    local icon = nil 
    if heroInfo.wake == 4 then
        icon = img.createUISprite(img.ui.hero_star_ten_bg)
        json.load(json.ui.lv10_framefx)
        local aniten = DHSkeletonAnimation:createWithKey(json.ui.lv10_framefx)
        aniten:playAnimation("animation", -1)
        aniten:scheduleUpdateLua()
        aniten:setPosition(icon:getContentSize().width/2, icon:getContentSize().height/2)
        icon:addChild(aniten, 3)
    else
        icon = img.createUISprite(img.ui.herolist_head_bg)
    end
    icon:setCascadeOpacityEnabled(true)
    icon:setScale(0.9)
    -- 人物头像
    local headIcon
	local iconId
    if heroInfo.skin then
		iconId = cfgequip[heroInfo.skin].heroBody
        headIcon = CCSprite:createWithSpriteFrameName(string.format("head/%04d.png", cfgequip[heroInfo.skin].heroBody)) 
    else
		iconId = heroInfo.id
        headIcon = img.createHeroHeadIcon(heroInfo.id)
    end
    --local headIcon = img.createHeroHeadByHid(heroInfo.hid)
    headIcon:setPosition(CCPoint(icon:getContentSize().width / 2, icon:getContentSize().height / 2))
	img.fixOfficialScale(headIcon, "hero", iconId)
    icon:addChild(headIcon)
     --类型背景
    local groupBg = img.createUISprite(img.ui.herolist_group_bg)
    groupBg:setScale(0.42)
    groupBg:setPosition(CCPoint(18, icon:getContentSize().height - 18))
    icon:addChild(groupBg)
    -- 类型图标
    print("进入一次"..heroInfo.id)
    local groupIcon = img.createUISprite(img.ui["herolist_group_" .. heroInfo.group])
    print("阵容为"..heroInfo.group)
    groupIcon:setPosition(groupBg:getPosition())
    groupIcon:setScale(0.42)
    icon:addChild(groupIcon)
    -- 等级标签
    local showLv = lbl.createFont2(15 * 0.92, heroInfo.lv)
    showLv:setPosition(CCPoint(67, icon:getContentSize().height - 18))
    icon:addChild(showLv)
    -- 品阶对应的星星
    local startX = 10
    local offsetX = 10
    local isRed = false
    local totalStarNum = 1
    if heroInfo.qlt <= 5 then
        totalStarNum = heroInfo.qlt
        for i=totalStarNum, 1, -1 do
            local star = img.createUISprite(img.ui.star_s)
            star:setPositionX((i-(totalStarNum+1)/2)*12*0.8 + icon:getContentSize().width / 2)
            star:setPositionY(12)
            icon:addChild(star)
        end
    else
        isRed = true
        if heroInfo.wake then
            totalStarNum = heroInfo.wake + 1
            if totalStarNum >= 6 then
                json.load(json.ui.lv10plus_hero)
                local star = DHSkeletonAnimation:createWithKey(json.ui.lv10plus_hero)
                star:scheduleUpdateLua()
                star:playAnimation("animation", -1)
                star:setPosition(icon:getContentSize().width/2, 14)
                icon:addChild(star)
                local energizeStarLab = lbl.createFont2(26, totalStarNum-5)
                energizeStarLab:setPosition(star:getContentSize().width/2, 0)
                star:addChild(energizeStarLab)
                star:setScale(0.53)
            elseif totalStarNum >= 5 then
                local starIcon2 = img.createUISprite(img.ui.hero_star_ten)
                --starIcon2:setScale(0.92*0.75)
                starIcon2:setPosition(icon:getContentSize().width / 2, 12)
                icon:addChild(starIcon2)
            else
                for i=totalStarNum, 1, -1 do
                    local star = img.createUISprite(img.ui.hero_star_orange)
                    star:setScale(0.75)
                    star:setPositionX((i-(totalStarNum+1)/2)*12*0.8 + icon:getContentSize().width / 2)
                    star:setPositionY(12)
                    icon:addChild(star)
                end
            end
        else
            local star = img.createUISprite(img.ui.hero_star_orange)
            star:setScale(0.75)
            star:setPositionX(icon:getContentSize().width / 2)
            star:setPositionY(12)
            icon:addChild(star)
        end
    end
    -- 血条
    local hpBar = ui.createStateBar("hp","small",heroInfo.hp)
    hpBar:setPosition(icon:getContentSize().width / 2, -4)
    hpBar:setScale(1/0.9)
    icon:addChild(hpBar)
    -- 蓝条
    local mpBar = ui.createStateBar("mp","small",heroInfo.mp)
    mpBar:setPosition(icon:getContentSize().width / 2, hpBar:getPositionY() - 10)
    mpBar:setScale(1/0.9)
    icon:addChild(mpBar) 
    -- 遮罩层
    local maskLayer = CCLayer:create()
    maskLayer:setCascadeOpacityEnabled(true)
    maskLayer:setContentSize(icon:getContentSize())
    maskLayer:setPosition(ccp(0,0))
    maskLayer:setVisible(false)
    icon:addChild(maskLayer)
    -- 头像遮罩
    local headMask = img.createUISprite(img.ui.hero_head_shade)
    headMask:setOpacity(125)
    headMask:setPosition(ccp(maskLayer:getContentSize().width / 2,maskLayer:getContentSize().height / 2))
    maskLayer:addChild(headMask)
    -- 血条遮罩
    local hpMask = img.createUISprite(img.ui.solo_hp_mask)
    hpMask:setOpacity(125)
    hpMask:setScale(1/0.9)
    hpMask:setPosition(ccp(maskLayer:getContentSize().width / 2, -8))
    maskLayer:addChild(hpMask)
    -- 打勾图
    local tickImg = img.createUISprite(img.ui.hook_btn_sel)
    tickImg:setPosition(headIcon:getPosition())
    tickImg:setVisible(false)
    icon:addChild(tickImg)

    icon.state = heroInfo.hp > 0 and "normal" or "disable"
    icon.hpBar = hpBar
    icon.mpBar = mpBar
    icon.maskLayer = maskLayer
    icon.tickImg = tickImg

    if heroInfo.hp <= 0 then
        ui.beGray(icon)
        clearShader(icon.hpBar)
        clearShader(icon.mpBar)
    end
    return icon
end

-- 使某个英雄图标变灰
function ui.beGray(icon)
    setShader(icon, SHADER_GRAY, true)
end

-- 使某个英雄图标变暗
function ui.beDark(icon)
    icon.maskLayer:setVisible(true)
    icon.tickImg:setVisible(true)
end

-- 使某个英雄图标变正常
function ui.beNormal(icon)
    clearShader(icon,true)
    icon.maskLayer:setVisible(false)
    icon.tickImg:setVisible(false)
end

-- 播放buff条变化动画
function ui.playBuffBarAnimation(buffBar, ratio, time)
    ratio = ratio > 1 and 1 or ratio
    time = time or 0.5
    local percent = buffBar:getPercentage()
    local actionTimes = time / 0.01
    local deltaPercent = (ratio * 100 - percent) / actionTimes
    local delay = CCDelayTime:create(0.01)
    local callfunc = CCCallFunc:create(function ()
        percent = percent + deltaPercent
        buffBar:setPercentage(percent)
    end)
    local sequence = CCSequence:createWithTwoActions(callfunc,delay)
    buffBar:stopAllActions()
    buffBar:runAction(CCRepeat:create(sequence,actionTimes))
end

-- 播放buff条标签变化动画
function ui.playBuffLabelAnimation(buffLabel, maxNum, oldNum, newNum, time)
    if newNum > maxNum or oldNum == newNum then
        return
    end
    time = time or 0.5
    local oldData = oldNum
    local delta = newNum - oldNum > 0 and newNum - oldNum or 1
    local deltaTime = time / delta
    local delay = CCDelayTime:create(deltaTime)
    local callfunc = CCCallFunc:create(function ()
        oldData = oldData + 1
        buffLabel:setString(oldData .."/" ..maxNum)
        print("标签字符:"..oldData.."/"..maxNum)
    end)
    local arr = CCArray:create()
    arr:addObject(callfunc)
    arr:addObject(delay)
    local sequence = CCSequence:create(arr)
    buffLabel:stopAllActions()
    buffLabel:runAction(CCRepeat:create(sequence, delta))
    print("循环次数为："..delta)
end

-- 选择某个英雄
function ui.selectHero(order)
    if soloData.heroList[order].hp <= 0 then
        if ui.isAllDie then

        else
            return
        end
    end
    if ui.isAllDie then
        soloData.setSelectOrder(order)
        for i,v in ipairs(ui.widget.heroIcons) do
            v.maskLayer:setVisible(false)
            v.tickImg:setVisible(false)
        end
        ui.widget.heroIcons[order].tickImg:setVisible(true)
        ui.changeBuffBarState(ui.widget.speedBuffBar,soloData.heroList[soloData.getSelectOrder()])
        ui.changeBuffBarState(ui.widget.powerBuffBar,soloData.heroList[soloData.getSelectOrder()])
        ui.changeBuffBarState(ui.widget.critBuffBar,soloData.heroList[soloData.getSelectOrder()])
    else
        if soloData.heroList[order].hp <= 0 then
            return
        end
        soloData.setSelectOrder(order)
        for i,v in ipairs(ui.widget.heroIcons) do
            v.maskLayer:setVisible(false)
            v.tickImg:setVisible(false)
        end
        ui.widget.heroIcons[order].maskLayer:setVisible(true)
        ui.widget.heroIcons[order].tickImg:setVisible(true)
        ui.changeBuffBarState(ui.widget.speedBuffBar,soloData.heroList[soloData.getSelectOrder()])
        ui.changeBuffBarState(ui.widget.powerBuffBar,soloData.heroList[soloData.getSelectOrder()])
        ui.changeBuffBarState(ui.widget.critBuffBar,soloData.heroList[soloData.getSelectOrder()])
        ui.showHeroSpine(order)
    end
end

-- 触摸事件
function ui.onTouch(eventType, x, y)
    if eventType == "began" then
        return ui.onTouchBegan(x, y)
    elseif eventType == "moved" then
    else
        return ui.onTouchEnded(x, y)
    end
end

-- 开始触摸
function ui.onTouchBegan(x, y)
    --ui.data.lastSelected = 0
    print("点击坐标"..x..","..y)
    for i,v in ipairs(ui.widget.heroIcons) do
        local point = v:getParent():convertToNodeSpace(ccp(x, y))
        local rect = v:boundingBox()

        if (ui.isAllDie or v.state ~= "disable") and rect:containsPoint(point) then
            print("我点中了第"..i.."个")
            ui.data.lastSelected = i
            return true
        end
    end
    return false
end

-- 结束触摸
function ui.onTouchEnded(x, y)
    if ui.data.lastSelected == 0 then
        return
    end

    local icon = ui.widget.heroIcons[ui.data.lastSelected]
    local point = icon:getParent():convertToNodeSpace(ccp(x,y))
    local rect = icon:boundingBox()

    if rect:containsPoint(point) then
        print("我取消了第"..ui.data.lastSelected.."个")
        if soloData.getSelectOrder() ~= ui.data.lastSelected then
            ui.selectHero(ui.data.lastSelected) 
        end
    end
end

-- 显示出战的英雄动画
function ui.showHeroSpine(order)
    ui.widget.spineNode:removeChildFollowSlot("code_hero")
    local heroInfo = soloData.heroList[order]
    -- 英雄骨骼动画
    if heroInfo.skin then
        ui.widget.heroSpine = json.createSpineHeroSkin(heroInfo.skin)
    else
        ui.widget.heroSpine = json.createSpineHero(heroInfo.id)
    end
    ui.widget.heroSpine:setScale(0.65)
    ui.widget.spineNode:addChildFollowSlot("code_hero",ui.widget.heroSpine)
    -- 英雄名称
    ui.widget.heroNameLabel:setString(i18n.hero[heroInfo.id].heroName)
    ui.widget.heroNameLabel:setVisible(true)
    -- 英雄阵营
    print("这个种族的阵营是"..heroInfo.group)
    local oldImg = ui.widget.heroGroupImg
    ui.widget.heroGroupImg = img.createGroupIcon(heroInfo.group)
    ui.widget.heroGroupImg:setPosition(oldImg:getPosition())
    ui.widget.heroGroupImg:setScale(oldImg:getScale())
    ui.widget.heroGroupImg:setVisible(true)
    ui.widget.spineNode:removeChildFollowSlot("code_circle")
    ui.widget.spineNode:addChildFollowSlot("code_circle",ui.widget.heroGroupImg)
    -- 英雄血条
    ui.setStateBar(ui.widget.heroHpBar,heroInfo.hp / 100)
    ui.widget.heroHpBar:setVisible(true)
    -- 英雄能量条
    ui.setStateBar(ui.widget.heroMpBar,heroInfo.mp / 100)
    ui.widget.heroMpBar:setVisible(true)
end

-- 显示出战的boss动画
function ui.showBossSpine(id)
    ui.widget.spineNode:removeChildFollowSlot("code_boss")
    ui.widget.bossSpine = json.createSpineMons(id)
    ui.widget.bossSpine:setScale(0.65)
    ui.widget.spineNode:addChildFollowSlot("code_boss",ui.widget.bossSpine)
    ui.widget.spineNode:playAnimation("boss_birth")
    ui.createSwallowLayer(30 / 30)
end

-- 显示商人的动画
function ui.showTraderSpine(id)
    ui.widget.spineNode:removeChildFollowSlot("code_trader")
    ui.widget.traderSpine = json.create(json.ui["trader"..id])
    ui.widget.spineNode:addChildFollowSlot("code_trader",ui.widget.traderSpine)
    ui.widget.spineNode:playAnimation("trader_birth")
    ui.widget.spineNode:registerLuaHandler(function (event)
        if event == "trader_birth" then
            print("商人进入结束")
            ui.widget.traderSpine:playAnimation("stand", -1)
        end
    end)
    ui.createSwallowLayer(25 / 30)
end

-- 显示药水的动画
function ui.showPotionSpine(id)
    print("---------进入函数 showPotionSpine")
    ui.widget.spineNode:removeChildFollowSlot("code_drug")
    local drugStr = {power = "solo_power_potion", speed = "solo_speed_potion", crit = "solo_crit_potion",
                     milk  = "solo_milk",         angel = "solo_angel_potion", evil = "solo_evil_potion"} 
    ui.widget.drugImg = img.createUISprite(img.ui[drugStr[id]])
    ui.widget.drugImg.id = id
    ui.widget.spineNode:addChildFollowSlot("code_drug",ui.widget.drugImg)
    ui.widget.spineNode:playAnimation("drug_birth")
    ui.widget.spineNode:registerLuaHandler(function (event)
        if event == "drug_birth" then
            if id == "power" or id == "speed" or id == "crit" then
                --ui.widget.spineNode:playAnimation("drug_loop", -1)
                local delay = CCDelayTime:create(0.1)
                local callfunc = CCCallFunc:create(function ()
                    ui.usePotion()
                end)
                ui.widget.spineNode:runAction(CCSequence:createWithTwoActions(delay,callfunc))
                --soloData.setBuf(nil)
            else
                local delay = CCDelayTime:create(0.1)
                local callfunc = CCCallFunc:create(function ()
                    ui.savePotion()
                end)
                ui.widget.spineNode:runAction(CCSequence:createWithTwoActions(delay,callfunc))
            end
        end
    end)
    ui.createSwallowLayer(45 / 30)
end

-- 显示宝箱动画
function ui.showRewardSpine()
    print("调用一次奖励骨骼")
    ui.widget.spineNode:removeChildFollowSlot("code_treasure")
    -- ui.widget.rewardImg = img.createUISprite(img.ui.solo_chest)
    -- ui.widget.spineNode:addChildFollowSlot("code_treasure",ui.widget.rewardImg)
    ui.widget.spineNode:registerAnimation("treasure_birth")
    ui.widget.spineNode:registerLuaHandler(function (event)
        -- if event == "treasure_birth" then
        --     ui.widget.spineNode:registerAnimation("treasure_click")
        --     ui.widget.spineNode:setPlayBackwardsEnabled(false)
        -- elseif event == "treasure_click" then
        --     ui.showRewardUI()
        -- end
        if event == "treasure_birth" then
            ui.showRewardUI()
        end
    end)

    -- local arr = CCArray:create()
    -- arr:addObject(CCDelayTime:create(0.5))
    -- arr:addObject(CCCallFunc:create(function()
    --     print("进来了一次")
    --     ui.showRewardUI()
    -- end))
    -- ui.widget.layer:runAction(CCSequence:create(arr))

    ui.createSwallowLayer(60 / 30)
end

-- 结束出战boss的动画
function ui.endBossSpine(data)
    if ui.widget.bossSpine ~= nil then
        ui.widget.spineNode:playAnimation("boss_die")
        ui.widget.spineNode:registerLuaHandler(function (event)
            if event == "boss_die" then
                ui.refreshUI(data)
            end
        end)
        ui.createSwallowLayer(20 / 30)
    end
end

-- 结束商人的动画
function ui.endTraderSpine()
    if ui.widget.traderSpine ~= nil then
        ui.widget.traderSpine:playAnimation("jump")
        ui.widget.spineNode:registerAnimation("trader_die")
        ui.widget.spineNode:registerLuaHandler(function (event)
            if event == "trader_die" then
                ui.refreshBoss()
            end
        end)
        ui.createSwallowLayer(40 / 30)
    end
end

-- 结束药水的动画
function ui.endPotionSpine()
    print("------进入函数 endPotionSpine")
    print(soloData.getBufType())
    if soloData.getBuf() then
        local drugStr = {speed = "1speed_click" , power = "2power_click", crit = "3cc_click",
                         milk = "4milk_click2", evil = "5demon_click2", angel = "6angel_click2"}
        local drugSpine = {speed = ui.widget.speedBuffBar.drugSpine, power = ui.widget.powerBuffBar.drugSpine, crit = ui.widget.critBuffBar.drugSpine,}                 
        --ui.widget.spineNode:unregisterAnimation("drug_loop")
        if soloData.getBufType() == "milk" or soloData.getBufType() == "evil" or soloData.getBufType() == "angel" then
            ui.widget.spineNode:registerAnimation(drugStr[soloData.getBufType()])
        else
            --ui.widget.spineNode:stopAnimation()
            ui.widget.spineNode:playAnimation(drugStr[soloData.getBufType()])
            drugSpine[soloData.getBufType()]:playAnimation(drugStr[soloData.getBufType()])
            ui.widget.spineNode:registerLuaHandler(function (event)
                if event == drugStr[soloData.getBufType()] then
                    print("结束药水动画")
                    ui.refreshBoss()
                end
            end)
        end
        --ui.widget.spineNode:playAnimation("drug_loop",-1)
        ui.createSwallowLayer(50 / 30)
    end
end

-- 保存药水的动画
function ui.savePotionSpine()
    print("---------进入函数 savePotionSpine")
    print(soloData.getBufType())
    if soloData.getBuf() then
        local drugStr = {milk = "4milk_click", evil = "5demon_click", angel = "6angel_click"}
        --ui.widget.spineNode:unregisterAnimation("drug_loop")
        ui.widget.spineNode:stopAnimation()
        ui.widget.spineNode:playAnimation(drugStr[soloData.getBufType()])
        ui.widget.sideSpine:registerAnimation(drugStr[soloData.getBufType()]) 
        ui.widget.spineNode:registerLuaHandler(function (event)
            if event == drugStr[soloData.getBufType()] then
                print("保存药水动画")
                ui.refreshBoss()
            end
        end)
        ui.createSwallowLayer(50 / 30)
    end

    -- addWaitNet()
    -- local params = {sid = player.sid,buf = soloData.getBuf(),save = 1}
    -- if soloData.getBuf() then
    --     tablePrint(params)
    --     net:spk_buf(params,function (data)
    --         delWaitNet()
    --         print("药水返回数据")
    --         tablePrint(data)
    --         if data.status == 0 then
    --             ui.setStage(data.nstage)
    --             local drugStr = {milk = "4milk_click", evil = "5demon_click", angel = "6angel_click"}
    --             ui.widget.spineNode:unregisterAnimation("drug_loop")
    --             ui.widget.spineNode:playAnimation(drugStr[soloData.getBufType()])
    --             ui.widget.spineNode:registerLuaHandler(function (event)
    --                 if event == drugStr[soloData.getBufType()] then
    --                     print("保存药水动画")
    --                     ui.refreshBoss()
    --                 end
    --             end)
    --             ui.createSwallowLayer(50 / 30)
    --         end
    --     end)
    -- end
end

-- 创建一个防触摸层
function ui.createSwallowLayer(time,zorder)
    time = time or 0.5
    zorder = zorder or 999
    local swallowLayer = CCLayer:create()
    swallowLayer:setTouchEnabled(true)
    ui.widget.layer:addChild(swallowLayer, zorder)
    --延迟时间
    local delayTime = CCDelayTime:create(time)
    local callfunc = CCCallFunc:create(function ()
        if swallowLayer ~= nil then
            swallowLayer:removeFromParent()
            swallowLayer = nil
        end
    end)
    local arr = CCArray:create()
    arr:addObject(delayTime)
    arr:addObject(callfunc)
    swallowLayer:runAction(CCSequence:create(arr))
end

-- 使用药水
function ui.usePotion()
    print("------进入函数 usePotion")
    local potionStr = { milk = {hp = 25,mp = 0}, angel = {hp = 100, mp = 0}, evil = {hp = 50, mp = 100} }
    local bufStr = { speed = ui.widget.speedBuffBar, power = ui.widget.powerBuffBar ,crit = ui.widget.critBuffBar }
    if potionStr[soloData.getBufType()] then
        local addHp,addMp = 0,0
        for i,v in ipairs(cfgDrug[soloData.getBuf()].effect) do
            if v.type == "healP" then
                addHp = v.num * 100
            elseif v.type == "energy" then
                addMp = v.num * 100
            end
        end 
        local hp,mp = soloData.heroList[soloData.getSelectOrder()].hp, soloData.heroList[soloData.getSelectOrder()].mp
        soloData.heroList[soloData.getSelectOrder()].hp = hp + addHp > 100 and 100 or hp + addHp
        soloData.heroList[soloData.getSelectOrder()].mp = mp + addMp > 100 and 100 or mp + addMp
        -- 延迟变化血条/能量条
        local delay = CCDelayTime:create(0.4)
        local callfunc = CCCallFunc:create(function ()
            ui.changeStateBar(ui.widget.heroHpBar, soloData.heroList[soloData.getSelectOrder()].hp / 100)
            ui.changeStateBar(ui.widget.heroMpBar, soloData.heroList[soloData.getSelectOrder()].mp / 100)
            ui.changeStateBar(ui.widget.heroIcons[soloData.getSelectOrder()].hpBar, soloData.heroList[soloData.getSelectOrder()].hp / 100)
            ui.changeStateBar(ui.widget.heroIcons[soloData.getSelectOrder()].mpBar, soloData.heroList[soloData.getSelectOrder()].mp / 100)
        end)
        ui.widget.layer:runAction(CCSequence:createWithTwoActions(delay,callfunc))
    elseif bufStr[soloData.getBufType()] then
        local oldBufData = soloData.heroList[soloData.getSelectOrder()][soloData.getBufType()]
        local newBufData = oldBufData + 1 > 20 and 20 or oldBufData + 1 
        --print("老数据"..oldBufData..",新数据"..newBufData.."选中英雄"..ui.data.selectOrder)
        --soloData.heroList[soloData.getSelectOrder()][soloData.getBufType()] = newBufData
        soloData.addPotion(soloData.getBuf())
        -- 延迟变化buff条
        local delay = CCDelayTime:create(0.4)
        local callfunc = CCCallFunc:create(function ()
            ui.playBuffBarAnimation(bufStr[soloData.getBufType()].progressBar, newBufData / 20)
            ui.playBuffLabelAnimation(bufStr[soloData.getBufType()].progressLabel, 20, oldBufData, newBufData)
        end)
        ui.widget.layer:runAction(CCSequence:createWithTwoActions(delay,callfunc))
        -- ui.playBuffBarAnimation(bufStr[ui.data.buf].progressBar, newBufData / 20)
        -- ui.playBuffLabelAnimation(bufStr[ui.data.buf].progressLabel, 20, oldBufData, newBufData)
    end
    ui.endPotionSpine()
end

-- 保存药剂
function ui.savePotion()
    print("------进入函数 savePotion")

    local potionStr = { milk = {hp = 20,mp = 0}, angel = {hp = 100, mp = 0}, evil = {hp = 50, mp = 300} }
    local label = {milk = ui.widget.milkLabel,angel = ui.widget.angelLabel,evil = ui.widget.evilLabel}
    if soloData.getBufType() == "milk" or soloData.getBufType() == "angel" or soloData.getBufType() == "evil" then
        -- addWaitNet()
        -- local params = {sid = player.sid,buf = soloData.getBuf(),save = 1}
        -- if soloData.getBuf() then
        --     tablePrint(params)
        --     net:spk_buf(params,function (data)
        --         delWaitNet()
        --         print("药水返回数据")
        --         tablePrint(data)
        --         if data.status == 0 then
        --             ui.setStage(data.nstage)
        --             table.insert(soloData[soloData.getBufType()],soloData.getBuf())
        --             label[soloData.getBufType()]:setString(#soloData[soloData.getBufType()])
        --             ui.savePotionSpine()
        --         end
        --     end)
        -- end
        --ui.setStage(data.nstage)
        table.insert(soloData[soloData.getBufType()],soloData.getBuf())
        label[soloData.getBufType()]:setString(#soloData[soloData.getBufType()])
        ui.savePotionSpine()

        -- table.insert(soloData[soloData.getBufType()],soloData.getBuf())
        -- label[soloData.getBufType()]:setString(#soloData[soloData.getBufType()])
        -- ui.savePotionSpine()
    end
end

-- 显示boss列表图
function ui.showBossList()
    local listView = require("ui.solo.monsListUI").create(soloData.bossList)
    ui.widget.layer:addChild(listView,99999)
end

-- 显示购买弹窗
function ui.showBuyUI()
    if ui == nil then
        print("ui值是空的")
    end
    -- 显示购买窗口
    local itemType = cfgTrader[soloData.getTrader()].yes[1].type
    local itemID   = cfgTrader[soloData.getTrader()].yes[1].id
    local itemNum  = cfgTrader[soloData.getTrader()].yes[1].num
    local cost     = cfgTrader[soloData.getTrader()].cost
    local gold     = cfgTrader[soloData.getTrader()].gold
    local params = {goodsType = itemType,id = itemID, num = itemNum ,gem = cost}
    local shopUI = require("ui.solo.shopUI").create({goodsType = itemType,id = itemID, num = itemNum ,gem = cost,coin = gold},ui) 
    ui.widget.layer:addChild(shopUI,99999)
end

-- 显示药水使用弹窗
function ui.showDrugUI()
    local hid = soloData.heroList[soloData.getSelectOrder()].hid
    local drugUI = require("ui.solo.useDrugUI").create(soloData.getBufType(),soloData.getBuf(),ui,hid)
    ui.widget.layer:addChild(drugUI,99999)
end

-- 显示奖励弹窗
function ui.showRewardUI()
    local reward = soloData.getReward()
    local rewardID,rewardNum,rewardType
    if reward.items then
        print("HAVE ITEM")
        rewardType = 1 -- 道具
        rewardID = reward.items[1].id
        rewardNum = reward.items[1].num
    else
        rewardType = 2  -- 装备
        rewardID = reward.equips[1].id
        rewardNum = reward.equips[1].num
    end
    print("奖励为：")
    tablePrint(reward)
	
	-- old method
    --local rewardUI = require("ui.solo.rewardUI").create({id = rewardID,num = rewardNum,goodsType = rewardType},ui)
    --ui.widget.layer:addChild(rewardUI,99999)
	
	-- new method
	require("ui.custom").showFloatRewardSingle(rewardType, rewardID, rewardNum)
	
	local delay = CCDelayTime:create(0.4)
	local callfunc = CCCallFunc:create(function ()
		ui.refreshBoss()
	end)
	local sequence = CCSequence:createWithTwoActions(delay,callfunc)
	ui.widget.layer:runAction(sequence)
	
	--ui.refreshBoss()
end

-- 刷新战斗后的数据
function ui.refreshFightData(data)
    print("刷新战斗后的数据")
    tablePrint(data)
    if data.win then
        print("胜利")
        if data.mhpp then
            soloData.heroList[soloData.getSelectOrder()].hp = data.mhpp
        end
        if data.menergy then
            soloData.heroList[soloData.getSelectOrder()].mp = data.menergy
        end
        if data.reward then
            print("有奖励")
            soloData.setReward(data.reward)
            soloData.setStage(data.nstage)
            print("新的波次"..soloData.getStage())
            soloData.setTrader(nil)
            soloData.setBuf(nil)
        elseif data.buf then
            print("有药水"..data.buf)
            soloData.setStage(data.nstage)
            soloData.setBuf(data.buf)
            soloData.setReward(nil)
            soloData.setTrader(nil)
        elseif data.seller then
            print("有商人"..data.seller)
            -- 手动战斗后特殊处理商人情况下的波次显示
            soloData.setWave(soloData.getWave() + 1)
            soloData.setTrader(data.seller)
            soloData.setReward(nil)
            soloData.setBuf(nil)
        end
    else
        if data.menergy then
            soloData.heroList[soloData.getSelectOrder()].mp = data.menergy
        else
            soloData.heroList[soloData.getSelectOrder()].mp = 0
        end
        if data.mhpp then
            soloData.heroList[soloData.getSelectOrder()].hp = data.mhpp
        else
            soloData.heroList[soloData.getSelectOrder()].hp = 0
            soloData.setSelectOrder(nil)
        end
        --soloData.setSelectOrder(nil)
        if data.ehpp == nil then
            data.ehpp = {}
            for i,v in ipairs(soloData.bossList) do
                table.insert(data.ehpp,0)
            end
        end
        for i,v in ipairs(data.ehpp) do
            if i > 4 then
                return
            end
            print("bossHP"..v)
            soloData.bossList[i].hp = v
        end
    end
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
        ui.widget.countDownLabel:setString(ui.getTimeString(time))
        if time == 0 then
            soloData.setStatus(0)
            replaceScene(require("ui.town.main").create())
        end
     end 
end

-- 全部阵亡的设置
function ui.heroAllDie()
    ui.isAllDie = true
    --创建一个遮罩层吞噬按钮触摸
    local maskLayer = CCLayer:create()
    maskLayer:setTouchEnabled(true)
    ui.widget.layer:addChild(maskLayer,50)
    --置灰部分按钮
    ui.setBattleBtnState(ui.widget.battleBtn,"fight")
    if ui.widget.autoBtn.state == "auto" then
        ui.changeAutoBtnState(ui.widget.autoBtn)
    end
    for i,v in ipairs(ui.widget.heroIcons) do
        ui.beGray(v)
        ui.setStateBar(v.hpBar,0)
        ui.setStateBar(v.mpBar,0)
        clearShader(v.hpBar,true)
        clearShader(v.mpBar,true)
    end
    ui.beGray(ui.widget.battleBtn)
    ui.beGray(ui.widget.autoBtn)
    --移除部分节点
    ui.widget.spineNode:removeChildFollowSlot("code_hero")
    ui.widget.spineNode:removeChildFollowSlot("code_boss")
    ui.widget.spineNode:removeChildFollowSlot("code_trader")
    ui.widget.spineNode:removeChildFollowSlot("code_drug")
    ui.widget.spineNode:unregisterAllAnimation()
    ui.widget.spineNode:playAnimation("start")
    ui.widget.sideSpine:playAnimation("start")
    ui.widget.upSpine:playAnimation("start")
    ui.widget.downSpine:playAnimation("start")
    ui.widget.heroNameLabel:setVisible(false)
    ui.widget.heroGroupImg:setVisible(false)
    ui.widget.heroHpBar:setVisible(false)
    ui.widget.heroMpBar:setVisible(false)

    ui.widget.touchLayer:setLocalZOrder(60)

    soloData.setSelectOrder(nil)
end

-- 通关
function ui.clearStage()
    local maxWave = ui.data.maxClearNum 
    -- if soloData.getWave() == nil or (soloData.getWave() - 1) % 100 + 1 <= maxWave then
    --     return false
    -- end
    -- if (soloData.getWave() == nil or math.floor((soloData.getWave() - 1) / maxWave) <= soloData.level) and (soloData.status ~= 2 or soloData.trader) then
    --     return false
    -- end
    if (soloData.getWave() == nil or soloData.getWave() <= ui.data.overNum) and (soloData.status ~= 2 or soloData.trader) then
        return false
    end
    --创建一个遮罩层吞噬按钮触摸
    local maskLayer = CCLayer:create()
    maskLayer:setTouchEnabled(true)
    ui.widget.layer:addChild(maskLayer,50)
    --
    -- if ui.widget.drugImg then
    --     ui.widget.drugImg:setVisible(false)
    -- end
    ui.widget.spineNode:removeChildFollowSlot("code_boss")
    ui.widget.spineNode:removeChildFollowSlot("code_trader")
    ui.widget.spineNode:removeChildFollowSlot("code_drug")
    ui.widget.spineNode:removeChildFollowSlot("code_treasure")
    ui.widget.battleBtn:setVisible(false)
    -- 通关图
    ui.widget.victoryImg = img.createUISprite(img.ui.solo_victory)
    ui.widget.spineNode:addChild(ui.widget.victoryImg)
    ui.widget.victoryImg:setPositionY(70)
    -- 通关波次
    --ui.widget.waveLabel:setString(i18n.global["solo_stage" .. soloData.level].string .. " " .. string.format(i18n.global.solo_wave.string, maxWave))
    ui.widget.waveLabel:setString(i18n.global["solo_stage" .. math.floor((ui.data.overNum - 1) / 100)].string .. ":" .. maxWave)
    -- 通关标签
    ui.widget.victoryLabel = lbl.createFont2(16, i18n.global.solo_victory.string, lbl.whiteColor)
    ui.widget.victoryLabel:setPositionY(15)
    ui.widget.spineNode:addChild(ui.widget.victoryLabel)
    return true 
end

-- 存储宝箱内容
function ui.storageReward(reward)
    if reward == nil then
        return
    end
    local pb = {}
    if reward.items then
        pb.id = reward.items[1].id
        pb.num = reward.items[1].num 
        bag.items.add(pb)
    elseif reward.equips then
        pb.id = reward.equips[1].id 
        pb.num = reward.equips[1].num  
        bag.equips.add(pb)
    end
end

-- 添加历史药剂使用提示
function ui.addDrugTipUI(drugType)
    if #soloData[drugType] > 0 then
        --[[print("使用保存的药剂")
        local drugText = {milk = i18n.global.solo_useMilk.string,angel = i18n.global.solo_useAngel.string,evil = i18n.global.solo_useEvil.string}
        local drugLabel = {milk = ui.widget.milkLabel,angel = ui.widget.angelLabel,evil = ui.widget.evilLabel}
        local dialog = require "ui.dialog" 
        local tag = 1000
        local body_text = drugText[drugType]
        local function process_dialog(data)
            if data.selected_btn == 1 then
                ---
            elseif data.selected_btn == 2 then
                local label = {milk = ui.widget.milkLabel,angel = ui.widget.angelLabel,evil = ui.widget.evilLabel}
                local heroHid = soloData.heroList[soloData.getSelectOrder()].hid
                local drugId = soloData[drugType][1]
                local params = {sid = player.sid,buf = drugId,hid = heroHid}
                print("使用的历史药水")
                tablePrint(params)
                net:spk_buf(params,function (data)
                    delWaitNet()
                    print("药水返回数据")
                    tablePrint(data)
                    if data.status == 0 then
                        local drug = soloData.getBuf()
                        soloData.setBuf(drugId)
                        ui.usePotion()
                        soloData.setBuf(nil)
                        if drug ~= nil then
                            soloData.setBuf(drug)
                        end
                        table.remove(soloData[drugType],1)
                        drugLabel[drugType]:setString(#soloData[drugType])
                    end
                end)
            end
            ui.widget.layer:removeChildByTag(tag)
        end
        local params = {
            title = "",
            body = body_text,
            btn_count = 2,
            btn_color = {
                [1] = dialog.COLOR_GOLD,
                [2] = dialog.COLOR_GOLD,
            },
            btn_text = {
                [1] = i18n.global.board_confirm_no.string,
                [2] = i18n.global.board_confirm_yes.string,
            },
            callback = process_dialog,
        }

        local tipDialog = dialog.create(params, true)
        tipDialog:setAnchorPoint(CCPoint(0,0))
        tipDialog:setPosition(CCPoint(0,0))
        ui.widget.layer:addChild(tipDialog, 999,tag)--]]
		
		local label = {milk = ui.widget.milkLabel,angel = ui.widget.angelLabel,evil = ui.widget.evilLabel}
		local heroHid = soloData.heroList[soloData.getSelectOrder()].hid
		local drugId = soloData[drugType][1]
		local params = {sid = player.sid,buf = drugId,hid = heroHid}
		local drugLabel = {milk = ui.widget.milkLabel,angel = ui.widget.angelLabel,evil = ui.widget.evilLabel}
		net:spk_buf(params, function (data)
			delWaitNet()
			if data.status == 0 then
				local drug = soloData.getBuf()
				soloData.setBuf(drugId)
				ui.usePotion()
				soloData.setBuf(nil)
				if drug ~= nil then
					soloData.setBuf(drug)
				end
				table.remove(soloData[drugType],1)
				drugLabel[drugType]:setString(#soloData[drugType])
			end
		end)
    end 
end

-- 修改扫荡动作前的初始化显示
function ui.modifyBufShow()
    local property = {}
    property.power = 0
    property.speed = 0
    property.crit = 0
    ui.widget.milkLabel:setString(0)
    ui.widget.angelLabel:setString(0)
    ui.widget.evilLabel:setString(0)
    ui.changeBuffBarState(ui.widget.speedBuffBar,property)
    ui.changeBuffBarState(ui.widget.powerBuffBar,property)
    ui.changeBuffBarState(ui.widget.critBuffBar,property)
end

-- 播放扫荡后添加药剂的动画
function ui.playSweepAnimation()
    -- soloData.power = 10
    -- soloData.crit = 10
    -- soloData.speed = 10
    -- soloData.milk = {1,1,1}
    -- soloData.evil = {1,1,1}
    -- soloData.angel = {1,1,1}

    ui.widget.milkLabel:setString(#soloData.milk)
    ui.widget.angelLabel:setString(#soloData.angel)
    ui.widget.evilLabel:setString(#soloData.evil)
    -- 延迟变化属性buff条
    bufStr = { speed = ui.widget.speedBuffBar, power = ui.widget.powerBuffBar ,crit = ui.widget.critBuffBar }
    local delay = CCDelayTime:create(0.4)
    local callfunc = CCCallFunc:create(function ()
        print("-------speed"..soloData.speed)
        print("-------power"..soloData.power)
        print("-------crit"..soloData.crit)
        ui.playBuffBarAnimation(bufStr["speed"].progressBar, soloData.speed / 20)
        ui.playBuffLabelAnimation(bufStr["speed"].progressLabel, 20, 0, soloData.speed)
        ui.playBuffBarAnimation(bufStr["power"].progressBar, soloData.power / 20)
        ui.playBuffLabelAnimation(bufStr["power"].progressLabel, 20, 0, soloData.power)
        ui.playBuffBarAnimation(bufStr["crit"].progressBar, soloData.crit / 20)
        ui.playBuffLabelAnimation(bufStr["crit"].progressLabel, 20, 0, soloData.crit)
    end)
    ui.widget.layer:runAction(CCSequence:createWithTwoActions(delay,callfunc))

    -- local drugStr = {speed = "1speed_click" , power = "2power_click", crit = "3cc_click",milk = "4milk_click", evil = "5demon_click", angel = "6angel_click"}
    -- for _,v in pairs(drugStr) do
    --     ui.widget.spineNode:registerAnimation(v)
    -- end

    -- 添加预备光效
    local angelLight = json.create(json.ui.solo_lightA)
    local evilLight = json.create(json.ui.solo_lightA)
    local milkLight = json.create(json.ui.solo_lightA)
    local speedLight = json.create(json.ui.solo_lightB)
    local powerLight = json.create(json.ui.solo_lightB)
    local critLight = json.create(json.ui.solo_lightB)
    angelLight:setPosition(ccp(-438, 107))
    evilLight:setPosition(ccp(-438, 35))
    milkLight:setPosition(ccp(-438, -37))
    speedLight:setPosition(ccp(-450, -180))
    powerLight:setPosition(ccp(-450, -220))
    critLight:setPosition(ccp(-450, -260))
    ui.widget.spineNode:addChild(angelLight,99999999)
    ui.widget.spineNode:addChild(evilLight,99999999)
    ui.widget.spineNode:addChild(milkLight,99999999)
    ui.widget.spineNode:addChild(speedLight,99999999)
    ui.widget.spineNode:addChild(powerLight,99999999)
    ui.widget.spineNode:addChild(critLight,99999999)

    if soloData.angel and #soloData.angel > 0 then
        angelLight:playAnimation("animation")
    end
    if soloData.evil and #soloData.evil > 0 then
        evilLight:playAnimation("animation")
    end
    if soloData.milk and #soloData.milk > 0 then
        milkLight:playAnimation("animation")
    end
    if soloData.speed and soloData.speed > 0 then
        speedLight:playAnimation("animation")
    end
    if soloData.power and soloData.power > 0 then
        powerLight:playAnimation("animation")
    end
    if soloData.crit and soloData.crit > 0 then
        critLight:playAnimation("animation")
    end

    ui.createSwallowLayer(50 / 30)
end

-- 设置出战队列
function ui.setStage(stage)
    soloData.setStage(stage)
end

return ui
