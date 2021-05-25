-- 单挑赛排名界面

local ui = {}

require "common.func"
local view      = require "common.view"
local img       = require "res.img"
local lbl       = require "res.lbl"
local json      = require "res.json"
local i18n      = require "res.i18n"
local audio     = require "res.audio"
local netClient = require "net.netClient"
local heros     = require "data.heros"
local bag       = require "data.bag"
local player    = require "data.player"


local icon_rank = {
    [1] = img.ui.arena_rank_1,
    [2] = img.ui.arena_rank_2,
    [3] = img.ui.arena_rank_3,
}

function ui.create(pramas)
	ui.widget = {}
	ui.data = {}

    ui.data.myWave = pramas.wave
    ui.data.myTime = pramas.time
	ui.data.myRank = pramas.rank
	ui.data.rankList = pramas.mbr or {}

	ui.widget.rankList = {}

	ui.widget.layer = CCLayer:create()
	ui.widget.layer:setTouchEnabled(true)
	-- 暗色层
	ui.widget.darkLayer = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    ui.widget.layer:addChild(ui.widget.darkLayer)
	-- 主背景
	ui.widget.bg = img.createUI9Sprite(img.ui.dialog_1)
    ui.widget.bg:setPreferredSize(CCSizeMake(662, 514))
    ui.widget.bg:setScale(view.minScale)
    ui.widget.bg:setPosition(view.midX, view.midY)
    ui.widget.layer:addChild(ui.widget.bg)
    local bg_w = ui.widget.bg:getContentSize().width
    local bg_h = ui.widget.bg:getContentSize().height
    -- 标题
    ui.widget.title = lbl.createFont1(24, i18n.global.hook_pverank_title.string, ccc3(0xe6, 0xd0, 0xae))
    ui.widget.title:setPosition(CCPoint(bg_w/2, bg_h-29))
    ui.widget.bg:addChild(ui.widget.title, 2)
    ui.widget.shadow = lbl.createFont1(24, i18n.global.hook_pverank_title.string, ccc3(0x59, 0x30, 0x1b))
    ui.widget.shadow:setPosition(CCPoint(bg_w/2, bg_h-31))
    ui.widget.bg:addChild(ui.widget.shadow)
    -- 底框
    ui.widget.board = img.createUI9Sprite(img.ui.inner_bg)
    ui.widget.board:setPreferredSize(CCSizeMake(604, 413))
    ui.widget.board:setAnchorPoint(CCPoint(0.5, 0))
    ui.widget.board:setPosition(CCPoint(bg_w/2, 38))
    ui.widget.bg:addChild(ui.widget.board)
    local board_w = ui.widget.board:getContentSize().width
    local board_h = ui.widget.board:getContentSize().height
    -- 关闭按钮
    local closeImg = img.createUISprite(img.ui.close)
    ui.widget.closeBtn = SpineMenuItem:create(json.ui.button, closeImg)
    ui.widget.closeBtn:setPosition(CCPoint(bg_w-25, bg_h-28))
    local closeMenu = CCMenu:createWithItem(ui.widget.closeBtn)
    closeMenu:setPosition(CCPoint(0, 0))
    ui.widget.bg:addChild(closeMenu, 100)
    -- 滚动容器
    local scroll_params = {
        width = 604,
        height = 380,
    }
    ui.widget.scroll = require("ui.lineScroll").create(scroll_params)
    ui.widget.scroll:setAnchorPoint(CCPoint(0, 0))
    ui.widget.scroll:setPosition(CCPoint(0, 20))
    ui.widget.scroll.addSpace(4)
    ui.widget.board:addChild(ui.widget.scroll)
    -- 添加所有的排行
    ui.addItems()
    -- 添加我的排行
    ui.widget.myItem = ui.createMyItem()
    if ui.widget.myItem ~= nil then
        ui.widget.myItem:setPosition(board_w/2, 36)
        ui.widget.board:addChild(ui.widget.myItem,3)
    end
    -- 入场动作
    ui.widget.bg:setScale(0.5*view.minScale)
    ui.widget.bg:runAction(CCScaleTo:create(0.15, 1*view.minScale, 1*view.minScale))

    ui.callBack()
    
	return ui.widget.layer
