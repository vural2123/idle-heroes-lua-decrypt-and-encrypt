-- 最高纪录弹窗

local ui = {}

require "common.func"
local view 		= require "common.view"
local img 		= require "res.img"
local lbl 		= require "res.lbl"
local json 		= require "res.json"
local i18n 		= require "res.i18n"
local audio 	= require "res.audio"
local netClient = require "net.netClient"
local heros 	= require "data.heros"
local bag 		= require "data.bag"
local player 	= require "data.player"

-- params = {max = "" ,now = "", cd = ""}
function ui.create(params)
	ui.widget = {}
	ui.data = {}
	ui.params = params

	ui.widget.layer = CCLayer:create()
	-- 暗色层
	ui.widget.darkLayer = CCLayerColor:create(ccc4(0, 0, 0, 200))
    ui.widget.layer:addChild(ui.widget.darkLayer)
	-- 背景
	ui.widget.bg = img.createUISprite()
	ui.widget.bg:setScale(view.minScale)
	ui.widget.bg:setPosition(scalep(100,300))
	ui.widget.layer:addChild(ui.widget.bg)
	-- 标题
	ui.widget.title =  lbl.createFont2(24, i18n.global.chip_board_title.string, lbl.whiteColor)
	ui.widget.title:setPosition(ccp(ui.widget.bg:getContentSize().width / 2,170))
	ui.widget.bg:addChild(ui.widget.title)
	-- 最高波次
	ui.widget.maxWaveLabel = lbl.createFont2(18, i18n.global.chip_board_title.string)
	ui.widget.maxWaveLabel:setAnchorPoint(ccp(0,0.5))
	ui.widget.maxWaveLabel:setPosition(ccp(10,300))
	ui.widget.bg:addChild(ui.widget.maxWaveLabel)
	-- 当前波次
	ui.widget.nowWaveLabel = lbl.createFont2(18, i18n.global.chip_board_title.string)
	ui.widget.nowWaveLabel:setAnchorPoint(ccp(0,0.5))
	ui.widget.nowWabeLabel:setPosition(ccp(ui.widget.nowWaveLabel:getPositionX(),300))
	ui.widget.bg:addChild(ui.widget.nowWaveLabel)
	-- 最高数量
	ui.widget.maxNumLabel = lbl.createFont2(18, params.max)
	ui.widget.maxNumLabel:setPosition(ccp(300,ui.widget.maxWaveLabel:getPositionY()))
	ui.widget.bg:addChild(ui.widget.maxNumLabel)
	-- 当前数量
	ui.widget.nowNumLabel = lbl.createFont2(18, params.now)
	ui.widget.nowNumLabel:setPosition(ui.widget.maxNumLabel:getPositionX(),ui.widget.nowWaveLabel:getPosition())
	ui.widget.bg:addChild(ui.widget.nowNumLabel)
	-- 时间按钮
	ui.widget.countImg = img.createLogin9Sprite(img.login.button_9_small_gold)
	ui.widget.countImg:setPreferredSize(CCSizeMake(164, 54))
	ui.widget.countImg:setPosition(ccp(ui.widget.bg:getContentSize().width / 2,100))
	ui.widget.bg:addChild(ui.widget.countImg)
	setShader(ui.widget.countImg, SHADER_GRAY, true)
	-- 倒计时
	ui.widget.countDownLabel = lbl.createFont2(20,"")
	ui.widget.countDownLabel:setPosition(ccp(ui.widget.countImg:getContentSize().width / 2,ui.widget.countImg:getContentSize().height / 2))
	ui.widget.countImg:addChild(ui.widget.countDownLabel)

	-- 返回按钮
    ui.widget.backBtn = HHMenuItem:create(img.createUISprite(img.ui.back))
    ui.widget.backBtn:setPosition(ccp(35, 576))
    local backMenu = CCMenu:createWithItem(ui.widget.backBtn)
    backMenu:setPosition(0, 0)
    ui.widget.bg:addChild(backMenu)

    ui.widget.backBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        replaceScene(require("ui.town.main").create())
    end)

    -- 返回
    ui.widget.layer.onAndroidBack = function ()
        audio.play(audio.button)
        ui.widget.layer:removeFromParent()
    end
    addBackEvent(ui.widget.layer)

	return ui.widget.layer
end

function ui.countDown()
	local delay = CCDelayTime:create(1)
	local callfunc = CCCallFunc:create(function()endend)
end

return ui