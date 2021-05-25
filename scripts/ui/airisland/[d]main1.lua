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
    [1] = json.ui.kongzhan_chengbao,
    [2] = json.ui.kongzhan_jinkuang,
    [3] = json.ui.kongzhan_shuijing,
    [4] = json.ui.kongzhan_mofachen,
    [5] = json.ui.kongzhan_fengshou,
    [6] = json.ui.kongzhan_huoli,
    [7] = json.ui.kongzhan_jifeng,
    [8] = json.ui.kongzhan_baojun,
    [9] = json.ui.kongzhan_xueyue,
}

function ui.create(__data)
    local data = {}
    data = airData.data

    ui.mines = {}
    ui.holys = {}
    ui.mainTower = nil
    --data.id = 1014
    --data.vit = {vit = 10,buy = 0 }
    --data.holy = {{id = 5001,pos = 1},{id = 6001,pos = 2},{id = 7001,pos = 3},{id = 8001,pos = 4}}
    --data.mine = {{id = 2001,pos = 1},{id = 3001,pos = 2},{id = 4001,pos = 3},{id = 4003,pos = 4}}
    -- local mineralPosX = {534, 485, 599, 639, 765, 704}
    -- local mineralPosY = {154.5, 89.5, 105.5, 252.5, 258.5, 297.5}
    -- local holyPosX = {384, 280, 498, 548, 385, 162, 133, 353}
    -- local holyPosY = {254, 273, 226, 365, 392, 382, 476, 489}

    ui.mineralPosX = {528, 457, 587, 639, 775, 706}
    ui.mineralPosY = {159.5, 92.5, 108.5, 252.5, 259.5, 304.5}
    ui.holyPosX = {374, 280, 468, 548, 374, 164, 137, 342}
    ui.holyPosY = {255, 274, 236, 359, 384, 364, 454, 474}

    --airData.setData(data)

    local layer = CCLayer:create()
    img.load(img.packedOthers.ui_airisland_bg)
    img.load(img.packedOthers.ui_airisland)
    --local bg = CCNode:create()
    --bg:setContentSize(CCSizeMake(view.logical.w, view.logical.h))
    --bg:setScale(view.minScale)
    --bg:setPosition(CCPoint(view.midX, view.midY))
    --layer:addChild(bg)
    local bg = img.createUISprite(img.ui.airisland_bg)
    bg:setScale(view.minScale)
    bg:setPosition(view.midX, view.midY)
    layer:addChild(bg)
    ui.bg = bg

    --img.load(img.packedOthers.spine_ui_kongzhan_1)
    --img.load(img.packedOthers.spine_ui_kongzhan_2)
    --img.load(img.packedOthers.spine_ui_kongzhan_3)
    --img.load(img.packedOthers.spine_ui_kongzhan_4)
    local animBg = json.create(json.ui.kongzhan_zhudao)
    animBg:setPosition(bg:getContentSize().width/2, bg:getContentSize().height/2)
    animBg:playAnimation("animation", -1)
    bg:addChild(animBg)

    local buildingObjs = {}
    --local lbl_buildings = {}  -- for red dot

    local aniFeiting = json.create(json.ui.kongzhan_feiting)
    aniFeiting:playAnimation("animation", -1)
    buildingObjs[1] = aniFeiting
    animBg:addChildFollowSlot("code_feiting", aniFeiting)

    local feitingLabel = lbl.createFont2(18, i18n.global.airisland_fight.string, ccc3(0xfb, 0xe6, 0x7e))
    local size = feitingLabel:boundingBox().size

    local feitingLabelBg = img.createUI9Sprite(img.ui.main_building_lbl)
    feitingLabelBg:setPreferredSize(CCSizeMake(size.width+76, 40))
    feitingLabel:setPosition(feitingLabelBg:getContentSize().width/2, feitingLabelBg:getContentSize().height/2)
    feitingLabelBg:addChild(feitingLabel)
    aniFeiting:addChildFollowSlot("code_bd", feitingLabelBg)

    local btnBackSprite = img.createUISprite(img.ui.back)
    local btnBack = SpineMenuItem:create(json.ui.button, btnBackSprite)
    btnBack:setScale(view.minScale)
    btnBack:setPosition(scalep(35, 546))
    local menuBack = CCMenu:createWithItem(btnBack)
    menuBack:setPosition(0, 0)
    layer:addChild(menuBack, 10)
    btnBack:registerScriptTapHandler(function()
        audio.play(audio.button)
        replaceScene(require("ui.town.main").create())
    end)
	
	local okSprite = img.createLogin9Sprite(img.login.button_9_small_gold)
	okSprite:setPreferredSize(CCSize(155, 45))
	local oklab = lbl.createFont1(18, i18n.global.mail_btn_batch.string, ccc3(0x7e, 0x27, 0x00))
	oklab:setPosition(CCPoint(okSprite:getContentSize().width/2,
									okSprite:getContentSize().height/2))
	okSprite:addChild(oklab)

	local okBtn = SpineMenuItem:create(json.ui.button, okSprite)
	okBtn:setPosition(scalep(780, 70))
	okBtn:setScale(view.minScale)
	
	local okMenu = CCMenu:createWithItem(okBtn)
	okMenu:setPosition(0,0)
	layer:addChild(okMenu, 10)

	okBtn:registerScriptTapHandler(function()
		audio.play(audio.button) 
		local params = {sid = player.sid,type = 0,act = 21,id = 1,pos = 1}
		addWaitNet()
		net:island_op(params, function(data)
			delWaitNet()
			tablePrint(data)
			if data.status == 0 then
				local pbBag = {}
				pbBag.items = {}
				if data.vit then
					airData.changeVit(data.vit)
					if data.vit > 0 then
						local pbb = {}
						pbb.id = 4302
						pbb.num = data.vit
						pbBag.items[#pbBag.items + 1] = pbb
					end
				end
				if data.item and data.item.items then
					for i=1, #data.item.items do
						bagdata.items.add(data.item.items[i])
						if data.item.items[i].num > 0 then
							pbBag.items[#pbBag.items + 1] = data.item.items[i]
						end
					end
				end
				if #pbBag.items > 0 then
					CCDirector:sharedDirector():getRunningScene():addChild(reward.createFloating(pbBag),99999)
				end
				for _, mainNode in pairs(ui.holys) do
					if mainNode.buildID and mainNode.isFull and mainNode.tipSpine then
						mainNode.isFull = false
						mainNode.tipSpine:playAnimation("animation2",-1)
						--airData.getOutPut()
					end
				end
				for _, mainNode in pairs(ui.mines) do
					if mainNode.buildID and mainNode.isFull and mainNode.tipSpine then
						mainNode.isFull = false
						mainNode.tipSpine:playAnimation("animation2",-1)
						airData.getOutPut()
					end
				end
			elseif data.status == -2 then
				showToast(i18n.global.airisland_no_putout.string)
			else
				showToast("status:" .. data.status)
			end
		end)
	end)
	
	autoLayoutShift(okBtn)

    -- 帮助按钮
    local helpImg = img.createUISprite(img.ui.btn_help)
    local helpBtn = SpineMenuItem:create(json.ui.button, helpImg)
    helpBtn:setScale(view.minScale)
    helpBtn:setPosition(scalep(926, 546))
    local helpMenu = CCMenu:createWithItem(helpBtn)
    helpMenu:setPosition(ccp(0, 0))
    layer:addChild(helpMenu,10) 
    helpBtn:registerScriptTapHandler(function ()
        audio.play(audio.button)
        local helpUI = require("ui.help").create(i18n.global.airisland_help.string)
        layer:addChild(helpUI,99999)
    end)

    autoLayoutShift(btnBack)
    autoLayoutShift(helpBtn)

    -- -- 金币板
    -- local coinBoard = ui.createCurrencyBoard(1)
    -- coinBoard:setPosition(198, 550)
    -- bg:addChild(coinBoard,5)
    -- -- 钻石板
    -- local gemBoard = ui.createCurrencyBoard(2)
    -- gemBoard:setPosition(388, 550)
    -- bg:addChild(gemBoard,5)
    -- -- 虚空之石
    -- local stoneBoard = ui.createCurrencyBoard(70)
    -- stoneBoard:setPosition(578, 550)
    -- bg:addChild(stoneBoard,5)
    -- -- 体力
    -- local apBoard = ui.createCurrencyBoard(0)
    -- apBoard:setPosition(768, 550)
    -- bg:addChild(apBoard,5)

    -- 消耗品栏
    local itembar = require "ui.airisland.itembar"
    layer:addChild(itembar.create(), 1000)

    local buildLayer = nil

    -- -- 矿产 圣物
    -- local function showBuild()
    --     buildLayer = CCLayer:create()
    --     bg:addChild(buildLayer)
        
    --     -- 主城部分
    --     local zhuchengSprite = CCSprite:create()
    --     zhuchengSprite:setContentSize(CCSizeMake(140, 140))
    --     json.load(IMG_BUILD_ID[1])
    --     local aniTower = DHSkeletonAnimation:createWithKey(IMG_BUILD_ID[1])
    --     aniTower:scheduleUpdateLua()
    --     aniTower:setAnchorPoint(CCPoint(0.5, 0.5))
    --     aniTower:setPosition(CCPoint(70, 70))
    --     aniTower:registerAnimation("animation_" .. airConf[data.id].show, -1)
    --     zhuchengSprite:addChild(aniTower)

    --     local btnTower = HHMenuItem:createWithScale(zhuchengSprite, 1)
    --     btnTower:setPosition(524,479-48)
    --     local menuTower = CCMenu:createWithItem(btnTower)
    --     menuTower:setPosition(0, 0)
    --     buildLayer:addChild(menuTower)

    --     btnTower:registerScriptTapHandler(function()
    --         audio.play(audio.button)
    --         local upmaintower = require "ui.airisland.upmaintower"
    --         layer:addChild(upmaintower.create(), 1000)
    --     end)

    --     -- 矿产部分
    --     for i = 1,6 do
    --         local regikind = 1
    --         local itemType = 1 
    --         local itemmine = nil
    --         local btnItemmine = nil
    --         if data.mine and i <= #data.mine then
    --             regikind = 1
    --             itemType = math.floor(data.mine[i].id/1000)
    --             itemmine = CCSprite:create()
    --             itemmine:setContentSize(CCSizeMake(110, 110))
    --             json.load(IMG_BUILD_ID[itemType])
    --             local aniItemmine = DHSkeletonAnimation:createWithKey(IMG_BUILD_ID[itemType])
    --             aniItemmine:scheduleUpdateLua()
    --             aniItemmine:setAnchorPoint(CCPoint(0.5, 0.5))
    --             aniItemmine:setPosition(CCPoint(55, 55))
    --             aniItemmine:registerAnimation("animation_" .. airConf[data.mine[i].id].show, -1)
    --             itemmine:addChild(aniItemmine)
    --         elseif i <= airConf[data.id].pit then
    --             regikind = 2
    --             itemmine = img.createUISprite(img.ui.airisland_bottom2)
    --             local itemflag = img.createUISprite(img.ui.airisland_flag)
    --             itemflag:setAnchorPoint(0.5, 0)
    --             itemflag:setScale(1/0.515)
    --             itemflag:setPosition(itemmine:getContentSize().width/2, itemmine:getContentSize().height/2)
    --             itemmine:addChild(itemflag)
    --         else
    --             regikind = 3
    --             itemmine = img.createUISprite(img.ui.airisland_bottom2)
    --         end
    --         btnItemmine = HHMenuItem:createWithScale(itemmine, 1)
    --         if regikind == 1 then
    --             btnItemmine:setPosition(mineralPosX[i], mineralPosY[i]+28-18)
    --         else
    --             btnItemmine:setPosition(mineralPosX[i], mineralPosY[i])
    --             btnItemmine:setScale(0.515)
    --             if regikind == 3 then
    --                btnItemmine:setVisible(false) 
    --             end
    --         end
    --         local menuItemmine = CCMenu:createWithItem(btnItemmine)
    --         menuItemmine:setPosition(0, 0)
    --         buildLayer:addChild(menuItemmine, 6-i)

    --         btnItemmine:registerScriptTapHandler(function()
    --             audio.play(audio.button)
    --             if regikind == 3 then
    --                 showToast("no place")
    --                 return
    --             end
    --             if regikind == 2 then
    --                 return
    --             end
    --             if regikind == 1 then
    --             end
    --         end)
    --     end

    --     -- 圣物部分
    --     for i = 1,8 do
    --         local regikind = 1
    --         local itemType = 1 
    --         local itemholy = nil
    --         local btnItemholy = nil
    --         if data.holy and i <= #data.holy then
    --             regikind = 1
    --             itemType = math.floor(data.holy[i].id/1000)
    --             itemholy = CCSprite:create()
    --             itemholy:setContentSize(CCSizeMake(110, 110))
    --             json.load(IMG_BUILD_ID[itemType])
    --             local aniItemholy = DHSkeletonAnimation:createWithKey(IMG_BUILD_ID[itemType])
    --             aniItemholy:scheduleUpdateLua()
    --             aniItemholy:setAnchorPoint(CCPoint(0.5, 0.5))
    --             aniItemholy:setPosition(CCPoint(55, 55))
    --             aniItemholy:registerAnimation("animation_" .. airConf[data.holy[i].id].show, -1)
    --             itemholy:addChild(aniItemholy)
    --         elseif i <= airConf[data.id].plat then
    --             regikind = 2
    --             itemholy = img.createUISprite(img.ui.airisland_bottom1)
    --             local itemflag = img.createUISprite(img.ui.airisland_flag)
    --             itemflag:setAnchorPoint(0.5, 0)
    --             itemflag:setScale(1/0.515)
    --             itemflag:setPosition(itemholy:getContentSize().width/2, itemholy:getContentSize().height/2)
    --             itemholy:addChild(itemflag)
    --         else
    --             regikind = 3
    --             itemholy = img.createUISprite(img.ui.airisland_bottom1)
    --         end
    --         btnItemholy = HHMenuItem:createWithScale(itemholy, 1)
    --         if regikind == 1 then
    --             btnItemholy:setPosition(holyPosX[i], holyPosY[i]+28-18)
    --         else
    --             btnItemholy:setPosition(holyPosX[i], holyPosY[i])
    --             btnItemholy:setScale(0.515)
    --             if regikind == 3 then
    --                btnItemholy:setVisible(false) 
    --             end
    --         end
    --         local menuItemholy = CCMenu:createWithItem(btnItemholy)
    --         menuItemholy:setPosition(0, 0)
    --         buildLayer:addChild(menuItemholy, 8-i)

    --         btnItemholy:registerScriptTapHandler(function()
    --             audio.play(audio.button)
    --             if regikind == 3 then
    --                 showToast("no place")
    --                 return
    --             end
    --             if regikind == 2 then
    --                 return
    --             end
    --             if regikind == 1 then
    --             end
    --         end)
    --     end
    -- end

    -- showBuild()

    airData.data.mine = airData.data.mine or {}
    airData.data.holy = airData.data.holy or {}
    ui.addMainTower()
    ui.addMines()
    ui.addHolys()
	
	local hasAnyBuildings = 0
	for _, v in pairs(ui.holys) do
		if v.buildID and ((v.resultType >= 2 and v.resultType <= 4) or v.resultType == 6) then
			hasAnyBuildings = hasAnyBuildings + 1
		end
	end
	for _, v in pairs(ui.mines) do
		if v.buildID and ((v.resultType >= 2 and v.resultType <= 4) or v.resultType == 6) then
			hasAnyBuildings = hasAnyBuildings + 1
		end
	end
	
	if hasAnyBuildings < 2 then
		okBtn:setVisible(false)
	end

    addBackEvent(layer)
    function layer.onAndroidBack()
        replaceScene(require("ui.town.main").create())
    end

    local function onEnter()
        layer.notifyParentLock()
    end
    
    local function onExit()
        layer.notifyParentUnlock()
    end
    
    local last_selected_sprite = 0
    local beginX = 0
    local beginY = 0
    local isClick = false
    local function onTouchBegan(x, y)
        local po = bg:convertToNodeSpace(CCPoint(x, y))
        beginX = po.x
        beginY = po.y
        isClick = true
        for ii=1,#buildingObjs do
            local tObj = buildingObjs[ii]
            if tObj:getAabbBoundingBox():containsPoint(CCPoint(x, y)) then
                setShader(tObj, SHADER_HIGHLIGHT, true)
                last_selected_sprite = tObj
                break
            end
        end
        return true
    end

    local function onTouchMoved(x, y)
        local po = bg:convertToNodeSpace(CCPoint(x, y))
        if isClick and (math.abs(po.x-beginX) > 15 or math.abs(po.y-beginY) > 15) then
            isClick = false
            if last_selected_sprite ~= 0 then
                clearShader(last_selected_sprite, true)
                last_selected_sprite = 0
            end
        end
    end

    local function onTouchEnded(x, y)
        if not isClick then return end
        for ii=1,#buildingObjs do
            local tObj = buildingObjs[ii]
            if tObj:getAabbBoundingBox():containsPoint(CCPoint(x, y)) then
                local params = {
                    sid = player.sid,
                    pos = 0,
                }
                addWaitNet()
                net:island_land(params, function(__data)
                    delWaitNet()
            
                    tbl2string(__data)
                    airData.setLandData(__data)
                    replaceScene(require("ui.airisland.fightmain").create())
                end)

                last_selected_sprite = 0
                clearShader(tObj, true)
                break
            end
        end
    end

    local function onTouch(eventType, x, y)
        if eventType == "began" then   
            return onTouchBegan(x, y)
        elseif eventType == "moved" then
            return onTouchMoved(x, y)
        else
            return onTouchEnded(x, y)
        end
    end
    layer:registerScriptTouchHandler(onTouch)
	layer:setTouchEnabled(true)

    layer:registerScriptHandler(function(event)
        if event == "enter" then
            onEnter()
        elseif event == "exit" then
            onExit()
        elseif event == "cleanup" then
            img.unload(img.packedOthers.ui_airisland_bg)
            img.unload(img.packedOthers.ui_airisland)
            for i=1,#IMG_BUILD_ID do
                json.unload(IMG_BUILD_ID[i])
            end
            --img.unload(img.packedOthers.spine_ui_kongzhan_1)
            --img.unload(img.packedOthers.spine_ui_kongzhan_2)
            --img.unload(img.packedOthers.spine_ui_kongzhan_3)
            --img.unload(img.packedOthers.spine_ui_kongzhan_4)
        end
    end)
    ui.layer = layer

    return layer
end

-- 创建建筑：type 0-主城,1-矿坑,2-圣物
function ui.createBuild(buildType,buildID,pos)
    local pos = pos
    local resultType = math.floor((buildID or 1000)/1000)
    local touch_w = buildType == 0 and 160 or 100
    local touch_h = buildType == 0 and 130 or 50
    -- 主节点
    local mainNode = CCNode:create()
    mainNode:setAnchorPoint(0.5, 0.5)
    mainNode:setContentSize(CCSizeMake(touch_w, touch_h))

    local colorLayer = CCLayerColor:create(ccc4(0, 0, 0, 0))
    colorLayer:setPosition(0,0)
    colorLayer:setContentSize(CCSizeMake(touch_w ,touch_h))
    mainNode:addChild(colorLayer)

    -- 底部坑图
    local sp = CCSprite:create()
    sp:setAnchorPoint(0.5, 0.5)
    sp:setContentSize(CCSizeMake(touch_w, touch_h))
    local sp_w = sp:getContentSize().width
    local sp_h = sp:getContentSize().height
    json.load(IMG_BUILD_ID[resultType])
    -- local bottomImg
    -- local flag = img.createUISprite(img.ui.airisland_flag)
    -- flag:setAnchorPoint(0.5, 0)
    -- flag:setScale(1/0.515)
    -- if buildType == 1 then
    --     bottomImg = img.createUISprite(img.ui.airisland_bottom2)
    --     bottomImg:setAnchorPoint(0.5, 0)
    --     bottomImg:setPosition(sp:getContentSize().width / 2, 0)
    --     bottomImg:addChild(flag)
    --     bottomImg:setScale(0.515)
    --     sp:addChild(bottomImg)
    --     flag:setPosition(bottomImg:getContentSize().width/2, bottomImg:getContentSize().height/2)
    -- elseif buildType == 2 then
    --     bottomImg = img.createUISprite(img.ui.airisland_bottom1)
    --     bottomImg:setAnchorPoint(0.5, 0)
    --     bottomImg:setPosition(sp:getContentSize().width / 2, 0)
    --     bottomImg:addChild(flag)
    --     bottomImg:setScale(0.515)
    --     sp:addChild(bottomImg)
    --     flag:setPosition(bottomImg:getContentSize().width/2, bottomImg:getContentSize().height/2)
    -- end

    -- 底座
    local bottomImg = json.create(json.ui.kongzhan_dizuo)
    bottomImg:setPosition(sp_w / 2,sp_h / 2)
    sp:addChild(bottomImg)
    if buildType == 0 then
        bottomImg:playAnimation("animation_1",-1)
        bottomImg:setVisible(false)
    else
        bottomImg:playAnimation("animation_" .. buildType, -1)
    end
    -- 拆除特效
    local removeSpine = json.create(json.ui.kongzhan_zhudao_chaichu)
    removeSpine:setPosition(sp_w / 2,sp_h / 2)
    sp:addChild(removeSpine,10)
    -- 创建特效
    local buildSpine = json.create(json.ui.kongzhan_zhudao_jianzao)
    buildSpine:setPosition(sp_w / 2,sp_h / 2)
    sp:addChild(buildSpine,10)
    -- 升级特效
    local upgradeSpine = json.create(json.ui.kongzhan_zhudao_shengji)
    upgradeSpine:setPosition(sp_w / 2,sp_h / 2)
    sp:addChild(upgradeSpine,10)

    local menuItem = HHMenuItem:createWithScale(sp, 1)
    menuItem:setAnchorPoint(0.5, 0.5)
    menuItem:setPosition(sp:getContentSize().width / 2, sp:getContentSize().height / 2)
    if buildType == 0 then
        menuItem:setPositionY(menuItem:getPositionY() - 20)
    end
    local menu = CCMenu:createWithItem(menuItem)
    menu:setPosition(0, 0)
    mainNode:addChild(menu)
    menuItem:registerScriptTapHandler(function()
        audio.play(audio.button)
        -- 主塔
        if buildType == 0 then
            local upgradeUI = require("ui.airisland.upgradeUI").create(airData.data.id,0,nil,ui,nil)
            ui.layer:addChild(upgradeUI,99999)
            return
        end

        local isSeed
        if buildType == 2 then
            for i,v in ipairs(airData.data.holy) do
                if v.pos == mainNode.pos then
                    isSeed = true
                    break
                end
            end
        elseif buildType == 1 then
            for i,v in ipairs(airData.data.mine) do
                    if v.pos == mainNode.pos then
                        isSeed = true
                        break
                    end
                end
            end
        -- 未种植(进入创建界面)
        if not isSeed then
            local buildUI = require("ui.airisland.buildUI").create(mainNode.buildType,pos,ui)
            --local buildUI = require("ui.airisland.upgradeUI").create(2001)
            --local buildUI = require("ui.airisland.lvMaxUI").create(1001)
            ui.layer:addChild(buildUI,99999)
            return
        end
        -- 已种植(进入升级和移除界面)
        if airConf[mainNode.buildID].give or airConf[mainNode.buildID].time then
            local params = {
                sid = player.sid,
            }
            addWaitNet()
            net:island_sync(params, function(__data)
                delWaitNet()
                print("------result-------")
                tablePrint(__data)
                --tbl2string(__data)
                airData.setData(__data)
                airData.data.holy = airData.data.holy or {}
                airData.data.mine = airData.data.mine or {}
                local outPut
                local list = buildType == 1 and airData.data.mine or airData.data.holy
                for i,v in ipairs(list) do
                    if v.pos == mainNode.pos then
                        outPut = v.val or 0
                        break
                    end
                end
                local upgradeUI = require("ui.airisland.upgradeUI").create(mainNode.buildID,mainNode.buildType,pos,ui,outPut)
                ui.layer:addChild(upgradeUI,99999)
            end)
            return 
        end
        local upgradeUI = require("ui.airisland.upgradeUI").create(mainNode.buildID,mainNode.buildType,pos,ui,nil)
        ui.layer:addChild(upgradeUI,99999)
    end)

    -- 顶部骨骼动画
    local result = DHSkeletonAnimation:createWithKey(IMG_BUILD_ID[resultType])
    result:scheduleUpdateLua()
    result:setAnchorPoint(CCPoint(0.5, 0.5))
    result:setPosition(CCPoint(sp_w / 2, sp_h / 2))
    sp:addChild(result)
    if buildID then
        result:registerAnimation("animation_" .. airConf[buildID].show, -1)
    end

    if buildID then
        result:setVisible(true)
        bottomImg:setVisible(false) 
    else
        result:setVisible(false)
        bottomImg:setVisible(true) 
    end

    -- 顶部提示板
    local tipBg
    if buildID and ((resultType >= 2 and resultType <= 4) or resultType == 6) then
        print("进来这里了")
        tipBg = img.createUISprite(img.ui.airisland_tip)
        tipBg:setOpacity(0)
        local bg_w = tipBg:getContentSize().width 
        local bg_h = tipBg:getContentSize().height
        local own 
        local max = airConf[buildID].max
        for i,v in ipairs(airData.data.mine) do
            if v.id == buildID and v.pos == pos then
                v.val = v.val or 0
                own = v.val
                break
            end
        end
        for i,v in ipairs(airData.data.holy) do
            if v.id == buildID and v.pos == pos then
                v.val = v.val or 0
                own = v.val
                break
            end
        end

        -- 骨骼动画
        local tipSpine = json.create(json.ui.kongzhan_tish)
        tipSpine:setPosition(bg_w / 2,bg_h / 2 - 28)
        tipBg:addChild(tipSpine)
        mainNode.tipSpine = tipSpine

        -- 产物图标
        local outID
        if resultType == 2 then
            outID = 1
        elseif resultType == 3 then
            outID = 2
        elseif resultType == 4 then
            outID = 15
        elseif resultType == 6 then
            outID = 4302
        end
        local outIcon1 = resultType == 6 and img.createItemIconForId(outID) or img.createItemIcon(outID)
        local outIcon2 = resultType == 6 and img.createItemIconForId(outID) or img.createItemIcon(outID)
        if resultType ~= 6 then
            outIcon1:setScale(0.4)
            outIcon2:setScale(0.4)
        end
        tipSpine:addChildFollowSlot("code_icon1", outIcon1)
        tipSpine:addChildFollowSlot("code_icon2", outIcon2)

        local outItem = HHMenuItem:createWithScale(tipBg, 1)
        outItem:setAnchorPoint(0.5, 0.5)
        outItem:setPosition(sp:getContentSize().width / 2, 75)
        local outMenu = CCMenu:createWithItem(outItem)
        outMenu:setPosition(0, 0)
        ui.bg:addChild(outMenu,10)
        mainNode.outMenu = outMenu

        local buildType = buildType
        local buildID = buildID
        local buildPos = pos
        outItem:registerScriptTapHandler(function()
            local createType = buildType == 1 and 1 or 0
            local params = {sid = player.sid,type = createType,act = 2,id = mainNode.buildID,pos = mainNode.pos}
            addWaitNet()
            print("-------output info--------")
            print("type" .. createType .. "," .. "act:" .. 2 .. "," .. "id:" .. mainNode.buildID .. "," .. "pos:" .. mainNode.pos)
            net:island_op(params, function(data)
                print("--------get output--------")
                delWaitNet()
                --tbl2string(data)
                tablePrint(data)
                if data.status == 0 then
                    --outItem:setEnabled(false)
                    if data.vit then
                        airData.changeVit(data.vit)
                        if data.vit > 0 then
                            local pbBag = {}
                            pbBag.items = {}
                            pbBag.items[1] = {}
                            pbBag.items[1].id = 4302
                            pbBag.items[1].num = data.vit
                            CCDirector:sharedDirector():getRunningScene():addChild(reward.createFloating(pbBag),99999)
                            local max = airConf[mainNode.buildID].max
                            if data.vit >= max then
                                mainNode.tipSpine:playAnimation("animation2",-1)
								mainNode.isFull = false
                            end
                        else
                            showToast(i18n.global.airisland_no_putout.string)
                        end
                    else
                        bagdata.items.add(data.item.items[1])
                        if data.item.items[1].num > 0 then
                            local pbBag = {}
                            pbBag.items = {}
                            pbBag.items[1] = data.item.items[1]
                            CCDirector:sharedDirector():getRunningScene():addChild(reward.createFloating(pbBag),99999)
                            local max = airConf[mainNode.buildID].max
                            if data.item.items[1].num >= max then
                                mainNode.tipSpine:playAnimation("animation2",-1)
								mainNode.isFull = false
                            end

                            local limit = airConf[params.id].max
                            if data.item.items[1].num >= limit then
                               airData.getOutPut() 
                            end
                        else
                            showToast(i18n.global.airisland_no_putout.string)
                        end
                    end
                    --tipSpine:playAnimation("animation2",-1)
                else
                    showToast(i18n.global.airisland_no_putout.string)
                end
            end)
        end)

        if own >= max then
            tipSpine:playAnimation("animation",-1)
			mainNode.isFull = true
        else
            tipSpine:playAnimation("animation2",-1)
			mainNode.isFull = false
        end
    end

    mainNode.bottomImg = bottomImg
    mainNode.result = result
    mainNode.buildType = buildType
    mainNode.buildID = buildID
    mainNode.pos = pos
    mainNode.resultType = resultType
    mainNode.removeSpine = removeSpine
    mainNode.buildSpine = buildSpine
    mainNode.upgradeSpine = upgradeSpine
    mainNode.sp = sp

    return mainNode
end

-- 添加主城
function ui.addMainTower()
    ui.mainTower = ui.createBuild(0, airData.data.id)
    ui.mainTower:setPosition(500,454)
    ui.bg:addChild(ui.mainTower)
end

-- 添加矿物
function ui.addMines() 
    local touch_w = 100
    local touch_h = 50
    local pitMax = airConf[airData.data.id].pit
    for i,v in ipairs(airData.data.mine) do
        local mine = ui.createBuild(1, v.id ,v.pos)
        ui.mines[v.pos] = mine
    end
    for i=1,pitMax do
        if not ui.mines[i] then
            local mine = ui.createBuild(1, nil ,i)
            ui.mines[i] = mine
        end
        ui.mines[i]:setPositionX(ui.mineralPosX[i])
        ui.mines[i]:setPositionY(ui.mineralPosY[i])
        ui.bg:addChild(ui.mines[i],7 - i)
        if ui.mines[i].outMenu then
            ui.mines[i].outMenu:setPositionX(ui.mineralPosX[i] - touch_w / 2)
            ui.mines[i].outMenu:setPositionY(ui.mineralPosY[i] - 10)
        end
    end 
end

-- 添加圣物
function ui.addHolys()
    local touch_w = 100
    local touch_h = 50
    local platMax = airConf[airData.data.id].plat
    for i,v in ipairs(airData.data.holy) do
        local holy = ui.createBuild(2, v.id, v.pos)
        ui.holys[v.pos] = holy
    end
    for i=1,platMax do
        if not ui.holys[i] then
            local holy = ui.createBuild(2, nil, i)
            ui.holys[i] = holy
        end
        ui.holys[i]:setPositionX(ui.holyPosX[i])
        ui.holys[i]:setPositionY(ui.holyPosY[i])
        ui.bg:addChild(ui.holys[i],8 - i)
        if ui.holys[i].outMenu then
            ui.holys[i].outMenu:setPositionX(ui.holyPosX[i] - touch_w / 2)
            ui.holys[i].outMenu:setPositionY(ui.holyPosY[i] - 10)
        end
    end 
end

-- 建造建筑
function ui.buildItem(pos,buildType,buildID)
    local item
    if buildType == 1 then
        item = ui.mines[pos]
    else
        item = ui.holys[pos]
    end    
    item.buildType = buildType
    item.buildID = buildID
    item.pos = pos
    item.resultType = math.floor(buildID / 1000)
    item.bottomImg:setVisible(false)

    print("----resultType-----" .. item.resultType)
    print("show:" .. airConf[buildID].show)

    local sp_w = item.sp:getContentSize().width
    local sp_h = item.sp:getContentSize().height
    local result = json.create(IMG_BUILD_ID[item.resultType])
    -- local result = DHSkeletonAnimation:createWithKey(IMG_BUILD_ID[item.resultType])
    -- result:scheduleUpdateLua()
    --local result = json.create(IMG_BUILD_ID[item.resultType])
    result:setAnchorPoint(CCPoint(0.5, 0.5))
    result:setPosition(CCPoint(sp_w / 2, sp_h / 2))
    item.sp:addChild(result)
    if buildID then
        result:unregisterAllAnimation()
        result:registerAnimation("animation_" .. airConf[buildID].show, -1)
    end
    item.result:removeFromParent()
    item.result = result
    item.buildSpine:playAnimation("animation")

    -- 查看是否添加产物动画
    -- 顶部提示板
    if buildID and ((item.resultType >= 2 and item.resultType <= 4) or item.resultType == 6) then
        print("进来这里了")
        if item.outMenu then
            item.outMenu:removeFromParent()
            item.outMenu = nil
        end
        local tipBg
        tipBg = img.createUISprite(img.ui.airisland_tip)
        tipBg:setOpacity(0)
        local bg_w = tipBg:getContentSize().width 
        local bg_h = tipBg:getContentSize().height
        local own = 0
        local max = airConf[buildID].max

        -- 骨骼动画
        local tipSpine = json.create(json.ui.kongzhan_tish)
        tipSpine:setPosition(bg_w / 2,bg_h / 2 - 28)
        tipBg:addChild(tipSpine)
        item.tipSpine = tipSpine

        -- 产物图标
        local outID
        if item.resultType == 2 then
            outID = 1
        elseif item.resultType == 3 then
            outID = 2
        elseif item.resultType == 4 then
            outID = 15
        elseif item.resultType == 6 then
            outID = 4302
        end
        local outIcon1 = item.resultType == 6 and img.createItemIconForId(outID) or img.createItemIcon(outID)
        local outIcon2 = item.resultType == 6 and img.createItemIconForId(outID) or img.createItemIcon(outID)
        if item.resultType ~= 6 then
            outIcon1:setScale(0.4)
            outIcon2:setScale(0.4)
        end
        tipSpine:addChildFollowSlot("code_icon1", outIcon1)
        tipSpine:addChildFollowSlot("code_icon2", outIcon2)

        local outItem = HHMenuItem:createWithScale(tipBg, 1)
        outItem:setAnchorPoint(0.5, 0.5)
        outItem:setPosition(item.sp:getContentSize().width / 2, 75)
        local outMenu = CCMenu:createWithItem(outItem)
        outMenu:setPosition(0, 0)
        ui.bg:addChild(outMenu,10)
        item.outMenu = outMenu

        local buildType = buildType
        local buildID = buildID
        local buildPos = pos
        outItem:registerScriptTapHandler(function()
            local createType = buildType == 1 and 1 or 0
            local params = {sid = player.sid,type = createType,act = 2,id = item.buildID,pos = item.pos}
            addWaitNet()
            print("-------output info--------")
            print("type" .. createType .. "," .. "act:" .. 2 .. "," .. "id:" .. item.buildID .. "," .. "pos:" .. item.pos)
            net:island_op(params, function(data)
                print("--------get output--------")
                delWaitNet()
                --tbl2string(data)
                tablePrint(data)
                if data.status == 0 then
                    --outItem:setEnabled(false)
                    if data.vit then
                        airData.changeVit(data.vit)
                        if data.vit > 0 then
                            local pbBag = {}
                            pbBag.items = {}
                            pbBag.items[1] = {}
                            pbBag.items[1].id = 4302
                            pbBag.items[1].num = data.vit
                            CCDirector:sharedDirector():getRunningScene():addChild(reward.createFloating(pbBag),99999)
                            local max = airConf[item.buildID].max
                            if data.vit >= max then
                                item.tipSpine:playAnimation("animation2",-1)
								item.isFull = false
                            end
                        else
                            showToast(i18n.global.airisland_no_putout.string)
                        end
                    else
                        bagdata.items.add(data.item.items[1])
                        if data.item.items[1].num > 0 then
                            local pbBag = {}
                            pbBag.items = {}
                            pbBag.items[1] = data.item.items[1]
                            CCDirector:sharedDirector():getRunningScene():addChild(reward.createFloating(pbBag),99999)
                            local max = airConf[item.buildID].max
                            if data.item.items[1].num >= max then
                                item.tipSpine:playAnimation("animation2",-1)
								item.isFull = false
                                airData.getOutPut()
                            end
                        else
                            showToast(i18n.global.airisland_no_putout.string)
                        end
                    end
                    --tipSpine:playAnimation("animation2",-1)
                else
                    showToast(i18n.global.airisland_no_putout.string)
                end
            end)
        end)

        if own >= max then
            tipSpine:playAnimation("animation",-1)
			item.isFull = true
        else
            tipSpine:playAnimation("animation2",-1)
			item.isFull = false
        end

        local touch_w = 100
        if buildType == 1 then
            item.outMenu:setPositionX(ui.mineralPosX[pos] - touch_w / 2)
            item.outMenu:setPositionY(ui.mineralPosY[pos] - 10)
        else
            item.outMenu:setPositionX(ui.holyPosX[pos] - touch_w / 2)
            item.outMenu:setPositionY(ui.holyPosY[pos] - 10)
        end
    end

    -- 将新数据灌入数据模块
    local item = {}
    item.id = buildID
    item.pos = pos
    item.val = 0
    local list = buildType == 1 and airData.data.mine or airData.data.holy
    table.insert(list,item)
end

-- 移除建筑
function ui.removeItem(pos,buildType)
    print("----removeItem------")
    print("pos:" .. pos .. "," .. "buildType" .. buildType)
    local item
    if buildType == 1 then
        item = ui.mines[pos]
    else
        item = ui.holys[pos]
    end
    if item.outMenu then
        item.outMenu:setVisible(false)
    end
    item.buildType = buildType
    item.buildID = nil
    item.resultType = 1
    item.bottomImg:setVisible(false)
    item.result:setVisible(false)
    item.removeSpine:registerAnimation("animation" .. buildType)
    item.removeSpine:registerLuaHandler(function (event)
        if event == "fx" then
            -- 移除动画结束
            item.bottomImg:setVisible(true)
        end
    end)
    -- 更新数据模块
    local list = buildType == 1 and airData.data.mine or airData.data.holy
    for i,v in ipairs(list) do
        if v.pos == pos then
            table.remove(list,i)
            break
        end
    end
end

-- 升级建筑
function ui.upgradeItem(pos,buildType)
    if buildType == 0 then
        --主城
        ui.mainTower.buildType = buildType
        ui.mainTower.buildID = ui.mainTower.buildID + 1
        ui.mainTower.result:unregisterAllAnimation()
        ui.mainTower.result:registerAnimation("animation_" .. airConf[ui.mainTower.buildID].show, -1)
        airData.data.id = ui.mainTower.buildID
        return
    end
    -- 矿物和圣物
    local item
    if buildType == 1 then
        item = ui.mines[pos]
    else
        item = ui.holys[pos]
    end
    item.buildType = buildType
    item.buildID = item.buildID + 1
    item.result:unregisterAllAnimation()
    item.result:registerAnimation("animation_" .. airConf[item.buildID].show, -1)
    --item.upgradeSpine:playAnimation("animation")
    -- 更新数据模块
    local list = buildType == 1 and airData.data.mine or airData.data.holy
    for i,v in ipairs(list) do
        if v.pos == pos then
            v.id = item.buildID
            return
        end
    end
end

-- 创建货币板
function ui.createCurrencyBoard(id)
    -- 底板
    local board = img.createUI9Sprite(img.ui.main_coin_bg)
    board:setPreferredSize(CCSizeMake(146, 32))
    local board_w = board:getContentSize().width 
    local board_h = board:getContentSize().height
    -- 图标
    local icon
    if id == 0 then
        icon = img.createItemIcon2(ITEM_ID_COIN)
    else
        icon = img.createItemIcon2(id)  
    end
    icon:setPosition(5, board_h / 2 + 2)
    board:addChild(icon)
    -- 数字标签
    local num 
    if id == 1 then
        num = num2KM(bagdata.coin())
    elseif id == 2 then
        num = num2KM(bagdata.gem())
    elseif id == 72 then
        num = num2KM(bagdata.items.find(id).num)
    elseif id == 0 then
        num = airData.data.vit.vit .. "/" .. airConf[airData.data.id].xMax
    end
    local numLabel = lbl.createFont2(16, num, ccc3(255, 246, 223)) 
    numLabel:setPosition(board_w / 2, board_h / 2 + 3)
    board:addChild(numLabel)
    -- 加号按钮
    local plusImg = img.createUISprite(img.ui.main_icon_plus)
    plusBtn = HHMenuItem:create(plusImg)
    plusBtn:setPosition(board_w-18, board_h/2)
    plusBtn:setVisible(false)
    local plusMenu = CCMenu:createWithItem(plusBtn)
    plusMenu:setPosition(ccp(0, 0))
    board:addChild(plusMenu)

    local id = id 
    board:scheduleUpdateWithPriorityLua(function()
        if id == 1 then
            numLabel:setString(num2KM(bagdata.coin()))
        elseif id == 2 then
            numLabel:setString(num2KM(bagdata.gem()))
        elseif id == 72 then
            numLabel:setString(num2KM(bagdata.items.find(id).num))
        elseif id == 0 then
            numLabel:setString(airData.data.vit.vit .. "/" .. airConf[airData.data.id].xMax)
        end
    end, 0)

    board.label = numLabel

    return board
end

-- 添加坑位
function ui.addHole(buildType,pos)
    local item
    if buildType == 1 then
        item = ui.createBuild(buildType,nil,pos)
        ui.mines[pos] = item
        item:setPositionX(ui.mineralPosX[#ui.mines])
        item:setPositionY(ui.mineralPosY[#ui.mines])
    elseif buildType == 2 then
        item = ui.createBuild(buildType,nil,pos)
        ui.holys[pos] = item
        item:setPositionX(ui.holyPosX[#ui.holys])
        item:setPositionY(ui.holyPosY[#ui.holys])
    end
    local maxOrder = buildType == 1 and 7 or 8
    ui.bg:addChild(item,maxOrder - pos)
end

-- 更新某个产物
function ui.refreshOutPut(buildType,pos,isEnough)
    local item 
    if buildType == 1 then
        item = ui.mines[pos]
    elseif buildType == 2 then
        item = ui.holys[pos]
    end
    if item.tipSpine then
        if isEnough then
            item.tipSpine:playAnimation("animation",-1)
			item.isFull = true
        else
            item.tipSpine:playAnimation("animation2",-1)
			item.isFull = false
        end
    end
end

-- 收获某个产物
function ui.getOutPut(buildType,pos)
    local item 
    if buildType == 1 then
        item = ui.mines[pos]
    elseif buildType == 2 then
        item = ui.holys[pos]
    end
    if item.tipSpine then
        item.tipSpine:playAnimation("animation2",-1)
		item.isFull = false
    end
end

return ui
