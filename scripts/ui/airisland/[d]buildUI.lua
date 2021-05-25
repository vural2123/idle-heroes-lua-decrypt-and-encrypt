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

-- 参数buildType 1-矿坑 2-圣台
function ui.create(buildType,pos,mainUI)
    ui.mainUI = mainUI
    ui.buildPos = pos
	ui.buildType = buildType
    ui.items = {}
    ui.selectType = nil
	-- 主层
	local layer = CCLayer:create()
    layer:setTouchEnabled(true)
	-- 暗色层
	local darkLayer = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
	layer:addChild(darkLayer)
	-- 背景板
	local board = img.createLogin9Sprite(img.login.dialog)
    board:setPreferredSize(CCSizeMake(750, 500))
    board:setScale(view.minScale)
    board:setPosition(view.midX-0*view.minScale, view.midY - 10)
    layer:addChild(board) 
    local board_w = board:getContentSize().width
    local board_h = board:getContentSize().height
    -- 标题
    local titleStr = buildType == 1 and i18n.global.airisland_mine.string or i18n.global.airisland_holy.string
    local title = lbl.createFont1(24, titleStr, ccc3(0xe6, 0xd0, 0xae))
    title:setPosition(CCPoint(board_w/2, board_h-29))
    board:addChild(title,2)

    local shadow = lbl.createFont1(24, titleStr, ccc3(0x59, 0x30, 0x1b))
    shadow:setPosition(CCPoint(board_w/2, board_h-31))
    board:addChild(shadow,1)
    -- 棕色框
    local box = img.createUI9Sprite(img.ui.inner_bg)
    box:setPreferredSize(CCSize(690, 256))
    box:setAnchorPoint(ccp(0.5, 0.5))
    box:setPosition(board:getContentSize().width/2, 290)
    board:addChild(box)
    local box_w = box:getContentSize().width
    local box_h = box:getContentSize().height
    -- 滚动容器
    local scroll = CCScrollView:create()
    scroll:setDirection(kCCScrollViewDirectionHorizontal)
    scroll:setViewSize(CCSize(box_w - 8, box_h))
    scroll:setContentSize(CCSize(box_w - 8, box_h))
    scroll:setContentOffset(ccp(0, 0))
    scroll:setPosition(4, 0)
    scroll:setTouchEnabled(false)
    box:addChild(scroll)
    -- 滚动判定层
    local scrollLayer = CCLayer:create()
    scrollLayer:setContentSize(scroll:getViewSize())
    scrollLayer:setPosition(0, 0)
    scrollLayer:setTouchEnabled(true)
    scrollLayer:setTouchSwallowEnabled(false)
    box:addChild(scrollLayer,10)

    local lastX,lastY
    local moveX,moveY
    local isClicked
    scrollLayer:registerScriptTouchHandler(function(event,x,y)
        local p = box:convertToNodeSpace(ccp(x, y))
        if event == "began" then
            if not scrollLayer:boundingBox():containsPoint(p) then
                return false
            end
            lastX,lastY = x,y
            moveX,moveY = x,y
            isClicked = false
            return true
        elseif event == "moved" then
            if math.abs(x - lastX) > 10 or math.abs(y - lastY) > 10 then
                isClicked = true
                for i,v in ipairs(ui.items) do
                    v.btn:setEnabled(false)
                end
            end
            if isClicked then
                local posX = ui.scroll:getContentOffset().x
                ui.scroll:setContentOffset(ccp(posX + (x  - moveX), 0))
            end
            moveX,moveY = x,y
        elseif event == "ended" then
            local isEnabled = true
            for i,v in ipairs(ui.items) do
                if v.btn then
                    if not v.btn:isEnabled() then
                        isEnabled = false
                    end
                    v.btn:setEnabled(true)
                end
            end
            local content_w = ui.scroll:getContentSize().width
            local view_w = ui.scroll:getViewSize().width
            local offsetX = ui.scroll:getContentOffset().x
            if isEnabled then
                return
            end
            if offsetX > 0 then
                ui.scroll:setContentOffsetInDuration(ccp(0, 0),0.2)
            elseif offsetX + content_w < view_w then
                ui.scroll:setContentOffsetInDuration(ccp(view_w - content_w, 0),0.2)
            end
        end
    end)
    -- 金币底板
    local goldBoard = img.createUI9Sprite(img.ui.guild_mill_coinbg)
    goldBoard:setPreferredSize(CCSize(196, 30))
    goldBoard:setPosition(board_w / 2 - 110, 128)
    board:addChild(goldBoard)
    local gold_w = goldBoard:getContentSize().width
    local gold_h = goldBoard:getContentSize().height
   	-- 金币图标
    local goldIcon = img.createItemIcon2(ITEM_ID_COIN)
    goldIcon:setPosition(0,gold_h / 2)
    goldBoard:addChild(goldIcon)
   	-- 金币数量
    local goldLabel = lbl.createFont2(16, num2KM(1000), lbl.whiteColor) 
    goldLabel:setPosition(gold_w / 2,gold_h / 2)
    goldBoard:addChild(goldLabel)
   	-- 钻石底板
    local gemBoard = img.createUI9Sprite(img.ui.guild_mill_coinbg)
    gemBoard:setPreferredSize(CCSize(196, 30))
    gemBoard:setPosition(board_w / 2 + 110, 128)
    board:addChild(gemBoard)
    -- 钻石图标
    local gemIcon = img.createItemIcon2(ITEM_ID_GEM)
    gemIcon:setPosition(0,gold_h / 2)
    gemBoard:addChild(gemIcon)
    -- 虚空之石图标
    local stoneIcon = img.createItemIcon2(3)
    stoneIcon:setPosition(gemIcon:getPosition())
    stoneIcon:setVisible(false)
    gemBoard:addChild(stoneIcon)
    -- 钻石数量
    local gemLabel = lbl.createFont2(16, num2KM(1000), lbl.whiteColor) 
    gemLabel:setPosition(gold_w / 2,gold_h / 2)
    gemBoard:addChild(gemLabel)
   	-- 建造按钮
    local buildImg = img.createLogin9Sprite(img.login.button_9_small_gold)
    buildImg:setPreferredSize(CCSize(204, 60))
    buildBtn = SpineMenuItem:create(json.ui.button, buildImg)
    buildBtn:setPosition(board_w / 2, 66)
    local buildMenu = CCMenu:createWithItem(buildBtn)
    buildMenu:setPosition(0, 0)
    board:addChild(buildMenu) 
    local buildLabel = lbl.createFont1(18, i18n.global.airisland_build.string, ccc3(115, 59, 5))
    buildLabel:setPosition(CCPoint(buildImg:getContentSize().width/2, buildImg:getContentSize().height/2))
    buildImg:addChild(buildLabel)
    buildBtn:registerScriptTapHandler(function ()
        -- 无可种植项
        if not ui.selectType then
            return
        end

        -- 创建矿物或者圣物
        local createType = ui.buildType == 1 and 1 or 0
        local buildID = ui.selectType * 1000 + 1
        local params = {sid = player.sid,type = createType,act = 0,id = buildID,pos = ui.buildPos}
        addWaitNet()
        print("--------create build--------")
        print("type:" .. createType .. "," .. "id:" .. buildID .. "," .. "pos:" .. ui.buildPos)
        print("buildID:" .. buildID)
        net:island_op(params, function(data)
            print("--------create Build result--------")
            delWaitNet()
            tbl2string(data)
            if data.status == 0 then
                for i,v in ipairs(airConf[buildID].need) do
                    bagdata.items.sub(v)
                end
                ui.mainUI.buildItem(ui.buildPos,ui.buildType,buildID)
                layer:removeFromParent()
            end
        end)
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

    ui.scroll = scroll
    ui.goldLabel = goldLabel
    ui.gemLabel = gemLabel
    ui.gemIcon = gemIcon
    ui.stoneIcon = stoneIcon
    ui.buildBtn = buildBtn
    ui.layer = layer

    ui.addItems()
    ui.resetScroll()
    --ui.selectItem(ui.items[1])
    for i,v in ipairs(ui.items) do
        if v.canBuild then
            ui.selectItem(ui.items[i])
            break
        end
    end

    board:setScale(0.5*view.minScale)
    board:runAction(CCScaleTo:create(0.15, 1*view.minScale, 1*view.minScale))

	return layer
end

-- 创建一个子项
function ui.createItem(resultType)
    local resultType = resultType
    local boardWidth = resultType >= 5 and 202 or 206
    local ownNum = 0
    local maxNum = 2
	-- 底板
	local board = img.createUI9Sprite(img.ui.tutorial_text_bg)
	board:setPreferredSize(CCSizeMake(boardWidth, 216))
    local boardHeight = board:getContentSize().height
    local boardBtn = SpineMenuItem:create(json.ui.button, board)
    boardBtn:setAnchorPoint(0.5, 0.5)
    boardBtn:setPosition(0, 0)
    local boardMenu =  CCMenu:createWithItem(boardBtn)
	-- 顶板
	local top = img.createUI9Sprite(img.ui.item_yellow)
	top:setPreferredSize(CCSizeMake(boardWidth + 2, boardHeight + 2))
	top:setPosition(boardWidth / 2, boardHeight / 2 - 1)
    top:setVisible(false)
	board:addChild(top)
	-- 名称
    local resultName = i18n.global["airisland_buildName_" .. resultType].string
	local nameLabel = lbl.createFont1(14, resultName, ccc3(111, 76, 56))
	nameLabel:setPosition(boardWidth / 2, 27)
	board:addChild(nameLabel)
	-- 横线
    local line_w = resultType >= 5 and 154 or 170
	local line = img.createLoginSprite(img.login.help_line)
 	line:setScaleX(line_w/line:getContentSize().width)
   	line:setPosition(boardWidth / 2, 45)
   	board:addChild(line)
	-- 图标
	-- local icon = json.create(IMG_BUILD_ID[resultType])
 --    icon:playAnimation("animation_1", -1)
 --    icon:setPosition(boardWidth / 2, 90)
 --    icon:setScale(1.2)
 --    board:addChild(icon)
    local show = airConf[resultType * 1000 + 1].show
    print("----------------"..resultType .. "," .. show)
    local icon = img.createUISprite(img.ui[IMG_BUILD_ID[resultType] .. show])
    icon:setAnchorPoint(0.5, 0)
    icon:setPosition(boardWidth / 2, 69)
    icon:setScale(0.6)
    board:addChild(icon)
    -- 次数标签
    local timesLabel = lbl.createFont1(16, "0/2", ccc3(81, 39, 18))
    timesLabel:setAnchorPoint(0, 0.5)
    timesLabel:setPosition(14, 194)
    board:addChild(timesLabel)
    -- 打勾图
    local tick = img.createUISprite(img.ui.hook_btn_sel)
    tick:setScale(0.5)
    tick:setPositionX(boardWidth - 27)
    tick:setPositionY(icon:getPositionY() - 5)
    tick:setVisible(false)
    board:addChild(tick)
	-- 帮助按钮
    local helpImg = img.createUISprite(img.ui.btn_detail)
    local helpBtn = SpineMenuItem:create(json.ui.button, helpImg)
    helpBtn:setScale(0.8)
    helpBtn:setPosition(boardWidth - 26, 189)
    local helpMenu = CCMenu:createWithItem(helpBtn)
    helpMenu:setPosition(CCPoint(0, 0))
    board:addChild(helpMenu)
    helpBtn:registerScriptTapHandler(function ()
        audio.play(audio.button)
        local propertyUI = require("ui.airisland.propertyUI").create(resultType * 1000 + 1)
        ui.layer:addChild(propertyUI,10)
    end)

    -- 判断是否已经满了
    if resultType == 5 or resultType == 6 then
        maxNum = 1
    end
    for i,v in ipairs(airData.data.holy) do
        if math.floor(v.id / 1000) == resultType then
            ownNum = ownNum + 1
        end
    end
    for i,v in ipairs(airData.data.mine) do
        if math.floor(v.id / 1000) == resultType then
            ownNum = ownNum + 1
        end
    end
    timesLabel:setString(ownNum .. "/" .. maxNum)
    if ownNum >= maxNum then
        tick:setVisible(true)
        --boardMenu:setEnabled(false)
        --boardBtn:setEnabled(false)
        --setShader(boardBtn, SHADER_GRAY, true)
    end

    -- nameLabel:setCascadeOpacityEnabled(false)
    -- line:setCascadeOpacityEnabled(false)
    -- top:setCascadeOpacityEnabled(false)
    -- timesLabel:setCascadeOpacityEnabled(false)
    -- icon:setCascadeOpacityEnabled(false)
    -- helpBtn:setCascadeOpacityEnabled(false)

    boardMenu.ownNum = ownNum
    boardMenu.maxNum = maxNum
    boardMenu.btn = boardBtn
    boardMenu.top = top
    boardMenu.resultType = resultType
    boardMenu.canBuild = ownNum < maxNum and true or false

    boardBtn:registerScriptTapHandler(function()
        if boardMenu.canBuild then
           ui.selectItem(boardMenu)
        else
           showToast(i18n.global.airisland_limit_num.string)
        end
    end)

	return boardMenu
end

-- 添加子项
function ui.addItems()
    local startX = 120
    local intervalX = 224
    local posY = 128
    if ui.buildType == 1 then
        for i=2,4 do
            local item = ui.createItem(i)
            item:setPositionX(startX + (i - 2) * intervalX)
            item:setPositionY(posY)
            ui.scroll:addChild(item)
            table.insert(ui.items,item)
        end
    else
        startX = 110
        intervalX = 210
        for i=5,9 do
            local item = ui.createItem(i)
            item:setPositionX(startX + (i - 5) * intervalX)
            item:setPositionY(posY)
            ui.scroll:addChild(item)
            table.insert(ui.items,item)
        end
    end
    -- 排序,建造到达满级的置后
    local grayItems = {}
    for i=#ui.items,1,-1 do
        if not ui.items[i].canBuild then
            table.insert(grayItems,ui.items[i])
            table.remove(ui.items,i)
        end
    end
    for i=#grayItems,1,-1 do
        table.insert(ui.items,grayItems[i])
    end
    -- 重设位置
    for i,v in ipairs(ui.items) do
        v:setPositionX(startX + (i - 1) * intervalX)
    end
end

-- 重设滚动容器内部大小
function ui.resetScroll()
    if ui.buildType == 1 then
        ui.scroll:setContentSize(CCSize(690, 256))
        ui.scroll:setContentOffset(ccp(0, 0))
    else
        ui.scroll:setContentSize(CCSize(8 * 2 + 202 * #ui.items + 8 * (#ui.items - 1), 256))
        ui.scroll:setContentOffset(ccp(0, 0))
    end
end

-- 选择子项
function ui.selectItem(item)
    ui.selectType = item.resultType
    for i,v in ipairs(ui.items) do
        if v ~= item then
            v.top:setVisible(false)
            --v:setOpacity(255)
        else
            v.top:setVisible(true)
            --v:setOpacity(0)
        end
    end
    local conf = airConf[item.resultType * 1000 + 1]
    local gold,gem,stone
    for i,v in ipairs(conf.need) do
        if v.id == 1 then
            gold = v.num
            ui.goldLabel:setString(num2KM(v.num))
        elseif v.id == 2 then
            gem = v.num
            ui.gemIcon:setVisible(true)
            ui.stoneIcon:setVisible(false)
            ui.gemLabel:setString(num2KM(v.num))
        else
            stone = v.num
            ui.gemIcon:setVisible(false)
            ui.stoneIcon:setVisible(true)
            ui.gemLabel:setString(num2KM(v.num))
        end
    end
    local canBuild = true
    if gold and bagdata.coin() < gold then
        canBuild = false
        ui.goldLabel:setColor(cc.c3b(255,44,44))
    end
    if gem and bagdata.gem() < gem then
        canBuild = false
        ui.gemLabel:setColor(cc.c3b(252,44,44))
    end
    if stone and bagdata.items.find(ITEM_ID_BUILD_STONE) < stone then
        canBuild = false
        ui.gemLabel:setColor(cc.c3b(255,44,44))
    end
    if canBuild then
        clearShader(ui.buildBtn, true)
        ui.goldLabel:setColor(lbl.whiteColor)
        ui.gemLabel:setColor(lbl.whiteColor)
    else
        setShader(ui.buildBtn, SHADER_GRAY, true)
    end
    ui.buildBtn:setEnabled(canBuild)
end

return ui
