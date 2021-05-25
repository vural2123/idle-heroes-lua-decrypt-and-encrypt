-- 宠物战斗界面
local ui = {}

require "common.func"

local view          = require "common.view"
local img           = require "res.img"
local lbl           = require "res.lbl"
local json          = require "res.json"
local audio         = require "res.audio"
local i18n          = require "res.i18n"
local net           = require "net.netClient"
local petdata       = require "config.pet"
local DHComponents  = require "dhcomponents.DroidhangComponents"
local petNetData    = require "data.pet"
local userdata      = require "data.userdata"
local Tag           = 100
local sele = {}

function ui.create(layer, petCallBack)

    ui.data = {}
    ui.widget = {}
    ui.widget.Card = {}

    --添加卡牌,为保证顺序排序
    local petKey = {}
    local petNum = 0
    for k,v in pairs(petdata) do
        petNum = petNum + 1 
        table.insert(petKey,k)
    end
    table.sort(petKey)

    --载入魔兽的图片
    for i=1,petNum do
        local myId = petKey[i]
        local name = string.gsub(petdata[myId]["petBody"],"pet_","")
        name = string.gsub(name,"_","")
        local fixName = petNetData.getData(myId) == nil and 1 or petNetData.getData(myId).advanced
        img.load(img.packedOthers["spine_ui_"..name..fixName])
    end

    --主要层
    ui.widget.layer = CCLayer:create()
    ui.widget.layer:setPosition(CCPoint(0,0))
    layer:addChild(ui.widget.layer,999)

    --灰底
    local darkBg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    ui.widget.layer:addChild(darkBg)
    darkBg:setTouchEnabled(true)
    darkBg:registerScriptTouchHandler(function (event,x,y)
        return false
    end)

    --主要背景
    ui.widget.bg = img.createLogin9Sprite(img.login.dialog)                    
    ui.widget.bg:setPreferredSize(CCSize(900, 500))
    ui.widget.bg:setAnchorPoint(CCPoint(0.5,0.5))
    ui.widget.bg:setPosition(CCPoint(view.midX, view.midY))
    ui.widget.layer:addChild(ui.widget.bg)
    ui.widget.bg:setScale(0.7*view.minScale)

    --缩放动作
    local anim_arr = CCArray:create()
    anim_arr:addObject(CCScaleTo:create(0.12, 1.1*view.minScale, 1.1*view.minScale))
    anim_arr:addObject(CCScaleTo:create(0.09, 1*view.minScale, 1*view.minScale))
    ui.widget.bg:runAction(CCSequence:create(anim_arr))

    --标题
    local title = lbl.createFont1(24, i18n.global.pet_battle_title.string, ccc3(0xe6, 0xd0, 0xae))
    ui.widget.bg:addChild(title,2)

    --后面有点影子
    local titleShade = lbl.createFont1(24, i18n.global.pet_battle_title.string, ccc3(0x59, 0x30, 0x1b))
    ui.widget.bg:addChild(titleShade,1)

    --描述
    local doc = lbl.createFont1(18, i18n.global.pet_battle_doc.string, ccc3(0x60, 0x2c, 0x0f))
    ui.widget.bg:addChild(doc)

    --返回按钮
    ui.widget.backBtn = SpineMenuItem:create(json.ui.button, img.createUISprite(img.ui.close))
    local menuPet = CCMenu:createWithItem(ui.widget.backBtn)
    menuPet:setPosition(0, 0)
    ui.widget.bg:addChild(menuPet)

    --内部框
    local board = img.createUI9Sprite(img.ui.bag_btn_inner_bg)
    board:setPreferredSize(CCSizeMake(844, 360))
    ui.widget.bg:addChild(board)

    ui.widget.Scroll = CCScrollView:create()
    ui.widget.Scroll:setAnchorPoint(CCPoint(0.5,0.5))
    ui.widget.Scroll:setPosition(CCPoint(10,0))
    ui.widget.Scroll:setDirection(kCCScrollViewDirectionHorizontal)
    ui.widget.Scroll:setViewSize(CCSize(822,500))
    ui.widget.Scroll:setContentSize(CCSize(175 * petNum,500))
    ui.widget.Scroll:setTouchEnabled(true)
    ui.widget.Scroll:setCascadeOpacityEnabled(true)
    ui.widget.Scroll:getContainer():setCascadeOpacityEnabled(true)
    board:addChild(ui.widget.Scroll)

    --创建卡片
    ui.widget.Card = {}
    for i=1,petNum do
        ui.createCard(petKey[i], ui.widget.Scroll)
    end

    ui.refreshCard()
    ui.widget.backBtn:registerScriptTapHandler(function()
        if ui.widget.layer ~= nil then
            audio.play(audio.button)
            petCallBack()
            ui.widget.layer:removeFromParent()
            ui.data = {}
            ui.widget = {}

            --卸载魔兽的图片
            for i=1,petNum do
                local myId = petKey[i]
                local name = string.gsub(petdata[myId]["petBody"],"pet_","")
                name = string.gsub(name,"_","")
                local fixName = petNetData.getData(myId) == nil and 1 or petNetData.getData(myId).advanced
                img.unload(img.packedOthers["spine_ui_"..name..fixName])
            end
        end
    end)

    --每帧调用的函数
    --检测卡牌位置隐藏card，用于解决底层滚动视图，将用于裁剪的滚动层滚动到屏幕外擅自取消裁剪的问题
    local function onUpdate()
        ui.checkCard()
    end
    ui.widget.bg:scheduleUpdateWithPriorityLua(onUpdate)

    DHComponents:mandateNode(ui.widget.backBtn,"yw_petBattle_backBtn")
    DHComponents:mandateNode(board,"yw_petBattle_board")
    DHComponents:mandateNode(title,"yw_petBattle_title")
    DHComponents:mandateNode(titleShade,"yw_petBattle_titleShade")
    DHComponents:mandateNode(doc,"yw_petBattle_doc")
	return ui.widget
