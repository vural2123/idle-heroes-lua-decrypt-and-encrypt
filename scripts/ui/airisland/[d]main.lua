
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

function ui.create()
    local data = {}
    data.id = 1001
    data.vit = {vit = 10,buy = 0 }
    data.holy = {{id = 5001,pos = 1},{id = 6001,pos = 2},{id = 7001,pos = 3},{id = 8001,pos = 4}}
    data.mine = {{id = 2001,pos = 1},{id = 3001,pos = 2},{id = 4001,pos = 3},{id = 4003,pos = 4}}

    airData.setData(data)

    local layer = CCLayer:create()
    img.load(img.packedOthers.ui_airisland_bg)
    img.load(img.packedOthers.ui_airisland)
    local bg = img.createUISprite(img.ui.airisland_bg)
    bg:setScale(view.minScale)
    bg:setPosition(view.midX, view.midY)
    layer:addChild(bg)

    -- fight test
    local airislandBtn = CCMenuItemFont:create("Feiting")
    airislandBtn:setScale(view.minScale)
    airislandBtn:setColor(ccc3(0xff, 0x00, 0x00))
    airislandBtn:setPosition(scalep(400, 490))
    local airislandMenu = CCMenu:createWithItem(airislandBtn)
    airislandMenu:setPosition(0, 0)
    layer:addChild(airislandMenu)
    airislandBtn:registerScriptTapHandler(function()
        replaceScene(require("ui.airisland.fightmain").create())
    end)

    local btnBackSprite = img.createUISprite(img.ui.back)
    local btnBack = SpineMenuItem:create(json.ui.button, btnBackSprite)
    btnBack:setScale(view.minScale)
    btnBack:setPosition(scalep(35, 546))
    local menuBack = CCMenu:createWithItem(btnBack)
    menuBack:setPosition(0, 0)
    layer:addChild(menuBack, 10)
    btnBack:registerScriptTapHandler(function()
        replaceScene(require("ui.town.main").create())
    end)

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
    
    layer:registerScriptHandler(function(event)
        if event == "enter" then
            onEnter()
        elseif event == "exit" then
            onExit()
        elseif event == "cleanup" then
            img.unload(img.packedOthers.ui_airisland_bg)
            img.unload(img.packedOthers.ui_airisland)
        end
    end)

    -- 添加矿坑
    ui.mineral = {}
    local mineralPos = {{534,154.5},{485,89.5},{599,105.5},{639,252.5},{765,258.5},{704,297.5}}
    for i = 1, 6 do
        local holeLayer = CCLayerColor:create(ccc4(0, 0, 0, 0))
        holeLayer:setContentSize(CCSizeMake(200 ,80))
        holeLayer:setPosition(scalep(mineralPos[i][1],mineralPos[i][2]))
        holeLayer:setScale(view.minScale * 0.515)
        holeLayer:setTouchEnabled(true)
        holeLayer:setTouchSwallowEnabled(false)
        holeLayer:ignoreAnchorPointForPosition(false)
        layer:addChild(holeLayer,7 - i)
        table.insert(ui.mineral,holeLayer)

        local function onTouch(eventType, x, y)
            local isOut
            local box = holeLayer:getBoundingBox()
            local point = layer:convertToNodeSpace(CCPoint(x, y))
            if eventType == "began" then
                if box:containsPoint(point) then
                    setShader(holeLayer, SHADER_HIGHLIGHT, true)
                    return true
                end
                return false
            elseif eventType == "moved" then
                if not box:containsPoint(point) then
                    clearShader(holeLayer, true)
                    isOut = true
                end
            elseif eventType == "ended" then
                clearShader(holeLayer, true)
                if box:containsPoint(point) and not isOut then
                    print("end")
                end
            end
        end
        holeLayer:registerScriptTouchHandler(onTouch)

        local holeImg = img.createUISprite(img.ui.airisland_bottom2)
        local holeFlag = img.createUISprite(img.ui.airisland_flag)
        holeFlag:setScale(1 / 0.515)
        holeFlag:setPosition(ccp(52 / 0.515, 39 / 0.515))
        holeImg:setPosition(ccp(100, 40))
        holeImg:addChild(holeFlag)
        holeLayer:addChild(holeImg)

        -- 显示已有的建筑
        local build
        for _, v in ipairs(airData.data.mine) do
            if v.pos == i then
                build = ui.createBuild(1,clone(v))
                build:setAnchorPoint(ccp(0.5, 0))
                build:setPosition(89,0)
                holeLayer:addChild(build)
                break
            end
        end

        holeLayer.hole = holeImg
        holeLayer.build = build or nil
        if build ~= nil then
            holeImg:setVisible(false)
        end
    end

    -- 添加圣物坑
    ui.relic = {}
    local relicPos = {{384,254},{280,273},{498,226},{548,365},{385,392},{162,382},{133,476},{353,489}}
    for i = 1, 8 do
        local holeLayer = CCLayerColor:create(ccc4(0, 0, 0, 0))
        holeLayer:setContentSize(CCSizeMake(200 ,80))
        holeLayer:setPosition(scalep(relicPos[i][1],relicPos[i][2]))
        holeLayer:setScale(view.minScale * 0.515)
        holeLayer:setTouchEnabled(true)
        holeLayer:setTouchSwallowEnabled(false)
        holeLayer:ignoreAnchorPointForPosition(false)
        layer:addChild(holeLayer)
        table.insert(ui.relic,holeLayer)

        local function onTouch(eventType, x, y)
            local isOut
            local box = holeLayer:getBoundingBox()
            local point = layer:convertToNodeSpace(CCPoint(x, y))
            if eventType == "began" then
                if box:containsPoint(point) then
                    setShader(holeLayer, SHADER_HIGHLIGHT, true)
                    return true
                end
                return false
            elseif eventType == "moved" then
                if not box:containsPoint(point) then
                    clearShader(holeLayer, true)
                    isOut = true
                end
            elseif eventType == "ended" then
                clearShader(holeLayer, true)
                if box:containsPoint(point) and not isOut then
                    print("end")
                end
            end
        end
        holeLayer:registerScriptTouchHandler(onTouch)

        local holeImg = img.createUISprite(img.ui.airisland_bottom1)
        local holeFlag = img.createUISprite(img.ui.airisland_flag)
        holeFlag:setScale(1 / 0.515)
        holeFlag:setPosition(ccp(49 / 0.515, 43 / 0.515))
        holeImg:setPosition(ccp(100, 40))
        holeImg:addChild(holeFlag)
        holeLayer:addChild(holeImg)

        -- 显示已有的建筑
        local build
        for _, v in ipairs(airData.data.holy) do
            if v.pos == i then
                build = ui.createBuild(2,clone(v))
                build:setAnchorPoint(ccp(0.5, 0))
                build:setPosition(89,0)
                holeLayer:addChild(build)
                break
            end
        end

        holeLayer.hole = holeImg
        holeLayer.build = build or nil
        if build ~= nil then
            holeImg:setVisible(false)
        end
    end

    -- 添加主城
    local towerLayer = CCLayerColor:create(ccc4(0, 0, 0, 0))
    towerLayer:setContentSize(CCSizeMake(195 ,163))
    towerLayer:setPosition(scalep(524,479))
    towerLayer:setScale(view.minScale)
    towerLayer:setTouchEnabled(true)
    towerLayer:setTouchSwallowEnabled(false)
    towerLayer:ignoreAnchorPointForPosition(false)
    layer:addChild(towerLayer)
    local function onTouch(eventType, x, y)
        local isOut
        local box = towerLayer:getBoundingBox()
        local point = layer:convertToNodeSpace(CCPoint(x, y))
        if eventType == "began" then
            if box:containsPoint(point) then
                setShader(towerLayer, SHADER_HIGHLIGHT, true)
                return true
            end
            return false
        elseif eventType == "moved" then
            if not box:containsPoint(point) then
                clearShader(towerLayer, true)
                isOut = true
            end
        elseif eventType == "ended" then
            clearShader(towerLayer, true)
            if box:containsPoint(point) and not isOut then
                print("end")
                ui.createMainTowerTip()
            end
        end
    end
    towerLayer:registerScriptTouchHandler(onTouch)

    local towerConf = airConf[airData.data.id]
    local towerShow = towerConf.show
    local towerImg = img.createUISprite(img.ui["airisland_maintower_"..towerShow])
    towerImg:setPosition(97.5, 81.5)
    towerLayer:addChild(towerImg)

    -- 判定哪些坑不显示
    local pit = towerConf.pit
    local plat = towerConf.plat
    for i, v in ipairs(ui.mineral) do
        if i > pit then
            v:setVisible(false)
        end
    end
    for i, v in ipairs(ui.relic) do
        if i > plat then
            v:setVisible(false)
        end
    end

    local data = {}
    data = airConf[5001]
    data.id = 5001

    local box = ui.createBuildBox(2,data,false)
    box:setScale(view.minScale)
    box:setPosition(view.midX,view.midY)
    layer:addChild(box,100)

    ui.mainLayer = layer
    return layer
