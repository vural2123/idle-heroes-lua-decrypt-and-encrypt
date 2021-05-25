local ui = {}

require "common.func"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local audio = require "res.audio"
local i18n = require "res.i18n"
local net = require "net.netClient"
local player = require "data.player"
local bag = require "data.bag"
local datablackmarket = require "data.blackmarket"
local cfgblackmarket = require "config.blackmarket"
local cfgequip = require "config.equip"
local cfgitem = require "config.item"
local tipsequip = require "ui.tips.equip"
local tipsitem = require "ui.tips.item"
local midas = require "ui.midas.main"
local gemshop = require "ui.shop.main"

local MARKETTIME = 60*60*3
local REFRESHGEM = 20

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
        local itemBtn = SpineMenuItem:create(json.ui.button, item)
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

function ui.create()
    local layer = CCLayer:create() 
    local isBuy = {}
    local itemBg = {}

    local refresh = 0 
    local _stack = 0

    local setAlreadyBuy = nil
    local createItemWithPos = nil
    
    img.load(img.packedOthers.ui_blackmarket_bg)
    json.load(json.ui.heishi)
    local aniBlackmarket = DHSkeletonAnimation:createWithKey(json.ui.heishi)
    aniBlackmarket:setScale(view.minScale)
    aniBlackmarket:scheduleUpdateLua()
    aniBlackmarket:playAnimation("start")
    aniBlackmarket:registerAnimation("loop", -1)
    aniBlackmarket:setPosition(scalep(480, 288))
    layer:addChild(aniBlackmarket, 100)

    json.load(json.ui.heishishangren)
    local aniShangren = DHSkeletonAnimation:createWithKey(json.ui.heishishangren)
    aniShangren:scheduleUpdateLua()
    aniShangren:playAnimation("stand", -1)
    aniBlackmarket:addChildFollowSlot("code_shangren", aniShangren)

    schedule(layer, 1, function()
        aniBlackmarket:registerAnimation("loop2", -1) 
    end)

    -- bg
    local bg = img.createUISprite(img.ui.blackmarket_bg)
    bg:setScale(view.minScale)
    bg:setPosition(view.midX, view.midY)
    layer:addChild(bg)
    
    local tableLayer = CCLayer:create()
    tableLayer:setPosition(-480, -288)
    aniBlackmarket:addChildFollowSlot("code_icons", tableLayer)

    local showItemLayer = CCLayer:create()
    tableLayer:addChild(showItemLayer)

    local function createlist(aniFlag)
        showItemLayer:removeAllChildrenWithCleanup(true)
        for i=1,8 do
            if datablackmarket.goods[i].bought == 1 then
                isBuy[i] = true
            else
                isBuy[i] = false
            end
            itemBg[i] = createItemWithPos(datablackmarket.goods[i], i)

            if aniFlag then
                json.load(json.ui.ic_refresh)
                local aniRef = DHSkeletonAnimation:createWithKey(json.ui.ic_refresh)
                aniRef:scheduleUpdateLua()
                aniRef:playAnimation("animation")
                aniRef:setPosition(itemBg[i]:getContentSize().width/2, itemBg[i]:getContentSize().height/2)
                itemBg[i]:addChild(aniRef, 100)
            end
            if datablackmarket.goods[i].bought == 1 then    
                setAlreadyBuy(i)
            end
        end
    end
    
    -- 确认是否用钻石刷新
    local function createCostDiamond()
        local params = {}
        params.btn_count = 0
        params.body = string.format(i18n.global.blackmarket_sure.string, 20)
        local board_w = 474

        local dialoglayer = require("ui.dialog").create(params) 

        local btnYesSprite = img.createLogin9Sprite(img.login.button_9_small_gold)
        btnYesSprite:setPreferredSize(CCSize(153, 50))
        local btnYes = SpineMenuItem:create(json.ui.button, btnYesSprite)
        btnYes:setPosition(board_w/2+95, 100)
        local labYes = lbl.createFont1(18, i18n.global.board_confirm_yes.string, ccc3(0x73, 0x3b, 0x05))
        labYes:setPosition(btnYes:getContentSize().width/2, btnYes:getContentSize().height/2)
        btnYesSprite:addChild(labYes)
        local menuYes = CCMenu:create()
        menuYes:setPosition(0, 0)
        menuYes:addChild(btnYes)
        dialoglayer.board:addChild(menuYes)

        local btnNoSprite = img.createLogin9Sprite(img.login.button_9_small_gold)
        btnNoSprite:setPreferredSize(CCSize(153, 50))
        local btnNo = SpineMenuItem:create(json.ui.button, btnNoSprite)
        btnNo:setPosition(board_w/2-95, 100)
        local labNo = lbl.createFont1(18, i18n.global.board_confirm_no.string, ccc3(0x73, 0x3b, 0x05))
        labNo:setPosition(btnNo:getContentSize().width/2, btnNo:getContentSize().height/2)
        btnNoSprite:addChild(labNo)
        local menuNo = CCMenu:create()
        menuNo:setPosition(0, 0)
        menuNo:addChild(btnNo)
        dialoglayer.board:addChild(menuNo)

        
        btnYes:registerScriptTapHandler(function()
            dialoglayer:removeFromParentAndCleanup(true)
            local param = {}
            param.sid = player.sid
            param.type = 3
            param.gem = REFRESHGEM  
            addWaitNet()
            net:bmarket_pull(param, function(__data)
                tbl2string(__data) 
                delWaitNet()
                if __data.status ~= 0 then
                    showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                    return
                end
                bag.subGem(REFRESHGEM)
                datablackmarket.init(__data, true)
                createlist(true)
            end)
            audio.play(audio.button)
        end)
        btnNo:registerScriptTapHandler(function()
            dialoglayer:removeFromParentAndCleanup(true)
            audio.play(audio.button)
        end)

        local function backEvent()
            dialoglayer:removeFromParentAndCleanup(true)
        end

        function dialoglayer.onAndroidBack()
            backEvent()
        end

        addBackEvent(dialoglayer)
        
        local function onEnter()
            dialoglayer.notifyParentLock()
        end

        local function onExit()
            dialoglayer.notifyParentUnlock()
        end

        dialoglayer:registerScriptHandler(function(event) 
            if event == "enter" then 
                onEnter()
            elseif event == "exit" then
                onExit()
            end
        end)
        return dialoglayer
    end
    
    local function createSurebuy(iteminfo, buyBtn, cost, pos)
        local params = {}
        params.btn_count = 0
        params.body = string.format(i18n.global.blackmarket_buy_sure.string, 20)
        local board_w = 474

        local dialoglayer = require("ui.dialog").create(params) 

        local btnYesSprite = img.createLogin9Sprite(img.login.button_9_small_gold)
        btnYesSprite:setPreferredSize(CCSize(153, 50))
        local btnYes = SpineMenuItem:create(json.ui.button, btnYesSprite)
        btnYes:setPosition(board_w/2+95, 100)
        local labYes = lbl.createFont1(18, i18n.global.board_confirm_yes.string, ccc3(0x73, 0x3b, 0x05))
        labYes:setPosition(btnYes:getContentSize().width/2, btnYes:getContentSize().height/2)
        btnYesSprite:addChild(labYes)
        local menuYes = CCMenu:create()
        menuYes:setPosition(0, 0)
        menuYes:addChild(btnYes)
        dialoglayer.board:addChild(menuYes)

        local btnNoSprite = img.createLogin9Sprite(img.login.button_9_small_gold)
        btnNoSprite:setPreferredSize(CCSize(153, 50))
        local btnNo = SpineMenuItem:create(json.ui.button, btnNoSprite)
        btnNo:setPosition(board_w/2-95, 100)
        local labNo = lbl.createFont1(18, i18n.global.board_confirm_no.string, ccc3(0x73, 0x3b, 0x05))
        labNo:setPosition(btnNo:getContentSize().width/2, btnNo:getContentSize().height/2)
        btnNoSprite:addChild(labNo)
        local menuNo = CCMenu:create()
        menuNo:setPosition(0, 0)
        menuNo:addChild(btnNo)
        dialoglayer.board:addChild(menuNo)

        btnYes:registerScriptTapHandler(function()
            dialoglayer:removeFromParentAndCleanup(true)
            local param = {}
            param.sid = player.sid
            param.index = pos
            param.type = cfgblackmarket[iteminfo.excel_id].cost.type     
            param.count = cfgblackmarket[iteminfo.excel_id].cost.count
           
            if param.type == 1 then
                if bag.coin() < cost then
                    showToast(i18n.global.blackmarket_coin_lack.string)
                    return
                end
            elseif param.type == 2 then
                if bag.gem() < cost then
                    showToast(i18n.global.summon_gem_lack.string)
                    return
                end
            else
                if bag.items.find(ITEM_ID_SMITH_CRYSTAL).num < cost then
                    showToast(i18n.global.blackmarket_essence_lack.string)
                    return 
                end
            end

            addWaitNet()
            net:bmarket_buy(param, function(__data)
                delWaitNet()
                tbl2string(__data)
                if __data.status ~= 0 then
                    showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                    return
                end

				require("ui.custom").showFloatReward(__data.bag)
                if __data.bag.equips then
                    bag.equips.addAll(__data.bag.equips)
                    --local pop = createPopupPieceBatchSummonResult("equip", iteminfo.id, iteminfo.count)
                    --layer:addChild(pop, 100)
                end
                if __data.bag.items then
                    bag.items.addAll(__data.bag.items)
                    --local pop = createPopupPieceBatchSummonResult("item", iteminfo.id, iteminfo.count)
                    --layer:addChild(pop, 100)
                end
                setShader(buyBtn, SHADER_GRAY, true)
                buyBtn:setEnabled(false)
                if param.type == 1 then
                    bag.subCoin(cost)
                elseif param.type == 2 then
                    bag.subGem(cost)
                else
                    bag.items.sub({id = ITEM_ID_SMITH_CRYSTAL, num = cost})
                end
                setAlreadyBuy(pos)
            end)
        end)
        btnNo:registerScriptTapHandler(function()
            dialoglayer:removeFromParentAndCleanup(true)
            audio.play(audio.button)
        end)

        local function diabackEvent()
            dialoglayer:removeFromParentAndCleanup(true)
        end

        function dialoglayer.onAndroidBack()
            diabackEvent()
        end

        addBackEvent(dialoglayer)
        
        local function onEnter()
            dialoglayer.notifyParentLock()
        end

        local function onExit()
            dialoglayer.notifyParentUnlock()
        end

        dialoglayer:registerScriptHandler(function(event) 
            if event == "enter" then 
                onEnter()
            elseif event == "exit" then
                onExit()
            end
        end)
        return dialoglayer
    end

    -- refresh btn
    local refreshSprite = img.createLogin9Sprite(img.login.button_9_small_green)
    refreshSprite:setPreferredSize(CCSizeMake(164, 54))
    local refreshBtn = SpineMenuItem:create(json.ui.button, refreshSprite)
    refreshBtn:setVisible(false)
    local refreshGem = img.createItemIcon2(ITEM_ID_GEM)
    refreshGem:setScale(0.9)
    refreshGem:setVisible(false)
    refreshGem:setPosition(30, refreshSprite:getContentSize().height/2+3)
    refreshSprite:addChild(refreshGem)

    local refreshGemlab = lbl.createFont2(16, string.format("%d", REFRESHGEM), ccc3(255, 246, 223))
    refreshGemlab:setPosition(refreshGem:getContentSize().width/2, 0) 
    refreshGem:addChild(refreshGemlab)

    local refreshlab = lbl.createFont1(20, i18n.global.blackmarket_refresh.string, ccc3(0x1d, 0x67, 0x00))
    refreshlab:setPosition(CCPoint(refreshSprite:getContentSize().width*3/5, refreshSprite:getContentSize().height/2))
    refreshSprite:addChild(refreshlab)
    refreshlab:setVisible(false)
    refreshBtn:setAnchorPoint(CCPoint(0, 0))
    refreshBtn:setPosition(663, 576-244)
    local refreshMenu = CCMenu:createWithItem(refreshBtn)
    refreshMenu:setPosition(0, 0)
    tableLayer:addChild(refreshMenu)
    refreshBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        local param = {}
        param.sid = player.sid
        if _stack > 0 then
            param.type = 2
        else
            if bag.gem() < REFRESHGEM then
                showToast(i18n.global.summon_gem_lack.string)
                return
            else
                local dialog = createCostDiamond()
                layer:addChild(dialog, 300)
                return 
            end
        end
        addWaitNet()
        net:bmarket_pull(param, function(__data)
            delWaitNet()
            tbl2string(__data) 
            if __data.status ~= 0 then
                showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                return
            end
            datablackmarket.init(__data, true)
            createlist(true)
        end)
    end)

    function setAlreadyBuy(pos)
        setShader(itemBg[pos], SHADER_GRAY, true)
        itemBg[pos]:setEnabled(false)
        local soldout = img.createUISprite(img.ui.blackmarket_soldout)
        --soldout:setAnchorPoint(0, 0)
        soldout:setPosition(CCPoint(itemBg[pos]:getContentSize().width/2, itemBg[pos]:getContentSize().height/2))
        itemBg[pos]:addChild(soldout)
    end

    local ITEM_POS = { 
        [1] = { 252, 256 }, [2] = { 402, 256 }, [3] = { 552, 256 }, [4] = { 702, 256 }, 
        [5] = { 252, 120 }, [6] = { 402, 120 }, [7] = { 552, 120 }, [8] = { 702, 120 },
    }

    function createItemWithPos(iteminfo, pos)
        local item = nil
        local icon = nil
        local cost = nil

        local menuBg = CCMenu:create()
        menuBg:setPosition(0, 0)
        showItemLayer:addChild(menuBg)
        if iteminfo.type == 1 then
            item = img.createItem(iteminfo.id, iteminfo.count)
        elseif iteminfo.type == 2 then
            item = img.createEquip(iteminfo.id, iteminfo.count)
        end
        local itemBg = SpineMenuItem:create(json.ui.button, item)
        itemBg:setScale(0.9)
        itemBg:setPosition(ITEM_POS[pos][1], ITEM_POS[pos][2])
        menuBg:addChild(itemBg)
 
        if cfgblackmarket[iteminfo.excel_id].cost.type == 1 then
            icon = img.createItemIcon2(ITEM_ID_COIN)
            cost = cfgblackmarket[iteminfo.excel_id].cost.count
        elseif cfgblackmarket[iteminfo.excel_id].cost.type == 2 then
            icon = img.createItemIcon2(ITEM_ID_GEM)
            cost = cfgblackmarket[iteminfo.excel_id].cost.count
        else
            icon = img.createItemIcon2(ITEM_ID_SMITH_CRYSTAL)
            cost = cfgblackmarket[iteminfo.excel_id].cost.count
        end

        local menuBuy = CCMenu:create()
        menuBuy:setPosition(0, 0)
        showItemLayer:addChild(menuBuy)
    
        local buyBtnSprite = img.createUISprite(img.ui.blackmarket_btn_buy)
        icon:setAnchorPoint(ccp(0, 0.5))
        icon:setScale(0.75)
        icon:setPosition(10, buyBtnSprite:getContentSize().height/2)
        buyBtnSprite:addChild(icon)

        local buyBtn = SpineMenuItem:create(json.ui.button, buyBtnSprite)
        --buyBtn:setScale(view.minScale)
        buyBtn:setPosition(ITEM_POS[pos][1], ITEM_POS[pos][2] - 65)
        buyBtn:setEnabled(isBuy[pos] == false)
        menuBuy:addChild(buyBtn)
        if isBuy[pos] then
            setShader(buyBtn, SHADER_GRAY, true)
        end

        local costLabel = lbl.createFont2(14, convertItemNum(cost), ccc3(255, 246, 223))
        local x = (buyBtn:getContentSize().width - icon:boundingBox():getMaxX())/2
        costLabel:setPosition(x + icon:boundingBox():getMaxX() - 5, buyBtnSprite:getContentSize().height/2 - 1)
        buyBtnSprite:addChild(costLabel)
        layer.tipsTag = false
        itemBg:registerScriptTapHandler(function()
            audio.play(audio.button)
            local tips = nil
            local pbdata = {}
            if layer.tipsTag == false then
                layer.tipsTag = true
                if iteminfo.type == 1 then
                    pbdata.id = iteminfo.id 
                    tips = tipsitem.createForShow(pbdata)
                elseif iteminfo.type == 2 then
                    pbdata.id = iteminfo.id 
                    tips = tipsequip.createForShow(pbdata)
                end
                layer:addChild(tips, 200)
                tips.setClickBlankHandler(function()
                    tips:removeFromParent()
                    layer.tipsTag = false
                end)
            end
        end)

        buyBtn:registerScriptTapHandler(function()
            audio.play(audio.button)
            local surebuy = createSurebuy(iteminfo, buyBtn, cost, pos)
            layer:addChild(surebuy, 300)
        end)
        return itemBg
    end
    
    --local refreshFirstLab = lbl.createFont1(18, i18n.global.blackmarket_refresh_first.string, ccc3(0x64, 0x31, 0x20))
    --refreshFirstLab:setPosition(150, 120)
    --refreshFirstLab:setVisible(false)
    --tableLayer:addChild(refreshFirstLab)
    --local clockIcon = img.createUISprite(img.ui.blackmarket_clock)
    --clockIcon:setPosition(678, 576-155)
    --clockIcon:setVisible(false)
    --tableLayer:addChild(clockIcon)
    json.load(json.ui.clock)
    local clockIcon = DHSkeletonAnimation:createWithKey(json.ui.clock)
    clockIcon:scheduleUpdateLua()
    clockIcon:playAnimation("animation", -1)
    clockIcon:setPosition(678, 576-155)
    clockIcon:setVisible(false)
    tableLayer:addChild(clockIcon, 100)

    local showTimeLab = lbl.createFont2(14, "", ccc3(0xa5, 0xfd, 0x47))
    showTimeLab:setAnchorPoint(0, 0.5)
    showTimeLab:setPosition(700, 576-155)
    tableLayer:addChild(showTimeLab)

    local refreshNextLab = lbl.createFont2(14, i18n.global.blackmarket_refresh_next.string, ccc3(255, 246, 223))
    refreshNextLab:setAnchorPoint(0, 0.5)
    refreshNextLab:setPosition(765, 576 - 154)
    refreshNextLab:setVisible(false)
    tableLayer:addChild(refreshNextLab)

    local initFlag = false
    local initRefresh = false

    local function onUpdate()
        if initRefresh == true then
            refreshBtn:setVisible(true)
            initRefresh = false
        end
        if initFlag == true then
            _stack = datablackmarket.stack or 0
            refresh = math.max(0, datablackmarket.refresh - os.time())
            if(_stack < 5) then
                local timeLab = string.format("%02d:%02d:%02d",math.floor(refresh/3600),math.floor((refresh%3600)/60),math.floor(refresh%60))
                showTimeLab:setString(timeLab)
                showTimeLab:setColor(ccc3(0xa5, 0xfd, 0x47))
                showTimeLab:setAnchorPoint(0, 0.5)
                showTimeLab:setPosition(700, 576-155)
                showTimeLab:setVisible(true)
                clockIcon:setVisible(true)
                refreshNextLab:setVisible(true)
            else
                showTimeLab:setVisible(false)
                clockIcon:setVisible(false)
                refreshNextLab:setVisible(false)
            end
            if(_stack > 0) then
                refreshGem:setVisible(false)
                refreshlab:setVisible(true)
                refreshlab:setPosition(CCPoint(refreshSprite:getContentSize().width/2, refreshSprite:getContentSize().height/2))
                refreshlab:setString(i18n.global.blackmarket_refresh.string .. string.format(" (%d)", _stack))
            else
                refreshGem:setVisible(true)
                refreshlab:setVisible(true)
                refreshlab:setPosition(CCPoint(refreshSprite:getContentSize().width*3/5, refreshSprite:getContentSize().height/2))
                refreshlab:setString(i18n.global.blackmarket_refresh.string)
            end
            if(needRefresh == false and _stack < 5 and refresh == 0) then
                needRefresh = true
                doRefreshing()
            end
        end
    end


    local function init()
        local param = {}
        param.sid = player.sid
        param.type = 1
        addWaitNet()
        net:bmarket_pull(param, function(__data)
            delWaitNet()
            tbl2string(__data)
            if __data.status ~= 0 then
                showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                return
            end
            datablackmarket.init(__data, true)
            createlist()
            refresh = math.max(0, datablackmarket.refresh - os.time())
            initFlag = true
            initRefresh = true
        end)

    end

    layer:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.02), CCCallFunc:create(init)))
    
    layer:scheduleUpdateWithPriorityLua(onUpdate, 0)

    -- table orn
    --local tableorn = img.createUISprite(img.ui.blackmarket_table_orn)
    --tableorn:setScale(view.minScale)
    --tableorn:setPosition(scalep(234, 576-245))
    --layer:addChild(tableorn)

    -- platfont
    --local platfont = img.createUISprite(img.ui.blackmarket_platfond)
    --platfont:setScale(view.minScale)
    --platfont:setAnchorPoint(CCPoint(0.5, 1))
    --platfont:setPosition(scalep(960/2, 576))
    --layer:addChild(platfont)

    --money bar
    local moneybar = require "ui.moneybar"
    layer:addChild(moneybar.create(), 100)
    
    -- back btn
    local back0 = img.createUISprite(img.ui.back)
    local backBtn = HHMenuItem:create(back0)
    backBtn:setScale(view.minScale)
    backBtn:setPosition(scalep(35, 546))
    local backMenu = CCMenu:createWithItem(backBtn)
    backMenu:setPosition(0, 0)
    layer:addChild(backMenu)
    local function backEvent()
        audio.play(audio.button)
        replaceScene(require("ui.town.main").create())  
    end
    backBtn:registerScriptTapHandler(function()
        backEvent()
    end)

    autoLayoutShift(backBtn)
    
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
        elseif event == "cleanup" then
            img.unload(img.packedOthers.ui_blackmarket_bg)
        end
    end)

    require("ui.tutorial").show("ui.bmarket.main", layer)
    
    return layer
end

return ui
