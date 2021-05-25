-- 购买弹窗

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
local rewards    = require "ui.reward"

-- params = {id = "",num = "",gem = ""}
function ui.create(params,mainUI)
	ui.widget = {}
	ui.data = {}
	ui.data.params = params
    ui.data.mainUI = mainUI

	ui.widget.layer = CCLayer:create()
	ui.widget.layer:setTouchEnabled(true)
    -- 暗色层
    ui.widget.darkLayer = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    ui.widget.layer:addChild(ui.widget.darkLayer)
	-- 主背景
	ui.widget.bg = img.createUI9Sprite(img.ui.dialog_1)
	ui.widget.bg:setPreferredSize(CCSizeMake(370, 386))
    ui.widget.bg:setScale(view.minScale)
    ui.widget.bg:setPosition(view.midX, view.midY)
    ui.widget.layer:addChild(ui.widget.bg)
    local board_bg_w = ui.widget.bg:getContentSize().width
    local board_bg_h = ui.widget.bg:getContentSize().height
    -- 标题
    ui.widget.title = lbl.createFont1(24, i18n.global.chip_btn_buy.string, ccc3(0xe6, 0xd0, 0xae))
    ui.widget.title:setPosition(CCPoint(board_bg_w/2, board_bg_h-29))
    ui.widget.bg:addChild(ui.widget.title, 2)
    ui.widget.titleShadow = lbl.createFont1(24, i18n.global.chip_btn_buy.string, ccc3(0x59, 0x30, 0x1b))
    ui.widget.titleShadow:setPosition(CCPoint(board_bg_w/2, board_bg_h-31))
    ui.widget.bg:addChild(ui.widget.titleShadow)
    -- 拥有钻石UI
    ui.widget.ownGemBg = img.createUI9Sprite(img.ui.main_coin_bg)
    ui.widget.ownGemBg:setPreferredSize(CCSizeMake(174, 40))
    ui.widget.ownGemBg:setPosition(ccp(ui.widget.bg:getContentSize().width / 2, 300))
    ui.widget.bg:addChild(ui.widget.ownGemBg)

    local gemIcon
    if params.gem then
        gemIcon = img.createItemIcon2(ITEM_ID_GEM)
    elseif params.coin then
        gemIcon = img.createItemIcon2(ITEM_ID_COIN)
    end
    gemIcon:setPosition(CCPoint(5, ui.widget.ownGemBg:getContentSize().height/2+2))
    ui.widget.ownGemBg:addChild(gemIcon)
    local bagCost = params.gem and bagdata.gem() or bagdata.coin()
    ui.widget.ownLabel =lbl.createFont2(16, num2KM(bagCost), ccc3(255, 246, 223)) 
    ui.widget.ownLabel:setPosition(77, 23)
    ui.widget.ownGemBg:addChild(ui.widget.ownLabel)

    local gemPlusImg = img.createUISprite(img.ui.main_icon_plus)
    ui.widget.gemPlusBtn = HHMenuItem:create(gemPlusImg)
    ui.widget.gemPlusBtn:setPosition(ui.widget.ownGemBg:getContentSize().width-18, ui.widget.ownGemBg:getContentSize().height/2+2)
    local goldPlusMenu = CCMenu:createWithItem(ui.widget.gemPlusBtn)
    goldPlusMenu:setPosition(ccp(0, 0))
    ui.widget.ownGemBg:addChild(goldPlusMenu)
    if params.coin then
        ui.widget.gemPlusBtn:setVisible(false)
    end
    -- 钻石底板
    ui.widget.gemBg = img.createUI9Sprite(img.ui.casino_gem_bg)
    ui.widget.gemBg:setPreferredSize(CCSizeMake(220, 36))
    ui.widget.gemBg:setPosition(CCPoint(board_bg_w/2, 141))
    ui.widget.bg:addChild(ui.widget.gemBg)
    -- 钻石图标
    if params.gem then
        ui.widget.gemIcon = img.createItemIcon2(ITEM_ID_GEM)
    elseif params.coin then
        ui.widget.gemIcon = img.createItemIcon2(ITEM_ID_COIN)
    end
    ui.widget.gemIcon:setScale(0.9)
    ui.widget.gemIcon:setPosition(CCPoint(44, ui.widget.gemBg:getContentSize().height/2))
    ui.widget.gemBg:addChild(ui.widget.gemIcon)
    -- 钻石价格标签
    local cost = params.gem or params.coin
    ui.widget.gemLabel = lbl.createFont2(18, num2KM(cost))
    ui.widget.gemLabel:setPosition(CCPoint(130, ui.widget.gemBg:getContentSize().height/2))
    ui.widget.gemBg:addChild(ui.widget.gemLabel)
    -- 物品图标
    if params.goodsType == 1 then
        ui.widget.goodsIcon = img.createItem(params.id,params.num)
    else
        ui.widget.goodsIcon = img.createEquip(params.id,params.num)
    end
    ui.widget.goodsIcon:setPosition(ccp(ui.widget.bg:getContentSize().width / 2,220))
    ui.widget.bg:addChild(ui.widget.goodsIcon)
    -- 购买按钮
    local buyImg = img.createLogin9Sprite(img.login.button_9_small_gold)
    buyImg:setPreferredSize(CCSizeMake(155, 55))
    local buyLabel = lbl.createFont1(18, i18n.global.chip_btn_buy.string, ccc3(0x73, 0x3b, 0x05))
    buyLabel:setPosition(CCPoint(buyImg:getContentSize().width/2, buyImg:getContentSize().height/2))
    buyImg:addChild(buyLabel)
    ui.widget.buyBtn = SpineMenuItem:create(json.ui.button, buyImg)
    ui.widget.buyBtn:setPosition(CCPoint(board_bg_w/2, 70))
    local buyMenu = CCMenu:createWithItem(ui.widget.buyBtn)
    buyMenu:setPosition(CCPoint(0, 0))
    ui.widget.bg:addChild(buyMenu)
    -- 关闭按钮
    local closeImg = img.createUISprite(img.ui.close)
    ui.widget.closeBtn = SpineMenuItem:create(json.ui.button, closeImg) 
    ui.widget.closeBtn:setPosition(CCPoint(board_bg_w-25, board_bg_h-28))
    local closeMenu = CCMenu:createWithItem(ui.widget.closeBtn)
    closeMenu:setPosition(CCPoint(0, 0))
    ui.widget.bg:addChild(closeMenu, 100)
    -- 入场动作
    ui.widget.bg:setScale(0.5*view.minScale)
    ui.widget.bg:runAction(CCScaleTo:create(0.15, 1*view.minScale, 1*view.minScale))

    ui.btnCallback()

	return ui.widget.layer

