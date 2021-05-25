local ui = {}

require "common.func"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local i18n = require "res.i18n"
local audio = require "res.audio"
local player = require "data.player"
local net = require "net.netClient"
local cfgwave = require "config.wavetrial"
local cfgmonster = require "config.monster"
local trial = require "data.trial"

function ui.create()
    local layer = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))

    local board = img.createLogin9Sprite(img.login.dialog)
    board:setPreferredSize(CCSize(580, 354))
    board:setScale(view.minScale)
    board:setPosition(view.midX, view.midY)
    layer:addChild(board)

    local titleRecord = lbl.createFont1(26, i18n.global.trial_record_tite.string, ccc3(0xe6, 0xd0, 0xae))
    titleRecord:setPosition(290, 324)
    board:addChild(titleRecord, 1)
    local titleRecordShade = lbl.createFont1(26, i18n.global.trial_record_tite.string, ccc3(0x59, 0x30, 0x1b))
    titleRecordShade:setPosition(290, 322)
    board:addChild(titleRecordShade)

    local btnCloseSprite = img.createUISprite(img.ui.close)
    local btnClose = SpineMenuItem:create(json.ui.button, btnCloseSprite)
    btnClose:setPosition(556, 325)
    local menuClose = CCMenu:createWithItem(btnClose)
    menuClose:setPosition(0, 0)
    board:addChild(menuClose)
    btnClose:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer:removeFromParentAndCleanup(true)
    end)

    local function createRecords(records)
        local records = records or {}
        
        if #records == 0 then
            local empty = require("ui.empty").create({ text = i18n.global.empty_tongguan.string })
            empty:setPosition(board:getContentSize().width/2, board:getContentSize().height/2)
            board:addChild(empty)
        end
        
        for i, v in ipairs(records) do
            local recordBg = img.createUI9Sprite(img.ui.botton_fram_2)
            recordBg:setPreferredSize(CCSize(163, 249))
            recordBg:setAnchorPoint(ccp(0, 0))
            recordBg:setPosition(34 + 175 * (i - 1), 36)
            board:addChild(recordBg)

            local showName = lbl.createFontTTF(22, v.name, ccc3(0x51, 0x27, 0x12))
            showName:setPosition(82, 212)
            recordBg:addChild(showName)

            local showHead = img.createPlayerHead(v.logo, v.lv)
            showHead:setScale(0.9)
            showHead:setPosition(82, 136)
            recordBg:addChild(showHead)
         
            local btnVideoSprite = img.createUISprite(img.ui.arena_button_video)
            local btnVideo = HHMenuItem:create(btnVideoSprite)
            btnVideo:setPosition(82, 50)
            local menuVideo = CCMenu:createWithItem(btnVideo)
            menuVideo:setPosition(0, 0)
            recordBg:addChild(menuVideo)
            btnVideo:registerScriptTapHandler(function()
                audio.play(audio.button)
				local newVideo = clone(v.video)
                newVideo.stage = trial.stage
                -- atk
                require ("fight.helper.ccamp").processCamp(newVideo)

                replaceScene(require("fight.trialrep.loading").create(newVideo))
            end)
        end
    end

    addBackEvent(layer)
    function layer.onAndroidBack()
        layer:removeFromParentAndCleanup(true)
    end
    local function onEnter()
        print("onEnter")
        layer.notifyParentLock()
        if not trial.video_stage or trial.video_stage ~= trial.stage then
            local params = {
                sid = player.sid,
            }

            tbl2string(params)
            
            addWaitNet()
            net:trial_video(params, function(__data)
                delWaitNet()
                
                tbl2string(__data)
                trial.initVideo(__data.videos)
                createRecords(__data.videos)
            end)      
        else
            createRecords(trial.videos)
        end
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

    layer:registerScriptTouchHandler(function() return true end)
    layer:setTouchEnabled(true)

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