end

function ui.initData(hids)
    sele[1] = hids[19] or -1
    sele[2] = hids[20] or -1
    sele[3] = hids[21] or -1
end

function ui.getNowSele( hids )
    hids[19] = sele[1]
    hids[20] = sele[2]
    hids[21] = sele[3]
end

function ui.checkNumNow(id)
    print("checkNumNow id == "..id)
    for k,v in pairs(sele) do
        if v == -1 then
            sele[k] = id
            print("checkNumNow sele[k] == "..k)
            return
        end
    end
    showToast(string.format(i18n.global.pet_sele_is_max.string))
end

function ui.addPetData(data)    
    if sele[1] ~= -1 then
        local petSele_1 = {}
        petSele_1.id = sele[1]
        petSele_1.pos = 19
        table.insert(data,petSele_1)
    end

    if sele[2] ~= -1 then
        local petSele_2 = {}
        petSele_2.id = sele[2]
        petSele_2.pos = 20
        table.insert(data,petSele_2)
    end

    if sele[3] ~= -1 then
        local petSele_3 = {}
        petSele_3.id = sele[3]
        petSele_3.pos = 21
        table.insert(data,petSele_3)
    end

    return data
end

--返回宠物ID，没有返回空
function ui.findNum(num)
    if sele[num] == -1 then
        return nil
    end
    return sele[num]
end

function ui.changeNum(change1,change2)
    local changeKey1 = sele[change1]
    local changeKey2 = sele[change2]
    sele[change1] = changeKey2
    sele[change2] = changeKey1
end

