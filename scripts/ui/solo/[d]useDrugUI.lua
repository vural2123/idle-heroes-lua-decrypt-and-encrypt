-- 单挑赛排名界面

local ui = {}

require "common.func"
local view     = require "common.view"
local img      = require "res.img"
local lbl      = require "res.lbl"
local json     = require "res.json"
local i18n     = require "res.i18n"
local audio    = require "res.audio"
local net      = require "net.netClient"
local heros    = require "data.heros"
local bag      = require "data.bag"
local player   = require "data.player"
local soloData = require "data.solo"

function ui.create(drugType,drugId,mainUI,hid)
  	ui.widget = {}
  	ui.data = {}

    print("药水"..drugType..drugId)

  	ui.data.drugType = drugType
  	ui.data.drugId = drugId
    ui.data.hid = hid
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
    local bg_w = ui.widget.bg:getContentSize().width
    local bg_h = ui.widget.bg:getContentSize().height
   	-- 标题
   	ui.widget.title = lbl.createFont1(24, i18n.global.solo_drugUse.string, ccc3(0xe6, 0xd0, 0xae))
    ui.widget.title:setPosition(ccp(ui.widget.bg:getContentSize().width / 2,290))
  	ui.widget.bg:addChild(ui.widget.title,2)
    ui.widget.titleShadow = lbl.createFont1(24, i18n.global.solo_drugUse.string, ccc3(0x59, 0x30, 0x1b))
    ui.widget.titleShadow:setPosition(CCPoint(ui.widget.bg:getContentSize().width / 2, 288))
    ui.widget.bg:addChild(ui.widget.titleShadow,1)
  	-- 物品图标
  	local itemImgStr = {speed = img.ui.solo_speed_potion, power = img.ui.solo_power_potion, crit = img.ui.solo_crit_potion,
  						          milk  = img.ui.solo_milk, angel = img.ui.solo_angel_potion,	evil = img.ui.solo_evil_potion}
  	ui.widget.itemIcon = img.createUISprite(img.ui.grid)
  	ui.widget.itemIcon:setPosition(ccp(ui.widget.bg:getContentSize().width / 2, 180))
  	ui.widget.bg:addChild(ui.widget.itemIcon)
  	local size = ui.widget.itemIcon:getContentSize()
  	ui.widget.itemContent = img.createUISprite(itemImgStr[ui.data.drugType])
  	ui.widget.itemContent:setPosition(ccp(size.width / 2,size.height / 2))
  	ui.widget.itemContent:setScale(size.width / ui.widget.itemContent:getContentSize().width)
  	ui.widget.itemIcon:addChild(ui.widget.itemContent)
  	-- 图标按钮
  	local sprite = CCSprite:create()
  	sprite:setContentSize(ui.widget.itemIcon:getContentSize())
  	ui.widget.iconBtn = SpineMenuItem:create(json.ui.button, sprite)
  	ui.widget.iconBtn:setPosition(ui.widget.itemIcon:getPosition())
  	local btnMenu = CCMenu:createWithItem(ui.widget.iconBtn)
  	btnMenu:setPosition(CCPoint(0, 0))
    ui.widget.bg:addChild(btnMenu)
  	-- 确认按钮
    local confirmImg = img.createLogin9Sprite(img.login.button_9_small_gold)
    confirmImg:setPreferredSize(CCSizeMake(153, 52))
    local confirmLabel = lbl.createFont1(18, i18n.global.herotast_use_sco.string, ccc3(0x73, 0x3b, 0x05))
    confirmLabel:setPosition(CCPoint(confirmImg:getContentSize().width/2, confirmImg:getContentSize().height/2))
    confirmImg:addChild(confirmLabel)
    ui.widget.confirmBtn = SpineMenuItem:create(json.ui.button, confirmImg)
    ui.widget.confirmBtn:setPosition(ccp(ui.widget.bg:getContentSize().width / 2,80))
    local confirmMenu = CCMenu:createWithItem(ui.widget.confirmBtn)
    confirmMenu:setPosition(CCPoint(0, 0))
    ui.widget.bg:addChild(confirmMenu)
    if drugType == "milk" or drugType == "angel" or drugType == "evil" then
        confirmLabel:setString(i18n.global.crystal_btn_save.string)
    end

   	-- 关闭按钮
    local closeImg = img.createUISprite(img.ui.close)
    ui.widget.closeBtn = SpineMenuItem:create(json.ui.button, closeImg)
    ui.widget.closeBtn:setPosition(CCPoint(bg_w-30, bg_h-30))
    local closeMenu = CCMenu:createWithItem(ui.widget.closeBtn)
    closeMenu:setPosition(CCPoint(0, 0))
    ui.widget.bg:addChild(closeMenu, 100)
    -- 入场动作
    ui.widget.bg:setScale(0.5*view.minScale)
    ui.widget.bg:runAction(CCScaleTo:create(0.15, 1*view.minScale, 1*view.minScale))

    ui.callBack()
  	return ui.widget.layer
end

