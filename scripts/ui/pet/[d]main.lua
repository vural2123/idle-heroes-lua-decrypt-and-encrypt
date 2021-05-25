-- 战宠界面

local ui = {}

require "common.func"
local view      = require "common.view"
local img       = require "res.img"
local lbl       = require "res.lbl"
local json      = require "res.json"
local audio     = require "res.audio"
local i18n      = require "res.i18n"
local bag       = require "data.bag"
local midas     = require "ui.midas.main"
local midasdata = require "data.midas"
local petdata       = require "config.pet"

function ui.create(backlayer, tagType)
    ui.widget = {}
    ui.data = {}
    ui.widget.layer = CCLayer:create()
    ui.widget.layer:setScale(view.minScale)

    local petNum = 0
    local petKey = {}
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
        img.load(img.packedOthers["spine_ui_"..name.."1"])
        img.load(img.packedOthers["spine_ui_"..name.."2"])
        img.load(img.packedOthers["spine_ui_"..name.."3"])
        img.load(img.packedOthers["spine_ui_"..name.."4"])
    end

    -- bg
    local bg = img.createUISprite(img.ui.pet_bg)
    
    bg:setPosition(view.midX, view.midY)
    ui.widget.layer:addChild(bg)

    --骨骼动画，专用于切换
    ui.widget.petJson = json.create(json.ui.pet_json)
    ui.widget.petJson:setPosition(view.midX, view.midY)
    ui.widget.layer:addChild(ui.widget.petJson, 21)

    --[[
    ui.widget.petJsonForAm = json.create(json.ui.pet_json)
    ui.widget.petJson:setScale(view.minScale)
    ui.widget.petJson:setPosition(view.midX, view.midY)
    ui.widget.layer:addChild(ui.widget.petJson, 21)
    ]]
    --上方相关节点层
    local jsonNode = CCNode:create()
    ui.widget.petJson:addChildFollowSlot("code_top", jsonNode )
    --金币相关UI
    local goldBg = img.createUI9Sprite(img.ui.main_coin_bg)
    goldBg:setPreferredSize(CCSizeMake(174, 40))
    --ui.widget.layer:addChild(goldBg,30)
    jsonNode:addChild(goldBg)

    local goldIcon = img.createItemIcon2(ITEM_ID_COIN)
    goldIcon:setPosition(CCPoint(5, goldBg:getContentSize().height/2+2))

    goldBg:addChild(goldIcon)
    ui.widget.goldLabel =lbl.createFont2(16, num2KM(bag.coin()), ccc3(255, 246, 223)) 
    ui.widget.goldLabel:setPosition(77, 23)
    goldBg:addChild(ui.widget.goldLabel)

    local goldPlusImg = img.createUISprite(img.ui.main_icon_plus)
    ui.widget.goldPlusBtn = HHMenuItem:create(goldPlusImg)
    ui.widget.goldPlusBtn:setPosition(CCPoint(goldBg:getContentSize().width-18, goldBg:getContentSize().height/2+2))
    local goldPlusMenu = CCMenu:createWithItem(ui.widget.goldPlusBtn)
    goldPlusMenu:setPosition(CCPoint(0, 0))
    goldBg:addChild(goldPlusMenu)

    --恶魔之魂相关UI
    local soulBg = img.createUI9Sprite(img.ui.main_coin_bg)
    soulBg:setPreferredSize(CCSizeMake(174, 40))
    jsonNode:addChild(soulBg)

    local soulIcon = img.createItemIcon2(ITEM_ID_PET_DEVIL)
    soulIcon:setPosition(5, 23)
    soulBg:addChild(soulIcon)
    ui.widget.soulLabel = lbl.createFont2(16, num2KM(bag.devil()), ccc3(255, 246, 223))
    ui.widget.soulLabel:setPosition(90, 23)
    soulBg:addChild(ui.widget.soulLabel)

    --混沌石相关UI
    local stoneBg = img.createUI9Sprite(img.ui.main_coin_bg)
    stoneBg:setPreferredSize(CCSizeMake(174, 40))
    jsonNode:addChild(stoneBg)

    local stoneIcon = img.createItemIcon2(ITEM_ID_PET_CHAOS)
    stoneIcon:setPosition(5, 23)
    stoneBg:addChild(stoneIcon)          
    ui.widget.stoneLabel = lbl.createFont2(16, num2KM(bag.chaos()), ccc3(255, 246, 223))
    ui.widget.stoneLabel:setPosition(90, 23)
    stoneBg:addChild(ui.widget.stoneLabel)

    --返回按钮
    ui.widget.backBtn = HHMenuItem:create(img.createUISprite(img.ui.back))
    ui.widget.backBtn:setPosition(scalep(35, 546))
    local backMenu = CCMenu:createWithItem(ui.widget.backBtn)
    backMenu:setPosition(0, 0)
    jsonNode:addChild(backMenu)

    --帮助按钮
    ui.widget.helpImg = img.createUISprite(img.ui.btn_help)
    ui.widget.helpBtn = SpineMenuItem:create(json.ui.button, ui.widget.helpImg)
    local helpMenu = CCMenu:createWithItem(ui.widget.helpBtn)
    helpMenu:setPosition(CCPoint(0, 0))
    jsonNode:addChild(helpMenu)

    local DHComponents = require("dhcomponents.DroidhangComponents")
    DHComponents:mandateNode(goldBg,"px_peimainui_goldBg")
    DHComponents:mandateNode(soulBg,"px_peimainui_soulBg")
    DHComponents:mandateNode(stoneBg,"px_peimainui_stoneBg")
    DHComponents:mandateNode(ui.widget.helpBtn,"px_petmainui_helpBtn")
    DHComponents:mandateNode(ui.widget.backBtn,"px_peimainui_backBtn")

    --依赖于骨骼动画的位置，在更新之前位置不对，因此需要手动判断方位
    autoLayoutShift(goldBg, true)
    autoLayoutShift(soulBg, true)
    autoLayoutShift(stoneBg, true)
    autoLayoutShift(ui.widget.backBtn, true, false, true, false)
    autoLayoutShift(ui.widget.helpBtn, true, false, false, true)

    ui.CallFun()
    ui.gotoPetMainUI()

    ui.widget.layer.onAndroidBack = function ()
        audio.play(audio.button)
        replaceScene(require("ui.town.main").create())  
    end
    addBackEvent(ui.widget.layer)

    return ui.widget.layer
