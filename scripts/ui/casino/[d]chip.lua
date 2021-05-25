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
local casinodata = require "data.casino"
local i18n = require "res.i18n"
local tipsequip = require "ui.tips.equip"
local tipsitem = require "ui.tips.item"
local NetClient = require "net.netClient"
local netClient = NetClient:getInstance()

local COST_PER_CHIP = casinodata.COST_PER_CHIP
local buy_chip_count = 0

--local function createEdit(parentObj)
--    local edit0 = img.createLogin9Sprite(img.login.input_border)
--    local edit = CCEditBox:create(CCSizeMake(160*view.minScale, 40*view.minScale), edit0)
--    edit:setInputMode(kEditBoxInputModeNumeric)
--    edit:setReturnType(kKeyboardReturnTypeDone)
--    edit:setMaxLength(5)
--    edit:setPlaceHolder("")
--    edit:setFontColor(ccc3(0x94, 0x62, 0x42))
--    edit:setPosition(scalep(454, 272))
--    parentObj:addChild(edit)
--    parentObj.edit = edit
--end

function ui.create()
    -- init 
    buy_chip_count = 0
    local layer = CCLayer:create()
    -- dark bg
    local darkbg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    layer:addChild(darkbg)
    -- board_bg
    local board_bg = img.createUI9Sprite(img.ui.dialog_1)
    board_bg:setPreferredSize(CCSizeMake(370, 448))
    board_bg:setScale(view.minScale)
    board_bg:setPosition(view.midX-0*view.minScale, view.midY)
    layer:addChild(board_bg)
    local board_bg_w = board_bg:getContentSize().width
    local board_bg_h = board_bg:getContentSize().height
    
    -- edit
    local edit0 = img.createLogin9Sprite(img.login.input_border)
    local edit = CCEditBox:create(CCSizeMake(160*view.minScale, 40*view.minScale), edit0)
    edit:setInputMode(kEditBoxInputModeNumeric)
    edit:setReturnType(kKeyboardReturnTypeDone)
    edit:setMaxLength(5)
    edit:setFont("", 20*view.minScale)
    --edit:setPlaceHolder("0")
    edit:setText("0")
    edit:setFontColor(ccc3(0x94, 0x62, 0x42))
    edit:setPosition(scalep(480, 272))
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

    -- title
    local lbl_title = lbl.createFont1(24, i18n.global.chip_board_title.string, ccc3(0xe6, 0xd0, 0xae))
    lbl_title:setPosition(CCPoint(board_bg_w/2, board_bg_h-29))
    board_bg:addChild(lbl_title, 2)
    local lbl_title_shadowD = lbl.createFont1(24, i18n.global.chip_board_title.string, ccc3(0x59, 0x30, 0x1b))
    lbl_title_shadowD:setPosition(CCPoint(board_bg_w/2, board_bg_h-31))
    board_bg:addChild(lbl_title_shadowD)

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
        backEvent()
    end)

    -- chip icon
    local icon_chip = img.createItem(ITEM_ID_CHIP)
    icon_chip:setPosition(CCPoint(board_bg_w/2, 309))
    board_bg:addChild(icon_chip)

    local btn_sub0 = img.createUISprite(img.ui.btn_sub)
    --local btn_sub0 = img.createLogin9Sprite(img.login.button_9_small_gold)
    --btn_sub0:setPreferredSize(CCSizeMake(40, 40))
    --local lbl_btn_sub = lbl.createFont1(20, "-", ccc3(0x94, 0x62, 0x42))
    --lbl_btn_sub:setPosition(CCPoint(btn_sub0:getContentSize().width/2, btn_sub0:getContentSize().height/2))
    --btn_sub0:addChild(lbl_btn_sub)
    local btn_sub = SpineMenuItem:create(json.ui.button, btn_sub0)
    btn_sub:setPosition(CCPoint(73, 208))
    local btn_sub_menu = CCMenu:createWithItem(btn_sub)
    btn_sub_menu:setPosition(CCPoint(0, 0))
    board_bg:addChild(btn_sub_menu)
    
    local btn_add0 = img.createUISprite(img.ui.btn_add)
    --local btn_add0 = img.createLogin9Sprite(img.login.button_9_small_gold)
    --btn_add0:setPreferredSize(CCSizeMake(40, 40))
    --local lbl_btn_add = lbl.createFont1(20, "+", ccc3(0x94, 0x62, 0x42))
    --lbl_btn_add:setPosition(CCPoint(btn_add0:getContentSize().width/2, btn_add0:getContentSize().height/2))
    --btn_add0:addChild(lbl_btn_add)
    local btn_add = SpineMenuItem:create(json.ui.button, btn_add0)
    btn_add:setPosition(CCPoint(295, 208))
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
    local lbl_pay = lbl.createFont3(16, bagdata.gem() .. "/0")
    --lbl_pay:setAnchorPoint(CCPoint(0, 0.5))
    lbl_pay:setPosition(CCPoint(130, gem_bg:getContentSize().height/2-1))
    gem_bg:addChild(lbl_pay)
    lbl_pay.gems = bagdata.gem()

    local function updatePay(_count)
        --if layer.edit and not tolua.isnull(layer.edit) then
        --    local tmp_count = layer.edit:getText()
        --    tmp_count = string.trim(tmp_count)
        --    tmp_count = checkint(tmp_count)
        --    if tmp_count <= 0 then
        --        tmp_count = 0
        --    end
        --    local tmp_str = tmp_count*COST_PER_CHIP .. "/" .. bagdata.gem()
        --    lbl_pay:setString(tmp_str)
        --end
        local tmp_str = bagdata.gem() .. "/" .. (_count*COST_PER_CHIP)
        lbl_pay:setString(tmp_str)
        lbl_pay.gems = bagdata.gem()
    end

    local edit_chips = layer.edit
    edit_chips:registerScriptEditBoxHandler(function(eventType)
        if eventType == "returnSend" then
        elseif eventType == "return" then
        elseif eventType == "ended" then
            local tmp_chip_count = edit_chips:getText()
            tmp_chip_count = string.trim(tmp_chip_count)
            tmp_chip_count = checkint(tmp_chip_count)
            if tmp_chip_count <= 0 then
                tmp_chip_count = 0
            end
            edit_chips:setText(tmp_chip_count)
            updatePay(tmp_chip_count)
            buy_chip_count = tmp_chip_count
        elseif eventType == "began" then
        elseif eventType == "changed" then
        end
    end)

    btn_sub:registerScriptTapHandler(function()
        audio.play(audio.button)
        local edt_txt = edit_chips:getText()
        edt_txt = string.trim(edt_txt)
        if edt_txt == "" then
            edt_txt = 0
            edit_chips:setText(0)
            updatePay(0)
            buy_chip_count = 0
            return
        end
        local chip_count = checkint(edt_txt)
        if chip_count <= 0 then
            edit_chips:setText(0)
            updatePay(0)
            buy_chip_count = 0
            return
        else
            chip_count = chip_count - 1
            edit_chips:setText(chip_count)
            updatePay(chip_count)
            buy_chip_count = chip_count
        end
    end)
    btn_add:registerScriptTapHandler(function()
        audio.play(audio.button)
        local edt_txt = edit_chips:getText()
        edt_txt = string.trim(edt_txt)
        if edt_txt == "" then
            edt_txt = 0
            edit_chips:setText(0)
            updatePay(0)
            buy_chip_count = 0
            return
        end
        local chip_count = checkint(edt_txt)
        if chip_count < 0 then
            edit_chips:setText(0)
            updatePay(0)
            buy_chip_count = 0
            return
        --elseif chip_count >= 999 then
        --    return
        else
            local tmp_gem_cost = COST_PER_CHIP*(chip_count+1)
            if tmp_gem_cost > bagdata.gem() then
                --showToast(i18n.global.ele_hint_no_gem.string)
                --showToast(i18n.global.chip_toast_need_more_gem.string)
                local gotoShopDlg= require "ui.gotoShopDlg"
                gotoShopDlg.show(layer, "casino")
                return
            end
            chip_count = chip_count + 1
            edit_chips:setText(chip_count)
            updatePay(chip_count)
            buy_chip_count = chip_count
        end
    end)

    local btn_buy0 = img.createLogin9Sprite(img.login.button_9_small_gold)
    btn_buy0:setPreferredSize(CCSizeMake(155, 55))
    local lbl_buy = lbl.createFont1(18, i18n.global.chip_btn_buy.string, ccc3(0x73, 0x3b, 0x05))
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
        local tmp_edt_txt = edit_chips:getText()
        tmp_edt_txt = string.trim(tmp_edt_txt)
        if tmp_edt_txt == "" then
            tmp_edt_txt = 0
            edit_chips:setText(0)
            updatePay(0)
            buy_chip_count = 0
            btn_buy:setEnabled(true)
            return
        else
            local chip_count = checkint(tmp_edt_txt)
            if chip_count <= 0 then
                btn_buy:setEnabled(true)
                return
            else
                buy_chip_count = chip_count
            end
        end
        local tmp_gem = buy_chip_count * COST_PER_CHIP
        if tmp_gem > bagdata.gem() then
            --showToast(i18n.global.ele_hint_no_gem.string)
            local gotoShopDlg= require "ui.gotoShopDlg"
            gotoShopDlg.show(layer, "casino")
            btn_buy:setEnabled(true)
            return
        end
        if tmp_gem == 0 then
            btn_buy:setEnabled(true)
            return
        end
        local params = {
            sid = player.sid,
            count = buy_chip_count,
        }
        addWaitNet()
        netClient:casino_buy(params, function(__data)
            cclog("buy_chip callback.")
            tbl2string(__data)
            delWaitNet()
            if __data.status ~=0 then
                showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                mainBtn:setEnabled(true)
                return
            end
            casinodata.addChips(buy_chip_count)
            bagdata.subGem(tmp_gem)
            btn_buy:setEnabled(true)
            layer:removeFromParentAndCleanup(true)
            showToast(i18n.global.toast_buy_okay.string)
        end)
    end)

    local last_update = os.time()
    local function onUpdate(ticks)
        if os.time() - last_update < 0.5 then
            return
        end
        if lbl_pay.gems ~= bagdata.gem() then
            updatePay(buy_chip_count or 0)
        end
        last_update = os.time()
    end
    layer:scheduleUpdateWithPriorityLua(onUpdate, 0)
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
