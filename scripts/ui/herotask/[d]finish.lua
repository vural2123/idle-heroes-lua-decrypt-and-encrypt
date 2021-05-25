local ui = {}

require "common.func"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local i18n = require "res.i18n"
local audio = require "res.audio"
local net = require "net.netClient"
local cfghero = require "config.hero"
local cfgtask = require "config.herotask"
local cfgequip = require "config.equip"
local heros = require "data.heros"
local bag = require "data.bag"
local player = require "data.player"
local htaskData = require "data.herotask"
local achieveData = require "data.achieve"

function ui.create(info)
    local layer = CCLayer:create()
   
    --dark bg
    local darkbg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    darkbg:setScale(2)
    layer:addChild(darkbg)

    local showReward = {}
    local showHero = {}
    
    local showPowerBg = CCSprite:create()
    showPowerBg:setContentSize(CCSize(960, 576))
    showPowerBg:setPosition(480, 576/2)
    layer:addChild(showPowerBg)

    ---- anim
    showPowerBg:setScale(0.5)
    showPowerBg:runAction(CCScaleTo:create(0.15, 1, 1))

    local lbg = img.createUISprite(img.ui.herotask_dialog)
    lbg:setAnchorPoint(1, 0.5)
    lbg:setPosition(480, 576/2)
    showPowerBg:addChild(lbg)
   
    local rbg = img.createUISprite(img.ui.herotask_dialog)
    rbg:setFlipX(true)
    rbg:setAnchorPoint(0, 0.5)
    rbg:setPosition(479, 576/2)
    showPowerBg:addChild(rbg)
    --local powerIconBg = img.createUISprite(img.ui.select_hero_power_bg)
    --powerIconBg:setAnchorPoint(ccp(0, 0.5))
    --powerIconBg:setPosition(0, 19)
    --showPowerBg:addChild(powerIconBg)
  
    local board = img.createUI9Sprite(img.ui.select_hero_camp_bg)
    board:setPreferredSize(CCSize(656, 268))
    board:setAnchorPoint(ccp(0, 0))
    board:setPosition(152, 228)
    showPowerBg:addChild(board)

    local powerBg = img.createUI9Sprite(img.ui.select_tab_tab_bg)
    powerBg:setPreferredSize(CCSize(646, 38))
    powerBg:setAnchorPoint(ccp(0, 0))
    powerBg:setPosition(158, 455)
    showPowerBg:addChild(powerBg)

    --local powerIcon = img.createUISprite(img.ui.power_icon)
    --powerIcon:setScale(0.48)
    --powerIcon:setPosition(27, 19)
    --powerBg:addChild(powerIcon)
    
    --local showPower = lbl.createFont2(16, info.power)
    --showPower:setAnchorPoint(ccp(1, 0.5)) 
    --showPower:setPosition(112, 19)
    --powerBg:addChild(showPower, 1)

    --local powerNeed = lbl.createFont2(16, "/" .. cfgtask[info.id].power)
    --powerNeed:setAnchorPoint(ccp(0, 0.5))
    --powerNeed:setPosition(112, 19)
    --powerBg:addChild(powerNeed, 1)
 
    local showTime = lbl.createFont2(16, time2string(math.max(0, info.cd - os.time())), ccc3(0xb6, 0xff, 0x44))
    showTime:setAnchorPoint(ccp(1, 0.5))
    showTime:setPosition(110, 19)
    powerBg:addChild(showTime)
  
    json.load(json.ui.clock)
    local timeIcon = DHSkeletonAnimation:createWithKey(json.ui.clock)
    timeIcon:scheduleUpdateLua()
    timeIcon:playAnimation("animation", -1)
    timeIcon:setAnchorPoint(ccp(1, 0.5))
    timeIcon:setPosition(showTime:boundingBox():getMinX() - 20, 19)
    powerBg:addChild(timeIcon)

    local reward = conquset2items(info.reward) 
    local offsetX = 480 - 46 * #reward + 9
    for i, v in ipairs(reward) do
        local showRewardSprite
        if v.type == 1 then
            showRewardSprite = img.createItem(v.id, v.num)
        else
            showRewardSprite = img.createEquip(v.id, v.num)
        end
        showReward[i] = CCMenuItemSprite:create(showRewardSprite, nil)
        local menuReward = CCMenu:createWithItem(showReward[i])
        menuReward:setPosition(0, 0)
        showPowerBg:addChild(menuReward)
        showReward[i]:setAnchorPoint(ccp(0, 0))
        showReward[i]:setScale(74/92)
        showReward[i]:setPosition(offsetX + (i-1) * 92, 127)
        
        showReward[i]:registerScriptTapHandler(function()
            local superlayer = layer:getParent():getParent():getParent()
            if v.type == 1 then
                local tips = require("ui.tips.item").createForShow(v)
                superlayer:addChild(tips, 10000)
            else
                local tips = require("ui.tips.equip").createById(v.id)
                superlayer:addChild(tips, 10000)
            end
        end)
    end
       
    offsetX = 480 - 50 * cfgtask[info.id].heroNum + 9
    local heroes = info.heroes
    for i=1, #heroes do
        --showHero[i] = img.createHeroHead(heroes[i].id, heroes[i].lv, true, heroes.star, heroes[i].wake)
        local param = {
            id = heroes[i].id,
            lv = heroes[i].lv,
            showGroup = true,
            showStar = heroes.star,
            wake = heroes[i].wake,
            orangeFx = nil,
            petID = nil,
            hskills = heroes[i].hskills,
            hid = heroes[i].hid
        }
        showHero[i] = img.createHeroHeadByParam(param)
        showHero[i]:setAnchorPoint(ccp(0, 0))
        showHero[i]:setScale(84/94)
        showHero[i]:setPosition(offsetX + (i-1) * 100, 323)
        showPowerBg:addChild(showHero[i])
    end
    
    local offsetX = 480 - 26 * #info.conds + 5
    local condition = {}
    for i, v in ipairs(info.conds) do
        condition[i] = img.createUISprite(img.ui.hook_rate_bg)
        condition[i]:setScale(0.8)
        condition[i]:setAnchorPoint(ccp(0, 0))
        condition[i]:setPosition(offsetX + 52 * (i - 1), 238)
        showPowerBg:addChild(condition[i])

        if v.type == 1 then
            local showJob = img.createUISprite(img.ui["herotask_job_" .. v.faction])
            showJob:setPosition(condition[i]:getContentSize().width/2, condition[i]:getContentSize().height/2)
            condition[i]:addChild(showJob)
        elseif v.type == 2 then
            local showStar = img.createUISprite(img.ui.star)
            showStar:setScale(0.95)
            showStar:setPosition(condition[i]:getContentSize().width/2, condition[i]:getContentSize().height/2)
            condition[i]:addChild(showStar)

            local showNum = lbl.createFont2(18, v.faction)
            showNum:setPosition(condition[i]:getContentSize().width/2, condition[i]:getContentSize().height/2)
            condition[i]:addChild(showNum)
        elseif v.type == 3 then
            local showGroup = img.createUISprite(img.ui["herolist_group_" .. v.faction])
            showGroup:setPosition(condition[i]:getContentSize().width/2, condition[i]:getContentSize().height/2)
            condition[i]:addChild(showGroup)
        elseif v.type == 4 then
            local showQlt = img.createUISprite(img.ui.evolve)
            showQlt:setScale(0.7)
            showQlt:setPosition(condition[i]:getContentSize().width/2, condition[i]:getContentSize().height/2)
            condition[i]:addChild(showQlt)

            local showNum = lbl.createFont2(18, v.faction)
            showNum:setPosition(condition[i]:getContentSize().width/2, condition[i]:getContentSize().height/2)
            condition[i]:addChild(showNum)
        end
    end

    local titleCondition = lbl.createFont1(18, i18n.global.herotask_title_condition.string, ccc3(0x5b, 0x27, 0x06))
    titleCondition:setPosition(480, 298)
    showPowerBg:addChild(titleCondition)

    local showLfgline = img.createUISprite(img.ui.herotask_fgline)
    showLfgline:setAnchorPoint(ccp(1, 0.5))
    showLfgline:setPosition(titleCondition:boundingBox():getMinX() - 30, titleCondition:boundingBox():getMidY())
    showPowerBg:addChild(showLfgline)

    local showRfgline = img.createUISprite(img.ui.herotask_fgline)
    showRfgline:setAnchorPoint(ccp(0, 0.5))
    showRfgline:setFlipX(true)
    showRfgline:setPosition(titleCondition:boundingBox():getMaxX() + 30, titleCondition:boundingBox():getMidY())
    showPowerBg:addChild(showRfgline)
 
    --local btnFinishSprite = img.createUI9Sprite(img.ui.btn_2)
    --btnFinishSprite:setPreferredSize(CCSize(165, 50))
    --local btnFinish = HHMenuItem:create(btnFinishSprite)
    --local menuFinish = CCMenu:createWithItem(btnFinish)
    --menuFinish:setPosition(0, 0)
    --layer:addChild(menuFinish)
    --btnFinish:setPosition(480, 81)

    --local labFinish = lbl.createFont1(20, i18n.global.herotask_finish.string, ccc3(0x73, 0x3b, 0x05))
    --labFinish:setPosition(btnFinish:getContentSize().width/2, btnFinish:getContentSize().height/2)
    --btnFinish:addChild(labFinish)

    --btnFinish:registerScriptTapHandler(function()
    --    audio.play(audio.button)
    --    local params = {
    --        sid = player.sid,
    --        tid = info.tid,
    --    }

    --    addWaitNet()
    --    net:htask_rec(params, function(__data)
    --        delWaitNet()

    --        tbl2string(__data)
             
    --        if __data.status ~= 0 then
    --            showToast("server status:" .. __data.status)
    --            return
    --        end
    --        if cfgtask[info.id].star == QUALITY_4 then
    --            achieveData.add(ACHIEVE_TYPE_COMPLETE_HEROTASK4, 1)
    --            -- 酒馆任务达标
    --            local activity_data = require"data.activity"
    --            activity_data.addScore(activity_data.IDS.SCORE_TARVEN_4.ID, 1)
    --        end

    --        if cfgtask[info.id].star == QUALITY_5 then
    --            achieveData.add(ACHIEVE_TYPE_COMPLETE_HEROTASK5, 1)
    --            -- 酒馆任务达标
    --            local activity_data = require"data.activity"
    --            activity_data.addScore(activity_data.IDS.SCORE_TARVEN_5.ID, 1)
    --        end
            
    --        if cfgtask[info.id].star == QUALITY_6 then
    --            achieveData.add(ACHIEVE_TYPE_COMPLETE_HEROTASK6, 1)
    --        end
            
    --        local dailytask = require "data.task"
    --        dailytask.increment(dailytask.TaskType.HERO_TASK, 1)
            
    --        databag = require "data.bag"
    --        databag.addRewards(__data.reward)
    --        htaskData.del(info.tid)
    --        layer:getParent():getParent():getParent():addChild(require("ui.tips.reward").create(__data.reward), 1000)
    --        layer:removeFromParentAndCleanup(true)
    --    end)
    --end)

    local function backEvent()
        layer:removeFromParentAndCleanup()
    end

    -- close btn
    local close0 = img.createUISprite(img.ui.close)
    local closeBtn = SpineMenuItem:create(json.ui.button, close0)
    closeBtn:setPosition(CCPoint(814, 525))
    local closeMenu = CCMenu:createWithItem(closeBtn)
    closeMenu:setPosition(CCPoint(0, 0))
    showPowerBg:addChild(closeMenu)
    closeBtn:registerScriptTapHandler(function()     
        backEvent()
    end)

    function layer.onAndroidBack()
        backEvent()
    end

    addBackEvent(layer)

    local function onEnter()
        layer.notifyParentLock()
    end

    local function onExit()
        layer.notifyParentUnlock()
    end

    layer:registerScriptHandler(function(event)
        if event == "enter" then
            onEnter()
        elseif event == "exit" then
            onExit()        
        end
    end)

    --layer:registerScriptTouchHandler(onTouch)
    layer:setTouchEnabled(true)
    --layer:setTouchSwallowEnabled(false)
    
    return layer
end

return ui
