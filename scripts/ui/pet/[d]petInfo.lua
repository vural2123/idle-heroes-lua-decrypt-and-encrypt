-- 战宠UI by yw
local ui = {}

require "common.func"
require "common.const"
local view          = require "common.view"
local img           = require "res.img"
local json          = require "res.json"
local lbl           = require "res.lbl"
local audio         = require "res.audio"
local i18n          = require "res.i18n"
local net           = require "net.netClient"
local petData       = require "config.pet"
local skilldata     = require "config.skill"
local buffdata      = require "config.petskill"
local petExpData    = require "config.exppet"
local DHComponents  = require "dhcomponents.DroidhangComponents"
local netClient     = require "net.netClient"
local player        = require "data.player"
local petNetData    = require "data.pet"
local bagdata       = require "data.bag"
local advancedMax   = 4 --当前标记最高升级星级
local buffMaxLv     = 30 --当前每个BUFF的最高等级认为30

--主要的创建函数，每次调用就重新创建新的数据结构，必须保证上一次的所有控件都删除完毕后才调用。
function ui.create(data , petJson , mainLayer)
	--创建测试数据
	ui.data = {}
	ui.widget = {}
	ui.data = data
    ui.widget.petJson = petJson
    ui.widget.mainLayer = mainLayer
    ui.data.buffEff = 1 --每次默认为1

	--创建一个卡牌框在
    ui.widget.pet_card_layer = CCLayer:create()
    ui.widget.pet_card_layer:setCascadeOpacityEnabled(true)
    ui.widget.pet_card_layer:setPosition(CCPoint(0,0))
    petJson:addChildFollowSlot("code_card_position2", ui.widget.pet_card_layer )

    --[[
    local path = img.ui.pet_card
    if  (petNetData.getData(data.id).advanced == 2 or petNetData.getData(data.id).advanced == 3) then
        path = img.ui["pet_card2"]
    elseif petNetData.getData(data.id).advanced == 4 then
        path = img.ui["pet_card3"] 
    end

	ui.widget.pet_card = img.createUISprite(path)
    ui.widget.pet_card:setPosition(CCPoint(0,0))
    ui.widget.pet_card_layer:addChild(ui.widget.pet_card,20)]]
    
	--创建信息框
	ui.widget.pet_info = img.createLogin9Sprite(img.login.dialog)                    
	ui.widget.pet_info:setPreferredSize(CCSize(470, 455))
    ui.widget.pet_info:setAnchorPoint(CCPoint(0.5,0.5))
    ui.widget.pet_info:setCascadeOpacityEnabled(true)
    petJson:addChildFollowSlot("code_attribute_position", ui.widget.pet_info )

    --创建切换按钮
    ui.widget.info_tag = CCMenuItemSprite:create(img.createUISprite(img.ui.pet_info_unsele) ,nil , img.createUISprite(img.ui.pet_info_sele))
    ui.widget.info_tag:setEnabled(false)
    ui.widget.info_tag:setPosition(CCPoint(0,0))

    ui.widget.buff_tag = CCMenuItemSprite:create(img.createUISprite(img.ui.pet_buff_unsele) ,nil ,img.createUISprite(img.ui.pet_buff_sele))
    ui.widget.buff_tag:setEnabled(true)
    ui.widget.buff_tag:setPosition(CCPoint(0,0))

    local infoMenu = CCMenu:createWithItem(ui.widget.info_tag)
    ui.widget.pet_info:addChild(infoMenu)

    local buffMenu = CCMenu:createWithItem(ui.widget.buff_tag)
    ui.widget.pet_info:addChild(buffMenu)

    --重生按钮
    local btnSp = img.createLogin9Sprite(img.login.button_9_small_orange)
    btnSp:setPreferredSize(CCSize(160, 50))

    local labReStore = lbl.createFont1(18, i18n.global.pet_reStore_btn.string, ccc3(0x76, 0x25, 0x05))
    labReStore:setPosition(btnSp:getContentSize().width/2, btnSp:getContentSize().height/2 + 2)
    btnSp:addChild(labReStore)

    ui.widget.btnReStore = SpineMenuItem:create(json.ui.button, btnSp)
    local menuReStore = CCMenu:createWithItem(ui.widget.btnReStore)
    menuReStore:setPosition(CCPoint(0,0))
    ui.widget.pet_card_layer:addChild(menuReStore,20)

    DHComponents:mandateNode(infoMenu,"yw_petInfo_infoMenu")
    DHComponents:mandateNode(buffMenu,"yw_petInfo_buffMenu")
    DHComponents:mandateNode(ui.widget.btnReStore,"yw_petInfo_btnReStore")
    ui.showMainCard()
   	ui.showInfo(true)
   	ui.showBuff(false)
    ui.CallFun()

    --每帧调用的函数
    local function onUpdate()
        ui.showUpLvNeed()
        ui.showUpBuffNeed()
        --ui.widget.goldLabel:setString(num2KM(bag.coin()))
    end
    ui.widget.pet_card_layer:scheduleUpdateWithPriorityLua(onUpdate)

	return ui.widget
end

--创建新的卡牌的骨骼动画
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

