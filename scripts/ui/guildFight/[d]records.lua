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
local cfgarena = require "config.arena"
local arenaData = require "data.arena"
local heros = require "data.heros"
local bag = require "data.bag"
local player = require "data.player"
local gdata = require "data.guild"

local droidhangComponents = require("dhcomponents.DroidhangComponents")

function ui.create()
    local layer = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))

    local board = img.createLogin9Sprite(img.login.dialog)
    board:setPreferredSize(CCSize(660, 510))
    board:setPosition(view.midX, view.midY)
    layer:addChild(board)

    local innerBg = img.createUI9Sprite(img.ui.inner_bg)
    innerBg:setPreferredSize(CCSize(600, 410))
    innerBg:setAnchorPoint(ccp(0.5, 0))
    innerBg:setPosition(board:getContentSize().width/2, 34)
    board:addChild(innerBg)

    local showTitle = lbl.createFont1(26, i18n.global.arena_records_title.string, ccc3(0xe6, 0xd0, 0xae))
    showTitle:setPosition(board:getContentSize().width/2, 480)
    board:addChild(showTitle, 1)
    
    local showTitleShade = lbl.createFont1(26, i18n.global.arena_records_title.string, ccc3(0x59, 0x30, 0x1b))
    showTitleShade:setPosition(board:getContentSize().width/2, 480 - 2)
    board:addChild(showTitleShade)
 
    local btnCloseSprite = img.createUISprite(img.ui.close)
    local btnClose = SpineMenuItem:create(json.ui.button, btnCloseSprite)
    droidhangComponents:mandateNode(btnClose, "LLAz_RnDfYk")
    local menuClose = CCMenu:createWithItem(btnClose)
    menuClose:setPosition(0, 0)
    board:addChild(menuClose)
    btnClose:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer:removeFromParentAndCleanup(true)
    end)

    local scroll = nil
    local function createRecords(logs)
        if scroll then
            return
        end
        local logs = logs or {}

        local height = 98 * #logs 
        scroll = CCScrollView:create()
        scroll:setDirection(kCCScrollViewDirectionVertical)
        scroll:setAnchorPoint(ccp(0, 0))
        scroll:setPosition(10, 1+1)
        scroll:setViewSize(CCSize(600, 410 - 4))
        scroll:setContentSize(CCSize(600, height))
        scroll:setContentOffset(ccp(0, 410 - height))
        innerBg:addChild(scroll)

        if #logs == 0 then
            local empty = require("ui.empty").create({ text = i18n.global.empty_battlerec.string })
            empty:setPosition(innerBg:getContentSize().width/2, innerBg:getContentSize().height/2)
            innerBg:addChild(empty, 0, 101)
        end
        for i, v in ipairs(logs) do
            local recordBg = img.createUI9Sprite(img.ui.botton_fram_2)
            recordBg:setPreferredSize(CCSize(578, 95))
            recordBg:setAnchorPoint(ccp(0.5, 0))
            recordBg:setPosition(578 * 0.5, height - 98 * i - 8)
            scroll:getContainer():addChild(recordBg)

            local showHead = img.createGFlag(v.enemy.logo)
            showHead:setScale(67/84)
            showHead:setPosition(54, 95 * 0.5)
            recordBg:addChild(showHead)
        
            local showName = lbl.createFontTTF(18, v.enemy.name, ccc3(0x72, 0x48, 0x35))
            showName:setAnchorPoint(ccp(0, 0))
            showName:setPosition(97, 58 - 2)
            recordBg:addChild(showName)

            local serverBg = img.createUISprite(img.ui.anrea_server_bg)
            recordBg:addChild(serverBg)
            droidhangComponents:mandateNode(serverBg, "IcBt_ZCKZ7m")

            local serverLabel = lbl.createFont1(16, getSidname(v.enemy.sid), ccc3(255, 251, 215))
            serverLabel:setPosition(serverBg:getContentSize().width * 0.5, serverBg:getContentSize().height * 0.5)
            serverBg:addChild(serverLabel)
        
            local titleScore = lbl.createFont1(14, i18n.global.arena_records_score.string, ccc3(0x7c, 0x4c, 0x34))
            titleScore:setPosition(420, 58)
            recordBg:addChild(titleScore)
  
            local showScore = lbl.createFont1(20, v.score, ccc3(0x5b, 0x93, 0x02))
            showScore:setPosition(420, 34+2)
            recordBg:addChild(showScore)
            if v.score > 0 then
                showScore:setString("+" .. v.score)
            end

            local showResult 
            if not v.win then
                showResult = img.createUISprite(img.ui.arena_icon_lost)
                showScore:setColor(ccc3(0xe1, 0x59, 0x52))
            else 
                showResult = img.createUISprite(img.ui.arena_icon_win)
            end
            showResult:setPosition(302, 47 + 2)
            recordBg:addChild(showResult)

            local btnSprite = img.createUISprite(img.ui.fight_hurts)
            local btnDetail = SpineMenuItem:create(json.ui.button, btnSprite)
            droidhangComponents:mandateNode(btnDetail, "IcBt_RIz7pj")
            local menuBtn = CCMenu:createWithItem(btnDetail)
            menuBtn:setPosition(0, 0)
            recordBg:addChild(menuBtn)

            btnDetail:registerScriptTapHandler(function()
                audio.play(audio.button)

                local params = {
                    sid = player.sid,
                    log_id = v.log_id,
                }

                addWaitNet()
                net:guild_fight_log(params, function(__data)
                    delWaitNet()
                    
                    --tbl2string(__data)

                    if __data.status < 0 then
                        showToast("status:" .. __data.status)
                        return 
                    end

                    local selfGuildObj = {logo = gdata.guildObj.logo, name = gdata.guildObj.name, sid = player.sid}
                    if __data.status == 1 then
                        layer:addChild(require("ui.guildFight.videoDetail").create(v.win == false, v.enemy, selfGuildObj, __data), 100)
                    else
                        layer:addChild(require("ui.guildFight.videoDetail").create(v.win, selfGuildObj, v.enemy, __data), 100)
                    end

                end)
            end)
        end
    end

    layer:registerScriptTouchHandler(function() return true end)
    layer:setTouchEnabled(true)
      
    addBackEvent(layer)
    function layer.onAndroidBack()
        layer:removeFromParentAndCleanup(true)
    end
    local function onEnter()
        local params = {
            sid = player.sid,
        }

        addWaitNet()
        net:guild_fight_logs(params, function(__data)
            delWaitNet()
            
            tbl2string(__data)
            createRecords(__data.logs)
        end)      

        -- local data = {}
        -- data.logs = {
        --     {log_id = 3, score = 30, win = true, enemy = {name = "55", sid = 4, logo = 4}},
        -- }

        -- createRecords(data.logs)

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

    board:setScale(0.5 * view.minScale)
    local anim_arr = CCArray:create()
    anim_arr:addObject(CCScaleTo:create(0.15, view.minScale))
    anim_arr:addObject(CCDelayTime:create(0.15))
    anim_arr:addObject(CCCallFunc:create(function()
    
    end))
    board:runAction(CCSequence:create(anim_arr))

    return layer
end

return ui