end

function ui.gotoPetInfo(data)
    ui.widget.petInfoVec = require("ui.pet.petInfo").create(data , ui.widget.petJson , ui.widget.layer)
    ui.widget.petJson:playAnimation("switch")
    ui.createMaskLayer(0.4)
    ui.widget.layer:runAction(createSequence(
        {
            CCDelayTime:create(0.35),
            CCCallFunc:create(function() 
                require("ui.pet.mainui").clear( ui.widget.petJson )
                ui.widget.mainui = nil
            end)
        }))
end

function ui.gotoPetMainUI()
    ui.createMaskLayer(0.4)
    ui.widget.mainui = require("ui.pet.mainui").create(ui.widget.petJson)
    ui.widget.petJson:playAnimation("switch2")
    --移动到上一次选定的宠物位置
    require("ui.pet.mainui").forceMove()
    ui.widget.layer:runAction(createSequence(
    {
        CCDelayTime:create(0.35),
        CCCallFunc:create(function() 
            require("ui.pet.petInfo").clear( ui.widget.petJson )
            ui.widget.petInfoVec = nil
        end)
    }))

end

function ui.CallFun()
    ui.widget.goldPlusBtn:registerScriptTapHandler(function ()
        audio.play(audio.midas)
        local midasdlg = midas.create()
        ui.widget.layer:getParent():addChild(midasdlg, 1001)
    end)

    ui.widget.backBtn:registerScriptTapHandler(function ()
        audio.play(audio.button)
        --特殊处理删除一次这个
        --ui.widget.infoLvSpine:playAnimation("skill_upgrade")
        ui.widget.petJson:removeChildFollowSlot("code_attribute_position2")

        if ui.widget.petInfoVec == nil then
            --卸载魔兽的图片

            local petNum = 0
            local petKey = {}
            for k,v in pairs(petdata) do
                petNum = petNum + 1 
                table.insert(petKey,k)
            end
            table.sort(petKey)

            --卸载魔兽的图片
            for i=1,petNum do
                local myId = petKey[i]
                local name = string.gsub(petdata[myId]["petBody"],"pet_","")
                name = string.gsub(name,"_","")
                img.unload(img.packedOthers["spine_ui_"..name.."1"])
                img.unload(img.packedOthers["spine_ui_"..name.."2"])
                img.unload(img.packedOthers["spine_ui_"..name.."3"])
                img.unload(img.packedOthers["spine_ui_"..name.."4"])
            end

            replaceScene(require("ui.town.main").create()) 
        else
            ui.gotoPetMainUI()
        end
    end)

    ui.widget.helpBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        ui.widget.layer:getParent():addChild(require("ui.help").create(i18n.global.pet_help.string, i18n.global.help_title.string), 1000)
    end)

    --每帧调用的函数
    local function onUpdate()
        local reddot_offset = 5
        if midasdata.showRedDot() then
            addRedDot(ui.widget.goldPlusBtn, {
                px=ui.widget.goldPlusBtn:getContentSize().width-reddot_offset,
                py=ui.widget.goldPlusBtn:getContentSize().height-reddot_offset,
            })
        else
            delRedDot(ui.widget.goldPlusBtn)
        end
        ui.widget.goldLabel:setString(num2KM(bag.coin()))
    end
    ui.widget.layer:scheduleUpdateWithPriorityLua(onUpdate)
