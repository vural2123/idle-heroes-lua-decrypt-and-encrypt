local ui = {}

require "common.func"

local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local audio = require "res.audio"
local i18n = require "res.i18n"
local player = require "data.player"
local bag = require "data.bag"
local net = require "net.netClient"
local cfghero = require "config.hero"
local cfgequip = require "config.equip"
local cfgdisplace = require "config.displace"
local heros = require "data.heros"
local selecthero = require "ui.summonspe.selecthero"

local function createPopupPieceBatchSummonResult(id, heroinfo)
    local params = {}
    params.title = i18n.global.reward_will_get.string
    params.btn_count = 0

    local dialog = require("ui.dialog").create(params) 

    local back = img.createLogin9Sprite(img.login.button_9_small_gold)
    back:setPreferredSize(CCSize(153, 50))
    local comfirlab = lbl.createFont1(22, i18n.global.summon_comfirm.string, lbl.buttonColor)
    comfirlab:setPosition(CCPoint(back:getContentSize().width/2,
                                    back:getContentSize().height/2))
    back:addChild(comfirlab)
    local backBtn = SpineMenuItem:create(json.ui.button, back)
    backBtn:setPosition(CCPoint(dialog.board:getContentSize().width/2, 80))
    local menu = CCMenu:createWithItem(backBtn)
    menu:setPosition(0, 0)
    dialog.board:addChild(menu)

    --local hero = img.createHeroHead(id, heroinfo.lv, true, true)
    local param = {
        id = id,
        lv = heroinfo.lv,
        showGroup = true,
        showStar = true,
        wake = nil,
        orangeFx = nil,
        petID = nil,
        --hid = heroinfo.hid
    }
    local hero = img.createHeroHeadByParam(param)
    --heroBtn = SpineMenuItem:create(json.ui.button, hero)
    --heroBtn:setScale(0.85)
    hero:setPosition(dialog.board:getContentSize().width/2, 185)
    dialog.board:addChild(hero)
    --local iconMenu = CCMenu:createWithItem(heroBtn)
    --iconMenu:setPosition(0, 0)
    --dialog.board:addChild(iconMenu)
    --heroBtn:registerScriptTapHandler(function()
    --    audio.play(audio.button)
    --    local herotips = require "ui.tips.hero"
    --    local tips = herotips.create(heroinfo)
    --    dialog:addChild(tips, 1001)
    --end)

    backBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        dialog:removeFromParentAndCleanup()
    end)
    return dialog
end

