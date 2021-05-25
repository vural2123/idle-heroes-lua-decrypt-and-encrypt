local ui = {}

require "common.func"
require "common.const"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local audio = require "res.audio"
local cfgitem = require "config.item"
local cfgequip = require "config.equip"
local player = require "data.player"
local bagdata = require "data.bag"
local i18n = require "res.i18n"
local tipsequip = require "ui.tips.equip"
local tipsitem = require "ui.tips.item"
local NetClient = require "net.netClient"
local netClient = NetClient:getInstance()

local COST_PER_TICKET = 5 
local buyCount = 0

function ui.create()
    -- init 
    buyCount = 0
    local layer = CCLayer:create()
    -- dark bg
    local darkbg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    layer:addChild(darkbg)
    -- board_bg
    local board_bg = img.createUI9Sprite(img.ui.dialog_1)
    board_bg:setPreferredSize(CCSizeMake(400, 448))
    board_bg:setScale(view.minScale)
    board_bg:setPosition(view.midX-25*view.minScale, view.midY)
    layer:addChild(board_bg)
    local board_bg_w = board_bg:getContentSize().width
    local board_bg_h = board_bg:getContentSize().height
    
    -- edit
    local edit0 = img.createLogin9Sprite(img.login.input_border)
    local edit = CCEditBox:create(CCSizeMake(160*view.minScale, 40*view.minScale), edit0)
    edit:setInputMode(kEditBoxInputModeNumeric)
    edit:setReturnType(kKeyboardReturnTypeDone)
    edit:setMaxLength(5)
    edit:setFont("", 16*view.minScale)
    --edit:setPlaceHolder("0")
    edit:setText("0")
    edit:setFontColor(ccc3(0x94, 0x62, 0x42))
    edit:setPosition(scalep(454, 272))
    edit:setVisible(false)
    layer:addChild(edit, 1000)
    layer.edit = edit

    board_bg:setScale(0.5*view.minScale)

    local anim_arr = CCArray:create()
    anim_arr:addObject(CCScaleTo:create(0.15, 1*view.minScale, 1*view.minScale))
    anim_arr:addObject(CCDelayTime:create(0.15))
    anim_arr:addObject(CCCallFunc:create(function()
        --createEdit(layer)
        edit:setVisible(true)
    end))

    -- anim
    board_bg:runAction(CCSequence:create(anim_arr))

    local showTitle = lbl.createFont1(26, i18n.global.trial_buy_title.string, ccc3(0xe6, 0xd0, 0xae))
    showTitle:setPosition(board_bg:getContentSize().width/2, board_bg_h-30)
    board_bg:addChild(showTitle, 1)
    
    local showTitleShade = lbl.createFont1(26, i18n.global.trial_buy_title.string, ccc3(0x59, 0x30, 0x1b))
    showTitleShade:setPosition(board_bg:getContentSize().width/2, board_bg_h - 32)
    board_bg:addChild(showTitleShade)

    local function backEvent()
        audio.play(audio.button)
        layer:removeFromParentAndCleanup(true)
    end
    
    -- btn_close
    local btn_close0 = img.createUISprite(img.ui.close)
    local btn_close = SpineMenuItem:create(json.ui.button, btn_close0)
    btn_close:setPosition(CCPoint(board_bg_w-25, board_bg_h-28))
    local btn_close_menu = CCMenu:createWithItem(btn_close)
    btn_close_menu:setPosition(CCPoint(0, 0))
    board_bg:addChild(btn_close_menu, 100)
    btn_close:registerScriptTapHandler(function()
        audio.play(audio.button)
        backEvent()
    end)

    -- ticket icon
    local icon_ticket = img.createItem(ITEM_ID_TRIAL_TL)--img.createUISprite(img.ui.casino_chip)
    icon_ticket:setPosition(CCPoint(board_bg_w/2, 309))
    board_bg:addChild(icon_ticket)

    local btn_sub0 = img.createUISprite(img.ui.btn_sub)
    local btn_sub = SpineMenuItem:create(json.ui.button, btn_sub0)
    btn_sub:setPosition(CCPoint(board_bg:getContentSize().width/2 - 111, 208))
    local btn_sub_menu = CCMenu:createWithItem(btn_sub)
    btn_sub_menu:setPosition(CCPoint(0, 0))
    board_bg:addChild(btn_sub_menu)
    
    local btn_add0 = img.createUISprite(img.ui.btn_add)
    local btn_add = SpineMenuItem:create(json.ui.button, btn_add0)
    btn_add:setPosition(CCPoint(board_bg:getContentSize().width/2 + 111, 208))
    local btn_add_menu = CCMenu:createWithItem(btn_add)
    btn_add_menu:setPosition(CCPoint(0, 0))
    board_bg:addChild(btn_add_menu)

    local gem_bg = img.createUI9Sprite(img.ui.casino_gem_bg)
    gem_bg:setPreferredSize(CCSizeMake(220, 36))
    gem_bg:setPosition(CCPoint(board_bg_w/2, 141))
    board_bg:addChild(gem_bg)

    local icon_gem = img.createItemIcon2(ITEM_ID_GEM)
    icon_gem:setScale(0.8)
    icon_gem:setPosition(CCPoint(44, gem_bg:getContentSize().height/2))
    gem_bg:addChild(icon_gem)
    local lbl_pay = lbl.createFont2(16, num2KM(bagdata.gem()) .. "/0")
    lbl_pay:setPosition(CCPoint(140, gem_bg:getContentSize().height/2))
    gem_bg:addChild(lbl_pay)

    local function updatePay(_count)
        local tmp_str = num2KM(bagdata.gem()) .. "/" .. num2KM(_count*COST_PER_TICKET)
        lbl_pay:setString(tmp_str)
    end

    local edit_tickets = layer.edit
    edit_tickets:registerScriptEditBoxHandler(function(eventType)
        if eventType == "returnSend" then
        elseif eventType == "return" then
        elseif eventType == "ended" then
            local tmp_ticket_count = edit_tickets:getText()
            tmp_ticket_count = string.trim(tmp_ticket_count)
            tmp_ticket_count = checkint(tmp_ticket_count)
            if tmp_ticket_count <= 0 then
                tmp_ticket_count = 0
            end
            edit_tickets:setText(tmp_ticket_count)
            updatePay(tmp_ticket_count)
            buyCount = tmp_ticket_count
        elseif eventType == "began" then
        elseif eventType == "changed" then
        end
    end)

    btn_sub:registerScriptTapHandler(function()
        audio.play(audio.button)
        local edt_txt = edit_tickets:getText()
        edt_txt = string.trim(edt_txt)
        if edt_txt == "" then
            edt_txt = 0
            edit_tickets:setText(0)
            updatePay(0)
            buyCount = 0
            return
        end
        local ticket_count = checkint(edt_txt)
        if ticket_count <= 0 then
            edit_tickets:setText(0)
            updatePay(0)
            buyCount = 0
            return
        else
            ticket_count = ticket_count - 1
            edit_tickets:setText(ticket_count)
            updatePay(ticket_count)
            buyCount = ticket_count
        end
    end)
    btn_add:registerScriptTapHandler(function()
        audio.play(audio.button)
        local edt_txt = edit_tickets:getText()
        edt_txt = string.trim(edt_txt)
        if edt_txt == "" then
            edt_txt = 0
            edit_tickets:setText(0)
            updatePay(0)
            buyCount = 0
            return
        end
        local ticket_count = checkint(edt_txt)
        if ticket_count < 0 then
            edit_tickets:setText(0)
            updatePay(0)
            buyCount = 0
            return
        else
            local tmp_gem_cost = COST_PER_TICKET*(ticket_count+1)
            if tmp_gem_cost > bagdata.gem() then
                --local gotoStoreDialog = require "uikit.gotoStoreDialog"
                --gotoStoreDialog.show(layer, "casino")
                return
            end
            ticket_count = ticket_count + 1
            edit_tickets:setText(ticket_count)
            updatePay(ticket_count)
            buyCount = ticket_count
        end
    end)

    local btn_buy0 = img.createLogin9Sprite(img.login.button_9_small_gold)
    btn_buy0:setPreferredSize(CCSizeMake(155, 55))
    local lbl_buy = lbl.createFont1(18, i18n.global.arena_buy_tickets_btn.string, ccc3(0x73, 0x3b, 0x05))
    lbl_buy:setPosition(CCPoint(btn_buy0:getContentSize().width/2, btn_buy0:getContentSize().height/2))
    btn_buy0:addChild(lbl_buy)
    local btn_buy = SpineMenuItem:create(json.ui.button, btn_buy0)
    btn_buy:setPosition(CCPoint(board_bg_w/2, 70))
    local btn_buy_menu = CCMenu:createWithItem(btn_buy)
    btn_buy_menu:setPosition(CCPoint(0, 0))
    board_bg:addChild(btn_buy_menu)

    btn_buy:registerScriptTapHandler(function()
        audio.play(audio.button)
        btn_buy:setEnabled(false)
        local tmp_edt_txt = edit_tickets:getText()
        tmp_edt_txt = string.trim(tmp_edt_txt)
        if tmp_edt_txt == "" then
            tmp_edt_txt = 0
            edit_tickets:setText(0)
            updatePay(0)
            buyCount = 0
            btn_buy:setEnabled(true)
            return
        else
            local ticket_count = checkint(tmp_edt_txt)
            if ticket_count <= 0 then
                btn_buy:setEnabled(true)
                return
            else
                buyCount = ticket_count
            end
        end
        local tmp_gem = buyCount * COST_PER_TICKET
        if tmp_gem > bagdata.gem() then
            local gotoStoreDialog = require "ui.gotoShopDlg"
            gotoStoreDialog.show(layer, "arena")
            btn_buy:setEnabled(true)
            return
        end
        if tmp_gem == 0 then
            btn_buy:setEnabled(true)
            return
        end
        local params = {
            sid = player.sid,
            num = buyCount,
        }
        addWaitNet(function()
            delWaitNet()
            showToast(i18n.global.error_network_timeout.string)
            btn_buy:setEnabled(true)
        end)
        netClient:trial_tl(params, function(__data)
            cclog("buy_ticket callback.")
            tbl2string(__data)
            delWaitNet()
            if __data.status ~=0 then
                showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                mainBtn:setEnabled(true)
                return
            end
            bagdata.subGem(tmp_gem)
            btn_buy:setEnabled(true)
            local trialdata = require "data.trial"
            trialdata.tl = trialdata.tl + buyCount
            showToast(i18n.global.toast_buy_okay.string)
            layer:removeFromParentAndCleanup(true)
        end)
    end)

    layer:setTouchEnabled(true)
    layer:setTouchSwallowEnabled(true)

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

    return layer
end

return ui