end

function ui.btnCallback()
    -- 每帧检测数据
    local function resetLabel()
        local bagCost = ui.data.params.gem and bagdata.gem() or bagdata.coin()
        ui.widget.ownLabel:setString(num2KM(bagCost))
    end
    ui.widget.layer:scheduleUpdateWithPriorityLua(resetLabel, 0)
	-- 关闭按钮
	ui.widget.closeBtn:registerScriptTapHandler(function ()
		print("关闭")
        audio.play(audio.button)
        if ui.widget.layer then
            ui.widget.layer:removeFromParent()
            ui.widget.layer = nil
        end
	end)
	-- 购买按钮
	ui.widget.buyBtn:registerScriptTapHandler(function ()
		print("购买物品")
        audio.play(audio.button)
        if ui.data.params.gem and bagdata.gem() < ui.data.params.gem then
            showToast(i18n.global.gboss_fight_st6.string)
            return
        elseif ui.data.params.coin and bagdata.coin() < ui.data.params.coin then
            showToast(i18n.global.crystal_toast_coin.string)
            return
        end
        addWaitNet()
        local params = {sid = player.sid,id = soloData.getTrader(),count = 1,variety = 1}
        print("购买商品")
        tablePrint(params)
        net:spk_buy(params, function (data)
            delWaitNet()
            print("购买返回数据")
            tablePrint(data)
            if data.status == 0 then     
                local pbBag = {} 
                local pb = {}
                if ui.data.params.goodsType == 1 then
                    pb.id = ui.data.params.id 
                    pb.num = ui.data.params.num
                    bagdata.items.add(pb)
                    pbBag.items = {}
                    pbBag.items[1] = {}
                    pbBag.items[1].id = pb.id
                    pbBag.items[1].num = pb.num
                elseif ui.data.params.goodsType == 2 then
                    pb.id = ui.data.params.id 
                    pb.num = ui.data.params.count   
                    bagdata.equips.add(pb)
                    pbBag.equips = {}
                    pbBag.equips[1] = {}
                    pbBag.equips[1].id = pb.id
                    pbBag.equips[1].num = pb.num
                end
                if ui.data.params.gem then
                    bagdata.subGem(ui.data.params.gem)
                elseif ui.data.params.coin then
                    bagdata.subCoin(ui.data.params.coin)
                end 
                CCDirector:sharedDirector():getRunningScene():addChild(rewards.createFloating(pbBag),9999)
                ui.data.mainUI.setStage(data.nstage)
                ui.data.mainUI.endTraderSpine()
                ui.widget.layer:removeFromParent()
            end
        end)
        -- if bagdata.gem() < ui.data.params.gem then
        --     showToast(i18n.global.gboss_fight_st6.string)
        --     return
        -- end
        -- local pb = {}
        -- if ui.data.params.goodsType == 1 then
        --     pb.id = ui.data.params.id 
        --     pb.num = ui.data.params.num   
        --     bagdata.items.add(pb)
        -- elseif ui.data.params.goodsType == 2 then
        --     pb.id = ui.data.params.id 
        --     pb.num = ui.data.params.num   
        --     bagdata.equips.add(pb)
        -- end
        -- -- if ui.data.mainUI == nil then
        -- --     print("回调里面是空的")
        -- -- end
        -- ui.data.mainUI.setStage(math.random(1,403))
        -- ui.data.mainUI.endTraderSpine()
        -- ui.widget.layer:removeFromParent()
	end)
	-- 购买钻石按钮
	ui.widget.gemPlusBtn:registerScriptTapHandler(function ()
		print("购买钻石")
        audio.play(audio.button)
        local shopUI = require("ui.shop.main").create()
        ui.widget.layer:getParent():addChild(shopUI,999999)
        -- ui.widget.layer:removeFromParent()
        -- local gotoShopDlg= require "ui.gotoShopDlg"
        -- gotoShopDlg.show(ui.widget.layer:getParent(), "casino")
        -- ui.widget.layer:removeFromParent()
	end)
    -- 返回
    ui.widget.layer.onAndroidBack = function ()
        audio.play(audio.button)
        if ui.widget.layer then
            ui.widget.layer:removeFromParent()
            ui.widget.layer = nil
        end
    end
    addBackEvent(ui.widget.layer)

    -- 层事件
    ui.widget.layer:registerScriptHandler(function(event)
        if event == "enter" then
            ui.widget.layer.notifyParentLock()
        elseif event == "exit" then
            ui.widget.layer.notifyParentUnlock()
        end
    end)
end

-- 刷新拥有钻石
function ui.refreshLabel(num)
	ui.widget.ownLabel:setString(num)
end

return ui