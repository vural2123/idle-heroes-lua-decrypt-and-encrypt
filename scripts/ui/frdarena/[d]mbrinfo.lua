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
local frdarena = require "data.frdarena"

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
    [2] = { 414, 258, 102},
    [3] = { 100, 262, 424 },
}

local COLOR2TYPE = {
    [1] = img.login.button_9_small_orange,
    [2] = img.login.button_9_small_gold,
}

function tips.create(params, way, callBack)  --way默认表示离开队伍  way:"quit" 表示退出队伍 way:"clear"踢出队伍 way:"owner"转让队长  
    local layer = CCLayer:create()

    local guildName = params.gname or ""
    local board = img.createUI9Sprite(img.ui.tips_bg)
    board:setPreferredSize(CCSize(TIPS_WIDTH, TIPS_HEIGHT))
    board:setScale(view.minScale)
    board:setPosition(view.midX, view.midY)
    layer:addChild(board)
    layer.board = board

    local btnCloseSprite = img.createUISprite(img.ui.close)
    local btnClose = SpineMenuItem:create(json.ui.button, btnCloseSprite)
    btnClose:setPosition(492, TIPS_HEIGHT - 28)
    local menuClose = CCMenu:createWithItem(btnClose)
    menuClose:setPosition(0, 0)
    board:addChild(menuClose)
    btnClose:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer:removeFromParentAndCleanup(true)
    end)

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
        deletparams.body = string.format(i18n.global.frdpvp_team_isquit.string, 20)

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
            param.type = 3
            param.teamid = params.teamid
            addWaitNet()
            net:gpvp_mbrop(param, function(__data)
                delWaitNet()
                tbl2string(__data)
                if __data.status ~= 0 then
                    showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                    return
                end
                frdarena.setdissmiss()
                layer:removeFromParentAndCleanup(true)
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

        dialoglayer:registerScriptHandler(function(event) 
            if event == "enter" then 
                onEnter()
            elseif event == "exit" then
                onExit()
            end
        end)
        return dialoglayer
    end

    local function createTransfer()
        local deletparams = {}
        deletparams.btn_count = 0
        deletparams.body = string.format(i18n.global.frdpvp_team_istransfer.string, 20)

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
            param.type = 5
            param.uid = params.uid
            addWaitNet()
            net:gpvp_leaderop(param, function(__data)
                delWaitNet()
                tbl2string(__data)
                if __data.status == -2 then
                    showToast(i18n.global.frdpvp_team_playerleave.string) 
                    return 
                end
                if __data.status ~= 0 then
                    showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                    return
                end
                frdarena.setLeader(params.uid)
                if callBack then
                    callBack()
                end
                layer:removeFromParentAndCleanup(true)
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

        dialoglayer:registerScriptHandler(function(event) 
            if event == "enter" then 
                onEnter()
            elseif event == "exit" then
                onExit()
            end
        end)
        return dialoglayer
    end

    if way == "clear" then
        wayText = i18n.global.frdpvp_team_kick.string
    elseif way == "quit" then
        wayText = i18n.global.frdpvp_team_quick.string
    elseif way == "owner" then
        wayText = i18n.global.frdpvp_team_transfer.string
    else
        wayText = "none"
    end
    local btnConfig = {
        [1] = { text = wayText, Color = 1 },
        [2] = { text = i18n.global.frdpvp_team_transfer.string, Color = 2 },
    }

    btnConfig[1].handler = function() 
        audio.play(audio.button)
        if way == "quit" then
            local dialog = createdelete()
            layer:addChild(dialog, 300)
        elseif way == "owner" then
            local dialog = createTransfer()
            layer:addChild(dialog, 300)
        else
            local param = {}
            param.sid = player.sid
            param.type = 3
            param.uid = params.uid
            addWaitNet()
            net:gpvp_leaderop(param, function(__data)
                delWaitNet()
                tbl2string(__data)
                if __data.status == -2 then
                    showToast(i18n.global.frdpvp_team_playerleave.string) 
                    return 
                end
                if __data.status ~= 0 then
                    showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                    return
                end
                frdarena.delTeammate(params)
                layer:removeFromParentAndCleanup(true)
            end)
        end
    end

    btnConfig[2].handler = function() 
        audio.play(audio.button)
        local dialog = createTransfer()
        layer:addChild(dialog, 300)
    end

    for i, v in ipairs(btnConfig) do
        local btnSp = img.createLogin9Sprite(COLOR2TYPE[v.Color])
        btnSp:setPreferredSize(CCSize(148, 46))
        local btn = SpineMenuItem:create(json.ui.button, btnSp)
        btn:setPosition(BUTTON_POSX[2][i], TIPS_HEIGHT - 296)
        local menu = CCMenu:createWithItem(btn)
        menu:setPosition(0, 0)
        board:addChild(menu)
        local label = nil
        label = lbl.createFont1(18, v.text or "", ccc3(0x73, 0x3b, 0x05))
        label:setPosition(btnSp:getContentSize().width/2, btnSp:getContentSize().height/2)
        btnSp:addChild(label)

        if v.handler then
            btn:registerScriptTapHandler(function() 
                audio.play(audio.button)
                v.handler()
            end)
        end

        if wayText == "none" then
            btn:setVisible(false)
        end

        if i==2 and way ~= "clear" then
            btn:setVisible(false) 
        end
    end

    local function onCreate(params)
        local showGuild = lbl.createFontTTF(18, params.mbr.gname or guildName)
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

        local showPower = lbl.createFont2(22, params.mbr.power or 0)
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
        local pheroes = params.mbr.camp or {}
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

    layer:registerScriptTouchHandler(function() return true end)
    layer:setTouchEnabled(true)

    local function onEnter()
        local params = {
            sid = player.sid,
            uid = params.uid,
        }

        addWaitNet()
        net:gpvp_mbr(params, function(__data)
            delWaitNet()
            
            tbl2string(__data)
            onCreate(__data)
        end) 
    end

    local function onExit()

    end

    layer:registerScriptHandler(function(event)
        if event == "enter" then
            onEnter()
        elseif event == "exit" then

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
