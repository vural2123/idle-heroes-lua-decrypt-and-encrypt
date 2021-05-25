local ui = {}

require "common.func"

local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local audio = require "res.audio"
local i18n = require "res.i18n"
local player = require "data.player"

function ui.createLabel(text, fontSize, color, isMix)
	if not fontSize then fontSize = 16 end
	if not color then color = ccc3(0x73, 0x3b, 0x05) end
	if isMix then
		if not width then width = 200 end
		return lbl.createFontTTF(fontSize, text, color)
	end
	return lbl.createFont1(fontSize, text, color)
end

function ui.setButtonEnabled(btn, enabled)
	local wasEnabled = true
	if btn.customDisable then
		wasEnabled = false
	end
	if wasEnabled == enabled then return end
	
	if enabled then
		btn.customDisable = nil
		btn:setEnabled(true)
		clearShader(btn, true)
	else
		btn.customDisable = true
		setShader(btn, SHADER_GRAY, true)
        btn:setEnabled(false)
	end
end

function ui.createButton(type, text, width, height, isMix)
	-- type
	-- 0 = yellow
	-- 1 = green
	-- 2 = purple
	
	local spriteName = img.login.button_9_small_gold
	local textColor = ccc3(0x73, 0x3b, 0x05)
	if type == 1 then
		spriteName = img.login.button_9_small_green
		textColor = ccc3(0x1d, 0x67, 0x00)
	elseif type == 2 then
		spriteName = img.login.button_9_small_purple
		textColor = ccc3(0x5c, 0x19, 0x8e)
	end
	
	local btnSprite = img.createLogin9Sprite(spriteName)
    btnSprite:setPreferredSize(CCSizeMake(width or 200, height or 50))

    local btnLabel = ui.createLabel(text, 16, textColor)
    btnLabel:setPosition(CCPoint(btnSprite:getContentSize().width/2, btnSprite:getContentSize().height/2))
    btnSprite:addChild(btnLabel)

    local btn = SpineMenuItem:create(json.ui.button, btnSprite)
    local btnMenu = CCMenu:createWithItem(btn)
    btnMenu:setPosition(0,0)
    return btn, btnMenu
end

function ui.combineBag(bag)
	if not bag then return nil end
	local itemMap = {}
	local equipMap = {}
	if bag.items then
		for _, v in ipairs(bag.items) do
			itemMap[v.id] = (itemMap[v.id] or 0) + v.num
		end
	end
	if bag.equips then
		for _, v in ipairs(bag.equips) do
			equipMap[v.id] = (equipMap[v.id] or 0) + v.num
		end
	end
	
	local cbag = { items = {}, equips = {} }
	for id, num in pairs(itemMap) do
		cbag.items[#cbag.items + 1] = { id = id, num = num }
	end
	for id, num in pairs(equipMap) do
		cbag.equips[#cbag.equips + 1] = { id = id, num = num }
	end
	return cbag
end

function ui.showFloatReward(bag, items, equips)
	local cbag = { items = {}, equips = {} }
	if bag then
		if bag.items then
			for _, v in ipairs(bag.items) do
				cbag.items[#cbag.items + 1] = v
			end
		end
		if bag.equips then
			for _, v in ipairs(bag.equips) do
				cbag.equips[#cbag.equips + 1] = v
			end
		end
	end
	if items then
		for _, v in ipairs(items) do
			cbag.items[#cbag.items + 1] = v
		end
	end
	if equips then
		for _, v in ipairs(equips) do
			cbag.equips[#cbag.equips + 1] = v
		end
	end
	cbag = ui.combineBag(cbag)
	if #cbag.items > 0 or #cbag.equips > 0 then
		CCDirector:sharedDirector():getRunningScene():addChild((require "ui.reward").createFloating(cbag), 100000)
	end
end

function ui.getBagFromCfg(cfgRewards)
	if not cfgRewards then return nil end
	local bag = { items = {}, equips = {} }
	for _, v in ipairs(cfgRewards) do
		if v.type == 1 then
			bag.items[#bag.items + 1] = { id = v.id, num = v.num }
		elseif v.type == 2 then
			bag.equips[#bag.equips + 1] = { id = v.id, num = v.num }
		end
	end
	return bag
end

function ui.showFloatRewardSingle(type, id, num)
	local items = nil
	local equips = nil
	if type == 1 then
		items = { { id = id, num = num } }
	elseif type == 2 then
		equips = { { id = id, num = num } }
	end
	ui.showFloatReward(nil, items, equips)
end

function ui.createSurebuy(callback)
	local params = {}
	params.btn_count = 0
	params.body = string.format(i18n.global.blackmarket_buy_sure.string, 20)
	local board_w = 474

	local dialoglayer = require("ui.dialog").create(params) 

	local btnYesSprite = img.createLogin9Sprite(img.login.button_9_small_gold)
	btnYesSprite:setPreferredSize(CCSize(153, 50))
	local btnYes = SpineMenuItem:create(json.ui.button, btnYesSprite)
	btnYes:setPosition(board_w/2+95, 100)
	local labYes = lbl.createFont1(18, i18n.global.board_confirm_yes.string, ccc3(0x73, 0x3b, 0x05))
	labYes:setPosition(btnYes:getContentSize().width/2, btnYes:getContentSize().height/2)
	btnYesSprite:addChild(labYes)
	local menuYes = CCMenu:create()
	menuYes:setPosition(0, 0)
	menuYes:addChild(btnYes)
	dialoglayer.board:addChild(menuYes)

	local btnNoSprite = img.createLogin9Sprite(img.login.button_9_small_gold)
	btnNoSprite:setPreferredSize(CCSize(153, 50))
	local btnNo = SpineMenuItem:create(json.ui.button, btnNoSprite)
	btnNo:setPosition(board_w/2-95, 100)
	local labNo = lbl.createFont1(18, i18n.global.board_confirm_no.string, ccc3(0x73, 0x3b, 0x05))
	labNo:setPosition(btnNo:getContentSize().width/2, btnNo:getContentSize().height/2)
	btnNoSprite:addChild(labNo)
	local menuNo = CCMenu:create()
	menuNo:setPosition(0, 0)
	menuNo:addChild(btnNo)
	dialoglayer.board:addChild(menuNo)

	btnYes:registerScriptTapHandler(function()
		dialoglayer:removeFromParentAndCleanup(true)
		audio.play(audio.button)
		if callback then callback() end
	end)
	btnNo:registerScriptTapHandler(function()
		dialoglayer:removeFromParentAndCleanup(true)
		audio.play(audio.button)
	end)

	local function diabackEvent()
		dialoglayer:removeFromParentAndCleanup(true)
	end

	function dialoglayer.onAndroidBack()
		diabackEvent()
	end

	addBackEvent(dialoglayer)
	
	local function onEnter()
		dialoglayer.notifyParentLock()
	end

	local function onExit()
		dialoglayer.notifyParentUnlock()
	end

	dialoglayer:registerScriptHandler(function(event) 
		if event == "enter" then 
			onEnter()
		elseif event == "exit" then
			onExit()
		end
	end)
	return dialoglayer
end

return ui