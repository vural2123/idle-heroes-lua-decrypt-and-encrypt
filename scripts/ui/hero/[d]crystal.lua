local ui = {}

require "common.func"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local cfgskill = require "config.skill"
local json = require "res.json"
local i18n = require "res.i18n"
local audio = require "res.audio"
local net = require "net.netClient"
local cfghero = require "config.hero"
local cfgequip = require "config.equip"
local heros = require "data.heros"
local bag = require "data.bag"
local player = require "data.player"
local particle = require "res.particle"

local function createSuredia(callback)
    local params = {}
    params.btn_count = 0
    params.body = string.format(i18n.global.crystal_dialog_upsure.string, 20)
    local board_w = 474

    local dialoglayer = require("ui.dialog").create(params) 

    local btnYesSprite = img.createLogin9Sprite(img.login.button_9_small_gold)
    btnYesSprite:setPreferredSize(CCSize(153, 50))
    local btnYes = SpineMenuItem:create(json.ui.button, btnYesSprite)
    btnYes:setPosition(board_w/2+95, 100)
    local labYes = lbl.createFont1(18, i18n.global.board_confirm_yes.string, ccc3(0x73, 0x3b, 0x05))
    labYes:setPosition(btnYes:getContentSize().width/2, btnYes:getContentSize().height/2)
    btnYesSprite:addChild(labYes)
    local menuYes = CCMenu:create()
    menuYes:setPosition(0, 0)
    menuYes:addChild(btnYes)
    dialoglayer.board:addChild(menuYes)

    local btnNoSprite = img.createLogin9Sprite(img.login.button_9_small_gold)
    btnNoSprite:setPreferredSize(CCSize(153, 50))
    local btnNo = SpineMenuItem:create(json.ui.button, btnNoSprite)
    btnNo:setPosition(board_w/2-95, 100)
    local labNo = lbl.createFont1(18, i18n.global.board_confirm_no.string, ccc3(0x73, 0x3b, 0x05))
    labNo:setPosition(btnNo:getContentSize().width/2, btnNo:getContentSize().height/2)
    btnNoSprite:addChild(labNo)
    local menuNo = CCMenu:create()
    menuNo:setPosition(0, 0)
    menuNo:addChild(btnNo)
    dialoglayer.board:addChild(menuNo)
    
    btnYes:registerScriptTapHandler(function()
        audio.play(audio.button)
        dialoglayer:removeFromParentAndCleanup(true)
        callback()
    end)

    btnNo:registerScriptTapHandler(function()
        dialoglayer:removeFromParentAndCleanup(true)
        audio.play(audio.button)
    end)

    local function backEvent()
        dialoglayer:removeFromParentAndCleanup(true)
    end

    function dialoglayer.onAndroidBack()
        backEvent()
    end

    addBackEvent(dialoglayer)
    
    local function onEnter()
        dialoglayer.notifyParentLock()
    end

    local function onExit()
        dialoglayer.notifyParentUnlock()
    end

    dialoglayer:registerScriptHandler(function(event) 
        if event == "enter" then 
            onEnter()
        elseif event == "exit" then
            onExit()
        end
    end)
    return dialoglayer
end

