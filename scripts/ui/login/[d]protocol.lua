local ui = {}

require "common.const"
require "common.func"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local i18n = require "res.i18n"
local audio = require "res.audio"
local userdata = require "data.userdata"

function ui.create(agreeCallback,disagreeCallback)
	local layer = CCLayer:create()

	local darkBg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    layer:addChild(darkBg)

    local bg = img.createLogin9Sprite(img.login.login_home_protocol_board)
    local bg_w = bg:getContentSize().width
    local bg_h = bg:getContentSize().height

    bg:setScale(view.minScale * 0.1)
    bg:setPosition(scalep(480, 288))
    bg:runAction(CCEaseBackOut:create(CCScaleTo:create(0.3, view.minScale)))
    layer:addChild(bg)

    local linkSprite = img.createLoginSprite(img.login.login_home_protocol_link)
    
    local linkMenuItem = CCMenuItemSprite:create(linkSprite,nil)
    linkMenuItem:setPosition(bg_w/2,184)
    linkMenuItem:registerScriptTapHandler(function ()
    	device.openURL("https://www.dhgames.cn/other/ad/agreement.html")
    end)

    local linkMenu = CCMenu:createWithItem(linkMenuItem)
    linkMenu:setPosition(0,0)
    bg:addChild(linkMenu)

    -- local title = lbl.createFont2(22, i18n.global.setting_title_notice.string)
    -- lbl_title:setPosition(CCPoint(bg_w/2, bg_h-63))
    -- bg:addChild(lbl_title)

	local disagree = img.createLogin9Sprite(img.login.button_9_small_orange)
	disagree:setPreferredSize(CCSizeMake(164, 47))

	local disagreeLabel = lbl.createFont1(18, i18n.global.user_protocol_disagree.string, ccc3(0x29, 0x103, 0x0))
	disagreeLabel:setPosition(disagree:getContentSize().width/2,disagree:getContentSize().height/2)
	disagree:addChild(disagreeLabel)

    local disagreeBtn = SpineMenuItem:create(json.ui.button, disagree)
    -- disagreeBtn:setScale(view.minScale)
    disagreeBtn:setPosition(206, 60)
    disagreeBtn:registerScriptTapHandler(function()
    	audio.play(audio.button)
    	layer:removeFromParent()
    	userdata.setBool(userdata.keys.agree_user_protocol,false)

    	if disagreeCallback then
    		disagreeCallback()
    	end
    end)

	local disagreeMenu = CCMenu:createWithItem(disagreeBtn)
    disagreeMenu:setPosition(0, 0)
    bg:addChild(disagreeMenu)

    local agree = img.createLogin9Sprite(img.login.button_9_small_green)
    agree:setPreferredSize(CCSizeMake(164, 47))

	local agreeLabel = lbl.createFont1(18, i18n.global.user_protocol_agree.string, ccc3(0x115, 0x59, 0x05))
	agreeLabel:setPosition(agree:getContentSize().width/2,agree:getContentSize().height/2)
	agree:addChild(agreeLabel)

    local agreeBtn = SpineMenuItem:create(json.ui.button, agree)
    -- agreeBtn:setScale(view.minScale)
    agreeBtn:setPosition(390, 60)
    agreeBtn:registerScriptTapHandler(function()
    	audio.play(audio.button)
        layer:removeFromParent()

        userdata.setBool(userdata.keys.agree_user_protocol,true)

        if agreeCallback then
        	agreeCallback()
        end
    end)

	local agreeMenu = CCMenu:createWithItem(agreeBtn)
    agreeMenu:setPosition(0, 0)
    bg:addChild(agreeMenu)

    addBackEvent(layer)

    function layer.onAndroidBack()
        -- layer:removeFromParent()
    end

    layer:registerScriptHandler(function(event)
        if event == "enter" then
            layer.notifyParentLock()
        elseif event == "exit" then
            layer.notifyParentUnlock()
        end
    end)

    layer:setTouchEnabled(true)
    layer:setTouchSwallowEnabled(true)

    return layer

end

return ui