--显示宠物信息界面，如果不存在就创建
function  ui.showInfo( isShow )
    if ui.widget.infoLayer == nil then 
        ui.widget.infoLayer = CCLayer:create()
        ui.widget.infoLayer:setPosition(CCPoint(300,300))
        ui.widget.infoLayer:setCascadeOpacityEnabled(true)
        ui.widget.pet_info:addChild(ui.widget.infoLayer)

        local labInfo = lbl.createFont1(24, i18n.global.pet_info.string, ccc3(0xe6, 0xd0, 0xae))
        ui.widget.infoLayer:addChild(labInfo,2)

        --后面有点影子
        local labInfoShade = lbl.createFont1(24, i18n.global.pet_info.string, ccc3(0x59, 0x30, 0x1b))
        ui.widget.infoLayer:addChild(labInfoShade,1)

        --创建主要信息部分
        local framInfo = img.createUI9Sprite(img.ui.botton_fram_2)
        framInfo:setPreferredSize(CCSizeMake(410, 240))
        framInfo:setAnchorPoint(CCPoint(0, 0))
        ui.widget.infoLayer:addChild(framInfo)

        --创建升级的骨骼动画效果
        ui.widget.infoLvSpine = json.create(json.ui.pet2_json)
        ui.widget.infoLvSpine:setScaleY(0.95)
        ui.widget.infoLvSpine:setScaleX(1.15)
        ui.widget.infoLvSpine:setPosition(-244, -50)
        ui.widget.infoLayer:addChild(ui.widget.infoLvSpine, 50)

        --创建进化部分
        local labAdv = lbl.createFont1(20, i18n.global.pet_advanced.string, ccc3(0x72, 0x3b, 0x0f))
        ui.widget.infoLayer:addChild(labAdv)

        --创建进化部分星星标记
        local starLayer = CCLayer:create()
        starLayer:setContentSize(CCSize(100,50))
        starLayer:setCascadeOpacityEnabled(true)
        ui.widget.infoLayer:addChild(starLayer)

        ui.widget.advStar = {}
        for i=1,advancedMax do
            local advStarBg = img.createUISprite(img.ui.hero_star0)
            advStarBg:setPosition(CCPoint(i*30,0))
            starLayer:addChild(advStarBg)
            
            ui.widget.advStar[i] = img.createUISprite(img.ui.hero_star1)
            ui.widget.advStar[i]:setPosition(CCPoint(i*30,0))
            starLayer:addChild(ui.widget.advStar[i])
        end
        ui.showStar()

        --创建等级部分
        local labLV = lbl.createFont1(20, "LV:", ccc3(0x91, 0x3b, 0x38))
        ui.widget.infoLayer:addChild(labLV)

        ui.widget.petMainLV = lbl.createFont1(20, "/", ccc3(0x50, 0x27, 0x15))
        ui.widget.infoLayer:addChild(ui.widget.petMainLV)
        ui.showLv()

        --创建进化按钮
        ui.widget.btnUpLV = SpineMenuItem:create(json.ui.button, img.createUISprite(img.ui.hero_btn_lvup))
        ui.widget.btnAdvanced = SpineMenuItem:create(json.ui.button, img.createUISprite(img.ui.hero_btn_lvup))

        local menuAdvanced = CCMenu:createWithItem(ui.widget.btnAdvanced)
        menuAdvanced:setPosition(CCPoint(0,0))
        ui.widget.infoLayer:addChild(menuAdvanced,20)

        local menuUpLV = CCMenu:createWithItem(ui.widget.btnUpLV)
        menuUpLV:setPosition(CCPoint(0,0))
        ui.widget.infoLayer:addChild(menuUpLV,20)

        --战宠的升级消耗
        ui.showUpLvNeed()

        --创建技能图标
        local skillIconBg = ui.creatSkillBtn(petData[ui.data.id].actSkillId,ui.widget.infoLayer)

        --创建说明文字
        ui.widget.nameMainSkill = lbl.createMix({font = 1, size = 20, text = i18n.skill[petData[ui.data.id].actSkillId].skillName, width = 380 , color = ccc3(0x72, 0x3f, 0x23), align = kCCTextAlignmentLeft})
        ui.widget.nameMainSkill:setAnchorPoint(CCPoint(0,0))
        ui.widget.infoLayer:addChild(ui.widget.nameMainSkill,20)

        ui.widget.lvMainSkill = lbl.createFont1(20, "LV:", ccc3(0x91, 0x3b, 0x38))
        ui.widget.infoLayer:addChild(ui.widget.lvMainSkill,20)

        ui.widget.labSkill = lbl.createMix({font = 1, size = 16, text = "--", width = 350 , color = ccc3(0x8e, 0x5d, 0x43), align = kCCTextAlignmentLeft})
        ui.widget.infoLayer:addChild(ui.widget.labSkill,20)

        DHComponents:mandateNode(ui.widget.btnAdvanced  ,"yw_petInfo_btnAdvanced")
        DHComponents:mandateNode(ui.widget.btnUpLV      ,"yw_petInfo_btnUpLV")
        DHComponents:mandateNode(starLayer              ,"yw_petInfo_starLayer")
        DHComponents:mandateNode(framInfo               ,"yw_petInfo_framInfo")
        DHComponents:mandateNode(labAdv                 ,"yw_petInfo_labAdv")
        DHComponents:mandateNode(labInfo                ,"yw_petInfo_labTitle")
        DHComponents:mandateNode(labInfoShade           ,"yw_petInfo_labTitleShade")
        DHComponents:mandateNode(labLV                  ,"yw_petInfo_labLV")
        DHComponents:mandateNode(ui.widget.petMainLV    ,"yw_petInfo_petMainLV")
        DHComponents:mandateNode(skillIconBg            ,"yw_petInfo_skillIcon")
        DHComponents:mandateNode(ui.widget.lvMainSkill  ,"yw_petInfo_lvMainSkill")
        DHComponents:mandateNode(ui.widget.labSkill     ,"yw_petInfo_labSkill")

        --创建升级消耗，并且判断是否显示升星按钮
        ui.showMainSkillLable()
    end

    --ui.showUpLvNeed()
    ui.widget.infoLayer:setVisible(isShow)
end

