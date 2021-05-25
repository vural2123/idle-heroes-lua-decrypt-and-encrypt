local ui = {}

require "common.func"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local i18n = require "res.i18n"
local audio = require "res.audio"
local net = require "net.netClient"
local player = require "data.player"
local bag = require "data.bag"
local dataheromarket = require "data.heromarket"
local cfgheromarket = require "config.heromarket"
local cfgequip = require "config.equip"
local cfgitem = require "config.item"
local tipsequip = require "ui.tips.equip"
local tipsitem = require "ui.tips.item"

local REFRESHLUCKY = 5000

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

function ui.create()
    local layer = CCLayerColor:create(ccc4(0,0,0,POPUP_DARK_OPACITY))

    local isBuy = {}
    local itemBg = {}

    local setAlreadyBuy = nil
    local createItemWithPos = nil
    local initFlag = false
    local addshowpage = false

    local currentPage = 1
    local cfgCount = 0
    for v,k in pairs(cfgheromarket) do 
        cfgCount = cfgCount + 1
    end
    local maxPage = math.floor((cfgCount-1)/8)+1

    -- bg
    local board = img.createUI9Sprite(img.ui.shop_board)
    board:setPreferredSize(CCSizeMake(838, 483))
    board:setScale(view.minScale)
    board:setPosition(view.midX, view.midY-20*view.minScale)
    layer:addChild(board)
    
    local boardtop = img.createUISprite(img.ui.casino_shop_top)
    boardtop:setPosition(415, 478)
    board:addChild(boardtop)

    -- board anim
    board:setScale(0.1 * view.minScale)
    board:runAction(CCEaseBackOut:create(CCScaleTo:create(0.3, view.minScale)))
    
    -- lucky coin bg
    local lCoinBg = img.createUI9Sprite(img.ui.main_coin_bg)
    lCoinBg:setPreferredSize(CCSizeMake(174, 40))
    lCoinBg:setPosition(480-68, 545-25)
    board:addChild(lCoinBg, 5)

    -- lucky coin icon
    local lcoinIcon = img.createItemIcon(ITEM_ID_RUNE_COIN)
    lcoinIcon:setScale(0.517)
    lcoinIcon:setPosition(CCPoint(5, lCoinBg:getContentSize().height/2+2))
    lCoinBg:addChild(lcoinIcon)

    -- lucky lbl coin
    local lCoin = bag.items.find(ITEM_ID_RUNE_COIN)
    local lCoinLab = lbl.createFont2(16, lCoin.num, ccc3(255, 246, 223))
    lCoinLab:setPosition(CCPoint(lCoinBg:getContentSize().width/2, lCoinBg:getContentSize().height/2+2))
    lCoinBg:addChild(lCoinLab)

    local showItemLayer = CCLayer:create()
    board:addChild(showItemLayer)

    local circlePos = {[1] = {405, 118}, [2] = {435, 118}, [3] = {465, 118}, [4] = {595, 118}}
    local function createlist(page)
        showItemLayer:removeAllChildrenWithCleanup(true)
        for i=(page-1)*8+1, page*8 do
            if i > #dataheromarket.goods then
                return 
            end
            if dataheromarket.goods[i].num >= cfgheromarket[dataheromarket.goods[i].id].limitNumb then
                isBuy[i] = true
            else
                isBuy[i] = false
            end
            --if cfgheromarket[i] then
                itemBg[i] = createItemWithPos(dataheromarket.goods[i], i)
            --end
            if dataheromarket.goods[i].num >= cfgheromarket[dataheromarket.goods[i].id].limitNumb then    
                setAlreadyBuy(i)
            end
        end
    end
    
    function setAlreadyBuy(pos)
        setShader(itemBg[pos], SHADER_GRAY, true)
        itemBg[pos]:setEnabled(false)
        local soldout = img.createUISprite(img.ui.blackmarket_soldout)
        --soldout:setAnchorPoint(0, 0)
        --soldout:setPosition(CCPoint(0, itemBg[pos]:getContentSize().height/2))
        soldout:setPosition(CCPoint(itemBg[pos]:getContentSize().width/2, itemBg[pos]:getContentSize().height/2))
        itemBg[pos]:addChild(soldout)
    end

    -- 确认是否刷新弹窗
    local function createCostDiamond()
        local params = {}
        params.btn_count = 0
        params.body = string.format(i18n.global.heroshop_ref_sure.string, REFRESHLUCKY)

        local dialoglayer = require("ui.dialog").create(params) 

        local btnYesSprite = img.createLogin9Sprite(img.login.button_9_small_gold)
        btnYesSprite:setPreferredSize(CCSize(153, 50))
        local btnYes = SpineMenuItem:create(json.ui.button, btnYesSprite)
        btnYes:setPosition(340, 100)
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
        btnNo:setPosition(150, 100)
        local labNo = lbl.createFont1(18, i18n.global.board_confirm_no.string, ccc3(0x73, 0x3b, 0x05))
        labNo:setPosition(btnNo:getContentSize().width/2, btnNo:getContentSize().height/2)
        btnNoSprite:addChild(labNo)
        local menuNo = CCMenu:create()
        menuNo:setPosition(0, 0)
        menuNo:addChild(btnNo)
        dialoglayer.board:addChild(menuNo)

        
        btnYes:registerScriptTapHandler(function()
            dialoglayer:removeFromParentAndCleanup(true)
            if bag.items.find(ITEM_ID_RUNE_COIN).num < REFRESHLUCKY then
               showToast(i18n.global.heromarket_soulstone_lack.string)
               return
            end

            local param = {}
            param.sid = player.sid
            addWaitNet()
            net:hmarket_refresh(param, function(__data)
                tbl2string(__data) 
                delWaitNet()
                if __data.status == -2 then
                    showToast(i18n.global.heromarket_soulstone_lack.string)
                    return
                end

                if __data.status ~= 0 then
                    showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                    return
                end

                bag.items.sub({id = ITEM_ID_RUNE_COIN, num = REFRESHLUCKY})
                lCoinLab:setString(bag.items.find(ITEM_ID_RUNE_COIN).num)
                dataheromarket.init(__data)
                createlist(currentPage)
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

    -- chat
    local chat = img.createLogin9Sprite(img.login.toast_bg)
    chat:setPreferredSize(CCSize(752, 70))
    chat:setAnchorPoint(CCPoint(0.5, 0))
    chat:setPosition(480-68, 545-514)
    board:addChild(chat)

    -- refresh btn
    local refreshSprite = img.createLogin9Sprite(img.login.button_9_small_green)
    refreshSprite:setPreferredSize(CCSize(160, 50))
    local refreshBtn = SpineMenuItem:create(json.ui.button, refreshSprite)
    local refreshlab = lbl.createFont1(18, i18n.global.blackmarket_refresh.string, ccc3(0x1d, 0x67, 0x00))
    refreshlab:setPosition(CCPoint(refreshSprite:getContentSize().width*3/5, refreshSprite:getContentSize().height/2))
    refreshSprite:addChild(refreshlab)
    refreshBtn:setAnchorPoint(CCPoint(0, 0.5))
    refreshBtn:setPosition(683-68, 545-480)
    local refreshMenu = CCMenu:createWithItem(refreshBtn)
    refreshMenu:setPosition(0, 0)
    board:addChild(refreshMenu)

    local refreshGem = img.createItemIcon(ITEM_ID_RUNE_COIN)
    refreshGem:setScale(0.379)
    refreshGem:setPosition(CCPoint(28, refreshSprite:getContentSize().height/2+3))
    refreshSprite:addChild(refreshGem)

    local refreshGemlab = lbl.createFont2(16/0.379, string.format("5k"), ccc3(255, 246, 223))
    refreshGemlab:setPosition(CCPoint(refreshGem:getContentSize().width/2, 5))
    refreshGem:addChild(refreshGemlab)

    refreshBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        local param = {}
        param.sid = player.sid
        --if refresh <= 0 then
        --    param.type = 2
        --else
        if bag.items.find(ITEM_ID_RUNE_COIN).num < REFRESHLUCKY then
            showToast(i18n.global.heromarket_soulstone_lack.string)
            return
        else
            local dialog = createCostDiamond()
            layer:addChild(dialog, 300)
            return 
        end
    end)

    local ITEM_POS = { 
        [1] = { 164, 369 }, [2] = { 164+172, 369 }, [3] = { 164+172*2, 369 }, [4] = { 164+172*3, 369 }, 
        [5] = { 164, 218 }, [6] = { 164+172, 218 }, [7] = { 164+172*2, 218 }, [8] = { 164+172*3, 218 },
    }

    local timeLab = {}

    local sx = 415
    local dx = 30

    local circlelight = nil

    local function onUpdate()
        if initFlag then
            if addshowpage == false then
                circlelight = img.createUISprite(img.ui.shop_circle_light)
                circlelight:setPosition(sx + (1-(maxPage+1)/2)*dx , 118)
                board:addChild(circlelight, 1)
                local circledark = {}
                for i = 1,maxPage do
                    circlePos[i][1] = sx + (i-(maxPage+1)/2)*dx                
                    circlePos[i][2] = 118
                    circledark[i] = img.createUISprite(img.ui.shop_circle_dark)
                    circledark[i]:setPosition(circlePos[i][1], circlePos[i][2])
                    board:addChild(circledark[i])
                end
                addshowpage = true
            end
            for i=(currentPage-1)*8+1, currentPage*8 do
                if i > #dataheromarket.goods then
                    return 
                end
                if dataheromarket.goods[i].cd then
                    local cd = dataheromarket.goods[i].cd + dataheromarket.pull_time - os.time()
                    if cd > 0 then
                        local timelab = string.format("%02d:%02d:%02d",math.floor(cd/3600),math.floor((cd%3600)/60),math.floor(cd%60))
                        if timeLab[i] then
                            timeLab[i]:setString(timelab)
                        end
                    else
                        dataheromarket.goods[i].cd = nil
                        dataheromarket.rm(i)
                        createlist(currentPage)
                    end
                end
            end
        end
    end

    layer:scheduleUpdateWithPriorityLua(onUpdate, 0)

    function createItemWithPos(iteminfo, pos)
        local item = nil
        local icon = nil
        local cost = nil

        local itemFrame = img.createUISprite(img.ui.casino_shop_frame)
        itemFrame:setPosition(ITEM_POS[(pos-1)%8+1][1], ITEM_POS[(pos-1)%8+1][2])
        showItemLayer:addChild(itemFrame)

        local menuBg = CCMenu:create()
        menuBg:setPosition(0, 0)
        showItemLayer:addChild(menuBg)

        item = img.createItem(cfgheromarket[iteminfo.id].excelId, cfgheromarket[iteminfo.id].count)

        local itemBg = SpineMenuItem:create(json.ui.button, item)
        itemBg:setPosition(ITEM_POS[(pos-1)%8+1][1], ITEM_POS[(pos-1)%8+1][2] + 8)
        menuBg:addChild(itemBg)

        if iteminfo.cd then
            local timelab = string.format("%02d:%02d:%02d",math.floor(iteminfo.cd/3600),math.floor((iteminfo.cd%3600)/60),math.floor(iteminfo.cd%60))
            timeLab[pos] = lbl.createFont2(14, timelab, ccc3(0xa5, 0xfd, 0x47))
            timeLab[pos]:setPosition(itemBg:getContentSize().width/2 , -2)
            itemBg:addChild(timeLab[pos], 10000)
        end

        icon = img.createItemIcon(ITEM_ID_RUNE_COIN)
        icon:setScale(0.379)
        cost = cfgheromarket[iteminfo.id].cost

        local menuBuy = CCMenu:create()
        menuBuy:setPosition(0, 0)
        showItemLayer:addChild(menuBuy)
    
        local buyBtnSprite = img.createUISprite(img.ui.casino_shop_btn)
        local buyBtn = SpineMenuItem:create(json.ui.button, buyBtnSprite)
        buyBtn:setPosition(ITEM_POS[(pos-1)%8+1][1], ITEM_POS[(pos-1)%8+1][2] - 62)
        buyBtn:setEnabled(isBuy[pos] == false)
        menuBuy:addChild(buyBtn)
        if isBuy[pos] then
            setShader(buyBtn, SHADER_GRAY, true)
        end

        icon:setAnchorPoint(ccp(0, 0.5))
        icon:setPosition(15, buyBtnSprite:getContentSize().height/2)
        buyBtnSprite:addChild(icon)

        local costLabel = lbl.createFont2(16, string.format("%d", cost), ccc3(255, 246, 223))
        local x = (buyBtn:getContentSize().width - icon:boundingBox():getMaxX())/2
        costLabel:setAnchorPoint(0, 0.5)
        costLabel:setPosition(icon:boundingBox():getMaxX() + 3, buyBtnSprite:getContentSize().height/2)
        buyBtnSprite:addChild(costLabel)
        layer.tipsTag = false
        itemBg:registerScriptTapHandler(function()
            audio.play(audio.button)
            local tips = nil
            local pbdata = {}
            if layer.tipsTag == false then
                layer.tipsTag = true
                --if iteminfo.type == 1 then
                pbdata.id = cfgheromarket[iteminfo.id].excelId 
                tips = tipsitem.createForShow(pbdata)
                --elseif iteminfo.type == 2 then
                    --pbdata.id = iteminfo.excelId 
                    --tips = tipsequip.createForShow(pbdata)
                --end
                layer:addChild(tips, 200)
                tips.setClickBlankHandler(function()
                    tips:removeFromParent()
                    layer.tipsTag = false
                end)
            end
        end)

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
                if lCoin.num < cost then
                    showToast(i18n.global.heromarket_soulstone_lack.string)
                    return
                end

                local param = {}
                param.sid = player.sid
                param.id = iteminfo.id

                addWaitNet()
                net:hmarket_buy(param, function(__data)
                    delWaitNet()
                    tbl2string(__data)
                    if __data.status ~= 0 then
                        showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                        return
                    end

                    bag.items.add({id = cfgheromarket[iteminfo.id].excelId, num = cfgheromarket[iteminfo.id].count})
                    --local pop = createPopupPieceBatchSummonResult("item", cfgheromarket[iteminfo.id].excelId, cfgheromarket[iteminfo.id].count)
                    --layer:addChild(pop, 100)
					require("ui.custom").showFloatRewardSingle(1, cfgheromarket[iteminfo.id].excelId, cfgheromarket[iteminfo.id].count)

                    iteminfo.num = iteminfo.num + 1
                    if iteminfo.num >= cfgheromarket[iteminfo.id].limitNumb then
                        setAlreadyBuy(pos)
                        setShader(buyBtn, SHADER_GRAY, true)
                        buyBtn:setEnabled(false)
                    end

                    lCoinLab:setString(lCoin.num-cost)
                    bag.items.sub({id = ITEM_ID_RUNE_COIN, num = cost})
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
        
        buyBtn:registerScriptTapHandler(function()
            audio.play(audio.button)
            
            local surebuy = createSurebuy(iteminfo, buyBtn, cost, pos)
            layer:addChild(surebuy, 300)
        end)
        return itemBg
    end

    local function init()
        local param = {}
        param.sid = player.sid
        addWaitNet()
        net:hmarket_sync(param, function(__data)
            delWaitNet()
            tbl2string(__data)
            if __data.status ~= 0 then
                showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                return
            end
        
            dataheromarket.init(__data, true)
            maxPage = dataheromarket.getMaxPage()
            initFlag = true
            createlist(currentPage)
        end)
        
    end

    layer:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.02), CCCallFunc:create(init)))

    local function showdot(page)
        if circlelight then
            circlelight:setPosition(circlePos[page][1], circlePos[page][2])
        end
    end

    local lefMenu = CCMenu:create()
    lefMenu:setPosition(0,0)
    board:addChild(lefMenu)

    local lefBtnSprite = img.createUISprite(img.ui.gemstore_next_icon1)
    local lefBtn = HHMenuItem:create(lefBtnSprite)
    lefBtn:setScale(-1)
    lefBtn:setPosition(60,290)
    if currentPage <= 1 then
        lefBtn:setVisible(false)
    end
    lefMenu:addChild(lefBtn)

    local rigMenu = CCMenu:create()
    rigMenu:setPosition(0,0)
    board:addChild(rigMenu)
    local rigBtnSprite = img.createUISprite(img.ui.gemstore_next_icon1)
    local rigBtn = HHMenuItem:create(rigBtnSprite)
    rigBtn:setPosition(780,290)
    if currentPage >= maxPage then
        rigBtn:setVisible(false)
    end
    rigMenu:addChild(rigBtn)

    lefBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        if currentPage <= 1 then
            return
        end
        currentPage = currentPage - 1
        if currentPage <= 1 then
            lefBtn:setVisible(false)
        end
        if currentPage <= maxPage - 1 then
            rigBtn:setVisible(true)
        end
        createlist(currentPage)
        showdot(currentPage)
    end)

    rigBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        if currentPage >= maxPage then
            return
        end
        currentPage = currentPage + 1
        if currentPage >= maxPage then
            rigBtn:setVisible(false)
        end
        if currentPage >= 2 then
            lefBtn:setVisible(true)
        end
        createlist(currentPage)
        showdot(currentPage)
    end)

    -- back btn
    local back0 = img.createUISprite(img.ui.close)
    local backBtn = SpineMenuItem:create(json.ui.button, back0)
    backBtn:setPosition(866-68, 545-71)
    local backMenu = CCMenu:createWithItem(backBtn)
    backMenu:setPosition(0, 0)
    board:addChild(backMenu)
    local function backEvent()
        audio.play(audio.button)
        layer:removeFromParentAndCleanup()
    end
    backBtn:registerScriptTapHandler(function()
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
