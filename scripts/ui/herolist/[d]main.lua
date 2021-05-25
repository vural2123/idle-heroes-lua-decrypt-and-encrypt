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
local heros = require "data.heros"
local cfgvip = require "config.vip"
local bag = require "data.bag"
local player = require "data.player"
local cfgherBag = require "config.herobag"

function ui.create(params)
    local layer = CCLayer:create()

    layer.needFresh = false
    local params = params or {}

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
        audio.play(audio.button)
        if not params.back then
            replaceScene(require("ui.town.main").create())
        elseif params.back == "hook" then
            replaceScene(require("ui.hook.map").create())
        end
    end)

    autoLayoutShift(btnBack)

    local title = lbl.createFont3(30, i18n.global.herolist_title.string, ccc3(0xfa, 0xd8, 0x69))
    title:setScale(view.minScale)
    title:setPosition(scalep(480, 545))
    layer:addChild(title, 100)
    
    local showHeroLayer
    local model = params.model or "Hero"
    local sortType
    local group = params.group

    local board = img.createUISprite(img.ui.herolist_bg)
    board:setScale(view.minScale)
    board:setPosition(scalep(467, 272))
    --board:setPosition(view.midX - 15, view.midY - 20)
    layer:addChild(board)

    local vipLv = player.vipLv() or 0
    local heroNumLab = lbl.createFont1(16, #heros .. "/" .. (cfgvip[vipLv].heroes + player.buy_hlimit * 5), ccc3(0x70, 0x36, 0x19))
    heroNumLab:setPosition(110, 472)
    board:addChild(heroNumLab)
 
    -- gem btn
    local btnAdd0 = img.createUISprite(img.ui.main_icon_plus)
    local btnAdd = SpineMenuItem:create(json.ui.button, btnAdd0)
    btnAdd:setScale(view.minScale)
    btnAdd:setPosition(scalep(215, 495))
    local btnAddMenu = CCMenu:createWithItem(btnAdd)
    btnAddMenu:setPosition(CCPoint(0, 0))
    layer:addChild(btnAddMenu)

    btnAdd:registerScriptTapHandler(function()
        local function onAdd()
            if bag.gem() < cfgherBag[player.buy_hlimit + 1].cost then
                showToast(i18n.global.summon_gem_lack.string)
                return
            else
                local params = {
                    sid = player.sid
                }
                addWaitNet()
                net:buy_hlimit(params, function(__data)
                    delWaitNet()

                    tbl2string(__data)
                    bag.subGem(cfgherBag[player.buy_hlimit + 1].cost)
                    player.buy_hlimit = player.buy_hlimit + 1
                    heroNumLab:setString(#heros .. "/" .. (cfgvip[vipLv].heroes + player.buy_hlimit * 5))
                end)
            end
        end
        if player.buy_hlimit >= #cfgherBag then
            showToast(i18n.global.toast_buy_herolist_full.string) 
        else
            local pr = {
                --title = i18n.global.herolist_buynum_title.string,
                title = "",
                text = string.format(i18n.global.herolist_buynum_text.string, cfgherBag[player.buy_hlimit + 1].cost, 5),
                handle = onAdd,
                scale = true,
            }
            layer:addChild(require("ui.tips.confirm").create(pr), 100)
        end
    end)

    local btnHeroSprite0 = img.createUISprite(img.ui.herolist_tab_hero_nselect)
    local btnHeroSprite1 = img.createUISprite(img.ui.herolist_tab_hero_select)
    local btnHero = CCMenuItemSprite:create(btnHeroSprite0, btnHeroSprite1, btnHeroSprite0)
    local btnHeroMenu = CCMenu:createWithItem(btnHero)
    btnHero:setPosition(848, 318)
    btnHeroMenu:setPosition(0, 0)
    board:addChild(btnHeroMenu, 10)

    local btnBookSprite0 = img.createUISprite(img.ui.herolist_tab_book_nselect)
    local btnBookSprite1 = img.createUISprite(img.ui.herolist_tab_book_select)
    local btnBook = CCMenuItemSprite:create(btnBookSprite0, btnBookSprite1, btnBookSprite0)
    local btnBookMenu = CCMenu:createWithItem(btnBook)
    btnBook:setPosition(848, 195)
    btnBookMenu:setPosition(0, 0)
    board:addChild(btnBookMenu, 10)

    local btnGroupList = {}
    local getDataAndCreateList
    if model == "Hero" then
        btnHero:selected()
        btnAdd:setVisible(true)
    else
        btnBook:selected()
        btnAdd:setVisible(false)
    end
    btnHero:registerScriptTapHandler(function()
        audio.play(audio.button)
        if model ~= "Hero" then
            btnHero:setEnabled(false)
            btnBook:setEnabled(true)
            title:setString(i18n.global.herolist_title.string)
            btnHero:selected()
            btnBook:unselected()
            model = "Hero"
            if group then
                btnGroupList[group]:unselected()
                group = nil
            end
            btnAdd:setVisible(true)
            getDataAndCreateList()
        end
    end)
    btnBook:registerScriptTapHandler(function()
        audio.play(audio.button)
        if model ~= "Book" then
            btnHero:setEnabled(true)
            btnBook:setEnabled(false)
            title:setString(i18n.global.herolist_title_herobook.string)
            btnHero:unselected()
            btnBook:selected()
            model = "Book"
            btnAdd:setVisible(false)
            getDataAndCreateList()
        end
    end)

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
        
        local showSelect = img.createUISprite(img.ui.herolist_select_icon)
        showSelect:setPosition(btnGroupList[i]:getContentSize().width/2, btnGroupList[i]:getContentSize().height/2 + 2)
        btnGroupList[i]:addChild(showSelect)
        btnGroupList[i].showSelect = showSelect
        showSelect:setVisible(false)

        btnGroupList[i]:registerScriptTapHandler(function()
            audio.play(audio.button)
            for j=1, 6 do
                btnGroupList[j]:unselected()
                btnGroupList[j].showSelect:setVisible(false)
            end
            if not group or i ~= group then
                group = i
                btnGroupList[i]:selected()
                btnGroupList[i].showSelect:setVisible(true)
            else
                group = nil
            end

            getDataAndCreateList()
        end)
    end
    if group then
        btnGroupList[group]:selected()
        btnGroupList[group].showSelect:setVisible(true)
    end

    local function createDownList()
        local layer = CCLayer:create()
       
        local bg = img.createUI9Sprite(img.ui.tips_bg)
        bg:setPreferredSize(CCSize(142, 116))
        bg:setPosition(707, 377)
        layer:addChild(bg)

        local btnLevelSprite = img.createUISprite(img.ui.herolist_pulldown) 
        btnLevelSprite:setFlipY(true)
        local btnLevel = HHMenuItem:createWithScale(btnLevelSprite, 1)
        local btnLevelLab = lbl.createFont1(18, i18n.global.herolist_sort_lv.string)--, ccc3(0xff, 0xdb, 0x67))
        btnLevelLab:setPosition(btnLevel:getContentSize().width/2 , btnLevel:getContentSize().height/2)
        btnLevel:addChild(btnLevelLab)
        if sortType == "Level" then
            btnLevelLab:setColor(ccc3(0xff, 0xdb, 0x67))
        end
        local btnLevelMenu = CCMenu:createWithItem(btnLevel)
        btnLevel:setAnchorPoint(ccp(0.5, 0))
        btnLevel:setPosition(bg:getContentSize().width/2, bg:getContentSize().height/2)
        btnLevelMenu:setPosition(0, 0)
        bg:addChild(btnLevelMenu)
        btnLevel:registerScriptTapHandler(function()
            audio.play(audio.button)
            sortType = "Level" 
            getDataAndCreateList()
            layer:removeFromParentAndCleanup(true)
        end)

        local btnStarSprite = img.createUISprite(img.ui.herolist_pulldown) 
        local btnStar = HHMenuItem:createWithScale(btnStarSprite, 1)
        local btnStarLab = lbl.createFont1(18, i18n.global.herolist_sort_qlt.string)--, ccc3(0xff, 0xdb, 0x67))
        btnStarLab:setPosition(btnStar:getContentSize().width/2 , btnStar:getContentSize().height/2)
        btnStar:addChild(btnStarLab)
        if sortType == "Star" then
            btnStarLab:setColor(ccc3(0xff, 0xdb, 0x67))
        end
        local btnStarMenu = CCMenu:createWithItem(btnStar)
        btnStar:setAnchorPoint(ccp(0.5, 1))
        btnStar:setPosition(bg:getContentSize().width/2, bg:getContentSize().height/2 + 1)
        btnStarMenu:setPosition(0, 0)
        bg:addChild(btnStarMenu)
        btnStar:registerScriptTapHandler(function()
            audio.play(audio.button)
            sortType = "Star"
            getDataAndCreateList()
            layer:removeFromParentAndCleanup(true)
        end)

        layer:registerScriptTouchHandler(function() 
            layer:removeFromParentAndCleanup(true)
            return true 
        end)
        layer:setTouchEnabled(true)

        return layer
    end

    local btnSortSprite = img.createUISprite(img.ui.herolist_button_pulldown)
    local btnSortIcon = img.createUISprite(img.ui.herolist_triangle)
    btnSortIcon:setPosition(78, 18)
    btnSortSprite:addChild(btnSortIcon)
    local btnSort = HHMenuItem:createWithScale(btnSortSprite, 1)
    local btnSortLab = lbl.createFont1(12, i18n.global.herolist_sort_btn.string, ccc3(0x70, 0x36, 0x19))
    btnSortLab:setPosition(btnSort:getContentSize().width/2 - 12, btnSort:getContentSize().height/2)
    btnSort:addChild(btnSortLab)
    local btnSortMenu = CCMenu:createWithItem(btnSort)
    btnSortMenu:setPosition(0, 0)
    board:addChild(btnSortMenu, 10)
    btnSort:setPosition(715, 472)
    btnSort:registerScriptTapHandler(function()
        audio.play(audio.button)
        board:addChild(createDownList(), 1000)
    end)

    local function createHeroList(herolist)
        local layer = CCLayer:create()

        local SCROLLVIEW_WIDTH = 710
        local SCROLLVIEW_HEIGHT = 411
        local SCROLLCONTENT_HEIGHT = 23 + 101 * math.ceil(#herolist/7)
        
        local scroll = CCScrollView:create()
        scroll:setDirection(kCCScrollViewDirectionVertical)
        scroll:setAnchorPoint(ccp(0, 0))
        scroll:setPosition(66, 29)
        scroll:setViewSize(CCSize(SCROLLVIEW_WIDTH, SCROLLVIEW_HEIGHT))
        scroll:setContentSize(CCSize(SCROLLVIEW_WIDTH, SCROLLCONTENT_HEIGHT))
        scroll:setContentOffset(ccp(0, SCROLLVIEW_HEIGHT - SCROLLCONTENT_HEIGHT))
        layer:addChild(scroll)

        local iconBgBatch = img.createBatchNodeForUI(img.ui.herolist_head_bg)
        scroll:getContainer():addChild(iconBgBatch, 1)
        local iconBgBatch1 = img.createBatchNodeForUI(img.ui.hero_star_ten_bg)
        scroll:getContainer():addChild(iconBgBatch1, 1)
        local groupBgBatch = img.createBatchNodeForUI(img.ui.herolist_group_bg)
        scroll:getContainer():addChild(groupBgBatch , 3)
        local starBatch = img.createBatchNodeForUI(img.ui.star_s)
        scroll:getContainer():addChild(starBatch, 3)
        local star1Batch = img.createBatchNodeForUI(img.ui.hero_star_orange)
        scroll:getContainer():addChild(star1Batch, 3)
        local star10Batch = img.createBatchNodeForUI(img.ui.hero_star_ten)
        scroll:getContainer():addChild(star10Batch, 3)
        local blackBatch = img.createBatchNodeForUI(img.ui.hero_head_shade)
        scroll:getContainer():addChild(blackBatch, 5)


        local headIcons = {}
        local function createItem(i, v)
            local y, x = SCROLLCONTENT_HEIGHT - math.ceil( i / 7 ) * 101 + 40, ( i - math.ceil( i / 7 ) * 7 + 7 ) * 101 - 51
            local headBg = nil
            local qlt = cfghero[herolist[i].id].maxStar
            if qlt == 10 then
                headBg = img.createUISprite(img.ui.hero_star_ten_bg)
                headBg:setPosition(x, y)
                iconBgBatch1:addChild(headBg)

                json.load(json.ui.lv10_framefx)
                local aniten = DHSkeletonAnimation:createWithKey(json.ui.lv10_framefx)
                aniten:playAnimation("animation", -1)
                aniten:scheduleUpdateLua()
                aniten:setPosition(x, y)
                scroll:getContainer():addChild(aniten, 4)
            else
                headBg = img.createUISprite(img.ui.herolist_head_bg)
                headBg:setPosition(x, y)
                iconBgBatch:addChild(headBg)
            end
           
            if herolist[i].hid then 
                headIcons[i] = img.createHeroHeadByHid(herolist[i].hid)
            else
                headIcons[i] = img.createHeroHeadIcon(herolist[i].id)
				img.fixOfficialScale(headIcons[i], "hero", herolist[i].id)
                local groupBg = img.createUISprite(img.ui.herolist_group_bg)
                groupBg:setScale(0.42)
                groupBg:setPosition(x - 30, y + 29)
                groupBgBatch:addChild(groupBg)
        
                local groupIcon = img.createUISprite(img.ui["herolist_group_" .. cfghero[herolist[i].id].group])
                groupIcon:setScale(0.42)
                groupIcon:setPosition(x - 30, y + 30)
                scroll:getContainer():addChild(groupIcon, 3)

                local showLv = lbl.createFont2(16, herolist[i].lv)
                showLv:setPosition(x + 26, y + 30)
                scroll:getContainer():addChild(showLv, 3)

                if qlt <= 5 then
                    for i = qlt, 1, -1 do
                        local star = img.createUISprite(img.ui.star_s)
                        star:setPosition(x + (i-(qlt+1)/2)*12, y - 32)
                        starBatch:addChild(star)
                    end
                elseif qlt == 6 then
                    local redstar = 1
                    if herolist[i].wake then
                        redstar = herolist[i].wake+1
                    end
                    for i = redstar, 1, -1 do
                        local star = img.createUISprite(img.ui.hero_star_orange)
                        star:setScale(0.75)
                        star:setPosition(x + (i-(redstar+1)/2)*12, y - 30)
                        star1Batch:addChild(star)
                    end
                elseif qlt == 10 then
                    local star = img.createUISprite(img.ui.hero_star_ten)
                    --star:setScale(0.75)
                    star:setPosition(x, y - 30)
                    star10Batch:addChild(star)
                end
            end
            headIcons[i]:setPosition(x, y)
            scroll:getContainer():addChild(headIcons[i], 2)

           
            if model ~= "Hero" and not v.isHave then 
                local blackBoard = img.createUISprite(img.ui.hero_head_shade)
                blackBoard:setScale(90/94)
                blackBoard:setOpacity(120)
                blackBoard:setPosition(headIcons[i]:getPositionX(), headIcons[i]:getPositionY())
                blackBatch:addChild(blackBoard, 0, i)
            end
        end

        local initShowCount = 60
        for i, v in ipairs(herolist) do
            if i > initShowCount then
                break
            end

            createItem(i, v)
        end

        local heroCount = #herolist
        local function showAfter()
            if initShowCount < heroCount then
                initShowCount = initShowCount + 1
                createItem(initShowCount, herolist[initShowCount])
                return true
            end
        end

        if heroCount == 0 then
            local empty = require("ui.empty").create({ text = i18n.global.empty_herolist.string , color = ccc3(0xd9, 0xbb, 0x9d)})
            empty:setPosition(board:getContentSize().width/2, board:getContentSize().height/2)
            layer:addChild(empty)
        elseif heroCount > initShowCount then
            layer:scheduleUpdateWithPriorityLua(function ( dt )
                if showAfter() then
                    if showAfter() then
                        showAfter()
                    end
                end
            end, 0)
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
                    audio.play(audio.button)
                    if model == "Hero" then
                        --replaceScene(require("ui.hero.main").create(herolist[i].hid, group))
                        bg:getParent():addChild(require("ui.hero.main").create(herolist[i].hid, group, herolist, i), 10000)
                    else
                        --replaceScene(require("ui.herolist.herobook").create(herolist[i].id))
                        bg:getParent():addChild(require("ui.herolist.herobook").create(herolist[i].id, nil, herolist, i), 10000)
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

    function getDataAndCreateList()
        local herolist = {}
        if model == "Hero" then
            for _, v in ipairs(heros) do
                if not group or cfghero[v.id].group == group then
                    herolist[#herolist + 1] = {
                        hid = v.hid,
                        id = v.id,
                        lv = v.lv,
                        star = v.star,
                        wake = v.wake,
                        --power = heros.power(v.hid),
                    }
                end
            end
            btnSort:setVisible(true)
            heroNumLab:setVisible(true)
            
            if sortType == "Level" then
                for i=1, #herolist do
                    for j=i+1, #herolist do
                        if herolist[i].lv < herolist[j].lv then
                            herolist[i], herolist[j] = herolist[j], herolist[i]
                        end
                    end
                end
            elseif sortType == "Star" then
                for i=1, #herolist do
                    for j=i+1, #herolist do
                        if cfghero[herolist[i].id].qlt < cfghero[herolist[j].id].qlt then
                            herolist[i], herolist[j] = herolist[j], herolist[i]
                        end
                        if herolist[i].wake == nil and herolist[j].wake then
                            herolist[i], herolist[j] = herolist[j], herolist[i]
                        end
                        if herolist[i].wake and herolist[j].wake then
                            if herolist[i].wake < herolist[j].wake then
                                herolist[i], herolist[j] = herolist[j], herolist[i]
                            end
                        end
                    end
                end
            else
                table.sort(herolist, compareHero)
            end
        else
            if not group then
                group = 1
                btnGroupList[1]:selected()
                btnGroupList[1].showSelect:setVisible(true)
            end
            for _, v in pairs(cfghero) do
                if v.showInGuide > 0 then
                    if not group or v.group == group then
                        herolist[#herolist + 1] = {
                            id = _ ,
                            lv = cfghero[_].maxLv,
                        }
                    end
                end
            end
            for i=1, #herolist do
                for j=i+1, #herolist do
                    if herolist[i].id > herolist[j].id then
                        herolist[i], herolist[j] = herolist[j], herolist[i]
                    end
                end
            end    
            local herobook = require "data.herobook"
            for i=1, #herolist do
                herolist[i].isHave = false
                for j=1, #herobook do
                    if herolist[i].id  == herobook[j] then
                        herolist[i].isHave = true
                    end
                end
            end
            btnSort:setVisible(false)
            heroNumLab:setVisible(false)
        end
        if showHeroLayer then
            showHeroLayer:removeFromParentAndCleanup(true)
            showHeroLayer = nil
        end
        showHeroLayer = createHeroList(herolist)
        board:addChild(showHeroLayer)
    end
    getDataAndCreateList()

    layer:scheduleUpdateWithPriorityLua(function()
        if layer.needFresh == true then
            layer.needFresh = false
            heroNumLab:setString(#heros .. "/" .. (cfgvip[vipLv].heroes + player.buy_hlimit * 5))
            getDataAndCreateList()
        end
    end)
    addBackEvent(layer)
    function layer.onAndroidBack()
        if not params.back then
            replaceScene(require("ui.town.main").create())
        elseif params.back == "hook" then
            replaceScene(require("ui.hook.map").create())
        end
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

    require("ui.tutorial").show("ui.hero.main", layer)

    return layer
end

return ui
