-- 主UI
local ui = {}

require "common.func"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local i18n = require "res.i18n"
local audio = require "res.audio"
local particle = require "res.particle"
local player = require "data.player"
local bagdata = require "data.bag"
local gdata = require "data.guild"
local onlinedata = require "data.online"
local bag = require "data.bag"
local tipsequip = require "ui.tips.equip"
local tipsitem = require "ui.tips.item"
local rewards = require "ui.reward"
local NetClient = require "net.netClient"
local netClient = NetClient:getInstance()

local btn_color = ccc3(255, 246, 223)
local btn_color2 = ccc3(0xff, 0xed, 0x72)
local btn_color3 = ccc3(255, 246, 223)

-- uiparams
--     .pop_layer:    layer to show
--     .from_layer:   from which layer, if no pop_layer then  pop from_layer
function ui.create(uiparams)
    local layer = CCLayer:create()

    local mask_topL = img.createUISprite(img.ui.main_mask_topL)
    mask_topL:setScaleX(view.xScale)
    mask_topL:setScaleY(view.yScale)
    mask_topL:setAnchorPoint(CCPoint(0, 1))
    mask_topL:setPosition(ccp(0, view.physical.h))
    layer:addChild(mask_topL)
    local mask_topR = img.createUISprite(img.ui.main_mask_topL)
    mask_topR:setFlipX(true)
    mask_topR:setScaleX(view.xScale)
    mask_topR:setScaleY(view.yScale)
    mask_topR:setAnchorPoint(CCPoint(1, 1))
    mask_topR:setPosition(ccp(view.physical.w, view.physical.h))
    layer:addChild(mask_topR)
    local mask_bottom = img.createUISprite(img.ui.main_mask_bottom)
    --mask_bottom:setPreferredSize(CCSizeMake(960, 113))
    mask_bottom:setScaleX(view.physical.w / 6)
    mask_bottom:setScaleY(view.minScale)
    mask_bottom:setAnchorPoint(CCPoint(0, 0))
    mask_bottom:setPosition(ccp(0, 0))
    layer:addChild(mask_bottom)

    -- for animation
    local entry_offset = 120
    local top_container = CCSprite:create()
    top_container:setContentSize(CCSizeMake(960, 576))
    top_container:setScale(view.minScale)
    top_container:setPosition(scalep(480, 288+entry_offset))
    layer:addChild(top_container)
    local right_container = CCSprite:create()
    right_container:setContentSize(CCSizeMake(960, 576))
    right_container:setScale(view.minScale)
    right_container:setPosition(scalep(480+entry_offset, 288))
    layer:addChild(right_container)
    local bottom_container = CCSprite:create()
    bottom_container:setContentSize(CCSizeMake(960, 576))
    bottom_container:setScale(view.minScale)
    bottom_container:setPosition(scalep(480, 288-entry_offset))
    layer:addChild(bottom_container)
    local left_container = CCSprite:create()
    left_container:setContentSize(CCSizeMake(960, 576))
    left_container:setScale(view.minScale)
    left_container:setPosition(scalep(480-entry_offset, 288))
    layer:addChild(left_container)

    local main_list_bg = img.createUI9Sprite(img.ui.main_list_bg)
    main_list_bg:setPreferredSize(CCSizeMake(80, 388))
    main_list_bg:setAnchorPoint(CCPoint(0.5, 1))
    main_list_bg:setPosition(CCPoint(960-45, 576-7))
    right_container:addChild(main_list_bg)
    local btn_list_fold0 = img.createUISprite(img.ui.main_btn_fold)
    local btn_list_unfold0 = img.createUISprite(img.ui.main_btn_unfold)
    local btn_list_fold = SpineMenuItem:create(json.ui.button, btn_list_fold0)
    btn_list_fold:setPosition(CCPoint(960-45, 576-5-25))
    local btn_list_fold_menu = CCMenu:createWithItem(btn_list_fold)
    btn_list_fold_menu:setPosition(CCPoint(0, 0))
    right_container:addChild(btn_list_fold_menu)
    local btn_list_unfold = SpineMenuItem:create(json.ui.button, btn_list_unfold0)
    btn_list_unfold:setPosition(CCPoint(960-45, 576-5-25))
    local btn_list_unfold_menu = CCMenu:createWithItem(btn_list_unfold)
    btn_list_unfold_menu:setPosition(CCPoint(0, 0))
    right_container:addChild(btn_list_unfold_menu)
    btn_list_unfold:setVisible(false)

    autoLayoutShift(main_list_bg)
    autoLayoutShift(btn_list_fold)
    autoLayoutShift(btn_list_unfold)

    -- player info
    --local player_bg = img.createUISprite(img.ui.main_player_bg)
    local player_bg = CCSprite:create()
    player_bg:setContentSize(CCSizeMake(82, 111))
    player_bg:setAnchorPoint(CCPoint(0, 1))
    player_bg:setPosition(CCPoint(0, 576))
    top_container:addChild(player_bg)
    autoLayoutShift(player_bg)
    -- player logo
    local btn_logo0 = CCSprite:create()
    btn_logo0:setContentSize(CCSizeMake(78, 78))
    --[[local head_bg = img.createUISprite(img.ui.head_bg)
    head_bg:setPosition(CCPoint(39, 39))
    btn_logo0:addChild(head_bg)--]]
    local btn_logo = HHMenuItem:createWithScale(btn_logo0, 1)
    btn_logo:setPosition(CCPoint(40, 70))
    local btn_logo_menu = CCMenu:createWithItem(btn_logo)
    btn_logo_menu:setPosition(CCPoint(0, 0))
    player_bg:addChild(btn_logo_menu)
    -- 公会战头像框
    if player.final_rank then
        addHeadBox(btn_logo, player.final_rank, 122)
    end
    addRedDot(btn_logo, {
        px=btn_logo:getContentSize().width-5,
        py=btn_logo:getContentSize().height-5,
    })
    delRedDot(btn_logo)
    local function updateLogo()
        if not btn_logo.logo or player.logo ~= btn_logo.logo then
            if btn_logo:getChildByTag(111) then
                btn_logo:removeChildByTag(111)
            end
            --[[local player_logo = img.createPlayerHeadById(player.logo)
            local cfghead = require "config.head"
            local cfghero = require "config.hero"
            if (cfghead[player.logo] and cfghead[player.logo].isShine) or (not cfghead[player.logo] and cfghero[player.logo] and cfghero[player.logo].maxStar == 10) then
                json.load(json.ui.touxiang)
                aniTouxiang = DHSkeletonAnimation:createWithKey(json.ui.touxiang)
                aniTouxiang:scheduleUpdateLua()
                aniTouxiang:playAnimation("animation", -1)
                aniTouxiang:setAnchorPoint(CCPoint(0.5, 0))
                aniTouxiang:setPosition(player_logo:getContentSize().width/2, player_logo:getContentSize().height/2)
                player_logo:addChild(aniTouxiang)
            end
            player_logo:setScale(0.9)
            player_logo:setPosition(CCPoint(btn_logo:getContentSize().width/2, btn_logo:getContentSize().height/2))
			img.fixOfficialScale(player_logo, "hero")--]]
			
			local player_logo = img.createPlayerHead(player.logo)
			player_logo:setScale(0.9)
            player_logo:setPosition(CCPoint(btn_logo:getContentSize().width/2, btn_logo:getContentSize().height/2))
			
            btn_logo:addChild(player_logo, 111, 111)
            btn_logo.logo = player.logo
            btn_logo.player_logo = player_logo
        end
    end
    btn_logo:registerScriptTapHandler(function()
        layer:addChild(require("ui.player.main").create(), 1000)
        audio.play(audio.button)
    end)
    updateLogo()
    -- main_lt
    local main_lt = img.createUISprite(img.ui.main_lt)
    main_lt:setAnchorPoint(CCPoint(0, 1))
    main_lt:setPosition(CCPoint(0, 576))
    top_container:addChild(main_lt, 5)
    autoLayoutShift(main_lt)
    -- player name
    --local lbl_player_name = lbl.createFontTTF(18, player.name, ccc3(0xff, 0xff, 0xff))
    --lbl_player_name:setAnchorPoint(CCPoint(0, 1))
    --lbl_player_name:setPosition(CCPoint(player_bg:getContentSize().width+10, 
    --            player_bg:getContentSize().height-10))
    --player_bg:addChild(lbl_player_name)
    --lbl_player_name.name = player.name
    -- player lv
    local player_lv_bg = img.createUISprite(img.ui.main_lv_bg)
    player_lv_bg:setAnchorPoint(CCPoint(0.5, 0.5))
    player_lv_bg:setPosition(CCPoint(19, 42))
    player_bg:addChild(player_lv_bg)
    local lbl_player_lv = lbl.createFont2(14, "" .. player.lv())
    lbl_player_lv:setPosition(CCPoint(player_lv_bg:getContentSize().width/2, player_lv_bg:getContentSize().height/2))
    player_lv_bg:addChild(lbl_player_lv)
    lbl_player_lv.lv = player.lv()
    -- player vip
    local vip_a ={1,1,1,2,2,2,3,3,3,4,4,4,4,4,4,4,4,4,4,4,4,4}  --图标等级
    vip_a[0] = 1
    local vip_c1 = ccc3(0xff, 0xd1, 0x79)
    local vip_c2 = ccc3(0xe8, 0xfb, 0xff)
    local vip_c3 = ccc3(0xff, 0xf4, 0x78)
    local vip_c4 = ccc3(0x8a, 0xf8, 0xff)
    local vip_c = {vip_c1, vip_c1, vip_c1, 
                   vip_c2, vip_c2, vip_c2, 
                   vip_c3, vip_c3, vip_c3, 
                   vip_c4, vip_c4, vip_c4, vip_c4, vip_c4, vip_c4, vip_c4, vip_c4, vip_c4, vip_c4, vip_c4, vip_c4, }
    vip_c[0] = vip_c1
    json.load(json.ui.ic_vip)
    local vip_bg = CCSprite:create()
    vip_bg:setContentSize(CCSizeMake(58, 58))
    local ic_vip = DHSkeletonAnimation:createWithKey(json.ui.ic_vip)
    ic_vip:scheduleUpdateLua()
    ic_vip:playAnimation("" .. vip_a[player.vipLv()], -1)
    ic_vip:setPosition(CCPoint(29, 29))
    vip_bg:addChild(ic_vip)
    local useless_node = CCNode:create()
    local lbl_player_vip = lbl.createFont2(18, player.vipLv(), ccc3(0xff, 0xdc, 0x82))
    lbl_player_vip:setColor(vip_c[player.vipLv()])
    --lbl_player_vip:setPosition(CCPoint(vip_bg:getContentSize().width/2, vip_bg:getContentSize().height/2))
    --vip_bg:addChild(lbl_player_vip)
    useless_node:addChild(lbl_player_vip)
    ic_vip:addChildFollowSlot("code_num", useless_node)
    lbl_player_vip.vip = player.vipLv()
    local btn_vip = SpineMenuItem:create(json.ui.button, vip_bg)
    btn_vip:setPosition(CCPoint(41, 0))

    local btn_vip_menu = CCMenu:createWithItem(btn_vip)
    btn_vip_menu:setPosition(CCPoint(0, 0))
    player_bg:addChild(btn_vip_menu)
    btn_vip:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer:addChild((require "ui.shop.main").create("vip"), 1000)
    end)
    if player.vipLv() < 1 then
        btn_vip:setVisible(false)
    end
    -- money bar
    local moneybar = require "ui.moneybar"
    local moneybar_ins = moneybar.create()
    local moneyContainer = CCNode:create()
    moneyContainer:addChild(moneybar_ins)
    --moneybar_ins.container:setScale(1)
    moneyContainer:setPosition(0, entry_offset)
    layer:addChild(moneyContainer, 100)

    -- shop bg
    --local shop_bg = img.createUISprite(img.ui.main_btn_shop_bg)
    local shop_bg = CCSprite:create()
    shop_bg:setContentSize(CCSizeMake(99, 110))
    shop_bg:setAnchorPoint(CCPoint(1, 0))
    shop_bg:setPosition(CCPoint(960, 0))
    bottom_container:addChild(shop_bg)
    autoLayoutShift(shop_bg)
    -- main_rt
    --local main_rt = img.createUISprite(img.ui.main_rt)
    --main_rt:setAnchorPoint(CCPoint(1, 1))
    --main_rt:setPosition(CCPoint(960, 576))
    --top_container:addChild(main_rt, 5)
    -- btn shop
    local btn_shop0 = img.createUISprite(img.ui.main_btn_shop)
    local btn_shop = HHMenuItem:createWithScale(btn_shop0, 1)
    btn_shop:setPosition(CCPoint(shop_bg:getContentSize().width-54, shop_bg:getContentSize().height-58))
    local btn_shop_menu = CCMenu:createWithItem(btn_shop)
    btn_shop_menu:setPosition(CCPoint(0, 0))
    shop_bg:addChild(btn_shop_menu)

    btn_shop:registerScriptTapHandler(function()
        delayBtnEnable(btn_shop)
        audio.play(audio.button)
        layer:addChild(require("ui.shop.main").create(), 2000)
    end)
    
    --local main_icon_start_x = 832
    --local main_icon_start_y = 125
    local main_icon_step_x = -82
    local main_icon_step_y = 77
    local main_icon_pos_x = 916
    local main_icon_pos_y = 44

    local particle_scale = view.minScale
    local particle_shop = particle.create("ui_shop")
    particle_shop:setScale(particle_scale)
    particle_shop:setPosition(scalep(910, 65))
    layer:addChild(particle_shop, 100)
    autoLayoutShift(particle_shop, false, true, false, true)

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

    shine_particle:setVisible(false)
    shine_particle2:setVisible(false)

    -- particle animation params
    local particle_cx = view.minX + (960-144) * view.minScale --gift_hero_menu_item:getContentSize().width/2
    local particle_cy = view.minY + (576-46) * view.minScale --gift_hero_menu_item:getContentSize().height/2
    local particle_speed = 4
    local particle_radius = 36 * view.minScale
    local particle_angle = 0
    local function runParticle(dt)
        shine_particle:setVisible(true)
        shine_particle2:setVisible(true)
        particle_angle = particle_angle + particle_speed * dt
        if particle_angle > 360 then
            particle_angle = particle_angle - 360 
        end
        local particle_pos_x = particle_cx + particle_radius * math.sin(particle_angle)
        local particle_pos_y = particle_cy + particle_radius * math.cos(particle_angle)
        shine_particle:setPosition(CCPoint(particle_pos_x, particle_pos_y))
        shine_particle2:setPosition(CCPoint(particle_pos_x, particle_pos_y))
    end
    local function stopParticle()
        shine_particle:setVisible(false)
        shine_particle2:setVisible(false)
    end
    -- first pay
    local fpay_particle = particle.create("loop_shine_1")
    fpay_particle:setStartSize(particle_scale * (fpay_particle:getStartSize()-13))
    fpay_particle:setStartSizeVar(particle_scale * fpay_particle:getStartSizeVar())
    fpay_particle:setEndSize(particle_scale * fpay_particle:getEndSize())
    fpay_particle:setEndSizeVar(particle_scale * fpay_particle:getEndSizeVar())
    layer:addChild(fpay_particle, 110)
    local fpay_particle2 = particle.create("loop_shine_2")
    fpay_particle2:setStartSize(particle_scale * (fpay_particle2:getStartSize()-0))
    fpay_particle2:setStartSizeVar(particle_scale * fpay_particle2:getStartSizeVar())
    fpay_particle2:setEndSize(particle_scale * fpay_particle2:getEndSize())
    fpay_particle2:setEndSizeVar(particle_scale * fpay_particle2:getEndSizeVar())
    layer:addChild(fpay_particle2, 105)

    fpay_particle:setVisible(false)
    fpay_particle2:setVisible(false)

    local fpay_particle_cx = view.minX + (960-234) * view.minScale 
    local fpay_particle_cy = view.minY + (576-46) * view.minScale 
    local fpay_particle_speed = 4
    local fpay_particle_radius = 32 * view.minScale
    local fpay_particle_angle = 0
    local function runFpayParticle(dt)
        fpay_particle:setVisible(true)
        fpay_particle2:setVisible(true)
        fpay_particle_angle = fpay_particle_angle + fpay_particle_speed * dt
        if fpay_particle_angle > 360 then
            fpay_particle_angle = fpay_particle_angle - 360 
        end
        local fpay_particle_pos_x = fpay_particle_cx + fpay_particle_radius * math.sin(fpay_particle_angle)
        local fpay_particle_pos_y = fpay_particle_cy + fpay_particle_radius * math.cos(fpay_particle_angle)
        fpay_particle:setPosition(CCPoint(fpay_particle_pos_x, fpay_particle_pos_y))
        fpay_particle2:setPosition(CCPoint(fpay_particle_pos_x, fpay_particle_pos_y))
    end
    local function stopFpayParticle()
        fpay_particle:setVisible(false)
        fpay_particle2:setVisible(false)
    end

    -- online reward
    local online_particle = particle.create("loop_shine_1")
    online_particle:setStartSize(particle_scale * (online_particle:getStartSize()-13))
    online_particle:setStartSizeVar(particle_scale * online_particle:getStartSizeVar())
    online_particle:setEndSize(particle_scale * online_particle:getEndSize())
    online_particle:setEndSizeVar(particle_scale * online_particle:getEndSizeVar())
    layer:addChild(online_particle, 110)
    local online_particle2 = particle.create("loop_shine_2")
    online_particle2:setStartSize(particle_scale * (online_particle2:getStartSize()-0))
    online_particle2:setStartSizeVar(particle_scale * online_particle2:getStartSizeVar())
    online_particle2:setEndSize(particle_scale * online_particle2:getEndSize())
    online_particle2:setEndSizeVar(particle_scale * online_particle2:getEndSizeVar())
    layer:addChild(online_particle2, 105)
    local online_particle_speed = 4
    local online_particle_radius = 32 * view.minScale
    local online_particle_angle = 0
    local function runOnlineParticle(dt, node)
        -- local online_particle_cx = view.minX + 130 * view.minScale 
        -- local online_particle_cy = view.minY + (576 - 46) * view.minScale
        local pos = node:convertToWorldSpace(CCPoint(node:getContentSize().width * 0.5, node:getContentSize().height * 0.5))
        local online_particle_cx = pos.x
        local online_particle_cy = pos.y

        online_particle:setVisible(true)
        online_particle2:setVisible(true)
        online_particle_angle = online_particle_angle + online_particle_speed * dt
        if online_particle_angle > 360 then
            online_particle_angle = online_particle_angle - 360 
        end
        local online_particle_pos_x = online_particle_cx + online_particle_radius * math.sin(online_particle_angle)
        local online_particle_pos_y = online_particle_cy + online_particle_radius * math.cos(online_particle_angle)
        online_particle:setPosition(CCPoint(online_particle_pos_x, online_particle_pos_y))
        online_particle2:setPosition(CCPoint(online_particle_pos_x, online_particle_pos_y))
    end
    local function stopOnlineParticle()
        online_particle:setVisible(false)
        online_particle2:setVisible(false)
    end

    local icon_offset_y = 366
    local icon_step_y = 72
    -- msg
    --local msg_bg = img.createUI9Sprite(img.ui.main_msg_bg)
    --msg_bg:setPreferredSize(CCSizeMake(421, 74))
    --msg_bg:setScale(view.minScale)
    --msg_bg:setAnchorPoint(CCPoint(0, 0))
    --msg_bg:setPosition(CCPoint(view.minX, view.minY))
    --layer:addChild(msg_bg)
    -- btn_bubble
    local btn_bubble0 = img.createUISprite(img.ui.main_icon_bubble)
    addRedDot(btn_bubble0, {
        px=btn_bubble0:getContentSize().width-20,
        py=btn_bubble0:getContentSize().height-20,
    }, 2.0)
    delRedDot(btn_bubble0)
    local btn_bubble = SpineMenuItem:create(json.ui.button, btn_bubble0)
    btn_bubble:setScale(0.5)
    btn_bubble:setPosition(CCPoint(35, icon_offset_y))
    local btn_bubble_menu = CCMenu:createWithItem(btn_bubble)
    btn_bubble_menu:setPosition(CCPoint(0, 0))
    left_container:addChild(btn_bubble_menu)
    btn_bubble:registerScriptTapHandler(function()
        delayBtnEnable(btn_bubble)
        audio.play(audio.button)
        local chatdata = require "data.chat"
        if not chatdata.isSynced() then
            addWaitNet()
            chatdata.sync(function(__data)
                delWaitNet()
                chatdata.synced()       -- 标记 已同步
                if __data and __data.msgs then
                    chatdata.addMsgs(__data.msgs)
                end
                chatdata.registEvent()   -- 注册推送处理
                if layer and not tolua.isnull(layer) then
                    layer:addChild((require"ui.chat.main").create(), 1000)
                end
            end)
        else
            layer:addChild((require"ui.chat.main").create(), 1000)
        end
    end)
    autoLayoutShift(btn_bubble, nil, true)

    -- mail
    local mail_btn_0 = img.createUISprite(img.ui.main_icon_mail)
    addRedDot(mail_btn_0, {
        px=mail_btn_0:getContentSize().width-20,
        py=mail_btn_0:getContentSize().height-20,
    }, 2.0)
    delRedDot(mail_btn_0)
    local mail_btn = SpineMenuItem:create(json.ui.button, mail_btn_0)
    mail_btn:setScale(0.5)
    mail_btn:setPosition(CCPoint(35, icon_offset_y-icon_step_y*1))
    mail_btn:registerScriptTapHandler(function()
        delayBtnEnable(mail_btn)
        audio.play(audio.button)
        local maillayer = require "ui.mail.main"
        layer:addChild(maillayer.create(), 1000)
    end)
    local mail_menu = CCMenu:createWithItem(mail_btn)
    mail_menu:setPosition(CCPoint(0,0))
    left_container:addChild(mail_menu, 101)

    autoLayoutShift(mail_btn, nil, true)

    -- friend
    local friend_btn_0 = img.createUISprite(img.ui.main_icon_friend)
    addRedDot(friend_btn_0, {
        px=friend_btn_0:getContentSize().width-20,
        py=friend_btn_0:getContentSize().height-20,
    }, 2.0)
    delRedDot(friend_btn_0)
    local friend_btn = SpineMenuItem:create(json.ui.button, friend_btn_0)
    friend_btn:setScale(0.5)
    friend_btn:setPosition(CCPoint(35, icon_offset_y-icon_step_y*2))
    friend_btn:registerScriptTapHandler(function()
        delayBtnEnable(friend_btn)
        local friends = require "ui.friends.main"
        layer:addChild(friends.create(),200)
        audio.play(audio.button)
    end)
    local friend_menu = CCMenu:createWithItem(friend_btn)
    friend_menu:setPosition(CCPoint(0,0))
    left_container:addChild(friend_menu, 101)

    autoLayoutShift(friend_btn, nil, true)

    -- feed
    local feed_btn_0 = img.createUISprite(img.ui.main_icon_feed)
    addRedDot(feed_btn_0, {
        px=feed_btn_0:getContentSize().width-20,
        py=feed_btn_0:getContentSize().height-20,
    }, 2.0)
    delRedDot(feed_btn_0)
    local feed_btn = SpineMenuItem:create(json.ui.button, feed_btn_0)
    feed_btn:setScale(0.5)
    feed_btn:setPosition(CCPoint(35, icon_offset_y-icon_step_y*3))
    feed_btn:registerScriptTapHandler(function()
        delayBtnEnable(feed_btn)
        audio.play(audio.button)
        local feedui = require "ui.setting.feed"
        layer:addChild(feedui.create(true), 200)
    end)
    local feed_menu = CCMenu:createWithItem(feed_btn)
    feed_menu:setPosition(CCPoint(0,0))
    left_container:addChild(feed_menu, 101)

    autoLayoutShift(feed_btn, nil, true)

    -- setting
    local setting_btn_0 = img.createUISprite(img.ui.main_icon_setting)
    --addRedDot(setting_btn_0)
    --delRedDot(setting_btn_0)
    local lbl_icon_setting = lbl.create({font=2, size=14, text=i18n.global.main_btn_setting.string, color=btn_color3, cn={size=16}, pt={size=14}})
    lbl_icon_setting:setPosition(CCPoint(setting_btn_0:getContentSize().width/2-0, 9))
    setting_btn_0:addChild(lbl_icon_setting, 1000)
    local setting_btn = SpineMenuItem:create(json.ui.button, setting_btn_0)
    --setting_btn:setScale(view.minScale)
    --setting_btn:setPosition(CCPoint(main_icon_pos_x+0*main_icon_step_x, main_icon_pos_y+0*main_icon_step_y))
    setting_btn:setPosition(CCPoint(40, 60+0*main_icon_step_y))
    setting_btn:registerScriptTapHandler(function()
        delayBtnEnable(setting_btn)
        audio.play(audio.button)
        layer:addChild((require"ui.setting.option").create(true), 1000)
    end)
    local setting_menu = CCMenu:createWithItem(setting_btn)
    setting_menu:setPosition(CCPoint(0,0))
    main_list_bg:addChild(setting_menu, 101)

    -- hero
    local hero_btn_0 = img.createUISprite(img.ui.main_icon_hero)
    addRedDot(hero_btn_0)
    delRedDot(hero_btn_0)
    local lbl_icon_hero = lbl.create({font=2, size=16, text=i18n.global.main_btn_hero.string, color=btn_color3, us={size=16}, pt={size=14}})
    lbl_icon_hero:setPosition(CCPoint(hero_btn_0:getContentSize().width/2, 6))
    hero_btn_0:addChild(lbl_icon_hero, 1000)
    local hero_btn = SpineMenuItem:create(json.ui.button, hero_btn_0)
    --hero_btn:setScale(view.minScale)
    hero_btn:setPosition(CCPoint(main_icon_pos_x+1*main_icon_step_x-25, main_icon_pos_y+0*main_icon_step_y))
    hero_btn:registerScriptTapHandler(function()
        delayBtnEnable(hero_btn)
        audio.play(audio.button)
        replaceScene(require("ui.herolist.main").create())
    end)
    local hero_menu = CCMenu:createWithItem(hero_btn)
    hero_menu:setPosition(CCPoint(0,0))
    bottom_container:addChild(hero_menu, 101)

    autoLayoutShift(hero_btn, nil, nil, nil, true)

    -- bag
    local bag_btn_0 = img.createUISprite(img.ui.main_icon_bag)
    addRedDot(bag_btn_0, {
        px=bag_btn_0:getContentSize().width-5,
        py=bag_btn_0:getContentSize().height-15,
    })
    delRedDot(bag_btn_0)
    local lbl_icon_bag = lbl.create({font=2, size=16, text=i18n.global.main_btn_bag.string, color=btn_color3, us={size=16}, pt={size=14}})
    lbl_icon_bag:setPosition(CCPoint(bag_btn_0:getContentSize().width/2, 6))
    bag_btn_0:addChild(lbl_icon_bag, 1000)
    local bag_btn = SpineMenuItem:create(json.ui.button, bag_btn_0)
    --bag_btn:setScale(view.minScale)
    bag_btn:setPosition(CCPoint(main_icon_pos_x+2*main_icon_step_x-25, main_icon_pos_y+0*main_icon_step_y))
    bag_btn:registerScriptTapHandler(function()
        delayBtnEnable(bag_btn)
        audio.play(audio.button)
        replaceScene((require "ui.bag.main").create("town"))
    end)
    local bag_menu = CCMenu:createWithItem(bag_btn)
    bag_menu:setPosition(CCPoint(0,0))
    bottom_container:addChild(bag_menu, 101)

    autoLayoutShift(bag_btn, nil, nil, nil, true)

    -- guild
    local guild_btn_0 = img.createUISprite(img.ui.main_icon_guild)
    addRedDot(guild_btn_0, {
        px=guild_btn_0:getContentSize().width-5,
        py=guild_btn_0:getContentSize().height-15,
    })
    delRedDot(guild_btn_0)
    local lbl_icon_guild = lbl.create({font=2, size=16, text=i18n.global.main_btn_guild.string, color=btn_color3, us={size=16}, pt={size=14}})
    lbl_icon_guild:setPosition(CCPoint(guild_btn_0:getContentSize().width/2, 6))
    guild_btn_0:addChild(lbl_icon_guild, 1000)
    local guild_btn = SpineMenuItem:create(json.ui.button, guild_btn_0)
    --guild_btn:setScale(view.minScale)
    guild_btn:setPosition(CCPoint(main_icon_pos_x+3*main_icon_step_x-25, main_icon_pos_y+0*main_icon_step_y))
    guild_btn:registerScriptTapHandler(function()
        delayBtnEnable(guild_btn)
        audio.play(audio.button)
        if BUILD_ENTRIES_ENABLE and player.lv() < UNLOCK_GUILD_LEVEL then
            showToast(string.format(i18n.global.func_need_lv.string, UNLOCK_GUILD_LEVEL))
            return
        end
        if player.gid and player.gid > 0 and not gdata.IsInit() then
            local gparams = {
                sid = player.sid,
            }
            addWaitNet()
            netClient:guild_sync(gparams, function(__data)
                delWaitNet()
                tbl2string(__data)
                if __data .status ~= 0 then
                    showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                    return
                end
                gdata.init(__data)
                replaceScene((require"ui.guild.main").create())
            end)
        elseif player.gid and player.gid > 0 and gdata.IsInit() then
            replaceScene((require"ui.guild.main").create())
        else
            layer:addChild((require"ui.guild.recommend").create(1, true), 1000)
        end
    end)
    local guild_menu = CCMenu:createWithItem(guild_btn)
    guild_menu:setPosition(CCPoint(0,0))
    bottom_container:addChild(guild_menu, 101)

    autoLayoutShift(guild_btn, nil, nil, nil, true)

    -- pet(战宠)
    local pet_img = img.createUISprite(img.ui.main_icon_pet)
    local pet_btn = SpineMenuItem:create(json.ui.button, pet_img)
    local pet_label = lbl.create({font=2, size=16, text=i18n.global.main_btn_pet.string, color=btn_color3, us={size=16}, pt={size=14}})
    pet_label:setPosition(CCPoint(pet_btn:getContentSize().width/2, 6))
    pet_img:addChild(pet_label, 1000)
    pet_btn:setPosition(CCPoint(main_icon_pos_x+4*main_icon_step_x-25, main_icon_pos_y+0*main_icon_step_y))
    pet_btn:registerScriptTapHandler(function ()
        audio.play(audio.button)
        if BUILD_ENTRIES_ENABLE and player.lv() < UNLOCK_PET then
            showToast(string.format(i18n.global.func_need_lv.string, UNLOCK_PET))
            return
        end
        replaceScene(require("ui.pet.main").create())
    end)
    local pet_menu = CCMenu:createWithItem(pet_btn)
    pet_menu:setPosition(CCPoint(0,0))
    bottom_container:addChild(pet_menu, 101)
    
    if player.isSeasonal() then
        local ebutton2_img = img.createUISprite(img.ui.main_icon_reward)
        local ebutton2_btn = SpineMenuItem:create(json.ui.button, ebutton2_img)
        local ebutton2_label = lbl.create({font=2, size=16, text="Season", color=btn_color3, us={size=16}, pt={size=14}})
        ebutton2_label:setPosition(CCPoint(ebutton2_btn:getContentSize().width/2, 6))
        ebutton2_img:addChild(ebutton2_label, 1000)
        ebutton2_btn:setPosition(CCPoint(main_icon_pos_x+7*main_icon_step_x-25, main_icon_pos_y+0*main_icon_step_y))
        ebutton2_btn:registerScriptTapHandler(function ()
            audio.play(audio.button)
            layer:addChild(require("ui.season.main").create(), 1000)
        end)
        local ebutton2_menu = CCMenu:createWithItem(ebutton2_btn)
        ebutton2_menu:setPosition(CCPoint(0,0))
        bottom_container:addChild(ebutton2_menu, 101)
        
        autoLayoutShift(ebutton2_btn, nil, nil, nil, true)
    end

    
    local ebutton1_img = img.createUISprite(img.ui.main_icon_feats)
    local ebutton1_btn = SpineMenuItem:create(json.ui.button, ebutton1_img)
    local ebutton1_label = lbl.create({font=2, size=16, text=i18n.global.foodbag_label.string, color=btn_color3, us={size=16}, pt={size=14}})
    ebutton1_label:setPosition(CCPoint(ebutton1_btn:getContentSize().width/2, 6))
    ebutton1_img:addChild(ebutton1_label, 1000)
    ebutton1_btn:setPosition(CCPoint(main_icon_pos_x+6*main_icon_step_x-25, main_icon_pos_y+0*main_icon_step_y))
    ebutton1_btn:registerScriptTapHandler(function ()
        audio.play(audio.button)
        replaceScene(require("ui.foodbag.main").create())
    end)
    local ebutton1_menu = CCMenu:createWithItem(ebutton1_btn)
    ebutton1_menu:setPosition(CCPoint(0,0))
    bottom_container:addChild(ebutton1_menu, 101)
    
    autoLayoutShift(ebutton1_btn, nil, nil, nil, true)


    autoLayoutShift(pet_btn, nil, nil, nil, true)

    -- skin
    local skin_img = img.createUISprite(img.ui.main_icon_skin)
    local skin_btn = SpineMenuItem:create(json.ui.button, skin_img)
    local skin_label = lbl.create({font=2, size=16, text=i18n.global.main_btn_skin.string, color=btn_color3, us={size=16}, pt={size=14}})
    skin_label:setPosition(CCPoint(skin_btn:getContentSize().width/2, 6))
    skin_img:addChild(skin_label, 1000)
    skin_btn:setPosition(CCPoint(main_icon_pos_x+5*main_icon_step_x-25, main_icon_pos_y+0*main_icon_step_y))
    skin_btn:registerScriptTapHandler(function ()
        audio.play(audio.button)
        --if BUILD_ENTRIES_ENABLE and player.lv() < UNLOCK_PET then
        --    showToast(string.format(i18n.global.func_need_lv.string, UNLOCK_PET))
        --    return
        --end
        replaceScene(require("ui.skin.main").create())
    end)
    local skin_menu = CCMenu:createWithItem(skin_btn)
    skin_menu:setPosition(CCPoint(0,0))
    bottom_container:addChild(skin_menu, 101)

    autoLayoutShift(skin_btn, nil, nil, nil, true)

    -- videoad
    local video_btn_0 = img.createUISprite(img.ui.main_icon_video)
    local video_btn = SpineMenuItem:create(json.ui.button, video_btn_0)
    video_btn:setPosition(CCPoint(230, 576-46))
    local video_btn_menu = CCMenu:createWithItem(video_btn)
    video_btn_menu:setPosition(CCPoint(0, 0))
    top_container:addChild(video_btn_menu, 101)
    local function showVideoBtn()
        local videoData = require "data.videoad"
        if videoData.isAvailable() then
            video_btn:setVisible(true)
            video_btn:setEnabled(true)
        else
            video_btn:setEnabled(false)
            video_btn:setVisible(false)
        end
    end
    showVideoBtn()
    video_btn:registerScriptTapHandler(function()
        delayBtnEnable(video_btn)
        audio.play(audio.button)
        video_btn:setVisible(false)
        layer:addChild((require"ui.videoad.main").create(function()
            video_btn:setVisible(false)
        end), 1000)
    end)
    autoLayoutShift(video_btn, nil, nil, true)

    -- fpay
    local fpay_btn_0 = CCSprite:create()
    fpay_btn_0:setContentSize(CCSizeMake(74, 74))
    fpay_btn_0:setCascadeOpacityEnabled(true)
    local fpay_ani = json.create(json.ui.daojishi)
    fpay_ani:playAnimation("animation", -1)
    fpay_ani:setPosition(CCPoint(37, 37))
    fpay_btn_0:addChild(fpay_ani)
    addRedDot(fpay_btn_0, {
        px=fpay_btn_0:getContentSize().width-15,
        py=fpay_btn_0:getContentSize().height-15,
    })
    delRedDot(fpay_btn_0)
    --local lbl_icon_fpay = lbl.createFont2(14, "", ccc3(0xa5, 0xfd, 0x47))  -- cd
    local lbl_icon_fpay = lbl.create({font=2, size=10, text=i18n.global.town_limit.string, color=btn_color2, cn={size=16}, tw={size=16}, us={size=14}})
    lbl_icon_fpay:setPosition(CCPoint(fpay_btn_0:getContentSize().width/2, 6))
    fpay_btn_0:addChild(lbl_icon_fpay, 1000)
    local fpay_btn = SpineMenuItem:create(json.ui.button, fpay_btn_0)
    --fpay_btn:setScale(0.9)
    --fpay_btn:setScale(view.minScale)
    fpay_btn:setPosition(CCPoint(960-234, 576-46))
    fpay_btn:registerScriptTapHandler(function()
        audio.play(audio.button)
        --layer:addChild(require("ui.firstpay.main").create(), 1000)
        layer:addChild(require("ui.activitylimit.main").create(), 1000)
    end)
    local fpay_menu = CCMenu:createWithItem(fpay_btn)
    fpay_menu:setPosition(CCPoint(0,0))
    top_container:addChild(fpay_menu, 101)
    autoLayoutShift(fpay_btn, nil, nil, nil, true)

    -- online
    local online_btn_0 = CCSprite:create()
    online_btn_0:setContentSize(CCSizeMake(77, 77))
    local online_bg = img.createUISprite(img.ui.main_icon_online)
    online_bg:setPosition(CCPoint(online_btn_0:getContentSize().width/2, 42))
    online_btn_0:addChild(online_bg)
    local function updateOnlineReward()
        if online_bg:getChildByTag(233) then
            online_bg:removeChildByTag(233)
        end
        if onlinedata.id and onlinedata.id > 0 then
            local tmp_reward = onlinedata.getRewardById()[1]
            local tmp_icon
            if tmp_reward.type == 1 then
                tmp_icon = img.createItem(tmp_reward.id, tmp_reward.num)
            elseif tmp_reward.type == 2 then
                tmp_icon = img.createEquip(tmp_reward.id, tmp_reward.num)
            end
            tmp_icon:setScale(0.57)
            tmp_icon:setPosition(CCPoint(39, 29))
            online_bg:addChild(tmp_icon, 1, 233)
        end
    end
    updateOnlineReward()
    local lbl_online_cd = lbl.createFont2(14, "", ccc3(0xa5, 0xfd, 0x47))  -- cd
    lbl_online_cd:setScale(lbl_online_cd:getScale()*0.9)
    lbl_online_cd:setPosition(CCPoint(online_btn_0:getContentSize().width/2, 6))
    online_btn_0:addChild(lbl_online_cd)
    local online_btn = SpineMenuItem:create(json.ui.button, online_btn_0)
    --online_btn:setPosition(CCPoint(main_icon_pos_x+0*main_icon_step_x, 335+1*main_icon_step_y))
    online_btn:setPosition(CCPoint(130, 576-46))

    local online_btn_menu = CCMenu:createWithItem(online_btn)
    online_btn_menu:setPosition(CCPoint(0, 0))
    top_container:addChild(online_btn_menu, 101)

    autoLayoutShift(online_btn, true, false, true, false)

    local function updateOnlineCD(dt)
        if onlinedata.id and onlinedata.id > 0 then
            local remain_cd = onlinedata.cd - (os.time() - onlinedata.pull_time)
            if remain_cd > 0 then
                lbl_online_cd:setVisible(true)
                stopOnlineParticle()
                local time_str = time2string(remain_cd)
                lbl_online_cd:setString(time_str)
            else
                lbl_online_cd:setVisible(false)
                runOnlineParticle(dt, online_btn)
            end
        else
            lbl_online_cd:setVisible(false)
            stopOnlineParticle(dt)
            online_btn:setVisible(false)
        end
    end

    online_btn:registerScriptTapHandler(function()
        delayBtnEnable(online_btn)
        audio.play(audio.button)
        if not onlinedata.id or onlinedata.id <= 0 then
            stopOnlineParticle(dt)
            online_btn:setVisible(false)
            return
        end
        local remain_cd = onlinedata.cd - (os.time() - onlinedata.pull_time)
        if remain_cd > 0 then    -- view item
            local tmp_reward = onlinedata.getRewardById()[1]
            if tmp_reward.type == 1 then
                local tmp_tip = tipsitem.createForShow({id=tmp_reward.id})
                layer:addChild(tmp_tip, 1000)
            elseif tmp_reward.type == 2 then
                local tmp_tip = tipsequip.createById(tmp_reward.id)
                layer:addChild(tmp_tip, 1000)
            end
        else
            local nParams = {
                sid = player.sid,
                id = onlinedata.id,
            }
            addWaitNet()
            netClient:online_claim(nParams, function(__data)
                delWaitNet()
                tbl2string(__data)
                if __data.status < 0 then
                    showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                    onlinedata.sync(__data.online)
                    updateOnlineReward()
                    return
                else
                    local tmp_pbbag = reward2Pbbag(onlinedata.getRewardById())
                    bagdata.addRewards(tmp_pbbag)
                    CCDirector:sharedDirector():getRunningScene():addChild(rewards.createFloating(tmp_pbbag), 100000)
                    onlinedata.sync(__data.online)
                    if onlinedata.id <= 0 then
                        online_btn:setVisible(false)
                        stopOnlineParticle()
                    else
                        updateOnlineReward()
                    end
                end
            end)
        end
    end)

    -- gift
    local gift_btn_0 = img.createUISprite(img.ui.main_icon_activity)
    addRedDot(gift_btn_0, {
        px=gift_btn_0:getContentSize().width-15,
        py=gift_btn_0:getContentSize().height-15,
    })
    delRedDot(gift_btn_0)
    local lbl_icon_gift = lbl.create({font=2, size=10, text=i18n.global.main_btn_gift.string, color=btn_color2, cn={size=16}, tw={size=16}, us={size=14}})
    lbl_icon_gift:setPosition(CCPoint(gift_btn_0:getContentSize().width/2, 6))
    gift_btn_0:addChild(lbl_icon_gift, 1000)
    local gift_btn = SpineMenuItem:create(json.ui.button, gift_btn_0)
    --gift_btn:setScale(view.minScale)
    --gift_btn:setPosition(CCPoint(main_icon_pos_x+0*main_icon_step_x, 335+1*main_icon_step_y))
    gift_btn:setPosition(CCPoint(960-144, 576-46))
    gift_btn:registerScriptTapHandler(function()
        delayBtnEnable(gift_btn)
        audio.play(audio.button)
        layer:addChild(require("ui.activity.main").create(), 1000)
    end)
    local gift_menu = CCMenu:createWithItem(gift_btn)
    gift_menu:setPosition(CCPoint(0,0))
    top_container:addChild(gift_menu, 101)

    autoLayoutShift(gift_btn, nil, nil, nil, true)

    -- reward
    local reward_btn_0 = img.createUISprite(img.ui.main_icon_reward)
    addRedDot(reward_btn_0, {
        px=reward_btn_0:getContentSize().width-15,
        py=reward_btn_0:getContentSize().height-15,
    })
    delRedDot(reward_btn_0)
    local lbl_icon_reward = lbl.create({font=2, size=14, text=i18n.global.main_btn_reward.string, color=btn_color3, cn={size=16}, tw={size=16}})
    lbl_icon_reward:setPosition(CCPoint(reward_btn_0:getContentSize().width/2, 9))
    reward_btn_0:addChild(lbl_icon_reward, 1000)
    local reward_btn = SpineMenuItem:create(json.ui.button, reward_btn_0)
    --reward_btn:setScale(view.minScale)
    --reward_btn:setPosition(CCPoint(main_icon_pos_x+0*main_icon_step_x, 335-1*main_icon_step_y))
    reward_btn:setPosition(CCPoint(40, 60+2*main_icon_step_y))
    reward_btn:registerScriptTapHandler(function()
        delayBtnEnable(reward_btn)
        --layer:addChild(require("ui.midas.crystal").create(), 2000)
        layer:addChild(require("ui.achieve.main").create(), 1000)
        audio.play(audio.button)
    end)
    local reward_menu = CCMenu:createWithItem(reward_btn)
    reward_menu:setPosition(CCPoint(0,0))
    main_list_bg:addChild(reward_menu, 101)

    -- task
    local task_btn_0 = img.createUISprite(img.ui.main_icon_task)
    addRedDot(task_btn_0, {
        px=task_btn_0:getContentSize().width-15,
        py=task_btn_0:getContentSize().height-15,
    })
    delRedDot(task_btn_0)
    local lbl_icon_task = lbl.create({font=2, size=14, text=i18n.global.main_btn_task.string, color=btn_color3, cn={size=16}, pt={size=14}})
    --local lbl_icon_task = lbl.createFont2(16, "Task", btn_color2)
    lbl_icon_task:setPosition(CCPoint(task_btn_0:getContentSize().width/2, 9))
    task_btn_0:addChild(lbl_icon_task, 1000)
    local task_btn = SpineMenuItem:create(json.ui.button, task_btn_0)
    --task_btn:setScale(view.minScale)
    --task_btn:setPosition(CCPoint(main_icon_pos_x+0*main_icon_step_x, 335-2*main_icon_step_y))
    task_btn:setPosition(CCPoint(40, 60+1*main_icon_step_y))
    task_btn:registerScriptTapHandler(function()
        delayBtnEnable(task_btn)
        audio.play(audio.button)
        if player.lv() < UNLOCK_TASK_LEVEL then
            showToast(string.format(i18n.global.func_need_lv.string, UNLOCK_TASK_LEVEL))
            return
        end
        layer:addChild(require("ui.task.main").create(true), 1000)
    end)
    local task_menu = CCMenu:createWithItem(task_btn)
    task_menu:setPosition(CCPoint(0,0))
    main_list_bg:addChild(task_menu, 101)

    -- challenge
    local challenge_btn_0 = img.createUISprite(img.ui.main_icon_challenge)
    addRedDot(challenge_btn_0, {
        px=challenge_btn_0:getContentSize().width-15,
        py=challenge_btn_0:getContentSize().height-15,
    })
    delRedDot(challenge_btn_0)
    local lbl_icon_challenge = lbl.create({font=2, size=14, text=i18n.global.main_btn_dare.string, color=btn_color3, cn={size=16}, pt={size=14}})
    --local lbl_icon_challenge = lbl.createFont2(16, "challenge", btn_color2)
    lbl_icon_challenge:setPosition(CCPoint(challenge_btn_0:getContentSize().width/2, 9))
    challenge_btn_0:addChild(lbl_icon_challenge, 1000)
    local challenge_btn = SpineMenuItem:create(json.ui.button, challenge_btn_0)
    --challenge_btn:setScale(view.minScale)
    --challenge_btn:setPosition(CCPoint(main_icon_pos_x+0*main_icon_step_x, 335-0*main_icon_step_y))
    challenge_btn:setPosition(CCPoint(40, 60+3*main_icon_step_y))
    local function goDare(_params)
        local daredata = require "data.dare"
        local nParams = {
            sid = player.sid,
        }
        addWaitNet()
        netClient:dare_sync(nParams, function(__data)
            delWaitNet()
            tbl2string(__data)
            daredata.sync(__data)
            if layer and not tolua.isnull(layer) then
                layer:addChild((require"ui.dare.main").create(_params), 1000)
            end
        end)
    end
    challenge_btn:registerScriptTapHandler(function()
        delayBtnEnable(challenge_btn)
        audio.play(audio.button)
        goDare({_anim=true})
    end)
    local challenge_menu = CCMenu:createWithItem(challenge_btn)
    challenge_menu:setPosition(CCPoint(0,0))
    main_list_bg:addChild(challenge_menu, 101)

    btn_list_fold:registerScriptTapHandler(function()
        audio.play(audio.button)
        btn_list_fold:setVisible(false)
        btn_list_unfold:setVisible(true)
        main_list_bg:runAction(createSequence({
            CCScaleTo:create(0.1, 1, 0.01),
            CCCallFunc:create(function()
                main_list_bg:setVisible(false)
            end)
        }))
    end)
    btn_list_unfold:registerScriptTapHandler(function()
        audio.play(audio.button)
        btn_list_fold:setVisible(true)
        btn_list_unfold:setVisible(false)
        main_list_bg:runAction(createSequence({
            CCCallFunc:create(function()
                main_list_bg:setVisible(true)
            end),
            CCScaleTo:create(0.1, 1, 1)
        }))
    end)

    -- entry animation
    local entry_ani = CCArray:create()
    entry_ani:addObject(CCCallFunc:create(function()
        local entry_duration = 0.3
        top_container:runAction(CCEaseOut:create(CCMoveTo:create(entry_duration, scalep(480, 288)), 2))
        right_container:runAction(CCEaseOut:create(CCMoveTo:create(entry_duration, scalep(480, 288)), 2))
        bottom_container:runAction(CCEaseOut:create(CCMoveTo:create(entry_duration, scalep(480, 288)), 2))
        left_container:runAction(CCEaseOut:create(CCMoveTo:create(entry_duration, scalep(480, 288)), 2))
        moneyContainer:runAction(CCEaseOut:create(CCMoveTo:create(entry_duration, CCPoint(0, 0)), 2))
    end))
    layer:runAction(CCSequence:create(entry_ani))

    local last_update = os.time() - 4
    local function onUpdate(ticks)
        updateOnlineCD(ticks)
        updateLogo()
        if lbl_player_lv.lv~= player.lv() then
            lbl_player_lv:setString(tostring(player.lv()))
            lbl_player_lv.lv = player.lv()
        end
        if lbl_player_vip.vip~= player.vipLv() then
            lbl_player_vip:setString(tostring(player.vipLv()))
            lbl_player_vip.vip= player.vipLv()
            ic_vip:playAnimation("" .. vip_a[player.vipLv()], -1)
            lbl_player_vip:setColor(vip_c[player.vipLv()])
        end
        if player.vipLv() < 1 then
            btn_vip:setVisible(false)
        else
            btn_vip:setVisible(true)
        end
        if os.time() - last_update < 3 then
            return
        end
        last_update = os.time()
        -- check reddot
        local chatdata = require "data.chat"
        if chatdata.showRedDot() then
            addRedDot(btn_bubble0, {
                px=btn_bubble0:getContentSize().width-10,
                py=btn_bubble0:getContentSize().height-10,
            })
        else
            delRedDot(btn_bubble0)
        end
        local maildata = require "data.mail"
        if maildata.showRedDot() then
            addRedDot(mail_btn_0, {
                px=mail_btn_0:getContentSize().width-10,
                py=mail_btn_0:getContentSize().height-10,
            })
        else
            delRedDot(mail_btn_0)
        end
        if gdata.showRedDot() then
            addRedDot(guild_btn_0, {
                px=guild_btn_0:getContentSize().width-5,
                py=guild_btn_0:getContentSize().height-5,
            })
        else
            delRedDot(guild_btn_0)
        end

        local pet = require "data.pet"
        if pet.showRedDot() then
            addRedDot(pet_img, {
                px=pet_img:getContentSize().width-5,
                py=pet_img:getContentSize().height-5,
            })
        else
            delRedDot(pet_img)
        end

        if bag.showRedDot() then
            addRedDot(bag_btn_0, {
                px=bag_btn_0:getContentSize().width-5,
                py=bag_btn_0:getContentSize().height-5,
            })
        else
            delRedDot(bag_btn_0)
        end

        local friend = require "data.friend"
        if friend.showRedDot() then
            addRedDot(friend_btn_0, {
                px=friend_btn_0:getContentSize().width-10,
                py=friend_btn_0:getContentSize().height-10,
            })
        else
            delRedDot(friend_btn_0)
        end

        local achieveData = require "data.achieve"
        if achieveData.showRedDot() then
            addRedDot(reward_btn_0, {
                px=reward_btn_0:getContentSize().width-10,
                py=reward_btn_0:getContentSize().height-10,
            })
        else
            delRedDot(reward_btn_0)
        end

        -- videoad
        showVideoBtn()

        -- 解锁新头像
        local headData = require "data.head"
        if headData.showRedDot() then
            addRedDot(btn_logo, {
                px=btn_logo:getContentSize().width-5,
                py=btn_logo:getContentSize().height-5,
            })
        else
            delRedDot(btn_logo)
        end
        -- check any activity
        local activity_data = require "data.activity"
        if activity_data.anyNew() then
            --runParticle(ticks)
            addRedDot(gift_btn_0, {
                px=gift_btn_0:getContentSize().width-15,
                py=gift_btn_0:getContentSize().height-15,
            })
        else
            --stopParticle()
            delRedDot(gift_btn_0)
        end
        -- check dailytask
        local taskdata = require "data.task"
        if taskdata.showRedDot() then
            addRedDot(task_btn_0, {
                px=task_btn_0:getContentSize().width-15,
                py=task_btn_0:getContentSize().height-15,
            })
        else
            delRedDot(task_btn_0)
        end
        -- check limit
        local limitData = require "data.activitylimit"
        if limitData.showLimit() then
            fpay_btn:setVisible(true)
            if limitData.showRedDot() then
                addRedDot(fpay_btn_0, {
                    px=fpay_btn_0:getContentSize().width-15,
                    py=fpay_btn_0:getContentSize().height-15,
                })
            else
                delRedDot(fpay_btn_0)
            end
        else
            fpay_btn:setVisible(false)
        end
    end

    if uiparams then
        print("uiparams.from_layer:", uiparams.from_layer)
    end
    if uiparams and uiparams.from_layer == "language" then
        layer:runAction(CCCallFunc:create(function()
            layer:addChild((require"ui.setting.option").create(), 1000)
        end))
    elseif uiparams and uiparams.from_layer == "task" then
        layer:runAction(CCCallFunc:create(function()
            layer:addChild(require("ui.task.main").create(), 1000)
        end))
    elseif uiparams and uiparams.from_layer == "dareStage" then
        layer:runAction(CCCallFunc:create(function()
            goDare({_anim=true, from_layer="dareStage", type=uiparams.type})
        end))
    elseif uiparams and uiparams.from_layer:beginwith("frdboss_") then
        layer:runAction(CCCallFunc:create(function()
            layer:addChild(require("ui.friends.main").create(uiparams), 1000)
        end))
    elseif uiparams and uiparams.from_layer == "frdpk" then
        layer:runAction(CCCallFunc:create(function()
            layer:addChild(require("ui.friends.main").create(uiparams), 1000)
        end))
    elseif require("data.rateus").isAvailable() then
        layer:runAction(CCCallFunc:create(function()
            layer:addChild(require("ui.rateus.main").create(), 1000)
        end))
    elseif uiparams and uiparams.from_layer:beginwith("brokenboss") then
        layer:runAction(CCCallFunc:create(function()
            layer:addChild(require("ui.activitylimit.main").create("brokenboss"), 1000)
        end))
    elseif uiparams and uiparams.from_layer:beginwith("airisland") then
        layer:runAction(CCCallFunc:create(function()
            local params = {
                sid = player.sid,
                pos = 0,
            }
            addWaitNet()
            netClient:island_land(params, function(__data)
                delWaitNet()
        
                tbl2string(__data)
                local airData = require "data.airisland"
                airData.setLandData(__data)
                replaceScene(require("ui.airisland.fightmain").create())
            end)
            --local params = {
            --    sid = player.sid,
            --}
            --addWaitNet()
            --netClient:island_sync(params, function(__data)
            --    delWaitNet()
        
            --    tbl2string(__data)
            --    airData.setData(__data)
            --    replaceScene(require("ui.airisland.main1").create(__data, "floatland"))
            --end)
        end))
    end


    layer:scheduleUpdateWithPriorityLua(onUpdate, 0)

    addBackEvent(layer)
    function layer.onAndroidBack()
        exitGame(layer)
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
        end
    end)

    layer.initHelperUI = function (rdFlag)
        img.load(img.packedOthers.spine_ui_yindao_face)
        local iconFace = json.create(json.ui.yindao_face)

        if rdFlag then
            local rdNum = math.random(1, 3)--暂时不播放第四个
            if rdNum == 1 then
                iconFace:playAnimation("stand02", -1)
            elseif rdNum == 2 then
                iconFace:playAnimation("stand04", -1)
            elseif rdNum == 3 then
                iconFace:playAnimation("stand05", -1)
            elseif rdNum == 4 then
                iconFace:playAnimation("stand03", -1)--惊讶的表情暂时不用
            end
        else
            iconFace:playAnimation("enter")
            iconFace:appendNextAnimation("stand02", -1)
        end
        
        iconFace:setContentSize(CCSize(110, 110))

        local btnHelper = SpineMenuItem:create(json.ui.button, iconFace)
        btnHelper:setPosition(ccp(53, 53))
        local btnMenu = CCMenu:createWithItem(btnHelper)
        btnMenu:setPosition(CCPoint(0, 0))
        left_container:addChild(btnMenu, 10)
        if isChannel() then
            --btnHelper:setVisible(false)
        end
        btnHelper:registerScriptTapHandler(function()
            audio.play(audio.button)
            layer:addChild((require"ui.town.gotoEnter").create(), 1000)
        end)

        autoLayoutShift(btnHelper)
    end

    local tutorialData = require("data.tutorial")
    if tutorialData.isComplete() then
        layer.initHelperUI(true)
    end

    return layer
end

return ui
