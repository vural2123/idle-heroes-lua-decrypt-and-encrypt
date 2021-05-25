local ui = {}

require "common.func"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local audio = require "res.audio"
local i18n = require "res.i18n"
local net = require "net.netClient"
local bag = require "data.bag"
local cfgequip = require "config.equip"
local tipsitem = require "ui.tips.item"
local tipsequip = require "ui.tips.equip"
local player = require "data.player"
local heroData = require "data.heros"

local equiptr = {}

ui.equiptr = equiptr
-- 宝物
local function showtr()
    local treasures = {}
    for i,eq in ipairs(bag.equips) do
        if cfgequip[eq.id].pos == 6 then
            if eq.num ~= 0 then  
                local tmp = {}
                treasures[#treasures+1] = tmp
                treasures[#treasures].id = eq.id
                treasures[#treasures].num = eq.num
            end
        end
    end
    return treasures
end

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

local function createBag()
    local layer = CCLayer:create()

    ui.equiptr = showtr()

    -- outer bg
    local outerBg = img.createUI9Sprite(img.ui.bag_outer)
    outerBg:setPreferredSize(CCSizeMake(426, 474))
    outerBg:setAnchorPoint(0, 0)
    outerBg:setScale(view.minScale)
    outerBg:setPosition(scalep(482, 576-537))
    layer:addChild(outerBg)
    local boardSize = outerBg:getContentSize()

    -- inner bg
    local innerBg = img.createUI9Sprite(img.ui.bag_btn_inner_bg)
    innerBg:setPreferredSize(CCSizeMake(375, 416))
    innerBg:setScale(view.minScale)
    innerBg:setAnchorPoint(0, 1)
    innerBg:setPosition(scalep(510, 576-90))
    layer:addChild(innerBg)

    --scroll const
    local GRID_SCREEN = 12
    local GRID_COLUMN = 4
    local GRID_WIDTH = 76
    local GRID_HEIGHT = 76
    local GAP_HORIZONTAL = 8
    local GAP_VERTICAL = 8
    local MARGIN_TOP = 14
    local MARGIN_BOTTOM = 14
    local MARGIN_LEFT = 28
    local VIEW_WIDTH = innerBg:getContentSize().width
    local VIEW_HEIGHT = 314
    local VIEW_HEIGHT_NORMAL = 352
    local VIEW_HEIGHT_SMALL  = 382

    -- scroll
    local scroll = CCScrollView:create()
    scroll:setDirection(kCCScrollViewDirectionVertical)
    scroll:setAnchorPoint(0, 0)
    innerBg:addChild(scroll)
    layer.scroll = scroll

    -- icons
    local icons = {}
    layer.icons = icons

    local function getPosition(i, type)
        local x0 = MARGIN_LEFT - 5
        local y0 = scroll:getContentSize().height - MARGIN_TOP - GRID_HEIGHT + 8
        local x = x0 + math.floor((i-1)%GRID_COLUMN) * (GRID_WIDTH+GAP_HORIZONTAL)
        local y = y0
        y = y0 - math.floor((i-1)/GRID_COLUMN) * (GRID_HEIGHT+GAP_VERTICAL)
        
        return x, y
    end

    --init scroll
    local function initScroll(gridnum, keepOldPosition)
        if gridnum < GRID_SCREEN then
            gridnum = GRID_SCREEN
        end
        for i, _ in pairs(icons) do
            if icons[i].gridSelected then
                icons[i].gridSelected:removeFromParent()
                icons[i].gridSelected = nil
            end
            icons[i]:removeFromParent()
            icons[i] = nil
        end
        local rownum = math.ceil(gridnum/GRID_COLUMN)
        local height = rownum*86
        
        local contentOffsetY = scroll:getContentOffset().y  
        local viewHeight
        viewHeight = VIEW_HEIGHT_SMALL
        scroll:setPosition(0, 14)

        if not keepOldPosition then
            contentOffsetY = viewHeight-height
        elseif contentOffsetY > 0 then
            contentOffsetY = 0
        elseif contentOffsetY < viewHeight-height then
            contentOffsetY = viewHeight-height
        end
        scroll:setViewSize(CCSize(VIEW_WIDTH, viewHeight))
        scroll:setContentSize(CCSize(VIEW_WIDTH, height))
        scroll:setContentOffset(ccp(0, contentOffsetY))
    end

    local function addFunctionsForIcon(icon, i, kind)
        function icon.isGridSelected()
            return icon.gridSelected ~= nil and icon.gridSelected:isVisible()
        end

        function icon.setGridSelected(b)
            if icon.gridSelected == nil then
                icon.gridSelected = img.createUISprite(img.ui.bag_grid_selected)
                icon.gridSelected:setAnchorPoint(ccp(0, 0))
                icon.gridSelected:setScale(0.9)
                local x, y = icons[i]:getPosition()
                icon.gridSelected:setPosition(x, y)
                local gridSelectedBatch = img.createBatchNodeForUI(img.ui.bag_grid_selected)
                scroll:getContainer():addChild(gridSelectedBatch, 4)
                gridSelectedBatch:addChild(icon.gridSelected)
            end
            icon.gridSelected:setVisible(b)
        end
    end

    --show equips
    function layer.showEquips(equips, keepOldPosition)
        table.sort(equips, compareEquipReverse)
		if keepOldPosition and #equips <= 16 then
			keepOldPosition = false
		end
        initScroll(#equips, keepOldPosition)
        for i, eq in ipairs(equips) do
            local x, y = getPosition(i, kind)

            -- 装备
            icons[i] = img.createEquip(eq.id, eq.num)
            icons[i]:setScale(0.9)
            icons[i]:setAnchorPoint(ccp(0, 0))
            icons[i]:setPosition(x, y)
            icons[i].data = eq
            icons[i].tipTag = false
            scroll:getContainer():addChild(icons[i], 3)
            
            addFunctionsForIcon(icons[i], i, kind) 

            if i > #equips-4 then
               y = y+4*103+56
            end
            
            if i > #equips-4 then
                y = y-4*103-56
            end
        end
    end

    layer.showEquips(ui.equiptr)

    --handler
    local clickHandler
    function layer.setClickHandler(h)
        clickHandler = h
    end

    --touch 
    local touchbeginx, touchbeginy
    local isclick
  
    
    --touch 
    local touchbeginx, touchbeginy
    local isclick
    local last_touch_sprite = nil

    local function onTouchBegan(x, y)
        touchbeginx, touchbeginy = x, y
        isclick = true
        local p0 = scroll:getContainer():convertToNodeSpace(ccp(x, y))           
        
        for _, icon in ipairs(icons) do
            if p0 and icon:boundingBox():containsPoint(p0) then
                return true
            end
        end
        return true
    end

    local function onTouchMoved(x, y)
        if isclick and (math.abs(touchbeginx-x) > 10 or math.abs(touchbeginy-y) > 10) then
            isclick = false
        end
    end

    local function onTouchEnded(x, y)
        if isclick then
            local p0 = scroll:getContainer():convertToNodeSpace(ccp(x,y))
            local p1
            if #icons > 0 then
                p1 = icons[1]:getParent():convertToNodeSpace(ccp(x, y))
            end
            for _, icon in ipairs(icons) do
                if p1 and icon:boundingBox():containsPoint(p1) then
                    for __, ic in ipairs(icons) do
                        if ic.isGridSelected() then
                            ic.setGridSelected(false)
                        end
                    end
                    icon.setGridSelected(true)
                    layer.ID = _
                    if clickHandler then
                        clickHandler(icon)
                    end
                    return
                end
            end
        end 
    end

    local function onTouch(eventType, x, y)
        if eventType == "began" then
            return onTouchBegan(x, y)
        elseif eventType == "moved" then
            return onTouchMoved(x, y)
        else
            return onTouchEnded(x, y)
        end
    end
   
    layer:registerScriptTouchHandler(onTouch , false , -128 , false)
    layer:setTouchEnabled(true)

    return layer
end

function ui.create(equip, onWear)
    local id = equip.id
    local hid = nil
    if equip.owner then
        hid = equip.owner.hid
    end

    local layer = CCLayerColor:create(ccc4(0,0,0,POPUP_DARK_OPACITY))

    local exp = 0
    local clickID
    local clickNUM
    local hidsid = {}
    local hidscount = {}
    local hidsbagid = {}
    local showTre = {}
    -- outer bg
    local outerBg = img.createUI9Sprite(img.ui.bag_outer)
    outerBg:setPreferredSize(CCSizeMake(432,338))
    outerBg:setAnchorPoint(0, 0)
    outerBg:setScale(view.minScale)
    outerBg:setPosition(scalep(50, 576-537))
    layer:addChild(outerBg, 1)
    local boardSize = outerBg:getContentSize()

    local lefBoard = img.createUI9Sprite(img.ui.hero_treasure_board)
    lefBoard:setPreferredSize(CCSizeMake(464, 319))
    lefBoard:setAnchorPoint(ccp(0.5, 0))
    lefBoard:setPosition(outerBg:getContentSize().width/2, 170)
    outerBg:addChild(lefBoard, 1)

    local showTitle = lbl.createFont2(22, i18n.global.treasure_levelUp_title.string, ccc3(0xf6, 0xd7, 0x71))
    showTitle:setPosition(lefBoard:getContentSize().width/2, 294)
    lefBoard:addChild(showTitle)

    local powerBar = img.createUISprite(img.ui.treasure_bar_0)
    powerBar:setPosition(lefBoard:getContentSize().width/2, 114)
    lefBoard:addChild(powerBar)

    local progress0 = img.createUISprite(img.ui.treasure_bar_1)
    local powerProgress = createProgressBar(progress0)
    powerProgress:setPosition(powerBar:getContentSize().width/2, powerBar:getContentSize().height/2+1)
    powerProgress:setPercentage(exp/cfgequip[id].treasureUpg*100)
    powerBar:addChild(powerProgress)

    local progressStr = string.format("%d/%d", exp, cfgequip[id].treasureUpg)
    local progressLabel = lbl.createFont2(16, progressStr, ccc3(255, 246, 223))
    progressLabel:setPosition(CCPoint(powerBar:getContentSize().width/2,
                                    powerBar:getContentSize().height/2+5))
    powerBar:addChild(progressLabel)

    local tipsTag = false
    local texiaoFlag = false
    json.load(json.ui.baowu_line)
    local lineani = nil
    --lineani:playAnimation("animation", -1)
    --lineani:scheduleUpdateLua()
    --lineani:setPosition(powerBar:getContentSize().width/2, powerBar:getContentSize().height/2)
    --powerBar:addChild(lineani)

    local function uplef()
        local leflayer = CCLayer:create()
        -- 宝物图标
        local icon1 = img.createEquip(id)
        local itemBtn1 = SpineMenuItem:create(json.ui.button, icon1)
        itemBtn1:setPosition(135, 180)
        local iconMenu = CCMenu:createWithItem(itemBtn1)
        iconMenu:setPosition(0, 0)
        leflayer:addChild(iconMenu)
         

        itemBtn1:registerScriptTapHandler(function()
            audio.play(audio.button)
            if tipsTag == false then
                tipsTag = true    
                local tips = tipsequip.createForShow({id = id})
                layer:addChild(tips, 10001)
                tips.setClickBlankHandler(function()
                    tips:removeFromParent()
                    tipsTag = false
                end)
            end
        end)

        local raw = img.createUISprite(img.ui.arrow)
        raw:setPosition(lefBoard:getContentSize().width/2, 180)
        lefBoard:addChild(raw)

        if cfgequip[id].treasureNext then
            local icon2 = img.createEquip(cfgequip[id].treasureNext)
            local itemBtn2 = SpineMenuItem:create(json.ui.button, icon2)
            itemBtn2:setPosition(325, 180)
            local iconMenu2 = CCMenu:createWithItem(itemBtn2)
            iconMenu2:setPosition(0, 0)
            leflayer:addChild(iconMenu2)

            itemBtn2:registerScriptTapHandler(function()
                audio.play(audio.button)
                if tipsTag == false then
                    tipsTag = true    
                    local tips = tipsequip.createForShow({id = cfgequip[id].treasureNext})
                    layer:addChild(tips, 10001)
                    tips.setClickBlankHandler(function()
                        tips:removeFromParent()
                        tipsTag = false
                    end)
                end
            end)
        end
        for i =1,4 do
            if showTre[i] then
                showTre[i]:removeFromParent()
                showTre[i] = nil
                if hidscount[i] then
                    hidsid[i] = nil
                    hidscount[i] = nil
                    hidsbagid[i] = nil
                end
            end
        end

        return leflayer
    end

    local leflayer = uplef()
    lefBoard:addChild(leflayer)

    local baglayer = nil
    
    local onSelect = nil

    local upgradesprit = img.createLogin9Sprite(img.login.button_9_small_green)
    upgradesprit:setPreferredSize(CCSize(174, 50))
    local upgradeInfo = SpineMenuItem:create(json.ui.button, upgradesprit)
    upgradeInfo:setPosition(lefBoard:getContentSize().width/2, 64)
    local declab1 = lbl.createFont1(16, i18n.global.hero_title_exp.string, ccc3(0x1b, 0x59, 0x02))
    declab1:setPosition(CCPoint(upgradesprit:getContentSize().width/2, 
                                upgradesprit:getContentSize().height/2))
    upgradesprit:addChild(declab1)
    local menuInfo = CCMenu:createWithItem(upgradeInfo)
    menuInfo:setPosition(0, 0)
    lefBoard:addChild(menuInfo, 100)

    upgradeInfo:registerScriptTapHandler(function()
        audio.play(audio.button)
        if exp < cfgequip[id].treasureUpg then
            showToast(i18n.global.treasure_no_enough_exp.string)
            return
        end

        local tritems = {}
        for i=1,#hidsid do
            local pitem = {}
            if hidscount[i] ~= nil then
                pitem.id = hidsid[i]
                pitem.num = hidscount[i]
                tritems[#tritems+1] = pitem
            end
        end
        local param = {}
        param.sid = player.sid
        param.id = id
        param.source = tritems
        if hid then
            param.hid = hid  
        end

        tbl2string(param) 
        addWaitNet()
        net:up_treasure(param, function(__data)
            tbl2string(__data) 
            delWaitNet()
            if __data.status ~= 0 then
                showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                return
            end
        
            if hid == nil then 
                bag.equips.sub({id = id, num = 1})
            end

            for i=1,#param.source do
                bag.equips.sub(param.source[i])
            end

            if __data.over ~= 0 then
                bag.equips.add({id = 5000, num = __data.over})

                local ban = CCLayer:create()
                ban:setTouchEnabled(true)
                ban:setTouchSwallowEnabled(true)
                layer:addChild(ban, 1000)
                schedule(layer, 1, function()
                    ban:removeFromParent()
                    --local pop = createPopupPieceBatchSummonResult("equip", 5000, __data.over)
                    --layer:addChild(pop, 100)
					require("ui.custom").showFloatRewardSingle(2, 5000, __data.over)
                end)
            end
            json.load(json.ui.baowu_upgrade)
            local lefupgrade = DHSkeletonAnimation:createWithKey(json.ui.baowu_upgrade)
            lefupgrade:playAnimation("animation")
            lefupgrade:scheduleUpdateLua()
            lefupgrade:setPosition(135, 180-42)
            lefBoard:addChild(lefupgrade, 1000)

            json.load(json.ui.baowu_upgrade2)
            local rigupgrade = DHSkeletonAnimation:createWithKey(json.ui.baowu_upgrade2)
            rigupgrade:playAnimation("animation")
            rigupgrade:scheduleUpdateLua()
            rigupgrade:setPosition(325, 180-42)
            lefBoard:addChild(rigupgrade, 1000)

            lineani:removeFromParent()
            texiaoFlag = false
            
            local pid = id
            id = cfgequip[id].treasureNext

            bag.equips.add({id = id, num = 1})
            if hid then
                onWear(id, EQUIP_POS_TREASURE, false, function()
                    bag.equips.sub({id = pid, num = 1})
                    if cfgequip[id].treasureNext then
                        leflayer:removeFromParentAndCleanup(true)
                        leflayer = nil
                        leflayer = uplef()
                        lefBoard:addChild(leflayer)
                        exp = 0
                        progressLabel:setString(string.format("%d/%d", exp, cfgequip[id].treasureUpg))
                        powerProgress:setPercentage(exp/cfgequip[id].treasureUpg*100) 

                        baglayer:removeFromParentAndCleanup(true)
                        baglayer = nil
                        baglayer = createBag()
                        baglayer:setPosition(0, 0)
                        layer:addChild(baglayer)
                        baglayer.setClickHandler(function(icon)
                            clickID = icon.data.id
                            clickNUM = icon.data.num
                            local function onPutOne( ... )
                                if clickNUM >= 1 then
                                    clickNUM = clickNUM - 1
                                    onSelect(clickID, 1)
                                end
                            end

                            local function onPutTen( ... )
                                if clickNUM >= 1 then
                                    if clickNUM >= 100 then
                                        onSelect(clickID, 100)
                                        clickNUM = clickNUM - 100
                                    else
                                        onSelect(clickID, clickNUM)
                                        clickNUM = 0
                                    end
                                end
                            end

                            local tipsTreasureLevelUp = require("ui.tips.equip").createForTreasureLevelUp(icon.data, onPutOne, onPutTen)
                            layer:addChild(tipsTreasureLevelUp, 10000)
                        end)
                    else
                        local reward = require "ui.reward"
                        layer:getParent():addChild(reward.showRewardFortreasure({id = id,num = 1}), 10001)

                        schedule(layer, 0.5, function()
                            layer:removeFromParentAndCleanup()
                        end)
                    end
                end)
            end
        end)
    end)

    local declab = lbl.createMixFont1(16, i18n.global.treasure_levelUp_material_hint.string, ccc3(0x5d, 0x2b, 0x0f))
    declab:setPosition(CCPoint(outerBg:getContentSize().width/2, 144))
    outerBg:addChild(declab)

    local treasureGrid = {}
    local treasures = {}

    for i=1, 4 do
        treasureGrid[i] = img.createUISprite(img.ui.grid)
        treasureGrid[i]:setPosition(33+42+(i-1)*94, 84)
        outerBg:addChild(treasureGrid[i])
    
        treasureGrid[i].flag = false
    end

    -- bag
    baglayer = createBag(false)
    baglayer:setPosition(0, 0)
    layer:addChild(baglayer)

    local function backEvent()
        layer:removeFromParentAndCleanup()
    end

    -- close btn
    local close0 = img.createUISprite(img.ui.close)
    local closeBtn = SpineMenuItem:create(json.ui.button, close0)
    closeBtn:setScale(view.minScale)
    closeBtn:setPosition(scalep(884, 576-86))
    local closeMenu = CCMenu:createWithItem(closeBtn)
    closeMenu:setPosition(CCPoint(0, 0))
    layer:addChild(closeMenu, 1)
    closeBtn:registerScriptTapHandler(function()     
        backEvent()
    end)

    local function upbag()
        baglayer.showEquips(ui.equiptr, true)
    end
    
    function onSelect(treaid, count, treabagid)
        for i =1, 4 do
            if not hidscount[i] or hidscount[i] == 0 then
                hidscount[i] = count
                hidsid[i] = treaid
                hidsbagid[i] = baglayer.ID
                local showitem = img.createEquip(treaid, hidscount[i])
                showTre[i] = SpineMenuItem:create(json.ui.button, showitem)
                showTre[i]:setPosition(treasureGrid[i]:getPositionX(), treasureGrid[i]:getPositionY())
                local itemMenu = CCMenu:createWithItem(showTre[i])
                itemMenu:setPosition(0, 0)
                outerBg:addChild(itemMenu)
                showTre[i].bagid = baglayer.ID

                showTre[i]:registerScriptTapHandler(function()
                    audio.play(audio.button)
                    showTre[i]:removeFromParent()
                    showTre[i] = nil
                    exp = exp - hidscount[i]*cfgequip[treaid].treasureExp
                    progressLabel:setString(string.format("%d/%d", exp, cfgequip[id].treasureUpg))
                    powerProgress:setPercentage(exp/cfgequip[id].treasureUpg*100) 
                    if exp < cfgequip[id].treasureUpg and texiaoFlag == true then
                        lineani:removeFromParent()
                        texiaoFlag = false
                    end
                    ui.equiptr[hidsbagid[i]].num = ui.equiptr[hidsbagid[i]].num + hidscount[i] 
                    upbag()
                    hidsid[i] = nil
                    hidscount[i] = nil
                    hidsbagid[i] = nil
                end)

                exp = exp + count*cfgequip[treaid].treasureExp
                progressLabel:setString(string.format("%d/%d", exp, cfgequip[id].treasureUpg))
                powerProgress:setPercentage(exp/cfgequip[id].treasureUpg*100)

                if exp >= cfgequip[id].treasureUpg and texiaoFlag == false then
                    lineani = DHSkeletonAnimation:createWithKey(json.ui.baowu_line)
                    lineani:playAnimation("animation", -1)
                    lineani:scheduleUpdateLua()
                    lineani:setPosition(powerBar:getContentSize().width/2, powerBar:getContentSize().height/2+1)
                    powerBar:addChild(lineani)
                    texiaoFlag = true
                end
                ui.equiptr[hidsbagid[i]].num = ui.equiptr[hidsbagid[i]].num - count 
                upbag()

                break
            else
                if hidsid[i] == treaid then
                    hidscount[i] = hidscount[i] + count 
                    hidsbagid[i] = baglayer.ID
                    showTre[i]:removeFromParent()
                    showTre[i] = nil
                    local showitem = img.createEquip(treaid, hidscount[i])
                    showTre[i] = SpineMenuItem:create(json.ui.button, showitem)
                    showTre[i]:setPosition(treasureGrid[i]:getPositionX(), treasureGrid[i]:getPositionY())
                    local itemMenu = CCMenu:createWithItem(showTre[i])
                    itemMenu:setPosition(0, 0)
                    outerBg:addChild(itemMenu)
                    showTre[i].bagid = baglayer.ID

                    showTre[i]:registerScriptTapHandler(function()
                        audio.play(audio.button)
                        showTre[i]:removeFromParent()
                        showTre[i] = nil
                        exp = exp - hidscount[i]*cfgequip[treaid].treasureExp
                        progressLabel:setString(string.format("%d/%d", exp, cfgequip[id].treasureUpg))
                        powerProgress:setPercentage(exp/cfgequip[id].treasureUpg*100) 
                        if exp < cfgequip[id].treasureUpg and texiaoFlag == true then
                            lineani:removeFromParent()
                            texiaoFlag = false
                        end
                        ui.equiptr[hidsbagid[i]].num = ui.equiptr[hidsbagid[i]].num + hidscount[i] 
                        upbag()
                        hidsid[i] = nil
                        hidscount[i] = nil
                        hidsbagid[i] = nil
                    end)

                    exp = exp + count*cfgequip[treaid].treasureExp
                    progressLabel:setString(string.format("%d/%d", exp, cfgequip[id].treasureUpg))
                    powerProgress:setPercentage(exp/cfgequip[id].treasureUpg*100) 

                    if exp >= cfgequip[id].treasureUpg and texiaoFlag == false then
                        lineani = DHSkeletonAnimation:createWithKey(json.ui.baowu_line)
                        lineani:playAnimation("animation", -1)
                        lineani:scheduleUpdateLua()
                        lineani:setPosition(powerBar:getContentSize().width/2, powerBar:getContentSize().height/2+1)
                        powerBar:addChild(lineani)
                        --lineani:playAnimation("animation", -1)
                        texiaoFlag = true
                    end

                    ui.equiptr[hidsbagid[i]].num = ui.equiptr[hidsbagid[i]].num - count 
                    upbag()
                    break
                end
            end
        end
    end

    baglayer.setClickHandler(function(icon)
        clickID = icon.data.id
        clickNUM = icon.data.num
        local function onPutOne( ... )
            if clickNUM >= 1 then
                clickNUM = clickNUM - 1
                onSelect(clickID, 1)
            end
        end

        local function onPutTen( ... )
            if clickNUM >= 1 then
                if clickNUM >= 100 then
                    onSelect(clickID, 100)
                    clickNUM = clickNUM - 100
                else
                    onSelect(clickID, clickNUM)
                    clickNUM = 0
                end
            end
        end

        local tipsTreasureLevelUp = require("ui.tips.equip").createForTreasureLevelUp(icon.data, onPutOne, onPutTen)
        layer:addChild(tipsTreasureLevelUp, 10000)
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

    return layer
end

return ui
