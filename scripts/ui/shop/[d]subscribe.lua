local ui = {}

require "common.func"
local view = require "common.view"
local i18n = require "res.i18n"
local lbl = require "res.lbl"
local img = require "res.img"
local audio = require "res.audio"
local json = require "res.json"
local player = require "data.player"
local activityData = require "data.activity"
local shop = require "data.shop"
local NetClient = require "net.netClient"
local netClient = NetClient:getInstance()
local tipsequip = require "ui.tips.equip"
local tipsitem = require "ui.tips.item"

function ui.create()
    local layer = CCLayer:create()
    img.load("ui_sub")
    local bg = img.createUISprite("sub_bg.png")
    bg:setScale(view.minScale)
    bg:setPosition(scalep(480, 288))
    layer:addChild(bg)
    local bg_w = bg:getContentSize().width
    local bg_h = bg:getContentSize().height

    -- logo
    local logo = img.createUISprite("sub_logo.png")
    logo:setPosition(CCPoint(690, 478))
    bg:addChild(logo)

    local tip1 = lbl.createFont1(20, "Gold coin in auto-battle +100%", ccc3(0xff, 0xff, 0xff))
    tip1:setPosition(CCPoint(690, 362))
    bg:addChild(tip1)
    local tip2 = lbl.createFont1(20, "A special gold dragon avatar", ccc3(0xff, 0xff, 0xff))
    tip2:setPosition(CCPoint(690, 320))
    bg:addChild(tip2)

    local btn_buy0 = img.createUI9Sprite("sub_button_yellow.png")
    btn_buy0:setPreferredSize(CCSizeMake(300, 56))
    local lbl_buy = CCLabelTTF:create("USD 0.99/week", "", 22)
    lbl_buy:setColor(ccc3(0x65, 0x42, 0x05))
    lbl_buy:setPosition(CCPoint(btn_buy0:getContentSize().width/2, btn_buy0:getContentSize().height/2))
    btn_buy0:addChild(lbl_buy)
    local btn_buy = SpineMenuItem:create(json.ui.button, btn_buy0)
    btn_buy:setPosition(CCPoint(690, 207))
    local btn_buy_menu = CCMenu:createWithItem(btn_buy)
    btn_buy_menu:setPosition(CCPoint(0, 0))
    bg:addChild(btn_buy_menu)
    btn_buy:registerScriptTapHandler(function()
        audio.play(audio.button)
        if shop.pay and shop.pay[33] and shop.pay[33] > 0 then
            showToast("you have subscribed this.")
            return
        end
        local waitnet = addWaitNet()
        waitnet.setTimeout(90)
        local iap = require "common.iap"
        local cfg= require"config.store"
        iap.pay(cfg[33].payId, function(conquest)
            delWaitNet()
            if conquest then
                shop.setPay(33, 1)
                shop.addSubHead()
                showToast("subscribed.")
                replaceScene(require("ui.town.main").create({from_layer="shop"}))  
            end
        end)
    end)

    local btn_restore0 = img.createUI9Sprite("sub_button_green.png")
    btn_restore0:setPreferredSize(CCSizeMake(300, 56))
    local lbl_restore = CCLabelTTF:create("Restore Purchase", "", 22)
    lbl_restore:setColor(ccc3(0x30, 0x4f, 0x05))
    lbl_restore:setPosition(CCPoint(btn_restore0:getContentSize().width/2, btn_restore0:getContentSize().height/2))
    btn_restore0:addChild(lbl_restore)
    local btn_restore = SpineMenuItem:create(json.ui.button, btn_restore0)
    btn_restore:setPosition(CCPoint(690, 127))
    local btn_restore_menu = CCMenu:createWithItem(btn_restore)
    btn_restore_menu:setPosition(CCPoint(0, 0))
    bg:addChild(btn_restore_menu)
    btn_restore:registerScriptTapHandler(function()
        audio.play(audio.button)
        if shop.pay and shop.pay[33] and shop.pay[33] > 0 then
            showToast("you have subscribed this.")
            return
        end
        local waitnet = addWaitNet()
        waitnet.setTimeout(90)
        DHPayment:getInstance():restore(function(status, purchases)
            print("iap pull {")
            print("status", status);
            if status ~= "ok" or #purchases == 0 then
                delWaitNet()
                print("iap pull }")
                return
            end
            local iap = require "common.iap"
            iap.verify(purchases, function(reward)
                delWaitNet()
                print("iap pull }")
                if reward then
                    shop.setPay(33, 1)
                    shop.addSubHead()
                    showToast("restored.")
                    replaceScene(require("ui.town.main").create({from_layer="shop"}))  
                end
            end)
        end)
    end)

    local tip3 = CCLabelTTF:create("Continue means that you accept", "", 14)
    tip3:setColor(ccc3(0xff, 0xff, 0xff))
    tip3:setPosition(CCPoint(690, 66))
    bg:addChild(tip3)

    local tip4 = CCLabelTTF:create("[ Terms Of Service & Privacy Policy ]", "", 14)
    tip4:setColor(ccc3(0xff, 0xff, 0xff))
    local btn_tip4_0 = CCSprite:create()
    btn_tip4_0:setContentSize(tip4:getContentSize())
    tip4:setPosition(CCPoint(btn_tip4_0:getContentSize().width/2, btn_tip4_0:getContentSize().height/2))
    btn_tip4_0:addChild(tip4)
    local btn_tip4 = CCMenuItemSprite:create(btn_tip4_0, nil)
    btn_tip4:setPosition(CCPoint(610, 40))
    local btn_tip4_menu = CCMenu:createWithItem(btn_tip4)
    btn_tip4_menu:setPosition(CCPoint(0, 0))
    bg:addChild(btn_tip4_menu)
    btn_tip4:registerScriptTapHandler(function()
        audio.play(audio.button)
        print("click tip4")
        layer:addChild(require("ui.shop.privacy").create(), 1000)
    end)

    local tip5 = CCLabelTTF:create("[ Payment Terms ]", "", 14)
    tip5:setColor(ccc3(0xff, 0xff, 0xff))
    local btn_tip5_0 = CCSprite:create()
    btn_tip5_0:setContentSize(tip5:getContentSize())
    tip5:setPosition(CCPoint(btn_tip5_0:getContentSize().width/2, btn_tip5_0:getContentSize().height/2))
    btn_tip5_0:addChild(tip5)
    local btn_tip5 = CCMenuItemSprite:create(btn_tip5_0, nil)
    btn_tip5:setPosition(CCPoint(800+10, 40))
    local btn_tip5_menu = CCMenu:createWithItem(btn_tip5)
    btn_tip5_menu:setPosition(CCPoint(0, 0))
    bg:addChild(btn_tip5_menu)
    btn_tip5:registerScriptTapHandler(function()
        audio.play(audio.button)
        print("click tip5")
        layer:addChild(require("ui.shop.payment").create(), 1000)
    end)

    local function backEvent()
        layer:removeFromParent()
    end
    local btnBackSprite = img.createUISprite(img.ui.back)
    local btnBack = SpineMenuItem:create(json.ui.button, btnBackSprite)
    btnBack:setScale(view.minScale)
    btnBack:setPosition(scalep(35, 546))
    local menuBack = CCMenu:createWithItem(btnBack)
    menuBack:setPosition(0, 0)
    layer:addChild(menuBack, 10)
    btnBack:registerScriptTapHandler(function()
        backEvent()
    end)

    addBackEvent(layer)
    function layer.onAndroidBack()
        backEvent()
    end
    local function onEnter()
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
