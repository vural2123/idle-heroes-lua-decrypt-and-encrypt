-- 奖励界面

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
local soloData  = require "data.solo"

-- params = {id = "", num = ""}
function ui.create(params,mainUI)
  	ui.widget = {}
  	ui.data = {}

  	ui.data.params = params
    ui.data.mainUI = mainUI

  	ui.widget.layer = CCLayer:create()
    ui.widget.layer:setTouchEnabled(true)
	  -- 暗色层
    ui.widget.darkLayer = CCLayerColor:create(ccc4(0, 0, 0, 200))
    ui.widget.layer:addChild(ui.widget.darkLayer)
    -- 背景框
    ui.widget.bg = img.createLogin9Sprite(img.login.dialog)
    ui.widget.bg:setPreferredSize(CCSizeMake(444, 318))
    ui.widget.bg:setScale(view.minScale)
    ui.widget.bg:setPosition(view.midX, view.midY)
    ui.widget.layer:addChild(ui.widget.bg)
   	-- 标题
   	ui.widget.title =  lbl.createFont1(24, i18n.global.mail_rewards.string, ccc3(0xe6, 0xd0, 0xae))
	  ui.widget.title:setPosition(ccp(ui.widget.bg:getContentSize().width / 2,290))
	  ui.widget.bg:addChild(ui.widget.title,2)
    ui.widget.shadow = lbl.createFont1(24, i18n.global.mail_rewards.string, ccc3(0x59, 0x30, 0x1b))
    ui.widget.shadow:setPosition(CCPoint(ui.widget.bg:getContentSize().width / 2, 288))
    ui.widget.bg:addChild(ui.widget.shadow)
	  -- 物品图标
    if params.goodsType == 1 then
        ui.widget.itemIcon = img.createItem(params.id,params.num)
    else
        ui.widget.itemIcon = img.createEquip(params.id,params.num)
    end
	  ui.widget.itemIcon:setPosition(ccp(ui.widget.bg:getContentSize().width / 2, 180))
	  ui.widget.bg:addChild(ui.widget.itemIcon)
	  -- 确认按钮
    local confirmImg = img.createLogin9Sprite(img.login.button_9_small_gold)
    confirmImg:setPreferredSize(CCSizeMake(153, 52))
    local confirmLabel = lbl.createFont1(18, i18n.global.dialog_button_confirm.string, ccc3(0x73, 0x3b, 0x05))
    confirmLabel:setPosition(CCPoint(confirmImg:getContentSize().width/2, confirmImg:getContentSize().height/2))
    confirmImg:addChild(confirmLabel)
    ui.widget.confirmBtn = SpineMenuItem:create(json.ui.button, confirmImg)
    ui.widget.confirmBtn:setPosition(ccp(ui.widget.bg:getContentSize().width / 2,80))
    local confirmMenu = CCMenu:createWithItem(ui.widget.confirmBtn)
    confirmMenu:setPosition(CCPoint(0, 0))
    ui.widget.bg:addChild(confirmMenu)

   	ui.widget.confirmBtn:registerScriptTapHandler(function ()
        audio.play(audio.button)
         -- ui.data.mainUI.setStage(ui.data.mainUI.data.estage + 1)
         -- soloData.setReward(nil)

        ui.data.mainUI.refreshBoss()
     	  ui.widget.layer:removeFromParent()
   	end)

    ui.widget.layer:registerScriptTouchHandler(function (eventType, x, y)
      if eventType == "began" then
        local p = ccp(x,y)
        if ui.widget.bg:boundingBox():containsPoint(p) then
            return false
        else
            return true
        end
      elseif eventType == "ended" then
        ui.data.mainUI.refreshBoss()
        ui.widget.layer:removeFromParent()
      end
    end)

    ui.widget.layer.onAndroidBack = function ()
        audio.play(audio.button)
        ui.data.mainUI.refreshBoss()
        ui.widget.layer:removeFromParent()
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

    -- 入场动作
    ui.widget.bg:setScale(0.5*view.minScale)
    ui.widget.bg:runAction(CCScaleTo:create(0.15, 1*view.minScale, 1*view.minScale))


	return ui.widget.layer
end

return ui