--显示宠物BUFF界面，如果不存在就创建
function  ui.showBuff( isShow )
    if ui.widget.buffLayer == nil then  

        ui.widget.buffLayer = CCLayer:create()
        ui.widget.buffLayer:setCascadeOpacityEnabled(true)
        ui.widget.buffLayer:setPosition(CCPoint(300,300))
        ui.widget.pet_info:addChild(ui.widget.buffLayer)

        --创建主要信息部分
        local framBuff = img.createUI9Sprite(img.ui.botton_fram_2)
        framBuff:setPreferredSize(CCSizeMake(430, 120))
        framBuff:setAnchorPoint(CCPoint(0, 0))
        ui.widget.buffLayer:addChild(framBuff)

        local labBuff = lbl.createFont1(24, i18n.global.pet_buff.string, ccc3(0xe6, 0xd0, 0xae))
        ui.widget.buffLayer:addChild(labBuff,2)

        --后面有点影子
        local labBuffShade = lbl.createFont1(24, i18n.global.pet_buff.string, ccc3(0x59, 0x30, 0x1b))
        ui.widget.buffLayer:addChild(labBuffShade,1)

        --创建按钮部分
        btnSp = img.createLogin9Sprite(img.login.button_9_small_gold)
        btnSp:setPreferredSize(CCSize(180, 56))

        local labUpgrade = lbl.createFont1(18, i18n.global.pet_upLevel.string, ccc3(0x76, 0x25, 0x05))
        labUpgrade:setPosition(btnSp:getContentSize().width/2, btnSp:getContentSize().height/2 + 2)
        btnSp:addChild(labUpgrade)

        ui.widget.btnUpgrade = SpineMenuItem:create(json.ui.button, btnSp)
        ui.widget.btnUpgrade:setPosition(CCPoint(0,0))
		
		btnSp = img.createLogin9Sprite(img.login.button_9_small_gold)
        btnSp:setPreferredSize(CCSize(180, 56))

        labUpgrade = lbl.createFont1(18, i18n.global.act_bboss_sweep.string, ccc3(0x76, 0x25, 0x05))
        labUpgrade:setPosition(btnSp:getContentSize().width/2, btnSp:getContentSize().height/2 + 2)
        btnSp:addChild(labUpgrade)
		
		ui.widget.btnfUpgrade = SpineMenuItem:create(json.ui.button, btnSp)
        ui.widget.btnfUpgrade:setPosition(CCPoint(0,0))

        local menuUpgrade = CCMenu:createWithItem(ui.widget.btnUpgrade)
        menuUpgrade:setPosition(CCPoint(0,0))
        ui.widget.buffLayer:addChild(menuUpgrade)
		
		local fmenuUpgrade = CCMenu:createWithItem(ui.widget.btnfUpgrade)
        fmenuUpgrade:setPosition(CCPoint(0,0))
        ui.widget.buffLayer:addChild(fmenuUpgrade)

        --创建4个SKILL
        ui.widget.skillIconBg = {}
       --print("petData[ui.data.id].pasSkillId[1] = ",)
        ui.widget.skillIconBg[1] = ui.creatSkillBtn(petData[ui.data.id].pasSkillId[1] , ui.widget.buffLayer,1)
        ui.widget.skillIconBg[2] = ui.creatSkillBtn(petData[ui.data.id].pasSkillId[2] , ui.widget.buffLayer,2)
        ui.widget.skillIconBg[3] = ui.creatSkillBtn(petData[ui.data.id].pasSkillId[3] , ui.widget.buffLayer,3)
        ui.widget.skillIconBg[4] = ui.creatSkillBtn(petData[ui.data.id].pasSkillId[4] , ui.widget.buffLayer,4)

        ui.widget.skillIconBg[1].lv = lbl.create({font=2, size=16, text="LV:--", color=ccc3(255, 246, 223)})
        ui.widget.skillIconBg[1]:addChild(ui.widget.skillIconBg[1].lv,21)

        ui.widget.skillIconBg[2].lv = lbl.create({font=2, size=16, text="LV:--", color=ccc3(255, 246, 223)})
        ui.widget.skillIconBg[2]:addChild(ui.widget.skillIconBg[2].lv,21)
        
        ui.widget.skillIconBg[3].lv = lbl.create({font=2, size=16, text="LV:--", color=ccc3(255, 246, 223)})
        ui.widget.skillIconBg[3]:addChild(ui.widget.skillIconBg[3].lv,21)
        
        ui.widget.skillIconBg[4].lv = lbl.create({font=2, size=16, text="LV:--", color=ccc3(255, 246, 223)})
        ui.widget.skillIconBg[4]:addChild(ui.widget.skillIconBg[4].lv,21)

        --创建一个骨骼动画用于升级技能
        ui.widget.buffLvSpine = json.create(json.ui.pet2_json)
        ui.widget.buffLvSpine:setScale(view.minScale)
        ui.widget.buffLayer:addChild(ui.widget.buffLvSpine, 50)
        
        ui.showBuffLv()        
        ui.showBuffSele(ui.data.buffEff)
        ui.showBuffuffBtnShader()
        ui.showUpBuffNeed()
        ui.showBuffAllAddData()

        DHComponents:mandateNode(framBuff                       ,"yw_petBuff_framBuff")
        DHComponents:mandateNode(labBuff                        ,"yw_petInfo_labTitle")
        DHComponents:mandateNode(labBuffShade                   ,"yw_petInfo_labTitleShade")
        DHComponents:mandateNode(ui.widget.btnUpgrade           ,"yw_petBuff_btnUpgrade")
		DHComponents:mandateNode(ui.widget.btnfUpgrade           ,"yw_petBuff_btnUpgrade")
        DHComponents:mandateNode(ui.widget.skillIconBg[1]       ,"yw_petBuff_skillIconBg_1")
        DHComponents:mandateNode(ui.widget.skillIconBg[2]       ,"yw_petBuff_skillIconBg_2")
        DHComponents:mandateNode(ui.widget.skillIconBg[3]       ,"yw_petBuff_skillIconBg_3")
        DHComponents:mandateNode(ui.widget.skillIconBg[4]       ,"yw_petBuff_skillIconBg_4")
        DHComponents:mandateNode(ui.widget.skillIconBg[1].lv    ,"yw_petBuff_skillIconBg_LV")
        DHComponents:mandateNode(ui.widget.skillIconBg[2].lv    ,"yw_petBuff_skillIconBg_LV")
        DHComponents:mandateNode(ui.widget.skillIconBg[3].lv    ,"yw_petBuff_skillIconBg_LV")
        DHComponents:mandateNode(ui.widget.skillIconBg[4].lv    ,"yw_petBuff_skillIconBg_LV")
		
		ui.widget.btnUpgrade:setPosition(ui.widget.btnUpgrade:getPositionX() - 100, ui.widget.btnUpgrade:getPositionY())
		ui.widget.btnfUpgrade:setPosition(ui.widget.btnfUpgrade:getPositionX() + 100, ui.widget.btnfUpgrade:getPositionY())
    end

    --ui.showUpLvNeed()
    --ui.showUpBuffNeed()
    ui.widget.buffLayer:setVisible(isShow)
end

--删除该层函数
function ui.clear( petJson )
    petJson:removeChildFollowSlot("code_card_position2")
    petJson:removeChildFollowSlot("code_attribute_position")
    petJson:removeChildFollowSlot("code_attribute_position2")
    petJson:removeChildFollowSlot("code_icon")
    petJson:removeChildFollowSlot("code_black")
    petJson:removeChildFollowSlot("code_card2")

    ui.data = nil
    ui.widget = nil
end

function ui.showBuffLv()
    for i=1 ,advancedMax do
        if i > ui.data.advanced then
            ui.widget.skillIconBg[i].lv:setVisible(false)
        else
            ui.widget.skillIconBg[i].lv:setVisible(true)
            if ui.data.buffLv[i] == 30 then
                ui.widget.skillIconBg[i].lv:setString("LV:Max")
            else
                if ui.data.buffLv[i] == nil then
                    ui.data.buffLv[i] = 1
                end
                ui.widget.skillIconBg[i].lv:setString("LV:"..ui.data.buffLv[i])
            end
        end
    end
end

--显示宠物Card
function ui.showMainCard()
	if ui.widget.pet_image ~= nil then
		ui.widget.pet_image:removeFromParent()
		ui.widget.pet_image = nil
    end
    --[[ --之前因为层级裁剪问题，将pet_spine放在了pet_image上，此处只需要removeFromParent掉pet_image即可
    if ui.widget.pet_spine ~= nil then
        ui.widget.pet_spine:removeFromParent()
        ui.widget.pet_spine = nil
    end]]
    if ui.widget.pet_card ~= nil then
        ui.widget.pet_card:removeFromParent()
        ui.widget.pet_card = nil
    end
	

    local path = img.ui.pet_card
    if  (petNetData.getData(ui.data.id).advanced == 2 or petNetData.getData(ui.data.id).advanced == 3) then
        path = img.ui["pet_card2"]
    elseif petNetData.getData(ui.data.id).advanced == 4 then
        path = img.ui["pet_card3"] 
    end

    ui.widget.pet_card = img.createUISprite(path)
    ui.widget.pet_card:setPosition(CCPoint(0,0))
    ui.widget.pet_card_layer:addChild(ui.widget.pet_card,20)

    ui.widget.pet_image = img.createUISprite(img.ui[petData[ui.data.id]["petBody"]..ui.data.advanced])
    ui.widget.pet_image:setCascadeOpacityEnabled(true)
    ui.widget.pet_card_layer:addChild(ui.widget.pet_image,10)

    --骨骼动画
    local name =  string.gsub(petData[ui.data.id]["petBody"],"pet_","spine_")
    ui.widget.pet_spine = ui.createJsonCard(json.ui[name..ui.data.advanced])
    ui.widget.pet_image:addChild(ui.widget.pet_spine,12)

    --加点特效
    if ui.data.advanced == 4 then 
        local lightJson = json.create(json.ui.pet_json)
        lightJson:setCascadeOpacityEnabled(true)
        lightJson:setScale(1.21)
        lightJson:setPositionX(ui.widget.pet_image:getContentSize().width/2)
        lightJson:setPositionY(ui.widget.pet_image:getContentSize().height/2)
        lightJson:playAnimation(petData[ui.data.id].petEff,-1)
        lightJson:setVisible(false)
        ui.widget.pet_image:addChild(lightJson,5)

        lightJson:runAction(CCSequence:createWithTwoActions(
        CCDelayTime:create(0.1),
        CCCallFunc:create(function()
            lightJson:setVisible(true)
        end)
    ))
    end
