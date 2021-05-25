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
local arena3v3Data = require "data.3v3arena"
local databag = require "data.bag"

function ui.create(uiParams)
    local layer = CCLayer:create()

    json.load(json.ui.jjc2)
    local board = DHSkeletonAnimation:createWithKey(json.ui.jjc2)
    board:scheduleUpdateLua()
    board:setPosition(view.midX, view.midY)
    board:setScale(view.minScale)
    board:playAnimation("start")
    board:appendNextAnimation("loop", -1)
    layer:addChild(board)

    local bg1 = CCLayer:create()
    board:addChildFollowSlot("code_bg1", bg1)

    local bg2 = CCLayer:create()
    board:addChildFollowSlot("code_bg2", bg2)

    -- backBtn
    local btnBackSprite = img.createUISprite(img.ui.back)
    local btnBack = SpineMenuItem:create(json.ui.button, btnBackSprite)
    btnBack:setPosition(-5, 546-18)
    local menuBack = CCMenu:createWithItem(btnBack)
    menuBack:setPosition(0, 0)
    bg1:addChild(menuBack)
    btnBack:registerScriptTapHandler(function()
        audio.play(audio.button)
        replaceScene(require("ui.town.main").create())  
    end)

    local btnInfoSprite = img.createUISprite(img.ui.btn_help)
    local btnInfo = SpineMenuItem:create(json.ui.button, btnInfoSprite)
    btnInfo:setPosition(603-35, 546-18)
    local menuInfo = CCMenu:createWithItem(btnInfo)
    menuInfo:setPosition(0, 0)
    bg1:addChild(menuInfo)
    btnInfo:registerScriptTapHandler(function()
        audio.play(audio.button)
        local str = i18n.arena[2].infoTitle1 .. ":::" .. string.gsub(i18n.arena[2].info1, ";", "|||")
        str = str .. "###" .. i18n.arena[2].infoTitle2 .. ":::" .. string.gsub(i18n.arena[2].info2, ";", "|||")
        layer:addChild(require("ui.help").create(str, i18n.global.help_title.string), 1000)
    end)

    autoLayoutShift(btnBack, true, false, true, false)
    autoLayoutShift(btnInfo, true, false, false, false)

    local showTitle = lbl.createFont3(22, i18n.arena[2].name)
    showTitle:setPosition(289 - 20, 458)
    bg1:addChild(showTitle)

    local showLeftTitle = lbl.createFont3(18, i18n.global.arena_remain_title.string, ccc3(0xff, 0xcd, 0x33))
    showLeftTitle:setPosition(289 - 20, 431)
    bg1:addChild(showLeftTitle)

    local showTime = lbl.createFont2(16, "")
    showTime:setPosition(289 - 20, 410)
    bg1:addChild(showTime)

    local btnRewardSprite = img.createUISprite(img.ui.arena_reward_icon)
    local btnReward = SpineMenuItem:create(json.ui.button, btnRewardSprite)
    local menuReward = CCMenu:createWithItem(btnReward)
    btnReward:setPosition(687, 42)
    menuReward:setPosition(0, 0)
    bg2:addChild(menuReward)
    btnReward:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer:addChild(require("ui.3v3arena.rewards").create())
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
        layer:addChild(require("ui.3v3arena.records").create())
    end)

    if uiParams and uiParams.video then
        layer:addChild(require("ui.3v3arena.records").create(uiParams.video))
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
        btnDefen:setEnabled(false)
        disableObjAWhile(btnDefen)
        audio.play(audio.button)
        layer:addChild(require("ui.3v3arena.select").create({ type = "3v3arenaDef" })) 
    end)

    local showDefenTab = lbl.createFont2(14, i18n.global.arena_main_defen.string)
    showDefenTab:setPosition(btnDefen:boundingBox():getMidX(), btnDefen:boundingBox():getMinY() + 8)
    bg2:addChild(showDefenTab)

    local showHead = img.createPlayerHeadForArena(player.logo, player.lv())
    showHead:setPosition(740, 485)
    bg2:addChild(showHead)

    local powerIcon = img.createUISprite(img.ui.power_icon)
    powerIcon:setScale(0.48)
    powerIcon:setPosition(807, 500)
    bg2:addChild(powerIcon)

    local showPower = lbl.createFont3(22, arena3v3Data.power)
    showPower:setPosition(792, 450)
    showPower:setAnchorPoint(ccp(0, 0))
    bg2:addChild(showPower)

    local titleRank = lbl.createFont2(20, i18n.global.arena_main_rank.string, ccc3(0xf8, 0xe1, 0xbf))
    titleRank:setAnchorPoint(ccp(0, 0))
    titleRank:setPosition(695, 395)
    bg2:addChild(titleRank)

    local titleScore = lbl.createFont2(20, i18n.global.arena_main_score_Big.string, ccc3(0xf8, 0xe1, 0xbf))
    titleScore:setAnchorPoint(ccp(0, 0))
    titleScore:setPosition(695, 360)
    bg2:addChild(titleScore)

    local showRank = lbl.createFont2(20, arena3v3Data.rank)
    showRank:setAnchorPoint(ccp(0, 0))
    showRank:setPosition(titleRank:boundingBox():getMaxX() + 10, 395)
    bg2:addChild(showRank)

    local showScore = lbl.createFont2(20, arena3v3Data.score)
    showScore:setAnchorPoint(ccp(0, 0))
    showScore:setPosition(titleScore:boundingBox():getMaxX() + 10, 360)
    bg2:addChild(showScore)

    local showTicketBg = img.createUI9Sprite(img.ui.arena_ticket_bg)
    showTicketBg:setPreferredSize(CCSize(150, 25))
    showTicketBg:setPosition(788, 315)
    bg2:addChild(showTicketBg)

    local showTicketIcon = img.createItemIcon(ITEM_ID_ARENA)
    showTicketIcon:setScale(0.6)
    showTicketIcon:setPosition(710, 313)
    bg2:addChild(showTicketIcon)

    local showTicket = lbl.createFont2(18, "0")
    showTicket:setPosition(showTicketBg:getContentSize().width/2, showTicketBg:getContentSize().height/2)
    showTicketBg:addChild(showTicket)

    local btnAddSprite = img.createUISprite(img.ui.main_icon_plus)
    local btnAdd = SpineMenuItem:create(json.ui.button, btnAddSprite)
    local menuAdd = CCMenu:createWithItem(btnAdd)
    btnAdd:setPosition(858, 315)
    menuAdd:setPosition(0, 0)
    bg2:addChild(menuAdd)
    btnAdd:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer:addChild(require("ui.arena.buy").create()) 
    end)

    local btnBattleSprite = img.createUI9Sprite(img.ui.btn_1)
    btnBattleSprite:setPreferredSize(CCSize(190, 72))
    local labBattle = lbl.createFont1(22, i18n.global.arena_main_battle.string, ccc3(0x73, 0x3b, 0x05))
    labBattle:setPosition(btnBattleSprite:getContentSize().width/2, btnBattleSprite:getContentSize().height/2)
    btnBattleSprite:addChild(labBattle)
    
    local btnBattle = SpineMenuItem:create(json.ui.button, btnBattleSprite)
    local menuBattle = CCMenu:createWithItem(btnBattle)
    btnBattle:setPosition(787, 230)
    menuBattle:setPosition(0, 0)
    bg2:addChild(menuBattle)
    
    btnBattle:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer:addChild(require("ui.3v3arena.pickRival").create())
    end)

    local scroll = CCScrollView:create()
    scroll:setDirection(kCCScrollViewDirectionVertical)
    scroll:setAnchorPoint(ccp(0, 0))
    scroll:setPosition(0, 2)
    scroll:setViewSize(CCSize(539, 382))
    scroll:setContentSize(CCSize(539, 0))
    bg1:addChild(scroll)

    local function loadRank(ranks)
        local height = 86 * #ranks + 3
        scroll:getContainer():removeAllChildrenWithCleanup(true)
        scroll:setContentSize(CCSize(539, height))
        scroll:setContentOffset(ccp(0, 382 - height))

        local IMG = { img.ui.arena_frame1, img.ui.arena_frame3, img.ui.arena_frame5 }
        for i, v in ipairs(ranks) do
            local playerBg
            local showRank
            local showPowerBg
            if i < 4 then
                playerBg = img.createUI9Sprite(IMG[i])
                showRank = img.createUISprite(img.ui["arena_rank_" .. i])
                showPowerBg = img.createUI9Sprite(img.ui["arena_frame" .. (i * 2)])
            else
                playerBg = img.createUI9Sprite(img.ui.botton_fram_2)
                showRank = lbl.createFont1(20, i, ccc3(0x82, 0x5a, 0x3d))
                showPowerBg = img.createUI9Sprite(img.ui.arena_frame7)
            end
            playerBg:setPreferredSize(CCSize(539, 84))
            playerBg:setAnchorPoint(ccp(0, 0))
            playerBg:setPosition(0, height - 86 * i - 3)
            scroll:getContainer():addChild(playerBg)
       
            showRank:setPosition(44, 43)
            playerBg:addChild(showRank)

            local showHead = img.createPlayerHeadForArena(v.logo, v.lv)
            showHead:setScale(0.7)
            local btnHead = CCMenuItemSprite:create(showHead, nil)
            local menuHead = CCMenu:createWithItem(btnHead)
            menuHead:setPosition(0, 0)
            playerBg:addChild(menuHead)
            btnHead:setPosition(122, 55)
            btnHead:registerScriptTapHandler(function()
                layer:addChild(require("ui.3v3arena.player").create(v), 1000)
            end)

            local showName = lbl.createFontTTF(20, v.name, ccc3(0x51, 0x27, 0x12))
            showName:setAnchorPoint(ccp(0, 0))
            showName:setPosition(160, 48)
            playerBg:addChild(showName)

            local serverBg = img.createUISprite(img.ui.anrea_server_bg)
            serverBg:setPosition(404, 84 * 0.5)
            playerBg:addChild(serverBg)
            local serverLabel = lbl.createFont1(16, getSidname(v.sid), ccc3(255, 251, 215))
            serverLabel:setPosition(serverBg:getContentSize().width * 0.5, serverBg:getContentSize().height * 0.5)
            serverBg:addChild(serverLabel)
    
            showPowerBg:setPreferredSize(CCSize(197, 28))
            showPowerBg:setAnchorPoint(ccp(0, 0))
            showPowerBg:setPosition(160, 15)
            playerBg:addChild(showPowerBg)
          
            local showPowerIcon = img.createUISprite(img.ui.power_icon)
            showPowerIcon:setScale(0.5)
            showPowerIcon:setPosition(175, 30)
            playerBg:addChild(showPowerIcon)
 
            local showPower = lbl.createFont2(16, v.power)
            showPower:setAnchorPoint(ccp(0, 0))
            showPower:setPosition(202, 18)
            playerBg:addChild(showPower)

            local titleScore = lbl.createFont1(14, i18n.global.arena_main_score.string, ccc3(0x9a, 0x6a, 0x52))
            titleScore:setPosition(476, 53)
            playerBg:addChild(titleScore)
 
            local showScore = lbl.createFont1(22, v.score, ccc3(0xa4, 0x2f, 0x28))
            showScore:setPosition(476, 34)
            playerBg:addChild(showScore)
        end
    end
 
    local function pullRank()
        if (not arena3v3Data.members) or arena3v3Data.rank <= 50 then 
            local params = {
                sid = player.sid,
                id = 2,
            }

            addWaitNet()
            net:pvp_rank(params, function(__data)
                delWaitNet()

                tbl2string(__data)
                arena3v3Data.members = __data.members
                loadRank(__data.members)

                for i=1, #arena3v3Data.members do
                    if arena3v3Data.members[i].uid == player.uid and arena3v3Data.members[i].sid == player.sid then
                        arena3v3Data.rank = i
                        if arena3v3Data.trank and arena3v3Data.trank > arena3v3Data.rank then
                            arena3v3Data.trank = arena3v3Data.rank
                        end
                        arena3v3Data.score = arena3v3Data.members[i].score 
                    end
                end
                if showRank then
                    showRank:setString(arena3v3Data.rank)
                end
                if showScore then
                    showScore:setString(arena3v3Data.score)
                end
            end)
        else
            if arena3v3Data.members then
                loadRank(arena3v3Data.members)
            end
        end
    end

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

    layer:scheduleUpdateWithPriorityLua(function()
        local item = databag.items.find(ITEM_ID_ARENA)
        local count = 0
        if item then count = item.num end
        showTicket:setString(count)
       
        if (arena3v3Data.season_cd - os.time()) > 86400 * 3 then
            showTime:setString(math.floor((arena3v3Data.season_cd - os.time())/86400) .. " " .. i18n.global.arena_time_day.string)
        else
            showTime:setString(time2string(arena3v3Data.season_cd - os.time()))
        end

        if arena3v3Data.season_cd <= os.time() then
            replaceScene(require("ui.town.main").create())
        end
    end)

    return layer
end

return ui

