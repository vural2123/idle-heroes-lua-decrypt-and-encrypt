local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local i18n = require "res.i18n"
local json = require "res.json"
local audio = require "res.audio"
local dataGuild = require "data.guild"
local dataPlayer = require "data.player"
local dataHeros = require "data.heros"
local net = require "net.netClient"

local ENEGY_MAX = 6
local ENEGY_DURATION = 3 * 60 * 60
local FIGHT_DURATION = 20

local droidhangComponents = require("dhcomponents.DroidhangComponents")

local guildFightMain = class("guildFightMain", function ()
	return cc.LayerColor:create(cc.c4b(0, 0, 0, POPUP_DARK_OPACITY))
end)

function guildFightMain.create(uiParams)
	return guildFightMain.new(uiParams)
end

function guildFightMain:ctor()
    --资源加载
    img.load(img.packedOthers.spine_ui_baoshihecheng)
    img.load(img.packedOthers.ui_guild_fight)
    img.load(img.packedOthers.spine_ui_guildwar_ui)
    self:registerScriptHandler(function(event)
        if event == "cleanup" then
            img.unload(img.packedOthers.spine_ui_baoshihecheng)
            img.unload(img.packedOthers.ui_guild_fight)
            img.unload(img.packedOthers.spine_ui_guildwar_ui)
        end
    end)

    local bg = img.createUI9Sprite(img.ui.bag_outer)
    bg:setPreferredSize(CCSizeMake(930, 550))
    bg:setAnchorPoint(0.5, 0.5)
    bg:setPosition(scalep(480, 288))
    bg:setScale(view.minScale)
    self:addChild(bg)
    self.bg = bg

    local detailSprite = img.createUISprite(img.ui.btn_help)
    local detailBtn = SpineMenuItem:create(json.ui.button, detailSprite)
    detailBtn:setPosition(710, 505)

    local detailMenu = CCMenu:create()
    detailMenu:setPosition(0, 0)
    bg:addChild(detailMenu, 20)
    detailMenu:addChild(detailBtn)

    detailBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        self:addChild(require("ui.help").create(i18n.global.help_guildFight.string), 1000)
    end)


	-- btn_tabLeft
    local btn_tabLeft0 = img.createLogin9Sprite(img.login.button_9_small_mwhite)
    btn_tabLeft0:setPreferredSize(CCSizeMake(200, 48))
    local btn_tabLeft_sel = img.createLogin9Sprite(img.login.button_9_small_gold)
    btn_tabLeft_sel:setPreferredSize(CCSizeMake(200, 48))
    btn_tabLeft_sel:setPosition(CCPoint(btn_tabLeft0:getContentSize().width/2, btn_tabLeft0:getContentSize().height/2))
    btn_tabLeft0:addChild(btn_tabLeft_sel)
    local lbl_tabLeft = lbl.createFont1(18, i18n.global.guildFight_tab_1.string, ccc3(0x73, 0x3b, 0x05))
    lbl_tabLeft:setPosition(CCPoint(btn_tabLeft0:getContentSize().width/2, btn_tabLeft0:getContentSize().height/2))
    btn_tabLeft0:addChild(lbl_tabLeft)
    local btn_tabLeft = SpineMenuItem:create(json.ui.button, btn_tabLeft0)
    droidhangComponents:mandateNode(btn_tabLeft, "Bz4W_74Fa95")
    local btn_tabLeft_menu = CCMenu:createWithItem(btn_tabLeft)
    btn_tabLeft_menu:setPosition(CCPoint(0, 0))
    bg:addChild(btn_tabLeft_menu, 1)

    -- btn_tabRight
    local btn_tabRight0 = img.createLogin9Sprite(img.login.button_9_small_mwhite)
    btn_tabRight0:setPreferredSize(CCSizeMake(200, 48))
    local btn_tabRight_sel = img.createLogin9Sprite(img.login.button_9_small_gold)
    btn_tabRight_sel:setPreferredSize(CCSizeMake(200, 48))
    btn_tabRight_sel:setPosition(CCPoint(btn_tabRight0:getContentSize().width/2, btn_tabRight0:getContentSize().height/2))
    btn_tabRight0:addChild(btn_tabRight_sel)
    local lbl_tabRight = lbl.createFont1(18, i18n.global.guildFight_tab_2.string, ccc3(0x73, 0x3b, 0x05))
    lbl_tabRight:setPosition(CCPoint(btn_tabRight0:getContentSize().width/2, btn_tabRight0:getContentSize().height/2))
    btn_tabRight0:addChild(lbl_tabRight)
    local btn_tabRight = SpineMenuItem:create(json.ui.button, btn_tabRight0)
    droidhangComponents:mandateNode(btn_tabRight, "wpnE_wchUX5")
    local btn_tabRightmenu = CCMenu:createWithItem(btn_tabRight)
    btn_tabRightmenu:setPosition(CCPoint(0, 0))
    bg:addChild(btn_tabRightmenu, 1)

    btn_tabLeft_sel:setVisible(false)
    btn_tabRight_sel:setVisible(false)

    --touch 
    local touchbeginx, touchbeginy
    local isclick, enegyFlag
    local last_touch_sprite = nil

    local function onTouchBegan(x, y)
        touchbeginx, touchbeginy = x, y
        isclick = true
        if self.rightTabNode and self.enegyBottom then
            local p0 = self.enegyBottom:getParent():convertToNodeSpace(ccp(x, y))
            if p0 and self.enegyBottom:boundingBox():containsPoint(p0) then
                enegyFlag = true
                audio.play(audio.button)
                self.enegyToast:setVisible(true)
                last_touch_sprite = self.enegyBottom
                last_touch_sprite._scale = 1
                playAnimTouchBegin(last_touch_sprite)
                
            end
        end
        return true
    end

    local function onTouchMoved(x, y)
        return true
    end
    local function onTouchEnded(x, y)
        if isclick then
            if enegyFlag == true then
                enegyFlag = false
                if self.rightTabNode then
                    if last_touch_sprite and not tolua.isnull(last_touch_sprite) then
                        playAnimTouchEnd(last_touch_sprite)
                        last_touch_sprite = nil
                    end
                    self.enegyToast:setVisible(false)
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

    self:registerScriptTouchHandler(onTouch , false , -128 , false)
    self:setTouchEnabled(true)

    local function backEvent()
        self:removeFromParentAndCleanup(true)
    end

    -- close btn
    local close0 = img.createUISprite(img.ui.close)
    local closeBtn = SpineMenuItem:create(json.ui.button, close0)
    droidhangComponents:mandateNode(closeBtn, "SCVo_yTQYof")
    local closeMenu = CCMenu:createWithItem(closeBtn)
    closeMenu:setPosition(CCPoint(0, 0))
    bg:addChild(closeMenu, 1)
    closeBtn:registerScriptTapHandler(function()     
        backEvent()
    end)

    addBackEvent(self)
    function self.onAndroidBack()
        backEvent()
    end

    local function onLeftTab()
        btn_tabLeft_sel:setVisible(true)
        btn_tabRight_sel:setVisible(false)

        btn_tabLeft:setEnabled(false)
        btn_tabRight:setEnabled(true)

        if self.demoFightLayer then
            self.demoFightLayer:removeFromParent()
            self.demoFightLayer = nil
        end
        if self.rightTabNode then
            self.rightTabNode:removeFromParent()
            self.rightTabNode = nil
        end
        if self.enegyToast then
            self.enegyToast:removeFromParent()
            self.enegyToast = nil
        end

        local params = {
            sid = dataPlayer.sid,
        }

        addWaitNet()
        net:guild_fight_sync(params, function(__data)
            delWaitNet()
            tbl2string(__data)

            if __data.status < 0 then
                showToast("status:" .. __data.status)
                return 
            end

            if not __data.mbrs then
                __data.mbrs = {}
            end
            if not __data.uids then
                __data.uids = {}
            end
            if not __data.mask then
                __data.mask = {}
            end
            if __data.cd and __data.cd < 0 then
                __data.cd = 0
            end

            local uidMap = {}
            for i, uid in ipairs(__data.uids) do
                uidMap[uid] = i
            end
            table.sort(__data.mbrs, function (a, b)
                if uidMap[a.uid] and uidMap[b.uid] then
                    return uidMap[a.uid] < uidMap[b.uid]
                elseif not uidMap[a.uid] and uidMap[b.uid] then
                    return false
                elseif uidMap[a.uid] and not uidMap[b.uid] then
                    return true
                else
                    return a.uid < b.uid
                end
            end)

            __data.pull_time = os.time()
            self:createLeftTab(__data)
        end)   
    end

    btn_tabLeft:registerScriptTapHandler(function()
        audio.play(audio.button)
        onLeftTab()
    end)

    local function onRightTab()
        if self.guildData.status == 1 and not self.guildData.reg then
            showToast(i18n.global.guiidFight_toast_reg.string)
            return
        end

        btn_tabLeft_sel:setVisible(false)
        btn_tabRight_sel:setVisible(true)

        btn_tabLeft:setEnabled(true)
        btn_tabRight:setEnabled(false)

        if self.leftTabNode then
            self.leftTabNode:removeFromParent()
            self.leftTabNode = nil
        end

        local params = {
            sid = dataPlayer.sid,
        }

        addWaitNet()
        net:guild_fight_sync_2(params, function(__data)
            delWaitNet()

            tbl2string(__data)

            --rightTab temp
            -- local data = {}
            -- data.status = 6
            -- data.tl = 12
            -- data.tl_cd = 5
            -- data.cd = 45
            -- data.guilds = {
            --     {name = "111", sid = 3, logo = 3},
            --     {name = "333", sid = 11, logo = 2},
            --     {name = "111", sid = 3, logo = 3},
            --     {name = "333", sid = 11, logo = 2},
            --     {name = "111", sid = 3, logo = 3},
            --     {name = "333", sid = 11, logo = 2},
            --     {name = "111", sid = 3, logo = 3},
            --     {name = "333", sid = 11, logo = 2},
            --     {name = "111", sid = 3, logo = 3},
            --     {name = "333", sid = 11, logo = 2},
            --     {name = "111", sid = 3, logo = 3},
            --     {name = "333", sid = 11, logo = 2},
            --     {name = "111", sid = 3, logo = 3},
            --     {name = "333", sid = 11, logo = 2},
            --     {name = "111", sid = 3, logo = 3},
            --     -- {name = "333", sid = 11, logo = 2},
            -- }
            -- __data = data

            if __data.status < 0 then
                showToast("status:" .. __data.status)
                return 
            end

            if not __data.guilds then
                __data.guilds = {}
            end

            if __data.cd and __data.cd < 0 then
                __data.cd = 0
            end

            self:createRightTab(__data)
        end)
    end

    btn_tabRight:registerScriptTapHandler(function()
        audio.play(audio.button)
        onRightTab()
    end)

    onLeftTab()

    self.onRightTab = onRightTab
    self.onLeftTab = onLeftTab
