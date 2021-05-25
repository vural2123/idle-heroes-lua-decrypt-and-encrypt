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
local airData = require "data.airisland"

local COST_TICKET = {
    [1] = 50,
    [2] = 100,
    [3] = 200,
    [4] = 400,
    [5] = 0,
} 

local buyCount = 5

function ui.create()
    -- init 
    local layer = CCLayer:create()
    -- dark bg
    local darkbg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    layer:addChild(darkbg)
    -- board_bg
    local board_bg = img.createUI9Sprite(img.ui.dialog_1)
    board_bg:setPreferredSize(CCSizeMake(340, 415))
    board_bg:setScale(view.minScale)
    board_bg:setPosition(view.midX-25*view.minScale, view.midY)
    layer:addChild(board_bg)
    local board_bg_w = board_bg:getContentSize().width
    local board_bg_h = board_bg:getContentSize().height
    
    board_bg:setScale(0.5*view.minScale)

    local anim_arr = CCArray:create()
    anim_arr:addObject(CCScaleTo:create(0.15, 1*view.minScale, 1*view.minScale))
    anim_arr:addObject(CCDelayTime:create(0.15))
    --anim_arr:addObject(CCCallFunc:create(function()
        --edit:setVisible(true)
    --end))

    -- anim
    board_bg:runAction(CCSequence:create(anim_arr))

    local showTitle = lbl.createFont1(20, i18n.global.flower_buy_title.string, ccc3(0xe6, 0xd0, 0xae))
    showTitle:setPosition(board_bg:getContentSize().width/2, board_bg_h-30)
    board_bg:addChild(showTitle, 1)
    
    local showTitleShade = lbl.createFont1(20, i18n.global.flower_buy_title.string, ccc3(0x59, 0x30, 0x1b))
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
    local iconBg = img.createUISprite(img.ui.grid)
    local size = iconBg:getContentSize()
    iconBg:setPosition(CCPoint(board_bg_w/2, 272))
    board_bg:addChild(iconBg)
    local numl = lbl.createFont2(14, "5")
    numl:setAnchorPoint(ccp(1, 0))
    numl:setPosition(74, 6)
    iconBg:addChild(numl)
    local icon_ticket = img.createItemIconForId(4301)
    icon_ticket:setPosition(size.width/2, size.height/2)
    iconBg:addChild(icon_ticket)

    local gem_bg = img.createUI9Sprite(img.ui.casino_gem_bg)
    gem_bg:setPreferredSize(CCSizeMake(220, 36))
    gem_bg:setPosition(CCPoint(board_bg_w/2, 172))
    board_bg:addChild(gem_bg)

    local icon_gem = img.createItemIcon2(ITEM_ID_GEM)
    icon_gem:setScale(0.8)
    icon_gem:setPosition(CCPoint(44, gem_bg:getContentSize().height/2))
    gem_bg:addChild(icon_gem)
    print("airData.data.vit.buy:", airData.data.vit.buy)
    local lbl_pay = lbl.createFont2(16, num2KM(bagdata.gem()) .. "/" .. COST_TICKET[airData.data.vit.buy+1], ccc3(255, 246, 223))
    lbl_pay:setPosition(CCPoint(140, gem_bg:getContentSize().height/2))
    gem_bg:addChild(lbl_pay)

    local limitnum = 4-airData.data.vit.buy
    local lblLimit = lbl.createMixFont1(16, i18n.global.limitact_limit.string .. string.format("%d", limitnum), ccc3(0x73, 0x3b, 0x05))
    --lblLimit:setAnchorPoint(ccp(1, 0))
    lblLimit:setPosition(board_bg_w/2, 114)
    board_bg:addChild(lblLimit)

    local btn_buy0 = img.createLogin9Sprite(img.login.button_9_small_gold)
    btn_buy0:setPreferredSize(CCSizeMake(156, 52))
    local lbl_buy = lbl.createFont1(18, i18n.global.arena_buy_tickets_btn.string, ccc3(0x73, 0x3b, 0x05))
    lbl_buy:setPosition(CCPoint(btn_buy0:getContentSize().width/2, btn_buy0:getContentSize().height/2))
    btn_buy0:addChild(lbl_buy)
    local btn_buy = SpineMenuItem:create(json.ui.button, btn_buy0)
    btn_buy:setPosition(CCPoint(board_bg_w/2, 75))
    local btn_buy_menu = CCMenu:createWithItem(btn_buy)
    btn_buy_menu:setPosition(CCPoint(0, 0))
    board_bg:addChild(btn_buy_menu)

    btn_buy:registerScriptTapHandler(function()
        audio.play(audio.button)
        if limitnum <= 0 then
            showToast(i18n.global.toast_buy_herolist_full.string)
            return
        end
        local tmp_gem = COST_TICKET[airData.data.vit.buy+1]
        if tmp_gem > bagdata.gem() then
            local gotoStoreDialog = require "ui.gotoShopDlg"
            gotoStoreDialog.show(layer, "arena")
            btn_buy:setEnabled(true)
            return
        end
        --if tmp_gem == 0 then
        --    btn_buy:setEnabled(true)
        --    return
        --end
        local params = {
            sid = player.sid,
        }
        addWaitNet(function()
            delWaitNet()
            showToast(i18n.global.error_network_timeout.string)
            --btn_buy:setEnabled(true)
        end)
        netClient:island_buy(params, function(__data)
            cclog("buy_ticket callback.")
            tbl2string(__data)
            delWaitNet()
            if __data.status ~=0 then
                showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                mainBtn:setEnabled(true)
                return
            end
            limitnum = limitnum - 1
            lblLimit:setString(i18n.global.limitact_limit.string .. string.format("%d", limitnum))
            bagdata.subGem(tmp_gem)
            btn_buy:setEnabled(true)
            airData.data.vit.buy = airData.data.vit.buy + 1
            airData.changeVit(buyCount)
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
