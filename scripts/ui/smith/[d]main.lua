local ui = {}

require "common.func"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local audio = require "res.audio"
local particle = require "res.particle"
local i18n = require "res.i18n"
local net = require "net.netClient"
local player = require "data.player"
local bagdata = require "data.bag"
local cfgitem = require "config.item"
local cfgequip = require "config.equip"
local tipsitem = require "ui.tips.item"
local tipsequip = require "ui.tips.equip"
local reward = require "ui.reward"
local herosdata = require "data.heros"

-- 最大分解个数
local MAX_DECOMPOSE = 4

local equipformulas = {}
local equipSuitFormulas = {}

ui.equipformulas = equipformulas
ui.equipSuitFormulas = equipSuitFormulas

local kind = "forge"

local currentForge = 1

local function getInitialCount(id, reqper)
	if not reqper or reqper <= 0 then
		reqper = 1
	end
	local cf = cfgequip[id]
	if cf then
		local has = bagdata.equips.count(id)
		local maxcan = math.floor(has / reqper)
		local should = 1
		if cf.qlt and cf.qlt < 6 then
			should = 3
		end
		return math.min(should, maxcan)
	end
	return 0
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
        local equip = img.createEquip(id)
        equipBtn = SpineMenuItem:create(json.ui.button, equip)
        equipBtn:setScale(0.85)
        equipBtn:setPosition(dialog.board:getContentSize().width/2, 185)
        local iconMenu = CCMenu:createWithItem(equipBtn)
        iconMenu:setPosition(0, 0)
        dialog.board:addChild(iconMenu)

        local countLbl = lbl.createFont2(20, string.format("X%d", count), ccc3(255, 246, 223))
        countLbl:setAnchorPoint(ccp(0, 0.5))
        countLbl:setPosition(equipBtn:boundingBox():getMaxX()+10, 185)
        dialog.board:addChild(countLbl)

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

