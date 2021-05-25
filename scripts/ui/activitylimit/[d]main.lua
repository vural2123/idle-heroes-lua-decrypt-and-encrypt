local ui = {}

require "common.func"
local view = require "common.view"
local i18n = require "res.i18n"
local lbl = require "res.lbl"
local img = require "res.img"
local json = require "res.json"
local audio = require "res.audio"
local player = require "data.player"
local activityData = require "data.activity"
local activitylimitData = require "data.activitylimit"
local cfglimitgift = require "config.limitgift"
local shopData = require "data.shop"
local NetClient = require "net.netClient"
local netClient = NetClient:getInstance()

local IDS = activityData.IDS
local LIMITIDS = activitylimitData.IDS

local function refreshSelf(layerObj)
    local parent_obj = layerObj:getParent()
    layerObj:removeFromParentAndCleanup(true)
    --local activityListlayer = require "uilayer.activityListlayer"
    --parent_obj:addChild(activityListlayer.create(), 1000)
end

local function getItems()
    return {
        [IDS.FIRST_PAY.ID] = {
            id = IDS.FIRST_PAY.ID,
            group = IDS.FIRST_PAY.ID,               -- group 用于标识一组相同UI的活动，值为第一个活动ID
            name = "FIRST_PAY",
            icon = img.ui.limit_first_icon,
            --description = "activity_list_first_pay",
            description = i18n.global.limitactivity_limitgift.string,
            tapFunc = function(parent_obj)
                parent_obj:removeAllChildrenWithCleanup(true)
                parent_obj:runAction(CCCallFunc:create(function()
                    local firstpayrewardlayer = require "ui.firstpay.main"
                    local pop = firstpayrewardlayer.create()
                    pop:setTouchEnabled(true)
                    pop:setTouchSwallowEnabled(false)
                    parent_obj:addChild(pop, 1000)
                end))
            end,
        },
        [LIMITIDS.GRADE_24.ID] = {
            id = LIMITIDS.GRADE_24.ID,
            group = LIMITIDS.GRADE_24.ID,               -- group 用于标识一组相同UI的活动，值为第一个活动ID
            name = "GRADE_24",
            icon = img.ui.limit_grade_icon,
            description = i18n.global.limitactivity_limitgift.string,
            tapFunc = function(parent_obj)
                parent_obj:removeAllChildrenWithCleanup(true)
                parent_obj:runAction(CCCallFunc:create(function()
                    local gradelayer = require "ui.activitylimit.grade"
                    local pop = gradelayer.create(cfglimitgift[LIMITIDS.GRADE_24.ID].parameter, function()
                        -- claim callback
                        refreshSelf(parent_obj)
                    end)
                    pop:setTouchEnabled(true)
                    pop:setTouchSwallowEnabled(false)
                    parent_obj:addChild(pop, 1000)
                end))
            end,
        },
        [LIMITIDS.GRADE_32.ID] = {
            id = LIMITIDS.GRADE_32.ID,
            group = LIMITIDS.GRADE_32.ID,               -- group 用于标识一组相同UI的活动，值为第一个活动ID
            name = "GRADE_32",
            icon = img.ui.limit_grade_icon,
            description = i18n.global.limitactivity_limitgift.string,
            tapFunc = function(parent_obj)
                parent_obj:removeAllChildrenWithCleanup(true)
                parent_obj:runAction(CCCallFunc:create(function()
                    local gradelayer = require "ui.activitylimit.grade"
                    local pop = gradelayer.create(cfglimitgift[LIMITIDS.GRADE_32.ID].parameter, function()
                        -- claim callback
                        refreshSelf(parent_obj)
                    end)
                    pop:setTouchEnabled(true)
                    pop:setTouchSwallowEnabled(false)
                    parent_obj:addChild(pop, 1000)

                end))
            end,
        },
        [LIMITIDS.GRADE_48.ID] = {
            id = LIMITIDS.GRADE_48.ID,
            group = LIMITIDS.GRADE_48.ID,               -- group 用于标识一组相同UI的活动，值为第一个活动ID
            name = "GRADE_48",
            icon = img.ui.limit_grade_icon,
            description = i18n.global.limitactivity_limitgift.string,
            tapFunc = function(parent_obj)
                parent_obj:removeAllChildrenWithCleanup(true)
                parent_obj:runAction(CCCallFunc:create(function()
                    local gradelayer = require "ui.activitylimit.grade"
                    local pop = gradelayer.create(cfglimitgift[LIMITIDS.GRADE_48.ID].parameter, function()
                        -- claim callback
                        refreshSelf(parent_obj)
                    end)
                    pop:setTouchEnabled(true)
                    pop:setTouchSwallowEnabled(false)
                    parent_obj:addChild(pop, 1000)
                end))
            end,
        },
        [LIMITIDS.GRADE_58.ID] = {
            id = LIMITIDS.GRADE_58.ID,
            group = LIMITIDS.GRADE_58.ID,               -- group 用于标识一组相同UI的活动，值为第一个活动ID
            name = "GRADE_58",
            icon = img.ui.limit_grade_icon,
            description = i18n.global.limitactivity_limitgift.string,
            tapFunc = function(parent_obj)
                parent_obj:removeAllChildrenWithCleanup(true)
                parent_obj:runAction(CCCallFunc:create(function()
                    local gradelayer = require "ui.activitylimit.grade"
                    local pop = gradelayer.create(cfglimitgift[LIMITIDS.GRADE_58.ID].parameter, function()
                        -- claim callback
                        refreshSelf(parent_obj)
                    end)
                    pop:setTouchEnabled(true)
                    pop:setTouchSwallowEnabled(false)
                    parent_obj:addChild(pop, 1000)
                end))
            end,
        },
        [LIMITIDS.GRADE_78.ID] = {
            id = LIMITIDS.GRADE_78.ID,
            group = LIMITIDS.GRADE_78.ID,               -- group 用于标识一组相同UI的活动，值为第一个活动ID
            name = "GRADE_78",
            icon = img.ui.limit_grade_icon,
            description = i18n.global.limitactivity_limitgift.string,
            tapFunc = function(parent_obj)
                parent_obj:removeAllChildrenWithCleanup(true)
                parent_obj:runAction(CCCallFunc:create(function()
                    local gradelayer = require "ui.activitylimit.grade"
                    local pop = gradelayer.create(cfglimitgift[LIMITIDS.GRADE_78.ID].parameter, function()
                        -- claim callback
                        refreshSelf(parent_obj)
                    end)
                    pop:setTouchEnabled(true)
                    pop:setTouchSwallowEnabled(false)
                    parent_obj:addChild(pop, 1000)
                end))
            end,
        },
        [LIMITIDS.LEVEL_3_15.ID] = {
            id = LIMITIDS.LEVEL_3_15.ID,
            group = LIMITIDS.LEVEL_3_15.ID,               -- group 用于标识一组相同UI的活动，值为第一个活动ID
            name = "LEVEL_3_15",
            icon = img.ui.limit_level_icon,
            description = i18n.global.limitactivity_limitgift.string,
            tapFunc = function(parent_obj)
                parent_obj:removeAllChildrenWithCleanup(true)
                parent_obj:runAction(CCCallFunc:create(function()
                    local gradelayer = require "ui.activitylimit.level"
                    local pop = gradelayer.create(cfglimitgift[LIMITIDS.LEVEL_3_15.ID].parameter,function()
                        -- claim callback
                        refreshSelf(parent_obj)
                    end)
                    pop:setTouchEnabled(true)
                    pop:setTouchSwallowEnabled(false)
                    parent_obj:addChild(pop, 1000)
                end))
            end,
        },
        [LIMITIDS.SUMMON_4.ID] = {
            id = LIMITIDS.SUMMON_4.ID,
            group = LIMITIDS.SUMMON_4.ID,               -- group 用于标识一组相同UI的活动，值为第一个活动ID
            name = "SUMMON_4",
            icon = img.ui.limit_summon_icon,
            description = i18n.global.limitactivity_limitgift.string,
            tapFunc = function(parent_obj)
                parent_obj:removeAllChildrenWithCleanup(true)
                parent_obj:runAction(CCCallFunc:create(function()
                    local summonlayer = require "ui.activitylimit.summon"
                    local pop = summonlayer.create(cfglimitgift[LIMITIDS.SUMMON_4.ID].parameter,function()
                        -- claim callback
                        refreshSelf(parent_obj)
                    end)
                    pop:setTouchEnabled(true)
                    pop:setTouchSwallowEnabled(false)
                    parent_obj:addChild(pop, 1000)
                end))
            end,
        },
        [LIMITIDS.SUMMON_5.ID] = {
            id = LIMITIDS.SUMMON_5.ID,
            group = LIMITIDS.SUMMON_5.ID,               -- group 用于标识一组相同UI的活动，值为第一个活动ID
            name = "SUMMON_5",
            icon = img.ui.limit_summon_icon,
            description = i18n.global.limitactivity_limitgift.string,
            tapFunc = function(parent_obj)
                parent_obj:removeAllChildrenWithCleanup(true)
                parent_obj:runAction(CCCallFunc:create(function()
                    local gradelayer = require "ui.activitylimit.summon"
                    local pop = gradelayer.create(cfglimitgift[LIMITIDS.SUMMON_5.ID].parameter, function()
                        -- claim callback
                        refreshSelf(parent_obj)
                    end)
                    pop:setTouchEnabled(true)
                    pop:setTouchSwallowEnabled(false)
                    parent_obj:addChild(pop, 1000)
                end))
            end,
        },
        [IDS.SCORE_CASINO.ID] = {
            id = IDS.SCORE_CASINO.ID,
            group = IDS.SCORE_CASINO.ID,
            name = "SCORE_CASINO",
            icon = img.ui.activity_icon_casino,
            description = i18n.global.activity_des_casino.string,
            tapFunc = function(parent_obj)
                parent_obj:removeAllChildrenWithCleanup(true)
                parent_obj:runAction(CCCallFunc:create(function()
                    local scorecasinolayer = require "ui.activity.scoreCasino"
                    local pop = scorecasinolayer.create()
                    pop:setTouchEnabled(true)
                    pop:setTouchSwallowEnabled(false)
                    parent_obj:addChild(pop, 1000)
                end))
            end,
        },
        [IDS.SCORE_FIGHT.ID] = {
            id = IDS.SCORE_FIGHT.ID,
            group = IDS.SCORE_FIGHT.ID,
            icon = img.ui.activity_icon_fight,
            description = i18n.global.activity_des_fight.string,
            tapFunc = function(parent_obj)
                parent_obj:removeAllChildrenWithCleanup(true)
                --parent_obj:addChild(require("ui.activity.scoreFight").create(), 1000)
                parent_obj:runAction(CCCallFunc:create(function()
                    local scorefightlayer = require "ui.activity.scoreFight"
                    local pop = scorefightlayer.create()
                    pop:setTouchEnabled(true)
                    pop:setTouchSwallowEnabled(false)
                    parent_obj:addChild(pop, 1000)
                end))
            end,
        },
        [IDS.VP_1.ID] = {
            id = IDS.VP_1.ID,
            group = IDS.VP_1.ID,
            icon = img.ui.activity_icon_vp,
            description = i18n.global.activity_des_vp.string,
            tapFunc = function(parent_obj)
                parent_obj:removeAllChildrenWithCleanup(true)
                --parent_obj:addChild(require("ui.activity.valuePack").create(), 1000)
                parent_obj:runAction(CCCallFunc:create(function()
                    local valuepacklayer = require "ui.activity.valuePack"
                    local pop = valuepacklayer.create()
                    pop:setTouchEnabled(true)
                    pop:setTouchSwallowEnabled(false)
                    parent_obj:addChild(pop, 1000)
                end))
            end,
        },
        [IDS.BLACKBOX_1.ID] = {
            id = IDS.BLACKBOX_1.ID,
            group = IDS.BLACKBOX_1.ID,
            icon = img.ui.activity_icon_summer,
            description = i18n.global.activity_des_secbox.string,
            tapFunc = function(parent_obj)
                parent_obj:removeAllChildrenWithCleanup(true)
                --parent_obj:addChild(require("ui.activity.valuePack").create(), 1000)
                parent_obj:runAction(CCCallFunc:create(function()
                    local pplayer = require "ui.activity.blackbox"
                    local pop = pplayer.create()
                    pop:setTouchEnabled(true)
                    pop:setTouchSwallowEnabled(false)
                    parent_obj:addChild(pop, 1000)
                end))
            end,
        },
        [IDS.SCORE_TARVEN_4.ID] = {
            id = IDS.SCORE_TARVEN_4.ID,
            group = IDS.SCORE_TARVEN_4.ID,
            icon = img.ui.activity_icon_tarven,
            description = i18n.global.activity_des_tarven.string,
            tapFunc = function(parent_obj)
                parent_obj:removeAllChildrenWithCleanup(true)
                --parent_obj:addChild(require("ui.activity.scoreTarven").create(), 1000)
                parent_obj:runAction(CCCallFunc:create(function()
                    local scoretarvenlayer = require "ui.activity.scoreTarven"
                    local pop = scoretarvenlayer.create()
                    pop:setTouchEnabled(true)
                    pop:setTouchSwallowEnabled(false)
                    parent_obj:addChild(pop, 1000)
                end))
            end,
        },
        [IDS.FORGE_1.ID] = {
            id = IDS.FORGE_1.ID,
            group = IDS.FORGE_1.ID,
            icon = img.ui.activity_icon_forge,
            description = i18n.global.activity_des_forge.string,
            tapFunc = function(parent_obj)
                parent_obj:removeAllChildrenWithCleanup(true)
                parent_obj:runAction(CCCallFunc:create(function()
                    local forgelayer = require "ui.activity.forge"
                    local pop = forgelayer.create()
                    pop:setTouchEnabled(true)
                    pop:setTouchSwallowEnabled(false)
                    parent_obj:addChild(pop, 1000)
                end))
            end,
        },
        [IDS.SUMMON_HERO_1.ID] = {
            id = IDS.SUMMON_HERO_1.ID,
            group = IDS.SUMMON_HERO_1.ID,
            icon = img.ui.acticity_icon_summonmimu,
            description = i18n.global.activity_des_summon.string,
            tapFunc = function(parent_obj)
                parent_obj:removeAllChildrenWithCleanup(true)
                parent_obj:runAction(CCCallFunc:create(function()
                    local activity_summon = require "ui.activity.summon"
                    local pop = activity_summon.create()
                    pop:setTouchEnabled(true)
                    pop:setTouchSwallowEnabled(false)
                    parent_obj:addChild(pop, 1000)
                end))
            end,
        },
        [IDS.SCORE_SUMMON.ID] = {
            id = IDS.SCORE_SUMMON.ID,
            group = IDS.SCORE_SUMMON.ID,
            icon = img.ui.activity_icon_summon_score,
            description = i18n.global.activity_des_summon_score.string,
            tapFunc = function(parent_obj)
                parent_obj:removeAllChildrenWithCleanup(true)
                parent_obj:runAction(CCCallFunc:create(function()
                    local scoresummon = require "ui.activity.scoreSummon"
                    local pop = scoresummon.create()
                    pop:setTouchEnabled(true)
                    pop:setTouchSwallowEnabled(false)
                    parent_obj:addChild(pop, 1000)
                end))
            end,
        },
        [IDS.CRUSHING_SPACE_1.ID] = {
            id = IDS.CRUSHING_SPACE_1.ID,
            group = IDS.CRUSHING_SPACE_1.ID,
            icon = img.ui.activity_icon_crush1,
            description = i18n.global.broken_space_name1.string,
            tapFunc = function(parent_obj)
                parent_obj:removeAllChildrenWithCleanup(true)
                parent_obj:runAction(CCCallFunc:create(function()
                    local crushboss1 = require "ui.activity.crushboss1"
                    local pop = crushboss1.create()
                    pop:setTouchEnabled(true)
                    pop:setTouchSwallowEnabled(false)
                    parent_obj:addChild(pop, 1000)
                end))
            end,
        },
        [IDS.CRUSHING_SPACE_2.ID] = {
            id = IDS.CRUSHING_SPACE_2.ID,
            group = IDS.CRUSHING_SPACE_2.ID,
            icon = img.ui.activity_icon_crush2,
            description = i18n.global.broken_space_name2.string,
            tapFunc = function(parent_obj)
                parent_obj:removeAllChildrenWithCleanup(true)
                parent_obj:runAction(CCCallFunc:create(function()
                    local crushboss2 = require "ui.activity.crushboss2"
                    local pop = crushboss2.create()
                    pop:setTouchEnabled(true)
                    pop:setTouchSwallowEnabled(false)
                    parent_obj:addChild(pop, 1000)
                end))
            end,
        },
        [IDS.CRUSHING_SPACE_3.ID] = {
            id = IDS.CRUSHING_SPACE_3.ID,
            group = IDS.CRUSHING_SPACE_3.ID,
            icon = img.ui.activity_icon_crush3,
            description = i18n.global.broken_space_name3.string,
            tapFunc = function(parent_obj)
                parent_obj:removeAllChildrenWithCleanup(true)
                parent_obj:runAction(CCCallFunc:create(function()
                    local crushboss3 = require "ui.activity.crushboss3"
                    local pop = crushboss3.create()
                    pop:setTouchEnabled(true)
                    pop:setTouchSwallowEnabled(false)
                    parent_obj:addChild(pop, 1000)
                end))
            end,
        },
        [IDS.FISHBABY_1.ID] = {
            id = IDS.FISHBABY_1.ID,
            group = IDS.FISHBABY_1.ID,
            icon = img.ui.activity_icon_element,
            description = i18n.global.activity_des_element.string,
            tapFunc = function(parent_obj)
                parent_obj:removeAllChildrenWithCleanup(true)
                --parent_obj:addChild(require("ui.activity.fish").create(), 1000)
                parent_obj:runAction(CCCallFunc:create(function()
                    local fish = require "ui.activity.elementAltar"
                    local pop = fish.create()
                    pop:setTouchEnabled(true)
                    pop:setTouchSwallowEnabled(false)
                    parent_obj:addChild(pop, 1000)
                end))
            end,
        },
        [IDS.CHRISTMAS_1.ID] = {
            id = IDS.CHRISTMAS_1.ID,
            group = IDS.CHRISTMAS_1.ID,
            icon = img.ui.acticity_icon_anniversary,
            description = i18n.global.activity_des_anniversary.string,
            tapFunc = function(parent_obj)
                parent_obj:removeAllChildrenWithCleanup(true)
                --parent_obj:addChild(require("ui.activity.fish").create(), 1000)
                parent_obj:runAction(CCCallFunc:create(function()
                    local tinysnowman = require "ui.activity.tinysnowman"
                    local pop = tinysnowman.create()
                    pop:setTouchEnabled(true)
                    pop:setTouchSwallowEnabled(false)
                    parent_obj:addChild(pop, 1000)
                end))
            end,
        },
        [IDS.ICEBABY_1.ID] = {
            id = IDS.ICEBABY_1.ID,
            group = IDS.ICEBABY_1.ID,
            --icon = img.ui.activity_icon_tinyhome,
			icon = img.ui.limit_grade_icon,
            description = i18n.global.activity_des_cdkey.string,
            tapFunc = function(parent_obj)
                parent_obj:removeAllChildrenWithCleanup(true)
                --parent_obj:addChild(require("ui.activity.fish").create(), 1000)
                parent_obj:runAction(CCCallFunc:create(function()
                    local fish = require "ui.activity.feathershop"
                    local pop = fish.create()
                    pop:setTouchEnabled(true)
                    pop:setTouchSwallowEnabled(false)
                    parent_obj:addChild(pop, 1000)
                end))
            end,
        },
        [IDS.FOLLOW.ID] = {
            id = IDS.FOLLOW.ID,
            group = IDS.FOLLOW.ID,
            icon = img.ui.activity_icon_fb,
            description = i18n.global.follow_reward.string,
            tapFunc = function(parent_obj)
                parent_obj:removeAllChildrenWithCleanup(true)
                parent_obj:runAction(CCCallFunc:create(function()
                    local follow = require "ui.activity.follow"
                    local pop = follow.create()
                    pop:setTouchEnabled(true)
                    pop:setTouchSwallowEnabled(false)
                    parent_obj:addChild(pop, 1000)
                end))
            end,
        },
        [IDS.SCORE_SPESUMMON.ID] = {
            id = IDS.SCORE_SPESUMMON.ID,
            group = IDS.SCORE_SPESUMMON.ID,
            icon = img.ui.activity_icon_spesummon,
            description = i18n.global.activity_des_spesummon.string,
            tapFunc = function(parent_obj)
                parent_obj:removeAllChildrenWithCleanup(true)
                parent_obj:runAction(CCCallFunc:create(function()
                    local spesummon = require "ui.activity.scoreSpesummon"
                    local pop = spesummon.create()
                    pop:setTouchEnabled(true)
                    pop:setTouchSwallowEnabled(false)
                    parent_obj:addChild(pop, 1000)
                end))
            end,
        },
        [IDS.EXCHANGE.ID] = {
            id = IDS.EXCHANGE.ID,
            group = IDS.EXCHANGE.ID,
            icon = img.ui.activity_icon_exchange,
            description = i18n.global.activity_des_exchange.string,
            tapFunc = function(parent_obj)
                --parent_obj:removeAllChildrenWithCleanup(true)
                --parent_obj:addChild(require("ui.activity.exchange").create(), 1000)
                parent_obj:removeAllChildrenWithCleanup(true)
                parent_obj:runAction(CCCallFunc:create(function()
                    local exchange = require "ui.activity.exchange"
                    local pop = exchange.create()
                    pop:setTouchEnabled(true)
                    pop:setTouchSwallowEnabled(false)
                    parent_obj:addChild(pop, 1000)
                end))
            end,
        },
        [IDS.AWAKING_GLORY_1.ID] = {
            id = IDS.AWAKING_GLORY_1.ID,
            group = IDS.AWAKING_GLORY_1.ID,
            icon = img.ui.activity_icon_awaking_glory,
            description = i18n.global.activity_des_awaking_glory.string,
            tapFunc = function(parent_obj)
                parent_obj:removeAllChildrenWithCleanup(true)
                parent_obj:runAction(CCCallFunc:create(function()
                    local awakinglayer = require "ui.activity.awakingGlory"
                    local pop = awakinglayer.create()
                    pop:setTouchEnabled(true)
                    pop:setTouchSwallowEnabled(false)
                    parent_obj:addChild(pop, 1000)
                end))
            end,
        },
        [IDS.HERO_SUMMON_1.ID] = {
            id = IDS.HERO_SUMMON_1.ID,
            group = IDS.HERO_SUMMON_1.ID,
            icon = img.ui.activity_icon_hero_summon,
            description = i18n.global.activity_des_hero_summon.string,
            tapFunc = function(parent_obj)
                parent_obj:removeAllChildrenWithCleanup(true)
                parent_obj:runAction(CCCallFunc:create(function()
                    local heroSummonlayer = require "ui.activity.heroSummon"
                    local pop = heroSummonlayer.create()
                    pop:setTouchEnabled(true)
                    pop:setTouchSwallowEnabled(false)
                    parent_obj:addChild(pop, 1000)
                end))
            end,
        },
        [IDS.BLACKCARD.ID] = {
            id = IDS.BLACKCARD.ID,
            group = IDS.BLACKCARD.ID,
            icon = img.ui.acticity_icon_anniversarycard,
            description = i18n.global.activity_des_anniversarycard.string,
            tapFunc = function(parent_obj)
                parent_obj:removeAllChildrenWithCleanup(true)
                parent_obj:runAction(CCCallFunc:create(function()
                    local blackcardlayer = require "ui.activity.blackcard"
                    local pop = blackcardlayer.create()
                    pop:setTouchEnabled(true)
                    pop:setTouchSwallowEnabled(false)
                    parent_obj:addChild(pop, 1000)
                end))
            end,
        },
        [IDS.ASYLUM_1.ID] = {
            id = IDS.ASYLUM_1.ID,
            group = IDS.ASYLUM_1.ID,
            icon = img.ui.activity_icon_asylum,
            description = i18n.global.activity_asylum_title.string,
            tapFunc = function(parent_obj)
                parent_obj:removeAllChildrenWithCleanup(true)
                parent_obj:runAction(CCCallFunc:create(function()
                    local asylum = require "ui.activity.asylum"
                    local pop = asylum.create()
                    pop:setTouchEnabled(true)
                    pop:setTouchSwallowEnabled(false)
                    parent_obj:addChild(pop, 1000)
                end))
            end,
        },
        [IDS.NEWYEAR.ID] = {
            id = IDS.NEWYEAR.ID,
            group = IDS.NEWYEAR.ID,
            icon = img.ui.activity_icon_stonetablet,
            description = i18n.global.activity_des_stonefigure.string,
            tapFunc = function(parent_obj)
                parent_obj:removeAllChildrenWithCleanup(true)
                parent_obj:runAction(CCCallFunc:create(function()
                    local newyear = require "ui.activity.newyear"
                    local pop = newyear.create()
                    pop:setTouchEnabled(true)
                    pop:setTouchSwallowEnabled(false)
                    parent_obj:addChild(pop, 1000)
                end))
            end,
        },
        [IDS.WEEKYEARBOX_1.ID] = {
            id = IDS.WEEKYEARBOX_1.ID,
            group = IDS.WEEKYEARBOX_1.ID,
            icon = img.ui.acticity_icon_weekbox,
            description = i18n.global.activity_des_weekyearbox.string,
            tapFunc = function(parent_obj)
                parent_obj:removeAllChildrenWithCleanup(true)
                parent_obj:runAction(CCCallFunc:create(function()
                    local newyear = require "ui.activity.weekbox"
                    local pop = newyear.create()
                    pop:setTouchEnabled(true)
                    pop:setTouchSwallowEnabled(false)
                    parent_obj:addChild(pop, 1000)
                end))
            end,
        },
        [IDS.DWARF_1.ID] = {
            id = IDS.DWARF_1.ID,
            group = IDS.DWARF_1.ID,
            icon = img.ui.acticity_icon_dwarf,
            description = i18n.global.activity_des_dwarf.string,
            tapFunc = function(parent_obj)
                parent_obj:removeAllChildrenWithCleanup(true)
                parent_obj:runAction(CCCallFunc:create(function()
                    local dwarf = require "ui.activity.dwarf"
                    local pop = dwarf.create()
                    pop:setTouchEnabled(true)
                    pop:setTouchSwallowEnabled(false)
                    parent_obj:addChild(pop, 1000)
                end))
            end,
        },
    }
