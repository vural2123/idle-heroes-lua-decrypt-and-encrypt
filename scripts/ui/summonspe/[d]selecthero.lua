local ui = {}

require "common.func"

local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local audio = require "res.audio"
local i18n = require "res.i18n"
local heros = require "data.heros"
local cfghero = require "config.hero"

function ui.create(callBack)
    --local layer = CCLayerColor:create(ccc4(0,0,0,POPUP_DARK_OPACITY))
    local layer = CCLayer:create()

    local headIcons = {}
    local herolist = {}

    local group = 0
    local function initHerolistData()
        herolist = {}
        local tmpheros = clone(heros)
        for i, v in ipairs(tmpheros) do
            if cfghero[v.id].qlt > 3 and cfghero[v.id].qlt < 6 and 
                cfghero[v.id].group < 5 and (group == 0 or cfghero[v.id].group == group) then
                herolist[#herolist + 1] = {
                    hid = v.hid,
                    id = v.id,
                    lv = v.lv,
                    star = v.star,
                    flag = v.flag,
                }
            end
        end
        table.sort(herolist, compareHero)
        --herolist = herolistless(herolist)
    end
    initHerolistData()

    local herolistBg = img.createUI9Sprite(img.ui.tips_bg)
    herolistBg:setPreferredSize(CCSize(958, 112))
    herolistBg:setScale(view.minScale)
    herolistBg:setAnchorPoint(ccp(0.5, 1))
    herolistBg:setPosition(view.midX, view.minY - 0 * view.minScale)
    layer:addChild(herolistBg)

    local SCROLLVIEW_WIDTH = 943 - 150
    local SCROLLVIEW_HEIGHT = 112
    local SCROLLCONTENT_WIDTH = #herolist * 90 + 8

    local scroll = CCScrollView:create()
    scroll:setDirection(kCCScrollViewDirectionHorizontal)
    scroll:setAnchorPoint(ccp(0, 0))
    scroll:setPosition(7, 0)
    scroll:setViewSize(CCSize(SCROLLVIEW_WIDTH, SCROLLVIEW_HEIGHT))
    scroll:setContentSize(CCSizeMake(SCROLLCONTENT_WIDTH, SCROLLVIEW_HEIGHT))
    herolistBg:addChild(scroll)

    local btnFilterSprite = img.createLogin9Sprite(img.login.button_9_small_gold)
    btnFilterSprite:setPreferredSize(CCSize(130, 70))
    local btnFilterIcon = lbl.createFont1(20, i18n.global.selecthero_btn_hero.string, ccc3(0x73, 0x3b, 0x05)) 
    btnFilterIcon:setPosition(btnFilterSprite:getContentSize().width/2, btnFilterSprite:getContentSize().height/2)
    btnFilterSprite:addChild(btnFilterIcon)

    local btnFilter = SpineMenuItem:create(json.ui.button, btnFilterSprite)
    btnFilter:setPosition(873, 56)
    local menuFilter = CCMenu:createWithItem(btnFilter)
    menuFilter:setPosition(0, 0)
    herolistBg:addChild(menuFilter, 1)
    
    local filterBg = img.createUI9Sprite(img.ui.tips_bg)
    filterBg:setPreferredSize(CCSize(122, 325))
    filterBg:setScale(view.minScale)
    filterBg:setAnchorPoint(ccp(1, 0))
    filterBg:setPosition(scalep(938, 110))
    layer:addChild(filterBg)

    local showHeroLayer = CCLayer:create()
    scroll:getContainer():addChild(showHeroLayer)

    local selectBatch
    local blackBatch
    local function createHerolist()
        showHeroLayer:removeAllChildrenWithCleanup(true)
        arrayclear(headIcons)

        scroll:setContentSize(CCSizeMake(#herolist * 90 + 8, SCROLLVIEW_HEIGHT))
        scroll:setContentOffset(ccp(0, 0))
        local iconBgBatch = img.createBatchNodeForUI(img.ui.herolist_head_bg)
        showHeroLayer:addChild(iconBgBatch, 1)
        local groupBgBatch = img.createBatchNodeForUI(img.ui.herolist_group_bg)
        showHeroLayer:addChild(groupBgBatch , 3)
        local starBatch = img.createBatchNodeForUI(img.ui.star_s)
        showHeroLayer:addChild(starBatch, 3)
        local star1Batch = img.createBatchNodeForUI(img.ui.hero_star_orange)
        showHeroLayer:addChild(star1Batch, 3)
        blackBatch = CCNode:create()
        showHeroLayer:addChild(blackBatch, 4)
        selectBatch = img.createBatchNodeForUI(img.ui.hook_btn_sel)
        showHeroLayer:addChild(selectBatch, 5)
        local lockBatch = img.createBatchNodeForUI(img.ui.devour_icon_lock)
        showHeroLayer:addChild(lockBatch, 6)

        for i=1, #herolist do
            local x, y = 45 + (i-1) * 90 + 8, 56 
       
            local heroBg = img.createUISprite(img.ui.herolist_head_bg)
            heroBg:setScale(0.92)
            heroBg:setPosition(x, y)
            iconBgBatch:addChild(heroBg)

            headIcons[i] = img.createHeroHeadByHid(herolist[i].hid)
            headIcons[i]:setScale(0.92)
            headIcons[i]:setPosition(x, y)
            showHeroLayer:addChild(headIcons[i], 2)

            --local groupBg = img.createUISprite(img.ui.herolist_group_bg)
            --groupBg:setScale(0.42 * 0.92)
            --groupBg:setPosition(x - 26, y + 26)
            --groupBgBatch:addChild(groupBg)

            --local groupIcon = img.createUISprite(img.ui["herolist_group_" .. cfghero[herolist[i].id].group])
            --groupIcon:setScale(0.42 * 0.92)
            --groupIcon:setPosition(x - 26, y + 26)
            --showHeroLayer:addChild(groupIcon, 3)

            --local showLv = lbl.createFont2(15 * 0.92, herolist[i].lv)
            --showLv:setPosition(x + 23, y + 26)
            --showHeroLayer:addChild(showLv, 3)

            --local qlt = cfghero[herolist[i].id].qlt
            --for i = qlt, 1, -1 do
            --    local star = img.createUISprite(img.ui.star_s)
            --    star:setScale(0.92)
            --    star:setPosition(x + (i-(qlt+1)/2)*12*0.8, y - 30)
            --    starBatch:addChild(star)
            --end

            if herolist[i].flag and herolist[i].flag > 0 then
                local count = 0
                local text = ""
                if herolist[i].flag % 2 == 1 then
                    text = text..i18n.global.toast_devour_arena.string
                    count = count + 1
                end
                if math.floor((herolist[i].flag / 2)) % 2 == 1 then
                    if count >= 1 then
                        text = text.."\n"
                    end
                    text = text..i18n.global.toast_devour_lock.string
                    count = count + 1
                end
                if math.floor((herolist[i].flag / 4)) % 2 == 1 then
                    if count >= 1 then
                        text = text.."\n"
                    end
                    text = text..i18n.global.toast_devour_3v3arena.string
                    count = count + 1
                end
                if math.floor((herolist[i].flag / 8)) % 2 == 1 then
                    if count >= 1 then
                        text = text.."\n"
                    end
                    text = text..i18n.global.toast_devour_frdarena.string
                    count = count + 1
                end
                herolist[i].lock = text
                
                local blackBoard = img.createUISprite(img.ui.hero_head_shade)
                blackBoard:setScale(76/94)
                blackBoard:setOpacity(120)
                blackBoard:setPosition(headIcons[i]:getPositionX(), headIcons[i]:getPositionY())
                blackBatch:addChild(blackBoard, 0, i)
               
                local showLock = img.createUISprite(img.ui.devour_icon_lock)
                showLock:setPosition(headIcons[i]:getPositionX(), headIcons[i]:getPositionY())
                lockBatch:addChild(showLock, 0, i)
            end
        end
    end
    createHerolist()

    local anim_duration = 0.2
    herolistBg:runAction(CCMoveTo:create(anim_duration, CCPoint(view.midX, view.minY+110*view.minScale)))

    local btnGroupList = {}
    for i=1, 4 do
        local btnGroupSpriteFg = img.createUISprite(img.ui["herolist_group_" .. i])
        local btnGroupSpriteBg = img.createUISprite(img.ui.herolist_group_bg)
        btnGroupSpriteFg:setPosition(btnGroupSpriteBg:getContentSize().width/2, btnGroupSpriteBg:getContentSize().height/2 + 2)
        btnGroupSpriteBg:addChild(btnGroupSpriteFg)
        btnGroupList[i] = HHMenuItem:createWithScale(btnGroupSpriteBg, 1)
        local btnGroupMenu = CCMenu:createWithItem(btnGroupList[i])
        btnGroupMenu:setPosition(0, 0)
        filterBg:addChild(btnGroupMenu, 10)
        btnGroupList[i]:setPosition(61, 52 + 70 * (i - 1))
        
        local showSelect = img.createUISprite(img.ui.herolist_select_icon)
        showSelect:setPosition(btnGroupList[i]:getContentSize().width/2, btnGroupList[i]:getContentSize().height/2 + 2)
        btnGroupList[i]:addChild(showSelect)
        btnGroupList[i].showSelect = showSelect
        showSelect:setVisible(false)

        btnGroupList[i]:registerScriptTapHandler(function()
            audio.play(audio.button)
            for j=1, 4 do
                btnGroupList[j]:unselected()
                btnGroupList[j].showSelect:setVisible(false)
            end
            if group == 0 or i ~= group then
                group = i
                btnGroupList[i]:selected()
                btnGroupList[i].showSelect:setVisible(true)
            else
                group = 0
            end

            initHerolistData()
            createHerolist()

            --for ii,v in ipairs(herolist) do
            --    for j=1, 6 do
            --        if v.hid == hids[j] then
                        --onMoveUp(ii, j, true)
                        --herolist[ii].isUsed = true
            --        end
            --    end
            --end
        end)
    end

    filterBg:setVisible(false)
    btnFilter:registerScriptTapHandler(function()
        if filterBg:isVisible() == true then
            filterBg:setVisible(false)
        else
            filterBg:setVisible(true)
        end
    end)

    local lastx
    local preSelect
    local function onTouchBegin(x, y)
        lastx = x
        return true 
    end

    local function onTouchMoved(x, y)
        return true
    end

    local function onTouchEnd(x, y)
        local pointOnScroll = scroll:getContainer():convertToNodeSpace(ccp(x, y))

        if math.abs(x - lastx) < 10 then
            for i,v in ipairs(headIcons) do
                if v:boundingBox():containsPoint(pointOnScroll) then
                    audio.play(audio.button)
                    if herolist[i].lock then
                        showToast(herolist[i].lock)
                        return
                    end
                    tbl2string(herolist)
                    callBack(herolist[i])
                    --layer:getParent():addChild(require("ui.hero.main").create(herolist[i].hid, group), 10000)
                    layer:removeFromParentAndCleanup()
                end
            end
        end
        return true
    end

    -- 点击空白区域的回调
    local clickBlankHandler
    function layer.setClickBlankHandler(handler)
        clickBlankHandler = handler
    end

    local function onTouch(eventType, x, y)
        if eventType == "began" then
            return onTouchBegin(x, y)        
        elseif eventType == "moved" then
            return onTouchMoved(x, y)
        else
            if not herolistBg:boundingBox():containsPoint(ccp(x, y))
                and not filterBg:boundingBox():containsPoint(ccp(x, y)) then
                layer.onAndroidBack()
            else
                return onTouchEnd(x, y)        
            end
        end
    end

    layer:registerScriptTouchHandler(onTouch)
    layer:setTouchEnabled(true)
    layer:setTouchSwallowEnabled(true)

    local function backEvent()
        audio.play(audio.button)
        layer:removeFromParentAndCleanup()
    end

    function layer.onAndroidBack()
        if clickBlankHandler then
            clickBlankHandler()
        else
            backEvent()
        end
    end

    addBackEvent(layer) 
    
    local function onEnter()
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

    return layer
end

return ui
