--需要复用,写法有点不一样
local ui = {}

require "common.func"

local view = require "common.view"
local img = require "res.img"
local json = require "res.json"
local lbl = require "res.lbl"
local i18n = require "res.i18n"
local pet = require "ui.pet.main"
local petConf = require "config.pet"
local netClient = require "net.netClient"
local player = require "data.player"
local bag = require "data.bag"
local petNetData = require "data.pet"

function ui.create(petJson,id,data)
	--会出现不同对象的用此写法,保证create出的每张表的数据不共享
	local obj = {}
	obj.data = {}
	obj.widget = {}
    obj.data.id = id
	obj.data.info = data
	--主节点
	obj.widget.node = CCNode:create()
	obj.widget.node:setContentSize(CCSize(304*0.8,455*0.8))
    obj.widget.node:setCascadeOpacityEnabled(true)

	--战宠图片
    local name =  string.gsub(petConf[id]["petBody"],"pet_","spine_")  
    if data ~= nil then
        --加1是因为服务器不是lua语言，起始数据都认为是0，但是lua是1
        obj.widget.petPic = img.createUISprite(img.ui[petConf[id].petBody..(data.star+1)])
        obj.widget.pet_spine = ui.createJsonCard(json.ui[name..petNetData.getData(id).advanced],id)
        obj.widget.petPic:addChild(obj.widget.pet_spine)
    else
        print("----------"..img.ui[petConf[id].petBody.."1"] .."-------")
        obj.widget.petPic = img.createUISprite(img.ui[petConf[id].petBody.."1"])
        obj.widget.pet_spine = ui.createJsonCard(json.ui[name..1],id)
        obj.widget.petPic:addChild(obj.widget.pet_spine)
    end
    --drawBoundingbox(obj.widget.petPic, obj.widget.pet_spine)

    obj.widget.petPic:setScaleX(0.8)
    obj.widget.petPic:setScaleY(0.8)
    obj.widget.petPic:setCascadeOpacityEnabled(true)
	obj.widget.node:addChild(obj.widget.petPic,10)

    local searchBtn = SpineMenuItem:create(json.ui.button, img.createUISprite(img.ui.pet_search))
    searchBtn:setScale(0.9)
    searchBtn:setAnchorPoint(ccp(1, 1))
    searchBtn:setPosition(CCPoint(obj.widget.node:getContentSize().width/2-20,obj.widget.node:getContentSize().height/2-20))
    local searchMenu = CCMenu:createWithItem(searchBtn)
    searchMenu:setPosition(0, 0)
    obj.widget.node:addChild(searchMenu,11)
    --激活按钮点击响应
    searchBtn:registerScriptTapHandler(function()        
        local petDetails = require("ui.pet.petDetails").create(id)
        local parentLayer = obj.widget.node:getParent():getParent():getParent():getParent():getParent():getParent():getParent()
        parentLayer:addChild(petDetails,9999)
    end)

    --边框
    local path = img.ui.pet_card
    if data and (petNetData.getData(id).advanced == 2 or petNetData.getData(id).advanced == 3) then
        path = img.ui["pet_card2"]
    elseif data and petNetData.getData(id).advanced == 4 then
        path = img.ui["pet_card3"] 
    end
    obj.widget.qualityBox = img.createUISprite(path)
    obj.widget.qualityBox:setScaleX(0.8)
    obj.widget.qualityBox:setScaleY(0.8)
    obj.widget.qualityBox:setPosition(obj.widget.petPic:getPosition())
    obj.widget.node:addChild(obj.widget.qualityBox,20)
	if data == nil then
		setShader(obj.widget.petPic, SHADER_GRAY, true)
        obj.data.info = ui.setConfig(id)
		--激活按钮
		obj.widget.actBtn = ui.createActBtn(obj,id,obj.data.info,petJson)
		obj.widget.node:addChild(obj.widget.actBtn)
	else
		obj.widget.detBtn = ui.createDetBtn(obj,id,obj.data.info)
		obj.widget.node:addChild(obj.widget.detBtn)
	end
    
	return obj
end

--创建新的卡牌的骨骼动画
function ui.createJsonCard(key,id)
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

