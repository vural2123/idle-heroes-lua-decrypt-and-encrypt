local ui = {}

require "common.func"

local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local audio = require "res.audio"
local i18n = require "res.i18n"
local order = require "ui.guildmill.order"
local upgrade = require "ui.guildmill.upgrade"
local harry = require "ui.guildmill.harry"
local drank = require "ui.guildmill.drank"
local guildmill = require "data.guildmill"
local player = require "data.player"
local net = require "net.netClient"

local TAB = {
    ORDER = 1,
    UPGRADE = 2,
    DRANK = 3,
}

local currentmillTab = TAB.ORDER

local titles = {
    [TAB.ORDER] = i18n.global.friend_friend_list.global,
    [TAB.UPGRADE] = i18n.global.friend_friend_apply.global,
    [TAB.DRANK] = i18n.global.friend_apply_list.global,
}

function ui.create(tab)
    local layer = CCLayerColor:create(ccc4(0,0,0,POPUP_DARK_OPACITY))

    currentmillTab = TAB.ORDER
    if tab then
        currentmillTab = tab
    end

    img.load(img.packedOthers.spine_ui_mofang)
    -- board
    local board_w = 718
    local board_h = 520

    local board = img.createUI9Sprite(img.ui.dialog_1)
    board:setPreferredSize(CCSizeMake(board_w, board_h))
    board:setScale(view.minScale)
    board:setPosition(view.physical.w/2, view.physical.h/2)
    layer:addChild(board)

    -- anim
    board:setScale(0.5*view.minScale)
    board:runAction(CCScaleTo:create(0.15, 1*view.minScale, 1*view.minScale))

    local bottom = img.createUI9Sprite(img.ui.bag_btn_inner_bg)
    bottom:setPreferredSize(CCSizeMake(660, 422))
    bottom:setAnchorPoint(0, 0)
    bottom:setPosition(CCPoint(184-156, 545-516))
    board:addChild(bottom)

    local milllayer = nil
    local function initlayer()
        milllayer:removeFromParentAndCleanup(true)
        milllayer = nil
    end

    --local initFlag = false
    local function showmill()
        if milllayer then 
            initlayer()
            --initFlag = true
        end
        
        if currentmillTab == TAB.ORDER then
            milllayer = order.create() 
            board:addChild(milllayer, 1000)
        elseif currentmillTab == TAB.UPGRADE then
            milllayer = upgrade.create() 
            board:addChild(milllayer, 1000)
        else 
            --if initFlag == true then
            --    milllayer = drank.create() 
            --    board:addChild(milllayer, 1000)
            --    return
            --end
            --local param = {}
            --param.sid = player.sid

            --addWaitNet()
            --net:gmill_sync(param, function(__data)
            --    delWaitNet()
            --    tbl2string(__data)
            --    guildmill.initorder(__data)
                milllayer = drank.create() 
                board:addChild(milllayer, 1000)
            --end)

        end
        
    end

    -- order tab
    local orderTab0 = img.createUISprite(img.ui.guild_mill_order_0)
    local orderTab1 = img.createUISprite(img.ui.guild_mill_order_1)
    
    local orderTab = CCMenuItemSprite:create(orderTab0 ,nil , orderTab1)
    orderTab:setAnchorPoint(0, 0)
    orderTab:setPosition(CCPoint(746-188+126, 545 - 212))
    orderTab:setEnabled(currentmillTab ~= TAB.ORDER)

    local orderMenu = CCMenu:createWithItem(orderTab)
    orderMenu:setPosition(0 ,0)
    board:addChild(orderMenu, 1003)

    -- upgrade tab
    local upgradeTab0 = img.createUISprite(img.ui.guild_mill_upgrade_0)
    local upgradeTab1 = img.createUISprite(img.ui.guild_mill_upgrade_1)
    
    local upgradeTab = CCMenuItemSprite:create(upgradeTab0 ,nil ,upgradeTab1)
    upgradeTab:setAnchorPoint(0, 0)
    upgradeTab:setPosition(CCPoint(746-188+126, 545 - 304))
    upgradeTab:setEnabled(currentmillTab ~= TAB.UPGRADE)
    local upgradeMenu = CCMenu:createWithItem(upgradeTab)
    upgradeMenu:setPosition(0 ,0)
    board:addChild(upgradeMenu, 1003)

    -- harry tab
    local harryTab0 = img.createUISprite(img.ui.guild_mill_drank_0)
    local harryTab1 = img.createUISprite(img.ui.guild_mill_drank_1)
    
    local harryTab = CCMenuItemSprite:create(harryTab0 ,nil , harryTab1)
    harryTab:setAnchorPoint(0, 0)
    harryTab:setPosition(CCPoint(746-188+126, 545 - 396))
    harryTab:setEnabled(currentmillTab ~= TAB.DRANK)
    local harryMenu = CCMenu:createWithItem(harryTab)
    harryMenu:setPosition(0 ,0)
    board:addChild(harryMenu, 1003)
    
    local function setTabstatus()
        orderTab:setEnabled(currentmillTab ~= TAB.ORDER)
        upgradeTab:setEnabled(currentmillTab ~= TAB.UPGRADE)
        harryTab:setEnabled(currentmillTab ~= TAB.DRANK)
    end

    orderTab:registerScriptTapHandler(function()
        audio.play(audio.button)
        currentmillTab = TAB.ORDER
        setTabstatus()
        showmill()
    end)

    upgradeTab:registerScriptTapHandler(function()
        audio.play(audio.button)
        currentmillTab = TAB.UPGRADE
        setTabstatus()
        showmill()
    end)

    harryTab:registerScriptTapHandler(function()
        audio.play(audio.button)
        currentmillTab = TAB.DRANK
        setTabstatus()
        showmill()
    end)

    local function backEvent()
        audio.play(audio.button)
        layer:removeFromParentAndCleanup()
    end

    -- close btn
    local close0 = img.createUISprite(img.ui.close)
    local closeBtn = SpineMenuItem:create(json.ui.button, close0)
    closeBtn:setPosition(CCPoint(746+56-110, 545-50))
    local closeMenu = CCMenu:createWithItem(closeBtn)
    closeMenu:setPosition(CCPoint(0, 0))
    board:addChild(closeMenu)
    closeBtn:registerScriptTapHandler(function()     
        backEvent()
    end)

    layer:setTouchEnabled(true)
    
    function layer.onAndroidBack()
        backEvent()
    end

    addBackEvent(layer) 
    
    local function onEnter()
        layer.notifyParentLock()
        showmill()
    end

    local function onExit()
        layer.notifyParentUnlock()
    end
    
    layer:registerScriptHandler(function(event)
        if event == "enter" then 
            onEnter()
        elseif event == "exit" then
            onExit()
        elseif event == "cleanup" then
            img.unload(img.packedOthers.spine_ui_mofang)
        end
    end)

    return layer 
end

return ui
