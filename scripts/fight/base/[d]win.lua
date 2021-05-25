-- 胜利结算

local ui = {}

require "common.const"
require "common.func"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local i18n = require "res.i18n"
local audio = require "res.audio"
local particle = require "res.particle"

function ui.create()
    local layer = CCLayer:create()

    audio.play(audio.fight_win)

    -- dark bg
    local darkbg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    layer:addChild(darkbg)

    -- bg
    local bg = json.create(json.ui.zhandou_win)
    bg:playAnimation("animation")
    bg:appendNextAnimation("loop", -1)
    bg:setScale(view.minScale)
    bg:setPosition(scalep(480, 288))
    -- bg:addChildFollowSlot("code_bg", img.createUISprite(img.ui.fight_pay_bg_win))
    -- bg:addChildFollowSlot("code_bg2", img.createUISprite(img.ui.fight_pay_bg_win))
    layer:addChild(bg)
    layer.bg = bg

    -- title
    local title,title2 
    if i18n.getCurrentLanguage() == kLanguageChinese then
        title = img.createUISprite(img.ui.language_victory_cn)
        title2 = img.createUISprite(img.ui.language_victory_cn)
    elseif i18n.getCurrentLanguage() == kLanguageChineseTW then
        title = img.createUISprite(img.ui.language_victory_jp)
        title2 = img.createUISprite(img.ui.language_victory_jp)
    elseif i18n.getCurrentLanguage() == kLanguageJapanese then
        title = img.createUISprite(img.ui.language_victory_jp)
        title2 = img.createUISprite(img.ui.language_victory_jp)
    elseif i18n.getCurrentLanguage() == kLanguageKorean then
        title = img.createUISprite(img.ui.language_victory_kr)
        title2 = img.createUISprite(img.ui.language_victory_kr)
    elseif i18n.getCurrentLanguage() == kLanguageRussian then
        title = img.createUISprite(img.ui.language_victory_ru)
        title2 = img.createUISprite(img.ui.language_victory_ru)
    elseif i18n.getCurrentLanguage() == kLanguageTurkish then
        title = img.createUISprite(img.ui.language_victory_tr)
        title2 = img.createUISprite(img.ui.language_victory_tr)
    else
        title = img.createUISprite(img.ui.language_victory_us)
        title2 = img.createUISprite(img.ui.language_victory_us)
    end
    bg:addChildFollowSlot("code_victory",title)
    bg:addChildFollowSlot("code_victory2",title2)

    -- 左右礼花
    schedule(layer, bg:getEventTime("animation", "lihua"), function()
        local p1 = particle.create("lihua_left")
        p1:setScale(view.minScale)
        p1:setPosition(bg:getBonePositionRelativeToWorld("code_lihua"))
        layer:addChild(p1, 10)
        local p2 = particle.create("lihua_left")
        p2:setScale(view.minScale)
        p2:setScaleX(-view.minScale)
        p2:setPosition(bg:getBonePositionRelativeToWorld("code_lihua2"))
        layer:addChild(p2, 10)
    end)

    -- 顶部礼花
    schedule(layer, bg:getEventTime("animation", "lihua2"), function()
        local p = particle.create("lihua_top")
        p:setScale(view.minScale)
        p:setPosition(ccp(view.midX, view.maxY))
        layer:addChild(p, 10)
    end)

    -- content
    ui.addContent(layer)

    -- okNextBtn
    function layer.addOkNextButton(handler1, handler2)
        ui.addOkNextButton(layer, handler1, handler2)
    end

    -- okBtn
    function layer.addOkButton(handler, text)
        ui.addOkButton(layer, handler, text)
    end

    -- 奖励图标
    function layer.addRewardIcons(reward)
        ui.addRewardIcons(layer, reward)
    end

    -- VS和分数
    function layer.addVsScores(video)
        ui.addVsScores(layer, video)
    end

    -- 伤害统计
    function layer.addHurtsButton(atks, defs, hurts, video)
        require("fight.base.win").addHurtsButton(layer, atks, defs, hurts, video)
    end 

    -- 伤害总计
    function layer.addHurtsSum(hurts)
        ui.addHurtsSum(layer, hurts)
    end 

    -- 强化引导
    function layer.addEnhanceGuide(handlers)
        ui.addEnhanceGuide(layer, handlers)
    end

    layer:setTouchEnabled(true)
    layer:setTouchSwallowEnabled(true)

    return layer
end