end

--显示选中的buff
function ui.showBuffSele(SeleID)
    if  SeleID > ui.data.advanced then return end
    if ui.widget.buffSele ~= nil then
        ui.widget.buffSele:removeFromParent()
        ui.widget.buffSele = nil
    end

    ui.widget.buffLvSpine:setPosition(ui.widget.skillIconBg[SeleID]:getPosition())
    ui.data.buffEff = SeleID
    ui.widget.buffSele = img.createUISprite(img.ui.pet_skill_sele)
    ui.widget.buffSele:setPosition(CCPoint(42,42))
    ui.widget.skillIconBg[SeleID]:addChild(ui.widget.buffSele)
end

--显示BUFF的所有加层属性
function ui.showBuffAllAddData()
    local allData = {}
    for key,val in pairs(petData[ui.data.id].pasSkillId) do  
        if  key > ui.data.advanced then
            break
        end

        local effect = buffdata[ui.data.skl[key]].effect
        for k,v in pairs(effect) do
            if allData[effect[k].type] == nil then
                allData[effect[k].type] = effect[k].num
            else
                allData[effect[k].type] = allData[effect[k].type] + effect[k].num
            end
        end
    end
    
    if ui.widget.allBuffLayer ~= nil then
        ui.widget.allBuffLayer:removeFromParent()
        ui.widget.allBuffLayer = nil
    end

    ui.widget.allBuffLayer = CCLayer:create()

    local numberLab = 1
    for k,v in pairs(allData) do
        local name,number = buffString(k,v)
        local labName = lbl.createFont1(16, name, ccc3(0x91, 0x3b, 0x38))
        if labName == nil then
            print("当K =  "..k.."时，labName = nil，and name = ",name)
        else
            labName:setAnchorPoint(0,0.5)
            ui.widget.allBuffLayer:addChild(labName)
        end

        local lblNumber = lbl.createFont1(16, "+"..number, ccc3(0x50, 0x27, 0x15))
        if lblNumber ~= nil then
            lblNumber:setAnchorPoint(0,0.5)
            ui.widget.allBuffLayer:addChild(lblNumber)
        end

        DHComponents:mandateNode(labName              ,"yw_petBuff_labName"..numberLab)
        DHComponents:mandateNode(lblNumber               ,"yw_petBuff_number"..numberLab)
        numberLab = numberLab + 1
    end

    ui.widget.allBuffLayer:setPosition(CCPoint(0,0))
    ui.widget.buffLayer:addChild(ui.widget.allBuffLayer,30)
end

--战宠升级的需求显示
function ui.showUpLvNeed()
    local maxLv = petData[ui.data.id]["starLv"][ui.data.advanced] or petData[ui.data.id]["maxLv"]
    ui.widget.infoLayer:removeChildByTag(1001)
    --等级不满
    if ui.data.lv < maxLv then
        --setShader(ui.widget.btnAdvanced,SHADER_GRAY,true)
        local CostBg = img.createUI9Sprite(img.ui.hero_lv_cost_bg)
        CostBg:setPreferredSize(CCSize(220, 40))
        ui.widget.infoLayer:addChild(CostBg,20,1001)
        local expPetID = (math.floor((ui.data.id)/100))*1000 + ui.data.lv
        local i = 0
        for k,v in pairs(petExpData[expPetID].need) do
            local icon = img.createItemIcon2(v.type)
            icon:setPosition(CCPoint(i*110+21,20))
            CostBg:addChild(icon,20,100)

            local numLab = lbl.create({font=2, size=16, text=num2KM(v.count), color=ccc3(255, 246, 223)})
            numLab:setPosition(CCPoint(i*100+65,20))
            CostBg:addChild(numLab)

            local bagCount = bagdata.items.find(v.type)
            if bagCount.num < tonumber(v.count) then
                numLab:setColor(ccc3(0xff, 0x2c, 0x2c))
            end
            i = i + 1
        end
        DHComponents:mandateNode(CostBg,"yw_petInfo_CostBg")
    else
        local img_maxlv = img.ui.hero_maxlv
        if i18n.getCurrentLanguage() == kLanguageChinese then
            img_maxlv = img.ui.hero_maxlv_cn
        elseif i18n.getCurrentLanguage() == kLanguageChineseTW then
            img_maxlv = img.ui.hero_maxlv_tw
        elseif i18n.getCurrentLanguage() == kLanguageJapanese then
            img_maxlv = img.ui.hero_maxlv_jp
        elseif i18n.getCurrentLanguage() == kLanguageRussian then
            img_maxlv = img.ui.hero_maxlv_ru
        elseif i18n.getCurrentLanguage() == kLanguageKorean then
            img_maxlv = img.ui.hero_maxlv_kr
        end
        local CostBg = img.createUI9Sprite(img_maxlv)
        ui.widget.infoLayer:addChild(CostBg,20,1001)
        DHComponents:mandateNode(CostBg,"yw_petInfo_CostBgSp")
        --clearShader(ui.widget.btnAdvanced,true)
    end

    if ui.data.lv  >= maxLv then 
        ui.widget.btnUpLV:setVisible(false)
    else
        ui.widget.btnUpLV:setVisible(true)
    end
    
    if ui.data.advanced >= advancedMax and ui.data.lv >= maxLv then
        ui.widget.btnAdvanced:setVisible(false)
    else
        ui.widget.btnAdvanced:setVisible(true)
    end
end

--战宠光环升级的需求显示
function ui.showUpBuffNeed()
    --不处理手速太快点出的30级以上问题

    ui.widget.buffLayer:removeChildByTag(1001)
    ui.widget.buffLayer:removeChildByTag(1002)

    if ui.data.buffLv[ui.data.buffEff] >= 30 then
        return
    end

    local CostBg = {}
    CostBg[1] = img.createUI9Sprite(img.ui.hero_evolve_cost_bg)
    CostBg[1]:setPreferredSize(CCSize(170, 30))
    ui.widget.buffLayer:addChild(CostBg[1],20,1001)

    CostBg[2] = img.createUI9Sprite(img.ui.hero_evolve_cost_bg)
    CostBg[2]:setPreferredSize(CCSize(170, 30))
    ui.widget.buffLayer:addChild(CostBg[2],20,1002)

    local i = 1
    if buffdata[ui.data.skl[ui.data.buffEff]] == nil or buffdata[ui.data.skl[ui.data.buffEff]].need == nil then
        return
    end

    for k,v in pairs(buffdata[ui.data.skl[ui.data.buffEff]].need) do
        local icon = img.createItemIcon2(v.type)
        icon:setPosition(CCPoint(5,15))
        CostBg[i]:addChild(icon,20)

        local numLab = lbl.create({font=2, size=16, text=v.count, color=ccc3(0xff, 0xf7, 0xe6)})
        numLab:setPosition(CCPoint(85,16))
        numLab:setAnchorPoint(CCPoint(0.5,0.5))
        CostBg[i]:addChild(numLab)
        i = i + 1

        local bagCount = bagdata.items.find(v.type)
        if bagCount.num < tonumber(v.count) then
            numLab:setColor(ccc3(0xff, 0x2c, 0x2c))
        end
    end

    DHComponents:mandateNode(CostBg[1],"yw_buffInfo_CostBg_1")
    DHComponents:mandateNode(CostBg[2],"yw_buffInfo_CostBg_2")
