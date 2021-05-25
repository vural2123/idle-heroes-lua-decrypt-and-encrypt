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
local dataarenashop = require "data.arenashop"
local cfgarenashop = require "config.arenamarket"
local cfgequip = require "config.equip"
local cfgitem = require "config.item"
local tipsequip = require "ui.tips.equip"
local tipsitem = require "ui.tips.item"

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

    img.load(img.packedOthers.ui_brave)
    local isBuy = {}
    local itemBg = {}

    local setAlreadyBuy = nil
    local createItemWithPos = nil

    local currentPage = 1
    local maxPage = math.floor((#cfgarenashop-1)/8)+1

    -- bg
    local board = img.createUISprite(img.ui.shop_board)
    board:setScale(view.minScale)
    board:setPosition(view.midX, view.midY-30*view.minScale)
    layer:addChild(board)
    
    local boardicon = img.createUISprite(img.ui.arena_new_shop_icon) 
    boardicon:setPosition(415, 425)
    board:addChild(boardicon)

    local boardtop = img.createUISprite(img.ui.arena_new_shop_up_bar)
    boardtop:setPosition(415, 462)
    board:addChild(boardtop)

    -- board anim
    board:setScale(0.1 * view.minScale)
    board:runAction(CCEaseBackOut:create(CCScaleTo:create(0.3, view.minScale)))
    
    -- lucky coin bg
    local lCoinBg = img.createUI9Sprite(img.ui.main_coin_bg)
    lCoinBg:setPreferredSize(CCSizeMake(174, 40))
    lCoinBg:setPosition(480-68, 545-40)
    board:addChild(lCoinBg, 5)

    -- lucky coin icon
    local lcoinIcon = img.createItemIcon(ITEM_ID_ARENA_SHOP)
    lcoinIcon:setScale(0.517)
    lcoinIcon:setPosition(CCPoint(5, lCoinBg:getContentSize().height/2+2))
    lCoinBg:addChild(lcoinIcon)

    -- lucky lbl coin
    local lCoin = bag.items.find(ITEM_ID_ARENA_SHOP)
    local lCoinLab = lbl.createFont2(16, lCoin.num, ccc3(255, 246, 223))
    lCoinLab:setPosition(CCPoint(lCoinBg:getContentSize().width/2, lCoinBg:getContentSize().height/2+2))
    lCoinBg:addChild(lCoinLab)

    local showItemLayer = CCLayer:create()
    board:addChild(showItemLayer)

    local function createlist(page)
        showItemLayer:removeAllChildrenWithCleanup(true)
        for i=(page-1)*8+1, page*8 do
            if i > #dataarenashop.goods then
                return 
            end
            if cfgarenashop[dataarenashop.goods[i].id].limitNumb and
                dataarenashop.goods[i].num >= cfgarenashop[dataarenashop.goods[i].id].limitNumb then
                isBuy[i] = true
            else
                isBuy[i] = false
            end

            itemBg[i] = createItemWithPos(dataarenashop.goods[i], i)

            if cfgarenashop[dataarenashop.goods[i].id].limitNumb and
                dataarenashop.goods[i].num >= cfgarenashop[dataarenashop.goods[i].id].limitNumb then
                setAlreadyBuy(i)
            end
        end
    end
    
    function setAlreadyBuy(pos)
        setShader(itemBg[pos], SHADER_GRAY, true)
        itemBg[pos]:setEnabled(false)
        local soldout = img.createUISprite(img.ui.blackmarket_soldout)
        --soldout:setAnchorPoint(0, 0)
        soldout:setPosition(CCPoint(itemBg[pos]:getContentSize().width/2, itemBg[pos]:getContentSize().height/2))
        itemBg[pos]:addChild(soldout)
    end

    local ITEM_POS = { 
        [1] = { 175, 405-65 }, [2] = { 335, 405-65 }, [3] = { 495, 405-65 }, [4] = { 655, 405-65 }, 
        [5] = { 175, 175 }, [6] = { 335, 175 }, [7] = { 495, 175 }, [8] = { 655, 175 },
    }

    function createItemWithPos(iteminfo, pos)
        local item = nil
        local icon = nil
        local cost = nil

        local showpos = (pos-1)%8+1
        local itemFrame = img.createUISprite(img.ui.casino_shop_frame)
        itemFrame:setPosition(ITEM_POS[showpos][1], ITEM_POS[showpos][2])
        showItemLayer:addChild(itemFrame)

        local menuBg = CCMenu:create()
        menuBg:setPosition(0, 0)
        showItemLayer:addChild(menuBg)

        if cfgarenashop[iteminfo.id].goods[1].type == 1 then
            item = img.createItem(cfgarenashop[iteminfo.id].goods[1].id, cfgarenashop[iteminfo.id].goods[1].num)
        else
            item = img.createEquip(cfgarenashop[iteminfo.id].goods[1].id, cfgarenashop[iteminfo.id].goods[1].num)
        end

        local itemBg = SpineMenuItem:create(json.ui.button, item)
        itemBg:setPosition(ITEM_POS[showpos][1], ITEM_POS[showpos][2]+8)
        menuBg:addChild(itemBg)
 
        icon = img.createItemIcon(ITEM_ID_ARENA_SHOP)
        icon:setScale(0.379)
        cost = cfgarenashop[iteminfo.id].cost

        local menuBuy = CCMenu:create()
        menuBuy:setPosition(0, 0)
        showItemLayer:addChild(menuBuy)
    
        local buyBtnSprite = img.createUISprite(img.ui.casino_shop_btn)
        local buyBtn = SpineMenuItem:create(json.ui.button, buyBtnSprite)
        buyBtn:setPosition(ITEM_POS[showpos][1], ITEM_POS[showpos][2] - 58)
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
                if cfgarenashop[iteminfo.id].goods[1].type == 1 then
                    pbdata.id = cfgarenashop[iteminfo.id].goods[1].id 
                    tips = tipsitem.createForShow(pbdata)
                elseif cfgarenashop[iteminfo.id].goods[1].type == 2 then
                    pbdata.id = cfgarenashop[iteminfo.id].goods[1].id 
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
            
            if lCoin.num < cost then
                showToast(i18n.global.arena_shop_coin_lack.string)
                return
            end

            local param = {}
            param.sid = player.sid
            param.id = pos

            addWaitNet()
            net:pmarket_buy(param, function(__data)
                delWaitNet()
                tbl2string(__data)
                if __data.status ~= 0 then
                    showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                    return
                end

				local cui = require "ui.custom"
				local rbag = cui.getBagFromCfg(cfgarenashop[iteminfo.id].goods)
				cui.showFloatReward(rbag)
                if cfgarenashop[iteminfo.id].goods[1].type == 1 then
                    bag.items.add({id = cfgarenashop[iteminfo.id].goods[1].id, num = cfgarenashop[iteminfo.id].goods[1].num})
                    --local pop = createPopupPieceBatchSummonResult("item", cfgarenashop[iteminfo.id].goods[1].id, cfgarenashop[iteminfo.id].goods[1].num)
                    --layer:addChild(pop, 100)
                else
                    bag.equips.add({id = cfgarenashop[iteminfo.id].goods[1].id, num = cfgarenashop[iteminfo.id].goods[1].num})
                    --local pop = createPopupPieceBatchSummonResult("equip", cfgarenashop[iteminfo.id].goods[1].id, cfgarenashop[iteminfo.id].goods[1].num)
                    --layer:addChild(pop, 100)
                end

                iteminfo.num = iteminfo.num + 1
                if cfgarenashop[iteminfo.id].limitNumb and
                    iteminfo.num >= cfgarenashop[iteminfo.id].limitNumb then
                    setAlreadyBuy(pos)
                    setShader(buyBtn, SHADER_GRAY, true)
                    buyBtn:setEnabled(false)
                end

                lCoinLab:setString(lCoin.num-cost)
                bag.items.sub({id = ITEM_ID_ARENA_SHOP, num = cost})
                --dataarenashop.goods[pos].num = 1
            end)
        end)
        return itemBg
    end
    
    local function init()
        local param = {}
        param.sid = player.sid
        addWaitNet()
        net:pmarket(param, function(__data)
            delWaitNet()
            tbl2string(__data)
            if __data.status ~= 0 then
                showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                return
            end
        
            dataarenashop.init(__data, true)
            createlist(currentPage)
        end)
        
    end

    layer:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.02), CCCallFunc:create(init)))

    --local dotLayer = CCLayer:create()
    --board:addChild(dotLayer)

    local circlePos = {[1] = {400, 60}, [2] = {430, 60}}
    local circlelight = img.createUISprite(img.ui.shop_circle_light)
    circlelight:setPosition(circlePos[1][1], circlePos[1][2])
    board:addChild(circlelight, 1)

    local circledark1 = img.createUISprite(img.ui.shop_circle_dark)
    circledark1:setPosition(circlePos[1][1], circlePos[1][2])
    board:addChild(circledark1)

    local circledark2 = img.createUISprite(img.ui.shop_circle_dark)
    circledark2:setPosition(circlePos[2][1], circlePos[2][2])
    board:addChild(circledark2)

    local function showdot(page)
        circlelight:setPosition(circlePos[page][1], circlePos[page][2])
    end

    local lefMenu = CCMenu:create()
    lefMenu:setPosition(0,0)
    board:addChild(lefMenu)

    local lefBtnSprite = img.createUISprite(img.ui.gemstore_next_icon1)
    local lefBtn = HHMenuItem:create(lefBtnSprite)
    lefBtn:setScale(-1)
    lefBtn:setPosition(70,250)
    if currentPage <= 1 then
        lefBtn:setVisible(false)
    end
    lefMenu:addChild(lefBtn)

    local rigMenu = CCMenu:create()
    rigMenu:setPosition(0,0)
    board:addChild(rigMenu)
    local rigBtnSprite = img.createUISprite(img.ui.gemstore_next_icon1)
    local rigBtn = HHMenuItem:create(rigBtnSprite)
    rigBtn:setPosition(760,250)
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
