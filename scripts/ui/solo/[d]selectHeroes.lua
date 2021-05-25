
local ui = {}

require "common.func"
local view        = require "common.view"
local img         = require "res.img"
local lbl         = require "res.lbl"
local json        = require "res.json"
local i18n        = require "res.i18n"
local audio       = require "res.audio"
local net         = require "net.netClient"
local heros       = require "data.heros"
local userdata    = require "data.userdata"
local cfghero     = require "config.hero"
local bag         = require "data.bag"
local player      = require "data.player"
local hookdata    = require "data.hook"
local trialdata   = require "data.trial"
local arenaData   = require "data.arena"
local achieveData = require "data.achieve"
local petBattle   = require "ui.pet.petBattle"
local bagdata     = require "data.bag"
local cfgDrug    = require "config.spkdrug"

local function initHerolistData(params)
    local params = params or {}
    local tmpheros = clone(heros)
    
    local herolist = {}
    for i, v in ipairs(tmpheros) do
        if params.group then
            if cfghero[v.id].group == params.group then
                herolist[#herolist + 1] = v
            else
                for j=1, 5  do
                    if params.hids[j] == v.hid then
                        herolist[#herolist + 1] = v
                    end
                end
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

function ui.create(params)
    local layer = CCLayer:create()
    
    local darkbg = CCLayerColor:create(ccc4(0, 0, 0, 0))
    layer:addChild(darkbg)

    local board = img.createLogin9Sprite(img.login.dialog)
    board:setPreferredSize(CCSize(825, 370))
    board:setAnchorPoint(ccp(0.5, 0))
    board:setScale(view.minScale)
    board:setPosition(view.midX, view.midY + 34*view.minScale)
    layer:addChild(board)

    local btnCloseSprite = img.createUISprite(img.ui.close)
    local btnClose = SpineMenuItem:create(json.ui.button, btnCloseSprite)
    btnClose:setPosition(800, 340)
    local menuClose = CCMenu:createWithItem(btnClose)
    menuClose:setPosition(0, 0)
    board:addChild(menuClose)
    btnClose:registerScriptTapHandler(function()
        audio.play(audio.button)
        replaceScene(require("ui.town.main").create())
    end)

    layer.onAndroidBack = function ()
        -- audio.play(audio.button)
        replaceScene(require("ui.town.main").create())
    end
    addBackEvent(layer)

    local title = lbl.createFont1(26, i18n.global.solo_selectHero.string, ccc3(0xe6, 0xd0, 0xae))
    title:setPosition(413, 342)
    board:addChild(title, 1)

    local titleShade = lbl.createFont1(26, i18n.global.solo_selectHero.string, ccc3(0x59, 0x30, 0x1b))
    titleShade:setPosition(413, 340)
    board:addChild(titleShade)

    local heroCampBg = img.createUI9Sprite(img.ui.select_hero_camp_bg)
    heroCampBg:setPreferredSize(CCSize(770, 205))
    heroCampBg:setPosition(414, 190)
    board:addChild(heroCampBg, 1)

    local selectTeamBg = img.createUI9Sprite(img.ui.select_tab_tab_bg)
    selectTeamBg:setPreferredSize(CCSize(759, 37))
    selectTeamBg:setPosition(385, 179)
    heroCampBg:addChild(selectTeamBg)

    local showPowerBg = img.createUISprite(img.ui.select_hero_power_bg)
    showPowerBg:setAnchorPoint(ccp(0, 0.5))
    showPowerBg:setPosition(0, 19)
    selectTeamBg:addChild(showPowerBg)

    local powerIcon = img.createUISprite(img.ui.power_icon)
    powerIcon:setScale(0.46)
    powerIcon:setPosition(27, 21)
    showPowerBg:addChild(powerIcon)

    local showPower = lbl.createFont2(20, "0")
    showPower:setAnchorPoint(ccp(0, 0.5))
    showPower:setPosition(powerIcon:boundingBox():getMaxX() + 15, powerIcon:boundingBox():getMidY())
    showPowerBg:addChild(showPower)

    local posY = heroCampBg:getContentSize().height / 2 - 21
    local centerX = heroCampBg:getContentSize().width / 2
    local offsetX = 96

    local baseHeroBg = {}
    local showHeros = {}
    local hids = {}
    local headIcons = {}
    local herolist = initHerolistData()
    
    for i=1, 5 do
        baseHeroBg[i] = img.createUI9Sprite(img.ui.herolist_withouthero_bg)
        baseHeroBg[i]:setPreferredSize(CCSize(84, 84))
        baseHeroBg[i]:setPositionX((i - math.ceil(5 / 2)) * offsetX + centerX)
        baseHeroBg[i]:setPositionY(posY)
        heroCampBg:addChild(baseHeroBg[i])
    end

    -- 保存按钮
    ui.mainUI.modifyBufShow()

    local saveImg = img.createLogin9Sprite(img.login.button_9_small_gold)
    saveImg:setPreferredSize(CCSize(216, 54))
    local saveLabel = lbl.createFont1(20, i18n.global.solo_save.string, ccc3(0x73, 0x3b, 0x05)) 
    saveLabel:setPosition(saveImg:getContentSize().width/2, saveImg:getContentSize().height/2)
    saveImg:addChild(saveLabel)
    local saveBtn = SpineMenuItem:create(json.ui.button, saveImg)
    saveBtn:setPosition(board:getContentSize().width / 2, 50)
    local saveMenu = CCMenu:createWithItem(saveBtn)
    saveMenu:setPosition(0, 0)
    board:addChild(saveMenu, 1)
    saveBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        local heroHids = {}
        for i=1,5 do
            if hids[i] ~= nil then
                -- 添加请求
                for j=1,5 do
                    if hids[j] ~= nil then
                        table.insert(heroHids,1,hids[j])
                    end
                end
                break
                -- -- 保存出战数据以及波次数据并刷新界面
                -- local soloData   = require("data.solo")
                -- local cfgSpkWave = require "config.spkwave"
                -- local bossArr  = cfgSpkWave[1].trial
                -- local ehpp     = {}
                -- for i=1,#bossArr do
                --     ehpp[i] = 100
                -- end
                -- soloData.setStage(1)
                -- soloData.heroList = ui.getHeroList(hids)
                -- tablePrint(soloData.heroList)
                -- soloData.bossList = soloData.convertBossInfo(ehpp)
                -- layer:getParent().mainUI.initHandle()
                -- --ui.setHeroList(hids,layer:getParent().mainUI)
                -- layer:removeFromParent()
                -- return
            end
        end
        if #heroHids > 0 then
            local soloData = require("data.solo")
            addWaitNet()
            local params = {sid = player.sid, hids = heroHids}
            print("选人申请数据")
            tablePrint(params)
            net:spk_camp(params,function (data)
                delWaitNet()
                print("选人返回数据")
                tablePrint(data)
                if data.status == 0 then
                    soloData.reddot = 0
                    local cfgSpkWave = require "config.spkwave"
                    local bossArr  = cfgSpkWave[1].trial
                    local ehpp     = {}
                    for i=1,#bossArr do
                        ehpp[i] = 100
                    end  
                    data.bufs = data.bufs or {}
                    data.reward = data.reward or {}
                    soloData.setStage(data.nstage)
                    soloData.setWave(data.wave or 1)
                    soloData.heroList = ui.getHeroList(hids)
                    soloData.bossList = soloData.convertBossInfo(ehpp)
                    soloData.traderList = data.sellers or {}
                    soloData.power      = soloData.getDrugNum(data.bufs,"power")
                    soloData.crit       = soloData.getDrugNum(data.bufs,"crit")
                    soloData.speed      = soloData.getDrugNum(data.bufs,"speed")
                    soloData.milk       = soloData.getDrugList(data.bufs,"milk")
                    soloData.angel      = soloData.getDrugList(data.bufs,"angel")
                    soloData.evil       = soloData.getDrugList(data.bufs,"evil")
                    soloData.level      = soloData.getStageLevel()
                    print("aaa " .. soloData.power .. "," .. soloData.crit .. "," ..soloData.speed )
                    for i,v in ipairs(soloData.heroList) do
                        v.power = soloData.power
                        v.speed = soloData.speed
                        v.crit = soloData.crit
                    end
                    bagdata.items.addAll(data.reward.items)
                    bagdata.equips.addAll(data.reward.equips)

                    local rewards = {}
                    local items = data.reward ~= nil and data.reward.items or {}
                    local equips = data.reward ~= nil and data.reward.equips or {}
                    local bufs = data.bufs or {}
                    for i,v in ipairs(items) do
                        local item = {}
                        item.type = 1
                        item.id = v.id
                        item.num = v.num
                        table.insert(rewards,item)

                        -- 金币
                        -- 钻石
                        -- 英雄进阶
                        -- 恶魔之魂
                        -- 混沌碎片
                        -- local division = {[1]  = {mid = 40000, delta = 10000},  
                        --                   [2]  = {mid = 10, delta = 3},
                        --                   [11] = {mid = 50, delta = 10},
                        --                   [40] = {mid = 30, delta = 5},
                        --                   [41] = {mid = 15, delta = 3},
                        --                  }

                        -- local totalNum = v.num
                        -- local info = division[v.id]
                        -- while totalNum > 0 do
                        --     local randNum = math.random(-1 * info.delta,info.delta)
                        --     local item = {}
                        --     item.type = 1
                        --     item.id = v.id
                        --     item.num = totalNum > info.mid and info.mid + randNum or totalNum
                        --     totalNum = totalNum - item.num
                        --     table.insert(rewards,item)
                        -- end
                    end
                    for i,v in ipairs(equips) do
                        local item = {}
                        item.type = 2
                        item.id = v.id
                        item.num = v.num
                        table.insert(rewards,item)
                    end
                    print("------- ")
                    tablePrint(bufs)
                    local bufList = {}
                    for i,v in ipairs(bufs) do
                        -- for j=1,v.num do
                        --     local item = {}
                        --     item.type = 3
                        --     item.id = v.id
                        --     item.num = 1
                        --     table.insert(rewards,item)
                        -- end
                        if bufList[cfgDrug[v.id].iconId] then
                            bufList[cfgDrug[v.id].iconId].num = bufList[cfgDrug[v.id].iconId].num + v.num
                        else
                            bufList[cfgDrug[v.id].iconId] = {}
                            bufList[cfgDrug[v.id].iconId].id = v.id
                            bufList[cfgDrug[v.id].iconId].num = v.num
                        end
                    end
                    for k,v in pairs(bufList) do
                        local item = {}
                        item.type = 3
                        item.id = v.id
                        item.num = v.num
                        table.insert(rewards,item)
                    end

                    -- for i=1,math.ceil(#rewards / 2) do
                    --     local rand1 = math.random(1, #rewards)
                    --     local rand2 = math.random(1, #rewards)
                    --     rewards[rand1],rewards[rand2] = rewards[rand2],rewards[rand1]
                    -- end

                    local parentLayer = layer:getParent().mainUI
                    local callfunc = function() 
                        parentLayer.initHandle()
                        parentLayer.modifyBufShow()
                        parentLayer.playSweepAnimation()
                    end
                    if #rewards > 0 then
                        -- 扫荡骨骼动画
                        local darkLayer = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
                        parentLayer.widget.layer:addChild(darkLayer,99999)
                        local spineNode = json.create(json.ui.solo_sweep)
                        spineNode:setScale(view.minScale)
                        spineNode:setPosition(view.midX, view.midY)
                        spineNode:playAnimation("animation")
                        parentLayer.widget.layer:addChild(spineNode,99999)
                        local sweepLabel = lbl.createFont2(22, i18n.global.solo_sweep_finish.string, ccc3(255, 225, 107))
                        sweepLabel:setAnchorPoint(0.5,1)
                        spineNode:addChildFollowSlot("code_text", sweepLabel)
                        sweepLabel:setPositionY(sweepLabel:getPositionY() + 3)

                        -- local lang = i18n.getCurrentLanguage()
                        -- if lang == kLanguageChinese then
                        --     spineNode:playAnimation("animation2")
                        -- else
                        --     spineNode:playAnimation("animation")
                        -- end
                        parentLayer.createSwallowLayer(1.6,99999)
                        local delay = CCDelayTime:create(1.6)
                        local callfunc = CCCallFunc:create(function()
                            darkLayer:removeFromParent()
                            spineNode:removeFromParent()
                            local sweepUI = require("ui.solo.sweepUI").create(rewards,parentLayer,callfunc)
                            parentLayer.widget.layer:addChild(sweepUI,99999)
                        end)
                        parentLayer.widget.layer:runAction(CCSequence:createWithTwoActions(delay,callfunc))
                    else
                        layer:getParent().mainUI.initHandle()
                    end
                    layer:removeFromParent()
                    return
                end
            end)
        else
            showToast(i18n.global.toast_selhero_needhero.string)
        end
    end)
    
    local herolistBg = img.createUI9Sprite(img.ui.tips_bg)
    herolistBg:setPreferredSize(CCSize(957, 112))
    herolistBg:setScale(view.minScale)
    herolistBg:setAnchorPoint(ccp(0.5, 1))
    herolistBg:setPosition(view.midX, view.minY + 0 * view.minScale)
    layer:addChild(herolistBg)

    SCROLLVIEW_WIDTH = 943 - 150
    SCROLLVIEW_HEIGHT = 112
    SCROLLCONTENT_WIDTH = #herolist * 90 + 8

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
    filterBg:setPreferredSize(CCSize(122, 458))
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
        local iconBgBatch1 = img.createBatchNodeForUI(img.ui.hero_star_ten_bg)
        showHeroLayer:addChild(iconBgBatch1, 1)
        local groupBgBatch = img.createBatchNodeForUI(img.ui.herolist_group_bg)
        showHeroLayer:addChild(groupBgBatch , 3)
        local starBatch = img.createBatchNodeForUI(img.ui.star_s)
        showHeroLayer:addChild(starBatch, 3)
        local star1Batch = img.createBatchNodeForUI(img.ui.hero_star_orange)
        showHeroLayer:addChild(star1Batch, 3)
        local star10Batch = img.createBatchNodeForUI(img.ui.hero_star_ten)
        showHeroLayer:addChild(star10Batch, 3)
        blackBatch = CCNode:create()
        showHeroLayer:addChild(blackBatch, 4)
        selectBatch = img.createBatchNodeForUI(img.ui.hook_btn_sel)
        showHeroLayer:addChild(selectBatch, 5)

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
                showHeroLayer:addChild(aniten, 3)
            else
                heroBg = img.createUISprite(img.ui.herolist_head_bg)
                heroBg:setScale(0.92)
                heroBg:setPosition(x, y)
                iconBgBatch:addChild(heroBg)
            end

            --headIcons[i] = img.createHeroHeadIcon(herolist[i].id)
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
            --        starIcon2:setPosition(x, y-30)
            --        star10Batch:addChild(starIcon2)
            --    else
            --        for i = redstar, 1, -1 do
            --            local star = img.createUISprite(img.ui.hero_star_orange)
            --            star:setScale(0.92*0.75)
            --            star:setPosition(x + (i-(redstar+1)/2)*12*0.8, y - 30)
            --            star1Batch:addChild(star)
            --        end
            --    end
            --end
        end
    end

    --local iconBuff
    --local iconTips 
    local function checkUpdate()
        local power = 0
        local sk = 0
        for i=1, 5 do 
            if hids[i] and hids[i] > 0 and heros.find(hids[i]) then
                power = power + heros.power(hids[i])
                local heroData = heros.find(hids[i])
                if bit.band(sk, bit.blshift(1, cfghero[heroData.id].group - 1)) == 0 then
                    sk = sk + bit.blshift(1, cfghero[heroData.id].group - 1)
                end
            end
        end

        showPower:setString(power)
        
        local heroids = {}
        for i=1, 5 do 
            heroids[i] = nil
            if heros.find(hids[i]) ~= nil then
                heroids[i] = heros.find(hids[i]).id
            end
        end
 
        local showIcon = require("ui.selecthero.campLayer").checkUpdateForHeroids(heroids,true)

        if showIcon ~= -1 then
            campWidget.icon[showIcon]:setVisible(true)
        end
    end

    local function onMoveUp(pos, tpos, isNotCallBack)
        checkUpdate()
        if not isNotCallBack then
            local heroInfo = heros.find(hids[tpos])
            --showHeros[tpos] = img.createHeroHead(heroInfo.id, heroInfo.lv, true, 3, heroInfo.wake,nil)
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
            showHeros[tpos]:setScale(86/94)
            showHeros[tpos]:setPositionX((tpos - math.ceil(5 / 2)) * offsetX + centerX)
            showHeros[tpos]:setPositionY(posY)
            heroCampBg:addChild(showHeros[tpos])
        end

        local blackBoard = CCLayerColor:create(ccc4(0, 0, 0, 120))
        blackBoard:setContentSize(CCSize(84, 84))
        blackBoard:setPosition(headIcons[pos]:getPositionX() - 42, headIcons[pos]:getPositionY() - 42)
        blackBatch:addChild(blackBoard, 0, pos)

        local selectIcon = img.createUISprite(img.ui.hook_btn_sel)
        selectIcon:setPosition(headIcons[pos]:getPositionX(), headIcons[pos]:getPositionY())
        selectBatch:addChild(selectIcon, 0, pos)
    end

    local function moveUp(pos)
        if ui.mianUI ~= nil then
            print("真的不为空")
        end
        local tpos
        for i=1, 5 do
            if not hids[i] or hids[i] == 0 then
                tpos = i
                break
            end
        end

        if tpos and not herolist[pos].isUsed then
            herolist[pos].isUsed = true
            hids[tpos] = herolist[pos].hid
            
            local worldbpos = scroll:getContainer():convertToWorldSpace(ccp(headIcons[pos]:getPositionX(), headIcons[pos]:getPositionY()))
            local realbpos = board:convertToNodeSpace(worldbpos)
            local worldepos = heroCampBg:convertToWorldSpace(ccp(baseHeroBg[tpos]:getPositionX(), baseHeroBg[tpos]:getPositionY()))
            local realepos = board:convertToNodeSpace(worldepos)
            --local tempHero = img.createHeroHead(herolist[pos].id, herolist[pos].lv, true, nil , nil ,nil )
            local param = {
                id = herolist[pos].id,
                lv = herolist[pos].lv,
                showGroup = true,
                showStar = nil,
                wake = nil,
                orangeFx = nil,
                petID = nil,
                hskills = herolist[pos].hskills,
                hid = herolist[pos].hid
            }
            local tempHero = img.createHeroHeadByParam(param)
            tempHero:setScale(0.92)
            tempHero:setPosition(realbpos)
            board:addChild(tempHero, 100)
            
            local arr = CCArray:create()
            arr:addObject(CCMoveTo:create(0.1, realepos))
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
        checkUpdate()
        blackBatch:removeChildByTag(tpos)
        selectBatch:removeChildByTag(tpos)
    end

    local function moveDown(pos)
        local tpos
        for i, v in ipairs(herolist) do
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
            
            local worldbpos = heroCampBg:convertToWorldSpace(ccp(baseHeroBg[pos]:getPositionX(), baseHeroBg[pos]:getPositionY()))
            local realbpos = board:convertToNodeSpace(worldbpos)
            local worldepos = scroll:getContainer():convertToWorldSpace(ccp(headIcons[tpos]:getPositionX(), headIcons[tpos]:getPositionY()))
            local realepos = board:convertToNodeSpace(worldepos)
            --local tempHero = img.createHeroHead(herolist[tpos].id, herolist[tpos].lv, true, nil , nil ,nil )
            local param = {
                id = herolist[tpos].id,
                lv = herolist[tpos].lv,
                showGroup = true,
                showStar = nil,
                wake = nil,
                orangeFx = nil,
                petID = nil,
                hskills = herolist[tpos].hskills,
                hid = herolist[tpos].hid
            }
            local tempHero = img.createHeroHeadByParam(param)
            tempHero:setPosition(realbpos)
            tempHero:setScale(0.92)
            board:addChild(tempHero, 100)
            
            local arr = CCArray:create()
            arr:addObject(CCMoveTo:create(0.1, realepos))
            local act1 = CCSpawn:create(arr)
            tempHero:runAction(CCSequence:createWithTwoActions(act1, CCCallFunc:create(function() 
                tempHero:removeFromParentAndCleanup(true)
                onMoveDown(pos, tpos)
            end)))
        end
    end

    local lastx
    local preSelect
    local function onTouchBegin(x, y)
        local point = heroCampBg:convertToNodeSpace(ccp(x, y))
        preSelect = nil
        lastx = x
        
        for i=1, 5 do
            if hids[i] and showHeros[i] and showHeros[i]:boundingBox():containsPoint(point) then
                preSelect = i
            end
        end
        
        return true 
    end

    local function onTouchMoved(x, y)
        local point = heroCampBg:convertToNodeSpace(ccp(x, y))

        if preSelect and math.abs(x - lastx) >= 10 then
            showHeros[preSelect]:setPosition(point)
            showHeros[preSelect]:setZOrder(1)
        end
        
        return true
    end

    local function onTouchEnd(x, y)
        if not scroll or tolua.isnull(scroll) then
            return
        end

        local point = heroCampBg:convertToNodeSpace(ccp(x, y))
        local pointOnScroll = scroll:getContainer():convertToNodeSpace(ccp(x, y))

        if math.abs(x - lastx) < 10 then
            for i,v in ipairs(headIcons) do
                if v:boundingBox():containsPoint(pointOnScroll) then
                    audio.play(audio.button)
                    moveUp(i)
                end
            end

            for i=1,5 do 
                if hids[i] and showHeros[i] and showHeros[i]:boundingBox():containsPoint(point) then
                    audio.play(audio.button)
                    moveDown(i)
                end
            end
        end
 
        if not preSelect or math.abs(x - lastx) < 10 then
            return true
        end

        local ifset = false
        for i=1, 5 do
            if baseHeroBg[i]:boundingBox():containsPoint(point) then
                if math.abs(showHeros[preSelect]:getPositionX() - baseHeroBg[i]:getPositionX()) < 33
                    and math.abs(showHeros[preSelect]:getPositionY() - baseHeroBg[i]:getPositionY()) < 33 then
                    ifset = true
                    showHeros[preSelect]:setZOrder(0)
                    showHeros[preSelect]:setPosition(baseHeroBg[i]:getPosition())
                    if hids[i] and showHeros[i] then
                        showHeros[i]:setPosition(baseHeroBg[preSelect]:getPosition())
                    end
                    showHeros[preSelect], showHeros[i] = showHeros[i], showHeros[preSelect]
                    hids[preSelect], hids[i] = hids[i], hids[preSelect]
                end
            end
        end      
       
        if ifset == false then
            showHeros[preSelect]:setPosition(baseHeroBg[preSelect]:getPosition())
            showHeros[preSelect]:setZOrder(0)
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

    layer.showHint = function ()
        if 1 then
            local bubble = img.createUI9Sprite(img.ui.tutorial_bubble)
            local bubbleMinWidth, bubbleMinHeight = 208, 82
            bubble:setScale(view.minScale)
            bubble:setAnchorPoint(ccp(0.5, 0))
            bubble:setPosition(scalep(215, 430))
            layer:addChild(bubble)
            -- text
            local label = lbl.createMix({
                font = 1, size = 16, text = i18n.global.tutorial_text_new_hit_1.string,
                color = ccc3(0x72, 0x48, 0x35), width = 350
            })
            local labelSize = label:boundingBox().size
            label:setAnchorPoint(ccp(0.5, 0.5))
            bubble:addChild(label)
            -- 大小调整
            local bubbleWidth = labelSize.width + 20
            if bubbleWidth < bubbleMinWidth then
                bubbleWidth = bubbleMinWidth
            end
            local bubbleHeight = labelSize.height + 5
            if bubbleHeight < bubbleMinHeight then
                bubbleHeight = bubbleMinHeight
            end
            bubble:setPreferredSize(CCSize(bubbleWidth, bubbleHeight))
            label:setPosition(bubbleWidth / 2, bubbleHeight / 2)

            local bubbleArrow = img.createUISprite(img.ui.tutorial_bubble_arrow)
            bubbleArrow:setRotation(-90)
            bubbleArrow:setPosition(bubbleWidth / 2, -6)
            bubble:addChild(bubbleArrow)

            bubble:setVisible(false)
            bubble:runAction(createSequence({
                CCDelayTime:create(0.4),
                CCShow:create(),
            }))
        end

        if 2 then
            local bubble = img.createUI9Sprite(img.ui.tutorial_bubble)
            local bubbleMinWidth, bubbleMinHeight = 208, 82
            bubble:setScale(view.minScale)
            bubble:setAnchorPoint(ccp(0.5, 1))
            bubble:setPosition(scalep(514, 280))
            layer:addChild(bubble)
            -- text
            local label = lbl.createMix({
                font = 1, size = 16, text = i18n.global.tutorial_text_new_hit_2.string,
                color = ccc3(0x72, 0x48, 0x35), width = 450
            })
            local labelSize = label:boundingBox().size
            label:setAnchorPoint(ccp(0.5, 0.5))
            bubble:addChild(label)
            -- 大小调整
            local bubbleWidth = labelSize.width + 20
            if bubbleWidth < bubbleMinWidth then
                bubbleWidth = bubbleMinWidth
            end
            local bubbleHeight = labelSize.height + 5
            if bubbleHeight < bubbleMinHeight then
                bubbleHeight = bubbleMinHeight
            end
            bubble:setPreferredSize(CCSize(bubbleWidth, bubbleHeight))
            label:setPosition(bubbleWidth / 2, bubbleHeight / 2)

            local bubbleArrow = img.createUISprite(img.ui.tutorial_bubble_arrow)
            bubbleArrow:setRotation(90)
            bubbleArrow:setPosition(bubbleWidth / 2, bubbleHeight + 6)
            bubble:addChild(bubbleArrow)

            bubble:setVisible(false)
            bubble:runAction(createSequence({
                CCDelayTime:create(0.8),
                CCShow:create(),
            }))
        end
    end

    -- if params.type == "pve" then--新手引导小提示
    --     local hookdata = require("data.hook")
    --     local pveStage = hookdata.getPveStageId()
    --     local stageId = 10
    --     if pveStage >= 3 and pveStage <= stageId then
    --         layer.showHint()
    --     end
    -- end

    createHerolist()

    local function onEnter()
    
    end

    local function onExit()

    end

    layer:registerScriptHandler(function(event)
        if event == "enter" then
            onEnter()
        elseif event == "exit" then

        end
    end)
    
    local anim_duration = 0.2
    board:setPosition(CCPoint(view.midX, view.minY+576*view.minScale))
    board:runAction(CCMoveTo:create(anim_duration, CCPoint(view.midX, view.minY+150*view.minScale)))
    herolistBg:runAction(CCMoveTo:create(anim_duration, CCPoint(view.midX, view.minY+123*view.minScale)))
    darkbg:runAction(CCFadeTo:create(anim_duration, POPUP_DARK_OPACITY))

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

            for i,v in ipairs(herolist) do
                for j=1, 5 do
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

    require("ui.tutorial").show("ui.selected.pve", layer)

    return layer
end

-- 获取出战队列
function ui.getHeroList(hids)
    local list = {}
    for i=1,5 do
        if hids[i] ~= nil then
            local heroInfo = heros.find(hids[i])
            heroInfo.group = cfghero[heroInfo.id].group
            heroInfo.qlt   = cfghero[heroInfo.id].qlt
            heroInfo.hp    = 100
            heroInfo.mp    = heroInfo.energy or 50
            heroInfo.power = 0
            heroInfo.speed = 0
            heroInfo.crit  = 0
            heroInfo.pos   = 1
            heroInfo.skin  = getHeroSkin(hids[i])
            table.insert(list,heroInfo)
        end
    end
    return list
end

-- 传递出战队列
function ui.setHeroList(hids,mainUI)
    local list = {}
    for i=1,5 do
        if hids[i] ~= nil then
            local heroInfo = heros.find(hids[i])
            heroInfo.group = cfghero[heroInfo.id].group
            heroInfo.qlt   = cfghero[heroInfo.id].qlt
            heroInfo.hp    = 100
            heroInfo.mp    = 100
            heroInfo.power = 0
            heroInfo.speed = 0
            heroInfo.crit  = 0
            table.insert(list,heroInfo)
        end
    end
    print("开始打印表")
    tablePrint(list)
    mainUI.setHeroList(list)
    return list
end

-- 设置下一波对应波次表的ID
function ui.setStage(stage,mainUI)
    mainUI.setStage(stage)
end

return ui
