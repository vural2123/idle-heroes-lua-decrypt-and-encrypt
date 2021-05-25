local ui = {}

require "common.func"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local i18n = require "res.i18n"
local audio = require "res.audio"
local net = require "net.netClient"
local userdata = require "data.userdata"
local cfghero = require "config.hero"
local bag = require "data.bag"
local player = require "data.player"
local frdarena = require "data.arenac"

local function getHeroList()
    local herolist = {}
	
	for i, v in ipairs(frdarena.team.mbrs) do
		if v.camp then
			for ii, vv in ipairs(v.camp) do
				local hi = clone(vv)
				hi.hid = (i - 1) * 6 + hi.pos
				herolist[#herolist + 1] = hi
			end
		end
	end

    for i, v in ipairs(herolist) do
        v.isUsed = false
    end

    return herolist
end

local function getHero(herolist, hid)
	for i, v in ipairs(herolist) do
		if v.hid == hid then
			return v
		end
	end
end

local function setHeroHpp(hid, hpp)
	for i, v in ipairs(frdarena.team.mbrs) do
		if v.camp then
			for ii, vv in ipairs(v.camp) do
				if ((i - 1) * 6 + vv.pos) == hid then
					vv.hpp = hpp
					return
				end
			end
		end
	end
end

local function onHadleBattle(content)
    if #content.hids <= 0 then
        showToast(i18n.global.toast_selhero_needhero.string)
        return
    end
    
    local params = {
        sid = player.sid + 256 * content.grp_id,
        camp = content.hids
    }

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
        video.map = 1 --cfgbrave[databrave.id].mapId[databrave.stage]
        video.reward = content.reward
        
        video.atk = {}
        video.atk.camp = content.hids 
        video.atk.name = player.name
        video.atk.lv = player.lv()
        video.atk.logo = player.logo

        --video.def = clone(databrave.enemys[databrave.stage])
        local camp = {}
        for i, v in ipairs(video.def.camp) do
            if v.pos ~= 7 then
                v.hp = v.hpp
                if v.hp > 0 then
                    camp[#camp + 1] = clone(v)
                end
            else
                camp[#camp + 1] = clone(v)
            end
        end
        video.def.camp = camp
        if video.rewards and video.select then
            bag.addRewards(video.rewards[video.select])
        end

        -- update hp
        for i, v in ipairs(video.mhpp) do
			setHeroHpp(v.hid, v.hpp)
        end
        
        -- pet
        processPetPosAtk1(video)
        processPetPosDef2(video)

        tbl2string(video)
        replaceScene(require("fight.brave.loading").create(video))
    end)
end

function ui.create(grp_id)
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

    --[[local showPowerBg = img.createUISprite(img.ui.select_hero_power_bg)
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
    showPowerBg:addChild(showPower)--]]

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
    local herolist = getHeroList()
    
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

        local heroHeadParam = {}
		heroHeadParam.id = herolist[i].id
		heroHeadParam.skin = herolist[i].skin
		heroHeadParam.lv = herolist[i].lv
		heroHeadParam.wake = herolist[i].wake
		heroHeadParam.showStar = herolist[i].star
        headIcons[i] = img.createHeroHeadByParam(heroHeadParam)
        headIcons[i]:setScale(0.92)
        headIcons[i]:setPosition(x, y)
        scroll:getContainer():addChild(headIcons[i], 2)

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
        if heroSkillBg:getChildByTag(1) then
            heroSkillBg:removeChildByTag(1)
        end

        for i=1, #require("ui.selecthero.campLayer").BuffTable do
            campWidget.icon[i]:setVisible(false)
        end
        
        local heroids = {}
        for i=1, 6 do 
			if hids[i] then
				local hi = getHero(herolist, hids[i])
				if hi then
					heroids[i] = hi.id
				end
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
            local heroInfo = getHero(herolist, hids[tpos])
            local param = {
                id = heroInfo.id,
                lv = heroInfo.lv,
                showGroup = true,
                showStar = 3,
                wake = heroInfo.wake,
                orangeFx = nil,
				skin = heroInfo.skin
            }
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
            local param = {
                id = herolist[pos].id,
				-- This is probably the flying icon
                --[[lv = herolist[pos].lv,
                showGroup = true,
                showStar = herolist[pos].star,
                wake = herolist[pos].wake,
                orangeFx = nil,
				skin = herolist[pos].skin--]]
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
            local param = {
                id = herolist[tpos].id,
                --lv = herolist[tpos].lv,
                --showGroup = true,
                --showStar = nil,
                --wake = nil,
                --orangeFx = nil,
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
        
        for i=1, 6 do
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
        local point = heroCampBg:convertToNodeSpace(ccp(x, y))
        local pointOnScroll = scroll:getContainer():convertToNodeSpace(ccp(x, y))

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
        local unit = {}
        for i=1, 6 do
            if hids[i] and hids[i] > 0 then
                unit[#unit + 1] = {
                    hid = hids[i],
                    pos = i,
                }
                -- 觉醒处理
                local hh = getHero(herolist, hids[i])
                if hh and hh.wake then
                    unit[#unit].wake = hh.wake
                end
				if hh then
					unit[#unit].hp = hh.hpp
				end
            end
        end
        onHadleBattle({ hids = unit, grp_id = grp_id })
    end)

    hids = {}

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