end

function guildFightMain:createLeftTab(data)
    -- local tempBg = cc.Sprite:create("temp.png")
    -- tempBg:setPosition(self.bg:getContentSize().width * 0.5, self.bg:getContentSize().height * 0.5)
    -- tempBg:setOpacity(100)
    -- self.bg:addChild(tempBg, 20)

    if data then
        self.guildData = data
    else
        data = self.guildData
    end
    
    data.logo = dataGuild.guildObj.logo
    data.name = dataGuild.guildObj.name
    data.sid = dataPlayer.sid

	if self.leftTabNode then
		self.leftTabNode:removeFromParent()
		self.leftTabNode = nil
	end

	local leftTabNode = cc.Node:create()
	self.leftTabNode = leftTabNode
	self.bg:addChild(leftTabNode)

    --板子左边部分
    local innerBg = img.createUI9Sprite(img.ui.bag_btn_inner_bg)
    innerBg:setPreferredSize(CCSizeMake(560, 440))
    leftTabNode:addChild(innerBg)
    droidhangComponents:mandateNode(innerBg, "m9cS_rw5Zdz")
    
    local boardTab = img.createUI9Sprite(img.ui.select_tab_tab_bg)
    boardTab:setPreferredSize(CCSizeMake(500, 38))
    innerBg:addChild(boardTab)
    droidhangComponents:mandateNode(boardTab, "Ep8y_s4aqQG")

    local powerBg = img.createUISprite(img.ui.select_hero_power_bg)
    powerBg:setAnchorPoint(CCPoint(0, 0.5))
    powerBg:setPosition(CCPoint(0, boardTab:getContentSize().height/2))
    boardTab:addChild(powerBg)

    local powerIcon = img.createUISprite(img.ui.power_icon)
    powerIcon:setScale(0.5)
    powerIcon:setPosition(CCPoint(30, powerBg:getContentSize().height/2))
    powerBg:addChild(powerIcon)

    local powerCount = 0
    for _, mbr in ipairs(data.mbrs) do
        local selected = false
        for _, uid in ipairs(data.uids) do
            if uid == mbr.uid then
                selected = true
                break
            end
        end

        if selected then
            powerCount = powerCount + (mbr.power or 0)
        end
    end
    self.powerCount = powerCount

    local lblPower = lbl.createFont2(20, string.format("%d", powerCount))
    lblPower:setAnchorPoint(CCPoint(0, 0.5))
    lblPower:setPosition(CCPoint(55, powerBg:getContentSize().height/2))
    powerBg:addChild(lblPower)

    local btnSettingSprite = img.createLogin9Sprite(img.login.button_9_small_green)
    btnSettingSprite:setPreferredSize(CCSize(150, 42))
    local btnSettingLab = lbl.createFont1(16, i18n.global.arena3v3_btn_setting.string, ccc3(0x1b, 0x59, 0x02))
    btnSettingLab:setPosition(btnSettingSprite:getContentSize().width/2, btnSettingSprite:getContentSize().height/2)
    btnSettingSprite:addChild(btnSettingLab)

    local btnSetting = SpineMenuItem:create(json.ui.button, btnSettingSprite)
    droidhangComponents:mandateNode(btnSetting, "phOd_uDIpP5")
    local menuSetting = CCMenu:createWithItem(btnSetting)
    menuSetting:setPosition(0, 0)
    boardTab:addChild(menuSetting)
    
    btnSetting:registerScriptTapHandler(function()
        audio.play(audio.button)
        self:addChild(require("ui.guildFight.settingLineup").create(data, function (newData)
            self:createLeftTab(newData)
        end), 1000)
    end)

    if dataGuild.selfTitle() <= dataGuild.TITLE.RESIDENT then
        btnSetting:setVisible(false)
    end

    local guildTeamTitle = lbl.createFont2(18, i18n.global.guildFight_guild_team.string, ccc3(0xff, 0xf3, 0x8d))
    guildTeamTitle:setAnchorPoint(0, 0.5)
    innerBg:addChild(guildTeamTitle)
    droidhangComponents:mandateNode(guildTeamTitle, "iFF9_j1MWOF")

    local teamCount = #(data.uids or {})
    local guildTeamDesc = lbl.createFont2(18, string.format("%d/%d", teamCount, #data.mbrs))
    guildTeamDesc:setAnchorPoint(0, 0.5)
    guildTeamDesc:setPosition(guildTeamTitle:getPositionX() + guildTeamTitle:getContentSize().width * guildTeamTitle:getScaleX(), guildTeamTitle:getPositionY())
    innerBg:addChild(guildTeamDesc)

    -- 背景框大小
    local BG_WIDTH   = innerBg:getContentSize().width
    local BG_HEIGHT  = 356
    -- 滑动区域大小
    local SCROLL_MARGIN_TOP     = 26
    local SCROLL_MARGIN_BOTTOM  = 14
    local SCROLL_VIEW_WIDTH     = BG_WIDTH
    local SCROLL_VIEW_HEIGHT    = BG_HEIGHT - SCROLL_MARGIN_TOP - SCROLL_MARGIN_BOTTOM

    local scroll = CCScrollView:create()
    scroll:setDirection(kCCScrollViewDirectionVertical)
    scroll:setViewSize(CCSize(SCROLL_VIEW_WIDTH, SCROLL_VIEW_HEIGHT))
    scroll:setPosition(0, SCROLL_MARGIN_BOTTOM)
    innerBg:addChild(scroll)

    local function createItem(player, idx)
        local bg = img.createUI9Sprite(img.ui.botton_fram_2)
        bg:setPreferredSize(CCSizeMake(504, 100))

        if idx then
            local numLabel = lbl.createFont1(18, string.format("%d", idx), ccc3(0x73, 0x3b, 0x05))
            bg:addChild(numLabel)
            droidhangComponents:mandateNode(numLabel, "Zlpx_yPScHf")
        end
        

        local playerLogo = img.createPlayerHeadForArena(player.logo)
        playerLogo:setScale(0.8)
        bg:addChild(playerLogo)
        droidhangComponents:mandateNode(playerLogo, "ICm4_5q9HLP")

        local showName = lbl.createFontTTF(16, player.name, ccc3(0x51, 0x27, 0x12))
        bg:addChild(showName)
        droidhangComponents:mandateNode(showName, "ICm4_fOxOXZ")

        local player_lv_bg = img.createUISprite(img.ui.main_lv_bg)
        local lbl_player_lv = lbl.createFont2(14, "" .. player.lv)
        lbl_player_lv:setPosition(CCPoint(player_lv_bg:getContentSize().width/2, player_lv_bg:getContentSize().height/2))
        player_lv_bg:addChild(lbl_player_lv)
        playerLogo:addChild(player_lv_bg)
        player_lv_bg:setScale(1 / 0.85)
        droidhangComponents:mandateNode(player_lv_bg, "ICm4_PEFRPi")

        local hids = {}
        local pheroes = player.camp or {}
        for i, v in ipairs(pheroes) do
            hids[v.pos] = v
        end

        local dx = 46
        local sx0 = 158
        local sx1 = sx0 + dx + 58
        local sxAry = {sx0, sx0 + dx, sx1, sx1 + dx, sx1 + dx * 2, sx1 + dx * 3}
        for i=1, 6 do
            local showHero
            if hids[i] then
                --showHero = img.createHeroHead(hids[i].id, hids[i].lv, true, true, hids[i].wake, nil ,require("data.pet").getPetID(hids))
                local param = {
                    id = hids[i].id,
                    lv = hids[i].lv,
                    showGroup = true,
                    showStar = true,
                    wake = hids[i].wake,
                    orangeFx = nil,
                    petID = require("data.pet").getPetID(hids),
                    hskills = hids[i].hskills,
skin = hids[i].skin,
                }
                showHero = img.createHeroHeadByParam(param)
            else
                showHero = img.createUISprite(img.ui.herolist_head_bg)
            end
            showHero:setAnchorPoint(ccp(0.5, 0.5))
            showHero:setScale(0.45)
            showHero:setPosition(sxAry[i], 36)
            bg:addChild(showHero)
        end

        -- btn_search
        local btn_search0 = img.createUISprite(img.ui.guildFight_icon_search)
        local btn_search = SpineMenuItem:create(json.ui.button, btn_search0)
        droidhangComponents:mandateNode(btn_search, "yand_Hu3IhP")
        local btn_search_menu = CCMenu:createWithItem(btn_search)
        btn_search_menu:setPosition(CCPoint(0, 0))
        bg:addChild(btn_search_menu)
        btn_search:registerScriptTapHandler(function()
            audio.play(audio.button)
            self:addChild(require("ui.guildFight.teamDetail").create(player), 1000)
        end)
        
        return bg
    end

    local height = 0
    local index = 0
    local itemAry = {}
    for _, mbr in ipairs(data.mbrs or {}) do
        local selected = false
        for _, uid in ipairs(data.uids or {}) do
            if uid == mbr.uid then
                selected = true
                break
            end
        end

        local item
        if selected then
            index = index + 1
            item = createItem(mbr, index)
        else
            item = createItem(mbr, nil)
        end

        height = height + item:getContentSize().height + 4
        table.insert(itemAry, item)
        scroll:addChild(item)
    end

    local sy = height - 0
    for _, item in ipairs(itemAry) do
        item:setAnchorPoint(0.5, 0.5)
        item:setPosition(SCROLL_VIEW_WIDTH * 0.5, sy - item:getContentSize().height * 0.5)
        sy = sy - item:getContentSize().height - 4
    end

    scroll:setContentSize(CCSize(SCROLL_VIEW_WIDTH, height))
    scroll:setContentOffset(ccp(0, SCROLL_VIEW_HEIGHT-height))

    --板子右边部分
    local infoBg = img.createUISprite(img.ui.guildFight_infoBg)
    leftTabNode:addChild(infoBg)
    droidhangComponents:mandateNode(infoBg, "16iU_gCbA6A")

    local infoBgTitle = lbl.createFont2(16, i18n.global.guildFight_points_race_title.string, ccc3(0xff, 0xe8, 0x9b))
    infoBg:addChild(infoBgTitle)
    droidhangComponents:mandateNode(infoBgTitle, "OSwy_XQutm1")

    local lbranch = img.createUISprite(img.ui.guildFight_branch)
    infoBg:addChild(lbranch)
    droidhangComponents:mandateNode(lbranch, "OSwy_XQuibl")
    local rbranch = img.createUISprite(img.ui.guildFight_branch)
    infoBg:addChild(rbranch)
    rbranch:setFlipX(true)
    droidhangComponents:mandateNode(rbranch, "OSwy_XQuibr")

    local infoRankTitle = lbl.createFont2(14, i18n.global.guildFight_rank.string, ccc3(0xff, 0xf3, 0x8d))
    infoBg:addChild(infoRankTitle)
    droidhangComponents:mandateNode(infoRankTitle, "OSwy_13uT7b")

    local infoRankDesc = lbl.createFont2(28, "", ccc3(0xff, 0xff, 0xff))
    if data.rank then
        infoRankDesc:setString(string.format("%d", data.rank))
    else
        infoRankDesc:setString("--")
    end
    infoBg:addChild(infoRankDesc)
    droidhangComponents:mandateNode(infoRankDesc, "OSwy_ctyPyo")

    local infoCutLine = img.createUISprite(img.ui.guildFight_cut_line)
    infoBg:addChild(infoCutLine)
    droidhangComponents:mandateNode(infoCutLine, "OSwy_gK2J8F")

    local infoScoreTitle = lbl.createFont2(16, i18n.global.guildFight_score.string, ccc3(0xff, 0xf3, 0x8d))
    infoScoreTitle:setAnchorPoint(0, 0.5)
    infoBg:addChild(infoScoreTitle)
    droidhangComponents:mandateNode(infoScoreTitle, "8dxy_4HDkZK")

    local infoScoreDesc = lbl.createFont2(16, string.format("%d", data.score or 0))
    infoScoreDesc:setAnchorPoint(0, 0.5)
    infoScoreDesc:setPosition(infoScoreTitle:getPositionX() + infoScoreTitle:getContentSize().width * infoScoreTitle:getScaleX(), infoScoreTitle:getPositionY())
    infoBg:addChild(infoScoreDesc)

    local infoStartTitle = lbl.createFont2(16, i18n.global.guildFight_end_cd.string, ccc3(0xff, 0xf3, 0x8d))
    infoStartTitle:setAnchorPoint(0, 0.5)
    infoBg:addChild(infoStartTitle)
    droidhangComponents:mandateNode(infoStartTitle, "8dxy_SYZfOK")
    if data.status == 4 then
        infoStartTitle:setString(i18n.global.guildFight_start_cd.string)
    end

    local infoStartDesc = lbl.createFont2(16, "", ccc3(0xc6, 0xff, 0x64))
    infoStartDesc:setString(time2string(data.cd))
    infoStartDesc:setAnchorPoint(0, 0.5)
    infoStartDesc:setPosition(infoStartTitle:getPositionX() + infoStartTitle:getContentSize().width * infoStartTitle:getScaleX(), infoStartTitle:getPositionY())
    infoBg:addChild(infoStartDesc)

    local startTime = os.time()
    infoStartDesc:scheduleUpdateWithPriorityLua(function ()
        local passTime = os.time() - startTime
        local remainCd = math.max(0, data.cd + 3 - passTime)
        infoStartDesc:setString(time2string(remainCd))

        if remainCd <= 0 then
            infoStartDesc:unscheduleUpdate()
            self:onLeftTab()
            return
        end
    end)

    -- btn_rank
    local btn_rank0 = img.createLogin9Sprite(img.login.button_9_small_gold)
    btn_rank0:setPreferredSize(CCSizeMake(65, 55))
    local icon_rank = img.createUISprite(img.ui.guild_icon_rank)
    icon_rank:setScale(0.9)
    icon_rank:setPosition(CCPoint(33, 28))
    btn_rank0:addChild(icon_rank)
    local btn_rank = SpineMenuItem:create(json.ui.button, btn_rank0)
    droidhangComponents:mandateNode(btn_rank, "lwrC_hFyIKC")
    local btn_rank_menu = CCMenu:createWithItem(btn_rank)
    btn_rank_menu:setPosition(CCPoint(0, 0))
    infoBg:addChild(btn_rank_menu)
    btn_rank:registerScriptTapHandler(function()
        audio.play(audio.button)

        if not self.guildData.reg then
            showToast(i18n.global.guiidFight_toast_reg.string)
            return
        end

        -- local __data = {
        --     {logo = 4, lv = 4, name = "myName", sid = 66},
        --     {logo = 1, lv = 4, name = "myName1", sid = 2},
        -- }

        local params = {
            sid = dataPlayer.sid,
        }

        addWaitNet()
        net:guild_fight_rank(params, function(__data)
            delWaitNet()
            tbl2string(__data)

            if __data.rank then
                data.rank = __data.rank
                infoRankDesc:setString(string.format("%d", data.rank))
            end

            self:addChild(require("ui.guildFight.rank").create(__data.guds, data.rank, data.score), 1000)
        end)
    end)
    -- btn_log
    local btn_log0 = img.createLogin9Sprite(img.login.button_9_small_gold)
    btn_log0:setPreferredSize(CCSizeMake(65, 55))
    local icon_log = img.createUISprite(img.ui.guild_icon_log)
    icon_log:setScale(0.9)
    icon_log:setPosition(CCPoint(33, 28))
    btn_log0:addChild(icon_log)
    local btn_log = SpineMenuItem:create(json.ui.button, btn_log0)
    droidhangComponents:mandateNode(btn_log, "lwrC_Y5ZJHV")
    local btn_log_menu = CCMenu:createWithItem(btn_log)
    btn_log_menu:setPosition(CCPoint(0, 0))
    infoBg:addChild(btn_log_menu)
    btn_log:registerScriptTapHandler(function()
        audio.play(audio.button)
        self:addChild(require("ui.guildFight.records").create())
    end)
    -- btn_award
    local btn_award0 = img.createLogin9Sprite(img.login.button_9_small_gold)
    btn_award0:setPreferredSize(CCSizeMake(65, 55))
    local icon_award = img.createUISprite(img.ui.guildFight_icon_award)
    icon_award:setScale(1)
    icon_award:setPosition(CCPoint(33, 28))
    btn_award0:addChild(icon_award)
    local btn_award = SpineMenuItem:create(json.ui.button, btn_award0)
    droidhangComponents:mandateNode(btn_award, "F7RD_C49AOG")
    local btn_award_menu = CCMenu:createWithItem(btn_award)
    btn_award_menu:setPosition(CCPoint(0, 0))
    infoBg:addChild(btn_award_menu)
    btn_award:registerScriptTapHandler(function()
        audio.play(audio.button)
        if not self.guildData.reg then
            showToast(i18n.global.guiidFight_toast_reg.string)
            return
        end
        self:addChild(require("ui.guildFight.rewards").create(data.rank, data.status, data.cd, data.pull_time))
    end)
    -- btn_lrank
    local btn_lrank0 = img.createLogin9Sprite(img.login.button_9_small_gold)
    btn_lrank0:setPreferredSize(CCSizeMake(65, 55))
    local icon_lrank = img.createUISprite(img.ui.guildFight_icon_history)
    icon_lrank:setPosition(CCPoint(33, 28))
    btn_lrank0:addChild(icon_lrank)
    local btn_lrank = SpineMenuItem:create(json.ui.button, btn_lrank0)
    droidhangComponents:mandateNode(btn_lrank, "Uqbk_XNpGem")
    local btn_lrank_menu = CCMenu:createWithItem(btn_lrank)
    btn_lrank_menu:setPosition(CCPoint(0, 0))
    infoBg:addChild(btn_lrank_menu)
    if self.guildData.reg then
        btn_lrank:setEnabled(false)
        setShader(btn_lrank, SHADER_GRAY, true)
    end
    btn_lrank:setVisible(false)
    btn_lrank:registerScriptTapHandler(function()
        disableObjAWhile(btn_lrank, 2)
        audio.play(audio.button)
        local params = {
            sid = dataPlayer.sid,
        }
        addWaitNet()
        net:guild_fight_rank(params, function(__data)
            delWaitNet()
            tbl2string(__data)

            if __data.rank then
                data.rank = __data.rank
                infoRankDesc:setString(string.format("%d", data.rank))
            end

            self:addChild(require("ui.guildFight.rank").create(__data.guds, data.rank, data.score), 1000)
        end)
    end)

    -- btn_ring
    local btn_ring0 = img.createLogin9Sprite(img.login.button_9_small_gold)
    btn_ring0:setPreferredSize(CCSizeMake(65, 55))
    local icon_ring = img.createUISprite(img.ui.guildFight_icon_ring)
    --icon_ring:setScale(0.9)
    icon_ring:setPosition(CCPoint(btn_ring0:getContentSize().width/2, btn_ring0:getContentSize().height/2))
    btn_ring0:addChild(icon_ring)
    local btn_ring = SpineMenuItem:create(json.ui.button, btn_ring0)
    --droidhangComponents:mandateNode(btn_ring, "Y1I8_h5nkT4")
    droidhangComponents:mandateNode(btn_ring, "Uqbk_XNpGem")
    local btn_ring_menu = CCMenu:createWithItem(btn_ring)
    btn_ring_menu:setPosition(CCPoint(0, 0))
    infoBg:addChild(btn_ring_menu)
    btn_ring:registerScriptTapHandler(function()
        audio.play(audio.button)
        if dataGuild.selfTitle() <= dataGuild.TITLE.RESIDENT then
            showToast(i18n.global.permission_denied.string)
            return
        end
        local dialog = require "ui.dialog"
        local function process_dialog(data)
            self:removeChildByTag(dialog.TAG)
            if data.selected_btn == 2 then
                local params = {
                    sid = dataPlayer.sid,
                    type = 4,
                    gud_imsg = msg,
                }
                addWaitNet()
                netClient:chat(params, function(__data)
                    delWaitNet()
                    showToast(i18n.global.mail_send_ok.string)
                end)
            elseif data.selected_btn == 1 then
            end
        end
        local params = {
            title = "",
            body = i18n.global.guildFight_call_lineup.string,
            btn_count = 2,
            btn_color = {
                [1] = dialog.COLOR_BLUE,
                [2] = dialog.COLOR_GOLD,
            },
            btn_text = {
                [1] = i18n.global.dialog_button_cancel.string,
                [2] = i18n.global.dialog_button_confirm.string,
            },
            callback = process_dialog,
        }
        local dialog_ins = dialog.create(params, true)
        dialog_ins:setAnchorPoint(CCPoint(0,0))
        dialog_ins:setPosition(CCPoint(0,0))
        self:addChild(dialog_ins, 10000, dialog.TAG)
    end)

    --btn_register
    local img_register = img.createLogin9Sprite(img.login.button_9_small_green)
    img_register:setPreferredSize(CCSizeMake(275, 58))
    local lbl_btn_register = lbl.createFont1(18, i18n.global.guildFight_register.string, ccc3(0x1b, 0x59, 0x02))
    lbl_btn_register:setPosition(CCPoint(img_register:getContentSize().width/2, img_register:getContentSize().height/2))
    img_register:addChild(lbl_btn_register)
    local btn_register = SpineMenuItem:create(json.ui.button, img_register)
    droidhangComponents:mandateNode(btn_register, "2KoT_THySV3")
    local btn_register_menu = CCMenu:createWithItem(btn_register)
    btn_register_menu:setPosition(CCPoint(0, 0))
    leftTabNode:addChild(btn_register_menu)

    if data.reg then
        btn_register:setEnabled(false)
        setShader(btn_register, SHADER_GRAY, true)
    else
        btn_register:registerScriptTapHandler(function()
            audio.play(audio.button)

            if dataGuild.selfTitle() <= dataGuild.TITLE.RESIDENT then
                showToast(i18n.global.permission_denied.string)
                return
            end

            local params = {
                sid = dataPlayer.sid,
            }

            addWaitNet()
            net:guild_fight_reg(params, function(__data)
                delWaitNet()
                tbl2string(__data)

                if __data.status < 0 then
                    if __data.status == -2 then
                        showToast(i18n.global.guildFight_mix_teams.string)
                    elseif __data.status == -4 then
                        showToast(i18n.global.guiidFight_toast_reg_end.string)
                    else
                        showToast("status:" .. __data.status)
                    end
                    return
                end

                showToast(i18n.global.guiidFight_toast_reg_success.string)

                self:onLeftTab()
                -- data.reg = true
                -- btn_register:setEnabled(false)
                -- setShader(btn_register, SHADER_GRAY, true)
            end)
        end)
    end

    --btn_team
    local img_team = img.createLogin9Sprite(img.login.button_9_small_gold)
    img_team:setPreferredSize(CCSizeMake(275, 58))
    local lbl_btn_team = lbl.createFont1(18, i18n.global.guildFight_my_team.string, ccc3(0x73, 0x3b, 0x05))
    lbl_btn_team:setPosition(CCPoint(img_team:getContentSize().width/2, img_team:getContentSize().height/2))
    img_team:addChild(lbl_btn_team)
    local btn_team = SpineMenuItem:create(json.ui.button, img_team)
    droidhangComponents:mandateNode(btn_team, "2KoT_0itJUH")
    local btn_team_menu = CCMenu:createWithItem(btn_team)
    btn_team_menu:setPosition(CCPoint(0, 0))
    leftTabNode:addChild(btn_team_menu)

    btn_team:registerScriptTapHandler(function()
        disableObjAWhile(btn_team)
        audio.play(audio.button)
        self:addChild(require("ui.selecthero.main").create({type = "guildFight", callBack = function (camp)
            local newCamp = clone(camp)
            local power = 0
            for _, info in ipairs(newCamp) do
                if info.pos and info.pos ~= 7 then
                    power = power + dataHeros.power(info.hid)

                    local heroInfo = dataHeros.find(info.hid)
                    info.id = heroInfo.id
                    info.hid = info.hid
                    info.lv = heroInfo.lv
                end
            end
            local findFlag = false
            for _, mbr in ipairs(self.guildData.mbrs) do
                if mbr.uid == dataPlayer.uid then
                    mbr.camp = newCamp
                    findFlag = true
                    break
                end
            end

            if not findFlag then
                local mbr = {name = dataPlayer.name, logo = dataPlayer.logo, lv = dataPlayer.lv(), camp = newCamp, uid = dataPlayer.uid, power = power}
                table.insert(self.guildData.mbrs, mbr)
            end

            self:createLeftTab()
        end}), 1000) 
    end)
end

function guildFightMain:createRightTab(data)
    if self.demoFightLayer then
        self.demoFightLayer:removeFromParent()
        self.demoFightLayer = nil
    end
    if self.rightTabNode then
        self.rightTabNode:removeFromParent()
        self.rightTabNode = nil
    end
    if self.enegyToast then
        self.enegyToast:removeFromParent()
        self.enegyToast = nil
    end

    local rightTabNode = cc.Node:create()
    self.rightTabNode = rightTabNode
    self.bg:addChild(rightTabNode)

    
    -- if data.status == 0 then
    --     if self.guildData.status == 2 then
    --         data.status = 4
    --     elseif self.guildData.status == 3 then
    --         data.status = 5
    --     else
    --         data.status = 6
    --     end
    -- end
    local status = data.status
    if status == 1 or status == 2 or status == 3 then--匹配赛
        if self.guildData.reg then
            self:createRightTabFighting(rightTabNode, data)
        else
            showToast(i18n.global.guiidFight_toast_reg.string)
        end
    elseif status == 4 then--决赛准备期
        self:createRightTabFinals(rightTabNode, data, true)
    elseif status == 5 then--决赛期
        self:createRightTabFinals(rightTabNode, data, false)
    elseif status == 6 then--休息期
        self:createRightTabFinish(rightTabNode, data)
    end
end

function guildFightMain:createRightTabFinish(rightTabNode, data)
    local bg = img.createUI9Sprite(img.ui.bag_btn_inner_bg)
    bg:setPreferredSize(CCSizeMake(876, 440))
    rightTabNode:addChild(bg)
    droidhangComponents:mandateNode(bg, "VTe0_cU034t")

    local titleLabel = lbl.createFont2(24, i18n.global.guildFight_final_title.string, ccc3(0xe6, 0xd0, 0xae))
    bg:addChild(titleLabel)
    droidhangComponents:mandateNode(titleLabel, "ITmN_jx6ppy")

    local leftTitleIcon = img.createUISprite(img.ui.guildFight_icon_final)
    bg:addChild(leftTitleIcon)
    droidhangComponents:mandateNode(leftTitleIcon, "ITmN_Jgfkt8")

    local rightTitleIcon = img.createUISprite(img.ui.guildFight_icon_final)
    rightTitleIcon:setFlipX(true)
    bg:addChild(rightTitleIcon)
    droidhangComponents:mandateNode(rightTitleIcon, "ITmN_Aojh61")

    --bar
    local bar2 = img.createUISprite(img.ui.guildFight_bar_2)
    local bar2Label = lbl.createFont2(22, i18n.global.guildFight_final_2_1.string, ccc3(0xff, 0xe4, 0x7d))
    bar2:addChild(bar2Label)
    bar2Label:setPosition(bar2:getContentSize().width * 0.5, bar2:getContentSize().height * 0.5 + 2)

    local bar2Btn = SpineMenuItem:create(json.ui.button, bar2)
    local bar2BtnMenu = CCMenu:createWithItem(bar2Btn)
    bar2BtnMenu:setPosition(CCPoint(0, 0))
    bg:addChild(bar2BtnMenu)
    bar2Btn:registerScriptTapHandler(function()
        audio.play(audio.button)
        self:addChild(require("ui.guildFight.final_2").create(data))
    end)
    droidhangComponents:mandateNode(bar2Btn, "ITmN_2TgYlP")

    local bar4 = img.createUISprite(img.ui.guildFight_bar_4)
    local bar4Label = lbl.createFont2(22, i18n.global.guildFight_final_4_2.string, ccc3(0xfa, 0xda, 0xf4))
    bar4:addChild(bar4Label)
    bar4Label:setPosition(bar4:getContentSize().width * 0.5, bar4:getContentSize().height * 0.5 + 2)

    local bar4Btn = SpineMenuItem:create(json.ui.button, bar4)
    local bar4BtnMenu = CCMenu:createWithItem(bar4Btn)
    bar4BtnMenu:setPosition(CCPoint(0, 0))
    bg:addChild(bar4BtnMenu)
    bar4Btn:registerScriptTapHandler(function()
        audio.play(audio.button)
        self:addChild(require("ui.guildFight.final_4").create(data))
    end)
    droidhangComponents:mandateNode(bar4Btn, "ITmN_RTbaPr")

    local bar8 = img.createUISprite(img.ui.guildFight_bar_8)
    local bar8Label = lbl.createFont2(22, i18n.global.guildFight_final_8_4.string, ccc3(0xbd, 0xe4, 0xff))
    bar8:addChild(bar8Label)
    bar8Label:setPosition(bar8:getContentSize().width * 0.5, bar8:getContentSize().height * 0.5 + 2)

    local bar8Btn = SpineMenuItem:create(json.ui.button, bar8)
    local bar8BtnMenu = CCMenu:createWithItem(bar8Btn)
    bar8BtnMenu:setPosition(CCPoint(0, 0))
    bg:addChild(bar8BtnMenu)
    bar8Btn:registerScriptTapHandler(function()
        audio.play(audio.button)
        self:addChild(require("ui.guildFight.final_8").create(data))
    end)
    droidhangComponents:mandateNode(bar8Btn, "ITmN_DXII7R")

    local bar16 = img.createUISprite(img.ui.guildFight_bar_16)
    local bar16Label = lbl.createFont2(22, i18n.global.guildFight_final_16_8.string)
    bar16:addChild(bar16Label)
    bar16Label:setPosition(bar16:getContentSize().width * 0.5, bar16:getContentSize().height * 0.5 + 2)

    local bar16Btn = SpineMenuItem:create(json.ui.button, bar16)
    local bar16BtnMenu = CCMenu:createWithItem(bar16Btn)
    bar16BtnMenu:setPosition(CCPoint(0, 0))
    bg:addChild(bar16BtnMenu)
    bar16Btn:registerScriptTapHandler(function()
        audio.play(audio.button)
        self:addChild(require("ui.guildFight.final_16").create(data))
    end)
    droidhangComponents:mandateNode(bar16Btn, "pVLe_3cOPsU")
end

function guildFightMain:createRightTabFighting(rightTabNode, data)
    -- local tempBg = cc.Sprite:create("temp.png")
    -- tempBg:setPosition(self.bg:getContentSize().width * 0.5, self.bg:getContentSize().height * 0.5)
    -- tempBg:setOpacity(100)
    -- self.bg:addChild(tempBg, 20)

    local bg = img.createUI9Sprite(img.ui.bag_btn_inner_bg)
    bg:setPreferredSize(CCSizeMake(876, 440))
    rightTabNode:addChild(bg)
    droidhangComponents:mandateNode(bg, "VTe0_cU034t")

    local teamBgWidth = 480
    local teamBgHeight = 182
    local myTeambg = img.createUI9Sprite(img.ui.guildFight_bar_bg)
    myTeambg:setPreferredSize(CCSizeMake(teamBgWidth, teamBgHeight))
    bg:addChild(myTeambg)
    droidhangComponents:mandateNode(myTeambg, "zFFL_7ohsyz_xx")

    local leftTitleIcon = img.createUISprite(img.ui.guildFight_icon_final)
    bg:addChild(leftTitleIcon)
    droidhangComponents:mandateNode(leftTitleIcon, "zFFL_fDWtbB")

    local rightTitleIcon = img.createUISprite(img.ui.guildFight_icon_final)
    rightTitleIcon:setFlipX(true)
    bg:addChild(rightTitleIcon)
    droidhangComponents:mandateNode(rightTitleIcon, "zFFL_Uty10x")

    local vsIcon = img.createUISprite(img.ui.arena_new_vs)
    bg:addChild(vsIcon)
    droidhangComponents:mandateNode(vsIcon, "IJcm_HuX20g")

    local enemyTeambg = img.createUI9Sprite(img.ui.botton_fram_2)
    enemyTeambg:setPreferredSize(CCSizeMake(teamBgWidth, teamBgHeight))
    bg:addChild(enemyTeambg)
    droidhangComponents:mandateNode(enemyTeambg, "zFFL_vg2kCp")

    local function createTeamItem(data, mask, fuzzyFlag)
        local container = cc.Node:create()

        local guildFlag = img.createGFlag(data.logo or 1)
        guildFlag:setScale(0.6)
        container:addChild(guildFlag)
        droidhangComponents:mandateNode(guildFlag, "sZ25_CyveZF")

        local nameLabel = lbl.createFontTTF(18, data.name or "unknow", ccc3(0x6c, 0x3e, 0x35))
        container:addChild(nameLabel)
        droidhangComponents:mandateNode(nameLabel, "8TTW_HkCKyZ")

        local rankdLabel = lbl.createFont1(16, i18n.global.guildvice_dps_rank.string..": "..(data.rank or "--"), ccc3(0xa0, 0x51, 0x42))
        container:addChild(rankdLabel)
        droidhangComponents:mandateNode(rankdLabel, "8TTW_IPpHVj")

        local mylookSprite = img.createUISprite(img.ui.guildFight_icon_search)
        local btnmylook = SpineMenuItem:create(json.ui.button, mylookSprite)
        droidhangComponents:mandateNode(btnmylook, "XawZ_yEzDMB")
        local menumylook= CCMenu:createWithItem(btnmylook)
        menumylook:setPosition(0, 0)
        container:addChild(menumylook)

        btnmylook:registerScriptTapHandler(function()
            audio.play(audio.button)
            local camplayer = require "ui.guildFight.guildFightcamp"
            self:addChild(camplayer.create(data.mbrs, mask), 1000)
        end)

        if fuzzyFlag and data.rank then
            local idx = math.ceil(data.rank / 50)
            local text = string.format("%d-%d", 1 + (idx - 1) * 50, 50 + (idx - 1) * 50)
            rankdLabel:setString(i18n.global.guildvice_dps_rank.string..": "..text)
        end

        local splitLine = img.createUISprite(img.ui.split_line)
        container:addChild(splitLine)
        droidhangComponents:mandateNode(splitLine, "WCt8_ruT3zz")
        splitLine:setScaleX(439 / splitLine:getContentSize().width)

        local serverBg = img.createUISprite(img.ui.anrea_server_bg)
        container:addChild(serverBg)
        droidhangComponents:mandateNode(serverBg, "XGbN_wqPpxm")

        local serverLabel = lbl.createFont1(16, getSidname(data.sid or 1), ccc3(255, 251, 215))
        serverLabel:setPosition(serverBg:getContentSize().width * 0.5, serverBg:getContentSize().height * 0.5)
        serverBg:addChild(serverLabel)

        -- 背景框大小
        local BG_WIDTH   = teamBgWidth
        local BG_HEIGHT  = 114
        -- 滑动区域大小
        local SCROLL_MARGIN_TOP     = 4
        local SCROLL_MARGIN_BOTTOM  = 12
        local SCROLL_VIEW_WIDTH     = BG_WIDTH
        local SCROLL_VIEW_HEIGHT    = BG_HEIGHT - SCROLL_MARGIN_TOP - SCROLL_MARGIN_BOTTOM

        local scroll = CCScrollView:create()
        scroll:setDirection(kCCScrollViewDirectionVertical)
        scroll:setViewSize(CCSize(SCROLL_VIEW_WIDTH, SCROLL_VIEW_HEIGHT))
        scroll:setPosition(0, SCROLL_MARGIN_BOTTOM)
        container:addChild(scroll)

        local function createItem(i, player)
            local bg = cc.Node:create()
            bg:setContentSize(cc.size(SCROLL_VIEW_WIDTH, 50))

            local numLabel = lbl.createFont1(18, string.format("%d", i), ccc3(0x6c, 0x3e, 0x35))
            bg:addChild(numLabel)
            numLabel:setPosition(30, bg:getContentSize().height * 0.5)

            local hids = {}
            local pheroes = player.camp or {}
            for i, v in ipairs(pheroes) do
                hids[v.pos] = v
            end

            local dx = 54
            local sx0 = 80
            local sx1 = sx0 + dx + 64
            local sxAry = {sx0, sx0 + dx, sx1, sx1 + dx, sx1 + dx * 2, sx1 + dx * 3}
            for i=1, 6 do
                local showHero

                local hideFlag = false
                if mask then
                    for _, uid in ipairs(mask) do
                        if uid == player.uid then
                            hideFlag = true
                            break
                        end
                    end
                end

                if hideFlag then
                    showHero = img.createUISprite(img.ui.herolist_head_bg)
                    local icon = img.createUISprite(img.ui.arena_new_question)
                    icon:setPosition(showHero:getContentSize().width * 0.5, showHero:getContentSize().height * 0.5)
                    showHero:addChild(icon)
                else
                    if hids[i] then
                        --showHero = img.createHeroHead(hids[i].id, hids[i].lv, true, true, hids[i].wake,nil,require("data.pet").getPetID(hids))
                        local param = {
                            id = hids[i].id,
                            lv = hids[i].lv,
                            showGroup = true,
                            showStar = true,
                            wake = hids[i].wake,
                            orangeFx = nil,
                            petID = require("data.pet").getPetID(hids),
                            --hid = hids[i].hid,
                            hskills = hids[i].hskills,
skin = hids[i].skin,
                        }
                        showHero = img.createHeroHeadByParam(param)
                    else
                        showHero = img.createUISprite(img.ui.herolist_head_bg)
                    end
                end

                showHero:setAnchorPoint(ccp(0.5, 0.5))
                showHero:setScale(0.55)
                showHero:setPosition(sxAry[i], bg:getContentSize().height * 0.5)
                bg:addChild(showHero)
            end
            
            return bg
        end

        local height = 0
        local itemAry = {}
        for i, mbr in ipairs(data.mbrs or {}) do
            local selected = false
            if data.uids then
                for _, uid in ipairs(data.uids or {}) do
                    if uid == mbr.uid then
                        selected = true
                        break
                    end
                end
            else
                selected = true
            end
            
            if selected then
                local item = createItem(i, mbr)

                height = height + item:getContentSize().height + 6
                table.insert(itemAry, item)
                scroll:addChild(item)
            end
        end

        local sy = height - 6 - 4
        for _, item in ipairs(itemAry) do
            item:setAnchorPoint(0.5, 0.5)
            item:setPosition(SCROLL_VIEW_WIDTH * 0.5, sy - item:getContentSize().height * 0.5 + 4)
            sy = sy - item:getContentSize().height - 6
        end

        scroll:setContentSize(CCSize(SCROLL_VIEW_WIDTH, height))
        scroll:setContentOffset(ccp(0, SCROLL_VIEW_HEIGHT-height))

        return container
    end

    myTeambg:addChild(createTeamItem(self.guildData))




    --可以匹配
    if data.status == 1 then
        local container_w = enemyTeambg:getContentSize().width
        local container_h = enemyTeambg:getContentSize().height
        local icon_nomail = img.createUISprite(img.ui.mail_icon_nomail)
        icon_nomail:setScale(0.7)
        icon_nomail:setPosition(CCPoint(container_w/2, container_h/2 + 15))
        enemyTeambg:addChild(icon_nomail)
        local lbl_nomail = lbl.createFont1(16, i18n.global.guildFight_enemy_empty.string, ccc3(0x93, 0x6c, 0x54))
        lbl_nomail:setAnchorPoint(0.5, 1)
        lbl_nomail:setPosition(CCPoint(container_w/2, icon_nomail:getPositionY()-icon_nomail:getContentSize().height * icon_nomail:getScale() * 0.5 - 5))
        enemyTeambg:addChild(lbl_nomail)
    else
        --展示对手公会信息
        if data.enemy then
            enemyTeambg:addChild(createTeamItem(data.enemy, data.enemy.mask, true))
        end
    end

    --右边
    local rightAnimBg = img.createUISprite(img.ui.guildFight_anim_bg)
    bg:addChild(rightAnimBg, 1)
    droidhangComponents:mandateNode(rightAnimBg, "zFFL_JIMnya")

    -- 体力
    local enegyBottom = img.createUI9Sprite(img.ui.main_coin_bg)
    enegyBottom:setPreferredSize(CCSizeMake(138, 40))
    rightAnimBg:addChild(enegyBottom)
    droidhangComponents:mandateNode(enegyBottom, "R7uJ_fCwuH9")
    self.enegyBottom = enegyBottom

    local enegylab = lbl.createFont2(16, string.format("%d/%d", data.tl, ENEGY_MAX), ccc3(0xf8, 0xf2, 0xe2))
    enegylab:setPosition(CCPoint(enegyBottom:getContentSize().width/2, 
                                enegyBottom:getContentSize().height/2+3))
    enegyBottom:addChild(enegylab)

    enegyIcon = img.createUISprite(img.ui.guildFight_tl)
    enegyIcon:setPosition(8, enegyBottom:getContentSize().height/2+4)
    enegyBottom:addChild(enegyIcon)

    --体力提示
    local enegyToast = img.createUI9Sprite(img.ui.tips_bg)
    enegyToast:setPreferredSize(CCSizeMake(410, 68))
    enegyToast:setVisible(false)
    self.bg:addChild(enegyToast, 1000)
    self.enegyToast = enegyToast
    droidhangComponents:mandateNode(self.enegyToast, "iFF6_kF4hVm")

    self.showenegyTimeLab = lbl.createFont2(16, "", ccc3(0xa5, 0xfd, 0x47))
    self.showenegyTimeLab:setAnchorPoint(0, 0.5)
    self.showenegyTimeLab:setPosition(enegyToast:getContentSize().width/2+30, enegyToast:getContentSize().height/2)
    enegyToast:addChild(self.showenegyTimeLab)

    self.tlrecoverlab = lbl.createFont1(16, i18n.global.friendboss_enegy_recovery.string, ccc3(255, 246, 223))
    self.tlrecoverlab:setAnchorPoint(1, 0.5)
    self.tlrecoverlab:setPosition(CCPoint(self.showenegyTimeLab:boundingBox():getMinX() - 10, enegyToast:getContentSize().height/2))
    enegyToast:addChild(self.tlrecoverlab)

    self.enegyFull = lbl.createMixFont1(16, i18n.global.friendboss_enegy_full.string, ccc3(255, 246, 223))
    self.enegyFull:setPosition(enegyToast:getContentSize().width/2, enegyToast:getContentSize().height/2)
    self.enegyFull:setVisible(false)
    enegyToast:addChild(self.enegyFull)

    if data.tl < ENEGY_MAX then
        local startTime = os.time()
        enegylab:scheduleUpdateWithPriorityLua(function ()
            local passTime = os.time() - startTime
            local remainCd = math.max(0, data.tl_cd - passTime)

            if remainCd <= 0 then
                data.tl = data.tl + 1
                data.tl_cd = ENEGY_DURATION
                remainCd = ENEGY_DURATION
                startTime = os.time()
                enegylab:setString(string.format("%d/%d", data.tl, ENEGY_MAX))
            end

            self.showenegyTimeLab:setString(time2string(remainCd))

            if data.tl >= ENEGY_MAX then
                enegylab:unscheduleUpdate()
                self.showenegyTimeLab:setVisible(false)
                self.tlrecoverlab:setVisible(false)
                self.enegyFull:setVisible(true)
                return
            end
        end)
    else
        self.showenegyTimeLab:setVisible(false)
        self.tlrecoverlab:setVisible(false)
        self.enegyFull:setVisible(true)
    end

    local function addTipsLabel(boardAnim, nameAry)
        local textUp = ""
        local textDown = ""
        if nameAry then
            if nameAry[1] then
                textUp = nameAry[1]
            end
            if nameAry[2] then
                textDown = nameAry[2]
            end
        end
        local labelUp = lbl.createFontTTF(18, textUp, ccc3(0x73, 0x3b, 0x05))
        boardAnim:addChildFollowSlot("code_text_up", labelUp)

        local labelMiddle = lbl.createFontTTF(22, data.enemy.name, ccc3(0x73, 0x3b, 0x05))
        boardAnim:addChildFollowSlot("code_text_middle", labelMiddle)

        local labelDown = lbl.createFontTTF(18, textDown, ccc3(0x73, 0x3b, 0x05))
        boardAnim:addChildFollowSlot("code_text_down", labelDown)
    end

    --local stateBg = img.createUI9Sprite(img.ui.guildFight_state_bg)
    --stateBg:setPreferredSize(CCSizeMake(316, 158))
    --bg:addChild(stateBg)
    --droidhangComponents:mandateNode(stateBg, "n2Ut_4HQTIb")

    if data.status == 1 or data.status == 2 then
        --btnFight
        local btnFightSprite = img.createUISprite(img.ui.guildFight_battle_1)
        local btnFightSprite2 = img.createUISprite(img.ui.guildFight_battle_2)
        btnFightSprite2:setPosition(btnFightSprite:getContentSize().width/2, btnFightSprite:getContentSize().height/2)
        btnFightSprite:addChild(btnFightSprite2)
        local btnFightLab = lbl.createFont1(24, i18n.global.guildFight_fight.string, ccc3(0x7e, 0x27, 0x00))
        btnFightLab:setPosition(btnFightSprite:getContentSize().width/2, btnFightSprite:getContentSize().height/2)
        btnFightSprite:addChild(btnFightLab)

        local btnFight = SpineMenuItem:create(json.ui.button, btnFightSprite)
        droidhangComponents:mandateNode(btnFight, "XawZ_yEzDMA")
        local menuFight= CCMenu:createWithItem(btnFight)
        menuFight:setPosition(0, 0)
        bg:addChild(menuFight)

        btnFight:registerScriptTapHandler(function()
            audio.play(audio.button)

            if dataGuild.selfTitle() <= dataGuild.TITLE.RESIDENT then
                showToast(i18n.global.permission_denied.string)
                return
            end

            local params = {
                sid = dataPlayer.sid,
                server_id = data.enemy.sid,
                gid = data.enemy.gid,
            }

            addWaitNet()
            net:guild_fight_fight(params, function(__data)
                delWaitNet()
                tbl2string(__data)

                if __data.status < 0 then
                    if __data.status == -1 then
                        showToast(i18n.global.guiidFight_toast_matchOther.string)
                    elseif __data.status == -3 then
                        showToast(i18n.global.friendboss_no_enegy.string)
                    elseif __data.status == -4 then
                        showToast(i18n.global.guiidFight_toast_reg_end.string)
                    else
                        showToast("status:" .. __data.status)
                    end
                    return 
                end

                local newData = clone(data)
                newData.status = 3
                newData.cd = FIGHT_DURATION
                newData.tl = newData.tl - 1
                newData.fight_win = __data.win
                newData.fight_bats = __data.bats
                self:createRightTab(newData)
            end)
        end)

        if not data.enemy then
            btnFight:setEnabled(false)
            setShader(btnFight, SHADER_GRAY, true)
        end

        --btnMatch
        local btnMathSprite = img.createUISprite(img.ui.guildFight_find_1)
        --btnMathSprite:setPreferredSize(CCSize(180, 46))
        local btnMathLab = lbl.createFont1(16, i18n.global.guildFight_math.string, ccc3(0x1b, 0x59, 0x02))
        btnMathLab:setPosition(btnMathSprite:getContentSize().width/2, btnMathSprite:getContentSize().height/2)
        btnMathSprite:addChild(btnMathLab)

        local btnMatch = SpineMenuItem:create(json.ui.button, btnMathSprite)
        droidhangComponents:mandateNode(btnMatch, "XawZ_PGD3iq")
        local menuMath = CCMenu:createWithItem(btnMatch)
        menuMath:setPosition(0, 0)
        bg:addChild(menuMath)

        local matchSprite = img.createUISprite(img.ui.guildFight_find_2)
        droidhangComponents:mandateNode(matchSprite, "XawZ_PGD3iq")
        matchSprite:setVisible(false)
        bg:addChild(matchSprite)

        local function showMathCd(cd)
--[[            btnMathLab:setVisible(false)
            matchSprite:setVisible(true)
            btnMatch:setVisible(false)
            --setShader(btnMatch, SHADER_GRAY, true)

            local cdLabel = lbl.createFont2(16, "", ccc3(0xc6, 0xff, 0x64))
            cdLabel:setString(time2string(cd))
            cdLabel:setPosition(matchSprite:getContentSize().width/2, matchSprite:getContentSize().height/2)
            matchSprite:addChild(cdLabel)

            local startTime = os.time()
            cdLabel:scheduleUpdateWithPriorityLua(function ()
                local passTime = os.time() - startTime
                local remainCd = math.max(0, cd - passTime)

                cdLabel:setString(time2string(remainCd))

                if remainCd <= 0 then
                    cdLabel:unscheduleUpdate()
                    btnMatch:setVisible(true)
                    --clearShader(btnMatch, true)
                    matchSprite:setVisible(false)
                    cdLabel:setVisible(false)
                    btnMathLab:setVisible(true)
                    return
                end
            end)
--]]
            if cd == 0 then
                btnMatch:setEnabled(true)
                clearShader(btnMatch, true)
            else
                btnMatch:setEnabled(false)
                setShader(btnMatch, SHADER_GRAY, true)
            end
        end

        btnMatch:registerScriptTapHandler(function()
            if dataGuild.selfTitle() <= dataGuild.TITLE.RESIDENT then
                showToast(i18n.global.permission_denied.string)
                return
            end

            local params = {
                sid = dataPlayer.sid,
            }

            addWaitNet()
            net:guild_fight_macth(params, function(__data)
                delWaitNet()
                tbl2string(__data)

                if __data.status < 0 then
                    if __data.status == -2 then
                        showToast(i18n.global.guiidFight_toast_noOther.string)
                    elseif __data.status == -4 then
                        showToast(i18n.global.guiidFight_toast_reg_end.string)
                    else
                        showToast("status:" .. __data.status)
                    end
                    
                    return 
                end

                data.enemy = __data.enemy
                data.status = 2

                showMathCd(1)

                self.boardAnim:playAnimation("open", 1, 0)
                self.boardAnim:appendNextAnimation("loop", 1, 0)
                self.boardAnim:appendNextAnimation("end", 1, 0)

                self.boardAnim:removeChildFollowSlot("code_text_up")
                self.boardAnim:removeChildFollowSlot("code_text_middle")
                self.boardAnim:removeChildFollowSlot("code_text_down")

                addTipsLabel(self.boardAnim, __data.name)

                self.boardAnim:registerLuaHandler(function ( ... )
                    enemyTeambg:removeFromParent()
                    enemyTeambg = img.createUI9Sprite(img.ui.botton_fram_2)
                    enemyTeambg:setPreferredSize(CCSizeMake(teamBgWidth, teamBgHeight))
                    bg:addChild(enemyTeambg)
                    droidhangComponents:mandateNode(enemyTeambg, "zFFL_vg2kCp")
                    enemyTeambg:addChild(createTeamItem(__data.enemy, __data.enemy.mask, true))

                    btnFight:setEnabled(true)
                    clearShader(btnFight, true)
                end)
            end)
        end)

        if data.status == 1 then
            json.load(json.ui.guildwar_ui)
            local boardAnim = DHSkeletonAnimation:createWithKey(json.ui.guildwar_ui)
            boardAnim:scheduleUpdateLua()
            boardAnim:playAnimation("close")
            rightAnimBg:addChild(boardAnim)
            droidhangComponents:mandateNode(boardAnim, "hpcK_UE65ao")
            self.boardAnim = boardAnim
        elseif data.status == 2 then
            if true then
                showMathCd(1)
            end

            json.load(json.ui.guildwar_ui)
            local boardAnim = DHSkeletonAnimation:createWithKey(json.ui.guildwar_ui)
            boardAnim:playAnimation("end")
            boardAnim:scheduleUpdateLua()
            boardAnim:update(10)
            rightAnimBg:addChild(boardAnim)
            droidhangComponents:mandateNode(boardAnim, "hpcK_UE65ao")
            self.boardAnim = boardAnim

            addTipsLabel(boardAnim, data.names)
        end
    else
        --正在战斗
        local fightBg = img.createUISprite(img.ui.guildFight_fight_bg)
        rightAnimBg:addChild(fightBg)
        droidhangComponents:mandateNode(fightBg, "BeSu_7bT8fp")

        local btnMathSprite1 = img.createUISprite(img.ui.guildFight_find_2)
        local btnMathLab = lbl.createFont1(16, i18n.global.guildFight_fight_ing.string, ccc3(0xff, 0xd7, 0x6b))
        btnMathLab:setPosition(btnMathSprite1:getContentSize().width/2, btnMathSprite1:getContentSize().height/2)
        btnMathSprite1:addChild(btnMathLab)
        droidhangComponents:mandateNode(btnMathSprite1, "BeSu_30AjBq")
        bg:addChild(btnMathSprite1)
        --local timerTitle = lbl.createFont1(16, i18n.global.guildFight_fight_ing.string)
        --bg:addChild(timerTitle)
        --droidhangComponents:mandateNode(timerTitle, "BeSu_30AjBq")

        local timerBg = img.createUISprite(img.ui.guildFight_battle_1)
        --timerBg:setPreferredSize(CCSizeMake(214, 34))
        bg:addChild(timerBg)
        droidhangComponents:mandateNode(timerBg, "BeSu_uxjby2")

        local timerProgress = createProgressBar(img.createUISprite(img.ui.guildFight_battle_3))
        timerProgress:setPosition(timerBg:getContentSize().width * 0.5, timerBg:getContentSize().height * 0.5)
        timerBg:addChild(timerProgress)
        timerProgress:setPercentage(data.cd / FIGHT_DURATION * 100)

        local timerDesc = lbl.createFont2(20, time2string(data.cd), ccc3(0xff, 0xf7, 0xe5))
        timerDesc:setPosition(timerBg:getContentSize().width * 0.5, timerBg:getContentSize().height * 0.5-2)
        timerBg:addChild(timerDesc)

        local startTime = os.time()
        timerDesc:scheduleUpdateWithPriorityLua(function ()
            local passTime = os.time() - startTime
            local remainCd = math.max(0, data.cd - passTime)

            timerDesc:setString(time2string(remainCd))
            timerProgress:setPercentage(remainCd / FIGHT_DURATION * 100)

            if remainCd <= 0 then
                timerDesc:unscheduleUpdate()

                local newData = clone(data)
                newData.status = 1
                newData.enemy = nil
                self:createRightTab(newData)

                local selfGuildObj = {logo = dataGuild.guildObj.logo, name = dataGuild.guildObj.name, sid = dataPlayer.sid}
                local enemyGuildObj = {logo = data.enemy.logo, name = data.enemy.name, sid = data.enemy.sid}
                local videoData = {bats = data.fight_bats}
                videoData.atk = {mbrs = self.guildData.mbrs}
                videoData.def = data.enemy
                self:addChild(require("ui.guildFight.videoDetail").create(data.fight_win, selfGuildObj, enemyGuildObj, videoData), 100)

                return
            end
        end)

        local params = {
            atkIds = {1101, 1102, 1103, 1201},
            defIds = {1202, 1203, 1301, 1302},
        }

        for _, mbr in ipairs(self.guildData.mbrs) do
            local findFlag
            for _, uid in ipairs(self.guildData.uids) do
                if uid == mbr.uid then
                    params.atkIds = {}
                    for _, info in ipairs(mbr.camp) do
                        if info.pos and info.pos == 7 then
                        elseif info.id then
                            table.insert(params.atkIds, info.id)
                        else
                            local heroInfo = dataHeros.find(info.hid)
                            table.insert(params.atkIds, heroInfo.id)
                        end
                    end
                    findFlag = true
                    break
                end
            end
            if findFlag then
                break
            end
        end

        if data.enemy and data.enemy.mbrs then
            for _, mbr in ipairs(data.enemy.mbrs) do
                params.defIds = {}
                for _, info in ipairs(mbr.camp) do
                    if info.pos and info.pos == 7 then
                    elseif info.id then
                        table.insert(params.defIds, info.id)
                    end
                end
                break
            end
        end

        self.demoFightLayer = (require"ui.guildFight.demoFight").create(params)
        self:addChild(self.demoFightLayer, 1000)
    end
end

function guildFightMain:createRightTabFinals(rightTabNode, data, waitting)
    -- local tempBg = cc.Sprite:create("temp.png")
    -- tempBg:setPosition(self.bg:getContentSize().width * 0.5, self.bg:getContentSize().height * 0.5)
    -- tempBg:setOpacity(100)
    -- self.bg:addChild(tempBg, 20)

    local bg = img.createUI9Sprite(img.ui.bag_btn_inner_bg)
    bg:setPreferredSize(CCSizeMake(876, 440))
    rightTabNode:addChild(bg)
    droidhangComponents:mandateNode(bg, "VTe0_cU034t")

    -- local titleLabel = lbl.createFont2(24, i18n.global.guildFight_final_vs.string, ccc3(0xe6, 0xd0, 0xae))
    -- bg:addChild(titleLabel)
    -- droidhangComponents:mandateNode(titleLabel, "3Jrf_t7yuHd")

    local lbl_title = lbl.createFont2(24, i18n.global.guildFight_final_vs.string, ccc3(0xe6, 0xd0, 0xae))
    bg:addChild(lbl_title, 2)
    droidhangComponents:mandateNode(lbl_title, "3Jrf_t7yuHd")

    -- local lbl_title_shadowD = lbl.createFont1(24, i18n.global.guildFight_final_vs.string, ccc3(0x59, 0x30, 0x1b))
    -- lbl_title_shadowD:setPosition(lbl_title:getPositionX(), lbl_title:getPositionY() - 2)
    -- bg:addChild(lbl_title_shadowD)

    local leftTitleIcon = img.createUISprite(img.ui.guildFight_icon_final)
    bg:addChild(leftTitleIcon)
    -- droidhangComponents:mandateNode(leftTitleIcon, "3Jrf_Rzjotm")
    leftTitleIcon:setAnchorPoint(1, 0.5)
    leftTitleIcon:setPosition(lbl_title:getPositionX() - lbl_title:getContentSize().width * 0.5 * lbl_title:getScaleX() - 40, lbl_title:getPositionY())

    local rightTitleIcon = img.createUISprite(img.ui.guildFight_icon_final)
    rightTitleIcon:setFlipX(true)
    bg:addChild(rightTitleIcon)
    rightTitleIcon:setAnchorPoint(0, 0.5)
    rightTitleIcon:setPosition(lbl_title:getPositionX() + lbl_title:getContentSize().width * 0.5 * lbl_title:getScaleX() + 40, lbl_title:getPositionY())
    -- droidhangComponents:mandateNode(rightTitleIcon, "3Jrf_4OZq0N")

    local labelNode = cc.Node:create()
    bg:addChild(labelNode)

    local cdLabel = lbl.createFont2(16, "", ccc3(0xc6, 0xff, 0x64))
    cdLabel:setString(time2string((data.cd or 0)))
    cdLabel:setAnchorPoint(0, 0.5)
    labelNode:addChild(cdLabel)

    local startTime = os.time()
    cdLabel:scheduleUpdateWithPriorityLua(function ()
        local passTime = os.time() - startTime
        local remainCd = math.max(0, (data.cd or 0) + 10 - passTime)

        cdLabel:setString(time2string(remainCd))

        if remainCd <= 0 then
            cdLabel:unscheduleUpdate()
            self:onRightTab()
            return
        end
    end)

    local descLabel = lbl.createFont2(16, "")
    labelNode:addChild(descLabel)

    if waitting then
        descLabel:setString(i18n.global.guildFight_start_cd.string)
    else
        descLabel:setString(i18n.global.guildFight_end_cd.string)
    end

    descLabel:setAnchorPoint(0, 0.5)

    cdLabel:setPositionX(descLabel:getContentSize().width * descLabel:getScaleX() + 15)

    local offsetX = descLabel:getContentSize().width * descLabel:getScaleX() + cdLabel:getContentSize().width * cdLabel:getScaleX() + 15
    labelNode:setPosition(bg:getContentSize().width * 0.5 - offsetX * 0.5, 365)

    if not data.guilds then
        return
    end

    -- 背景框大小
    local BG_WIDTH   = bg:getContentSize().width
    local BG_HEIGHT  = 360
    -- 滑动区域大小
    local SCROLL_MARGIN_TOP     = 8
    local SCROLL_MARGIN_BOTTOM  = 14
    local SCROLL_VIEW_WIDTH     = BG_WIDTH
    local SCROLL_VIEW_HEIGHT    = BG_HEIGHT - SCROLL_MARGIN_TOP - SCROLL_MARGIN_BOTTOM

    local scroll = CCScrollView:create()
    scroll:setDirection(kCCScrollViewDirectionVertical)
    scroll:setViewSize(CCSize(SCROLL_VIEW_WIDTH, SCROLL_VIEW_HEIGHT))
    scroll:setPosition(0, SCROLL_MARGIN_BOTTOM)
    bg:addChild(scroll)

    local function createItem(leftPlayer, rightPlayer, index)
        local bg = cc.Node:create()
        bg:setContentSize(cc.size(SCROLL_VIEW_WIDTH, 91))

        local bgName
        if (8 - index) % 2 == 1 then
            bgName = "guildFight_vs_bg_1.png"
        else
            bgName = "guildFight_vs_bg_2.png"
        end
        
        local leftBg = img.createUISprite(bgName)
        leftBg:setAnchorPoint(0, 0.5)
        leftBg:setPosition(30, bg:getContentSize().height * 0.5)
        bg:addChild(leftBg)
        if leftPlayer then
            local guildFlag = img.createGFlag(leftPlayer.logo or 1)
            guildFlag:setScale(0.8)
            leftBg:addChild(guildFlag)
            droidhangComponents:mandateNode(guildFlag, "9eUG_w8WLCh")

            local nameLabel = lbl.createFontTTF(18, leftPlayer.name or "unknow", ccc3(0x6c, 0x3e, 0x35))
            leftBg:addChild(nameLabel)
            droidhangComponents:mandateNode(nameLabel, "9eUG_xft90Y")

            local serverBg = img.createUISprite(img.ui.anrea_server_bg)
            leftBg:addChild(serverBg)
            droidhangComponents:mandateNode(serverBg, "9eUG_JFqvHp")

            local serverLabel = lbl.createFont1(16, getSidname(leftPlayer.sid or 1), ccc3(255, 251, 215))
            serverLabel:setPosition(serverBg:getContentSize().width * 0.5, serverBg:getContentSize().height * 0.5)
            serverBg:addChild(serverLabel)
        end

        local rightBg = img.createUISprite(bgName)
        rightBg:setAnchorPoint(1, 0.5)
        rightBg:setFlipX(true)
        rightBg:setPosition(bg:getContentSize().width - 30 + 3, bg:getContentSize().height * 0.5)
        bg:addChild(rightBg)
        if rightPlayer then
            local guildFlag = img.createGFlag(rightPlayer.logo or 1)
            guildFlag:setScale(0.8)
            rightBg:addChild(guildFlag)
            droidhangComponents:mandateNode(guildFlag, "YX87_kzoYuS")

            local nameLabel = lbl.createFontTTF(18, rightPlayer.name or "unknow", ccc3(0x6c, 0x3e, 0x35))
            rightBg:addChild(nameLabel)
            droidhangComponents:mandateNode(nameLabel, "YX87_8M4Bxj")

            local serverBg = img.createUISprite(img.ui.anrea_server_bg)
            rightBg:addChild(serverBg)
            droidhangComponents:mandateNode(serverBg, "YX87_XeI4cQ")

            local serverLabel = lbl.createFont1(16, getSidname(rightPlayer.sid or 1), ccc3(255, 251, 215))
            serverLabel:setPosition(serverBg:getContentSize().width * 0.5, serverBg:getContentSize().height * 0.5)
            serverBg:addChild(serverLabel)
        end

        local vsIcon = img.createUISprite(img.ui.fight_pay_vs)
        bg:addChild(vsIcon)
        droidhangComponents:mandateNode(vsIcon, "YX87_X77I8cQ")
        
        return bg
    end

    local height = 0
    local itemAry = {}
    for i = 1, 8 do
        local leftGuild = data.guilds[i]
        local rightGuild = data.guilds[17 - i]
        if leftGuild or rightGuild then
            local item = createItem(leftGuild, rightGuild, i)

            height = height + item:getContentSize().height + 8
            table.insert(itemAry, item)
            scroll:addChild(item)
        end
    end

    local sy = height - 4
    for _, item in ipairs(itemAry) do
        item:setAnchorPoint(0.5, 0.5)
        item:setPosition(SCROLL_VIEW_WIDTH * 0.5 - 2, sy - item:getContentSize().height * 0.5)
        sy = sy - item:getContentSize().height - 8
    end

    scroll:setContentSize(CCSize(SCROLL_VIEW_WIDTH, height))
    scroll:setContentOffset(ccp(0, SCROLL_VIEW_HEIGHT-height))
end

return guildFightMain
