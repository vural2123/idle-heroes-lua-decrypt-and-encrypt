local ui = {}

require "common.func"
require "common.const"
local view = require "common.view"
local i18n = require "res.i18n"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local particle = require "res.particle"
local audio = require "res.audio"
local cfgexpplayer = require "config.expplayer"
local cfghooklock = require "config.hooklock"
local player = require "data.player"
local bagdata = require "data.bag"
local hookdata = require "data.hook"

local function showRemark()
    if APP_CHANNEL and APP_CHANNEL ~= "" then return end
    local director = CCDirector:sharedDirector()
    director:getRunningScene():addChild((require"ui.remark").create(), 1000000)
end

-- [[
-- pre_level: 升级前等级
-- level: 升级后等级
-- callback: 回调
-- gems: 升级过程中产生的钻石奖励（注意升级跨多级）
-- ]]
function ui.create(pre_level, level, callback)
    local gems = 0
    for ii=pre_level+1,level do
        gems = gems + cfgexpplayer[ii].levelReward[1].num
    end
    bagdata.addGem(gems)
    local layer = CCLayer:create()
    layer:setCascadeOpacityEnabled(true)

    local lv_bg = img.createUISprite(img.ui.levelup_lv_bg)
    lv_bg:setScale(view.minScale)
    lv_bg:setPosition(scalep(480, 286))
    layer:addChild(lv_bg, 3)

    local lbl_lv = lbl.createFont1(28, "LV" .. level, ccc3(0xff, 0xde, 0x6b))
    lbl_lv:setPosition(CCPoint(lv_bg:getContentSize().width/2, lv_bg:getContentSize().height/2))
    lv_bg:addChild(lbl_lv)

    local lbl_hero_count = lbl.createFont1(20, i18n.global.unlock_battle_field.string, ccc3(255, 246, 223), true)
    local lbl_hero_count2 = lbl.createFont1(20, "" .. hookdata.getMaxHeroes(), ccc3(0xa5, 0xfd, 0x47), true)
    --local lbl_hero_count
    --if pre_level < UNLOCK_BATTLE_POSITION2 and level >= UNLOCK_BATTLE_POSITION2 then
    --    lbl_hero_count = lbl.createFont1(20, string.format(i18n.global.unlock_battle_field.string, 6), nil, true)
    --elseif pre_level < UNLOCK_BATTLE_POSITION1 and level >= UNLOCK_BATTLE_POSITION1 then
    --    lbl_hero_count = lbl.createFont1(20, "To play the hero reached: " .. 4, nil, true)
    --    lbl_hero_count = lbl.createFont1(20, string.format(i18n.global.unlock_battle_field.string, 4), nil, true)
    --elseif pre_level < 1 and level >= 1 then
    --    lbl_hero_count = lbl.createFont1(20, string.format(i18n.global.unlock_battle_field.string, 2), nil, true)
    --end

    if cfghooklock[level].show == 1 then
        lbl_hero_count:setPosition(scalep(480-10, 242))
        layer:addChild(lbl_hero_count, 3)
        lbl_hero_count2:setPosition(CCPoint(lbl_hero_count:boundingBox():getMaxX()+10*view.minScale, lbl_hero_count:boundingBox():getMidY()))
        layer:addChild(lbl_hero_count2, 3)
    end

    local lbl_reward = lbl.createFont1(20, i18n.global.mail_rewards.string, ccc3(0xff, 0xd4, 0x52), true)
    lbl_reward:setPosition(scalep(480, 194))
    layer:addChild(lbl_reward, 3)

    local tmp_item = img.createItem(ITEM_ID_GEM, gems)
    tmp_item:setScale(view.minScale)
    tmp_item:setPosition(scalep(480, 136))
    layer:addChild(tmp_item, 3)

    local title 
    if i18n.getCurrentLanguage() == kLanguageChinese then
        title = img.createUISprite(img.ui.language_upgrade_cn)
    elseif i18n.getCurrentLanguage() == kLanguageChineseTW then
        title = img.createUISprite(img.ui.language_upgrade_tw)
    elseif i18n.getCurrentLanguage() == kLanguageJapanese then
        title = img.createUISprite(img.ui.language_upgrade_jp)
    elseif i18n.getCurrentLanguage() == kLanguageKorean then
        title = img.createUISprite(img.ui.language_upgrade_kr)
    elseif i18n.getCurrentLanguage() == kLanguageRussian then
        title = img.createUISprite(img.ui.language_upgrade_ru)
    elseif i18n.getCurrentLanguage() == kLanguageTurkish then
        title = img.createUISprite(img.ui.language_upgrade_tr)
    else
        title = img.createUISprite(img.ui.language_upgrade_us)
    end
    title:setPosition(lv_bg:getContentSize().width / 2, 150)
    lv_bg:addChild(title)
    
    -- dark bg
    local darkbg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    layer:addChild(darkbg)

    json.load(json.ui.shengji)
    local level_up = DHSkeletonAnimation:createWithKey(json.ui.shengji)
    level_up:setScale(view.minScale)
    level_up:scheduleUpdateLua()
    level_up:setPosition(CCPoint(view.midX, view.midY))
    layer:addChild(level_up, 2)
    level_up:registerLuaHandler(function(_ev_str)
        print("event str:", _ev_str)
        if _ev_str == "birth_a" then
            local particle_scale = view.minScale
            local particle_lv_a = particle.create("shengji_particle_a")
            particle_lv_a:setPosition(scalep(480, 288+133.26))
            particle_lv_a:setStartSize(particle_scale * (particle_lv_a:getStartSize()))
            particle_lv_a:setStartSizeVar(particle_scale * particle_lv_a:getStartSizeVar())
            particle_lv_a:setEndSize(particle_scale * particle_lv_a:getEndSize())
            particle_lv_a:setEndSizeVar(particle_scale * particle_lv_a:getEndSizeVar())
            --level_up:addChildFollowSlot("code_particle_a_position", particle_lv_a)
            layer:addChild(particle_lv_a, 1000)
        elseif _ev_str == "birth_b" then
            --local particle_scale = view.minScale
            --local particle_lv_b = particle.create("shengji_particle_b")
            --particle_lv_b:setPosition(scalep(480, 288+130.65))
            --particle_lv_b:setStartSize(particle_scale * (particle_lv_b:getStartSize()))
            --particle_lv_b:setStartSizeVar(particle_scale * particle_lv_b:getStartSizeVar())
            --particle_lv_b:setEndSize(particle_scale * particle_lv_b:getEndSize())
            --particle_lv_b:setEndSizeVar(particle_scale * particle_lv_b:getEndSizeVar())
            ----level_up:addChildFollowSlot("code_particle_b_position", particle_lv_b)
            --layer:addChild(particle_lv_b, 1000)
        end
    end)

    local arr = CCArray:create()
    arr:addObject(CCCallFunc:create(function()
        level_up:playAnimation("animation", 1)
    end))
    arr:addObject(CCDelayTime:create(level_up:getAnimationTime("animation")+1))
    arr:addObject(CCCallFunc:create(function()
        layer:removeFromParentAndCleanup(true)

        local tutorialData = require("data.tutorial")

        if tutorialData.getVersion() == 1 then
            -- 策划说，跨解锁功能的等级升级, 只展示第一个解锁功能
            local unlockFunclayer = require "ui.unlockFunclayer"
            if pre_level < UNLOCK_BLACKMARKET_LEVEL and level >= UNLOCK_BLACKMARKET_LEVEL then
                showUnlockFunc(unlockFunclayer.WHICH.BLACKMARKET, callback)
            elseif pre_level < UNLOCK_CASINO_LEVEL and level >= UNLOCK_CASINO_LEVEL then
                showUnlockFunc(unlockFunclayer.WHICH.CASINO, callback)
            elseif pre_level < UNLOCK_ARENA_LEVEL and level >= UNLOCK_ARENA_LEVEL then
                showUnlockFunc(unlockFunclayer.WHICH.ARENA, callback)
            elseif pre_level < UNLOCK_GUILD_LEVEL and level >= UNLOCK_GUILD_LEVEL then
                showUnlockFunc(unlockFunclayer.WHICH.GUILD, callback)
            elseif pre_level < UNLOCK_TRIAL_LEVEL and level >= UNLOCK_TRIAL_LEVEL then
                showUnlockFunc(unlockFunclayer.WHICH.TRIAL, callback)
            elseif pre_level < UNLOCK_TAVERN_LEVEL and level >= UNLOCK_TAVERN_LEVEL then
                showUnlockFunc(unlockFunclayer.WHICH.TAVERN, callback)
            elseif pre_level < REMARK_LEVEL and level >= REMARK_LEVEL then
                showRemark()
            end
        else
            if tutorialData.exists() then--教程中不弹窗
                return
            end
        
            -- 策划说，跨解锁功能的等级升级, 只展示第一个解锁功能
            local unlockFunclayer = require "ui.unlockFunclayer"
            if pre_level < UNLOCK_CASINO_LEVEL and level >= UNLOCK_CASINO_LEVEL then
                showUnlockFunc(unlockFunclayer.WHICH.CASINO, callback)
            elseif pre_level < UNLOCK_ARENA_LEVEL and level >= UNLOCK_ARENA_LEVEL then
                showUnlockFunc(unlockFunclayer.WHICH.ARENA, callback)
            elseif pre_level < UNLOCK_GUILD_LEVEL and level >= UNLOCK_GUILD_LEVEL then
                showUnlockFunc(unlockFunclayer.WHICH.GUILD, callback)
            elseif pre_level < UNLOCK_TRIAL_LEVEL and level >= UNLOCK_TRIAL_LEVEL then
                showUnlockFunc(unlockFunclayer.WHICH.TRIAL, callback)
            elseif pre_level < UNLOCK_TAVERN_LEVEL and level >= UNLOCK_TAVERN_LEVEL then
                showUnlockFunc(unlockFunclayer.WHICH.TAVERN, callback)
            elseif pre_level < REMARK_LEVEL and level >= REMARK_LEVEL then
                showRemark()
            end
        end
    end))

    audio.play(audio.player_lv_up)
    layer:runAction(CCSequence:create(arr))

    layer:setTouchEnabled(true)
    layer:setTouchSwallowEnabled(true)

    function layer.onAndroidBack()
        layer:removeFromParentAndCleanup(true)
    end
        
    addBackEvent(layer)

    local function onEnter()
        print("onEnter")
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

    return layer
end

return ui
