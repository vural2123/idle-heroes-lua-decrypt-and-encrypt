local ui = {}

require "common.func"
require "common.const"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local audio = require "res.audio"
local cfgitem = require "config.item"
local cfgequip = require "config.equip"
local cfghero = require "config.hero"
local chatdata = require "data.chat"
local player = require "data.player"
local i18n = require "res.i18n"
local tipsequip = require "ui.tips.equip"
local tipsitem = require "ui.tips.item"
local dialog = require "ui.dialog"
local NetClient = require "net.netClient"
local netClient = NetClient:getInstance()

local TAG_EDIT = 3111

local current_tab = -1

local EXTRA_WIDTH = 100

local anim_duration = 0.2
local space_height = 3

local qltColor = {
    [1] = ccc3(0x00, 0x6e, 0xd5),
    [2] = ccc3(0xaa, 0x94, 0x00),
    [3] = ccc3(0x9e, 0x3f, 0xe1),
    [4] = ccc3(0x00, 0x94, 0x07),
    [5] = ccc3(0xe7, 0x25, 0x25),
    [6] = ccc3(0xfe, 0x78, 0x00),
}

function ui.getWorldTab()
	if i18n.getCurrentLanguage() == kLanguageChinese or i18n.getCurrentLanguage() == kLanguageChineseTW then
		return 5
	end
	return 1
end

function ui.initTab()
	if current_tab < 0 then
		current_tab = ui.getWorldTab()
	end
	return current_tab
end

local function stamp2str(_stamp)
    return os.date("[%H:%M %m-%d]", _stamp) 
end

local function createEdit(parentObj)
    local edit_bg = img.createLogin9Sprite(img.login.input_border)
    local edit_msg = CCEditBox:create(CCSizeMake((508+EXTRA_WIDTH)*view.minScale, 44*view.minScale), edit_bg)
    edit_msg:setInputFlag(kEditBoxInputFlagInitialCapsSentence)
    edit_msg:setReturnType(kKeyboardReturnTypeDone)
    edit_msg:setMaxLength(210)
    edit_msg:setFont("", 18*view.minScale)
    edit_msg:setFontColor(ccc3(0x0, 0x0, 0x0))
    edit_msg:setPlaceHolder("")
    edit_msg:setAnchorPoint(CCPoint(0, 0))
    edit_msg:setPosition(scalep(13, 17))
    parentObj:addChild(edit_msg, 100, TAG_EDIT)
    
    parentObj.edit_msg = edit_msg

    autoLayoutShift(edit_msg)
end

local function removeEdit(parentObj)
    local obj = parentObj:getChildByTag(TAG_EDIT)
    if obj then
        parentObj:removeChildByTag(TAG_EDIT)
        parentObj.edit_msg = nil
    end
end

local msg_pos = {
    head = {l=42, r=550-42+EXTRA_WIDTH},
    name = {l=89, r=550-89+EXTRA_WIDTH},
}

local share_items = {}

local function getShareInfo(share_id, callback)
    local nParams = {
        sid = player.sid,
        share_id = share_id,
    }
    addWaitNet()
    netClient:cunit(nParams, function(__data)
        delWaitNet()
        tbl2string(__data)
        if __data.status ~= 0 then
            if __data.status == -1 then
                showToast("have been deleted")
            end
            return
        end
        if callback then
            callback(__data.unit)
        end
    end)
end

local vip_a = {4, 3, 3, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1}
vip_a[0] = 1
local vip_c = {ccc3(0xe0, 0xe0, 0xe0), ccc3(0xe0, 0xe0, 0xe0), ccc3(0xe0, 0xe0, 0xe0), ccc3(0xe0, 0xe0, 0xe0), ccc3(0xe0, 0xe0, 0xe0), ccc3(0xff, 0xd1, 0x79), ccc3(0xff, 0xd1, 0x79), ccc3(0xff, 0xd1, 0x79), ccc3(0xff, 0xd1, 0x79), ccc3(0xff, 0xd1, 0x79), ccc3(0xff, 0xd1, 0x79), ccc3(0xff, 0xd1, 0x79), ccc3(0xff, 0xd1, 0x79)}
vip_c[0] = ccc3(0xff, 0xd1, 0x79)
local vip_s = {"System", "Dev", "Admin", "GM", "CS", "6", "7", "8", "9", "10", "11", "12", "13"}
vip_s[0] = "0"

