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
local NetClient = require "net.netClient"
local netClient = NetClient:getInstance()

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
    local lbl_title = lbl.createFont1(24, i18n.global.setting_btn_switch.string, ccc3(0xe6, 0xd0, 0xae))
    lbl_title:setPosition(CCPoint(board_w/2, board_h-29))
    board:addChild(lbl_title, 2)
    local lbl_title_shadowD = lbl.createFont1(24, i18n.global.setting_btn_switch.string, ccc3(0x59, 0x30, 0x1b))
    lbl_title_shadowD:setPosition(CCPoint(board_w/2, board_h-31))
    board:addChild(lbl_title_shadowD)

    local lbl_acct = lbl.createMixFont1(18, i18n.global.setting_account.string, ccc3(0x71, 0x3f, 0x16))
    lbl_acct:setAnchorPoint(CCPoint(0, 0))
    lbl_acct:setPosition(CCPoint(79, 282))
    board:addChild(lbl_acct)
    
    local lbl_passwd = lbl.createMixFont1(18, i18n.global.setting_passwd.string, ccc3(0x71, 0x3f, 0x16))
    lbl_passwd:setAnchorPoint(CCPoint(0, 0))
    lbl_passwd:setPosition(CCPoint(79, 205))
    board:addChild(lbl_passwd)

    local edit_acct0 = img.createLogin9Sprite(img.login.input_border)
    local edit_acct = CCEditBox:create(CCSizeMake(354*view.minScale, 44*view.minScale), edit_acct0)
    edit_acct:setInputFlag(kEditBoxInputFlagInitialCapsSentence)
    --edit_acct:setInputMode(kEditBoxInputModeNumeric)
    edit_acct:setReturnType(kKeyboardReturnTypeDone)
    edit_acct:setMaxLength(150)
    edit_acct:setFont("", 18*view.minScale)
    edit_acct:setFontColor(ccc3(0x71, 0x3f, 0x16))
    edit_acct:setPlaceHolder("")
    edit_acct:setVisible(false)
    edit_acct:setPosition(scalep(480, 346))
    layer:addChild(edit_acct, 100)

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
    edit_passwd:setPosition(scalep(480, 269))
    layer:addChild(edit_passwd, 100)

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
    btn_cancel:setPosition(CCPoint(board_w/2-98, 91))
    local btn_cancel_menu = CCMenu:createWithItem(btn_cancel)
    btn_cancel_menu:setPosition(CCPoint(0, 0))
    board:addChild(btn_cancel_menu)
    btn_cancel:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer:removeFromParentAndCleanup(true)
    end)

    local btn_login0 = img.createLogin9Sprite(img.login.button_9_small_gold)
    btn_login0:setPreferredSize(CCSizeMake(160, 55))
    local lbl_login = lbl.createFont1(18, i18n.global.setting_btn_login.string, ccc3(0x73, 0x3b, 0x05))
    lbl_login:setPosition(CCPoint(btn_login0:getContentSize().width/2, btn_login0:getContentSize().height/2))
    btn_login0:addChild(lbl_login)
    local btn_login = SpineMenuItem:create(json.ui.button, btn_login0)
    btn_login:setPosition(CCPoint(board_w/2+98, 91))
    local btn_login_menu = CCMenu:createWithItem(btn_login)
    btn_login_menu:setPosition(CCPoint(0, 0))
    board:addChild(btn_login_menu)

    btn_login:registerScriptTapHandler(function()
        audio.play(audio.button)
        local input_account = edit_acct:getText()
        input_account = string.trim(input_account)
        input_account = string.lower(input_account)
        if isEmail(input_account) then
            --showToast("email ok")
        else
            showToast(i18n.global.setting_bad_email.string)
            return
        end
        -- check invalid chars
        if containsInvalidChar(input_account) then
            showToast(i18n.global.input_invalid_char.string)
            return
        end
        local input_pwd = edit_passwd:getText()
        input_pwd = string.trim(input_pwd)
        if not input_pwd or string.len(input_pwd) < 6 then
            showToast(i18n.global.setting_invalid_passwd2.string)
            return
        end
        addWaitNet()
        input_pwd = crypto.md5(input_pwd, false)
        local auth = require "ui.login.auth"
        auth.start({new=true, account=input_account, password=input_pwd}, function(_err)
            delWaitNet()
            if _err ~= "ok" then
                showToast(i18n.global.setting_switch_error.string .. _err)
                return
            end
            userdata.setString(userdata.keys.account, input_account)
            userdata.setEncryptString(userdata.keys.password, input_pwd)
            userdata.setBool(userdata.keys.accountFormal, true)
            userdata.clearWhenSwitchAccount()
            netClient:close(function()
                replaceScene((require"ui.login.update").create())
            end)
        end)
    end)

    -- anim
    --board:setScale(0.5*view.minScale)
    --local anim_arr = CCArray:create()
    --anim_arr:addObject(CCScaleTo:create(0.15, 1*view.minScale, 1*view.minScale))
    --anim_arr:addObject(CCDelayTime:create(0.15))
    --anim_arr:addObject(CCCallFunc:create(function()
    --    edit_acct:setVisible(true)
    --    edit_passwd:setVisible(true)
    --end))
    --board:runAction(CCSequence:create(anim_arr))
    edit_acct:setVisible(true)
    edit_passwd:setVisible(true)

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