end

function ui.create(from_layer)
    local all_items = getItems()
    local activity_items = {}
    local touch_items = {}
    local item_count = 0
    local padding = 5
    local item_width = 100
    local item_height = 120

    local function init()
        local groups = {}
        for _, tmp_item in pairs(all_items) do
            if tmp_item.group == IDS.FIRST_PAY.ID or tmp_item.group == IDS.SCORE_CASINO.ID or
                tmp_item.group == IDS.VP_1.ID or tmp_item.group == IDS.SCORE_FIGHT.ID or
                tmp_item.group == IDS.SCORE_TARVEN_4.ID or tmp_item.group == IDS.FORGE_1.ID or
                tmp_item.group == IDS.SUMMON_HERO_1.ID or tmp_item.group == IDS.SCORE_SUMMON.ID or
                tmp_item.group == IDS.CRUSHING_SPACE_1.ID or tmp_item.group == IDS.CRUSHING_SPACE_2.ID or
                tmp_item.group == IDS.CRUSHING_SPACE_3.ID or tmp_item.group == IDS.FISHBABY_1.ID or
                (tmp_item.group == IDS.FOLLOW.ID and not isChannel()) or tmp_item.group == IDS.SCORE_SPESUMMON.ID or
                tmp_item.group == IDS.EXCHANGE.ID or tmp_item.group == IDS.AWAKING_GLORY_1.ID or
                tmp_item.group == IDS.HERO_SUMMON_1.ID or tmp_item.group == IDS.ICEBABY_1.ID or
                tmp_item.group == IDS.TENCHANGE.ID or tmp_item.group == IDS.BLACKCARD.ID or 
                tmp_item.group == IDS.BLACKBOX_1.ID or tmp_item.group == IDS.CHRISTMAS_1.ID or
                tmp_item.group == IDS.WEEKYEARBOX_1.ID or tmp_item.group == IDS.DWARF_1.ID or
                tmp_item.group == IDS.ASYLUM_1.ID or tmp_item.group == IDS.NEWYEAR.ID then
                if groups[tmp_item.group] then  -- 属于group组的活动，已经添加过了
                else
                    groups[tmp_item.group] = tmp_item.group
                    local item_status = activityData.getStatusById(tmp_item.id)
                    if item_status and item_status.status ~= 2  and item_status.cd and
                            item_status.cd > os.time() - activityData.pull_time then
                        item_count = item_count + 1
                        activity_items[item_count] = tmp_item
                        activity_items[item_count].status = item_status
                    elseif item_status and item_status.status ~= 2  and tmp_item.nocd then  -- 没有cd
                        item_count = item_count + 1
                        activity_items[item_count] = tmp_item
                        activity_items[item_count].status = item_status
                    else
                        print("======================================if 3")
                    end
                end
            else
                if groups[tmp_item.group] then  -- 属于group组的活动，已经添加过了
                else
                    groups[tmp_item.group] = tmp_item.group
                    local item_status = activitylimitData.getStatusById(tmp_item.id)
                    --print("item_status:", item_status, item_status.status)
                    if item_status and item_status.status == 0  and item_status.cd and
                            item_status.cd > os.time() - activityData.pull_time then
                        item_count = item_count + 1
                        activity_items[item_count] = tmp_item
                        activity_items[item_count].status = item_status
                    elseif item_status and item_status.status == 0  and tmp_item.nocd then  -- 没有cd
                        item_count = item_count + 1
                        activity_items[item_count] = tmp_item
                        activity_items[item_count].status = item_status
                    else
                        print("======================================if 3")
                    end
                end

            end
        end
        table.sort(activity_items, function(a, b)
            local ai = a.id
            local bi = b.id
            if ai == 47001 then ai = 0 end
            if bi == 47001 then bi = 0 end
            return ai < bi

        end)
    end
    init()
    local layer = CCLayer:create()

    -- dark bg
    local darkbg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY*0.8))
    layer:addChild(darkbg)

    -- money bar
    local moneybar = require "ui.moneybar"
    layer:addChild(moneybar.create(), 101)

    local content_layer = CCLayer:create()
    content_layer:setTouchEnabled(true)
    content_layer:setTouchSwallowEnabled(false)
    layer:addChild(content_layer, 100)

    local board = img.createUISprite(img.ui.activity_board)
    board:setScale(view.minScale)
    board:setAnchorPoint(CCPoint(0.5,0))
    board:setPosition(scalep(480, 0))
    layer:addChild(board)
    local board_w = board:getContentSize().width
    local board_h = board:getContentSize().height

    local function backEvent()
        layer:removeFromParent()
    end

    -- btn_close
    local btn_close0 = img.createUISprite(img.ui.close)
    local btn_close = SpineMenuItem:create(json.ui.button, btn_close0)
    btn_close:setScale(view.minScale)
    --btn_close:setPosition(CCPoint(board_w-32, board_h-74))
    btn_close:setPosition(scalep(960-32, 576-70))
    local btn_close_menu = CCMenu:createWithItem(btn_close)
    btn_close_menu:setPosition(CCPoint(0, 0))
    layer:addChild(btn_close_menu, 100)
    btn_close:registerScriptTapHandler(function()
        audio.play(audio.button)
        backEvent()
    end)

    --local bar = img.createUISprite(img.ui.limit_top)
    --bar:setAnchorPoint(CCPoint(0, 1))
    --bar:setPosition(CCPoint(48, board_h-50))
    --board:addChild(bar, 10)
    local bar_icon = img.createUISprite(img.ui.activity_bar_icon)
    bar_icon:setAnchorPoint(CCPoint(0.5, 0))
    bar_icon:setPosition(CCPoint(200, 54+430))
    board:addChild(bar_icon)
    local lbl_bar = lbl.createFont2(22, i18n.global.limitactivity_board_title.string, ccc3(0xfa, 0xd8, 0x69))
    lbl_bar:setPosition(CCPoint(200, 41+430))
    board:addChild(lbl_bar)

    local tree_icon = img.createUISprite(img.ui.activity_icon_tree)
    tree_icon:setAnchorPoint(CCPoint(0.5, 0))
    tree_icon:setPosition(CCPoint(60, 435))
    board:addChild(tree_icon)

    local sea_icon = img.createUISprite(img.ui.activity_icon_sea)
    sea_icon:setAnchorPoint(CCPoint(0.5, 1))
    sea_icon:setPosition(CCPoint(board_w/2, 95))
    board:addChild(sea_icon)
    --local scroll_bg = img.createUI9Sprite(img.ui.inner_bg)
    --scroll_bg:setPreferredSize(CCSizeMake(290, 382))
    --scroll_bg:setAnchorPoint(CCPoint(0, 0))
    --scroll_bg:setPosition(CCPoint(53, 67))
    --board:addChild(scroll_bg)

    local function createItem(item_obj)
        local tmp_item = img.createUISprite(img.ui.activity_item_bg)
        local tmp_item_w = tmp_item:getContentSize().width
        local tmp_item_h = tmp_item:getContentSize().height
        local tmp_item_sel = img.createUISprite(img.ui.activity_item_bg_sel)
        tmp_item_sel:setPosition(CCPoint(tmp_item_w/2, tmp_item_h/2))
        tmp_item:addChild(tmp_item_sel)
        tmp_item.sel = tmp_item_sel
        tmp_item_sel:setVisible(false)
        if item_obj.id == IDS.FOLLOW.ID and (APP_CHANNEL == "IAS" 
            or i18n.getCurrentLanguage() == kLanguageChinese)then
            item_obj.icon = img.ui.activity_icon_weibo 
        end
        local item_icon = img.createUISprite(item_obj.icon)
        item_icon:setPosition(CCPoint(40, tmp_item_h/2))
        tmp_item:addChild(item_icon, 1)
        local lbl_description = lbl.create({font=1, size=12, text=item_obj.description, color=ccc3(0x73, 0x3b, 0x05),
                                cn={size=16}, us={size=14}, tw={size=16}
                            })
        if item_obj.nocd then
            lbl_description:setAnchorPoint(CCPoint(0, 0.5))
            lbl_description:setPosition(CCPoint(94, tmp_item_h/2))
        else
            lbl_description:setAnchorPoint(CCPoint(0, 0))
            lbl_description:setPosition(CCPoint(94, tmp_item_h/2))
        end
        tmp_item:addChild(lbl_description, 2)
        local lbl_cd = lbl.create({font=2, size=10, text="", color=ccc3(0xb5, 0xf4, 0x3b),
                                cn={size=14}, us={size=12}, tw={size=14}
                            })
        --lbl_cd:setColor(ccc3(0xb5, 0xf4, 0x3b))
        lbl_cd:setAnchorPoint(CCPoint(0, 1))
        lbl_cd:setPosition(CCPoint(94, tmp_item_h/2-2))
        tmp_item:addChild(lbl_cd, 1)
        tmp_item.lbl_cd = lbl_cd
        addRedDot(tmp_item, {
            px = tmp_item:getContentSize().width-5,
            py = tmp_item:getContentSize().height-10,
        })
        delRedDot(tmp_item)
        return tmp_item
    end

    local lineScroll = require "ui.lineScroll"

    local scroll_params = {
        width = 290,
        height = 359,
    }

    local scroll = lineScroll.create(scroll_params)
    scroll:setAnchorPoint(CCPoint(0, 0))
    scroll:setPosition(CCPoint(53, 74))
    board:addChild(scroll)
    layer.scroll = scroll
    --drawBoundingbox(scroll_bg, scroll)

    local function showList(listObjs)
        for ii=1,#listObjs do
            if ii == 1 then
                scroll.addSpace(4)
            end
            local tmp_item = createItem(listObjs[ii])
            touch_items[#touch_items+1] = tmp_item
            tmp_item.obj = listObjs[ii]
            tmp_item.ax = 0.5
            tmp_item.px = 145
            scroll.addItem(tmp_item)
            if ii ~= item_count then
                scroll.addSpace(padding-3)
            end
        end
    end

    showList(activity_items)

    scroll.setOffsetBegin()
    
    function layer.onAndroidBack()
        backEvent()
    end

    layer:setTouchEnabled(true)
    layer:setTouchSwallowEnabled(true)
        
    addBackEvent(layer)

    local function onEnter()
        print("onEnter")
        layer.notifyParentLock()
        if item_count == 0 then
            --showToast(i18n.global.event_empty.string)
            --backEvent()
        end
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

    -- for touch
    local last_touch_sprite = nil
    local last_sel_sprite = nil
    local function clearShaderForItem(itemObj)
        if itemObj and not tolua.isnull(itemObj) then
            clearShader(itemObj, true)
            itemObj = nil
        end
    end
    local function setShaderForItem(itemObj)
        setShader(itemObj, SHADER_HIGHLIGHT, true)
        last_touch_sprite = itemObj
    end

    local touchbeginx, touchbeginy
    local isclick
    local function onTouchBegan(x, y)
        touchbeginx, touchbeginy = x, y
        isclick = true
        if not scroll or tolua.isnull(scroll) then return true end
        local p1 = scroll.content_layer:convertToNodeSpace(ccp(x, y))
        for ii=1,#touch_items do
            if touch_items[ii]:boundingBox():containsPoint(p1) then
                --playAnimTouchBegin(touch_items[ii])
                last_touch_sprite = touch_items[ii]
            end
        end
        return true
    end

    local function onTouchMoved(x, y)
        if isclick and (math.abs(touchbeginx-x) > 10 or math.abs(touchbeginy-y) > 10) then
            isclick = false
            if last_touch_sprite and not tolua.isnull(last_touch_sprite) then
                --playAnimTouchEnd(last_touch_sprite)
                last_touch_sprite = nil
            end
        end
    end

    local function onTouchEnded(x, y)
        if last_touch_sprite and not tolua.isnull(last_touch_sprite) then
            --playAnimTouchEnd(last_touch_sprite)
            last_touch_sprite = nil
        end
        local p0 = layer:convertToNodeSpace(ccp(x, y))
        if isclick and not board:boundingBox():containsPoint(p0) then
            backEvent()
        elseif isclick then
            local p1 = scroll.content_layer:convertToNodeSpace(ccp(x, y))
            for ii=1,#touch_items do
                if touch_items[ii]:boundingBox():containsPoint(p1) then
                    if last_sel_sprite and last_sel_sprite == touch_items[ii] then
                        return 
                    elseif last_sel_sprite and not tolua.isnull(last_sel_sprite) then
                        if last_sel_sprite.sel and not tolua.isnull(last_sel_sprite.sel) then
                            last_sel_sprite.sel:setVisible(false)
                        end
                    end
                    audio.play(audio.button)
                    touch_items[ii].sel:setVisible(true)
                    touch_items[ii].obj.tapFunc(content_layer)
                    last_sel_sprite = touch_items[ii]
                    -- set read
                    if touch_items[ii].obj.status then
                        touch_items[ii].obj.status.read = 1
                    end
                end
            end
        end
    end
    local function onTouch(eventType, x, y)
        if eventType == "began" then   
            return onTouchBegan(x, y)
        elseif eventType == "moved" then
            return onTouchMoved(x, y)
        else
            return onTouchEnded(x, y)
        end
    end
    layer:registerScriptTouchHandler(onTouch , false , -128 , false)

    local last_check_time = 0
    local function updateCountDown()
        if os.time() - last_check_time < 1 then return end
        last_check_time = os.time()
        for ii=1,#touch_items do
            local item_status = touch_items[ii].obj.status
            if item_status.id == IDS.FIRST_PAY.ID then
                if item_status.status ~= 2 then
                    if item_status.cd and os.time() - activityData.pull_time > item_status.cd then
                        item_status.status = 2
                        refreshSelf(layer)
                    elseif item_status.cd then
                        local count_down = item_status.cd - (os.time() - activityData.pull_time)
                        local time_str = time2string(count_down)
                        if count_down <= 2592000 then
                            touch_items[ii].lbl_cd:setString(time_str)
                        end
                    end
                end
            else
                if item_status.status == 0 then
                    if item_status.cd and os.time() - activityData.pull_time > item_status.cd then
                        item_status.status = 1
                        refreshSelf(layer)
                    elseif item_status.cd then
                        local count_down = item_status.cd - (os.time() - activityData.pull_time)
                        local time_str = time2string(count_down)
                        if count_down <= 2592000 then
                            touch_items[ii].lbl_cd:setString(time_str)
                        end
                    end
                    --if item_status.next and os.time() - activityData.pull_time > item_status.next then
                    --    item_status.status = 1
                    --    refreshSelf(layer)
                    --end
                end
            end

            -- red dot 
            local tmp_status = item_status --activityData.getStatusById(touch_items[ii].obj.id)
            if touch_items[ii].obj.redFunc then
                if touch_items[ii].obj.redFunc() then
                    addRedDot(touch_items[ii], {
                        px = touch_items[ii]:getContentSize().width-5,
                        py = touch_items[ii]:getContentSize().height-10,
                    })
                else
                    delRedDot(touch_items[ii])
                end
            elseif tmp_status and tmp_status.read and tmp_status.read == 0 then
                addRedDot(touch_items[ii], {
                    px = touch_items[ii]:getContentSize().width-5,
                    py = touch_items[ii]:getContentSize().height-10,
                })
            else
                delRedDot(touch_items[ii])
            end

        end
    end

    local function onUpdate(ticks)
        updateCountDown()
    end
    layer:scheduleUpdateWithPriorityLua(onUpdate, 0)

    local function showActivity(i)
        if touch_items[i].sel and not tolua.isnull(touch_items[i].sel) then
            touch_items[i].sel:setVisible(true)
        end
        touch_items[i].obj.tapFunc(content_layer)
        last_sel_sprite = touch_items[i]
        -- set read
        if touch_items[i].obj.status then
            touch_items[i].obj.status.read = 1
        end
    end

    -- show firt activity
    if #touch_items > 0 then
        if from_layer then
            for i=1,#touch_items do
                if from_layer == "brokenboss" and touch_items[i].obj.id == IDS.CRUSHING_SPACE_1.ID then
                    showActivity(i)
                end
            end
        else
            showActivity(1)
        end
    end

    return layer
end

return ui
