local ui = {}

require "common.func"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local audio = require "res.audio"
local particle = require "res.particle"
local i18n = require "res.i18n"
local net = require "net.netClient"
local player = require "data.player"
local bagdata = require "data.bag"
local cfgitem = require "config.item"
local cfgequip = require "config.equip"
local tipsitem = require "ui.tips.item"
local tipsequip = require "ui.tips.equip"
local reward = require "ui.reward"
local herosdata = require "data.heros"
local airData = require "data.airisland"
local airConf = require "config.homeworld"

local IMG_BUILD_ID = {
    -- [1] = json.ui.kongzhan_chengbao,
    -- [2] = json.ui.kongzhan_jinkuang,
    -- [3] = json.ui.kongzhan_shuijing,
    -- [4] = json.ui.kongzhan_mofachen,
    -- [5] = json.ui.kongzhan_fengshou,
    -- [6] = json.ui.kongzhan_huoli,
    -- [7] = json.ui.kongzhan_jifeng,
    -- [8] = json.ui.kongzhan_baojun,
    -- [9] = json.ui.kongzhan_xueyue,
    [1] = "airisland_maintower_",
    [2] = "airisland_gold_",
    [3] = "airisland_diamond_",
    [4] = "airisland_magic_",
    [5] = "airisland_bumper_",
    [6] = "airisland_energy_",
    [7] = "airisland_gale_",
    [8] = "airisland_tyrant_",
    [9] = "airisland_moon_",
}

function ui.create(buildID)
	img.load(img.packedOthers.ui_airisland)
	--img.load(img.packedOthers.spine_ui_kongzhan_1)
    --img.load(img.packedOthers.spine_ui_kongzhan_2)
    --img.load(img.packedOthers.spine_ui_kongzhan_3)
    --img.load(img.packedOthers.spine_ui_kongzhan_4)

    ui.items = {}
	ui.buildID = buildID
	ui.resultType = math.floor(ui.buildID / 1000)
	-- 主层
	local layer = CCLayer:create()
    layer:setTouchEnabled(true)
    -- 背景框
    local board = img.createUI9Sprite(img.ui.tips_bg)
    board:setPreferredSize(CCSizeMake(352, 280))
    board:setScale(view.minScale)
    board:setPosition(view.midX, view.midY)
    layer:addChild(board)
    board_w = board:getContentSize().width
    board_h = board:getContentSize().height
    -- 建筑图标
   	local show = airConf[buildID].show
	local level = airConf[buildID].lv
   	-- local icon = json.create(IMG_BUILD_ID[ui.resultType])
    -- icon:playAnimation("animation_" .. show, -1)
    -- icon:setPosition(board_w / 2, 180)
    -- board:addChild(icon)
    local icon = img.createUISprite(img.ui[IMG_BUILD_ID[ui.resultType] .. show])
    icon:setAnchorPoint(0.5, 0)
    icon:setPosition(board_w / 2, 140)
    icon:setScale(0.8)
    board:addChild(icon)
    -- 名称
    local resultName = i18n.global["airisland_buildName_" .. ui.resultType].string
    local nameLabel = lbl.createFont1(18, resultName, ccc3(255, 228, 156)) 
    nameLabel:setPosition(board_w / 2,127)
    board:addChild(nameLabel)
    -- 横线
    local line = img.createUI9Sprite(img.ui.hero_tips_fgline)
    line:setPreferredSize(CCSizeMake(292, 1))
    line:setPosition(board_w / 2,108)
    board:addChild(line)
    -- 关闭按钮
    local closeImg = img.createUISprite(img.ui.close)
    closeBtn = SpineMenuItem:create(json.ui.button, closeImg) 
    closeBtn:setPosition(CCPoint(board_w-25, board_h-28))
    local closeMenu = CCMenu:createWithItem(closeBtn)
    closeMenu:setPosition(CCPoint(0, 0))
    board:addChild(closeMenu,11)
    closeBtn:registerScriptTapHandler(function ()
        audio.play(audio.button)
        layer:removeFromParent()
    end)
    closeBtn:setVisible(false)

    -- 隐藏的按钮
    local btnImg = CCSprite:create()
    btnImg:setContentSize(board:getContentSize())
    local hideBtn = SpineMenuItem:create(json.ui.button, btnImg)
   	hideBtn:setPosition(ccp(board:getContentSize().width / 2,board:getContentSize().height / 2))
    local btnMenu = CCMenu:createWithItem(hideBtn)
    btnMenu:setPosition(0, 0)
    board:addChild(btnMenu,1000)

    layer:registerScriptTouchHandler(function (event,x,y)
		if event == "began" then
			layer:removeFromParent()
			return true
		end
	end)

    ui.board = board
    ui.line = line
    ui.nameLabel = nameLabel
    ui.icon = icon
    ui.addItems()

    return layer
