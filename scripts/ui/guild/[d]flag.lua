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
local cfgguildflag = require "config.guildflag"
local gdata = require "data.guild"
local player = require "data.player"
local i18n = require "res.i18n"


function ui.create(callback, _sel_flag)
    _sel_flag = _sel_flag or 0
    local layer = CCLayer:create()

    -- dark bg
    local darkbg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    layer:addChild(darkbg)

    local function backEvent()
        audio.play(audio.button)
        layer:removeFromParentAndCleanup(true)
    end
    -- board
    local board = img.createUI9Sprite(img.ui.tips_bg)
    board:setPreferredSize(CCSizeMake(664, 414))
    board:setScale(view.minScale)
    board:setPosition(view.midX-0*view.minScale, view.midY)
    layer:addChild(board)
    local board_w = board:getContentSize().width
    local board_h = board:getContentSize().height
    
    board:setScale(0.5*view.minScale)
    local anim_arr = CCArray:create()
    anim_arr:addObject(CCScaleTo:create(0.15, 1*view.minScale, 1*view.minScale))
    -- anim
    board:runAction(CCSequence:create(anim_arr))

    -- title
    local lbl_title = lbl.createFont1(22, i18n.global.guild_flag_select_flag.string, ccc3(0xff, 0xe3, 0x86))
    lbl_title:setPosition(CCPoint(board_w/2, board_h-36))
    board:addChild(lbl_title)

    -- line
    local line = img.createUISprite(img.ui.help_line)
    line:setScaleX(610/line:getContentSize().width)
    line:setPosition(board_w/2, board_h-64)
    board:addChild(line)

    -- flags 
    local SCROLL_VIEW_W = 540
    local SCROLL_VIEW_H = 268
    local scroll = CCScrollView:create()
    scroll:setDirection(kCCScrollViewDirectionVertical)
    scroll:setViewSize(CCSize(SCROLL_VIEW_W, SCROLL_VIEW_H))
    scroll:setContentSize(CCSize(SCROLL_VIEW_W, SCROLL_VIEW_H))
    scroll:setAnchorPoint(CCPoint(0, 0))
    scroll:setPosition(CCPoint(62, 53))
    board:addChild(scroll)
    --drawBoundingbox(board, scroll)
    
    local content_layer = CCLayer:create()
    content_layer:setAnchorPoint(CCPoint(0, 0))
    content_layer:setPosition(CCPoint(0, 0))
    scroll:getContainer():addChild(content_layer)
    scroll.content_layer = content_layer

    local function createItem(itemObj)
        local item = img.createGFlag(itemObj.resId)
        local item_sel = img.createUISprite(img.ui.guild_icon_sel)
        item_sel:setAnchorPoint(CCPoint(1, 0))
        item_sel:setPosition(CCPoint(item:getContentSize().width, 0))
        item:addChild(item_sel)
        item.sel = item_sel
        item_sel:setVisible(_sel_flag == itemObj.resId)
        return item
    end

    local items = {}

    local item_offset_x = 38
    local item_offset_y = 36
    local item_step_x = 91
    local item_step_y = 96
    local row_count = 6
    local function showList()
        arrayclear(items)
        content_layer:removeAllChildrenWithCleanup(true)
        local height = 0
        for ii=1, #cfgguildflag do
            local tmp_item = createItem(cfgguildflag[ii])
            tmp_item.obj = cfgguildflag[ii]
            local pos_x = item_offset_x + item_step_x*((ii-1)%row_count)
            local pos_y = item_offset_y + item_step_y*(math.floor((ii+row_count-1)/row_count)-1)
            tmp_item:setPosition(CCPoint(pos_x, 0 - pos_y))
            content_layer:addChild(tmp_item)
            items[#items+1] = tmp_item
            height = pos_y + 45
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
        audio.play(audio.button)
        if not itemObj or tolua.isnull(itemObj) then return end
        for ii=1,#items do
            items[ii].sel:setVisible(false)
        end
        itemObj.sel:setVisible(true)
        if callback then
            callback(itemObj.obj.resId)
        end
        layer:removeFromParentAndCleanup(true)
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
        if isclick then
            local p0 = layer:convertToNodeSpace(ccp(x, y))
            if not board:boundingBox():containsPoint(p0) then
                backEvent()
                return
            end
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
