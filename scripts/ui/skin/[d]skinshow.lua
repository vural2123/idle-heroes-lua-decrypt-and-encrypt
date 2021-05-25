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
local cfghero = require "config.hero"
local player = require "data.player"
local bagdata = require "data.bag"
local hookdata = require "data.hook"
local i18n = require "res.i18n"
local tipsequip = require "ui.tips.equip"
local tipsitem = require "ui.tips.item"
local tipshero = require "ui.tips.hero"

local ItemType = {
    Item = 1,
    Equip = 2,
}

function ui.create(_bag, title)
    local layer = CCLayer:create()
    -- dark bg
    local darkbg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    layer:addChild(darkbg)
    -- board_bg
    local board_bg = img.createUI9Sprite(img.ui.dialog_1)
    board_bg:setPreferredSize(CCSizeMake(645, 486))
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
    --local closeText = i18n.global.hook_drop_btn_get.string
    local closeText = i18n.global.dialog_button_confirm.string
    --end
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
        return img.createHeroHead(itemObj.id, 1, true, true)
    end

    local items = {}

    local item_offset_x = 56
    local item_offset_y = 87
    local item_step_x = 140
    local item_step_y = 174
    local row_count = 4
    local function showList()
        arrayclear(items)
        content_layer:removeAllChildrenWithCleanup(true)
        local height = 0
        local showbag = _bag
        --for ii = 1,#_bag do
        --    local flag = false
        --    if #showbag == 0 then
        --        showbag[#showbag+1] = _bag[ii]
        --        showbag[#showbag].num = 1
        --    else
        --        for j = 1,#showbag do
        --            if showbag[j].id == _bag[ii].id then
        --                showbag[j].num = showbag[j].num + 1
        --                flag = true
        --                break
        --            end
        --        end
        --        if flag == false then
        --            showbag[#showbag+1] = _bag[ii]
        --            showbag[#showbag].num = 1
        --        end
        --    end
        --end
        for ii=1, #showbag do
            local tmp_item = img.createSkinIcon(showbag[ii].id)
            tmp_item.obj = showbag[ii]
            local pos_x = item_offset_x + item_step_x*((ii-1)%row_count)
            local pos_y = item_offset_y + item_step_y*(math.floor((ii+row_count-1)/row_count)-1)
            tmp_item:setScale(0.7)
            tmp_item:setPosition(CCPoint(pos_x, 0 - pos_y))

            content_layer:addChild(tmp_item)
            items[#items+1] = tmp_item

            local framBg = nil
            if cfgequip[showbag[ii].id].powerful and cfgequip[showbag[ii].id].powerful ~= 0 then
                framBg = img.createUISprite(img.ui.skin_frame_sp)
            else
                framBg = img.createUISprite(img.ui.skin_frame)
            end
            framBg:setScale(0.7)
            framBg:setPosition(pos_x, 0 - pos_y)
            content_layer:addChild(framBg, 1)
            local groupBg = img.createUISprite(img.ui.skin_circle)
            groupBg:setPosition(pos_x - 43, 0 - pos_y + 61)
            content_layer:addChild(groupBg, 1)
            local groupIcon = img.createUISprite(img.ui["herolist_group_" .. cfghero[cfgequip[showbag[ii].id].heroId[1]].group])
            groupIcon:setScale(0.48)
            groupIcon:setPosition(pos_x - 43, 0 - pos_y + 61)
            content_layer:addChild(groupIcon, 1)

            height = pos_y + 100
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
        layer:addChild(require("ui.skin.preview").create(itemObj.obj.id, i18n.equip[itemObj.obj.id].name), 10000)
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
                    --playAnimTouchBegin(items[ii])
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
                --playAnimTouchEnd(last_touch_sprite)
                last_touch_sprite = nil
            end
        end
    end
    local function onTouchEnded(x, y)
        if last_touch_sprite and not tolua.isnull(last_touch_sprite) then
            --playAnimTouchEnd(last_touch_sprite)
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
        backEvent()
    end)

    return layer
end

return ui
