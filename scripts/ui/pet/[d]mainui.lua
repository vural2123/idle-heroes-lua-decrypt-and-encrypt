-- 战宠UI
local ui = {}

require "common.func"

local view = require "common.view"
local img = require "res.img"
local json = require "res.json"
local lbl = require "res.lbl"
local audio = require "res.audio"
local i18n = require "res.i18n"
local net = require "net.netClient"
local petdata = require "config.pet"
local scrollUI = require "ui.pet.scrollUI"
local cardClass = require "ui.pet.card"
local petNetData = require "data.pet"

function ui.create(petJson)
    ui.data = {}
    ui.widget = {}
    
    ui.data.leftOrder = 1   --当前展示的三张牌最左边的牌的序号
    ui.data.totalCards = 0  --卡牌总数
    ui.data.touchX = -100   --触摸开始时候触摸点的横坐标
    ui.data.isMove = false --正在移动

	--添加滚动容器
	ui.widget.scrollView = scrollUI.create()
    ui.widget.scrollView:setPosition(CCPoint(-400,-270))
    petJson:addChildFollowSlot("code_card_position", ui.widget.scrollView )

    --添加触摸层
    ui.widget.touchLayer = CCLayer:create()
    ui.widget.touchLayer:setContentSize(800,400)
    ui.widget.touchLayer:setPosition(CCPoint(0,80))
    ui.widget.touchLayer:setTouchEnabled(true)
    ui.widget.scrollView:addChild(ui.widget.touchLayer,-1)

    --添加卡牌,为保证顺序排序
    local petKey = {}
    local petNum = 0
    for k,v in pairs(petdata) do
        petNum = petNum + 1 
        table.insert(petKey,k)
    end
    table.sort(petKey)

    ui.data.totalCards = petNum
	for i=1,ui.data.totalCards do
        local haveCard = false
        for k,v in pairs(petNetData.data) do
            if v["id"] == petKey[i] then
                local card = cardClass.create(petJson,petKey[i],v)
                scrollUI.addCard(card, 20 - i)
                haveCard = true
                break
            end
        end
        if not haveCard then
            local card = cardClass.create(petJson,petKey[i])
            scrollUI.addCard(card,20-i)
        end
	end
	--添加箭头按钮
	ui.widget.leftArrow = img.createUISprite(img.ui.hero_raw)
    ui.widget.leftArrow:setScaleX(-1)
    ui.widget.leftArrowBtn = SpineMenuItem:create(json.ui.button, ui.widget.leftArrow)

    local leftMenu = CCMenu:createWithItem(ui.widget.leftArrowBtn)
    leftMenu:setPosition(0, 0)
    petJson:addChildFollowSlot("code_arrow_position2", leftMenu )
    setShader(ui.widget.leftArrowBtn, SHADER_GRAY, true)
    
    ui.widget.rightArrow = img.createUISprite(img.ui.hero_raw)
    ui.widget.rightArrow:setScaleX(-1)
    ui.widget.rightArrowBtn = SpineMenuItem:create(json.ui.button, ui.widget.rightArrow)
    local rightMenu = CCMenu:createWithItem(ui.widget.rightArrowBtn)
    rightMenu:setPosition(0, 0)
    petJson:addChildFollowSlot("code_arrow_position", rightMenu )

	local DHComponents = require("dhcomponents.DroidhangComponents")
    ui.CallFun()

    --每帧调用的函数
    --检测卡牌位置隐藏card，用于解决底层滚动视图，将用于裁剪的滚动层滚动到屏幕外擅自取消裁剪的问题
    local function onUpdate()
        scrollUI.checkCard()
    end
    ui.widget.touchLayer:scheduleUpdateWithPriorityLua(onUpdate)

	return ui.widget
end

--强制移动，用于返回的时候的标记
function ui.forceMove()
    if ui.dirNum == nil then
        return
    elseif ui.dirNum == 2 then
        scrollUI.moveDir(-2, ui.widget.leftArrowBtn, 0.01)
        ui.dirNum = 0
        ui.changeArrowState(2)
    elseif ui.dirNum == 4 then
        scrollUI.moveDir(-4, ui.widget.leftArrowBtn, 0.01)
        ui.dirNum = 0
        ui.changeArrowState(4)
    elseif ui.dirNum == 6 then
        scrollUI.moveDir(-6, ui.widget.leftArrowBtn, 0.01)
        ui.dirNum = 0
        ui.changeArrowState(6)
    end
end

--删除该层函数
function ui.clear( petJson )
    petJson:removeChildFollowSlot("code_card_position")
    petJson:removeChildFollowSlot("code_arrow_position")
    petJson:removeChildFollowSlot("code_arrow_position2")
    ui.data = nil
    ui.widget = nil
end

function ui.CallFun()
    --左箭头点击
    ui.widget.leftArrowBtn:registerScriptTapHandler(function()

        if ui.data.leftOrder <= 1 then
            --到底无法再移动
            return
        end

        --给移动一点时间
        if ui.data.isMove == true then
            return
        end

        ui.data.isMove = true
        ui.widget.scrollView:runAction(CCSequence:createWithTwoActions(
        CCDelayTime:create(0.3),
        CCCallFunc:create(function() 
            ui.data.isMove = false 
            end)))

        audio.play(audio.button)
        scrollUI.moveDir(2,ui.widget.leftArrowBtn)
        ui.changeArrowState(-2)

    end)
    
    --右箭头点击
    ui.widget.rightArrowBtn:registerScriptTapHandler(function()
        if ui.data.leftOrder >= ui.data.totalCards - 2 then
            --到底无法再移动
            return
        end
        --给移动一点时间
        if ui.data.isMove == true then
            return
        end

        ui.data.isMove = true
        ui.widget.scrollView:runAction(CCSequence:createWithTwoActions(
        CCDelayTime:create(0.3),
        CCCallFunc:create(function() 
            ui.data.isMove = false 
            end)))

        audio.play(audio.button)
        scrollUI.moveDir(-2,ui.widget.rightArrowBtn)
        ui.changeArrowState(2)
    end)
    
    --触摸层点击
    ui.widget.touchLayer:registerScriptTouchHandler(function (event,x,y)
        if event == "began" then
            if not ui.widget.touchLayer:getBoundingBox():containsPoint(CCPoint(x,y)) then
                return false
            end
            ui.data.touchX = x
            return true
        elseif event == "ended" then
            local difX = x - ui.data.touchX
            if difX > 5 and ui.data.leftOrder > 1 then
                scrollUI.moveDir(2,ui.widget.leftArrowBtn)
                ui.changeArrowState(-2)
                scrollUI.checkCard()
            elseif difX < -5 and ui.data.leftOrder < ui.data.totalCards - 2 then
                scrollUI.moveDir(-2,ui.widget.rightArrowBtn)
                ui.changeArrowState(2)
            end
        end
    end)
end

--根据情况改变左右箭头的显示
function ui.changeArrowState(dirNum)
    ui.widget.leftArrowBtn:setVisible(true)
    ui.widget.rightArrowBtn:setVisible(true)
    
    clearShader(ui.widget.leftArrowBtn, true)
    clearShader(ui.widget.rightArrowBtn, true)

    ui.data.leftOrder = ui.data.leftOrder + dirNum
    ui.dirNum = (ui.dirNum or 0) + dirNum

    if ui.data.leftOrder <= 1 then
        setShader(ui.widget.leftArrowBtn, SHADER_GRAY, true)

    elseif ui.data.leftOrder >= ui.data.totalCards - 2 then
        setShader(ui.widget.rightArrowBtn, SHADER_GRAY, true)
    end
end

return ui
