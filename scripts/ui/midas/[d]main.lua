local ui = {}

require "common.func"
require "common.const"

local view = require "common.view"
local img = require "res.img"
local json = require "res.json"
local lbl = require "res.lbl"
local audio = require "res.audio"
local i18n = require "res.i18n"
local player = require "data.player"
local midas = require "data.midas"
local bag = require "data.bag"
local cfgmidas = require "config.midas"
local cfgvip = require "config.vip"
local net = require "net.netClient"
local tipsitem = require "ui.tips.item"
local cui = require "ui.custom"

local MIDASTIME = 60*60*8 - 600

local function createPopupPieceBatchSummonResult(type, id, count)
    local params = {}
    params.title = i18n.global.reward_will_get.string
    params.btn_count = 0

    local dialog = require("ui.dialog").create(params) 

    local back = img.createLogin9Sprite(img.login.button_9_small_gold)
    back:setPreferredSize(CCSize(153, 50))
    local comfirlab = lbl.createFont1(22, i18n.global.summon_comfirm.string, lbl.buttonColor)
    comfirlab:setPosition(CCPoint(back:getContentSize().width/2,
                                    back:getContentSize().height/2))
    back:addChild(comfirlab)
    local backBtn = SpineMenuItem:create(json.ui.button, back)
    backBtn:setPosition(CCPoint(dialog.board:getContentSize().width/2, 80))
    local menu = CCMenu:createWithItem(backBtn)
    menu:setPosition(0, 0)
    dialog.board:addChild(menu)

    dialog.board.tipsTag = false
    if type == "item" then
        local item = img.createItem(id, count)
        itemBtn = SpineMenuItem:create(json.ui.button, item)
        itemBtn:setScale(0.85)
        itemBtn:setPosition(dialog.board:getContentSize().width/2, 185)
        local iconMenu = CCMenu:createWithItem(itemBtn)
        iconMenu:setPosition(0, 0)
        dialog.board:addChild(iconMenu)

        itemBtn:registerScriptTapHandler(function()
            audio.play(audio.button)
            if dialog.board.tipsTag == false then
                dialog.board.tipsTag = true
                tips = tipsitem.createForShow({id = id, num = count})
                dialog:addChild(tips, 200)
                tips.setClickBlankHandler(function()
                    tips:removeFromParent()
                    dialog.board.tipsTag = false
                end)
            end
        end)
    else
        local equip = img.createEquip(id, count)
        equipBtn = SpineMenuItem:create(json.ui.button, equip)
        equipBtn:setScale(0.85)
        equipBtn:setPosition(dialog.board:getContentSize().width/2, 185)
        local iconMenu = CCMenu:createWithItem(equipBtn)
        iconMenu:setPosition(0, 0)
        dialog.board:addChild(iconMenu)

        equipBtn:registerScriptTapHandler(function()
            audio.play(audio.button)
            if dialog.board.tipsTag == false then
                dialog.board.tipsTag = true
                tips = tipsequip.createForShow({id = id})
                dialog:addChild(tips, 200)
                tips.setClickBlankHandler(function()
                    tips:removeFromParent()
                    dialog.board.tipsTag = false
                end)
            end
        end)
    end
    backBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        dialog:removeFromParentAndCleanup()
    end)
    return dialog
end