function ui.change(heroData, callback)
    local layer = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))

    local equipPos, cryId 
    local NextId

    local board = img.createUI9Sprite(img.ui.dialog_1)
    board:setPreferredSize(CCSize(680, 520))
    board:setScale(view.minScale)
    board:setPosition(view.midX, view.midY)
    layer:addChild(board)

    local btnCloseSprite = img.createUISprite(img.ui.close)
    local btnClose = SpineMenuItem:create(json.ui.button, btnCloseSprite)
    btnClose:setPosition(654, 490)
    local menuClose = CCMenu:createWithItem(btnClose)
    menuClose:setPosition(0, 0)
    board:addChild(menuClose)
    btnClose:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer:removeFromParentAndCleanup(true)
    end)

    local title = lbl.createFont1(24, i18n.global.crystal_title_recast.string, ccc3(0xe6, 0xd0, 0xae))
    title:setPosition(340, 430+58)
    board:addChild(title, 1)
    local titleShade = lbl.createFont1(24, i18n.global.crystal_title_recast.string, ccc3(0x59, 0x30, 0x1b))
    titleShade:setPosition(340, 428+58)
    board:addChild(titleShade)

    -- coin bg
    local coin_bg = img.createUI9Sprite(img.ui.main_coin_bg)
    coin_bg:setPreferredSize(CCSizeMake(155, 40))
    coin_bg:setPosition(CCPoint(240, 436))
    board:addChild(coin_bg)
    -- crpiece bg
    local crpiece_bg = img.createUI9Sprite(img.ui.main_coin_bg)
    crpiece_bg:setPreferredSize(CCSizeMake(155, 40))
    crpiece_bg:setPosition(CCPoint(440, 436))
    board:addChild(crpiece_bg)
    -- coin icon
    local icon_coin = img.createItemIcon2(ITEM_ID_COIN)
    icon_coin:setPosition(CCPoint(5, coin_bg:getContentSize().height/2+2))
    coin_bg:addChild(icon_coin)
    local icon_crpiece = img.createItemIcon2(ITEM_ID_CRYSTAL_PIECE)
    icon_crpiece:setPosition(CCPoint(5, crpiece_bg:getContentSize().height/2+2))
    crpiece_bg:addChild(icon_crpiece)
    -- coin btn
    local btn_coin0 = img.createUISprite(img.ui.main_icon_plus)
    local btn_coin = HHMenuItem:create(btn_coin0)
    btn_coin:setPosition(CCPoint(coin_bg:getContentSize().width-18, coin_bg:getContentSize().height/2+2))
    local btn_coin_menu = CCMenu:createWithItem(btn_coin)
    btn_coin_menu:setPosition(CCPoint(0, 0))
    coin_bg:addChild(btn_coin_menu)
    ---- gem btn
    --local btn_gem0 = img.createUISprite(img.ui.main_icon_plus)
    --local btn_gem = HHMenuItem:create(btn_gem0)
    --btn_gem:setPosition(CCPoint(gem_bg:getContentSize().width-18, gem_bg:getContentSize().height/2+2))
    --local btn_gem_menu = CCMenu:createWithItem(btn_gem)
    --btn_gem_menu:setPosition(CCPoint(0, 0))
    --gem_bg:addChild(btn_gem_menu)

    btn_coin:registerScriptTapHandler(function()
        audio.play(audio.button)
        local midas = require "ui.midas.main"
        local midasdlg = midas.create()
        layer:addChild(midasdlg, 1001)
    end)

    --btn_gem:registerScriptTapHandler(function()
    --    audio.play(audio.button)
    --    local gemshop = require "ui.shop.main"
    --    local gemShop = gemshop.create()
    --    layer:addChild(gemShop, 1001)
    --end)

    -- lbl coin
    local coin_num = bag.coin()
    local lbl_coin = lbl.createFont2(16, num2KM(coin_num), ccc3(255, 246, 223))
    lbl_coin:setPosition(CCPoint(coin_bg:getContentSize().width/2-10, coin_bg:getContentSize().height/2+3))
    coin_bg:addChild(lbl_coin)
    lbl_coin.num = coin_num
    -- lbl crpiece
    local crpiece_num = 0
    if bag.items.find(ITEM_ID_CRYSTAL_PIECE) then
        crpiece_num = bag.items.find(ITEM_ID_CRYSTAL_PIECE).num
    end
    local lbl_crpiece = lbl.createFont2(16, crpiece_num, ccc3(255, 246, 223))
    lbl_crpiece:setPosition(CCPoint(crpiece_bg:getContentSize().width/2-10, crpiece_bg:getContentSize().height/2+3))
    crpiece_bg:addChild(lbl_crpiece)
    lbl_crpiece.num = crpiece_num

    local function updateLabels()
        local coinnum = bag.coin()
        if lbl_coin.num ~= coinnum then
            lbl_coin:setString(num2KM(coinnum))
            lbl_coin.num = coinnum
        end
        local crpiecenum = 0
        if bag.items.find(ITEM_ID_CRYSTAL_PIECE) then
            crpiecenum = bag.items.find(ITEM_ID_CRYSTAL_PIECE).num
        end
        if lbl_crpiece.num ~= crpiecenum then
            lbl_crpiece:setString(crpiecenum)
            lbl_crpiece.num = crpiecenum
        end
    end
    
    local function onUpdate(ticks)
        updateLabels()
    end

    layer:scheduleUpdateWithPriorityLua(onUpdate, 0)

    local InnerBg = img.createUI9Sprite(img.ui.inner_bg)
    InnerBg:setPreferredSize(CCSize(620, 218))
    InnerBg:setAnchorPoint(0.5, 0)
    InnerBg:setPosition(340, 190)
    board:addChild(InnerBg)

    local lefBoard = img.createUI9Sprite(img.ui.botton_fram_2)
    lefBoard:setPreferredSize(CCSize(254, 175))
    lefBoard:setPosition(153, 113)
    InnerBg:addChild(lefBoard)

    local lefLayer = CCLayer:create()
    lefBoard:addChild(lefLayer)

    local showArrow = img.createUISprite(img.ui.arrow)
    showArrow:setPosition(310, 113)
    InnerBg:addChild(showArrow)

    local rigBoard = img.createUI9Sprite(img.ui.botton_fram_2)
    rigBoard:setPreferredSize(CCSize(254, 175))
    rigBoard:setPosition(467, 113)
    InnerBg:addChild(rigBoard)
   
    local rigLayer = CCLayer:create()
    rigBoard:addChild(rigLayer)

    json.load(json.ui.baoshi_hecheng)
    local anim = DHSkeletonAnimation:createWithKey(json.ui.baoshi_hecheng)
    anim:scheduleUpdateLua()
    anim:setPosition(rigBoard:getContentSize().width/2 - 2, rigBoard:getContentSize().height/2 + 2)
    rigBoard:addChild(anim)
    
    --local coin = 0
    --local crystal = 0
    --if bag.items.find(ITEM_ID_COIN) then
    --    coin = bag.items.find(ITEM_ID_COIN).num
    --end
    --if bag.items.find(ITEM_ID_CRYSTAL_PIECE) then
    --    crystal = bag.items.find(ITEM_ID_CRYSTAL_PIECE).num
    --end
    local coinCost, crystalCost = 0, 0 
    local coinBg = img.createUI9Sprite(img.ui.hero_evolve_cost_bg)
    coinBg:setPreferredSize(CCSize(200, 30))
    coinBg:setAnchorPoint(ccp(0, 0))
    coinBg:setPosition(135, 130)
    board:addChild(coinBg)

    local crystalBg = img.createUI9Sprite(img.ui.hero_evolve_cost_bg)
    crystalBg:setPreferredSize(CCSize(200, 30))
    crystalBg:setAnchorPoint(ccp(0, 0))
    crystalBg:setPosition(360, 130)
    board:addChild(crystalBg)

    local coinIcon = img.createItemIcon(ITEM_ID_COIN)
    coinIcon:setScale(0.53)
    coinIcon:setPosition(10, 15)
    coinBg:addChild(coinIcon)

    local crystalIcon = img.createItemIcon2(ITEM_ID_CRYSTAL_PIECE)
    --crystalIcon:setScale(0.53)
    crystalIcon:setPosition(10, 15)
    crystalBg:addChild(crystalIcon)

    local showCoin = lbl.createFont2(16, num2KM(coinCost), ccc3(255, 246, 223))
    showCoin:setPosition(coinBg:getContentSize().width/2, 15)
    coinBg:addChild(showCoin)

    local showCrystal = lbl.createFont2(16, num2KM(crystalCost), ccc3(255, 246, 223))
    showCrystal:setPosition(crystalBg:getContentSize().width/2, 15)
    crystalBg:addChild(showCrystal)

    local btnCrystalSp = img.createLogin9Sprite(img.login.button_9_small_gold)
    btnCrystalSp:setPreferredSize(CCSize(175, 55))
    local labCrystal = lbl.createFont1(20, i18n.global.crystal_recast.string, ccc3(0x73, 0x3b, 0x05))
    labCrystal:setPosition(btnCrystalSp:getContentSize().width/2, btnCrystalSp:getContentSize().height/2)
    btnCrystalSp:addChild(labCrystal)

    local btnCrystal = SpineMenuItem:create(json.ui.button, btnCrystalSp)
    local menuCrystal = CCMenu:createWithItem(btnCrystal)
    btnCrystal:setPosition(340, 60)
    menuCrystal:setPosition(0, 0)
    board:addChild(menuCrystal)

    local btnSaveSp = img.createLogin9Sprite(img.login.button_9_small_green)
    btnSaveSp:setPreferredSize(CCSize(175, 55))
    local labSave = lbl.createFont1(20, i18n.global.crystal_btn_save.string, ccc3(0x1b, 0x59, 0x02))
    labSave:setPosition(btnSaveSp:getContentSize().width/2, btnSaveSp:getContentSize().height/2)
    btnSaveSp:addChild(labSave)

    local btnSave = SpineMenuItem:create(json.ui.button, btnSaveSp)
    local menuSave = CCMenu:createWithItem(btnSave)
    btnSave:setPosition(446, 70)
    menuSave:setPosition(0, 0)
    board:addChild(menuSave)

    local btnCancelSp = img.createLogin9Sprite(img.login.button_9_small_gold)
    btnCancelSp:setPreferredSize(CCSize(175, 62))
    local labCancel = lbl.createFont1(20, i18n.global.crystal_recast.string, ccc3(0x73, 0x3b, 0x05))
    labCancel:setPosition(btnCancelSp:getContentSize().width/2, btnCancelSp:getContentSize().height/2)
    btnCancelSp:addChild(labCancel)

    local btnCancel = SpineMenuItem:create(json.ui.button, btnCancelSp)
    local menuCancel = CCMenu:createWithItem(btnCancel)
    btnCancel:setPosition(230, 70)
    menuCancel:setPosition(0, 0)
    board:addChild(menuCancel)

    local function loadStatus()
        lefLayer:removeAllChildrenWithCleanup()
        for i, v in ipairs(heroData.equips) do
            if cfgequip[v].pos == EQUIP_POS_JADE then
                equipPos = i
                cryId = v
            end
        end

        local showCrystalIcon = img.createEquip(cryId)
        showCrystalIcon:setScale(0.5)
        showCrystalIcon:setPosition(43, 133)
        lefLayer:addChild(showCrystalIcon)

        local showName = lbl.createFont1(18, i18n.equip[cryId].name, ccc3(0x94, 0x62, 0x42))
        showName:setAnchorPoint(ccp(0, 0))
        showName:setPosition(showCrystalIcon:boundingBox():getMaxX() + 5, showCrystalIcon:boundingBox():getMinY())
        lefLayer:addChild(showName)

        local fgLine = img.createUI9Sprite(img.ui.hero_enchant_info_fgline)
        fgLine:setPreferredSize(CCSize(217, 2))
        fgLine:setPosition(127, 100)
        lefLayer:addChild(fgLine)

        for i = 1, 3 do
            local attr = cfgequip[cryId]["base" .. i]
            if attr then
                local name, value = buffString(attr.type, math.abs(attr.num))
                local attr_str = "+" .. value .. " " .. name
                if attr.num < 0 then
                    attr_str = "-" .. value .. " " .. name
                end
                local label = lbl.createMixFont1(18, attr_str, ccc3(0x6f, 0x4c, 0x38))
                label:setAnchorPoint(ccp(0, 0))
                label:setPosition(20, 92 - 24 * i)
                lefLayer:addChild(label)
            end
        end
        if bag.items.find(ITEM_ID_COIN) then
            coin = bag.items.find(ITEM_ID_COIN).num
        end
        if bag.items.find(ITEM_ID_CRYSTAL_PIECE) then
            crystal = bag.items.find(ITEM_ID_CRYSTAL_PIECE).num
        else
            crystal = 0
        end
        coinCost, crystalCost = cfgequip[cryId].jadeRefresh[2].num, cfgequip[cryId].jadeRefresh[1].num
        showCoin:setString(num2KM(coinCost))
        showCrystal:setString(num2KM(crystalCost))
    
        rigLayer:removeAllChildrenWithCleanup(true)
        if NextId then
            local showCrystalIcon = img.createEquip(NextId)
            showCrystalIcon:setScale(0.5)
            showCrystalIcon:setPosition(43, 133)
            rigLayer:addChild(showCrystalIcon)

            local showName = lbl.createFont1(18, i18n.equip[NextId].name, ccc3(0x94, 0x62, 0x42))
            showName:setAnchorPoint(ccp(0, 0))
            showName:setPosition(showCrystalIcon:boundingBox():getMaxX() + 5, showCrystalIcon:boundingBox():getMinY())
            rigLayer:addChild(showName)

            local fgLine = img.createUI9Sprite(img.ui.hero_enchant_info_fgline)
            fgLine:setPreferredSize(CCSize(217, 2))
            fgLine:setPosition(127, 100)
            rigLayer:addChild(fgLine)

            for i = 1, 3 do
                local attr = cfgequip[NextId]["base" .. i]
                if attr then
                    local name, value = buffString(attr.type, math.abs(attr.num))
                    local attr_str = "+" .. value .. " " .. name
                    if attr.num < 0 then
                        attr_str = "-" .. value .. " " .. name
                    end

                    local label = lbl.createMixFont1(18, attr_str, ccc3(0x08, 0x8d, 0x0e))
                    label:setAnchorPoint(ccp(0, 0))
                    label:setPosition(20, 92 - 24 * i)
                    rigLayer:addChild(label)
                end
            end          
            btnSave:setVisible(true)
            btnCancel:setVisible(true)
            btnCrystal:setVisible(false)
        else
            btnSave:setVisible(false)
            btnCancel:setVisible(false)
            btnCrystal:setVisible(true)
            
            local showRigLab = lbl.createFont1(18, i18n.global.crystal_rig_content.string, ccc3(0x6f, 0x4c, 0x38))
            showRigLab:setPosition(127, 54)
            rigLayer:addChild(showRigLab)

            local showRigIcon = img.createUISprite(img.ui.hero_equip_crystal)
            showRigIcon:setPosition(127, 105)
            rigLayer:addChild(showRigIcon)
        end
    end

    loadStatus()
    btnCrystal:registerScriptTapHandler(function()
        local params = {
            sid = player.sid,
            hid = heroData.hid,
        }
        if coin < coinCost then
            showToast(i18n.global.crystal_toast_coin.string)
            return
        elseif crystal < crystalCost then
            showToast(i18n.global.crystal_toast_piece.string)
            return
        end
        addWaitNet()
        net:jade_change(params, function(__data)
            delWaitNet()

            tbl2string(__data)
            if __data.status < 0 then
                showToast("status:" .. __data.status)
                return
            end

            NextId = __data.jade
            bag.items.sub({ id = ITEM_ID_COIN, num = coinCost })
            bag.items.sub({ id = ITEM_ID_CRYSTAL_PIECE, num = crystalCost })
            anim:playAnimation("animation2")
            loadStatus()
        end)
    end)

    btnCancel:registerScriptTapHandler(function()
        local params = {
            sid = player.sid,
            hid = heroData.hid,
        }
        if coin < coinCost then
            showToast(i18n.global.crystal_toast_coin.string)
            return
        elseif crystal < crystalCost then
            showToast(i18n.global.crystal_toast_piece.string)
            return
        end
        addWaitNet()
        net:jade_change(params, function(__data)
            delWaitNet()

            tbl2string(__data)
            if __data.status < 0 then
                showToast("status:" .. __data.status)
                return
            end

            NextId = __data.jade
            bag.items.sub({ id = ITEM_ID_COIN, num = coinCost })
            bag.items.sub({ id = ITEM_ID_CRYSTAL_PIECE, num = crystalCost })
            anim:playAnimation("animation2")
            loadStatus()
        end)
    end)

    btnSave:registerScriptTapHandler(function()
        local params = {
            sid = player.sid,
            hid = heroData.hid,
        }
        addWaitNet()
        net:jade_ok(params, function(__data)
            delWaitNet()

            tbl2string(__data)
            if __data.status < 0 then
                showToast("status:" .. __data.status)
                return
            end

            heroData.equips[equipPos] = NextId
            NextId = nil
            loadStatus()
            callback(heroData.equips[equipPos])
        end)
    end)
    
    layer:registerScriptTouchHandler(function() return true end)
    layer:setTouchEnabled(true)
    
    return layer
