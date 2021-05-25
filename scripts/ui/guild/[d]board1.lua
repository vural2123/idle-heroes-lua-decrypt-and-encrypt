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

local TAB = {
    GUILD = 1,
    CREATE = 2,
    SEARCH = 3,
}
ui.TAB = TAB

function ui.create(_tab, _anim)
    local layer = CCLayer:create()
    -- dark bg
    local darkbg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    layer:addChild(darkbg)

    local bg = img.createUI9Sprite(img.ui.dialog_2)
    bg:setPreferredSize(CCSizeMake(710, 497))
    bg:setScale(view.minScale)
    bg:setPosition(CCPoint(view.midX, view.midY-0*view.minScale))
    layer:addChild(bg)
    local bg_w = bg:getContentSize().width
    local bg_h = bg:getContentSize().height

    if _anim then
        bg:setScale(0.5*view.minScale)
        local anim_arr = CCArray:create()
        anim_arr:addObject(CCScaleTo:create(0.15, 1*view.minScale, 1*view.minScale))
        -- anim
        bg:runAction(CCSequence:create(anim_arr))
    end

    local function backEvent()
        audio.play(audio.button)
        layer:removeFromParentAndCleanup(true)
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

    -- btn_guild
    local btn_guild0 = img.createLogin9Sprite(img.login.button_9_small_mwhite)
    btn_guild0:setPreferredSize(CCSizeMake(176, 48))
    local btn_guild_sel = img.createLogin9Sprite(img.login.button_9_small_gold)
    btn_guild_sel:setPreferredSize(CCSizeMake(176, 48))
    btn_guild_sel:setPosition(CCPoint(btn_guild0:getContentSize().width/2, btn_guild0:getContentSize().height/2))
    btn_guild0:addChild(btn_guild_sel)
    local lbl_guild = lbl.createFont1(18, i18n.global.guild_recommend_board_title.string, ccc3(0x73, 0x3b, 0x05))
    lbl_guild:setPosition(CCPoint(btn_guild0:getContentSize().width/2, btn_guild0:getContentSize().height/2))
    btn_guild0:addChild(lbl_guild)
    local btn_guild = SpineMenuItem:create(json.ui.button, btn_guild0)
    btn_guild:setPosition(CCPoint(168, bg_h-44))
    local btn_guild_menu = CCMenu:createWithItem(btn_guild)
    btn_guild_menu:setPosition(CCPoint(0, 0))
    bg:addChild(btn_guild_menu)

    -- btn_create
    local btn_create0 = img.createLogin9Sprite(img.login.button_9_small_mwhite)
    btn_create0:setPreferredSize(CCSizeMake(176, 48))
    local btn_create_sel = img.createLogin9Sprite(img.login.button_9_small_gold)
    btn_create_sel:setPreferredSize(CCSizeMake(176, 48))
    btn_create_sel:setPosition(CCPoint(btn_create0:getContentSize().width/2, btn_create0:getContentSize().height/2))
    btn_create0:addChild(btn_create_sel)
    local lbl_create = lbl.createFont1(18, i18n.global.guild_create_board_title.string, ccc3(0x73, 0x3b, 0x05))
    lbl_create:setPosition(CCPoint(btn_create0:getContentSize().width/2, btn_create0:getContentSize().height/2))
    btn_create0:addChild(lbl_create)
    local btn_create = SpineMenuItem:create(json.ui.button, btn_create0)
    btn_create:setPosition(CCPoint(354, bg_h-44))
    local btn_create_menu = CCMenu:createWithItem(btn_create)
    btn_create_menu:setPosition(CCPoint(0, 0))
    bg:addChild(btn_create_menu)

    -- btn_search
    local btn_search0 = img.createLogin9Sprite(img.login.button_9_small_mwhite)
    btn_search0:setPreferredSize(CCSizeMake(176, 48))
    local btn_search_sel = img.createLogin9Sprite(img.login.button_9_small_gold)
    btn_search_sel:setPreferredSize(CCSizeMake(176, 48))
    btn_search_sel:setPosition(CCPoint(btn_search0:getContentSize().width/2, btn_search0:getContentSize().height/2))
    btn_search0:addChild(btn_search_sel)
    local lbl_search = lbl.createFont1(18, i18n.global.guild_search_board_title.string, ccc3(0x73, 0x3b, 0x05))
    lbl_search:setPosition(CCPoint(btn_search0:getContentSize().width/2, btn_search0:getContentSize().height/2))
    btn_search0:addChild(lbl_search)
    local btn_search = SpineMenuItem:create(json.ui.button, btn_search0)
    btn_search:setPosition(CCPoint(540, bg_h-44))
    local btn_search_menu = CCMenu:createWithItem(btn_search)
    btn_search_menu:setPosition(CCPoint(0, 0))
    bg:addChild(btn_search_menu)

    if _tab == TAB.GUILD then
        btn_guild_sel:setVisible(true)
        btn_create_sel:setVisible(false)
        btn_search_sel:setVisible(false)
        btn_guild:setEnabled(false)
        btn_create:setEnabled(true)
        btn_search:setEnabled(true)
    elseif _tab == TAB.CREATE then
        btn_guild_sel:setVisible(false)
        btn_create_sel:setVisible(true)
        btn_search_sel:setVisible(false)
        btn_guild:setEnabled(true)
        btn_create:setEnabled(false)
        btn_search:setEnabled(true)
    elseif _tab == TAB.SEARCH then
        btn_guild_sel:setVisible(false)
        btn_create_sel:setVisible(false)
        btn_search_sel:setVisible(true)
        btn_guild:setEnabled(true)
        btn_create:setEnabled(true)
        btn_search:setEnabled(false)
    end

    local board = img.createUI9Sprite(img.ui.bag_btn_inner_bg)
    board:setPreferredSize(CCSizeMake(640, 374))
    board:setAnchorPoint(CCPoint(0.5, 0))
    board:setPosition(CCPoint(bg_w/2, 43))
    bg:addChild(board)
    layer.board = board
    local board_w = board:getContentSize().width
    local board_h = board:getContentSize().height

    btn_guild:registerScriptTapHandler(function()
        audio.play(audio.button)
        local parentObj = layer:getParent()
        layer:removeFromParentAndCleanup(true)
        parentObj:addChild((require"ui.guild.recommend").create(), 1000)
    end)
    btn_create:registerScriptTapHandler(function()
        audio.play(audio.button)
        local parentObj = layer:getParent()
        layer:removeFromParentAndCleanup(true)
        parentObj:addChild((require"ui.guild.create").create(), 1000)
    end)
    btn_search:registerScriptTapHandler(function()
        audio.play(audio.button)
        local parentObj = layer:getParent()
        layer:removeFromParentAndCleanup(true)
        parentObj:addChild((require"ui.guild.search").create(), 1000)
    end)

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