--创建每个cardItem
function ui.createCard(id, Scroll)
    if petdata[id] == nil then
        showToast(string.format("pet error id"))
        return
    end
    ui.widget.Card[id] = {}
    ui.widget.Card[id].cardLayer = CCLayer:create()
    ui.widget.Card[id].cardLayer:setPosition(CCPoint(0,0))
    Scroll:addChild(ui.widget.Card[id].cardLayer)

    local path = img.ui.pet_card
    if petNetData.getData(id) ~= nil and (petNetData.getData(id).advanced == 2 or petNetData.getData(id).advanced == 3) then
        path = img.ui["pet_card2"]
    elseif petNetData.getData(id) ~= nil and petNetData.getData(id).advanced == 4 then
        path = img.ui["pet_card3"] 
    end

    local cardBg = img.createUISprite(path)
    cardBg:setPosition(CCPoint(0,0))
    cardBg:setScale(0.5) -- 152
    ui.widget.Card[id].cardBg = cardBg
    ui.widget.Card[id].cardLayer:addChild(cardBg)
    
    --创建按钮部分,未出战，要求出战按钮
    local battleSp = img.createLogin9Sprite(img.login.button_9_small_gold)
    battleSp:setPreferredSize(CCSize(150, 50))
    ui.widget.Card[id].battleSp = battleSp

    local battleLab = lbl.createFont1(18, i18n.global.pet_battle_out.string, ccc3(0x76, 0x25, 0x05))
    battleLab:setPosition(battleSp:getContentSize().width/2, battleSp:getContentSize().height/2 + 2)
    battleSp:addChild(battleLab)
    ui.widget.Card[id].battleLab = battleLab

    ui.widget.Card[id].battleItem = SpineMenuItem:create(json.ui.button, battleSp)
    local battleMenu = CCMenu:createWithItem(ui.widget.Card[id].battleItem)
    battleMenu:setPosition(CCPoint(0,0))
    ui.widget.Card[id].cardLayer:addChild(battleMenu)
    ui.widget.Card[id].battleMenu = battleMenu

    --出战取消按钮
    local battleCancelSp = img.createLogin9Sprite(img.login.button_9_small_orange)
    battleCancelSp:setPreferredSize(CCSize(150, 50))
    ui.widget.Card[id].battleCancelSp = battleCancelSp

    local battleCancelLab = lbl.createFont1(18, i18n.global.pet_battle_cancel.string, ccc3(0x76, 0x25, 0x05))
    battleCancelLab:setPosition(battleCancelSp:getContentSize().width/2, battleCancelSp:getContentSize().height/2 + 2)
    battleCancelSp:addChild(battleCancelLab)
    ui.widget.Card[id].battleCancelLab = battleCancelLab

    ui.widget.Card[id].battleCancelItem = SpineMenuItem:create(json.ui.button, battleCancelSp)
    local battleCancelMenu = CCMenu:createWithItem(ui.widget.Card[id].battleCancelItem)
    battleCancelMenu:setPosition(CCPoint(0,0))
    ui.widget.Card[id].cardLayer:addChild(battleCancelMenu)
    ui.widget.Card[id].battleCancelMenu = battleCancelMenu

    local imgStar = 1 
    if petNetData.getData(id) then
        imgStar = petNetData.getData(id).star + 1
    end
    --创建图片
    local cardMain = img.createUISprite(img.ui[petdata[id]["petBody"]..imgStar])
    ui.widget.Card[id].cardMain = cardMain

    cardMain:setPosition(CCPoint(cardMain:getContentSize().width/2, cardMain:getContentSize().height/2))
    cardBg:addChild(cardMain,-1)

    --创建骨骼动画
    local name = string.gsub(petdata[id]["petBody"],"pet_","spine_")
    local fixName = petNetData.getData(id) == nil and 1 or petNetData.getData(id).advanced
    local petSpine = ui.createJsonCard(json.ui[name..fixName],id)
    cardMain:addChild(petSpine)

    DHComponents:mandateNode(ui.widget.Card[id].cardLayer,"yw_petBattle_cardBg"..id)
    DHComponents:mandateNode(ui.widget.Card[id].battleItem,"yw_petBattle_battleItem")
    DHComponents:mandateNode(ui.widget.Card[id].battleCancelItem,"yw_petBattle_battleItem")
    
    ui.widget.Card[id].battleItem:registerScriptTapHandler(function()
        audio.play(audio.button)
        ui.battleItemTouch(id)
    end)

    ui.widget.Card[id].battleCancelItem:registerScriptTapHandler(function()
        audio.play(audio.button)
        ui.battleItemTouchCancel(id)
    end)
end

--创建骨骼动画
function ui.createJsonCard(key)
    local stencil = img.createUISprite(img.ui.pet_deer_1)
    stencilSize = stencil:getContentSize()
    local mySize = CCSize(stencilSize.width-20,stencilSize.height-40)

    local Scroll = CCScrollView:create()
    Scroll:setAnchorPoint(CCPoint(0.5,0.5))
    Scroll:setPosition(10,15)
    Scroll:setDirection(kCCScrollViewDirectionHorizontal)
    Scroll:setViewSize(mySize)
    Scroll:setContentSize(mySize)
    Scroll:setTouchEnabled(false)
    Scroll:setCascadeOpacityEnabled(true)
    Scroll:getContainer():setCascadeOpacityEnabled(true)   

    local rightAnimBg = json.create(key)
    rightAnimBg:setPosition(stencilSize.width/2,0)
    rightAnimBg:playAnimation("stand", -1)
    Scroll:addChild(rightAnimBg)
    return Scroll
