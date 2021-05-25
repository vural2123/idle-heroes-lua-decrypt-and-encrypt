local ui = {}

require "common.func"
require "common.const"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local audio = require "res.audio"
local particle = require "res.particle"
local cfgitem = require "config.item"
local cfgequip = require "config.equip"
local cfgstage = require "config.stage"
local player = require "data.player"
local bagdata = require "data.bag"
local hookdata = require "data.hook"
local i18n = require "res.i18n"
local tipsequip = require "ui.tips.equip"
local tipsitem = require "ui.tips.item"
local dialog = require "ui.dialog"
local rewards = require "ui.reward"

local TAG_CONTENT_LAYER = 1117
local last_ask = os.time()
--local ASK_INTERVAL = 60*30
local ASK_INTERVAL = 60

-- uiParams
--    .win = true  mean back from pve
--    .from_layer
function ui.create(uiParams)
    -- forward declare explicit
    local updateOutput

    local layer = CCLayer:create()

    img.load(img.packedOthers.ui_hookmap_bg1)
    local bgg = img.createUISprite(img.ui.hookmap_bg1)
    bgg:setScale(view.maxScale)
    bgg:setPosition(CCPoint(view.midX, view.midY))
    layer:addChild(bgg)
    -- dark bg
    local darkbg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY*0.6))
    layer:addChild(darkbg)

    local bg = CCSprite:create()
    bg:setContentSize(CCSizeMake(960, 576))
    bg:setScale(view.minScale)
    bg:setPosition(CCPoint(view.midX, view.midY))
    layer:addChild(bg)
    local bg_w = bg:getContentSize().width
    local bg_h = bg:getContentSize().height
    
    --back btn
    local back0 = img.createUISprite(img.ui.back)
    local backBtn = HHMenuItem:create(back0)
    backBtn:setScale(view.minScale)
    backBtn:setPosition(scalep(35, 546))
    local backMenu = CCMenu:createWithItem(backBtn)
    backMenu:setPosition(0, 0)
    layer:addChild(backMenu)
    backBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer.onAndroidBack()
    end)

    autoLayoutShift(backBtn)

    local icon_layer = CCLayer:create()
    icon_layer:setCascadeOpacityEnabled(true)
    icon_layer:setOpacity(0)
    icon_layer:setVisible(false)
    layer:addChild(icon_layer, 100)

    json.load(json.ui.hook)
    json.load(json.ui.hook_reward_01)
    json.load(json.ui.hook_reward_02)
    json.load(json.ui.hook_reward_03)
    json.load(json.ui.radar)

    local ani_hook = DHSkeletonAnimation:createWithKey(json.ui.hook)
    ani_hook:setScale(view.minScale)
    ani_hook:scheduleUpdateLua()
    ani_hook:setAnchorPoint(CCPoint(0.5, 0.5))
    ani_hook:setPosition(scalep(480, 288))
    layer:addChild(ani_hook)

    local stage_board = img.createUI9Sprite(img.ui.hook_stage_board)
    stage_board:setPreferredSize(CCSizeMake(856, 158))
    --stage_board:setAnchorPoint(CCPoint(0.5, 0))
    --stage_board:setPosition(CCPoint(bg_w/2, 16))
    --bg:addChild(stage_board)
    stage_board:setCascadeOpacityEnabled(true)
    ani_hook:addChildFollowSlot("code_down_bg", stage_board)
    local stage_board_w = stage_board:getContentSize().width
    local stage_board_h = stage_board:getContentSize().height

    local play_board = img.createUI9Sprite(img.ui.hook_play_board)
    --play_board:setPreferredSize(CCSizeMake(930, 302))
    play_board:setPreferredSize(CCSizeMake(925, 329))
    --play_board:setAnchorPoint(CCPoint(0.5, 0))
    --play_board:setPosition(CCPoint(bg_w/2, 215))
    --bg:addChild(play_board, 2)
    --play_board:setVisible(false)
    play_board:setCascadeOpacityEnabled(true)
    ani_hook:addChildFollowSlot("code_screen", play_board)
    local play_board_w = play_board:getContentSize().width
    local play_board_h = play_board:getContentSize().height

    local play_bg
    if hookdata.getHookStage() == 0 then
        play_bg = img.createHookMap(cfgstage[1].thumbnail)
    else
        play_bg = img.createHookMap(cfgstage[hookdata.getHookStage()].thumbnail)
    end
    play_bg:setPosition(CCPoint(play_board_w/2, play_board_h/2+3))
    play_board:addChild(play_bg)

    local fightAnim = require("ui.hook.fight").create()
    layer:addChild(fightAnim, 10)

    local arr_hook = CCArray:create()
    arr_hook:addObject(CCCallFunc:create(function()
        ani_hook:playAnimation("enter", 1)
    end))
    arr_hook:addObject(CCDelayTime:create(ani_hook:getAnimationTime("enter")-1.5))
    arr_hook:addObject(CCCallFunc:create(function()
        icon_layer:setVisible(true)
        icon_layer:runAction(CCFadeIn:create(1.0))
    end))
    layer:runAction(CCSequence:create(arr_hook))

    -- pole
    --local pole_left = img.createUISprite(img.ui.hook_pole)
    --pole_left:setFlipX(true)
    --pole_left:setAnchorPoint(CCPoint(0, 0))
    --pole_left:setPosition(CCPoint(-3, 197))
    --bg:addChild(pole_left)
    --local pole_right = img.createUISprite(img.ui.hook_pole)
    --pole_right:setAnchorPoint(CCPoint(1, 0))
    --pole_right:setPosition(CCPoint(bg_w+3, 197))
    --bg:addChild(pole_right)
    
    -- moneybar
    local container = CCSprite:create()
    container:setContentSize(CCSizeMake(374, 40))
    container:setScale(view.minScale)
    container:setAnchorPoint(CCPoint(0.5, 1))
    container:setPosition(CCPoint(view.midX, view.maxY-15*view.minScale))
    icon_layer:addChild(container)

    autoLayoutShift(container)

    local container_w = container:getContentSize().width
    local container_h = container:getContentSize().height
    -- coin bg
    local coin_bg = img.createUI9Sprite(img.ui.main_coin_bg)
    coin_bg:setPreferredSize(CCSizeMake(174, 40))
    coin_bg:setAnchorPoint(CCPoint(1, 0.5))
    coin_bg:setPosition(CCPoint(container_w/2-13, container_h/2))
    container:addChild(coin_bg)
    -- gem bg
    local gem_bg = img.createUI9Sprite(img.ui.main_coin_bg)
    gem_bg:setPreferredSize(CCSizeMake(174, 40))
    gem_bg:setAnchorPoint(CCPoint(0, 0.5))
    gem_bg:setPosition(CCPoint(container_w/2+13, container_h/2))
    container:addChild(gem_bg)
    -- coin icon
    local icon_coin = img.createItemIcon2(ITEM_ID_COIN)
    icon_coin:setPosition(CCPoint(5, coin_bg:getContentSize().height/2+2))
    coin_bg:addChild(icon_coin)
    -- gem icon
    local icon_gem = img.createItemIcon(ITEM_ID_HERO_EXP)
    icon_gem:setScale(0.5)
    icon_gem:setPosition(CCPoint(5, gem_bg:getContentSize().height/2+2))
    gem_bg:addChild(icon_gem)
    -- lbl coin
    local coin_num = bagdata.coin()
    local lbl_coin = lbl.createFont2(16, num2KM(coin_num), ccc3(255, 246, 223))
    lbl_coin:setPosition(CCPoint(coin_bg:getContentSize().width/2, coin_bg:getContentSize().height/2+3))
    coin_bg:addChild(lbl_coin)
    lbl_coin.num = coin_num
    -- lbl gem
    local gem_num = bagdata.items.find(ITEM_ID_HERO_EXP).num
    local lbl_gem = lbl.createFont2(16, num2KM(gem_num), ccc3(255, 246, 223))
    lbl_gem:setPosition(CCPoint(gem_bg:getContentSize().width/2, gem_bg:getContentSize().height/2+3))
    gem_bg:addChild(lbl_gem)
    lbl_gem.num = gem_num
    
    local function updateLabels()
        local coinnum = bagdata.coin()
        if lbl_coin.num ~= coinnum then
            lbl_coin:setString(num2KM(coinnum))
            lbl_coin.num = coinnum
        end
        local gemnum = bagdata.items.find(ITEM_ID_HERO_EXP).num
        if lbl_gem.num ~= gemnum then
            lbl_gem:setString(num2KM(gemnum))
            lbl_gem.num = gemnum
        end
    end

    -- bar bg
    local bar_bg = img.createUI9Sprite(img.ui.hook_bar_bg)
    bar_bg:setPreferredSize(CCSizeMake(871, 45))
    bar_bg:setScale(view.minScale)
    bar_bg:setPosition(scalep(480, 465))
    icon_layer:addChild(bar_bg)

    -- fort name
    local fortName = hookdata.getFortName()
    --if uiParams and uiParams.jump_stage then
    --    fortName = hookdata.getFortName(uiParams.jump_stage)
    --end
    local lbl_fort_name = lbl.createFont2(24, fortName, ccc3(0xff, 0xf6, 0xd8), true)
    lbl_fort_name:setAnchorPoint(CCPoint(0, 0.5))
    lbl_fort_name:setPosition(scalep(100, 465))
    icon_layer:addChild(lbl_fort_name)

    -- forward declare
    local addStageFocus
    local addRadar
    local stage_items = {}
    
    local btn_offset_x = 690
    local btn_offset_y = 540
    local btn_step_x = 78
    -- btn team
    local btn_team0 = img.createLogin9Sprite(img.login.button_9_small_gold)
    btn_team0:setPreferredSize(CCSizeMake(148, 42))
    if hookdata.checkTeamChange() then
        addRedDot(btn_team0, {
            px = btn_team0:getContentSize().width-3,
            py = btn_team0:getContentSize().height-3,
        })
    end
    local icon_team = img.createUISprite(img.ui.hook_icon_team)
    icon_team:setPosition(CCPoint(19, 21))
    btn_team0:addChild(icon_team)
    local lbl_btn_team = lbl.createFont1(16, i18n.global.hook_btn_team.string, ccc3(0x83, 0x41, 0x1d))
    lbl_btn_team:setPosition(CCPoint(btn_team0:getContentSize().width/2+10, 21))
    btn_team0:addChild(lbl_btn_team)
    local btn_team = SpineMenuItem:create(json.ui.button, btn_team0)
    btn_team:setScale(view.minScale)
    btn_team:setPosition(scalep(122, 227))
    local btn_team_menu = CCMenu:createWithItem(btn_team)
    btn_team_menu:setPosition(CCPoint(0, 0))
    icon_layer:addChild(btn_team_menu, 10)
    btn_team:registerScriptTapHandler(function()
        btn_team:setEnabled(false)
        audio.play(audio.button)
        delRedDot(btn_team0)
        layer:addChild((require"ui.hook.team").create(function(_isChange)
            if _isChange then
                fightAnim.refresh()
                return
            end
            if #stage_items > 0 and not tolua.isnull(stage_items[1]) then
                fightAnim.refresh()
                addRadar(stage_items[1])
            end
            require("data.tutorial").goNext("hook", 1, true) 
        end), 1000)
        schedule(btn_team, 1.5, function()
            btn_team:setEnabled(true)
        end)
    end)

    ---- btn bag
    --local btn_bag0 = img.createUISprite(img.ui.hook_icon_bag)
    --local lbl_btn_bag = lbl.createFont3(16, i18n.global.hook_btn_bag.string)
    --lbl_btn_bag:setPosition(CCPoint(btn_bag0:getContentSize().width/2, 0))
    --btn_bag0:addChild(lbl_btn_bag)
    --local btn_bag = SpineMenuItem:create(json.ui.button, btn_bag0)
    --btn_bag:setPosition(CCPoint(btn_offset_x+btn_step_x*1, btn_offset_y))
    --local btn_bag_menu = CCMenu:createWithItem(btn_bag)
    --btn_bag_menu:setPosition(CCPoint(0, 0))
    --bg:addChild(btn_bag_menu)
    --btn_bag:registerScriptTapHandler(function()
    --    audio.play(audio.button)
    --    replaceScene((require"ui.bag.main").create("hook"))
    --end)
	
	local last_battle_st

    -- btn hero
    local btn_hero0 = img.createLogin9Sprite(img.login.button_9_small_green)
    btn_hero0:setPreferredSize(CCSizeMake(148, 42))
    --local icon_hero = img.createUISprite(img.ui.hook_icon_hero)
    --icon_hero:setPosition(CCPoint(19, 21))
    --btn_hero0:addChild(icon_hero)
    local lbl_btn_hero = lbl.createFont1(16, i18n.global.act_bboss_sweep.string, ccc3(0x1d, 0x67, 0x00))
    lbl_btn_hero:setPosition(CCPoint(btn_hero0:getContentSize().width/2, 21))
    btn_hero0:addChild(lbl_btn_hero)
    local btn_hero = SpineMenuItem:create(json.ui.button, btn_hero0)
    btn_hero:setScale(view.minScale)
    btn_hero:setPosition(scalep(276, 227))
    local btn_hero_menu = CCMenu:createWithItem(btn_hero)
    btn_hero_menu:setPosition(CCPoint(0, 0))
    icon_layer:addChild(btn_hero_menu)
    btn_hero:registerScriptTapHandler(function()
        --audio.play(audio.button)
        --layer:addChild((require"ui.herolist.main").create({back="hook"}), 10000)
		disableObjAWhile(btn_hero)
        if last_battle_st and last_battle_st == "bt1" then
            audio.play(audio.button)
            layer:addChild(require("ui.selecthero.main").create({type = "pve", isBatch = true}), 10000)
        end
    end)
	
	local function setSweepEnable(enabled)
		require ("ui.custom").setButtonEnabled(btn_hero, enabled)
	end

    -- btn map
    local btn_map0 = img.createLogin9Sprite(img.login.button_9_small_gold)
    btn_map0:setPreferredSize(CCSizeMake(148, 42))
    local icon_map = img.createUISprite(img.ui.hook_icon_map)
    icon_map:setPosition(CCPoint(19, 21))
    btn_map0:addChild(icon_map)
    addRedDot(btn_map0, {
        px = btn_map0:getContentSize().width - 7,
        py = btn_map0:getContentSize().height - 4,
    })
    delRedDot(btn_map0)
    local lbl_btn_map = lbl.createFont1(16, i18n.global.hook_btn_map.string, ccc3(0x83, 0x41, 0x1d))
    lbl_btn_map:setPosition(CCPoint(btn_map0:getContentSize().width/2+10, 21))
    btn_map0:addChild(lbl_btn_map)
    local btn_map = SpineMenuItem:create(json.ui.button, btn_map0)
    btn_map:setScale(view.minScale)
    btn_map:setPosition(scalep(684, 227))
    local btn_map_menu = CCMenu:createWithItem(btn_map)
    btn_map_menu:setPosition(CCPoint(0, 0))
    icon_layer:addChild(btn_map_menu, 100)
    btn_map:registerScriptTapHandler(function()
        --replaceScene(require("ui.hook.map").create())
        audio.play(audio.button)
        local hint_flag = true
        if hookdata.fort_hint_flag then
            hookdata.fort_hint_flag = nil
            local tmp_pve_stage_id = hookdata.getPveStageId()
            if tmp_pve_stage_id > hookdata.lastStage() then
                hint_flag = nil
            else
                hint_flag = hookdata.getFortIdByStageId(tmp_pve_stage_id)
            end
        end
        --layer:removeFromParentAndCleanup(true)
        replaceScene(require("ui.hook.map").create(nil, hint_flag))
    end)

    local particle_scale = view.minScale
    local shine_particle = particle.create("loop_shine_1")
    shine_particle:setStartSize(particle_scale * (shine_particle:getStartSize()-13))
    shine_particle:setStartSizeVar(particle_scale * shine_particle:getStartSizeVar())
    shine_particle:setEndSize(particle_scale * shine_particle:getEndSize())
    shine_particle:setEndSizeVar(particle_scale * shine_particle:getEndSizeVar())
    layer:addChild(shine_particle, 110)
    local shine_particle2 = particle.create("loop_shine_2")
    shine_particle2:setStartSize(particle_scale * (shine_particle2:getStartSize()-0))
    shine_particle2:setStartSizeVar(particle_scale * shine_particle2:getStartSizeVar())
    shine_particle2:setEndSize(particle_scale * shine_particle2:getEndSize())
    shine_particle2:setEndSizeVar(particle_scale * shine_particle2:getEndSizeVar())
    layer:addChild(shine_particle2, 105)

    json.load(json.ui.guaji_yellow_btn)
    local map_ani = DHSkeletonAnimation:createWithKey(json.ui.guaji_yellow_btn)
    map_ani:scheduleUpdateLua()
    map_ani:playAnimation("animation", -1)
    map_ani:setAnchorPoint(CCPoint(0.5, 0.5))
    map_ani:setPosition(CCPoint(74, 21))
    btn_map:addChild(map_ani)

    -- particle animation params
    local function runParticle(dt)
        shine_particle:setVisible(true)
        shine_particle2:setVisible(true)
        shine_particle:setPosition(map_ani:getBonePositionRelativeToLayer("code_fx"))
        shine_particle2:setPosition(map_ani:getBonePositionRelativeToLayer("code_fx"))
    end
    local function stopParticle()
        shine_particle:setVisible(false)
        shine_particle2:setVisible(false)
    end

    -- 是否有掉落
    local function anyReward()
        if hookdata.reward and hookdata.reward.items and #hookdata.reward.items > 0 then
            return true
        end
        if hookdata.reward and hookdata.reward.equips and #hookdata.reward.equips > 0 then
            return true
        end
        return false
    end

    -- btn help
    local btn_help0 = img.createUISprite(img.ui.btn_help)
    local btn_help = SpineMenuItem:create(json.ui.button, btn_help0)
    btn_help:setPosition(CCPoint(bg_w - 40, bg_h - 33))
    local btn_help_menu = CCMenu:createWithItem(btn_help)
    btn_help_menu:setPosition(CCPoint(0, 0))
    bg:addChild(btn_help_menu)
    btn_help:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer:addChild((require"ui.help").create(i18n.global.help_hook.string), 1000)
    end)

    autoLayoutShift(btn_help)

    -- btn rank
    local btn_rank0 = img.createUISprite(img.ui.btn_rank)
    local btn_rank = SpineMenuItem:create(json.ui.button, btn_rank0)
    btn_rank:setPosition(CCPoint(bg_w - 90, bg_h - 33))
    local btn_rank_menu = CCMenu:createWithItem(btn_rank)
    btn_rank_menu:setPosition(CCPoint(0, 0))
    bg:addChild(btn_rank_menu)
    btn_rank:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer:addChild((require"ui.hook.rank").create(), 1000)
    end)

    autoLayoutShift(btn_rank)

    local p_offset_x = 0
    local p_offset_y = -2
    -- btn_drops
    local btn_drops0 = img.createUISprite(img.ui.hook_btn_drops)
    local btn_drops = SpineMenuItem:create(json.ui.button, btn_drops0)
    btn_drops:setScale(view.minScale)
    btn_drops:setPosition(scalep(p_offset_x+72, p_offset_y+464))
    local btn_drops_menu = CCMenu:createWithItem(btn_drops)
    btn_drops_menu:setPosition(CCPoint(0, 0))
    icon_layer:addChild(btn_drops_menu, 100)

    -- btn_reward
    --local btn_reward0 = img.createUISprite(img.ui.hook_btn_rewards)
    local btn_reward0 = img.createLogin9Sprite(img.login.button_9_small_gold)
    btn_reward0:setPreferredSize(CCSizeMake(148, 42))
    addRedDot(btn_reward0, {
        px = btn_reward0:getContentSize().width - 7,
        py = btn_reward0:getContentSize().height - 4,
    })
    delRedDot(btn_reward0)
    local icon_reward = img.createUISprite(img.ui.hook_icon_reward)
    icon_reward:setPosition(CCPoint(19, 21))
    btn_reward0:addChild(icon_reward)
    local lbl_btn_reward = lbl.createFont1(16, i18n.global.hook_btn_reward.string, ccc3(0x83, 0x41, 0x1d))
    lbl_btn_reward:setPosition(CCPoint(btn_reward0:getContentSize().width/2+10, 21))
    btn_reward0:addChild(lbl_btn_reward)
    local btn_reward = SpineMenuItem:create(json.ui.button, btn_reward0)
    btn_reward:setScale(view.minScale)
    btn_reward:setPosition(scalep(838, 227))
    local btn_reward_menu = CCMenu:createWithItem(btn_reward)
    btn_reward_menu:setPosition(CCPoint(0, 0))
    icon_layer:addChild(btn_reward_menu, 100)
    btn_reward:registerScriptTapHandler(function()
        audio.play(audio.button)
        if not anyReward() then
            showToast(i18n.global.hook_no_reward.string)
            return
        end
        local params = {
            sid = player.sid,
            type = 2,
        }
        addWaitNet()
        hookdata.hook_reward(params, function(__data)
            delWaitNet()
            tbl2string(__data)
            if __data.status ~= 0 then
                showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                return
            end
            if __data.reward and __data.reward.items then
                bagdata.items.addAll(__data.reward.items)
            end
            if __data.reward and __data.reward.equips then
                bagdata.equips.addAll(__data.reward.equips)
            end
            --showToast(i18n.global.hook_get_ok.string)
            hookdata.set_reward({})
            if __data.reward then
                layer:addChild((require"ui.hook.drops").create(__data.reward), 1000)
            end
        end)
    end)

    -- coin
    local btn_coin0 = img.createItemIcon2(ITEM_ID_COIN)
    local btn_coin = SpineMenuItem:create(json.ui.button, btn_coin0)
    btn_coin:setScale(view.minScale*0.76)
    btn_coin:setPosition(scalep(528, p_offset_y+467))
    local btn_coin_menu = CCMenu:createWithItem(btn_coin)
    btn_coin_menu:setPosition(CCPoint(0, 0))
    icon_layer:addChild(btn_coin_menu, 100)
    local lbl_play_coin = lbl.createFont2(18, "5/s", ccc3(0xff, 0xf6, 0xd8), true)
    lbl_play_coin:setAnchorPoint(CCPoint(0, 0.5))
    lbl_play_coin:setPosition(CCPoint(btn_coin:boundingBox():getMaxX()+6*view.minScale, view.minY+(p_offset_y+467)*view.minScale))
    icon_layer:addChild(lbl_play_coin, 100)

    -- pxp
    local btn_pxp0 = img.createItemIcon2(ITEM_ID_PLAYER_EXP)
    local btn_pxp = SpineMenuItem:create(json.ui.button, btn_pxp0)
    btn_pxp:setScale(view.minScale*0.72)
    btn_pxp:setPosition(scalep(720, p_offset_y+467))
    local btn_pxp_menu = CCMenu:createWithItem(btn_pxp)
    btn_pxp_menu:setPosition(CCPoint(0, 0))
    icon_layer:addChild(btn_pxp_menu, 100)
    local lbl_play_pxp = lbl.createFont2(18, "10/s", ccc3(0xff, 0xf6, 0xd8), true)
    lbl_play_pxp:setAnchorPoint(CCPoint(0, 0.5))
    lbl_play_pxp:setPosition(CCPoint(btn_pxp:boundingBox():getMaxX()+6*view.minScale, view.minY+(p_offset_y+467)*view.minScale))
    icon_layer:addChild(lbl_play_pxp, 100)

    -- hxp
    local btn_hxp0 = img.createItemIcon(ITEM_ID_HERO_EXP)
    local btn_hxp = SpineMenuItem:create(json.ui.button, btn_hxp0)
    btn_hxp:setScale(view.minScale*0.38)
    btn_hxp:setPosition(scalep(624, p_offset_y+467))
    local btn_hxp_menu = CCMenu:createWithItem(btn_hxp)
    btn_hxp_menu:setPosition(CCPoint(0, 0))
    icon_layer:addChild(btn_hxp_menu, 100)
    local lbl_play_hxp = lbl.createFont2(18, "10/s", ccc3(0xff, 0xf6, 0xd8), true)
    lbl_play_hxp:setAnchorPoint(CCPoint(0, 0.5))
    lbl_play_hxp:setPosition(CCPoint(btn_hxp:boundingBox():getMaxX()+6*view.minScale, view.minY+(p_offset_y+467)*view.minScale))
    icon_layer:addChild(lbl_play_hxp, 100)

    -- btn_get
    json.load(json.ui.guaji_green_btn)
    --local btn_get0 = img.createLogin9Sprite(img.login.button_9_small_green)
    --btn_get0:setPreferredSize(CCSizeMake(86, 38))
    local btn_get0 = DHSkeletonAnimation:createWithKey(json.ui.guaji_green_btn)
    btn_get0:scheduleUpdateLua()
    btn_get0:playAnimation("animation", -1)
    local lbl_btn_get = lbl.createFont1(20, i18n.global.hook_btn_get.string, ccc3(0x1f, 0x60, 0x06))
    --lbl_btn_get:setPosition(CCPoint(btn_get0:getContentSize().width/2, btn_get0:getContentSize().height/2))
    --btn_get0:addChild(lbl_btn_get)
    btn_get0:addChildFollowSlot("code_font", lbl_btn_get)
    local btn_get_box = CCSprite:create()
    btn_get_box:setContentSize(CCSizeMake(88, 40))
    btn_get0:setPosition(CCPoint(44, 20))
    btn_get_box:addChild(btn_get0)
    local btn_get = SpineMenuItem:create(json.ui.button, btn_get_box)
    btn_get:setScale(view.minScale)
    btn_get:setPosition(scalep(871, p_offset_y+467))
    local btn_get_menu = CCMenu:createWithItem(btn_get)
    btn_get_menu:setPosition(CCPoint(0, 0))
    icon_layer:addChild(btn_get_menu, 100)

    local ani_get_01 = DHSkeletonAnimation:createWithKey(json.ui.hook_reward_01)
    ani_get_01:setScale(view.minScale)
    ani_get_01:scheduleUpdateLua()
    ani_get_01:setPosition(scalep(528, p_offset_y+451))
    icon_layer:addChild(ani_get_01)
    local ani_get_02 = DHSkeletonAnimation:createWithKey(json.ui.hook_reward_02)
    ani_get_02:setScale(view.minScale)
    ani_get_02:scheduleUpdateLua()
    --ani_get_02:setAnchorPoint(CCPoint(0.5, 0.5))
    ani_get_02:setPosition(scalep(624, p_offset_y+451))
    icon_layer:addChild(ani_get_02)
    local ani_get_03 = DHSkeletonAnimation:createWithKey(json.ui.hook_reward_03)
    ani_get_03:setScale(view.minScale)
    ani_get_03:scheduleUpdateLua()
    --ani_get_03:setAnchorPoint(CCPoint(0.5, 0.5))
    ani_get_03:setPosition(scalep(720, p_offset_y+451))
    icon_layer:addChild(ani_get_03)

    btn_get:registerScriptTapHandler(function()
        disableObjAWhile(btn_get, 2)
        audio.play(audio.get_gold_exp)
        if hookdata.getHookStage() <= 0 then
            showToast(i18n.global.hook_not_hooking.string)
            return
        end
        local params = {
            sid = player.sid,
            type = 1,
        }
        addWaitNet()
        hookdata.hook_reward(params, function(__data)
            delWaitNet()
            tbl2string(__data)
            if __data.status ~= 0 then
                showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                return
            end
            btn_get:setVisible(false)
            local will_check_lv = false
            if player.lv() >= player.maxLv() then
                will_check_lv = false
            else
                will_check_lv = true
            end
            require("data.tutorial").goNext("hook2", 3, true) 
            if __data.reward and __data.reward.items then
                bagdata.items.addAll(__data.reward.items)
            end
            if __data.reward and __data.reward.equips then
                bagdata.equips.addAll(__data.reward.equips)
            end
            -- task increment
            local taskdata = require "data.task"
            taskdata.increment(taskdata.TaskType.HOOK_GET)
            -- checkLevelUp
            local g_coin, g_pxp, g_hxp = coinAndExp(__data.reward)
            if will_check_lv then
                checkLevelUp(g_pxp)
            end
            --showToast("coin:" .. g_coin .. ", player exp:" .. g_pxp .. ", hero exp:" .. g_hxp)
            local arr_get = CCArray:create()
            arr_get:addObject(CCCallFunc:create(function()
                ani_get_01:playAnimation("animation", 1)
                ani_get_02:playAnimation("animation", 1)
                ani_get_03:playAnimation("animation", 1)
                json.load(json.ui.hook_pariticle)
                local ani_particle = DHSkeletonAnimation:createWithKey(json.ui.hook_pariticle)
                ani_particle:setScale(view.minScale)
                ani_particle:scheduleUpdateLua()
                ani_particle:playAnimation("animation")
                ani_particle:setPosition(scalep(480, 288))
                layer:addChild(ani_particle, 10000)
                local particle_coin = particle.create("decompose_particle4")
                layer:addChild(particle_coin, 10000)
                local particle_hxp = particle.create("decompose_particle5")
                layer:addChild(particle_hxp, 10000)
                local function partileUpdate()
                    particle_coin:setPosition(ani_particle:getBonePositionRelativeToLayer("code_particle_01"))
                    particle_hxp:setPosition(ani_particle:getBonePositionRelativeToLayer("code_particle_02"))
                end
                icon_layer:scheduleUpdateWithPriorityLua(partileUpdate, 0)
                schedule(icon_layer, 0.8, function()
                    icon_layer:unscheduleUpdate()
                end)
            end))
            arr_get:addObject(CCDelayTime:create(0.1))
            arr_get:addObject(CCCallFunc:create(function()
                hookdata.resetOutput()
            end))
            layer:runAction(CCSequence:create(arr_get))
            --updateOutput()
        end)
    end)

    -- pgb
    local pgb_bg = img.createUI9Sprite(img.ui.hook_pgb_bg)
    pgb_bg:setPreferredSize(CCSizeMake(657, 32))
    pgb_bg:setScale(view.minScale)
    pgb_bg:setPosition(scalep(480, p_offset_y+209))
    icon_layer:addChild(pgb_bg, 100)
    local pgb_fg = img.createUISprite(img.ui.hook_pgb_fg)
    local pgb = createProgressBar(pgb_fg)
    pgb:setPosition(CCPoint(pgb_bg:getContentSize().width/2, pgb_bg:getContentSize().height/2))
    pgb_bg:addChild(pgb)
    pgb:setPercentage(20)
    local lbl_boss_cd = lbl.createFont2(16, "", ccc3(255, 246, 223))
    lbl_boss_cd:setPosition(CCPoint(pgb_bg:getContentSize().width/2, pgb_bg:getContentSize().height/2))
    pgb_bg:addChild(lbl_boss_cd, 2)
    pgb_bg:setVisible(false)

    -- btn_pve
    json.load(json.ui.guaji_red_btn)
    --local btn_pve0 = img.createUISprite(img.ui.hook_btn_battle)
    local btn_pve0 = DHSkeletonAnimation:createWithKey(json.ui.guaji_red_btn)
    btn_pve0:scheduleUpdateLua()
    local lbl_btn_pve = lbl.createFont1(22, i18n.global.hook_btn_pve.string, ccc3(0x7e, 0x27, 0x00))
    btn_pve0:addChildFollowSlot("code_font", lbl_btn_pve)
    local lbl_btn_pve2 = lbl.createFont1(16, i18n.global.hook_btn_pve.string, ccc3(0x2f, 0x45, 0x8b))
    btn_pve0:addChildFollowSlot("code_font2", lbl_btn_pve2)
    local lbl_btn_pve3 = lbl.createFont2(22, "00:00:00")
    btn_pve0:addChildFollowSlot("code_font3", lbl_btn_pve3)
    local btn_pve_box = CCSprite:create()
    btn_pve_box:setContentSize(CCSizeMake(252, 57))
    btn_pve0:setPosition(CCPoint(126, 0))
    btn_pve_box:addChild(btn_pve0)
    local btn_pve = HHMenuItem:createWithScale(btn_pve_box, 1)
    btn_pve:setScale(view.minScale)
    btn_pve:setAnchorPoint(CCPoint(0.5, 0))
    btn_pve:setPosition(scalep(480, p_offset_y+199))
    local btn_pve_menu = CCMenu:createWithItem(btn_pve)
    btn_pve_menu:setPosition(CCPoint(0, 0))
    icon_layer:addChild(btn_pve_menu, 100)
    -- cd progressbar
    local btn_pve_cd_bg = img.createUISprite(img.ui.hook_btn_cd_bg)
    btn_pve_cd_bg:setScale(view.minScale)
    btn_pve_cd_bg:setAnchorPoint(CCPoint(0.5, 0))
    btn_pve_cd_bg:setPosition(scalep(480, p_offset_y+199))
    icon_layer:addChild(btn_pve_cd_bg, 100)
    local btn_pve_cd_fg = img.createUISprite(img.ui.hook_btn_cd_fg)
    local btn_pve_pgb = createProgressBar(btn_pve_cd_fg)
    btn_pve_pgb:setAnchorPoint(CCPoint(0.5, 0))
    btn_pve_pgb:setPosition(CCPoint(btn_pve_cd_bg:getContentSize().width/2, 0))
    btn_pve_cd_bg:addChild(btn_pve_pgb)
    local lbl_btn_pve4 = lbl.createFont2(22, "00:00:00")
    lbl_btn_pve4:setPosition(CCPoint(btn_pve_cd_bg:getContentSize().width/2, 26))
    btn_pve_cd_bg:addChild(lbl_btn_pve4, 100)
    local function cdPercent()
        local boss_time = hookdata.getStageBossCD()
        local time_cd = hookdata.boss_cd - getMilliSecond()/1000 + hookdata.init_time
        local time_str = time2string(checkint(time_cd))
        lbl_btn_pve4:setString(time_str)
        --playBattle2()
        local percent = (boss_time - time_cd)*100/boss_time
        btn_pve_pgb:setPercentage(percent)
    end
    -- btn_pass
    local btn_pve_pass = img.createUISprite(img.ui.hook_btn_battle_pass)
    btn_pve_pass:setScale(view.minScale)
    btn_pve_pass:setAnchorPoint(CCPoint(0.5, 0))
    btn_pve_pass:setPosition(scalep(480, p_offset_y+199))
    icon_layer:addChild(btn_pve_pass, 90)
    local lbl_pve_pass = lbl.createFont1(24, i18n.global.hook_btn_passed.string, ccc3(0xff, 0xd7, 0x6b))
    lbl_pve_pass:setPosition(CCPoint(btn_pve_pass:getContentSize().width/2, 29))
    btn_pve_pass:addChild(lbl_pve_pass)
    
    local function playBattle1()
        btn_pve_pass:setVisible(false)
        btn_pve:setVisible(true)
		setSweepEnable(true)
        if last_battle_st and last_battle_st == "bt1" then
            return
        end
        last_battle_st = "bt1"
        btn_pve0:playAnimation("animation", -1)
    end
    local function playBattle2()
        btn_pve_pass:setVisible(false)
        btn_pve:setVisible(true)
		setSweepEnable(false)
        if last_battle_st and last_battle_st == "bt2" then
            return
        end
        last_battle_st = "bt2"
        btn_pve0:playAnimation("animation2", -1)
    end
    local function checkBattleSt()
        local tmp_stage_id = hookdata.getHookStage()
        --if uiParams and uiParams.jump_stage then
        --    tmp_stage_id = uiParams.jump_stage
        --end
        if tmp_stage_id <= 0 then
            lbl_pve_pass:setVisible(false)
            btn_pve_pass:setVisible(true)
            btn_pve:setVisible(false)
            btn_pve_cd_bg:setVisible(false)
			setSweepEnable(false)
            return
        else
            lbl_pve_pass:setVisible(true)
        end
        local tmp_pve_stage_id = hookdata.getPveStageId()
        if tmp_stage_id ~= tmp_pve_stage_id then
            btn_pve_pass:setVisible(true)
            btn_pve:setVisible(false)
            btn_pve_cd_bg:setVisible(false)
			setSweepEnable(false)
            return
        end
        if hookdata.boss_cd and hookdata.boss_cd > os.time() - hookdata.init_time then
            btn_pve_pass:setVisible(false)
            btn_pve:setVisible(false)
            btn_pve_cd_bg:setVisible(true)
			setSweepEnable(false)
            cdPercent()
            --local boss_time = hookdata.getStageBossCD()
            --local time_cd = hookdata.boss_cd - os.time() + hookdata.init_time
            --local time_str = time2string(time_cd)
            --lbl_btn_pve3:setString(time_str)
            --playBattle2()
            --local percent = (boss_time - time_cd)*100/boss_time
            --pgb:setPercentage(percent)
        else
            btn_pve_pass:setVisible(false)
            btn_pve:setVisible(true)
            btn_pve_cd_bg:setVisible(false)
            playBattle1()
        end
    end
    checkBattleSt()
    btn_pve:registerScriptTapHandler(function()
        disableObjAWhile(btn_pve)
        if last_battle_st and last_battle_st == "bt1" then
            audio.play(audio.button)
            layer:addChild(require("ui.selecthero.main").create({type = "pve"}), 10000)
        end
    end)

    local SCROLL_VIEW_W = 768
    local SCROLL_VIEW_H = 135
    local scroll = CCScrollView:create()
    scroll:setDirection(kCCScrollViewDirectionHorizontal)
    scroll:setViewSize(CCSize(SCROLL_VIEW_W, SCROLL_VIEW_H))
    scroll:setAnchorPoint(CCPoint(0, 0))
    scroll:setPosition(CCPoint(43, 13))
    stage_board:addChild(scroll)
    --drawBoundingbox(stage_board, scroll)

    local content_layer = CCLayer:create()
    content_layer:setAnchorPoint(CCPoint(0, 0))
    content_layer:setPosition(CCPoint(0, 0))
    scroll:getContainer():addChild(content_layer, 1, TAG_CONTENT_LAYER)
    scroll.content_layer = content_layer

    function addStageFocus(spriteObj)
        -- method 1
        --local tmp_focus = img.createUISprite(img.ui.hook_stage_focus)
        --tmp_focus:setFlipX(true)
        --tmp_focus:setPosition(CCPoint(50, 50))
        --spriteObj:addChild(tmp_focus, 100)
        --spriteObj.focus = tmp_focus
        --tmp_focus:runAction(CCRepeatForever:create(CCRotateBy:create(1.0, 360)))
        -- method 2
        --local jump_up = CCJumpBy:create(3, CCPoint(0, 0), 10, 4)
        --local act_arr = CCArray:create()
        --act_arr:addObject(jump_up)
        --act_arr:addObject(jump_up:reverse())
        --spriteObj:runAction(CCRepeatForever:create(CCSequence:create(act_arr)))
        --spriteObj.focus = true
        -- method 3
        --local tmp_pos = layer:convertToNodeSpace(CCPoint(spriteObj:getPosition()))
        --particle_radius = 51*view.minScale
        --particle_cx = scalex(485)
        --particle_cy = scaley(104)
        -- method 4
        json.load(json.ui.guaji_xuanguan)
        local next_ani = DHSkeletonAnimation:createWithKey(json.ui.guaji_xuanguan)
        next_ani:scheduleUpdateLua()
        next_ani:setPosition(CCPoint(spriteObj:getContentSize().width/2, spriteObj:getContentSize().height/2))
        spriteObj:addChild(next_ani)
        next_ani:playAnimation("animation", -1)
        spriteObj.ani = next_ani
    end
    function addRadar(spriteObj)
        local stage_anim = DHSkeletonAnimation:createWithKey(json.ui.radar)
        stage_anim:scheduleUpdateLua()
        stage_anim:playAnimation("radar", -1)
        stage_anim:setAnchorPoint(CCPoint(0.5, 0.5))
        stage_anim:setPosition(CCPoint(50, 50))
        spriteObj:addChild(stage_anim)
    end

    local stage_id = hookdata.getHookStage()
    --if uiParams and uiParams.jump_stage then
    --    stage_id = uiParams.jump_stage
    --end
    local fort_id = hookdata.getFortIdByStageId(stage_id)
    local pve_stage_id = hookdata.getPveStageId()
    local function createStageItem(_stage_id)
        local btn_stage0 = img.createUISprite(img.ui.hook_btn_stage_bg)
        local fortInfo = hookdata.getFortByStageId(_stage_id)
        local stage_name = fort_id .. "-" .. (_stage_id - fortInfo.stageId[1] + 1)
        local lbl_stage_name = lbl.createFont1(22, stage_name, ccc3(0x83, 0x41, 0x1d))
        lbl_stage_name:setPosition(CCPoint(btn_stage0:getContentSize().width/2, 50))
        btn_stage0:addChild(lbl_stage_name)
        if _stage_id < pve_stage_id then
            --local stage_drop = img.createUISprite(img.ui.coin)
            --stage_drop:setPosition(CCPoint(btn_stage0:getContentSize().width/2, 70))
            --btn_stage0:addChild(stage_drop)
        elseif _stage_id == pve_stage_id and player.lv() >= hookdata.getStageLv(_stage_id) then
        else
            local icon_lock = img.createUISprite(img.ui.hook_btn_lock)
            icon_lock:setPosition(CCPoint(btn_stage0:getContentSize().width/2, btn_stage0:getContentSize().height/2))
            btn_stage0:addChild(icon_lock)
            lbl_stage_name:setVisible(false)
        end
        --if uiParams and uiParams.jump_stage and _stage_id == stage_id then
        --    addStageFocus(btn_stage0)
        --elseif _stage_id == stage_id then
        if _stage_id == stage_id then
            --local stage_anim_1 = img.createUISprite(img.ui.hook_btn_hook_anim1)
            --stage_anim_1:setPosition(CCPoint(btn_stage0:getContentSize().width/2, btn_stage0:getContentSize().height/2))
            --btn_stage0:addChild(stage_anim_1)
            --local stage_anim_2 = img.createUISprite(img.ui.hook_btn_hook_anim2)
            --stage_anim_2:setPosition(CCPoint(btn_stage0:getContentSize().width/2, btn_stage0:getContentSize().height/2))
            --btn_stage0:addChild(stage_anim_2, 2)
            --stage_anim_2:runAction(CCRepeatForever:create(CCRotateBy:create(1, 360)))
            addRadar(btn_stage0)
        elseif uiParams and uiParams.win and _stage_id == stage_id+1 then
        --elseif _stage_id == stage_id+1 then
            addStageFocus(btn_stage0)
        end
        return btn_stage0
    end
    local stage_offset_x = 91
    local stage_step_x = 150
    local function createStageList(_stage_id)
        content_layer:removeAllChildrenWithCleanup(true)
        arrayclear(stage_items)
        local fortInfo = hookdata.getFortByStageId(_stage_id)
        local list_width = 0
        for ii=1,#fortInfo.stageId do
            local tmp_stage_item = createStageItem(fortInfo.stageId[ii])
            tmp_stage_item.stage_id = fortInfo.stageId[ii]
            tmp_stage_item:setPosition(CCPoint(stage_offset_x+(ii-1)*stage_step_x, SCROLL_VIEW_H/2))
            content_layer:addChild(tmp_stage_item)
            stage_items[#stage_items+1] = tmp_stage_item
            list_width = stage_offset_x+(ii-1)*stage_step_x + 100
        end
        if list_width > SCROLL_VIEW_W then
            scroll:setContentSize(CCSizeMake(list_width, SCROLL_VIEW_H))
        else
            scroll:setContentSize(CCSizeMake(SCROLL_VIEW_W, SCROLL_VIEW_H))
        end
        local stage_count = #fortInfo.stageId
        local cur_idx = _stage_id - fortInfo.stageId[1] + 1
        if cur_idx <= 0 then cur_idx = 1 end
        if stage_count - cur_idx <= 3 then
            cur_idx = stage_count - 3
        end
        --cur_idx = math.floor((cur_idx-1)/5)*5
        if cur_idx <= 2 then cur_idx = 2 end
        scroll:setContentOffset(CCPoint(0-(cur_idx-2)*stage_step_x, 0))
    end
    createStageList(stage_id)

    local function onClickItem(_obj)
        if _obj.focus  then
            _obj:stopAllActions()
            _obj.focus = nil
        end
        if _obj.ani and not tolua.isnull(_obj.ani) then
            _obj.ani:removeFromParentAndCleanup(true)
        end
        local tmp_stage_id = _obj.stage_id
        if tmp_stage_id == pve_stage_id then
            -- check lv
            if player.lv() < hookdata.getStageLv(tmp_stage_id) then
                local tmp_tip = (require"ui.hook.powerTip").create(1, tmp_stage_id)
                local pp1 = CCPoint(_obj:getPosition())
                local pp2 = scroll:getContentOffset()
                local p0 = layer:convertToNodeSpace(ccpAdd(pp1, pp2))
                tmp_tip.adaptPos(p0)
                layer:addChild(tmp_tip, 1000)
                return
            end
            if hookdata.getAllPower() < hookdata.stage_power(tmp_stage_id) then  -- need power
                local tmp_tip = (require"ui.hook.powerTip").create(1, tmp_stage_id)
                local pp1 = CCPoint(_obj:getPosition())
                local pp2 = scroll:getContentOffset()
                local p0 = layer:convertToNodeSpace(ccpAdd(pp1, pp2))
                tmp_tip.adaptPos(p0)
                layer:addChild(tmp_tip, 1000)
                return
            end
        elseif tmp_stage_id > pve_stage_id then  -- unlock
            local tmp_tip = (require"ui.hook.powerTip").create(2, tmp_stage_id)
            local pp1 = CCPoint(_obj:getPosition())
            local pp2 = scroll:getContentOffset()
            local p0 = layer:convertToNodeSpace(ccpAdd(pp1, pp2))
            tmp_tip.adaptPos(p0)
            layer:addChild(tmp_tip, 1000)
            return
        end
        layer:addChild((require"ui.hook.stage").create(tmp_stage_id), 1000)
    end

    btn_drops:registerScriptTapHandler(function()
        audio.play(audio.button)
        stage_id = hookdata.getHookStage()
        --if uiParams and uiParams.jump_stage then
        --    stage_id = uiParams.jump_stage
        --end
        if stage_id <= 0 then return end
        layer:addChild((require"ui.hook.stage").create(stage_id), 1000)
    end)

    -- touch event
    local touchbeginx, touchbeginy
    local isclick
    local last_touch_sprite = nil
    local function onTouchBegan(x, y)
        touchbeginx, touchbeginy = x, y
        isclick = true
        if scroll and not tolua.isnull(scroll) then
            local p0 = content_layer:convertToNodeSpace(ccp(x, y))
            for ii=1,#stage_items do
                if stage_items[ii]:boundingBox():containsPoint(p0) then
                    --if uiParams and uiParams.jump_stage == stage_items[ii].stage_id then
                    --    playAnimTouchBegin(stage_items[ii])
                    --    last_touch_sprite = stage_items[ii]
                    --elseif stage_items[ii].stage_id ~= stage_id then
                    if stage_items[ii].stage_id ~= stage_id then
                        playAnimTouchBegin(stage_items[ii])
                        last_touch_sprite = stage_items[ii]
                    else
                        isclick = false
                        return false
                    end
                    break
                end
            end
        end
        return true
    end
    local function onTouchMoved(x, y)
        if isclick and (math.abs(touchbeginx-x) > 10 or math.abs(touchbeginy-y) > 10) then
            isclick = false
            if last_touch_sprite and not tolua.isnull(last_touch_sprite) then
                playAnimTouchEnd(last_touch_sprite)
                last_touch_sprite = nil
            end
        end
    end
    local function onTouchEnded(x, y)
        if last_touch_sprite and not tolua.isnull(last_touch_sprite) then
            playAnimTouchEnd(last_touch_sprite)
            last_touch_sprite = nil
        end
        if isclick and scroll and not tolua.isnull(scroll) then
            local p0 = content_layer:convertToNodeSpace(ccp(x, y))
            for ii=1,#stage_items do
                if stage_items[ii]:boundingBox():containsPoint(p0) then
                    audio.play(audio.button)
                    onClickItem(stage_items[ii])
                    break
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
    layer:setTouchEnabled(true)
    layer:setTouchSwallowEnabled(true)

    addBackEvent(layer)
    function layer.onAndroidBack()
        fightAnim:unloadAllResources()
        if uiParams and uiParams.from_layer == "task" then
            replaceScene(require("ui.town.main").create({from_layer="task"}))  
        else
            replaceScene(require("ui.town.main").create())  
        end
    end

    local function onEnter()
        print("onEnter")
        layer.notifyParentLock()
        --if hookdata.status and hookdata.status ~= 0 then
        --end
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

    local function askReward()
        if os.time() - last_ask < ASK_INTERVAL then return end  -- ask every half
        last_ask = os.time()
        local params = {
            sid = player.sid,
        }
        hookdata.hook_ask(params, function(__data)
            tbl2string(__data)
            if __data.status == 0 then
                hookdata.set_reward(__data.reward or {})
            end
        end)
    end

    local last_output_update = os.time() - hookdata.OUTPUT_INTERVAL
    function updateOutput()
        if not hookdata.status or hookdata.status ~= 0 then return end
        --if os.time() - last_output_update < hookdata.OUTPUT_INTERVAL then return end
        last_output_update = os.time()
        local tmp_coins = hookdata.coins or 0
        if tmp_coins > 10000000 then
            tmp_coins = math.floor(tmp_coins/1000000) .. "M"
        elseif tmp_coins > 10000 then
            tmp_coins = math.floor(tmp_coins/1000) .. "K"
        end
        local tmp_pxps = hookdata.pxps or 0
        if tmp_pxps > 10000000 then
            tmp_pxps = math.floor(tmp_pxps/1000000) .. "M"
        elseif tmp_pxps > 10000 then
            tmp_pxps = math.floor(tmp_pxps/1000) .. "K"
        end
        local tmp_hxps = hookdata.hxps or 0
        if tmp_hxps > 10000000 then
            tmp_hxps = math.floor(tmp_hxps/1000000) .. "M"
        elseif tmp_hxps > 10000 then
            tmp_hxps = math.floor(tmp_hxps/1000) .. "K"
        end
        if player.lv() >= player.maxLv() then
            tmp_pxps = 0
            btn_pxp:setVisible(false)
            lbl_play_pxp:setVisible(false)
        else
            btn_pxp:setVisible(true)
            lbl_play_pxp:setVisible(true)
        end
        lbl_play_coin:setString(tmp_coins or 0)
        lbl_play_pxp:setString(tmp_pxps or 0)
        lbl_play_hxp:setString(tmp_hxps or 0)
        if hookdata.coins and hookdata.coins > 0 then
            btn_get:setVisible(true)
        else
            btn_get:setVisible(false)
        end
    end

    local function checkLastPVE()
        --if 1 then return true end
        --if uiParams and uiParams.win then
        if hookdata.fort_hint_flag then
            local tmp_stage_id = hookdata.getHookStage()
            local tmp_pve_stage_id = hookdata.getPveStageId()
            if tmp_pve_stage_id > hookdata.lastStage() then return false end
            local fortInfo = hookdata.getFortByStageId(hookdata.getHookStage())
            if fortInfo.stageId[#fortInfo.stageId] == tmp_stage_id and tmp_pve_stage_id and tmp_stage_id < tmp_pve_stage_id then
                return true
            end
        end
        return false
    end

    local last_update = os.time()
    local function onUpdate(ticks)
        updateOutput()
        askReward()
        -- 如果pve_win解锁下一关
        if checkLastPVE() then
            addRedDot(btn_map0, {
                px = btn_map0:getContentSize().width - 7,
                py = btn_map0:getContentSize().height - 4,
            })
            runParticle(ticks)
        else
            delRedDot(btn_map0)
            stopParticle()
        end
        checkBattleSt()
        if os.time() - last_update < 1 then return end
        last_update = os.time()
        updateLabels()
        if anyReward() then
            addRedDot(btn_reward0, {
                px = btn_reward0:getContentSize().width - 7,
                py = btn_reward0:getContentSize().height - 4,
            })
        else
            delRedDot(btn_reward0)
        end
    end
    layer:scheduleUpdateWithPriorityLua(onUpdate, 0)
        
    if uiParams and uiParams.pop_layer == "stage" then
        schedule(layer, function()
            layer:addChild((require"ui.hook.stage").create(uiParams.stage_id), 1000)
        end)
    end

    require("ui.tutorial").show("ui.hook.main", layer)

    return layer
end

return ui
