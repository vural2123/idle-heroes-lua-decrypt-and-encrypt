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
local cfgpoker = require "config.poker"
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

function ui.create(_stage_id)
    local layer = CCLayer:create()
    -- dark bg
    local darkbg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    layer:addChild(darkbg)
    -- board_bg
    local board_bg = img.createUI9Sprite(img.ui.dialog_1)
    board_bg:setPreferredSize(CCSizeMake(666, 515))
    board_bg:setScale(view.minScale)
    board_bg:setPosition(view.midX-0*view.minScale, view.midY)
    layer:addChild(board_bg)
    local board_bg_w = board_bg:getContentSize().width
    local board_bg_h = board_bg:getContentSize().height

    -- anim
    board_bg:setScale(0.5*view.minScale)
    board_bg:runAction(CCScaleTo:create(0.15, 1*view.minScale, 1*view.minScale))

    local ff, ss = hookdata.getFortStageByStageId(_stage_id)

    -- title
    local title_str = string.format(i18n.global.hook_stage_board_title.string, ff, ss)
    local lbl_title = lbl.createFont1(24, title_str, ccc3(0xe6, 0xd0, 0xae))
    lbl_title:setPosition(CCPoint(board_bg_w/2, board_bg_h-29))
    board_bg:addChild(lbl_title, 2)
    local lbl_title_shadowD = lbl.createFont1(24, title_str, ccc3(0x59, 0x30, 0x1b))
    lbl_title_shadowD:setPosition(CCPoint(board_bg_w/2, board_bg_h-31))
    board_bg:addChild(lbl_title_shadowD)

    local function backEvent()
        audio.play(audio.button)
        layer:removeFromParentAndCleanup(true)
    end
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

    -- rate_board
    local rate_board = img.createUI9Sprite(img.ui.hero_attribute_lab_frame)
    rate_board:setPreferredSize(CCSizeMake(614, 110))
    rate_board:setPosition(CCPoint(board_bg_w/2, 390))
    board_bg:addChild(rate_board)
    local rate_board_w = rate_board:getContentSize().width
    local rate_board_h = rate_board:getContentSize().height

    local lbl_rate_title = lbl.createFont1(18, i18n.global.hook_stage_output.string, ccc3(0x94, 0x62, 0x42))
    lbl_rate_title:setPosition(CCPoint(rate_board_w/2, 88))
    rate_board:addChild(lbl_rate_title)
    local split_l1 = img.createUISprite(img.ui.hook_title_split)
    split_l1:setAnchorPoint(CCPoint(1, 0.5))
    split_l1:setPosition(CCPoint(rate_board_w/2-62, 88))
    rate_board:addChild(split_l1)
    local split_r1 = img.createUISprite(img.ui.hook_title_split)
    split_r1:setFlipX(true)
    split_r1:setAnchorPoint(CCPoint(0, 0.5))
    split_r1:setPosition(CCPoint(rate_board_w/2+62, 88))
    rate_board:addChild(split_r1)
    local coin_box = img.createUI9Sprite(img.ui.hero_icon_bg)
    coin_box:setPreferredSize(CCSizeMake(150, 52))
    coin_box:setPosition(CCPoint(rate_board_w/2-36-150, 42))
    rate_board:addChild(coin_box)
    local coin_icon_bg = img.createUISprite(img.ui.hook_rate_bg)
    coin_icon_bg:setPosition(CCPoint(2, coin_box:getContentSize().height/2))
    coin_box:addChild(coin_icon_bg)
    local coin_icon = img.createItemIcon2(ITEM_ID_COIN)
    coin_icon:setPosition(CCPoint(coin_icon_bg:getContentSize().width/2, coin_icon_bg:getContentSize().height/2))
    coin_icon_bg:addChild(coin_icon)
    local pxp_box = img.createUI9Sprite(img.ui.hero_icon_bg)
    pxp_box:setPreferredSize(CCSizeMake(150, 52))
    pxp_box:setPosition(CCPoint(rate_board_w/2+10, 42))
    rate_board:addChild(pxp_box)
    local pxp_icon_bg = img.createUISprite(img.ui.hook_rate_bg)
    pxp_icon_bg:setPosition(CCPoint(2, pxp_box:getContentSize().height/2))
    pxp_box:addChild(pxp_icon_bg)
    local pxp_icon = img.createItemIcon2(ITEM_ID_PLAYER_EXP)
    pxp_icon:setPosition(CCPoint(pxp_icon_bg:getContentSize().width/2, pxp_icon_bg:getContentSize().height/2))
    pxp_icon_bg:addChild(pxp_icon)
    local hxp_box = img.createUI9Sprite(img.ui.hero_icon_bg)
    hxp_box:setPreferredSize(CCSizeMake(150, 52))
    hxp_box:setPosition(CCPoint(rate_board_w/2+56+150, 42))
    rate_board:addChild(hxp_box)
    local hxp_icon_bg = img.createUISprite(img.ui.hook_rate_bg)
    hxp_icon_bg:setPosition(CCPoint(2, hxp_box:getContentSize().height/2))
    hxp_box:addChild(hxp_icon_bg)
    local hxp_icon = img.createItemIcon(ITEM_ID_HERO_EXP)
    hxp_icon:setScale(0.5)
    hxp_icon:setPosition(CCPoint(hxp_icon_bg:getContentSize().width/2, hxp_icon_bg:getContentSize().height/2))
    hxp_icon_bg:addChild(hxp_icon)

    local lbl_rate_coin = lbl.createFont1(20, "+" .. cfgstage[_stage_id].gold .. "/5s", ccc3(0x94, 0x62, 0x42))
    --lbl_rate_coin:setAnchorPoint(CCPoint(0, 0.5))
    lbl_rate_coin:setPosition(CCPoint(82, coin_box:getContentSize().height/2))
    coin_box:addChild(lbl_rate_coin)
    local lbl_rate_pxp= lbl.createFont1(20, "+" .. cfgstage[_stage_id].expP .. "/5s", ccc3(0x94, 0x62, 0x42))
    --lbl_rate_pxp:setAnchorPoint(CCPoint(0, 0.5))
    lbl_rate_pxp:setPosition(CCPoint(82, pxp_box:getContentSize().height/2))
    pxp_box:addChild(lbl_rate_pxp)
    local lbl_rate_hxp= lbl.createFont1(20, "+" .. cfgstage[_stage_id].expH .. "/5s", ccc3(0x94, 0x62, 0x42))
    --lbl_rate_hxp:setAnchorPoint(CCPoint(0, 0.5))
    lbl_rate_hxp:setPosition(CCPoint(82, hxp_box:getContentSize().height/2))
    hxp_box:addChild(lbl_rate_hxp)

    local board = img.createUI9Sprite(img.ui.bag_btn_inner_bg)
    board:setPreferredSize(CCSizeMake(614, 202))
    board:setAnchorPoint(CCPoint(0.5, 0))
    board:setPosition(CCPoint(board_bg_w/2, 85))
    board_bg:addChild(board)
    local board_w = board:getContentSize().width
    local board_h = board:getContentSize().height

    local lbl_board_title = lbl.createFont1(18, i18n.global.hook_stage_drops.string, ccc3(0x94, 0x62, 0x42))
    lbl_board_title:setPosition(CCPoint(board_w/2, board_h+23))
    board:addChild(lbl_board_title)
    local split_l2 = img.createUISprite(img.ui.hook_title_split)
    split_l2:setAnchorPoint(CCPoint(1, 0.5))
    split_l2:setPosition(CCPoint(board_w/2-62, board_h+23))
    board:addChild(split_l2)
    local split_r2 = img.createUISprite(img.ui.hook_title_split)
    split_r2:setFlipX(true)
    split_r2:setAnchorPoint(CCPoint(0, 0.5))
    split_r2:setPosition(CCPoint(board_w/2+62, board_h+23))
    board:addChild(split_r2)

    local btn_hook0 = img.createLogin9Sprite(img.login.button_9_small_gold)
    btn_hook0:setPreferredSize(CCSizeMake(220, 54))
    local lbl_btn_hook = lbl.createFont1(22, i18n.global.hook_btn_hook.string, ccc3(0x73, 0x3b, 0x05))
    lbl_btn_hook:setPosition(CCPoint(btn_hook0:getContentSize().width/2, btn_hook0:getContentSize().height/2))
    btn_hook0:addChild(lbl_btn_hook)
    local btn_hook = SpineMenuItem:create(json.ui.button, btn_hook0)
    btn_hook:setPosition(CCPoint(board_bg_w/2, 51))
    local btn_hook_menu = CCMenu:createWithItem(btn_hook)
    btn_hook_menu:setPosition(CCPoint(0, 0))
    board_bg:addChild(btn_hook_menu)

    if _stage_id == hookdata.getHookStage() then
        btn_hook:setVisible(false)
    end

    -- drops
    local SCROLL_VIEW_W = 548
    local SCROLL_VIEW_H = 174
    local scroll = CCScrollView:create()
    scroll:setDirection(kCCScrollViewDirectionVertical)
    scroll:setViewSize(CCSize(SCROLL_VIEW_W, SCROLL_VIEW_H))
    scroll:setContentSize(CCSize(SCROLL_VIEW_W, SCROLL_VIEW_H))
    scroll:setAnchorPoint(CCPoint(0, 0))
    scroll:setPosition(CCPoint(33, 12))
    board:addChild(scroll)
    --drawBoundingbox(board, scroll)
    
    local content_layer = CCLayer:create()
    content_layer:setAnchorPoint(CCPoint(0, 0))
    content_layer:setPosition(CCPoint(0, 0))
    scroll:getContainer():addChild(content_layer)
    scroll.content_layer = content_layer

    local function createItem(itemObj)
        if itemObj.type == ItemType.Equip then  -- equip
            return img.createEquip(itemObj.id)
        elseif itemObj.type == ItemType.Item then
            return img.createItem(itemObj.id)
        end
    end

    local items = {}

    local item_offset_x = 41
    local item_offset_y = 53
    local item_step_x = 93
    local item_step_y = 95
    local row_count = 6
    local function showList()
        arrayclear(items)
        content_layer:removeAllChildrenWithCleanup(true)
        local height = 0
		local yesls = nil
		if player.isSeasonal() then
			yesls = cfgpoker[_stage_id].yes2
		else
			yesls = cfgpoker[_stage_id].yes
		end
        for ii=1, #yesls do
            local tmp_itemObj = {
                id = yesls[ii].id,
                type = yesls[ii].type,
            }
            --if tmp_itemObj.id ~= 50 then
                local tmp_item = createItem(tmp_itemObj)
                tmp_item.obj = tmp_itemObj
                local pos_x = item_offset_x + item_step_x*((ii-1)%row_count)
                local pos_y = item_offset_y + item_step_y*(math.floor((ii+row_count-1)/row_count)-1)
                tmp_item:setPosition(CCPoint(pos_x, 0 - pos_y))
                content_layer:addChild(tmp_item)
                items[#items+1] = tmp_item
                height = pos_y + 47
            --end
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
        audio.play(audio.button)
        btn_hook:setEnabled(false)
        local params = {
            sid = player.sid,
            stage = _stage_id,
        }
        addWaitNet()
        hookdata.change(params, function(__data)
            delWaitNet()
            tbl2string(__data)
            if __data.status ~= 0 then
                showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                return
            end
            require("data.tutorial").goNext("hook2", 2, true) 
            hookdata.hook_stage = _stage_id
            if __data.reward then
                hookdata.set_reward(__data.reward)
            end
            if __data.boss_cd then
                hookdata.boss_cd = __data.boss_cd + os.time() - hookdata.init_time
            end
            replaceScene((require"ui.hook.map").create())
        end)
    end)

    return layer
end

return ui
