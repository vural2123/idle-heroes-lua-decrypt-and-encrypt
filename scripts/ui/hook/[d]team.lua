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
local cfghooklock = require "config.hooklock"
local player = require "data.player"
local bagdata = require "data.bag"
local herodata = require "data.heros"
local hookdata = require "data.hook"
local i18n = require "res.i18n"

function ui.create(callback)
    local layer = CCLayer:create()
    -- dark bg
    local darkbg = CCLayerColor:create(ccc4(0, 0, 0, 0))
    layer:addChild(darkbg)
    -- board_bg
    local board_bg = img.createUI9Sprite(img.ui.dialog_1)
    board_bg:setPreferredSize(CCSizeMake(827, 410))
    board_bg:setScale(view.minScale)
    board_bg:setAnchorPoint(CCPoint(0.5, 0))
    board_bg:setPosition(view.midX, view.minY+127*view.minScale)
    layer:addChild(board_bg)
    local board_bg_w = board_bg:getContentSize().width
    local board_bg_h = board_bg:getContentSize().height

    -- list_board
    local list_board = img.createUI9Sprite(img.ui.tips_bg)
    list_board:setPreferredSize(CCSizeMake(954, 125))
    list_board:setScale(view.minScale)
    list_board:setAnchorPoint(CCPoint(0.5, 1))
    list_board:setPosition(CCPoint(view.midX, view.minY+0*view.minScale))
    layer:addChild(list_board)

    -- anim
    local anim_duration = 0.2
    board_bg:setPosition(CCPoint(view.midX, view.minY+576*view.minScale))
    board_bg:runAction(CCMoveTo:create(anim_duration, CCPoint(view.midX, view.minY+130*view.minScale)))
    list_board:runAction(CCMoveTo:create(anim_duration, CCPoint(view.midX, view.minY+123*view.minScale)))
    darkbg:runAction(CCFadeTo:create(anim_duration, POPUP_DARK_OPACITY))

    local function backEvent()
        audio.play(audio.button)
        local act_array = CCArray:create()
        act_array:addObject(CCCallFunc:create(function()
            board_bg:runAction(CCMoveTo:create(anim_duration, CCPoint(view.midX, view.minY+576*view.minScale)))
        end))
        act_array:addObject(CCCallFunc:create(function()
            list_board:runAction(CCMoveTo:create(anim_duration, CCPoint(view.midX, view.minY+0*view.minScale)))
        end))
        act_array:addObject(CCCallFunc:create(function()
            darkbg:runAction(CCFadeTo:create(anim_duration, 0))
        end))
        act_array:addObject(CCDelayTime:create(anim_duration))
        act_array:addObject(CCCallFunc:create(function()
            layer:removeFromParentAndCleanup(true)
        end))
        layer:runAction(CCSequence:create(act_array))
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

    local lbl_title = lbl.createFont1(24, i18n.global.hook_team_board_title.string, ccc3(0xe6, 0xd0, 0xae))
    lbl_title:setPosition(CCPoint(board_bg_w/2, board_bg_h-29))
    board_bg:addChild(lbl_title, 2)
    local lbl_title_shadowD = lbl.createFont1(24, i18n.global.hook_team_board_title.string, ccc3(0x59, 0x30, 0x1b))
    lbl_title_shadowD:setPosition(CCPoint(board_bg_w/2, board_bg_h-31))
    board_bg:addChild(lbl_title_shadowD)

    local board = img.createUI9Sprite(img.ui.select_hero_camp_bg)
    board:setPreferredSize(CCSizeMake(770, 248))
    board:setAnchorPoint(CCPoint(0.5, 0))
    board:setPosition(CCPoint(board_bg_w/2, 94))
    board_bg:addChild(board)
    local board_w = board:getContentSize().width
    local board_h = board:getContentSize().height
    local board_tab = img.createUI9Sprite(img.ui.select_tab_tab_bg)
    board_tab:setPreferredSize(CCSizeMake(760, 38))
    board_tab:setAnchorPoint(CCPoint(0.5, 1))
    board_tab:setPosition(CCPoint(board_w/2, board_h-4))
    board:addChild(board_tab)
    local power_bg = img.createUISprite(img.ui.select_hero_power_bg)
    power_bg:setAnchorPoint(CCPoint(0, 0.5))
    power_bg:setPosition(CCPoint(0, board_tab:getContentSize().height/2))
    board_tab:addChild(power_bg)

    local power_icon = img.createUISprite(img.ui.power_icon)
    power_icon:setScale(0.5)
    power_icon:setPosition(CCPoint(30, power_bg:getContentSize().height/2))
    power_bg:addChild(power_icon)

    local lbl_power = lbl.createFont2(20, "0")
    lbl_power:setAnchorPoint(CCPoint(0, 0.5))
    lbl_power:setPosition(CCPoint(55, power_bg:getContentSize().height/2))
    power_bg:addChild(lbl_power)

    -- btn_hook
    local btn_confirm0 = img.createLogin9Sprite(img.login.button_9_small_gold)
    btn_confirm0:setPreferredSize(CCSizeMake(216, 52))
    local lbl_confirm = lbl.createFont1(22, i18n.global.hook_team_save.string, ccc3(0x73, 0x3b, 0x05))
    lbl_confirm:setPosition(CCPoint(btn_confirm0:getContentSize().width/2, btn_confirm0:getContentSize().height/2))
    btn_confirm0:addChild(lbl_confirm)
    local btn_confirm = SpineMenuItem:create(json.ui.button, btn_confirm0)
    btn_confirm:setPosition(CCPoint(board_bg_w/2, 53))
    local btn_confirm_menu = CCMenu:createWithItem(btn_confirm)
    btn_confirm_menu:setPosition(CCPoint(0, 0))
    board_bg:addChild(btn_confirm_menu)

    local function createHeroHead(_hid)
        local headBg = img.createUISprite(img.ui.select_hero_hero_bg)
        local headBg_w = headBg:getContentSize().width
        local headBg_h = headBg:getContentSize().height
        --local btn_add = img.createUISprite(img.ui.hook_btn_add)
        --btn_add:setPosition(CCPoint(headBg_w/2, headBg_h/2))
        --headBg:addChild(btn_add)
        if _hid then
            local headIcon = img.createHeroHeadByHid(_hid)
            headIcon:setScale(0.9)
            headIcon:setPosition(CCPoint(headBg_w/2, headBg_h/2))
            headBg:addChild(headIcon)
            headBg.headIcon = headIcon
        end
        return headBg
    end
    local function createLock()
        local headBg = img.createUISprite(img.ui.select_hero_hero_bg)
        local headBg_w = headBg:getContentSize().width
        local headBg_h = headBg:getContentSize().height
        local btn_lock = img.createUISprite(img.ui.hook_icon_lock)
        btn_lock:setPosition(CCPoint(headBg_w/2, headBg_h/2))
        headBg:addChild(btn_lock)
        return headBg
    end

    local function dealSelHids(_sel_hids)
        arrayfilter(_sel_hids, herodata.find)
    end

    local sel_items = {}
    local unlock_items = {}
    -- 16 hero pos
    local max_heroes = hookdata.getMaxHeroes()
    dealSelHids(hookdata.hids)
    local sel_hids = clone(hookdata.hids or {})
    local offset_x = 62
    local offset_y = 150
    local step_x = 92
    local step_y = 92
    for ii=1,16 do
        local tmp_item
        if ii <= max_heroes then
            if sel_hids[ii] then
                tmp_item = createHeroHead(sel_hids[ii])
                tmp_item.hid = sel_hids[ii]
                sel_items[#sel_items+1] = tmp_item
            else
                tmp_item = createHeroHead()
                sel_items[#sel_items+1] = tmp_item
            end
        else
            tmp_item = createLock()
            tmp_item.idx = ii
            unlock_items[#unlock_items+1] = tmp_item
        end
        local pos_x = offset_x + (ii-1)%8*step_x
        local pos_y = offset_y - step_y*(math.floor((ii+8-1)/8)-1)
        --tmp_item:setScale(0.9)
        tmp_item:setPosition(CCPoint(pos_x, pos_y))
        board:addChild(tmp_item)
    end

    local function findUnlockLv(_count)
        for ii=1,#cfghooklock do
            if cfghooklock[ii].unlock >= _count then
                return ii
            end
        end
    end
    local function showUnlock(_lv)
        if not _lv then return end
        audio.play(audio.button)
        showToast(string.format(i18n.global.func_need_lv.string, _lv))
    end

    local function updatePower()
        lbl_power:setString(hookdata.getAllPower(sel_hids))
    end
    updatePower()
    
    local SCROLL_VIEW_W = 937
    local SCROLL_VIEW_H = 130
    local scroll = CCScrollView:create()
    scroll:setDirection(kCCScrollViewDirectionHorizontal)
    scroll:setViewSize(CCSize(SCROLL_VIEW_W, SCROLL_VIEW_H))
    scroll:setContentSize(CCSize(SCROLL_VIEW_W, SCROLL_VIEW_H))
    scroll:setAnchorPoint(CCPoint(0, 0))
    scroll:setPosition(CCPoint(9, -7))
    list_board:addChild(scroll)
    --drawBoundingbox(list_board, scroll)

    local content_layer = CCLayer:create()
    content_layer:setAnchorPoint(CCPoint(0, 0))
    content_layer:setPosition(CCPoint(0, 0))
    scroll:getContainer():addChild(content_layer)
    scroll.content_layer = content_layer

    local function createListHeroHead(heroObj)
        local headBg = img.createUISprite(img.ui.herolist_head_bg)
        local headBg_w = headBg:getContentSize().width
        local headBg_h = headBg:getContentSize().height
        local headIcon = img.createHeroHeadByHid(heroObj.hid)
        headIcon:setPosition(CCPoint(headBg_w/2, headBg_h/2))
        headBg:addChild(headIcon)
        local head_mask = img.createUISprite(img.ui.hook_btn_mask)
        head_mask:setPosition(CCPoint(headBg_w/2, headBg_h/2))
        headBg:addChild(head_mask)
        local icon_sel = img.createUISprite(img.ui.hook_btn_sel)
        icon_sel:setPosition(CCPoint(head_mask:getContentSize().width/2, head_mask:getContentSize().height/2))
        head_mask:addChild(icon_sel)
        headBg.head_mask = head_mask
        if heroObj.isSelected then
            head_mask:setVisible(true)
        else
            head_mask:setVisible(false)
        end
        return headBg
    end

    local function findHeroFromList(_list, _hid)
        if not _list then return end
        for ii=1,#_list do
            if _list[ii].hid == _hid then
                return _list[ii]
            end
        end
    end
    local function initHeroList(_list)
        if not sel_hids or #sel_hids<=0 then return end
        for ii=1,#sel_hids do
            local _h = findHeroFromList(_list, sel_hids[ii])
            if _h then
                _h.isSelected = true
            else
            end
        end
    end

    local hero_items = {}

    local item_offset_x = 54
    local item_offset_y = list_board:getContentSize().height/2+7
    local item_step_x = 100
    local item_step_y = 0
    local function showHeroList()
        arrayclear(hero_items)
        content_layer:removeAllChildrenWithCleanup(true)
        local hero_list = clone(herodata)
        table.sort(hero_list, compareHero)
        hero_list = herolistless(hero_list, sel_hids)
        initHeroList(hero_list)
        local list_width = 0
        for ii=1,#hero_list do
            local tmp_item = createListHeroHead(hero_list[ii])
            tmp_item.heroObj = hero_list[ii]
            local pos_x = item_offset_x + item_step_x*(ii-1)
            local pos_y = item_offset_y
            tmp_item:setPosition(CCPoint(pos_x, pos_y))
            content_layer:addChild(tmp_item)
            hero_items[#hero_items+1] = tmp_item
            list_width = pos_x + 67
        end
        if list_width < SCROLL_VIEW_W then
            scroll:setContentSize(CCSizeMake(SCROLL_VIEW_W, SCROLL_VIEW_H))
            content_layer:setPosition(CCPoint(0, 0))
            scroll:setContentOffset(CCPoint(0, 0))
        else
            scroll:setContentSize(CCSizeMake(list_width, SCROLL_VIEW_H))
            content_layer:setPosition(CCPoint(0, 0))
            --scroll:setContentOffset(CCPoint(SCROLL_VIEW_W-list_width, 0))
            scroll:setContentOffset(CCPoint(0, 0))
        end
    end
    showHeroList()

    local function findFirstBlank()
        for ii=1,#sel_items do
            if not sel_items[ii].hid then
                return sel_items[ii]
            end
        end
    end
    
    -- 把一个头像放到空白框
    local function touchHead(itemObj, _hid)
        local headIcon = img.createHeroHeadByHid(_hid)
        headIcon:setScale(0.9)
        headIcon:setPosition(CCPoint(itemObj:getContentSize().width/2, itemObj:getContentSize().height/2))
        itemObj:addChild(headIcon)
        itemObj.hid = _hid
        itemObj.headIcon = headIcon
    end

    -- 把一个头像变成空白框
    local function detouchHead(itemObj)
        for ii=1,#sel_hids do
            if sel_hids[ii] == itemObj.hid then
                table.remove(sel_hids, ii)
                break
            end
        end
        --for ii=1,#sel_items do
        --    if sel_items[ii] == itemObj then
        --        table.remove(sel_items, ii)
        --        break
        --    end
        --end
        if itemObj.headIcon and not tolua.isnull(itemObj.headIcon) then
            itemObj.headIcon:removeFromParentAndCleanup(true)
            itemObj.headIcon = nil
            itemObj.hid = nil
        end
    end

    local function below2above(belowObj)
        if belowObj.heroObj.isSelected then return end
        local blank_item = findFirstBlank()
        if not blank_item then return end
        belowObj.head_mask:setVisible(true)
        belowObj.heroObj.isSelected = true
        sel_hids[#sel_hids+1] = belowObj.heroObj.hid
        sel_items[#sel_items+1] = blank_item
        touchHead(blank_item, belowObj.heroObj.hid)
    end

    local function findFromBelowList(_hid)
        for ii=1,#hero_items do
            if hero_items[ii].heroObj.hid == _hid then
                return hero_items[ii]
            end
        end
    end

    local function findFromAboveList(_hid)
        for ii=1,#sel_items do
            if sel_items[ii].hid and sel_items[ii].hid == _hid then
                return sel_items[ii]
            end
        end
    end

    local function above2below(aboveObj)
        if aboveObj.hid then
            local tmp_hid = aboveObj.hid
            detouchHead(aboveObj)
            local listObj = findFromBelowList(tmp_hid)
            if listObj then
                listObj.head_mask:setVisible(false)
                listObj.heroObj.isSelected = false
            end
        end
    end

    local function teamChange(_hids)
        if not hookdata.status or hookdata.status ~= 0 then -- first hook
            local params = {
                sid = player.sid,
                hids = _hids,
            }
            addWaitNet()
            hookdata.hook_init(params, function(__data)
                delWaitNet()
                tbl2string(__data)
                hookdata.init(__data.hook)
                if callback then
                    callback()
                end
                backEvent()
            end)
        else
            local params = {
                sid = player.sid,
                hids = _hids,
            }
            addWaitNet()
            hookdata.hook_heroes(params, function(__data)
                delWaitNet()
                tbl2string(__data)
                if __data.status ~= 0 then
                    showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                    btn_confirm:setEnabled(true)
                    return
                end
                require("data.tutorial").goNext("hook2", 1, true) 
                arrayclear(hookdata.hids)
                hookdata.hids = clone(_hids)
                hookdata.ids = {}
                for ii=1,#hookdata.hids do
                    hookdata.ids[ii] = hid2id(hookdata.hids[ii])
                end
                if callback then
                    callback(true)
                end
                backEvent()
            end)
        end
    end

    btn_confirm:registerScriptTapHandler(function()
        --audio.play(audio.button)
        btn_confirm:setEnabled(false)
        if not sel_hids or #sel_hids <= 0 then
            showToast(i18n.global.hook_team_empty.string)
            btn_confirm:setEnabled(true)
            return
        end
        teamChange(sel_hids)
    end)

    local function onClickBelowItem(_obj)
        if _obj.heroObj.isSelected then 
            local _above_obj = findFromAboveList(_obj.heroObj.hid)
            if _above_obj then
                above2below(_above_obj)
                updatePower()
            end
        else
            below2above(_obj)
            updatePower()
        end
    end
    local function onClickAboveItem(_obj)
        above2below(_obj)
        updatePower()
    end

    -- touch event
    local touchbeginx, touchbeginy
    local isclick
    local last_touch_sprite = nil
    local function onTouchBegan(x, y)
        touchbeginx, touchbeginy = x, y
        isclick = true
        if scroll and not tolua.isnull(scroll) then
            local pp0 = list_board:convertToNodeSpace(ccp(x, y))
            --if not scroll:boundingBox():containsPoint(pp0) then
            --    isclick = false
            --    return false
            --end
            local p0 = content_layer:convertToNodeSpace(ccp(x, y))
            for ii=1,#hero_items do
                if hero_items[ii]:boundingBox():containsPoint(p0) then
                    playAnimTouchBegin(hero_items[ii])
                    last_touch_sprite = hero_items[ii]
                    break
                end
            end
            local p1 = board:convertToNodeSpace(ccp(x, y))
            for ii=1,#sel_items do
                if sel_items[ii]:boundingBox():containsPoint(p1) then
                    playAnimTouchBegin(sel_items[ii])
                    last_touch_sprite = sel_items[ii]
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
            for ii=1,#hero_items do
                if hero_items[ii]:boundingBox():containsPoint(p0) then
                    audio.play(audio.button)
                    onClickBelowItem(hero_items[ii])
                    break
                end
            end
            local p1 = board:convertToNodeSpace(ccp(x, y))
            for ii=1,#sel_items do
                if sel_items[ii]:boundingBox():containsPoint(p1) then
                    audio.play(audio.button)
                    onClickAboveItem(sel_items[ii])
                    break
                end
            end
            for ii=1,#unlock_items do
                if unlock_items[ii]:boundingBox():containsPoint(p1) then
                    if unlock_items[ii].idx then
                        showUnlock(findUnlockLv(unlock_items[ii].idx))
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
