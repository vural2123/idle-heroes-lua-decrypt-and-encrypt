-- 扫荡奖励弹窗

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
local cfgDrug    = require "config.spkdrug"
local particle   = require "res.particle"

-- params = {id = "",num = "",gem = ""}
function ui.create(bag,mainUI,callfunc)
    -- callfunc = function() 
    --     mainUI.initHandle()
    --     mainUI.modifyBufShow()
    --     mainUI.playSweepAnimation()
    -- end

	ui.widget = {}
	ui.data = {}
	ui.widget.items = {}
	ui.data.bag = bag
    ui.data.mainUI = mainUI
    ui.data.callfunc = callfunc

    -- 主层
    ui.widget.layer = CCLayer:create()
    ui.widget.layer:setTouchEnabled(true)
    -- 灰层
    ui.widget.darkBg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    ui.widget.layer:addChild(ui.widget.darkBg)
    -- 主背景
	ui.widget.bg = img.createUI9Sprite(img.ui.dialog_1)
	ui.widget.bg:setPreferredSize(CCSizeMake(645, 496))
    ui.widget.bg:setScale(view.minScale)
    ui.widget.bg:setPosition(view.midX, view.midY)
    ui.widget.layer:addChild(ui.widget.bg)
    local width = ui.widget.bg:getContentSize().width
    local height = ui.widget.bg:getContentSize().height
    -- 标题
    local title = i18n.global.solo_sweep.string
    ui.widget.title = lbl.createFont1(24, title, ccc3(0xe6, 0xd0, 0xae))
	ui.widget.title:setPosition(CCPoint(width/2, height-29))
	ui.widget.bg:addChild(ui.widget.title, 2)

	ui.widget.shadow = lbl.createFont1(24, title, ccc3(0x59, 0x30, 0x1b))
    ui.widget.shadow:setPosition(CCPoint(width/2, height-31))
    ui.widget.bg:addChild(ui.widget.shadow)
	-- 内部板子
	ui.widget.board = img.createUI9Sprite(img.ui.bag_btn_inner_bg)
    ui.widget.board:setPreferredSize(CCSizeMake(594, 334))
    ui.widget.board:setAnchorPoint(CCPoint(0.5, 0))
    ui.widget.board:setPosition(CCPoint(width/2, 92))
    ui.widget.bg:addChild(ui.widget.board)
    -- 滚动容器
    local ITEM_H = 80
   	local SCROLL_INTERVAL = 10
    local SCROLL_VIEW_W = 545
    local SCROLL_VIEW_H = 306
    local SCROLL_CONTENT_W = 545 
    local SCROLL_CONTENT_H = math.ceil(#bag / 6) > 3 and math.ceil(#bag / 6) * (ITEM_H + SCROLL_INTERVAL) or 306
    ui.widget.scroll = CCScrollView:create()
    ui.widget.scroll:setDirection(kCCScrollViewDirectionVertical)
    ui.widget.scroll:setViewSize(CCSize(SCROLL_VIEW_W, SCROLL_VIEW_H))
    ui.widget.scroll:setContentSize(CCSize(SCROLL_CONTENT_W, SCROLL_CONTENT_H))
    ui.widget.scroll:setAnchorPoint(CCPoint(0, 0))
    ui.widget.scroll:setPosition(CCPoint(25, 15))
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
    -- 确认按钮
    local confirmImg = img.createLogin9Sprite(img.login.button_9_small_gold)
    confirmImg:setPreferredSize(CCSizeMake(158, 54))
    local confirmLabel = lbl.createFont1(18, i18n.global.hook_drop_btn_get.string, ccc3(0x73, 0x3b, 0x05))
    confirmLabel:setPosition(CCPoint(confirmImg:getContentSize().width/2, confirmImg:getContentSize().height/2))
    confirmImg:addChild(confirmLabel)
    ui.widget.confirmBtn = SpineMenuItem:create(json.ui.button, confirmImg)
    ui.widget.confirmBtn:setPosition(CCPoint(width/2, 58))
    local confirmMenu = CCMenu:createWithItem(ui.widget.confirmBtn)
    confirmMenu:setPosition(CCPoint(0, 0))
    ui.widget.bg:addChild(confirmMenu)

    -- 粒子效果
    local particle1 = particle.create("firework1")
    particle1:setPosition(ccp(56, 40))
    ui.widget.board:addChild(particle1)
    local particle2 = particle.create("firework1")
    particle2:setPosition(ccp(560, 40))
    ui.widget.board:addChild(particle2)
    local particle3 = particle.create("firework1")
    particle3:setPosition(ccp(300, 330))
    ui.widget.board:addChild(particle3)
    -- local particle4 = particle.create("firework1")
    -- particle4:setPosition(ccp(335, 342))
    -- ui.widget.board:addChild(particle4)

    -- ui.widget.closeBtn:setVisible(false)
    -- ui.widget.confirmBtn:setVisible(false)

    ui.btnCallback()

    ui.addItems()
    --ui.playSweepAnimation()

    -- 入场动作
    ui.widget.bg:setScale(0.5*view.minScale)
    ui.widget.bg:runAction(CCScaleTo:create(0.15, 1*view.minScale, 1*view.minScale))

	return ui.widget.layer
end

-- 添加背包项
function ui.addItems()
    -- if params.goodsType == 1 then
    --     ui.widget.goodsIcon = img.createItem(params.id,params.num)
    -- else
    --     ui.widget.goodsIcon = img.createEquip(params.id,params.num)
    -- end
    -- ui.widget.goodsIcon:setPosition(ccp(ui.widget.bg:getContentSize().width / 2,220))
    -- ui.widget.bg:addChild(ui.widget.goodsIcon)

    local ITEM_H = 80
   	local SCROLL_INTERVAL = 10
   	local SCROLL_CONTENT_H = math.ceil(#ui.data.bag / 6) > 3 and math.ceil(#ui.data.bag / 6) * (ITEM_H + SCROLL_INTERVAL) or 306

    for i,v in ipairs(ui.data.bag) do
    	local item
    	if v.type == 1 then
    		item = img.createItem(v.id,v.num)
    	elseif v.type == 2 then
    		item = img.createEquip(v.id,v.num)
        elseif v.type == 3 then
            item = ui.createBufIcon(v.id,v.num)
    	end
        item:setAnchorPoint(CCPoint(0.5, 0.5))
    	table.insert(ui.widget.items,item)
    	local posX = ((i - 1) % 6 + 0.5) * (ITEM_H + SCROLL_INTERVAL) + 2
    	local posY = SCROLL_CONTENT_H - (math.floor((i - 1) / 6 + 1) - 0.5) * (ITEM_H + SCROLL_INTERVAL) - 14
    	item:setPosition(CCPoint(posX, posY))
    	item:setVisible(true)
        item:setScale(1)
    	ui.widget.scroll:addChild(item)
        item:setAnchorPoint(ccp(0.5, 0.5))
    end
end

-- 创建药水图标
function ui.createBufIcon(id,num)
    local grid = img.createUISprite(img.ui.grid)
    local size = grid:getContentSize()
    grid:setCascadeOpacityEnabled(true)
    local iconID = cfgDrug[id].iconId
    local icon
    if iconID == 4001 then
        -- 神秘牛奶
        icon = img.createUISprite(img.ui.solo_milk)
    elseif iconID == 4101 then
        -- 恶魔药剂
        icon = img.createUISprite(img.ui.solo_evil_potion)
    elseif iconID == 4201 then
        -- 天使药剂
        icon = img.createUISprite(img.ui.solo_angel_potion)
    elseif iconID == 3801 then
        -- 力量药剂
        icon = img.createUISprite(img.ui.solo_power_potion)
    elseif iconID == 3701 then
        -- 速度药剂(现改为暴伤药剂)
        icon = img.createUISprite(img.ui.solo_speed_potion)
    elseif iconID == 3901 then
        -- 暴击药剂
        icon = img.createUISprite(img.ui.solo_crit_potion)
    end
    icon:setScale(0.7)
    icon:setPosition(size.width/2, size.height/2)
    grid:addChild(icon)

    local label = lbl.createFont2(14, convertItemNum(num))
    label:setAnchorPoint(ccp(1, 0))
    label:setPosition(74, 6)
    grid:addChild(label)

    return grid
end

-- 播放扫荡动画
function ui.playSweepAnimation()
	local ITEM_H = 80
   	local SCROLL_INTERVAL = 10
	local scaleTime = 0.35
    local moveTime = 0.2
    local stopTime = 0.2
	local lines = math.ceil(#ui.data.bag / 6)
	local showLine = 1
	if lines > 3 then
		-- 移动动画
		local delay1 = CCDelayTime:create(0.15 + (scaleTime + stopTime) * 3 + moveTime * 2)
		local delay2 = CCDelayTime:create(scaleTime + moveTime + stopTime)
		local call = CCCallFunc:create(function()
			local offsetY = ui.widget.scroll:getContentOffset().y
			ui.widget.scroll:setContentOffsetInDuration(ccp(0, offsetY + ITEM_H + SCROLL_INTERVAL),moveTime)
		end)
		local seq1 = createSequence({call,delay2})
		local rep = CCRepeat:create(seq1,lines - 3)
		local seq2 = createSequence({delay1,rep})
		ui.widget.board:runAction(seq2)
	end
	-- 显示动画
    local maskLayer = CCLayer:create()
    maskLayer:setTouchEnabled(true)
    maskLayer:setContentSize(ui.widget.scroll:getViewSize())
    maskLayer:setPosition(ui.widget.scroll:getPosition())
    ui.widget.layer:addChild(maskLayer,999999)

	local delayTime = CCDelayTime:create(scaleTime + moveTime + stopTime)
	local callfunc = CCCallFunc:create(function()
		local endNum = showLine == lines and #ui.data.bag - (lines - 1) * 6 or 6
		for i=1,endNum do
			ui.widget.items[(showLine - 1) * 6 + i]:setVisible(true)
            local itemDelay = CCDelayTime:create(i * 0.05)
            local scale = CCScaleTo:create(0.1, 1, 1)
            ui.widget.items[(showLine - 1) * 6 + i]:runAction(createSequence({itemDelay,scale}))
		end 
        if showLine >= lines then
            ui.widget.closeBtn:setVisible(true)
            ui.widget.confirmBtn:setVisible(true)
            if maskLayer ~= nil then
                maskLayer:removeFromParent()
            end
            maskLayer = nil
            return
        end
		showLine = showLine + 1
	end)
    local startDelay = CCDelayTime:create(0.15)
	local sequence = createSequence({callfunc,delayTime})
	ui.widget.board:runAction(createSequence({startDelay,CCRepeat:create(sequence, lines)}))
end

function ui.btnCallback()
    local function closeTip()
        audio.play(audio.button)
        if ui.data.callfunc then
            ui.data.callfunc()
        end
        ui.widget.layer:removeFromParent()
    end
    ui.widget.closeBtn:registerScriptTapHandler(function ()
        closeTip()
    end)
    ui.widget.confirmBtn:registerScriptTapHandler(function ()
        closeTip()
    end)
    ui.widget.layer.onAndroidBack = function ()
        closeTip()
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

return ui