json.load(json.ui.ic_vip)
local function createItem(msgObj, parentObj)
    local item_bg = CCSprite:create()
    local item = CCSprite:create()
    item:setContentSize(CCSizeMake(550 + EXTRA_WIDTH, 1))
    local isMe = false
    local anchorX = 0
    if msgObj.uid == player.uid then
        isMe = true
        anchorX = 1
    end
    -- head
    local head0
    if isMe then
        head0 = img.createPlayerHead(msgObj.logo, msgObj.lv, true)
    else
        head0 = img.createPlayerHead(msgObj.logo, msgObj.lv)
    end
    -- 公会战头像框
    if msgObj.final_rank then
        addHeadBox(head0, msgObj.final_rank, 122)
    end
    local head = SpineMenuItem:create(json.ui.button, head0)
    head:registerScriptTapHandler(function()
        audio.play(audio.button)
        if isMe then return end
        msgObj.report = true
        parentObj:addChild((require"ui.tips.player1").create(clone(msgObj)), 100)
    end)
    local name = lbl.create({kind="ttf", size=18, text=msgObj.name, color=ccc3(0x51, 0x27, 0x12),})
     -- width = 417
    local msg_bg = img.createUI9Sprite(img.ui.chat_bubble)
    local msg
    if msgObj.share_id then
        local msg_str = "[ " .. i18n.hero[msgObj.hero_id].heroName .. " ]"
        msg = lbl.create({kind="ttf", size=18, text=msg_str, color=qltColor[cfghero[msgObj.hero_id].qlt],})
    elseif msgObj.gid then
        local msg_str = "[ LV." .. msgObj.glv .. " " .. msgObj.gname .. " ]" .. msgObj.gmsg
        msg = lbl.create({kind="ttf", size=18, text=msg_str, color=ccc3(0x70, 0x4a, 0x2b),})
    elseif msgObj.gFight then
        local msg_str = i18n.global.chat_gFight_desc.string
        msg = lbl.create({kind="ttf", size=18, text=msg_str, color=ccc3(0x70, 0x4a, 0x2b),})
    else
        msg = lbl.create({kind="ttf", size=18, text=msgObj.text or "", color=ccc3(0x70, 0x4a, 0x2b),})
    end
    local extra_h = 0
    if msgObj.gid or msgObj.gFight then
        extra_h = 40
    elseif not msgObj.share_id then
        extra_h = 0
    end
    msg_bg:addChild(msg)
    local function updateMsgSize()
        msg:setDimensions(CCSizeMake(0, 0))
        if msg:getContentSize().width > 417+EXTRA_WIDTH then
            msg:setHorizontalAlignment(kCCTextAlignmentLeft)
            msg:setDimensions(CCSizeMake(417+EXTRA_WIDTH, 0))
            msg_bg:setPreferredSize(CCSizeMake(417+30+EXTRA_WIDTH, msg:getContentSize().height+30+extra_h))
        else
            local width = msg:getContentSize().width+30
            if extra_h > 0 then
                width = op3(width > 200, width, 200)
            end
            msg_bg:setPreferredSize(CCSizeMake(width, msg:getContentSize().height+30+extra_h))
        end
        msg:setAnchorPoint(CCPoint(0.5, 1))
        msg:setPosition(CCPoint(msg_bg:getContentSize().width/2, msg_bg:getContentSize().height - 15))
    end
    updateMsgSize()
    local time_str = ""
    if msgObj.time then
        time_str = stamp2str(msgObj.time)
    end
    local lbl_time = lbl.createFont1(14, time_str, ccc3(0x82, 0x4f, 0x27))
    -- 是否是英雄分享信息
    if msgObj.share_id then
        msg_bg.share_id = msgObj.share_id
        share_items[#share_items+1] = msg_bg
        -- create a button
        local share_btn0 = CCSprite:create()
        share_btn0:setContentSize(CCSizeMake(msg:getContentSize().width+30, msg:getContentSize().height+30))
        local share_btn = CCMenuItemSprite:create(share_btn0, nil)
        share_btn:setPosition(CCPoint(msg_bg:getContentSize().width/2, msg_bg:getContentSize().height/2))
        local share_btn_menu = CCMenu:createWithItem(share_btn)
        share_btn_menu:setPosition(CCPoint(0, 0))
        msg_bg:addChild(share_btn_menu)
        share_btn:registerScriptTapHandler(function()
            audio.play(audio.button)
            getShareInfo(msgObj.share_id, function(heroInfo)
                parentObj:addChild((require"ui.tips.hero").create(heroInfo), 1000)
            end)
        end)
    elseif msgObj.gid then
        local lbl_invite = lbl.createMixFont1(10, i18n.global.chat_btn_join.string, ccc3(0x1b, 0x59, 0x02))
        local btn_invite0 = img.createLogin9Sprite(img.login.button_9_small_green)
        btn_invite0:setContentSize(CCSizeMake(150, 40))
        lbl_invite:setPosition(CCPoint(btn_invite0:getContentSize().width/2, btn_invite0:getContentSize().height/2+1))
        btn_invite0:addChild(lbl_invite)
        local btn_invite = SpineMenuItem:create(json.ui.button, btn_invite0)
        btn_invite:setPosition(CCPoint(msg_bg:getContentSize().width/2, 30))
        local btn_invite_menu = CCMenu:createWithItem(btn_invite)
        btn_invite_menu:setPosition(CCPoint(0, 0))
        msg_bg:addChild(btn_invite_menu)
        btn_invite:registerScriptTapHandler(function()
            disableObjAWhile(btn_invite)
            audio.play(audio.button)
            if player.gid and player.gid > 0 then
                showToast(i18n.global.guild_accepted_u.string)
                return
            end
            if player.lv() < UNLOCK_GUILD_LEVEL then
                showToast(string.format(i18n.global.func_need_lv.string, UNLOCK_GUILD_LEVEL))
                return
            end
            parentObj:addChild(require("ui.guild.search").create({word=msgObj.gid}), 1000)
        end)
    elseif msgObj.gFight then
        local lbl_invite = lbl.createMixFont1(10, i18n.global.chat_btn_gFight.string, ccc3(0x1b, 0x59, 0x02))
        local btn_invite0 = img.createLogin9Sprite(img.login.button_9_small_green)
        btn_invite0:setContentSize(CCSizeMake(150, 40))
        lbl_invite:setPosition(CCPoint(btn_invite0:getContentSize().width/2, btn_invite0:getContentSize().height/2+1))
        btn_invite0:addChild(lbl_invite)
        local btn_invite = SpineMenuItem:create(json.ui.button, btn_invite0)
        btn_invite:setPosition(CCPoint(msg_bg:getContentSize().width/2, 30))
        local btn_invite_menu = CCMenu:createWithItem(btn_invite)
        btn_invite_menu:setPosition(CCPoint(0, 0))
        msg_bg:addChild(btn_invite_menu)
        btn_invite:registerScriptTapHandler(function()
            disableObjAWhile(btn_invite)
            audio.play(audio.button)
            local gdata = require "data.guild"
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
                    replaceScene((require"ui.guildVice.main").create({from_layer="gwar"}))
                end)
            elseif player.gid and player.gid > 0 and gdata.IsInit() then
                replaceScene((require"ui.guildVice.main").create({from_layer="gwar"}))
            else
            end
        end)
    else -- 普通消息，加翻译按钮
    end
    
    local arrow = img.createUISprite(img.ui.chat_bubble_arrow)
    local icon_vip = DHSkeletonAnimation:createWithKey(json.ui.ic_vip)
    icon_vip:setScale(0.70)
    icon_vip:scheduleUpdateLua()
    if msgObj.vip then
        icon_vip:playAnimation("" .. vip_a[msgObj.vip], -1)
        local lbl_player_vip = lbl.createFont2(18, vip_s[msgObj.vip], ccc3(0xff, 0xdc, 0x82))
        lbl_player_vip:setColor(vip_c[msgObj.vip])
        icon_vip:addChildFollowSlot("code_num", lbl_player_vip)
    end
    if isMe then
        name:setAnchorPoint(CCPoint(1, 1))
        msg_bg:setAnchorPoint(CCPoint(1, 1))
        lbl_time:setAnchorPoint(CCPoint(0, 1))
        head:setPosition(CCPoint(550-42+EXTRA_WIDTH, -47))
        name:setPosition(CCPoint(550-95+EXTRA_WIDTH, -8))
        msg_bg:setPosition(CCPoint(550-95+EXTRA_WIDTH, -37))
        lbl_time:setPosition(CCPoint(8, -8))
        icon_vip:setPosition(CCPoint(name:boundingBox():getMinX()-30, -20))
        arrow:setFlipX(true)
        arrow:setAnchorPoint(CCPoint(0, 1))
        arrow:setPosition(CCPoint(msg_bg:getContentSize().width-2, msg_bg:getContentSize().height-14))
        msg_bg:addChild(arrow)
    else
        name:setAnchorPoint(CCPoint(0, 1))
        msg_bg:setAnchorPoint(CCPoint(0, 1))
        lbl_time:setAnchorPoint(CCPoint(1, 1))
        head:setPosition(CCPoint(42, -47))
        name:setPosition(CCPoint(95, -8))
        msg_bg:setPosition(CCPoint(95, -37))
        lbl_time:setPosition(CCPoint(550-8+EXTRA_WIDTH, -8))
        icon_vip:setPosition(CCPoint(name:boundingBox():getMaxX()+30, -20))
        arrow:setAnchorPoint(CCPoint(1, 1))
        arrow:setPosition(CCPoint(2, msg_bg:getContentSize().height-14))
        msg_bg:addChild(arrow)
    end
    local head_menu = CCMenu:createWithItem(head)
    head_menu:setPosition(CCPoint(0, 0))
    item:addChild(head_menu)
    item:addChild(name)
    item:addChild(icon_vip)
    item:addChild(msg_bg)
    item:addChild(lbl_time)
    item.height = 37+msg_bg:getContentSize().height+10

    if msgObj.vip and msgObj.vip > 0 then
        icon_vip:setVisible(true)
    else
        icon_vip:setVisible(false)
    end

    item_bg:setContentSize(CCSizeMake(550+EXTRA_WIDTH, item.height))
    item:setAnchorPoint(CCPoint(0, 1))
    item:setPosition(CCPoint(0, item.height))
    item_bg:addChild(item)
    item_bg.height = item.height
    return item_bg
