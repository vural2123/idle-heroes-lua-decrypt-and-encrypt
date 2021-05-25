local ui = {}

require "common.func"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local i18n = require "res.i18n"
local audio = require "res.audio"
local net = require "net.netClient"
local cfghero = require "config.hero"
local cfgequip = require "config.equip"
local heros = require "data.heros"
local bag = require "data.bag"
local player = require "data.player"
local cfgDaily = require "config.dailyrewards"
local cfgSeasons = require "config.endrewards"
local arenaData = require "data.arena"
local frdarena = require "data.frdarena"

local superlayer 

local function createSeasonRewards()
    local layer = CCLayer:create()

    local height = 0 
    local scroll = CCScrollView:create()
    scroll:setDirection(kCCScrollViewDirectionVertical)
    scroll:setAnchorPoint(ccp(0, 0))
    scroll:setPosition(0, 1)
    scroll:setViewSize(CCSize(682, 405))
    scroll:setContentSize(CCSize(682, 0))
    layer:addChild(scroll)

    local showItems = {}
    local cfgSeason = {}
    for i=1, #cfgSeasons do
        if cfgSeasons[i].arenaId == 4 then
            cfgSeason[#cfgSeason + 1] = cfgSeasons[i]
        end
    end

    for i=1, #cfgSeason do
        local idx = #cfgSeason - i + 1

        local taskBg = img.createUI9Sprite(img.ui.botton_fram_2)
        taskBg:setPreferredSize(CCSize(650, 80))
        taskBg:setAnchorPoint(ccp(0.5, 0))
        taskBg:setPosition(341, i * 82 - 80)
        scroll:getContainer():addChild(taskBg)

        local showRank
        if cfgSeason[idx].rank <= 3 then
            showRank = img.createUISprite(img.ui["arena_rank_" .. cfgSeason[idx].rank]) 
        else
            if cfgSeason[idx].rank == cfgSeason[idx - 1].rank + 1 then
                showRank = lbl.createMixFont1(20, cfgSeason[idx].rank, ccc3(0x82, 0x5a, 0x3d))
            else
                showRank = lbl.createMixFont1(16, (cfgSeason[idx-1].rank + 1) .. "-" .. cfgSeason[idx].rank , ccc3(0x82, 0x5a, 0x3d))
            end
        end
        showRank:setPosition(58, 40)
        taskBg:addChild(showRank)

        for j, v in ipairs(cfgSeason[idx].rewards) do
            local showItem
            if v.type == 1 then
                showItem = img.createItem(v.id, v.num)
            else
                showItem = img.createEquip(v.id)
            end
            showItem:setScale(0.7)
            showItem:setAnchorPoint(ccp(0, 0))
            showItem:setPosition(132 + 64 * (j-1), taskBg:getPositionY() + 12)
            scroll:getContainer():addChild(showItem)
            showItems[#showItems + 1] = showItem
            showItems[#showItems].Info = v
        end

        height = taskBg:boundingBox():getMaxY()
    end

    local showText = lbl.createMix({
        font = 1, size = 14, text = i18n.global.arena_reward_season_info.string,
        color = ccc3(0x5d, 0x2d, 0x12), width = 682, align = kCCTextAlignmentLeft,
    })
    showText:setAnchorPoint(ccp(0, 0))
    showText:setPosition(17, height + 4)
    scroll:getContainer():addChild(showText)

    local rankIdx
    local str
    if frdarena.team == nil then
        str = string.format(i18n.global.frdpvp_norank.string)
    else
        if frdarena.team.rank then
            rankIdx = 1
            for i, v in ipairs(cfgSeason) do
                if frdarena.team.rank and frdarena.team.rank > v.rank and i <= 11 then
                    rankIdx = i + 1
                end
            end
            if rankIdx == 1 or cfgSeason[rankIdx].rank == cfgSeason[rankIdx-1].rank + 1 then
                str = string.format(i18n.global.arena_reward_end_rank1.string, cfgSeason[rankIdx].rank)
            else
                str = string.format(i18n.global.arena_reward_end_rank2.string, cfgSeason[rankIdx-1].rank, cfgSeason[rankIdx].rank)
            end
        else
            rankIdx = #cfgSeason
            str = string.format(i18n.global.frdpvp_norank.string)
        end
        --for i, v in ipairs(cfgSeason) do
        --    if frdarena.team.rank and frdarena.team.rank > v.rank and i <= 11 then
        --        rankIdx = i + 1
        --    end
        --end
        --if rankIdx == 1 or cfgSeason[rankIdx].rank == cfgSeason[rankIdx-1].rank + 1 then
        --    str = string.format(i18n.global.arena_reward_end_rank1.string, cfgSeason[rankIdx].rank)
        --else
        --    str = string.format(i18n.global.arena_reward_end_rank2.string, cfgSeason[rankIdx-1].rank, cfgSeason[rankIdx].rank)
        --end
    end
    local showRank = lbl.createMixFont2(14, str)
    showRank:setAnchorPoint(ccp(0, 0))
    showRank:setPosition(17, showText:boundingBox():getMaxY() + 2)
    scroll:getContainer():addChild(showRank)    

    scroll:setContentSize(CCSize(682, showRank:boundingBox():getMaxY() + 10))
    scroll:setContentOffset(ccp(0, 405 -  scroll:getContentSize().height))    

    local lasty
    local function onTouchBegin(x, y)
        lasty = y
        return true 
    end

    local function onTouchMoved(x, y)
        return true
    end

    local function onTouchEnd(x, y)
        local pointOnBoard = layer:convertToNodeSpace(ccp(x, y))
        if math.abs(y - lasty) > 10 or not scroll:boundingBox():containsPoint(pointOnBoard) then
            return true
        end

        local point = scroll:getContainer():convertToNodeSpace(ccp(x, y))
        for i, v in ipairs(showItems) do
            if v:boundingBox():containsPoint(point) then
                local tips 
                if v.Info.type == 1 then
                    tips = require("ui.tips.item").createForShow(v.Info)
                else
                    tips = require("ui.tips.equip").createById(v.Info.id)
                end
                superlayer:addChild(tips)
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

function ui.create()
    local layer = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    superlayer = layer
 
    local board = img.createLogin9Sprite(img.login.dialog)
    board:setPreferredSize(CCSize(726, 510))
    board:setScale(view.minScale)
    board:setPosition(view.midX, view.midY)
    layer:addChild(board)

    local showTitle = lbl.createFont1(26, i18n.global.arena_reward_title.string, ccc3(0xe6, 0xd0, 0xae))
    showTitle:setPosition(board:getContentSize().width/2, 481)
    board:addChild(showTitle, 1)
    
    local showTitleShade = lbl.createFont1(26, i18n.global.arena_reward_title.string, ccc3(0x59, 0x30, 0x1b))
    showTitleShade:setPosition(board:getContentSize().width/2, 479)
    board:addChild(showTitleShade)
 
    local showRewardBg = img.createUI9Sprite(img.ui.inner_bg)
    showRewardBg:setPreferredSize(CCSize(682, 412))
    showRewardBg:setAnchorPoint(ccp(0, 0))
    showRewardBg:setPosition(22, 27)
    board:addChild(showRewardBg)

    showRewardBg:addChild(createSeasonRewards(), 1, 1)
 
    local btnCloseSprite = img.createUISprite(img.ui.close)
    local btnClose = SpineMenuItem:create(json.ui.button, btnCloseSprite)
    btnClose:setPosition(702, 483)
    local menuClose = CCMenu:createWithItem(btnClose)
    menuClose:setPosition(0, 0)
    board:addChild(menuClose)
    btnClose:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer:removeFromParentAndCleanup(true)
    end)

    addBackEvent(layer)
    function layer.onAndroidBack()
        layer:removeFromParentAndCleanup(true)
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
