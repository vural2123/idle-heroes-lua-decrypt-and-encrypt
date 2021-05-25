local ui = {}

require "common.const"
require "common.func"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local audio = require "res.audio"
local i18n = require "res.i18n"
local player = require "data.player"
local userdata = require "data.userdata"
local NetClient = require "net.netClient"
local netClient = NetClient:getInstance()

-- 背景框大小
local BG_WIDTH   = 382
local BG_HEIGHT  = 472

-- 滑动区域大小
local SCROLL_MARGIN_TOP     = 70
local SCROLL_MARGIN_BOTTOM  = 10
local SCROLL_VIEW_WIDTH     = BG_WIDTH
local SCROLL_VIEW_HEIGHT    = BG_HEIGHT - SCROLL_MARGIN_TOP - SCROLL_MARGIN_BOTTOM

local function createItem(serverObj)
    local item = img.createUI9Sprite(img.ui.botton_fram_2)
    item:setPreferredSize(CCSizeMake(336, 86))
    local item_w = item:getContentSize().width
    local item_h = item:getContentSize().height
    -- current
    local current = img.createUI9Sprite(img.ui.setting_server_sel)
    current:setPreferredSize(CCSizeMake(336, 86))
    current:setPosition(CCPoint(item_w/2, item_h/2))
    current:setVisible(serverObj.uid == player.uid and serverObj.sid == player.sid)
    item:addChild(current)
    -- focus
    local focus = img.createUI9Sprite(img.ui.setting_server_focus)
    focus:setPreferredSize(CCSizeMake(342, 92))
    focus:setPosition(CCPoint(item_w/2, item_h/2+2))
    focus:setVisible(false)
    item:addChild(focus)
    item.focus = focus
    -- sname
    local lbl_sname = lbl.createFont1(22, serverObj.sname, ccc3(0x51, 0x27, 0x12))
    lbl_sname:setAnchorPoint(CCPoint(0, 0.5))
    lbl_sname:setPosition(CCPoint(22, item_h/2))
    item:addChild(lbl_sname)
    -- pname
    if serverObj.pname then
        local lbl_pname = lbl.createFontTTF(22, serverObj.pname, ccc3(0x51, 0x27, 0x12))
        lbl_pname:setAnchorPoint(CCPoint(1, 0.5))
        lbl_pname:setPosition(CCPoint(256, item_h/2))
        item:addChild(lbl_pname)
    end
    if serverObj.plogo then
        local head = img.createPlayerHead(serverObj.plogo, serverObj.plv)
        head:setScale(0.7)
        head:setPosition(CCPoint(292, item_h/2+2))
        item:addChild(head)
    end
    item.height = item_h
    return item
end