end

--根据数据显示进阶星星
function ui.showStar()
	for i=1,advancedMax do
		ui.widget.advStar[i]:setVisible(true)
		if i > ui.data.advanced then
			ui.widget.advStar[i]:setVisible(false)
		end
	end
end

--显示当前主动技能数据
function ui.showMainSkillLable()
    print((petData[ui.data.id].actSkillId + ui.data.lv -1).."技能内容 = "..i18n.skill[petData[ui.data.id].actSkillId + ui.data.lv -1].desc)
    ui.widget.labSkill:setString(i18n.skill[petData[ui.data.id].actSkillId + ui.data.lv -1].desc)
    ui.widget.lvMainSkill:setString("LV."..ui.data.lv)

    local x = ui.widget.lvMainSkill:getPositionX() + (152+ui.widget.lvMainSkill:boundingBox():getMaxX())
    ui.widget.nameMainSkill:setPosition(CCPoint(x,ui.widget.lvMainSkill:getPositionY()))
end

--根据数据显示buffbtn的置灰效果
function ui.showBuffuffBtnShader()
    for k,v in pairs(ui.widget.skillIconBg) do
        if  v._key > ui.data.advanced then
            setShader(v, SHADER_GRAY, true)
        else
            clearShader(v, true)
        end
    end
end

--显示宠物当前等级
function ui.showLv()
    local maxLv = petData[ui.data.id]["starLv"][ui.data.advanced] or petData[ui.data.id]["maxLv"]
    ui.widget.petMainLV:setString(ui.data.lv.."/"..maxLv)
end

--创建buff技能按钮，和 主技能非按钮控件公用这个函数，最后一个参数是区分两者的关键
function ui.creatSkillBtn(spID,layer,key)
    --创建技能背景图标
    local skillIconBg = img.createUISprite(img.ui.hero_skill_bg)
    skillIconBg:setCascadeOpacityEnabled(true)
    skillIconBg._key = key
    local skillIcon = nil
    if skillIconBg._key == nil then
        skillIcon = img.createSkill(spID)
    else
        skillIcon = img.createPetBuff(spID)
    end

    skillIcon:setPosition(skillIconBg:getContentSize().width/2, skillIconBg:getContentSize().height/2)
    skillIconBg:addChild(skillIcon)
	layer:addChild(skillIconBg,20)

	local tip = {} 
    local function onTouch(eventType, x, y)
        if skillIconBg._key == nil then
            return true
        end

        if eventType == "began" then
            --排除意外错误
            local skillID = ui.data.skl[key]
            if ui.data.skl[key] == nil then
                print("petID = "..ui.data.id)
                skillID = petData[ui.data.id].pasSkillId[key]   
            end
            tip = require("ui.tips.skill").createForPet(skillID)
            tip:setPosition(CCPoint(240,320))
            ui.widget.pet_info:addChild(tip,21)
        elseif eventType == "ended" then
            ui.showBuffSele(skillIconBg._key)
            ui.showUpBuffNeed()
            tip:removeFromParent()
        end
        return true
    end
    skillIconBg:registerScriptTouchHandler(onTouch)
    skillIconBg:setTouchEnabled(true)
    skillIconBg:setTouchSwallowEnabled(true)

	return skillIconBg
end

--尽可能刷新所有可以刷新的部件
function ui.refreshAllShow()
    ui.showBuffSele(1)
    ui.showBuffLv()
    ui.showMainCard()
    ui.showBuffAllAddData()
    ui.showUpLvNeed()
    ui.showUpBuffNeed()
    ui.showStar()
    ui.showMainSkillLable()
    ui.showBuffuffBtnShader()
    ui.showLv()
end

