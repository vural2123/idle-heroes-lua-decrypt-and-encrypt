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
local player = require "data.player"
local i18n = require "res.i18n"

local space_height = 3

function ui.create(logs)
    local layer = CCLayer:create()

    --local sortLogs = proc(logs)

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
    --drawBoundingbox(layer, board)
    
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
        backEvent()
    end)

    -- title
    local lbl_title = lbl.createFont1(24, i18n.global.casino_records.string, ccc3(0xff, 0xe3, 0x86))
    lbl_title:setPosition(CCPoint(board_w/2, board_h-36))
    board:addChild(lbl_title)
    local tips_line = img.createUI9Sprite(img.ui.hero_tips_fgline)
    tips_line:setPreferredSize(CCSizeMake(594, 1))
    tips_line:setPosition(CCPoint(board_w/2, board_h-64))
    board:addChild(tips_line)

    -- logs
    --
    local function createItem(msgObj)
        local msg_str = msgObj.name .. " " ..  i18n.global.casino_log_gain.string 
        if msgObj.type == 1 then
            msg_str = msg_str .. " " .. i18n.item[msgObj.id].name
        elseif msgObj.type == 2 then
            msg_str = msg_str .. " " .. i18n.equip[msgObj.id].name
        end
        if msgObj.count and msgObj.count > 1 then
            msg_str = msg_str .. " x " .. msgObj.count
        end
        local lbl_msg = lbl.createFontTTF(18, msg_str, ccc3(0xfe, 0xeb, 0xca))
        --local lbl_msg = lbl.create({kind="ttf", size=18, text=msg_str, color=ccc3(0xff, 0xd0, 0x2c),
        --                        width=185, align=kCCTextAlignmentLeft})
        lbl_msg.height = lbl_msg:getContentSize().height
        return lbl_msg
    end
    local function createScroll()
        local scroll_params = {
            width = 594,
            height = 300,
        }
        local lineScroll = require "ui.lineScroll"
        return lineScroll.create(scroll_params)
    end

    local function showList(listObj)
        if not listObj then
            local ui_empty = (require "ui.empty").create({text=i18n.global.empty_reward.string, color=ccc3(255, 246, 223)})
            ui_empty:setPosition(CCPoint(317, 220))
            board:addChild(ui_empty)
            return 
        end
        --board:removeAllChildrenWithCleanup(true)
        board.scroll = nil
        local scroll = createScroll()
        scroll:setAnchorPoint(CCPoint(0, 0))
        scroll:setPosition(CCPoint(35, 35))
        board:addChild(scroll)
        board.scroll = scroll
        for ii=1,#listObj do
            local tmp_item = createItem(listObj[ii])
            tmp_item.ax = 0
            tmp_item.px = 0
            scroll.addItem(tmp_item)
            if ii ~= #listObj then
                scroll.addSpace(space_height)
            end
        end
        scroll.setOffsetBegin()
    end

    showList(logs)

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
                backEvent()
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
    layer:registerScriptTouchHandler(onTouch , false , -128 , false)

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