end

-- 创建建筑(1 -- 矿物，2 -- 圣物)
function ui.createBuild(type,buildData)
    local buildImg
    print("这个id" .. buildData.id)
    print("type"..type)

    local buildShow = airConf[buildData.id].show
    print("这个show"..buildShow)

    if type == 1 then
        if buildData.id > 2000 and buildData.id < 3000 then
            -- 金矿
            buildImg = img.createUISprite(img.ui["airisland_gold_".. buildShow])
        elseif buildData.id > 3000 and buildData.id < 4000 then
            -- 钻石矿
            buildImg = img.createUISprite(img.ui["airisland_diamond_".. buildShow])
        elseif buildData.id > 4000 and buildData.id < 5000 then
            -- 魔法之尘
            buildImg = img.createUISprite(img.ui["airisland_magic_".. buildShow])
        end
    else
        if buildData.id > 5000 and buildData.id < 6000 then
            -- 丰收圣物
            buildImg = img.createUISprite(img.ui["airisland_bumper_".. buildShow])
        elseif buildData.id > 6000 and buildData.id < 7000 then
            -- 活力圣物
            buildImg = img.createUISprite(img.ui["airisland_energy_".. buildShow])
        elseif buildData.id > 7000 and buildData.id < 8000 then    
            -- 迅捷圣物
            buildImg = img.createUISprite(img.ui["airisland_fast_".. buildShow])
        elseif buildData.id > 8000 and buildData.id < 9000 then
            -- 暴君圣物
            buildImg = img.createUISprite(img.ui["airisland_tyrant_".. buildShow])
        elseif buildData.id > 9000 and buildData.id < 10000 then
            -- 血月圣物
            buildImg = img.createUISprite(img.ui["airisland_moon_".. buildShow])
        end
    end

    buildImg.type = type
    buildImg.data = clone(buildData)

    return buildImg