function ui.addContent(layer)
    local content = CCLayer:create()
    content:setCascadeOpacityEnabled(true)
    content:setVisible(false)
    layer:addChild(content, 5)
    layer.content = content
    content:runAction(createSequence({
        CCDelayTime:create(1), CCShow:create(), CCFadeIn:create(0.3)
    }))
end

function ui.addOkNextButton(layer, handler1, handler2)
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

function ui.addOkButton(layer, handler, text)
    local okBtn0 = img.createLogin9Sprite(img.login.button_9_gold)
    okBtn0:setPreferredSize(CCSize(208, 75))
    okBtn0:setCascadeOpacityEnabled(true)
    local okBtn = SpineMenuItem:create(json.ui.button, okBtn0)
    local okSize = okBtn:getContentSize()
    local okText = text or i18n.global.dialog_button_confirm.string
    local okLabel = lbl.createFont1(22, okText, lbl.buttonColor)
    okLabel:setPosition(okSize.width/2, okSize.height/2)
    okBtn0:addChild(okLabel)
    okBtn:setCascadeOpacityEnabled(true)
    local okMenu = CCMenu:createWithItem(okBtn)
    okMenu:ignoreAnchorPointForPosition(false)
    okMenu:setCascadeOpacityEnabled(true)
    layer.bg:addChildFollowSlot("code_button", okMenu)
    okBtn:registerScriptTapHandler(function()
        okBtn:setEnabled(false)
        audio.play(audio.button)
        handler()
    end)
    addBackEvent(layer)
    function layer.onAndroidBack()
        handler()
    end
end