end

function ui.create(params)
	ui.initTab()
	
	local chan = chatdata.getChannel(current_tab)

    local layer = CCLayer:create()

    local board = img.createUI9Sprite(img.ui.chat_board)
    board:setPreferredSize(CCSizeMake(602+EXTRA_WIDTH, 576))
    board:setScale(view.minScale)
    board:setAnchorPoint(CCPoint(0, 0))
    board:setPosition(scalep(-(630+EXTRA_WIDTH), 0))
    layer:addChild(board)

    autoLayoutShift(board)

    local fix_bg = img.createUI9Sprite(img.ui.chat_board)
    fix_bg:setPreferredSize(CCSizeMake(200, 576))
    fix_bg:setAnchorPoint(CCPoint(1, 0))
    fix_bg:setPosition(CCPoint(0, 0))
    board:addChild(fix_bg)

    --anim
    local arr_anim = CCArray:create()
    arr_anim:addObject(CCCallFunc:create(function()
        board:runAction(CCMoveTo:create(anim_duration, getAutoLayoutShiftPos(board, scalep(0, 0))))
    end))
    arr_anim:addObject(CCDelayTime:create(anim_duration))
    arr_anim:addObject(CCCallFunc:create(function()
        createEdit(layer)
    end))
    layer:runAction(CCSequence:create(arr_anim))

    local board_w = board:getContentSize().width
    local board_h = board:getContentSize().height

    local btn_close0 = img.createUISprite(img.ui.chat_btn_close)
    local btn_close = HHMenuItem:createWithScale(btn_close0, 1)
    btn_close:setAnchorPoint(CCPoint(0, 0.5))
    btn_close:setPosition(CCPoint(board_w-4, board_h/2))
    local btn_close_menu = CCMenu:createWithItem(btn_close)
    btn_close_menu:setPosition(CCPoint(0, 0))
    board:addChild(btn_close_menu)

    local function backEvent()
        audio.play(audio.button)
        local arr = CCArray:create()
        arr:addObject(CCCallFunc:create(function()
            removeEdit(layer)
        end))
        arr:addObject(CCMoveTo:create(anim_duration, getAutoLayoutShiftPos(board, scalep(-(630+EXTRA_WIDTH), 0))))
        arr:addObject(CCDelayTime:create(anim_duration))
        arr:addObject(CCCallFunc:create(function()
            layer:removeFromParentAndCleanup(true)
        end))
        board:runAction(CCSequence:create(arr))
    end
    
    btn_close:registerScriptTapHandler(function()
        backEvent()
    end)

    -- btn_send
    local btn_send0 = img.createUISprite(img.ui.chat_btn_send)
    local btn_send = SpineMenuItem:create(json.ui.button, btn_send0)
    btn_send:setPosition(CCPoint(board_w-44, 37))
    local btn_send_menu = CCMenu:createWithItem(btn_send)
    btn_send_menu:setPosition(CCPoint(0, 0))
    board:addChild(btn_send_menu)

    local tab_world0 = img.createLogin9Sprite(img.login.button_9_small_gold) -- mwhite
	local btnHeight = 52
	local btnExtraUp = 0 --math.floor((btnHeight - 47) / 2)
    tab_world0:setPreferredSize(CCSizeMake(300, btnHeight))
    addRedDot(tab_world0, {
        px=tab_world0:getContentSize().width-5,
        py=tab_world0:getContentSize().height-5,
    })
    delRedDot(tab_world0)
    local lbl_tab_world = lbl.createFontTTF(20, chan.proto.label, ccc3(0x73, 0x3b, 0x05)) --lbl.createMix({ font = 1, size = 20, text = chan.proto.label, width = 290, color = ccc3(0x73, 0x3b, 0x05), align = kCCTextAlignmentCenter }) -- lbl.createFont1(20, chan.proto.label, ccc3(0x73, 0x3b, 0x05))
    lbl_tab_world:setPosition(CCPoint(tab_world0:getContentSize().width/2, tab_world0:getContentSize().height/2))
    tab_world0:addChild(lbl_tab_world)
    
    local tab_world = SpineMenuItem:create(json.ui.button, tab_world0)
    tab_world:setPosition(CCPoint(math.floor(board_w / 2), 543 + btnExtraUp))
    local tab_world_menu = CCMenu:createWithItem(tab_world)
    tab_world_menu:setPosition(CCPoint(0, 0))
    board:addChild(tab_world_menu, 1)

    -- btn_setting
    local btn_setting0 = img.createUISprite(img.ui.guild_icon_admin)
    local btn_setting = SpineMenuItem:create(json.ui.button, btn_setting0)
    btn_setting:setPosition(CCPoint(board_w-33, 543))
    local btn_setting_menu = CCMenu:createWithItem(btn_setting)
    btn_setting_menu:setPosition(CCPoint(0, 0))
    board:addChild(btn_setting_menu)
    btn_setting:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer:addChild((require"ui.chat.setting").create(), 1000)
    end)

    -- content_bg
    local content_bg = img.createUI9Sprite(img.ui.chat_bg)
    content_bg:setPreferredSize(CCSizeMake(576+EXTRA_WIDTH, 439))
    content_bg:setAnchorPoint(CCPoint(0, 0))
    content_bg:setPosition(CCPoint(12, 74))
    board:addChild(content_bg)
    local content_bg_w = content_bg:getContentSize().width
    local content_bg_h = content_bg:getContentSize().height

    local msg_container = CCSprite:create()
    msg_container:setContentSize(CCSizeMake(576+EXTRA_WIDTH, 439))
    msg_container:setAnchorPoint(CCPoint(0, 0))
    msg_container:setPosition(CCPoint(0, 0))
    content_bg:addChild(msg_container)
    layer.msg_container = msg_container
    local msg_container_w = msg_container:getContentSize().width
    local msg_container_h = msg_container:getContentSize().height


    local function createScroll()
        local scroll_params = {
            width = 550+EXTRA_WIDTH,
            height = 428,
        }
        local lineScroll = require "ui.lineScroll"
        return lineScroll.create(scroll_params)
    end

    local function showList(listObj)
        arrayclear(share_items)
        share_items = {}
        local scroll = createScroll()
        scroll:setAnchorPoint(CCPoint(0, 0))
        scroll:setPosition(CCPoint(13, 6))
        msg_container:addChild(scroll)
        msg_container.scroll = scroll
        --drawBoundingbox(msg_container, scroll)
        for ii=1,#listObj do
            local tmp_item = createItem(listObj[ii], layer)
            tmp_item.msgObj = listObj[ii]
            tmp_item.ax = 0.5
            tmp_item.px = 275+ math.floor(EXTRA_WIDTH / 2)
            scroll.addItem(tmp_item)
            if ii ~= #listObj then
                scroll.addSpace(space_height)
            end
        end
        scroll.setOffsetEnd()
    end
	
	local function showChat()
		local msg_list = chatdata.getMsg(current_tab)
		showList(msg_list)
	end

    local function onTabSel(which)
        msg_container:removeAllChildrenWithCleanup(true)
        msg_container.scroll = nil
        current_tab = which
		chan = chatdata.getChannel(which)
		lbl_tab_world:setString(chan.proto.label)
		showChat()
		if chan.proto.nosend then
		elseif layer.edit_msg then
			layer.edit_msg:setVisible(true)
            btn_send:setVisible(true)
			content_bg:setPreferredSize(CCSizeMake(576+EXTRA_WIDTH, 439))
			content_bg:setPosition(CCPoint(12, 74))
			msg_container.scroll:setViewSize(CCSize(550+EXTRA_WIDTH, 428))
		end
    end
    onTabSel(current_tab)
	
	local function gotoGuild()
        local function process_dialog(data)
            layer:removeChildByTag(dialog.TAG)
            if data.selected_btn == 2 then  -- join
                layer:addChild((require"ui.guild.recommend").create(true), 10000)
            elseif data.selected_btn == 1 then  -- create
                layer:addChild((require"ui.guild.create").create(true), 10000)
            end
        end
        local dParams = {
            title = "",
            body = i18n.global.goto_guild_body.string,
            btn_count = 2,
            btn_color = {
                [1] = dialog.COLOR_GOLD,
                [2] = dialog.COLOR_GOLD,
            },
            btn_text = {
                [1] = i18n.global.goto_guild_create.string,
                [2] = i18n.global.goto_guild_join.string,
            },
            callback = process_dialog,
        }
        local dialog_ins = dialog.create(dParams, true)
        dialog_ins:setAnchorPoint(CCPoint(0, 0))
        dialog_ins:setPosition(CCPoint(0, 0))
        layer:addChild(dialog_ins, 10000, dialog.TAG)
    end

    tab_world:registerScriptTapHandler(function()
        audio.play(audio.button)
		layer:addChild((require"ui.chat.channel").create(current_tab, function(newTab)
			local newChan = chatdata.getChannel(newTab)
			if newChan and newChan.proto.isguild then
				if player.lv() < UNLOCK_GUILD_LEVEL then
					showToast(string.format(i18n.global.func_need_lv.string, UNLOCK_GUILD_LEVEL))
					return
				end
				-- check guild
				if player.gid <= 0 then
					gotoGuild()
					return
				end
			end
			onTabSel(newTab)
		end), 1000)
    end)
	
    btn_send:registerScriptTapHandler(function()
        audio.play(audio.button)
        if not layer.edit_msg or tolua.isnull(layer.edit_msg) then
            return
        end
        local msg_type = chan.proto.id
		if chan.proto.speaklv then
			local reqlv = chatdata.getSpeakLv()
			if player.lv() < reqlv then
				showToast(string.format(i18n.global.func_need_lv.string, reqlv))
                return
			end
		end
		if chan.proto.speaktime then
			if chatdata.last_world_sent then
				local reqcd = chatdata.getSpeakCd()
				local timeSince = math.max(0, os.time() - chatdata.last_world_sent)
                if timeSince < reqcd then
                    showToast(string.format(i18n.global.chat_interval.string, reqcd - timeSince))
                    return
                end
            end
		end
		if chan.proto.isguild then
			if not player.gid or player.gid <= 0 then
                showToast(i18n.global.chat_toast_need_guild.string)
                return
            end
		end
        local sendStr = layer.edit_msg:getText()
        sendStr = string.trim(sendStr)
        --[[if false then
            showToast(i18n.global.input_invalid_char.string)
            return
        end--]]
        if sendStr == "" then
            showToast(i18n.global.chat_toast_empty_msg.string)
            return
        end
        if containsInvalidChar(sendStr) then
            showToast(i18n.global.input_invalid_char.string)
            return
        end
        local send_params = {
            sid = player.sid,
            type = msg_type,
            text = sendStr,
        }
		addWaitNet()
        chatdata.send(send_params, function(__data)
			delWaitNet()
			if __data.status < 0 then
				showToast("status:"..__data.status)
			end
		end)
        layer.edit_msg:setText("")
        if chan.proto.speaktime then
            chatdata.last_world_sent = os.time()
        end
    end)

    local function onUpdate(ticks)
		local tmp_new_msg = chatdata.fetchMsg(current_tab)
		local scrollObj = msg_container.scroll
        if scrollObj and not tolua.isnull(scrollObj) and tmp_new_msg and #tmp_new_msg > 0 then
			for i=1, #tmp_new_msg do
				scrollObj.addSpace(space_height)
                local tmp_item = createItem(tmp_new_msg[i], layer)
                scrollObj.addItem(tmp_item)
			end
			scrollObj.updateOffsetEnd()
		end
		
		if chan.proto.nosend and layer.edit_msg then
			layer.edit_msg:setVisible(false)
			btn_send:setVisible(false)
			content_bg:setPreferredSize(CCSizeMake(576+EXTRA_WIDTH, 499))
			content_bg:setPosition(CCPoint(12, 14))
			if scrollObj then
				scrollObj:setViewSize(CCSize(550+EXTRA_WIDTH, 488))
			end
		end
		
        -- check reddot
        local chatdata = require "data.chat"
        if chatdata.showRedDot(nil, current_tab) then
            addRedDot(tab_world0, {
                px=tab_world0:getContentSize().width-5,
                py=tab_world0:getContentSize().height-5,
            })
        else
            delRedDot(tab_world0)
        end
    end
    
    layer:scheduleUpdateWithPriorityLua(onUpdate, 0)

    -- touch event
    local touchbeginx, touchbeginy
    local isclick
    local function onTouchBegan(x, y)
        touchbeginx, touchbeginy = x, y
        isclick = true
        return true
    end
    local function onTouchMoved(x, y)
        if isclick and (math.abs(touchbeginx-x) > 10 or math.abs(touchbeginy-y) > 10) then
            isclick = false
        end
    end
    local function onTouchEnded(x, y)
        local p0 = layer:convertToNodeSpace(ccp(x, y))
        if isclick and not board:boundingBox():containsPoint(p0) then
            backEvent()
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
        end
    end)

    return layer
end

return ui
