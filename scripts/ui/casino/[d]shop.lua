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
local dataluckymarket = require "data.luckymarket"
local cfgluckymarket = require "config.luckymarket"
local cfgequip = require "config.equip"
local cfgitem = require "config.item"
local tipsequip = require "ui.tips.equip"
local tipsitem = require "ui.tips.item"

local MARKETTIME = 60*60*3
local REFRESHLUCKY = 50

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

    local refresh

    local createItemWithPos = nil
    
    local setAlreadyBuy = nil

    -- board anim
    --layer:setScale(0.1)
    --layer:runAction(CCEaseBackOut:create(CCScaleTo:create(0.3, 1)))

    -- bg
    local board = img.createUISprite(img.ui.casino_shop_bottom)
    board:setScale(view.minScale)
    board:setPosition(view.midX, view.midY)
    layer:addChild(board)
    
    -- board anim
    board:setScale(0.1 * view.minScale)
    board:runAction(CCEaseBackOut:create(CCScaleTo:create(0.3, view.minScale)))
    
    local boss = json.createSpineHero(3303)
    boss:setPosition(156 - 68, 30)
    board:addChild(boss)

    -- chat
    local chat = img.createLogin9Sprite(img.login.toast_bg)
    chat:setPreferredSize(CCSize(752, 74))
    chat:setAnchorPoint(CCPoint(0.5, 0))
    chat:setPosition(480-68, 545-516)
    board:addChild(chat)

    -- lucky coin bg
    local lCoinBg = img.createUI9Sprite(img.ui.main_coin_bg)
    lCoinBg:setPreferredSize(CCSizeMake(174, 40))
    lCoinBg:setPosition(480-68, 545-40)
    board:addChild(lCoinBg, 5)

    -- lucky coin icon
    local lcoinIcon = img.createItemIcon(ITEM_ID_LUCKY_COIN)
    lcoinIcon:setScale(0.517)
    lcoinIcon:setPosition(CCPoint(5, lCoinBg:getContentSize().height/2+2))
    lCoinBg:addChild(lcoinIcon)

    -- lucky lbl coin
    local lCoin = bag.items.find(6)
    local lCoinLab = lbl.createFont2(16, lCoin.num, ccc3(255, 246, 223))
    lCoinLab:setPosition(CCPoint(lCoinBg:getContentSize().width/2, lCoinBg:getContentSize().height/2+2))
    lCoinBg:addChild(lCoinLab)

    local showItemLayer = CCLayer:create()
    board:addChild(showItemLayer)

    local function createlist(aniFlag)
        showItemLayer:removeAllChildrenWithCleanup(true)
        for i=1,8 do
            if dataluckymarket.goods[i].bought == 1 then
                isBuy[i] = true
            else
                isBuy[i] = false
            end
            itemBg[i] = createItemWithPos(dataluckymarket.goods[i], i)
            if aniFlag then
                json.load(json.ui.ic_refresh)
                local aniRef = DHSkeletonAnimation:createWithKey(json.ui.ic_refresh)
                aniRef:scheduleUpdateLua()
                aniRef:playAnimation("animation")
                aniRef:setPosition(itemBg[i]:getContentSize().width/2, itemBg[i]:getContentSize().height/2)
                itemBg[i]:addChild(aniRef, 100)
            end
            if dataluckymarket.goods[i].bought == 1 then    
                setAlreadyBuy(i)
            end
        end
    end
    
    -- 确认是否用幸运币刷新弹窗
    local function createCostDiamond()
        local params = {}
        params.btn_count = 0
        params.body = string.format(i18n.global.casino_sure.string, REFRESHLUCKY)

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
            if bag.items.find(ITEM_ID_LUCKY_COIN).num < REFRESHLUCKY then
               showToast(i18n.global.casino_shop_coin_lack.string)
               return
            end

            local param = {}
            param.sid = player.sid
            param.type = 3
            addWaitNet()
            net:lmarket_pull(param, function(__data)
                tbl2string(__data) 
                delWaitNet()
                if __data.status == -2 then
                    showToast(i18n.global.casino_shop_coin_lack.string)
                    return
                end

                if __data.status ~= 0 then
                    showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                    return
                end

                bag.items.sub({id = ITEM_ID_LUCKY_COIN, num = REFRESHLUCKY})
                lCoinLab:setString(bag.items.find(ITEM_ID_LUCKY_COIN).num)
                dataluckymarket.init(__data)
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

    -- refresh btn
    local refreshSprite = img.createLogin9Sprite(img.login.button_9_small_green)
    refreshSprite:setPreferredSize(CCSize(146, 50))
    local refreshBtn = SpineMenuItem:create(json.ui.button, refreshSprite)
    refreshBtn:setVisible(false)
    local refreshlab = lbl.createFont1(18, i18n.global.blackmarket_refresh.string, ccc3(0x1d, 0x67, 0x00))
    refreshlab:setPosition(CCPoint(refreshSprite:getContentSize().width*3/5, refreshSprite:getContentSize().height/2))
    refreshlab:setVisible(false)
    refreshSprite:addChild(refreshlab)
    refreshBtn:setAnchorPoint(CCPoint(0, 0.5))
    refreshBtn:setPosition(683-68, 545-480)
    local refreshMenu = CCMenu:createWithItem(refreshBtn)
    refreshMenu:setPosition(0, 0)
    board:addChild(refreshMenu)

    refreshBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        local param = {}
        param.sid = player.sid
        if refresh <= 0 then
            param.type = 2
        else
            if bag.items.find(ITEM_ID_LUCKY_COIN).num < REFRESHLUCKY then
                showToast(i18n.global.casino_shop_coin_lack.string)
                return
            else
                local dialog = createCostDiamond()
                layer:addChild(dialog, 300)
                return 
            end
        end
        addWaitNet()
        net:lmarket_pull(param, function(__data)
            delWaitNet()
            tbl2string(__data) 
            if __data.status ~= 0 then
                showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                return
            end
            dataluckymarket.init(__data, true)
            createlist(true)
        end)
    end)

    function setAlreadyBuy(pos)
        setShader(itemBg[pos], SHADER_GRAY, true)
        itemBg[pos]:setEnabled(false)
        local soldout = img.createUISprite(img.ui.blackmarket_soldout)
        --soldout:setAnchorPoint(0, 0)
        --soldout:setPosition(CCPoint(0, itemBg[pos]:getContentSize().height/2))
        soldout:setPosition(CCPoint(itemBg[pos]:getContentSize().width/2, itemBg[pos]:getContentSize().height/2))
        itemBg[pos]:addChild(soldout)
    end


    local ITEM_POS = { 
        [1] = { 232, 415-65 }, [2] = { 390, 415-65 }, [3] = { 616-68, 415-65 }, [4] = { 774-68, 415-65 }, 
        [5] = { 232, 198 }, [6] = { 390, 198 }, [7] = { 616-68, 200 }, [8] = { 774-68, 198 },
    }

    function createItemWithPos(iteminfo, pos)
        local item = nil
        local icon = nil
        local cost = nil

        local itemFrame = img.createUISprite(img.ui.casino_shop_frame)
        itemFrame:setPosition(ITEM_POS[pos][1], ITEM_POS[pos][2])
        showItemLayer:addChild(itemFrame)

        local menuBg = CCMenu:create()
        menuBg:setPosition(0, 0)
        showItemLayer:addChild(menuBg)
        if iteminfo.type == 1 then
            item = img.createItem(iteminfo.id, iteminfo.count)
        elseif iteminfo.type == 2 then
            item = img.createEquip(iteminfo.id, iteminfo.count)
        end
        local itemBg = SpineMenuItem:create(json.ui.button, item)
        itemBg:setPosition(ITEM_POS[pos][1], ITEM_POS[pos][2])
        menuBg:addChild(itemBg)
 
        icon = img.createItemIcon(ITEM_ID_LUCKY_COIN)
        icon:setScale(0.379)
        cost = cfgluckymarket[iteminfo.excel_id].cost

        local menuBuy = CCMenu:create()
        menuBuy:setPosition(0, 0)
        showItemLayer:addChild(menuBuy)
    
        local buyBtnSprite = img.createUISprite(img.ui.casino_shop_btn)
        local buyBtn = SpineMenuItem:create(json.ui.button, buyBtnSprite)
        buyBtn:setPosition(ITEM_POS[pos][1], ITEM_POS[pos][2] - 65)
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
            local param = {}
            param.sid = player.sid
            param.id = pos
            
            if lCoin.num < cost then
                showToast(i18n.global.casino_shop_coin_lack.string)
                return
            end

            addWaitNet()
            net:lmarket_buy(param, function(__data)
                delWaitNet()
                tbl2string(__data)
                if __data.status ~= 0 then
                    showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                    return
                end

				require("ui.custom").showFloatReward(__data.bag)
                if __data.bag.equips then
                    bag.equips.addAll(__data.bag.equips)
                    --local pop = createPopupPieceBatchSummonResult("equip", iteminfo.id, cfgluckymarket[iteminfo.excel_id].count)
                    --layer:addChild(pop, 100)
                end
                if __data.bag.items then
                    bag.items.addAll(__data.bag.items)
                    --local pop = createPopupPieceBatchSummonResult("item", iteminfo.id, cfgluckymarket[iteminfo.excel_id].count)
                    --layer:addChild(pop, 100)
                end 
                lCoinLab:setString(lCoin.num - cost)
                setShader(buyBtn, SHADER_GRAY, true)
                buyBtn:setEnabled(false)
                bag.items.sub({id = ITEM_ID_LUCKY_COIN, num = cost})
                setAlreadyBuy(pos)
            end)
        end)
        return itemBg
    end

    local refreshGem = img.createItemIcon(ITEM_ID_LUCKY_COIN)
    refreshGem:setScale(0.379)
    refreshGem:setPosition(CCPoint(25, refreshSprite:getContentSize().height/2+5))
    refreshGem:setVisible(false)
    refreshSprite:addChild(refreshGem)

    local refreshGemlab = lbl.createFont2(16/0.379, string.format("%d", REFRESHLUCKY), ccc3(255, 246, 223))
    refreshGemlab:setPosition(CCPoint(refreshGem:getContentSize().width/2, 5))
    refreshGem:addChild(refreshGemlab)
    
    local showTimeLab = lbl.createFont2(16, "", ccc3(0xa5, 0xfd, 0x47))
    showTimeLab:setAnchorPoint(1, 0.5)
    showTimeLab:setPosition(refreshBtn:boundingBox():getMinX()-30, refreshBtn:getPositionY())
    showTimeLab:setVisible(false)
    board:addChild(showTimeLab,10)

    local toFreelab = lbl.createFont2(16, i18n.global.casino_shop_to_free.string, ccc3(255, 246, 223))
    toFreelab:setAnchorPoint(1, 0.5)
    toFreelab:setVisible(false)
    toFreelab:setPosition(showTimeLab:getPositionX() - showTimeLab:getContentSize().width - 10, refreshBtn:getPositionY())
    board:addChild(toFreelab)

    local initFlag = false
    local initRefresh = false

    local function onUpdate()
        if initRefresh == true then
            refreshBtn:setVisible(true)
            initRefresh = false
        end
        if initFlag == true then
            refresh = math.max(0, dataluckymarket.refresh - os.time())
            if refresh > 0 then
                toFreelab:setVisible(true)
                refreshlab:setVisible(true)
                showTimeLab:setVisible(true)
                refreshGem:setVisible(true)
                local timeLab = string.format("%02d:%02d:%02d",math.floor(refresh/3600),math.floor((refresh%3600)/60),math.floor(refresh%60))
                showTimeLab:setString(timeLab)
                --showTimeLab:setPosition(CCPoint(480, chat:getContentSize().height/2))
                showTimeLab:setColor(ccc3(0xa5,0xfd,0x47))
                refreshlab:setPosition(CCPoint(refreshSprite:getContentSize().width*3/5, refreshSprite:getContentSize().height/2))
                toFreelab:setPosition(showTimeLab:boundingBox():getMinX() - 10, refreshBtn:getPositionY())
            else
                toFreelab:setVisible(false)
                refreshGem:setVisible(false)
                refreshlab:setVisible(true)
                showTimeLab:setVisible(true)
                showTimeLab:setString(i18n.global.blackmarket_free_refresh.string) 
                --showTimeLab:setPosition(CCPoint(430, chat:getContentSize().height/2))
                showTimeLab:setColor(ccc3(255, 246, 223))
                refreshlab:setPosition(CCPoint(refreshSprite:getContentSize().width/2, refreshSprite:getContentSize().height/2))
            end
        end
    end

    local function init()
        local param = {}
        param.sid = player.sid
        param.type = 1
        addWaitNet()
        net:lmarket_pull(param,function(__data)
            delWaitNet()
            tbl2string(__data)
            if __data.status ~= 0 then
                showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                return
            end
            tbl2string(__data) 
            dataluckymarket.init(__data, true)
            createlist()
            refresh = math.max(0, dataluckymarket.refresh - os.time())
            initFlag = true
            initRefresh = true
        end)
    end

    layer:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.02), CCCallFunc:create(init)))

    layer:scheduleUpdateWithPriorityLua(onUpdate, 0)

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
