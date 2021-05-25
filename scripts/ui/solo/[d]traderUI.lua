-- 商人奖励弹窗

local ui = {}

require "common.func"
require "common.const"
local view       = require "common.view"
local img        = require "res.img"
local lbl        = require "res.lbl"
local json       = require "res.json"
local net        = require "net.netClient"
local audio      = require "res.audio"
local cfgitem    = require "config.item"
local cfgequip   = require "config.equip"
local player     = require "data.player"
local bagdata    = require "data.bag"
local casinodata = require "data.casino"
local i18n       = require "res.i18n"
local tipsequip  = require "ui.tips.equip"
local tipsitem   = require "ui.tips.item"
local NetClient  = require "net.netClient"
local netClient  = NetClient:getInstance()
local soloData   = require "data.solo"
local traderConf = require "config.spktrader"
local dialog = require "ui.dialog"
local cfgTrader = require "config.spktrader"

function ui.create(traderType)
	ui.widget = {}
	ui.data = {}
	ui.widget.items = {}
	--ui.data.idList = idList or {}
	--ui.data.idList = soloData.traderList
    ui.data.idList = {}
    for i,v in ipairs(soloData.traderList) do
        if traderConf[v].Body == traderType then
            table.insert(ui.data.idList,v)
        end
    end

	-- ui.data.bag = bag
 --    ui.data.mainUI = mainUI

    -- 主层
    local layer = CCLayer:create()
    ui.widget.layer = layer
    ui.widget.layer:setTouchEnabled(true)
    -- 灰层
    ui.widget.darkBg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    ui.widget.layer:addChild(ui.widget.darkBg)
    -- 主背景
	ui.widget.bg = img.createUI9Sprite(img.ui.dialog_1)
	ui.widget.bg:setPreferredSize(CCSizeMake(658, 508))
    ui.widget.bg:setScale(view.minScale)
    ui.widget.bg:setPosition(view.midX, view.midY)
    ui.widget.layer:addChild(ui.widget.bg)
    local width = ui.widget.bg:getContentSize().width
    local height = ui.widget.bg:getContentSize().height
    -- 标题
    local title = i18n.global["solo_trader"..traderType].string
    ui.widget.title = lbl.createFont1(24, title, ccc3(0xe6, 0xd0, 0xae))
	ui.widget.title:setPosition(CCPoint(width/2, height-29))
	ui.widget.bg:addChild(ui.widget.title, 2)

	ui.widget.shadow = lbl.createFont1(24, title, ccc3(0x59, 0x30, 0x1b))
    ui.widget.shadow:setPosition(CCPoint(width/2, height-31))
    ui.widget.bg:addChild(ui.widget.shadow)
	-- 内部板子
	ui.widget.board = img.createUI9Sprite(img.ui.bag_btn_inner_bg)
    ui.widget.board:setPreferredSize(CCSizeMake(602, 400))
    ui.widget.board:setAnchorPoint(CCPoint(0.5, 0.5))
    ui.widget.board:setPosition(CCPoint(width/2, 230))
    ui.widget.bg:addChild(ui.widget.board)
    -- 总计标签
    ui.widget.totalLabel = lbl.createFont1(18, i18n.global.solo_total.string .. ":" .. #ui.data.idList, ccc3(81, 39, 18))
    ui.widget.totalLabel:setAnchorPoint(CCPoint(0, 0.5))
    ui.widget.totalLabel:setPosition(CCPoint(24, 360))
    ui.widget.board:addChild(ui.widget.totalLabel)
    -- 拥有金币UI
    ui.widget.ownGoldBg = img.createUI9Sprite(img.ui.main_coin_bg)
    ui.widget.ownGoldBg:setPreferredSize(CCSizeMake(148, 40))
    ui.widget.ownGoldBg:setPosition(ccp(338, 360))
    ui.widget.board:addChild(ui.widget.ownGoldBg)
    local goldIcon = img.createItemIcon2(ITEM_ID_COIN)
    goldIcon:setPosition(CCPoint(5, ui.widget.ownGoldBg:getContentSize().height/2+2))
    ui.widget.ownGoldBg:addChild(goldIcon)
    local bagCost = bagdata.coin()
    local ownGoldLabel = lbl.createFont2(16, num2KM(bagCost), ccc3(255, 246, 223)) 
    ui.widget.ownGoldLabel = ownGoldLabel
    ui.widget.ownGoldLabel:setPosition(69, 23)
    ui.widget.ownGoldBg:addChild(ui.widget.ownGoldLabel)

    local goldPlusImg = img.createUISprite(img.ui.main_icon_plus)
    ui.widget.goldPlusBtn = HHMenuItem:create(goldPlusImg)
    ui.widget.goldPlusBtn:setPosition(ui.widget.ownGoldBg:getContentSize().width-18, ui.widget.ownGoldBg:getContentSize().height/2+2)
    ui.widget.goldPlusBtn:setVisible(false)
    local goldPlusMenu = CCMenu:createWithItem(ui.widget.goldPlusBtn)
    goldPlusMenu:setPosition(ccp(0, 0))
    ui.widget.ownGoldBg:addChild(goldPlusMenu)
    -- 拥有钻石UI
    ui.widget.ownGemBg = img.createUI9Sprite(img.ui.main_coin_bg)
    ui.widget.ownGemBg:setPreferredSize(CCSizeMake(148, 40))
    ui.widget.ownGemBg:setPosition(ccp(508, 360))
    ui.widget.board:addChild(ui.widget.ownGemBg)

    local gemIcon = img.createItemIcon2(ITEM_ID_GEM)
    gemIcon:setPosition(CCPoint(5, ui.widget.ownGemBg:getContentSize().height/2+2))
    ui.widget.ownGemBg:addChild(gemIcon)
    local bagCost = bagdata.gem()
    local ownLabel = lbl.createFont2(16, num2KM(bagCost), ccc3(255, 246, 223))
    ui.widget.ownLabel = ownLabel
    ui.widget.ownLabel:setPosition(68, 23)
    ui.widget.ownGemBg:addChild(ui.widget.ownLabel)

    local gemPlusImg = img.createUISprite(img.ui.main_icon_plus)
    ui.widget.gemPlusBtn = HHMenuItem:create(gemPlusImg)
    ui.widget.gemPlusBtn:setPosition(ui.widget.ownGemBg:getContentSize().width-18, ui.widget.ownGemBg:getContentSize().height/2+2)
    ui.widget.gemPlusBtn:setVisible(false)
    local gemPlusMenu = CCMenu:createWithItem(ui.widget.gemPlusBtn)
    gemPlusMenu:setPosition(ccp(0, 0))
    ui.widget.ownGemBg:addChild(gemPlusMenu)

    -- 滚动容器
    local ITEM_H = 88
   	local SCROLL_INTERVAL = 4
    local SCROLL_VIEW_W = 560
    local SCROLL_VIEW_H = 320
    local SCROLL_CONTENT_W = 560 
    local SCROLL_CONTENT_H = (ITEM_H + SCROLL_INTERVAL) * #ui.data.idList > SCROLL_VIEW_H and (ITEM_H + SCROLL_INTERVAL) * #ui.data.idList or SCROLL_VIEW_H
    ui.widget.scroll = CCScrollView:create()
    ui.widget.scroll:setDirection(kCCScrollViewDirectionVertical)
    ui.widget.scroll:setViewSize(CCSize(SCROLL_VIEW_W, SCROLL_VIEW_H))
    ui.widget.scroll:setContentSize(CCSize(SCROLL_CONTENT_W, SCROLL_CONTENT_H))
    ui.widget.scroll:setAnchorPoint(CCPoint(0, 0))
    ui.widget.scroll:setPosition(CCPoint(21, 15))
    ui.widget.scroll:setContentOffset(ccp(0, SCROLL_VIEW_H - SCROLL_CONTENT_H))
    ui.widget.board:addChild(ui.widget.scroll)
    --drawBoundingbox(ui.widget.board, ui.widget.scroll)

    -- 关闭按钮
    local closeImg = img.createUISprite(img.ui.close)
    ui.widget.closeBtn = SpineMenuItem:create(json.ui.button, closeImg) 
    ui.widget.closeBtn:setPosition(CCPoint(width-25, height-28))
    local closeMenu = CCMenu:createWithItem(ui.widget.closeBtn)
    closeMenu:setPosition(CCPoint(0, 0))
    ui.widget.bg:addChild(closeMenu, 10)
    ui.widget.closeBtn:registerScriptTapHandler(function ()
        audio.play(audio.button)
        ui.widget.layer:unscheduleUpdate()
    	ui.widget.layer:removeFromParent()
        ui.widget.layer = nil
    end)

    ui.addItems()
    -- 入场动作
    ui.widget.bg:setScale(0.5*view.minScale)
    ui.widget.bg:runAction(CCScaleTo:create(0.15, 1*view.minScale, 1*view.minScale))


    -- 每帧检测数据
    local function resetLabel()
        local gem = bagdata.gem()
        local coin = bagdata.coin()
        ownLabel:setString(num2KM(gem))
        ownGoldLabel:setString(num2KM(coin))
    end
    ui.widget.layer:scheduleUpdateWithPriorityLua(resetLabel, 0)


    ui.widget.layer.onAndroidBack = function ()
        audio.play(audio.button)
        ui.widget.layer:unscheduleUpdate()
        ui.widget.layer:removeFromParent()
        ui.widget.layer = nil
    end
    addBackEvent(ui.widget.layer)

    -- 层事件
    layer:registerScriptHandler(function(event)
        if event == "enter" then
            layer.notifyParentLock()
        elseif event == "exit" then
            layer.notifyParentUnlock()
        end
    end)

	return layer
end

function ui.createItem(id)
	local bg = img.createUI9Sprite(img.ui.bottom_border_2)
	bg:setPreferredSize(CCSizeMake(554, 88))
	bg:ignoreAnchorPointForPosition(false)
	bg:setAnchorPoint(ccp(0.5, 0.5))
	-- 图标
	local icon
	print("id ".. id)
	local reward = traderConf[id].yes[1]
	if reward.type == 1 then
		icon = img.createItem(reward.id,reward.num)
	elseif reward.type == 2 then
	    icon = img.createEquip(reward.id,reward.num)
	end
	icon:setAnchorPoint(CCPoint(0.5, 0.5))
	icon:setPosition(CCPoint(44, 44))
	icon:setScale(0.7)
	bg:addChild(icon)
	-- 购买按钮
	local buyImg = img.createLogin9Sprite(img.login.button_9_small_green)
	buyImg:setPreferredSize(CCSizeMake(155, 49))
    local buyBtn = SpineMenuItem:create(json.ui.button, buyImg)
    buyBtn:setPosition(CCPoint(456, 45))
    local buyMenu = CCMenu:createWithItem(buyBtn)
    buyMenu:setPosition(CCPoint(0, 0))
    bg:addChild(buyMenu)
	local buyLabel = lbl.createFont1(18, i18n.global.chip_btn_buy.string, ccc3(30, 99, 5))
	buyLabel:setPosition(CCPoint(90, buyImg:getContentSize().height/2))
    buyImg:addChild(buyLabel)
   	local buyIcon
   	local buyNum = lbl.createFont2(14, "0", ccc3(255, 255, 255))
   	buyNum:setPosition(CCPoint(31, 16))
   	buyImg:addChild(buyNum, 2)
   	if traderConf[id].cost then
   		buyIcon = img.createItemIcon2(ITEM_ID_GEM)
   		buyNum:setString(num2KM(traderConf[id].cost))
   	elseif traderConf[id].gold then
   		buyIcon = img.createItemIcon2(ITEM_ID_COIN)
   		buyNum:setString(num2KM(traderConf[id].gold))
   	end
   	buyIcon:setPosition(CCPoint(31,29))
   	buyIcon:setScale(0.7)
   	buyImg:addChild(buyIcon)

	bg.id = id

	buyBtn:registerScriptTapHandler(function ()
		if cfgTrader[bg.id].cost and cfgTrader[bg.id].cost > bagdata.gem() then
			showToast(i18n.global.gboss_fight_st6.string)
			return
		elseif cfgTrader[bg.id].gold and cfgTrader[bg.id].gold > bagdata.coin() then
			showToast(i18n.global.crystal_toast_coin.string)
			return 
		end
		print("购买")
        audio.play(audio.button)
		local dialog_params = {
            title = "",
            body = string.format(i18n.global.blackmarket_buy_sure.string, 2),
            btn_count = 2,
            btn_color = {
                [1] = dialog.COLOR_BLUE,
                [2] = dialog.COLOR_GOLD,
            },
            btn_text = {
                [1] = i18n.global.dialog_button_cancel.string,
                [2] = i18n.global.dialog_button_confirm.string,
            },
            selected_btn = 0,
            callback = function(__data)
            	ui.widget.layer:removeChildByTag(dialog.TAG)
	            if __data.selected_btn == 2 then
	                -- button confirm
                    addWaitNet()
                    local params = {sid = player.sid,id = bg.id,count = 1,variety = 2}
                    net:spk_buy(params, function (data)
                        delWaitNet()
                        print("购买返回数据")
                        tablePrint(data)
                        if data.status == 0 then
                            if traderConf[bg.id].cost then
                                bagdata.subGem(traderConf[bg.id].cost)
                            elseif traderConf[bg.id].gold then
                                bagdata.subCoin(traderConf[bg.id].gold)
                            end
                            local reward = cfgTrader[bg.id].yes[1]
                            if reward.type == 1 then
                                bagdata.items.add(reward)
                            elseif reward.type == 2 then
                                bagdata.equips.add(reward)
                            end
                            ui.removeItem(bg)
                        end
                    end)

	            elseif __data.selected_btn == 1 then
	                -- button Cancel
	            end
            end,
        }
        local tip = dialog.create(dialog_params)
        ui.widget.layer:addChild(tip, 1000, dialog.TAG)
	end)

	return bg
end

function ui.addItems()
	local ITEM_H = 88
   	local SCROLL_INTERVAL = 4
   	local SCROLL_H = ui.widget.scroll:getContentSize().height
	for i,v in ipairs(ui.data.idList) do
		local item = ui.createItem(v)
		item:setPositionX(ui.widget.scroll:getViewSize().width / 2)
		item:setPositionY(SCROLL_H - (i - 0.5) * (ITEM_H + SCROLL_INTERVAL))
		ui.widget.scroll:addChild(item)
		item:setAnchorPoint(ccp(0.5, 0.5))
		table.insert(ui.widget.items,item)
	end
end

function ui.removeItem(item)
	local ITEM_H = 88
   	local SCROLL_INTERVAL = 4
    local viewH = ui.widget.scroll:getViewSize().height
    local viewW = ui.widget.scroll:getViewSize().width
    local contentH = ui.widget.scroll:getContentSize().height
    local contentW = ui.widget.scroll:getContentSize().width
	local order
	-- for i,v in ipairs(ui.data.idList) do
	-- 	if v == id then
 --            ui.widget.items[i]:removeFromParent()
	-- 		table.remove(ui.widget.items, i)
 --            soloData.removeTrader(id)
	-- 		order = i
	-- 		break
	-- 	end
	-- end

    for i,v in ipairs(ui.widget.items) do
        if v == item then
            soloData.removeTrader(item.id)
            ui.widget.items[i]:removeFromParent()
            table.remove(ui.widget.items,i)
            order = i
            break
        end
    end

	-- if order and order <= #ui.widget.items then
	-- 	for i=order,#ui.widget.items do
	-- 		ui.widget.items[i]:setPositionY(ui.widget.items[i]:getPositionY() + ITEM_H + SCROLL_INTERVAL)
	-- 	end
	-- end

    -- local offset = ui.widget.scroll:getContentOffset().y
    local height = contentH - ITEM_H - SCROLL_INTERVAL
    height = height < viewH and viewH or height
    ui.widget.scroll:setContentSize(CCSize(contentW, height))
    if order <= 4 then
        ui.widget.scroll:setContentOffset(ccp(0, viewH - height))
    end
    for i,v in ipairs(ui.widget.items) do
        v:setPositionY(height - (i - 0.5) * (ITEM_H + SCROLL_INTERVAL))
    end
	ui.widget.totalLabel:setString(i18n.global.solo_total.string .. ":" .. (#ui.widget.items))
end

return ui