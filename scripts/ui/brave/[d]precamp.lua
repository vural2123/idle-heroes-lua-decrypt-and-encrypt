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

function ui.create()
    local layer = CCLayer:create()
    -- dark bg
    local darkbg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    layer:addChild(darkbg)
    
    local boardBg = img.createUI9Sprite(img.ui.dialog_1)
    boardBg:setPreferredSize(CCSizeMake(827, 425))
    boardBg:setScale(view.minScale)
    boardBg:setAnchorPoint(CCPoint(0.5, 0))
    boardBg:setPosition(view.midX, view.minY+127*view.minScale)
    layer:addChild(boardBg)

    -- list_board
    local herolistBg = img.createUI9Sprite(img.ui.tips_bg)
    herolistBg:setPreferredSize(CCSizeMake(954, 125))
    herolistBg:setScale(view.minScale)
    herolistBg:setAnchorPoint(CCPoint(0.5, 1))
    herolistBg:setPosition(CCPoint(view.midX, view.minY+0*view.minScale))
    layer:addChild(herolistBg)

    -- anim
    local anim_duration = 0.2
    boardBg:setPosition(CCPoint(view.midX, view.minY+576*view.minScale))
    boardBg:runAction(CCMoveTo:create(anim_duration, CCPoint(view.midX, view.minY+130*view.minScale)))
    herolistBg:runAction(CCMoveTo:create(anim_duration, CCPoint(view.midX, view.minY+123*view.minScale)))
    darkbg:runAction(CCFadeTo:create(anim_duration, POPUP_DARK_OPACITY))

    local lblTitle = lbl.createFont1(24, i18n.global.hook_team_board_title.string, ccc3(0xe6, 0xd0, 0xae))
    lblTitle:setPosition(CCPoint(boardBg:getContentSize().width/2, boardBg:getContentSize().height-29))
    boardBg:addChild(lblTitle, 2)
    local lblTitleShadow = lbl.createFont1(24, i18n.global.hook_team_board_title.string, ccc3(0x59, 0x30, 0x1b))
    lblTitleShadow:setPosition(CCPoint(boardBg:getContentSize().width/2, boardBg:getContentSize().height-31))
    boardBg:addChild(lblTitleShadow)

    local board = img.createUI9Sprite(img.ui.select_hero_camp_bg)
    board:setPreferredSize(CCSizeMake(770, 248))
    board:setAnchorPoint(CCPoint(0.5, 0))
    board:setPosition(CCPoint(boardBg:getContentSize().width/2, 94))
    boardBg:addChild(board)
    local boardTab = img.createUI9Sprite(img.ui.select_tab_tab_bg)
    boardTab:setPreferredSize(CCSizeMake(760, 38))
    boardTab:setAnchorPoint(CCPoint(0.5, 1))
    boardTab:setPosition(CCPoint(board:getContentSize().width/2, board:getContentSize().height-4))
    board:addChild(boardTab)
    local powerBg = img.createUISprite(img.ui.select_hero_power_bg)
    powerBg:setAnchorPoint(CCPoint(0, 0.5))
    powerBg:setPosition(CCPoint(0, boardTab:getContentSize().height/2))
    boardTab:addChild(powerBg)

    local powerIcon = img.createUISprite(img.ui.brave_team_icon)
    powerIcon:setPosition(CCPoint(30, powerBg:getContentSize().height/2))
    powerBg:addChild(powerIcon)

    local lblPower = lbl.createFont2(20, "0/18")
    lblPower:setAnchorPoint(CCPoint(0, 0.5))
    lblPower:setPosition(CCPoint(55, powerBg:getContentSize().height/2))
    powerBg:addChild(lblPower)

    local showText = lbl.createMixFont1(14, "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", ccc3(0x51, 0x27, 0x12))
    showText:setPosition(boardBg:getContentSize().width/2, 355)
    boardBg:addChild(showText)

    -- btn_hook
    local btnConfirm0 = img.createLogin9Sprite(img.login.button_9_small_gold)
    btnConfirm0:setPreferredSize(CCSizeMake(216, 52))
    local lblConfirm = lbl.createFont1(22, i18n.global.hook_team_save.string, ccc3(0x73, 0x3b, 0x05))
    lblConfirm:setPosition(CCPoint(btnConfirm0:getContentSize().width/2, btnConfirm0:getContentSize().height/2))
    btnConfirm0:addChild(lblConfirm)
    local btnConfirm = SpineMenuItem:create(json.ui.button, btnConfirm0)
    btnConfirm:setPosition(CCPoint(boardBg:getContentSize().width/2, 53))
    local btnConfirmMenu = CCMenu:createWithItem(btnConfirm)
    btnConfirmMenu:setPosition(CCPoint(0, 0))
    boardBg:addChild(btnConfirmMenu)

    local btnClose0 = img.createUISprite(img.ui.close)
    local btnClose = SpineMenuItem:create(json.ui.button, btnClose0)
    btnClose:setPosition(CCPoint(boardBg:getContentSize().width-25, boardBg:getContentSize().height-28))
    local btnCloseMenu = CCMenu:createWithItem(btnClose)
    btnCloseMenu:setPosition(CCPoint(0, 0))
    boardBg:addChild(btnCloseMenu, 100)
    btnClose:registerScriptTapHandler(function()
        layer:removeFromParentAndCleanup(true)
    end)

    local heroBg = {}
    for i=1, 18 do
        heroBg[i] = img.createUISprite(img.ui.select_hero_hero_bg)
        heroBg[i]:setAnchorPoint(ccp(0, 0))
        heroBg[i]:setScale(0.88)
        heroBg[i]:setPosition(20 + 82 * ((i-1)%9), 193 - math.ceil(i/9) * 86 )
        board:addChild(heroBg[i])
    end

    local scroll

    local herolist = clone(heros)
    local hids = {}
    local headIcons = {}
    local function createHeroList()
        local SCROLLVIEW_WIDTH = 943
        local SCROLLVIEW_HEIGHT = 112
        local SCROLLCONTENT_WIDTH = #herolist * 90 + 8

        scroll = CCScrollView:create()
        scroll:setDirection(kCCScrollViewDirectionHorizontal)
        scroll:setAnchorPoint(ccp(0, 0))
        scroll:setPosition(7, 6)
        scroll:setViewSize(CCSize(SCROLLVIEW_WIDTH, SCROLLVIEW_HEIGHT))
        scroll:setContentSize(CCSizeMake(SCROLLCONTENT_WIDTH, SCROLLVIEW_HEIGHT))
        herolistBg:addChild(scroll)

        local iconBgBatch = img.createBatchNodeForUI(img.ui.herolist_head_bg)
        scroll:getContainer():addChild(iconBgBatch, 1)
        local groupBgBatch = img.createBatchNodeForUI(img.ui.herolist_group_bg)
        scroll:getContainer():addChild(groupBgBatch , 3)
        local starBatch = img.createBatchNodeForUI(img.ui.star_s)
        scroll:getContainer():addChild(starBatch, 3)
        blackBatch = CCNode:create()
        scroll:getContainer():addChild(blackBatch, 4)
        selectBatch = img.createBatchNodeForUI(img.ui.hook_btn_sel)
        scroll:getContainer():addChild(selectBatch, 5)

        for i=1, #herolist do
            local x, y = 45 + (i-1) * 90 + 8, 56 
       
            local heroBg = img.createUISprite(img.ui.herolist_head_bg)
            heroBg:setScale(0.92)
            heroBg:setPosition(x, y)
            iconBgBatch:addChild(heroBg)

            headIcons[i] = img.createHeroHeadIcon(herolist[i].id)
            headIcons[i]:setScale(0.92)
            headIcons[i]:setPosition(x, y)
            scroll:getContainer():addChild(headIcons[i], 2)

            local groupBg = img.createUISprite(img.ui.herolist_group_bg)
            groupBg:setScale(0.42 * 0.92)
            groupBg:setPosition(x - 26, y + 26)
            groupBgBatch:addChild(groupBg)

            local groupIcon = img.createUISprite(img.ui["herolist_group_" .. cfghero[herolist[i].id].group])
            groupIcon:setScale(0.42 * 0.92)
            groupIcon:setPosition(x - 26, y + 26)
            scroll:getContainer():addChild(groupIcon, 3)

            local showLv = lbl.createFont2(15 * 0.92, herolist[i].lv)
            showLv:setPosition(x + 23, y + 26)
            scroll:getContainer():addChild(showLv, 3)

            local quality = cfghero[herolist[i].id].qlt
            local offset = x + 13 * quality / 2
            for j = 1, quality do
                local star = img.createUISprite(img.ui.star_s)
                star:setScale(0.92)
                star:setPosition(offset - j * 13 + 5, y - 30)
                starBatch:addChild(star)
            end
        end
    end
    createHeroList()

    local function onSelect(pos)
        if herolist[pos].isUsed == true then
            return
        end
        for i=1, 18 do
            if not hids[i] then
                herolist[pos].isUsed = true
                hids[i] = herolist[pos].hid 
                local showHero = img.createHeroHeadByHid(hids[i])
                showHero:setScale(0.88)
                showHero:setPosition(heroBg[i]:getContentSize().width/2, heroBg[i]:getContentSize().height/2)
                heroBg[i]:addChild(showHero)
            
                local blackBoard = img.createUISprite(img.ui.hero_head_shade)
                blackBoard:setScale(80/94)
                blackBoard:setOpacity(120)
                blackBoard:setPosition(headIcons[pos]:getPositionX(), headIcons[pos]:getPositionY())
                blackBatch:addChild(blackBoard, 0, pos)
                
                local selectIcon = img.createUISprite(img.ui.hook_btn_sel)
                selectIcon:setPosition(headIcons[pos]:getPositionX(), headIcons[pos]:getPositionY())
                selectBatch:addChild(selectIcon, 0, pos)
                return
            end
        end
    end

    local function onUnselect(pos)
        if hids[pos] then
            for i, v in ipairs(herolist) do
                if v.hid == hids[pos] then
                    v.isUsed = false
                    blackBatch:removeChildByTag(i)
                    selectBatch:removeChildByTag(i)
                end
            end
            hids[pos] = nil
            heroBg[pos]:removeAllChildrenWithCleanup(true)
        end
    end

    local lastx
    local function onTouchBegin(x, y)
        lastx = x
        
        return true 
    end

    local function onTouchMoved(x, y)
        return true
    end

    local function onTouchEnd(x, y)
        if math.abs(x - lastx) > 10 then 
            return
        end

        local pointOnScroll = scroll:getContainer():convertToNodeSpace(ccp(x, y))
        local point = board:convertToNodeSpace(ccp(x, y))

        for i, v in ipairs(headIcons) do
            if v:boundingBox():containsPoint(pointOnScroll) then
                onSelect(i)            
            end
        end

        for i, v in ipairs(heroBg) do
            if v:boundingBox():containsPoint(point) then
                onUnselect(i)
            end
        end
        return true
    end

    local function onTouch(eventType, x, y)
        if eventType == "began" then
            return onTouchBegin(x, y)        
        elseif eventType == "moved" then
            return onTouchMoved(x, y)
        else
            return onTouchEnd(x, y)
        end
    end

    layer:registerScriptTouchHandler(onTouch)
    layer:setTouchEnabled(true)

    return layer
end

return ui
