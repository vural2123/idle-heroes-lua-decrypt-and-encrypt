local ui = {}

require "common.func"
require "common.const"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local audio = require "res.audio"
local i18n = require "res.i18n"
local player = require "data.player"
local userdata = require "data.userdata"
local net = require "net.netClient"
local frdarena = require "data.arenac"

function ui.create()
    local layer = CCLayer:create()
    -- dark bg
    local darkbg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    layer:addChild(darkbg)
    -- board
    local board = img.createUI9Sprite(img.ui.dialog_1)
    board:setPreferredSize(CCSizeMake(510, 376))
    board:setScale(view.minScale)
    board:setPosition(view.midX, view.midY)
    layer:addChild(board)
    local board_w = board:getContentSize().width
    local board_h = board:getContentSize().height
    --board:setScale(0.5*view.minScale)
    --board:runAction(CCScaleTo:create(0.15, 1*view.minScale, 1*view.minScale))

    -- title todo
    local lbl_title = lbl.createFont1(24, i18n.global.goto_guild_create.string, ccc3(0xe6, 0xd0, 0xae))
    lbl_title:setPosition(CCPoint(board_w/2, board_h-29))
    board:addChild(lbl_title, 2)
    local lbl_title_shadowD = lbl.createFont1(24, i18n.global.goto_guild_create.string, ccc3(0x59, 0x30, 0x1b))
    lbl_title_shadowD:setPosition(CCPoint(board_w/2, board_h-31))
    board:addChild(lbl_title_shadowD)

    local lbl_teamname = lbl.createFont1(18, i18n.global.frdpvp_team_teamname.string, ccc3(0x71, 0x3f, 0x16))
    lbl_teamname:setAnchorPoint(CCPoint(0, 0))
    lbl_teamname:setPosition(CCPoint(79, 262))
    board:addChild(lbl_teamname)
    
    local lbl_power = lbl.createFont1(18, i18n.global.frdpvp_team_reqpower.string, ccc3(0x71, 0x3f, 0x16))
    lbl_power:setAnchorPoint(CCPoint(0, 0))
    lbl_power:setPosition(CCPoint(79, 187))
    board:addChild(lbl_power)

    local edit_name0 = img.createLogin9Sprite(img.login.input_border)
    local edit_name = CCEditBox:create(CCSizeMake(350*view.minScale, 40*view.minScale), edit_name0)
    --edit_name:setInputMode(kEditBoxInputModeNumeric)
    --edit_name:setInputFlag(kEditBoxInputFlagPassword)
    edit_name:setReturnType(kKeyboardReturnTypeDone)
    edit_name:setMaxLength(12)
    edit_name:setFont("", 16*view.minScale)
    edit_name:setFontColor(ccc3(0x71, 0x3f, 0x16))
    edit_name:setPlaceHolder("")
    edit_name:setVisible(false)
    edit_name:setPosition(scalep(480, 338))
    layer:addChild(edit_name, 100)

    local edit_power0 = img.createLogin9Sprite(img.login.input_border)
    local edit_power = CCEditBox:create(CCSizeMake(350*view.minScale, 40*view.minScale), edit_power0)
    edit_power:setInputMode(kEditBoxInputModeNumeric)
    --edit_power:setInputFlag(kEditBoxInputFlagPassword)
    edit_power:setReturnType(kKeyboardReturnTypeDone)
    edit_power:setMaxLength(9)
    edit_power:setFont("", 16*view.minScale)
    --edit_power:setFontColor(ccc3(0x71, 0x3f, 0x16))
    edit_power:setText(string.format("%d", 1))
    --edit_power:setPlaceHolder("")
    edit_power:setVisible(false)
    edit_power:setFontColor(ccc3(0x94, 0x62, 0x42))
    edit_power:setPosition(scalep(480, 262))
    layer:addChild(edit_power, 100)

    local edit_chips = edit_power
    edit_chips:registerScriptEditBoxHandler(function(eventType)
        if eventType == "returnSend" then
        elseif eventType == "return" then
        elseif eventType == "ended" then
            local tmp_chip_count = edit_chips:getText()
            tmp_chip_count = string.trim(tmp_chip_count)
            tmp_chip_count = checkint(tmp_chip_count)
            if tmp_chip_count < 1 then
                tmp_chip_count = 1
            elseif tmp_chip_count > 999999 then
                tmp_chip_count = 999999
            end
            edit_chips:setText(tmp_chip_count)
        elseif eventType == "began" then
        elseif eventType == "changed" then
        end
    end)

    local function backEvent()
        audio.play(audio.button)
        layer:removeFromParentAndCleanup(true)
    end
    -- btn_close
    local btn_close0 = img.createUISprite(img.ui.close)
    local btn_close = SpineMenuItem:create(json.ui.button, btn_close0)
    btn_close:setPosition(CCPoint(board_w-25, board_h-28))
    local btn_close_menu = CCMenu:createWithItem(btn_close)
    btn_close_menu:setPosition(CCPoint(0, 0))
    board:addChild(btn_close_menu, 100)
    btn_close:registerScriptTapHandler(function()
        backEvent()
    end)

    local btn_create0 = img.createLogin9Sprite(img.login.button_9_small_gold)
    btn_create0:setPreferredSize(CCSizeMake(160, 55))
    local lbl_create = lbl.createFont1(18, i18n.global.goto_guild_create.string, ccc3(0x73, 0x3b, 0x05))
    lbl_create:setPosition(CCPoint(btn_create0:getContentSize().width/2, btn_create0:getContentSize().height/2))
    btn_create0:addChild(lbl_create)
    local btn_create = SpineMenuItem:create(json.ui.button, btn_create0)
    btn_create:setPosition(CCPoint(board_w/2, 75))
    local btn_create_menu = CCMenu:createWithItem(btn_create)
    btn_create_menu:setPosition(CCPoint(0, 0))
    board:addChild(btn_create_menu)

    btn_create:registerScriptTapHandler(function()
        audio.play(audio.button)
        local input_power = checkint(edit_power:getText())
        local input_name = edit_name:getText()
        input_name = string.trim(input_name)

        if not input_name or string.len(input_name) < 5 then
            showToast(i18n.global.frdpvp_team_name_limit.string)
            return
        end
        
        if not input_name or string.len(input_name) > 12 then
            showToast(i18n.global.frdpvp_team_name_limit.string)
            return
        end
        
        local params = {
            sid = player.sid + 256,        
            name = input_name,
            need_power = input_power
        }

        addWaitNet()
        net:create_gpvpteam(params, function(__data)
            delWaitNet()
            tbl2string(__data)
            if __data.status == -11 then
                showToast(i18n.global.player_change_name_invalid.string)
                return
            end
            if __data.status == -2 then
                showToast(i18n.global.frdpvp_team_iinteam.string)
                return 
            end
            if __data.status == -1 then
                showToast(i18n.global.player_change_name_equal.string)
                return 
            end
            if __data.status ~= 0 then
                showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                return
            end
            addWaitNet() 
            net:gpvp_sync(params, function(_data)
                delWaitNet()
                tbl2string(_data)
                frdarena.team = _data.team
                layer:getParent():getParent():addChild(require("ui.arenac.teaminfo").create())
                layer:getParent():removeFromParentAndCleanup(true)
            end)
        end)
    end)

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

    board:setScale(0.5*view.minScale)
    local anim_arr = CCArray:create()
    anim_arr:addObject(CCScaleTo:create(0.15, 1*view.minScale, 1*view.minScale))
    anim_arr:addObject(CCDelayTime:create(0.15))
    anim_arr:addObject(CCCallFunc:create(function()
        edit_name:setVisible(true)
        edit_power:setVisible(true)
    end))
    board:runAction(CCSequence:create(anim_arr))

    layer:setTouchEnabled(true)
    layer:setTouchSwallowEnabled(true)

    return layer
end

return ui
