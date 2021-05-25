local ui = {}

require "common.func"
require "common.const"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local audio = require "res.audio"
local cfgitem = require "config.item"
local cfgequip = require "config.equip"
local cfgstage = require "config.stage"
local player = require "data.player"
local bagdata = require "data.bag"
local hookdata = require "data.hook"
local i18n = require "res.i18n"
local tipsequip = require "ui.tips.equip"
local tipsitem = require "ui.tips.item"

local ItemType = {
    Item = 1,
    Equip = 2,
}

function ui.create()
    local layer = CCLayer:create()
    -- dark bg
    local darkbg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    layer:addChild(darkbg)
    -- board_bg
    local board_bg = img.createUI9Sprite(img.ui.dialog_1)
    board_bg:setPreferredSize(CCSizeMake(740, 491))
    board_bg:setScale(view.minScale)
    board_bg:setPosition(view.midX-0*view.minScale, view.midY)
    layer:addChild(board_bg)
    local board_bg_w = board_bg:getContentSize().width
    local board_bg_h = board_bg:getContentSize().height

    -- anim
    board_bg:setScale(0.5*view.minScale)
    board_bg:runAction(CCScaleTo:create(0.15, 1*view.minScale, 1*view.minScale))

    -- title
    --if not title then
    --    title = i18n.global.hook_drop_board_title.string
    --end

    local lbl_title = lbl.createFont1(24, i18n.global.bag_treasureshow_title.string, ccc3(0xe6, 0xd0, 0xae))
    lbl_title:setPosition(CCPoint(board_bg_w/2, board_bg_h-29))
    board_bg:addChild(lbl_title, 2)
    local lbl_title_shadowD = lbl.createFont1(24, i18n.global.bag_treasureshow_title.string, ccc3(0x59, 0x30, 0x1b))
    lbl_title_shadowD:setPosition(CCPoint(board_bg_w/2, board_bg_h-31))
    board_bg:addChild(lbl_title_shadowD)

    local function backEvent()
        audio.play(audio.button)
        layer:removeFromParentAndCleanup(true)
    end

    local board = img.createUI9Sprite(img.ui.bag_btn_inner_bg)
    board:setPreferredSize(CCSizeMake(684, 337))
    board:setAnchorPoint(CCPoint(0.5, 0))
    board:setPosition(CCPoint(board_bg_w/2, 84))
    board_bg:addChild(board)
    local board_w = board:getContentSize().width
    local board_h = board:getContentSize().height

    -- btn_close
    local btn_close0 = img.createUISprite(img.ui.close)
    local btn_close = SpineMenuItem:create(json.ui.button, btn_close0)
    btn_close:setPosition(CCPoint(board_bg_w-25, board_bg_h-28))
    local btn_close_menu = CCMenu:createWithItem(btn_close)
    btn_close_menu:setPosition(CCPoint(0, 0))
    board_bg:addChild(btn_close_menu, 100)
    btn_close:registerScriptTapHandler(function()
        backEvent()
    end)

    -- drops
    local SCROLL_VIEW_W = 650
    local SCROLL_VIEW_H = 315
    local scroll = CCScrollView:create()
    scroll:setDirection(kCCScrollViewDirectionVertical)
    scroll:setViewSize(CCSize(SCROLL_VIEW_W, SCROLL_VIEW_H))
    scroll:setContentSize(CCSize(SCROLL_VIEW_W, SCROLL_VIEW_H))
    scroll:setAnchorPoint(CCPoint(0, 0))
    scroll:setPosition(CCPoint(25, 12))
    board:addChild(scroll)
    --drawBoundingb
    
    local content_layer = CCLayer:create()
    content_layer:setAnchorPoint(CCPoint(0, 0))
    content_layer:setPosition(CCPoint(0, 0))
    scroll:getContainer():addChild(content_layer)
    scroll.content_layer = content_layer

    local items = {}

    local item_offset_x = 46
    local item_offset_y = 54
    local item_step_x = 91
    local item_step_y = 95
    local row_count = 7
    local equips = {}
    local currentfilter = 0

    local function compareTreasure(a, b)
        -- 品质高的排在前面
        local qlt1, qlt2 = cfgequip[a.id].qlt, cfgequip[b.id].qlt
        if qlt1 < qlt2 then
            return true
        elseif qlt1 > qlt2 then
            return false
        end

        return a.id < b.id
    end

    for i = 5000, 6000 do
        if cfgequip[i] == nil then break end
        if cfgequip[i].treasureNext == nil then
            equips[#equips+1] = cfgequip[i]
            equips[#equips].id = i
        end
    end
    table.sort(equips, compareTreasure)

    local function showList(filter)
        arrayclear(items)
        content_layer:removeAllChildrenWithCleanup(true)
        local height = 0
        local count = 0
        for ii = 1,#equips do
            if filter == 0 or filter == cfgequip[equips[ii].id].qlt then
                local tmp_item = img.createEquip(equips[ii].id)
                count = count + 1
                tmp_item.obj = equips[ii]
                local pos_x = item_offset_x + item_step_x*((count-1)%row_count)
                local pos_y = item_offset_y + item_step_y*(math.floor((count+row_count-1)/row_count)-1)
                tmp_item:setPosition(CCPoint(pos_x, 0 - pos_y))
                content_layer:addChild(tmp_item)
                items[#items+1] = tmp_item
                height = pos_y + 47
            end
        end
        if height < SCROLL_VIEW_H then
            scroll:setContentSize(CCSizeMake(SCROLL_VIEW_W, SCROLL_VIEW_H))
            content_layer:setPosition(CCPoint(0, SCROLL_VIEW_H))
            scroll:setContentOffset(CCPoint(0, 0))
        else
            scroll:setContentSize(CCSizeMake(SCROLL_VIEW_W, height))
            content_layer:setPosition(CCPoint(0, height))
            scroll:setContentOffset(CCPoint(0, SCROLL_VIEW_H-height))
        end
    end
    showList(currentfilter)

    local function onClickItem(itemObj)
        layer:addChild(tipsequip.createById(itemObj.obj.id), 100)
    end

    --batch btn
    local orangeBatchbtn0 = img.createUISprite(img.ui.bag_btn_orange)
    local orangeBatchBtn = HHMenuItem:create(orangeBatchbtn0)
    --orangeBatchBtn:setScale(view.minScale)
    orangeBatchBtn:setPosition(326-110, 50)

    local orangeBatchMenu = CCMenu:createWithItem(orangeBatchBtn)
    orangeBatchMenu:setPosition(0, 0)
    board_bg:addChild(orangeBatchMenu)
    
    local redBatchbtn0 = img.createUISprite(img.ui.bag_btn_red)
    local redBatchBtn = HHMenuItem:create(redBatchbtn0)
    --redBatchBtn:setScale(view.minScale)
    redBatchBtn:setPosition(385-110, 50)

    local redBatchMenu = CCMenu:createWithItem(redBatchBtn)
    redBatchMenu:setPosition(0, 0)
    board_bg:addChild(redBatchMenu)

    local greenBatchbtn0 = img.createUISprite(img.ui.bag_btn_green)
    local greenBatchBtn = HHMenuItem:create(greenBatchbtn0)
    --greenBatchBtn:setScale(view.minScale)
    greenBatchBtn:setPosition(448-110, 50)

    local greenBatchMenu = CCMenu:createWithItem(greenBatchBtn)
    greenBatchMenu:setPosition(0, 0)
    board_bg:addChild(greenBatchMenu)

    local purpleBatchbtn0 = img.createUISprite(img.ui.bag_btn_purple)
    local purpleBatchBtn = HHMenuItem:create(purpleBatchbtn0)
    --purpleBatchBtn:setScale(view.minScale)
    purpleBatchBtn:setPosition(510-110, 50)

    local purpleBatchMenu = CCMenu:createWithItem(purpleBatchBtn)
    purpleBatchMenu:setPosition(0, 0)
    board_bg:addChild(purpleBatchMenu)

    local yellowBatchbtn0 = img.createUISprite(img.ui.bag_btn_yellow)
    local yellowBatchBtn = HHMenuItem:create(yellowBatchbtn0)
    --yellowBatchBtn:setScale(view.minScale)
    yellowBatchBtn:setPosition(572-110, 50)

    local yellowBatchMenu = CCMenu:createWithItem(yellowBatchBtn)
    yellowBatchMenu:setPosition(0, 0)
    board_bg:addChild(yellowBatchMenu)

    local blueBatchbtn0 = img.createUISprite(img.ui.bag_btn_blue)
    local blueBatchBtn = HHMenuItem:create(blueBatchbtn0)
    --blueBatchBtn:setScale(view.minScale)
    blueBatchBtn:setPosition(634-110, 50)

    local blueBatchMenu = CCMenu:createWithItem(blueBatchBtn)
    blueBatchMenu:setPosition(0, 0)
    board_bg:addChild(blueBatchMenu)

    local selectBatch = img.createUISprite(img.ui.bag_dianji)
    --selectBatch:setScale(view.minScale)
    selectBatch:setPosition(-1000, -1000)
    board_bg:addChild(selectBatch)
    
    orangeBatchBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        if currentfilter == 6 then
            currentfilter = 0
            selectBatch:setVisible(false)
            showList(currentfilter)
            return
        end
        selectBatch:setVisible(true)
        selectBatch:setPosition(326-110, 52)     
        currentfilter = 6
        showList(currentfilter)
    end)

    redBatchBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        if currentfilter == 5 then
            currentfilter = 0
            selectBatch:setVisible(false)
            showList(currentfilter)
            return
        end
        selectBatch:setVisible(true)
        selectBatch:setPosition(385-110, 52)     
        currentfilter = 5
        showList(currentfilter)
    end)

    greenBatchBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        if currentfilter == 4 then
            currentfilter = 0
            selectBatch:setVisible(false)
            showList(currentfilter)
            return
        end
        selectBatch:setVisible(true)
        selectBatch:setPosition(448-110, 52)     
        currentfilter = 4
        showList(currentfilter)
    end)

    purpleBatchBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        if currentfilter == 3 then
            currentfilter = 0
            selectBatch:setVisible(false)
            showList(currentfilter)
            return
        end
        selectBatch:setVisible(true)
        selectBatch:setPosition(510-110, 52)     
        currentfilter = 3
        showList(currentfilter)
    end)

    yellowBatchBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        if currentfilter == 2 then
            currentfilter = 0
            selectBatch:setVisible(false)
            showList(currentfilter)
            return
        end
        selectBatch:setVisible(true)
        selectBatch:setPosition(572-110, 52)     
        currentfilter = 2
        showList(currentfilter)
    end)

    blueBatchBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        if currentfilter == 1 then
            currentfilter = 0
            selectBatch:setVisible(false)
            showList(currentfilter)
            return
        end
        selectBatch:setVisible(true)
        selectBatch:setPosition(634-110, 52)     
        currentfilter = 1
        showList(currentfilter)
    end)
    -- touch event
    local touchbeginx, touchbeginy
    local isclick
    local last_touch_sprite = nil
    local function onTouchBegan(x, y)
        touchbeginx, touchbeginy = x, y
        isclick = true
        if scroll and not tolua.isnull(scroll) then
            local p0 = content_layer:convertToNodeSpace(ccp(x, y))
            for ii=1,#items do
                if items[ii]:boundingBox():containsPoint(p0) then
                    playAnimTouchBegin(items[ii])
                    last_touch_sprite = items[ii]
                    break
                end
            end
        end
        return true
    end
    local function onTouchMoved(x, y)
        if isclick and (math.abs(touchbeginx-x) > 10 or math.abs(touchbeginy-y) > 10) then
            isclick = false
            if last_touch_sprite and not tolua.isnull(last_touch_sprite) then
                playAnimTouchEnd(last_touch_sprite)
                last_touch_sprite = nil
            end
        end
    end
    local function onTouchEnded(x, y)
        if last_touch_sprite and not tolua.isnull(last_touch_sprite) then
            playAnimTouchEnd(last_touch_sprite)
            last_touch_sprite = nil
        end
        if isclick and scroll and not tolua.isnull(scroll) then
            local p0 = content_layer:convertToNodeSpace(ccp(x, y))
            for ii=1,#items do
                if items[ii]:boundingBox():containsPoint(p0) then
                    audio.play(audio.button)
                    onClickItem(items[ii])
                    break
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
    layer:setTouchSwallowEnabled(true)

    addBackEvent(layer)
    function layer.onAndroidBack()
        backEvent()
    end
    local function onEnter()
        print("onEnter")
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
