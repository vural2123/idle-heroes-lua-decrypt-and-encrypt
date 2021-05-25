local ui = {}

require "common.func"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local i18n = require "res.i18n"
local audio = require "res.audio"
local net = require "net.netClient"
local heros = require "data.heros"
local cfghero = require "config.hero"
local player = require "data.player"
local cfgbrave = require "config.brave"
local databrave = require "data.brave"
local particle = require "res.particle"

function ui.create()
    local layer = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
   
    img.load(img.packedOthers.ui_brave)
    --img.load(img.packedOthers.spine_ui_yuanzheng_jiemian)
    img.load(img.packedOthers.spine_ui_yuanzheng)
    
    local btnBackSprite = img.createUISprite(img.ui.back)
    local btnBack = SpineMenuItem:create(json.ui.button, btnBackSprite)
    btnBack:setScale(view.minScale)
    btnBack:setPosition(scalep(35, 546))
    local menuBack = CCMenu:createWithItem(btnBack)
    menuBack:setPosition(0, 0)
    layer:addChild(menuBack, 10)
    layer.back = btnBack
    btnBack:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer:removeFromParentAndCleanup(true)
    end)

    local btnInfoSprite = img.createUISprite(img.ui.btn_help)
    local btnInfo = SpineMenuItem:create(json.ui.button, btnInfoSprite)
    btnInfo:setScale(view.minScale)
    btnInfo:setPosition(scalep(960-155, 546))
    local menuInfo = CCMenu:createWithItem(btnInfo)
    menuInfo:setPosition(0, 0)
    layer:addChild(menuInfo, 10)
    btnInfo:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer:addChild(require("ui.help").create(i18n.global.help_brave.string, i18n.global.help_title.string), 1000)
    end)

    local anim = json.create(json.ui.yuanzheng)
    anim:setScale(view.minScale)
    anim:setPosition(scalep(480, 259))
    anim:playAnimation("animation_in1")
    anim:appendNextAnimation("loop1", -1)
    layer:addChild(anim)

    local shopBg = img.createUISprite(img.ui.brave_shopbg)
    shopBg:setScale(view.minScale)
    shopBg:setAnchorPoint(CCPoint(1, 1))
    shopBg:setPosition(scalep(980, 582))
    layer:addChild(shopBg)

    autoLayoutShift(btnBack)
    autoLayoutShift(shopBg)
    autoLayoutShift(btnInfo)
  
    local particle_scale = view.minScale
    local particle_shop = particle.create("ui_shop")
    particle_shop:setScale(particle_scale)
    particle_shop:setPosition(scalep(910, 530))
    layer:addChild(particle_shop, 100)

    autoLayoutShift(particle_shop)

    local btnShop0 = img.createUISprite(img.ui.brave_store_icon)
    local btnShop = HHMenuItem:createWithScale(btnShop0, 1)
    btnShop:setPosition(CCPoint(shopBg:getContentSize().width-70, shopBg:getContentSize().height-51))
    local btnShopMenu = CCMenu:createWithItem(btnShop)
    btnShopMenu:setPosition(CCPoint(0, 0))
    shopBg:addChild(btnShopMenu)
    btnShop:registerScriptTapHandler(function()
        audio.play(audio.button)
        local shop = require "ui.braveshop.main"
        layer:addChild(shop.create(), 1000)
    end)

    --local innerBg = img.createUI9Sprite(img.ui.brave_bg_frame)
    --innerBg:setPreferredSize(CCSize(774, 422))
    --innerBg:setScale(view.minScale)
    --innerBg:setPosition(scalep(409, 246))
    --layer:addChild(innerBg)

    --local circleBg = img.createUISprite(img.ui.brave_shoot_bg)
    --circleBg:setPosition(387, 214)
    --innerBg:addChild(circleBg, 1)
    
    --local animBg = img.createUISprite(img.ui.brave_first_bg)
    --animBg:setPosition(387, 214)
    --innerBg:addChild(animBg)


    local battleBar
    local showTime
    if databrave.status == 0 then
        local showMons = json.createSpineHero(cfgbrave[databrave.id].picId)
        showMons:setScale(0.7)
        anim:addChildFollowSlot("code_hero", showMons)


        local btnStartSprite = img.createUI9Sprite(img.ui.btn_10)
        btnStartSprite:setPreferredSize(CCSize(220, 60))
        local labStart = lbl.createFont1(20, i18n.global.brave_btn_battle.string, ccc3(0x73, 0x3b, 0x05))
        labStart:setPosition(btnStartSprite:getContentSize().width/2, btnStartSprite:getContentSize().height/2)
        btnStartSprite:addChild(labStart)

        local btnStart = HHMenuItem:createWithScale(btnStartSprite, 1)
        local menuStart = CCMenu:createWithItem(btnStart)
        menuStart:setPosition(0, 0)
        --btnStart:setAnchorPoint(0.5, 0)
        layer:addChild(menuStart, 3)
        btnStart:setScale(view.minScale)
        btnStart:setPosition(scalep(480, 40))
    
        btnStart:registerScriptTapHandler(function()
            --anim:playAnimation("animation2")
            layer:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.8), CCCallFunc:create(function()
                replaceScene(require("ui.brave.map").create())
            end)))
        end)
    
        local timeSp = CCSprite:create()
        timeSp:setScale(view.minScale)
        timeSp:setPosition(scalep(480, 505))
        layer:addChild(timeSp)

        local clock = json.create(json.ui.clock)
        clock:setPosition(-66, 0)
        clock:playAnimation("animation", -1)
        timeSp:addChild(clock)

        showTime = lbl.createFont2(16, time2string(databrave.cd - os.time()), ccc3(0xc3, 0xff, 0x42))
        showTime:setPosition(-10, 0)
        timeSp:addChild(showTime)
        
        local showLab = lbl.createFont2(16, i18n.global.brave_end_time.string)
        showLab:setAnchorPoint(ccp(0, 0.5))
        showLab:setPosition(showTime:boundingBox():getMaxX() + 2, 0)
        timeSp:addChild(showLab)

        local lTitleBg = img.createUISprite(img.ui.brave_title)
        lTitleBg:setAnchorPoint(1,1)
        lTitleBg:setScale(view.minScale)
        lTitleBg:setPosition(scalep(480, 576))
        layer:addChild(lTitleBg)

        local rTitleBg = img.createUISprite(img.ui.brave_title)
        rTitleBg:setFlipX(true)
        rTitleBg:setAnchorPoint(0,1)
        rTitleBg:setScale(view.minScale)
        rTitleBg:setPosition(scalep(480, 576))
        layer:addChild(rTitleBg)

        local TitleSp = CCSprite:create()
        TitleSp:setScale(view.minScale)
        TitleSp:setPosition(scalep(480, 550))
        layer:addChild(TitleSp)

        local showTitle = lbl.createMixFont3(26, i18n.brave[databrave.id].name, ccc3(0xfa, 0xd8, 0x69))
        TitleSp:addChild(showTitle)
        
        autoLayoutShift(lTitleBg)
        autoLayoutShift(rTitleBg)
        autoLayoutShift(TitleSp)
        autoLayoutShift(timeSp)
    else
        anim:playAnimation("animation_in2")
        anim:appendNextAnimation("loop2", -1)
       
        --local battleBarSp = img.createUISprite(img.ui.brave_btn_fight0)
        --battleBar = createProgressBar(battleBarSp) 
        --battleBar:setAnchorPoint(0.5, 0)
        --innerBg:addChild(battleBar, 3)
        --battleBar:setPosition(innerBg:getContentSize().width/2, 9)

        --local highCor = img.createUISprite(img.ui.brave_btn_fight00)
        --highCor:setPosition(battleBar:boundingBox():getMidX(), battleBar:boundingBox():getMidY())
        --innerBg:addChild(highCor, 5)

        local timeBg = img.createUI9Sprite(img.ui.btn_7)
        timeBg:setPreferredSize(CCSize(220, 60))
        timeBg:setScale(view.minScale)
        timeBg:setPosition(scalep(480, 40))
        layer:addChild(timeBg)


        showTime = lbl.createFont2(18, time2string(databrave.cd - os.time()), ccc3(255, 246, 223))
        showTime:setPosition(timeBg:getContentSize().width/2, timeBg:getContentSize().height/2)
        timeBg:addChild(showTime, 4)
    end

    --local lefDerocation = img.createUISprite(img.ui.brave_decoration)
    --lefDerocation:setAnchorPoint(ccp(1, 0))
    --lefDerocation:setPosition(innerBg:getContentSize().width/2 + 1, 10)
    --innerBg:addChild(lefDerocation, 2)

    --local rigDerocation = img.createUISprite(img.ui.brave_decoration)
    --rigDerocation:setFlipX(true)
    --rigDerocation:setAnchorPoint(ccp(0, 0))
    --rigDerocation:setPosition(innerBg:getContentSize().width/2 - 1, 10)
    --innerBg:addChild(rigDerocation, 2)

    layer:registerScriptTouchHandler(function() return true end)
    layer:setTouchEnabled(true)

    layer:scheduleUpdateWithPriorityLua(function()
        showTime:setString(time2string(databrave.cd - os.time()))
        if databrave.cd <= os.time() then
            databrave.isPull = false
            replaceScene(require("ui.town.main").create())
        end
        if databrave.status ~= 0 and battleBar then
            battleBar:setPercentage((databrave.cd - os.time())/86400*100)
        end
    end)

    addBackEvent(layer)
    function layer.onAndroidBack()
        replaceScene(require("ui.town.main").create())
    end
    local function onEnter()
        print("onEnter")
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
            --img.unload(img.packedOthers.spine_ui_yuanzheng_jiemian)
            img.unload(img.packedOthers.spine_ui_yuanzheng)
            img.unload(img.packedOthers.ui_brave)
        end
    end)

    return layer 
end

return ui
