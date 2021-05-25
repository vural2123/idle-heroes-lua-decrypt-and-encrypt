-- 召唤界面

local ui = {}

require "common.func"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local i18n = require "res.i18n"
local audio = require "res.audio"
local net = require "net.netClient"
local gacha = require "data.gacha"
local heros = require "data.heros"
local bag = require "data.bag"
local player = require "data.player"
local cfgvip = require "config.vip" 
local cfghero = require "config.hero"
local gemshop = require "ui.shop.main"
local achieveData = require "data.achieve"

local NORMALSUMMONTIME = 60 * 60 * 8 - 600
local SUPERSUMMONTIME = 60 * 60 * 48 - 3600
local SUPERSUMMON = 250
local TENSUMMON = 2200

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

function ui.create(uiParams)
    local layer = CCLayer:create()
   
    local fullPower = false

    -- bg
    local bg = img.createUISprite(img.ui.summon_bg)
    --local bg = display.newSprite("#ui/" .. img.ui.summon_bg, nil, nil, {class=CCFilteredSpriteWithOne})
    bg:setScale(view.minScale)
    --bg:setFilter(filter.newFilter("GAUSSIAN_VBLUR", {2}))
    bg:setPosition(view.midX, view.midY)
    layer:addChild(bg)

    img.load(img.packedOthers.spine_ui_zhaohuan_1)
    json.load(json.ui.zhaohuan_lizihua)
    local aniLizihua = DHSkeletonAnimation:createWithKey(json.ui.zhaohuan_lizihua)
    aniLizihua:setScale(view.minScale)
    aniLizihua:scheduleUpdateLua()
    aniLizihua:playAnimation("animation", -1)
    aniLizihua:setAnchorPoint(CCPoint(0.5, 0))
    aniLizihua:setPosition(scalep(480, 576-190))
    layer:addChild(aniLizihua, 1000)

    -- table
    local table = img.createUISprite(img.ui.summon_table)
    table:setScale(view.minScale)
    table:setPosition(scalep(960/2, 576/2))
    table:setVisible(false)
    layer:addChild(table)
   
    json.load(json.ui.zhaohuan)
    local aniSummon = DHSkeletonAnimation:createWithKey(json.ui.zhaohuan)
    aniSummon:setScale(view.minScale)
    aniSummon:scheduleUpdateLua()
    aniSummon:playAnimation("fire", -1)
    aniSummon:registerAnimation("animation")
    aniSummon:registerAnimation("loop", -1)
    aniSummon:setAnchorPoint(CCPoint(0.5, 0))
    aniSummon:setPosition(scalep(480, 288))
    layer:addChild(aniSummon)

    local infoSprite = img.createUISprite(img.ui.btn_detail)
    local infoBtn = SpineMenuItem:create(json.ui.button, infoSprite)
    infoBtn:setScale(view.minScale)
    infoBtn:setPosition(scalep(880, 576-27))
    local infoMenu = CCMenu:create()
    infoMenu:setPosition(0, 0)
    layer:addChild(infoMenu)
    infoMenu:addChild(infoBtn)
    infoBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer:addChild(require("ui.help").create(i18n.global.summon_rate_des.string, i18n.global.casino_item_rate.string), 1000)
    end)

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

    autoLayoutShift(infoBtn)
    autoLayoutShift(detailBtn)

    -- backBtn
    local back = img.createUISprite(img.ui.back)
    local backBtn = HHMenuItem:create(back)
    backBtn:setScale(view.minScale)
    backBtn:setPosition(scalep(35, 546))
    local backMenu = CCMenu:createWithItem(backBtn)
    backMenu:setPosition(0, 0)
    layer:addChild(backMenu)
    layer.back = backBtn

    autoLayoutShift(backBtn)
    
    local function backEvent()
        audio.play(audio.button)
        if uiParams and uiParams.from_layer == "task" then
            replaceScene(require("ui.town.main").create({from_layer="task"}))  
        else
            replaceScene(require("ui.town.main").create())  
        end
    end
    
    backBtn:registerScriptTapHandler(function()
        backEvent()
    end)
    
    -- power bar
    local powerBar = img.createUISprite(img.ui.summon_power_gauge)
    powerBar:setScale(view.minScale)
    powerBar:setPosition(scalep(480, 576-30))
    layer:addChild(powerBar)

    autoLayoutShift(powerBar)

    -- gem icon
    local icon_gem = img.createItemIcon2(ITEM_ID_GEM)
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

    local function updateLabels()
        local gemnum = bag.gem()
        if lbl_gem.num ~= gemnum then
            lbl_gem:setString(gemnum)
            lbl_gem.num = gemnum
        end
    end

    local helmet0 = img.createUISprite(img.ui.summon_helmet0)
    local helmetBtn0 = SpineMenuItem:create(json.ui.button, helmet0)    
    helmetBtn0:setPosition(CCPoint(504, powerBar:getContentSize().height/2+5))
    local helmetMenu = CCMenu:create()
    helmetMenu:setPosition(0, 0)
    powerBar:addChild(helmetMenu, 1101)
    helmetMenu:addChild(helmetBtn0)

    helmetBtn0:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer:addChild(require("ui.help").create(i18n.global.summon_help_enegy.string), 1000)
        --showToast(i18n.global.summon_help_enegy.string)
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
    local helmetMenu = CCMenu:create()
    helmetMenu:setPosition(0, 0)
    powerBar:addChild(helmetMenu, 1101)
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

        local item = bag.items.find(ITEM_ID_ENERGY)
        local summonItemCount = 0
        if item then
            summonItemCount = item.num
        end

        local params = {}
        params.sid = player.sid
        params.type = 10

        addWaitNet()
        net:gacha(params, function(__data)
            delWaitNet()
            tbl2string(__data)

            bag.items.sub({id = ITEM_ID_ENERGY, num = 1000}) --从背包中扣掉
            currentPower = currentPower - 1000
            progressStr = string.format("%d/%d", currentPower, requiredPower)
            progressLabel:setString(progressStr)
            powerProgress:setPercentage(currentPower/requiredPower*100)   
            if currentPower < 1000 then
                aniSummonnenglcao:setVisible(false)
                helmetBtn0:setVisible(true)
                helmetBtn:setVisible(false)
            end
            ui.actHeroSummon10(__data.heroes)
            replaceScene(require("ui.summon.info").createInfo(__data.heroes, 10, uiParams))
            heros.addAll(__data.heroes)
            ui.checkGiftLimit(__data.heroes)
        end)
    end)


    local titleLable = {
        i18n.global.summon_title_basic.string,
        i18n.global.summon_title_hero.string,
        i18n.global.summon_title_friend.string,
    }

    local titleColor = {
        ccc3(0xbd, 0xe4, 0xff),
        ccc3(0xff, 0xe4, 0x7d),
        ccc3(0xeb, 0xd4, 0xe7)
    }

    local infoLayer = CCLayer:create()
    aniSummon:addChildFollowSlot("code_weizhi", infoLayer) 
    local summonPos = {183, 480, 778, 183, 778}

    local summonBtn = {}
    local tensummonBtn = {}
    local summonFree = {}
    local summonTime = {}

    --item count
    local itemBg1 = img.createUI9Sprite(img.ui.summon_blue_bg)
    itemBg1:setPreferredSize(CCSizeMake(146, 30))
    itemBg1:setPosition(CCPoint(summonPos[1], 576-332))
    infoLayer:addChild(itemBg1)
    local item1 = img.createUISprite(img.ui.summon_item1)
    item1:setPosition(CCPoint(10, itemBg1:getContentSize().height/2))
    itemBg1:addChild(item1)
    local itemcount1 = bag.items.find(ITEM_ID_GACHA) 
    local itemLabel1 = lbl.createFont2(16, itemcount1.num, ccc3(255, 246, 223))
    itemLabel1:setPosition(CCPoint(itemBg1:getContentSize().width/2,
                                    itemBg1:getContentSize().height/2))
    itemBg1:addChild(itemLabel1)

    local itemBg2 = img.createUI9Sprite(img.ui.summon_red_bg)
    itemBg2:setPreferredSize(CCSizeMake(146, 30))
    itemBg2:setPosition(CCPoint(summonPos[2], 576-320))
    infoLayer:addChild(itemBg2)
    local item2 = img.createUISprite(img.ui.summon_item2)
    item2:setPosition(CCPoint(10, itemBg2:getContentSize().height/2))
    itemBg2:addChild(item2)
    local itemcount2 = bag.items.find(ITEM_ID_SUPERGACHA) 
    local itemLabel2 = lbl.createFont2(16, itemcount2.num, ccc3(255, 246, 223))
    itemLabel2:setPosition(CCPoint(itemBg2:getContentSize().width/2,
                                    itemBg2:getContentSize().height/2))
    itemBg2:addChild(itemLabel2)

    local itemBg3 = img.createUI9Sprite(img.ui.summon_purple_bg)
    itemBg3:setPreferredSize(CCSizeMake(146, 30))
    itemBg3:setPosition(CCPoint(summonPos[3], 576-332))
    infoLayer:addChild(itemBg3)
    local item3 = img.createItemIcon2(ITEM_ID_LOVE)
    item3:setScale(0.9)
    item3:setPosition(CCPoint(10, itemBg3:getContentSize().height/2))
    itemBg3:addChild(item3)
    local itemcount3 = bag.items.find(ITEM_ID_LOVE) 
    local itemLabel3 = lbl.createFont2(16, itemcount3.num, ccc3(255, 246, 223))
    itemLabel3:setPosition(CCPoint(itemBg3:getContentSize().width/2,
                                    itemBg3:getContentSize().height/2))
    itemBg3:addChild(itemLabel3)

    for i=1,5 do 
        -- summon title
        local title 
        if i == 2 then
            title = lbl.createFont2(20, titleLable[i], titleColor[i])
            title:setPosition(CCPoint(summonPos[i], 576-275))
        else
            title = lbl.create({
                font = 2, size = 20, text = titleLable[i], color = titleColor[i],
                us = { size = 16 }, fr = { size = 14}, es = { size = 16 }, pt = { size = 16 } 
            })
            title:setPosition(CCPoint(summonPos[i], 576-280))
        end
        infoLayer:addChild(title)
    
        -- 单抽 
        local summon1 = img.createLogin9Sprite(img.login.button_9_small_gold)
        --if i == 2 then
            summon1:setPreferredSize(CCSize(174, 58))
        --else
            --summon1:setPreferredSize(CCSize(146, 50))
        --end
        summonBtn[i] = SpineMenuItem:create(json.ui.button, summon1)
        local summonSize1 = summon1:getContentSize()
        summonBtn[i]:setPosition(CCPoint(summonPos[i], 576-416))


        local summonText1 = i18n.global.summon_buy.string
        summonBtn[i].summonLabel1 = lbl.createFont1(16, summonText1, ccc3(0x73, 0x3b, 0x05))
        summonBtn[i].summonLabel1:setPosition(summonSize1.width*3/5, summonSize1.height/2)
        if i == 5 then
            frdIcon = img.createItemIcon2(ITEM_ID_LOVE)
            frdIcon:setScale(0.9)
            frdIcon:setPosition(CCPoint(30, summon1:getContentSize().height/2+2))
            summon1:addChild(frdIcon)
            
            local frdcountLable = lbl.createFont2(16, 100, ccc3(255, 246, 223))
            frdcountLable:setPosition(CCPoint(frdIcon:getContentSize().width/2, 5))
            frdIcon:addChild(frdcountLable) 

            summonBtn[i]:setPosition(CCPoint(summonPos[i], 576-486))
            summonBtn[i].summonLabel1:setVisible(true)
        elseif i == 4 then
            summonBtn[i].itemIcon = img.createUISprite(img.ui.summon_item1)
            summonBtn[i].itemIcon:setScale(0.9)
            summonBtn[i].itemIcon:setPosition(CCPoint(30, summon1:getContentSize().height/2+2))
            --summonBtn[i].itemIcon:setVisible(false)
            summon1:addChild(summonBtn[i].itemIcon)
            local itemcountLable = lbl.createFont2(16, 10, ccc3(255, 246, 223))
            itemcountLable:setPosition(CCPoint(summonBtn[i].itemIcon:getContentSize().width/2, 5))
            summonBtn[i]:setPosition(CCPoint(summonPos[i], 576-486))
            summonBtn[i].itemIcon:addChild(itemcountLable)
            summonBtn[i].itemcountLable = itemcountLable
        elseif i == 3 then
            frdIcon = img.createItemIcon2(ITEM_ID_LOVE)
            frdIcon:setScale(0.9)
            frdIcon:setPosition(CCPoint(30, summon1:getContentSize().height/2+2))
            summon1:addChild(frdIcon)
            
            local frdcountLable = lbl.createFont2(16, 10, ccc3(255, 246, 223))
            frdcountLable:setPosition(CCPoint(frdIcon:getContentSize().width/2, 5))
            frdIcon:addChild(frdcountLable) 
            
            summonBtn[i].summonLabel1:setVisible(true)
        elseif i == 1 then
            summonBtn[i].itemIcon = img.createUISprite(img.ui.summon_item1)
            summonBtn[i].itemIcon:setScale(0.9)
            summonBtn[i].itemIcon:setPosition(CCPoint(30, summon1:getContentSize().height/2+2))
            summonBtn[i].itemIcon:setVisible(false)
            summon1:addChild(summonBtn[i].itemIcon)
            local itemcountLable = lbl.createFont2(16, 1, ccc3(255, 246, 223))
            itemcountLable:setPosition(CCPoint(summonBtn[i].itemIcon:getContentSize().width/2, 5))
            summonBtn[i].itemIcon:addChild(itemcountLable)
            summonBtn[i].itemcountLable = itemcountLable
        else
            summonBtn[i].summonLabel1:setVisible(false)
        end
        summon1:addChild(summonBtn[i].summonLabel1)
       
        if i == 2 then
            summonBtn[i].itemIcon = img.createUISprite(img.ui.summon_item2)
            summonBtn[i].itemIcon:setScale(0.9)
            summonBtn[i].itemIcon:setPosition(CCPoint(30, summon1:getContentSize().height/2+2))
            summonBtn[i].itemIcon:setVisible(false) 
            summon1:addChild(summonBtn[i].itemIcon)
            local itemcountLable1 = lbl.createFont2(16, 1, ccc3(255, 246, 223))
            itemcountLable1:setPosition(CCPoint(summonBtn[i].itemIcon:getContentSize().width/2, 5))
            summonBtn[i].itemIcon:addChild(itemcountLable1)

            local summonDiamond = img.createItemIcon2(ITEM_ID_GEM)
            summonDiamond:setScale(0.9)
            summonDiamond:setPosition(CCPoint(30, summon1:getContentSize().height/2+2))
            summon1:addChild(summonDiamond)
            summonBtn[i].summonDiamond = summonDiamond
            summonBtn[i].summonDiamond:setVisible(false)
            local summonPriceText1 = SUPERSUMMON
            local summonPrice1 = lbl.createFont2(16, summonPriceText1, ccc3(255, 246, 223))
            summonPrice1:setPosition(CCPoint(summonDiamond:getContentSize().width/2, 5))
            summonDiamond:addChild(summonPrice1)
            summonBtn[i].summonPrice1 = summonPrice1

            summonBtn[i]:setPosition(CCPoint(summonPos[i], 576-416))
            -- 十连抽
            local tensummon1 = img.createLogin9Sprite(img.login.button_9_small_gold)
            tensummon1:setPreferredSize(CCSize(174, 58))
            tensummonBtn[i] = SpineMenuItem:create(json.ui.button, tensummon1)
            local tensummonSize1 = tensummon1:getContentSize()
            --tensummonBtn[i]:setScale(view.minScale)
            tensummonBtn[i]:setPosition(CCPoint(summonPos[i], 576-486))
            local tensummonText1 = i18n.global.summon_buy10.string
            local tensummonLabel1 = lbl.createFont1(16, tensummonText1, ccc3(0x73, 0x3b, 0x05))
            tensummonLabel1:setPosition(tensummonSize1.width*3/5, tensummonSize1.height/2)
            tensummon1:addChild(tensummonLabel1)
        
            tensummonBtn[i].itemIcon = img.createUISprite(img.ui.summon_item2)
            tensummonBtn[i].itemIcon:setScale(0.9)
            tensummonBtn[i].itemIcon:setPosition(CCPoint(30, tensummon1:getContentSize().height/2+2))
            tensummon1:addChild(tensummonBtn[i].itemIcon)
            local itemcountLable = lbl.createFont2(16, 10, ccc3(255, 246, 223))
            itemcountLable:setPosition(CCPoint(tensummonBtn[i].itemIcon:getContentSize().width/2, 5))
            tensummonBtn[i].itemIcon:addChild(itemcountLable)
            
            tensummonBtn[i].gemIcon = img.createItemIcon2(ITEM_ID_GEM)
            tensummonBtn[i].gemIcon:setScale(0.9)
            tensummonBtn[i].gemIcon:setPosition(CCPoint(30, tensummon1:getContentSize().height/2+2))
            tensummonBtn[i].gemIcon:setVisible(false)
            tensummon1:addChild(tensummonBtn[i].gemIcon)
            
            local gemcountLable = lbl.createFont2(16, TENSUMMON, ccc3(255, 246, 223))
            gemcountLable:setPosition(CCPoint(tensummonBtn[i].gemIcon:getContentSize().width/2, 5))
            tensummonBtn[i].gemIcon:addChild(gemcountLable) 

        end

        --免费状态
        if i < 3 then
            local summonPriceText3 = i18n.global.summon_free.string
            summonFree[i] = lbl.createFont1(18, summonPriceText3, ccc3(0x73, 0x3b, 0x05)) summonFree[i]:setPosition(CCPoint(summon1:getContentSize().width/2, summon1:getContentSize().height/2))
            summon1:addChild(summonFree[i])
            summonFree[i]:setVisible(false)
        end
        --付费状态
        summonTime[i] = CCLayer:create()
        summonTime[i]:setPosition(0,0)
        infoLayer:addChild(summonTime[i])

        if i == 1 then
            summonTime[i].time = math.max(0, gacha.item - os.time())
            local item = bag.items.find(ITEM_ID_GACHA)
            local summonItemCount = 0
            if item then
                summonItemCount = item.num
            end
            
            local countTimeInfoStr =  string.format("%02d:%02d:%02d",math.floor(summonTime[i].time/3600),math.floor((summonTime[i].time%3600)/60),math.floor(summonTime[i].time%60))            
            local summonItemInfoStr = summonItemCount

            local countTimeInfo = lbl.createFont2(16, countTimeInfoStr, ccc3(0xa5,0xfd,0x47))
            countTimeInfo:setAnchorPoint(1, 0.5)
            summonTime[i].view1 = countTimeInfo
            
            local textPre = lbl.createFont2(16, i18n.global.summon_tofree.string, ccc3(255, 246, 223))
            textPre:setAnchorPoint(0, 0.5)

            local timeWid = 8 + countTimeInfo:boundingBox().size.width + textPre:boundingBox().size.width
            local timeSpr = CCSprite:create()
            timeSpr:setContentSize(CCSizeMake(timeWid, textPre:getContentSize().height))
            timeSpr:setPosition(summonPos[i], 576-370)
            summonTime[i]:addChild(timeSpr)

            textPre:setPosition(0, timeSpr:getContentSize().height/2)
            countTimeInfo:setPosition(timeSpr:getContentSize().width,
                                        timeSpr:getContentSize().height/2)
            timeSpr:addChild(textPre)
            timeSpr:addChild(countTimeInfo)

            summonTime[i]:setVisible(false)
        elseif i == 2 then
            summonTime[i].time = math.max(0, gacha.gem - os.time())

            local item = bag.items.find(ITEM_ID_SUPERGACHA)
            local summonItemCount = 0
            if item then
                summonItemCount = item.num
            end

            local countTimeInfoStr =  string.format("%02d:%02d:%02d",math.floor(summonTime[i].time/3600),math.floor((summonTime[i].time%3600)/60),math.floor(summonTime[i].time%60))            
            local summonItemInfoStr = summonItemCount
            
            local countTimeInfo = lbl.createFont2(16, countTimeInfoStr, ccc3(0xa5,0xfd,0x47))
            countTimeInfo:setAnchorPoint(ccp(1,0.5))
            summonTime[i].view1 = countTimeInfo
            
            local textPre = lbl.createFont2(16, i18n.global.summon_tofree.string, ccc3(255, 246, 223))
            textPre:setAnchorPoint(ccp(0,0.5))

            local timeWid = 8 + countTimeInfo:boundingBox().size.width + textPre:boundingBox().size.width
            local timeSpr = CCSprite:create()
            timeSpr:setContentSize(CCSizeMake(timeWid, textPre:getContentSize().height))
            timeSpr:setPosition(summonPos[i], 576-370)
            summonTime[i]:addChild(timeSpr)

            textPre:setPosition(0, timeSpr:getContentSize().height/2)
            countTimeInfo:setPosition(timeSpr:getContentSize().width,
                                        timeSpr:getContentSize().height/2)
            timeSpr:addChild(textPre)
            timeSpr:addChild(countTimeInfo)

            if summonItemCount > 0 then
                summonBtn[i].summonDiamond:setVisible(false)
                summonBtn[i].summonPrice1:setVisible(false)
            else
                summonBtn[i].summonDiamond:setVisible(true)
                summonBtn[i].summonDiamond:setVisible(true)
            end
            summonTime[i]:setVisible(false)
        end
    end
    local function onUpdate()
        updateLabels()
        if itemcount2.num >= 10 then
            tensummonBtn[2].itemIcon:setVisible(true)
            tensummonBtn[2].gemIcon:setVisible(false)
        else
            tensummonBtn[2].itemIcon:setVisible(false)
            tensummonBtn[2].gemIcon:setVisible(true)
        end

        summonTime[1].time = math.max(0, gacha.item - os.time())
        summonTime[2].time = math.max(0, gacha.gem - os.time())
        for i=1,2 do
            if summonTime[i].time > 0 then
                summonTime[i]:setVisible(true)
                summonFree[i]:setVisible(false)
                summonBtn[i].summonLabel1:setVisible(true)
                local countTimeInfoStr = string.format("%02d:%02d:%02d",math.floor(summonTime[i].time/3600),math.floor((summonTime[i].time%3600)/60),math.floor(summonTime[i].time%60))
                summonTime[i].view1:setString(countTimeInfoStr)
                if i == 1 then
                    summonBtn[i].itemIcon:setVisible(true)
                    summonBtn[i].itemcountLable:setString(1)
                else
                    if itemcount2.num >= 1 then
                        summonBtn[2].itemIcon:setVisible(true)
                        summonBtn[2].summonDiamond:setVisible(false)
                    else
                        summonBtn[2].itemIcon:setVisible(false)
                        summonBtn[2].summonDiamond:setVisible(true)
                    end
                end
            else
                summonBtn[i].itemIcon:setVisible(false)
                if i == 2 then
                    summonBtn[2].summonDiamond:setVisible(false)
                end
                summonTime[i]:setVisible(false)
                summonFree[i]:setVisible(true)
                summonBtn[i].summonLabel1:setVisible(false)
            end
        end
    end

    local summonMenu = CCMenu:create()
    summonMenu:ignoreAnchorPointForPosition(false)
    infoLayer:addChild(summonMenu)
    summonMenu:addChild(summonBtn[1])
    summonMenu:addChild(summonBtn[2])
    summonMenu:addChild(summonBtn[3])
    summonMenu:addChild(summonBtn[4])
    summonMenu:addChild(summonBtn[5])
    summonMenu:addChild(tensummonBtn[2])

    --普通抽
    summonBtn[1]:registerScriptTapHandler(function()
        audio.play(audio.button)
        if #heros + 1 > cfgvip[player.vipLv()].heroes + player.buy_hlimit*5 then
            local gotoHeroDlg= require "ui.summon.tipsdialog"
            gotoHeroDlg.show(layer)
            --showToast(i18n.global.summon_hero_full.string)
            return
        end

        local item = bag.items.find(ITEM_ID_GACHA)
        local summonItemCount = 0
        if item then
            summonItemCount = item.num
        end
        
        local params = {}
        params.sid = player.sid
        params.type = 1

        local paramsItem
        if summonTime[1].time > 0 then
            params.type = 2
            if summonItemCount <= 0 then
                showToast(i18n.global.summon_basic_lack.string)
                return 
            else
                paramsItem = { id = ITEM_ID_GACHA , num = 1}
            end
        end

        addWaitNet()
        net:gacha(params, function(__data)
            delWaitNet()
            tbl2string(__data)
            if __data.status ~= 0 then
                showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                return
            end
            if params.type == 1 then
                gacha.item = os.time() + NORMALSUMMONTIME 
            else
                bag.items.sub({id = ITEM_ID_GACHA, num = paramsItem.num}) --从背包中扣掉
                summonItemCount = summonItemCount - paramsItem.num
                local summonItemInfoStr = summonItemCount
                itemLabel1:setString(summonItemInfoStr)
            end
            ui.actHeroSummon10(__data.heroes)
            local task = require "data.task"
            task.increment(task.TaskType.BASIC_SUMMON)

            if cfghero[__data.heroes[1].id].maxStar == 5 then
                achieveData.add(ACHIEVE_TYPE_COMMONSUMMONFIVE, 1) 
            end

            heros.addAll(__data.heroes)
            replaceScene(require("ui.summon.info").createInfo(__data.heroes, params.type, uiParams))
        end)
    end)
    -- 高级召唤单抽
    summonBtn[2]:registerScriptTapHandler(function() 
        audio.play(audio.button)
        local params = {}
        params.sid = player.sid
        params.type = 4
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
        if summonTime[2].time > 0 then
            params.type = 6
            if summonItemCount > 0 then                
                params.type = 5
                paramsItem = { id = ITEM_ID_SUPERGACHA , num = 1}
            elseif bag.gem() < SUPERSUMMON then
                showToast(i18n.global.summon_gem_lack.string)
                return
            end
        end

        addWaitNet()
        net:gacha(params, function(__data)
            delWaitNet()
            tbl2string(__data)
            if __data.status ~= 0 then
                showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                return
            end
            if params.type == 4 then
                gacha.gem = os.time() + SUPERSUMMONTIME
            elseif params.type == 5 then
                bag.items.sub({id = ITEM_ID_SUPERGACHA, num = paramsItem.num})
                summonItemCount = summonItemCount - paramsItem.num
                local summonItemInfoStr = summonItemCount
                itemLabel2:setString(summonItemInfoStr)
            else
                bag.subGem(SUPERSUMMON)
            end
            if summonItemCount > 0 then
                summonBtn[2].summonDiamond:setVisible(false) 
                summonBtn[2].summonPrice1:setVisible(false)
            else
                summonBtn[2].summonDiamond:setVisible(true)
                summonBtn[2].summonPrice1:setVisible(true)
            end
            ui.actHeroSummon10(__data.heroes)
            bag.items.add({id = ITEM_ID_ENERGY, num = 10})
            replaceScene(require("ui.summon.info").createInfo(__data.heroes, params.type, uiParams))
            heros.addAll(__data.heroes)
            ui.checkGiftLimit(__data.heroes)

            local activity = require "data.activity"
            activity.addScore(activity.IDS.SCORE_SUMMON.ID, 1)

            achieveData.add(ACHIEVE_TYPE_HIGHSUMMON, 1) 

            local task = require "data.task"
            task.increment(task.TaskType.SENIOR_SUMMON)
        end)       
    end)
	
	local function actualGemSummon(params)
		addWaitNet()
        net:gacha(params, function(__data)
            delWaitNet()
            tbl2string(__data)
            
            if __data.status ~= 0 then
                showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                return
            end
            if params.type ~= 7 then
                bag.subGem(TENSUMMON)
            end
            
            ui.actHeroSummon10(__data.heroes)
            bag.items.add({id = ITEM_ID_ENERGY, num = 100})
            replaceScene(require("ui.summon.info").createInfo(__data.heroes, params.type, uiParams))
            heros.addAll(__data.heroes)
            ui.checkGiftLimit(__data.heroes)

            local activity = require "data.activity"
            activity.addScore(activity.IDS.SCORE_SUMMON.ID, 10)

            achieveData.add(ACHIEVE_TYPE_HIGHSUMMON, 10) 

            local task = require "data.task"
            task.increment(task.TaskType.SENIOR_SUMMON, 10)
        end)
	end

    -- 高级十连抽
    tensummonBtn[2]:registerScriptTapHandler(function()
        audio.play(audio.button)
        if #heros + 10 > cfgvip[player.vipLv()].heroes + player.buy_hlimit*5 then
            local gotoHeroDlg= require "ui.summon.tipsdialog"
            gotoHeroDlg.show(layer)
            return
        end
        
        local params = {}
        params.sid = player.sid
        params.type = 8

        local item = bag.items.find(ITEM_ID_SUPERGACHA) 
        local summonItemCount = 0
        if item then
            summonItemCount = item.num
        end
        local paramsItem
        if summonItemCount >= 10 then                
            params.type = 7
            paramsItem = { id = ITEM_ID_SUPERGACHA , num = 10}
        elseif bag.gem() < TENSUMMON then
            showToast(i18n.global.summon_gem_lack.string)
            return
		else
			local function caller()
				actualGemSummon(params)
			end
			layer:addChild(require("ui.custom").createSurebuy(caller), 1000)
			return
        end

        addWaitNet()
        net:gacha(params, function(__data)
            delWaitNet()
            tbl2string(__data)
            
            if __data.status ~= 0 then
                showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                return
            end
            if params.type == 7 then
                bag.items.sub({id = ITEM_ID_SUPERGACHA, num = paramsItem.num})
                summonItemCount = summonItemCount - paramsItem.num
                local summonItemInfoStr = summonItemCount
                itemLabel2:setString(summonItemInfoStr)
            else
                bag.subGem(TENSUMMON)
            end
            
            ui.actHeroSummon10(__data.heroes)
            bag.items.add({id = ITEM_ID_ENERGY, num = 100})
            replaceScene(require("ui.summon.info").createInfo(__data.heroes, params.type, uiParams))
            heros.addAll(__data.heroes)
            ui.checkGiftLimit(__data.heroes)

            local activity = require "data.activity"
            activity.addScore(activity.IDS.SCORE_SUMMON.ID, 10)

            achieveData.add(ACHIEVE_TYPE_HIGHSUMMON, 10) 

            local task = require "data.task"
            task.increment(task.TaskType.SENIOR_SUMMON, 10)
        end)
    end)

    -- 好友抽
    summonBtn[3]:registerScriptTapHandler(function()
        audio.play(audio.button)

        local item = bag.items.find(12)
        local summonItemCount = 0
        if item then
            summonItemCount = item.num
        end
        if item.num < 10 then
            showToast(i18n.global.summon_love_lack.string)
            return
        end
        if #heros + 1 > cfgvip[player.vipLv()].heroes + player.buy_hlimit*5 then
            --showToast(i18n.global.summon_hero_full.string)
            local gotoHeroDlg= require "ui.summon.tipsdialog"
            gotoHeroDlg.show(layer)
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
            ui.actHeroSummon10(__data.heroes)
            bag.items.sub({id = ITEM_ID_LOVE, num = 10})
            summonItemCount = summonItemCount - 10
            itemLabel3:setString(summonItemCount)
            replaceScene(require("ui.summon.info").createInfo(__data.heroes, 9, uiParams))
            heros.addAll(__data.heroes)
            ui.checkGiftLimit(__data.heroes)

            if cfghero[__data.heroes[1].id].maxStar == 5 then
                achieveData.add(ACHIEVE_TYPE_LOVESUMMONFIVE, 1) 
            end
        end)
    end)

    -- 普通十连
    summonBtn[4]:registerScriptTapHandler(function()
        audio.play(audio.button)
        if #heros + 10 > cfgvip[player.vipLv()].heroes + player.buy_hlimit*5 then
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

            bag.items.sub({id = ITEM_ID_GACHA, num = paramsItem.num}) --从背包中扣掉
            summonItemCount = summonItemCount - paramsItem.num
            local summonItemInfoStr = summonItemCount
            itemLabel1:setString(summonItemInfoStr)

            ui.actHeroSummon10(__data.heroes)
            local task = require "data.task"
            task.increment(task.TaskType.BASIC_SUMMON)

            for ii=1,#__data.heroes do
                if cfghero[__data.heroes[ii].id].maxStar == 5 then
                    achieveData.add(ACHIEVE_TYPE_COMMONSUMMONFIVE, 1) 
                end
            end

            heros.addAll(__data.heroes)
            replaceScene(require("ui.summon.info").createInfo(__data.heroes, params.type, uiParams))
        end)
    end)

    -- 好友十连
    summonBtn[5]:registerScriptTapHandler(function()
        audio.play(audio.button)
        if #heros + 10 > cfgvip[player.vipLv()].heroes + player.buy_hlimit*5 then
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
            ui.actHeroSummon10(__data.heroes)
            bag.items.sub({id = ITEM_ID_LOVE, num = 100})
            summonItemCount = summonItemCount - 100
            itemLabel3:setString(summonItemCount)
            replaceScene(require("ui.summon.info").createInfo(__data.heroes, 16, uiParams))
            heros.addAll(__data.heroes)
            ui.checkGiftLimit(__data.heroes)

            for ii=1,#__data.heroes do
                if cfghero[__data.heroes[ii].id].maxStar == 5 then
                    achieveData.add(ACHIEVE_TYPE_LOVESUMMONFIVE, 1) 
                end
            end
        end)
    end)

    layer:scheduleUpdateWithPriorityLua(onUpdate,0)

    addBackEvent(layer)
    function layer.onAndroidBack()
        backEvent()
    end
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
        elseif event == "cleanup" then
            img.unload(img.packedOthers.spine_ui_hanjingta_1)
        end
    end)

    require("ui.tutorial").show("ui.summon.main", layer)

    return layer
end

return ui
