local ui = {}

require "common.const"
require "common.func"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local audio = require "res.audio"
local i18n = require "res.i18n"

function ui.create()
    local layer = CCLayer:create()

    local params = {}
    
    local scale_factor = params.scale_factor or view.minScale
    -- dark bg
    local darkbg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    layer:addChild(darkbg)
    
    local board = img.createLogin9Sprite(img.login.dialog_pink)
    local board_w = 560
    local board_h = 330
    
    board:setPreferredSize(CCSize(board_w, board_h))
    board:setScale(scale_factor)
    board:setAnchorPoint(CCPoint(0.5,0.5))
    board:setPosition(CCPoint(view.physical.w/2, view.physical.h/2))
    layer:addChild(board, 100)
    layer.board = board
    
    -- board anim
    board:setScale(0.1 * scale_factor)
    board:runAction(CCEaseBackOut:create(CCScaleTo:create(0.3, scale_factor)))

    img.load("spine_ui_praise")
    local mm = json.create(json.ui.praise)
    mm:setPosition(CCPoint(0, 0))
    mm:playAnimation("animation", -1)
    board:addChild(mm)

    params.title = i18n.global.review_dlg_title.string
    -- create title
    if params.title then
        local lbl_title = lbl.createFont1(24, params.title, ccc3(0xff, 0xeb, 0x7f))
        lbl_title:setPosition(CCPoint(board_w/2, board_h-29))
        board:addChild(lbl_title,2)
        local lbl_title_shadowD = lbl.createFont1(24, params.title, ccc3(0x64, 0x01, 0x21))
        lbl_title_shadowD:setPosition(CCPoint(board_w/2, board_h-31))
        board:addChild(lbl_title_shadowD)
    end

    local body_y = 195
    local bubble = img.createUI9Sprite(img.ui.tutorial_bubble)
    bubble:setPreferredSize(CCSize(424, 115))
    bubble:setPosition(CCPoint(316, body_y))
    board:addChild(bubble)
    local bubbleArrow = img.createUISprite(img.ui.tutorial_bubble_arrow)
    bubbleArrow:setAnchorPoint(ccp(1, 0.5))
    bubbleArrow:setPosition(2, 115/2)
    bubble:addChild(bubbleArrow)

    params.body = i18n.global.review_dlg_body.string
    -- create body
    if params.body then
        local lbl_body = lbl.create({
            font = 1, size = 18, text = params.body, color = ccc3(0x78, 0x46, 0x27),
            width = 390, align = kCCTextAlignmentLeftt
        })
        lbl_body:setAnchorPoint(CCPoint(0.5, 0.5))
        lbl_body:setPosition(CCPoint(316, body_y))
        board:addChild(lbl_body)
        layer.bodyLabel = lbl_body
    end

    local btn_size = CCSize(192, 56)
    local btn_sprite_refuse = img.createLogin9Sprite(img.login.button_9_small_mwhite) 
    btn_sprite_refuse:setPreferredSize(btn_size)
    local lbl_btn_refuse = lbl.createFont1(18, i18n.global.review_dlg_refuse.string, ccc3(0x73, 0x3b, 0x05))
    lbl_btn_refuse:setPosition(CCPoint(btn_sprite_refuse:getContentSize().width/2, btn_sprite_refuse:getContentSize().height/2))
    btn_sprite_refuse:addChild(lbl_btn_refuse)
    local btn_refuse = SpineMenuItem:create(json.ui.button, btn_sprite_refuse)
    btn_refuse:setPosition(CCPoint(208, 78))
    local btn_refuse_menu = CCMenu:createWithItem(btn_refuse)
    btn_refuse_menu:setPosition(CCPoint(0, 0))
    board:addChild(btn_refuse_menu)

    local btn_sprite_goto = img.createLogin9Sprite(img.login.button_9_small_pink) 
    btn_sprite_goto:setPreferredSize(btn_size)
    local lbl_btn_goto = lbl.createFont1(18, i18n.global.review_dlg_goto.string, ccc3(0x8d, 0x02, 0x4d))
    lbl_btn_goto:setPosition(CCPoint(btn_sprite_goto:getContentSize().width/2, btn_sprite_goto:getContentSize().height/2))
    btn_sprite_goto:addChild(lbl_btn_goto)
    local btn_goto = SpineMenuItem:create(json.ui.button, btn_sprite_goto)
    btn_goto:setPosition(CCPoint(420, 78))
    local btn_goto_menu = CCMenu:createWithItem(btn_goto)
    btn_goto_menu:setPosition(CCPoint(0, 0))
    board:addChild(btn_goto_menu)

    btn_refuse:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer.onAndroidBack()
    end)

    btn_goto:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer.onAndroidBack()
        if isOnestore() then
            local URL_ONESTORE = "http://onesto.re/0000721940"
            device.openURL(URL_ONESTORE)
        elseif device.platform == "android" then
            device.openURL(URL_GOOGLE_PLAY_ANDROID)
        elseif device.platform == "ios" then
            device.openURL(URL_APP_STORE_IOS)
        else
            device.openURL(URL_APP_STORE_IOS)
        end
    end)

    function layer.onAndroidBack()
        img.unload("spine_ui_praise")
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

return ui
