local ui = {}

require "common.func"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local i18n = require "res.i18n"
local audio = require "res.audio"
local heros = require "data.heros"
local userdata = require "data.userdata"
local cfghero = require "config.hero"
local bag = require "data.bag"
local player = require "data.player"
local net = require "net.netClient"

local space_height = 1
local MAXSHADOW = 3
local MIXLIMIXTEAME = 10
local MAXLIMIXTEAME = 15

function createChangePos(curpos, teamnum, callback)
    local layer = CCLayer:create()

    local BG_WIDTH   = 448
    local BG_HEIGHT  = 322

    local bg = img.createUI9Sprite(img.ui.tips_bg)
    bg:setPreferredSize(CCSize(BG_WIDTH, BG_HEIGHT))
    bg:setScale(view.minScale * 0.1)
    bg:setAnchorPoint(ccp(0.5,0.5))
    bg:setPosition(scalep(960/2, 576/2+50))
    bg:runAction(CCEaseBackOut:create(CCScaleTo:create(0.3, view.minScale)))
    layer:addChild(bg)

    local titlelab = lbl.createFont1(20, i18n.global.guiidFight_number_sel.string, ccc3(0xff, 0xe3, 0x86))
    titlelab:setPosition(BG_WIDTH/2, 286)
    bg:addChild(titlelab)

    -- line
    local line = img.createUISprite(img.ui.help_line)
    line:setScaleX(405/line:getContentSize().width)
    line:setPosition(BG_WIDTH/2, 260)
    bg:addChild(line)

    local sx = 80
    local sy = 200
    local dx = 74
    local dy = 68
    for i=1,teamnum do
        local numbg = img.createLogin9Sprite(img.login.button_9_small_gold)
        numbg:setPreferredSize(CCSize(64, 56))
        local numlab = lbl.createFont1(16, i, ccc3(0x73, 0x3b, 0x05))
        numlab:setPosition(numbg:getContentSize().width/2, numbg:getContentSize().height/2)
        numbg:addChild(numlab)
        
        local numBtn = SpineMenuItem:create(json.ui.button, numbg)
        numBtn:setPosition(sx+((i-1)%5)*dx, sy - math.floor((i-1)/5)*dy)
        local nummenu = CCMenu:createWithItem(numBtn)
        nummenu:setPosition(0, 0)
        bg:addChild(nummenu)
        
        numBtn:registerScriptTapHandler(function()
            audio.play(audio.button)
            callback(curpos, i, true)
            layer:removeFromParentAndCleanup()
        end)
    end

    layer:setTouchEnabled(true)
    layer:setTouchSwallowEnabled(true)

    return layer
end