--创建战宠进阶弹窗
function ui.createAdvancedWindow()
    local layer = CCLayer:create()
    --layer:setPosition(CCPoint(view.midX, view.midY))
    --layer:setScale(view.minScale)
    ui.widget.mainLayer:getParent():addChild(layer, 1000)

    local darkBg = CCLayer:create()
    darkBg:setTouchEnabled(true)
    darkBg:setScale(view.maxScale)
    --darkBg:setPosition(CCPoint(view.midX, view.midY))
    darkBg:addChild(CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY)))
    darkBg:registerScriptTouchHandler(function (event)
        if event == "began" then return false end
    end)
    ui.widget.mainLayer:getParent():addChild(darkBg, 999)

    local bg = img.createUI9Sprite(img.ui.dialog_1)
    bg:setPreferredSize(CCSizeMake(490, 470))
    bg:setPosition(CCPoint(view.midX, view.midY))
    layer:addChild(bg)
    bg:setScale(0.5)
    --缩放动作
    local anim_arr = CCArray:create()
    anim_arr:addObject(CCScaleTo:create(0.15, 1*view.minScale, 1*view.minScale))
    bg:runAction(CCSequence:create(anim_arr))

    --标题
    local lbl_title = lbl.createFont1(24, i18n.global.pet_war_advanced.string, ccc3(0xe6, 0xd0, 0xae))
    bg:addChild(lbl_title, 2)
    
    local lbl_title_shadowD = lbl.createFont1(24, i18n.global.pet_war_advanced.string, ccc3(0x59, 0x30, 0x1b))
    bg:addChild(lbl_title_shadowD)
    
    --等级字符标签
    local lvLabel = lbl.createFont2(20,i18n.global.hero_wake_level_up.string,ccc3(0xfc,0xea,0x8d))
    bg:addChild(lvLabel) 

    local nowLv = petData[ui.data.id]["starLv"][ui.data.advanced]
    local nextLv = nowLv
    if ui.data.advanced == # petData[ui.data.id]["starLv"]then
        nextLv = petData[ui.data.id]["maxLv"]
    else
        nextLv = petData[ui.data.id]["starLv"][ui.data.advanced+1]
    end

    --当前等级标签
    local nowLvLabel = lbl.createFont2(20,nowLv,ccc3(255, 246, 223))
    bg:addChild(nowLvLabel)

    --下一等级标签
    local nextLvLabel = lbl.createFont2(20,nextLv,ccc3(0x9f,0xf2,0x3e))
    bg:addChild(nextLvLabel)

    --箭头图片
    local arrowPic = img.createUISprite(img.ui.arrow)
    bg:addChild(arrowPic)

    --底部背景框
    local bottomBox = img.createUI9Sprite(img.ui.hero_attribute_lab_frame)
    bottomBox:setOpacity(200)
    bottomBox:setPreferredSize(CCSizeMake(370,170))
    bg:addChild(bottomBox)

    --解锁字样
    local unlockLabel = lbl.createFont1(20,i18n.global.hero_unlock.string,ccc3(0x93,0x62,0x45))
    bg:addChild(unlockLabel)

    --光环背景
    local auraBg = img.createUISprite(img.ui.hero_skill_bg)
    bg:addChild(auraBg)

    --解锁光环
    local unlockAura = img.createPetBuff(petData[ui.data.id].pasSkillId[ui.data.advanced+1])
    bg:addChild(unlockAura)

    --数量显示底板
    local goldBg = img.createUI9Sprite(img.ui.hero_evolve_cost_bg)
    goldBg:setPreferredSize(CCSize(160,30))

    bg:addChild(goldBg)

    local soulBg = img.createUI9Sprite(img.ui.hero_evolve_cost_bg)
    soulBg:setPreferredSize(CCSize(160,30))
    bg:addChild(soulBg)

    --金币和魂的图标
    local goldIcon = img.createItemIcon2(ITEM_ID_COIN)
    goldBg:addChild(goldIcon)

    local soulIcon = img.createItemIcon2(ITEM_ID_PET_DEVIL)
    soulBg:addChild(soulIcon)

    --金币和魂的数量标签
    local goldNum = 0
    local soulNum = 0
    local starTable = petData[ui.data.id]["starExp"]
    for k,v in pairs(starTable) do
        if v["type"] == ITEM_ID_COIN and ui.data.advanced == v["star"] then
            goldNum = v["count"]
        elseif v["type"] == ITEM_ID_PET_DEVIL and ui.data.advanced == v["star"] then
            soulNum = v["count"]
        end
    end

    local goldLabel = lbl.createFont2(16,goldNum,ccc3(255, 246, 223))
    goldBg:addChild(goldLabel)
    local soulLabel = lbl.createFont2(16,soulNum,ccc3(255, 246, 223))
    soulBg:addChild(soulLabel)

    if (bagdata.items.find(ITEM_ID_COIN)).num < goldNum then
        goldLabel:setColor(ccc3(0xff, 0x2c, 0x2c))
    end
    if (bagdata.items.find(ITEM_ID_PET_DEVIL)).num < soulNum then
        soulLabel:setColor(ccc3(0xff, 0x2c, 0x2c))
    end

    --关闭按钮
    local btn_close = SpineMenuItem:create(json.ui.button, img.createUISprite(img.ui.close))
    btn_close:setPosition(CCPoint(bg:getContentSize().width-25, bg:getContentSize().height-28))
    local btn_close_menu = CCMenu:createWithItem(btn_close)
    btn_close_menu:setPosition(CCPoint(0, 0))
    bg:addChild(btn_close_menu, 100)
    btn_close:registerScriptTapHandler(function()
        audio.play(audio.button)
        ui.widget.petJson:removeChildFollowSlot("code_card2")
        ui.widget.petJson:removeChildFollowSlot("code_icon")
        ui.widget.petJson:removeChildFollowSlot("code_black")
        layer:removeFromParent()
        darkBg:removeFromParent()
    end)

    --升级按钮
    local advanceImg = img.createUI9Sprite(img.ui.btn_2)
    advanceImg:setPreferredSize(CCSize(200,60))
    local advanceBtn = SpineMenuItem:create(json.ui.button,advanceImg)
    local advanceMenu = CCMenu:createWithItem(advanceBtn)
    advanceMenu:setPosition(CCPoint(0,0))
    bg:addChild(advanceMenu)
    local advanceLabel = lbl.createFont1(20,i18n.global.hero_advance.string,ccc3(0x72,0x3b,0x0f))
    advanceLabel:setPosition(CCPoint(100,30))
    advanceImg:addChild(advanceLabel)
    advanceBtn:registerScriptTapHandler(function ()
        audio.play(audio.button)
        layer:setVisible(false)
        darkBg:setVisible(false)

        local starExp = tablecp(petData[ui.data.id].starExp)
        for k,v in pairs(starExp) do
            if v["star"] ~= ui.data.advanced then
                starExp[k] = nil
            end 
        end

        --消费计算
        if require("ui.pet.main").subItem(starExp) == false then return end  

        --用于播放升星的动画
        local playAni = function()
            ui.widget.petJson:playAnimation("upgrade")
            local pasSkillId = petData[ui.data.id].pasSkillId
            local myPetBuffKey = pasSkillId[ui.data.advanced + 1]
            local showSkill = img.createPetBuff(myPetBuffKey)
            setShader(showSkill, SHADER_GRAY, true)
            ui.widget.petJson:addChildFollowSlot("code_icon", showSkill )

            local nameSkill = lbl.createMix({font = 1, size = 24, text = i18n.petskill[pasSkillId[ui.data.advanced + 1] ].skillName, width = 200 , color = ccc3(0xff, 0xff, 0xff)})
            nameSkill:setPositionY(-20)
            ui.widget.petJson:addChildFollowSlot("code_text", nameSkill )

            local myUpTime = ui.widget.petJson:getEventTime("upgrade", "fx")
            ui.widget.petJson:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(myUpTime),CCCallFunc:create(
                    function()
                        local showSkill2 = img.createPetBuff(myPetBuffKey)
                        ui.widget.petJson:addChildFollowSlot("code_icon", showSkill2 )
                    end
                )))

            --创建背景卡牌
            local card = img.createUISprite(img.ui[petData[ui.data.id]["petBody"]..ui.data.advanced])
            card:setCascadeOpacityEnabled(true)
            card:setPosition(CCPoint(card:getContentSize().width/2,card:getContentSize().height/2))
            local mySize = card:getContentSize()
            --创建骨骼动画
            local name =  string.gsub(petData[ui.data.id]["petBody"],"pet_","spine_")
            local clippingSp = ui.createJsonCard(json.ui[name..ui.data.advanced])    --骨骼动画

            --创建卡牌边框
            local path= img.ui.pet_card
            if  (petNetData.getData(ui.data.id).advanced == 2 or petNetData.getData(ui.data.id).advanced == 3) then
                path = img.ui["pet_card2"]
            elseif petNetData.getData(ui.data.id).advanced == 4 then
                path = img.ui["pet_card3"] 
            end
            local card_bg= img.createUISprite(path)
            card_bg:setCascadeOpacityEnabled(true)
            card_bg:setPosition(CCPoint(0,0))

            card:addChild(clippingSp,12)
            card_bg:addChild(card,-1)

            ui.widget.petJson:addChildFollowSlot("code_card2", card_bg )
            require("ui.pet.main").createMaskLayer(1.8)
            ui.widget.btnAdvanced:runAction(createSequence(
            {
                CCDelayTime:create(0.2), CCCallFunc:create(function () ui.widget.petJson:removeChildFollowSlot("code_black") end),
                CCDelayTime:create(0.5), CCCallFunc:create(function ()
                    ui.data.star = ui.data.star + 1
                    petNetData.refreshData()
                    card:removeFromParent()
                    card_bg:removeFromParent()

                    --创建卡牌边框
                    local path= img.ui.pet_card
                    if  (petNetData.getData(ui.data.id).advanced == 2 or petNetData.getData(ui.data.id).advanced == 3) then
                        path = img.ui["pet_card2"]
                    elseif petNetData.getData(ui.data.id).advanced == 4 then
                        path = img.ui["pet_card3"] 
                    end
                    local card_bg= img.createUISprite(path)
                    card_bg:setCascadeOpacityEnabled(true)
                    card_bg:setPosition(CCPoint(0,0))
                    ui.widget.petJson:addChildFollowSlot("code_card2", card_bg )


                    card = img.createUISprite(img.ui[petData[ui.data.id]["petBody"]..ui.data.advanced])
                    card:setCascadeOpacityEnabled(true)
                    card:setPosition(CCPoint(card:getContentSize().width/2,card:getContentSize().height/2))

                    --创建骨骼动画
                    local name =  string.gsub(petData[ui.data.id]["petBody"],"pet_","spine_")
                    local clippingSp = ui.createJsonCard(json.ui[name..ui.data.advanced])    --骨骼动画
                    card:addChild(clippingSp,12)
                    card_bg:addChild(card,-1)
                    ui.refreshAllShow()
                    --切换显示页面
                    ui.widget.buff_tag:setEnabled(false)
                    ui.widget.info_tag:setEnabled(true)
                    ui.showInfo(false)
                    ui.showBuff(true)
                    layer:removeFromParent() end),
                CCDelayTime:create(1.2),CCCallFunc:create(function ()
                    darkBg:removeFromParent()
                    ui.widget.petJson:removeChildFollowSlot("code_card2")
                    ui.widget.petJson:removeChildFollowSlot("code_icon")
                    ui.widget.petJson:removeChildFollowSlot("code_black") end)
            }))
        end

        --宠物升星网络通讯
        local params = {sid = player.sid,id = ui.data.id,opcode =3}
        addWaitNet()
        netClient:pet_op(params, function (data)
            if data.status == 0 then
                playAni()
            end
            petNetData.coutRsult(3,data.status)
            delWaitNet()
        end)

    end)

    DHComponents:mandateNode(lbl_title,"lpx_petInfo_title")
    DHComponents:mandateNode(lbl_title_shadowD,"lpx_petInfo_titleShadow")
    DHComponents:mandateNode(lvLabel,"lpx_petInfo_lvLabel")
    DHComponents:mandateNode(nowLvLabel,"lpx_petInfo_nowLvLabel")
    DHComponents:mandateNode(nextLvLabel,"lpx_petInfo_nextLvLabel")
    DHComponents:mandateNode(arrowPic,"lpx_petInfo_arrowPic")
    DHComponents:mandateNode(bottomBox,"lpx_petInfo_bottomBox")
    DHComponents:mandateNode(unlockLabel,"lpx_petInfo_unlockLabel")
    DHComponents:mandateNode(auraBg,"lpx_petInfo_unlockAura")
    DHComponents:mandateNode(unlockAura,"lpx_petInfo_unlockAura")
    DHComponents:mandateNode(goldBg,"lpx_petInfo_goldBg")
    DHComponents:mandateNode(soulBg,"lpx_petInfo_soulBg")
    DHComponents:mandateNode(goldIcon,"lpx_petInfo_goldIcon")
    DHComponents:mandateNode(soulIcon,"lpx_petInfo_soulIcon")
    DHComponents:mandateNode(goldLabel,"lpx_petInfo_goldLabel")
    DHComponents:mandateNode(soulLabel,"lpx_petInfo_soulLabel")
    DHComponents:mandateNode(advanceBtn,"lpx_petInfo_advanceBtn")

    return layer
