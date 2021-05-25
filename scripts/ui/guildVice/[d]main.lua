local ui = {}

require "common.func"
require "common.const"
local view = require "common.view"
local img = require "res.img"
local i18n = require "res.i18n"
local lbl = require "res.lbl"
local json = require "res.json"
local audio = require "res.audio"
local cfgitem = require "config.item"
local cfgequip = require "config.equip"
local player = require "data.player"
local gdata = require "data.guild"
local gbossdata = require "data.gboss"
local gskilldata = require "data.gskill"
local i18n = require "res.i18n"
local tipsequip = require "ui.tips.equip"
local tipsitem = require "ui.tips.item"
local dialog = require "ui.dialog"
local gmill = require "ui.guildmill.main"
local vicecontinue = require "ui.guildVice.vicecontinue"
local rewards = require "ui.reward"
local NetClient = require "net.netClient"
local netClient = NetClient:getInstance()

function ui.create(uiParams)
    local layer = CCLayer:create()

    img.load(img.packedOthers.ui_guildvice)
    img.load(img.packedOthers.ui_guildvice_bg)
    local function backEvent()
        audio.play(audio.button)
        if uiParams and uiParams.from_layer == "task" then
            replaceScene(require("ui.town.main").create({from_layer="task"}))  
        else
            replaceScene(require("ui.guild.main").create())  
        end
    end
    
    --back btn
    local back0 = img.createUISprite(img.ui.back)
    local backBtn = HHMenuItem:create(back0)
    backBtn:setScale(view.minScale)
    backBtn:setPosition(scalep(35, 546))
    local backMenu = CCMenu:createWithItem(backBtn)
    backMenu:setPosition(0, 0)
    layer:addChild(backMenu, 1000)
    backBtn:registerScriptTapHandler(function()
        backEvent()
    end)

    autoLayoutShift(backBtn)

    json.load(json.ui.guild)
    local ani_guild = DHSkeletonAnimation:createWithKey(json.ui.guild)
    ani_guild:setScale(view.minScale)
    ani_guild:scheduleUpdateLua()
    ani_guild:setAnchorPoint(CCPoint(0.5, 0.5))
    ani_guild:setPosition(scalep(480, 288))
    layer:addChild(ani_guild)
    ani_guild:registerAnimation("animation", -1)
    ani_guild:registerAnimation("animation2", -1)

    layer:setTouchEnabled(true)
    layer:setTouchSwallowEnabled(true)
    
    local lbl_spaces = 76
    local building_lbl_color = ccc3(0xfb, 0xe6, 0x7e)
    local lbl_buildings = {}  -- for red dot
    local building_lbls = {
        [1] = {name=i18n.global.guild_building_vice.string, pos=CCPoint(161*view.minScale, 100*view.minScale)},
        [2] = {name=i18n.global.guild_building_keji.string, pos=CCPoint(806*view.minScale, 87*view.minScale)},
        [3] = {name=i18n.global.guild_building_mofang.string, pos=CCPoint(577*view.minScale, 176*view.minScale)},
        [4] = {name=i18n.global.guild_building_shop.string, pos=CCPoint(1123*view.minScale, 97*view.minScale)},
        [5] = {name=i18n.global.guild_building_war.string, pos=CCPoint(1472*view.minScale, 181*view.minScale)},
        [6] = {name=i18n.global.pray_title.string, pos=CCPoint(161*view.minScale, 100*view.minScale)},
    }
    local function createBuildingLbls()
        for ii=1,#building_lbls do
            local lbl_xxx= lbl.createFont2(18, building_lbls[ii].name, building_lbl_color)
            local building_lbl_xxx = img.createUI9Sprite(img.ui.main_building_lbl)
            --building_lbl_xxx:setScale(view.minScale)
            local bd_size = lbl_xxx:boundingBox().size
            building_lbl_xxx:setPreferredSize(CCSizeMake(bd_size.width+lbl_spaces, 40))
            lbl_xxx:setPosition(CCPoint(building_lbl_xxx:getContentSize().width/2, building_lbl_xxx:getContentSize().height/2))
            building_lbl_xxx:addChild(lbl_xxx)
            --building_lbl_xxx:setPosition(building_lbls[ii].pos)
            lbl_buildings[ii] = building_lbl_xxx
        end
    end
    createBuildingLbls()
    -- vice
    local sprite_fuben = CCSprite:create()
    sprite_fuben:setContentSize(CCSizeMake(255, 200))
    json.load(json.ui.fuben)
    local ani_fuben = DHSkeletonAnimation:createWithKey(json.ui.fuben)
    ani_fuben:scheduleUpdateLua()
    ani_fuben:setAnchorPoint(CCPoint(0.5, 0))
    ani_fuben:setPosition(CCPoint(120, 28))
    sprite_fuben:addChild(ani_fuben)
    ani_fuben:registerAnimation("animation", -1)
    local btn_fuben = HHMenuItem:createWithScale(sprite_fuben, 1.0)
    btn_fuben:setScale(view.minScale)
    btn_fuben:setAnchorPoint(CCPoint(0.5, 0))
    btn_fuben:setPosition(scalep(461, 334))
    local btn_fuben_menu = CCMenu:createWithItem(btn_fuben)
    btn_fuben_menu:setPosition(CCPoint(0, 0))
    layer:addChild(btn_fuben_menu, 2)
    lbl_buildings[1]:setPosition(CCPoint(148, 0))
    btn_fuben:addChild(lbl_buildings[1])

    -- keji
    local sprite_keji = CCSprite:create()
    sprite_keji:setContentSize(CCSizeMake(140, 182))
    json.load(json.ui.keji)
    local ani_keji = DHSkeletonAnimation:createWithKey(json.ui.keji)
    ani_keji:scheduleUpdateLua()
    ani_keji:setAnchorPoint(CCPoint(0.5, 0))
    ani_keji:setPosition(CCPoint(70, 28))
    sprite_keji:addChild(ani_keji)
    ani_keji:registerAnimation("animation", -1)
    local btn_keji = HHMenuItem:createWithScale(sprite_keji, 1.0)
    btn_keji:setScale(view.minScale)
    btn_keji:setAnchorPoint(CCPoint(0.5, 0))
    btn_keji:setPosition(scalep(731, 304))
    local btn_keji_menu = CCMenu:createWithItem(btn_keji)
    btn_keji_menu:setPosition(CCPoint(0, 0))
    layer:addChild(btn_keji_menu, 2)
    lbl_buildings[2]:setPosition(CCPoint(70, 0))
    btn_keji:addChild(lbl_buildings[2])
    btn_keji:registerScriptTapHandler(function()
        disableObjAWhile(btn_keji, 2)
        audio.play(audio.button)
        layer:addChild((require"ui.guildVice.skill").create(), 1000)
        --local nParam = {
        --    sid = player.sid,
        --}
        --addWaitNet()
        --netClient:gskl_sync(nParam, function(__data)
        --    delWaitNet()
        --    tbl2string(__data)
        --    gskilldata.sync(__data.skls)
        --    layer:addChild((require"ui.guildVice.skill").create(), 1000)
        --end)
    end)

    -- mofang
    local sprite_mofang = CCSprite:create()
    sprite_mofang:setContentSize(CCSizeMake(164, 192))
    json.load(json.ui.mofang)
    local ani_mofang = DHSkeletonAnimation:createWithKey(json.ui.mofang)
    ani_mofang:scheduleUpdateLua()
    ani_mofang:setAnchorPoint(CCPoint(0.5, 0))
    ani_mofang:setPosition(CCPoint(89, 18))
    sprite_mofang:addChild(ani_mofang)
    ani_mofang:registerAnimation("animation", -1)
    local btn_mofang = HHMenuItem:createWithScale(sprite_mofang, 1.0)
    btn_mofang:setScale(view.minScale)
    btn_mofang:setAnchorPoint(CCPoint(0.5, 0))
    btn_mofang:setPosition(scalep(180, 289))
    local btn_mofang_menu = CCMenu:createWithItem(btn_mofang)
    btn_mofang_menu:setPosition(CCPoint(0, 0))
    layer:addChild(btn_mofang_menu, 2)
    lbl_buildings[3]:setPosition(CCPoint(82, 15))
    btn_mofang:addChild(lbl_buildings[3])
    --drawBoundingbox(layer, btn_mofang)
    btn_mofang:registerScriptTapHandler(function()
        audio.play(audio.button)
        if gdata.Lv() < 8 then
            showToast(string.format(i18n.global.need_guild_lv.string, 8))
            return
        end
        layer:addChild(gmill.create(), 1000)
    end)


    -- bbq
    local sprite_bbq = CCSprite:create()
    sprite_bbq:setContentSize(CCSizeMake(136, 82))
    json.load(json.ui.bbq)
    local ani_bbq = DHSkeletonAnimation:createWithKey(json.ui.bbq)
    ani_bbq:scheduleUpdateLua()
    ani_bbq:setAnchorPoint(CCPoint(0.5, 0))
    ani_bbq:setPosition(CCPoint(66, 25))
    sprite_bbq:addChild(ani_bbq)
    ani_bbq:registerAnimation("animation", -1)
    local btn_bbq = HHMenuItem:createWithScale(sprite_bbq, 1.0)
    btn_bbq:setScale(view.minScale)
    btn_bbq:setAnchorPoint(CCPoint(0.5, 0))
    btn_bbq:setPosition(scalep(490, 158))
    local btn_bbq_menu = CCMenu:createWithItem(btn_bbq)
    btn_bbq_menu:setPosition(CCPoint(0, 0))
    layer:addChild(btn_bbq_menu, 2)
    lbl_buildings[6]:setPosition(CCPoint(70, -10))
    btn_bbq:addChild(lbl_buildings[6])
    --drawBoundingbox(layer, btn_bbq)
    --btn_bbq:setEnabled(false)
    local function gotoGray(gParams)
        local nParam = {
            sid = player.sid,
        }
        addWaitNet()
        netClient:gfire_sync(nParam, function(__data)
            delWaitNet()
            tbl2string(__data)
            if __data.status == -3 then
                showToast(i18n.global.guild_func_waiting.string)
                return
            end
            if __data.status == -2 then
                showToast(i18n.global.gray_toast_unlock.string)
                return
            end
            if __data.status ~= 0 then
                showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                return
            end
            
            --gbossdata.sync(__data)
            layer:addChild((require"ui.guildVice.vicecontinue").create(__data), 1000)
            btn_bbq:setEnabled(true)
        end)
        --layer:addChild((require"ui.guildVice.vicecontinue").create(), 1000)
    end

    btn_bbq:registerScriptTapHandler(function()
        audio.play(audio.button)
        --if true then
        --    showToast(i18n.global.guild_func_waiting.string)
        --    return
        --end
        gotoGray()
    end)

    -- shop
    local sprite_shop = CCSprite:create()
    sprite_shop:setContentSize(CCSizeMake(298, 220))
    json.load(json.ui.shop)
    local ani_shop = DHSkeletonAnimation:createWithKey(json.ui.shop)
    ani_shop:scheduleUpdateLua()
    ani_shop:setAnchorPoint(CCPoint(0.5, 0))
    ani_shop:setPosition(CCPoint(149, 28))
    sprite_shop:addChild(ani_shop)
    ani_shop:registerAnimation("animation", -1)
    local btn_shop = HHMenuItem:createWithScale(sprite_shop, 1.0)
    btn_shop:setScale(view.minScale)
    btn_shop:setAnchorPoint(CCPoint(0.5, 0))
    btn_shop:setPosition(scalep(240, 79))
    local btn_shop_menu = CCMenu:createWithItem(btn_shop)
    btn_shop_menu:setPosition(CCPoint(0, 0))
    layer:addChild(btn_shop_menu, 2)
    lbl_buildings[4]:setPosition(CCPoint(149, -10))
    btn_shop:addChild(lbl_buildings[4])
    --drawBoundingbox(layer, btn_shop)
    btn_shop:registerScriptTapHandler(function()
        audio.play(audio.button)
        local shop = require "ui.guildVice.shop"
        layer:addChild(shop.create(), 1000)
    end)

    -- war
    local sprite_war = CCSprite:create()
    sprite_war:setContentSize(CCSizeMake(300, 275))
    json.load(json.ui.guildwar)
    local ani_war = DHSkeletonAnimation:createWithKey(json.ui.guildwar)
    ani_war:scheduleUpdateLua()
    ani_war:setAnchorPoint(CCPoint(0.5, 0))
    ani_war:setPosition(CCPoint(150, 68))
    sprite_war:addChild(ani_war)
    ani_war:registerAnimation("animation", -1)
    local btn_war = HHMenuItem:createWithScale(sprite_war, 1.0)
    btn_war:setScale(view.minScale)
    btn_war:setAnchorPoint(CCPoint(0.5, 0))
    btn_war:setPosition(scalep(750, 50))
    local btn_war_menu = CCMenu:createWithItem(btn_war)
    btn_war_menu:setPosition(CCPoint(0, 0))
    layer:addChild(btn_war_menu, 2)
    lbl_buildings[5]:setPosition(CCPoint(165, 0))
    btn_war:addChild(lbl_buildings[5])
    btn_war:registerScriptTapHandler(function()
        audio.play(audio.button)
        if gdata.Lv() < 12 then
            showToast(string.format(i18n.global.need_guild_lv.string, 12))
            return
        end
        --showToast(i18n.global.guild_func_waiting.string)
        layer:addChild((require"ui.guildFight.guildFightMain").create(), 1000)
    end)

    local function gotoVice(gParams)
        local nParam = {
            sid = player.sid,
        }
        addWaitNet()
        netClient:gboss_sync(nParam, function(__data)
            delWaitNet()
            tbl2string(__data)
            gbossdata.sync(__data)
            layer:addChild((require"ui.guildVice.vice").create(gParams), 1000)
            btn_fuben:setEnabled(true)
        end)
    end

    btn_fuben:registerScriptTapHandler(function()
        btn_fuben:setEnabled(false)
        audio.play(audio.button)
        gotoVice()
    end)

    local masklayer = CCLayer:create()
    layer:addChild(masklayer, 100)
    local mask_lt = img.createUISprite(img.ui.guildvice_scene_mask)  -- LT
    mask_lt:setScale(view.minScale)
    mask_lt:setAnchorPoint(CCPoint(0, 1))
    mask_lt:setPosition(scalep(0, 576))
    masklayer:addChild(mask_lt)
    local mask_lb = img.createUISprite(img.ui.guildvice_scene_mask)  -- LB
    mask_lb:setFlipY(true)
    mask_lb:setScale(view.minScale)
    mask_lb:setAnchorPoint(CCPoint(0, 0))
    mask_lb:setPosition(scalep(0, 0))
    masklayer:addChild(mask_lb)
    local mask_rb = img.createUISprite(img.ui.guildvice_scene_mask)  -- RB
    mask_rb:setFlipX(true)
    mask_rb:setFlipY(true)
    mask_rb:setScale(view.minScale)
    mask_rb:setAnchorPoint(CCPoint(1, 0))
    mask_rb:setPosition(scalep(960, 0))
    masklayer:addChild(mask_rb)
    local mask_rt = img.createUISprite(img.ui.guildvice_scene_mask)  -- rt
    mask_rt:setFlipX(true)
    mask_rt:setScale(view.minScale)
    mask_rt:setAnchorPoint(CCPoint(1, 1))
    mask_rt:setPosition(scalep(960, 576))
    masklayer:addChild(mask_rt)

    autoLayoutShift(mask_lt, nil, nil, nil, nil, true) 
    autoLayoutShift(mask_lb, nil, nil, nil, nil, true) 
    autoLayoutShift(mask_rb, nil, nil, nil, nil, true) 
    autoLayoutShift(mask_rt, nil, nil, nil, nil, true) 

    -- 为ios审核准备，未开放功能隐藏
    if APP_CHANNEL and APP_CHANNEL == "LT" then
        --btn_mofang:setVisible(false)
        --btn_war:setVisible(false)
    end

    addBackEvent(layer)
    function layer.onAndroidBack()
        backEvent()
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
            img.unload(img.packedOthers.ui_guildvice)
            img.unload(img.packedOthers.ui_guildvice_bg)
        end
    end)

    if uiParams and uiParams.from_layer == "info" then
        schedule(layer, function()
            gotoVice({from_layer="info"})
        end)
    elseif uiParams and uiParams.from_layer == "gfire" then
        gotoGray()
    elseif uiParams and uiParams.from_layer == "gmill" then
        layer:addChild(gmill.create(3), 1000)
    elseif uiParams and uiParams.from_layer == "gwar" then
        layer:addChild((require"ui.guildFight.guildFightMain").create(), 1000)
    end

    local last_update = os.time()
    local function onUpdate(ticks)
        if os.time() - last_update < 0.5 then return end
        last_update = os.time()
        local gmillData = require"data.guildmill"
        if gmillData.showRedDot() then
            addRedDot(lbl_buildings[3], {
                px = lbl_buildings[3]:getContentSize().width - 10,
                py = lbl_buildings[3]:getContentSize().height - 5,
            })
        else
            delRedDot(lbl_buildings[3])
        end
    end
    layer:scheduleUpdateWithPriorityLua(onUpdate, 0)
    return layer
end


return ui