end

--创建一个短暂的吞噬触摸层
function ui.createMaskLayer(time)
    local maskLayer = CCLayer:create()
    maskLayer:setTouchEnabled(true)
    ui.widget.layer:addChild(maskLayer,100)
    maskLayer:registerScriptTouchHandler(function (event,x,y)
        if event == "began" then
            return false
        end
    end)

    local delay = CCDelayTime:create(time)
    local callfunc = CCCallFunc:create(function ()
        maskLayer:removeFromParent()
    end)
    local arr = CCArray:create()
    arr:addObject(delay)
    arr:addObject(callfunc)
    ui.widget.layer:runAction(CCSequence:create(arr))
end

--加上某一类型的货币
function ui.addItem(itemTable)
    for k,v in pairs(itemTable) do
        if v.type == ITEM_ID_COIN then
            print("加入金币 - "..v.count)
            bag.addCoin(v.count)
            ui.widget.goldLabel:setString(num2KM(bag.coin()))
        elseif v.type == ITEM_ID_PET_DEVIL then
            print("加入Devil - "..v.count)
            bag.addDevil(v.count)
            ui.widget.soulLabel:setString(num2KM(bag.devil()))
        elseif v.type == ITEM_ID_PET_CHAOS then
            print("加入CHAOS - "..v.count)
            bag.addChaos(v.count)
            ui.widget.stoneLabel:setString(num2KM(bag.chaos()))
        end
    end
end

--减去某一类型的货币(参数为table,每一项有:type,count两种值)
function ui.subItem(itemTable)
    for k,v in pairs(itemTable) do
        local bagCount = bag.items.find(v.type)
        if bagCount.num < v.count then
            showToast(string.format(i18n.global.pet_smaterial_not_enough.string))
            return false
        end
    end

    for k,v in pairs(itemTable) do
        if v.type == ITEM_ID_COIN then
            bag.subCoin(v.count)
            ui.widget.goldLabel:setString(num2KM(bag.coin()))
        elseif v.type == ITEM_ID_PET_DEVIL then
            bag.subDevil(v.count)
            ui.widget.soulLabel:setString(num2KM(bag.devil()))
        elseif v.type == ITEM_ID_PET_CHAOS then
            bag.subChaos(v.count)
            ui.widget.stoneLabel:setString(num2KM(bag.chaos()))
        end
    end
    return true
end

function ui.hasItem(itemTable)
    for k,v in pairs(itemTable) do
        local bagCount = bag.items.find(v.type)
        if bagCount.num < v.count then
            showToast(string.format(i18n.global.pet_smaterial_not_enough.string))
            return false
        end
    end

    return true
end

return ui
