-- 背包UI
local ui = {}

require "common.func"

local view = require "common.view"
local img = require "res.img"
local json = require "res.json"
local lbl = require "res.lbl"
local audio = require "res.audio"
local i18n = require "res.i18n"
local baglayer = require "ui.bag.bag"
local bagdata = require "data.bag"
local herosdata = require "data.heros"
local player = require "data.player"
local cfgvip = require "config.vip"
local cfgequip = require "config.equip"
local cfgitem = require "config.item"
local cfghero = require "config.hero"
local tipsequip = require "ui.tips.equip"
local tipsitem = require "ui.tips.item"
local tipssummon = require "ui.tips.summon"
local tipssell = require "ui.tips.sell"
local tipsgift = require "ui.tips.gift"
local net = require "net.netClient"
local treasureshow = require "ui.bag.treasureshow"

local function createPopupPieceBatchSummonResult(type, id, count)
    local params = {}
    params.title = i18n.global.reward_will_get.string
    params.btn_count = 0

    local dialog = require("ui.dialog").create(params) 

    local back = img.createLogin9Sprite(img.login.button_9_small_gold)
    back:setPreferredSize(CCSize(153, 50))
    local comfirlab = lbl.createFont1(18, i18n.global.summon_comfirm.string, lbl.buttonColor)
    comfirlab:setPosition(CCPoint(back:getContentSize().width/2,
                                    back:getContentSize().height/2))
    back:addChild(comfirlab)
    local backBtn = SpineMenuItem:create(json.ui.button, back)
    backBtn:setPosition(CCPoint(dialog.board:getContentSize().width/2, 80))
    local menu = CCMenu:createWithItem(backBtn)
    menu:setPosition(0, 0)
    dialog.board:addChild(menu)

    autoLayoutShift(backBtn)

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
    elseif type == "equip" then
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
    else
		local hskills = nil
		local isSpecialMod = false
		if player.isMod(1) then
			local cf = cfghero[id]
			if cf and cf.maxStar == 6 then
				isSpecialMod = true
				hskills = { 1301, 0 }
			end
		end
        local hero = img.createHeroHead(id, 1, true, true, nil, nil, nil, nil, hskills)
        heroBtn = SpineMenuItem:create(json.ui.button, hero)
        heroBtn:setScale(0.7)
        heroBtn:setPosition(dialog.board:getContentSize().width/2, 185)

        local countLbl = lbl.createFont2(20, string.format("X%d", count), ccc3(255, 246, 223))
        countLbl:setAnchorPoint(ccp(0, 0.5))
        countLbl:setPosition(heroBtn:boundingBox():getMaxX()+10, 185)
        dialog.board:addChild(countLbl)

        local iconMenu = CCMenu:createWithItem(heroBtn)
        iconMenu:setPosition(0, 0)
        dialog.board:addChild(iconMenu)
        heroBtn:registerScriptTapHandler(function()
            audio.play(audio.button)
			if not isSpecialMod then
				local herotips = require "ui.tips.hero"
				local tips = herotips.create(id)
				dialog:addChild(tips, 1001)
			end
        end)
    end
    backBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        dialog:removeFromParentAndCleanup()
    end)
    return dialog
end

