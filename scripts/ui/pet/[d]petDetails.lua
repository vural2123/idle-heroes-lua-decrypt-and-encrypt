-- 装备tips, 有回调则为handler(equip)形式
-- equip = { id, num, owner(装备所有者), hero(英雄面板当前英雄) } 
--     除id外其他可选

local ui = {}

require "common.func"
require "common.const"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local audio = require "res.audio"
local i18n = require "res.i18n"
local petData       = require "config.pet"
local skilldata     = require "config.skill"
local buffdata      = require "config.petskill"
local DHComponents  = require "dhcomponents.DroidhangComponents"

local w = 470
local h = 460
function ui.create(petID)
    local actSkillMax = petData[petID].actSkillId + 120 -1
    ui.buffSkillMax = {}
    for k,v in pairs(petData[petID].pasSkillId) do
        ui.buffSkillMax[k] = v + 30 - 1
    end

    ui.petDetailsLayer = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY)) 
    ui.petDetailsLayer:setTouchEnabled(true)
    ui.petDetailsLayer:setTouchSwallowEnabled(true)

    local container = CCSprite:create()
    container:setContentSize(CCSize(960, 576))
    container:setPosition(scalep(480, 288))
    container:setScale(view.minScale)

    ui.petDetailsLayer.container = container
    ui.petDetailsLayer:addChild(container)

    local bg = img.createLogin9Sprite(img.login.dialog) 
        
    bg:setScale(0.1)
    bg:runAction(CCEaseBackOut:create(CCScaleTo:create(0.3, 1)))

    bg:setPreferredSize(CCSize(w, h))
    bg:setPosition(CCPoint(container:getContentSize().width/2,container:getContentSize().height/2))

    local labInfo = lbl.createFont1(24, i18n.global.ui_decompose_preview.string, ccc3(0xe6, 0xd0, 0xae))
    bg:addChild(labInfo,2)

    --后面有点影子
    local labInfoShade = lbl.createFont1(24, i18n.global.ui_decompose_preview.string, ccc3(0x59, 0x30, 0x1b))
    bg:addChild(labInfoShade,1)

    local closeBtn = SpineMenuItem:create(json.ui.button, img.createLoginSprite(img.login.button_close))
    closeBtn:setAnchorPoint(CCPoint(1, 1))
    closeBtn:setPosition(CCPoint(w,h))

    local closeMenu = CCMenu:createWithItem(closeBtn)
    closeMenu:setPosition(0, 0)
    bg:addChild(closeMenu,12)
    
    --激活按钮点击响应
    closeBtn:registerScriptTapHandler(function()        
        if ui.petDetailsLayer ~= nil then
            ui.petDetailsLayer:removeFromParent()
            ui.petDetailsLayer = nil
        end 
    end)

    --创建主要信息部分
    local framInfo = img.createUI9Sprite(img.ui.botton_fram_2)
    framInfo:setPreferredSize(CCSizeMake(410, 250))
    framInfo:setAnchorPoint(CCPoint(0, 0))
    framInfo:setPosition(CCPoint(30,138))
    bg:addChild(framInfo)

    --创建技能图标
    local skillIconBg = ui.creatSkillBtn(actSkillMax,framInfo)

    --创建说明文字
    print(actSkillMax)
    local nameMainSkill = lbl.createMix({font = 1, size = 16, text = i18n.skill[actSkillMax].skillName, width = 380 , color = ccc3(0x72, 0x3f, 0x23), align = kCCTextAlignmentLeft})
    nameMainSkill:setAnchorPoint(CCPoint(0,0))
    framInfo:addChild(nameMainSkill,20)

    local lvMainSkill = lbl.createFont1(16, "LV:120", ccc3(0x91, 0x3b, 0x38))
    framInfo:addChild(lvMainSkill,20)

    local labSkill = lbl.createMix({font = 1, size = 14, text = i18n.skill[actSkillMax].desc, width = 350 , color = ccc3(0x8e, 0x5d, 0x43), align = kCCTextAlignmentLeft})
    framInfo:addChild(labSkill,20)

    --创建buff技能
    local buffSkill1 = ui.creatSkillBtn(ui.buffSkillMax[1] , framInfo , 1)
    local buffSkill2 = ui.creatSkillBtn(ui.buffSkillMax[2] , framInfo , 2)
    local buffSkill3 = ui.creatSkillBtn(ui.buffSkillMax[3] , framInfo , 3)
    local buffSkill4 = ui.creatSkillBtn(ui.buffSkillMax[4] , framInfo , 4)

    local buffSkilllv1 = lbl.create({font=2, size=16, text="LV:30", color=ccc3(255, 246, 223)})
    buffSkilllv1:setPosition(CCPoint(buffSkill1:getContentSize().width/2,13))
    buffSkill1:addChild(buffSkilllv1,21)

    local buffSkilllv2 = lbl.create({font=2, size=16, text="LV:30", color=ccc3(255, 246, 223)})
    buffSkilllv2:setPosition(CCPoint(buffSkill1:getContentSize().width/2,13))
    buffSkill2:addChild(buffSkilllv2,21)
        
    local buffSkilllv3 = lbl.create({font=2, size=16, text="LV:30", color=ccc3(255, 246, 223)})
    buffSkilllv3:setPosition(CCPoint(buffSkill1:getContentSize().width/2,13))
    buffSkill3:addChild(buffSkilllv3,21)

    local buffSkilllv4 = lbl.create({font=2, size=16, text="LV:30", color=ccc3(255, 246, 223)})
    buffSkilllv4:setPosition(CCPoint(buffSkill1:getContentSize().width/2,13))
    buffSkill4:addChild(buffSkilllv4,21)

    DHComponents:mandateNode(labInfo        ,"yw_petDetails_labInfo")
    DHComponents:mandateNode(labInfoShade   ,"yw_petDetails_labInfoShade")
    DHComponents:mandateNode(skillIconBg    ,"yw_petDetails_skillIconBg")
    DHComponents:mandateNode(nameMainSkill  ,"yw_petDetails_nameMainSkill")
    DHComponents:mandateNode(lvMainSkill    ,"yw_petDetails_lvMainSkill")
    DHComponents:mandateNode(labSkill       ,"yw_petDetails_labSkill")
    DHComponents:mandateNode(buffSkill1     ,"yw_petDetails_buffSkill1")
    DHComponents:mandateNode(buffSkill2     ,"yw_petDetails_buffSkill2")
    DHComponents:mandateNode(buffSkill3     ,"yw_petDetails_buffSkill3")
    DHComponents:mandateNode(buffSkill4     ,"yw_petDetails_buffSkill4")

    container:addChild(bg)
    -- ui.petDetailsLayer:setPosition(CCPoint(-view.maxX/2,-view.maxY/2))
    return ui.petDetailsLayer
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
            local skillID = ui.buffSkillMax[key]
            tip = require("ui.tips.skill").createForPet(skillID)
            --tip:setPosition(CCPoint(240,320))
            local pObj = ui.petDetailsLayer.container
            tip:setPosition(CCPoint(pObj:getContentSize().width/2, pObj:getContentSize().height/2))
            ui.petDetailsLayer.container:addChild(tip,21)
        elseif eventType == "ended" then
            tip:removeFromParent()
        end
        return true
    end
    skillIconBg:registerScriptTouchHandler(onTouch)
    skillIconBg:setTouchEnabled(true)
    skillIconBg:setTouchSwallowEnabled(true)

    return skillIconBg
end

return ui
