-- 失败结算

local ui = {}

require "common.const"
require "common.func"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local i18n = require "res.i18n"
local audio = require "res.audio"

function ui.create()
    local layer = CCLayer:create()

    audio.play(audio.fight_lose)

    -- dark bg
    local darkbg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    layer:addChild(darkbg)

    -- bg
    local bg = json.create(json.ui.zhandou_lose)
    bg:playAnimation("animation")
    bg:appendNextAnimation("loop", -1)
    bg:setScale(view.minScale)
    bg:setPosition(scalep(480, 288))
    --bg:addChildFollowSlot("code_bg", img.createUISprite(img.ui.fight_pay_bg_lose))
    --bg:addChildFollowSlot("code_bg2", img.createUISprite(img.ui.fight_pay_bg_lose))
    layer:addChild(bg)
    layer.bg = bg

    -- title
    local title 
    local posX = 0
    local posY = 0
    if i18n.getCurrentLanguage() == kLanguageChinese then
        posX = 8
        posY = -10
        title = img.createUISprite(img.ui.language_defeat_cn)
    elseif i18n.getCurrentLanguage() == kLanguageChineseTW then
        title = img.createUISprite(img.ui.language_defeat_jp)
    elseif i18n.getCurrentLanguage() == kLanguageJapanese then
        title = img.createUISprite(img.ui.language_defeat_jp)
    elseif i18n.getCurrentLanguage() == kLanguageKorean then
        title = img.createUISprite(img.ui.language_defeat_kr)
    elseif i18n.getCurrentLanguage() == kLanguageRussian then
        title = img.createUISprite(img.ui.language_defeat_ru)
    else
        title = img.createUISprite(img.ui.language_defeat_us)
    end
    bg:addChildFollowSlot("code_defeat",title)
    title:setPositionX(posX)
    title:setPositionY(posY)

    -- content
    require("fight.base.win").addContent(layer)

    -- okNextBtn
    function layer.addOkNextButton(handler1, handler2, text)
        ui.addOkNextButton(layer, handler1, handler2, text)
    end

    -- okBtn
    function layer.addOkButton(handler, text)
        require("fight.base.win").addOkButton(layer, handler, text)
    end

    -- 奖励图标
    function layer.addRewardIcons(reward, losed)
        require("fight.base.win").addRewardIcons(layer, reward, losed)
    end

    -- VS和分数
    function layer.addVsScores(video)
        require("fight.base.win").addVsScores(layer, video)
    end

    -- 伤害统计
    function layer.addHurtsButton(atks, defs, hurts, video)
        require("fight.base.win").addHurtsButton(layer, atks, defs, hurts, video)
    end 

    -- 伤害总计
    function layer.addHurtsSum(hurts)
        require("fight.base.win").addHurtsSum(layer, hurts)
    end 

    -- 强化引导
    function layer.addEnhanceGuide(handlers)
        require("fight.base.win").addEnhanceGuide(layer, handlers)
    end

    layer:setTouchEnabled(true)
    layer:setTouchSwallowEnabled(true)

    return layer
end

function ui.addOkNextButton(layer, handler1, handler2, text)
    local newNode = CCSprite:create()
    newNode:ignoreAnchorPointForPosition(false)
    newNode:setCascadeOpacityEnabled(true)

    local okBtn0 = img.createLogin9Sprite(img.login.button_9_gold)
    okBtn0:setPreferredSize(CCSize(208, 75))
    local okBtn = SpineMenuItem:create(json.ui.button, okBtn0)
    local okSize = okBtn:getContentSize()
    local okText = i18n.global.dialog_button_confirm.string
    local okLabel = lbl.createFont1(22, okText, lbl.buttonColor)
    okLabel:setPosition(okSize.width/2, okSize.height/2)
    okBtn0:addChild(okLabel)
    okBtn:setPosition(-150, 0)
    local okMenu = CCMenu:createWithItem(okBtn)
    okMenu:ignoreAnchorPointForPosition(false)
    newNode:addChild(okMenu)
    okBtn:registerScriptTapHandler(function()
        okBtn:setEnabled(false)
        audio.play(audio.button)
        handler1()
    end)

    addBackEvent(layer)
    function layer.onAndroidBack()
        handler1()
    end

    local nextBtn0 = img.createLogin9Sprite(img.login.button_9_gold)
    nextBtn0:setPreferredSize(CCSize(208, 75))
    local nextBtn = SpineMenuItem:create(json.ui.button, nextBtn0)
    local nextSize = okBtn:getContentSize()
    local nextText = i18n.global.arena_video_next.string
    if text then
        nextText = i18n.global.frdpk_video_next.string
    end
    local nextLabel = lbl.createFont1(22, nextText, lbl.buttonColor)
    nextLabel:setPosition(nextSize.width/2, nextSize.height/2)
    nextBtn0:addChild(nextLabel)
    nextBtn:setPosition(150, 0)
    --nextBtn:setCascadeOpacityEnabled(true)
    local nextMenu = CCMenu:createWithItem(nextBtn)
    nextMenu:ignoreAnchorPointForPosition(false)
    --nextMenu:setCascadeOpacityEnabled(true)
    --nextMenu:setPosition(0, 0)
    newNode:addChild(nextMenu)
    layer.bg:addChildFollowSlot("code_button", newNode)
    nextBtn:registerScriptTapHandler(function()
        nextBtn:setEnabled(false)
        audio.play(audio.button)
        handler2()
    end)
end

return ui