end

-- 创建一种属性介绍
function ui.createItem(property)
	local introStr = {goldOut = "airisland_gold",gemOut = "airisland_gem", magicOut = "airisland_magic",
					  staminaOut = "airisland_stamina",capacity = "airisland_capacity", outAdd = "airisland_outadd",
					  hpAdd = "airisland_hp",spdAdd = "airisland_spd", atkAdd = "airisland_atk",
					  pit = "airisland_pit",plat = "airisland_plat",land = "airisland_island",xMax = "airisland_aplimit"}

					  -- 	local introStr = {goldOut = "airisland_gold",gemOut = "airisland_gem", magicOut = "airisland_magic",
					  -- staminaOut = "airisland_stamina",capacity = "airisland_capacity", outAdd = "airisland_outadd",
					  -- hpAdd = "airisland_hp",spdAdd = "airisland_spd", atkAdd = "airisland_atk",
					  -- pit = "airisland_stamina",plat = "airisland_stamina",land = "airisland_stamina",xMax = "airisland_aplimit"}

	local node = CCNode:create()
	node:setAnchorPoint(0.5, 0.5)
	node:setContentSize(CCSizeMake(ui.board:getContentSize().width, 28))
	local node_w = node:getContentSize().width
	local node_h = node:getContentSize().height
	-- 描述标签
    local introLabel = lbl.createFont1(16, i18n.global[introStr[property]].string .. ":", lbl.whiteColor)
    --local introLabel = lbl.createFont1(18,  "紫水水上限:", ccc3(224, 206, 177))
    introLabel:setAnchorPoint(0, 0.5)
    introLabel:setPosition(30,node_h / 2)
    node:addChild(introLabel)
	-- 数量标签
	local numLabel = lbl.createFont2(16, "0", lbl.whiteColor) 
	numLabel:setAnchorPoint(1, 0.5)
	numLabel:setPosition(322, node_h / 2)
	node:addChild(numLabel)

	if property == "goldOut" or property == "gemOut" or property == "magicOut" then
		numLabel:setString("+" .. num2KM(airConf[ui.buildID].give) .. "/" ..i18n.global.airisland_day.string)
	elseif property == "staminaOut" then
		numLabel:setString("+1" .. "/" .. math.floor(airConf[ui.buildID].time / 60) .. "m")	
	elseif property == "capacity" then
		numLabel:setString(num2KM(airConf[ui.buildID].max))
	elseif property == "outAdd" then
		numLabel:setString("+" .. airConf[ui.buildID].add .. "%")
	elseif property == "hpAdd" or property == "spdAdd" or property == "atkAdd" then
		if property == "spxAdd" then
			numLabel:setString("+" .. airConf[ui.buildID].effect[1].num)
		else
			numLabel:setString("+" .. airConf[ui.buildID].effect[1].num * 100 .. "%")
		end
	elseif property == "pit" then
		numLabel:setString(airConf[ui.buildID].pit)
	elseif property == "plat" then
		numLabel:setString(airConf[ui.buildID].plat)
	elseif property == "land" then
		numLabel:setString(airConf[ui.buildID].land)
	elseif property == "xMax" then
		numLabel:setString(airConf[ui.buildID].xMax)
	end

	node.introLabel = introLabel
	node.numLabel = numLabel
	node.intro_w = introLabel:boundingBox():getMaxX() - introLabel:boundingBox():getMinX()
	node.intro_H = introLabel:getContentSize().height
	node.num_w = numLabel:boundingBox():getMaxX() - numLabel:boundingBox():getMinX()
	node.num_h = numLabel:getContentSize().height
	node.node_w = node_w

	return node 
