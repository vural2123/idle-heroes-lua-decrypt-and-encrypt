local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local i18n = require "res.i18n"
local json = require "res.json"
local audio = require "res.audio"

local droidhangComponents = require("dhcomponents.DroidhangComponents")

local teamDetail = class("teamDetail", function ()
	return cc.LayerColor:create(cc.c4b(0, 0, 0, POPUP_DARK_OPACITY))
end)

function teamDetail.create(uiParams)
	return teamDetail.new(uiParams)
end

function teamDetail:ctor(player)
	local BG_WIDTH = 680
	local BG_HEIGHT = 278

	self:setScale(view.minScale)
	self:ignoreAnchorPointForPosition(false)
	self:setAnchorPoint(cc.p(0.5, 0.5))
    self:setPosition(scalep(480, 288))

    -- bg
    local bg = img.createUI9Sprite(img.ui.bag_outer)
    bg:setPreferredSize(CCSizeMake(BG_WIDTH, BG_HEIGHT))
    bg:setAnchorPoint(0.5, 0.5)
    bg:setPosition(self:getContentSize().width * 0.5, self:getContentSize().height * 0.5)
    bg:setScale(0.1)
    bg:runAction(CCEaseBackOut:create(CCScaleTo:create(0.3, 1)))
    self:addChild(bg)
    self.bg = bg

    local innerBg = img.createUI9Sprite(img.ui.bag_btn_inner_bg)
    innerBg:setPreferredSize(CCSizeMake(634, 228))
    bg:addChild(innerBg)
    droidhangComponents:mandateNode(innerBg, "7I2p_uVsW9Y")

    -- closeBtn
    local closeBtn0 = img.createUISprite(img.ui.close)
    local closeBtn = SpineMenuItem:create(json.ui.button, closeBtn0)
    closeBtn:setPosition(BG_WIDTH-26, BG_HEIGHT-30)
    local closeMenu = CCMenu:createWithItem(closeBtn)
    closeMenu:setPosition(0, 0)
    bg:addChild(closeMenu)
    closeBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        self.onAndroidBack()
    end)

    
    addBackEvent(self)

    function self.onAndroidBack()
        self:removeFromParent()
    end

    self:registerScriptHandler(function(event)
        if event == "enter" then
            self.notifyParentLock()
        elseif event == "exit" then
            self.notifyParentUnlock()
        end
    end)

    self:setTouchEnabled(true)
    self:setTouchSwallowEnabled(true)

    --detail
    local boardTab = img.createUI9Sprite(img.ui.select_tab_tab_bg)
    boardTab:setPreferredSize(CCSizeMake(604, 38))
    innerBg:addChild(boardTab)
    droidhangComponents:mandateNode(boardTab, "UBAg_zboAjG")

    local powerBg = img.createUISprite(img.ui.select_hero_power_bg)
    powerBg:setAnchorPoint(CCPoint(0, 0.5))
    powerBg:setPosition(CCPoint(0, boardTab:getContentSize().height/2))
    boardTab:addChild(powerBg)

    local powerIcon = img.createUISprite(img.ui.power_icon)
    powerIcon:setScale(0.5)
    powerIcon:setPosition(CCPoint(30, powerBg:getContentSize().height/2))
    powerBg:addChild(powerIcon)

    local lblPower = lbl.createFont2(20, string.format("%d", player.power))
    lblPower:setAnchorPoint(CCPoint(0, 0.5))
    lblPower:setPosition(CCPoint(55, powerBg:getContentSize().height/2))
    powerBg:addChild(lblPower)

    local hids = {}
    local pheroes = player.camp or {}
    for i, v in ipairs(pheroes) do
        hids[v.pos] = v
    end

    for i=1, 6 do
        if hids[i] then
            --local showHero = img.createHeroHead(hids[i].id, hids[i].lv, true, true, hids[i].wake, nil, require("data.pet").getPetID(hids))
            local param = {
                id = hids[i].id,
                lv = hids[i].lv,
                showGroup = true,
                showStar = true,
                wake = hids[i].wake,
                orangeFx = nil,
                petID = require("data.pet").getPetID(hids),
                hskills = hids[i].hskills,
                skin = hids[i].skin,
            }
            showHero = img.createHeroHeadByParam(param)
            showHero:setAnchorPoint(ccp(0.5, 0.5))
            showHero:setScale(82 / showHero:getContentSize().width)
            innerBg:addChild(showHero)
            droidhangComponents:mandateNode(showHero, string.format("KWYr_Ppsxdg_%d", i))
        else
            local showHero = img.createUI9Sprite(img.ui.herolist_withouthero_bg)
            showHero:setPreferredSize(CCSize(82, 82))
            innerBg:addChild(showHero)
            droidhangComponents:mandateNode(showHero, string.format("KWYr_Ppsxdg_%d", i))
        end
    end

    local frontLabel = lbl.createFont1(16, i18n.global.select_hero_front.string, ccc3(0x73, 0x3b, 0x05))
    bg:addChild(frontLabel)
    droidhangComponents:mandateNode(frontLabel, "h6KW_Q4ri12")

    local behindLabel = lbl.createFont1(16, i18n.global.select_hero_behind.string, ccc3(0x73, 0x3b, 0x05))
    bg:addChild(behindLabel)
    droidhangComponents:mandateNode(behindLabel, "h6KW_dYWcHk")

    -- local tempBg = cc.Sprite:create("temp.png")
    -- tempBg:setPosition(self.bg:getContentSize().width * 0.5, self.bg:getContentSize().height * 0.5)
    -- tempBg:setOpacity(100)
    -- self.bg:addChild(tempBg, 20)
end

return teamDetail
