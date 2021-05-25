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

local TAB = {
    OPTION = 1,
    HELP = 2,
    SERVER = 3,
    --PUB = 4,
    FEED = 4,
}
ui.TAB = TAB

function ui.create(_tab, _anim)
    local layer = CCLayer:create()
    -- dark bg
    local darkbg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    layer:addChild(darkbg)
    -- board
    local board= img.createUI9Sprite(img.ui.dialog_1)
    board:setPreferredSize(CCSizeMake(790, 526))
    board:setScale(view.minScale)
    board:setPosition(view.midX-5*view.minScale, view.midY)
    layer:addChild(board)
    layer.board = board
    local board_w = board:getContentSize().width
    local board_h = board:getContentSize().height

    -- anim
    if _anim then
        board:setScale(0.5*view.minScale)
        board:runAction(CCScaleTo:create(0.15, 1*view.minScale, 1*view.minScale))
    end

    -- title
    local lbl_title = lbl.createFont1(24, i18n.global.setting_board_title.string, ccc3(0xe6, 0xd0, 0xae))
    lbl_title:setPosition(CCPoint(board_w/2, board_h-29))
    board:addChild(lbl_title, 2)
    local lbl_title_shadowD = lbl.createFont1(24, i18n.global.setting_board_title.string, ccc3(0x59, 0x30, 0x1b))
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
    inner_board:setPreferredSize(CCSizeMake(736, 422))
    inner_board:setAnchorPoint(CCPoint(0.5, 0))
    inner_board:setPosition(CCPoint(board_w/2, 35))
    board:addChild(inner_board)
    layer.inner_board = inner_board
    local inner_board_w = inner_board:getContentSize().width
    local inner_board_h = inner_board:getContentSize().height

    -- tabs
    local tab_offset_y = 20
    local tab_opt0 = img.createUISprite(img.ui.setting_tab_opt_norm)
    local tab_opt = HHMenuItem:createWithScale(tab_opt0, 1)
    tab_opt:setScale(0.5)
    tab_opt:setAnchorPoint(CCPoint(0, 0))
    tab_opt:setPosition(CCPoint(758, 322+tab_offset_y))
    local tab_opt_menu = CCMenu:createWithItem(tab_opt)
    tab_opt_menu:setPosition(CCPoint(0, 0))
    board:addChild(tab_opt_menu)
    local tab_opt_sel = img.createUISprite(img.ui.setting_tab_opt_sel)
    tab_opt_sel:setAnchorPoint(CCPoint(0, 0))
    tab_opt_sel:setPosition(CCPoint(0, 0))
    tab_opt:addChild(tab_opt_sel)
    tab_opt_sel:setVisible(false)

    local tab_faq0 = img.createUISprite(img.ui.setting_tab_help_norm)
    local tab_faq = HHMenuItem:createWithScale(tab_faq0, 1)
    tab_faq:setScale(0.5)
    tab_faq:setAnchorPoint(CCPoint(0, 0))
    tab_faq:setPosition(CCPoint(758, 230+tab_offset_y))
    local tab_faq_menu = CCMenu:createWithItem(tab_faq)
    tab_faq_menu:setPosition(CCPoint(0, 0))
    board:addChild(tab_faq_menu)
    local tab_faq_sel = img.createUISprite(img.ui.setting_tab_help_sel)
    tab_faq_sel:setAnchorPoint(CCPoint(0, 0))
    tab_faq_sel:setPosition(CCPoint(0, 0))
    tab_faq:addChild(tab_faq_sel)
    tab_faq_sel:setVisible(false)

    local tab_svr0 = img.createUISprite(img.ui.setting_tab_svr_norm)
    local tab_svr = HHMenuItem:createWithScale(tab_svr0, 1)
    tab_svr:setScale(0.5)
    tab_svr:setAnchorPoint(CCPoint(0, 0))
    tab_svr:setPosition(CCPoint(758, 138+tab_offset_y))
    local tab_svr_menu = CCMenu:createWithItem(tab_svr)
    tab_svr_menu:setPosition(CCPoint(0, 0))
    board:addChild(tab_svr_menu)
    local tab_svr_sel = img.createUISprite(img.ui.setting_tab_svr_sel)
    tab_svr_sel:setAnchorPoint(CCPoint(0, 0))
    tab_svr_sel:setPosition(CCPoint(0, 0))
    tab_svr:addChild(tab_svr_sel)
    tab_svr_sel:setVisible(false)

    --local tab_pub0 = img.createUISprite(img.ui.setting_tab_pub_norm)
    --local tab_pub = HHMenuItem:createWithScale(tab_pub0, 1)
    --tab_pub:setAnchorPoint(CCPoint(0, 0))
    --tab_pub:setPosition(CCPoint(758, 46+tab_offset_y))
    --local tab_pub_menu = CCMenu:createWithItem(tab_pub)
    --tab_pub_menu:setPosition(CCPoint(0, 0))
    --board:addChild(tab_pub_menu)
    --local tab_pub_sel = img.createUISprite(img.ui.setting_tab_pub_sel)
    --tab_pub_sel:setAnchorPoint(CCPoint(0, 0))
    --tab_pub_sel:setPosition(CCPoint(0, 0))
    --tab_pub:addChild(tab_pub_sel)
    --tab_pub_sel:setVisible(false)

    local tab_feed0 = img.createUISprite(img.ui.setting_tab_feed_norm)
    local tab_feed = HHMenuItem:createWithScale(tab_feed0, 1)
    tab_feed:setScale(0.5)
    tab_feed:setAnchorPoint(CCPoint(0, 0))
    tab_feed:setPosition(CCPoint(758, 46+tab_offset_y))
    local tab_feed_menu = CCMenu:createWithItem(tab_feed)
    tab_feed_menu:setPosition(CCPoint(0, 0))
    board:addChild(tab_feed_menu)
    local tab_feed_sel = img.createUISprite(img.ui.setting_tab_feed_sel)
    tab_feed_sel:setAnchorPoint(CCPoint(0, 0))
    tab_feed_sel:setPosition(CCPoint(0, 0))
    tab_feed:addChild(tab_feed_sel)
    tab_feed_sel:setVisible(false)

    if _tab == TAB.OPTION then
        tab_opt_sel:setVisible(true)
        tab_opt:setEnabled(false)
    elseif _tab == TAB.HELP then
        tab_faq_sel:setVisible(true)
        tab_faq:setEnabled(false)
    elseif _tab == TAB.SERVER then
        tab_svr_sel:setVisible(true)
        tab_svr:setEnabled(false)
    --elseif _tab == TAB.PUB then
    --    tab_pub_sel:setVisible(true)
    --    tab_pub:setEnabled(false)
    elseif _tab == TAB.FEED then
        tab_feed_sel:setVisible(true)
        tab_feed:setEnabled(false)
    end

    tab_opt:registerScriptTapHandler(function()
        audio.play(audio.button)
        local parentObj = layer:getParent()
        layer:removeFromParentAndCleanup(true)
        parentObj:addChild((require"ui.setting.option").create(), 1000)
    end)
    tab_faq:registerScriptTapHandler(function()
        audio.play(audio.button)
        local parentObj = layer:getParent()
        layer:removeFromParentAndCleanup(true)
        parentObj:addChild((require"ui.setting.help").create(), 1000)
    end)
    tab_svr:registerScriptTapHandler(function()
        audio.play(audio.button)
        local parentObj = layer:getParent()
        layer:removeFromParentAndCleanup(true)
        parentObj:addChild((require"ui.setting.server").create(), 1000)
    end)
    --tab_pub:registerScriptTapHandler(function()
    --    audio.play(audio.button)
    --    local parentObj = layer:getParent()
    --    layer:removeFromParentAndCleanup(true)
    --    parentObj:addChild((require"ui.setting.notice").create(), 1000)
    --end)
    tab_feed:registerScriptTapHandler(function()
        audio.play(audio.button)
        local parentObj = layer:getParent()
        layer:removeFromParentAndCleanup(true)
        parentObj:addChild((require"ui.setting.feed").create(), 1000)
    end)

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