function ui.callBack()
    ui.widget.confirmBtn:registerScriptTapHandler(function ()
        audio.play(audio.button)
        addWaitNet()
        local params
        if ui.data.drugType == "milk" or ui.data.drugType == "angel" or ui.data.drugType == "evil" then
            params = {sid = player.sid,buf = ui.data.drugId,save = 1}
            print("保存药水")
        else
            params = {sid = player.sid,buf = ui.data.drugId,hid = ui.data.hid}
            print("使用药水")
        end
        tablePrint(params)
        net:spk_buf(params,function (data)
            delWaitNet()
            print("药水返回数据")
            tablePrint(data)
            if data.status == 0 then
                ui.data.mainUI.setStage(data.nstage)
                if ui.data.drugType == "milk" or ui.data.drugType == "angel" or ui.data.drugType == "evil" then
                    ui.data.mainUI.savePotion()
                    ui.widget.layer:removeFromParent()
                else
                    ui.data.mainUI.usePotion()
                    ui.widget.layer:removeFromParent()
                end
            end
        end)
        -- print("玩家sid:"..player.sid.." ".."bufID:"..ui.data.drugId.." ".."英雄的hid:"..ui.data.hid)
        -- ui.data.mainUI.setStage(math.random(1,403))
        -- ui.data.mainUI.usePotion()
        -- ui.widget.layer:removeFromParent()
    end)

    ui.widget.closeBtn:registerScriptTapHandler(function ()
        audio.play(audio.button)
        ui.widget.layer:removeFromParent()
    end)

    ui.widget.iconBtn:registerScriptTapHandler(function ()
    	  print("点中了按钮")
        audio.play(audio.button)
        ui.showItemIntro()
    end)

    -- 返回
    ui.widget.layer.onAndroidBack = function ()
        audio.play(audio.button)
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
end

-- 显示药水的介绍
function ui.showItemIntro()
  	local layer = CCLayer:create()
    layer:setTouchEnabled(true)
  	ui.widget.layer:addChild(layer)
  	-- 背景图
  	local bg = img.createUI9Sprite(img.ui.tips_bg)
  	bg:setPreferredSize(CCSize(355, 248))
  	bg:setScale(view.minScale)
  	bg:setPosition(ccp(view.midX,view.midY))
  	layer:addChild(bg)
  	-- 图标
  	local itemImgStr = {speed = img.ui.solo_speed_potion, power = img.ui.solo_power_potion, crit = img.ui.solo_crit_potion,
    						         milk = img.ui.solo_milk,	angel = img.ui.solo_angel_potion, evil = img.ui.solo_evil_potion}
    local itemIcon = img.createUISprite(img.ui.grid)
    itemIcon:setScale(0.8)
    itemIcon:setAnchorPoint(ccp(0, 1))
  	itemIcon:setPositionX(21)
  	bg:addChild(itemIcon)
  	local size = ui.widget.itemIcon:getContentSize()
  	local itemContent = img.createUISprite(itemImgStr[ui.data.drugType])
  	itemContent:setPosition(ccp(size.width / 2,size.height / 2))
  	itemContent:setScale(size.width / itemContent:getContentSize().width)
  	itemIcon:addChild(itemContent)
    -- 名称标签
    local nameLabel = lbl.createMixFont1(18, i18n.spkdrug[ui.data.drugId].name, lbl.qualityColors[1])
    nameLabel:setAnchorPoint(ccp(0,1))
    nameLabel:setPositionX(21)
    bg:addChild(nameLabel)
    -- 类型标签
    local typeLabel = lbl.createMixFont1(18, i18n.spkdrug[ui.data.drugId].brief, ccc3(0xfb,0xfb,0xfb))
    typeLabel:setAnchorPoint(ccp(0,1))
    typeLabel:setPositionX(itemIcon:boundingBox():getMaxX() + 22)
    bg:addChild(typeLabel)
    -- 介绍标签
    local introLabel = lbl.createMix({font=1, size=18, width=320, 
            text=i18n.spkdrug[ui.data.drugId].explain, color=ccc3(0xfb,0xfb,0xfb), align=kCCTextAlignmentLeft})
    introLabel:setAnchorPoint(ccp(0,1))
    --introLabel:setLineBreakWithoutSpace(true)
    introLabel:setPositionX(21)
    --introLabel:setWidth(320)
    bg:addChild(introLabel)

    -- 调整底框大小,设置控件位置
    local introH = introLabel:boundingBox():getMaxY() - introLabel:boundingBox():getMinY()
    local iconH = itemIcon:boundingBox():getMaxY() - itemIcon:boundingBox():getMinY()
    local nameH = nameLabel:boundingBox():getMaxY() - nameLabel:boundingBox():getMinY()
    bg:setPreferredSize(CCSize(355,introH + 182))
    introLabel:setPositionY(introH + 34)
    itemIcon:setPositionY(introH + 121)
    typeLabel:setPositionY(introH + 117)
    nameLabel:setPositionY(introH + 156)

  	-- 隐藏按钮用于删除该层
  	local sprite = CCSprite:create()
  	sprite:setContentSize(bg:getContentSize())
  	local btn = SpineMenuItem:create(json.ui.button, sprite)
  	btn:setPosition(ccp(btn:getContentSize().width / 2,btn:getContentSize().height / 2))
  	local btnMenu = CCMenu:createWithItem(btn)
  	btnMenu:setPosition(CCPoint(0, 0))
    bg:addChild(btnMenu)

    layer:registerScriptTouchHandler(function (event,x,y)
        if event == "began" then
            return true
        elseif event == "ended" then
            layer:removeFromParent()
        end
    end)
end

return ui
