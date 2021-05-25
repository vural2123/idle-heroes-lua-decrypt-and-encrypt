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
local tipsequip = require "ui.tips.equip"
local tipsitem = require "ui.tips.item"
local dialog = require "ui.dialog"
local NetClient = require "net.netClient"
local netClient = NetClient:getInstance()

local TAB = {
    MEMBER = 1,
    APPLY = 2,
}
ui.TAB = TAB

function ui.create(_tab)
    local layer = CCLayer:create()
    -- dark bg
    local darkbg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    layer:addChild(darkbg)

    local bg = img.createUI9Sprite(img.ui.dialog_1)
    bg:setPreferredSize(CCSizeMake(680, 540))
    bg:setScale(view.minScale)
    bg:setPosition(CCPoint(view.midX, view.midY-0*view.minScale))
    layer:addChild(bg)
    local bg_w = bg:getContentSize().width
    local bg_h = bg:getContentSize().height

    bg:setScale(0.5*view.minScale)
    local anim_arr = CCArray:create()
    anim_arr:addObject(CCScaleTo:create(0.15, 1*view.minScale, 1*view.minScale))
    -- anim
    bg:runAction(CCSequence:create(anim_arr))

    local function backEvent()
        audio.play(audio.button)
        layer:removeFromParentAndCleanup(true)
    end

    -- title
    local lbl_title = lbl.createFont1(24, "", ccc3(0xe6, 0xd0, 0xae))
    lbl_title:setPosition(CCPoint(bg_w/2, bg_h-29))
    bg:addChild(lbl_title, 2)
    local lbl_title_shadowD = lbl.createFont1(24, "", ccc3(0x59, 0x30, 0x1b))
    lbl_title_shadowD:setPosition(CCPoint(bg_w/2, bg_h-31))
    bg:addChild(lbl_title_shadowD)
    function layer.setTitle(_title)
        lbl_title:setString(_title)
        lbl_title_shadowD:setString(_title)
    end
    -- btn_close
    local btn_close0 = img.createUISprite(img.ui.close)
    local btn_close = SpineMenuItem:create(json.ui.button, btn_close0)
    btn_close:setPosition(CCPoint(bg_w-25, bg_h-28))
    local btn_close_menu = CCMenu:createWithItem(btn_close)
    btn_close_menu:setPosition(CCPoint(0, 0))
    bg:addChild(btn_close_menu, 100)
    btn_close:registerScriptTapHandler(function()
        backEvent()
    end)

    -- board
    local board = img.createUI9Sprite(img.ui.inner_bg)
    board:setPreferredSize(CCSizeMake(634, 440))
    board:setAnchorPoint(CCPoint(0.5, 0))
    board:setPosition(CCPoint(bg_w/2, 33))
    bg:addChild(board)
    layer.board = board
    local board_w = board:getContentSize().width
    local board_h = board:getContentSize().height

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