function ui.create(roles)
    local layer = CCLayer:create()

    -- dark bg
    local darkbg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    layer:addChild(darkbg)

    -- bg
    local bg = img.createUI9Sprite(img.ui.tips_bg)
    bg:setPreferredSize(CCSize(BG_WIDTH, BG_HEIGHT))
    bg:setScale(view.minScale * 0.1)
    bg:setAnchorPoint(ccp(0.5,0.5))
    bg:setPosition(view.midX, view.midY)
    bg:runAction(CCEaseBackOut:create(CCScaleTo:create(0.3, view.minScale)))
    layer:addChild(bg)
    
    -- closeBtn
    local closeBtn0 = img.createUISprite(img.ui.close)
    local closeBtn = SpineMenuItem:create(json.ui.button, closeBtn0)
    closeBtn:setPosition(BG_WIDTH-23, BG_HEIGHT-26)
    local closeMenu = CCMenu:createWithItem(closeBtn)
    closeMenu:setPosition(0, 0)
    bg:addChild(closeMenu)
    closeBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer.onAndroidBack()
    end)

    -- title
    title = i18n.global.role_list.string
    local titleLabel = lbl.createMixFont1(24, title, ccc3(0xff, 0xe3, 0x86))
    titleLabel:setPosition(BG_WIDTH/2, BG_HEIGHT-36)
    bg:addChild(titleLabel)

    -- line
    local line = img.createUISprite(img.ui.help_line)
    line:setScaleX(610/line:getContentSize().width)
    line:setPosition(BG_WIDTH/2, BG_HEIGHT-64)
    bg:addChild(line)

    local board = bg
    
    local function createScroll()
        local scroll_params = {
            width = 336,
            height = 370,
        }
        local lineScroll = require "ui.lineScroll"
        return lineScroll.create(scroll_params)
    end

    local list_items = {}
    local function showList(listObj)
        if not listObj or #listObj == 0 then return end
        arrayclear(list_items)
        local scroll = createScroll()
        scroll:setAnchorPoint(CCPoint(0, 0))
        scroll:setPosition(CCPoint(24, 25))
        board:addChild(scroll)
        board.scroll = scroll
        for ii=1,#listObj do
            local tmp_item = CCSprite:create()
            tmp_item:setContentSize(CCSizeMake(336, 86))
            local tmp_server_item = createItem(listObj[ii])
            tmp_server_item.container = tmp_item
            tmp_server_item.obj = listObj[ii]
            list_items[#list_items+1] = tmp_server_item
            tmp_server_item:setPosition(CCPoint(168, 43))
            tmp_item:addChild(tmp_server_item)
            scroll.addItem(tmp_item)
            if ii < #listObj then
                scroll.addSpace(8)
            end
        end
        scroll.setOffsetBegin()
    end

    showList(roles)

    local function onClickItem(itemObj)
        audio.play(audio.button)
        if last_sel_sprite and not tolua.isnull(last_sel_sprite) then
            last_sel_sprite.focus:setVisible(false)
        end
        itemObj.focus:setVisible(true)
        last_sel_sprite = itemObj
        if player.uid == itemObj.obj.uid and player.sid == itemObj.obj.sid then
            return 
        end
        local dialog = require "ui.dialog"
        local function process_dialog(data)
            layer:removeChildByTag(dialog.TAG)
            if data.selected_btn == 2 then
                replaceScene((require "ui.login.update").create(nil, itemObj.obj.sid, nil, {uid=itemObj.obj.uid}))
            elseif data.selected_btn == 1 then
            end
        end
        local params = {
            title = "",
            body = i18n.global.change_role_tips.string,
            btn_count = 2,
            btn_color = {
                [1] = dialog.COLOR_BLUE,
                [2] = dialog.COLOR_GOLD,
            },
            btn_text = {
                [1] = i18n.global.dialog_button_cancel.string,
                [2] = i18n.global.dialog_button_confirm.string,
            },
            callback = process_dialog,
        }
        local dialog_ins = dialog.create(params, true)
        dialog_ins:setAnchorPoint(CCPoint(0,0))
        dialog_ins:setPosition(CCPoint(0,0))
        layer:addChild(dialog_ins, 10000, dialog.TAG)
    end

    addBackEvent(layer)

    function layer.onAndroidBack()
        layer:removeFromParent()
    end

    -- touch event
    local touchbeginx, touchbeginy
    local isclick
    local last_touch_sprite = nil
    local function onTouchBegan(x, y)
        touchbeginx, touchbeginy = x, y
        isclick = true
        if not board.scroll or tolua.isnull(board.scroll) then
            isclick = false
            return false
        end
        local content_layer = board.scroll.content_layer
        local p0 = board:convertToNodeSpace(ccp(x, y))
        if not board.scroll:boundingBox():containsPoint(p0) then
            isclick = false
            return false
        end
        for ii=1,#list_items do
            local p1 = list_items[ii].container:convertToNodeSpace(ccp(x, y))
            if list_items[ii]:boundingBox():containsPoint(p1) then
                playAnimTouchBegin(list_items[ii])
                last_touch_sprite = list_items[ii]
                break
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
        if not board.scroll or tolua.isnull(board.scroll) then
            return
        end
        if isclick then
            local content_layer = board.scroll.content_layer
            for ii=1,#list_items do
                local p0 = list_items[ii].container:convertToNodeSpace(ccp(x, y))
                if list_items[ii]:boundingBox():containsPoint(p0) then
                    onClickItem(list_items[ii])
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

    return layer
end


return ui