function ui.addRewardIcons(layer, reward, losed)
    reward = tablecp(reward or {})
    reward.equips = reward.equips or {}
    reward.items = reward.items or {}
    table.sort(reward.items, function(a, b)
        return a.id < b.id
    end)

    local w, h, gap = 84, 84, 12
    local count = #reward.equips + #reward.items
    local container = CCSprite:create()
    container:setContentSize(CCSize(count*w+(count-1)*gap, h))
    --container:setScale(view.minScale)
    --container:setPosition(scalep(480, 300))
    container:setCascadeOpacityEnabled(true)
    --layer.content:addChild(container)
    if losed then
        container:setScale(view.minScale)
        container:setPosition(scalep(480, 300))
        layer.content:addChild(container)
    else
        layer.bg:addChildFollowSlot("code_icon", container)
    end

    for i, t in ipairs(reward.items) do
        local icon = img.createItem(t.id, t.num)
        icon:setCascadeOpacityEnabled(true)
        local btn = SpineMenuItem:create(json.ui.button, icon)
        btn:setCascadeOpacityEnabled(true)
        btn:setPosition((i-0.5)*w+(i-1)*gap, h/2)
        local menu = CCMenu:createWithItem(btn)
        menu:setPosition(0, 0)
        menu:setCascadeOpacityEnabled(true)
        container:addChild(menu)
        btn:registerScriptTapHandler(function()
            layer:addChild(require("ui.tips.item").createForShow(t), 1000)
            audio.play(audio.button)
        end)
    end

    for i, e in ipairs(reward.equips) do
        local icon = img.createEquip(e.id, e.num)
        icon:setCascadeOpacityEnabled(true)
        local btn = SpineMenuItem:create(json.ui.button, icon)
        btn:setCascadeOpacityEnabled(true)
        btn:setPosition((#reward.items+i-0.5)*w+(#reward.items+i-1)*gap, h/2)
        local menu = CCMenu:createWithItem(btn)
        menu:setPosition(0, 0)
        menu:setCascadeOpacityEnabled(true)
        container:addChild(menu)
        btn:registerScriptTapHandler(function()
            layer:addChild(require("ui.tips.equip").createForShow(e), 1000)
            audio.play(audio.button)
        end)
    end
end

function ui.addVsScores(layer, video)
    local vs = img.createUISprite(img.ui.fight_pay_vs)
    vs:setScale(view.minScale)
    vs:setPosition(scalep(480, 300))
    layer.content:addChild(vs)

    local function addScoreInfo(info, score, delta, x)
        local y = 303
        local head = img.createPlayerHead(info.logo, info.lv)
        head:setScale(view.minScale)
        head:setPosition(scalep(x, y))
        head:setCascadeOpacityEnabled(true)
        layer.content:addChild(head, 1)

        local name = lbl.createFontTTF(18, info.name, lbl.whiteColor, true)
        name:setPosition(scalep(x, y+59))
        layer.content:addChild(name, 1)

        -- 如果声明了 noscore == true, 则不显示积分(3v3 普通结算界面不显示积分)
        if not video.noscore then
            local title = lbl.createFont2(18, i18n.global.fight_pvp_score.string, lbl.whiteColor, true)
            title:setPosition(scalep(x, y-72))
            layer.content:addChild(title, 1)

            local num1 = lbl.createFont3(28, score, ccc3(0xff, 0xd6, 0x67), true)
            num1:setAnchorPoint(ccp(1, 0))
            num1:setPosition(scalep(x-2, y-119))
            layer.content:addChild(num1, 1)

            local text = string.format("(%+d)", delta)
            local num2 = lbl.createFont2(20, text, ccc3(0xff, 0xd6, 0x67), true)
            num2:setAnchorPoint(ccp(0, 0))
            num2:setPosition(scalep(x+3, y-112))
            layer.content:addChild(num2, 1)
        end
    end

    addScoreInfo(video.atk, video.ascore, video.adelta, 480-150)
    addScoreInfo(video.def, video.dscore, video.ddelta, 480+150)
end

function ui.addHurtsButton(layer, atks, defs, hurts, video)
    print("进入基础addHurtsButton")
    local btn0 = img.createUISprite(img.ui.fight_hurts)
    btn0:setCascadeOpacityEnabled(true)
    local btn = SpineMenuItem:create(json.ui.button, btn0)
    btn:setCascadeOpacityEnabled(true)
    btn:setScale(view.minScale)
    btn:setPosition(scalep(920, 400))
    local btnMenu = CCMenu:createWithItem(btn)
    btnMenu:setCascadeOpacityEnabled(true)
    btnMenu:setPosition(0, 0)
    layer.content:addChild(btnMenu, 1)
    btn:registerScriptTapHandler(function()
        audio.play(audio.button)
        --layer:addChild(require("fight.hurts").create(atks, defs, hurts, video), 10)
		layer:addChild(require("fight.hurts").create(video.atk.camp, video.def.camp, hurts, video), 10)
    end)
end 

function ui.addHurtsSum(layer, hurts)
    local container = CCSprite:create()
    container:setCascadeOpacityEnabled(true)
    container:setScale(view.minScale)
    container:setPosition(scalep(480, 215))
    layer.content:addChild(container)
    local text = lbl.createFont2(18, i18n.global.fight_hurts_sum.string .. ":", ccc3(0xfc, 0xd7, 0x75))
    text:setAnchorPoint(ccp(0, 0.5))
    text:setPosition(0, 5)
    container:addChild(text)
    local value = 0
    for _, h in ipairs(hurts) do
        if h.pos <= 6 and h.value then
            value = value + h.value
        end
    end
    local num = lbl.createFont2(18, value, lbl.whiteColor)
    num:setAnchorPoint(ccp(0, 0.5))
    num:setPosition(text:boundingBox():getMaxX()+10, 5)
    container:addChild(num)
    container:setContentSize(CCSize(num:boundingBox():getMaxX(), 10))
end

function ui.addEnhanceGuide(layer, handlers)
    local label = lbl.createMixFont2(18, i18n.global.fight_guide.string, lbl.whiteColor, true)
    label:setPosition(scalep(480, 368))
    layer.content:addChild(label)

    local infos = {
        {
            icon = img.ui.fight_pay_go_smith, x = 480-170, y = 280,
            text = i18n.global.fight_pay_go_smith.string,
            handler = handlers.backToSmith,
        },
        {
            icon = img.ui.fight_pay_go_hero, x = 480, y = 280,
            text = i18n.global.fight_pay_go_hero.string,
            handler = handlers.backToHero,
        },
        {
            icon = img.ui.fight_pay_go_summon, x = 480+170, y = 280,
            text = i18n.global.fight_pay_go_summon.string,
            handler = handlers.backToSummon,
        },
    }

    for _, info in ipairs(infos) do
        local btn0 = img.createUISprite(info.icon)
        btn0:setCascadeOpacityEnabled(true)
        local btn = SpineMenuItem:create(json.ui.button, btn0)
        btn:setScale(view.minScale)
        btn:setPosition(scalep(info.x, info.y))
        btn:setCascadeOpacityEnabled(true)
        btn:registerScriptTapHandler(function()
            audio.play(audio.button)
            info.handler()
        end)
        local menu = CCMenu:createWithItem(btn)
        menu:setPosition(0, 0)
        menu:setCascadeOpacityEnabled(true)
        layer.content:addChild(menu)
        -- label
        local label = lbl.createMixFont1(14, info.text, ccc3(0xa1, 0xcc, 0xf2), true)
        label:setPosition(scalep(info.x, info.y-70))
        layer.content:addChild(label)
    end
end

return ui
