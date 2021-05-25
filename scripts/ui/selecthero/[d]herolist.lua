local herolist = {}

require "common.func"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local i18n = require "res.i18n"
local audio = require "res.audio"
local net = require "net.netClient"
local cfghero = require "config.hero"
local Dataheros = require "data.heros"
local bag = require "data.bag"
local player = require "data.player"

local condition = {}
local hids = {}
herolist.hids = hids
-- 根据需求获取英雄列表
--创建英雄列表面板的参数
--{
--    hids 已经选择的英雄
--    heroNum 数量
--    groups = {} 可选阵营
--    handler(hids) hids即为选择后确定的英雄列表
--}
local function initConditon(params)
    condition.heroNum = params.heroNum or 6
    condition.groups = params.groups 
end

local function getHeroListData(params)
    local heros = clone(Dataheros)
    local herolist = {}
    for _, v in ipairs(heros) do
        herolist[#herolist + 1] = {
            hid = v.hid,
            id = v.id,
            lv = v.lv,
            star = 3,
            isUsed = false,
        }

        for j, hid in ipairs(hids) do
            if hid == herolist[#herolist].hid then
                herolist[#herolist].isUsed = true
            end
        end
    end
    
    if condition.groups then
        groups = condition.groups
        local h = {}
        for _, v in ipairs(herolist) do
            if v.isUsed == false then
                for j, group in ipairs(groups) do
                    if cfghero[v.id].group == group then
                        h[#h + 1] = v
                    end
                end
            else
                h[#h + 1] = v
            end
        end
        herolist = h
    end

    local tlist = herolistless(herolist)
    return tlist
end

-- 排序下拉菜单
local function createDownList()
    local layer = CCLayer:create()
    
    local btnLevelSprite = img.createUISprite(img.ui.herolist_pulldown) 
    btnLevelSprite:setFlipY(true)
    local btnLevel = HHMenuItem:createWithScale(btnLevelSprite, 1)
    local btnLevelLab = lbl.createFont1(18, "Level", ccc3(0x70, 0x36, 0x19))
    btnLevelLab:setPosition(btnLevel:getContentSize().width/2 , btnLevel:getContentSize().height/2)
    btnLevel:addChild(btnLevelLab)
    local btnLevelMenu = CCMenu:createWithItem(btnLevel)
    btnLevel:setAnchorPoint(ccp(0, 0))
    btnLevel:setPosition(637, 377)
    btnLevelMenu:setPosition(0, 0)
    layer:addChild(btnLevelMenu)
    btnLevel:registerScriptTapHandler(function()
        sortType = "Level" 
        getDataAndCreateList()
        layer:removeFromParentAndCleanup(true)
    end)

    local btnBattleSprite = img.createUISprite(img.ui.herolist_pulldown) 
    local btnBattle = HHMenuItem:createWithScale(btnBattleSprite, 1)
    local btnBattleLab = lbl.createFont1(18, "Battle", ccc3(0x70, 0x36, 0x19))
    btnBattleLab:setPosition(btnBattle:getContentSize().width/2 , btnBattle:getContentSize().height/2)
    btnBattle:addChild(btnBattleLab)
    local btnBattleMenu = CCMenu:createWithItem(btnBattle)
    btnBattle:setAnchorPoint(ccp(0, 1))
    btnBattle:setPosition(637, 378)
    btnBattleMenu:setPosition(0, 0)
    layer:addChild(btnBattleMenu)
    btnBattle:registerScriptTapHandler(function()
        sortType = "Battle"
        layer:removeFromParentAndCleanup(true)
    end)

    layer:registerScriptTouchHandler(function() 
        layer:removeFromParentAndCleanup(true)
        return true 
    end)
    layer:setTouchEnabled(true)

    return layer
end

local function createHeroList(herolist)
    local layer = CCLayer:create()

    local SCROLLVIEW_WIDTH = 710
    local SCROLLVIEW_HEIGHT = 331
    local SCROLLCONTENT_HEIGHT = 23 + 101 * math.ceil(#herolist/7)
    
    local scroll = CCScrollView:create()
    scroll:setDirection(kCCScrollViewDirectionVertical)
    scroll:setAnchorPoint(ccp(0, 0))
    scroll:setPosition(66, 109)
    scroll:setViewSize(CCSize(SCROLLVIEW_WIDTH, SCROLLVIEW_HEIGHT))
    scroll:setContentSize(CCSize(SCROLLVIEW_WIDTH, SCROLLCONTENT_HEIGHT))
    scroll:setContentOffset(ccp(0, SCROLLVIEW_HEIGHT - SCROLLCONTENT_HEIGHT))
    layer:addChild(scroll)

    local iconBgBatch = img.createBatchNodeForUI(img.ui.herolist_head_bg)
    scroll:getContainer():addChild(iconBgBatch, 1)
    local groupBgBatch = img.createBatchNodeForUI(img.ui.herolist_group_bg)
    scroll:getContainer():addChild(groupBgBatch , 3)
    local starBatch = img.createBatchNodeForUI(img.ui.herolist_star)
    scroll:getContainer():addChild(starBatch, 3)
    local blackBatch = CCNode:create()
    scroll:getContainer():addChild(blackBatch, 4)
    local selectBatch = img.createBatchNodeForUI(img.ui.hook_btn_sel)
    scroll:getContainer():addChild(selectBatch, 5)

    local headIcons = {}
    local function selected(pos)
        local isFind
        for i, v in ipairs(hids) do
            if v == herolist[pos].hid then
                isFind = true
            end
        end
        if #hids >= condition.heroNum then
            return
        end
        if not isFind then
            herolist[pos].isUsed = true
            hids[#hids + 1] = herolist[pos].hid
        end

        local blackBoard = CCLayerColor:create(ccc4(0, 0, 0, 120))
        blackBoard:setContentSize(CCSize(92, 92))
        blackBoard:setPosition(headIcons[pos]:getPositionX() - 46, headIcons[pos]:getPositionY() - 46)
        blackBatch:addChild(blackBoard, 0, pos)

        local selectIcon = img.createUISprite(img.ui.hook_btn_sel)
        selectIcon:setPosition(headIcons[pos]:getPositionX(), headIcons[pos]:getPositionY())
        selectBatch:addChild(selectIcon, 0, pos)
        --tbl2string(hids)
    end

    local function unselected(pos)
        herolist[pos].isUsed = false
        blackBatch:removeChildByTag(pos)
        selectBatch:removeChildByTag(pos)

        local h = {}
        for i, v in ipairs(hids) do
            if v ~= herolist[pos].hid then
                h[#h + 1] = v
            end
        end
        hids = h
        --tbl2string(hids)
    end

    for i, v in ipairs(herolist) do
        local y, x = SCROLLCONTENT_HEIGHT - math.ceil( i / 7 ) * 101 + 40, ( i - math.ceil( i / 7 ) * 7 + 7 ) * 101 - 51
        local headBg = img.createUISprite(img.ui.herolist_head_bg)
        headBg:setPosition(x, y)
        iconBgBatch:addChild(headBg)
       
        headIcons[i] = img.createHeroHeadIcon(herolist[i].id)
        headIcons[i]:setPosition(x, y)
        scroll:getContainer():addChild(headIcons[i], 2)

        local groupBg = img.createUISprite(img.ui.herolist_group_bg)
        groupBg:setScale(0.42)
        groupBg:setPosition(x - 30, y + 30)
        groupBgBatch:addChild(groupBg)

        local groupIcon = img.createUISprite(img.ui["herolist_group_" .. cfghero[herolist[i].id].group])
        groupIcon:setScale(0.42)
        groupIcon:setPosition(x - 30, y + 30)
        scroll:getContainer():addChild(groupIcon, 3)

        local showLv = lbl.createFont2(16, herolist[i].lv)
        showLv:setPosition(x + 26, y + 30)
        scroll:getContainer():addChild(showLv, 3)

        local quality = herolist[i].star
        local offset = x + 10 * quality / 2
        for j = 1, quality do
            local star = img.createUISprite(img.ui.herolist_star)
            star:setScale(0.35)
            star:setPosition(offset - j * 10 + 5, y - 34)
            starBatch:addChild(star)
        end

        if v.isUsed == true then
            selected(i)
        end
    end

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
        for i, v in ipairs(headIcons) do
            if v:boundingBox():containsPoint(point) then
                if herolist[i].isUsed == false then
                    selected(i)
                else
                    unselected(i)
                end
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

function herolist.create(params)
    local layer = CCLayer:create()

    local params = params or {}
   
    initConditon(params)
    hids = params.hids or {}
    --print("1111111111111111")
    --tbl2string(params.hids or {})
    --print("222222222222222")
    --tbl2string(hids)

    local bg = img.createUISprite(img.ui.bag_bg)
    bg:setScale(view.minScale)
    bg:setPosition(view.midX, view.midY)
    layer:addChild(bg)

    -- backBtn
    local btnBackSprite = img.createUISprite(img.ui.back)
    local btnBack = HHMenuItem:create(btnBackSprite)
    btnBack:setScale(view.minScale)
    btnBack:setPosition(scalep(35, 546))
    local menuBack = CCMenu:createWithItem(btnBack)
    menuBack:setPosition(0, 0)
    layer:addChild(menuBack, 1000)
    layer.back = btnBack
    btnBack:registerScriptTapHandler(function()
        layer:removeFromParentAndCleanup(true)
    end)

    local title = lbl.createFont3(30, "HERO ENCYCLOPEDIA", ccc3(0xfa, 0xd8, 0x69))
    title:setScale(view.minScale)
    title:setPosition(scalep(480, 545))
    layer:addChild(title, 100)
    
    local board = img.createUISprite(img.ui.herolist_bg)
    board:setScale(view.minScale)
    board:setPosition(view.midX - 15, view.midY - 20)
    layer:addChild(board)

    local heroNumLab = lbl.createFont1(20, "41/100", ccc3(0x70, 0x36, 0x19))
    heroNumLab:setPosition(110, 472)
    board:addChild(heroNumLab)
 
    local herolist = getHeroListData()
    local showHeroLayer = CCLayer:create()
    board:addChild(showHeroLayer)
    showHeroLayer:addChild(createHeroList(herolist), 1000)

    local group
    local btnGroupList = {}
    for i=1, 6 do
        local btnGroupSpriteFg = img.createUISprite(img.ui["herolist_group_" .. i])
        local btnGroupSpriteBg = img.createUISprite(img.ui.herolist_group_bg)
        btnGroupSpriteFg:setPosition(btnGroupSpriteBg:getContentSize().width/2, btnGroupSpriteBg:getContentSize().height/2 + 2)
        btnGroupSpriteBg:addChild(btnGroupSpriteFg)
        btnGroupList[i] = HHMenuItem:createWithScale(btnGroupSpriteBg, 1)
        local btnGroupMenu = CCMenu:createWithItem(btnGroupList[i])
        btnGroupMenu:setPosition(0, 0)
        board:addChild(btnGroupMenu, 10)
        btnGroupList[i]:setPosition(183 + 66 * i, 460)
        btnGroupList[i]:registerScriptTapHandler(function()
            for j=1, 6 do
                btnGroupList[j]:unselected()
            end

            showHeroLayer:removeAllChildrenWithCleanup(true)
            if not group or group ~= i then
                group = i
                btnGroupList[i]:selected()
                local tempParams = clone(params) 
                tempParams.groups = { [1] = i }
                initConditon(tempParams)
                showHeroLayer:addChild(createHeroList(getHeroListData()))
            else
                group = nil
                initConditon(params)
                showHeroLayer:addChild(createHeroList(getHeroListData()))
            end
        end)
    end

    local btnSortSprite = img.createUISprite(img.ui.herolist_button_pulldown)
    local btnSortIcon = img.createUISprite(img.ui.herolist_triangle)
    btnSortIcon:setPosition(78, 18)
    btnSortSprite:addChild(btnSortIcon)
    local btnSort = HHMenuItem:createWithScale(btnSortSprite, 1)
    local btnSortLab = lbl.createFont1(20, "Sort", ccc3(0x70, 0x36, 0x19))
    btnSortLab:setPosition(btnSort:getContentSize().width/2 - 12, btnSort:getContentSize().height/2)
    btnSort:addChild(btnSortLab)
    local btnSortMenu = CCMenu:createWithItem(btnSort)
    btnSortMenu:setPosition(0, 0)
    board:addChild(btnSortMenu, 10)
    btnSort:setPosition(715, 472)
    btnSort:registerScriptTapHandler(function()

    end)

    local btnBattleSprite = img.createLogin9Sprite(img.login.button_9_gold)
    btnBattleSprite:setPreferredSize(CCSize(173, 66))
    local btnBattle = HHMenuItem:createWithScale(btnBattleSprite, 1)
    local btnBattleLab = lbl.createFont1(20, "Battle", ccc3(0x70, 0x36, 0x19))
    btnBattleLab:setPosition(btnBattle:getContentSize().width/2 , btnBattle:getContentSize().height/2)
    btnBattle:addChild(btnBattleLab)
    local btnBattleMenu = CCMenu:createWithItem(btnBattle)
    btnBattleMenu:setPosition(0, 0)
    board:addChild(btnBattleMenu, 10)
    btnBattle:setPosition(410, 75)
    btnBattle:registerScriptTapHandler(function()
        if params.handler then
            params.handler(clone(hids))
        end
        layer:removeFromParentAndCleanup(true)
    end)

    return layer
end

return herolist
