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

function ui.create()
    local layer = CCLayer:create()
    -- dark bg
    local darkbg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    layer:addChild(darkbg)
    -- board
    local board = img.createUI9Sprite(img.ui.dialog_1)
    board:setPreferredSize(CCSizeMake(510, 400))
    board:setScale(view.minScale)
    board:setPosition(view.midX, view.midY)
    layer:addChild(board)
    local board_w = board:getContentSize().width
    local board_h = board:getContentSize().height

    -- title
    local lbl_title = lbl.createFont1(24, i18n.global.setting_chpasswd_title.string, ccc3(0xe6, 0xd0, 0xae))
    lbl_title:setPosition(CCPoint(board_w/2, board_h-29))
    board:addChild(lbl_title, 2)
    local lbl_title_shadowD = lbl.createFont1(24, i18n.global.setting_chpasswd_title.string, ccc3(0x59, 0x30, 0x1b))
    lbl_title_shadowD:setPosition(CCPoint(board_w/2, board_h-31))
    board:addChild(lbl_title_shadowD)

    local lbl_opasswd = lbl.createFont1(18, i18n.global.setting_old_passwd.string, ccc3(0x71, 0x3f, 0x16))
    lbl_opasswd:setAnchorPoint(CCPoint(0, 0))
    lbl_opasswd:setPosition(CCPoint(79, 305))
    board:addChild(lbl_opasswd)
    
    local lbl_passwd = lbl.createFont1(18, i18n.global.setting_new_passwd.string, ccc3(0x71, 0x3f, 0x16))
    lbl_passwd:setAnchorPoint(CCPoint(0, 0))
    lbl_passwd:setPosition(CCPoint(79, 232))
    board:addChild(lbl_passwd)

    local lbl_cpasswd = lbl.createFont1(18, i18n.global.setting_cpasswd.string, ccc3(0x71, 0x3f, 0x16))
    lbl_cpasswd:setAnchorPoint(CCPoint(0, 0))
    lbl_cpasswd:setPosition(CCPoint(79, 161))
    board:addChild(lbl_cpasswd)

    local edit_opasswd0 = img.createLogin9Sprite(img.login.input_border)
    local edit_opasswd = CCEditBox:create(CCSizeMake(354*view.minScale, 44*view.minScale), edit_opasswd0)
    --edit_opasswd:setInputMode(kEditBoxInputModeNumeric)
    edit_opasswd:setInputFlag(kEditBoxInputFlagPassword)
    edit_opasswd:setReturnType(kKeyboardReturnTypeDone)
    edit_opasswd:setMaxLength(14)
    if device.platform == "android" then
        edit_opasswd:setFont("", 16*view.minScale)
    elseif device.platform == "ios" then
        edit_opasswd:setFont("", 14*view.minScale)
    end
    edit_opasswd:setFontColor(ccc3(0x71, 0x3f, 0x16))
    edit_opasswd:setPlaceHolder("")
    edit_opasswd:setVisible(false)
    edit_opasswd:setPosition(scalep(480, 371))
    layer:addChild(edit_opasswd, 100)

    local edit_passwd0 = img.createLogin9Sprite(img.login.input_border)
    local edit_passwd = CCEditBox:create(CCSizeMake(354*view.minScale, 44*view.minScale), edit_passwd0)
    --edit_passwd:setInputMode(kEditBoxInputModeNumeric)
    edit_passwd:setInputFlag(kEditBoxInputFlagPassword)
    edit_passwd:setReturnType(kKeyboardReturnTypeDone)
    edit_passwd:setMaxLength(14)
    if device.platform == "android" then
        edit_passwd:setFont("", 16*view.minScale)
    elseif device.platform == "ios" then
        edit_passwd:setFont("", 14*view.minScale)
    end
    edit_passwd:setFontColor(ccc3(0x71, 0x3f, 0x16))
    edit_passwd:setPlaceHolder("")
    edit_passwd:setVisible(false)
    edit_passwd:setPosition(scalep(480, 299))
    layer:addChild(edit_passwd, 100)

    local edit_cpasswd0 = img.createLogin9Sprite(img.login.input_border)
    local edit_cpasswd = CCEditBox:create(CCSizeMake(354*view.minScale, 44*view.minScale), edit_cpasswd0)
    --edit_cpasswd:setInputMode(kEditBoxInputModeNumeric)
    edit_cpasswd:setInputFlag(kEditBoxInputFlagPassword)
    edit_cpasswd:setReturnType(kKeyboardReturnTypeDone)
    edit_cpasswd:setMaxLength(14)
    if device.platform == "android" then
        edit_cpasswd:setFont("", 16*view.minScale)
    elseif device.platform == "ios" then
        edit_cpasswd:setFont("", 14*view.minScale)
    end
    edit_cpasswd:setFontColor(ccc3(0x71, 0x3f, 0x16))
    edit_cpasswd:setPlaceHolder("")
    edit_cpasswd:setVisible(false)
    edit_cpasswd:setPosition(scalep(480, 227))
    layer:addChild(edit_cpasswd, 100)

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

    local btn_cancel0 = img.createLogin9Sprite(img.login.button_9_small_gold)
    btn_cancel0:setPreferredSize(CCSizeMake(160, 55))
    local lbl_cancel = lbl.createFont1(18, i18n.global.dialog_button_cancel.string, ccc3(0x73, 0x3b, 0x05))
    lbl_cancel:setPosition(CCPoint(btn_cancel0:getContentSize().width/2, btn_cancel0:getContentSize().height/2))
    btn_cancel0:addChild(lbl_cancel)
    local btn_cancel = SpineMenuItem:create(json.ui.button, btn_cancel0)
    btn_cancel:setPosition(CCPoint(board_w/2-98, 66))
    local btn_cancel_menu = CCMenu:createWithItem(btn_cancel)
    btn_cancel_menu:setPosition(CCPoint(0, 0))
    board:addChild(btn_cancel_menu)

    local btn_confirm0 = img.createLogin9Sprite(img.login.button_9_small_gold)
    btn_confirm0:setPreferredSize(CCSizeMake(160, 55))
    local lbl_confirm = lbl.createFont1(18, i18n.global.dialog_button_confirm.string, ccc3(0x73, 0x3b, 0x05))
    lbl_confirm:setPosition(CCPoint(btn_confirm0:getContentSize().width/2, btn_confirm0:getContentSize().height/2))
    btn_confirm0:addChild(lbl_confirm)
    local btn_confirm = SpineMenuItem:create(json.ui.button, btn_confirm0)
    btn_confirm:setPosition(CCPoint(board_w/2+98, 66))
    local btn_confirm_menu = CCMenu:createWithItem(btn_confirm)
    btn_confirm_menu:setPosition(CCPoint(0, 0))
    board:addChild(btn_confirm_menu)

    -- anim
    --board:setScale(0.5*view.minScale)
    --local anim_arr = CCArray:create()
    --anim_arr:addObject(CCScaleTo:create(0.15, 1*view.minScale, 1*view.minScale))
    --anim_arr:addObject(CCDelayTime:create(0.15))
    --anim_arr:addObject(CCCallFunc:create(function()
    --    edit_opasswd:setVisible(true)
    --    edit_passwd:setVisible(true)
    --    edit_cpasswd:setVisible(true)
    --end))
    --board:runAction(CCSequence:create(anim_arr))
    edit_opasswd:setVisible(true)
    edit_passwd:setVisible(true)
    edit_cpasswd:setVisible(true)

    btn_cancel:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer:removeFromParentAndCleanup(true)
    end)

    btn_confirm:registerScriptTapHandler(function()
        audio.play(audio.button)
        local input_opwd = edit_opasswd:getText()
        input_opwd = string.trim(input_opwd)
        if not input_opwd or string.len(input_opwd) < 6 then
            showToast(i18n.global.setting_bad_opasswd.string)
            return
        end
        input_opwd = crypto.md5(input_opwd, false)
        local l_passwd = userdata.getEncryptString(userdata.keys.password)
        if l_passwd ~= input_opwd then
            showToast(i18n.global.setting_bad_opasswd.string)
            return
        end
        local input_pwd = edit_passwd:getText()
        input_pwd = string.trim(input_pwd)
        if not input_pwd or string.len(input_pwd) < 6 then
            showToast(i18n.global.setting_invalid_passwd.string)
            return
        end
        local input_cpwd = edit_cpasswd:getText()
        input_cpwd = string.trim(input_cpwd)
        if input_cpwd ~= input_pwd then
            showToast(i18n.global.setting_passwd_same.string)
            return
        end
        input_pwd = crypto.md5(input_pwd, false)
        local params = {
            sid = player.sid,
            old = input_opwd,
            new = input_pwd,
        }
        addWaitNet()
        netClient:change_password(params, function(__data)
            delWaitNet()
            tbl2string(__data)
            if __data.status ~= 0 then
                showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                return
            end
            userdata.setEncryptString(userdata.keys.password, params.new)
            showToast("Ok.")
            replaceScene(require("ui.town.main").create({from_layer="language"}))
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

    layer:setTouchEnabled(true)
    layer:setTouchSwallowEnabled(true)

    return layer
end

return ui