end

-- 回调
function ui.callBack()
	-- 返回按钮
	ui.widget.closeBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        ui.widget.layer:removeFromParent()
    end)

	-- 层事件
	ui.widget.layer:registerScriptHandler(function(event)
        if event == "enter" then
            ui.onEnter()
        elseif event == "exit" then
            ui.onExit()
        end
    end)
    -- 返回
    ui.widget.layer.onAndroidBack = function ()
        audio.play(audio.button)
        ui.widget.layer:removeFromParent()
    end
    addBackEvent(ui.widget.layer)
end

function ui.onEnter()
    print("onEnter")
    ui.widget.layer.notifyParentLock()
end

function ui.onExit()
    print("onExit")
	ui.widget.layer.notifyParentUnlock()
end

-- 创建子项
function ui.createItem(data,idx)
	-- 背景
	local item = img.createUI9Sprite(img.ui.botton_fram_2)
    item:setPreferredSize(CCSizeMake(577, 77))
    local item_w = item:getContentSize().width
    local item_h = item:getContentSize().height
    -- 排行
    local rank 
    if idx <= 3 then
    	rank = img.createUISprite(icon_rank[idx])
    else
    	rank = lbl.createFont1(18,""..idx, ccc3(0x51, 0x27, 0x12))
    end
    rank:setPosition(ccp(43, 39))
    item:addChild(rank)
    -- 头像
    local headIcon = img.createPlayerHead(data.logo)
    headIcon:setScale(48 / headIcon:getContentSize().width)
    headIcon:setPosition(CCPoint(103, 40))
    item:addChild(headIcon)
    -- 等级
    local lvImg = img.createUI9Sprite(img.ui.main_lv_bg)
    lvImg:setPosition(ccp(155, 39))
    item:addChild(lvImg)
    local lvLabel = lbl.createFont2(16, data.lv, lbl.whiteColor)
    lvLabel:setPosition(ccp(lvImg:getContentSize().width / 2,lvImg:getContentSize().height / 2))
    lvImg:addChild(lvLabel)
    -- 名称
    local nameLabel = lbl.createFontTTF(18, data.name, ccc3(0x51, 0x27, 0x12))
    nameLabel:setAnchorPoint(CCPoint(0, 0.5))
    nameLabel:setPosition(CCPoint(182, item_h / 2 + 12))
    item:addChild(nameLabel)
    -- 时间
    local year = os.date("%Y",data.time)
    local month = os.date("%m",data.time)
    local day = os.date("%d",data.time)
    local timeLabel = lbl.createFont1(14, year.."/"..month.."/"..day, ccc3(0x51, 0x27, 0x12))
    timeLabel:setAnchorPoint(CCPoint(0, 0.5))
    timeLabel:setPosition(CCPoint(182, 28))
    item:addChild(timeLabel)
    -- 波次
    --local waveLabel = lbl.createFont1(18, i18n.global.solo_wave_str.string, ccc3(0x7a, 0x53, 0x34))
    local levelStage = math.floor((data.wave - 1) / 100)
    local waveLabel = lbl.createFont1(18, i18n.global["solo_stage" .. levelStage].string, ccc3(0x7a, 0x53, 0x34))
    waveLabel:setPosition(CCPoint(521, 53))
    item:addChild(waveLabel)
    -- 波次数
    local waveNum = (data.wave - 1) % 100 + 1
    local waveNumLabel = lbl.createFont1(18, waveNum, ccc3(0x9c, 0x45, 0x2d))
    waveNumLabel:setPosition(CCPoint(521, 30))
    item:addChild(waveNumLabel)

    return item
end 

