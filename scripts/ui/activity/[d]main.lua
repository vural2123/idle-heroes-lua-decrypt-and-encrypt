local listlayer = {}

require "common.func"
local view = require "common.view"
local i18n = require "res.i18n"
local lbl = require "res.lbl"
local img = require "res.img"
local audio = require "res.audio"
local json = require "res.json"
local player = require "data.player"
local activityData = require "data.activity"
local monthloginData = require "data.monthlogin"
local shopData = require "data.shop"
local NetClient = require "net.netClient"
local netClient = NetClient:getInstance()

local function refreshSelf(layerObj)  -- layerObj is content_layer
    if not layerObj or tolua.isnull(layerObj) then return end
    local self_layer = layerObj:getParent()
    if self_layer and not tolua.isnull(self_layer) then
        local parent_obj = self_layer:getParent()
        self_layer:removeFromParentAndCleanup(true)
        parent_obj:addChild(require("ui.activity.main").create(), 1000)
    end
end

local function getItems()
	local IDS = activityData.IDS
    pItems = {
        [IDS.MONTH_LOGIN.ID] = {
            id = IDS.MONTH_LOGIN.ID,
            group = IDS.MONTH_LOGIN.ID,               -- group 用于标识一组相同UI的活动，值为第一个活动ID
            icon = img.ui.login_month_icon,
            description = i18n.global.activity_des_login.string,
            nocd = true,   -- 影响描述文字的位置
            redFunc = monthloginData.showRedDot,
            tapFunc = function(parent_obj)
                parent_obj:removeAllChildrenWithCleanup(true)
                local monthLoginlayer = require "ui.monthlogin.main"
                local pop = monthLoginlayer.create(function()
                    refreshSelf(parent_obj)
                end)
                pop:setTouchEnabled(true)
                pop:setTouchSwallowEnabled(false)
                parent_obj:addChild(pop, 1000)
            end,
        },
        [998] = {
            id = 998,
            group = 998,
            icon = img.ui.activity_icon_element,
            description = i18n.global.hero_skill_unlock.string,
            redFunc = function() return false end,
            nocd = true,
            tapFunc = function(parent_obj)
                parent_obj:removeAllChildrenWithCleanup(true)
                parent_obj:runAction(CCCallFunc:create(function()
                    local fish = require "ui.activity.bigfuse"
                    local pop = fish.create()
                    pop:setTouchEnabled(true)
                    pop:setTouchSwallowEnabled(false)
                    parent_obj:addChild(pop, 1000)
                end))
            end,
        },
        [48001] = {
            id = 48001,
            group = 48001,
            icon = img.ui.limit_first_icon,
            description = i18n.global.limitactivity_limitgift.string,
            redFunc = function() return false end,
            nocd = true,
            tapFunc = function(parent_obj)
                parent_obj:removeAllChildrenWithCleanup(true)
                parent_obj:runAction(CCCallFunc:create(function()
                    local fish = require "ui.activity.artishop"
                    local pop = fish.create()
                    pop:setTouchEnabled(true)
                    pop:setTouchSwallowEnabled(false)
                    parent_obj:addChild(pop, 1000)
                end))
            end,
        },
        [47001] = {
            id = 47001,
            group = 47001,
            icon = img.ui.activity_icon_newyear2,
            description = i18n.global.activity_des_magicfigure.string,
            redFunc = function() return false end,
            nocd = true,
            tapFunc = function(parent_obj)
                parent_obj:removeAllChildrenWithCleanup(true)
                parent_obj:runAction(CCCallFunc:create(function()
                    local fish = require "ui.activity.codeshop"
                    local pop = fish.create()
                    pop:setTouchEnabled(true)
                    pop:setTouchSwallowEnabled(false)
                    parent_obj:addChild(pop, 1000)
                end))
            end,
        },
		[IDS.TENCHANGE.ID] = {
            id = IDS.TENCHANGE.ID,
            group = IDS.TENCHANGE.ID,
            icon = img.ui.activity_icon_change,
            description = i18n.global.activity_des_tenplace.string,
			nocd = true,
			redFunc = function() return false end,
            tapFunc = function(parent_obj)
                parent_obj:removeAllChildrenWithCleanup(true)
                parent_obj:runAction(CCCallFunc:create(function()
                    local tenchangelayer = require "ui.activity.tenchange"
                    local pop = tenchangelayer.create()
                    pop:setTouchEnabled(true)
                    pop:setTouchSwallowEnabled(false)
                    parent_obj:addChild(pop, 1000)
                end))
            end,
        },
    }
	local ev_currency = require('data.bag').items.find(51) or { num = 0 }
    if ev_currency.num <= 0 then pItems[47001] = nil end
	return pItems