end

function ui.levelUp(heroData, callback)
    local layer = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))

    local equipPos, cryId 
    local NextId

    local board = img.createUI9Sprite(img.ui.dialog_1)
    board:setPreferredSize(CCSize(680, 518))
    board:setScale(view.minScale)
    board:setPosition(view.midX, view.midY)
    layer:addChild(board)

    local btnCloseSprite = img.createUISprite(img.ui.close)
    local btnClose = SpineMenuItem:create(json.ui.button, btnCloseSprite)
    btnClose:setPosition(654, 490)
    local menuClose = CCMenu:createWithItem(btnClose)
    menuClose:setPosition(0, 0)
    board:addChild(menuClose)
    btnClose:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer:removeFromParentAndCleanup(true)
    end)

    local title = lbl.createFont1(24, i18n.global.crystal_title_lvup.string, ccc3(0xe6, 0xd0, 0xae))
    title:setPosition(340, 430+58)
    board:addChild(title, 1)
    local titleShade = lbl.createFont1(24, i18n.global.crystal_title_lvup.string, ccc3(0x59, 0x30, 0x1b))
    titleShade:setPosition(340, 486)
    board:addChild(titleShade)

    --money bar
    -- coin bg
    local coin_bg = img.createUI9Sprite(img.ui.main_coin_bg)
    coin_bg:setPreferredSize(CCSizeMake(155, 40))
    coin_bg:setPosition(CCPoint(340-188, 436))
    board:addChild(coin_bg)
    -- gem bg
    local gem_bg = img.createUI9Sprite(img.ui.main_coin_bg)
    gem_bg:setPreferredSize(CCSizeMake(155, 40))
    gem_bg:setPosition(CCPoint(340, 436))
    board:addChild(gem_bg)
    -- crpiece bg
    local crpiece_bg = img.createUI9Sprite(img.ui.main_coin_bg)
    crpiece_bg:setPreferredSize(CCSizeMake(155, 40))
    crpiece_bg:setPosition(CCPoint(340+188, 436))
    board:addChild(crpiece_bg)
    -- coin icon
    local icon_coin = img.createItemIcon2(ITEM_ID_COIN)
    icon_coin:setPosition(CCPoint(5, coin_bg:getContentSize().height/2+2))
    coin_bg:addChild(icon_coin)
    -- gem icon
    local icon_gem = img.createItemIcon2(ITEM_ID_GEM)
    icon_gem:setPosition(CCPoint(5, gem_bg:getContentSize().height/2+2))
    gem_bg:addChild(icon_gem)
    local icon_crpiece = img.createItemIcon2(ITEM_ID_CRYSTAL_PIECE)
    icon_crpiece:setPosition(CCPoint(5, crpiece_bg:getContentSize().height/2+2))
    crpiece_bg:addChild(icon_crpiece)
    -- coin btn
    local btn_coin0 = img.createUISprite(img.ui.main_icon_plus)
    local btn_coin = HHMenuItem:create(btn_coin0)
    btn_coin:setPosition(CCPoint(coin_bg:getContentSize().width-18, coin_bg:getContentSize().height/2+2))
    local btn_coin_menu = CCMenu:createWithItem(btn_coin)
    btn_coin_menu:setPosition(CCPoint(0, 0))
    coin_bg:addChild(btn_coin_menu)

    btn_coin:registerScriptTapHandler(function()
        audio.play(audio.midas)
        local midas = require "ui.midas.main"
        local midasdlg = midas.create()
        layer:addChild(midasdlg, 1001)
    end)
    
    -- gem btn
    local btn_gem0 = img.createUISprite(img.ui.main_icon_plus)
    local btn_gem = HHMenuItem:create(btn_gem0)
    btn_gem:setPosition(CCPoint(gem_bg:getContentSize().width-18, gem_bg:getContentSize().height/2+2))
    local btn_gem_menu = CCMenu:createWithItem(btn_gem)
    btn_gem_menu:setPosition(CCPoint(0, 0))
    gem_bg:addChild(btn_gem_menu)

    btn_gem:registerScriptTapHandler(function()
        audio.play(audio.button)
        local gemshop = require "ui.shop.main"
        local gemShop = gemshop.create()
        layer:addChild(gemShop, 1001)
    end)
    -- lbl coin
    local coin_num = bag.coin()
    local lbl_coin = lbl.createFont2(16, num2KM(coin_num), ccc3(255, 246, 223))
    lbl_coin:setPosition(CCPoint(coin_bg:getContentSize().width/2-10, coin_bg:getContentSize().height/2+3))
    coin_bg:addChild(lbl_coin)
    lbl_coin.num = coin_num
    -- lbl gem
    local gem_num = bag.gem()
    local lbl_gem = lbl.createFont2(16, gem_num, ccc3(255, 246, 223))
    lbl_gem:setPosition(CCPoint(gem_bg:getContentSize().width/2-10, gem_bg:getContentSize().height/2+3))
    gem_bg:addChild(lbl_gem)
    lbl_gem.num = gem_num
    -- lbl crpiece
    local crpiece_num = 0
    if bag.items.find(ITEM_ID_CRYSTAL_PIECE) then
        crpiece_num = bag.items.find(ITEM_ID_CRYSTAL_PIECE).num
    end
    local lbl_crpiece = lbl.createFont2(16, crpiece_num, ccc3(255, 246, 223))
    lbl_crpiece:setPosition(CCPoint(crpiece_bg:getContentSize().width/2-10, crpiece_bg:getContentSize().height/2+3))
    crpiece_bg:addChild(lbl_crpiece)
    lbl_crpiece.num = crpiece_num


    local function updateLabels()
        local coinnum = bag.coin()
        if lbl_coin.num ~= coinnum then
            lbl_coin:setString(num2KM(coinnum))
            lbl_coin.num = coinnum
        end
        local gemnum = bag.gem()
        if lbl_gem.num ~= gemnum then
            lbl_gem:setString(gemnum)
            lbl_gem.num = gemnum
        end
        local crpiecenum = 0
        if bag.items.find(ITEM_ID_CRYSTAL_PIECE) then
            crpiecenum = bag.items.find(ITEM_ID_CRYSTAL_PIECE).num
        end
        if lbl_crpiece.num ~= crpiecenum then
            lbl_crpiece:setString(crpiecenum)
            lbl_crpiece.num = crpiecenum
        end
    end
    
    local function onUpdate(ticks)
        updateLabels()
    end

    layer:scheduleUpdateWithPriorityLua(onUpdate, 0)

    local InnerBg = img.createUI9Sprite(img.ui.inner_bg)
    InnerBg:setPreferredSize(CCSize(620, 218))
    InnerBg:setAnchorPoint(0.5, 0)
    InnerBg:setPosition(340, 188)
    board:addChild(InnerBg)

    local lefBoard = img.createUI9Sprite(img.ui.botton_fram_2)
    lefBoard:setPreferredSize(CCSize(254, 172))
    lefBoard:setPosition(153, 113)
    InnerBg:addChild(lefBoard)

    local lefLayer = CCLayer:create()
    lefBoard:addChild(lefLayer)

    local showArrow = img.createUISprite(img.ui.arrow)
    showArrow:setPosition(310, 113)
    InnerBg:addChild(showArrow)

    local rigBoard = img.createUI9Sprite(img.ui.botton_fram_2)
    rigBoard:setPreferredSize(CCSize(254, 172))
    rigBoard:setPosition(467, 113)
    InnerBg:addChild(rigBoard)
   
    local rigLayer = CCLayer:create()
    rigBoard:addChild(rigLayer)

    local showRigLab = lbl.createFont1(18, i18n.global.crystal_rig_content.string, ccc3(0x6f, 0x4c, 0x38))
    showRigLab:setPosition(127, 54)
    rigLayer:addChild(showRigLab)

    local showRigIcon = img.createUISprite(img.ui.hero_equip_crystal)
    showRigIcon:setPosition(127, 105)
    rigLayer:addChild(showRigIcon)

    local coinCost, crystalCost = 0, 0 
    local coinBg = img.createUI9Sprite(img.ui.hero_evolve_cost_bg)
    coinBg:setPreferredSize(CCSize(200, 30))
    coinBg:setAnchorPoint(ccp(0, 0))
    coinBg:setPosition(135, 148)
    board:addChild(coinBg)

    local crystalBg = img.createUI9Sprite(img.ui.hero_evolve_cost_bg)
    crystalBg:setPreferredSize(CCSize(200, 30))
    crystalBg:setAnchorPoint(ccp(0, 0))
    crystalBg:setPosition(360, 148)
    board:addChild(crystalBg)

    local coinIcon = img.createItemIcon(ITEM_ID_COIN)
    coinIcon:setScale(0.53)
    coinIcon:setPosition(10, 15)
    coinBg:addChild(coinIcon)

    local crystalIcon = img.createItemIcon2(ITEM_ID_CRYSTAL_PIECE)
    --crystalIcon:setScale(0.53)
    crystalIcon:setPosition(10, 15)
    crystalBg:addChild(crystalIcon)

    local showCoin = lbl.createFont2(16, num2KM(coinCost), ccc3(255, 246, 223))
    showCoin:setPosition(coinBg:getContentSize().width/2, 15)
    coinBg:addChild(showCoin)

    local showCrystal = lbl.createFont2(16, num2KM(crystalCost), ccc3(255, 246, 223))
    showCrystal:setPosition(crystalBg:getContentSize().width/2, 15)
    crystalBg:addChild(showCrystal)

    local lockstate = false

    local btnCrystalSp = img.createLogin9Sprite(img.login.button_9_small_gold)
    btnCrystalSp:setPreferredSize(CCSize(205, 58))
    local labCrystal = lbl.createFont1(20, i18n.global.crystal_lvup.string, ccc3(0x73, 0x3b, 0x05))
    labCrystal:setPosition(btnCrystalSp:getContentSize().width/2, btnCrystalSp:getContentSize().height/2)
    btnCrystalSp:addChild(labCrystal)

    local btnCrystal = SpineMenuItem:create(json.ui.button, btnCrystalSp)
    local menuCrystal = CCMenu:createWithItem(btnCrystal)
    btnCrystal:setPosition(340, 60)
    menuCrystal:setPosition(0, 0)
    board:addChild(menuCrystal)
    local btnGemSp = img.createLogin9Sprite(img.login.button_9_small_gold)
    btnGemSp:setPreferredSize(CCSize(205, 58))
    local labGem = lbl.createFont1(20, i18n.global.crystal_lvup.string, ccc3(0x73, 0x3b, 0x05))
    labGem:setPosition(btnGemSp:getContentSize().width/2, btnGemSp:getContentSize().height/2)
    btnGemSp:addChild(labGem)
    local levelupgem = 0 
    local upGem = img.createItemIcon2(ITEM_ID_GEM)
    upGem:setScale(0.9)
    upGem:setPosition(30, btnGemSp:getContentSize().height/2+3)
    btnGemSp:addChild(upGem)

    local upGemlab = lbl.createFont2(16, string.format("%d", levelupgem), ccc3(255, 246, 223))
    upGemlab:setPosition(upGem:getContentSize().width/2, 0) 
    upGem:addChild(upGemlab)

    local btnGem = SpineMenuItem:create(json.ui.button, btnGemSp)
    local menuGem = CCMenu:createWithItem(btnGem)
    btnGem:setPosition(340, 60)
    menuGem:setPosition(0, 0)
    board:addChild(menuGem) 

    local function loadStatus()
        lefLayer:removeAllChildrenWithCleanup()
        for i, v in ipairs(heroData.equips) do
            if cfgequip[v].pos == EQUIP_POS_JADE then
                equipPos = i
                cryId = v
            end
        end

        local showCrystalIcon = img.createEquip(cryId)
        showCrystalIcon:setScale(0.5)
        showCrystalIcon:setPosition(43, 133)
        lefLayer:addChild(showCrystalIcon)

        local showName = lbl.createFont1(18, i18n.equip[cryId].name, ccc3(0x94, 0x62, 0x42))
        showName:setAnchorPoint(ccp(0, 0))
        showName:setPosition(showCrystalIcon:boundingBox():getMaxX() + 5, showCrystalIcon:boundingBox():getMinY())
        lefLayer:addChild(showName)

        local fgLine = img.createUI9Sprite(img.ui.hero_enchant_info_fgline)
        fgLine:setPreferredSize(CCSize(217, 2))
        fgLine:setPosition(127, 100)
        lefLayer:addChild(fgLine)

        for i = 1, 3 do
            local attr = cfgequip[cryId]["base" .. i]
            if attr then
                local name, value = buffString(attr.type, math.abs(attr.num))
                local attr_str = "+" .. value .. " " .. name
                if attr.num < 0 then
                    attr_str = "-" .. value .. " " .. name
                end
                local label = lbl.createMixFont1(18, attr_str, ccc3(0x6f, 0x4c, 0x38))
                label:setAnchorPoint(ccp(0, 0))
                label:setPosition(20, 92 - 24 * i)
                lefLayer:addChild(label)
            end
        end
        --if bag.items.find(ITEM_ID_COIN) then
        --    coin = bag.items.find(ITEM_ID_COIN).num
        --end
        if bag.items.find(ITEM_ID_CRYSTAL_PIECE) then
            crystal = bag.items.find(ITEM_ID_CRYSTAL_PIECE).num
        else
            crystal = 0
        end

        if not isJadeUpgradable(cryId) then
            coinCost, crystalCost = 0, 0 
        else
            coinCost, crystalCost = cfgequip[cryId].jadeUpgrade[2].num, cfgequip[cryId].jadeUpgrade[1].num
        end
        showCoin:setString(num2KM(coinCost))
        showCrystal:setString(num2KM(crystalCost))

        rigLayer:removeAllChildrenWithCleanup(true)
        if NextId then
            local showCrystalIcon = img.createEquip(NextId)
            showCrystalIcon:setScale(0.5)
            showCrystalIcon:setPosition(43, 133)
            rigLayer:addChild(showCrystalIcon)

            local showName = lbl.createFont1(18, i18n.equip[NextId].name, ccc3(0x94, 0x62, 0x42))
            showName:setAnchorPoint(ccp(0, 0))
            showName:setPosition(showCrystalIcon:boundingBox():getMaxX() + 5, showCrystalIcon:boundingBox():getMinY())
            rigLayer:addChild(showName)

            local fgLine = img.createUI9Sprite(img.ui.hero_enchant_info_fgline)
            fgLine:setPreferredSize(CCSize(217, 2))
            fgLine:setPosition(127, 100)
            rigLayer:addChild(fgLine)

            for i = 1, 3 do
                local attr = cfgequip[NextId]["base" .. i]
                if attr then
                    local name, value = buffString(attr.type, math.abs(attr.num))
                    local attr_str = "+" .. value .. " " .. name
                    if attr.num < 0 then
                        attr_str = "-" .. value .. " " .. name
                    end
                    local label = lbl.createMixFont1(18, attr_str, ccc3(0x08, 0x8d, 0x0e))
                    label:setAnchorPoint(ccp(0, 0))
                    label:setPosition(20, 92 - 24 * i)
                    rigLayer:addChild(label)
                end
            end          
            levelupgem = cfgequip[cryId].jadeLockUp.num
            upGemlab:setString(string.format("%d", levelupgem))
            btnGem:setVisible(true)
            btnCrystal:setVisible(false)
        else
            btnGem:setVisible(false)
            btnCrystal:setVisible(true)
            
            local showRigLab = lbl.createFont1(18, i18n.global.crystal_rig_content.string, ccc3(0x6f, 0x4c, 0x38))
            showRigLab:setPosition(127, 54)
            rigLayer:addChild(showRigLab)

            local showRigIcon = img.createUISprite(img.ui.hero_equip_crystal)
            showRigIcon:setPosition(127, 105)
            rigLayer:addChild(showRigIcon)
        end
    end
    local updateHide = nil
    loadStatus()
    
    local function upno()
        local params = {
            sid = player.sid,
            hid = heroData.hid,
        }
        if not isJadeUpgradable(cryId) then
            showToast(i18n.global.crystal_toast_maxlv.string)
            return 
        elseif lbl_coin.num < coinCost then
            showToast(i18n.global.crystal_toast_coin.string)
            return
        elseif lbl_crpiece.num < crystalCost then
            showToast(i18n.global.crystal_toast_piece.string)
            return
        end
        addWaitNet()
        net:jade_up(params, function(__data)
            delWaitNet()

            tbl2string(__data)
            if __data.status < 0 then
                showToast("status:" .. __data.status)
                return
            end

            heroData.equips[equipPos] = __data.jade
            bag.items.sub({ id = ITEM_ID_COIN, num = coinCost })
            bag.items.sub({ id = ITEM_ID_CRYSTAL_PIECE, num = crystalCost })
            loadStatus()
            callback(__data.jade)
            btnCrystal:setEnabled(false)
            layer:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(1), CCCallFunc:create(function() 
                btnCrystal:setEnabled(true)
            end)))
        end)
    end

    local function upForgem()
        local params = {
            sid = player.sid,
            hid = heroData.hid,
            gem = true 
        }
        if not isJadeUpgradable(cryId) then
            showToast(i18n.global.crystal_toast_maxlv.string)
            return 
        elseif lbl_coin.num < coinCost then
            showToast(i18n.global.crystal_toast_coin.string)
            return
        elseif lbl_gem.num < levelupgem then
            showToast(i18n.global.gboss_fight_st6.string)
            return
        elseif lbl_crpiece.num < crystalCost then
            showToast(i18n.global.crystal_toast_piece.string)
            return
        end
        addWaitNet()
        net:jade_up(params, function(__data)
            delWaitNet()

            tbl2string(__data)
            if __data.status < 0 then
                showToast("status:" .. __data.status)
                return
            end

            heroData.equips[equipPos] = __data.jade
            bag.items.sub({ id = ITEM_ID_COIN, num = coinCost })
            bag.items.sub({ id = ITEM_ID_CRYSTAL_PIECE, num = crystalCost })
            bag.items.sub({ id = ITEM_ID_GEM, num = levelupgem })
            NextId = nil
            lockstate = false            
            updateHide()
            loadStatus()
            callback(__data.jade)
            btnCrystal:setEnabled(false)
            layer:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(1), CCCallFunc:create(function() 
                btnCrystal:setEnabled(true)
            end)))
        end)
    end

    btnGem:registerScriptTapHandler(function()
        audio.play(audio.button)

        if cfgequip[heroData.equips[equipPos]].qlt < 6 then
            upForgem()
        else
            local dialog = createSuredia(upForgem)
            layer:addChild(dialog, 300)
        end
    end)

    btnCrystal:registerScriptTapHandler(function()
        audio.play(audio.button)
        if cfgequip[heroData.equips[equipPos]].qlt < 5 then
            upno()
        else
            local dialog = createSuredia(upno)
            layer:addChild(dialog, 300)
        end
    end)

    local lbllock = lbl.createMixFont1(16, i18n.global.crystal_lock_property.string, ccc3(0x73, 0x3b, 0x05))
    lbllock:setPosition(340+22, 118)
    board:addChild(lbllock)

    local btn_check0 = img.createUISprite(img.ui.guildFight_tick_bg)
    local icon_sel = img.createUISprite(img.ui.hook_btn_sel)
    icon_sel:setScale(0.75)
    icon_sel:setAnchorPoint(CCPoint(0, 0))
    icon_sel:setPosition(CCPoint(2, 2))
    btn_check0:addChild(icon_sel)
    local btn_check = SpineMenuItem:create(json.ui.button, btn_check0)
    btn_check:setPosition(CCPoint(lbllock:boundingBox():getMinX()-30, 118))
    local btn_check_menu = CCMenu:createWithItem(btn_check)
    btn_check_menu:setPosition(CCPoint(0, 0))
    board:addChild(btn_check_menu)
    function updateHide()
        icon_sel:setVisible(lockstate)
        loadStatus()
    end
    updateHide()
    btn_check:registerScriptTapHandler(function()
        audio.play(audio.button)
        if lockstate == false then 
            lockstate = true
            if cfgequip[cryId].jadeLockUp == nil then
                showToast(i18n.global.crystal_toast_maxlv.string) 
                return  
            end
            NextId = cfgequip[cryId].jadeLockUp.id
        else
            lockstate = false
            NextId = nil
        end
        updateHide()
    end)

    layer:registerScriptTouchHandler(function() return true end)
    layer:setTouchEnabled(true)
    
    return layer
end

return ui
