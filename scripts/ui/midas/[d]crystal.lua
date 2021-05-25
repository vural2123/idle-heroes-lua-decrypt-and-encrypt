local ui = {}

require "common.func"
require "common.const"

local view = require "common.view"
local img = require "res.img"
local json = require "res.json"
local lbl = require "res.lbl"
local audio = require "res.audio"
local player = require "data.player"
local midas = require "data.midas"
local bag = require "data.bag"
local cfgmidas = require "config.midas"
local net = require "net.netClient"

local MIDASTIME = 60*60*8 - 600

function ui.create()
    local layer = CCLayer:create()
    -- 是否可以点金
    local currentMidas = true
    
    --dark bg
    local darkbg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    layer:addChild(darkbg)

    -- board
    local board_w = 686
    local board_h = 528
    
    local board = img.createUI9Sprite(img.ui.bag_outer_bg)
    board:setPreferredSize(CCSizeMake(board_w, board_h))
    board:setScale(view.minScale)
    board:setPosition(view.midX, view.midY-20*view.minScale)
    layer:addChild(board)
    
    -- board anim
    board:setScale(0.1 * view.minScale)
    board:runAction(CCEaseBackOut:create(CCScaleTo:create(0.3, view.minScale)))

    -- title bg
    local titleBg = img.createUISprite(img.ui.midas_titlebg_crst)
    titleBg:setAnchorPoint(0, 0)
    titleBg:setPosition(CCPoint(10, 570-252))
    board:addChild(titleBg)

    -- bottom border
    local border1 = img.createUI9Sprite(img.ui.bottom_border_2)
    border1:setPreferredSize(CCSizeMake(620, 82))
    border1:setAnchorPoint(0, 0)
    border1:setPosition(CCPoint(32, 570 - 352))
    board:addChild(border1)
    local border2 = img.createUI9Sprite(img.ui.bottom_border_2)
    border2:setPreferredSize(CCSizeMake(620, 82))
    border2:setAnchorPoint(0, 0)
    border2:setPosition(CCPoint(32, 570 - 444))
    board:addChild(border2)
    local border3 = img.createUI9Sprite(img.ui.bottom_border_2)
    border3:setPreferredSize(CCSizeMake(620, 82))
    border3:setAnchorPoint(0, 0)
    border3:setPosition(CCPoint(32, 570 - 536))
    board:addChild(border3)

    -- coin icons
    local coinIcon1 = img.createUISprite(img.ui.midas_icon_4)
    coinIcon1:setPosition(CCPoint(78, 570 - 310))
    board:addChild(coinIcon1)
    local coinIcon2 = img.createUISprite(img.ui.midas_icon_5)
    coinIcon2:setPosition(CCPoint(78, 570 - 402))
    board:addChild(coinIcon2)
    local coinIcon3 = img.createUISprite(img.ui.midas_icon_6)
    coinIcon3:setPosition(CCPoint(78, 570 - 494))
    board:addChild(coinIcon3)
  
    -- get btn
    local getBtn0 = img.createUI9Sprite(img.ui.btn_2)
    local getBtn1 = img.createUI9Sprite(img.ui.btn_4)
    getBtn0:setPreferredSize(CCSizeMake(192, 48))
    getBtn1:setPreferredSize(CCSizeMake(192, 48))

    local btnLevel1 = CCMenuItemSprite:create(getBtn0, nil, getBtn1) 
    btnLevel1:setPosition(CCPoint(670-138, 570-312))
    btnLevel1:setEnabled(currentMidas)
    local btnMenuLevel1 = CCMenu:createWithItem(btnLevel1)
    btnMenuLevel1:setPosition(0, 0)
    board:addChild(btnMenuLevel1)

    local level2getBtn0 = img.createUI9Sprite(img.ui.btn_2)
    local level2getBtn1 = img.createUI9Sprite(img.ui.btn_4)
    level2getBtn0:setPreferredSize(CCSizeMake(192, 48))
    level2getBtn1:setPreferredSize(CCSizeMake(192, 48))
    local btnLevel2 = CCMenuItemSprite:create(level2getBtn0, nil, level2getBtn1)
    btnLevel2:setPosition(CCPoint(670-138, 570-402))
    btnLevel2:setEnabled(currentMidas)
    local btnMenuLevel2 = CCMenu:createWithItem(btnLevel2)
    btnMenuLevel2:setPosition(0, 0)
    board:addChild(btnMenuLevel2)
    
    local level3getBtn0 = img.createUI9Sprite(img.ui.btn_2)
    local level3getBtn1 = img.createUI9Sprite(img.ui.btn_4)
    level3getBtn0:setPreferredSize(CCSizeMake(192, 48))
    level3getBtn1:setPreferredSize(CCSizeMake(192, 48))
    local btnLevel3 = CCMenuItemSprite:create(level3getBtn0, nil, level3getBtn1) 
    btnLevel3:setPosition(CCPoint(670-138, 570-494))
    btnLevel3:setEnabled(currentMidas)
    local btnMenuLevel3 = CCMenu:createWithItem(btnLevel3)
    btnMenuLevel3:setPosition(0, 0)
    board:addChild(btnMenuLevel3)
    
    --gem
    local lightGem2 = img.createUISprite(img.ui.gem)
    lightGem2:setPosition(btnLevel2:getContentSize().width/3, btnLevel2:getContentSize().height/2)
    btnLevel2:addChild(lightGem2)
    local lightGem3 = img.createUISprite(img.ui.gem)
    lightGem3:setPosition(btnLevel3:getContentSize().width/3, btnLevel3:getContentSize().height/2)
    btnLevel3:addChild(lightGem3)
    
    local greyGem2 = img.createUISprite(img.ui.midas_diamond_gray)
    greyGem2:setPosition(btnLevel2:getContentSize().width/3, btnLevel2:getContentSize().height/2)
    btnLevel2:addChild(greyGem2)
    local greyGem3 = img.createUISprite(img.ui.midas_diamond_gray)
    greyGem3:setPosition(btnLevel3:getContentSize().width/3, btnLevel3:getContentSize().height/2)
    btnLevel3:addChild(greyGem3)
   
    -- gold label
    local level = player.lv()
    local goldStr1 = string.format("x%d", cfgmidas[level].crystal)
    local goldLabel1 = lbl.createFont1(24, goldStr1, ccc3(0x7e, 0x2f, 0x1c))
    goldLabel1:setAnchorPoint(0, 0.5)
    goldLabel1:setPosition(CCPoint(255-138, 570-314))
    board:addChild(goldLabel1)
    local goldStr2 = string.format("x%d", 2*cfgmidas[level].crystal)
    local goldLabel2 = lbl.createFont1(24, goldStr2, ccc3(0x7e, 0x2f, 0x1c))
    goldLabel2:setAnchorPoint(0, 0.5)
    goldLabel2:setPosition(CCPoint(255-138, 570-404))
    board:addChild(goldLabel2)
    local goldStr3 = string.format("x%d", 5*cfgmidas[level].crystal)
    local goldLabel3 = lbl.createFont1(24, goldStr3, ccc3(0x7e, 0x2f, 0x1c))
    goldLabel3:setAnchorPoint(0, 0.5)
    goldLabel3:setPosition(CCPoint(255-138, 570-496))
    board:addChild(goldLabel3)

    -- gem label
    local gemLabel1 = lbl.createFont1(24, "FREE GET", ccc3(0x7e, 0x2f, 0x1c))
    gemLabel1:setAnchorPoint(0, 0.5)
    gemLabel1:setPosition(CCPoint(630-138, 570-314))
    board:addChild(gemLabel1)
    local gemLabel2 = lbl.createFont1(24, "GET", ccc3(0x7e, 0x2f, 0x1c))
    gemLabel2:setAnchorPoint(0, 0.5)
    gemLabel2:setPosition(CCPoint(678-138, 570-404))
    board:addChild(gemLabel2)
    local gemLabel3 = lbl.createFont1(24, "GET", ccc3(0x7e, 0x2f, 0x1c))
    gemLabel3:setAnchorPoint(0, 0.5)
    gemLabel3:setPosition(CCPoint(678-138, 570-496))
    board:addChild(gemLabel3)

    local gemnumLabel2 = lbl.createFont1(16, "20", ccc3(0xff, 0xfe, 0xf5))
    gemnumLabel2:setPosition(CCPoint(648-138, 570-410))
    board:addChild(gemnumLabel2)
    local gemnumLabel3 = lbl.createFont1(16, "50", ccc3(0xff, 0xfe, 0xf5))
    gemnumLabel3:setPosition(CCPoint(648-138, 570-504))
    board:addChild(gemnumLabel3)
    
    -- clock
    local clock = img.createUISprite(img.ui.midas_clock)
    clock:setPosition(CCPoint(577-138, 570-104))
    clock:setVisible(currentMidas == false)
    board:addChild(clock)
    
    -- midas crstcd
    local midasCd = math.max(0, midas.crstcd - os.time())
    local countTimeInfoStr =  string.format("%02d:%02d:%02d",math.floor(midasCd/3600),math.floor((midasCd%3600)/60),math.floor(midasCd%60))            
    local countTimeInfo = lbl.createFont2(18, countTimeInfoStr, ccc3(0xc4, 0xff, 0x24))
    countTimeInfo:setPosition(637-138, 570-105)
    countTimeInfo:setVisible(currentMidas == false)
    board:addChild(countTimeInfo)
    
    local function showMidas()
        lightGem2:setVisible(currentMidas)
        lightGem3:setVisible(currentMidas)
        greyGem2:setVisible(currentMidas == false)
        greyGem3:setVisible(currentMidas == false)
        
        btnLevel1:setEnabled(currentMidas)
        btnLevel2:setEnabled(currentMidas)
        btnLevel3:setEnabled(currentMidas)
       
        clock:setVisible(currentMidas == false)
        countTimeInfo:setVisible(currentMidas == false)

        if currentMidas then
            gemLabel1:setColor(ccc3(0x7e, 0x2f, 0x1c))
            gemLabel2:setColor(ccc3(0x7e, 0x2f, 0x1c))
            gemLabel3:setColor(ccc3(0x7e, 0x2f, 0x1c))
        else
            gemLabel1:setColor(ccc3(0x3c, 0x3c, 0x3c))
            gemLabel2:setColor(ccc3(0x3c, 0x3c, 0x3c))
            gemLabel3:setColor(ccc3(0x3c, 0x3c, 0x3c))
        end
    end
   
    local function onUpdate()
        midasCd = math.max(0, midas.crstcd - os.time())
        if midasCd > 0 then
            currentMidas = false
            showMidas()
            local countTimeInfoStr =  string.format("%02d:%02d:%02d",math.floor(midasCd/3600),math.floor((midasCd%3600)/60),math.floor(midasCd%60))            
            countTimeInfo:setString(countTimeInfoStr)
        else
            currentMidas = true
            showMidas()
        end
    end

    layer:scheduleUpdateWithPriorityLua(onUpdate,0)
    
    btnLevel1:registerScriptTapHandler(function()
        midas.eimit = os.time() + MIDASTIME  
        currentMidas = false
        local param = {}
        param.sid = player.sid
        param.type = 4
        addWaitNet(function()
            delWaitNet()
            showToast("sever timeout")
        end)
        net:midas(param, function(__data)
            delWaitNet()
            if __data.status ~= 0 then
                showToast("server status:" .. __data.status)
                return
            end
            midas.crstcd = os.time() + MIDASTIME
            bag.items.add({id = ITEM_ID_ENCHANT, num = cfgmidas[level].crystal}) 
        end)
        showMidas()
    end)

    btnLevel2:registerScriptTapHandler(function()
        if bag.gem() < 20 then
            showToast("no enough gem!")
            return
        end
        midas.crstcd = os.time() + MIDASTIME  
        currentMidas = false
        local param = {}
        param.sid = player.sid
        param.type = 5
        addWaitNet(function()
            delWaitNet()
            showToast("sever timeout")
        end)
        net:midas(param, function(__data)
            delWaitNet()
            if __data.status ~= 0 then
                showToast("server status:" .. __data.status)
                return
            end
            midas.crstcd = os.time() + MIDASTIME
            bag.items.add({id = ITEM_ID_ENCHANT, num = cfgmidas[level].crystal*2})
            bag.subGem(20)
        end)
        showMidas()
    end)
    
    btnLevel3:registerScriptTapHandler(function()
        if bag.gem() < 50 then
            showToast("no enough gem!")
            return
        end
        midas.limit = os.time() + MIDASTIME  
        currentMidas = false
        local param = {}
        param.sid = player.sid
        param.type = 6
        addWaitNet(function()
            delWaitNet()
            showToast("sever timeout")
        end)
        net:midas(param, function(__data)
            delWaitNet()
            if __data.status ~= 0 then
                showToast("server status:" .. __data.status)
                return
            end
            midas.crstcd = os.time() + MIDASTIME
            bag.items.add({id = ITEM_ID_ENCHANT, num = cfgmidas[level].crystal*5})
            bag.subGem(50)
        end)
        showMidas()
    end)

    -- close btn
    local close0 = img.createUISprite(img.ui.close)
    local closeBtn = SpineMenuItem:create(json.ui.button, close0)
    closeBtn:setPosition(CCPoint(810 - 138, 500))
    local closeMenu = CCMenu:createWithItem(closeBtn)
    closeMenu:setPosition(CCPoint(0, 0))
    board:addChild(closeMenu)
    closeBtn:registerScriptTapHandler(function()     
        audio.play(audio.button)
        layer:removeFromParentAndCleanup()
    end)

    function layer.onAndroidBack()
        audio.play(audio.button)
        layer:removeFromParentAndCleanup(true)
    end

    addBackEvent(layer)

    local function onEnter()
        layer.notifyParentLock()
        showMidas()
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
    
    return layer
end

return ui