function ui.create(backlayer, tagType)
    local currentbag = "equip" 
    if tagType then
        currentbag = tagType
    end
    local layer = baglayer.create()
    local currentBatch = ""
    
    --money bar
    local moneybar = require "ui.moneybar"
    layer:addChild(moneybar.create(), 100)

    -- equip tab
    local equipTab0 = img.createUISprite(img.ui.bag_tab_equip0)
    local equipTab1 = img.createUISprite(img.ui.bag_tab_equip1)
    
    local equipTab = CCMenuItemSprite:create(equipTab0 ,nil ,equipTab1)
    equipTab:setScale(view.minScale)
    equipTab:setAnchorPoint(0, 0.5)
    equipTab:setPosition(scalep(866, 576 - 140 + 1))
    equipTab:setEnabled(currentbag ~= "equip")
    local equipMenu = CCMenu:createWithItem(equipTab)
    equipMenu:setPosition(0 ,0)
    layer:addChild(equipMenu, 3)
    
    --tab size
    local tabWidth, tabHeight = 78, 94

    -- item tab
    local itemTab0 = img.createUI9Sprite(img.ui.bag_tab_item0)
    itemTab1 = img.createUI9Sprite(img.ui.bag_tab_item0)
    itemTab2 = img.createUI9Sprite(img.ui.bag_tab_item1)

    local itemTab = CCMenuItemSprite:create(itemTab0, itemTab1, itemTab2)
    itemTab:setScale(view.minScale)
    itemTab:setAnchorPoint(0, 0.5)
    itemTab:setPosition(scalep(866, 576-232 + 2))
    itemTab:setEnabled(currentbag ~= "item")

    local itemMenu = CCMenu:createWithItem(itemTab)
    itemMenu:setPosition(0, 0)
    layer:addChild(itemMenu, 3) 
    
    -- piece tab
    local pieceTab0 = img.createUISprite(img.ui.bag_tab_piece0)
    pieceTab1 = img.createUISprite(img.ui.bag_tab_piece1)

    local pieceTab = CCMenuItemSprite:create(pieceTab0, nil, pieceTab1)
    pieceTab:setScale(view.minScale)
    pieceTab:setAnchorPoint(0, 0.5)
    pieceTab:setPosition(scalep(866, 576-324 + 3))
    pieceTab:setEnabled(currentbag ~= "piece")
    addRedDot(pieceTab, {
        px=pieceTab:getContentSize().width-10,
        py=pieceTab:getContentSize().height-10,
    })
    delRedDot(pieceTab)

    local pieceMenu = CCMenu:createWithItem(pieceTab)
    pieceMenu:setPosition(0, 0)
    layer:addChild(pieceMenu, 3)

    local function onUpdate(ticks)
        if bagdata.showRedDot() then
            addRedDot(pieceTab, {
                px=pieceTab:getContentSize().width-10,
                py=pieceTab:getContentSize().height-10,
            })
        else
            delRedDot(pieceTab)
        end
    end

    layer:scheduleUpdateWithPriorityLua(onUpdate, 0)
    -- equip piece tab
    --local equippieceTab0 = img.createUISprite(img.ui.bag_tab_equippiece_0)
    --equippieceTab1 = img.createUISprite(img.ui.bag_tab_equippiece_1)

    --local equippieceTab = CCMenuItemSprite:create(equippieceTab0, nil, equippieceTab1)
    --equippieceTab:setScale(view.minScale)
    --equippieceTab:setAnchorPoint(0, 0.5)
    --equippieceTab:setPosition(scalep(866, 576-412))
    --equippieceTab:setEnabled(currentbag ~= "equippiece")

    --local equippieceMenu = CCMenu:createWithItem(equippieceTab)
    --equippieceMenu:setPosition(0, 0)
    --layer:addChild(equippieceMenu, 3)

    --宝物tab
    local treasureTab0 = img.createUISprite(img.ui.bag_tab_treasure_0)
    local treasureTab1 = img.createUISprite(img.ui.bag_tab_treasure_1)

    local treasureTab = CCMenuItemSprite:create(treasureTab0, nil, treasureTab1)
    treasureTab:setScale(view.minScale)
    treasureTab:setAnchorPoint(0, 0.5)
    treasureTab:setPosition(scalep(866, 576-416 + 4))
    treasureTab:setEnabled(currentbag ~= "equippiece")

    local treasureMenu = CCMenu:createWithItem(treasureTab)
    treasureMenu:setPosition(0, 0)
    layer:addChild(treasureMenu, 4)

    --batch btn
    local orangeBatchbtn0 = img.createUISprite(img.ui.bag_btn_orange)
    local orangeBatchBtn = HHMenuItem:create(orangeBatchbtn0)
    orangeBatchBtn:setScale(view.minScale)
    orangeBatchBtn:setPosition(scalep(326, 576-514))

    local orangeBatchMenu = CCMenu:createWithItem(orangeBatchBtn)
    orangeBatchMenu:setPosition(0, 0)
    layer:addChild(orangeBatchMenu)
    
    local redBatchbtn0 = img.createUISprite(img.ui.bag_btn_red)
    local redBatchBtn = HHMenuItem:create(redBatchbtn0)
    redBatchBtn:setScale(view.minScale)
    redBatchBtn:setPosition(scalep(385, 576-514))

    local redBatchMenu = CCMenu:createWithItem(redBatchBtn)
    redBatchMenu:setPosition(0, 0)
    layer:addChild(redBatchMenu)

    local greenBatchbtn0 = img.createUISprite(img.ui.bag_btn_green)
    local greenBatchBtn = HHMenuItem:create(greenBatchbtn0)
    greenBatchBtn:setScale(view.minScale)
    greenBatchBtn:setPosition(scalep(448, 576-514))

    local greenBatchMenu = CCMenu:createWithItem(greenBatchBtn)
    greenBatchMenu:setPosition(0, 0)
    layer:addChild(greenBatchMenu)

    local purpleBatchbtn0 = img.createUISprite(img.ui.bag_btn_purple)
    local purpleBatchBtn = HHMenuItem:create(purpleBatchbtn0)
    purpleBatchBtn:setScale(view.minScale)
    purpleBatchBtn:setPosition(scalep(510, 576-514))

    local purpleBatchMenu = CCMenu:createWithItem(purpleBatchBtn)
    purpleBatchMenu:setPosition(0, 0)
    layer:addChild(purpleBatchMenu)

    local yellowBatchbtn0 = img.createUISprite(img.ui.bag_btn_yellow)
    local yellowBatchBtn = HHMenuItem:create(yellowBatchbtn0)
    yellowBatchBtn:setScale(view.minScale)
    yellowBatchBtn:setPosition(scalep(572, 576-514))

    local yellowBatchMenu = CCMenu:createWithItem(yellowBatchBtn)
    yellowBatchMenu:setPosition(0, 0)
    layer:addChild(yellowBatchMenu)

    local blueBatchbtn0 = img.createUISprite(img.ui.bag_btn_blue)
    local blueBatchBtn = HHMenuItem:create(blueBatchbtn0)
    blueBatchBtn:setScale(view.minScale)
    blueBatchBtn:setPosition(scalep(634, 576-514))

    local blueBatchMenu = CCMenu:createWithItem(blueBatchBtn)
    blueBatchMenu:setPosition(0, 0)
    layer:addChild(blueBatchMenu)

    local selectBatch = img.createUISprite(img.ui.bag_dianji)
    selectBatch:setScale(view.minScale)
    selectBatch:setPosition(-1000, -1000)
    layer:addChild(selectBatch)
    
    local treasurebtn0 = img.createUISprite(img.ui.bag_btn_shenqi)
    local treasureBtn = HHMenuItem:create(treasurebtn0)
    treasureBtn:setAnchorPoint(0.5, 1)
    treasureBtn:setScale(view.minScale)
    treasureBtn:setPosition(scalep(780, 97))

    local treasureMenu = CCMenu:createWithItem(treasureBtn)
    treasureMenu:setPosition(0, 0)
    layer:addChild(treasureMenu)

    local currentfilter = 0
    -- filter 过滤项:
    -- 0:包括所有品质
    -- 1~6:从低到高对应其它6种品质
    local function showEquips(filter)
        local eqs = {}
        for i,eq in ipairs(bagdata.equips) do
            if (filter == 0 or filter == cfgequip[eq.id].qlt) and (cfgequip[eq.id].pos ~= EQUIP_POS_TREASURE)
                and (cfgequip[eq.id].pos ~= EQUIP_POS_SKIN) then
                eqs[#eqs+1] = eq
            end
        end
        layer.showEquips(eqs)
    end

    local function showItems()
        local items = {}
        for i, t in ipairs(bagdata.items) do
            if cfgitem[t.id] and cfgitem[t.id].type == ITEM_KIND_ITEM and t.num > 0 then
                items[#items+1] = t
            end
        end
        layer.showItems(items)
    end

    local function showPieces()
        local pieces = {}
        for i , t in ipairs(bagdata.items) do
            if cfgitem[t.id] and (cfgitem[t.id].type == ITEM_KIND_HERO_PIECE or cfgitem[t.id].type == ITEM_KIND_TREASURE_PIECE) and t.num > 0 then
                pieces[#pieces+1] = t
            end
        end
        layer.showPieces(pieces)
    end

    --local function showEquipPieces()
    --    local equipPieces = {}
    --    for i , t in ipairs(bagdata.items) do
    --        if cfgitem[t.id] and cfgitem[t.id].type == 6 and t.num > 0 then
    --            equipPieces[#equipPieces+1] = t
    --        end
    --    end
    --    layer.showEquipPieces(equipPieces)
    --end

    local function showTreasure(filter)
       local treasureAry = {}
       for i,eq in ipairs(bagdata.equips) do
            if cfgequip[eq.id].pos == EQUIP_POS_TREASURE and (filter == 0 or filter == cfgequip[eq.id].qlt) then
                treasureAry[#treasureAry+1] = eq
            end
        end

       layer.showTreasure(treasureAry)
    end

    local function setBagBtnsStatus()
        equipTab:setEnabled(currentbag ~= "equip")
        itemTab:setEnabled(currentbag ~= "item")
        pieceTab:setEnabled(currentbag ~= "piece")
        treasureTab:setEnabled(currentbag ~= "treasure")
        --equippieceTab:setEnabled(currentbag ~= "equippiece")
    
        selectBatch:setVisible(currentbag == "equip" or currentbag == "treasure")
        orangeBatchBtn:setVisible(currentbag == "equip" or currentbag == "treasure") 
        redBatchBtn:setVisible(currentbag == "equip" or currentbag == "treasure") 
        greenBatchBtn:setVisible(currentbag == "equip" or currentbag == "treasure") 
        purpleBatchBtn:setVisible(currentbag == "equip" or currentbag == "treasure") 
        yellowBatchBtn:setVisible(currentbag == "equip" or currentbag == "treasure") 
        blueBatchBtn:setVisible(currentbag == "equip" or currentbag == "treasure") 
        treasureBtn:setVisible(currentbag == "treasure") 
    end
    
    local function showBag()
        setBagBtnsStatus()
        if currentbag == "equip" then
            showEquips(currentfilter)
        elseif currentbag == "item" then
            showItems()
        elseif currentbag == "piece" then
            showPieces()
        elseif currentbag == "treasure" then
            showTreasure(currentfilter)
        end
    end

    equipTab:registerScriptTapHandler(function()
        currentbag = "equip"
        showBag()
        audio.play(audio.button)        
    end)
    
    itemTab:registerScriptTapHandler(function()
        currentbag = "item"
        showBag()
        audio.play(audio.button)        
    end)

    pieceTab:registerScriptTapHandler(function()
        currentbag = "piece"
        showBag()
        audio.play(audio.button)        
    end)

    --equippieceTab:registerScriptTapHandler(function()
    --    currentbag = "equippiece"
    --    showBag()
    --    audio.play(audio.button)
    --end)

    treasureTab:registerScriptTapHandler(function()
       currentbag = "treasure"
       showBag()
       audio.play(audio.button)
    end)

    orangeBatchBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        if currentfilter == 6 then
            currentfilter = 0
            selectBatch:setVisible(false)
            if currentbag == "equip" then
                showEquips(currentfilter)
            elseif currentbag == "treasure" then
                showTreasure(currentfilter)
            end
            return
        end
        selectBatch:setVisible(true)
        selectBatch:setPosition(scalep(326, 576-511))     
        currentfilter = 6
        if currentbag == "equip" then
            showEquips(currentfilter)
        elseif currentbag == "treasure" then
            showTreasure(currentfilter)
        end
    end)

    redBatchBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        if currentfilter == 5 then
            currentfilter = 0
            selectBatch:setVisible(false)
            if currentbag == "equip" then
                showEquips(currentfilter)
            elseif currentbag == "treasure" then
                showTreasure(currentfilter)
            end
            return
        end
        selectBatch:setVisible(true)
        selectBatch:setPosition(scalep(385, 576-511))
        currentfilter = 5
        if currentbag == "equip" then
            showEquips(currentfilter)
        elseif currentbag == "treasure" then
            showTreasure(currentfilter)
        end
    end)

    greenBatchBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        if currentfilter == 4 then
            currentfilter = 0
            selectBatch:setVisible(false)
            if currentbag == "equip" then
                showEquips(currentfilter)
            elseif currentbag == "treasure" then
                showTreasure(currentfilter)
            end
            return
        end
        selectBatch:setVisible(true)
        selectBatch:setPosition(scalep(448, 576-511))
        currentfilter = 4
        if currentbag == "equip" then
            showEquips(currentfilter)
        elseif currentbag == "treasure" then
            showTreasure(currentfilter)
        end
    end)

    purpleBatchBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        if currentfilter == 3 then
            currentfilter = 0
            selectBatch:setVisible(false)
            if currentbag == "equip" then
                showEquips(currentfilter)
            elseif currentbag == "treasure" then
                showTreasure(currentfilter)
            end
            return
        end
        selectBatch:setVisible(true)
        selectBatch:setPosition(scalep(510, 576-511))
        currentfilter = 3
        if currentbag == "equip" then
            showEquips(currentfilter)
        elseif currentbag == "treasure" then
            showTreasure(currentfilter)
        end
    end)

    yellowBatchBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        if currentfilter == 2 then
            currentfilter = 0
            selectBatch:setVisible(false)
            if currentbag == "equip" then
                showEquips(currentfilter)
            elseif currentbag == "treasure" then
                showTreasure(currentfilter)
            end
            return
        end
        selectBatch:setVisible(true)
        selectBatch:setPosition(scalep(572, 576-511))
        currentfilter = 2
        if currentbag == "equip" then
            showEquips(currentfilter)
        elseif currentbag == "treasure" then
            showTreasure(currentfilter)
        end
    end)

    blueBatchBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        if currentfilter == 1 then
            currentfilter = 0
            selectBatch:setVisible(false)
            if currentbag == "equip" then
                showEquips(currentfilter)
            elseif currentbag == "treasure" then
                showTreasure(currentfilter)
            end
            return
        end
        selectBatch:setVisible(true)
        selectBatch:setPosition(scalep(634, 576-511))
        currentfilter = 1
        if currentbag == "equip" then
            showEquips(currentfilter)
        elseif currentbag == "treasure" then
            showTreasure(currentfilter)
        end
    end)

    treasureBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer:addChild(treasureshow.create(), 2000)
    end)

    -- 出售物品
    local function onSellItem(item)
        if layer.sellPopul then
            layer.sellPopul:removeFromParent()
            layer.sellPopul = nil
        end
        if layer.tipsTag then
            layer.tipsTag = false
            layer.tips:removeFromParent()
            layer.sellPopul = nil
        end
        local paramItems = {}
        paramItems[#paramItems+1] = item
        local param = {}
        param.sid = player.sid
        param.items = paramItems
        addWaitNet()
        net:sell(param, function(__data)
            tbl2string(__data)
            delWaitNet()
            if __data.status ~= 0 then
                showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                return
            end
            bagdata.items.sub(item)
            bagdata.addCoin(__data.item.num)
            showBag()
            --local pop = createPopupPieceBatchSummonResult("item", ITEM_ID_COIN, __data.item.num)
            --layer:addChild(pop, 100)
			require("ui.custom").showFloatRewardSingle(1, ITEM_ID_COIN, __data.item.num)
        end)
    end

    -- 打开礼包
    local function onOpenGift(item)
        if layer.giftPopul then
            layer.giftPopul:removeFromParent()
            layer.giftPopul = nil
        end
        if layer.tipsTag then
            layer.tipsTag = false
            layer.tips:removeFromParent()
            layer.giftPopul = nil
        end
        local paramItems = {}
        paramItems[#paramItems+1] = item
        local param = {}
        param.sid = player.sid
        param.item = item.id
        param.num = item.num
        addWaitNet()
        net:open_gift(param, function(__data)
            tbl2string(__data)
            delWaitNet()
            if __data.status ~= 0 then
                showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                return
            end
            bagdata.items.sub(item)
            bagdata.addRewards(__data.reward)
            showBag()
            local rw = tablecp(__data.reward)
            layer:addChild(require("ui.reward").showReward(rw), 1000)
        end)
    end
    -- 出售装备
    local function onSellEquip(item)
        if layer.sellPopul then
            layer.sellPopul:removeFromParent()
            layer.sellPopul = nil
        end
        if layer.tipsTag then
            layer.tipsTag = false
            layer.tips:removeFromParent()
            layer.tips = nil
        end
        local paramItems = {}
        paramItems[#paramItems+1] = item
        local param = {}
        param.sid = player.sid
        param.equips = paramItems
        addWaitNet()
        net:sell(param, function(__data)
            tbl2string(__data)
            delWaitNet()
            if __data.status ~= 0 then
                showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                return
            end
            bagdata.equips.sub(item)
            bagdata.addCoin(__data.item.num)
            showBag()
            local pop = createPopupPieceBatchSummonResult("item", ITEM_ID_COIN, __data.item.num)
            layer:addChild(pop, 100)
        end)
    end

    -- 弹出出售物品数量弹窗
    local function onPopupSell(item)
        onSellItem(item)
    end

    -- 弹出打开礼包弹窗
    local function onPopupGift(item)
        onOpenGift(item)
    end

    local function onEquipPopupSell(equip)
        onSellEquip(equip)
    end

    --back btn
    local back0 = img.createUISprite(img.ui.back)
    local backBtn = HHMenuItem:create(back0)
    backBtn:setScale(view.minScale)
    backBtn:setPosition(scalep(35, 546))
    local backMenu = CCMenu:createWithItem(backBtn)
    backMenu:setPosition(0, 0)
    layer:addChild(backMenu)

    local function backEvent()
        audio.play(audio.button)
        if backlayer == "hook" then
            replaceScene(require("ui.hook.main").create()) 
        else
            replaceScene(require("ui.town.main").create())  
        end
    end
    backBtn:registerScriptTapHandler(function()
        backEvent()
    end)

    autoLayoutShift(backBtn)
    
    function layer.onAndroidBack()
        --local parent_layer = layer:getParent()
        --if parent_layer then
            --parent_layer.bagPopup = nil
        --end
        --layer:removeFromParentAndCleanup(true)
        backEvent()
    end

    addBackEvent(layer)

    local function onEnter()
        layer.notifyParentLock()
        showBag()
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
    
    layer.tipsTag = false
    layer.tipssTag = false

    local function onClickPieceInfo(piece)
        if layer.tipsTag then
            layer.tips:removeFromParent()
            layer.tipsTag = false
        end
    end
   

    -- 点击碎片tips上的召唤按钮
    local function onClickPieceSummon(piece)
        if layer.tipsTag then
            layer.tips:removeFromParent()
            layer.tipsTag = false
        end
        if layer.tipssTag then
            if layer.tipss and not tolua.isnull(layer.tipss) then
                layer.tipss:removeFromParent()
                layer.tipss = nil
            end
            layer.tipssTag = false
        end
        local costCount = cfgitem[piece.id].heroCost.count
        -- 召唤上限
        local capacityNum = cfgvip[player.vipLv()].heroes + player.buy_hlimit*5 - #herosdata
        local availableNum = math.floor(piece.num/costCount)
        local num = math.min(capacityNum, availableNum)
        --local num = availableNum
        if num <= 0 then
            --showToast(i18n.global.summon_hero_full.string)
            local gotoHeroDlg= require "ui.summon.tipsdialog"
            gotoHeroDlg.show(layer)
            return
        end

        local param = {}
        param.sid = player.sid
        --if isUniversalPiece(piece.id) then
        --    param.item = { id = piece.id, num = costCount }
        --else
        param.item = { id = piece.id, num = costCount*num }
        --end
        addWaitNet()
        net:hero_merge(param, function(data)
            delWaitNet()
            tbl2string(data)
            if data.status ~= 0 then
                showToast(i18n.global.error_server_status_wrong.string .. data.status)
                return
            end
            local activityData = require "data.activity"
            local IDS = activityData.IDS
            local cfghero = require "config.hero"
            if #data.heroes >= 1 and cfghero[data.heroes[1].id].maxStar == 10 then
                local achieveData2 = require('data.achieve')
                achieveData2.add(ACHIEVE_TYPE_WAKE9, 1)
                achieveData2.add(ACHIEVE_TYPE_WAKE10, 1)
            end
            for i=1,#data.heroes do
                if cfghero[data.heroes[i].id].maxStar ~= 5 then
                    break
                end
                local tmp_status = activityData.getStatusById(IDS.HERO_SUMMON_1.ID)
                if cfghero[data.heroes[i].id].group == 2 then
                    tmp_status = activityData.getStatusById(IDS.HERO_SUMMON_2.ID)
                end
                if cfghero[data.heroes[i].id].group == 3 then
                    tmp_status = activityData.getStatusById(IDS.HERO_SUMMON_3.ID)
                end
                if cfghero[data.heroes[i].id].group == 4 then
                    tmp_status = activityData.getStatusById(IDS.HERO_SUMMON_4.ID)
                end
                if cfghero[data.heroes[i].id].group == 5 then
                    tmp_status = activityData.getStatusById(IDS.HERO_SUMMON_5.ID)
                end
                if cfghero[data.heroes[i].id].group == 6 then
                    tmp_status = activityData.getStatusById(IDS.HERO_SUMMON_6.ID)
                end
                if tmp_status and tmp_status.limits and tmp_status.limits < tmp_status.cfg.parameter[1].num then
                    tmp_status.limits = tmp_status.limits + 1
                    local tmp_status7 = activityData.getStatusById(IDS.HERO_SUMMON_7.ID)
                    if tmp_status.limits == tmp_status.cfg.parameter[1].num and tmp_status7.limits < #tmp_status7.cfg.parameter then
                        tmp_status7.limits = tmp_status7.limits + 1
                    end
                end
            end
            -- 增加英雄
            herosdata.addAll(data.heroes)
            bagdata.items.sub({id=piece.id, num=costCount*(#data.heroes)})
            showBag()
            if isUniversalPiece(piece.id) then
                if #data.heroes == 1 then
                    local pop = createPopupPieceBatchSummonResult("hero", data.heroes[1].id, #data.heroes)
                    layer:addChild(pop, 100)
                else
                    layer:addChild((require"ui.bag.summonshow").create(data.heroes, i18n.global.tips_summon.string), 1000)
                end
            else
                local pop = createPopupPieceBatchSummonResult("hero", data.heroes[1].id, #data.heroes)
                layer:addChild(pop, 100)
            end

            require("data.tutorial").goNext("piece", 1, true) 
        end)
    end

    -- 点击碎片tips上的召唤按钮 (召唤多个)
    local function onClickPieceSummonShow(piece)
        if layer.tipsTag then
            layer.tips:removeFromParent()
            layer.tipsTag = false
        end
        layer.tipssTag = true
        layer.tipss = tipssummon.create("items", piece, onClickPieceSummon)
        layer:addChild(layer.tipss, 100)
    end

    -- 点击碎片tips上的召唤按钮
    local function onClickPieceSummonForTreasure(piece)
        if layer.tipsTag then
            layer.tips:removeFromParent()
            layer.tipsTag = false
        end
        local costCount = cfgitem[piece.id].treasureCost.count

        local param = {}
        param.sid = player.sid
        param.item = { id = piece.id, num = costCount }

        addWaitNet()
        net:merge_treasure(param, function(data)
            delWaitNet()
            tbl2string(data)
            if data.status ~= 0 then
                showToast(i18n.global.error_server_status_wrong.string .. data.status)
                return
            end
            bagdata.equips.add({id=data.id, num =1})
            bagdata.items.sub({id=piece.id, num=costCount})
            showBag()

            local pop = createPopupPieceBatchSummonResult("equip", data.id, 1)
            layer:addChild(pop, 100)
        end)
    end

    -- 卷轴碎片合成按钮
    local function onClickScrollPieceMerge(piece)
        if layer.tipsTag then
            layer.tips:removeFromParent()
            layer.tipsTag = false
        end
        local param = {}
        param.sid = player.sid
        local num = math.floor(piece.num/cfgitem[piece.id].itemCost.count)
        param.item = {id = piece.id, num = num*cfgitem[piece.id].itemCost.count}
        addWaitNet()
        net:item_merge(param, function(data)
            delWaitNet()
            tbl2string(data)
            if data.status ~= 0 then
                showToast(i18n.global.error_server_status_wrong.string .. tostring(data.status))
                return
            end
            bagdata.items.sub(param.item)
            bagdata.items.add({id = cfgitem[piece.id].itemCost.id, num = num})
            showBag()
            local pop = createPopupPieceBatchSummonResult("item", cfgitem[piece.id].itemCost.id, num)
            layer:addChild(pop, 100)
        end)
    end

    -- set click handler
    layer.setClickHandler(function(icon)
        if layer.tipsTag then
            return
        end

        if currentbag == "equip" or currentbag == "treasure" then
            layer.tipsTag = true
            layer.tips = tipsequip.createForBag(icon.data, function()
                layer.sellPopul = tipssell.create("equip", icon.data, onEquipPopupSell)
                layer:addChild(layer.sellPopul, 200)
            end)
            layer:addChild(layer.tips, 100)
            layer.tips.setClickBlankHandler(function()
                layer.tips:removeFromParent()
                layer.tipsTag = false
            end)
        elseif currentbag == "item" then      -- 如果是礼包，可打开
            layer.tipsTag = true
            local iconHandler
            tbl2string(icon.data)
            local itemObj = cfgitem[icon.data.id]
            if itemObj.giftId and itemObj.isAutoOpen == 2 then
                iconHandler = function()
                    layer.giftPopul = tipsgift.create("items", icon.data, onPopupGift)
                    layer:addChild(layer.giftPopul, 200)
                end
            else
                iconHandler = function()
                    layer.sellPopul = tipssell.create("items", icon.data, onPopupSell)
                    layer:addChild(layer.sellPopul, 200)
                end
            end
            layer.tips = tipsitem.createForBag(icon.data, iconHandler)
            layer:addChild(layer.tips, 100)
            layer.tips.setClickBlankHandler(function()
                showBag()
                layer.tips:removeFromParent()
                layer.tipsTag = false
            end)
        elseif currentbag == "piece" then
            layer.tipsTag = true

            if cfgitem[icon.data.id].type == ITEM_KIND_HERO_PIECE then
                if isUniversalPiece(icon.data.id) then
                    -- 万能碎片
                    local costCount = math.floor(icon.data.num/cfgitem[icon.data.id].heroCost.count)
                    if costCount <= 1 then
                        layer.tips = tipsitem.createForBag(icon.data, onClickPieceSummon)
                    else
                        layer.tips = tipsitem.createForBag(icon.data, onClickPieceSummonShow)
                        --layer.tips = tipssummon.create("items", icon.data, onClickPieceSummon)
                    end
                elseif icon.data.num >= cfgitem[icon.data.id].heroCost.count then
                    -- 碎片可召唤
                    local costCount = math.floor(icon.data.num/cfgitem[icon.data.id].heroCost.count)
                    if costCount <= 1 then
                        layer.tips = tipsitem.createForBag(icon.data, onClickPieceSummon)
                    else
                        layer.tips = tipsitem.createForBag(icon.data, onClickPieceSummonShow)
                    end
                else
                    -- 碎片不可召唤
                    layer.tips = tipsitem.createForBag(icon.data, function()
                        layer.sellPopul = tipssell.create("items", icon.data, onPopupSell)
                        layer:addChild(layer.sellPopul, 200)
                    end)
                end
                
            else
                layer.tips = tipsitem.createForBag(icon.data, onClickPieceSummonForTreasure)
            end

            layer:addChild(layer.tips, 100)
            layer.tips.setClickBlankHandler(function()
                layer.tips:removeFromParent()
                layer.tipsTag = false
            end)
        
        --elseif currentbag == "equippiece" then
        --    layer.tipsTag = true
        --    layer.tips = tipsitem.createForBag(icon.data, onClickScrollPieceMerge)
        --    layer:addChild(layer.tips, 100)
        --    layer.tips.setClickBlankHandler(function()
        --        layer.tips:removeFromParent()
        --        layer.tipsTag = false
        --    end)
        end
            
        audio.play(audio.button)
    end)

    return layer
end

return ui