end

-- 创建建筑升级小弹窗(type 0--主城 1--矿物 2--圣物)
function ui.createBuildTip(type,pos)
    -- 背景
    local bg = img.createLogin9Sprite(img.login.dialog)
    bg:setPreferredSize(CCSizeMake(752, 488))
    bg:setScale(view.minScale)
    bg:setPosition(view.midX, view.midY)
    layer:addChild(bg)
    -- 标题
    local title = lbl.createFont1(24, i18n.global.chip_btn_buy.string, ccc3(0xe6, 0xd0, 0xae))
    title:setPosition(CCPoint(376, 459))
    bg:addChild(title, 2)
    local titleShadow = lbl.createFont1(24, i18n.global.chip_btn_buy.string, ccc3(0x59, 0x30, 0x1b))
    titleShadow:setPosition(CCPoint(376, 457))
    bg:addChild(titleShadow)
    -- 关闭按钮
    local closeImg = img.createUISprite(img.ui.close)
    local closeBtn = SpineMenuItem:create(json.ui.button, closeImg)
    closeBtn:setPosition(CCPoint(727, 460))
    local closeMenu = CCMenu:createWithItem(closeBtn)
    closeMenu:setPosition(CCPoint(0, 0))
    bg:addChild(closeMenu, 100)
    -- 升级按钮
    local upgradeImg = img.createUI9Sprite(img.ui.btn_2)
    upgradeImg:setPreferredSize(CCSizeMake(204, 54))
    local upgradeLabel = lbl.createFont1(24, i18n.global.chip_btn_buy.string, ccc3(0x59, 0x30, 0x1b))
    upgradeLabel:setPosition(102,27)
    upgradeImg:addChild(upgradeLabel)
    local upgradeBtn = SpineMenuItem:create(json.ui.button, upgradeImg)
    upgradeBtn:setPosition(376, 72)
    local upgradeMenu = CCMenu:createWithItem(upgradeBtn)
    upgradeMenu:setPosition(0,0)
    bg:addChild(upgradeMenu)
    -- 内部框
    local innerBox = img.createUI9Sprite(img.ui.bottom_border_3)
    innerBox:setPreferredSize(CCSizeMake(656, 250))
    innerBox:setPosition(374, 280)
    bg:addChild(innerBox)
    -- 箭头
    local arrow = img.createUI9Sprite(img.ui.arrow)
    arrow:setPosition(330,120)
    innerBox:addChild(arrow)
    -- 满级信息/升级信息
    local maxUI
    local leftBuild
    local rightBuild
    local expend1
    local expend2
    local curConf
    local nextConf
    local id
    local maxLv = 40
    local data = {}
    if type == 0 then
        maxLv = 20
        data = clone(airConf[1000 + maxLv])
        data.id = 1000 + maxLv
        maxUI = ui.createBuildBox(type, data)
        maxUI:setPosition(324, 260)
        bg:addChild(maxUI)
        if airData.data.id < 1000 + maxLv then
            curConf = airConf[airData.data.id]
            nextConf = airConf[airData.data.id + 1]
            leftBuild = ui.createBuildBox(type,curConf,true)
            rightBuild = ui.createBuildBox(type,nextConf)
            leftBuild:setPosition(170,133)
            rightBuild:setPosition(490,133)
            bg:addChild(leftBuild)
            bg:addChild(rightBuild)
            --expend1 = ui.createExpendBar(nextConf.need[1].id,nextConf.need[1].num)
            --expend2 = ui.createExpendBar(nextConf.need[2].id,nextConf.need[2].num)
            --expend1:setPosition(188,)

        end
    elseif type == 1 then
        for k, v in pairs(airData.mine) do
            if v.pos == pos then
                id = math.floor(id / 1000) * 1000
                break
            end
        end
        data = clone(airConf[id + maxLv])
        data.id = id + maxLv
        maxUI = ui.createBuildBox(type, data)
        maxUI:setPosition(324, 260)
        bg:addChild(maxUI)
    elseif type == 2 then
        for k, v in pairs(airData.holy) do
            if v.pos == pos then
                id = math.floor(id / 1000) * 1000
                break
            end
        end
        data = clone(airConf[id + maxLv])
        data.id = id + maxLv
        maxUI = ui.createBuildBox(type, data)
        maxUI:setPosition(324, 260)
        bg:addChild(maxUI)
    end


    closeBtn:registerScriptTapHandler(function ()
        print("关闭")
        audio.play(audio.button)
        layer:removeFromParent()
    end)