function ui.create(uiParams)
    local layer = CCLayer:create()
    -- 是否可以点金
    local currentMidas = true
    
    --dark bg
    local darkbg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    layer:addChild(darkbg)

    -- board
    local board_w = 704
    local board_h = 370
    
    local board = img.createUI9Sprite(img.ui.midas_titlebg)
    board:setPreferredSize(CCSizeMake(board_w, board_h))
    board:setScale(view.minScale)
    board:setPosition(view.midX, view.midY)
    layer:addChild(board)
    
    json.load(json.ui.dianjin)
    local animMidas = DHSkeletonAnimation:createWithKey(json.ui.dianjin)
    animMidas:scheduleUpdateLua()
    animMidas:playAnimation("animation")
    animMidas:setPosition(board_w/2, board_h/2)
    board:addChild(animMidas, 1000)

    -- board anim
    board:setScale(0.1 * view.minScale)
    board:runAction(CCEaseBackOut:create(CCScaleTo:create(0.3, view.minScale)))

    --person
    -- local personAni = img.createUISprite(img.ui.midas_person)
    -- personAni:setPosition(230-130,453-295)
    -- board:addChild(personAni)

    json.load(json.ui.dianjin2)
    local personAni = json.create(json.ui.dianjin2)
    --personAni:setPosition(230-130,453-295)
    personAni:setPosition(0,0)
    personAni:playAnimation("animation",-1)
    board:addChild(personAni)

    -- title
    local titleLab = lbl.createFont1(28, i18n.global.midas_golden_hand.string, ccc3(0xff, 0xdc, 0x87))
    titleLab:setAnchorPoint(0, 0.5)
    titleLab:setPosition(310-130, 454-126)
    board:addChild(titleLab)

    -- bottom border
    local border1 = img.createUI9Sprite(img.ui.midas_icon_bottom1)
    border1:setPreferredSize(CCSizeMake(154, 186))
    border1:setAnchorPoint(0, 0)
    border1:setPosition(CCPoint(310-128, 454 - 374))
    board:addChild(border1)
    local border2 = img.createUI9Sprite(img.ui.midas_icon_bottom1)
    border2:setPreferredSize(CCSizeMake(154, 186))
    border2:setAnchorPoint(0, 0)
    border2:setPosition(CCPoint(475-128, 454 - 374))
    board:addChild(border2)
    local border3 = img.createUI9Sprite(img.ui.midas_icon_bottom1)
    border3:setPreferredSize(CCSizeMake(154, 186))
    border3:setAnchorPoint(0, 0)
    border3:setPosition(CCPoint(640-128, 454 - 374))
    board:addChild(border3)

    local coinFram1 = img.createUISprite(img.ui.midas_icon_bottom2)
    coinFram1:setPosition(border1:getContentSize().width/2, 105)
    border1:addChild(coinFram1)
    local coinFram2 = img.createUISprite(img.ui.midas_icon_bottom2)
    coinFram2:setPosition(border2:getContentSize().width/2, 105)
    border2:addChild(coinFram2)
    local coinFram3 = img.createUISprite(img.ui.midas_icon_bottom2)
    coinFram3:setPosition(border3:getContentSize().width/2, 105)
    border3:addChild(coinFram3)
  
    -- get btn
    local getBtn0 = img.createLogin9Sprite(img.login.button_9_small_gold)
    -- coin icons
    local coinIcon1 = img.createUISprite(img.ui.midas_icon_1)
    coinIcon1:setPosition(coinFram1:getContentSize().width/2, 70)
    coinFram1:addChild(coinIcon1)
    local coinIcon2 = img.createUISprite(img.ui.midas_icon_2)
    coinIcon2:setPosition(coinFram2:getContentSize().width/2, 70)
    coinFram2:addChild(coinIcon2)
    local coinIcon3 = img.createUISprite(img.ui.midas_icon_3)
    coinIcon3:setPosition(coinFram3:getContentSize().width/2, 70)
    coinFram3:addChild(coinIcon3)
  
    -- get btn
    local getBtn0 = img.createLogin9Sprite(img.login.button_9_small_gold)
    local getBtn1 = img.createLogin9Sprite(img.login.button_9_small_grey)
    getBtn0:setPreferredSize(CCSizeMake(122, 48))
    getBtn1:setPreferredSize(CCSizeMake(122, 48))

    local btnLevel1 = CCMenuItemSprite:create(getBtn0, nil, getBtn1) 
    btnLevel1:setPosition(border1:getContentSize().width/2, 0)
    if midas.kind[1] == 1 then
        btnLevel1:setEnabled(false)
    end
    local btnMenuLevel1 = CCMenu:createWithItem(btnLevel1)
    btnMenuLevel1:setPosition(0, 0)
    border1:addChild(btnMenuLevel1)

    local level2getBtn0 = img.createLogin9Sprite(img.login.button_9_small_gold)
    local level2getBtn1 = img.createLogin9Sprite(img.login.button_9_small_grey)
    level2getBtn0:setPreferredSize(CCSizeMake(122, 48))
    level2getBtn1:setPreferredSize(CCSizeMake(122, 48))
    local btnLevel2 = CCMenuItemSprite:create(level2getBtn0, nil, level2getBtn1)
    btnLevel2:setPosition(border2:getContentSize().width/2, 0)
    if midas.kind[2] == 1 then
        btnLevel2:setEnabled(false)
    end
    local btnMenuLevel2 = CCMenu:createWithItem(btnLevel2)
    btnMenuLevel2:setPosition(0, 0)
    border2:addChild(btnMenuLevel2)
    
    local level3getBtn0 = img.createLogin9Sprite(img.login.button_9_small_gold)
    local level3getBtn1 = img.createLogin9Sprite(img.login.button_9_small_grey)
    level3getBtn0:setPreferredSize(CCSizeMake(122, 48))
    level3getBtn1:setPreferredSize(CCSizeMake(122, 48))
    local btnLevel3 = CCMenuItemSprite:create(level3getBtn0, nil, level3getBtn1) 
    btnLevel3:setPosition(border3:getContentSize().width/2, 0)
    if midas.kind[3] == 1 then
        btnLevel3:setEnabled(false)
    end
    local btnMenuLevel3 = CCMenu:createWithItem(btnLevel3)
    btnMenuLevel3:setPosition(0, 0)
    border3:addChild(btnMenuLevel3)
    
    --gem
    local lightGem2 = img.createItemIcon2(ITEM_ID_GEM)
    lightGem2:setScale(0.68)
    lightGem2:setPosition(btnLevel2:getContentSize().width/3-10, btnLevel2:getContentSize().height/2+2)
    lightGem2:setVisible(midas.kind[2] == 0)
    btnLevel2:addChild(lightGem2)
    local lightGem3 = img.createItemIcon2(ITEM_ID_GEM)
    lightGem3:setScale(0.68)
    lightGem3:setPosition(btnLevel3:getContentSize().width/3-10, btnLevel3:getContentSize().height/2+2)
    lightGem3:setVisible(midas.kind[3] == 0)
    btnLevel3:addChild(lightGem3)
    
    local greyGem2 = img.createUISprite(img.ui.midas_diamond_gray)
    greyGem2:setPosition(btnLevel2:getContentSize().width/3-15, btnLevel2:getContentSize().height/2+4)
    greyGem2:setVisible(midas.kind[2] == 1)
    btnLevel2:addChild(greyGem2)
    local greyGem3 = img.createUISprite(img.ui.midas_diamond_gray)
    greyGem3:setPosition(btnLevel3:getContentSize().width/3-15, btnLevel3:getContentSize().height/2+4)
    greyGem3:setVisible(midas.kind[3] == 1)
    btnLevel3:addChild(greyGem3)
   
    -- gold label
    local level = player.lv()
    local goldStr1 = string.format("%d", cfgmidas[level].gold*(1+cfgvip[player.vipLv()].midas))
    local goldLabel1 = lbl.createFont2(18, goldStr1, ccc3(255, 246, 223))
    goldLabel1:setPosition(coinFram1:getContentSize().width/2, 28)
    coinFram1:addChild(goldLabel1)
    local goldStr2 = string.format("%d", 2*cfgmidas[level].gold*(1+cfgvip[player.vipLv()].midas))
    local goldLabel2 = lbl.createFont2(18, goldStr2, ccc3(255, 246, 223))
    goldLabel2:setPosition(coinFram2:getContentSize().width/2, 28)
    coinFram2:addChild(goldLabel2)
    local goldStr3 = string.format("%d", 5*cfgmidas[level].gold*(1+cfgvip[player.vipLv()].midas))
    local goldLabel3 = lbl.createFont2(18, goldStr3, ccc3(255, 246, 223))
    goldLabel3:setPosition(coinFram3:getContentSize().width/2, 28)
    coinFram3:addChild(goldLabel3)

    -- gem label
    local gemLabel1 = lbl.createFont1(16, i18n.global.midas_free_get.string, ccc3(0x7e, 0x2f, 0x1c))
    gemLabel1:setPosition(btnLevel1:getContentSize().width/2, btnLevel1:getContentSize().height/2)
    if midas.kind[1] == 1 then
        gemLabel1:setColor(ccc3(0x3c, 0x3c, 0x3c))
    end
    btnLevel1:addChild(gemLabel1)
    local gemLabel2 = lbl.createFont1(16, i18n.global.midas_get.string, ccc3(0x7e, 0x2f, 0x1c))
    gemLabel2:setPosition(greyGem2:getBoundingBox():getMaxX()+43, btnLevel2:getContentSize().height/2)
    if midas.kind[2] == 1 then
        gemLabel2:setColor(ccc3(0x3c, 0x3c, 0x3c))
    end
    btnLevel2:addChild(gemLabel2)
    local gemLabel3 = lbl.createFont1(16, i18n.global.midas_get.string, ccc3(0x7e, 0x2f, 0x1c))
    gemLabel3:setPosition(greyGem3:getBoundingBox():getMaxX()+43, btnLevel3:getContentSize().height/2)
    if midas.kind[3] == 1 then
        gemLabel3:setColor(ccc3(0x3c, 0x3c, 0x3c))
    end
    btnLevel3:addChild(gemLabel3)

    local gemnumLabel2 = lbl.createFont2(14, "20", ccc3(255, 246, 225))
    gemnumLabel2:setPosition(btnLevel2:getContentSize().width/3-15, btnLevel2:getContentSize().height/2-6)
    btnLevel2:addChild(gemnumLabel2)
    local gemnumLabel3 = lbl.createFont2(14, "50", ccc3(255, 246, 225))
    gemnumLabel3:setPosition(btnLevel3:getContentSize().width/3-15, btnLevel3:getContentSize().height/2-6)
    btnLevel3:addChild(gemnumLabel3)

    local midasInfo = lbl.createFont2(16, i18n.global.midas_info.string, ccc3(255, 246, 225))
    midasInfo:setAnchorPoint(0, 0.5)
    midasInfo:setPosition(CCPoint(312-130, 453-158))
    midasInfo:setVisible(false)
    board:addChild(midasInfo)

    json.load(json.ui.clock)
    local clockIcon = DHSkeletonAnimation:createWithKey(json.ui.clock)
    clockIcon:scheduleUpdateLua()
    clockIcon:playAnimation("animation", -1)
    clockIcon:setPosition(325-130, 453-163)
    board:addChild(clockIcon)
    
    -- to free label
    local toFreeLab = lbl.createMixFont2(16, i18n.global.blackmarket_refresh.string, ccc3(255, 246, 225))
    toFreeLab:setAnchorPoint(0, 0.5)
    toFreeLab:setPosition(clockIcon:getBoundingBox():getMaxX()+30, 453-163)
    toFreeLab:setVisible(currentMidas == false)
    board:addChild(toFreeLab)

    -- midas cd
    local midasCd = math.max(0, midas.cd - os.time())
    local countTimeInfoStr =  string.format("%02d:%02d:%02d",math.floor(midasCd/3600),math.floor((midasCd%3600)/60),math.floor(midasCd%60))            
    local countTimeInfo = lbl.createFont2(16, countTimeInfoStr, ccc3(0xc4, 0xff, 0x24))
    countTimeInfo:setAnchorPoint(0, 0.5)
    countTimeInfo:setPosition(toFreeLab:getBoundingBox():getMaxX()+10, 453-163)
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
       
        clockIcon:setVisible(currentMidas == false)
        countTimeInfo:setVisible(currentMidas == false)
        toFreeLab:setVisible(currentMidas == false)

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
        midasCd = math.max(0, midas.cd - os.time())
        if midasCd > 0 then
            currentMidas = false
            --showMidas()
            local countTimeInfoStr =  string.format("%02d:%02d:%02d",math.floor(midasCd/3600),math.floor((midasCd%3600)/60),math.floor(midasCd%60))            
            countTimeInfo:setString(countTimeInfoStr)
            midasInfo:setVisible(false)

            clockIcon:setVisible(currentMidas == false)
            countTimeInfo:setVisible(currentMidas == false)
            toFreeLab:setVisible(currentMidas == false)
        else
            currentMidas = true
            showMidas()
            midasInfo:setVisible(true)
        end
    end

    layer:scheduleUpdateWithPriorityLua(onUpdate,0)
    
    btnLevel1:registerScriptTapHandler(function()
        audio.play(audio.button)
        midas.eimit = os.time() + MIDASTIME  
        currentMidas = false
        local param = {}
        param.sid = player.sid
        param.type = 1
        addWaitNet()
        net:midas(param, function(__data)
            delWaitNet()
            tbl2string(__data)
            if __data.status ~= 0 then
                showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                return
            end
            local coinNum = cfgmidas[level].gold*(1+cfgvip[player.vipLv()].midas)
            local midascd = math.max(0, midas.cd - os.time())
            if midascd <= 0 then
                midas.cd = os.time() + MIDASTIME
            end
            bag.addCoin(coinNum) 
            --local pop = createPopupPieceBatchSummonResult("item", ITEM_ID_COIN, coinNum)
            --layer:addChild(pop, 100)
			cui.showFloatRewardSingle(1, ITEM_ID_COIN, coinNum)
            midas.kind[1] = 1
            btnLevel1:setEnabled(false)
            gemLabel1:setColor(ccc3(0x3c, 0x3c, 0x3c))
            local task = require "data.task"
            task.increment(task.TaskType.MIDAS)
        end)
    end)

    btnLevel2:registerScriptTapHandler(function()
        audio.play(audio.button)
        if bag.gem() < 20 then
            showToast(i18n.global.summon_gem_lack.string)
            return
        end
        currentMidas = false
        local param = {}
        param.sid = player.sid
        param.type = 2
        addWaitNet()
        net:midas(param, function(__data)
            delWaitNet()
            tbl2string(__data)
            if __data.status ~= 0 then
                showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                return
            end
            local midascd = math.max(0, midas.cd - os.time())
            if midascd <= 0 then
                midas.cd = os.time() + MIDASTIME
            end
            local coinNum = cfgmidas[level].gold*2*(1+cfgvip[player.vipLv()].midas)
            bag.addCoin(coinNum)
            bag.subGem(20)
            --local pop = createPopupPieceBatchSummonResult("item", ITEM_ID_COIN, coinNum)
            --layer:addChild(pop, 100)
			cui.showFloatRewardSingle(1, ITEM_ID_COIN, coinNum)
            midas.kind[2] = 1
            btnLevel2:setEnabled(false)
            gemLabel2:setColor(ccc3(0x3c, 0x3c, 0x3c))
            lightGem2:setVisible(false)
            greyGem2:setVisible(true)
            local task = require "data.task"
            task.increment(task.TaskType.MIDAS)
        end)
    end)
    
    btnLevel3:registerScriptTapHandler(function()
        audio.play(audio.button)
        if bag.gem() < 50 then
            showToast(i18n.global.summon_gem_lack.string)
            return
        end
        currentMidas = false
        local param = {}
        param.sid = player.sid
        param.type = 3
        addWaitNet()
        net:midas(param, function(__data)
            delWaitNet()
            tbl2string(__data)
            if __data.status ~= 0 then
                showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                return
            end
            local midascd = math.max(0, midas.cd - os.time())
            if midascd <= 0 then
                midas.cd = os.time() + MIDASTIME
            end
            local coinNum = cfgmidas[level].gold*5*(1+cfgvip[player.vipLv()].midas)
            bag.addCoin(coinNum)
            bag.subGem(50)
            --local pop = createPopupPieceBatchSummonResult("item", ITEM_ID_COIN, coinNum)
            --layer:addChild(pop, 100)
			cui.showFloatRewardSingle(1, ITEM_ID_COIN, coinNum)
            midas.kind[3] = 1
            btnLevel3:setEnabled(false)
            gemLabel3:setColor(ccc3(0x3c, 0x3c, 0x3c))
            lightGem3:setVisible(false)
            greyGem3:setVisible(true)
            local task = require "data.task"
            task.increment(task.TaskType.MIDAS)
        end)
    end)

    local function backEvent()
        audio.play(audio.button)
        if uiParams and uiParams.from_layer == "task" then
            replaceScene(require("ui.town.main").create({from_layer="task"}))  
        else
            layer:removeFromParentAndCleanup()
        end
    end
    -- close btn
    local close0 = img.createUISprite(img.ui.close)
    local closeBtn = SpineMenuItem:create(json.ui.button, close0)
    closeBtn:setPosition(CCPoint(813 - 130, 456-110))
    local closeMenu = CCMenu:createWithItem(closeBtn)
    closeMenu:setPosition(CCPoint(0, 0))
    board:addChild(closeMenu)
    closeBtn:registerScriptTapHandler(function()     
        backEvent()
    end)

    function layer.onAndroidBack()
        backEvent()
    end

    addBackEvent(layer)

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
    
    return layer
end

return ui