end

--计算所有的返还数据
function ui.getAllback()
    --宠物的经验返还
    local allBack = {}
    --宠物buff技能返还
    local toAllBack = function (t)
        for k,v in pairs(t) do
            if v.count ~= 0 then
                allBack[v.type] = (allBack[v.type] or 0)  + v.count
            end
        end
    end
    toAllBack(petExpData[(math.floor((ui.data.id)/100))*1000 + ui.data.lv].back)

    for i=1,advancedMax do
        if ui.data.skl[i] ~= nil then
            toAllBack(buffdata[ui.data.skl[i]].back)
        end
    end

    --为兼容数据，返回老格式的表
    local retrunTable = {}
    for k,v in pairs(allBack) do
        table.insert(retrunTable,{["count"]=v , ["type"]=k})
    end
    return retrunTable
end

--按钮响应事件，统一写在此处
function ui.CallFun()
	ui.widget.buff_tag:registerScriptTapHandler(function()
		ui.widget.buff_tag:setEnabled(false)
		ui.widget.info_tag:setEnabled(true)
		ui.showInfo(false)
   		ui.showBuff(true)
	end)

	ui.widget.info_tag:registerScriptTapHandler(function()
		ui.widget.buff_tag:setEnabled(true)
		ui.widget.info_tag:setEnabled(false)
		ui.showInfo(true)
   		ui.showBuff(false)
	end)

	ui.widget.btnAdvanced:registerScriptTapHandler(function()
        local maxLv = petData[ui.data.id]["starLv"][ui.data.advanced] or petData[ui.data.id]["maxLv"]
        --等级没有达到不能升星
        if ui.data.lv < maxLv then
            --showToast(string.format(i18n.global.pet_upSfail_forLv.string))
			
			local expid = (math.floor((ui.data.id)/100))*1000 + ui.data.lv
			if require("ui.pet.main").hasItem(petExpData[expid].need) == false then
				return
			end
			
			local params = {sid = player.sid, id = ui.data.id, opcode =21}
			addWaitNet()
			netClient:pet_op(params, function (data)
				if data.status > 0 then
					local uipetmain = require("ui.pet.main")
					for i=1, data.status do
						local expPetID = (math.floor((ui.data.id)/100))*1000 + ui.data.lv + (i - 1)
						if uipetmain.subItem(petExpData[expPetID].need) == false then
							break
						end
					end
					ui.widget.infoLvSpine:playAnimation("info_refresh")
					ui.data.lv = ui.data.lv + data.status
					ui.showLv()
					ui.showMainSkillLable()
					ui.showUpLvNeed()
				end
				petNetData.coutRsult(2,data.status)
				delWaitNet()
			end)
            return
        end

        local starExp = tablecp(petData[ui.data.id].starExp)
        for k,v in pairs(starExp) do
            if v["star"] ~= ui.data.advanced then
                starExp[k] = nil
            end 
        end
        
        --超过上限
        if ui.data.advanced >= advancedMax then
            showToast(string.format(i18n.global.pet_stars_lv_max.string))
            return
        end

        local advanceUI = ui.createAdvancedWindow()
	end)
    --主要等级升级
    ui.widget.btnUpLV:registerScriptTapHandler(function ()
        --宠物升级测试      
        audio.play(audio.button)
        local maxLv = petData[ui.data.id]["starLv"][ui.data.advanced] or petData[ui.data.id]["maxLv"]
        
        if ui.data.lv >= maxLv then
            showToast(string.format(i18n.global.pet_skill_lv_max.string))
            return
        end
        
        --消费计算
        local expPetID = (math.floor((ui.data.id)/100))*1000 + ui.data.lv
        if require("ui.pet.main").subItem(petExpData[expPetID].need) == false then
            return
        end

        local params = {sid = player.sid, id = ui.data.id, opcode =2}
        addWaitNet()
        netClient:pet_op(params, function (data)
            if data.status == 0 then
                ui.widget.infoLvSpine:playAnimation("info_refresh")
                ui.data.lv = ui.data.lv + 1
                ui.showLv()
                ui.showMainSkillLable()
                ui.showUpLvNeed()
            end
            petNetData.coutRsult(2,data.status)
            delWaitNet()
        end)
    end)
    --Buff升级
    ui.widget.btnUpgrade:registerScriptTapHandler(function ()
        if ui.data.buffLv[ui.data.buffEff] >= 30 then
            showToast(string.format(i18n.global.pet_buff_lv_max.string))
            return
        end

        --消费计算
        local buffId = ui.data.skl[ui.data.buffEff]
        if require("ui.pet.main").subItem(buffdata[buffId].need) == false then return end

        --宠物升技能
        local params = { sid = player.sid, id = ui.data.id, opcode =4, skl=buffId}
        addWaitNet()
        netClient:pet_op(params, function (data)
            if data.status == 0 then
                ui.data.buffLv[ui.data.buffEff] = ui.data.buffLv[ui.data.buffEff] + 1
                ui.data.skl[ui.data.buffEff] = ui.data.skl[ui.data.buffEff] + 1
                ui.showBuffSele(ui.data.buffEff)
                ui.showUpBuffNeed()
                ui.showBuffLv()
                ui.showBuffAllAddData()
                ui.widget.buffLvSpine:playAnimation("skill_upgrade")
            end
            petNetData.coutRsult(4,data.status)
            delWaitNet()
        end)
    end)
	ui.widget.btnfUpgrade:registerScriptTapHandler(function ()
        if ui.data.buffLv[ui.data.buffEff] >= 30 then
            showToast(string.format(i18n.global.pet_buff_lv_max.string))
            return
        end

        --消费计算
        local buffId = ui.data.skl[ui.data.buffEff]
		if require("ui.pet.main").hasItem(buffdata[buffId].need) == false then return end

        --宠物升技能
        local params = { sid = player.sid, id = ui.data.id, opcode =22, skl=buffId}
        addWaitNet()
        netClient:pet_op(params, function (data)
            if data.status > 0 then
				local uipetmain = require("ui.pet.main")
				for i=1, data.status do
					if uipetmain.subItem(buffdata[buffId + (i - 1)].need) == false then break end
				end
                ui.data.buffLv[ui.data.buffEff] = ui.data.buffLv[ui.data.buffEff] + data.status
                ui.data.skl[ui.data.buffEff] = ui.data.skl[ui.data.buffEff] + data.status
                ui.showBuffSele(ui.data.buffEff)
                ui.showUpBuffNeed()
                ui.showBuffLv()
                ui.showBuffAllAddData()
                ui.widget.buffLvSpine:playAnimation("skill_upgrade")
            end
            petNetData.coutRsult(4,data.status)
            delWaitNet()
        end)
    end)
    ui.widget.btnReStore:registerScriptTapHandler(function ()
        --如果没升级过，就不允许重生
        if ui.data.lv == 1 and ui.data.buffLv[1] == 1 then
            showToast(string.format(i18n.global.pet_reStore_fail.string))
            return
        end
        local onhandle = function()
            local backTable = ui.getAllback()
            require("ui.pet.main").addItem(backTable)
            --临时的数据还原
            ui.data.lv = 1
            for k,v in pairs(ui.data.buffLv) do
                ui.data.buffLv[k] = 1
            end
            
            local card = img.createUISprite(img.ui[petData[ui.data.id]["petBody"]..ui.data.advanced])
            card:setCascadeOpacityEnabled(true)
            card:setPosition(CCPoint(card:getContentSize().width/2,card:getContentSize().height/2))
            --骨骼动画
            local name =  string.gsub(petData[ui.data.id]["petBody"],"pet_","spine_")
            local clippingSp = ui.createJsonCard(json.ui[name..ui.data.advanced])    --骨骼动画
            card:addChild(clippingSp,12)

            --边框
            local path = img.ui.pet_card
            if  (petNetData.getData(ui.data.id).advanced == 2 or petNetData.getData(ui.data.id).advanced == 3) then
                path = img.ui["pet_card2"]
            elseif petNetData.getData(ui.data.id).advanced == 4 then
                path = img.ui["pet_card3"] 
            end

            local card_bg= img.createUISprite(path)
            card_bg:setCascadeOpacityEnabled(true)
            card_bg:setPosition(CCPoint(0,0))
            card_bg:addChild(card,-1)

            ui.widget.petJson:addChildFollowSlot("code_card2", card_bg )
            ui.widget.petJson:playAnimation("degrade")
            require("ui.pet.main").createMaskLayer(1.8)

            local params = {sid = player.sid,id = ui.data.id,opcode = 5}
            addWaitNet()
            netClient:pet_op(params, function (data)
                if data.status == 0 then
                    local seq = createSequence({CCDelayTime:create(0.6), CCCallFunc:create(function ()
                        card:removeFromParent()
                        card_bg:removeFromParent()
                        petNetData.Reset(ui.data.id)
                        ui.refreshAllShow()

                        --边框
                        local path = img.ui.pet_card
                        if  (petNetData.getData(ui.data.id).advanced == 2 or petNetData.getData(ui.data.id).advanced == 3) then
                            path = img.ui["pet_card2"]
                        elseif petNetData.getData(ui.data.id).advanced == 4 then
                            path = img.ui["pet_card3"] 
                        end

                        local card_bg= img.createUISprite(path)
                        card_bg:setCascadeOpacityEnabled(true)
                        card_bg:setPosition(CCPoint(0,0))
                

                        card = img.createUISprite(img.ui[petData[ui.data.id]["petBody"]..ui.data.advanced])
                        card:setCascadeOpacityEnabled(true)
                        card:setPosition(CCPoint(card:getContentSize().width/2,card:getContentSize().height/2))

                        --骨骼动画
                        local name =  string.gsub(petData[ui.data.id]["petBody"],"pet_","spine_")
                        local clippingSp = ui.createJsonCard(json.ui[name..ui.data.advanced])    --骨骼动画
                        card:addChild(clippingSp,12)
                        card_bg:addChild(card,-1) 
                        ui.widget.petJson:addChildFollowSlot("code_card2", card_bg )

                        end),
                        CCDelayTime:create(1.2) , CCCallFunc:create(function ()
                        ui.widget.petJson:removeChildFollowSlot("code_card2")
                        local tableDrop = {["items"]={}}
                        for k,v in pairs(backTable) do
                            table.insert( tableDrop.items, {["id"]=v.type, ["num"]=v.count} )
                        end
                        local drops = (require"ui.hook.drops").create(tableDrop, i18n.global.pet_restore_backe.string)
                        --drops:setScale(1)
                        ui.widget.mainLayer:getParent():addChild(drops, 1000)

                    end)})
                    ui.widget.btnReStore:runAction(seq)
                end
                petNetData.coutRsult(5,data.status)
                delWaitNet()
            end) 
        end

        local reStoreTip = require("ui.tips.confirm").create({title = "",text = i18n.global.pet_reStore.string,handle = onhandle})
 
        ui.widget.mainLayer:getParent():addChild(reStoreTip, 1000)
    end)
end

return ui