end

function listlayer.create()
	local IDS = activityData.IDS
    local all_items = getItems()
    local activity_items = {}
    local touch_items = {}
    local item_count = 0
    local padding = 5
    local item_width = 290
    local item_height = 70
    local function init()
        local groups = {}
        for _, tmp_item in pairs(all_items) do
            if tmp_item.group then
                if groups[tmp_item.group] then  -- 属于group组的活动，已经添加过了
                else
                    local item_status = activityData.getStatusById(tmp_item.id)
                    if item_status then
                        tbl2string(item_status)
                    end
                    if item_status and item_status.status == 0  and item_status.cd and
                            item_status.cd > os.time() - activityData.pull_time then
                        item_count = item_count + 1
                        activity_items[item_count] = tmp_item
                        activity_items[item_count].status = item_status
                        groups[tmp_item.group] = tmp_item.group
                    elseif item_status and item_status.status == 0  and tmp_item.nocd then  -- 没有cd
                        item_count = item_count + 1
                        activity_items[item_count] = tmp_item
                        activity_items[item_count].status = item_status
                        groups[tmp_item.group] = tmp_item.group
                    else
                        print("======================================if 3")
                    end
                end
            end
        end
        -- 登陆奖励 和 月卡 固定放前面2个
        local function sortValue(_obj)
            if _obj.id == IDS.MONTH_LOGIN.ID then
                return 100000
            elseif _obj.id == IDS.MONTH_CARD.ID then
                return 99999
            elseif _obj.id == IDS.MINI_CARD.ID then
                return 99998
            else
                return _obj.id
            end
        end
        table.sort(activity_items, function(a, b)
            return sortValue(a) > sortValue(b)
        end)
    end
    init()

    local layer = CCLayer:create()
    
    -- dark bg
    local darkbg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY*0.8))
    layer:addChild(darkbg)
    
    -- money bar
    local moneybar = require "ui.moneybar"
    layer:addChild(moneybar.create(), 101)

    local content_layer = CCLayer:create()
    content_layer:setTouchEnabled(true)
    content_layer:setTouchSwallowEnabled(false)
    layer:addChild(content_layer, 100)

    local board = img.createUISprite(img.ui.activity_board)
    board:setScale(view.minScale)
    board:setAnchorPoint(CCPoint(0.5,0))
    board:setPosition(scalep(480, 0))
    layer:addChild(board)
    local board_w = board:getContentSize().width
    local board_h = board:getContentSize().height

    local function backEvent()
        layer:removeFromParent()
    end
    -- btn_close
    local btn_close0 = img.createUISprite(img.ui.close)
    local btn_close = SpineMenuItem:create(json.ui.button, btn_close0)
    btn_close:setScale(view.minScale)
    --btn_close:setPosition(CCPoint(board_w-32, board_h-74))
    btn_close:setPosition(scalep(960-32, 576-74))
    local btn_close_menu = CCMenu:createWithItem(btn_close)
    btn_close_menu:setPosition(CCPoint(0, 0))
    layer:addChild(btn_close_menu, 100)
    btn_close:registerScriptTapHandler(function()
        audio.play(audio.button)
        backEvent()
    end)

    --local bar = img.createUISprite(img.ui.activity_bar)
    --bar:setAnchorPoint(CCPoint(0, 1))
    --bar:setPosition(CCPoint(48, board_h-50))
    --board:addChild(bar, 10)
    local bar_icon = img.createUISprite(img.ui.activity_bar_icon)
    bar_icon:setAnchorPoint(CCPoint(0.5, 0))
    bar_icon:setPosition(CCPoint(200, 54+430))
    board:addChild(bar_icon)
    local lbl_bar = lbl.createFont2(22, i18n.global.activity_board_title.string, ccc3(0xfa, 0xd8, 0x69))
    lbl_bar:setPosition(CCPoint(200, 41+430))
    board:addChild(lbl_bar)

    local tree_icon = img.createUISprite(img.ui.activity_icon_tree)
    tree_icon:setAnchorPoint(CCPoint(0.5, 0))
    tree_icon:setPosition(CCPoint(60, 435))
    board:addChild(tree_icon)

    local sea_icon = img.createUISprite(img.ui.activity_icon_sea)
    sea_icon:setAnchorPoint(CCPoint(0.5, 1))
    sea_icon:setPosition(CCPoint(board_w/2, 95))
    board:addChild(sea_icon)
    --local scroll_bg = img.createUI9Sprite(img.ui.inner_bg)
    --scroll_bg:setPreferredSize(CCSizeMake(290, 382))
    --scroll_bg:setAnchorPoint(CCPoint(0, 0))
    --scroll_bg:setPosition(CCPoint(53, 67))
    --board:addChild(scroll_bg)

    local function createItem(item_obj)
        --local tmp_item = img.createUISprite(item_obj.icon)
        local tmp_item = img.createUISprite(img.ui.activity_item_bg)
        local tmp_item_w = tmp_item:getContentSize().width
        local tmp_item_h = tmp_item:getContentSize().height
        local tmp_item_sel = img.createUISprite(img.ui.activity_item_bg_sel)
        tmp_item_sel:setPosition(CCPoint(tmp_item_w/2, tmp_item_h/2))
        tmp_item:addChild(tmp_item_sel)
        tmp_item.sel = tmp_item_sel
        tmp_item_sel:setVisible(false)
        local item_icon = img.createUISprite(item_obj.icon)
        item_icon:setPosition(CCPoint(40, tmp_item_h/2))
        tmp_item:addChild(item_icon, 10)
        local lbl_description = lbl.create({font=1, size=12, text=item_obj.description, color=ccc3(0x73, 0x3b, 0x05),
                                cn={size=16}, us={size=14}, tw={size=16}
                            })
        if item_obj.nocd then
            lbl_description:setAnchorPoint(CCPoint(0, 0.5))
            lbl_description:setPosition(CCPoint(94, tmp_item_h/2))
        else
            lbl_description:setAnchorPoint(CCPoint(0, 0))
            lbl_description:setPosition(CCPoint(94, tmp_item_h/2))
        end
        tmp_item:addChild(lbl_description, 2)
        local lbl_cd = lbl.create({font=2, size=10, text="", color=ccc3(0xb5, 0xf4, 0x3b),
                                cn={size=14}, us={size=12}, tw={size=14}
                            })
        --lbl_cd:setColor(ccc3(0xb5, 0xf4, 0x3b))
        lbl_cd:setAnchorPoint(CCPoint(0, 1))
        lbl_cd:setPosition(CCPoint(94, tmp_item_h/2-2))
        tmp_item:addChild(lbl_cd)
        tmp_item.lbl_cd = lbl_cd
        addRedDot(tmp_item, {
            px = tmp_item:getContentSize().width-5,
            py = tmp_item:getContentSize().height-10,
        })
        delRedDot(tmp_item)
        return tmp_item
    end

    local lineScroll = require "ui.lineScroll"
    local scroll_params = {
        width = 290,
        height = 359,
    }
    local scroll = lineScroll.create(scroll_params)
    scroll:setAnchorPoint(CCPoint(0, 0))
    scroll:setPosition(CCPoint(53, 74))
    board:addChild(scroll)
    layer.scroll = scroll
    --drawBoundingbox(scroll_bg, scroll)
    local function showList(listObjs)
        for ii=1,#listObjs do
            if ii == 1 then
                scroll.addSpace(4)
            end
            local tmp_item = createItem(listObjs[ii])
            touch_items[#touch_items+1] = tmp_item
            tmp_item.obj = listObjs[ii]
            tmp_item.ax = 0.5
            tmp_item.px = 145
            scroll.addItem(tmp_item)
            if ii ~= item_count then
                scroll.addSpace(padding-3)
            end
        end
    end
    showList(activity_items)

    scroll.setOffsetBegin()

    function layer.onAndroidBack()
        backEvent()
    end

    layer:setTouchEnabled(true)
    layer:setTouchSwallowEnabled(true)
        
    addBackEvent(layer)

    local function onEnter()
        print("onEnter")
        layer.notifyParentLock()
        if item_count == 0 then
            --showToast(i18n.global.event_empty.string)
            --backEvent()
        end
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

    -- for touch
    local last_touch_sprite = nil
    local last_sel_sprite = nil
    local function clearShaderForItem(itemObj)
        if itemObj and not tolua.isnull(itemObj) then
            clearShader(itemObj, true)
            itemObj = nil
        end
    end
    local function setShaderForItem(itemObj)
        setShader(itemObj, SHADER_HIGHLIGHT, true)
        last_touch_sprite = itemObj
    end
    local touchbeginx, touchbeginy
    local isclick
    local function onTouchBegan(x, y)
        touchbeginx, touchbeginy = x, y
        isclick = true
        if not scroll or tolua.isnull(scroll) then return true end
        local p1 = scroll.content_layer:convertToNodeSpace(ccp(x, y))
        for ii=1,#touch_items do
            if touch_items[ii]:boundingBox():containsPoint(p1) then
                --playAnimTouchBegin(touch_items[ii])
                last_touch_sprite = touch_items[ii]
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
        local p0 = layer:convertToNodeSpace(ccp(x, y))
        if isclick and not board:boundingBox():containsPoint(p0) then
            backEvent()
        elseif isclick then
            local p1 = scroll.content_layer:convertToNodeSpace(ccp(x, y))
            for ii=1,#touch_items do
                if touch_items[ii]:boundingBox():containsPoint(p1) then
                    if last_sel_sprite and last_sel_sprite == touch_items[ii] then
                        return 
                    elseif last_sel_sprite and not tolua.isnull(last_sel_sprite) then
                        if last_sel_sprite.sel and not tolua.isnull(last_sel_sprite.sel) then
                            last_sel_sprite.sel:setVisible(false)
                        end
                    end
                    audio.play(audio.button)
                    touch_items[ii].sel:setVisible(true)
                    touch_items[ii].obj.tapFunc(content_layer)
                    last_sel_sprite = touch_items[ii]
                    -- set read
                    if touch_items[ii].obj.status then
                        touch_items[ii].obj.status.read = 1
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

    local last_check_time = 0
    local function updateCountDown()
        if os.time() - last_check_time < 1 then return end
        last_check_time = os.time()
        for ii=1,#touch_items do
            local item_status = touch_items[ii].obj.status
            if item_status.status == 0 and not touch_items[ii].obj.nocd then
                if item_status.cd and os.time() - activityData.pull_time > item_status.cd then
                    item_status.status = 1
                    refreshSelf(content_layer)
                elseif item_status.cd then
                    local count_down = item_status.cd - (os.time() - activityData.pull_time)
                    local time_str = time2string(count_down)
                    touch_items[ii].lbl_cd:setString(time_str)
                end
            end
            -- red dot
            local tmp_status = item_status --activityData.getStatusById(touch_items[ii].obj.id)
            if touch_items[ii].obj.redFunc then
                if touch_items[ii].obj.redFunc() then
                    addRedDot(touch_items[ii], {
                        px = touch_items[ii]:getContentSize().width-5,
                        py = touch_items[ii]:getContentSize().height-10,
                    })
                else
                    delRedDot(touch_items[ii])
                end
            elseif tmp_status and tmp_status.read and tmp_status.read == 0 then
                addRedDot(touch_items[ii], {
                    px = touch_items[ii]:getContentSize().width-5,
                    py = touch_items[ii]:getContentSize().height-10,
                })
            else
                delRedDot(touch_items[ii])
            end
        end
    end
    local function onUpdate(ticks)
        updateCountDown()
    end
    layer:scheduleUpdateWithPriorityLua(onUpdate, 0)
    
    -- show firt activity
    if #touch_items > 0 then
        if touch_items[1].sel and not tolua.isnull(touch_items[1].sel) then
            touch_items[1].sel:setVisible(true)
        end
        touch_items[1].obj.tapFunc(content_layer)
        last_sel_sprite = touch_items[1]
        -- set read
        if touch_items[1].obj.status then
            touch_items[1].obj.status.read = 1
        end
    end

    return layer
end

return listlayer
