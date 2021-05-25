local ui = {}

require "common.func"
require "common.const"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local audio = require "res.audio"
local player = require "data.player"
local i18n = require "res.i18n"
local data = require "data.chat"

function ui.create(selected, callback)
    local layer = CCLayer:create()
    local TIPS_WIDTH , TIPS_HEIGHT = 278, 250
	
	local btns = {}
	local menus = {}
	
	local channels = data.getChannels()
	for _, v in pairs(channels) do
		local btnChannelSprite = nil
		if selected == v.id then
			btnChannelSprite = img.createLogin9Sprite(img.login.button_9_small_gold)
		else
			btnChannelSprite = img.createLogin9Sprite(img.login.button_9_small_mwhite)
		end
		btnChannelSprite:setPreferredSize(CCSizeMake(230, 64))
		if data.showRedDot(v.id) then
			addRedDot(btnChannelSprite, {
				px=btnChannelSprite:getContentSize().width-5,
				py=btnChannelSprite:getContentSize().height-5,
			})
		end
		local lbl_des = lbl.createFontTTF(20, v.label, ccc3(0x73, 0x3b, 0x05)) --lbl.createMix({ font = 1, size = 20, text = v.label, width = 220, color = ccc3(0x73, 0x3b, 0x05), align = kCCTextAlignmentCenter })
		lbl_des:setPosition(CCPoint(btnChannelSprite:getContentSize().width/2, btnChannelSprite:getContentSize().height/2))
		btnChannelSprite:addChild(lbl_des)
		local btnChannel = SpineMenuItem:create(json.ui.button, btnChannelSprite)
		btns[#btns + 1] = btnChannel
		local btnChannelMenu = CCMenu:createWithItem(btnChannel)
		btnChannelMenu:setPosition(CCPoint(0, 0))
		menus[#menus + 1] = btnChannelMenu
		
		local callbackIndex = v.id
		btnChannel:registerScriptTapHandler(function()
			audio.play(audio.button)
			layer:removeFromParentAndCleanup(true)
			if callback then
				callback(callbackIndex)
			end
		end)
	end
	
	local extraHeight = 40
	local btnHeight = 80
	
	TIPS_HEIGHT = extraHeight + #btns * btnHeight
	
    local bg = img.createUI9Sprite(img.ui.tips_bg)
    bg:setPreferredSize(CCSize(TIPS_WIDTH, TIPS_HEIGHT))
    bg:setScale(view.minScale)
    bg:setPosition(scalep(553, 326))
    layer:addChild(bg)
	
	for i, v  in ipairs(btns) do
		local indexFromEnd = #btns - i
		v:setPosition(CCPoint(math.floor(TIPS_WIDTH / 2), math.floor(extraHeight / 2) + math.floor(btnHeight / 2) + btnHeight * indexFromEnd))
	end
	
	for _, v in ipairs(menus) do
		bg:addChild(v, 1)
	end

    local function backEvent()
        audio.play(audio.button)
        layer:removeFromParentAndCleanup(true)
    end

    addBackEvent(layer)
    function layer.onAndroidBack()
        backEvent()
    end
    -- touch event
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
        local p0 = layer:convertToNodeSpace(ccp(x, y))
        if not bg:boundingBox():containsPoint(p0) then
            backEvent()
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
    layer:registerScriptTouchHandler(onTouch , false , -128 , false)

    layer:setTouchEnabled(true)
    layer:setTouchSwallowEnabled(true)
    return layer
end

return ui
