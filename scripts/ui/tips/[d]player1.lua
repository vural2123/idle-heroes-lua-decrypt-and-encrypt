local tips = {}

require "common.func"
require "common.const"
local view = require "common.view"
local player = require "data.player"
local net = require "net.netClient"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local audio = require "res.audio"
local i18n = require "res.i18n"
local friend = require "data.friend"


--[[
params = {
    name = "Candy123",
    logoId = 1,
    lv = 20,
    id = 39462,
    guild = "soul blade",
    power = 9998,
    frd = obj
    defens = {
        [1] = { id = 1101, pos = 3, lv = 29, star = 2 }
    },
    buttons = {
        [1] = { text = "add" , Color = 1, handler = func }// Color: 1 yellow, 2 red
    }
}
--]]

local TIPS_WIDTH = 516
local TIPS_HEIGHT = 342
local BUTTON_POSX = {
    [1] = { 258 },
    [2] = { 470, 414, 258, 102},
    [3] = { 100, 262, 424 },
}

local COLOR2TYPE = {
    [1] = img.login.button_9_small_gold,
    [2] = img.login.button_9_small_orange,
}

function tips.create(params, way, callBack)  --way默认表示添加好友  way:"del" 表示删除好友  way:"none" 只有确认按钮
    local _csid = 0
    local function string_starts(String,Start)
        return string.sub(String,1,string.len(Start))==Start
    end
    if string_starts(params.name, "[Seasonal]") then
        _csid = 102
    elseif string_starts(params.name, "[S1]") then
        _csid = 101
    elseif string_starts(params.name, "[S2]") then
        _csid = 102
    end
    local layer = CCLayer:create()

    local guildName = params.guild or ""
    local board = img.createUI9Sprite(img.ui.tips_bg)
    board:setPreferredSize(CCSize(TIPS_WIDTH, TIPS_HEIGHT))
    board:setScale(view.minScale)
    board:setPosition(view.midX, view.midY)
    layer:addChild(board)
    layer.board = board

    local showHead = img.createPlayerHead(params.logo, params.lv)
    showHead:setPosition(68, TIPS_HEIGHT - 68)
    board:addChild(showHead)

    local showName = lbl.createFontTTF(20, params.name)
    showName:setAnchorPoint(ccp(0, 0))
    showName:setPosition(118, TIPS_HEIGHT - 54)
    board:addChild(showName)

    local showID = lbl.createFont1(16, "ID " .. params.uid, ccc3(255, 246, 223))
    showID:setAnchorPoint(ccp(0, 0))
    showID:setPosition(118, TIPS_HEIGHT - 85)
    board:addChild(showID)

    local titleGuild = lbl.createFont2(18, i18n.global.tips_player_guild.string .. ":", ccc3(0xed, 0xcb, 0x1f))
    titleGuild:setAnchorPoint(ccp(0, 0))
    titleGuild:setPosition(118, TIPS_HEIGHT - 110)
    board:addChild(titleGuild)

    local function createdelete()
        local deletparams = {}
        deletparams.btn_count = 0
        deletparams.body = string.format(i18n.global.friend_sure_delete.string)

        local dialoglayer = require("ui.dialog").create(deletparams) 

        local btnYesSprite = img.createLogin9Sprite(img.login.button_9_small_gold)
        btnYesSprite:setPreferredSize(CCSize(115, 43))
        local btnYes = SpineMenuItem:create(json.ui.button, btnYesSprite)
        btnYes:setPosition(340, 100)
        local labYes = lbl.createFont1(18, i18n.global.board_confirm_yes.string, ccc3(0x73, 0x3b, 0x05))
        labYes:setPosition(btnYes:getContentSize().width/2, btnYes:getContentSize().height/2)
        btnYesSprite:addChild(labYes)
        local menuYes = CCMenu:create()
        menuYes:setPosition(0, 0)
        menuYes:addChild(btnYes)
        dialoglayer.board:addChild(menuYes)

        local btnNoSprite = img.createLogin9Sprite(img.login.button_9_small_gold)
        btnNoSprite:setPreferredSize(CCSize(115,43))
        local btnNo = SpineMenuItem:create(json.ui.button, btnNoSprite)
        btnNo:setPosition(150, 100)
        local labNo = lbl.createFont1(18, i18n.global.board_confirm_no.string, ccc3(0x73, 0x3b, 0x05))
        labNo:setPosition(btnNo:getContentSize().width/2, btnNo:getContentSize().height/2)
        btnNoSprite:addChild(labNo)
        local menuNo = CCMenu:create()
        menuNo:setPosition(0, 0)
        menuNo:addChild(btnNo)
        dialoglayer.board:addChild(menuNo)
        
        btnYes:registerScriptTapHandler(function()
            dialoglayer:removeFromParentAndCleanup(true)
            local param = {}
            param.sid = player.sid
            param.rm = params.uid

            addWaitNet()
            net:frd_op(param, function(__data)
                delWaitNet()
                tbl2string(__data)
                if __data.status ~= 0 then
                    showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                    return
                end
                friend.delFriendsList(params.frd)
                layer:removeFromParentAndCleanup(true)
                callBack()
                showToast(i18n.global.friend_delete_success.string)
            end)  
            audio.play(audio.button)
        end)
        btnNo:registerScriptTapHandler(function()
            dialoglayer:removeFromParentAndCleanup(true)
            audio.play(audio.button)
        end)

        local function backEvent()
            dialoglayer:removeFromParentAndCleanup(true)
        end

        function dialoglayer.onAndroidBack()
            backEvent()
        end

        addBackEvent(dialoglayer)
        
        local function onEnter()
            dialoglayer.notifyParentLock()
        end

        local function onExit()
            dialoglayer.notifyParentUnlock()
        end

        --dialoglayer:registerScriptHandler(function(event) 
        --    if event == "enter" then 
        --        onEnter()
        --    elseif event == "exit" then
        --        onExit()
        --    end
        --end)
        return dialoglayer
    end

    --local wayText = i18n.global.friend_add.string

    if friend.friends.friendsList and way ~= "del" then
        for i,obj in ipairs(friend.friends.friendsList) do
            if obj.name == params.name then
                way = "none"
                break
            end
        end
    end
            
    --if way == "del" then
    --    wayText = i18n.global.friend_delete.string
    --elseif way == "none" then
    --    wayText = "none"
    --else
    --    wayText = i18n.global.friend_add.string
    --end
    local btnConfig = {
        [1] = { text = "", Color = 1 },
        [2] = { text = i18n.global.friend_mail.string, Color = 1 },
        [3] = { text = i18n.global.chat_shield.string, Color = 1 },
        [4] = { text = i18n.global.friend_report.string, Color = 2 },
    }

    local btn = {}
	
	if params.isGuild then
		btnConfig[4].text = i18n.global.trial_stage_btn_battle.string
		btnConfig[4].Color = 1
	end

    btnConfig[1].handler = function() 
        audio.play(audio.button)
        if way == "del" then
            local dialog = createdelete()
            layer:addChild(dialog, 300)

        else
            if friend.friends.friendsList and #friend.friends.friendsList >= 30 then
                showToast(i18n.global.friend_friends_limit.string) 
                return
            end
            local param = {}
            param.sid = player.sid
            param.apply = params.uid
            addWaitNet()
            net:frd_op(param, function(__data)
                delWaitNet()
                tbl2string(__data)
                if __data.status == -1 then
                    showToast(i18n.global.friend_are_friend.string)
                    return
                end
                if __data.status ~= 0 then
                    showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                    return
                end
                if params.frd then
                    friend.delFriendsRecmd(params.frd)
                    callBack()
                end                

                if layer and not tolua.isnull(layer) then
                    layer:removeFromParentAndCleanup(true)
                end
                showToast(i18n.global.friend_apply_succese.string)
            end)
        end
    end

    btnConfig[2].handler = function()
        audio.play(audio.button)
        local maillayer = require "ui.mail.main"
        local mParams = {
            tab = maillayer.TAB.NEW,
            sendto = params.uid,
            close = true,
        }
        layer:addChild(maillayer.create(mParams), 100)
    end

    -- 确认是否屏蔽玩家
    local function createshield()
        local paramss = {}
        paramss.btn_count = 0
        paramss.body = i18n.global.chat_sure_shield.string

        local dialoglayer = require("ui.dialog").create(paramss) 

        local btnYesSprite = img.createLogin9Sprite(img.login.button_9_small_gold)
        btnYesSprite:setPreferredSize(CCSize(153, 50))
        local btnYes = SpineMenuItem:create(json.ui.button, btnYesSprite)
        btnYes:setPosition(340, 100)
        local labYes = lbl.createFont1(18, i18n.global.dialog_button_confirm.string, ccc3(0x73, 0x3b, 0x05))
        labYes:setPosition(btnYes:getContentSize().width/2, btnYes:getContentSize().height/2)
        btnYesSprite:addChild(labYes)
        local menuYes = CCMenu:create()
        menuYes:setPosition(0, 0)
        menuYes:addChild(btnYes)
        dialoglayer.board:addChild(menuYes)

        local btnNoSprite = img.createLogin9Sprite(img.login.button_9_small_gold)
        btnNoSprite:setPreferredSize(CCSize(153, 50))
        local btnNo = SpineMenuItem:create(json.ui.button, btnNoSprite)
        btnNo:setPosition(150, 100)
        local labNo = lbl.createFont1(18, i18n.global.dialog_button_cancel.string, ccc3(0x73, 0x3b, 0x05))
        labNo:setPosition(btnNo:getContentSize().width/2, btnNo:getContentSize().height/2)
        btnNoSprite:addChild(labNo)
        local menuNo = CCMenu:create()
        menuNo:setPosition(0, 0)
        menuNo:addChild(btnNo)
        dialoglayer.board:addChild(menuNo)

        
        btnYes:registerScriptTapHandler(function()
            dialoglayer:removeFromParentAndCleanup(true)
            audio.play(audio.button)
            local param = {}
            param.sid = player.sid
            param.uid = params.uid 
            addWaitNet()
            net:block_chat(param, function(__data)
                delWaitNet()
                tbl2string(__data)
                if __data.status ~= 0 then
                    showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                    return
                end
            end)
        end)
        btnNo:registerScriptTapHandler(function()
            dialoglayer:removeFromParentAndCleanup(true)
            audio.play(audio.button)
        end)

        local function backEvent()
            dialoglayer:removeFromParentAndCleanup(true)
        end

        function dialoglayer.onAndroidBack()
            backEvent()
        end

        addBackEvent(dialoglayer)
        
        local function onEnter()
            dialoglayer.notifyParentLock()
        end

        local function onExit()
            dialoglayer.notifyParentUnlock()
        end

        --dialoglayer:registerScriptHandler(function(event) 
        --    if event == "enter" then 
        --        onEnter()
        --    elseif event == "exit" then
        --        onExit()
        --    end
        --end)
        return dialoglayer
    end

    btnConfig[3].handler = function()
        local dialog = createshield()
        layer:addChild(dialog, 300)
    end

	if params.isGuild then
		btnConfig[4].handler = function()
			--audio.play(audio.button)
			layer:addChild(require("ui.selecthero.main").create({type = "frdpk", info = params, from_layer = "guild"}))
		end
	else
		btnConfig[4].handler = function()
			audio.play(audio.button)
			local param = {}
			param.sid = player.sid
			param.uid = params.uid
			addWaitNet()
			net:report(param, function(__data)
				delWaitNet()
				showToast(i18n.global.friend_report_toast.string)
				setShader(btn[4], SHADER_GRAY, true)
				btn[4]:setEnabled(false)
			end)
		end
	end

    for i, v in ipairs(btnConfig) do

        local btnSp = nil
        local menu = nil
        if i == 1 then
            if way == "del" then
                btnSp = img.createUISprite(img.ui.player_deletefrd)
            else
                btnSp = img.createUISprite(img.ui.player_addfrd)
            end
            btn[i] = SpineMenuItem:create(json.ui.button, btnSp)
            btn[i]:setPosition(BUTTON_POSX[2][i], TIPS_HEIGHT - 48)
            menu = CCMenu:createWithItem(btn[i])
            menu:setPosition(0, 0)
            board:addChild(menu)
        else
            btnSp = img.createLogin9Sprite(COLOR2TYPE[v.Color])
            btnSp:setPreferredSize(CCSize(148, 46))
            btn[i] = SpineMenuItem:create(json.ui.button, btnSp)
            btn[i]:setPosition(BUTTON_POSX[2][i], TIPS_HEIGHT - 296)
            menu = CCMenu:createWithItem(btn[i])
            menu:setPosition(0, 0)
            board:addChild(menu)
            local label = nil
            local icon = nil
            if i == 2 then 
                icon = img.createUISprite(img.ui.player_sendmail)
                icon:setPosition(btnSp:getContentSize().width/5-2, btnSp:getContentSize().height/2+1)
                label = lbl.createFont1(16, v.text or "", ccc3(0x76, 0x25, 0x05))
                label:setPosition(icon:boundingBox():getMaxX()+50, btnSp:getContentSize().height/2+1)
            end
            if i == 3 then 
                icon = img.createUISprite(img.ui.player_block)
                icon:setPosition(btnSp:getContentSize().width/5-2, btnSp:getContentSize().height/2+1)
                label = lbl.createFont1(16, v.text or "", ccc3(0x76, 0x25, 0x05))
                label:setPosition(icon:boundingBox():getMaxX()+50, btnSp:getContentSize().height/2+1)
            end
            if i == 4 then
				if not params.isGuild then
					icon = img.createUISprite(img.ui.player_report)
					icon:setPosition(btnSp:getContentSize().width/5-2, btnSp:getContentSize().height/2+1)
					label = lbl.createFont1(16, v.text or "", ccc3(0x7a, 0x28, 0x13))
					label:setPosition(icon:boundingBox():getMaxX()+50, btnSp:getContentSize().height/2+1)
				else
					label = lbl.createFont1(16, v.text or "", ccc3(0x76, 0x25, 0x05))
					label:setPosition(btnSp:getContentSize().width / 2, btnSp:getContentSize().height/2+1)
				end
            end
			if icon then
				btnSp:addChild(icon)
			end
            btnSp:addChild(label)
        end

        if v.handler then
            btn[i]:registerScriptTapHandler(function() 
                audio.play(audio.button)
                v.handler()
            end)
        end

        if way == "none" and i == 1 then
            btn[i]:setVisible(false)
        end
        if i == 4 and (params.report == nil and not params.isGuild) then
            btn[i]:setVisible(false)
        end
    end

    local function onCreate(params)
        local showGuild = lbl.createFontTTF(18, params.gname or guildName)
        showGuild:setAnchorPoint(ccp(0, 0))
        showGuild:setPosition(titleGuild:boundingBox():getMaxX() + 10, titleGuild:getPositionY())
        board:addChild(showGuild)

        local titleDefen = lbl.createMixFont3(18, i18n.global.tips_player_defen.string, ccc3(0xff, 0xf2, 0x98))
        titleDefen:setAnchorPoint(ccp(0, 0))
        titleDefen:setPosition(25, TIPS_HEIGHT - 161)
        board:addChild(titleDefen)

        local fgLine = img.createUI9Sprite(img.ui.hero_panel_fgline)
        fgLine:setOpacity(255 * 0.3)
        fgLine:setPreferredSize(CCSize(468, 2))
        fgLine:setPosition(TIPS_WIDTH/2, TIPS_HEIGHT - 168)
        board:addChild(fgLine)

        local showPower = lbl.createFont2(22, params.power or 0)
        showPower:setAnchorPoint(ccp(1, 0.5))
        showPower:setPosition(fgLine:boundingBox():getMaxX(), TIPS_HEIGHT - 146)
        board:addChild(showPower)

        local powerIcon = img.createUISprite(img.ui.power_icon)
        powerIcon:setScale(0.48)
        powerIcon:setAnchorPoint(ccp(1, 0.5))
        powerIcon:setPosition(showPower:boundingBox():getMinX() - 10, TIPS_HEIGHT - 148)
        board:addChild(powerIcon)

        local POSX = {
            [1] = 23, [2] = 98, [3] = 198, [4] = 273, [5] = 348, [6] = 423 
        }
        local hids = {}
        local pheroes = params.heroes or {}
        if pheroes then
            for i, v in ipairs(pheroes) do
                hids[v.pos] = v
            end
        end

        for i=1, 6 do
            local showHero
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
                    hid = nil,
                    hskills = hids[i].hskills,
                    skin = hids[i].skin
                }
                showHero = img.createHeroHeadByParam(param)
            else
                showHero = img.createUISprite(img.ui.herolist_head_bg)
            end
            showHero:setAnchorPoint(ccp(0, 0))
            showHero:setScale(0.75)
            showHero:setPosition(POSX[i], TIPS_HEIGHT - 252)
            board:addChild(showHero)
        end
    end

    -- for touch
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
        if not outside_remove and params.btn_count ~= nil and params.btn_count > 0 then
            return
        end
        print("toucheend")
        if isclick and not board:boundingBox():containsPoint(ccp(x, y)) then
            --if clickBlankHandler then
            --    clickBlankHandler()
            --else
                layer:removeFromParentAndCleanup(true)
            --end
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

    layer:registerScriptTouchHandler(onTouch, false , -128 , false)
    --layer:registerScriptTouchHandler(function() return true end)
    layer:setTouchEnabled(true)

    addBackEvent(layer)
    function layer.onAndroidBack()
        layer:removeFromParentAndCleanup(true)
    end
    local function onEnter()
        layer.notifyParentLock()
        local params = {
            sid = player.sid,
            uid = params.uid,
        }

        addWaitNet()
        if _csid >= 100 then
            params.svr_id = _csid
        end
        net:player(params, function(__data)
            delWaitNet()
            
            tbl2string(__data)
            onCreate(__data)
            if __data.report == 1 then
                setShader(btn[4], SHADER_GRAY, true)
                btn[4]:setEnabled(false)
            end
        end) 
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
 
    board:setScale(0.5*view.minScale)
    local anim_arr = CCArray:create()
    anim_arr:addObject(CCScaleTo:create(0.15, 1*view.minScale, 1*view.minScale))
    anim_arr:addObject(CCDelayTime:create(0.15))
    anim_arr:addObject(CCCallFunc:create(function()
    
    end))
    board:runAction(CCSequence:create(anim_arr))

    return layer
end

return tips