function ui.create(param, callBack)
    local layer = CCLayer:create()
    
    local param = param or {}

    local params = clone(param)
    local darkbg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    layer:addChild(darkbg)
    tbl2string(params)

    local BG_WIDTH = 930
    local BG_HEIGHT = 544
    local board = img.createLogin9Sprite(img.login.dialog)
    board:setPreferredSize(CCSize(BG_WIDTH, BG_HEIGHT))
    --board:setAnchorPoint(ccp(0.5, 0))
    board:setScale(view.minScale)
    board:setPosition(view.midX, view.midY)
    layer:addChild(board)

    local teamsUid = params.uids
    local shadowUid = params.mask

    -- 判断阵容设置是否改变
    local function judgeSet()
        if #teamsUid ~= #param.uids then
            return true
        end
        for i=1,#teamsUid do
            if teamsUid[i] ~= param.uids[i] then
                return true
            end
        end
        if #shadowUid ~= #param.mask then
            return true
        end
        for i=1,#shadowUid do
            if shadowUid[i] ~= param.mask[i] then
                return true
            end
        end
        return false
    end

    local function createCostDiamond(curlayer)
        local paramsc = {}
        paramsc.btn_count = 0
        paramsc.body = string.format(i18n.global.guildFight_save_tips.string)
        local board_w = 474

        local dialoglayer = require("ui.dialog").create(paramsc) 

        local btnYesSprite = img.createLogin9Sprite(img.login.button_9_small_gold)
        btnYesSprite:setPreferredSize(CCSize(153, 50))
        local btnYes = SpineMenuItem:create(json.ui.button, btnYesSprite)
        btnYes:setPosition(board_w/2+95, 100)
        local labYes = lbl.createFont1(18, i18n.global.board_confirm_yes.string, ccc3(0x73, 0x3b, 0x05))
        labYes:setPosition(btnYes:getContentSize().width/2, btnYes:getContentSize().height/2)
        btnYesSprite:addChild(labYes)
        local menuYes = CCMenu:create()
        menuYes:setPosition(0, 0)
        menuYes:addChild(btnYes)
        dialoglayer.board:addChild(menuYes)

        local btnNoSprite = img.createLogin9Sprite(img.login.button_9_small_gold)
        btnNoSprite:setPreferredSize(CCSize(153, 50))
        local btnNo = SpineMenuItem:create(json.ui.button, btnNoSprite)
        btnNo:setPosition(board_w/2-95, 100)
        local labNo = lbl.createFont1(18, i18n.global.board_confirm_no.string, ccc3(0x73, 0x3b, 0x05))
        labNo:setPosition(btnNo:getContentSize().width/2, btnNo:getContentSize().height/2)
        btnNoSprite:addChild(labNo)
        local menuNo = CCMenu:create()
        menuNo:setPosition(0, 0)
        menuNo:addChild(btnNo)
        dialoglayer.board:addChild(menuNo)

        
        btnYes:registerScriptTapHandler(function()
            dialoglayer:removeFromParentAndCleanup(true)
            curlayer:removeFromParentAndCleanup(true)
            audio.play(audio.button)
            local paramss = {
                sid = player.sid,
                uids = teamsUid,
                mask = shadowUid 
            }
            --tbl2string(teamsUid)
            --tbl2string(paramss)
            addWaitNet()
            net:guild_fight_lineup(paramss, function(__data)
                delWaitNet()
                tbl2string(__data)
                if __data.status ~= 0 then
                    if __data.status == -1 then
                        showToast(i18n.global.guildFight_mix_teams.string)
                    elseif __data.status == -2 then
                        showToast(i18n.global.guildFight_shadow_limit.string)
                    elseif __data.status == -4 then
                        showToast(i18n.global.guiidFight_toast_reg_end.string)
                    else
                        showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                    end
                    return
                end
                param = clone(params)
                callBack(params)
                showToast(i18n.global.guildFight_setting_ac.string)
            end)
        end)
        btnNo:registerScriptTapHandler(function()
            dialoglayer:removeFromParentAndCleanup(true)
            curlayer:removeFromParentAndCleanup(true)
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

    local btnCloseSprite = img.createUISprite(img.ui.close)
    local btnClose = SpineMenuItem:create(json.ui.button, btnCloseSprite)
    btnClose:setPosition(BG_WIDTH-25, BG_HEIGHT-25)
    local menuClose = CCMenu:createWithItem(btnClose)
    menuClose:setPosition(0, 0)
    board:addChild(menuClose)
    btnClose:registerScriptTapHandler(function()
        audio.play(audio.button)
        if judgeSet() == false or #params.uids < MIXLIMIXTEAME then
            layer:removeFromParentAndCleanup()
            return
        end
        layer:addChild(createCostDiamond(layer))
    end)

    local title = lbl.createFont1(26, i18n.global.arena3v3_btn_setting.string, ccc3(0xe6, 0xd0, 0xae))
    title:setPosition(BG_WIDTH/2, BG_HEIGHT-27)
    board:addChild(title, 1)

    local titleShade = lbl.createFont1(26, i18n.global.arena3v3_btn_setting.string, ccc3(0x59, 0x30, 0x1b))
    titleShade:setPosition(BG_WIDTH/2, BG_HEIGHT-29)
    board:addChild(titleShade)

    local heroCampBg = img.createUI9Sprite(img.ui.bag_btn_inner_bg)
    heroCampBg:setPreferredSize(CCSize(884, 452))
    heroCampBg:setPosition(BG_WIDTH/2, 265)
    board:addChild(heroCampBg)

    local selectTeamBg = img.createUI9Sprite(img.ui.select_tab_tab_bg)
    selectTeamBg:setPreferredSize(CCSize(840, 37))
    selectTeamBg:setPosition(442, 412)
    heroCampBg:addChild(selectTeamBg)

    local showPowerBg = img.createUISprite(img.ui.select_hero_power_bg)
    showPowerBg:setAnchorPoint(ccp(0, 0.5))
    showPowerBg:setPosition(0, 19)
    selectTeamBg:addChild(showPowerBg)

    local powerIcon = img.createUISprite(img.ui.team_icon)
    powerIcon:setPosition(27, 21)
    showPowerBg:addChild(powerIcon)

    local showteams = lbl.createFont2(20, string.format("%d/15", #params.uids), ccc3(255, 246, 223))
    showteams:setAnchorPoint(ccp(0, 0.5))
    showteams:setPosition(powerIcon:boundingBox():getMaxX() + 15, powerIcon:boundingBox():getMidY())
    showPowerBg:addChild(showteams)

    local btnSettingSprite = img.createLogin9Sprite(img.login.button_9_small_green)
    btnSettingSprite:setPreferredSize(CCSize(172, 44))
    local btnSettingLab = lbl.createFont1(16, i18n.global.guildFight_save_camp.string, ccc3(0x1b, 0x59, 0x02))
    btnSettingLab:setPosition(btnSettingSprite:getContentSize().width/2, btnSettingSprite:getContentSize().height/2)
    btnSettingSprite:addChild(btnSettingLab)

    local btnSetting = SpineMenuItem:create(json.ui.button, btnSettingSprite)
    btnSetting:setPosition(840-86, 19)
    local menuSetting = CCMenu:createWithItem(btnSetting)
    menuSetting:setPosition(0, 0)
    selectTeamBg:addChild(menuSetting, 1)

    local scrolloffsety = 0
    local teamslayer = nil
    local createteamlayer = nil

    btnSetting:registerScriptTapHandler(function()
        audio.play(audio.button)
        if #teamsUid < MIXLIMIXTEAME then
            showToast(i18n.global.guildFight_mix_teams.string)
            return
        end
        local paramss = {
            sid = player.sid,
            uids = teamsUid,
            mask = shadowUid 
        }
        --tbl2string(paramss)
        addWaitNet()
        net:guild_fight_lineup(paramss, function(__data)
            delWaitNet()
            tbl2string(__data)
            if __data.status ~= 0 then
                if __data.status == -1 then
                    showToast(i18n.global.guildFight_mix_teams.string)
                elseif __data.status == -2 then
                    showToast(i18n.global.guildFight_shadow_limit.string)
                elseif __data.status == -4 then
                    showToast(i18n.global.guiidFight_toast_reg_end.string)
                else
                    showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                end
                return
            end
            param = clone(params)
            callBack(params)
            showToast(i18n.global.guildFight_setting_ac.string)
        end)
        
    end)

    local function changepos(i, pos, setflag)
        if pos ~= i then
            if i == 0 then
                table.insert(params.mbrs, params.mbrs[pos])
                table.remove(params.mbrs, pos)
            else
                params.mbrs[i], params.mbrs[pos] = params.mbrs[pos], params.mbrs[i] 
            end
            if setflag then
                local aUidpos
                local bUidpos
                for j = 1,#teamsUid do
                    if params.mbrs[i].uid == teamsUid[j] then 
                        aUidpos = j 
                    end
                    if params.mbrs[pos].uid == teamsUid[j] then 
                        bUidpos = j 
                    end
                end
                teamsUid[aUidpos], teamsUid[bUidpos] = teamsUid[bUidpos], teamsUid[aUidpos] 
            end
        end
        if teamslayer then
            scrolloffsety = board.scroll:getContentOffset().y
            teamslayer:removeFromParentAndCleanup()
            teamslayer = nil
            teamslayer = createteamlayer()
            board:addChild(teamslayer)
        end
    end

    local function createItem(teamObj, _idx)
        local item = img.createUI9Sprite(img.ui.botton_fram_2)
        item:setPreferredSize(CCSizeMake(836, 100))
        local item_w = item:getContentSize().width
        local item_h = item:getContentSize().height

        if _idx <= #teamsUid then
            local numlab = lbl.createFont1(16, _idx, ccc3(0x51, 0x27, 0x12))
            numlab:setPosition(40-3, item_h/2)
            item:addChild(numlab)
        end

        local namelab = lbl.createFontTTF(16, teamObj.name, ccc3(0x51, 0x27, 0x12))
        namelab:setAnchorPoint(0, 0.5)
        namelab:setPosition(75-5-3, 68)
        item:addChild(namelab)
        local showPowerBg = img.createUI9Sprite(img.ui.arena_frame7)
        showPowerBg:setPreferredSize(CCSize(140, 28))
        showPowerBg:setAnchorPoint(ccp(0, 0.5))
        showPowerBg:setPosition(75-3, 36+2)
        item:addChild(showPowerBg)
        local showPowerIcon = img.createUISprite(img.ui.power_icon)
        showPowerIcon:setScale(0.5)
        showPowerIcon:setPosition(10, showPowerBg:getContentSize().height/2)
        showPowerBg:addChild(showPowerIcon)

        local showPower = lbl.createFont2(16, teamObj.power)
        showPower:setPosition(showPowerBg:getContentSize().width/2, showPower:getContentSize().height/2 - 4)
        showPowerBg:addChild(showPower)

        local POSX = {
            [1] = 265, [2] = 326, [3] = 400, [4] = 462, [5] = 524, [6] = 586 
        }

        for i=1, 6 do
            local showHero
            if teamObj.camp[i] and teamObj.camp[i].pos ~= 7 then
                --showHero = img.createHeroHead(teamObj.camp[i].id, teamObj.camp[i].lv, true, true, teamObj.camp[i].wake,nil,require("data.pet").getPetID(teamObj.camp))
                local param = {
                    id = teamObj.camp[i].id,
                    lv = teamObj.camp[i].lv,
                    showGroup = true,
                    showStar = true,
                    wake = teamObj.camp[i].wake,
                    orangeFx = nil,
                    petID = require("data.pet").getPetID(teamObj.camp),
                    hskills = teamObj.camp[i].hskills,
                    skin = teamObj.camp[i].skin,
                }
                showHero = img.createHeroHeadByParam(param)
                showHero:setScale(0.6)
            else
                showHero = img.createUI9Sprite(img.ui.herolist_withouthero_bg)
                showHero:setPreferredSize(CCSize(59, 59))
            end
            showHero:setPosition(POSX[i]-3, item:getContentSize().height/2)
            item:addChild(showHero)
        end
        local open = true
        for ii=1,#shadowUid do
            if shadowUid[ii] == teamObj.uid then
                open = false
                break
            end
        end
        local shadowbg = img.createLogin9Sprite(img.login.button_9_small_gold)
        shadowbg:setPreferredSize(CCSize(54, 52))
        local openshadow = img.createUISprite(img.ui.guildFight_eye_open)
        openshadow:setPosition(shadowbg:getContentSize().width/2, shadowbg:getContentSize().height/2)
        openshadow:setVisible(open == true)
        shadowbg:addChild(openshadow)
        local closeshadow = img.createUISprite(img.ui.guildFight_eye_close)
        closeshadow:setPosition(shadowbg:getContentSize().width/2, shadowbg:getContentSize().height/2)
        closeshadow:setVisible(open ~= true)
        shadowbg:addChild(closeshadow)
        local shadowBtn = SpineMenuItem:create(json.ui.button, shadowbg)
        shadowBtn:setPosition(662-3, item:getContentSize().height/2+2)
        if _idx > #teamsUid then
            shadowBtn:setVisible(false)
            --shadowBtn:setEnabled(false)    
            --setShader(shadowBtn, SHADER_GRAY, true)
        end
        local shadowmenu = CCMenu:createWithItem(shadowBtn)
        shadowmenu:setPosition(0, 0)
        item:addChild(shadowmenu)

        local exchangebg = img.createLogin9Sprite(img.login.button_9_small_gold)
        exchangebg:setPreferredSize(CCSize(54, 52))
        local exchange = img.createUISprite(img.ui.arena_new_switch)
        exchange:setScale(0.95)
        exchange:setPosition(exchangebg:getContentSize().width/2, exchangebg:getContentSize().height/2)
        exchangebg:addChild(exchange)
        local exchangeBtn = SpineMenuItem:create(json.ui.button, exchangebg)
        exchangeBtn:setPosition(726-3, item:getContentSize().height/2+2)
        if _idx > #teamsUid then
            exchangeBtn:setVisible(false)
            --exchangeBtn:setEnabled(false)    
            --setShader(exchangeBtn, SHADER_GRAY, true)
        end
        local exchangemenu = CCMenu:createWithItem(exchangeBtn)
        exchangemenu:setPosition(0, 0)
        item:addChild(exchangemenu)

        local selectteam = false
        for ii=1,#teamsUid do
            if teamsUid[ii] == teamObj.uid then
                selectteam = true
                break
            end
        end

        local tickbg = img.createUISprite(img.ui.guildFight_tick_bg)
        local tick = img.createUISprite(img.ui.hook_btn_sel)
        tick:setScale(0.75)
        tick:setPosition(tickbg:getContentSize().width/2+5, tickbg:getContentSize().height/2+3)
        tickbg:addChild(tick)
        tick:setVisible(selectteam)
        local tickBtn = SpineMenuItem:create(json.ui.button, tickbg)
        tickBtn:setPosition(794-5, item:getContentSize().height/2+3)
        local tickmenu = CCMenu:createWithItem(tickBtn)
        tickmenu:setPosition(0, 0)
        item:addChild(tickmenu)

        shadowBtn:registerScriptTapHandler(function()
            audio.play(audio.button)
            if open == true then
                if #shadowUid >= MAXSHADOW then
                    showToast(i18n.global.guildFight_shadow_limit.string)
                    return 
                end
                openshadow:setVisible(false)
                closeshadow:setVisible(true)
                open = false
                showToast(i18n.global.guildFight_shadow_camp.string)
                shadowUid[#shadowUid+1] = teamObj.uid
            else
                openshadow:setVisible(true)
                closeshadow:setVisible(false)
                open = true
                for i=1,#shadowUid do
                    if shadowUid[i] == teamObj.uid then
                        table.remove(shadowUid, i)
                        break
                    end
                end
                showToast(i18n.global.guildFight_show_camp.string)
            end
        end)

        exchangeBtn:registerScriptTapHandler(function()
            audio.play(audio.button)
            layer:addChild(createChangePos(_idx, #teamsUid, changepos))
        end)

        tickBtn:registerScriptTapHandler(function()
            audio.play(audio.button)
            if selectteam == false then
                if #teamsUid >= MAXLIMIXTEAME then
                    showToast(i18n.global.guildFight_max_teams.string)
                    return 
                end
                tick:setVisible(true)
                selectteam = true
                teamsUid[#teamsUid+1] = teamObj.uid
                showteams:setString(string.format("%d/15", #teamsUid))
                changepos(#teamsUid, _idx)
            else
                tick:setVisible(false)
                selectteam = false
                for i=1,#teamsUid do
                    if teamsUid[i] == teamObj.uid then
                        table.remove(teamsUid, i)
                        break
                    end
                end
                for i=1,#shadowUid do
                    if shadowUid[i] == teamObj.uid then
                        table.remove(shadowUid, i)
                        break
                    end
                end
                changepos(0, _idx)
                showteams:setString(string.format("%d/15", #teamsUid))
            end
        end)
        return item
    end

    local function createScroll()
        local scroll_params = {
            width = 836,
            height = 365,
        }
        local lineScroll = require "ui.lineScroll"
        return lineScroll.create(scroll_params)
    end

    function createteamlayer(begin)
        local tlayer = CCLayer:create()
        local scroll = createScroll()
        scroll:setAnchorPoint(CCPoint(0, 0))
        scroll:setPosition(CCPoint(48, 55))
        tlayer:addChild(scroll)
        board.scroll = scroll
        --drawBoundingbox(board, scroll)
        scroll.addSpace(4)
        for ii=1,#params.mbrs do
            local tmp_item = createItem(params.mbrs[ii], ii)
            tmp_item.guildObj = params.mbrs[ii]
            tmp_item.ax = 0.5
            tmp_item.px = 836/2
            scroll.addItem(tmp_item)
            if ii ~= #params.mbrs then
                scroll.addSpace(space_height)
            end
        end
        if begin then
            scroll:setOffsetBegin()
        else
            scroll:setContentOffset(CCPoint(0, scrolloffsety))
        end
      
        return tlayer
    end
    teamslayer = createteamlayer(true)
    board:addChild(teamslayer)
    
    layer:setTouchEnabled(true)
    layer:setTouchSwallowEnabled(true)

    return layer
end

return ui
