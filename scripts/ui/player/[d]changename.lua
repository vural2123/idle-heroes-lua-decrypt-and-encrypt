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
-- 创建换昵称面板
function ui.create(isFirst, handle)
    local layer = CCLayerColor:create(ccc4(0, 0, 0, 210))
    
    local board = img.createLogin9Sprite(img.login.dialog)
    board:setPreferredSize(CCSize(515, 343))
    board:setScale(view.minScale)
    board:setPosition(view.midX,view.midY)
    layer:addChild(board)
     
    local btnCloseSp = img.createLoginSprite(img.login.button_close)
    local btnClose = SpineMenuItem:create(json.ui.button, btnCloseSp)
    btnClose:setPosition(489, 317)
    local menuClose = CCMenu:createWithItem(btnClose)
    menuClose:setPosition(0, 0)
    board:addChild(menuClose)
    btnClose:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer:removeFromParentAndCleanup(true)
    end)

    if isFirst or tostring(player.uid) == tostring(player.name) then
        btnClose:setVisible(false)
    end

    local showTitle = lbl.createFont1(26, i18n.global.player_change_name_title.string, ccc3(0xe6, 0xd0, 0xae))
    showTitle:setPosition(board:getContentSize().width/2, 314)
    board:addChild(showTitle, 1)
    local showTitleShade = lbl.createFont1(26, i18n.global.player_change_name_title.string, ccc3(0x59, 0x30, 0x1b))
    showTitleShade:setPosition(board:getContentSize().width/2, 312)
    board:addChild(showTitleShade)
 
    local showText = lbl.createMixFont1(18, i18n.global.player_change_name_info.string, ccc3(0x71, 0x3f, 0x16))
    showText:setPosition(board:getContentSize().width/2, 244)
    board:addChild(showText)

    local edit_normal = img.createLogin9Sprite(img.login.input_border)
    local edit_click = img.createLogin9Sprite(img.login.input_border)
    local edit = CCEditBox:create(CCSizeMake(390 * view.minScale, 40 * view.minScale),edit_normal,edit_click)
    edit:setInputFlag(kEditBoxInputFlagInitialCapsSentence)
    edit:setFontColor(ccc3(0x73, 0x3b, 0x05))    
    edit:setReturnType(kKeyboardReturnTypeDone)
    edit:setMaxLength(240)
    edit:setFont("", 16*view.minScale)
    edit:setPlaceHolder(i18n.global.player_change_name_limit.string)
    edit:setPosition(view.midX, view.midY + 15)
    layer:addChild(edit, 10000)
   
    if isFirst or tostring(player.uid) == tostring(player.name) then
        btnClose:setVisible(false)
    end

    local btnConfirm
    if not isFirst and tostring(player.uid) ~= tostring(player.name) then
        local btnConfirmSprite = img.createLogin9Sprite(img.login.button_9_small_gold)
        local labConfirm = lbl.createFont1(16, i18n.global.player_change_name_confirm.string, ccc3(0x71, 0x3f, 0x16))
        labConfirm:setPosition(97, 59)
        btnConfirmSprite:addChild(labConfirm)

        local showDiamond = img.createItemIcon2(ITEM_ID_GEM)
        showDiamond:setScale(0.8)
        showDiamond:setPosition(64, 30)
        btnConfirmSprite:addChild(showDiamond)
        
        local showCost = lbl.createFont2(20, "200", ccc3(255, 246, 223))
        showCost:setAnchorPoint(ccp(0, 0.5))
        showCost:setPosition(showDiamond:boundingBox():getMaxX() + 5, showDiamond:getPositionY())
        btnConfirmSprite:addChild(showCost)
        if databag.gem() < 200 then
            showCost:setColor(ccc3(0xff, 0x2c, 0x2c))
        end
        
        btnConfirmSprite:setPreferredSize(CCSize(194, 80))
        btnConfirm = SpineMenuItem:create(json.ui.button, btnConfirmSprite)
        btnConfirm:setPosition(250, 86)
        local menuConfirm = CCMenu:create()
        menuConfirm:setPosition(0, 0)
        menuConfirm:addChild(btnConfirm)
        board:addChild(menuConfirm)
    else
        local btnConfirmSprite = img.createLogin9Sprite(img.login.button_9_small_gold)
        btnConfirmSprite:setPreferredSize(CCSize(194, 80))
        local labConfirm = lbl.createFont1(20, i18n.global.player_change_name_confirm.string, ccc3(0x71, 0x3f, 0x16))
        labConfirm:setPosition(btnConfirmSprite:getContentSize().width/2, btnConfirmSprite:getContentSize().height/2)
        btnConfirmSprite:addChild(labConfirm)
        
        btnConfirm = SpineMenuItem:create(json.ui.button, btnConfirmSprite)
        btnConfirm:setPosition(250, 86)
        local menuConfirm = CCMenu:create()
        menuConfirm:setPosition(0, 0)
        menuConfirm:addChild(btnConfirm)
        board:addChild(menuConfirm)
    end

    btnConfirm:registerScriptTapHandler(function()
        audio.play(audio.button)
        local newName = edit:getText()  
        newName = string.trim(newName)
        if isBanWord(newName) then 
            showToast(i18n.global.input_invalid_char.string)
            return 
        end
        if string.len(newName) > 16 then
            showToast(i18n.global.player_change_name_long.string)
            return
        elseif string.len(newName) < 4 then
            showToast(i18n.global.player_change_name_short.string)
            return
        elseif newName == player.name then
            showToast(i18n.global.player_change_name_equal.string)
            return
        elseif containsInvalidChar(newName) then
            showToast(i18n.global.player_change_name_invalid.string)
            return
        end
        
        if newName ~= "" and newName ~= "input:"then
            if databag.gem() < 200 and string.trim(player.name) ~= string.trim(player.uid) then
                showToast(i18n.global.player_change_name_gem.string)
                return 
            end

            local params = {
                sid = player.sid,
                name = newName,
            }
     
            --tbl2string(params)
            addWaitNet()
            net:change_name(params,function(__data)
                delWaitNet()

                if __data.status < 0 then
                    if __data.status == -1 then
                        showToast(i18n.global.toast_name_used.string)
                    elseif __data.status == -11 then
                        showToast(i18n.global.input_invalid_char.string)
                    elseif __data.status <= -10 then
                        showToast("不支持字母和数字")
                    else
                        showToast("status:" .. __data.status)
                    end
                    return
                end

                if string.trim(player.name) ~= string.trim(player.uid) then 
                    databag.subGem(200)
                end
                player.name = newName
                if handle then
                    handle()
                end
                if layer and not tolua.isnull(layer) then
                    layer:removeFromParentAndCleanup(true)
                end

                require("data.tutorial").goNext("rename", 1, true) 
            end)
        end
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