end

-- 添加子项
function ui.addItems()
	local centerX = ui.board:getContentSize().width / 2
	local centerY = 60
	local item_w = ui.board:getContentSize().width / 2
	local intervalY = 32
	local propertyList = {{"pit","plat","land","xMax"},
						  {"goldOut","capacity"},
						  {"gemOut","capacity"},
						  {"magicOut","capacity"},
						  {"outAdd"},
						  {"staminaOut","capacity"},
						  {"spdAdd"},
						  {"atkAdd"},
						  {"hpAdd"},
						 }
	for i,v in ipairs(propertyList[ui.resultType]) do
		local item = ui.createItem(v)
		ui.board:addChild(item)
		table.insert(ui.items,item)
	end

	-- if #ui.items == 1 then
	-- 	ui.items[1]:setPosition(centerX ,centerY)
	-- 	local total_w = ui.items[1].intro_w + ui.items[1].num_w + 12
	-- 	ui.items[1].introLabel:setAnchorPoint(0, 0.5)
	-- 	ui.items[1].numLabel:setAnchorPoint(1, 0.5)
	-- 	ui.items[1].introLabel:setPositionX(ui.items[1].node_w / 2 - total_w / 2)
	-- 	ui.items[1].numLabel:setPositionX(ui.items[1].node_w / 2 + total_w / 2)
	-- elseif #ui.items == 2 then
	-- 	for i,v in ipairs(ui.items) do
	-- 		v:setPositionX(centerX)
	-- 		v:setPositionY(centerY + (1.5 - i) * intervalY)
	-- 		local total_w = ui.items[i].intro_w + ui.items[i].num_w + 12
	-- 		ui.items[i].introLabel:setAnchorPoint(0, 0.5)
	-- 		ui.items[i].numLabel:setAnchorPoint(1, 0.5)
	-- 		ui.items[i].introLabel:setPositionX(ui.items[i].node_w / 2 - total_w / 2)
	-- 		ui.items[i].numLabel:setPositionX(ui.items[i].node_w / 2 + total_w / 2)
	-- 	end
	-- elseif #ui.items == 4 then
	-- 	for i,v in ipairs(ui.items) do
	-- 		v:setPositionX(((i + 1) % 2 + 1 - 1.5) * item_w + centerX)
	-- 		v:setPositionY((1.5 - math.floor((i - 1) / 2) - 1) * intervalY + centerY)
	-- 		if i % 2 == 0 then
	-- 			v:setPositionX(v:getPositionX() - 20)
	-- 		end
	-- 		--drawBoundingbox(v:getParent(), v)
	-- 	end
	-- end

	-- 重设坐标
	local startY = 32
	local intervalY = 28
	local intervalY1 = 18
	local intervalY2 = 10
	local intervalY3 = 130
	for i=#ui.items,1 , -1 do
		ui.items[i]:setPositionX(centerX)
		ui.items[i]:setPositionY(startY + intervalY * (#ui.items - i))
		--drawBoundingbox(ui.items[i]:getParent(), ui.items[i])
	end
	ui.line:setPositionY(ui.items[1]:getPositionY() + startY - 4)
	ui.nameLabel:setPositionY(ui.line:getPositionY() + intervalY1)
	ui.icon:setPositionY(ui.nameLabel:getPositionY() + intervalY2)
	ui.board:setPreferredSize(CCSizeMake(352, ui.icon:getPositionY() + intervalY3))
end

return ui
