-- 总结算

local ui = {}

require "common.const"
require "common.func"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local i18n = require "res.i18n"
local audio = require "res.audio"
local herosdata = require "data.heros"

function ui.create(video)
    local anim_name = json.ui.p3v3jiesuan_d
    local code_name = "code_defeat"
    local winlose = "defeat"
    local anim_birth = "start"
    local anim_loop  = "loop"
    local win_count = 0
    for ii=1,#video.wins do
        if video.wins[ii] == true then
            win_count = win_count + 1
        end
    end
    if win_count >= 2 then
        anim_name = json.ui.p3v3jiesuan_v
        code_name = "code_victory"
        winlose = "victory"
        --anim_birth = "win_birth"
        --anim_loop  = "win_loop"
    end
    local layer = CCLayer:create()
    -- dark bg
    local darkbg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY*0.8))
    layer:addChild(darkbg)

    json.load(anim_name)
    local anim = DHSkeletonAnimation:createWithKey(anim_name)
    anim:setScale(view.minScale)
    anim:scheduleUpdateLua()
    anim:setPosition(scalep(480, 288))
    layer:addChild(anim, 1)

    local atitle
    if i18n.getCurrentLanguage() == kLanguageChinese then
        atitle = img.createUISprite(img.ui["language_" .. winlose .. "_cn"])
    elseif i18n.getCurrentLanguage() == kLanguageChineseTW then
        atitle = img.createUISprite(img.ui["language_" .. winlose .. "_jp"])
    elseif i18n.getCurrentLanguage() == kLanguageJapanese then
        atitle = img.createUISprite(img.ui["language_" .. winlose .. "_jp"])
    elseif i18n.getCurrentLanguage() == kLanguageKorean then
        atitle = img.createUISprite(img.ui["language_" .. winlose .. "_kr"])
    elseif i18n.getCurrentLanguage() == kLanguageRussian then
        atitle = img.createUISprite(img.ui["language_" .. winlose .. "_ru"])
    else
        atitle = img.createUISprite(img.ui["language_" .. winlose .. "_us"])
    end
    anim:addChildFollowSlot(code_name, atitle)

    local base_win = require"fight.base.win"
    local function okHandler()
        require("fight.pvpf3.loading").backToUI(video)
    end

    local arr = CCArray:create()
    arr:addObject(CCCallFunc:create(function()
        anim:playAnimation(anim_birth)
    end))
    --arr:addObject(CCDelayTime:create(40.0/30))
    arr:addObject(CCCallFunc:create(function()
        ui.addContent(layer)
        ui.addOkButton(layer, okHandler)
        ui.addVsScores(layer, video)
    end))
    local remain_cd = anim:getAnimationTime(anim_birth)
    if remain_cd > 0 then
        arr:addObject(CCDelayTime:create(remain_cd))
    end
    arr:addObject(CCCallFunc:create(function()
        anim:playAnimation(anim_loop, -1)
    end))

    layer:runAction(CCSequence:create(arr))

    addBackEvent(layer)
    function layer.onAndroidBack()
        okHandler()
    end
    layer:setTouchEnabled(true)
    layer:setTouchSwallowEnabled(true)
    
    return layer
end

function ui.addContent(layer)
    local content = CCLayer:create()
    content:setCascadeOpacityEnabled(true)
    layer:addChild(content, 5)
    layer.content = content
end

function ui.addOkButton(layer, handler)
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
    okBtn:setScale(view.minScale)
    okBtn:setPosition(scalep(480, 101))
    local okMenu = CCMenu:createWithItem(okBtn)
    okMenu:setPosition(CCPoint(0, 0))
    layer:addChild(okMenu)
    okBtn:registerScriptTapHandler(function()
        okBtn:setEnabled(false)
        audio.play(audio.button)
        handler()
    end)
end

function ui.addVsScores(layer, video)
    local win_count = 0
    for ii=1,#video.wins do
        if video.wins[ii] == true then
            win_count = win_count + 1
        end
    end

    local vs = img.createUISprite(img.ui.fight_pay_vs)
    vs:setScale(view.minScale)
    vs:setPosition(scalep(480, 287))
    layer.content:addChild(vs)

    -- rate
    local lbl_rate = lbl.createFont3(28, win_count .. " : " .. (#video.wins-win_count), ccc3(0xff, 0xd6, 0x67), true)
    lbl_rate:setPosition(scalep(480, 352))
    layer.content:addChild(lbl_rate)

    local function addHeadFlag(obj)
        local flag = img.createUISprite(img.ui.friend_pvp_captain)
        flag:setAnchorPoint(CCPoint(0, 1))
        flag:setPosition(CCPoint(0, obj:getContentSize().height))
        obj:addChild(flag, 10000)
    end

    local function addScoreInfo(info, score, delta, x)
        local y = 321
        local head_scale = 0.7
        local head_step = 75
        local head = img.createPlayerHead(info.mbrs[1].logo, info.mbrs[1].lv)
        head:setScale(head_scale*view.minScale)
        head:setPosition(scalep(x-head_step, y))
        head:setCascadeOpacityEnabled(true)
        layer.content:addChild(head, 1)
        if info.mbrs[1].uid == info.leader then
            addHeadFlag(head)
        end
        local head2 = img.createPlayerHead(info.mbrs[2].logo, info.mbrs[2].lv)
        head2:setScale(head_scale*view.minScale)
        head2:setPosition(scalep(x-0, y))
        head2:setCascadeOpacityEnabled(true)
        layer.content:addChild(head2, 1)
        if info.mbrs[2].uid == info.leader then
            addHeadFlag(head2)
        end
        local head3 = img.createPlayerHead(info.mbrs[3].logo, info.mbrs[3].lv)
        head3:setScale(head_scale*view.minScale)
        head3:setPosition(scalep(x+head_step, y))
        head3:setCascadeOpacityEnabled(true)
        layer.content:addChild(head3, 1)
        if info.mbrs[3].uid == info.leader then
            addHeadFlag(head3)
        end

        local name = lbl.createFontTTF(18, info.name, lbl.whiteColor, true)
        name:setPosition(scalep(x, y+59))
        layer.content:addChild(name, 1)

        local title = lbl.createFont2(18, i18n.global.fight_pvp_score.string, lbl.whiteColor, true)
        title:setPosition(scalep(x, y-72))
        layer.content:addChild(title, 1)

        local num1 = lbl.createFont3(28, score, ccc3(0xff, 0xd6, 0x67), true)
        num1:setAnchorPoint(ccp(1, 0.5))
        num1:setPosition(scalep(x+10, y-99))
        layer.content:addChild(num1, 1)

        local text = string.format("(%+d)", delta)
        local num2 = lbl.createFont2(20, text, ccc3(0xff, 0xd6, 0x67), true)
        num2:setAnchorPoint(ccp(0, 0.5))
        num2:setPosition(scalep(x+15, y-99))
        layer.content:addChild(num2, 1)
    end

    addScoreInfo(video.ref.atk, video.ascore, video.adelta, 480-165)
    addScoreInfo(video.ref.def, video.dscore, video.ddelta, 480+165)
end

return ui
