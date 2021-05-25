local ui = {}

require "common.func"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local i18n = require "res.i18n"
local audio = require "res.audio"
local player = require "data.player"
local net = require "net.netClient"
local seasonrank = require "config.seasonrank"

function ui.create()
    local layer = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))

    local board = img.createLogin9Sprite(img.login.dialog)
    board:setPreferredSize(CCSize(660, 510))
    board:setScale(view.minScale)
    board:setPosition(view.midX, view.midY)
    layer:addChild(board)

    local titleRank = lbl.createFont1(26, i18n.global.trial_rank_title.string, ccc3(0xe6, 0xd0, 0xae))
    titleRank:setPosition(330, 481)
    board:addChild(titleRank, 1)
    local titleRankShade = lbl.createFont1(26, i18n.global.trial_rank_title.string, ccc3(0x59, 0x30, 0x1b))
    titleRankShade:setPosition(330, 479)
    board:addChild(titleRankShade)

    local innerBg = img.createUI9Sprite(img.ui.hero_equip_lab_frame)
    innerBg:setPreferredSize(CCSize(600, 410))
    innerBg:setPosition(330, 240)
    board:addChild(innerBg)

    local btnCloseSprite = img.createUISprite(img.ui.close)
    local btnClose = SpineMenuItem:create(json.ui.button, btnCloseSprite)
    btnClose:setPosition(636, 484)
    local menuClose = CCMenu:createWithItem(btnClose)
    menuClose:setPosition(0, 0)
    board:addChild(menuClose)
    btnClose:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer:removeFromParentAndCleanup(true)
    end)
	
    local function createRankList(ranks)
        local ranks = ranks or {}

        local Height = 82 * #ranks + 6
        local scroll = CCScrollView:create()
        scroll:setDirection(kCCScrollViewDirectionVertical)
        scroll:setAnchorPoint(ccp(0, 0))
        scroll:setPosition(0, 2)
        scroll:setViewSize(CCSize(600, 405))
        scroll:setContentSize(CCSize(600, Height))
        scroll:setContentOffset(ccp(0, 405 - Height))
        innerBg:addChild(scroll)

        for i, v in ipairs(ranks) do
            local showBg = img.createUI9Sprite(img.ui.botton_fram_2)
            showBg:setPreferredSize(CCSize(577, 77))
            showBg:setAnchorPoint(ccp(0.5, 0))
            showBg:setPosition(300, Height - 6 - i * 79)
            scroll:getContainer():addChild(showBg)

            local showName = lbl.createFontTTF(20, v["name"] or "Error", ccc3(0x51, 0x27, 0x12))
            showName:setAnchorPoint(ccp(0, 0.5))
            showName:setPosition(30, showBg:getContentSize().height/2)
            showBg:addChild(showName, 10)
			
			local btn_rank0 = img.createUISprite(img.ui.btn_rank)
			local btn_rank = SpineMenuItem:create(json.ui.button, btn_rank0)
			btn_rank:setAnchorPoint(ccp(0, 0.5))
			btn_rank:setPosition(450, showBg:getContentSize().height/2)
			--showBg:addChild(btn_rank)
			btn_rank:registerScriptTapHandler(function()
				audio.play(audio.button)
				layer:addChild((require"ui.season.scorerank").create(v), 1000)
			end)
			local btn_rank_menu = CCMenu:createWithItem(btn_rank)
			btn_rank_menu:setPosition(CCPoint(0, 0))
			showBg:addChild(btn_rank_menu, 100)
			
			local btn_drop0 = img.createUISprite(img.ui.btn_detail) --(img.ui.guildvice_icon_drop)
			local btn_drop = SpineMenuItem:create(json.ui.button, btn_drop0)
			btn_drop:setAnchorPoint(ccp(0, 0.5))
			btn_drop:setPosition(510, showBg:getContentSize().height/2)
			--showBg:addChild(btn_drop)
			btn_drop:registerScriptTapHandler(function()
				audio.play(audio.button)
				layer:addChild((require "ui.season.scorereward").create(v), 1000)
			end)
			local btn_drop_menu = CCMenu:createWithItem(btn_drop)
			btn_drop_menu:setPosition(CCPoint(0, 0))
			showBg:addChild(btn_drop_menu, 1000)
        end
    end

    addBackEvent(layer)
    function layer.onAndroidBack()
        layer:removeFromParentAndCleanup(true)
    end
    local function onEnter()
        print("onEnter")
        layer.notifyParentLock()
		createRankList(seasonrank or {})
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
	
	layer:registerScriptTouchHandler(function() return true end)
    layer:setTouchEnabled(true)

    board:setScale(0.5*view.minScale)
    local anim_arr = CCArray:create()
    anim_arr:addObject(CCScaleTo:create(0.15, 1*view.minScale, 1*view.minScale))
    anim_arr:addObject(CCDelayTime:create(0.15))
    anim_arr:addObject(CCCallFunc:create(function()
    
    end))
    board:runAction(CCSequence:create(anim_arr))


    return layer
end

return ui
