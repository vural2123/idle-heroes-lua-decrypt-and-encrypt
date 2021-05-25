
local ui = {}

require "common.func"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local i18n = require "res.i18n"
local audio = require "res.audio"
local player = require "data.player"
local net = require "net.netClient"
local cfgwave = require "config.wavetrial"
local cfgmonster = require "config.monster"
local trial = require "data.trial"
local cfgstage = require "config.stage"
local hook = require "data.hook"

function ui.create()
    local layer = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))

    local board = img.createLogin9Sprite(img.login.dialog)
    board:setPreferredSize(CCSize(660, 510))
    board:setScale(view.minScale)
    board:setPosition(view.midX, view.midY)
    layer:addChild(board)

    local titleRank = lbl.createFont1(26, i18n.global.hook_pverank_title.string, ccc3(0xe6, 0xd0, 0xae))
    titleRank:setPosition(330, 481)
    board:addChild(titleRank, 1)
    local titleRankShade = lbl.createFont1(26, i18n.global.hook_pverank_title.string, ccc3(0x59, 0x30, 0x1b))
    titleRankShade:setPosition(330, 479)
    board:addChild(titleRankShade)

    local innerBg = img.createUI9Sprite(img.ui.hero_equip_lab_frame)
    innerBg:setPreferredSize(CCSize(600, 410))
    innerBg:setPosition(330, 240)
    board:addChild(innerBg)

    local btnCloseSprite = img.createUISprite(img.ui.close)
    local btnClose = SpineMenuItem:create(json.ui.button, btnCloseSprite)
    btnClose:setPosition(636, 484)
    local menuClose = CCMenu:createWithItem(btnClose)
    menuClose:setPosition(0, 0)
    board:addChild(menuClose)
    btnClose:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer:removeFromParentAndCleanup(true)
    end)

    local function createRankList(ranks)
        local ranks = ranks or {}

        local Height = 82 * (#ranks+1) + 6
        local scroll = CCScrollView:create()
        scroll:setDirection(kCCScrollViewDirectionVertical)
        scroll:setAnchorPoint(ccp(0, 0))
        scroll:setPosition(0, 2)
        scroll:setViewSize(CCSize(600, 405))
        scroll:setContentSize(CCSize(600, Height))
        scroll:setContentOffset(ccp(0, 405 - Height))
        innerBg:addChild(scroll)

        for i, v in ipairs(ranks) do
            local showBg = img.createUI9Sprite(img.ui.botton_fram_2)
            showBg:setPreferredSize(CCSize(577, 77))
            showBg:setAnchorPoint(ccp(0.5, 0))
            showBg:setPosition(300, Height - 6 - i * 79)
            scroll:getContainer():addChild(showBg)

            local rank = i 
            local showRank
            if rank <= 3 then
                showRank = img.createUISprite(img.ui["arena_rank_" .. rank])
            else
                showRank = lbl.createFont1(18, rank, ccc3(0x51, 0x27, 0x12))
            end
            showRank:setPosition(43, 39)
            showBg:addChild(showRank)
            
            local showHead = img.createPlayerHead(v.logo)
            showHead:setScale(0.65)
            showHead:setPosition(105, 40)
            showBg:addChild(showHead)
            
            local showLvBg = img.createUISprite(img.ui.main_lv_bg)
            --showLvBg:setScale(0.6)
            showLvBg:setPosition(158, 39)
            showBg:addChild(showLvBg)

            local showLv = lbl.createFont1(14, v.lv)
            showLv:setPosition(showLvBg:getContentSize().width/2, showLvBg:getContentSize().height/2)
            showLvBg:addChild(showLv)

            local showName = lbl.createFontTTF(20, v.name, ccc3(0x51, 0x27, 0x12))
            showName:setAnchorPoint(ccp(0, 0.5))
            showName:setPosition(190, showBg:getContentSize().height/2)
            showBg:addChild(showName)

            --local titleLayer = lbl.createFont1(14, i18n.global.hook_pverank_level.string, ccc3(0x7a, 0x53, 0x34))
            --titleLayer:setPosition(523, 53)
            --showBg:addChild(titleLayer)

            local showHurt = lbl.createFont1(22, num2KM(v.hurt), ccc3(0x9c, 0x45, 0x2d))
            showHurt:setPosition(523, showBg:getContentSize().height/2)
            showBg:addChild(showHurt)
        end
    end

    addBackEvent(layer)
    function layer.onAndroidBack()
        layer:removeFromParentAndCleanup(true)
    end
    local function onEnter()
        print("onEnter")
        layer.notifyParentLock()
        local params = {}
        params.sid = player.sid

        addWaitNet()
        net:gfire_rank(params, function(__data)
            delWaitNet()

            tbl2string(__data)
            local ranks = __data.ranks or {}
            createRankList(ranks)
        end)
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


    layer:registerScriptTouchHandler(function() return true end)
    layer:setTouchEnabled(true)

    board:setScale(0.5*view.minScale)
    local anim_arr = CCArray:create()
    anim_arr:addObject(CCScaleTo:create(0.15, 1*view.minScale, 1*view.minScale))
    anim_arr:addObject(CCDelayTime:create(0.15))
    anim_arr:addObject(CCCallFunc:create(function()
    
    end))
    board:runAction(CCSequence:create(anim_arr))


    return layer
end

return ui
