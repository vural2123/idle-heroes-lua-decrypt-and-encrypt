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
local arena3v3Data = require "data.3v3arena"
local pet3v3 = require "ui.pet.petBattle3v3"
local ccamp = require "fight.helper.ccamp"

local function onHadleBattle(content)
    if content.type == "3v3arenaDef" then
        local params = {
            sid = player.sid,
            id = 2,
            camp = content.hids,
        }

        print("3V3的宠物防守整容数据-------begin3")
        pet3v3.addPetData(content.hids)
        tablePrint(content.hids)
        print("3V3的宠物防守整容数据-------end")

        tbl2string(params)
        addWaitNet()
        net:pvp_camp(params, function(__data)
            delWaitNet()
            tbl2string(__data)
            if __data.status >= 0 then
                addWaitNet() 
                net:joinp3p_sync(params, function(__data)
                    delWaitNet()

                    tbl2string(__data)
                    if __data.status == -1 then
                        --layer:addChild(require("ui.selecthero.main").create({ type = "ArenaDef" }), 10000)  
                    else
                        local arenaData = require "data.3v3arena"
                        arenaData.init(__data)
                        replaceScene(require("ui.3v3arena.main").create())
                    end
                end)
            end
        end)
    elseif content.type == "3v3arenaAtk" then
        print("3V3的宠物攻击数据-------begin4")
        pet3v3.addPetData(content.hids)
        print("3V3的宠物攻击数据-------end")

        local params = {
            sid = player.sid,
            camp = content.hids,
            uid = content.info.uid,
            id = 2,
            svr_id = content.info.sid,
        }
        tbl2string(params)
        addWaitNet()
        net:pvp_fight(params, function(__data)
            tbl2string(__data)
            delWaitNet()
            if __data.status < 0 then
                showToast("status:" .. __data.status)
                return 
            end

            if __data.video and __data.video.select then
                bag.addRewards(__data.video.rewards[__data.video.select])
            end
            bag.items.sub({ id = ITEM_ID_ARENA, num = content.cost})
            local video = __data.video
            local videoAry = {}

            -- 好战者活动
            if video and video.wins then
                local win_count = 0
                for ii=1,#video.wins do
                    if video.wins[ii] == true then
                        win_count = win_count + 1
                    end
                end
                local activityData = require "data.activity"
                if win_count >= 2 then
                    activityData.addScore(activityData.IDS.SCORE_FIGHT2.ID, 2)
                else
                    activityData.addScore(activityData.IDS.SCORE_FIGHT2.ID, 1)
                end
            end

            local function insertVideo(frames, hurts, round)
                if not frames then
                    return
                end
                local newData = clone(video)
                newData.frames = frames
                newData.hurts = hurts
                newData.win = video.wins[round]

                local function getNewCmp(camp)
                    local res = {}
                    local pheroes = camp or {}
                    for _, v in ipairs(pheroes) do
                        if v.pos >= (round - 1) * 6 + 1 and v.pos <= (round - 1) * 6 + 6 then
                            local newValue = clone(v)
                            newValue.pos = v.pos - (round - 1) * 6
                            table.insert(res, newValue)
                        elseif v.pos == 6*3+round then
                            local newValue = clone(v)
                            newValue.pos = 7
                            table.insert(res, newValue)
                        end
                    end
                    return res
                end

                newData.atk.camp = getNewCmp(video.atk.camp)
                newData.def.camp = getNewCmp(video.def.camp)

				ccamp.processCamp(newData, nil, 2)

                table.insert(videoAry, newData)
            end

            insertVideo(video.frames,   video.hurts,    1)
            insertVideo(video.frames1,  video.hurts1,   2)
            insertVideo(video.frames2,  video.hurts2,   3)

            if arenaSkip() == "enable" then
                local tmp_videos = videoAry[#videoAry]
                tmp_videos.idx = #videoAry
                tmp_videos.videos = videoAry
                tmp_videos.skip = true
                CCDirector:sharedDirector():getRunningScene():addChild(require("fight.pvp3.final").create(tmp_videos), 1000)
            else
                replaceScene(require("fight.pvp3.loading").create(videoAry))
            end

            --local arenaData = require "data.arena"
            --local video = __data.video
            --video.atk.camp = content.hids 
            --video.atk.name = player.name
            --video.atk.lv = player.lv()
            --video.atk.logo = player.logo
            --video.atk.score = arenaData.score

            --arenaData.update(video.ascore)
           
            --local tmp = video.def.camp 
            --video.def = {}
            --video.def = clone(content.info)
            --video.def.camp = tmp

            --if video.rewards and video.select then
            --    bag.addRewards(video.rewards[video.select])
            --end
            --arenaData.fight = arenaData.fight + 1
            --bag.items.sub({ id = ITEM_ID_ARENA, num = content.cost})
            --tbl2string(video)
            --local achieveData = require "data.achieve"
            --if video.win then
            --    achieveData.add(ACHIEVE_TYPE_ARENA_ATTACK, 1)
            --end

            --local dailytask = require "data.task"
            --dailytask.increment(dailytask.TaskType.ARENA, 1)
            --video.from_layer = "task"

            --replaceScene(require("fight.pvp.loading").create(__data.video))
        end)
  
    end
end


function ui.create(params)
    local layer = CCLayer:create()
    
    local params = params or {}
    local darkbg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    layer:addChild(darkbg)

    local board = img.createLogin9Sprite(img.login.dialog)
    board:setPreferredSize(CCSize(775, 512))
    --board:setAnchorPoint(ccp(0.5, 0))
    board:setScale(view.minScale)
    board:setPosition(view.midX, view.minY + 294*view.minScale)
    layer:addChild(board)

    local btnCloseSprite = img.createUISprite(img.ui.close)
    local btnClose = SpineMenuItem:create(json.ui.button, btnCloseSprite)
    btnClose:setPosition(745, 485)
    local menuClose = CCMenu:createWithItem(btnClose)
    menuClose:setPosition(0, 0)
    board:addChild(menuClose)
    btnClose:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer:removeFromParentAndCleanup(true)
    end)

    local title = lbl.createFont1(26, i18n.global.select_hero_title.string, ccc3(0xe6, 0xd0, 0xae))
    title:setPosition(388, 485)
    board:addChild(title, 1)

    local titleShade = lbl.createFont1(26, i18n.global.select_hero_title.string, ccc3(0x59, 0x30, 0x1b))
    titleShade:setPosition(388, 483)
    board:addChild(titleShade)

    local heroCampBg = img.createUI9Sprite(img.ui.select_hero_camp_bg)
    heroCampBg:setPreferredSize(CCSize(715, 336))
    heroCampBg:setPosition(388, 274)
    board:addChild(heroCampBg, 1)

    local btnBattleSprite = img.createLogin9Sprite(img.login.button_9_small_gold)
    btnBattleSprite:setPreferredSize(CCSize(215, 52))
    local btnBattleLab = lbl.createFont1(20, i18n.global.trial_stage_btn_battle.string, ccc3(0x73, 0x3b, 0x05))
    btnBattleLab:setPosition(btnBattleSprite:getContentSize().width/2, btnBattleSprite:getContentSize().height/2)
    btnBattleSprite:addChild(btnBattleLab)

    local btnBattle = SpineMenuItem:create(json.ui.button, btnBattleSprite)
    btnBattle:setPosition(388, 62)
    local menuBattle = CCMenu:createWithItem(btnBattle)
    menuBattle:setPosition(0, 0)
    board:addChild(menuBattle, 2)

    local selectTeamBg = img.createUI9Sprite(img.ui.select_tab_tab_bg)
    selectTeamBg:setPreferredSize(CCSize(705, 37))
    selectTeamBg:setPosition(357, 310)
    heroCampBg:addChild(selectTeamBg)

    local showPowerBg = img.createUISprite(img.ui.select_hero_power_bg)
    showPowerBg:setAnchorPoint(ccp(0, 0.5))
    showPowerBg:setPosition(0, 19)
    selectTeamBg:addChild(showPowerBg)

    local powerIcon = img.createUISprite(img.ui.power_icon)
    powerIcon:setScale(0.46)
    powerIcon:setPosition(27, 21)
    showPowerBg:addChild(powerIcon)

    local power = 0
    local showPower = lbl.createFont2(20, "0")
    showPower:setAnchorPoint(ccp(0, 0.5))
    showPower:setPosition(powerIcon:boundingBox():getMaxX() + 15, powerIcon:boundingBox():getMidY())
    showPowerBg:addChild(showPower)

    local btn_skip0 = img.createLogin9Sprite(img.login.button_9_small_gold)
    btn_skip0:setPreferredSize(CCSizeMake(180, 44))
    local skip_bg = img.createUISprite(img.ui.option_bg)
    skip_bg:setPosition(CCPoint(23, 22))
    btn_skip0:addChild(skip_bg)
    local skip_tick = img.createUISprite(img.ui.option_tick)
    skip_tick:setPosition(CCPoint(23, 22))
    btn_skip0:addChild(skip_tick)
    local lbl_skip = lbl.create({font=1, size=18, text=i18n.global.btn_skip_fight.string, color=ccc3(0x73, 0x3b, 0x05), fr={size=14}, ru={size=14}})
    lbl_skip:setPosition(CCPoint(100, 22))
    btn_skip0:addChild(lbl_skip)
    local btn_skip = SpineMenuItem:create(json.ui.button, btn_skip0)
    btn_skip:setPosition(CCPoint(300, 19))
    local btn_skip_menu = CCMenu:createWithItem(btn_skip)
    btn_skip_menu:setPosition(CCPoint(0, 0))
    selectTeamBg:addChild(btn_skip_menu)
    if not params or params.type ~= "3v3arenaAtk" then
        btn_skip:setVisible(false)
    end
    local function updateSkip()
        if arenaSkip() == "enable" then
            skip_tick:setVisible(true)
        else
            skip_tick:setVisible(false)
        end
    end
    updateSkip()
    btn_skip:registerScriptTapHandler(function()
        audio.play(audio.button)
        if arenaSkip() == "enable" then
            arenaSkip("disable")
        else
            arenaSkip("enable")
        end
        updateSkip()
    end)
    --宠物按钮
    local spPet = img.createLogin9Sprite(img.login.button_9_small_purple)
    spPet:setPreferredSize(CCSizeMake(150, 44))
    local spIcon = img.createUISprite(img.ui.pet_leg)
    spPet:addChild(spIcon)
    local btnLal = lbl.createFont1(16, i18n.global.pet_battle_btn_lal.string, ccc3(0x5c, 0x19, 0x8e))
    spPet:addChild(btnLal)

    local btnPet = SpineMenuItem:create(json.ui.button, spPet)
    require("dhcomponents.DroidhangComponents"):mandateNode(btnPet,"yw_petBattle_btnPet_3v3")
    require("dhcomponents.DroidhangComponents"):mandateNode(spIcon,"yw_petBattle_spIcon")
    require("dhcomponents.DroidhangComponents"):mandateNode(btnLal,"yw_petBattle_btnLal")
    local menuPet = CCMenu:createWithItem(btnPet)
    menuPet:setPosition(0, 0)
    selectTeamBg:addChild(menuPet,1)

    --设置按钮
    local btnSettingSprite = img.createLogin9Sprite(img.login.button_9_small_green)
    btnSettingSprite:setPreferredSize(CCSize(150, 44))
    local btnSettingLab = lbl.createFont1(16, i18n.global.arena3v3_btn_setting.string, ccc3(0x1b, 0x59, 0x02))
    btnSettingLab:setPosition(btnSettingSprite:getContentSize().width/2, btnSettingSprite:getContentSize().height/2)
    btnSettingSprite:addChild(btnSettingLab)

    local btnSetting = SpineMenuItem:create(json.ui.button, btnSettingSprite)
    btnSetting:setPosition(630, 19)
    local menuSetting = CCMenu:createWithItem(btnSetting)
    menuSetting:setPosition(0, 0)
    selectTeamBg:addChild(menuSetting, 1)

    local POSX = { 128, 210, 311, 392, 473, 554 }
    local baseHeroBg = {}
    local baseHeroBlack = {}
    for i = 1, 3 do
        local showLineBg = img.createUISprite(img.ui.hero_circle_bg)
        showLineBg:setPosition(53, 223 - (i - 1) * 82)
        heroCampBg:addChild(showLineBg)

        local showLine = lbl.createFont1(20, i, ccc3(0xe8, 0xd8, 0xb9))
        showLine:setPosition(showLineBg:getContentSize().width/2, showLineBg:getContentSize().height/2)
        showLineBg:addChild(showLine)
        for j = 1, 6 do
            local idx = (i - 1) * 6 + j
            baseHeroBg[idx] = img.createUI9Sprite(img.ui.herolist_withouthero_bg)
            baseHeroBg[idx]:setPreferredSize(CCSize(76, 76))
            baseHeroBg[idx]:setPosition(POSX[j], showLineBg:boundingBox():getMidY())
            heroCampBg:addChild(baseHeroBg[idx])
        
            baseHeroBlack[idx] = img.createUISprite(img.ui.hero_head_shade)
            baseHeroBlack[idx]:setScale(76/94)
            baseHeroBlack[idx]:setOpacity(120)
            baseHeroBlack[idx]:setPosition(baseHeroBg[idx]:getPositionX(), baseHeroBg[idx]:getPositionY())
            heroCampBg:addChild(baseHeroBlack[idx], 10000)
            baseHeroBlack[idx]:setVisible(false)
        end
    end
 
    local herolistBg = img.createUI9Sprite(img.ui.tips_bg)
    herolistBg:setPreferredSize(CCSize(957, 112))
    herolistBg:setScale(view.minScale)
    herolistBg:setAnchorPoint(ccp(0.5, 1))
    herolistBg:setPosition(view.midX, view.minY + 0 * view.minScale)
    layer:addChild(herolistBg)

    autoLayoutShift(herolistBg, false, true, false, false)

    local isShowHero = false
    btnSetting:registerScriptTapHandler(function()
        local anim_duration = 0.2
        if isShowHero == false then
            isShowHero = true
            herolistBg:stopAllActions()
            herolistBg:runAction(CCMoveTo:create(anim_duration, getAutoLayoutShiftPos(herolistBg, CCPoint(view.midX, view.minY + 112*view.minScale), false, true, false, false)))
        else
            isShowHero = false
            herolistBg:stopAllActions()
            herolistBg:runAction(CCMoveTo:create(anim_duration, getAutoLayoutShiftPos(herolistBg, CCPoint(view.midX, view.minY + 0*view.minScale), false, true, false, false)))
        end
    end)

    local herolist = clone(heros)
    table.sort(herolist, compareHero)
    local defhids = userdata.getSquadArena3v3Def() or {}
    local atkhids = userdata.getSquadArena3v3Atk() or {}
    local whitelist = arraymerge(defhids, atkhids)
    herolist = herolistless(herolist, whitelist)

    SCROLLVIEW_WIDTH = 943
    SCROLLVIEW_HEIGHT = 112
    SCROLLCONTENT_WIDTH = #herolist * 90 + 8

    local scroll = CCScrollView:create()
    scroll:setDirection(kCCScrollViewDirectionHorizontal)
    scroll:setAnchorPoint(ccp(0, 0))
    scroll:setPosition(7, 0)
    scroll:setViewSize(CCSize(SCROLLVIEW_WIDTH, SCROLLVIEW_HEIGHT))
    scroll:setContentSize(CCSizeMake(SCROLLCONTENT_WIDTH, SCROLLVIEW_HEIGHT))
    herolistBg:addChild(scroll)

    local showHeroLayer = CCLayer:create()
    scroll:getContainer():addChild(showHeroLayer)

    local hids = {}
    local headIcons = {}
    local showHeros = {}

    --战宠回调
    local PetCallBack = function ( ... )
        for i = 1, 18 do
            if showHeros[i] ~= nil then
                showHeros[i]:removeFromParent()
            end
            if hids[i] and hids[i] > 0 then
                local heroInfo = heros.find(hids[i])
                if heroInfo then
                    --showHeros[i] = img.createHeroHead(heroInfo.id, heroInfo.lv, true, 3, heroInfo.wake,nil,pet3v3.findNum(math.ceil(i/6)))
                    local param = {
                        id = heroInfo.id,
                        lv = heroInfo.lv,
                        showGroup = true,
                        showStar = 3,
                        wake = heroInfo.wake,
                        orangeFx = nil,
                        petID = pet3v3.findNum(math.ceil(i/6)),
                        hskills = heroInfo.hskills,
hid = heroInfo.hid
                    }
                    showHeros[i] = img.createHeroHeadByParam(param)
                    showHeros[i]:setScale(75/94)
                    showHeros[i]:setPosition(baseHeroBg[i]:getPositionX(), baseHeroBg[i]:getPositionY())
                    heroCampBg:addChild(showHeros[i])
                else
                    hids[i] = 0
                end
            end
        end
    end

    btnPet:registerScriptTapHandler(function()
        audio.play(audio.button)
        pet3v3.create(layer,PetCallBack)
    end)

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
        scroll:getContainer():addChild(star10Batch, 3)
        blackBatch = CCNode:create()
        showHeroLayer:addChild(blackBatch, 4)
        selectBatch = img.createBatchNodeForUI(img.ui.hook_btn_sel)
        showHeroLayer:addChild(selectBatch, 5)
    
        for i=1, #herolist do
            local x, y = 45 + (i-1) * 90 + 8, 56 
       
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
                showHeroLayer:addChild(aniten, 3)
            else
                heroBg = img.createUISprite(img.ui.herolist_head_bg)
                heroBg:setScale(0.92)
                heroBg:setPosition(x, y)
                iconBgBatch:addChild(heroBg)
            end

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
            --elseif qlt == 6 then
            --    local redstar = 1
            --    if herolist[i].wake then
            --        redstar = herolist[i].wake+1
            --    end
            --    for i = redstar, 1, -1 do
            --        local star = img.createUISprite(img.ui.hero_star_orange)
            --        star:setScale(0.92*0.75)
            --        star:setPosition(x + (i-(redstar+1)/2)*12*0.8, y - 28)
            --        star1Batch:addChild(star)
            --    end
            --elseif qlt == 10 then
            --    local starIcon2 = img.createUISprite(img.ui.hero_star_ten)
            --    starIcon2:setScale(0.92)
            --    starIcon2:setPosition(x, y-24)
            --    star10Batch:addChild(starIcon2)
            --end
        end
    end
    createHerolist()

    local function onMoveUp(pos, tpos, isNotCallBack)
        local heroInfo = heros.find(hids[tpos])
        power = power + heroInfo.attr().power
        showPower:setString(power)
        if not isNotCallBack then
            local heroInfo = heros.find(hids[tpos])
            --showHeros[tpos] = img.createHeroHead(heroInfo.id, heroInfo.lv, true, 3, heroInfo.wake, nil , pet3v3.findNum(math.ceil(tpos/6)))
            local param = {
                id = heroInfo.id,
                lv = heroInfo.lv,
                showGroup = true,
                showStar = 3,
                wake = heroInfo.wake,
                orangeFx = nil,
                petID = pet3v3.findNum(math.ceil(tpos/6)),
                hskills = heroInfo.hskills,
hid = heroInfo.hid
            }
            showHeros[tpos] = img.createHeroHeadByParam(param)
            showHeros[tpos]:setScale(76/92)
            showHeros[tpos]:setPosition(baseHeroBg[tpos]:getPositionX(), baseHeroBg[tpos]:getPositionY())
            heroCampBg:addChild(showHeros[tpos])
        end

        local blackBoard = CCLayerColor:create(ccc4(0, 0, 0, 120))
        blackBoard:setContentSize(CCSize(76, 76))
        blackBoard:setPosition(headIcons[pos]:getPositionX() - 38, headIcons[pos]:getPositionY() - 38)
        blackBatch:addChild(blackBoard, 0, pos)

        local selectIcon = img.createUISprite(img.ui.hook_btn_sel)
        selectIcon:setPosition(headIcons[pos]:getPositionX(), headIcons[pos]:getPositionY())
        selectBatch:addChild(selectIcon, 0, pos)
    end

    local function moveUp(pos)
        local tpos
        for i=1, 18 do
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
            local tempHero = img.createHeroHead(herolist[pos].id, herolist[pos].lv, true)
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
        local heroInfo = heros.find(herolist[tpos].hid)
        power = power - heroInfo.attr().power
        showPower:setString(power)

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
            local tempHero = img.createHeroHead(herolist[tpos].id, herolist[tpos].lv, true)
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
    local lasty
    local isMoved
    local preSelect
    local function onTouchBegin(x, y)
        local point = heroCampBg:convertToNodeSpace(ccp(x, y))
        preSelect = nil
        isMoved = false
        lastx = x
        lasty = y

        for i=1, 18 do
            if hids[i] and showHeros[i] and showHeros[i]:boundingBox():containsPoint(point) then
                preSelect = i
            end
        end
        
        return true 
    end

    local function onTouchMoved(x, y)
        local point = heroCampBg:convertToNodeSpace(ccp(x, y))
        if math.abs(x - lastx) >= 10 or math.abs(y - lasty) >= 10 then
            isMoved = true
        end

        if preSelect and isMoved then
            showHeros[preSelect]:setPosition(point)
            showHeros[preSelect]:setZOrder(1)
        end
        
        return true
    end

    local function onTouchEnd(x, y)
        local point = heroCampBg:convertToNodeSpace(ccp(x, y))
        local pointOnScroll = scroll:getContainer():convertToNodeSpace(ccp(x, y))

        if math.abs(x - lastx) < 10 then
            local isAct = false
            for i,v in ipairs(headIcons) do
                if v:boundingBox():containsPoint(pointOnScroll) then
                    audio.play(audio.button)
                    if isShowHero then
                        moveUp(i)
                        isAct = true
                    end
                end
            end

            for i=1, 18 do 
                if hids[i] and showHeros[i] and showHeros[i]:boundingBox():containsPoint(point) then
                    audio.play(audio.button)
                    if isShowHero then
                        moveDown(i)
                        isAct = true
                    end
                end
            end

            if not herolistBg:boundingBox():containsPoint(layer:convertToNodeSpace(ccp(x, y))) then
                if isShowHero and isAct == false then
                    isShowHero = false
                    herolistBg:runAction(CCMoveTo:create(0.2, getAutoLayoutShiftPos(herolistBg, CCPoint(view.midX, view.minY + 0*view.minScale))))
                elseif not isShowHero and isAct == false then
                    for i = 1, 18 do
                        if not hids[i] and baseHeroBg[i]:boundingBox():containsPoint(point) then
                            isShowHero = true
                            herolistBg:runAction(CCMoveTo:create(0.2, getAutoLayoutShiftPos(herolistBg, CCPoint(view.midX, view.minY + 112*view.minScale))))
                        end
                    end
                end
            end
        end
    
        if not preSelect or (not isMoved) then
            return true
        end

        local ifset = false
        for i=1, 18 do
            if baseHeroBg[i]:boundingBox():containsPoint(point) then
                if preSelect and showHeros[preSelect] and math.abs(showHeros[preSelect]:getPositionX() - baseHeroBg[i]:getPositionX()) < 25
                    and math.abs(showHeros[preSelect]:getPositionY() - baseHeroBg[i]:getPositionY()) < 25 then
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
       
        if ifset == false and preSelect and showHeros[preSelect] and baseHeroBg[preSelect] then
            showHeros[preSelect]:setPosition(baseHeroBg[preSelect]:getPosition())
            showHeros[preSelect]:setZOrder(0)
        end
        --重新显示一次所有的头像，为了兼容宠物
        PetCallBack()
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

    board:setScale(0.5*view.minScale)
    local anim_arr = CCArray:create()
    anim_arr:addObject(CCScaleTo:create(0.15, 1*view.minScale, 1*view.minScale))
    -- anim
    board:runAction(CCSequence:create(anim_arr))

    btnBattle:registerScriptTapHandler(function()
        local unit = {}
        for i = 0, 2 do
            local isFind = false
            for j = 1, 6 do
                if hids[i * 6 + j] and hids[i * 6 + j] > 0 then
                    unit[#unit + 1] = {
                        hid = hids[i * 6 + j],
                        pos = i * 6 + j,
                    }
                    isFind = true
                    -- 觉醒处理
                    local hh = heros.find(unit[#unit].hid)
                    if hh and hh.wake then
                        unit[#unit].wake = hh.wake
                    end
                end
            end
            if isFind == false then
                showToast(i18n.global.arena3v3_toast_need_hero.string)
                return 
            end
        end
        params.hids = unit

        local cloneHids = clone(hids)
        --特殊加入第7位宠物标记
        pet3v3.getNowSele(hids)

        if params.type == "3v3arenaDef" then 
            userdata.setSquadArena3v3Def(hids) 
        elseif params.type == "3v3arenaAtk" then
            userdata.setSquadArena3v3Atk(hids)
        end
        onHadleBattle(params)
    end)

    local function initLoad()
        if params.type == "3v3arenaDef" then 
            hids = userdata.getSquadArena3v3Def() or {}
            print("获取战宠防御整容---1")
            tablePrint(hids)
            pet3v3.initData(hids)
        elseif params.type == "3v3arenaAtk" then
            hids = userdata.getSquadArena3v3Atk() or {}
            tablePrint(hids)
            pet3v3.initData(hids)
        end

        for i = 1, 18 do
            if hids[i] and hids[i] > 0 then
                local heroInfo = heros.find(hids[i])
                if heroInfo then
                    --showHeros[i] = img.createHeroHead(heroInfo.id, heroInfo.lv, true, 3, heroInfo.wake,nil,pet3v3.findNum(math.ceil(i/6)))
                    local param = {
                        id = heroInfo.id,
                        lv = heroInfo.lv,
                        showGroup = true,
                        showStar = 3,
                        wake = heroInfo.wake,
                        orangeFx = nil,
                        petID = pet3v3.findNum(math.ceil(i/6)),
                        hskills = heroInfo.hskills,
hid = heroInfo.hid
                    }
                    showHeros[i] = img.createHeroHeadByParam(param)
                    showHeros[i]:setScale(75/94)
                    showHeros[i]:setPosition(baseHeroBg[i]:getPositionX(), baseHeroBg[i]:getPositionY())
                    heroCampBg:addChild(showHeros[i])
                else
                    hids[i] = 0
                end
            end
        end

        for i, v in ipairs(herolist) do
            for j = 1, 18 do
                if v.hid == hids[j] then
                    onMoveUp(i, j, true)
                    herolist[i].isUsed = true
                end
            end
        end
    end
    initLoad()

    local function onChangeLine(x, y)
        --改变宠物的数据
        require("ui.pet.petBattle3v3").changeNum(x,y)
        for i = 1, 18 do
            if hids[i] and showHeros[i] then
                showHeros[i]:removeFromParentAndCleanup(true)
                showHeros[i] = nil
            end
        end

        for i = 1, 6 do
            hids[(x-1) * 6 + i], hids[(y-1) * 6 + i] = hids[(y-1) * 6 + i], hids[(x-1) * 6 + i]
        end

        for i = 1, 18 do
            if hids[i] and hids[i] > 0 then
                local heroInfo = heros.find(hids[i])
                if heroInfo then
                    --showHeros[i] = img.createHeroHead(heroInfo.id, heroInfo.lv, true, 3, heroInfo.wake,nil,pet3v3.findNum(math.ceil(i/6)))
                    local param = {
                        id = heroInfo.id,
                        lv = heroInfo.lv,
                        showGroup = true,
                        showStar = 3,
                        wake = heroInfo.wake,
                        orangeFx = nil,
                        petID = pet3v3.findNum(math.ceil(i/6)),
                        hskills = heroInfo.hskills,
hid = heroInfo.hid
                    }
                    showHeros[i] = img.createHeroHeadByParam(param)
                    showHeros[i]:setScale(75/94)
                    showHeros[i]:setPosition(baseHeroBg[i]:getPositionX(), baseHeroBg[i]:getPositionY())
                    heroCampBg:addChild(showHeros[i])
                else
                    hids[i] = 0
                end
            end
        end
    end

    local preSelect
    local cfg = {
        [1] = { bg = img.login.button_9_small_gold, icon = img.ui.arena_new_switch },
        [2] = { bg = img.login.button_9_small_orange, icon = img.ui.arena_new_cancel_icon },
        [3] = { bg = img.login.button_9_small_green, icon = img.ui.arena_new_change_icon },
    }
    local btnList = {}
    for i = 1, 3 do
        btnList[i] = {}
        for j = 1, 3 do
            local spBg = img.createLogin9Sprite(cfg[j].bg)
            spBg:setPreferredSize(CCSize(62, 56))
            local spIcon = img.createUISprite(cfg[j].icon)
            spIcon:setPosition(spBg:getContentSize().width/2, spBg:getContentSize().height/2)
            spBg:addChild(spIcon)

            btnList[i][j] = SpineMenuItem:create(json.ui.button, spBg)
            btnList[i][j]:setPosition(646, 223 - (i - 1) * 82)
            local menu = CCMenu:createWithItem(btnList[i][j])
            menu:setPosition(0, 0)
            heroCampBg:addChild(menu)
            if j == 1 then
                btnList[i][j]:registerScriptTapHandler(function()
                    preSelect = i
                    for k = 1, 18 do
                        baseHeroBlack[k]:setVisible(true)
                    end
                    for k = 1, 6 do
                        baseHeroBlack[(i-1) * 6 + k]:setVisible(false)
                    end
                    for k = 1, 3 do
                        btnList[k][1]:setVisible(false)
                        if k == i then
                            btnList[k][2]:setVisible(true)
                        else
                            btnList[k][3]:setVisible(true)
                        end
                    end
                end)
            elseif j == 2 then
                btnList[i][j]:setVisible(false)
                btnList[i][j]:registerScriptTapHandler(function()
                    for k = 1, 18 do
                        baseHeroBlack[k]:setVisible(false)
                    end
                    for k = 1, 3 do
                        btnList[k][1]:setVisible(true)
                        btnList[k][2]:setVisible(false)
                        btnList[k][3]:setVisible(false)
                    end
                end)
            elseif j == 3 then
                btnList[i][j]:setVisible(false)
                btnList[i][j]:registerScriptTapHandler(function()
                    for k = 1, 18 do
                        baseHeroBlack[k]:setVisible(false)
                    end
                    for k = 1, 3 do
                        btnList[k][1]:setVisible(true)
                        btnList[k][2]:setVisible(false)
                        btnList[k][3]:setVisible(false)
                    end
                    onChangeLine(preSelect, i)
                end)
            end
        end
    end

    return layer
end

return ui
