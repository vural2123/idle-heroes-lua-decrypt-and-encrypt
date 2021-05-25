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

function ui.create()
    local layer = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))

    local board = img.createLogin9Sprite(img.login.dialog)
    board:setPreferredSize(CCSize(772, 533))
    board:setScale(view.minScale)
    board:setPosition(view.midX, view.midY)
    layer:addChild(board)

    local innerBg = img.createUI9Sprite(img.ui.inner_bg)
    innerBg:setPreferredSize(CCSize(720, 438))
    innerBg:setAnchorPoint(ccp(0.5, 0))
    innerBg:setPosition(board:getContentSize().width/2, 27)
    board:addChild(innerBg)

    local showTitle = lbl.createFont1(26, i18n.global.arena_records_title.string, ccc3(0xe6, 0xd0, 0xae))
    showTitle:setPosition(board:getContentSize().width/2, 504)
    board:addChild(showTitle, 1)
    
    local showTitleShade = lbl.createFont1(26, i18n.global.arena_records_title.string, ccc3(0x59, 0x30, 0x1b))
    showTitleShade:setPosition(board:getContentSize().width/2, 502)
    board:addChild(showTitleShade)
 
    local btnCloseSprite = img.createUISprite(img.ui.close)
    local btnClose = SpineMenuItem:create(json.ui.button, btnCloseSprite)
    btnClose:setPosition(749, 507)
    local menuClose = CCMenu:createWithItem(btnClose)
    menuClose:setPosition(0, 0)
    board:addChild(menuClose)
    btnClose:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer:removeFromParentAndCleanup(true)
    end)

    local function createRecords(logs)
        local logs = logs or {}

        for i=1, #logs/2 do
            logs[i], logs[#logs-i+1] = logs[#logs-i+1], logs[i]
        end

        local height = 105 * #logs 
        local scroll = CCScrollView:create()
        scroll:setDirection(kCCScrollViewDirectionVertical)
        scroll:setAnchorPoint(ccp(0, 0))
        scroll:setPosition(10, 1)
        scroll:setViewSize(CCSize(702, 435))
        scroll:setContentSize(CCSize(702, height))
        scroll:setContentOffset(ccp(0, 435 - height))
        innerBg:addChild(scroll)

        if #logs == 0 then
            local empty = require("ui.empty").create({ text = i18n.global.empty_battlerec.string })
            empty:setPosition(innerBg:getContentSize().width/2, innerBg:getContentSize().height/2)
            innerBg:addChild(empty, 0, 101)
        end
        for i, v in ipairs(logs) do
            local recordBg = img.createUI9Sprite(img.ui.botton_fram_2)
            recordBg:setPreferredSize(CCSize(700, 95))
            recordBg:setAnchorPoint(ccp(0.5, 0))
            recordBg:setPosition(350, height - 105 * i)
            scroll:getContainer():addChild(recordBg)
        
            if v.vid then
                local btnVideoSprite = img.createUISprite(img.ui.arena_button_video)
                local btnVideo = SpineMenuItem:create(json.ui.button, btnVideoSprite)
                btnVideo:setPosition(52, 49)
                local menuVideo = CCMenu:createWithItem(btnVideo)
                menuVideo:setPosition(0, 0)
                recordBg:addChild(menuVideo)
                btnVideo:registerScriptTapHandler(function()
                    audio.play(audio.button)
                    local params = {
                        sid = player.sid,
                        id = 1,
                        vid = v.vid,
                    }

                    tbl2string(params)
                    
                    addWaitNet()
                    net:video(params, function(__data)
                        delWaitNet()
                      
                        if __data.status == -1 then
                            showToast(i18n.global.vidio_overdue.string)
                            return
                        end
                        if __data.status < 0 then
                            showToast("status:" .. __data.status)
                            return 
                        end

                        require ("fight.helper.ccamp").processCamp(__data.video, nil, 2)

                        replaceScene(require("fight.pvprep.loading").create(__data.video))
                    end) 
                end)
            end

            local showHead = img.createPlayerHeadForArena(v.rival.logo, v.rival.lv)
            showHead:setScale(67/84)
            local btnHead = CCMenuItemSprite:create(showHead, nil)
            local menuHead = CCMenu:createWithItem(btnHead)
            menuHead:setPosition(0, 0)
            recordBg:addChild(menuHead)
            btnHead:setPosition(130, 57)
            btnHead:registerScriptTapHandler(function()
                layer:addChild(require("ui.tips.player").create(v.rival), 1000)
            end)
            --showHead:setPosition(130, 49)
            --recordBg:addChild(showHead)
        
            local showName = lbl.createFontTTF(18, v.rival.name, ccc3(0x72, 0x48, 0x35))
            showName:setAnchorPoint(ccp(0, 0))
            showName:setPosition(173, 51)
            recordBg:addChild(showName)
        
            local str
            print(os.time() - v.time)
            if (os.time() - v.time) >= 3600 * 24 then
                str = math.floor((os.time() - v.time)/3600/24) .. " " .. i18n.global.arena_records_days.string
            elseif (os.time() - v.time) >= 3600 then
                str = math.floor((os.time() - v.time)/3600) .. " " .. i18n.global.arena_records_hours.string
            elseif (os.time() - v.time) >= 60 then
                str = math.floor((os.time() - v.time)/60) .. " " .. i18n.global.arena_records_minutes.string
            else
                str = i18n.global.arena_records_times.string
            end
            local showTime = lbl.createFont1(16, str, ccc3(0xa0, 0x7c, 0x60))
            showTime:setAnchorPoint(ccp(0, 0))
            showTime:setPosition(173, 24)
            recordBg:addChild(showTime)
        
            local titleScore = lbl.createFont1(14, i18n.global.arena_records_score.string, ccc3(0xa0, 0x7c, 0x60))
            titleScore:setPosition(485, 58)
            recordBg:addChild(titleScore)
  
            local showScore = lbl.createFont1(20, v.score, ccc3(0x5b, 0x93, 0x02))
            showScore:setPosition(485, 34)
            recordBg:addChild(showScore)
            if v.score > 0 then
                showScore:setString("+" .. v.score)
            end

            local showResult 
            if (v.win == false and v.atk == true) or (v.win == false and v.atk == false) then
                showResult = img.createUISprite(img.ui.arena_icon_lost)
                showScore:setColor(ccc3(0xe1, 0x59, 0x52))
                
                --[[local btnBattleSp = img.createLogin9Sprite(img.login.button_9_small_gold)
                btnBattleSp:setPreferredSize(CCSize(136, 52))

                local ticketIcon = img.createItemIcon(ITEM_ID_ARENA)
                ticketIcon:setScale(0.5)
                ticketIcon:setPosition(34, 26)
                btnBattleSp:addChild(ticketIcon)
        
                local ticketCost = 0
                if arenaData.fight < #cfgarena[1].cost then
                    ticketCost = cfgarena[1].cost[arenaData.fight + 1]
                else
                    ticketCost = cfgarena[1].cost[#cfgarena[1].cost]
                end
           
                local showCost = lbl.createFont2(14, ticketCost)
                showCost:setPosition(34, 16)
                btnBattleSp:addChild(showCost)
                
                local labFight = lbl.createFont1(16, i18n.global.arena_rivals_fight.string, ccc3(0x73, 0x3b, 0x05))
                labFight:setPosition(90, 26)
                btnBattleSp:addChild(labFight)

                local btnBattle = SpineMenuItem:create(json.ui.button, btnBattleSp)
                local menuBattle = CCMenu:createWithItem(btnBattle)
                menuBattle:setPosition(0, 0)
                recordBg:addChild(menuBattle)
                btnBattle:setPosition(610, 47)

                btnBattle:registerScriptTapHandler(function() 
                    disableObjAWhile(btnBattle)
                    audio.play(audio.button)
                    local havTicket = 0
                    local item = bag.items.find(ITEM_ID_ARENA) 
                    if item then
                        havTicket = item.num
                    end
                    if havTicket >= ticketCost then
                        local params = {
                            sid = player.sid,
                            uid = v.rival.uid,
                        }

                        addWaitNet()
                        net:player(params, function(__data)
                            delWaitNet()
                           
                            local info = clone(v.rival)
                            info.camp = clone(__data.heroes)
                            layer:addChild(require("ui.selecthero.main").create({type = "ArenaAtk", info = info, cost = ticketCost}))
                        end) 
                    else
                        layer:addChild(require("ui.arena.buy").create()) 
                    end
                end)--]]
            else 
                showResult = img.createUISprite(img.ui.arena_icon_win)
            end
            showResult:setPosition(377, 47)
            recordBg:addChild(showResult)
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
            id = 1,
        }

        addWaitNet()
        net:plogs(params, function(__data)
            delWaitNet()
            
            tbl2string(__data)
            createRecords(__data.logs)
        end)      

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

    board:setScale(0.5*view.minScale)
    local anim_arr = CCArray:create()
    anim_arr:addObject(CCScaleTo:create(0.15, 1*view.minScale, 1*view.minScale))
    anim_arr:addObject(CCDelayTime:create(0.15))
    anim_arr:addObject(CCCallFunc:create(function()
    
    end))
    board:runAction(CCSequence:create(anim_arr))

    return layer
end

return ui
