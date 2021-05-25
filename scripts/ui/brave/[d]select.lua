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
local userdata = require "data.userdata"
local cfghero = require "config.hero"
local bag = require "data.bag"
local player = require "data.player"
local databrave = require "data.brave"
local cfgbrave = require "config.brave"
local petBattle = require "ui.pet.petBattle"
local ccamp = require "fight.helper.ccamp"

local function initHerolistData(params)
    local herolist = {}
    for i, v in ipairs(heros) do
        if v.lv >= 40 then
            herolist[#herolist + 1] = clone(v)
        end
    end

    for i, v in ipairs(herolist) do
        v.isUsed = false
        v.hpp = 100
        for j, k in ipairs(databrave.heros) do
            if v.hid == k.hid then
                v.hpp = k.hpp
            end
        end
    end

    table.sort(herolist, compareHero)

    local whitelist = userdata.getSquadBrave()
    local tlist = herolistless(herolist, whitelist)
    return tlist
end

local function onHadleBattle(content)
    if #content.hids <= 0 then
        showToast(i18n.global.toast_selhero_needhero.string)
        return
    end
    
    local params = {
        sid = player.sid,
        camp = content.hids,
    }

    print("远征的宠物防守整容数据-------begin")
    petBattle.addPetData(content.hids)
    print("远征的宠物防守整容数据-------end")
    
    tbl2string(params)
    addWaitNet()
    net:brave_fight(params, function(__data)
        delWaitNet()

        if __data.status < 0 then
            if __data.status == -1 then
                showToast(i18n.global.toast_brave_close.string)
            else
                showToast("status:" .. __data.status)
            end
            return 
        end
    
        local video = clone(__data)
        video.map = cfgbrave[databrave.id].mapId[databrave.stage]
        video.reward = content.reward
        
        video.atk = {}
        video.atk.camp = video.pself.camp
        video.atk.name = player.name
        video.atk.lv = player.lv()
        video.atk.logo = player.logo

        video.def = clone(databrave.enemys[databrave.stage])
        video.def.camp = video.penemy.camp
        if video.rewards and video.select then
            bag.addRewards(video.rewards[video.select])
        end

        -- update hp
        for i, v in ipairs(video.mhpp) do
            local isFind = false
            for j, k in ipairs(databrave.heros) do
                if k.hid == v.hid then
                    k.hpp = v.hpp
                    isFind = true
					break
                end
            end
            if not isFind then
                databrave.heros[#databrave.heros + 1] = {
                    hid = v.hid,
                    hpp = v.hpp,
                }
            end
        end
        for i, v in ipairs(databrave.enemys[databrave.stage].camp) do
            for j, k in ipairs(video.ehpp) do
                if v.pos == k.pos then
                    v.hpp = k.hpp
                end
            end
        end
        --
        if video.win == true then
            databrave.stage = databrave.stage + 1
            local achieveData = require "data.achieve"
            if achieveData.achieveInfos[ACHIEVE_TYPE_BRAVE].num+1 < databrave.stage then 
                achieveData.add(ACHIEVE_TYPE_BRAVE, 1) 
            end
            databrave.enemys[databrave.stage] = video.enemy

            for i, v in ipairs(video.reward) do
                if v.type == 1 then
                    bag.items.add({ id = v.id, num = v.num })
                else
                    bag.equips.add({ id = v.id, num = v.num })
                end
            end
        end
		
		ccamp.processCamp(video, nil, 2)
        
        tbl2string(video)
        replaceScene(require("fight.brave.loading").create(video))
    end)
end

function ui.create(params)
    local params = params or {}
    local layer = CCLayer:create()
    
    local darkbg = CCLayerColor:create(ccc4(0, 0, 0, 0))
    layer:addChild(darkbg)

    local board = img.createLogin9Sprite(img.login.dialog)
    board:setPreferredSize(CCSize(825, 410))
    board:setAnchorPoint(ccp(0.5, 0))
    board:setScale(view.minScale)
    board:setPosition(view.midX, view.midY + 34*view.minScale)
    layer:addChild(board)

    local btnCloseSprite = img.createUISprite(img.ui.close)
    local btnClose = SpineMenuItem:create(json.ui.button, btnCloseSprite)
    btnClose:setPosition(800, 385)
    local menuClose = CCMenu:createWithItem(btnClose)
    menuClose:setPosition(0, 0)
    board:addChild(menuClose)
    btnClose:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer:removeFromParentAndCleanup(true)
    end)

    local title = lbl.createFont1(26, i18n.global.select_hero_title.string, ccc3(0xe6, 0xd0, 0xae))
    title:setPosition(413, 382)
    board:addChild(title, 1)

    local titleShade = lbl.createFont1(26, i18n.global.select_hero_title.string, ccc3(0x59, 0x30, 0x1b))
    titleShade:setPosition(413, 380)
    board:addChild(titleShade)

    local heroCampBg = img.createUI9Sprite(img.ui.select_hero_camp_bg)
    heroCampBg:setPreferredSize(CCSize(770, 205))
    heroCampBg:setPosition(414, 240)
    board:addChild(heroCampBg, 1)

    local heroSkillBg = img.createUI9Sprite(img.ui.select_hero_buff_bg)
    heroSkillBg:setPreferredSize(CCSize(769, 76))
    heroSkillBg:setPosition(414, 85)
    board:addChild(heroSkillBg)

    --加入阵营layer
    local campWidget = require("ui.selecthero.campLayer").create()
    board:addChild(campWidget.layer,20)
    campWidget.layer:setPosition(CCPoint(11,35))

    --[[
    local btnDetailSprite = img.createUISprite(img.ui.btn_detail)
    local btnDetail = SpineMenuItem:create(json.ui.button, btnDetailSprite)
    btnDetail:setPosition(730, 38)
    local menuDetail = CCMenu:createWithItem(btnDetail)
    menuDetail:setPosition(0, 0)
    heroSkillBg:addChild(menuDetail)
    btnDetail:registerScriptTapHandler(function()
        disableObjAWhile(btnDetail)
        audio.play(audio.button)
        layer:addChild(require("ui.selecthero.camp").create(), 1000)
    end)]]

    local btnBattleSprite = img.createLogin9Sprite(img.login.button_9_small_gold)
    btnBattleSprite:setPreferredSize(CCSize(110, 78))
    local btnBattleIcon = img.createUISprite(img.ui.select_hero_btn_icon)
    btnBattleIcon:setPosition(btnBattleSprite:getContentSize().width/2, btnBattleSprite:getContentSize().height/2)
    btnBattleSprite:addChild(btnBattleIcon)

    local btnBattle = SpineMenuItem:create(json.ui.button, btnBattleSprite)
    btnBattle:setPosition(708, 211)
    local menuBattle = CCMenu:createWithItem(btnBattle)
    menuBattle:setPosition(0, 0)
    board:addChild(menuBattle, 1)

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

    local labFront = lbl.createFont1(18, i18n.global.select_hero_front.string, ccc3(0x4e, 0x30, 0x18))
    labFront:setAnchorPoint(ccp(0.5, 0.5))
    labFront:setPosition(122, 135)
    heroCampBg:addChild(labFront)

    local labBehind = lbl.createFont1(18, i18n.global.select_hero_behind.string, ccc3(0x4e, 0x30, 0x18))
    labBehind:setAnchorPoint(ccp(0.5, 0.5))
    labBehind:setPosition(415, 135)
    heroCampBg:addChild(labBehind)

    local POSX = {
        78, 168, 281, 371, 461, 551
    }
    local baseHeroBg = {}
    local baseHeroHp = {}
    local showHeros = {}
    local hids = {}
    local headIcons = {}
    local herolist = initHerolistData()
    
    for i=1, 6 do
        baseHeroBg[i] = img.createUI9Sprite(img.ui.herolist_withouthero_bg)
        baseHeroBg[i]:setPreferredSize(CCSize(84, 84))
        baseHeroBg[i]:setPosition(POSX[i], 74)
        heroCampBg:addChild(baseHeroBg[i])

        local showHpBg = img.createUISprite(img.ui.fight_hp_bg.small)
        showHpBg:setPosition(baseHeroBg[i]:boundingBox():getMidX(), baseHeroBg[i]:boundingBox():getMinY() - 13)
        heroCampBg:addChild(showHpBg)
    
        local showHpFgSp = img.createUISprite(img.ui.fight_hp_fg.small)
        baseHeroHp[i] = createProgressBar(showHpFgSp)
        baseHeroHp[i]:setPosition(showHpBg:getContentSize().width/2, showHpBg:getContentSize().height/2)
        baseHeroHp[i]:setPercentage(0)
        showHpBg:addChild(baseHeroHp[i])
    end

    local function loadHeroCamps(camps)
        for i=1, 6 do
            if hids[i] and hids[i] > 0 then
                local heroInfo = heros.find(hids[i])
                if heroInfo then
                    --showHeros[i] = img.createHeroHead(heroInfo.id, heroInfo.lv, true, 3, heroInfo.wake,nil,petBattle.getNowSele())
                    local param = {
                        id = heroInfo.id,
                        lv = heroInfo.lv,
                        showGroup = true,
                        showStar = 3,
                        wake = heroInfo.wake,
                        orangeFx = nil,
                        petID = petBattle.getNowSele(),
                        hskills = heroInfo.hskills,
						hid = heroInfo.hid
                    }
                    showHeros[i] = img.createHeroHeadByParam(param)
                    showHeros[i]:setScale(84/94)
                    showHeros[i]:setPosition(POSX[i], 74)
                    heroCampBg:addChild(showHeros[i])
                else
                    hids[i] = 0
                end
            end
        end
    end

    --宠物界面退出回调
    local function petCallBack()
        for k,v in pairs(showHeros) do
            v:removeFromParent()
        end
        showHeros = {}
        loadHeroCamps(hids)
    end
    --宠物按钮
    local spPet = img.createLogin9Sprite(img.login.button_9_small_purple)
    spPet:setPreferredSize(CCSizeMake(150, 45))
    local spIcon = img.createUISprite(img.ui.pet_leg)
    spPet:addChild(spIcon)
    local btnLal = lbl.createFont1(16, i18n.global.pet_battle_btn_lal.string, ccc3(0x5c, 0x19, 0x8e))
    spPet:addChild(btnLal)

    local btnPet = SpineMenuItem:create(json.ui.button, spPet)
    require("dhcomponents.DroidhangComponents"):mandateNode(btnPet,"yw_petBattle_btnPet")
    require("dhcomponents.DroidhangComponents"):mandateNode(spIcon,"yw_petBattle_spIcon")
    require("dhcomponents.DroidhangComponents"):mandateNode(btnLal,"yw_petBattle_btnLal")

    local menuPet = CCMenu:createWithItem(btnPet)
    menuPet:setPosition(0, 0)
    selectTeamBg:addChild(menuPet,1)
    btnPet:registerScriptTapHandler(function()
        btnPet:setEnabled(false)
        disableObjAWhile(btnPet)
        audio.play(audio.button)
        require("ui.pet.petBattle").create(layer, petCallBack)
    end)

    
    local herolistBg = img.createUI9Sprite(img.ui.tips_bg)
    herolistBg:setPreferredSize(CCSize(957, 118))
    herolistBg:setScale(view.minScale)
    herolistBg:setAnchorPoint(ccp(0.5, 1))
    herolistBg:setPosition(view.midX, view.minY + 0 * view.minScale)
    layer:addChild(herolistBg)

    SCROLLVIEW_WIDTH = 943
    SCROLLVIEW_HEIGHT = 118
    SCROLLCONTENT_WIDTH = #herolist * 90 + 8

    local scroll = CCScrollView:create()
    scroll:setDirection(kCCScrollViewDirectionHorizontal)
    scroll:setAnchorPoint(ccp(0, 0))
    scroll:setPosition(7, 0)
    scroll:setViewSize(CCSize(SCROLLVIEW_WIDTH, SCROLLVIEW_HEIGHT))
    scroll:setContentSize(CCSizeMake(SCROLLCONTENT_WIDTH, SCROLLVIEW_HEIGHT))
    herolistBg:addChild(scroll)

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
    blackBatch = CCNode:create()
    scroll:getContainer():addChild(blackBatch, 4)
    selectBatch = img.createBatchNodeForUI(img.ui.hook_btn_sel)
    scroll:getContainer():addChild(selectBatch, 5)

    for i=1, #herolist do
        local x, y = 45 + (i-1) * 90 + 8, 56 + 8 
   
        local qlt = cfghero[herolist[i].id].maxStar
        local heroBg = nil
        if qlt == 10 then
            headBg = img.createUISprite(img.ui.hero_star_ten_bg)
            headBg:setPosition(x, y)
            headBg:setScale(0.92)
            iconBgBatch1:addChild(headBg)
            json.load(json.ui.lv10_framefx)
            local aniten = DHSkeletonAnimation:createWithKey(json.ui.lv10_framefx)
            aniten:playAnimation("animation", -1)
            aniten:scheduleUpdateLua()
            aniten:setScale(0.92)
            aniten:setPosition(x, y)
            scroll:getContainer():addChild(aniten, 3)
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
        scroll:getContainer():addChild(headIcons[i], 2)

        --local groupBg = img.createUISprite(img.ui.herolist_group_bg)
        --groupBg:setScale(0.42 * 0.92)
        --groupBg:setPosition(x - 26, y + 26)
        --groupBgBatch:addChild(groupBg)

        --local groupIcon = img.createUISprite(img.ui["herolist_group_" .. cfghero[herolist[i].id].group])
        --groupIcon:setScale(0.42 * 0.92)
        --groupIcon:setPosition(x - 26, y + 26)
        --scroll:getContainer():addChild(groupIcon, 3)

        --local showLv = lbl.createFont2(15 * 0.92, herolist[i].lv)
        --showLv:setPosition(x + 23, y + 26)
        --scroll:getContainer():addChild(showLv, 3)

        --if qlt <= 5 then
        --    for i = qlt, 1, -1 do
        --        local star = img.createUISprite(img.ui.star_s)
        --        star:setScale(0.92)
        --        star:setPosition(x + (i-(qlt+1)/2)*12*0.8, y - 30)
        --        starBatch:addChild(star)
        --    end
        --elseif qlt == 6 then
        --    local redstar = 1
        --    if herolist[i].wake then
        --        redstar = herolist[i].wake+1
        --    end
        --    for i = redstar, 1, -1 do
        --        local star = img.createUISprite(img.ui.hero_star_orange)
        --        star:setScale(0.92*0.75)
        --        star:setPosition(x + (i-(redstar+1)/2)*12*0.8, y - 30)
        --        star1Batch:addChild(star)
        --    end
        --elseif qlt == 10 then
        --    local starIcon2 = img.createUISprite(img.ui.hero_star_ten)
        --    starIcon2:setScale(0.92)
        --    starIcon2:setPosition(x, y-30)
        --    star10Batch:addChild(starIcon2)
        --end        
        
        local showHpBg = img.createUISprite(img.ui.fight_hp_bg.small)
        showHpBg:setPosition(headIcons[i]:boundingBox():getMidX(), headIcons[i]:boundingBox():getMinY() - 8)
        scroll:getContainer():addChild(showHpBg)
    
        local showHpFgSp = img.createUISprite(img.ui.fight_hp_fg.small)
        local showHpFg = createProgressBar(showHpFgSp)
        showHpFg:setPosition(showHpBg:getContentSize().width/2, showHpBg:getContentSize().height/2)
        showHpFg:setPercentage(herolist[i].hpp)
        showHpBg:addChild(showHpFg)

        if herolist[i].hpp <= 0 then
            setShader(headIcons[i], SHADER_GRAY, true)
        end
    end

    local function updateHp()
        for i=1, 6 do
            baseHeroHp[i]:setPercentage(0)
            for j, k in ipairs(herolist) do
                if k.hid == hids[i] then
                    baseHeroHp[i]:setPercentage(k.hpp)
                end
            end
        end
    end

    --local iconBuff
    --local iconTips 
    local function checkUpdate()
        local power = 0
        local sk = 0
        for i=1, 6 do 
            if hids[i] and hids[i] > 0 and heros.find(hids[i]) then
                power = power + heros.power(hids[i])
                local heroData = heros.find(hids[i])
                if bit.band(sk, bit.blshift(1, cfghero[heroData.id].group - 1)) == 0 then
                    sk = sk + bit.blshift(1, cfghero[heroData.id].group - 1)
                end
            end
        end

        showPower:setString(power)
        if heroSkillBg:getChildByTag(1) then
            heroSkillBg:removeChildByTag(1)
        end

        for i=1, #require("ui.selecthero.campLayer").BuffTable do
            campWidget.icon[i]:setVisible(false)
        end
        
        local heroids = {}
        for i=1, 6 do 
            heroids[i] = nil
            if heros.find(hids[i]) ~= nil then
                heroids[i] = heros.find(hids[i]).id
            end
        end
 
        local showIcon = require("ui.selecthero.campLayer").checkUpdateForHeroids(heroids,true)

        if showIcon ~= -1 then
            campWidget.icon[showIcon]:setVisible(true)
        end

        --[[local power = 0
      
        iconBuff = nil
        iconTips = nil
        local isFull = true
        local sk = 0
        for i=1, 6 do 
            if hids[i] and hids[i] > 0 and heros.find(hids[i]) then
                power = power + heros.power(hids[i])
                local heroData = heros.find(hids[i])
                if bit.band(sk, bit.blshift(1, cfghero[heroData.id].group - 1)) == 0 then
                    sk = sk + bit.blshift(1, cfghero[heroData.id].group - 1)
                end
            else
                isFull = false
            end
        end

        showPower:setString(power)
        if heroSkillBg:getChildByTag(1) then
            heroSkillBg:removeChildByTag(1)
        end
      
        local ANIMS = {
            [1] = json.ui.jjc_kulou, [2] = json.ui.jjc_baolei,
            [3] = json.ui.jjc_shenyuan, [4] = json.ui.jjc_senlin,
            [5] = json.ui.jjc_anying, [6] = json.ui.jjc_shengguang,
            [7] = json.ui.jjc_hunhe,
        }
        local icon 
        for i=1, 7 do
            if (sk == bit.blshift(1, i - 1) and isFull) or (i == 7 and sk == 63) then
                --icon = img.createCampBuff(i)
                json.load(json.ui.campbuff[i])
                icon = DHSkeletonAnimation:createWithKey(json.ui.campbuff[i])
                icon:scheduleUpdateLua()
                icon:playAnimation("animation", -1)
                icon:setScale(0.72)
                
                iconTips = require("ui.tips.campbuff").create(i)
                iconTips.bg:setAnchorPoint(ccp(0, 0))
                iconTips.bg:setPosition(scalep(135, 250))
                layer:addChild(iconTips)
                iconTips:setVisible(false)
            end
        end
        if icon then
            icon:setPosition(63, heroSkillBg:getContentSize().height/2)
            heroSkillBg:addChild(icon, 1, 1)
            iconBuff = icon 
        end
        --]]
    end

    local function onMoveUp(pos, tpos, isNotCallBack)
        checkUpdate()
        if not isNotCallBack then
            local heroInfo = heros.find(hids[tpos])
            local param = {
                id = heroInfo.id,
                lv = heroInfo.lv,
                showGroup = true,
                showStar = 3,
                wake = heroInfo.wake,
                orangeFx = nil,
                petID = petBattle.getNowSele(),
                hskills = heroInfo.hskills,
				hid = heroInfo.hid
            }
            --showHeros[tpos] = img.createHeroHead(heroInfo.id, heroInfo.lv, true, 3, heroInfo.wake,nil,petBattle.getNowSele())
            showHeros[tpos] = img.createHeroHeadByParam(param)
            showHeros[tpos]:setScale(84/94)
            showHeros[tpos]:setPosition(POSX[tpos], 74)
            heroCampBg:addChild(showHeros[tpos])
            baseHeroHp[tpos]:setPercentage(herolist[pos].hpp)
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
        if herolist[pos].hpp <= 0 then
            return
        end
        local tpos
        for i=1, 6 do
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
            --local tempHero = img.createHeroHead(herolist[pos].id, herolist[pos].lv, true,nil,petBattle.getNowSele())
            local param = {
                id = herolist[pos].id,
                --lv = herolist[pos].lv,
                --showGroup = true,
                --showStar = nil,
                --wake = nil,
                --orangeFx = nil,
                --petID = petBattle.getNowSele(),
                --hid = herolist[pos].hid
            }
            local tempHero = img.createHeroHeadByParam(param)
            tempHero:setScale(0.92)
            tempHero:setPosition(realbpos)
            board:addChild(tempHero, 100)
            
            local arr = CCArray:create()
            arr:addObject(CCMoveTo:create(0.1, realepos))
            --arr:addObject(CCScaleTo:create(0.5, 0.92))
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
        baseHeroHp[pos]:setPercentage(0)
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
            --local tempHero = img.createHeroHead(herolist[tpos].id, herolist[tpos].lv, true,nil,petBattle.getNowSele())
            local param = {
                id = herolist[tpos].id,
                --lv = herolist[tpos].lv,
                --showGroup = true,
                --showStar = nil,
                --wake = nil,
                --orangeFx = nil,
                --petID = petBattle.getNowSele(),
                --hid = herolist[tpos].hid
            }
            local tempHero = img.createHeroHeadByParam(param)
            tempHero:setPosition(realbpos)
            tempHero:setScale(0.92)
            board:addChild(tempHero, 100)
            
            local arr = CCArray:create()
            arr:addObject(CCMoveTo:create(0.1, realepos))
            --arr:addObject(CCScaleTo:create(0.5, 1))
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
        
        --[[
        if iconBuff then
            if iconBuff:getAabbBoundingBox():containsPoint(ccp(x, y)) then
                iconTips:setVisible(true)
            end
        end]]
        
        for i=1, 6 do
            if hids[i] and showHeros[i] and showHeros[i]:boundingBox():containsPoint(point) then
                preSelect = i
            end
        end
        
        return true 
    end

    local function onTouchMoved(x, y)
        local point = heroCampBg:convertToNodeSpace(ccp(x, y))
        
        --[[
        if iconBuff then
            if iconBuff:getAabbBoundingBox():containsPoint(ccp(x, y)) then
                iconTips:setVisible(true)
            end
        end]]

        if preSelect and math.abs(x - lastx) >= 10 then
            showHeros[preSelect]:setPosition(point)
            showHeros[preSelect]:setZOrder(1)
        end
        
        return true
    end

    local function onTouchEnd(x, y)
        local point = heroCampBg:convertToNodeSpace(ccp(x, y))
        local pointOnScroll = scroll:getContainer():convertToNodeSpace(ccp(x, y))

        --[[
        if iconTips then
            iconTips:setVisible(false)
        end]]

        if math.abs(x - lastx) < 10 then
            for i,v in ipairs(headIcons) do
                if v:boundingBox():containsPoint(pointOnScroll) then
                    audio.play(audio.button)
                    moveUp(i)
                end
            end

            for i=1,6 do 
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
        for i=1, 6 do
            if baseHeroBg[i]:boundingBox():containsPoint(point) then
                if math.abs(showHeros[preSelect]:getPositionX() - baseHeroBg[i]:getPositionX()) < 25
                    and math.abs(showHeros[preSelect]:getPositionY() - baseHeroBg[i]:getPositionY()) < 25 then
                    ifset = true
                    showHeros[preSelect]:setZOrder(0)
                    showHeros[preSelect]:setPosition(baseHeroBg[i]:getPosition())
                    if hids[i] and showHeros[i] then
                        showHeros[i]:setPosition(baseHeroBg[preSelect]:getPosition())
                    end
                    showHeros[preSelect], showHeros[i] = showHeros[i], showHeros[preSelect]
                    hids[preSelect], hids[i] = hids[i], hids[preSelect]
                    updateHp()
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

    btnBattle:registerScriptTapHandler(function()
        audio.play(audio.fight_start_button)
        local cloneHids = clone(hids)
        cloneHids[7] = petBattle.getNowSele()
        userdata.setSquadBrave(cloneHids) 
        local unit = {}
        for i=1, 6 do
            if hids[i] and hids[i] > 0 then
                unit[#unit + 1] = {
                    hid = hids[i],
                    pos = i,
                }
                -- 觉醒处理
                local hh = heros.find(unit[#unit].hid)
                if hh and hh.wake then
                    unit[#unit].wake = hh.wake
                end
            end
        end
        for i, v in ipairs(unit) do
            for j, k in ipairs(herolist) do
                if v.hid == k.hid then
                    v.hp = k.hpp
                end
            end
        end
        params.hids = unit
        onHadleBattle(params)
    end)

    local function initLoad()
        hids = userdata.getSquadBrave()
        petBattle.initData(hids)
        for i, v in ipairs(hids) do
            for j, k in ipairs(herolist) do
                if v == k.hid then
                    if k.hpp == 0 then
                        hids[i] = 0
                    else
                        if baseHeroHp[i] then 
                            baseHeroHp[i]:setPercentage(k.hpp)
                        end
                    end
                    break
                end
            end
        end

        for i,v in ipairs(herolist) do
            for j=1, 6 do
                if v.hid == hids[j] and hids[j] ~= 0 then
                    onMoveUp(i, j, true)
                    herolist[i].isUsed = true
                end
            end
        end
        loadHeroCamps(hids)
    end
    initLoad()

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

    local anim_duration = 0.2
    board:setPosition(CCPoint(view.midX, view.minY+576*view.minScale))
    board:runAction(CCMoveTo:create(anim_duration, CCPoint(view.midX, view.minY+135*view.minScale)))
    herolistBg:runAction(CCMoveTo:create(anim_duration, CCPoint(view.midX, view.minY+130*view.minScale)))
    darkbg:runAction(CCFadeTo:create(anim_duration, POPUP_DARK_OPACITY))

    return layer
end

return ui
