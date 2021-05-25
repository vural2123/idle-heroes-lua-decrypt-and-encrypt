local ui = {}

require "common.func"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local i18n = require "res.i18n"
local audio = require "res.audio"
local net = require "net.netClient"
local player = require "data.player"
local cfgwave = require "config.wavetrial"
local cfgmonster = require "config.monster"

function ui.create(stageId, superlayer)
    local layer = CCLayer:create()

    local board = CCSprite:create()
    board:setPosition(0, 0)
    board:setContentSize(960, 576)
    layer:addChild(board)

    --local showTitleBg = img.createUISprite(img.ui.dreamland_level_bg)
    local showTitleBg = CCSprite:create()
    showTitleBg:setContentSize(CCSizeMake(328, 58))
    showTitleBg:setPosition(480, 524)
    board:addChild(showTitleBg)

    local showStageId = lbl.createFont3(26, i18n.global.trial_stage_title.string .. " " .. stageId, ccc3(0xfa, 0xd8, 0x69))
    showStageId:setPosition(showTitleBg:getContentSize().width/2, showTitleBg:getContentSize().height/2-4)
    showTitleBg:addChild(showStageId)

    local powerIcon = img.createUISprite(img.ui.power_icon)
    powerIcon:setScale(0.46)
    powerIcon:setAnchorPoint(ccp(0, 0.5))
    board:addChild(powerIcon)

    local showPower = lbl.createFont2(20, cfgwave[stageId].power)
    showPower:setAnchorPoint(ccp(1, 0.5))
    board:addChild(showPower)

    local wid = powerIcon:boundingBox().size.width + showPower:boundingBox().size.width
    powerIcon:setPosition(480 - wid/2 - 10, 469)
    showPower:setPosition(480 + wid/2 + 10, 469)
    --local powerIcon = img.createUISprite(img.ui.power_icon)
    --powerIcon:setScale(0.46)
    --powerIcon:setAnchorPoint(ccp(0, 0.5))
    --powerIcon:setPosition(421, 469)
    --board:addChild(powerIcon)

    --local showPower = lbl.createFont2(20, cfgwave[stageId].power)
    --showPower:setAnchorPoint(ccp(1, 0.5))
    --showPower:setPosition(543, 469)
    --board:addChild(showPower)

    local tabEnemy = lbl.createFont1(18, i18n.global.trial_stage_enemy.string, ccc3(0xff, 0xf4, 0x93))
    tabEnemy:setPosition(board:getContentSize().width/2, 404)
    board:addChild(tabEnemy)

    local mons = cfgwave[stageId].trial
    local offset = 485 - #mons * 44 
    for i=1, #mons do
        print(mons[i])
        local info = cfgmonster[mons[i]]
        local head = nil
        if info.star == 10 then
            head = img.createHeroHead(info.heroLink, info.lvShow, true, info.star, 4)
        else
            head = img.createHeroHead(info.heroLink, info.lvShow, true, info.star)
        end
        head:setScale(0.8)
        head:setAnchorPoint(ccp(0, 0))
        head:setPosition(offset + (i - 1) * 88, 310)
        board:addChild(head)
    end

    local rewards = cfgwave[stageId].reward
    local showRewards = {}
    offset = 470 - #rewards * 33 
    for i=1, #rewards do
        local showRewardsSp
        if rewards[i].type == 1 then
            showRewardsSp = img.createItem(rewards[i].id, rewards[i].num)
        else
            showRewardsSp = img.createEquip(rewards[i].id)
        end
        showRewards[i] = CCMenuItemSprite:create(showRewardsSp, nil)
        local menuReward = CCMenu:createWithItem(showRewards[i])
        menuReward:setPosition(0, 0)
        board:addChild(menuReward)
        showRewards[i]:setScale(0.8)
        showRewards[i]:setAnchorPoint(ccp(0, 0))
        showRewards[i]:setPosition(offset + (i - 1) * 82, 185)
        
        showRewards[i]:registerScriptTapHandler(function()
            audio.play(audio.button)
            if rewards[i].type == 1 then
                local tips = require("ui.tips.item").createForShow(rewards[i])
                superlayer:addChild(tips, 100)
            else
                local tips = require("ui.tips.equip").createById(rewards[i].id)
                superlayer:addChild(tips, 100)
            end
        end)
    end

    local tabReward = lbl.createFont1(18, i18n.global.trial_stage_reward.string, ccc3(0xff, 0xf4, 0x93))
    tabReward:setPosition(board:getContentSize().width/2, 270)
    board:addChild(tabReward)

    local btnBattleSprite = img.createUI9Sprite(img.ui.btn_1)
    btnBattleSprite:setPreferredSize(CCSize(190, 70))
    local labBattle = lbl.createFont1(18, i18n.global.trial_stage_btn_battle.string, ccc3(0x73, 0x3b, 0x05))
    labBattle:setPosition(btnBattleSprite:getContentSize().width/2, btnBattleSprite:getContentSize().height/2)
    btnBattleSprite:addChild(labBattle)

    local btnBattle = SpineMenuItem:create(json.ui.button, btnBattleSprite)
    local menuBattle = CCMenu:createWithItem(btnBattle)
    btnBattle:setPosition(board:getContentSize().width/2 - 100, 124)
    menuBattle:setPosition(0, 0)
    board:addChild(menuBattle)

    btnBattle:registerScriptTapHandler(function()
        disableObjAWhile(btnBattle)
        audio.play(audio.button)
        print("BATTLE") 
        local params = {
            type = "trial"
        }
        superlayer:addChild(require("ui.selecthero.main").create(params), 1000)
    end)
	
	local btnBatchSprite = img.createLogin9Sprite(img.login.button_9_small_green)
    btnBatchSprite:setPreferredSize(CCSize(190, 70))
    local labBatch = lbl.createFont1(18, i18n.global.act_bboss_sweep.string, ccc3(0x1d, 0x67, 0x00))
    labBatch:setPosition(btnBatchSprite:getContentSize().width/2, btnBatchSprite:getContentSize().height/2)
    btnBatchSprite:addChild(labBatch)
	
	local btnBatch = SpineMenuItem:create(json.ui.button, btnBatchSprite)
    local menuBatch = CCMenu:createWithItem(btnBatch)
    btnBatch:setPosition(board:getContentSize().width/2 + 100, 124)
    menuBatch:setPosition(0, 0)
    board:addChild(menuBatch)

    btnBatch:registerScriptTapHandler(function()
        disableObjAWhile(btnBatch)
        audio.play(audio.button)
        local params = {
            type = "trial",
			isBatch = true
        }
        superlayer:addChild(require("ui.selecthero.main").create(params), 1000)
    end)
    
    local btnVideoSprite = img.createUISprite(img.ui.arena_button_video)
    local btnVideo = SpineMenuItem:create(json.ui.button, btnVideoSprite)
    btnVideo:setPosition(710, 524)
    local menuVideo = CCMenu:createWithItem(btnVideo)
    menuVideo:setPosition(0, 0)
    board:addChild(menuVideo)
    btnVideo:registerScriptTapHandler(function()
        audio.play(audio.button)
        superlayer:addChild(require("ui.trial.record").create(), 100)
    end)
    
    return layer
end

return ui
