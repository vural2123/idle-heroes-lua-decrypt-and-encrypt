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
local daredata = require "data.dare"

function ui.create(uiParams)
    local layer = CCLayer:create()
    -- dark bg
    local darkbg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    layer:addChild(darkbg)
    -- board
    local board= img.createLogin9Sprite(img.login.dialog)
    board:setPreferredSize(CCSizeMake(840, 512))
    board:setScale(view.minScale)
    board:setPosition(view.midX-0*view.minScale, view.midY)
    layer:addChild(board)
    layer.board = board
    local board_w = board:getContentSize().width
    local board_h = board:getContentSize().height

    -- anim
    if uiParams and uiParams._anim then
        board:setScale(0.5*view.minScale)
        board:runAction(CCScaleTo:create(0.15, 1*view.minScale, 1*view.minScale))
    end

    -- title
    local lbl_title = lbl.createFont1(24, i18n.global.dare_main_title.string, ccc3(0xe6, 0xd0, 0xae))
    lbl_title:setPosition(CCPoint(board_w/2, board_h-29))
    board:addChild(lbl_title, 2)
    local lbl_title_shadowD = lbl.createFont1(24, i18n.global.dare_main_title.string, ccc3(0x59, 0x30, 0x1b))
    lbl_title_shadowD:setPosition(CCPoint(board_w/2, board_h-31))
    board:addChild(lbl_title_shadowD)

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

    local coin_entry = img.createUISprite(img.ui.dare_entry_coin)
    coin_entry:setPosition(CCPoint(420-260, 270))
    board:addChild(coin_entry)
    local coin_info0 = img.createUISprite(img.ui.btn_help)
    local coin_info = SpineMenuItem:create(json.ui.button, coin_info0)
    coin_info:setPosition(CCPoint(420-260+92, 415))
    local coin_info_menu = CCMenu:createWithItem(coin_info)
    coin_info_menu:setPosition(CCPoint(0, 0))
    board:addChild(coin_info_menu)
    local lbl_title_coin = lbl.createFont2(14, i18n.global.dare_main_coin.string, ccc3(255, 246, 223))
    lbl_title_coin:setPosition(CCPoint(420-265, 415))
    board:addChild(lbl_title_coin)
    local btn_coin0 = img.createLogin9Sprite(img.login.button_9_small_gold)
    btn_coin0:setPreferredSize(CCSizeMake(170, 68))
    local lbl_btn_coin = lbl.createFont1(20, i18n.global.dare_btn_challenge.string, ccc3(0x73, 0x3b, 0x05))
    lbl_btn_coin:setPosition(CCPoint(85, 34))
    btn_coin0:addChild(lbl_btn_coin)
    local btn_coin = SpineMenuItem:create(json.ui.button, btn_coin0)
    btn_coin:setPosition(CCPoint(420-260, 85))
    local btn_coin_menu = CCMenu:createWithItem(btn_coin)
    btn_coin_menu:setPosition(CCPoint(0, 0))
    board:addChild(btn_coin_menu)
    local exp_entry = img.createUISprite(img.ui.dare_entry_exp)
    exp_entry:setPosition(CCPoint(420+7, 270))
    board:addChild(exp_entry)
    local exp_info0 = img.createUISprite(img.ui.btn_help)
    local exp_info = SpineMenuItem:create(json.ui.button, exp_info0)
    exp_info:setPosition(CCPoint(420+92, 415))
    local exp_info_menu = CCMenu:createWithItem(exp_info)
    exp_info_menu:setPosition(CCPoint(0, 0))
    board:addChild(exp_info_menu)
    local lbl_title_exp = lbl.createFont2(14, i18n.global.dare_main_exp.string, ccc3(255, 246, 223))
    lbl_title_exp:setPosition(CCPoint(420-5, 415))
    board:addChild(lbl_title_exp)
    local btn_exp0 = img.createLogin9Sprite(img.login.button_9_small_gold)
    btn_exp0:setPreferredSize(CCSizeMake(170, 68))
    local lbl_btn_exp = lbl.createFont1(20, i18n.global.dare_btn_challenge.string, ccc3(0x73, 0x3b, 0x05))
    lbl_btn_exp:setPosition(CCPoint(85, 34))
    btn_exp0:addChild(lbl_btn_exp)
    local btn_exp = SpineMenuItem:create(json.ui.button, btn_exp0)
    btn_exp:setPosition(CCPoint(420, 85))
    local btn_exp_menu = CCMenu:createWithItem(btn_exp)
    btn_exp_menu:setPosition(CCPoint(0, 0))
    board:addChild(btn_exp_menu)
    local soul_entry = img.createUISprite(img.ui.dare_entry_soul)
    soul_entry:setPosition(CCPoint(420+260, 270))
    board:addChild(soul_entry)
    local soul_info0 = img.createUISprite(img.ui.btn_help)
    local soul_info = SpineMenuItem:create(json.ui.button, soul_info0)
    soul_info:setPosition(CCPoint(420+260+87, 415))
    local soul_info_menu = CCMenu:createWithItem(soul_info)
    soul_info_menu:setPosition(CCPoint(0, 0))
    board:addChild(soul_info_menu)
    local lbl_title_soul = lbl.createFont2(14, i18n.global.dare_main_soul.string, ccc3(255, 246, 223))
    lbl_title_soul:setPosition(CCPoint(420+245, 415))
    board:addChild(lbl_title_soul)
    local btn_soul0 = img.createLogin9Sprite(img.login.button_9_small_gold)
    btn_soul0:setPreferredSize(CCSizeMake(170, 68))
    local lbl_btn_soul = lbl.createFont1(20, i18n.global.dare_btn_challenge.string, ccc3(0x73, 0x3b, 0x05))
    lbl_btn_soul:setPosition(CCPoint(85, 34))
    btn_soul0:addChild(lbl_btn_soul)
    local btn_soul = SpineMenuItem:create(json.ui.button, btn_soul0)
    btn_soul:setPosition(CCPoint(420+260, 85))
    local btn_soul_menu = CCMenu:createWithItem(btn_soul)
    btn_soul_menu:setPosition(CCPoint(0, 0))
    board:addChild(btn_soul_menu)

    coin_info:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer:addChild((require"ui.help").create(i18n.global.dare_coin_help.string), 1000)
    end)
    exp_info:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer:addChild((require"ui.help").create(i18n.global.dare_exp_help.string), 1000)
    end)
    soul_info:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer:addChild((require"ui.help").create(i18n.global.dare_soul_help.string), 1000)
    end)

    btn_coin:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer:addChild((require"ui.dare.stage").create({_anim=true, type=daredata.Type.COIN}), 1000)
    end)
    btn_exp:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer:addChild((require"ui.dare.stage").create({_anim=true, type=daredata.Type.EXP}), 1000)
    end)
    btn_soul:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer:addChild((require"ui.dare.stage").create({_anim=true, type=daredata.Type.SOUL}), 1000)
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

    if uiParams and uiParams.from_layer == "dareStage" then
        layer:runAction(CCCallFunc:create(function()
            layer:addChild((require"ui.dare.stage").create({_anim=true, type=uiParams.type}), 1000)
        end))
    end

    return layer
end

return ui