function ui.create(mainlayer)
    local layer = CCLayer:create()

    local bg_w = 846
    local bg_h = 396
    local layer = CCLayer:create()
    --local bg = img.createUISprite(img.ui.summontree_replace_bg)
    --bg:setPosition(bg_w/2, bg_h/2)
    --layer:addChild(bg)

    json.load(json.ui.zhihuan)
    local aniZhihuan = DHSkeletonAnimation:createWithKey(json.ui.zhihuan)
    aniZhihuan:scheduleUpdateLua()
    aniZhihuan:playAnimation("1loop", -1)
    aniZhihuan:setPosition(bg_w/2, bg_h/2+45)
    layer:addChild(aniZhihuan)

    local detailSprite = img.createUISprite(img.ui.btn_help)
    local detailBtn = SpineMenuItem:create(json.ui.button, detailSprite)
    detailBtn:setPosition(bg_w-45, bg_h-40)

    local detailMenu = CCMenu:create()
    detailMenu:setPosition(0, 0)
    layer:addChild(detailMenu, 20)
    detailMenu:addChild(detailBtn)

    detailBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer:getParent():getParent():getParent():getParent():addChild(require("ui.help").create(i18n.global.help_summon_replace.string), 1000)
    end)

    local pleaseLab = lbl.createMixFont1(16, i18n.global.space_summon_please.string, ccc3(255, 246, 223))
    pleaseLab:setPosition(bg_w/2, bg_h-40)
    layer:addChild(pleaseLab)


    local lefenter = img.createUISprite(img.ui.summontree_click)
    local lefenterbtn = SpineMenuItem:create(json.ui.button, lefenter)
    lefenterbtn:setPosition(CCPoint(220+45, 200))
    local lefentermenu = CCMenu:createWithItem(lefenterbtn)
    lefentermenu:setPosition(CCPoint(0, 0))
    layer:addChild(lefentermenu, 100)

    local change = img.createLogin9Sprite(img.login.button_9_gold)
    change:setPreferredSize(CCSizeMake(172, 60))
    local cgicon = img.createItemIcon2(ITEM_ID_SP_REPLACE)
    cgicon:setScale(0.9)
    cgicon:setPosition(CCPoint(30, change:getContentSize().height/2+2))
    change:addChild(cgicon)
    local cgcountLable = lbl.createFont2(16, "", ccc3(255, 246, 223))
    cgcountLable:setPosition(CCPoint(cgicon:getContentSize().width/2, 5))
    cgicon:addChild(cgcountLable) 
    local changeLabel = lbl.createFont1(18, i18n.global.space_summon_replace.string, ccc3(0x73, 0x3b, 0x05))
    changeLabel:setPosition(change:getContentSize().width*3/5, change:getContentSize().height/2)
    change:addChild(changeLabel)
    local changebtn = SpineMenuItem:create(json.ui.button, change)
    changebtn:setPosition(CCPoint(bg_w/2, 55))
    changebtn:setVisible(false)
    --changebtn:setEnabled(false)
    --setShader(changebtn, SHADER_GRAY, true)
    local changemenu = CCMenu:createWithItem(changebtn)
    changemenu:setPosition(CCPoint(0, 0))
    layer:addChild(changemenu, 100)
    
    local cancel = img.createLogin9Sprite(img.login.button_9_gold)
    cancel:setPreferredSize(CCSizeMake(158, 58))
    local cancelLabel = lbl.createFont1(18, i18n.global.dialog_button_cancel.string, ccc3(0x73, 0x3b, 0x05))
    cancelLabel:setPosition(cancel:getContentSize().width/2, cancel:getContentSize().height/2)
    cancel:addChild(cancelLabel)
    local cancelbtn = SpineMenuItem:create(json.ui.button, cancel)
    cancelbtn:setPosition(CCPoint(317+15, 53))
    cancelbtn:setVisible(false)
    local cancelmenu = CCMenu:createWithItem(cancelbtn)
    cancelmenu:setPosition(CCPoint(0, 0))
    layer:addChild(cancelmenu, 100)

    local ok = img.createUI9Sprite(img.ui.btn_7)
    ok:setPreferredSize(CCSizeMake(158, 58))
    local okLabel = lbl.createFont1(18, i18n.global.crystal_btn_save.string, ccc3(0x1d, 0x67, 0x00))
    okLabel:setPosition(ok:getContentSize().width/2, ok:getContentSize().height/2)
    ok:addChild(okLabel)
    local okbtn = SpineMenuItem:create(json.ui.button, ok)
    okbtn:setPosition(CCPoint(bg_w-317-15, 53))
    okbtn:setVisible(false)
    local okmenu = CCMenu:createWithItem(okbtn)
    okmenu:setPosition(CCPoint(0, 0))
    layer:addChild(okmenu, 100)

    --local rawicon = img.createUISprite(img.ui.summontree_raw)
    --rawicon:setPosition(bg_w/2, 206)
    --rawicon:setVisible(false)
    --layer:addChild(rawicon)

    local heroinfoLayer = nil
    local lefheroinfo = nil
    local rigid
    local uphero = nil
    local heroBody = nil
    local queuedSched = nil

    local function upcount(group, star)
        for i=1,#cfgdisplace do
            if cfgdisplace[i].group == group and cfgdisplace[i].qlt == star then
                return cfgdisplace[i].cost
            end
        end
        return 0
    end

    local function createherolayer(lefhero, righeroid)
        local herolayer = CCLayer:create()
        changebtn:setEnabled(true)

        local heroName = lbl.createFont2(14, i18n.hero[lefhero.id].heroName)
        heroName:setPosition(225+45, 342)
        herolayer:addChild(heroName)
        local herogroup = img.createUISprite(img.ui["herolist_group_" .. cfghero[lefhero.id].group])
        herogroup:setScale(0.55)
        herogroup:setPosition(heroName:boundingBox():getMinX() - 30, heroName:getPositionY())
        herolayer:addChild(herogroup)

        local heroLv = lbl.createFont2(14, string.format("Lv: %d", lefhero.lv))
        heroLv:setPosition(225+45, 300)
        herolayer:addChild(heroLv)

        local star = cfghero[lefhero.id].qlt
        local baseX = 180+45
        for i=1, star do
            local starIcon = img.createUISprite(img.ui.star)
            starIcon:setScale(0.5)
            starIcon:setPosition(baseX + 24 * (i - 1), 320)
            herolayer:addChild(starIcon)
        end

        local righeroName = nil
        local riginfo = clone(lefhero) 
        riginfo.id = righeroid

        if righeroid then
            righeroName = lbl.createFont2(14, i18n.hero[righeroid].heroName)
            local btnDetailSprite = img.createUISprite(img.ui.fight_hurts)
            local btnDetail = SpineMenuItem:create(json.ui.button, btnDetailSprite)
            btnDetail:setPosition(bg_w-170, 280)
            local menuDetail = CCMenu:createWithItem(btnDetail)
            menuDetail:setPosition(0, 0)
            herolayer:addChild(menuDetail)
            btnDetail:registerScriptTapHandler(function()
                audio.play(audio.button)
                    local herotips = require "ui.tips.hero"
                    local tips = require("ui.tips.hero").create(righeroid)
                    layer:getParent():getParent():getParent():getParent():addChild(tips, 1001)
            end)
        else
            righeroName = lbl.createMixFont1(14, "????")
        end
        righeroName:setPosition(bg_w-225-45, 342)
        herolayer:addChild(righeroName)
        local righerogroup = img.createUISprite(img.ui["herolist_group_" .. cfghero[lefhero.id].group])
        righerogroup:setScale(0.55)
        righerogroup:setPosition(righeroName:boundingBox():getMinX() - 30, righeroName:getPositionY())
        herolayer:addChild(righerogroup)

        local righeroLv = lbl.createFont2(14, string.format("Lv: %d", lefhero.lv))
        righeroLv:setPosition(bg_w-225-45, 300)
        herolayer:addChild(righeroLv)

        local rigstar = cfghero[lefhero.id].qlt
        local rigbaseX = bg_w-262-45
        for i=1, rigstar do
            local starIcon = img.createUISprite(img.ui.star)
            starIcon:setScale(0.5)
            starIcon:setPosition(rigbaseX + 24 * (i - 1), 320)
            herolayer:addChild(starIcon)
        end

        if righeroid == nil then
            local clickenter = img.createUISprite(img.ui.summontree_click)
            local clickenterbtn = SpineMenuItem:create(json.ui.button, clickenter)
            clickenterbtn:setPosition(CCPoint(220+45, 200))
            local clickentermenu = CCMenu:createWithItem(clickenterbtn)
            clickentermenu:setPosition(CCPoint(0, 0))
            herolayer:addChild(clickentermenu, 100)
            clickenterbtn:registerScriptTapHandler(function()
                disableObjAWhile(clickenterbtn)
                audio.play(audio.button)   
                local selectherolayer = nil
                selectherolayer = selecthero.create(uphero)
                layer:getParent():getParent():getParent():getParent():addChild(selectherolayer, 1000)
                local ban = CCLayer:create()
                ban:setTouchEnabled(true)
                ban:setTouchSwallowEnabled(true)
                layer:addChild(ban, 1000)
                schedule(layer, 1, function()
                    ban:removeFromParent()
                end)
            end)
        end

        return herolayer
    end
    
    function uphero(lefhero, righeroid)

        if heroinfoLayer then
            heroinfoLayer:removeFromParent()
            heroinfoLayer = nil
        end
        

        if lefhero == nil then
            if heroBody then
                heroBody:removeFromParent()
                heroBody = nil
            end
            aniZhihuan:playAnimation("1loop", -1)
            lefenterbtn:setVisible(true)
            pleaseLab:setVisible(true)
            --rigicon:setVisible(true)
            changebtn:setVisible(false)
            --changebtn:setEnabled(false)
            --setShader(changebtn, SHADER_GRAY, true)
            cancelbtn:setVisible(false)
            okbtn:setVisible(false)
            --rawicon:setVisible(false)
            return
        end
        lefheroinfo = lefhero

        if righeroid == nil then
            lefenterbtn:setVisible(false)
            --rigicon:setVisible(false)
            pleaseLab:setVisible(false)
            changebtn:setVisible(true)
            cancelbtn:setVisible(false)
            okbtn:setVisible(false)
            aniZhihuan:playAnimation("2start")

            local ban = CCLayer:create()
            ban:setTouchEnabled(true)
            ban:setTouchSwallowEnabled(true)
            layer:addChild(ban, 1000)
            
            if heroBody then
                heroBody:removeFromParent()
                heroBody = nil
            end
            schedule(layer, 0.2, function()
                if getHeroSkin(lefhero.hid) then
                    heroBody = json.createSpineHeroSkin(getHeroSkin(lefhero.hid))
                else
                    heroBody = json.createSpineHero(lefhero.id)
                end
                heroBody:setScale(0.5)
                heroBody:setPosition(225+43, 114)
                layer:addChild(heroBody, 1)
                cgcountLable:setString(string.format("%d", upcount(cfghero[lefheroinfo.id].group, cfghero[lefheroinfo.id].qlt)))
            end)

            schedule(layer, 1, function()
                aniZhihuan:playAnimation("2loop", -1)
                ban:removeFromParent()
                heroinfoLayer = createherolayer(lefhero)
                layer:addChild(heroinfoLayer)
                if queuedSched then
                    local thid = queuedSched
                    queuedSched = nil
                    uphero(lefhero, thid)
                    rigid = thid
                end

            end)
        end
        if righeroid then
            aniZhihuan:playAnimation("3start")
            changebtn:setVisible(false)
            cancelbtn:setVisible(true)
            okbtn:setVisible(true)
            --rawicon:setVisible(true)
            local shadowicon = json.createSpineHero(righeroid)
            shadowicon:setScale(0.5)
            shadowicon:setAnchorPoint(0.5, 0.5)
            --shadowicon:setPosition(bg_w-225-45, 110)
            --herolayer:addChild(shadowicon, 1)
            aniZhihuan:addChildFollowSlot("code_hero2", shadowicon)
            local ban = CCLayer:create()
            ban:setTouchEnabled(true)
            ban:setTouchSwallowEnabled(true)
            layer:addChild(ban, 1000)
            schedule(layer, 1, function()
                aniZhihuan:playAnimation("3loop", -1)
                ban:removeFromParent()
                heroinfoLayer = createherolayer(lefhero, righeroid)
                layer:addChild(heroinfoLayer)
            end)
        end

    end

    if heros.treehid and heros.treeid then
        local templef = heros.find(heros.treehid)
        if templef then
            queuedSched = heros.treeid
            uphero(templef)
        end
    end
    
    lefenterbtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        local selectherolayer = nil
        selectherolayer = selecthero.create(uphero)
        layer:getParent():getParent():getParent():getParent():addChild(selectherolayer, 1000)

        --selectherolayer.setClickBlankHandler(function()
        --    print("removeFromParent")
        --    selecthero:removeFromParent()
        --end)
    end)

    changebtn:registerScriptTapHandler(function()
        audio.play(audio.button)

        local summonNum = 0
        if bag.items.find(ITEM_ID_SP_REPLACE) then
            summonNum = bag.items.find(ITEM_ID_SP_REPLACE).num
        end
        if summonNum < upcount(cfghero[lefheroinfo.id].group, cfghero[lefheroinfo.id].qlt) then
            showToast(i18n.global.space_summon_no_replace.string)
            return
        end
        local params = {}
        params.sid = player.sid
        params.hid = lefheroinfo.hid

        addWaitNet()
        net:transform_hero(params, function(__data)
            delWaitNet()
            tbl2string(__data)
            if __data.status < 0 then
                showToast("status:" .. __data.status)
                return
            end
            heros.treehid = lefheroinfo.hid
            heros.treeid = __data.hero_id
            mainlayer.replaceFlag = false
            uphero(lefheroinfo, __data.hero_id)
            rigid = __data.hero_id
            --heros.del(lefheroinfo.hid)
            --lefheroinfo.id = 
            bag.items.sub({id = ITEM_ID_SP_REPLACE, num = upcount(cfghero[lefheroinfo.id].group, cfghero[lefheroinfo.id].qlt)})
        end)
    end)

    cancelbtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        local params = {}
        params.sid = player.sid
        params.type = 0

        addWaitNet()
        net:transform_ok(params, function(__data)
            delWaitNet()
            tbl2string(__data)
            if __data.status < 0 then
                showToast("status:" .. __data.status)
                return
            end
            heros.treehid = nil
            heros.treeid = nil
            mainlayer.replaceFlag = false
            uphero(lefheroinfo)
        end)
    end)

    okbtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        local params = {}
        params.sid = player.sid
        params.type = 1

        addWaitNet()
        net:transform_ok(params, function(__data)
            delWaitNet()
            tbl2string(__data)
            if __data.status < 0 then
                showToast("status:" .. __data.status)
                return
            end
            local heroData = heros.find(lefheroinfo.hid)
            for _,v in ipairs(heroData.equips) do
                if cfgequip[v].pos == EQUIP_POS_SKIN then
                    bag.equips.returnbag({ id = getHeroSkin(lefheroinfo.hid), num = 1})
                    table.remove(heroData.equips, _)
                end
            end
            mainlayer.replaceFlag = false
            heros.treehid = nil
            heros.treeid = nil
            heros.changeID(lefheroinfo.hid, rigid)
            uphero()
            local reward = createPopupPieceBatchSummonResult(rigid, lefheroinfo)
            layer:getParent():getParent():getParent():getParent():addChild(reward, 1000)
        end)
    end)
    return layer
end

return ui
