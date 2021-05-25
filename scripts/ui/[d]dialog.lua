local dialog = {}

require "common.func"
local view = require "common.view"
local lbl = require "res.lbl"
local img = require "res.img"
local audio = require "res.audio"
local json = require "res.json"

dialog.TAG = 123333
dialog.COLOR_BLUE = "blue"
dialog.COLOR_GOLD = "gold"
dialog.COLOR_RED = "red"
dialog.COLOR_GREEN = "green"

local btn_pos = {
    [1] = {
        [1] ={
            x = 180, y= 55
        },
    },
    [2] = {
        [1] ={
            x = 86, y= 55
        },
        [2] ={
            x = 273, y= 55
        },
    },
    [3] = {
        [1] ={
            x = 52, y= 55
        },
        [2] ={
            x = 180, y= 55
        },
        [3] ={
            x = 308, y= 55
        },
    },
}

local btn_blue = img.login.button_9_small_gold
local btn_gold = img.login.button_9_small_gold
local btn_red = img.login.button_9_small_gold
local btn_green = img.login.button_9_small_green

--[[
    params = {
        title = text,
        body = text,
        text_color = color,
        text_fontsize = fontsize,
        btn_count = n,
        btn_text = {
            [n] = text,
        },
        btn_color = {
            [n] = color, -- [gold|blue|green|red]
        },
        selected_btn = index,
        callback = func,
    }
]]--

local function init_params(params)
    params.title = params.title or ""
    params.body = params.body or ""
    params.text_color = params.text_color or ccc3(0x63,0x34,0x18)
    params.text_fontsize = params.text_fontsize or 20
    params.board_w = params.board_w or 474
    params.board_h = params.board_h or 327
    if not params.btn_color then
        params.btn_color = {}
        for ii=1,params.btn_count do
            params.btn_color[ii] = "gold"
        end
    end
end

function dialog.create(params, outside_remove)
    init_params(params)
    local scale_factor = params.scale_factor or view.minScale
    local layer = CCLayer:create()

    function layer.setCallback(cb)
        params.callback = cb
    end

    -- 点击空白区域的回调
    local clickBlankHandler
    function layer.setClickBlankHandler(handler)
        clickBlankHandler = handler
    end

    -- dark bg
    local darkbg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    layer:addChild(darkbg)
    
    local board = img.createLogin9Sprite(img.login.dialog)
    local board_w = params.board_w
    local board_h = params.board_h
    
    board:setPreferredSize(CCSize(board_w, board_h))
    board:setScale(scale_factor)
    board:setAnchorPoint(CCPoint(0.5,0.5))
    board:setPosition(CCPoint(view.physical.w/2, view.physical.h/2))
    layer:addChild(board, 100)
    layer.board = board
    
    -- board anim
    board:setScale(0.1 * scale_factor)
    board:runAction(CCEaseBackOut:create(CCScaleTo:create(0.3, scale_factor)))

    -- create title
    if params.title then
        local lbl_title = lbl.createMixFont1(24, params.title, ccc3(0xe6, 0xd0, 0xae))
        lbl_title:setPosition(CCPoint(board_w/2, board_h-29))
        board:addChild(lbl_title,2)
        local lbl_title_shadowD = lbl.createMixFont1(24, params.title, ccc3(0x59, 0x30, 0x1b))
        lbl_title_shadowD:setPosition(CCPoint(board_w/2, board_h-31))
        board:addChild(lbl_title_shadowD)
    end
    -- create body
    if params.body then
        local lbl_body = lbl.createMix({
            font = 1, size = 18, text = params.body, color = ccc3(0x78, 0x46, 0x27),
            width = 400, align = kCCTextAlignmentLeftt
        })
        lbl_body:setAnchorPoint(CCPoint(0.5, 1))
        lbl_body:setPosition(CCPoint(board_w/2, board_h-100))
        board:addChild(lbl_body)
        layer.bodyLabel = lbl_body
    end

    -- create btn
    local btn_size
    if params.btn_count < 3 then
        btn_size = CCSize(153, 50)
    else
        btn_size = CCSize(115, 50)
    end
    layer.btns = {}
    for ii=1,params.btn_count do
        local btn_image = btn_gold
        if params.btn_color[ii] == dialog.COLOR_RED then
            btn_image = btn_red
        elseif params.btn_color[ii] == dialog.COLOR_BLUE then
            btn_image = btn_blue
        elseif params.btn_color[ii] == dialog.COLOR_GOLD then
            btn_image = btn_gold
        elseif params.btn_color[ii] == dialog.COLOR_GREEN then
            btn_image = btn_green
        end
        local btn_sprite1 = img.createLogin9Sprite(btn_image) 
        btn_sprite1:setPreferredSize(btn_size)
        local btn = SpineMenuItem:create(json.ui.button, btn_sprite1)
        --btn:setAnchorPoint(CCPoint(0, 0))
        btn:setPosition(CCPoint(btn_pos[params.btn_count][ii].x+57, 
                    btn_pos[params.btn_count][ii].y+27))
        btn:setEnabled(true)
        btn:registerScriptTapHandler(function()
            audio.play(audio.button)
            params.callback({ selected_btn = ii, button = btn })
        end)
        local lbl_btn_text = lbl.createFont1(18, params.btn_text[ii], ccc3(0x73, 0x3b, 0x05))
        lbl_btn_text:setAnchorPoint(CCPoint(0.5,0.5)) 
        lbl_btn_text:setPosition(CCPoint(btn:getContentSize().width/2,btn:getContentSize().height/2))
        --lbl_btn_text:setColor(ccc3(245,201,106))
        btn_sprite1:addChild(lbl_btn_text, 1000)
        local btn_menu = CCMenu:createWithItem(btn)
        btn_menu:setPosition(CCPoint(0,0))
        board:addChild(btn_menu)
        layer.btns[ii] = btn
    end

    function layer.moveBtnPosition(px, py)
        for ii=1, params.btn_count do
            layer.btns[ii]:setPosition(CCPoint(layer.btns[ii]:getPositionX()+px,
                        layer.btns[ii]:getPositionY()+py))
        end
    end

    -- for touch
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
        if not outside_remove and params.btn_count ~= nil and params.btn_count > 0 then
            return
        end
        if isclick and not board:boundingBox():containsPoint(ccp(x, y)) then
            if clickBlankHandler then
                clickBlankHandler()
            else
                layer:removeFromParentAndCleanup(true)
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

    layer:registerScriptTouchHandler(onTouch, false , -128 , false)
    layer:setTouchEnabled(true)
    
    function layer.onAndroidBack()
        layer:removeFromParentAndCleanup(true)
    end
        
    addBackEvent(layer)

    local function onEnter()
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

function dialog.setCallback(_callback)
    __callback = _callback
end

return dialog


--[[
-- this is an example of dialog usage .

function onShow_dialog()
        function process_dialog(data)
            layer:removeChildByTag(dialog.TAG)
            showToast(layer, "u choosed " .. data.selected_btn .. " button.")
        end
        local params = {
            title = "dialog example",
            body = "this is an example of dialog, please\n select a button below!\n",
            btn_count = 3,
            btn_text = {
                [1] = "Yes",
                [2] = "No",
                [3] = "Cancel",
            },
            selected_btn = 0,
            callback = process_dialog,
        }
        dialog_ins = dialog.create(params)
        --dialog_ins:setAnchorPoint(CCPoint(0.5, 0.5))
        --dialog_ins:setPosition(CCPoint(view.physical.w/2, view.physical.h/2))
        layer:addChild(dialog_ins, 10000, dialog.TAG)
end
--]]