--创建激活按钮
function ui.createActBtn(obj,petId,data,petJson)
    local itemId = petConf[petId]["activaty"][1]
    local itemNum = petConf[petId]["activaty"][2]
    local itemActivaty = petConf[petId]["activaty"]
    tablePrint(itemActivaty)

	local activateImg = img.createUI9Sprite(img.ui.btn_7)
	activateImg:setPreferredSize(CCSizeMake(190,65))
    local activateBtn = SpineMenuItem:create(json.ui.button, activateImg)
    local activateMenu = CCMenu:createWithItem(activateBtn)
    activateMenu:setPosition(0, 0)

    --网络通讯,宠物激活
    local netFun = function(itemId,itemNum)
        local params = { sid = player.sid, id = petId, opcode = 1}
        addWaitNet()
        netClient:pet_op(params, function (data)
            if data.status == 0 then
                pet.subItem({{["type"]=itemId,["count"]=itemNum}})
                ui.playActiveJson(obj)
                obj.widget.detBtn = ui.createDetBtn(obj,petId,data)
                obj.widget.node:addChild(obj.widget.detBtn)
                clearShader(obj.widget.petPic,true)
                activateBtn:removeFromParent()
                obj.widget.actBtn = nil
            end
            petNetData.coutRsult(1,data.status)
            delWaitNet()
        end)
    end
    --激活按钮点击响应
    activateBtn:registerScriptTapHandler(function()        
        if bag.items.find(itemId).num >= itemNum then
            petNetData.addData(petId)
            netFun(itemId,itemNum)
        else
            showToast(string.format(i18n.global.pet_smaterial_not_enough.string))
        end
    end)

    --小图标
    local goldIcon = img.createItemIcon2(itemId)
    goldIcon:setPosition(37, 32)
    activateImg:addChild(goldIcon)
    --激活的数量标签
   	local activeLabel = lbl.createFont2(16, itemNum) 
    activeLabel:setPosition(37, 20)
    activateImg:addChild(activeLabel)
    --激活字样标签
    local strLabel = lbl.createFont1(18,i18n.global.pet_activate.string,ccc3(0x17,0x53,0x0a))
    strLabel:setPosition(110,33)
    activateImg:addChild(strLabel)

	local DHComponents = require("dhcomponents.DroidhangComponents")
    DHComponents:mandateNode(activateBtn,"DAui_aiLhPV")
    activateMenu.itemId = itemId
    activateMenu.itemNum = itemNum

    return activateMenu
end

--创建查看按钮
function ui.createDetBtn(obj,id,data)
	local detailsImg = img.createUI9Sprite(img.ui.btn_1)
	detailsImg:setPreferredSize(CCSizeMake(190,65))
    local detailsBtn = SpineMenuItem:create(json.ui.button, detailsImg)
    local detailsMenu = CCMenu:createWithItem(detailsBtn)
    detailsMenu:setPosition(0, 0)
    detailsBtn:registerScriptTapHandler(function()
        require("ui.pet.main").gotoPetInfo(petNetData.getData(id))
    end)
    --添加特效
    if data.advanced == 4 then
   	    local lightJson = json.create(json.ui.pet_json)
        --lightJson:setScale(view.minScale)
        lightJson:setPositionX(obj.widget.petPic:getPositionX())
        lightJson:setPositionY(obj.widget.petPic:getPositionY())
        lightJson:setScaleY(0.98)
        lightJson:playAnimation(petConf[id].petEff,-1)
        obj.widget.node:addChild(lightJson,10)
    end
    
    --查看字样标签
    local strLabel = lbl.createFont1(18,i18n.global.pet_details.string,ccc3(0x72,0x3b,0x0f))
    strLabel:setPosition(95,33)
    detailsImg:addChild(strLabel)

    local DHComponents = require("dhcomponents.DroidhangComponents")
    DHComponents:mandateNode(detailsBtn,"DAui_aiLhPV")

    return detailsMenu
end

--设置配置为默认配置
function ui.setConfig(id)
    local data = {}
    data.id         = id
    data.lv         = 1
    data.advanced   = 1
    --data.star       = 0
    --data.buffLv     = {}
    --data.buffLv[1]  = 1
    --data.skl        = {}
    --data.skl        = petConf[id].pasSkillId[1]
    return data
end

--播放激活特效
function ui.playActiveJson(obj)
	local activeJson = json.create(json.ui.pet_json)
   	activeJson:setPositionX(obj.widget.petPic:getPositionX())
    activeJson:setPositionY(obj.widget.petPic:getPositionY())
   	activeJson:playAnimation("unlock")
   	obj.widget.node:addChild(activeJson,9999)
end

return ui