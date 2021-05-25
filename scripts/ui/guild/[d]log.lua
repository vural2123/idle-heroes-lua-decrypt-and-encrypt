
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
local player = require "data.player"
local i18n = require "res.i18n"

local space_height = 5

local function proc(logs)
    if not logs then return {} end
    table.sort(logs, function(a, b)
        if not b then
            return true
        elseif not a then
            return false
        else
            return a.time > b.time
        end
    end)
    local dates = {}
    local last_date = ""
    for ii=1,#logs do
        if last_date ~= os.date("%y%m%d", logs[ii].time) then
            last_date = os.date("%y%m%d", logs[ii].time)
            dates[#dates+1] = {}
            dates[#dates].title = os.date("%m-%d", logs[ii].time)
            dates[#dates].list = {}
        else
        end
        local tmp_list = dates[#dates].list
        tmp_list[#tmp_list+1] = logs[ii]
    end
    return dates
end

function ui.create(logs)
    local layer = CCLayer:create()

    local sortLogs = proc(logs)

    -- dark bg
    local darkbg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    layer:addChild(darkbg)

    local function backEvent()
        audio.play(audio.button)
        layer:removeFromParentAndCleanup(true)
    end
    -- board
    local board = img.createUI9Sprite(img.ui.tips_bg)
    board:setPreferredSize(CCSizeMake(664, 416))
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

    -- closeBtn
    local closeBtn0 = img.createUISprite(img.ui.close)
    local closeBtn = SpineMenuItem:create(json.ui.button, closeBtn0)
    closeBtn:setPosition(board_w-23, board_h-26)
    local closeMenu = CCMenu:createWithItem(closeBtn)
    closeMenu:setPosition(0, 0)
    board:addChild(closeMenu)
    closeBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        backEvent()
    end)

    -- title
    local lbl_title = lbl.createFont1(22, i18n.global.guild_log_board_title.string, ccc3(0xff, 0xe3, 0x86))
    lbl_title:setPosition(CCPoint(board_w/2, board_h-32))
    board:addChild(lbl_title)
    local tips_line = img.createUI9Sprite(img.ui.hero_tips_fgline)
    tips_line:setPreferredSize(CCSizeMake(594, 1))
    tips_line:setPosition(CCPoint(board_w/2, board_h-62))
    board:addChild(tips_line)

    -- logs
    --
    local function createItem(itemObj)
        local t_str = os.date("%H:%M  ", itemObj.time)
        local e_str
        if itemObj.type == 1 then       -- 创建公会
            e_str = string.format(i18n.global.guild_log_create.string, itemObj.do_name)
        elseif itemObj.type == 2 then       -- 加入公会
            e_str = string.format(i18n.global.guild_log_new.string, itemObj.do_name)
        elseif itemObj.type == 3 then       -- 任命官员
            --e_str = itemObj.do_name .. " appointed " .. itemObj.obj_name .. " as an officer"
            e_str = string.format(i18n.global.guild_log_appoint.string, itemObj.obj_name)
        elseif itemObj.type == 4 then       -- 罢免官员
            --e_str = itemObj.do_name .. " recalled " .. itemObj.obj_name .. "'s officer"
            e_str = string.format(i18n.global.guild_log_downgrade.string, itemObj.obj_name)
        elseif itemObj.type == 5 then       -- 逐出公会
            --e_str = itemObj.do_name .. " chased " .. itemObj.obj_name
            e_str = string.format(i18n.global.guild_log_chase.string, itemObj.obj_name)
        elseif itemObj.type == 6 then       -- 转让会长
            --e_str = itemObj.do_name .. " transfered president to " .. itemObj.obj_name
            e_str = string.format(i18n.global.guild_log_transfer.string, itemObj.do_name, itemObj.obj_name)
        elseif itemObj.type == 7 then       -- 退出公会
            --e_str = itemObj.do_name .. " quit from guild"
            e_str = string.format(i18n.global.guild_log_quit.string, itemObj.do_name)
        end
        local item = lbl.createFontTTF(18, t_str .. e_str, ccc3(0xfe, 0xeb, 0xca))
        return item
    end
    local function createTitleItem(itemObj)
        local item = img.createUISprite(img.ui.guild_vtitle_bg)
        local item_title = lbl.createFont1(18, itemObj.title, ccc3(0xeb, 0xaa, 0x5e))
        item_title:setPosition(CCPoint(item:getContentSize().width/2, item:getContentSize().height/2))
        item:addChild(item_title)
        return item
    end

    local function createScroll()
        local scroll_params = {
            width = 594,
            height = 310,
        }
        local lineScroll = require "ui.lineScroll"
        return lineScroll.create(scroll_params)
    end

    local function showList(listObj)
        --board:removeAllChildrenWithCleanup(true)
        board.scroll = nil
        local scroll = createScroll()
        scroll:setAnchorPoint(CCPoint(0, 0))
        scroll:setPosition(CCPoint(35, 35))
        board:addChild(scroll)
        board.scroll = scroll
        --drawBoundingbox(board, scroll)
        for ii=1,#listObj do
            local tmp_item = createTitleItem(listObj[ii])
            tmp_item.ax = 0
            tmp_item.px = 0
            scroll.addItem(tmp_item)
            local tmp_list = listObj[ii].list
            for jj=1,#tmp_list do
                local tmp_item = createItem(tmp_list[jj])
                tmp_item.ax = 0.0
                tmp_item.px = 0
                scroll.addItem(tmp_item)
                if jj ~= #tmp_list then
                    scroll.addSpace(space_height)
                end
            end
            if ii ~= #listObj then
                scroll.addSpace(space_height)
            end
        end
        scroll.setOffsetBegin()
    end

    showList(sortLogs)

    layer:setTouchEnabled(true)
    layer:setTouchSwallowEnabled(true)

    -- touch event
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
            local p0 = layer:convertToNodeSpace(ccp(x, y))
            if not board:boundingBox():containsPoint(p0) then
                --backEvent()
                return
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
    --layer:registerScriptTouchHandler(onTouch , false , -128 , false)

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
