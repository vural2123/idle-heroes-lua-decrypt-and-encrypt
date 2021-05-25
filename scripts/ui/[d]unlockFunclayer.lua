local ui = {}

require "common.func"
require "common.const"
local view = require "common.view"
local i18n = require "res.i18n"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local audio = require "res.audio"
local player = require "data.player"

ui.WHICH = {
    HOOK = 1,               -- 完成关卡2-5
    ARENA = 2,              -- lv. 20
    TRAIN = 3,              -- lv. 7
    SMITH = 4,              -- lv. 12
    MIDAS = 5,              -- lv. 13
    BLACKMARKET = 6,        -- lv. 10
    CASINO = 7,             -- lv. 15
    GUILD = 8,              -- lv. 25
    TRIAL = 9,              -- lv. 30
    TAVERN = 10,            -- lv. 40
}

local txt_color_gold = ccc3(0xfd, 0xee, 0x9c)

function ui.create(which, callback)
    local layer = CCLayer:create()
    layer:setCascadeOpacityEnabled(true)
    
    -- dark bg
    local darkbg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    layer:addChild(darkbg)

    -- lbl_feature
    local lbl_feature = lbl.createFont1(26, i18n.global.unlock_func_title.string, ccc3(0xfa, 0xdf, 0x60), true)
    lbl_feature:setPosition(scalep(480, 483))
    layer:addChild(lbl_feature, 2)

    local offset_y = -30
    -- lbl_building
    local lbl_building = lbl.createFont1(20, "", ccc3(0xff, 0xd1, 0x33), true)
    lbl_building:setPosition(scalep(480, 257+offset_y))
    layer:addChild(lbl_building, 2)

    -- lbl_func_des
    local lbl_func_des = lbl.createMix({size=18, text="", color=ccc3(0xff, 0xfb, 0xdc), minScale=true, 
                                                align=kCCTextAlignmentCenter, width=400})
    lbl_func_des:setAnchorPoint(CCPoint(0.5, 1))
    lbl_func_des:setPosition(scalep(480, 235+offset_y))
    layer:addChild(lbl_func_des, 2)

    json.load(json.ui.jiesuo)
    local jiesuo = DHSkeletonAnimation:createWithKey(json.ui.jiesuo)
    jiesuo:setScale(view.minScale)
    jiesuo:scheduleUpdateLua()
    --jiesuo:playAnimation("animation", 1)
    jiesuo:setPosition(CCPoint(view.midX, view.midY+40*view.minScale))
    layer:addChild(jiesuo, 2)

    local lbl_icon_offset_y = 220
    local lbl_tip_offset_y = 165
    local lbl_tip_width = 460
    local tip_bg = CCSprite:create()
    tip_bg:setContentSize(CCSizeMake(lbl_tip_width, 120))
    tip_bg:setScale(view.minScale)
    tip_bg:setPosition(CCPoint(view.midX, view.minY+lbl_tip_offset_y*view.minScale))
    layer:addChild(tip_bg, 10)
    if which == ui.WHICH.TAVERN then
        json.load(json.ui.main_jiuguan)
        local sprite_obj = DHSkeletonAnimation:createWithKey(json.ui.main_jiuguan)
        --sprite_obj:setScale(view.minScale*0.7)
        sprite_obj:setScale(1.0)
        sprite_obj:scheduleUpdateLua()
        sprite_obj:playAnimation("animation", -1)
        --sprite_obj:setPosition(CCPoint(view.midX, view.midY-5*view.minScale))
        --layer:addChild(sprite_obj, 10)
        jiesuo:addChildFollowSlot("code_building", sprite_obj)
        lbl_building:setString(i18n.global.town_building_tavern.string)
        lbl_func_des:setString(i18n.global.unlock_tavern_tip.string)
    elseif which == ui.WHICH.ARENA then
        json.load(json.ui.main_jjc)
        local sprite_obj = DHSkeletonAnimation:createWithKey(json.ui.main_jjc)
        --sprite_obj:setScale(view.minScale*0.7)
        sprite_obj:setScale(1.0)
        sprite_obj:scheduleUpdateLua()
        sprite_obj:playAnimation("animation", -1)
        --sprite_obj:setPosition(CCPoint(view.midX, view.midY-15*view.minScale))
        --layer:addChild(sprite_obj, 10)
        jiesuo:addChildFollowSlot("code_building", sprite_obj)
        lbl_building:setString(i18n.global.town_building_arena.string)
        lbl_func_des:setString(i18n.global.unlock_arena_tip.string)
    elseif which == ui.WHICH.BLACKMARKET then
        json.load(json.ui.main_heishi)
        local sprite_obj = DHSkeletonAnimation:createWithKey(json.ui.main_heishi)
        --sprite_obj:setScale(view.minScale*0.7)
        sprite_obj:setScale(1.2)
        sprite_obj:scheduleUpdateLua()
        sprite_obj:playAnimation("animation", -1)
        --sprite_obj:setPosition(CCPoint(view.midX, view.midY-5*view.minScale))
        --layer:addChild(sprite_obj, 10)
        jiesuo:addChildFollowSlot("code_building", sprite_obj)
        lbl_building:setString(i18n.global.town_building_bm.string)
        lbl_func_des:setString(i18n.global.unlock_blackmarket_tip.string)
    elseif which == ui.WHICH.CASINO then
        json.load(json.ui.main_duchang)
        local sprite_obj = DHSkeletonAnimation:createWithKey(json.ui.main_duchang)
        --sprite_obj:setScale(view.minScale*0.8)
        sprite_obj:setScale(1.5)
        sprite_obj:scheduleUpdateLua()
        sprite_obj:playAnimation("animation", -1)
        --sprite_obj:setPosition(CCPoint(view.midX, view.midY-15*view.minScale))
        --layer:addChild(sprite_obj, 10)
        jiesuo:addChildFollowSlot("code_building", sprite_obj)
        lbl_building:setString(i18n.global.town_building_casino.string)
        lbl_func_des:setString(i18n.global.unlock_casino_tip.string)
    elseif which == ui.WHICH.GUILD then
        --json.load(json.ui.main_heishi)
        --local sprite_obj = DHSkeletonAnimation:createWithKey(json.ui.main_heishi)
        --sprite_obj:setScale(view.minScale*0.7)
        --sprite_obj:scheduleUpdateLua()
        --sprite_obj:playAnimation("animation", -1)
        --sprite_obj:setPosition(CCPoint(view.midX, view.midY-5*view.minScale))
        --layer:addChild(sprite_obj, 10)
        local guild_icon = img.createUISprite(img.ui.main_icon_guild)
        --guild_icon:setScale(view.minScale)
        --guild_icon:setPosition(scalep(480, 338))
        --layer:addChild(guild_icon, 10)
        guild_icon:setScale(2)
        guild_icon:setAnchorPoint(CCPoint(0.5, 0))
        jiesuo:addChildFollowSlot("code_building", guild_icon)
        lbl_building:setString(i18n.global.main_btn_guild.string)
        lbl_func_des:setString(i18n.global.unlock_guild_tip.string)
    elseif which == ui.WHICH.TRIAL then
        json.load(json.ui.main_huanjing)
        local sprite_obj = DHSkeletonAnimation:createWithKey(json.ui.main_huanjing)
        --sprite_obj:setScale(view.minScale*0.4)
        sprite_obj:setScale(0.5)
        sprite_obj:scheduleUpdateLua()
        sprite_obj:playAnimation("animation", -1)
        --sprite_obj:setPosition(CCPoint(view.midX, view.midY-5*view.minScale))
        --layer:addChild(sprite_obj, 10)
        jiesuo:addChildFollowSlot("code_building", sprite_obj)
        lbl_building:setString(i18n.global.town_building_oblivion.string)
        lbl_func_des:setString(i18n.global.unlock_trial_tip.string)
    end


    local arr = CCArray:create()
    arr:addObject(CCCallFunc:create(function()
        jiesuo:playAnimation("animation", 1)
    end))
    arr:addObject(CCDelayTime:create(jiesuo:getAnimationTime("animation")))
    arr:addObject(CCCallFunc:create(function()
        jiesuo:playAnimation("animation2", -1)
    end))
    layer:runAction(CCSequence:create(arr))

    local btn_confirm0 = img.createLogin9Sprite(img.login.button_9_small_gold)
    btn_confirm0:setPreferredSize(CCSizeMake(140, 50))
    local lbl_confirm = lbl.createFont1(20, i18n.global.dialog_button_confirm.string, ccc3(0x73, 0x3b, 0x05))
    lbl_confirm:setPosition(CCPoint(btn_confirm0:getContentSize().width/2,
                btn_confirm0:getContentSize().height/2))
    btn_confirm0:addChild(lbl_confirm)
    local btn_confirm = SpineMenuItem:create(json.ui.button, btn_confirm0)
    btn_confirm:setScale(view.minScale)
    btn_confirm:setPosition(scalep(480, 130+offset_y))
    local btn_confirm_menu = CCMenu:createWithItem(btn_confirm)
    btn_confirm_menu:setPosition(CCPoint(0,0))
    layer:addChild(btn_confirm_menu, 100)
    btn_confirm:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer:removeFromParentAndCleanup(true)
        if callback then
            callback()
        else
            replaceScene((require"ui.town.main").create())
        end
        --if which == ui.WHICH.HOOK then
        --    local worldlayer = require "uilayer.worldlayer"
        --    replaceScene(worldlayer.create())
        --else
        --    -- go to townlayer
        --    local townlayer = require "uilayer.townlayer"
        --    replaceScene(townlayer.create())
        --end
    end)

    layer:setTouchEnabled(true)
    layer:setTouchSwallowEnabled(true)

    return layer
end

return ui
