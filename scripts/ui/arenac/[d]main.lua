local ui = {}

require "common.func"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local i18n = require "res.i18n"
local audio = require "res.audio"
local net = require "net.netClient"
local cfghero = require "config.hero"
local cfgequip = require "config.equip"
local heros = require "data.heros"
local bag = require "data.bag"
local player = require "data.player"
local frdarena = require "data.arenac"
local databag = require "data.bag"

local arenac_id = 28

function ui.create(uiParams)
    local layer = CCLayer:create()

    json.load(json.ui.frd_jjc)
    local board = DHSkeletonAnimation:createWithKey(json.ui.frd_jjc)
    board:scheduleUpdateLua()
    board:setPosition(view.midX, view.midY)
    board:setScale(view.minScale)
    layer:addChild(board)

    local bg1 = CCLayer:create()
    board:addChildFollowSlot("code_bg1", bg1)

    local bg2 = CCLayer:create()
    board:addChildFollowSlot("code_bg2", bg2)

    -- backBtn
    local btnBackSprite = img.createUISprite(img.ui.back)
    local btnBack = SpineMenuItem:create(json.ui.button, btnBackSprite)
    btnBack:setPosition(-136, 546)
    local menuBack = CCMenu:createWithItem(btnBack)
    menuBack:setPosition(0, 0)
    bg1:addChild(menuBack)
    btnBack:registerScriptTapHandler(function()
        audio.play(audio.button)
        replaceScene(require("ui.town.main").create())  
    end)

    local btnInfoSprite = img.createUISprite(img.ui.btn_help)
    local btnInfo = SpineMenuItem:create(json.ui.button, btnInfoSprite)
    btnInfo:setPosition(603-162, 546)
    local menuInfo = CCMenu:createWithItem(btnInfo)
    menuInfo:setPosition(0, 0)
    bg1:addChild(menuInfo, 1)
    btnInfo:registerScriptTapHandler(function()
        audio.play(audio.button)
        local str = i18n.arena[arenac_id].infoTitle1 .. ":::" .. string.gsub(i18n.arena[arenac_id].info1, ";", "|||")
        str = str .. "###" .. i18n.arena[arenac_id].infoTitle2 .. ":::" .. string.gsub(i18n.arena[arenac_id].info2, ";", "|||")
        layer:addChild(require("ui.help").create(str, i18n.global.help_title.string), 1000)
    end)

    autoLayoutShift(btnBack, true, false, true, false)
    autoLayoutShift(btnInfo, true, false, false, false)

    local showTitle = lbl.createFont3(22, i18n.arena[arenac_id].name)
    showTitle:setPosition(289 + 16 - 167, 478)
    bg1:addChild(showTitle)

    local showLeftTitle = lbl.createFont3(18, i18n.global.arena_remain_title.string, ccc3(0xff, 0xcd, 0x33))
    showLeftTitle:setPosition(289 + 16 - 167, 451)
    bg1:addChild(showLeftTitle)

    local showTime = lbl.createFont2(16, "")
    showTime:setPosition(289 + 16 - 167, 430)
    bg1:addChild(showTime)

    local function createFrdpvp1()
        local bg2layer = CCLayer:create()
        board:playAnimation("start1")
        board:appendNextAnimation("loop1", -1)

        local btnBattleSprite = img.createLogin9Sprite(img.login.button_9_gold)
        btnBattleSprite:setPreferredSize(CCSize(196, 62))
        local labBattle = lbl.createFont1(18, i18n.global.frdpvp_team_lobby.string, ccc3(0x73, 0x3b, 0x05))
        labBattle:setPosition(btnBattleSprite:getContentSize().width/2, btnBattleSprite:getContentSize().height/2-1)
        btnBattleSprite:addChild(labBattle)

        local btnBattle = SpineMenuItem:create(json.ui.button, btnBattleSprite)
        local menuBattle = CCMenu:createWithItem(btnBattle)
        btnBattle:setPosition(787, 198)
        menuBattle:setPosition(0, 0)
        bg2layer:addChild(menuBattle)
        

        btnBattle:registerScriptTapHandler(function()
            audio.play(audio.button)
            --layer:addChild(require("ui.arena.pickRival").create())
            board:playAnimation("click")
            local ban = CCLayer:create()
            ban:setTouchEnabled(true)
            ban:setTouchSwallowEnabled(true)
            layer:addChild(ban, 1000)
            schedule(layer, 1, function()
                if frdarena.team == nil then
                    layer:addChild(require("ui.arenac.teammain").create())
                else
                    layer:addChild(require("ui.arenac.teaminfo").create())
                end
                board:appendNextAnimation("loop1", -1)
                ban:removeFromParent()
            end)
        end)

        bg2layer:scheduleUpdateWithPriorityLua(function()
            if frdarena.team and frdarena.team.reg and frdarena.team.reg == true then
                replaceScene(require("ui.arenac.main").create())
            end
        end)

        return bg2layer
    end

    local function createFrdpvp2()
        local bg2layer = CCLayer:create()
        board:playAnimation("start2")
        board:appendNextAnimation("loop2", -1)

        local teamtitleBg = img.createUISprite(img.ui.friend_pvp_biaotidiban)
        teamtitleBg:setPosition(787, 520)
        bg2layer:addChild(teamtitleBg)
        
        local showTeamTitle = lbl.createMixFont1(18, frdarena.team.name, ccc3(0xff, 0xf4, 0x93))
        showTeamTitle:setPosition(teamtitleBg:getContentSize().width/2, teamtitleBg:getContentSize().height/2)
        teamtitleBg:addChild(showTeamTitle, 1)

        local lidIcon = img.createUISprite(img.ui.friend_pvp_maoding)
        lidIcon:setPosition(787-92, 478)
        bg2layer:addChild(lidIcon)

        local ridIcon = img.createUISprite(img.ui.friend_pvp_maoding)
        ridIcon:setPosition(787+92, 478)
        bg2layer:addChild(ridIcon)

        local showTeamId = lbl.createFont2(16, string.format("ID %d", frdarena.team.id))
        showTeamId:setPosition(787, 478)
        bg2layer:addChild(showTeamId, 1)

        local teaminfoBg = img.createUI9Sprite(img.ui.friend_pvp_teaminfo)
        teaminfoBg:setPreferredSize(CCSize(252, 200))
        teaminfoBg:setAnchorPoint(0.5, 0)
        teaminfoBg:setPosition(787, 255)
        bg2layer:addChild(teaminfoBg)

        local powerIcon = img.createUISprite(img.ui.power_icon)
        powerIcon:setScale(0.48)
        powerIcon:setAnchorPoint(ccp(0, 0.5))
        powerIcon:setPosition(787-105, 424)
        bg2layer:addChild(powerIcon)
        local showPower = lbl.createFont2(18, frdarena.team.power)
        showPower:setAnchorPoint(ccp(0, 0.5))
        showPower:setPosition(787-70, 424)
        bg2layer:addChild(showPower)

        -- btn_setting
        --[[local btn_setting0 = img.createUISprite(img.ui.guild_icon_admin)
        local btn_setting = SpineMenuItem:create(json.ui.button, btn_setting0)
        btn_setting:setPosition(CCPoint(787+89,415))
        local btn_setting_menu = CCMenu:createWithItem(btn_setting)
        btn_setting_menu:setPosition(CCPoint(0, 0))
        bg2layer:addChild(btn_setting_menu)
        btn_setting:registerScriptTapHandler(function()
            audio.play(audio.button)
            layer:addChild((require"ui.frdarena.setteamline").create(), 1000)
        end)--]]

        --[[local rankLbl = lbl.createFont1(16, i18n.global.arena_main_rank.string, ccc3(0xff, 0xf4, 0x93))
        rankLbl:setAnchorPoint(ccp(0, 0.5))
        rankLbl:setPosition(787-105, 390)
        bg2layer:addChild(rankLbl)
        
        local ranknum = lbl.createFont2(16, frdarena.team.rank)
        ranknum:setAnchorPoint(ccp(0, 0.5))
        ranknum:setPosition(rankLbl:boundingBox():getMaxX()+15, 390)
        bg2layer:addChild(ranknum)

        local scoreLbl = lbl.createFont1(16, i18n.global.arena_main_score_Big.string, ccc3(0xff, 0xf4, 0x93))
        scoreLbl:setAnchorPoint(ccp(0, 0.5))
        scoreLbl:setPosition(787-105, 390-26)
        bg2layer:addChild(scoreLbl)
        
        local scorenum = lbl.createFont2(16, frdarena.team.score)
        scorenum:setAnchorPoint(ccp(0, 0.5))
        scorenum:setPosition(scoreLbl:boundingBox():getMaxX()+15, 390-26)
        bg2layer:addChild(scorenum)--]]

        local teamIcon = {}
        local showHead = {}

        local function callfuncOwner()
            for i = 1,3 do
                if frdarena.team.mbrs[i].uid ~= frdarena.team.leader then
                    teamIcon[i]:setVisible(false)
                else
                    teamIcon[i]:setVisible(true)
                end
            end
        end

        local dx
        for i = 1,3 do
            showHead[i] = img.createPlayerHeadForArena(frdarena.team.mbrs[i].logo, frdarena.team.mbrs[i].lv)
            teamIcon[i] = img.createUISprite(img.ui.friend_pvp_captain)
            teamIcon[i]:setAnchorPoint(0, 1)
            teamIcon[i]:setPosition(0, showHead[i]:getContentSize().height)
            showHead[i]:addChild(teamIcon[i])
            if frdarena.team.mbrs[i].uid ~= frdarena.team.leader then
                teamIcon[i]:setVisible(false)
            end
            local headBtn = SpineMenuItem:create(json.ui.button, showHead[i])
            headBtn:setScale(0.8)
            headBtn:setPosition(787+74*(i-2), 306)
            local headMenu = CCMenu:createWithItem(headBtn)
            headMenu:setPosition(0, 0)
            bg2layer:addChild(headMenu)

            headBtn:registerScriptTapHandler(function()
                audio.play(audio.button)
                if player.uid == frdarena.team.leader then
                    if player.uid == frdarena.team.mbrs[i].uid then
                        layer:addChild((require"ui.arenac.mbrinfo").create(frdarena.team.mbrs[i], "none"), 100)
                    else
                        layer:addChild((require"ui.arenac.mbrinfo").create(frdarena.team.mbrs[i], "owner", callfuncOwner), 100)
                    end
                else
                    layer:addChild((require"ui.arenac.mbrinfo").create(frdarena.team.mbrs[i], "none"), 100)
                end
            end)
        end

        local btnBattleSprite = img.createLogin9Sprite(img.login.button_9_gold)
        btnBattleSprite:setPreferredSize(CCSize(172, 70))
        local labBattle = lbl.createFont1(18, i18n.global.arena_main_battle.string, ccc3(0x73, 0x3b, 0x05))
        labBattle:setPosition(btnBattleSprite:getContentSize().width/2, btnBattleSprite:getContentSize().height/2-1)
        btnBattleSprite:addChild(labBattle)

        local btnBattle = SpineMenuItem:create(json.ui.button, btnBattleSprite)
        local menuBattle = CCMenu:createWithItem(btnBattle)
        btnBattle:setPosition(787, 202)
        menuBattle:setPosition(0, 0)
        bg2layer:addChild(menuBattle)
        
        btnBattle:registerScriptTapHandler(function()
            audio.play(audio.button)
            if frdarena.team.leader ~= player.uid then
                showToast(i18n.global.frdpvp_permission_denied.string)
                return
            end
            layer:addChild(require("ui.arenac.selecfight").create())
        end)
        return bg2layer
    end

    local rightLayer = nil
    if frdarena.team and frdarena.team.reg and frdarena.team.reg == true then 
        rightLayer = createFrdpvp2()
    else
        rightLayer = createFrdpvp1()
    end
    bg2:addChild(rightLayer)

    --[[local btnRewardSprite = img.createUISprite(img.ui.arena_reward_icon)
    local btnReward = SpineMenuItem:create(json.ui.button, btnRewardSprite)
    local menuReward = CCMenu:createWithItem(btnReward)
    btnReward:setPosition(687, 42)
    menuReward:setPosition(0, 0)
    bg2:addChild(menuReward)
    btnReward:registerScriptTapHandler(function()
        audio.play(audio.button)
        --if frdarena.team == nil then
        --    showToast(i18n.global.frdpvp_team_nosubmit.string) 
        --    return
        --end
        layer:addChild(require("ui.frdarena.rewards").create())
    end)

    local showRewardTab = lbl.createFont2(14, i18n.global.arena_main_reward.string)
    showRewardTab:setPosition(btnReward:boundingBox():getMidX(), btnReward:boundingBox():getMinY() + 8)
    bg2:addChild(showRewardTab)

    local btnRecordSprite = img.createUISprite(img.ui.arena_record_icon)
    local btnRecord = SpineMenuItem:create(json.ui.button, btnRecordSprite)
    local menuRecord = CCMenu:createWithItem(btnRecord)
    btnRecord:setPosition(786, 40)
    menuRecord:setPosition(0, 0)
    bg2:addChild(menuRecord)
    btnRecord:registerScriptTapHandler(function()
        audio.play(audio.button)

        if frdarena.team == nil then
            showToast(i18n.global.frdpvp_team_nosubmit.string) 
            return
        end
        --local params = {
        --    sid = player.sid,
        --    vid = vid,
        --}
        --net:gpvp_video(params, function(__data)
        --    tbl2string(__data)
            layer:addChild(require("ui.frdarena.records").create())
        --end)
    end)

    if uiParams and uiParams.video then
        layer:addChild(require("ui.frdarena.records").create(uiParams.video))
    end

    local showRecordTab = lbl.createFont2(14, i18n.global.arena_main_record.string)
    showRecordTab:setPosition(btnRecord:boundingBox():getMidX() - 3, btnRecord:boundingBox():getMinY() + 8)
    bg2:addChild(showRecordTab)

    local btnDefenSprite = img.createUISprite(img.ui.arena_defen_icon)
    local btnDefen = SpineMenuItem:create(json.ui.button, btnDefenSprite)
    local menuDefen = CCMenu:createWithItem(btnDefen)
    btnDefen:setPosition(884, 40)
    menuDefen:setPosition(0, 0)
    bg2:addChild(menuDefen)
    btnDefen:registerScriptTapHandler(function()
        audio.play(audio.button)
        --layer:addChild(require("ui.frdarena.setteamline").create())
        layer:addChild(require("ui.selecthero.main").create({type = "FrdArena"})) 
    end)

    local showDefenTab = lbl.createFont2(14, i18n.global.arena_main_defen.string)
    showDefenTab:setPosition(btnDefen:boundingBox():getMidX(), btnDefen:boundingBox():getMinY() + 8)
    bg2:addChild(showDefenTab)--]]

    layer:scheduleUpdateWithPriorityLua(function()
        if (frdarena.season_cd - os.time()) > 86400 * 3 then
            showTime:setString(math.floor((frdarena.season_cd - os.time())/86400) .. " " .. i18n.global.arena_time_day.string)
        else
            showTime:setString(time2string(frdarena.season_cd - os.time()))
        end

        if frdarena.season_cd <= os.time() then
            replaceScene(require("ui.town.main").create())
        end
    end)

    local scroll = CCScrollView:create()
    scroll:setDirection(kCCScrollViewDirectionVertical)
    scroll:setAnchorPoint(ccp(0, 0))
    scroll:setPosition(36-167, 22)
    scroll:setViewSize(CCSize(539, 382))
    scroll:setContentSize(CCSize(539, 0))
    bg1:addChild(scroll)

    local playerBg = {}

    local function loadRank(ranks)
        local height = 89 * #ranks + 3
        scroll:getContainer():removeAllChildrenWithCleanup(true)
        scroll:setContentSize(CCSize(539, height))
        scroll:setContentOffset(ccp(0, 382 - height))

        playerBg = {}
        local IMG = { img.ui.arena_frame1, img.ui.arena_frame3, img.ui.arena_frame5 }
        for i, v in ipairs(ranks) do
            --local showRank
            local showPowerBg
            if i < 4 then
                playerBg[i] = img.createUI9Sprite(IMG[i])
                --showRank = img.createUISprite(img.ui["arena_rank_" .. i])
                showPowerBg = img.createUI9Sprite(img.ui["arena_frame" .. (i * 2)])
            else
                playerBg[i] = img.createUI9Sprite(img.ui.botton_fram_2)
                --showRank = lbl.createFont1(20, i, ccc3(0x82, 0x5a, 0x3d))
                showPowerBg = img.createUI9Sprite(img.ui.arena_frame7)
            end
            playerBg[i]:setPreferredSize(CCSize(541, 88))
            playerBg[i]:setAnchorPoint(ccp(0, 0))
            playerBg[i]:setPosition(0, height - 87 * i - 3)
            scroll:getContainer():addChild(playerBg[i])
       
            --showRank:setPosition(40, playerBg[i]:getContentSize().height/2+1)
            --playerBg[i]:addChild(showRank)

            for j=1,#v.mbrs do
                local playerHead = img.createPlayerHead(v.mbrs[j].logo, v.mbrs[j].lv)
                playerHead:setScale(0.66)
                playerHead:setPosition(98+(j-1)*60, playerBg[i]:getContentSize().height/2+1)
                playerBg[i]:addChild(playerHead)
            end

            local showName = lbl.createFontTTF(16, v.name, ccc3(0x51, 0x27, 0x12))
            showName:setAnchorPoint(ccp(0, 0))
            showName:setPosition(257, 49)
            playerBg[i]:addChild(showName)
    
            showPowerBg:setPreferredSize(CCSize(130, 28))
            showPowerBg:setAnchorPoint(ccp(0, 0))
            showPowerBg:setPosition(259, 18)
            playerBg[i]:addChild(showPowerBg)
          
            local showPowerIcon = img.createUISprite(img.ui.power_icon)
            showPowerIcon:setScale(0.45)
            showPowerIcon:setPosition(270, 33)
            playerBg[i]:addChild(showPowerIcon)
 
            local showPower = lbl.createFont2(16, v.power)
            showPower:setAnchorPoint(ccp(0, 0))
            showPower:setPosition(300, 22)
            playerBg[i]:addChild(showPower)

            -- server
            --[[local sevbg = img.createUISprite(img.ui.anrea_server_bg)
            sevbg:setScale(0.78)
            sevbg:setPosition(430, 47)
            playerBg[i]:addChild(sevbg)
            local sevlab = lbl.createFont1(18, getSidname(v.sid), ccc3(0xf7, 0xea, 0xd1))
            sevlab:setPosition(sevbg:getContentSize().width/2, sevbg:getContentSize().height/2)
            sevbg:addChild(sevlab)--]]

            --[[local titleScore = lbl.createFont1(14, i18n.global.arena_main_score.string, ccc3(0x9a, 0x6a, 0x52))
            titleScore:setPosition(490, 54)
            playerBg[i]:addChild(titleScore)
 
            local showScore = lbl.createFont1(22, v.score, ccc3(0xa4, 0x2f, 0x28))
            showScore:setPosition(490, 35)
            playerBg[i]:addChild(showScore)--]]
        end
    end

    local function pullRank()
        if not frdarena.teams then
            local params = {
                sid = player.sid + 256,
            }
             
            addWaitNet()
            net:gpvp_ranklist(params, function(__data)
                delWaitNet()

                tbl2string(__data)
                if __data.status < 0 then
                    showToast("status:" .. __data.status)
                    return
                end
                if __data.team then
                    frdarena.teams = __data.team
                    loadRank(__data.team)
                end
            end)
            return 
        end

        if frdarena.team.reg == true and frdarena.team.rank <= 50 then 
            local params = {
                sid = player.sid + 256,
            }
             
            addWaitNet()
            net:gpvp_ranklist(params, function(__data)
                delWaitNet()

                tbl2string(__data)
                if __data.status < 0 then
                    showToast("status:" .. __data.status)
                    return
                end
                if __data.team then
                    frdarena.teams = __data.team
                    loadRank(__data.team)
                    for i=1, #frdarena.teams do
                        if frdarena.teams[i].uid == player.uid then
                            frdarena.team.rank = i
                            if frdarena.trank and frdarena.trank > frdarena.team.rank then
                                frdarena.trank = frdarena.team.rank
                            end
                            frdarena.team.score = frdarena.teams[i].score 
                        end
                    end
                    if showRank then
                        showRank:setString(frdarena.team.rank)
                    end
                    if showScore then
                        showScore:setString(frdarena.team.score)
                    end
                end
            end)
            return
        end
        if frdarena.teams then
            loadRank(frdarena.teams)
        end
    end

    -- touch event
    local touchbeginx, touchbeginy
    local isclick
    local last_touch_sprite = nil
    local function onTouchBegan(x, y)
        touchbeginx, touchbeginy = x, y
        isclick = true
        --if current_tab ~= TAB.NEW then
            if scroll and not tolua.isnull(scroll) then
                local obj = scroll:getContainer()
                local p0 = obj:convertToNodeSpace(ccp(x, y))
                for ii=1,#playerBg do
                    if playerBg[ii]:boundingBox():containsPoint(p0) then
                        --playAnimTouchBegin(playerBg[ii])
                        last_touch_sprite = playerBg[ii]
                    end
                end
            end
        --end
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
        if isclick then
            if last_touch_sprite and not tolua.isnull(last_touch_sprite) then
                --playAnimTouchEnd(last_touch_sprite)
                last_touch_sprite = nil
            end
            if scroll and not tolua.isnull(scroll) then
                local obj = scroll:getContainer()
                local p0 = obj:convertToNodeSpace(ccp(x, y))
                for ii=1,#playerBg do
                    if playerBg[ii]:boundingBox():containsPoint(p0) then
                        if last_selet_item ~= playerBg[ii] then
                            audio.play(audio.button)
                            local params = {
                                sid = player.sid + 256,
                                grp_id = frdarena.teams[ii].id,
                            }
                            tbl2string(params)
                            addWaitNet()
                            net:gpvp_grp(params, function(__data)
                                delWaitNet()
                                
                                tbl2string(__data)
                                if __data.status ~= 0 then
                                    showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                                    return
                                end
                                layer:addChild(require("ui.arenac.teaminfotips").create(__data.grp))
                            end)

                            --if last_selet_item then
                            --    last_selet_item.focus:setVisible(false)
                            --end
                            --items[ii].focus:setVisible(true)
                            last_selet_item = nil
                            --showContent(items[ii].mailObj)
                            --items[ii].setRead()
                        end
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
    layer:setTouchEnabled(true)
    layer:setTouchSwallowEnabled(true)

    addBackEvent(layer)

    function layer.onAndroidBack()
        replaceScene(require("ui.town.main").create())  
    end

    local function onEnter()
        pullRank()
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
