local tips = {}

require "common.func"
require "common.const"
local view = require "common.view"
local player = require "data.player"
local net = require "net.netClient"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local audio = require "res.audio"
local i18n = require "res.i18n"
local cfghero = require "config.hero"

local TIPS_WIDTH = 360
local TIPS_HEIGHT = 146

function tips.createFilterBoard(starType, groupType, callfunc, starfunc, groupfunc)
    local filterLayer = CCLayer:create()
    
    local filterBoard = img.createUI9Sprite(img.ui.tips_bg)
    filterBoard:setPreferredSize(CCSize(TIPS_WIDTH, TIPS_HEIGHT))
    filterBoard:setScale(view.minScale)
    filterBoard:setPosition(scalep(696.5, 166))
    filterLayer:addChild(filterBoard)
    filterLayer.board = filterBoard

    local btnStar = {}
    for i=1, 5 do
        local btnStarSp = img.createUISprite(img.ui.devour_circle_bg)
        local starIcon = img.createUISprite(img.ui.star)
        starIcon:setPosition(btnStarSp:getContentSize().width/2, btnStarSp:getContentSize().height/2 + 2)
        starIcon:setScale(0.7)
        btnStarSp:addChild(starIcon)
        local showStar = lbl.createFont2(16, i)
        showStar:setPosition(btnStarSp:getContentSize().width/2, btnStarSp:getContentSize().height/2 + 2)
        btnStarSp:addChild(showStar)

        btnStar[i] = CCMenuItemSprite:create(btnStarSp, nil)
        local menuStar = CCMenu:createWithItem(btnStar[i])
        menuStar:setPosition(0, 0)
        filterBoard:addChild(menuStar)
        btnStar[i]:setPosition(76 + 54 * (i-1), 44)
        
        btnStar[i].sel = img.createUISprite(img.ui.bag_dianji)
        btnStar[i].sel:setPosition(btnStar[i]:getContentSize().width/2, btnStar[i]:getContentSize().height/2 + 2)
        btnStar[i]:addChild(btnStar[i].sel)
        if starType ~= i then
            btnStar[i].sel:setVisible(false)
        end
        btnStar[i]:registerScriptTapHandler(function()
            if starType == i then
                starType = 0
                starfunc(0)
                btnStar[i].sel:setVisible(false)
            else
                starType = i
                starfunc(i)
                for j=1, 5 do
                    btnStar[j].sel:setVisible(false)
                end
                btnStar[i].sel:setVisible(true)
            end
            callfunc()
        end)
    end

    local btnGroup = {}
    for i=1, 6 do
        local btnGroupSp = img.createUISprite(img.ui.devour_circle_bg)
        local groupIcon = img.createUISprite(img.ui["herolist_group_" .. i])
        groupIcon:setPosition(btnGroupSp:getContentSize().width/2, btnGroupSp:getContentSize().height/2 + 2)
        groupIcon:setScale(0.7)
        btnGroupSp:addChild(groupIcon)
        --local showStar = lbl.createFont2(16, i)
        --showStar:setPosition(btnStarSp:getContentSize().width/2, btnStarSp:getContentSize().height/2 + 2)
        --btnStarSp:addChild(showStar)

        btnGroup[i] = CCMenuItemSprite:create(btnGroupSp, nil)
        local menuGroup = CCMenu:createWithItem(btnGroup[i])
        menuGroup:setPosition(0, 0)
        filterBoard:addChild(menuGroup)
        btnGroup[i]:setPosition(46 + 54 * (i-1), 98)
        
        btnGroup[i].sel = img.createUISprite(img.ui.bag_dianji)
        btnGroup[i].sel:setPosition(btnGroup[i]:getContentSize().width/2, btnGroup[i]:getContentSize().height/2 + 2)
        btnGroup[i]:addChild(btnGroup[i].sel)
        if groupType ~= i then
            btnGroup[i].sel:setVisible(false)
        end
        btnGroup[i]:registerScriptTapHandler(function()
            if groupType == i then
                groupType = 0
                groupfunc(0)
                btnGroup[i].sel:setVisible(false)
            else
                groupType = i
                groupfunc(i)
                for j=1, 6 do
                    btnGroup[j].sel:setVisible(false)
                end
                btnGroup[i].sel:setVisible(true)
            end
            callfunc()
        end)
        
    end
    

    -- for touch
    local touchbeginx, touchbeginy
    local isclick

    local function onTouchBegan(x, y)
        touchbeginx, touchbeginy = x, y
        isclick = true
        return true
    end

    local function onTouchMoved(x, y)
        if isclick and (math.abs(touchbeginx-x) > 10 or math.abs(touchbeginy-y) > 10) then
            isclick = false
        end
    end

    local function onTouchEnded(x, y)
        --if not outside_remove then
        --    return
        --end
        print("toucheend")
        if isclick and not filterBoard:boundingBox():containsPoint(ccp(x, y)) then
            --if clickBlankHandler then
            --    clickBlankHandler()
            --else
                filterLayer:removeFromParentAndCleanup(true)
            --end
        end
    end

    local function onTouch(eventType, x, y)
        if eventType == "began" then   
            return onTouchBegan(x, y)
        elseif eventType == "moved" then
            return onTouchMoved(x, y)
        else
            return onTouchEnded(x, y)
        end
    end

    filterLayer:registerScriptTouchHandler(onTouch, false , -128 , false)
    filterLayer:setTouchEnabled(true)

    addBackEvent(filterLayer)
    function filterLayer.onAndroidBack()
        filterLayer:removeFromParentAndCleanup(true)
    end

    local function onEnter()
        filterLayer.notifyParentLock()
    end

    local function onExit()
        filterLayer.notifyParentUnlock()
    end

    filterLayer:registerScriptHandler(function(event)
        if event == "enter" then
            onEnter()
        elseif event == "exit" then
            onExit()
        end
    end)

    return filterLayer
end

return tips