function equipformulas.init()
    equipformulas = {}
    for i = 1 , 65000 do
        if cfgequip[i] and cfgequip[i].needFormula then
            equipformulas[#equipformulas+1] = {id = i} 
        end
    end
end

-- 可以合成的装备配方
local function createScrolls(filter)
    local scrolls = {}
    local scrolls2 = {}
    for i, t in ipairs(equipformulas) do
        if filter == 0 then scrolls[#scrolls+1] = {id = t.id}
        elseif filter == cfgequip[t.id].pos then scrolls[#scrolls+1] = {id = t.id}
        elseif filter == 3 and cfgequip[t.id].pos == 6 then scrolls2[#scrolls2+1] = {id = t.id}
        end
    end
    for i=1,#scrolls2 do
        scrolls[#scrolls+1] = scrolls2[i]
    end
    return scrolls

end


local function createBag()
    local layer = CCLayer:create()
    --layer:ignoreAnchorPointForPosition(false)
    
    layer.data = equipformulas[1] 

    -- outer bg
    local outerBg = img.createUI9Sprite(img.ui.bag_outer)
    outerBg:setPreferredSize(CCSizeMake(432, 480))
    outerBg:setAnchorPoint(0, 0)
    outerBg:setScale(view.minScale)
    outerBg:setPosition(scalep(477, 576-560))
    layer:addChild(outerBg)
    local boardSize = outerBg:getContentSize()

    -- inner bg
    local innerBg = img.createUI9Sprite(img.ui.bag_inner)
    innerBg:setPreferredSize(CCSizeMake(382, 410))
    innerBg:setScale(view.minScale)
    innerBg:setAnchorPoint(0, 1)
    innerBg:setPosition(scalep(500, 576-120))
    layer:addChild(innerBg)

    --scroll const
    local GRID_SCREEN = 12
    local GRID_COLUMN = 4
    local GRID_WIDTH = 76
    local GRID_HEIGHT = 76
    local GAP_HORIZONTAL = 10
    local GAP_VERTICAL = 10
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

    -- grids and icons
    local grids = {}
    local icons = {}
    local borders = {}
    layer.grids = grids
    layer.icons = icons
    layer.borders = borders

    local function getPosition(i, type)
        local x0 = MARGIN_LEFT - 3
        local y0 = scroll:getContentSize().height - MARGIN_TOP - GRID_HEIGHT + 3
        local x = x0 + math.floor((i-1)%GRID_COLUMN) * (GRID_WIDTH+GAP_HORIZONTAL)
        local y = y0
        y = y0 - math.floor((i-1)/GRID_COLUMN) * (GRID_HEIGHT+GAP_VERTICAL)
        
        return x, y
    end
    
    local function getForgePosition(i)
        local x0 = MARGIN_LEFT + 2
        local y0 = scroll:getContentSize().height + 5 
        local x
        local y
        if i <= 3 then
            x = x0 + (GRID_WIDTH+GAP_HORIZONTAL)*1.5 
            y = y0 - i*(GRID_HEIGHT+GAP_VERTICAL+10)
            return x, y
        end
        i = i-3
        y0 = y0 - 4*(GRID_HEIGHT+GAP_VERTICAL+10) - 25
        x = x0 + math.floor((i-1)%GRID_COLUMN) * (GRID_WIDTH+GAP_HORIZONTAL)
        y = y0 - math.floor((i-1)/GRID_COLUMN) * (GRID_HEIGHT+GAP_VERTICAL+10)
        return x,y
    end

    local function getborderPosition(i, type)
        local x0 = MARGIN_LEFT - 10
        local y0 = scroll:getContentSize().height - MARGIN_TOP - 135
        local x = x0
        local y = y0 - (i-1)*145
        return x, y
    end

    --init scroll
    local function initScroll(kind, gridnum, keepOldPosition)
        if gridnum < GRID_SCREEN then
            gridnum = GRID_SCREEN
        end
        for i, _ in pairs(icons) do
            if icons[i].gridSelected then
                icons[i].gridSelected:removeFromParent()
                icons[i].gridSelected = nil
            end
            if icons[i].redIcon then
                icons[i].redIcon:removeFromParent()
                icons[i].redIcon = nil
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

    local function initGrids(gridnum, kind)
        for i = 1,#borders do
            borders[i]:removeFromParent()
            borders[i] = nil
        end
    end

    -- 选中状态
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
    function layer.showEquips(kind, equips, keepOldPosition)
        --table.sort(equips, compareEquip)
        initScroll(kind, #equips, keepOldPosition)
        initGrids(#equips, kind)
        for i, eq in ipairs(equips) do
            local x, y = getPosition(i, kind)

            -- 装备
            icons[i] = img.createEquip(eq.id)
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

            local redIcon = img.createUISprite(img.ui.main_red_dot)
            redIcon:setPosition(x+70, y+70)
            scroll:getContainer():addChild(redIcon, 100)
            icons[i].redIcon = redIcon
            icons[i].redIcon:setVisible(false)

            if bagdata.equips.count(cfgequip[eq.id].needFormula[1].id) >= cfgequip[eq.id].needFormula[1].count then
                icons[i].redIcon:setVisible(true)
            end
        end
    end

    --show items
    function layer.showItems(kind, items, keepOldPosition)
        table.sort(items, compareItem)
        initScroll(kind, #items, keepOldPosition)
        initGrids(#items, kind)
        for i, item in ipairs(items) do
            local x, y = getPosition(i, kind)
            icons[i] = img.createItem(item.id, item.num)
            icons[i]:setAnchorPoint(ccp(0, 0))
            icons[i]:setPosition(x, y)
            icons[i].data = item
            scroll:getContainer():addChild(icons[i])
            addFunctionsForIcon(icons[i], i, kind)
        end
    end

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
    --layer:setTouchSwallowEnabled(false)

    return layer 
end

-- 合成界面
local function createForgeLayer(bag, checkReddot)
    local layer = CCLayer:create()

    json.load(json.ui.blacksmith)
    local aniSmith = DHSkeletonAnimation:createWithKey(json.ui.blacksmith)
    aniSmith:setScale(view.minScale)
    aniSmith:scheduleUpdateLua()
    aniSmith:playAnimation("begin")
    aniSmith:setPosition(scalep(480, 288))
    layer.aniSmith = aniSmith
    layer:addChild(aniSmith)

    local leftFrame = img.createUISprite(img.ui.smith_bottom)
    aniSmith:addChildFollowSlot("backplane", leftFrame)

    local forgeBoard = img.createUISprite(img.ui.smith_forge_board)
    forgeBoard:setPosition(225, 535-212)
    leftFrame:addChild(forgeBoard)

    --local grid = img.createUISprite(img.ui.grid)  
    --grid:setPosition(CCPoint(110, 535-418))
    --leftFrame:addChild(grid)

    -- cost coin bg
    local costCoinBg = img.createUISprite(img.ui.smith_resourse_trough)
    costCoinBg:setPosition(CCPoint(292, 535-394))
    leftFrame:addChild(costCoinBg)

    -- cost coin icon
    local iconCostCoin = img.createItemIcon2(ITEM_ID_COIN)
    iconCostCoin:setPosition(CCPoint(8, costCoinBg:getContentSize().height/2))
    costCoinBg:addChild(iconCostCoin)

    -- cost lbl coin
    local costCoinnum = 0
    local costCoinLab = lbl.createFont2(16, num2KM(costCoinnum), ccc3(255, 246, 223))
    costCoinLab:setPosition(CCPoint(costCoinBg:getContentSize().width/2, costCoinBg:getContentSize().height/2))
    costCoinBg:addChild(costCoinLab)
    
    -- coin bg
    local coin_bg = img.createUI9Sprite(img.ui.main_coin_bg)
    coin_bg:setPreferredSize(CCSizeMake(174, 40))
    coin_bg:setScale(view.minScale)
    coin_bg:setAnchorPoint(CCPoint(0, 0.5))
    coin_bg:setPosition(scalep(156, 576-96))
    layer:addChild(coin_bg)

    -- coin icon
    local icon_coin = img.createItemIcon2(ITEM_ID_COIN)
    icon_coin:setPosition(CCPoint(5, coin_bg:getContentSize().height/2+2))
    coin_bg:addChild(icon_coin)
    
    -- lbl coin
    local coin_num = bagdata.coin()
    local lbl_coin = lbl.createFont2(16, num2KM(coin_num), ccc3(255, 246, 223))
    lbl_coin:setPosition(CCPoint(coin_bg:getContentSize().width/2, coin_bg:getContentSize().height/2+2))
    coin_bg:addChild(lbl_coin)
    
    local updatePay = nil

    local firstForge = false

    local function batchForge()
		local mergeMaxequip = getInitialCount(layer.icon.data.id, layer.icon.data.num)

        -- edit
        local edit0 = img.createLogin9Sprite(img.login.input_border)
        layer.icon.edit = CCEditBox:create(CCSizeMake(118*view.minScale, 40*view.minScale), edit0)
        layer.icon.edit:setInputMode(kEditBoxInputModeNumeric)
        layer.icon.edit:setReturnType(kKeyboardReturnTypeDone)
        layer.icon.edit:setMaxLength(5)
        layer.icon.edit:setFont("", 20*view.minScale)
        --edit:setPlaceHolder("0")
        layer.icon.edit:setText(string.format("%d", mergeMaxequip))
        layer.icon.edit:setFontColor(ccc3(0x94, 0x62, 0x42))
        layer.icon.edit:setPosition(scalep(241, 576 - 354))
        layer:addChild(layer.icon.edit)
        --layer.edit = edit
        local editlbl = createEditLbl(118, 40)
        editlbl.lbl:setColor(ccc3(0x94, 0x62, 0x42))
        editlbl.lbl:setString(string.format("%d", mergeMaxequip))
        editlbl:setScale(view.minScale)
        editlbl:setPosition(scalep(241, 576 - 354))
        layer:addChild(editlbl, 100)

        local btn_sub0 = img.createUISprite(img.ui.btn_sub)
        local btn_sub = SpineMenuItem:create(json.ui.button, btn_sub0)
        btn_sub:setScale(view.minScale)
        btn_sub:setPosition(scalep(155, 576 - 354))
        layer.icon.btn_sub_menu = CCMenu:createWithItem(btn_sub)
        layer.icon.btn_sub_menu:setPosition(CCPoint(0, 0))
        layer:addChild(layer.icon.btn_sub_menu)
        
        local btn_add0 = img.createUISprite(img.ui.btn_add)
        local btn_add = SpineMenuItem:create(json.ui.button, btn_add0)
        btn_add:setScale(view.minScale)
        btn_add:setPosition(scalep(329, 576 - 354))
        layer.icon.btn_add_menu = CCMenu:createWithItem(btn_add)
        layer.icon.btn_add_menu:setPosition(CCPoint(0, 0))
        layer:addChild(layer.icon.btn_add_menu)

        if firstForge == false then
            layer.icon.edit:setVisible(false)
            layer.icon.btn_add_menu:setVisible(false)
            layer.icon.btn_sub_menu:setVisible(false)
            editlbl:setVisible(false)
            firstForge = true
            schedule(layer, 0.6, function()
                layer.icon.edit:setVisible(true)
                layer.icon.btn_add_menu:setVisible(true)
                layer.icon.btn_sub_menu:setVisible(true)
                editlbl:setVisible(true)
            end)
        end

        function updatePay(_count)
			local has = bagdata.equips.count(layer.icon.data.id)
			local need = layer.icon.data.num * _count
			if need <= 0 then
				layer.icon.progressFg:setPercentage(0)
			elseif has >= need then
				layer.icon.progressFg:setPercentage(100)
			else
				layer.icon.progressFg:setPercentage(has/need*100)
			end

            layer.icon.label:setString(string.format("%d/%d", has, need))

            costCoinLab.num = layer.icon.goldMat * _count
            costCoinLab:setString(num2KM(costCoinLab.num))

            editlbl.lbl:setString(_count .. "")
            editlbl:setVisible(true)
        end
		
		updatePay(mergeMaxequip)

        local edit_chips = layer.icon.edit
        edit_chips:registerScriptEditBoxHandler(function(eventType)
            if eventType == "returnSend" then
            elseif eventType == "return" then
            elseif eventType == "ended" then
                local tmp_chip_count = edit_chips:getText()
                tmp_chip_count = string.trim(tmp_chip_count)
                tmp_chip_count = checkint(tmp_chip_count)
                if tmp_chip_count <= 0 then
                    tmp_chip_count = 0
                elseif tmp_chip_count > math.floor(bagdata.equips.count(layer.icon.data.id)/layer.icon.data.num) then
                    tmp_chip_count = math.floor(bagdata.equips.count(layer.icon.data.id)/layer.icon.data.num)
                end
                edit_chips:setText(tmp_chip_count)

                updatePay(tmp_chip_count)
            elseif eventType == "began" then
                editlbl.lbl:setString("")
                editlbl:setVisible(false)
            elseif eventType == "changed" then
            end
        end)

        btn_sub:registerScriptTapHandler(function()
            audio.play(audio.button)
            local edt_txt = edit_chips:getText()
            edt_txt = string.trim(edt_txt)
            if edt_txt == "" then
                edt_txt = 0
                edit_chips:setText(0)
                updatePay(0)
                --buy_chip_count = 0
                return
            end
            local chip_count = checkint(edt_txt)
            if chip_count <= 0 then
                edit_chips:setText(0)
                updatePay(0)
                --buy_chip_count = 0
                return
            else
                chip_count = chip_count - 1
                edit_chips:setText(chip_count)
                updatePay(chip_count)
                --buy_chip_count = chip_count
            end
        end)

        btn_add:registerScriptTapHandler(function()
            audio.play(audio.button)
            local edt_txt = edit_chips:getText()
            edt_txt = string.trim(edt_txt)
            if edt_txt == "" then
                edt_txt = 0
                edit_chips:setText(0)
                updatePay(0)
                --buy_chip_count = 0
                return
            end
            local chip_count = checkint(edt_txt)
            if chip_count < 0 then
                edit_chips:setText(0)
                updatePay(0)
                --buy_chip_count = 0
                return
            elseif chip_count >= math.floor(bagdata.equips.count(layer.icon.data.id)/layer.icon.data.num) then
                return
            else
                chip_count = chip_count + 1
                edit_chips:setText(chip_count)
                updatePay(chip_count)
            end
        end)
    end

    -- compoyd btn
    local compoydBtn0 = img.createLogin9Sprite(img.login.button_9_small_gold)
    compoydBtn0:setPreferredSize(CCSizeMake(153, 60))
    local compoydBtnLab = lbl.createFont1(18, i18n.global.smith_breakdown.string, ccc3(0x73, 0x3b, 0x05))
    compoydBtnLab:setPosition(CCPoint(compoydBtn0:getContentSize().width/2,
                                compoydBtn0:getContentSize().height/2))
    compoydBtn0:addChild(compoydBtnLab)                            
    local compoydBtn = SpineMenuItem:create(json.ui.button, compoydBtn0)
    compoydBtn:setPosition(CCPoint(292, 535-455))
    local compoydMenu = CCMenu:createWithItem(compoydBtn)
    compoydMenu:ignoreAnchorPointForPosition(false)
    leftFrame:addChild(compoydMenu)

    compoydBtn:registerScriptTapHandler(function()
        audio.play(audio.smith_forge)
        if layer.icon == nil then
            showToast(i18n.global.smith_scroll_put_in.string)
            return
        end
        if costCoinLab.num > bagdata.coin() then
            showToast(i18n.global.blackmarket_coin_lack.string)
            return
        end

        if bagdata.equips.count(layer.icon.data.id) < layer.icon.data.num then
            showToast(i18n.global.smith_no_enough.string)
            return
        end

        if checkint(layer.icon.edit:getText()) == 0 then
            showToast(i18n.global.smith_forge_notzero.string)
            return 
        end

        local param = {}
        param.sid = player.sid
        param.id = bag.data.id
        param.num = checkint(layer.icon.edit:getText()) 

        addWaitNet()
        net:equip_merge(param, function(__data)
            delWaitNet()
            tbl2string(__data)
            if __data.status ~= 0 then
                showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                return           
            end
            bagdata.subCoin(costCoinLab.num)
            lbl_coin:setString(num2KM(bagdata.coin()))

            local needFormulanum = param.num*cfgequip[bag.data.id].needFormula[1].count
            bagdata.equips.sub({id = layer.icon.data.id, num = needFormulanum})
            bagdata.equips.add({id = bag.data.id, num = param.num})

            local task = require "data.task"
            task.increment(task.TaskType.FORGE, param.num)
            --layer.icon.label:setString(string.format("%d/%d", bagdata.equips.count(layer.icon.data.id), 
            --                            layer.icon.data.num))
            --layer.icon.progressFg:setPercentage(bagdata.equips.count(layer.icon.data.id)
            --                                    /layer.icon.data.num * 100)

			local chipnum = getInitialCount(layer.icon.data.id, layer.icon.data.num)
            layer.icon.edit:setText(chipnum)
            
            updatePay(chipnum)

            json.load(json.ui.tiejiangpu_shengji_fx)
            local aniSmithShengji = DHSkeletonAnimation:createWithKey(json.ui.tiejiangpu_shengji_fx)
            aniSmithShengji:scheduleUpdateLua()
            aniSmithShengji:playAnimation("animation")
            aniSmithShengji:setPosition(CCPoint(110, 535-418))
            leftFrame:addChild(aniSmithShengji)

            json.load(json.ui.blacksmith_hecheng)
            local aniSmithHecheng = DHSkeletonAnimation:createWithKey(json.ui.blacksmith_hecheng)
            aniSmithHecheng:scheduleUpdateLua()
            aniSmithHecheng:playAnimation("hecheng")
            aniSmithHecheng:setScale(view.minScale)
            aniSmithHecheng:setPosition(scalep(480, 288))
            layer:addChild(aniSmithHecheng)
            
            schedule(layer, 1.5, function()
                --local pop = createPopupPieceBatchSummonResult("equip", bag.data.id, param.num)
                --layer:addChild(pop, 100)
				require("ui.custom").showFloatRewardSingle(2, bag.data.id, param.num)
                if bagdata.equips.count(layer.icon.data.id) < layer.icon.data.num then
                    bag.redIcon:setVisible(false)
                end
                if bag.icons[bag.ID+1] then
                    local needFormulaId = cfgequip[bag.icons[bag.ID+1].data.id].needFormula[1].id
                    local needFormulaNum = cfgequip[bag.icons[bag.ID+1].data.id].needFormula[1].count
                        
                    if bagdata.equips.count(needFormulaId) >= needFormulaNum then
                        bag.icons[bag.ID+1].redIcon:setVisible(true)
                    end
                end
                if player.lv() <= 40 then
                    checkReddot()
                end
                aniSmithHecheng:removeFromParent()
            end)
            local ban = CCLayer:create()
            ban:setTouchEnabled(true)
            ban:setTouchSwallowEnabled(true)
            layer:addChild(ban, 1000)

            layer:runAction(createSequence({
                CCDelayTime:create(1.5),CCCallFunc:create(function()
                    ban:removeFromParent()
                end)
            }))

        end)
    end)

    function layer.init()
        if layer.icon then
            --layer.icon.equipTips:removeFromParent()
            --layer.icon.equipTips = nil
            layer.icon.edit:removeFromParent()
            layer.icon.edit = nil
            layer.icon.btn_sub_menu:removeFromParent()
            layer.icon.btn_sub_menu = nil
            layer.icon.btn_add_menu:removeFromParent()
            layer.icon.btn_add_menu = nil
            layer.icon.formulamenu:removeFromParent()
            layer.icon.formulamenu = nil
            layer.icon.formulaIcon = nil
            layer.icon.menu:removeFromParent()
            layer.icon.menu = nil
            layer.icon.data = nil
            layer.icon = nil
        end
        
        costCoinLab.num = 0
        costCoinLab:setString(num2KM(costCoinLab.num))
    end

    function layer.putScroll(equip, goldMat)
        layer.init()
        local icon = img.createEquip(equip.id)
        layer.icon = CCMenuItemSprite:create(icon, nil)
        layer.icon:setScale(0.85)
        layer.icon:setPosition(CCPoint(112, 535-413))
        layer.icon.data = equip
        layer.icon.goldMat = goldMat
        layer.icon.menu = CCMenu:createWithItem(layer.icon)
        layer.icon.menu:setPosition(0, 0)
        leftFrame:addChild(layer.icon.menu)

        local progressBg = img.createUISprite(img.ui.bag_heropiece_progr)
        progressBg:setPosition(43, -27)
        layer.icon:addChild(progressBg)

        local progressFgSprite = nil 
        
        --现有的装备材料的个数(材料合成装备的倍数)
        local equipmatNum = math.floor(bagdata.equips.count(equip.id)/equip.num) * equip.num
        layer.equipmatNum = equipmatNum

        if bagdata.equips.count(equip.id) < equip.num then
            progressFgSprite = img.createUISprite(img.ui.bag_heropiece_progr_0)
        else
            progressFgSprite = img.createUISprite(img.ui.bag_heropiece_progr_1)
        end
       
        local progressFg = createProgressBar(progressFgSprite) 
        progressFg:setPosition(43, -27)
        progressFg:setPercentage(bagdata.equips.count(equip.id) / equip.num * 100)
        layer.icon:addChild(progressFg)
        layer.icon.progressFg = progressFg

        local str = string.format("%d/%d", bagdata.equips.count(equip.id), equip.num)
        local label = lbl.createFont2(14, str, ccc3(255, 246, 223))
        label:setPosition(43, -28)
        layer.icon:addChild(label)
        layer.icon.label = label

        costCoinLab.num = goldMat * math.floor(bagdata.equips.count(equip.id)/equip.num)
        costCoinLab:setString(num2KM(costCoinLab.num))

        --local formulaEquip = {}
        --formulaEquip.id = cfgequip[equip.id].formula[1].id
        --layer.icon.equipTips = tipsequip.createForSmith(formulaEquip)
        --layer.icon.equipTips:setPosition(CCPoint(226, 535-360+145))
        --leftFrame:addChild(layer.icon.equipTips)

        local formulaIcon = img.createEquip(bag.data.id)
        layer.icon.formulaIcon = CCMenuItemSprite:create(formulaIcon, nil)
        layer.icon.formulaIcon:setPosition(225, 535-212)
        layer.icon.formulamenu = CCMenu:createWithItem(layer.icon.formulaIcon)
        layer.icon.formulamenu:setPosition(0, 0)
        leftFrame:addChild(layer.icon.formulamenu)
        
        -- remove
        layer.icon:registerScriptTapHandler(function()
            if not layer.tipsTag then
                layer.tipsTag = true
                layer.tips = tipsequip.createForSmith({id = equip.id})
                layer:addChild(layer.tips, 100)
                layer.tips.setClickBlankHandler(function()
                    layer.tips:removeFromParent()
                    layer.tipsTag = false
                end)
            end
            audio.play(audio.button)
        end)

        layer.icon.formulaIcon:registerScriptTapHandler(function()
            if not layer.tipsTag then
                layer.tipsTag = true
                layer.tips = tipsequip.createForShow({id = bag.data.id})
                layer:addChild(layer.tips, 100)
                layer.tips.setClickBlankHandler(function()
                    layer.tips:removeFromParent()
                    layer.tipsTag = false
                end)
            end
            audio.play(audio.button)
        end)


        batchForge()
    end

    return layer
end

function ui.create(uiParams)
    local layer = CCLayer:create()
    
    img.load(img.packedOthers.spine_ui_blacksmith_1)
    img.load(img.packedOthers.spine_ui_blacksmith_2)
    img.load(img.packedOthers.ui_smith_bg)
    img.load(img.packedOthers.ui_smith)
    currentForge = 1
    -- bg
    local bg = img.createUISprite(img.ui.smith_bg)
    bg:setScale(view.minScale)
    bg:setPosition(view.midX, view.midY)
    layer:addChild(bg)
   
    json.load(json.ui.blacksmith)
    local aniSmith = DHSkeletonAnimation:createWithKey(json.ui.blacksmith)
    aniSmith:setScale(view.minScale)
    aniSmith:scheduleUpdateLua()
    aniSmith:playAnimation("background", -1)
    aniSmith:setPosition(scalep(480, 288))
    layer:addChild(aniSmith)
    
    -- bag
    local bag = createBag()
    bag:setPosition(0, 0)
    layer:addChild(bag)

    -- roof
    local roof = img.createUISprite(img.ui.smith_roof)
    roof:setScaleX(view.physical.w / roof:getContentSize().width)
    roof:setScaleY(view.minScale)
    roof:setAnchorPoint(CCPoint(0.5, 1))
    roof:setPosition(scalep(960/2, 576))
    layer:addChild(roof, 20)

    local titleLbl = lbl.createFont2(24, i18n.global.smith_title_upgrade.string, ccc3(0xff, 0xfb, 0xbc), view.minScale)
    titleLbl:setPosition(scalep(480, 576-20))
    layer:addChild(titleLbl, 20)

    autoLayoutShift(roof, true, false, false, false)
    autoLayoutShift(titleLbl)


    -- weapon tab
    local weaponTab0 = img.createUISprite(img.ui.smith_weapon0)
    weaponTab1 = img.createUISprite(img.ui.smith_weapon0)
    weaponTab2 = img.createUISprite(img.ui.smith_weapon1)

    local weaponTab = CCMenuItemSprite:create(weaponTab0, weaponTab1, weaponTab2)
    weaponTab:setScale(view.minScale)
    weaponTab:setPosition(scalep(916, 576-186))
    weaponTab:setEnabled(false)
    addRedDot(weaponTab, {
        px=weaponTab:getContentSize().width-10,
        py=weaponTab:getContentSize().height-10,
    })
    delRedDot(weaponTab)

    local weaponMenu = CCMenu:createWithItem(weaponTab)
    weaponMenu:setPosition(0, 0)
    layer:addChild(weaponMenu, 3) 

    -- armour tab
    local armourTab0 = img.createUISprite(img.ui.smith_armour0)
    armourTab1 = img.createUISprite(img.ui.smith_armour0)
    armourTab2 = img.createUISprite(img.ui.smith_armour1)

    local armourTab = CCMenuItemSprite:create(armourTab0, armourTab1, armourTab2)
    armourTab:setScale(view.minScale)
    armourTab:setPosition(scalep(916, 576-276))
    addRedDot(armourTab, {
        px=armourTab:getContentSize().width-10,
        py=armourTab:getContentSize().height-10,
    })
    delRedDot(armourTab)

    local armourMenu = CCMenu:createWithItem(armourTab)
    armourMenu:setPosition(0, 0)
    layer:addChild(armourMenu, 3) 

    -- shoe tab
    local shoeTab0 = img.createUISprite(img.ui.smith_shoe0)
    shoeTab1 = img.createUISprite(img.ui.smith_shoe0)
    shoeTab2 = img.createUISprite(img.ui.smith_shoe1)

    local shoeTab = CCMenuItemSprite:create(shoeTab0, shoeTab1, shoeTab2)
    shoeTab:setScale(view.minScale)
    shoeTab:setPosition(scalep(916, 576-366))
    addRedDot(shoeTab, {
        px=shoeTab:getContentSize().width-10,
        py=shoeTab:getContentSize().height-10,
    })
    delRedDot(shoeTab)

    local shoeMenu = CCMenu:createWithItem(shoeTab)
    shoeMenu:setPosition(0, 0)
    layer:addChild(shoeMenu, 3) 

    -- jewelry tab
    local jewelryTab0 = img.createUISprite(img.ui.smith_jewelry0)
    jewelryTab1 = img.createUISprite(img.ui.smith_jewelry0)
    jewelryTab2 = img.createUISprite(img.ui.smith_jewelry1)

    local jewelryTab = CCMenuItemSprite:create(jewelryTab0, jewelryTab1, jewelryTab2)
    jewelryTab:setScale(view.minScale)
    jewelryTab:setPosition(scalep(916, 576-456))
    addRedDot(jewelryTab, {
        px=jewelryTab:getContentSize().width-10,
        py=jewelryTab:getContentSize().height-10,
    })
    delRedDot(jewelryTab)

    local jewelryMenu = CCMenu:createWithItem(jewelryTab)
    jewelryMenu:setPosition(0, 0)
    layer:addChild(jewelryMenu, 3) 
    
    local function checkReddot()
        for _ = 1,4 do
            local equips = createScrolls(_)
            local redflag = false
            for i, eq in ipairs(equips) do
                if bagdata.equips.count(cfgequip[eq.id].needFormula[1].id) >= cfgequip[eq.id].needFormula[1].count then
                    redflag = true
                    break
                    --icons[i].redIcon:setVisible(true)
                end
            end
            if redflag == true then
                if _ == 1 then
                    addRedDot(weaponTab, {
                        px=weaponTab:getContentSize().width-10,
                        py=weaponTab:getContentSize().height-10,
                    })
                elseif _ == 2 then
                    addRedDot(armourTab, {
                        px=armourTab:getContentSize().width-10,
                        py=armourTab:getContentSize().height-10,
                    })
                elseif _ == 3 then
                    addRedDot(jewelryTab, {
                        px=jewelryTab:getContentSize().width-10,
                        py=jewelryTab:getContentSize().height-10,
                    })
                else
                    addRedDot(shoeTab, {
                        px=shoeTab:getContentSize().width-10,
                        py=shoeTab:getContentSize().height-10,
                    })
                end
            else
                if _ == 1 then
                    delRedDot(weaponTab)
                elseif _ == 2 then
                    delRedDot(armourTab)
                elseif _ == 3 then
                    delRedDot(jewelryTab)
                else
                    delRedDot(shoeTab)
                end
            end
        end
    end

    local forgeLayer = createForgeLayer(bag, checkReddot)
    forgeLayer:setPosition(0, 0)
    layer:addChild(forgeLayer, 10)

    if player.lv() <= 40 then
        checkReddot()
    end
    local function onForgeFilter()
        local equips = createScrolls(currentForge)
        bag.showEquips(kind, equips)

        local equipMat = {id = cfgequip[bag.icons[1].data.id].needFormula[1].id, num = cfgequip[bag.icons[1].data.id].needFormula[1].count}
        local goldMat = cfgequip[bag.icons[1].data.id].needFormula[1].gold
        bag.data = bag.icons[1].data
        bag.redIcon = bag.icons[1].redIcon
        forgeLayer.putScroll(equipMat, goldMat)

        bag.icons[1].setGridSelected(true)
        bag.ID = 1
    end
    
    weaponTab:registerScriptTapHandler(function()
        audio.play(audio.button)
        currentForge = 1
        weaponTab:setEnabled(false)
        armourTab:setEnabled(true)
        shoeTab:setEnabled(true)
        jewelryTab:setEnabled(true)

        onForgeFilter()
    end)

    armourTab:registerScriptTapHandler(function()
        audio.play(audio.button)
        currentForge = 2
        weaponTab:setEnabled(true)
        armourTab:setEnabled(false)
        shoeTab:setEnabled(true)
        jewelryTab:setEnabled(true)

        onForgeFilter()
    end)

    shoeTab:registerScriptTapHandler(function()
        audio.play(audio.button)
        currentForge = 4
        weaponTab:setEnabled(true)
        armourTab:setEnabled(true)
        shoeTab:setEnabled(false)
        jewelryTab:setEnabled(true)

        onForgeFilter()
    end)

    jewelryTab:registerScriptTapHandler(function()
        audio.play(audio.button)
        currentForge = 3
        weaponTab:setEnabled(true)
        armourTab:setEnabled(true)
        shoeTab:setEnabled(true)
        jewelryTab:setEnabled(false)

        onForgeFilter()
    end)

    local forgeLab = lbl.createMixFont1(14, i18n.global.smith_forge_prompt.string, ccc3(0x73, 0x3b, 0x05), view.minScale)
    forgeLab:setPosition(scalep(688, 576-105))
    layer:addChild(forgeLab)

    local function showSmith()
        bag.showEquips(kind, createScrolls(currentForge))

        local equipMat = {id = cfgequip[bag.icons[1].data.id].needFormula[1].id, num = cfgequip[bag.icons[1].data.id].needFormula[1].count}
        local goldMat = cfgequip[bag.icons[1].data.id].needFormula[1].gold
        bag.data = bag.icons[1].data
        bag.redIcon = bag.icons[1].redIcon
        forgeLayer.putScroll(equipMat, goldMat)

        bag.icons[1].setGridSelected(true)
        bag.ID = 1
    end

    local detailSprite = img.createUISprite(img.ui.btn_help)
    local detailBtn = SpineMenuItem:create(json.ui.button, detailSprite)
    detailBtn:setScale(view.minScale)
    detailBtn:setPosition(scalep(930, 576-27))

    local detailMenu = CCMenu:create()
    detailMenu:setPosition(0, 0)
    layer:addChild(detailMenu, 20)
    detailMenu:addChild(detailBtn)

    detailBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer:addChild(require("ui.help").create(i18n.global.help_smith.string), 1000)
    end)

    autoLayoutShift(detailBtn)

    -- back 
    local back0 = img.createUISprite(img.ui.back)
    local backBtn = HHMenuItem:create(back0)
    backBtn:setScale(view.minScale)
    backBtn:setPosition(scalep(35, 546))
    local backMenu = CCMenu:createWithItem(backBtn)
    backMenu:setPosition(0, 0)
    layer:addChild(backMenu, 20)
    local function backEvent()
        audio.play(audio.button)
        if uiParams and uiParams.from_layer == "task" then
            replaceScene(require("ui.town.main").create({from_layer="task"}))  
        else
            replaceScene(require("ui.town.main").create())
        end
    end
    backBtn:registerScriptTapHandler(function()
        backEvent()
    end)

    autoLayoutShift(backBtn)

    bag.setClickHandler(function(icon)
        if layer.tipsTag then return end
        audio.play(audio.button)
        local datas = {}
        for i, _ in ipairs(bag.icons) do
            datas[i] = _.data
        end
        bag.data = icon.data
        bag.redIcon = icon.redIcon
        local equipMat = {id = cfgequip[icon.data.id].needFormula[1].id, num = cfgequip[icon.data.id].needFormula[1].count}
        local goldMat = cfgequip[icon.data.id].needFormula[1].gold
        forgeLayer.putScroll(equipMat, goldMat)
    end)

    function layer.onAndroidBack()
        backEvent()
    end

    addBackEvent(layer) 
    
    local function onEnter()
        layer.notifyParentLock()
        showSmith()
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
            img.unload(img.packedOthers.spine_ui_blacksmith_1)
            img.unload(img.packedOthers.spine_ui_blacksmith_2)
            img.unload(img.packedOthers.ui_smith_bg)
            img.unload(img.packedOthers.ui_smith)
        end
    end)

    return layer
end

return ui
