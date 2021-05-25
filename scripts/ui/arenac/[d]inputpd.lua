local ui = {}

require "common.func"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local i18n = require "res.i18n"
local net = require "net.netClient"
local player = require "data.player"
local databag = require "data.bag"
local audio = require "res.audio"

-- 加入队伍输入密码
function ui.create(isFirst, handle)
    local layer = CCLayerColor:create(ccc4(0, 0, 0, 210))
    
    local board_w = 465
    local board_h = 320
    local board = img.createLogin9Sprite(img.login.dialog)
    board:setPreferredSize(CCSize(board_w, board_h))
    board:setScale(view.minScale)
    board:setPosition(view.midX,view.midY)
    layer:addChild(board)
     
    local btnCloseSp = img.createLoginSprite(img.login.button_close)
    local btnClose = SpineMenuItem:create(json.ui.button, btnCloseSp)
    btnClose:setPosition(438, 294)
    local menuClose = CCMenu:createWithItem(btnClose)
    menuClose:setPosition(0, 0)
    board:addChild(menuClose)
    btnClose:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer:removeFromParentAndCleanup(true)
    end)

    --local showTitle = lbl.createFont1(26, i18n.global.player_change_name_title.string, ccc3(0xe6, 0xd0, 0xae))
    --showTitle:setPosition(board:getContentSize().width/2, 314)
    --board:addChild(showTitle, 1)
    --local showTitleShade = lbl.createFont1(26, i18n.global.player_change_name_title.string, ccc3(0x59, 0x30, 0x1b))
    --showTitleShade:setPosition(board:getContentSize().width/2, 312)
    --board:addChild(showTitleShade)
 
    local showText = lbl.createMixFont1(18, i18n.global.frdpvp_team_inputpwd.string, ccc3(0x71, 0x3f, 0x16))
    showText:setPosition(board:getContentSize().width/2, 214)
    board:addChild(showText)

    local edit_normal = img.createLogin9Sprite(img.login.input_border)
    local edit_click = img.createLogin9Sprite(img.login.input_border)
    local edit = CCEditBox:create(CCSizeMake(300 * view.minScale, 40 * view.minScale),edit_normal,edit_click)
    edit:setInputFlag(kEditBoxInputFlagInitialCapsSentence)
    edit:setFontColor(ccc3(0x73, 0x3b, 0x05))    
    edit:setReturnType(kKeyboardReturnTypeDone)
    edit:setMaxLength(240)
    edit:setFont("", 16*view.minScale)
    --edit:setPlaceHolder(i18n.global.player_change_name_limit.string)
    edit:setPosition(view.midX, view.midY + 5)
    layer:addChild(edit, 10000)
   
    --if isFirst or tostring(player.uid) == tostring(player.name) then
    --    btnClose:setVisible(false)
    --end

    local btnConfirm
    --if not isFirst and tostring(player.uid) ~= tostring(player.name) then
    local btnConfirmSprite = img.createLogin9Sprite(img.login.button_9_small_gold)
    btnConfirmSprite:setPreferredSize(CCSize(168, 52))
    local labConfirm = lbl.createFont1(16, i18n.global.player_change_name_confirm.string, ccc3(0x71, 0x3f, 0x16))
    labConfirm:setPosition(btnConfirmSprite:getContentSize().width/2, btnConfirmSprite:getContentSize().height/2)
    btnConfirmSprite:addChild(labConfirm)

    btnConfirm = SpineMenuItem:create(json.ui.button, btnConfirmSprite)
    btnConfirm:setPosition(board_w/2, 86)
    local menuConfirm = CCMenu:create()
    menuConfirm:setPosition(0, 0)
    menuConfirm:addChild(btnConfirm)
    board:addChild(menuConfirm)

    btnConfirm:registerScriptTapHandler(function()
        audio.play(audio.button)
        local input_pwd = edit:getText()  
        input_pwd = string.trim(input_pwd)
        if not input_pwd or string.len(input_pwd) < 4 or string.len(input_pwd) > 11 then
            showToast(i18n.global.setting_invalid_passwd.string)
            return
        end

        local params = {
            sid = player.sid,
            password = input_pwd,
        }
 
        tbl2string(params)
        addWaitNet()
        net:set_gpvppwd(params,function(__data)
            delWaitNet()
            tbl2string(__data)
            if __data.status < 0 then
                showToast("status:" .. __data.status)
                return
            end

        --    if string.trim(player.name) ~= string.trim(player.uid) then 
        --        databag.subGem(200)
        --    end
        --    player.name = newName
        --    if handle then
        --        handle()
        --    end
            layer:removeFromParentAndCleanup(true)
        end)
    end)

    --edit:registerScriptEditBoxHandler(function(eventType)
    --    if eventType == "returnSend" then

    --    end
    --end)

    addBackEvent(layer)
    function layer.onAndroidBack()
        layer:removeFromParentAndCleanup(true)
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

    layer:registerScriptTouchHandler(function() return true end)
    layer:setTouchEnabled(true)

    --board:setScale(0.5*view.minScale)
    --local anim_arr = CCArray:create()
    --anim_arr:addObject(CCScaleTo:create(0.15, 1*view.minScale, 1*view.minScale))
    --anim_arr:addObject(CCDelayTime:create(0.15))
    --anim_arr:addObject(CCCallFunc:create(function()
    
    --end))
    --board:runAction(CCSequence:create(anim_arr))

    return layer
end

return ui