end

-- 创建一个消耗物条
function ui.createExpendBar(id,num)
    local bar = img.createUI9Sprite(img.ui.hero_evolve_cost_bg)
    bar:setPreferredSize(CCSizeMake(200, 32))
    local label = lbl.createFont1(24, num, ccc3(0xe6, 0xd0, 0xae))
    label:setPosition(106,15)
    bar:addChild(label)
    local icon = img.createItemIcon(id)
    icon:setPosition(2,15)
    bar:addChild(icon)
    return bar
end

-- 创建一个建筑信息小框(type 0--主城 1--矿物 2--圣物)
function ui.createBuildBox(type,confData,isBgDark)
    print("---------")
    tablePrint(confData)
    -- 背景图
    local bg
    if isBgDark then
        bg = img.createUI9Sprite(img.ui.botton_fram_3)
    else
        bg = img.createUI9Sprite(img.ui.botton_fram_2)
    end
    bg:setPreferredSize(CCSizeMake(280, 210))
    -- 分割线
    local line = img.createUI9Sprite(img.ui.split_line)
    line:setPreferredSize(CCSizeMake(234, 1))
    line:setPosition(140,90)
    bg:addChild(line)
    -- 信息文本
    local label = {}
    for i = 1, 4 do
        local text = lbl.createFont1(24, "--", ccc3(0x59, 0x30, 0x1b))
        text:setAnchorPoint(ccp(0, 0.5))
        text:setPosition(20,25 + (i - 1) * 20)
        bg:addChild(text)
        table.insert(label,text)
    end
    -- 建筑等级
        --local lvBg = img.createUISprite(img.ui.airisland_lvbg)
    --lvBg:setPosition(140,106)
    --bg:addChild(lvBg,2)
    --local lvLabel = lbl.createFont2(16, "Lv." .. confData.lv, ccc3(255, 255, 255))
    --lvLabel:setPosition(lvBg:getContentSize().width / 2,lvBg:getContentSize().height / 2)
    --lvBg:addChild(lvLabel)
    -- 建筑图标
    local buildImg
    if type == 0 then
        local numStr = {confData.pit,confData.plat,confData.land,confData.xMax}
        buildImg = img.createUISprite(img.ui["airisland_maintower_" .. confData.show])
        buildImg:setScale(0.65)
        buildImg:setPosition(160,150)
        bg:addChild(buildImg)
        for i, v in ipairs(label) do
            v:setString("----"..numStr[i])
        end
    elseif type == 1 then
        local numStr = {confData.max, confData.give.num}
        if confData.id > 2000 and confData.id < 3000 then
            -- 金矿
            buildImg = img.createUISprite(img.ui["airisland_gold_".. confData.show])
        elseif confData.id > 3000 and confData.id < 4000 then
            -- 钻石矿
            buildImg = img.createUISprite(img.ui["airisland_diamond_".. confData.show])
        elseif confData.id > 4000 and confData.id < 5000 then
            -- 魔法之尘
            buildImg = img.createUISprite(img.ui["airisland_magic_".. confData.show])
        end
        bg:setPreferredSize(CCSizeMake(280, 180))
        buildImg:setPosition(140, 145)
        buildImg:setScale(0.72)
        bg:addChild(buildImg)
        line:setPositionY(66)
        lvBg:setPositionY(86)
        for i, v in ipairs(label) do
            if i > 2 then
                v:setVisible(false)
            else
                v:setString("------"..numStr[i])
            end
        end
    elseif type == 2 then
        if confData.id > 5000 and confData.id < 6000 then
            -- 丰收圣物
            buildImg = img.createUISprite(img.ui["airisland_bumper_".. confData.show])
        elseif confData.id > 6000 and confData.id < 7000 then
            -- 活力圣物
            buildImg = img.createUISprite(img.ui["airisland_energy_".. confData.show])
        elseif confData.id > 7000 and confData.id < 8000 then
            -- 迅捷圣物
            buildImg = img.createUISprite(img.ui["airisland_fast_".. confData.show])
        elseif confData.id > 8000 and confData.id < 9000 then
            -- 暴君圣物
            buildImg = img.createUISprite(img.ui["airisland_tyrant_".. confData.show])
        elseif confData.id > 9000 and confData.id < 10000 then
            -- 血月圣物
            buildImg = img.createUISprite(img.ui["airisland_moon_".. confData.show])
        end
        bg:setPreferredSize(CCSizeMake(280, 180))
        buildImg:setPosition(140, 145)
        buildImg:setScale(0.72)
        bg:addChild(buildImg)
        line:setPositionY(66)
        --lvBg:setPositionY(86)
        for i, v in ipairs(label) do
            if i > 1 then
                v:setVisible(false)
            else
                local num = confData.add or confData.effect[1].num or confData.give.num
                v:setString("------"..num)
            end
        end
    end

    return bg
end

return ui