end

function ui.checkCard()
    --防御性检测，避免玩家手速太快，一边滑动，一边关闭
    if ui.widget.Scroll == nil then
        return
    end

    local posX = ui.widget.Scroll:getContentOffset().x
    local view_w = ui.widget.Scroll:getViewSize().width
    local nowOff = 70

    for k,v in pairs(ui.widget.Card) do
        if v.cardLayer:getPositionX() + nowOff + posX < 0 then
            v.cardLayer:setVisible(false)
        elseif v.cardLayer:getPositionX() - view_w - nowOff + posX > 0 then
            v.cardLayer:setVisible(false)
        else
            v.cardLayer:setVisible(true)
        end
    end
end

function ui.battleItemTouchCancel(id)
    print("ui.isSele(id) = "..ui.isSele(id))
    if ui.isSele(id) ~= -1 then
        sele[ui.isSele(id)] = -1
    end
    tablePrint(sele)
    ui.refreshCard()
end

function ui.battleItemTouch(id)
    --报错逻辑
    if petNetData.getData(id) == nil then
        showToast(string.format(i18n.global.pet_need_act.string))
        return
    end
    
    ui.checkNumNow(id)
    ui.refreshCard()
end

function ui.isSele(id)
    for k,v in pairs(sele) do
        if sele[k] == id then
            return k
        end
    end
    return -1
end

function ui.refreshCard()
    if ui.widget.Card == nil then
        return
    end

    for id,val in pairs(ui.widget.Card) do
        --如果没有数据，置灰
        print("refreshCard id =="..id)
        print("refreshCard isSele =="..ui.isSele(id))
        if petNetData.getData(id) == nil then
            ui.widget.Card[id].battleCancelItem:setVisible(false)
            setShader(ui.widget.Card[id].battleMenu , SHADER_GRAY, true)
            setShader(ui.widget.Card[id].cardBg     , SHADER_GRAY, true)
            setShader(ui.widget.Card[id].cardMain   , SHADER_GRAY, true)
        elseif ui.isSele(id) == -1 then
            --清理置灰
            ui.widget.Card[id].battleItem:setVisible(true)
            ui.widget.Card[id].battleMenu:setTouchEnabled(true) 
            ui.widget.Card[id].battleCancelItem:setVisible(false)
            ui.widget.Card[id].battleCancelItem:setTouchEnabled(false) 
            ui.widget.Card[id].cardLayer:removeChildByTag(Tag)
            local sp = ui.widget.Card[id].cardLayer:getChildByTag(Tag)
            if sp ~= nil then
                sp:removeFromParent()
            end
            clearShader(ui.widget.Card[id].cardBg     , true)
            clearShader(ui.widget.Card[id].cardMain   , true) 

            if ui.widget.Card[id].color ~= nil then
                ui.widget.Card[id].color:removeFromParent()
                ui.widget.Card[id].color = nil
            end
        --选中状态
        else
            ui.widget.Card[id].battleCancelItem:setVisible(true)
            ui.widget.Card[id].battleCancelMenu:setTouchEnabled(true) 
            ui.widget.Card[id].battleItem:setVisible(false)
            ui.widget.Card[id].battleItem:setTouchEnabled(false)


            if ui.widget.Card[id].color == nil then
                ui.widget.Card[id].color = CCLayerColor:create(ccc4(0, 0, 0, 120))
                ui.widget.Card[id].color:setContentSize(CCSize(ui.widget.Card[id].cardMain:getContentSize().width-20, ui.widget.Card[id].cardMain:getContentSize().height-36))
                ui.widget.Card[id].cardMain:addChild(ui.widget.Card[id].color)
                ui.widget.Card[id].color:setPosition(CCPoint(9,11))
            end

            if ui.widget.Card[id].cardLayer:getChildByTag(Tag) == nil then
                for k,v in pairs(sele) do
                    if v == id then
                        local battleSpine = json.create(json.ui.pet_play_json)
                        ui.widget.Card[id].cardLayer:addChild(battleSpine,10,Tag)
                        battleSpine:playAnimation(""..k)
                    end 
                end 
                
            end
        end
    end
end

return ui