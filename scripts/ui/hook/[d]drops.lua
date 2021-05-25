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

function ui.create(_bag, title, imdClose)
    local layer = CCLayer:create()
    -- dark bg
    local darkbg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    layer:addChild(darkbg)
    -- board_bg
    local board_bg = img.createUI9Sprite(img.ui.dialog_1)
    board_bg:setPreferredSize(CCSizeMake(645, 496))
    board_bg:setScale(view.minScale)
    board_bg:setPosition(view.midX-0*view.minScale, view.midY)
    layer:addChild(board_bg)
    local board_bg_w = board_bg:getContentSize().width
    local board_bg_h = board_bg:getContentSize().height

    -- anim
    board_bg:setScale(0.5*view.minScale)
    board_bg:runAction(CCScaleTo:create(0.15, 1*view.minScale, 1*view.minScale))

    -- title
    if not title then
        title = i18n.global.hook_drop_board_title.string
    end

    local lbl_title = lbl.createFont1(24, title, ccc3(0xe6, 0xd0, 0xae))
    lbl_title:setPosition(CCPoint(board_bg_w/2, board_bg_h-29))
    board_bg:addChild(lbl_title, 2)
    local lbl_title_shadowD = lbl.createFont1(24, title, ccc3(0x59, 0x30, 0x1b))
    lbl_title_shadowD:setPosition(CCPoint(board_bg_w/2, board_bg_h-31))
    board_bg:addChild(lbl_title_shadowD)

    local function backEvent()
        audio.play(audio.button)
        layer:removeFromParentAndCleanup(true)
    end

    local board = img.createUI9Sprite(img.ui.bag_btn_inner_bg)
    board:setPreferredSize(CCSizeMake(594, 334))
    board:setAnchorPoint(CCPoint(0.5, 0))
    board:setPosition(CCPoint(board_bg_w/2, 92))
    board_bg:addChild(board)
    local board_w = board:getContentSize().width
    local board_h = board:getContentSize().height

    local btn_hook0 = img.createLogin9Sprite(img.login.button_9_small_gold)
    btn_hook0:setPreferredSize(CCSizeMake(158, 54))
    local closeText = i18n.global.hook_drop_btn_get.string
    if imdClose then
        closeText = i18n.global.dialog_button_confirm.string
    end
    local lbl_btn_hook = lbl.createFont1(22, closeText, ccc3(0x73, 0x3b, 0x05))
    lbl_btn_hook:setPosition(CCPoint(btn_hook0:getContentSize().width/2, btn_hook0:getContentSize().height/2))
    btn_hook0:addChild(lbl_btn_hook)
    local btn_hook = SpineMenuItem:create(json.ui.button, btn_hook0)
    btn_hook:setPosition(CCPoint(board_bg_w/2, 53))
    local btn_hook_menu = CCMenu:createWithItem(btn_hook)
    btn_hook_menu:setPosition(CCPoint(0, 0))
    board_bg:addChild(btn_hook_menu)

    -- drops
    local SCROLL_VIEW_W = 545
    local SCROLL_VIEW_H = 306
    local scroll = CCScrollView:create()
    scroll:setDirection(kCCScrollViewDirectionVertical)
    scroll:setViewSize(CCSize(SCROLL_VIEW_W, SCROLL_VIEW_H))
    scroll:setContentSize(CCSize(SCROLL_VIEW_W, SCROLL_VIEW_H))
    scroll:setAnchorPoint(CCPoint(0, 0))
    scroll:setPosition(CCPoint(25, 15))
    board:addChild(scroll)
    --drawBoundingbox(board, scroll)
    
    local content_layer = CCLayer:create()
    content_layer:setAnchorPoint(CCPoint(0, 0))
    content_layer:setPosition(CCPoint(0, 0))
    scroll:getContainer():addChild(content_layer)
    scroll.content_layer = content_layer

    local function createItem(itemObj)
        if itemObj.type == ItemType.Equip then  -- equip
            if cfgequip[itemObj.id].pos ~= EQUIP_POS_SKIN then
                return img.createEquip(itemObj.id, itemObj.num)
            end
        elseif itemObj.type == ItemType.Item then
            return img.createItem(itemObj.id, itemObj.num)
        end
    end

    local rewards = {}
    if _bag.equips then
        for ii=1,#_bag.equips do
            rewards[#rewards+1] = {
                type = ItemType.Equip,
                id = _bag.equips[ii].id,
                num = _bag.equips[ii].num,
            }
        end
    end
    if _bag.items then
        for ii=1,#_bag.items do
            rewards[#rewards+1] = {
                type = ItemType.Item,
                id = _bag.items[ii].id,
                num = _bag.items[ii].num,
            }
        end
    end

    local items = {}

    local item_offset_x = 46
    local item_offset_y = 54
    local item_step_x = 91
    local item_step_y = 95
    local row_count = 6
    local function showList()
        arrayclear(items)
        content_layer:removeAllChildrenWithCleanup(true)
        local height = 0
        local count = 0
        for ii=1, #rewards do
            local tmp_item = createItem(rewards[ii])
            if tmp_item then
                count = count + 1
                tmp_item.obj = rewards[ii]
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
    showList()

    local function onClickItem(itemObj)
        if itemObj.obj.type == ItemType.Equip then  -- equip
            layer:addChild(tipsequip.createById(itemObj.obj.id), 100)
        elseif itemObj.obj.type == ItemType.Item then  -- item 
            layer:addChild(tipsitem.createForShow({id=itemObj.obj.id}), 100)
        end
    end

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

    btn_hook:registerScriptTapHandler(function()
        if not imdClose then
            showToast(i18n.global.hook_get_ok.string)
        end
        backEvent()
    end)

    return layer
end

return ui
