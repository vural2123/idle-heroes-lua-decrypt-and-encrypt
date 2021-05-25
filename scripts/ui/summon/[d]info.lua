local ui = {}

require "common.func"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local i18n = require "res.i18n"
local audio = require "res.audio"
local particle = require "res.particle"
local net = require "net.netClient"
local gacha = require "data.gacha"
local heros = require "data.heros"
local bag = require "data.bag"
local player = require "data.player"
local cfgvip = require "config.vip"
local cfghero = require "config.hero"
local gemshop = require "ui.shop.main"
local achieveData = require "data.achieve"

local SUPERSUMMON = 250
local TENSUMMON = 2200

local SPEED_MULT = 1.5

local aniSummonzhen = nil

function ui.createInfo(heroes, summonType, uiParams)
    local layer = ui.createLayer(uiParams)
    if #heroes == 1 then
        aniSummonzhen:playAnimation("animation_1")
    else
        aniSummonzhen:playAnimation("animation_10")
    end
    
    audio.play(audio.summon)
    local function init()
        layer:addChild(ui.createHeroesShow(heroes, summonType, uiParams))    
    end
    layer:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0), CCCallFunc:create(init)))
    
    return layer
end

function ui.actHeroSummon10(heroes)
    local activityData = require "data.activity"
    local IDS = activityData.IDS
    for i=1,#heroes do
        if cfghero[heroes[i].id].maxStar == 5 then
            local tmp_status = activityData.getStatusById(IDS.HERO_SUMMON_1.ID)
            if cfghero[heroes[i].id].group == 2 then
                tmp_status = activityData.getStatusById(IDS.HERO_SUMMON_2.ID)
            end
            if cfghero[heroes[i].id].group == 3 then
                tmp_status = activityData.getStatusById(IDS.HERO_SUMMON_3.ID)
            end
            if cfghero[heroes[i].id].group == 4 then
                tmp_status = activityData.getStatusById(IDS.HERO_SUMMON_4.ID)
            end
            if cfghero[heroes[i].id].group == 5 then
                tmp_status = activityData.getStatusById(IDS.HERO_SUMMON_5.ID)
            end
            if cfghero[heroes[i].id].group == 6 then
                tmp_status = activityData.getStatusById(IDS.HERO_SUMMON_6.ID)
            end
            if tmp_status and tmp_status.limits and tmp_status.limits < tmp_status.cfg.parameter[1].num then
                tmp_status.limits = tmp_status.limits + 1
                local tmp_status7 = activityData.getStatusById(IDS.HERO_SUMMON_7.ID)
                if tmp_status.limits == tmp_status.cfg.parameter[1].num and tmp_status7.limits < #tmp_status7.cfg.parameter then
                    tmp_status7.limits = tmp_status7.limits + 1 
                end
            end
        end
    end
end

function ui.checkGiftLimit(heroes)
    local activitylimit = require "data.activitylimit"
    local cfglimitgift = require "config.limitgift"
    for i=1 , #heroes do
        if cfghero[heroes[i].id].qlt == 4 then
            local summon4_status = activitylimit.getStatusById(activitylimit.IDS.SUMMON_4.ID)
            if summon4_status == nil then
                activitylimit.summonNotice(4)
            elseif summon4_status.next and summon4_status.next + activitylimit.pull_time - os.time() <= 0 then
                activitylimit.summonNotice(4)
            end
        end
        if cfghero[heroes[i].id].qlt == 5 then
            local summon5_status = activitylimit.getStatusById(activitylimit.IDS.SUMMON_5.ID)
            if summon5_status == nil then
                activitylimit.summonNotice(5)
            elseif summon5_status.next and summon5_status.next + activitylimit.pull_time - os.time() <= 0 then
                activitylimit.summonNotice(5)
            end
        end
    end
end

