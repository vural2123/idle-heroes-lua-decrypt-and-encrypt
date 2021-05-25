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
    [7] = "airisland_fast_",
    [8] = "airisland_yrant_",
    [9] = "airisland_moon_",
}

function ui.create(buildID)
	img.load(img.packedOthers.ui_airisland)
	--img.load(img.packedOthers.spine_ui_kongzhan_1)
    --img.load(img.packedOthers.spine_ui_kongzhan_2)
    --img.load(img.packedOthers.spine_ui_kongzhan_3)
    --img.load(img.packedOthers.spine_ui_kongzhan_4)

    ui.buildID = buildID
    ui.resultType = math.floor(ui.buildID / 1000)
   	-- 主层
	local layer = CCLayer:create()
    layer:setTouchEnabled(true)
	-- 暗色层
	local darkLayer = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
	layer:addChild(darkLayer)
	-- 背景板
	local board = img.createLogin9Sprite(img.login.dialog)
    board:setPreferredSize(CCSizeMake(752, 512))
    board:setScale(view.minScale)
    board:setPosition(view.midX-0*view.minScale, view.midY)
    layer:addChild(board) 
    local board_w = board:getContentSize().width
    local board_h = board:getContentSize().height
    -- 内部框
	local box = img.createUI9Sprite(img.ui.botton_fram_2)
    box:setPreferredSize(CCSizeMake(660, 226))
    box:setPosition(board_w / 2, 290)
    board:addChild(box)
    local box_w = box:getContentSize().width
    local box_h = box:getContentSize().height
    -- 标题
    local titleStr = i18n.global["solo_trader"..1].string
    local title = lbl.createFont1(24, titleStr, ccc3(0xe6, 0xd0, 0xae))
    title:setPosition(CCPoint(board_w/2, board_h-29))
    board:addChild(title,2)
    local shadow = lbl.createFont1(24, titleStr, ccc3(0x59, 0x30, 0x1b))
    shadow:setPosition(CCPoint(board_w/2, board_h-31))
    board:addChild(shadow,1)
    -- 产出标签
    local outLabel = lbl.createFont1(24, titleStr, ccc3(0xe6, 0xd0, 0xae))
    outLabel:setPosition(46, 422)
    outLabel:setAnchorPoint(0, 0.5)
    board:addChild(outLabel)
    -- 进度条底板
    local progressBg = img.createUI9Sprite(img.ui.guild_mill_coinprobg)
    progressBg:setPosition(board_w / 2, 423)
    progressBg:setPreferredSize(CCSizeMake(468, 22))
    board:addChild(progressBg)
    local progressBg_w = progressBg:getContentSize().width
    local progressBg_h = progressBg:getContentSize().height 
    -- 进度条
    local progressImg = img.createUISprite(img.ui.airisland_stockbar)
    local progressTimer = createProgressBar(progressImg)
    progressTimer:setPercentage(50)
    progressTimer:setPosition(progressBg_w / 2, progressBg_h / 2)
    progressBg:addChild(progressTimer)
    -- 进度标签
    local progressLabel = lbl.createFont1(24, titleStr, ccc3(0xe6, 0xd0, 0xae))
    progressLabel:setPosition(progressBg_w / 2, progressBg_h)
    progressBg:addChild(progressLabel)
    -- 产出图标
    local outIcon = img.createItemIcon2(ITEM_ID_COIN)
    outIcon:setPosition(0, progressBg:getContentSize().width / 2)
    progressBg:addChild(outIcon)
    -- 获取按钮
    local getImg = img.createUI9Sprite(img.ui.btn_5)
    getImg:setPreferredSize(CCSizeMake(88, 38))
    local getLabel = lbl.createFont1(16, num2KM(1000), ccc3(255, 246, 223))
    getLabel:setPosition(44, 19)
    getImg:addChild(getLabel)
    getBtn = SpineMenuItem:create(json.ui.button, getImg) 
    getBtn:setPosition(CCPoint(660, 422))
    local getMenu = CCMenu:createWithItem(getBtn)
    getMenu:setPosition(CCPoint(0, 0))
    board:addChild(getMenu,11)
    getBtn:registerScriptTapHandler(function ()
        audio.play(audio.button)
        -- 获取产出

    end)
    -- 建筑图标
   	local show = airConf[buildID].show
	local level = airConf[buildID].lv
   	-- local icon = json.create(IMG_BUILD_ID[ui.resultType])
    -- icon:playAnimation("animation_" .. show, -1)
    -- icon:setPosition(box_w / 2, 80)
    -- icon:setScale(1.2)
    -- box:addChild(icon)
    local icon = img.createUISprite(img.ui[IMG_BUILD_ID[ui.resultType] .. show])
    icon:setPosition(board_w / 2, 180)
    box:addChild(icon)
    -- 等级板
    local lvBg = img.createUISprite(img.ui.airisland_lvbg)
    lvBg:setPosition(box_w / 2, 84)
    box:addChild(lvBg)
    -- 等级标签
    local lvLabel = lbl.createFont1(16, "Lv." .. level, ccc3(255, 246, 223)) 
    lvLabel:setPosition(lvBg:getContentSize().width / 2,lvBg:getContentSize().height / 2)
    lvBg:addChild(lvLabel)
    -- 横线
    local line = img.createUI9Sprite(img.ui.split_line)
    line:setPreferredSize(CCSizeMake(560, 1))
    line:setPosition(box_w / 2,62)
    box:addChild(line)
    -- 名称
    local nameLabel = lbl.createFont1(16, "aaa", ccc3(255, 246, 223)) 
    nameLabel:setPosition(box_w / 2,34)
    box:addChild(nameLabel)
    -- 提示
    local tipLabel = lbl.createFont1(16, num2KM(1000), ccc3(255, 246, 223)) 
    tipLabel:setPosition(board_w / 2, 130)
    board:addChild(tipLabel)
    -- 帮助按钮
    local helpImg = img.createUISprite(img.ui.btn_help)
    local helpBtn = SpineMenuItem:create(json.ui.button, helpImg)
    helpBtn:setPosition(614, 188)
    local helpMenu = CCMenu:createWithItem(helpBtn)
    helpMenu:setPosition(CCPoint(0, 0))
    box:addChild(helpMenu)
    helpBtn:registerScriptTapHandler(function ()
        audio.play(audio.button)

    end)
    -- 移除按钮
    local removeImg = img.createLogin9Sprite(img.login.button_9_small_orange)
    removeImg:setPreferredSize(CCSize(164, 48))
    removeBtn = SpineMenuItem:create(json.ui.button, removeImg) 
    removeBtn:setPosition(CCPoint(board_w / 2, 56))
    local removeMenu = CCMenu:createWithItem(removeBtn)
    removeMenu:setPosition(CCPoint(0, 0))
    board:addChild(removeMenu)
    removeBtn:registerScriptTapHandler(function ()
        audio.play(audio.button)
        -- 移除建筑
    end)
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

    -- 各种情况判断
    if not airConf[buildID].give and not airConf[buildID].time then
        -- 无产出的情况
    	outLabel:setVisible(false)
    	outIcon:setVisible(false)
    	progressBg:setVisible(false)
    	getBtn:setVisible(false)
    end

    return layer
end

return ui
