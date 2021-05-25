local ui = {}

require "common.func"
require "common.const"
local view = require "common.view"
local img = require "res.img"
local i18n = require "res.i18n"
local lbl = require "res.lbl"
local json = require "res.json"
local audio = require "res.audio"
local player = require "data.player"
local daredata = require "data.dare"
local cfghomeworld = require "config.homeworld"
local airData = require "data.airisland"

function ui.create()
    local id = airData.data.id

    local layer = CCLayer:create()
    -- dark bg
    local darkbg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    layer:addChild(darkbg)
    -- board
    local board= img.createLogin9Sprite(img.login.dialog)
    board:setPreferredSize(CCSizeMake(755, 486))
    board:setScale(view.minScale)
    board:setPosition(view.midX-0*view.minScale, view.midY)
    layer:addChild(board)
    layer.board = board
    local board_w = board:getContentSize().width
    local board_h = board:getContentSize().height

    -- anim
    if uiParams and uiParams._anim then
        board:setScale(0.5*view.minScale)
        board:runAction(CCScaleTo:create(0.15, 1*view.minScale, 1*view.minScale))
    end

    -- title
    --local lbl_title = lbl.createFont1(24, i18n.global.dare_main_title.string, ccc3(0xe6, 0xd0, 0xae))
    --lbl_title:setPosition(CCPoint(board_w/2, board_h-29))
    --board:addChild(lbl_title, 2)
    --local lbl_title_shadowD = lbl.createFont1(24, i18n.global.dare_main_title.string, ccc3(0x59, 0x30, 0x1b))
    --lbl_title_shadowD:setPosition(CCPoint(board_w/2, board_h-31))
    --board:addChild(lbl_title_shadowD)

    local function backEvent()
        audio.play(audio.button)
        layer:removeFromParentAndCleanup(true)
    end
    -- btn_close
    local btn_close0 = img.createUISprite(img.ui.close)
    local btn_close = SpineMenuItem:create(json.ui.button, btn_close0)
    btn_close:setPosition(CCPoint(board_w-25, board_h-28))
    local btn_close_menu = CCMenu:createWithItem(btn_close)
    btn_close_menu:setPosition(CCPoint(0, 0))
    board:addChild(btn_close_menu, 100)
    layer.btn_close = btn_close
    btn_close:registerScriptTapHandler(function()
        backEvent()
    end)

    local innerBg = img.createUI9Sprite(img.ui.inner_bg)
    innerBg:setPreferredSize(CCSize(660, 250))
    innerBg:setAnchorPoint(ccp(0.5, 0))
    innerBg:setPosition(board:getContentSize().width/2, 160)
    board:addChild(innerBg)

    local towerinfoLayer = nil
    local function showTowerinfo()
        towerinfoLayer = CCLayer:create()
        board:addChild(towerinfoLayer)

        if cfghomeworld[id].lv < 20 then 
            local row = img.createUISprite(img.ui.arrow)
            row:setPosition(board_w/2, 280)
            board:addChild(row)

            local lnpcboard = img.createUI9Sprite(img.ui.botton_fram_4)
            lnpcboard:setPreferredSize(CCSizeMake(284, 212))
            lnpcboard:setAnchorPoint(CCPoint(0.5, 0))
            lnpcboard:setPosition(70+142, 175)
            towerinfoLayer:addChild(lnpcboard)

            local lowTownicon = img.createUISprite(img.ui["airisland_maintower_" .. cfghomeworld[id].show])
            lowTownicon:setScale(0.9)
            lowTownicon:setAnchorPoint(0.5, 0)
            lowTownicon:setPosition(70+142+20, 235)
            towerinfoLayer:addChild(lowTownicon)
            local lowLvbg = img.createUISprite(img.ui.airisland_lvbg)
            lowLvbg:setPosition(CCPoint(lowTownicon:getContentSize().width/2-20, 10))
            lowTownicon:addChild(lowLvbg)
            local lowlvlab = lbl.createFont1(14, "Lv:" .. cfghomeworld[id].lv, ccc3(255, 246, 223))
            lowlvlab:setPosition(CCPoint(lowLvbg:getContentSize().width/2, 14))
            lowLvbg:addChild(lowlvlab)
            local line1 = img.createUI9Sprite(img.ui.gemstore_fgline)
            line1:setPreferredSize(CCSize(238, 2))
            line1:setPosition(CCPoint(70+142, 260))
            towerinfoLayer:addChild(line1)

            local rnpcboard = img.createUI9Sprite(img.ui.botton_fram_2)
            rnpcboard:setPreferredSize(CCSizeMake(284, 212))
            rnpcboard:setAnchorPoint(CCPoint(1, 0))
            rnpcboard:setPosition(board_w-70, 175)
            towerinfoLayer:addChild(rnpcboard)
            local highTownicon = img.createUISprite(img.ui["airisland_maintower_" .. cfghomeworld[id+1].show])
            highTownicon:setScale(0.9)
            highTownicon:setAnchorPoint(0.5, 0)
            highTownicon:setPosition(board_w-70-142+20, 235)
            towerinfoLayer:addChild(highTownicon)
            local highLvbg = img.createUISprite(img.ui.airisland_lvbg)
            highLvbg:setPosition(CCPoint(lowTownicon:getContentSize().width/2-20, 10))
            highTownicon:addChild(highLvbg)
            local highlvlab = lbl.createFont1(14, "Lv:" .. cfghomeworld[id+1].lv, ccc3(255, 246, 223))
            highlvlab:setPosition(CCPoint(highLvbg:getContentSize().width/2, 14))
            highLvbg:addChild(highlvlab)
            local line2 = img.createUI9Sprite(img.ui.gemstore_fgline)
            line2:setPreferredSize(CCSize(238, 2))
            line2:setPosition(CCPoint(board_w-70-142, 260))
            towerinfoLayer:addChild(line2)

            local coinBg = img.createUI9Sprite(img.ui.hero_evolve_cost_bg)
            coinBg:setPreferredSize(CCSize(198, 32))
            coinBg:setAnchorPoint(1, 0.5)
            coinBg:setPosition(board_w/2-10, 125)
            towerinfoLayer:addChild(coinBg)
            local coinIcon = img.createItemIcon2(ITEM_ID_COIN)
            coinIcon:setPosition(10, 15)
            coinBg:addChild(coinIcon)

            local cryBg = img.createUI9Sprite(img.ui.hero_evolve_cost_bg)
            cryBg:setPreferredSize(CCSize(198, 32))
            cryBg:setAnchorPoint(0, 0.5)
            cryBg:setPosition(board_w/2+10, 125)
            towerinfoLayer:addChild(cryBg)
            local crystalIcon = img.createItemIcon2(ITEM_ID_GEM)
            crystalIcon:setPosition(10, 15)
            cryBg:addChild(crystalIcon)

            local upgrade0 = img.createLogin9Sprite(img.login.button_9_small_gold)
            upgrade0:setPreferredSize(CCSize(205, 58))
            local labUpgrade = lbl.createFont1(20, i18n.global.crystal_lvup.string, ccc3(0x73, 0x3b, 0x05))
            labUpgrade:setPosition(upgrade0:getContentSize().width/2, upgrade0:getContentSize().height/2)
            upgrade0:addChild(labUpgrade)
            local upgrade = SpineMenuItem:create(json.ui.button, upgrade0)
            upgrade:setPosition(CCPoint(board_w/2, 65))
            local upgradeMenu = CCMenu:createWithItem(upgrade)
            upgradeMenu:setPosition(CCPoint(0, 0))
            board:addChild(upgradeMenu, 100)
            --layer.btn_close = btn_close
            upgrade:registerScriptTapHandler(function()
                audio.play(audio.button) 
            end)
        else
            local lnpcboard = img.createUI9Sprite(img.ui.botton_fram_2)
            lnpcboard:setPreferredSize(CCSizeMake(560, 245))
            lnpcboard:setAnchorPoint(CCPoint(0.5, 0))
            lnpcboard:setPosition(70+142, 175)
            towerinfoLayer:addChild(lnpcboard)

            local lowTownicon = img.createUISprite(img.ui["airisland_maintower_" .. cfghomeworld[id].show])
            lowTownicon:setScale(0.9)
            lowTownicon:setAnchorPoint(0.5, 0)
            lowTownicon:setPosition(board_w/2+20, 235)
            towerinfoLayer:addChild(lowTownicon)
            local lowLvbg = img.createUISprite(img.ui.airisland_lvbg)
            lowLvbg:setPosition(CCPoint(lowTownicon:getContentSize().width/2-20, 10))
            lowTownicon:addChild(lowLvbg)
            local lowlvlab = lbl.createFont1(14, "Lv:" .. cfghomeworld[id].lv, ccc3(255, 246, 223))
            lowlvlab:setPosition(CCPoint(lowLvbg:getContentSize().width/2, 14))
            lowLvbg:addChild(lowlvlab)
            local line1 = img.createUI9Sprite(img.ui.gemstore_fgline)
            line1:setPreferredSize(CCSize(238, 2))
            line1:setPosition(CCPoint(board_w/2, 260))
            towerinfoLayer:addChild(line1)
        end
    end

    showTowerinfo()

    layer:setTouchEnabled(true)
    layer:setTouchSwallowEnabled(true)

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
        end
    end)

    --if uiParams and uiParams.from_layer == "dareStage" then
    --    layer:runAction(CCCallFunc:create(function()
    --        layer:addChild((require"ui.dare.stage").create({_anim=true, type=uiParams.type}), 1000)
    --    end))
    --end

    return layer
end

return ui
