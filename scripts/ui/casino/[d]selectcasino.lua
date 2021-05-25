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
    board:setPreferredSize(CCSizeMake(596, 398))
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
    local lbl_title = lbl.createFont1(24, i18n.global.casino_main_title.string, ccc3(0xe6, 0xd0, 0xae))
    lbl_title:setPosition(CCPoint(board_w/2, board_h-29))
    board:addChild(lbl_title, 2)
    local lbl_title_shadowD = lbl.createFont1(24, i18n.global.casino_main_title.string, ccc3(0x59, 0x30, 0x1b))
    lbl_title_shadowD:setPosition(CCPoint(board_w/2, board_h-31))
    board:addChild(lbl_title_shadowD)

    local casinoSprite = img.createUISprite(img.ui.casino_common)
    local casinoBtn = SpineMenuItem:create(json.ui.button, casinoSprite)
    casinoBtn:setPosition(172, 202)
    local menucasino = CCMenu:createWithItem(casinoBtn)
    menucasino:setPosition(0, 0)
    board:addChild(menucasino, 100)
    casinoBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        if BUILD_ENTRIES_ENABLE and player.lv() < UNLOCK_CASINO_LEVEL then
            showToast(string.format(i18n.global.func_need_lv.string, UNLOCK_CASINO_LEVEL))
            return
        end
        local params = {
            sid = player.sid,
            type = 1,
        }
        addWaitNet()
        local casinodata = require"data.casino"
        casinodata.pull(params, function(__data)
            delWaitNet()
            tbl2string(__data)
            if __data.status ~= 0 then
                showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                return
            end
            casinodata.init(__data)
            replaceScene(require("ui.casino.main").create())
        end)
    end)

    local highcasinoSprite = img.createUISprite(img.ui.casino_advanced)
    local highcasinoBtn = SpineMenuItem:create(json.ui.button, highcasinoSprite)
    highcasinoBtn:setPosition(426, 202)
    local menuhighcasino = CCMenu:createWithItem(highcasinoBtn)
    menuhighcasino:setPosition(0, 0)
    board:addChild(menuhighcasino, 100)
    highcasinoBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        if BUILD_ENTRIES_ENABLE and (player.lv() < UNLOCK_ADVANCED_CASINO_LEVEL and player.vipLv() < 3) then
            showToast(string.format(i18n.global.func_need_lv.string, UNLOCK_ADVANCED_CASINO_LEVEL) .. "\n" .. string.format(i18n.global.func_need_lv_vip.string, 3))
            return
        end
        local params = {
            sid = player.sid,
            type = 1,
            up = true,
        }
        addWaitNet()
        local highcasinodata = require"data.highcasino"
        highcasinodata.pull(params, function(__data)
            delWaitNet()
            tbl2string(__data)
            if __data.status ~= 0 then
                showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                return
            end
            highcasinodata.init(__data)
            replaceScene(require("ui.highcasino.main").create())
        end)
    end)

    local lbl_casino = lbl.createFont1(20, i18n.global.casino_common.string, ccc3(0x73, 0x3b, 0x05))
    lbl_casino:setPosition(CCPoint(172, 56))
    board:addChild(lbl_casino)

    local lbl_highcasino = lbl.createFont1(20, i18n.global.casino_advanced.string, ccc3(0x73, 0x3b, 0x05))
    lbl_highcasino:setPosition(CCPoint(426, 56))
    board:addChild(lbl_highcasino)

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