function ui.createHeroesShow(heroes, summonType, uiParams)
    local layer = CCLayer:create()

    local function initHeroCards()
        if ui.heroCards then
            ui.heroCards:removeFromParentAndCleanup(true)
            ui.heroCards = nil
        end
    end
    -- power bar
    local powerBar = img.createUISprite(img.ui.summon_power_gauge)
    powerBar:setScale(view.minScale)
    powerBar:setPosition(scalep(480, 576-30))
    layer:addChild(powerBar)

    autoLayoutShift(powerBar)

    local detailSprite = img.createUISprite(img.ui.btn_help)
    local detailBtn = SpineMenuItem:create(json.ui.button, detailSprite)
    detailBtn:setScale(view.minScale)
    detailBtn:setPosition(scalep(930, 576-27))

    local detailMenu = CCMenu:create()
    detailMenu:setPosition(0, 0)
    layer:addChild(detailMenu)
    detailMenu:addChild(detailBtn)

    detailBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer:addChild(require("ui.help").create(i18n.global.help_summon.string), 1000)
    end)

    autoLayoutShift(detailBtn)

    -- gem icon
    local icon_gem 
    if summonType == 9 or summonType == 16 then
        icon_gem = img.createItemIcon2(ITEM_ID_LOVE)
    else
        icon_gem = img.createItemIcon2(ITEM_ID_GEM)
    end
    icon_gem:setPosition(CCPoint(8, powerBar:getContentSize().height/2))
    powerBar:addChild(icon_gem)

    -- gem btn
    local btn_gem0 = img.createUISprite(img.ui.main_icon_plus)
    local btn_gem = HHMenuItem:create(btn_gem0)
    btn_gem:setPosition(CCPoint(138, powerBar:getContentSize().height/2))
    local btn_gem_menu = CCMenu:createWithItem(btn_gem)
    btn_gem_menu:setPosition(CCPoint(0, 0))
    powerBar:addChild(btn_gem_menu)

    btn_gem:registerScriptTapHandler(function()
        audio.play(audio.button)
        local gemShop = gemshop.create()
        layer:getParent():addChild(gemShop, 1001)
    end)

    -- lbl gem
    local gem_num = bag.gem()
    local lbl_gem = lbl.createFont2(16, gem_num, ccc3(255, 246, 223))
    lbl_gem:setPosition(CCPoint(74, powerBar:getContentSize().height/2))
    powerBar:addChild(lbl_gem)
    lbl_gem.num = gem_num

    local love_num = bag.items.find(ITEM_ID_LOVE).num 
    local lbl_love = lbl.createFont2(16, love_num, ccc3(255, 246, 223))
    lbl_love:setPosition(CCPoint(74, powerBar:getContentSize().height/2))
    powerBar:addChild(lbl_love)
    lbl_love.num = gem_love
    if summonType == 9 or summonType == 16 then
        lbl_love:setVisible(true)
        lbl_gem:setVisible(false)
        btn_gem:setVisible(false)
    else
        lbl_love:setVisible(false)
        lbl_gem:setVisible(true)
        btn_gem:setVisible(true)
    end

    local function updateLabels()
        local gemnum = bag.gem()
        if lbl_gem.num ~= gemnum then
            lbl_gem:setString(gemnum)
            lbl_gem.num = gemnum
        end
    end

    local function onUpdate(ticks)
        updateLabels()
    end
    
    layer:scheduleUpdateWithPriorityLua(onUpdate, 0)

    local helmet0 = img.createUISprite(img.ui.summon_helmet0)
    local helmetBtn0 = SpineMenuItem:create(json.ui.button, helmet0)    
    helmetBtn0:setPosition(CCPoint(504, powerBar:getContentSize().height/2+5))
    local helmetMenu = CCMenu:create()
    helmetMenu:setPosition(0, 0)
    powerBar:addChild(helmetMenu, 1101)
    helmetMenu:addChild(helmetBtn0)

    helmetBtn0:registerScriptTapHandler(function()
        audio.play(audio.button)
        --showToast(i18n.global.summon_help_enegy.string)
        layer:addChild(require("ui.help").create(i18n.global.summon_help_enegy.string), 1000)
    end)

    json.load(json.ui.toukui)
    local aniSummontoukui = DHSkeletonAnimation:createWithKey(json.ui.toukui)
    aniSummontoukui:scheduleUpdateLua()
    aniSummontoukui:playAnimation("animation", -1)
    local toukuiSprite = CCSprite:create()
    toukuiSprite:setContentSize(CCSize(66, 53))
    aniSummontoukui:setPosition(CCPoint(toukuiSprite:getContentSize().width/2,
                                        toukuiSprite:getContentSize().height/2))
    toukuiSprite:addChild(aniSummontoukui)
    local helmetBtn = SpineMenuItem:create(json.ui.button, toukuiSprite)    
    helmetBtn:setPosition(CCPoint(504, powerBar:getContentSize().height/2+5))
    helmetBtn:setVisible(false)
    local helmetMenu = CCMenu:create()
    helmetMenu:setPosition(0, 0)
    powerBar:addChild(helmetMenu, 1001)
    helmetMenu:addChild(helmetBtn)

    json.load(json.ui.zhaohuan_nenglcao)
    local aniSummonnenglcao = DHSkeletonAnimation:createWithKey(json.ui.zhaohuan_nenglcao)
    aniSummonnenglcao:scheduleUpdateLua()
    aniSummonnenglcao:playAnimation("animation", -1)
    aniSummonnenglcao:setAnchorPoint(CCPoint(0.5, -1))
    aniSummonnenglcao:setPosition(CCPoint(325, powerBar:getContentSize().height/2))
    aniSummonnenglcao:setVisible(false)
    powerBar:addChild(aniSummonnenglcao, 1000)
    local currentPower = bag.items.find(ITEM_ID_ENERGY).num
    if summonType >= 4 and summonType <= 6 then
        currentPower = currentPower - 10
    end
    if summonType == 7 or summonType == 8 then
        currentPower = currentPower - 100
    end
    local requiredPower = 1000
    if currentPower < requiredPower or cfgvip[player.vipLv()].gacha == nil then
        aniSummonnenglcao:setVisible(false)
        helmetBtn0:setVisible(true)
        helmetBtn:setVisible(false)
    else
        aniSummonnenglcao:setVisible(true)
        helmetBtn0:setVisible(false)
        helmetBtn:setVisible(true)
    end

    local progress0 = img.createUISprite(img.ui.summon_power_bar)
    local powerProgress = createProgressBar(progress0)
    powerProgress:setAnchorPoint(ccp(0, 0.5))
    powerProgress:setPosition(171, powerBar:getContentSize().height/2-1)
    powerProgress:setPercentage(currentPower/requiredPower*100)
    powerBar:addChild(powerProgress)

    local progressStr = string.format("%d/%d", currentPower, requiredPower)
    local progressLabel = lbl.createFont2(16, progressStr, ccc3(255, 246, 223))
    progressLabel:setPosition(CCPoint(325, powerBar:getContentSize().height/2-2))
    powerBar:addChild(progressLabel)

    helmetBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        if #heros + 1 > cfgvip[player.vipLv()].heroes + player.buy_hlimit*5 then
            --showToast(i18n.global.summon_hero_full.string)
            local gotoHeroDlg= require "ui.summon.tipsdialog"
            gotoHeroDlg.show(layer)
            return
        end
        local params = {}
        params.sid = player.sid
        params.type = 10

        local item = bag.items.find(ITEM_ID_ENERGY)
        local summonItemCount = 0
        if item then
            summonItemCount = item.num
        end

        addWaitNet()
        net:gacha(params, function(__data)
            delWaitNet()
            tbl2string(__data)
            if __data.status ~= 0 then
                showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                return
            end
            bag.items.sub({id = ITEM_ID_ENERGY, num = 1000}) --从背包中扣掉
            local infoLayer = require("ui.summon.info").createInfo(__data.heroes, 10, uiParams)

            replaceScene(infoLayer)
            heros.addAll(__data.heroes)
            ui.actHeroSummon10(__data.heroes)
            ui.checkGiftLimit(__data.heroes)
        end)
    end)

    local defineBtn1 = img.createLogin9Sprite(img.login.button_9_small_gold)
    defineBtn1:setPreferredSize(CCSize(174, 60))
    local defineLab = lbl.createFont1(18, i18n.global.summon_comfirm.string, ccc3(0x73, 0x3b, 0x05))
    defineLab:setPosition(CCPoint(defineBtn1:getContentSize().width/2, 
                                defineBtn1:getContentSize().height/2))
    defineBtn1:addChild(defineLab)
    layer.defineBtn = SpineMenuItem:create(json.ui.button, defineBtn1)
    layer.defineBtn:setScale(view.minScale)
    layer.defineBtn:setVisible(false)
    layer.defineBtn:setAnchorPoint(CCPoint(0.5, 0.5))
    layer.defineBtn:setPosition(scalep(288, 576-452))
    local function backEvent()
        audio.play(audio.button)
        replaceScene(require("ui.summon.main").create(uiParams))
    end

    layer.defineBtn:registerScriptTapHandler(function()
        backEvent()
    end)

    local summonMenu = CCMenu:create()
    summonMenu:setPosition(0, 0)
    layer:addChild(summonMenu)
    summonMenu:addChild(layer.defineBtn)

    layer.itemsummonBtn = nil
    layer.itemsummon10Btn = nil
    layer.gemsummonBtn = nil
    
    local function setBtnvisit(visit)
        if layer.itemsummonBtn then
            layer.itemsummonBtn:setVisible(visit)
            if visit == true then
                layer.itemsummonBtn:setScale(0.5*view.minScale)
                layer.itemsummonBtn:runAction(CCScaleTo:create(0.15, 1*view.minScale, 1*view.minScale))
            end
        end
        if layer.itemsummon10Btn then
            layer.itemsummon10Btn:setVisible(visit)
            if visit == true then
                layer.itemsummon10Btn:setScale(0.5*view.minScale)
                layer.itemsummon10Btn:runAction(CCScaleTo:create(0.15, 1*view.minScale, 1*view.minScale))
            end
        end
        if layer.gemsummonBtn then
            layer.gemsummonBtn:setVisible(visit)
            if visit == true then
                layer.gemsummonBtn:setScale(0.5*view.minScale)
                layer.gemsummonBtn:runAction(CCScaleTo:create(0.15, 1*view.minScale, 1*view.minScale))
            end
        end
        layer.defineBtn:setVisible(visit)
        if visit == true then
            layer.defineBtn:setScale(0.5*view.minScale)
            layer.defineBtn:runAction(CCScaleTo:create(0.15, 1*view.minScale, 1*view.minScale))
        end
    end

    if summonType == 1 or summonType == 2 or summonType == 3 then
        local summon1 = img.createLogin9Sprite(img.login.button_9_small_gold)
        summon1:setPreferredSize(CCSize(174, 60))
        local item1 = img.createUISprite(img.ui.summon_item1)
        item1:setScale(0.9)
        item1:setPosition(CCPoint(30, summon1:getContentSize().height/2+2))
        summon1:addChild(item1)
        local itemcountLable = lbl.createFont2(16, 1, ccc3(255, 246, 223))
        itemcountLable:setPosition(CCPoint(item1:getContentSize().width/2, 5))
        item1:addChild(itemcountLable)
        local buyLab = lbl.createFont1(16, i18n.global.summon_buy.string, ccc3(0x73, 0x3b, 0x05))
        buyLab:setPosition(CCPoint(summon1:getContentSize().width*3/5, 
                                    summon1:getContentSize().height/2))
        summon1:addChild(buyLab)
        layer.itemsummonBtn = SpineMenuItem:create(json.ui.button, summon1)
        layer.itemsummonBtn:setScale(view.minScale)
        --layer.itemsummonBtn:setAnchorPoint(CCPoint(0.5, 0))
        layer.itemsummonBtn:setPosition(scalep(480, 576-452))
        layer.itemsummonBtn:registerScriptTapHandler(function()
            audio.play(audio.button)
            if #heros + 1 > cfgvip[player.vipLv()].heroes + player.buy_hlimit*5 then
                --showToast(i18n.global.summon_hero_full.string)
                local gotoHeroDlg= require "ui.summon.tipsdialog"
                gotoHeroDlg.show(layer)
                return
            end

            local item = bag.items.find(ITEM_ID_GACHA)
            local summonItemCount = 0
            if item then
                summonItemCount = item.num
            end
            
            if summonItemCount <= 0 then
                showToast(i18n.global.summon_basic_lack.string)
                return 
            else
                paramsItem = { id = ITEM_ID_GACHA , num = 1}
            end
            local params = {}
            params.sid = player.sid
            params.type = 2

            addWaitNet()
            net:gacha(params, function(__data)
                delWaitNet()
                tbl2string(__data)
                if __data.status ~= 0 then
                    showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                    return
                end
                initHeroCards()
                bag.items.sub({id = ITEM_ID_GACHA, num = paramsItem.num}) --从背包中扣掉
                
                setBtnvisit(false)
                schedule(layer, 1, function()
                    setBtnvisit(true)
                end)

                if #__data.heroes == 1 then
                    aniSummonzhen:playAnimation("animation_1_s")
                else
                    aniSummonzhen:playAnimation("animation_10_s")
                end
                ui.heroCards = ui.createHeroesShowCards(__data.heroes, summonType)
                layer:addChild(ui.heroCards, 1000)

                print("__data.heroes:", #__data.heroes)
                heros.addAll(__data.heroes)
                print("__data.heroes:", #__data.heroes)
                ui.actHeroSummon10(__data.heroes)

                if cfghero[__data.heroes[1].id].maxStar == 5 then
                    achieveData.add(ACHIEVE_TYPE_COMMONSUMMONFIVE, 1) 
                end

                local task = require "data.task"
                task.increment(task.TaskType.BASIC_SUMMON)
            end)
        end)

        local summon2 = img.createLogin9Sprite(img.login.button_9_small_gold)
        summon2:setPreferredSize(CCSize(174, 60))
        local item2 = img.createUISprite(img.ui.summon_item1)
        item2:setScale(0.9)
        item2:setPosition(CCPoint(30, summon2:getContentSize().height/2+2))
        summon2:addChild(item2)
        local itemcountLable2 = lbl.createFont2(16, 10, ccc3(255, 246, 223))
        itemcountLable2:setPosition(CCPoint(item2:getContentSize().width/2, 5))
        item2:addChild(itemcountLable2)
        local buyLab2 = lbl.createFont1(16, i18n.global.summon_buy.string, ccc3(0x73, 0x3b, 0x05))
        buyLab2:setPosition(CCPoint(summon2:getContentSize().width*3/5, 
                                    summon2:getContentSize().height/2))
        summon2:addChild(buyLab2)
        layer.itemsummon10Btn = SpineMenuItem:create(json.ui.button, summon2)
        layer.itemsummon10Btn:setScale(view.minScale)
        --layer.itemsummonBtn:setAnchorPoint(CCPoint(0.5, 0))
        layer.itemsummon10Btn:setPosition(scalep(672, 576-452))
        layer.itemsummon10Btn:registerScriptTapHandler(function()
            audio.play(audio.button)
            if #heros + 10 > cfgvip[player.vipLv()].heroes + player.buy_hlimit*5 then
                --showToast(i18n.global.summon_hero_full.string)
                local gotoHeroDlg= require "ui.summon.tipsdialog"
                gotoHeroDlg.show(layer)
                return
            end

            local item = bag.items.find(ITEM_ID_GACHA)
            local summonItemCount = 0
            if item then
                summonItemCount = item.num
            end
            
            if summonItemCount < 10 then
                showToast(i18n.global.summon_basic_lack.string)
                return 
            else
                paramsItem = { id = ITEM_ID_GACHA , num = 10}
            end
            local params = {}
            params.sid = player.sid
            params.type = 3

            addWaitNet()
            net:gacha(params, function(__data)
                delWaitNet()
                tbl2string(__data)
                if __data.status ~= 0 then
                    showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                    return
                end
                initHeroCards()
                bag.items.sub({id = ITEM_ID_GACHA, num = paramsItem.num}) --从背包中扣掉
                
                setBtnvisit(false)
                schedule(layer, 1, function()
                    setBtnvisit(true)
                end)

                if #__data.heroes == 1 then
                    aniSummonzhen:playAnimation("animation_1_s")
                else
                    aniSummonzhen:playAnimation("animation_10_s")
                end
                ui.heroCards = ui.createHeroesShowCards(__data.heroes, summonType)
                layer:addChild(ui.heroCards, 1000)

                print("__data.heroes:", #__data.heroes)
                heros.addAll(__data.heroes)
                print("__data.heroes:", #__data.heroes)
                ui.actHeroSummon10(__data.heroes)

                for ii=1,#__data.heroes do
                    if cfghero[__data.heroes[ii].id].maxStar == 5 then
                        achieveData.add(ACHIEVE_TYPE_COMMONSUMMONFIVE, 1) 
                    end
                end

                local task = require "data.task"
                task.increment(task.TaskType.BASIC_SUMMON)
            end)
        end)
        summonMenu:addChild(layer.itemsummonBtn)
        summonMenu:addChild(layer.itemsummon10Btn)

        setBtnvisit(false)
        schedule(layer, 1, function()
            setBtnvisit(true)
        end)

        layer.defineBtn:setPosition(scalep(288, 576-452))
    elseif summonType == 4 or summonType == 5 or summonType == 6 then
        local summon1 = img.createLogin9Sprite(img.login.button_9_small_gold)
        summon1:setPreferredSize(CCSize(174, 60))
        local item1 = img.createUISprite(img.ui.summon_item2)
        item1:setScale(0.9)
        item1:setPosition(CCPoint(30, summon1:getContentSize().height/2+2))
        summon1:addChild(item1)
        local itemcountLable = lbl.createFont2(16, 1, ccc3(255, 246, 223))
        itemcountLable:setPosition(CCPoint(item1:getContentSize().width/2, 5))
        item1:addChild(itemcountLable)
        local buyLab = lbl.createFont1(16, i18n.global.summon_buy.string, ccc3(0x73, 0x3b, 0x05))
        buyLab:setPosition(CCPoint(summon1:getContentSize().width*3/5, 
                                    summon1:getContentSize().height/2))
        summon1:addChild(buyLab)

        layer.itemsummonBtn = SpineMenuItem:create(json.ui.button, summon1)
        layer.itemsummonBtn:setScale(view.minScale)
        layer.itemsummonBtn:setAnchorPoint(CCPoint(0.5, 0))
        layer.itemsummonBtn:setPosition(scalep(480, 576-482))
        layer.itemsummonBtn:registerScriptTapHandler(function()
            audio.play(audio.button)
            if #heros + 1 > cfgvip[player.vipLv()].heroes + player.buy_hlimit*5 then
                --showToast(i18n.global.summon_hero_full.string)
                local gotoHeroDlg= require "ui.summon.tipsdialog"
                gotoHeroDlg.show(layer)
                return
            end

            local item = bag.items.find(ITEM_ID_SUPERGACHA) 
            local summonItemCount = 0
            if item then
                summonItemCount = item.num
            end
            local paramsItem
            if summonItemCount > 0 then                
                paramsItem = { id = ITEM_ID_SUPERGACHA , num = 1}
            else
                showToast(i18n.global.summon_hero_lack.string)
                return
            end

            local params = {}
            params.sid = player.sid
            params.type = 5

            addWaitNet()
            net:gacha(params, function(__data)
                delWaitNet()
                tbl2string(__data)
                if __data.status ~= 0 then
                    showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                    return
                end
                initHeroCards()
                bag.items.sub({id = ITEM_ID_SUPERGACHA, num = paramsItem.num})
                bag.items.add({id = ITEM_ID_ENERGY, num = 10})
                currentPower = currentPower + 10
                progressStr = string.format("%d/%d", currentPower, requiredPower)
                schedule(layer, 4, function()
                    progressLabel:setString(progressStr)
                    powerProgress:setPercentage(currentPower/requiredPower*100) 
                    if currentPower >= requiredPower and cfgvip[player.vipLv()].gacha == 1 then
                        aniSummonnenglcao:setVisible(true)
                        helmetBtn0:setVisible(false)
                        helmetBtn:setVisible(true)
                    end
                end)

                setBtnvisit(false)
                schedule(layer, 1, function()
                    setBtnvisit(true)
                end)

                ui.actHeroSummon10(__data.heroes)
                if #__data.heroes == 1 then
                    aniSummonzhen:playAnimation("animation_1_s")
                else
                    aniSummonzhen:playAnimation("animation_10_s")
                end
                ui.heroCards = ui.createHeroesShowCards(__data.heroes, summonType)
                layer:addChild(ui.heroCards, 1000)
                heros.addAll(__data.heroes)
                ui.checkGiftLimit(__data.heroes)
                local activity = require "data.activity"
                activity.addScore(activity.IDS.SCORE_SUMMON.ID, 1)

                achieveData.add(ACHIEVE_TYPE_HIGHSUMMON, 1) 

                local task = require "data.task"
                task.increment(task.TaskType.SENIOR_SUMMON)
            end)       
        end)

        local tensummon = img.createLogin9Sprite(img.login.button_9_small_gold)
        tensummon:setPreferredSize(CCSize(174, 60))
        local item2 = img.createItemIcon2(ITEM_ID_GEM)
        item2:setScale(0.9)
        item2:setPosition(CCPoint(30, tensummon:getContentSize().height/2+2))
        tensummon:addChild(item2)
        local itemcountLable = lbl.createFont2(16, SUPERSUMMON, ccc3(255, 246, 223))
        itemcountLable:setPosition(CCPoint(item2:getContentSize().width/2, 5))
        item2:addChild(itemcountLable)
        local tenbuyLab = lbl.createFont1(16, i18n.global.summon_buy.string, ccc3(0x73, 0x3b, 0x05))
        tenbuyLab:setPosition(CCPoint(tensummon:getContentSize().width*3/5, 
                                    tensummon:getContentSize().height/2))
        tensummon:addChild(tenbuyLab)
        layer.gemsummonBtn = SpineMenuItem:create(json.ui.button, tensummon)
        layer.gemsummonBtn:setScale(view.minScale)
        --layer.gemsummonBtn:setAnchorPoint(CCPoint(0.5, 0))
        layer.gemsummonBtn:setPosition(scalep(672, 576-452))

        layer.gemsummonBtn:registerScriptTapHandler(function()
            audio.play(audio.button)
            if #heros + 1 > cfgvip[player.vipLv()].heroes + player.buy_hlimit*5 then
                --showToast(i18n.global.summon_hero_full.string)
                local gotoHeroDlg= require "ui.summon.tipsdialog"
                gotoHeroDlg.show(layer)
                return
            end

            if bag.gem() < SUPERSUMMON then
                showToast(i18n.global.summon_gem_lack.string)
                return
            end

            local params = {}
            params.sid = player.sid
            params.type = 6

            addWaitNet()
            net:gacha(params, function(__data)
                delWaitNet()
                tbl2string(__data)
                if __data.status ~= 0 then
                    showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                    return
                end
                initHeroCards()
                bag.subGem(SUPERSUMMON)
                bag.items.add({id = ITEM_ID_ENERGY, num = 10})
                currentPower = currentPower + 10
                progressStr = string.format("%d/%d", currentPower, requiredPower)

                gem_num = bag.gem()
                lbl_gem:setString(gem_num)
                schedule(layer, 3.8, function()
                    progressLabel:setString(progressStr)
                    powerProgress:setPercentage(currentPower/requiredPower*100) 
                    if currentPower >= requiredPower and cfgvip[player.vipLv()].gacha == 1 then
                        aniSummonnenglcao:setVisible(true)
                        helmetBtn0:setVisible(false)
                        helmetBtn:setVisible(true)
                    end
                end)

                setBtnvisit(false)
                schedule(layer, 1, function()
                    setBtnvisit(true)
                end)
                if #__data.heroes == 1 then
                    aniSummonzhen:playAnimation("animation_1_s")
                else
                    aniSummonzhen:playAnimation("animation_10_s")
                end
                ui.heroCards = ui.createHeroesShowCards(__data.heroes, summonType)
                layer:addChild(ui.heroCards, 1000)
                heros.addAll(__data.heroes)
                ui.checkGiftLimit(__data.heroes)

                local activity = require "data.activity"
                activity.addScore(activity.IDS.SCORE_SUMMON.ID, 1)
                ui.actHeroSummon10(__data.heroes)

                achieveData.add(ACHIEVE_TYPE_HIGHSUMMON, 1) 

                local task = require "data.task"
                task.increment(task.TaskType.SENIOR_SUMMON)
            end)       
        end)
        summonMenu:addChild(layer.itemsummonBtn)
        summonMenu:addChild(layer.gemsummonBtn)
        setBtnvisit(false)
        schedule(layer, 1, function()
            setBtnvisit(true)
        end)
        currentPower = currentPower + 10
        progressStr = string.format("%d/%d", currentPower, requiredPower)
        schedule(layer, 3.8, function()
            progressLabel:setString(progressStr)
            powerProgress:setPercentage(currentPower/requiredPower*100)
            if currentPower >= requiredPower and cfgvip[player.vipLv()].gacha == 1 then
                aniSummonnenglcao:setVisible(true)
                helmetBtn0:setVisible(false)
                helmetBtn:setVisible(true)
            end
        end)
    elseif summonType == 7 or summonType == 8 then
        local summon1 = img.createLogin9Sprite(img.login.button_9_small_gold)
        summon1:setPreferredSize(CCSize(174, 60))
        local item1 = img.createUISprite(img.ui.summon_item2)
        item1:setScale(0.9)
        item1:setPosition(CCPoint(30, summon1:getContentSize().height/2+2))
        summon1:addChild(item1)
        local itemcountLable = lbl.createFont2(16, 10, ccc3(255, 246, 223))
        itemcountLable:setPosition(CCPoint(item1:getContentSize().width/2, 5))
        item1:addChild(itemcountLable)
        local buyLab = lbl.createFont1(16, i18n.global.summon_buy10.string, ccc3(0x73, 0x3b, 0x05))
        buyLab:setPosition(CCPoint(summon1:getContentSize().width*3/5, 
                                    summon1:getContentSize().height/2))
        summon1:addChild(buyLab)
        layer.itemsummonBtn = SpineMenuItem:create(json.ui.button, summon1)
        layer.itemsummonBtn:setScale(view.minScale)
        layer.itemsummonBtn:setAnchorPoint(CCPoint(0.5, 0))
        layer.itemsummonBtn:setPosition(scalep(480, 576-482))
        layer.itemsummonBtn:registerScriptTapHandler(function()
            audio.play(audio.button)
            if #heros + 10 > cfgvip[player.vipLv()].heroes + player.buy_hlimit*5 then
                --showToast(i18n.global.summon_hero_full.string)
                local gotoHeroDlg= require "ui.summon.tipsdialog"
                gotoHeroDlg.show(layer)
                return
            end
            
            local item = bag.items.find(ITEM_ID_SUPERGACHA) 
            local summonItemCount = 0
            if item then
                summonItemCount = item.num
            end
            local paramsItem
            if summonItemCount >= 10 then                
                paramsItem = { id = ITEM_ID_SUPERGACHA , num = 10}
            else 
                showToast(i18n.global.summon_hero_lack.string)
                return
            end
            local params = {}
            params.sid = player.sid
            params.type = 7

            addWaitNet()
            net:gacha(params, function(__data)
                delWaitNet()
                tbl2string(__data)
                if __data.status ~= 0 then
                    showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                    return
                end
                initHeroCards()
                bag.items.sub({id = ITEM_ID_SUPERGACHA, num = paramsItem.num})
                bag.items.add({id = ITEM_ID_ENERGY, num = 100})
                currentPower = currentPower + 100
                progressStr = string.format("%d/%d", currentPower, requiredPower)
                schedule(layer, 8, function()
                    progressLabel:setString(progressStr)
                    powerProgress:setPercentage(currentPower/requiredPower*100) 
                    if currentPower >= requiredPower and cfgvip[player.vipLv()].gacha == 1 then
                        aniSummonnenglcao:setVisible(true)
                        helmetBtn0:setVisible(false)
                        helmetBtn:setVisible(true)
                    end
                end)

                ui.actHeroSummon10(__data.heroes)
                setBtnvisit(false)
                schedule(layer, 3, function()
                    setBtnvisit(true)
                end)

                if #__data.heroes == 1 then
                    aniSummonzhen:playAnimation("animation_1_s")
                else
                    aniSummonzhen:playAnimation("animation_10_s")
                end
                ui.heroCards = ui.createHeroesShowCards(__data.heroes, summonType)
                layer:addChild(ui.heroCards, 1000)
                heros.addAll(__data.heroes)
                ui.checkGiftLimit(__data.heroes)

                local activity = require "data.activity"
                activity.addScore(activity.IDS.SCORE_SUMMON.ID, 10)

                achieveData.add(ACHIEVE_TYPE_HIGHSUMMON, 10) 

                local task = require "data.task"
                task.increment(task.TaskType.SENIOR_SUMMON, 10)
            end)
        end)

        local tensummon = img.createLogin9Sprite(img.login.button_9_small_gold)
        tensummon:setPreferredSize(CCSize(174, 60))
        local item2 = img.createItemIcon2(ITEM_ID_GEM)
        item2:setScale(0.9)
        item2:setPosition(CCPoint(30, tensummon:getContentSize().height/2+2))
        tensummon:addChild(item2)
        local itemcountLable = lbl.createFont2(16, TENSUMMON, ccc3(255, 246, 223))
        itemcountLable:setPosition(CCPoint(item2:getContentSize().width/2, 5))
        item2:addChild(itemcountLable)
        local tenbuyLab = lbl.createFont1(16, i18n.global.summon_buy10.string, ccc3(0x73, 0x3b, 0x05))
        tenbuyLab:setPosition(CCPoint(tensummon:getContentSize().width*3/5, 
                                    tensummon:getContentSize().height/2))
        tensummon:addChild(tenbuyLab)
        layer.gemsummonBtn = SpineMenuItem:create(json.ui.button, tensummon)
        layer.gemsummonBtn:setScale(view.minScale)
        layer.gemsummonBtn:setAnchorPoint(CCPoint(0.5, 0))
        layer.gemsummonBtn:setPosition(scalep(672, 576-482))

        layer.gemsummonBtn:registerScriptTapHandler(function()
            audio.play(audio.button)
            if #heros + 10 > cfgvip[player.vipLv()].heroes + player.buy_hlimit*5 then
                --showToast(i18n.global.summon_hero_full.string)
                local gotoHeroDlg= require "ui.summon.tipsdialog"
                gotoHeroDlg.show(layer)
                return
            end
            
            if bag.gem() < TENSUMMON then
                showToast(i18n.global.summon_gem_lack.string)
                return
            end

            local params = {}
            params.sid = player.sid
            params.type = 8

            addWaitNet()
            net:gacha(params, function(__data)
                delWaitNet()
                tbl2string(__data)
                if __data.status ~= 0 then
                    showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                    return
                end
                initHeroCards()
                bag.subGem(TENSUMMON)
                bag.items.add({id = ITEM_ID_ENERGY, num = 100})
                currentPower = currentPower + 100

                gem_num = bag.gem()
                lbl_gem:setString(gem_num)
                progressStr = string.format("%d/%d", currentPower, requiredPower)
                schedule(layer, 8, function()
                    progressLabel:setString(progressStr)
                    powerProgress:setPercentage(currentPower/requiredPower*100) 
                    if currentPower >= requiredPower and cfgvip[player.vipLv()].gacha == 1 then
                        aniSummonnenglcao:setVisible(true)
                        helmetBtn0:setVisible(false)
                        helmetBtn:setVisible(true)
                    end
                end)

                ui.actHeroSummon10(__data.heroes)
                setBtnvisit(false)
                schedule(layer, 3, function()
                    setBtnvisit(true)
                end)
                 
                if #__data.heroes == 1 then
                    aniSummonzhen:playAnimation("animation_1_s")
                else
                    aniSummonzhen:playAnimation("animation_10_s")
                end
                ui.heroCards = ui.createHeroesShowCards(__data.heroes, summonType)
                layer:addChild(ui.heroCards, 1000)
                heros.addAll(__data.heroes)
                ui.checkGiftLimit(__data.heroes)
                local activity = require "data.activity"
                activity.addScore(activity.IDS.SCORE_SUMMON.ID, 10)

                achieveData.add(ACHIEVE_TYPE_HIGHSUMMON, 10) 
                
                local task = require "data.task"
                task.increment(task.TaskType.SENIOR_SUMMON, 10)
            end)
        end)
        summonMenu:addChild(layer.itemsummonBtn)
        summonMenu:addChild(layer.gemsummonBtn)
        setBtnvisit(false)
        schedule(layer, 3, function()
            setBtnvisit(true)
        end)
        currentPower = currentPower + 100
        progressStr = string.format("%d/%d", currentPower, requiredPower)
        schedule(layer, 8, function()
            progressLabel:setString(progressStr)
            powerProgress:setPercentage(currentPower/requiredPower*100) 
            if currentPower >= requiredPower and cfgvip[player.vipLv()].gacha == 1 then
                aniSummonnenglcao:setVisible(true)
                helmetBtn0:setVisible(false)
                helmetBtn:setVisible(true)
            end
        end)
    elseif summonType == 9 or summonType == 16 then
        local summon1 = img.createLogin9Sprite(img.login.button_9_small_gold)
        summon1:setPreferredSize(CCSize(174, 60))
        local item1 = img.createItemIcon2(ITEM_ID_LOVE)
        item1:setScale(0.9)
        item1:setPosition(CCPoint(30, summon1:getContentSize().height/2+2))
        summon1:addChild(item1)
        local itemcountLable = lbl.createFont2(16, 10, ccc3(255, 246, 223))
        itemcountLable:setPosition(CCPoint(item1:getContentSize().width/2, 5))
        item1:addChild(itemcountLable)
        local buyLab = lbl.createFont1(16, i18n.global.summon_buy.string, ccc3(0x73, 0x3b, 0x05))
        buyLab:setPosition(CCPoint(summon1:getContentSize().width*3/5, 
                                    summon1:getContentSize().height/2))
        summon1:addChild(buyLab)
        layer.itemsummonBtn = SpineMenuItem:create(json.ui.button, summon1)
        layer.itemsummonBtn:setScale(view.minScale)
        layer.itemsummonBtn:setAnchorPoint(CCPoint(0.5, 0))
        layer.itemsummonBtn:setPosition(scalep(480, 576-482))
        layer.itemsummonBtn:registerScriptTapHandler(function()
            audio.play(audio.button)
            if #heros + 1 > cfgvip[player.vipLv()].heroes + player.buy_hlimit*5 then
                --showToast(i18n.global.summon_hero_full.string)
                local gotoHeroDlg= require "ui.summon.tipsdialog"
                gotoHeroDlg.show(layer)
                return
            end

            local item = bag.items.find(12)
            local summonItemCount = 0
            if item then
                summonItemCount = item.num
            end
            if item.num < 10 then
                showToast(i18n.global.summon_love_lack.string)
                return
            end
            local params = {}
            params.sid = player.sid
            params.type = 9

            addWaitNet()
            net:gacha(params, function(__data)
                delWaitNet()
                tbl2string(__data)
                if __data.status ~= 0 then
                    showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                    return
                end
                initHeroCards()
                bag.items.sub({id = ITEM_ID_LOVE, num = 10})

                love_num = bag.items.find(ITEM_ID_LOVE).num
                lbl_love:setString(love_num)

                setBtnvisit(false)
                schedule(layer, 1, function()
                    setBtnvisit(true)
                end)

                ui.actHeroSummon10(__data.heroes)
                if #__data.heroes == 1 then
                    aniSummonzhen:playAnimation("animation_1_s")
                else
                    aniSummonzhen:playAnimation("animation_10_s")
                end
                ui.heroCards = ui.createHeroesShowCards(__data.heroes, summonType)
                ui.checkGiftLimit(__data.heroes)
                layer:addChild(ui.heroCards, 1000)
                heros.addAll(__data.heroes)

                if cfghero[__data.heroes[1].id].maxStar == 5 then
                    achieveData.add(ACHIEVE_TYPE_LOVESUMMONFIVE, 1) 
                end
            end)
        end)

        local summon2 = img.createLogin9Sprite(img.login.button_9_small_gold)
        summon2:setPreferredSize(CCSize(174, 60))
        local item2 = img.createItemIcon2(ITEM_ID_LOVE)
        item2:setScale(0.9)
        item2:setPosition(CCPoint(30, summon2:getContentSize().height/2+2))
        summon2:addChild(item2)
        local itemcountLable2 = lbl.createFont2(16, 100, ccc3(255, 246, 223))
        itemcountLable2:setPosition(CCPoint(item2:getContentSize().width/2, 5))
        item2:addChild(itemcountLable2)
        local buyLab2 = lbl.createFont1(16, i18n.global.summon_buy.string, ccc3(0x73, 0x3b, 0x05))
        buyLab2:setPosition(CCPoint(summon2:getContentSize().width*3/5, 
                                    summon2:getContentSize().height/2))
        summon2:addChild(buyLab2)
        layer.itemsummon10Btn = SpineMenuItem:create(json.ui.button, summon2)
        layer.itemsummon10Btn:setScale(view.minScale)
        layer.itemsummon10Btn:setAnchorPoint(CCPoint(0.5, 0))
        layer.itemsummon10Btn:setPosition(scalep(672, 576-482))
        layer.itemsummon10Btn:registerScriptTapHandler(function()
            audio.play(audio.button)
            if #heros + 10 > cfgvip[player.vipLv()].heroes + player.buy_hlimit*5 then
                --showToast(i18n.global.summon_hero_full.string)
                local gotoHeroDlg= require "ui.summon.tipsdialog"
                gotoHeroDlg.show(layer)
                return
            end

            local item = bag.items.find(12)
            local summonItemCount = 0
            if item then
                summonItemCount = item.num
            end
            if item.num < 100 then
                showToast(i18n.global.summon_love_lack.string)
                return
            end
            local params = {}
            params.sid = player.sid
            params.type = 16

            addWaitNet()
            net:gacha(params, function(__data)
                delWaitNet()
                tbl2string(__data)
                if __data.status ~= 0 then
                    showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                    return
                end
                initHeroCards()
                bag.items.sub({id = ITEM_ID_LOVE, num = 100})

                love_num = bag.items.find(ITEM_ID_LOVE).num
                lbl_love:setString(love_num)

                setBtnvisit(false)
                schedule(layer, 1, function()
                    setBtnvisit(true)
                end)

                ui.actHeroSummon10(__data.heroes)
                if #__data.heroes == 1 then
                    aniSummonzhen:playAnimation("animation_1_s")
                else
                    aniSummonzhen:playAnimation("animation_10_s")
                end
                ui.heroCards = ui.createHeroesShowCards(__data.heroes, summonType)
                ui.checkGiftLimit(__data.heroes)
                layer:addChild(ui.heroCards, 1000)
                heros.addAll(__data.heroes)

                for ii=1,#__data.heroes do
                    if cfghero[__data.heroes[ii].id].maxStar == 5 then
                        achieveData.add(ACHIEVE_TYPE_LOVESUMMONFIVE, 1) 
                    end
                end
            end)
        end)
        summonMenu:addChild(layer.itemsummonBtn)
        summonMenu:addChild(layer.itemsummon10Btn)
        setBtnvisit(false)
        schedule(layer, 1, function()
            setBtnvisit(true)
        end)

        layer.defineBtn:setPosition(scalep(288, 576-452))
    else
        setBtnvisit(false)
        schedule(layer, 1, function()
            setBtnvisit(true)
        end)
        layer.defineBtn:setPosition(scalep(480, 576-452))
    end
    --json.load(json.ui.zhaohuan_kuozhan)
    --local aniSummonkuozhan = DHSkeletonAnimation:createWithKey(json.ui.zhaohuan_kuozhan)
    --aniSummonkuozhan:setScale(view.minScale)
    --aniSummonkuozhan:scheduleUpdateLua()
    --aniSummonkuozhan:playAnimation("animation")
    --aniSummonkuozhan:setAnchorPoint(CCPoint(0.5, 0))
    --aniSummonkuozhan:setPosition(scalep(480, 576-242))
    --layer:addChild(aniSummonkuozhan, 1000)
    
    local heroCards = ui.createHeroesShowCards(heroes, summonType, true)
    layer:addChild(heroCards, 1000)
    ui.heroCards = heroCards

    return layer
end

function ui.createHeroesShowCards(heroes, summonType, btnflag)
    local layer = CCLayer:create()
    local gridWidth = 102
    local function getPosition(i, rewardNum)
        if rewardNum <= 5 then
            y = 576-242
        elseif i <= 5 then
            y = 576-188
        else
            y = 576-300
        end

        if rewardNum%5 == 0 then
            x = 278
        elseif rewardNum%5 == 4 then
            x = 278 + gridWidth/2
        elseif rewardNum%5 == 3 then
            x = 278 + gridWidth
        elseif rewardNum%5 == 2 then
            x = 278 + gridWidth*3/2
        elseif rewardNum%5 == 1  then
            x = 278 + gridWidth*2
        end
        x = x + gridWidth*((i-1)%5)
        return x, y
    end

    local time = 2.4
    local audioTime = 0.8
    if btnflag then
        audioTime = 1.8
    end
    local icons = {}
    --local iconNodes = {}
    local loopparcl = {}
    if heroes then
        if #heroes == 10 then
            time = 6.5
        end
        for i , hero in ipairs(heroes) do
            schedule(layer, 0.5 / SPEED_MULT, function()
                --iconNodes[i] = CCNode:create()
                --iconNodes[i]:setCascadeOpacityEnabled(true)
                --iconNodes[i]:setCascadeColorEnabled(true)

                local icon = img.createHeroHeadByHid(hero.hid)
                icons[i] = CCMenuItemSprite:create(icon, nil)
                icons[i]:setScale(0.9)
                local x, y = getPosition(i, #heroes)
                icons[i].menu = CCMenu:createWithItem(icons[i])
                icons[i].menu:ignoreAnchorPointForPosition(false)
                --iconNodes[i]:addChild(icons[i].menu)
                icons[i]:registerScriptTapHandler(function()
                    audio.play(audio.button)
                    local herotips = require "ui.tips.hero"
                    local tips = herotips.create(hero.id)
                    if layer and not tolua.isnull(layer) then
                        layer:addChild(tips, 1001)
                    end
                end)
                json.load(json.ui.zhaohuan_fazhen_s)
                local aniSummontbtx = DHSkeletonAnimation:createWithKey(json.ui.zhaohuan_fazhen_s)
                aniSummontbtx:setScale(0.9)
                aniSummontbtx:scheduleUpdateLua()
                aniSummontbtx:setAnchorPoint(CCPoint(0.5, -1))
                --iconNodes[i]:addChild(aniSummontbtx)
                --aniSummontbtx:setPosition(scalep(x, y))
                --layer:addChild(aniSummontbtx, 1000)
                if cfghero[hero.id].qlt >= 5 then
                    aniSummontbtx:playAnimation("start")
                    aniSummontbtx:appendNextAnimation("loop", -1)
                end
                if i == 1 and #heroes == 1 then
                    aniSummonzhen:addChildFollowSlot("code_icon", icons[i].menu)
                    aniSummonzhen:addChildFollowSlot("code_position", aniSummontbtx)
                else
                    aniSummonzhen:addChildFollowSlot(string.format("code_icon_%d", i), icons[i].menu)
                    aniSummonzhen:addChildFollowSlot(string.format("code_position_%d", i), aniSummontbtx)
                end
            end)
            schedule(layer, audioTime / SPEED_MULT, function()
                if cfghero[hero.id].qlt >= 5 then
                    audio.play(audio.summon_get_nb)
                else
                    audio.play(audio.summon_get_common)
                end
            end)
            if cfghero[hero.id].qlt >= 5 then
                time = time + 0.46
                audioTime = audioTime + 0.5
            else
                audioTime = audioTime + 0.5
                --time = time + 0.2
            end
        end
    end
    
    if summonType >= 4 and summonType <= 8 then

        -- 2.4  6.5
        schedule(layer, time / SPEED_MULT, function()
            audio.play(audio.summon_reward)
            json.load(json.ui.zhaohuan_lizi)
            local aniSummonLz = DHSkeletonAnimation:createWithKey(json.ui.zhaohuan_lizi)
            aniSummonLz:setScale(view.minScale)
            aniSummonLz:scheduleUpdateLua()

            aniSummonLz:setPosition(scalep(480, 288))
            layer:addChild(aniSummonLz, 1001)
            local loopparcl = nil
            local tenloopparcl = {}
            if #heroes <= 5 then
                loopparcl = particle.create("zh_loop")
                loopparcl:setScale(view.minScale)
                layer:addChild(loopparcl, 1001) 
                aniSummonLz:playAnimation("animation1")
            else
                for i = 1,10 do
                    tenloopparcl[i] = particle.create("zh_loop")
                    tenloopparcl[i]:setScale(view.minScale)
                    layer:addChild(tenloopparcl[i], 1001) 
                end
                aniSummonLz:playAnimation("animation2")
            end

            local function onpartUpdate()
                if #heroes <= 5 then
                    loopparcl:setPosition(aniSummonLz:getBonePositionRelativeToLayer(string.format("code_ic%d", 1)))
                else
                    for i = 1,10 do
                        tenloopparcl[i]:setPosition(aniSummonLz:getBonePositionRelativeToLayer(string.format("code_ic%d", i)))
                    end
                end
            end

            layer:scheduleUpdateWithPriorityLua(onpartUpdate, 0)

            schedule(layer, 3.0, function()
                layer:unscheduleUpdate()
            end)
        end)
    end

    return layer
end

function ui.createLayer(uiParams)
    local layer = CCLayer:create()

    img.load(img.packedOthers.spine_ui_zhaohuan_1)
    json.load(json.ui.zhaohuan_fazhen)
    aniSummonzhen = DHSkeletonAnimation:createWithKey(json.ui.zhaohuan_fazhen)
    aniSummonzhen:setScale(view.minScale)
    aniSummonzhen:scheduleUpdateLua()
    aniSummonzhen:setAnchorPoint(CCPoint(0.5, 0))
    aniSummonzhen:setPosition(view.midX, view.midY)
	aniSummonzhen:setTimeScale(SPEED_MULT)
    layer:addChild(aniSummonzhen)

    -- bg
    local bg = img.createUISprite(img.ui.summon_bg)
    aniSummonzhen:addChildFollowSlot("code_bg", bg)

    layer:setTouchEnabled(true)

    addBackEvent(layer)
    local function backEvent()
        audio.play(audio.button)
        replaceScene(require("ui.summon.main").create(uiParams))
    end

    function layer.onAndroidBack()
        backEvent()
    end

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
        elseif event == "cleanup" then
            img.unload(img.packedOthers.spine_ui_zhaohuan_1)
        end
    end)

    require("ui.tutorial").show("ui.summon.info", layer)

    return layer
end

return ui
