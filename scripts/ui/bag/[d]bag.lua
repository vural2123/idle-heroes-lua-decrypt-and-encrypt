local bag = {}

require "common.func"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local cfgequip = require "config.equip"
local cfgitem = require "config.item"
local i18n = require "res.i18n"
local empty = require "ui.empty"

function bag.create()
    local layer = CCLayer:create()
    
    --outer bg
    local outerBg = img.createUI9Sprite(img.ui.bag_outer)
    outerBg:setPreferredSize(CCSizeMake(838, 502))
    outerBg:setAnchorPoint(0.5, 1)
    outerBg:setScale(view.minScale)
    outerBg:setPosition(scalep(480, 520))
    layer:addChild(outerBg)
   
    --inner bg
    local innerBg = img.createUI9Sprite(img.ui.bag_btn_inner_bg)
    innerBg:setPreferredSize(CCSizeMake(780, 404))
    innerBg:setScale(view.minScale)
    innerBg:setAnchorPoint(0.5, 1)
    innerBg:setPosition(scalep(480, 498))
    layer:addChild(innerBg)
    
    --scroll const
    local GRID_SCREEN = 32
    local GRID_COLUMN = 8
    local GRID_WIDTH = 84
    local GRID_HEIGHT = 84
    local GAP_HORIZONTAL = 7
    local GAP_VERTICAL = 7
    local MARGIN_TOP = 14
    local MARGIN_BOTTOM = 14
    local MARGIN_LEFT = 28
    local VIEW_WIDTH = innerBg:getContentSize().width
    local VIEW_HEIGHT = 382

    -- scroll
    local scroll = CCScrollView:create()
    scroll:setDirection(kCCScrollViewDirectionVertical)
    scroll:setAnchorPoint(0, 0)
    scroll:setPosition(0, 12)
    scroll:setViewSize(CCSize(VIEW_WIDTH, VIEW_HEIGHT))
    innerBg:addChild(scroll)
    layer.scroll = scroll

    -- grids and icons
    local grids = {}
    local icons = {}
    local qlts = {}
    layer.grids = grids
    layer.icons = icons
    layer.qlts = qlts 
    layer.emptyBox = nil
    -- batchNode, 渲染优化:
    -- grid batchNode
    --local gridBatch = img.createBatchNodeForUI(img.ui.grid)
    --scroll:getContainer():addChild(gridBatch)

    -- 获取第i个格子的坐标
    -- type = 1 表示获取的是装备或者英雄碎片
    local function getPosition(i, type)
        local x0 = MARGIN_LEFT
        local y0 = scroll:getContentSize().height - MARGIN_TOP - GRID_HEIGHT
        local x = x0 + math.floor((i-1)%GRID_COLUMN) * (GRID_WIDTH+GAP_HORIZONTAL)
        local y = y0
        if type ~= 1 then
            y = y - math.floor((i-1)/GRID_COLUMN) * (GRID_HEIGHT+GAP_VERTICAL)
        else
            y = y - math.floor((i-1)/GRID_COLUMN) * (GRID_HEIGHT+GAP_VERTICAL+34)    
        end
        return x, y
    end

    --init scroll
    local function initScroll(gridnum, bagType,  keepOldPosition)
        local pieceheight = 0
        if bagType ~= "piece" then
            if gridnum < 32 then
                gridnum = 32
            end
        else
            if gridnum < 24 then 
                gridnum = 24   
            end
            pieceheight = 36
        end
        for i, _ in pairs(icons) do
            if icons[i].gridSelected then
                icons[i].gridSelected:removeFromParent()
            end
            if icons[i].qlts then
                icons[i].qlts:removeFromParent()
            end
            icons[i].currentbag = nil
            icons[i]:removeFromParent()
            icons[i].gridSelected = nil
            icons[i].qlts = nil
            icons[i] = nil
        end
        if layer.emptyBox then
            layer.emptyBox:removeFromParent()
            layer.emptyBox = nil
        end
        local rownum = math.ceil(gridnum/GRID_COLUMN)
        local height = MARGIN_TOP + MARGIN_BOTTOM + rownum*GRID_HEIGHT + (rownum-1)*(pieceheight+GAP_VERTICAL)
        local contentOffsetY = scroll:getContentOffset().y  
        if not keepOldPosition then
            contentOffsetY = VIEW_HEIGHT-height
        elseif contentOffsetY > 0 then
            contentOffsetY = 0
        elseif contentOffsetY < VIEW_HEIGHT-height then
            contentOffsetY = VIEW_HEIGHT-height
        end

        scroll:setContentSize(CCSize(VIEW_WIDTH, height))
        scroll:setContentOffset(ccp(0, contentOffsetY))
    end

    --init grids
    local function initGrids(gridnum, currentbag)
        --for i = 1, math.max(#grids, gridnum) do
        --    if grids[i] ~= nil and i>gridnum then
        --        grids[i]:removeFromParent()
        --        grids[i] = nil
        --    elseif grids[i] == nil and i <= gridnum then
        --        grids[i] = img.createUISprite(img.ui.grid)
        --        grids[i]:setAnchorPoint(ccp(0, 0))
        --        gridBatch:addChild(grids[i])
        --    end
        --    if grids[i] ~= nil then
        --        local x, y = getPosition(i, 0)
        --        grids[i]:setPosition(x, y)
        --    end
        --end
    end

    -- 选中状态
    local function addFunctionsForIcon(icon, i)
        function icon.isGridSelected()
            return icon.gridSelected ~= nil and icon.gridSelected:isVisible()
        end

        function icon.setGridSelected(b)
            if icon.gridSelected == nil then
                icon.gridSelected = img.createUISprite(img.ui.bag_grid_selected)
                icon.gridSelected:setAnchorPoint(ccp(0, 0))
                if icons[i].currentbag == "equip" then
                    local x, y = icons[i]:getPosition()
                    icon.gridSelected:setPosition(x, y)
                elseif icons[i].currentbag == "item" then
                    icon.gridSelected:setPosition(icons[i]:getPosition())
                else
                    icon.gridSelected:setPosition(icons[i]:getPosition())
                end
                local gridSelectedBatch = img.createBatchNodeForUI(img.ui.bag_grid_selected)
                scroll:getContainer():addChild(gridSelectedBatch)
                gridSelectedBatch:addChild(icon.gridSelected)
            end
            icon.gridSelected:setVisible(b)
        end
    end

    --show equips
    function layer.showEquips(equips, keepOldPosition)
        table.sort(equips, compareEquip)
        initScroll(#equips, "equip", keepOldPosition)
        --initGrids(#equips, "equip")
        if #equips == 0 then
            layer.emptyBox = empty.create({text = i18n.global.empty_equips.string})
            layer.emptyBox:setPosition(innerBg:getContentSize().width/2, innerBg:getContentSize().height/2)            
            innerBg:addChild(layer.emptyBox)
            return 
        end

        for i, eq in ipairs(equips) do
            local x, y = getPosition(i, 0)
            
            -- 装备
            icons[i] = img.createEquip(eq.id, eq.num)
            icons[i]:setAnchorPoint(ccp(0, 0))
            icons[i]:setPosition(x, y)
            icons[i].data = eq
            icons[i].tipTag = false
            scroll:getContainer():addChild(icons[i])
            
            icons[i].currentbag = "equip"
            ---- 品质
            --icons[i].qlts = img.createEquipQualityBg(eq.id)
            --icons[i].qlts:setAnchorPoint(ccp(0, 0))
            --icons[i].qlts:setPosition(x+5, y+5)
            --qltBatch:addChild(icons[i].qlts)
            
            addFunctionsForIcon(icons[i], i) 
        end
    end

    --show items
    function layer.showItems(items, keepOldPosition)
        table.sort(items, compareItem)
        initScroll(#items, "item", keepOldPosition)
        --initGrids(#items, "item")
        if #items == 0 then
            layer.emptyBox = empty.create({text = i18n.global.empty_items.string})
            layer.emptyBox:setPosition(innerBg:getContentSize().width/2, innerBg:getContentSize().height/2)            
            innerBg:addChild(layer.emptyBox)
            return 
        end
        for i, item in ipairs(items) do
            local x, y = getPosition(i, 0)
            icons[i] = img.createItem(item.id, item.num)
            icons[i]:setAnchorPoint(ccp(0, 0))
            icons[i]:setPosition(x, y)
            icons[i].data = item
            scroll:getContainer():addChild(icons[i])
            icons[i].currentbag = "item"
            addFunctionsForIcon(icons[i], i)
        end
    end

    --show pieces
    function layer.showPieces(pieces)
        table.sort(pieces, compareHeroPiece)
        initScroll(#pieces, "piece")
        --initGrids(0, "piece")
        if #pieces == 0 then
            layer.emptyBox = empty.create({text = i18n.global.empty_pieces.string})
            layer.emptyBox:setPosition(innerBg:getContentSize().width/2, innerBg:getContentSize().height/2)            
            innerBg:addChild(layer.emptyBox)
            return 
        end
        for i, piece in ipairs(pieces) do
            local x, y = getPosition(i, 1)
            icons[i] = img.createItem(piece.id)
            icons[i]:setAnchorPoint(ccp(0, 0))
            icons[i]:setPosition(x, y)
            icons[i].data = piece
            scroll:getContainer():addChild(icons[i])
            icons[i].currentbag = "pieces"
            
            local progressBg = img.createUISprite(img.ui.bag_heropiece_progr)
            progressBg:setPosition(41, -10)
            icons[i]:addChild(progressBg)

            local costCount = 1
            if cfgitem[piece.id].type == ITEM_KIND_TREASURE_PIECE then
                costCount = cfgitem[piece.id].treasureCost.count
            else
                costCount = cfgitem[piece.id].heroCost.count
            end

            local progressFgSprite = nil 
            if piece.num < costCount then
                progressFgSprite = img.createUISprite(img.ui.bag_heropiece_progr_0)
            else
                progressFgSprite = img.createUISprite(img.ui.bag_heropiece_progr_1)
            end
           
            local progressFg = createProgressBar(progressFgSprite) 
            progressFg:setPosition(41, -10)
            progressFg:setPercentage(piece.num / costCount * 100)
            icons[i]:addChild(progressFg)

            local str = string.format("%d/%d", piece.num, costCount)
            local label = lbl.createFont2(14, str, ccc3(255, 246, 223))
            label:setPosition(41, -11)
            icons[i]:addChild(label)
            addFunctionsForIcon(icons[i], i)
        end
    end

    --show equippieces
    --function layer.showEquipPieces(equippieces)
    --    table.sort(equippieces, compareScrollPiece)
    --    initScroll(#equippieces)
    --    initGrids(#equippieces, "equippiece")
    --    for i, piece in ipairs(equippieces) do
    --        local x, y = getPosition(i, 1)
    --        icons[i] = img.createItem(piece.id)
    --        icons[i]:setAnchorPoint(ccp(0, 0))
    --        icons[i]:setPosition(x, y)
    --        icons[i].data = piece
    --        scroll:getContainer():addChild(icons[i])
    --        icons[i].currentbag = "equippiece"
            
    --        -- 品质 
    --        --local qlts = img.createEquipPieceQualityBg(piece.id)
    --        --qlts:setScale(0.89)
    --        --qlts:setAnchorPoint(ccp(0, 0))
    --        --qlts:setPosition(x+5, y+5)
    --        --icons[i]:addChild(qlts)
            
    --        local progressBg = img.createUISprite(img.ui.bag_heropiece_progr)
    --        progressBg:setPosition(41, -10)
    --        icons[i]:addChild(progressBg)
            
    --        local progressFgSprite = nil 
    --        if piece.num < cfgitem[piece.id].itemCost.count then
    --            progressFgSprite = img.createUISprite(img.ui.bag_heropiece_progr_0)
    --        else
    --            progressFgSprite = img.createUISprite(img.ui.bag_heropiece_progr_1)
    --        end
    --        local progressFg = createProgressBar(progressFgSprite) 
    --        progressFg:setPosition(41, -10)
    --        progressFg:setPercentage(piece.num / cfgitem[piece.id].itemCost.count * 100)
    --        icons[i]:addChild(progressFg)

    --        local str = string.format("%d/%d", piece.num, cfgitem[piece.id].itemCost.count)
    --        local label = lbl.createFont1(14, str)
    --        label:setPosition(41, -11)
    --        icons[i]:addChild(label)
            
    --        addFunctionsForIcon(icons[i], i)
    --    end
    --end

    --show pieces
    function layer.showTreasure(treasureAry)
        table.sort(treasureAry, compareEquip)
        initScroll(#treasureAry, "treasure")
        --initGrids(0, "piece")
        if #treasureAry == 0 then
            layer.emptyBox = empty.create({text = i18n.global.empty_treasure.string})
            layer.emptyBox:setPosition(innerBg:getContentSize().width/2, innerBg:getContentSize().height/2)            
            innerBg:addChild(layer.emptyBox)
            return 
        end
        for i, treasure in ipairs(treasureAry) do
            local x, y = getPosition(i, 0)
            icons[i] = img.createEquip(treasure.id, treasure.num)
            icons[i]:setAnchorPoint(ccp(0, 0))
            icons[i]:setPosition(x, y)
            icons[i].data = treasure
            scroll:getContainer():addChild(icons[i])
            icons[i].currentbag = "treasure"

            if cfgitem[treasure.id] then
                local progressBg = img.createUISprite(img.ui.bag_heropiece_progr)
                progressBg:setPosition(41, -10)
                icons[i]:addChild(progressBg)

                local costCount = cfgitem[treasure.id].treasureCost.count

                local progressFgSprite = nil 
                if treasure.num < costCount then
                    progressFgSprite = img.createUISprite(img.ui.bag_heropiece_progr_0)
                else
                    progressFgSprite = img.createUISprite(img.ui.bag_heropiece_progr_1)
                end
               
                local progressFg = createProgressBar(progressFgSprite) 
                progressFg:setPosition(41, -10)
                progressFg:setPercentage(treasure.num / costCount * 100)
                icons[i]:addChild(progressFg)

                local str = string.format("%d/%d", treasure.num, costCount)
                local label = lbl.createFont2(14, str, ccc3(255, 246, 223))
                label:setPosition(41, -11)
                icons[i]:addChild(label)
            end

            addFunctionsForIcon(icons[i], i)
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

    local function onTouchBegan(x, y)
        touchbeginx, touchbeginy = x, y
        isclick = true
        return true
    end

    local function onTouchMoved(x, y)
        if isclick and (math.abs(touchbeginx-x) > 10 or math.abs(touchbeginy-y) > 10) then
            isclick = false
        end
    end

    local function onTouchEnded(x, y)
        if isclick then
            local p0 = scroll:getParent():convertToNodeSpace(ccp(x,y))
            if scroll:getBoundingBox():containsPoint(p0) then
                local p1
                if #icons > 0 then
                    p1 = icons[1]:getParent():convertToNodeSpace(ccp(x, y))
                end
                for _, icon in ipairs(icons) do
                    if p1 and icon:boundingBox():containsPoint(p1) then
                        for _, ic in ipairs(icons) do
                            if ic.isGridSelected() then
                                ic.setGridSelected(false)
                            end
                        end
                        icon.setGridSelected(true)
                        if clickHandler then
                            clickHandler(icon)
                        end
                        return
                    end
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

    function layer.onAndroidBack()
        layer:removeFromParentAndCleanup(true)
    end
    
    addBackEvent(layer)

    local function onEnter()
        layer.notifyParentLock()
    end

    local function onExit()
        layer.notifyParentUnlock()
    end

    layer:registerScriptTouchHandler(onTouch)
    layer:setTouchEnabled(true)
    
    layer:registerScriptHandler(function(event)
        if event == "enter" then
            onEnter()
        elseif event == "exit" then
            onExit()
        end
    end)

    return layer    
end

return bag
