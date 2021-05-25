local ui = {}

require "common.func"
require "common.const"
local view = require "common.view"
local img = require "res.img"
local i18n = require "res.i18n"
local lbl = require "res.lbl"
local json = require "res.json"
local audio = require "res.audio"
local player = require "data.player"

function ui.create(uiParams)
    local layer = CCLayer:create()
    -- dark bg
    local darkbg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    layer:addChild(darkbg)
    -- board
    local board= img.createUI9Sprite(img.ui.dialog_1)
    board:setPreferredSize(CCSizeMake(796, 510))
    board:setScale(view.minScale)
    board:setAnchorPoint(CCPoint(0.5, 0))
    board:setPosition(view.midX-0*view.minScale, view.minY+15*view.minScale)
    layer:addChild(board)
    layer.board = board
    local board_w = board:getContentSize().width
    local board_h = board:getContentSize().height

    -- anim
    if uiParams and uiParams._anim then
        --board:setScale(0.3*view.minScale)
        --board:runAction(CCEaseBackOut:create(CCScaleTo:create(0.3, 1*view.minScale, 1*view.minScale)))
        board:setScale(0.5*view.minScale)
        board:runAction(CCScaleTo:create(0.15, 1*view.minScale, 1*view.minScale))
    end

    -- title
    local lbl_title = lbl.createFont1(24, "", ccc3(0xe6, 0xd0, 0xae))
    lbl_title:setPosition(CCPoint(board_w/2, board_h-29))
    board:addChild(lbl_title, 2)
    local lbl_title_shadowD = lbl.createFont1(24, "", ccc3(0x59, 0x30, 0x1b))
    lbl_title_shadowD:setPosition(CCPoint(board_w/2, board_h-31))
    board:addChild(lbl_title_shadowD)

    function layer.setTitle(_str)
        lbl_title:setString(_str)
        lbl_title_shadowD:setString(_str)
    end

    local function backEvent()
        audio.play(audio.button)
        layer:removeFromParentAndCleanup(true)
    end
    -- btn_close
    local btn_close0 = img.createUISprite(img.ui.close)
    local btn_close = SpineMenuItem:create(json.ui.button, btn_close0)
    btn_close:setPosition(CCPoint(board_w-25, board_h-28))
    local btn_close_menu = CCMenu:createWithItem(btn_close)
    btn_close_menu:setPosition(CCPoint(0, 0))
    board:addChild(btn_close_menu, 100)
    layer.btn_close = btn_close
    btn_close:registerScriptTapHandler(function()
        backEvent()
    end)

    -- inner_board
    local inner_board = img.createUI9Sprite(img.ui.bag_btn_inner_bg)
    inner_board:setPreferredSize(CCSizeMake(742, 406))
    inner_board:setAnchorPoint(CCPoint(0.5, 0))
    inner_board:setPosition(CCPoint(board_w/2, 35))
    board:addChild(inner_board)
    layer.inner_board = inner_board
    local inner_board_w = inner_board:getContentSize().width
    local inner_board_h = inner_board:getContentSize().height

    return layer
end

return ui