-- 创建我的排名项
function ui.createMyItem()
    if ui.data.myRank == nil or ui.data.myRank == 0 then
        return nil
    end

	--local data = ui.data.rankList[ui.data.myRank]
    local data = {}
    data.logo = player.logo
    data.lv = player.lv()
    data.name = player.name
    data.wave = ui.data.myWave
    data.time = ui.data.myTime
	local idx = ui.data.myRank

	-- 背景
	local item = img.createUI9Sprite(img.ui.item_yellow)
    item:setPreferredSize(CCSizeMake(606, 82))
    local item_w = item:getContentSize().width
    local item_h = item:getContentSize().height
    -- 排行
    local rank 
    if idx <= 3 then
    	rank = img.createUISprite(icon_rank[idx])
    else
    	rank = lbl.createFont1(18,""..idx, ccc3(0x51, 0x27, 0x12))
    end
    rank:setPosition(ccp(57, item_h/2))
    item:addChild(rank)
    -- 头像
    local headIcon = img.createPlayerHead(data.logo)
    headIcon:setScale(48 / headIcon:getContentSize().width)
    headIcon:setPosition(CCPoint(117, item_h/2))
    item:addChild(headIcon)
    -- 等级
    local lvImg = img.createUI9Sprite(img.ui.main_lv_bg)
    lvImg:setPosition(ccp(170, item_h / 2))
    item:addChild(lvImg)
    local lvLabel = lbl.createFont1(16, data.lv, lbl.whiteColor)
    lvLabel:setPosition(ccp(lvImg:getContentSize().width / 2,lvImg:getContentSize().height / 2))
    lvImg:addChild(lvLabel)
    -- 名称
    local nameLabel = lbl.createFontTTF(18, data.name, ccc3(0x51, 0x27, 0x12))
    nameLabel:setAnchorPoint(CCPoint(0, 0))
    nameLabel:setPosition(CCPoint(197, 43))
    item:addChild(nameLabel)
    -- 时间
    local year = os.date("%Y",data.time)
    local month = os.date("%m",data.time)
    local day = os.date("%d",data.time)
    local timeLabel = lbl.createFont1(14, year.."/"..month.."/"..day, ccc3(0x7a, 0x53, 0x34))
    timeLabel:setAnchorPoint(CCPoint(0, 0))
    timeLabel:setPosition(CCPoint(197, 20))
    item:addChild(timeLabel)
    -- 波次
    --local waveLabel = lbl.createFont1(18, i18n.global.solo_wave_str.string, ccc3(0x7a, 0x53, 0x34))
    local levelStage = math.floor((data.wave - 1) / 100)
    local waveLabel = lbl.createFont1(18, i18n.global["solo_stage" .. levelStage].string, ccc3(0x7a, 0x53, 0x34))
    waveLabel:setPosition(CCPoint(537, 53))
    item:addChild(waveLabel)
    -- 波次数
    local waveNum = (data.wave - 1) % 100 + 1
    local waveNumLabel = lbl.createFont1(18, waveNum, ccc3(0x9c, 0x45, 0x2d))
    waveNumLabel:setPosition(CCPoint(537, 30))
    item:addChild(waveNumLabel)

    return item
end

-- 添加排行项
function ui.addItems()
    if #ui.data.rankList <= 0 then
        return 
    end
    print("排行榜长度"..#ui.data.rankList)
	for i=1,#ui.data.rankList do
		ui.widget.rankList[i] = ui.createItem(ui.data.rankList[i],i)
		ui.widget.rankList[i].ax = 0.5
        ui.widget.rankList[i].px = 302
        ui.widget.scroll.addItem(ui.widget.rankList[i])
	end
    local cur_height = ui.widget.scroll.cur_height
    cur_height = cur_height + 160 > ui.widget.scroll.height and cur_height + 160 or ui.widget.scroll.height
    ui.widget.scroll.cur_height = cur_height
    ui.widget.scroll:setContentSize(CCSizeMake(ui.widget.scroll.width, cur_height))
    ui.widget.scroll.content_layer:setPosition(CCPoint(0, cur_height))
	ui.widget.scroll.setOffsetBegin()
end

return ui