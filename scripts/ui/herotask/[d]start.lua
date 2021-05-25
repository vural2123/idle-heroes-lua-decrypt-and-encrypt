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
local cfgtask = require "config.herotask"
local cfgequip = require "config.equip"
local heros = require "data.heros"
local bag = require "data.bag"
local player = require "data.player"
local htaskData = require "data.herotask"

local function initHerolistData(params)
    local params = params or {}
    local tmpheros = clone(heros)
    
    local herolist = {}
    for i, v in ipairs(tmpheros) do
        if params.group then
            if cfghero[v.id].group == params.group then
                herolist[#herolist + 1] = v
            --else
            --    for j=1, 6  do
            --        if params.hids[j] == v.hid then
            --            herolist[#herolist + 1] = v
            --        end
            --    end
            end
        else
            herolist[#herolist + 1] = v
        end
    end

    for i, v in ipairs(herolist) do
        v.isUsed = false
    end

    table.sort(herolist, compareHero)

    local tlist = herolistless(herolist)
    return tlist
end

function ui.create(info)
    local layer = CCLayer:create()

    --dark bg
    local darkbg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    darkbg:setScale(2)
    layer:addChild(darkbg)

    local showReward = {}
    local showHero = {}
    
    local showPowerBg = CCSprite:create()
    showPowerBg:setContentSize(CCSize(960, 576))
    showPowerBg:setPosition(480, 576/2)
    layer:addChild(showPowerBg)

    ---- anim
    showPowerBg:setScale(0.5)
    showPowerBg:runAction(CCScaleTo:create(0.15, 1, 1))

    local lbg = img.createUISprite(img.ui.herotask_dialog)
    lbg:setAnchorPoint(1, 0.5)
    lbg:setPosition(480, 576/2)
    showPowerBg:addChild(lbg)
   
    local rbg = img.createUISprite(img.ui.herotask_dialog)
    rbg:setFlipX(true)
    rbg:setAnchorPoint(0, 0.5)
    rbg:setPosition(lbg:boundingBox():getMaxX()-1, 576/2)
    showPowerBg:addChild(rbg)
    
    local board = img.createUI9Sprite(img.ui.select_hero_camp_bg)
    board:setPreferredSize(CCSize(656, 268))
    board:setAnchorPoint(ccp(0, 0))
    board:setPosition(152, 228)
    showPowerBg:addChild(board)

    local powerBg = img.createUI9Sprite(img.ui.select_tab_tab_bg)
    powerBg:setPreferredSize(CCSize(646, 38))
    powerBg:setAnchorPoint(ccp(0, 0))
    powerBg:setPosition(158, 455)
    showPowerBg:addChild(powerBg)

    --local powerIconBg = img.createUISprite(img.ui.select_hero_power_bg)
    --powerIconBg:setAnchorPoint(ccp(0, 0.5))
    --powerIconBg:setPosition(0, 19)
    --powerBg:addChild(powerIconBg)
  
    --local powerIcon = img.createUISprite(img.ui.power_icon)
    --powerIcon:setScale(0.48)
    --powerIcon:setPosition(27, 19)
    --powerBg:addChild(powerIcon)
    
    --local showPower = lbl.createFont2(16, "0", ccc3(0xee, 0x3d, 0x3d))
    --showPower:setAnchorPoint(ccp(1, 0.5)) 
    --showPower:setPosition(112, 19)
    --powerBg:addChild(showPower, 1)

    --local powerNeed = lbl.createFont2(16, "/" .. cfgtask[info.id].power)
    --powerNeed:setAnchorPoint(ccp(0, 0.5))
    --powerNeed:setPosition(112, 19)
    --powerBg:addChild(powerNeed, 1)
 
    local showTime = lbl.createFont1(16, (cfgtask[info.id].questTime/60) .. " " .. i18n.global.herotask_info_hours.string, ccc3(0xe2, 0xcd, 0xac))
    showTime:setAnchorPoint(ccp(1, 0.5))
    showTime:setPosition(90, 19)
    powerBg:addChild(showTime)

    local timeIcon = img.createUISprite(img.ui.clock)
    timeIcon:setAnchorPoint(ccp(1, 0.5))
    timeIcon:setPosition(showTime:boundingBox():getMinX() - 5, 19)
    powerBg:addChild(timeIcon)

    local reward = conquset2items(info.reward) 
    local offsetX = 480 - 46 * #reward + 9
    for i, v in ipairs(reward) do
        local showRewardSprite
        if v.type == 1 then
            showRewardSprite = img.createItem(v.id, v.num)
        else
            showRewardSprite = img.createEquip(v.id, v.num)
        end
        showReward[i] = CCMenuItemSprite:create(showRewardSprite, nil)
        local menuReward = CCMenu:createWithItem(showReward[i])
        menuReward:setPosition(0, 0)
        showPowerBg:addChild(menuReward)
        showReward[i]:setAnchorPoint(ccp(0, 0))
        showReward[i]:setScale(74/92)
        showReward[i]:setPosition(offsetX + (i-1) * 92, 137)
        
        showReward[i]:registerScriptTapHandler(function()
            local superlayer = layer:getParent():getParent():getParent()
            if v.type == 1 then
                local tips = require("ui.tips.item").createForShow(v)
                superlayer:addChild(tips, 10000)
            else
                local tips = require("ui.tips.equip").createById(v.id)
                superlayer:addChild(tips, 10000)
            end
        end)
    end

    local hids = {}
    local baseHeroBg = {}
    local showHeros = {}
    local heroNum = cfgtask[info.id].heroNum
    
    local offsetX = 480 - 26 * #info.conds + 5
    local condition = {}
    for i, v in ipairs(info.conds) do
        condition[i] = img.createUISprite(img.ui.hook_rate_bg)
        condition[i]:setScale(0.8)
        condition[i]:setAnchorPoint(ccp(0, 0))
        condition[i]:setPosition(offsetX + 52 * (i - 1), 248)
        showPowerBg:addChild(condition[i])

        local ctip
        if v.type == 1 then 
            ctip = string.gsub(i18n.global.toast_herotask_job.string, "##", i18n.global["job_" .. v.faction].string)
        elseif v.type == 2 then 
            ctip = string.format(i18n.global.toast_herotask_star.string, v.faction)
        elseif v.type == 3 then
            ctip = string.gsub(i18n.global.toast_herotask_group.string, "##", i18n.global["hero_group_" .. v.faction].string)
        elseif v.type == 4 then 
            ctip = string.format(i18n.global.toast_herotask_qualtiy.string, v.faction)
        end
        
        local showTipBg = img.createUI9Sprite(img.ui.tips_bg)
        showTipBg:setPreferredSize(CCSize(300, 100))
        showTipBg:setAnchorPoint(ccp(1, 0))
        showTipBg:setPosition(condition[i]:boundingBox():getMaxX(), condition[i]:boundingBox():getMaxY())
        showPowerBg:addChild(showTipBg, 10000)

        local showText = lbl.createMixFont1(16, ctip, ccc3(255, 246, 223))
        showTipBg:setPreferredSize(CCSize(showText:boundingBox().size.width + 50, 60))
        showText:setPosition(showTipBg:getContentSize().width/2, 30)
        showTipBg:addChild(showText)
        condition[i].showTipBg = showTipBg
        showTipBg:setVisible(false)

        if v.type == 1 then
            local showJob = img.createUISprite(img.ui["herotask_job_" .. v.faction])
            showJob:setPosition(condition[i]:getContentSize().width/2, condition[i]:getContentSize().height/2)
            condition[i]:addChild(showJob)
        elseif v.type == 2 then
            local showStar = img.createUISprite(img.ui.star)
            showStar:setScale(0.95)
            showStar:setPosition(condition[i]:getContentSize().width/2, condition[i]:getContentSize().height/2)
            condition[i]:addChild(showStar)

            local showNum = lbl.createFont2(18, v.faction)
            showNum:setPosition(condition[i]:getContentSize().width/2, condition[i]:getContentSize().height/2)
            condition[i]:addChild(showNum)
        elseif v.type == 3 then
            local showGroup = img.createUISprite(img.ui["herolist_group_" .. v.faction])
            showGroup:setPosition(condition[i]:getContentSize().width/2, condition[i]:getContentSize().height/2)
            condition[i]:addChild(showGroup)
        elseif v.type == 4 then
            local showQlt = img.createUISprite(img.ui.evolve)
            showQlt:setScale(0.7)
            showQlt:setPosition(condition[i]:getContentSize().width/2, condition[i]:getContentSize().height/2)
            condition[i]:addChild(showQlt)

            local showNum = lbl.createFont2(18, v.faction)
            showNum:setPosition(condition[i]:getContentSize().width/2, condition[i]:getContentSize().height/2)
            condition[i]:addChild(showNum)
        end
    end

    local titleCondition = lbl.createFont1(18, i18n.global.herotask_title_condition.string, ccc3(0x5b, 0x27, 0x06))
    titleCondition:setPosition(480, 308)
    showPowerBg:addChild(titleCondition)

    local showLfgline = img.createUISprite(img.ui.herotask_fgline)
    showLfgline:setAnchorPoint(ccp(1, 0.5))
    showLfgline:setPosition(titleCondition:boundingBox():getMinX() - 30, titleCondition:boundingBox():getMidY())
    showPowerBg:addChild(showLfgline)

    local showRfgline = img.createUISprite(img.ui.herotask_fgline)
    showRfgline:setAnchorPoint(ccp(0, 0.5))
    showRfgline:setFlipX(true)
    showRfgline:setPosition(titleCondition:boundingBox():getMaxX() + 30, titleCondition:boundingBox():getMidY())
    showPowerBg:addChild(showRfgline)
 

    local btnStart
    local checkConfirm = false
    local tip 
    local function checkCondition()
        checkConfirm = true
        tip = i18n.global.herotask_start_info.string
        local res = {}
        for i, v in ipairs(info.conds) do
            res[i] = false
        end
        --local power = 0
        for i=1, cfgtask[info.id].heroNum do
            local v = hids[i] or 0
            if v > 0 then
                local heroInfo = heros.find(v)
                --power = power + heros.power(heroInfo.hid)
                for j, k in ipairs(info.conds) do
                    if k.type == 1 then 
                        if cfghero[heroInfo.id].job == k.faction then
                            res[j] = true
                        end
                    elseif k.type == 2 then 
                        if cfghero[heroInfo.id].qlt >= k.faction then
                            res[j] = true
                        end
                    elseif k.type == 3 then
                        if cfghero[heroInfo.id].group == k.faction then
                            res[j] = true
                        end
                    elseif k.type == 4 then 
                        if heroInfo.star >= k.faction then
                            res[j] = true
                        end
                    end
                end
            end
        end

        for i, v in ipairs(info.conds) do
            if not res[i] then
                if v.type == 1 then 
                    tip = string.gsub(i18n.global.toast_herotask_job.string, "##", i18n.global["job_" .. v.faction].string)
                elseif v.type == 2 then 
                    tip = string.format(i18n.global.toast_herotask_star.string, v.faction)
                elseif v.type == 3 then
                    tip = string.gsub(i18n.global.toast_herotask_group.string, "##", i18n.global["hero_group_" .. v.faction].string)
                elseif v.type == 4 and not res[i] then 
                    tip = string.format(i18n.global.toast_herotask_qualtiy.string, v.faction)
                end
            end
        end

        for i, v in ipairs(condition) do
            if v:getChildByTag(1) then
                v:removeChildByTag(1)
            end
            if res[i] then
                local dg = img.createUISprite(img.ui.hook_btn_sel)
                dg:setAnchorPoint(ccp(1, 0))
                dg:setScale(0.6)
                dg:setPosition(condition[i]:getContentSize().width + 2, -2)
                v:addChild(dg, 1, 1)
            else
                checkConfirm = false
            end
        end
        --showPower:setString(power)
        --if power >= cfgtask[info.id].power then
        --    showPower:setColor(ccc3(0xff, 0xff, 0xff))
        --else
        --    checkConfirm = false
        --    showPower:setColor(ccc3(0xee, 0x3d, 0x3d))
        --end
        
        if not checkConfirm then
            setShader(btnStart, SHADER_GRAY, true)
        else
            clearShader(btnStart, true)
        end
    end
	
	local kscroll = nil

    local function createHeroList()
        local showHeroLayer = CCLayer:create()
        layer:addChild(showHeroLayer, 100)
        
        local herolistBg = img.createUI9Sprite(img.ui.tips_bg)
        herolistBg:setPreferredSize(CCSize(960, 112))
        herolistBg:setPosition(480, -64)
        showHeroLayer:addChild(herolistBg, 100)

        herolistBg:runAction(CCEaseBackOut:create(CCMoveTo:create(0.5, ccp(480, 56))))

        local herolist = clone(heros)
        table.sort(herolist, compareHero)
        herolist = herolistless(herolist)
        local headIcons = {}

        SCROLLVIEW_WIDTH = 943 - 150
        SCROLLVIEW_HEIGHT = 112
        SCROLLCONTENT_WIDTH = #herolist * 90 + 8

        kscroll = CCScrollView:create()
        kscroll:setDirection(kCCScrollViewDirectionHorizontal)
        kscroll:setAnchorPoint(ccp(0, 0))
        kscroll:setPosition(7, 0)
        kscroll:setViewSize(CCSize(SCROLLVIEW_WIDTH, SCROLLVIEW_HEIGHT))
        kscroll:setContentSize(CCSizeMake(SCROLLCONTENT_WIDTH, SCROLLVIEW_HEIGHT))
        kscroll:setContentOffset(CCPoint(0, 0))
        herolistBg:addChild(kscroll)

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
        filterBg:setPreferredSize(CCSize(122, 458))
        filterBg:setAnchorPoint(ccp(1, 0))
        filterBg:setPosition(938, 110)
        showHeroLayer:addChild(filterBg)

        local showHeroLayer2 = CCLayer:create()
        kscroll:getContainer():addChild(showHeroLayer2)

        local selectBatch = nil
        local blackBatch = nil
        local function onMoveUp(pos, tpos, isNotCallBack)
            if not isNotCallBack then
                local heroInfo = heros.find(hids[tpos])
                --showHeros[tpos] = img.createHeroHead(heroInfo.id, heroInfo.lv, true, 3, heroInfo.wake)
                local param = {
                    id = heroInfo.id,
                    lv = heroInfo.lv,
                    showGroup = true,
                    showStar = 3,
                    wake = heroInfo.wake,
                    orangeFx = nil,
                    petID = nil,
                    hskills = heroInfo.hskills,
hid = heroInfo.hid
                }
                showHeros[tpos] = img.createHeroHeadByParam(param)
                showHeros[tpos]:setScale(84/94)
                showHeros[tpos]:setPosition(baseHeroBg[tpos]:boundingBox():getMidX(), baseHeroBg[tpos]:boundingBox():getMidY())
                layer:addChild(showHeros[tpos])
            end

            local blackBoard = img.createUISprite(img.ui.hero_head_shade)
            blackBoard:setScale(80/94)
            blackBoard:setOpacity(120)
            blackBoard:setPosition(headIcons[pos]:getPositionX(), headIcons[pos]:getPositionY())
            blackBatch:addChild(blackBoard, 0, pos)
            --local blackBoard = CCLayerColor:create(ccc4(0, 0, 0, 120))
            --blackBoard:setContentSize(CCSize(92, 92))
            --blackBoard:setPosition(headIcons[pos]:getPositionX() - 46, headIcons[pos]:getPositionY() - 46)
            --blackBatch:addChild(blackBoard, 0, pos)

            local selectIcon = img.createUISprite(img.ui.hook_btn_sel)
            selectIcon:setPosition(headIcons[pos]:getPositionX(), headIcons[pos]:getPositionY())
            selectBatch:addChild(selectIcon, 0, pos)
        end

        local function moveUp(pos)
            local tpos
            for i=1, heroNum do
                if not hids[i] or hids[i] == 0 then
                    tpos = i
                    break
                end
            end

            if tpos and not herolist[pos].isUsed then
                herolist[pos].isUsed = true
                hids[tpos] = herolist[pos].hid
                
                local worldbpos = kscroll:getContainer():convertToWorldSpace(ccp(headIcons[pos]:getPositionX(), headIcons[pos]:getPositionY()))
                local realbpos = showHeroLayer:convertToNodeSpace(worldbpos)
                local worldepos = layer:convertToWorldSpace(ccp(baseHeroBg[tpos]:boundingBox():getMidX(), baseHeroBg[tpos]:boundingBox():getMidY()))
                local realepos = showHeroLayer:convertToNodeSpace(worldepos)
                --local tempHero = img.createHeroHead(herolist[pos].id, herolist[pos].lv, true)
                local param = {
                    id = herolist[pos].id,
                    lv = herolist[pos].lv,
                    showGroup = true,
                    showStar = nil,
                    wake = nil,
                    orangeFx = nil,
                    petID = nil,
                    hid = herolist[pos].hid
                }
                local tempHero = img.createHeroHeadByParam(param)
                tempHero:setPosition(realbpos)
                showHeroLayer:addChild(tempHero, 100)
                
                local arr = CCArray:create()
                arr:addObject(CCMoveTo:create(0.2, realepos))
                arr:addObject(CCScaleTo:create(0.2, 84/92))
                local act1 = CCSpawn:create(arr)
                tempHero:runAction(CCSequence:createWithTwoActions(act1, CCCallFunc:create(function() 
                    tempHero:removeFromParentAndCleanup(true)
                    onMoveUp(pos, tpos)
                end)))
            else
                if tpos then
                    showToast(i18n.global.toast_selhero_selected.string)
                else
                    showToast(i18n.global.toast_selhero_already.string)
                end
            end
        end

        local function onMoveDown(pos, tpos)
            blackBatch:removeChildByTag(tpos)
            selectBatch:removeChildByTag(tpos)
        end

        local function moveDown(pos)
            local tpos
            for i,v in ipairs(herolist) do
                if hids[pos] == v.hid then
                    tpos = i
                    break
                end
            end

            if tpos then
                showHeros[pos]:removeFromParentAndCleanup(true)
                showHeros[pos] = nil 
                herolist[tpos].isUsed = false
                hids[pos] = nil
                
                local worldbpos = layer:convertToWorldSpace(ccp(baseHeroBg[pos]:boundingBox():getMidX(), baseHeroBg[pos]:boundingBox():getMidY()))
                local realbpos = showHeroLayer:convertToNodeSpace(worldbpos)
                local worldepos = kscroll:getContainer():convertToWorldSpace(ccp(headIcons[tpos]:getPositionX(), headIcons[tpos]:getPositionY()))
                local realepos = showHeroLayer:convertToNodeSpace(worldepos)
                local tempHero = img.createHeroHead(herolist[tpos].id, herolist[tpos].lv, true)
                tempHero:setPosition(realbpos)
                tempHero:setScale(84/92)
                showHeroLayer:addChild(tempHero, 100)
                
                local arr = CCArray:create()
                arr:addObject(CCMoveTo:create(0.2, realepos))
                arr:addObject(CCScaleTo:create(0.2, 1))
                local act1 = CCSpawn:create(arr)
                tempHero:runAction(CCSequence:createWithTwoActions(act1, CCCallFunc:create(function() 
                    tempHero:removeFromParentAndCleanup(true)
                    onMoveDown(pos, tpos)
                end)))
            end
        end

        local function createHerolist()
            showHeroLayer2:removeAllChildrenWithCleanup(true)
            arrayclear(headIcons)
            local iconBgBatch = img.createBatchNodeForUI(img.ui.herolist_head_bg)
            showHeroLayer2:addChild(iconBgBatch, 1)
            local iconBgBatch1 = img.createBatchNodeForUI(img.ui.hero_star_ten_bg)
            showHeroLayer2:addChild(iconBgBatch1, 1)
            local groupBgBatch = img.createBatchNodeForUI(img.ui.herolist_group_bg)
            showHeroLayer2:addChild(groupBgBatch , 3)
            local starBatch = img.createBatchNodeForUI(img.ui.star_s)
            showHeroLayer2:addChild(starBatch, 3)
            local star10Batch = img.createBatchNodeForUI(img.ui.hero_star_ten)
            showHeroLayer2:addChild(star10Batch, 3)
            local star1Batch = img.createBatchNodeForUI(img.ui.hero_star_orange)
            showHeroLayer2:addChild(star1Batch, 3)
            blackBatch = img.createBatchNodeForUI(img.ui.hero_head_shade)
            showHeroLayer2:addChild(blackBatch, 4)
            selectBatch = img.createBatchNodeForUI(img.ui.hook_btn_sel)
            showHeroLayer2:addChild(selectBatch, 5)
            for i=1, #herolist do
                local x, y = 45 + (i-1) * 90 + 8, 56 
           
                local qlt = cfghero[herolist[i].id].maxStar
                local heroBg = nil
                if qlt == 10 then
                    heroBg = img.createUISprite(img.ui.hero_star_ten_bg)
                    heroBg:setPosition(x, y)
                    heroBg:setScale(0.92)
                    iconBgBatch1:addChild(heroBg)

                    json.load(json.ui.lv10_framefx)
                    local aniten = DHSkeletonAnimation:createWithKey(json.ui.lv10_framefx)
                    aniten:playAnimation("animation", -1)
                    aniten:scheduleUpdateLua()
                    aniten:setScale(0.92)
                    aniten:setPosition(x, y)
                    showHeroLayer2:addChild(aniten, 4)
                else
                    heroBg = img.createUISprite(img.ui.herolist_head_bg)
                    heroBg:setScale(0.92)
                    heroBg:setPosition(x, y)
                    iconBgBatch:addChild(heroBg)
                end

                headIcons[i] = img.createHeroHeadByHid(herolist[i].hid)
                headIcons[i]:setScale(0.92)
                headIcons[i]:setPosition(x, y)
                showHeroLayer2:addChild(headIcons[i], 2)

                --local groupBg = img.createUISprite(img.ui.herolist_group_bg)
                --groupBg:setScale(0.42 * 0.92)
                --groupBg:setPosition(x - 26, y + 26)
                --groupBgBatch:addChild(groupBg)

                --local groupIcon = img.createUISprite(img.ui["herolist_group_" .. cfghero[herolist[i].id].group])
                --groupIcon:setScale(0.42 * 0.92)
                --groupIcon:setPosition(x - 26, y + 26)
                --showHeroLayer2:addChild(groupIcon, 3)

                --local showLv = lbl.createFont2(15 * 0.92, herolist[i].lv)
                --showLv:setPosition(x + 23, y + 26)
                --showHeroLayer2:addChild(showLv, 3)

                --if qlt <= 5 then
                --    for i = qlt, 1, -1 do
                --        local star = img.createUISprite(img.ui.star_s)
                --        star:setScale(0.92)
                --        star:setPosition(x + (i-(qlt+1)/2)*12*0.8, y - 30)
                --        starBatch:addChild(star)
                --    end
                --else
                --    local redstar = 1
                --    if herolist[i].wake then
                --        redstar = herolist[i].wake+1
                --    end
                --    if redstar == 5 then
                --        local starIcon2 = img.createUISprite(img.ui.hero_star_ten)
                --        starIcon2:setScale(0.92)
                --        starIcon2:setPosition(x, y-28)
                --        star10Batch:addChild(starIcon2)
                --    else
                --        for i = redstar, 1, -1 do
                --            local star = img.createUISprite(img.ui.hero_star_orange)
                --            star:setScale(0.92*0.75)
                --            star:setPosition(x + (i-(redstar+1)/2)*12*0.8, y - 28)
                --            star1Batch:addChild(star)
                --        end
                --    end
                --end

                local showJob = img.createUISprite(img.ui["job_" .. cfghero[herolist[i].id].job])
                --showJob:setScale(0.92)
                showJob:setPosition(x - 26, y + 6)
                showHeroLayer2:addChild(showJob, 3)
            end
            for i,v in ipairs(herolist) do
                for j=1, heroNum do
                    if v.hid == hids[j] then
                        onMoveUp(i, j, true)
                        herolist[i].isUsed = true
                    end
                end
            end

            for i, v in ipairs(herolist) do
                for _, taskInfo  in ipairs(htaskData.tasks) do
                    if info.tid ~= taskInfo.tid and taskInfo.heroes then
                        for j, k in ipairs(taskInfo.heroes) do
                            if v.hid == k.hid then
                                onMoveUp(i, 0, true)
                                herolist[i].isUsed = true
                            end
                        end
                    end
                end
            end
        end
        createHerolist()


        local lastx
        local function onTouchExtraBegin(x, y)
            lastx = x
            return true
        end

        local function onTouchExtraMoved(x, y)
            return true
        end

        local function onTouchExtraEnd(x, y)
            local point = layer:convertToNodeSpace(ccp(x, y))
            local pointOnScroll 
            if kscroll and not tolua.isnull(kscroll) and kscroll:getContainer() then
                pointOnScroll = kscroll:getContainer():convertToNodeSpace(ccp(x, y))
            else
                return true
            end
            
            local flag = false
            if math.abs(x - lastx) < 10 then
                for i, v in ipairs(headIcons) do
                    if v:boundingBox():containsPoint(pointOnScroll) then
                        audio.play(audio.button)
                        local ban = CCLayer:create()
                        ban:setTouchEnabled(true)
                        ban:setTouchSwallowEnabled(true)
                        layer:addChild(ban, 1000)

                        layer:runAction(createSequence({
                            CCDelayTime:create(0.2),CCCallFunc:create(function()
                                ban:removeFromParent()
                            end)
                        }))
                        moveUp(i)
                        flag = true
                    end
                end

                for i=1, heroNum do 
                    if hids[i] and showHeros[i] and showHeros[i]:boundingBox():containsPoint(point) then
                        audio.play(audio.button)
                        moveDown(i)
                        flag = true
                    end
                end
            end

            checkCondition()
            local pointOnLayer = showHeroLayer:convertToNodeSpace(ccp(x, y))
            if not kscroll:getContainer():boundingBox():containsPoint(pointOnLayer) and not flag then
                showHeroLayer:removeFromParentAndCleanup(true)
                kscroll = nil
            end

            return true
        end

        local function onExtraTouch(eventType, x, y)
            if eventType == "began" then
                return onTouchExtraBegin(x, y)        
            elseif eventType == "moved" then
                return onTouchExtraMoved(x, y)
            else
                return onTouchExtraEnd(x, y)
            end
        end
    
        showHeroLayer:registerScriptTouchHandler(onExtraTouch)
        showHeroLayer:setTouchEnabled(true)

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
            filterBg:addChild(btnGroupMenu, 10)
            btnGroupList[i]:setPosition(61, 52 + 70 * (i - 1))
            
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

                herolist = initHerolistData({ group = group , hids = hids})
                createHerolist()
                
                --kscroll:setContentSize(CCSizeMake(#herolist * 90 + 8, SCROLLVIEW_HEIGHT))
                kscroll:setContentOffset(CCPoint(0, 0))

                for i,v in ipairs(herolist) do
                    for j=1, 6 do
                        if v.hid == hids[j] then
                            onMoveUp(i, j, true)
                            herolist[i].isUsed = true
                        end
                    end
                end
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
    end

    offsetX = 480 - 50 * cfgtask[info.id].heroNum + 9
    for i=1, cfgtask[info.id].heroNum do
        local baseHeroBgSp = img.createUISprite(img.ui.herolist_head_bg)
        baseHeroBg[i] = HHMenuItem:createWithScale(baseHeroBgSp, 1)
        local menuHero = CCMenu:createWithItem(baseHeroBg[i])
        menuHero:setPosition(0, 0)
        showPowerBg:addChild(menuHero)
        baseHeroBg[i]:setAnchorPoint(ccp(0, 0))
        baseHeroBg[i]:setScale(84/94)
        baseHeroBg[i]:setPosition(offsetX + (i-1) * 100, 333)

        baseHeroBg[i]:registerScriptTapHandler(function()
            delayBtnEnable(baseHeroBg[i])
            audio.play(audio.button)
            createHeroList()
        end)
    
        local icon = img.createUISprite(img.ui.herotask_add_icon)
        icon:setPosition(baseHeroBg[i]:getContentSize().width/2, baseHeroBg[i]:getContentSize().height/2)
        baseHeroBg[i]:addChild(icon)
        icon:runAction(CCRepeatForever:create(CCSequence:createWithTwoActions(CCFadeIn:create(2), CCFadeOut:create(2))))
    end

    local btnBatchSprite = img.createLogin9Sprite(img.login.button_9_small_green)
    btnBatchSprite:setPreferredSize(CCSize(165, 50))
    local labBatch = lbl.createFont1(20, i18n.global.herotask_btn_batch.string, ccc3(0x1e, 0x63, 0x05))
    labBatch:setPosition(btnBatchSprite:getContentSize().width/2, btnBatchSprite:getContentSize().height/2)
    btnBatchSprite:addChild(labBatch)

    local btnBatch = SpineMenuItem:create(json.ui.button, btnBatchSprite)
    local menuBatch = CCMenu:createWithItem(btnBatch)
    menuBatch:setPosition(0, 0)
    showPowerBg:addChild(menuBatch)
    btnBatch:setPosition(480-92, 90)

    local btnStartSprite = img.createLogin9Sprite(img.login.button_9_small_gold)
    btnStartSprite:setPreferredSize(CCSize(165, 50))
    local labStart = lbl.createFont1(20, i18n.global.herotask_start_btn.string, ccc3(0x73, 0x3b, 0x05))
    labStart:setPosition(btnStartSprite:getContentSize().width/2, btnStartSprite:getContentSize().height/2)
    btnStartSprite:addChild(labStart)

    btnStart = SpineMenuItem:create(json.ui.button, btnStartSprite)
    local menuStart = CCMenu:createWithItem(btnStart)
    menuStart:setPosition(0, 0)
    showPowerBg:addChild(menuStart)
    btnStart:setPosition(480+92, 90)
    setShader(btnStart, SHADER_GRAY, true)

    local function backEvent()
        layer:removeFromParentAndCleanup()
    end

    -- close btn
    local close0 = img.createUISprite(img.ui.close)
    local closeBtn = SpineMenuItem:create(json.ui.button, close0)
    closeBtn:setPosition(CCPoint(814, 525))
    local closeMenu = CCMenu:createWithItem(closeBtn)
    closeMenu:setPosition(CCPoint(0, 0))
    showPowerBg:addChild(closeMenu)
    closeBtn:registerScriptTapHandler(function()     
        backEvent()
    end)

    function layer.onAndroidBack()
        backEvent()
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

    local function batchSet()
        local batchflag = true
        local herolist = clone(heros)
        table.sort(herolist, compareHero)
        --herolist = herolistless(herolist)
        for i, v in ipairs(herolist) do
            for _, taskInfo  in ipairs(htaskData.tasks) do
                if info.tid ~= taskInfo.tid and taskInfo.heroes then
                    for j, k in ipairs(taskInfo.heroes) do
                        if v.hid == k.hid then
                            herolist[i].isUsed = true
                        end
                    end
                end
            end
        end
        for i=1, heroNum do 
            if hids[i] and showHeros[i] then
                showHeros[i]:removeFromParentAndCleanup(true)
                showHeros[i] = nil 
                local tpos
                for t,v in ipairs(herolist) do
                    if hids[i] == v.hid then
                        tpos = t
                        break
                    end
                end
                herolist[tpos].isUsed = false
                hids[i] = nil
            end
        end
        --local batchhids = {}
        local res = {}
        for i, k in ipairs(info.conds) do
            res[i] = false
        end
        for i, k in ipairs(info.conds) do
            if not res[i] then
                for j = #herolist, 1 , -1 do
                    if not herolist[j].isUsed then 
                        if k.type == 1 then
                            if cfghero[herolist[j].id].job == k.faction then
                                res[i] = true
                                hids[#hids+1] = herolist[j].hid
                                herolist[j].isUsed = true
                                for ii = i+1, #info.conds do
                                    if info.conds[ii].type == 2 then
                                        if cfghero[herolist[j].id].qlt >= info.conds[ii].faction then
                                            res[ii] = true
                                        end
                                    end
                                    if info.conds[ii].type == 3 then
                                        if cfghero[herolist[j].id].group == info.conds[ii].faction then
                                            res[ii] = true
                                        end
                                    end
                                end
                                break
                            end
                        elseif k.type == 2 then 
                            if cfghero[herolist[j].id].qlt >= k.faction then
                                res[i] = true
                                hids[#hids+1] = herolist[j].hid
                                herolist[j].isUsed = true
                                for ii = i+1, #info.conds do
                                    if info.conds[ii].type == 1 then
                                        if cfghero[herolist[j].id].job == info.conds[ii].faction then
                                            res[ii] = true
                                        end
                                    end
                                    if info.conds[ii].type == 3 then
                                        if cfghero[herolist[j].id].group == info.conds[ii].faction then
                                            res[ii] = true
                                        end
                                    end
                                end
                                break
                            end
                        elseif k.type == 3 then 
                            if cfghero[herolist[j].id].group == k.faction then
                                res[i] = true
                                hids[#hids+1] = herolist[j].hid
                                herolist[j].isUsed = true
                                for ii = i+1, #info.conds do
                                    if info.conds[ii].type == 2 then
                                        if cfghero[herolist[j].id].qlt >= info.conds[ii].faction then
                                            res[ii] = true
                                        end
                                    end
                                    if info.conds[ii].type == 1 then
                                        if cfghero[herolist[j].id].job == info.conds[ii].faction then
                                            res[ii] = true
                                        end
                                    end
                                end
                                break
                            end
                        end
                    end
                end
            end
        end
        for i, k in ipairs(info.conds) do
            if res[i] == false then
                batchflag = false
                break
            end
        end
        --print("#hids= ", #hids, heroNum)
        if batchflag and #hids < heroNum then
            for i=#hids+1 , heroNum do
                for j = #herolist, 1, -1 do
                    if not herolist[j].isUsed then
                        hids[i] = herolist[j].hid
                        herolist[j].isUsed = true
                        break
                    end
                end
            end
        end
        checkCondition()
        --print("#hids= ", #hids, heroNum)
        if  checkConfirm == false then
            showToast(i18n.global.herotask_lack_mat.string)
        --    local herolist = clone(heros)
        --    table.sort(herolist, compareHero)
        --    herolist = herolistless(herolist)
        --    for i, v in ipairs(herolist) do
        --        for _, taskInfo  in ipairs(htaskData.tasks) do
        --            if info.tid ~= taskInfo.tid and taskInfo.heroes then
        --                for j, k in ipairs(taskInfo.heroes) do
        --                    if v.hid == k.hid then
        --                        herolist[i].isUsed = true
        --                    else
        --                        herolist[i].isUsed = false
        --                    end
        --                end
        --            end
        --        end
        --    end
        --    for i=1, heroNum do 
        --        if hids[i] and showHeros[i] then
        --            showHeros[i]:removeFromParentAndCleanup(true)
        --            showHeros[i] = nil 
        --            local tpos
        --            for t,v in ipairs(herolist) do
        --                if hids[i] == v.hid then
        --                    tpos = t
        --                    break
        --                end
        --            end
        --            herolist[tpos].isUsed = false
        --            hids[i] = nil
        --        end
        --    end
        --    checkCondition()
            --return
        end
        if #hids <= heroNum then
            for i=1,#hids do
                tpos = i
                local heroInfo = heros.find(hids[tpos])
                --showHeros[tpos] = img.createHeroHead(heroInfo.id, heroInfo.lv, true, 3, heroInfo.wake)
                local param = {
                    id = heroInfo.id,
                    lv = heroInfo.lv,
                    showGroup = true,
                    showStar = 3,
                    wake = heroInfo.wake,
                    orangeFx = nil,
                    petID = nil,
                    hskills = heroInfo.hskills,
hid = heroInfo.hid
                }
                showHeros[tpos] = img.createHeroHeadByParam(param)
                showHeros[tpos]:setScale(84/94)
                showHeros[tpos]:setPosition(baseHeroBg[tpos]:boundingBox():getMidX(), baseHeroBg[tpos]:boundingBox():getMidY())
                layer:addChild(showHeros[tpos])
            end
        end
    end

    btnBatch:registerScriptTapHandler(function()
        delayBtnEnable(btnBatch)
        audio.play(audio.button)
        batchSet()
    end)

    btnStart:registerScriptTapHandler(function()
        delayBtnEnable(btnStart)
        audio.play(audio.button)
        if not checkConfirm then
            print (tip)
            if not tip or tip == "" then tip = i18n.global.herotask_start_info.string end 
            showToast(tip)
            return
        end
        local heroNum = 0
        for i=1, #hids do
            if hids[i] then heroNum = heroNum + 1 end
        end
        if not checkConfirm or heroNum < cfgtask[info.id].heroNum then
            showToast(i18n.global.herotask_start_info.string)
            return
        end
        local params = {
            sid = player.sid,
            hids = hids,
            tid = info.tid,
        }
        
        tbl2string(params)

        addWaitNet()
        net:htask_start(params, function(__data)
            delWaitNet()

            tbl2string(__data)
             
            if __data.status ~= 0 then
                showToast("server status:" .. __data.status)
                return
            end
 
            info.subrefgem()
            info.cd = os.time() + cfgtask[info.id].questTime * 60
            --info.power = tonumber(showPower:getString())
            local heroes = {}
            for i, v in ipairs(params.hids) do
                local hero = heros.find(v)
                local h = {
                    hid = hero.hid,
                    id = hero.id,
                    lv = hero.lv,
                    star = hero.star,
                }
                heroes[#heroes + 1] = h
            end
            info.heroes = heroes
            for i, v in ipairs(htaskData.tasks) do
                if v.tid == info.tid then
                    layer:getParent().addAni(i)
                    layer:removeFromParentAndCleanup(true)
                    return 
                end
            end
        end)
    end)

    local lastx
    local function onTouchBegin(x, y)
        for i, v in ipairs(condition) do
            if v:boundingBox():containsPoint(layer:convertToNodeSpace(ccp(x, y))) then
                v.showTipBg:setVisible(true)
            else 
                v.showTipBg:setVisible(false)
            end
        end
        return true 
    end

    local function onTouchMoved(x, y)
        for i, v in ipairs(condition) do
            if v:boundingBox():containsPoint(layer:convertToNodeSpace(ccp(x, y))) then
                v.showTipBg:setVisible(true)
            else 
                v.showTipBg:setVisible(false)
            end
        end
        return true
    end

    local function onTouchEnd(x, y)
        for i, v in ipairs(condition) do
            v.showTipBg:setVisible(false)
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
    --layer:setTouchSwallowEnabled(false)


    return layer
end

return ui
