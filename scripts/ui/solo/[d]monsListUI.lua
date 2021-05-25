-- 当前挑战的boss列表的图

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

function ui.create(params)
	ui.widget = {}
	ui.data = {}

	ui.data.monsList = params
	ui.widget.monsIcons = {}

	ui.widget.layer = CCLayer:create()
    ui.widget.layer:setTouchEnabled(true)
	-- 背景
	ui.widget.bg = img.createUI9Sprite(img.ui.tips_bg)
    ui.widget.bg:setPreferredSize(CCSizeMake(460, 204))
	ui.widget.bg:setScale(view.minScale)
	ui.widget.bg:setPosition(ccp(view.midX,view.midY))
	ui.widget.layer:addChild(ui.widget.bg)
    -- 横线
    ui.widget.line = img.createUI9Sprite(img.ui.hero_tips_fgline)
    ui.widget.line:setPreferredSize(CCSize(400, 1))
    ui.widget.line:setPosition(ui.widget.bg:getContentSize().width/2, ui.widget.bg:getContentSize().height-58)
    ui.widget.bg:addChild(ui.widget.line)
	-- 标题
	ui.widget.title =  lbl.createFont1(18, i18n.global.solo_preview.string, ccc3(0xff,0xe4,0x9c))
	ui.widget.title:setPosition(ccp(ui.widget.bg:getContentSize().width / 2,170))
	ui.widget.bg:addChild(ui.widget.title)
    -- 隐藏的按钮
    local btnImg = CCSprite:create()
    btnImg:setContentSize(ui.widget.bg:getContentSize())
    ui.widget.hideBtn = SpineMenuItem:create(json.ui.button, btnImg)
    ui.widget.hideBtn:setPosition(ccp(ui.widget.bg:getContentSize().width / 2,ui.widget.bg:getContentSize().height / 2))
    local btnMenu = CCMenu:createWithItem(ui.widget.hideBtn)
    btnMenu:setPosition(0, 0)
    ui.widget.bg:addChild(btnMenu,1000)

	ui.addMonsIcon()

	ui.widget.layer:registerScriptTouchHandler(function (event,x,y)
		if event == "began" then
            if ui.widget.layer then
                ui.widget.layer:removeFromParent()
                ui.widget.layer = nil
            end			
			return true
		end
	end)

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

	return ui.widget.layer
end

function ui.createMonsIcon(monsInfo)
	-- 背景框
    local icon = img.createUISprite(img.ui.herolist_head_bg)
    icon:setCascadeOpacityEnabled(true)
    -- 人物头像
    print("该怪物头像ID"..monsInfo.id)
    local headIcon = img.createHeroHeadIcon(monsInfo.id)
    headIcon:setPosition(CCPoint(icon:getContentSize().width / 2, icon:getContentSize().height / 2))
	img.fixOfficialScale(headIcon, "hero", monsInfo.id)
    icon:addChild(headIcon)
    -- 类型背景
    local groupBg = img.createUISprite(img.ui.herolist_group_bg)
    groupBg:setScale(0.42)
    groupBg:setPosition(CCPoint(18, icon:getContentSize().height - 18))
    icon:addChild(groupBg)
    -- 类型图标
    local groupIcon = img.createUISprite(img.ui["herolist_group_" .. monsInfo.group])
    groupIcon:setPosition(groupBg:getPosition())
    groupIcon:setScale(0.42)
    icon:addChild(groupIcon)
    -- 等级标签
    local showLv = lbl.createFont2(15 * 0.92, monsInfo.lv)
    showLv:setPosition(CCPoint(67, icon:getContentSize().height - 18))
    icon:addChild(showLv)
    -- 品阶对应的星星
    local startX = 10
    local offsetX = 10
    local isRed = false
    local totalStarNum = 1
    if monsInfo.qlt <= 5 then
        totalStarNum = monsInfo.qlt
    elseif monsInfo.qlt == 6 then
        isRed = true
        if monsInfo.wake then
            totalStarNum = monsInfo.wake + 1
        end
    end
    for i=totalStarNum, 1, -1 do
        local star
        if isRed then
            star = img.createUISprite(img.ui.hero_star_orange)
            star:setScale(0.75)
        else
            star = img.createUISprite(img.ui.star_s)
        end
        star:setPositionX((i-(totalStarNum+1)/2)*12*0.8 + icon:getContentSize().width / 2)
        star:setPositionY(12)
        icon:addChild(star)
    end
    -- 血条
    -- 底框
    local box = img.createUISprite(img.ui.fight_hp_bg.small)
    box:setCascadeOpacityEnabled(true)
    box:setPosition(icon:getContentSize().width / 2, -4)
    icon:addChild(box)
    -- 进度条
    local bar = img.createUISprite(img.ui.fight_hp_fg.small)
    bar:setAnchorPoint(ccp(0, 0.5))
    bar:setPositionX(box:getContentSize().width / 2 - bar:getContentSize().width / 2)
    bar:setPositionY(box:getContentSize().height / 2)
    box:addChild(bar)

    bar:setScaleX(monsInfo.hp / 100)

    if monsInfo.hp <= 0 then
        setShader(icon, SHADER_GRAY, true)
    end

    return icon
end

-- 添加怪物图标(无论怪物数量多少,整体居中)
function ui.addMonsIcon()
    local totalNum = #ui.data.monsList
	local midX = ui.widget.bg:getContentSize().width / 2
    print("中间值为："..midX.."总数量为："..totalNum)
	local offsetX = 102
	local posY = 84
	for i,v in ipairs(ui.data.monsList) do
        if i > 4 then
            return
        end
		ui.widget.monsIcons[i] = ui.createMonsIcon(v)
		ui.widget.monsIcons[i]:setPositionX(midX + offsetX * (i - (totalNum + 1) / 2))
		ui.widget.monsIcons[i]:setPositionY(posY)
		ui.widget.bg:addChild(ui.widget.monsIcons[i])
	end
end

return ui