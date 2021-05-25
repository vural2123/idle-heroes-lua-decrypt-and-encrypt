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
local particle = require "res.particle"
local food = require "ui.foodbag.data"

local function createBoardForRewards(hid, reward)
    local heroData = heros.find(hid)

    local params = {}
    params.title = i18n.global.reward_will_get.string
    params.btn_count = 0

    local dialog = require("ui.dialog").create(params) 

    local back = img.createLogin9Sprite(img.login.button_9_small_gold)
    back:setPreferredSize(CCSize(153, 50))
    local comfirlab = lbl.createFont1(22, i18n.global.summon_comfirm.string, lbl.buttonColor)
    comfirlab:setPosition(CCPoint(back:getContentSize().width/2,
                                    back:getContentSize().height/2))
    back:addChild(comfirlab)
    local backBtn = SpineMenuItem:create(json.ui.button, back)
    backBtn:setPosition(CCPoint(dialog.board:getContentSize().width/2, 80))
    local menu = CCMenu:createWithItem(backBtn)
    menu:setPosition(0, 0)
    dialog.board:addChild(menu)

    dialog.board.tipsTag = false
    local hero = img.createHeroHeadByHid(hid)
    heroBtn = SpineMenuItem:create(json.ui.button, hero)
    heroBtn:setScale(0.85)
    heroBtn:setPosition(dialog.board:getContentSize().width/2, 185)

    local iconMenu = CCMenu:createWithItem(heroBtn)
    iconMenu:setPosition(0, 0)
    dialog.board:addChild(iconMenu)
    heroBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        local herotips = require "ui.tips.hero"
        local heroInfo = clone(heroData.attr())
        heroInfo.lv = heroData.lv
        heroInfo.star = heroData.star
        heroInfo.id = heroData.id
		heroInfo.hskills = heroData.hskills
        local tips = herotips.create(heroInfo)
        dialog:addChild(tips, 1001)
    end)
    
    backBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        dialog:getParent():addChild((require"ui.hook.drops").create(reward, i18n.global.ui_decompose_preview.string), 1000)
        dialog:removeFromParentAndCleanup()
    end)
    dialog.setClickBlankHandler(function()
        dialog:getParent():addChild((require"ui.hook.drops").create(reward, i18n.global.ui_decompose_preview.string), 1000)
        dialog:removeFromParentAndCleanup()
    end)
    return dialog
end

local function getCondition(id, skipAuto)
    local condition = { 
        [1] = { id = cfghero[id].host, isHost = true, num = 1, select = {}}
    }
    for i, v in ipairs(cfghero[id].material) do
        local isFind = false
        
        for j, k in ipairs(condition) do
            if k.id == v and j~= 1 then
                k.num = k.num + 1
                isFind = true
                break
            end
        end
        
        if not isFind then
            condition[#condition + 1] = { id = v, num = 1, select = {}}
        end
    end
	
	if not skipAuto then
		local usedUp = {}
		for _, v in ipairs(condition) do
			local best = food.getBestFodder(v.id, v.num, v.isHost, true, true, usedUp, 2)
			if #best > 0 then
				for u, k in ipairs(best) do
					v.select[#v.select + 1] = k.hid
				end
				food.appendNotThis(best, usedUp, true)
			end
		end
	end
	
    return condition
end

local function canForge(condition)
    local usedUp = {}
	for _, v in ipairs(condition) do
		local best = food.getBestFodder(v.id, v.num, v.isHost, true, true, usedUp, 1)
		if #best < v.num then
			return false
		end
		food.appendNotThis(best, usedUp, true)
	end
	return true
end

local function canForgeSelect(condition, index)
	local usedUp = {}
	for i=1, #condition do
		if index ~= i then
			food.appendNotThis(condition[i].select, usedUp)
		end
	end
	local v = condition[index]
	local best = food.getBestFodder(v.id, v.num, v.isHost, true, true, usedUp, 1)
	return #best >= v.num
end

function ui.create()
    local layer = CCLayer:create()

    local hostId
	local condition

    img.load(img.packedOthers.ui_hero_forge_bg)
    img.load(img.packedOthers.ui_hero_forge)

    local bgg = img.createUISprite(img.ui.hero_forge_bg)
    bgg:setScale(view.minScale)
    bgg:setPosition(view.midX, view.midY)
    layer:addChild(bgg)

    local bg = CCSprite:create()
    bg:setContentSize(CCSizeMake(960, 576))
    bg:setScale(view.minScale)
    bg:setPosition(view.midX, view.midY)
    layer:addChild(bg)

    local lefTitleBg = img.createUISprite(img.ui.hero_forge_titlebg)
    lefTitleBg:setScaleX(view.physical.w / lefTitleBg:getContentSize().width / view.minScale * 0.5)
    lefTitleBg:setAnchorPoint(ccp(1, 1))
    lefTitleBg:setPosition(480, 576)
    bg:addChild(lefTitleBg)

    local rigTitleBg = img.createUISprite(img.ui.hero_forge_titlebg)
    rigTitleBg:setScaleX(view.physical.w / rigTitleBg:getContentSize().width / view.minScale * 0.5)
    rigTitleBg:setAnchorPoint(ccp(0, 1))
    rigTitleBg:setFlipX(true)
    rigTitleBg:setPosition(480, 576)
    bg:addChild(rigTitleBg)

    local showTitle = lbl.createFont2(22, i18n.global.heroforge_title.string, ccc3(0xf6, 0xd6, 0x6c))
    showTitle:setPosition(480, 560)
    bg:addChild(showTitle)

    autoLayoutShift(lefTitleBg, true, false, false, false)
    autoLayoutShift(rigTitleBg, true, false, false, false)
    autoLayoutShift(showTitle)

    local btnBackSprite = img.createUISprite(img.ui.back)
    local btnBack = HHMenuItem:create(btnBackSprite)
    --btnBack:setScale(view.minScale)
    btnBack:setPosition(35, 546)
    local menuBack = CCMenu:createWithItem(btnBack)
    menuBack:setPosition(0, 0)
    bg:addChild(menuBack, 1000)
    layer.back = btnBack
    btnBack:registerScriptTapHandler(function()
        audio.play(audio.button)
        replaceScene(require("ui.town.main").create())
    end)

    autoLayoutShift(btnBack)

    local btnDetailSprite = img.createUISprite(img.ui.fight_hurts)
    local btnDetail = SpineMenuItem:create(json.ui.button, btnDetailSprite)
    btnDetail:setPosition(408, 465)
    local menuDetail = CCMenu:createWithItem(btnDetail)
    menuDetail:setPosition(0, 0)
    bg:addChild(menuDetail)
    btnDetail:registerScriptTapHandler(function()
        audio.play(audio.button)
        if hostId then
            layer:addChild(require("ui.tips.hero").create(hostId), 1000)
        end
    end)
    btnDetail:setVisible(false)

    local btnInfoSprite = img.createUISprite(img.ui.btn_help)
    local btnInfo = SpineMenuItem:create(json.ui.button, btnInfoSprite)
    --btnInfo:setScale(view.minScale)
    btnInfo:setPosition(930, 550)
    local menuInfo = CCMenu:createWithItem(btnInfo)
    menuInfo:setPosition(0, 0)
    bg:addChild(menuInfo, 100)
    btnInfo:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer:addChild(require("ui.help").create(i18n.global.help_heroforge.string, i18n.global.help_title.string), 1000)
    end)

    autoLayoutShift(btnInfo)

    local rigAnim = json.create(json.ui.yingxiong_hecheng_animation_in)
    rigAnim:setPosition(480, 274)
    bg:addChild(rigAnim)

    local board = img.createUI9Sprite(img.ui.dialog_2)
    board:setPreferredSize(CCSize(425, 480))
    rigAnim:addChildFollowSlot("code_rightplane", board)
    rigAnim:playAnimation("animation")

    local avllab = lbl.createMixFont1(16, i18n.global.heroforge_available_hero.string, ccc3(0x6f, 0x4c, 0x38))
    avllab:setPosition(213, 454)
    board:addChild(avllab)

    local innerBg = img.createUI9Sprite(img.ui.hero_forge_inner)
    innerBg:setPreferredSize(CCSize(376, 354))
    innerBg:setPosition(213, 256)
    board:addChild(innerBg)

    local SCROLLVIEW_WIDTH = 357
    local SCROLLVIEW_HEIGHT = 332
    local scroll = CCScrollView:create()
    scroll:setDirection(kCCScrollViewDirectionVertical)
    scroll:setAnchorPoint(ccp(0, 0))
    scroll:setPosition(10, 13)
    scroll:setViewSize(CCSize(SCROLLVIEW_WIDTH, SCROLLVIEW_HEIGHT))
    innerBg:addChild(scroll)

    local blackBatch
    local selectBatch

    local headIcons = {}
    local heroTable = {}
    local showAnim = {}
    local btnHero = {}
    local reddot = {}
    local defaultGroup

    local showHeroLayer = CCLayer:create()
    bg:addChild(showHeroLayer)

    local anim = json.create(json.ui.yingxiong_hecheng)
    anim:setPosition(258, 222)
    anim:playAnimation("animation3")
    showHeroLayer:addChild(anim, 1000)

    local function loadHero(id)
        btnDetail:setVisible(true)
        condition = getCondition(id)
        hostId = id

        showHeroLayer:removeAllChildrenWithCleanup(true)
        blackBatch:removeAllChildrenWithCleanup(true)
        selectBatch:removeAllChildrenWithCleanup(true)

        anim = json.create(json.ui.yingxiong_hecheng)
        anim:setPosition(258, 222)
        anim:playAnimation("animation4", -1)
        showHeroLayer:addChild(anim, 1000)

        if layer.heroBody then
            layer.heroBody:removeFromParent()
            layer.heroBody = nil
        end

        local heroBody = json.createSpineHero(id)
        heroBody:setScale(0.7)
        heroBody:setVisible(false)
        layer:addChild(heroBody)
        layer.heroBody = heroBody

        local rdWidth = 512
        local rdHeight = 512
        local rdPosY = 100
        local render = cc.RenderTexture:create(rdWidth, rdHeight)
        render:setVisible(false)
        render:scheduleUpdateWithPriorityLua(function ()
            render:beginWithClear(0, 0, 0, 0)

            heroBody:setVisible(true)
            heroBody:setPosition(rdWidth * 0.5, rdPosY-8)
            heroBody:visit()
            heroBody:setVisible(false)

            render:endToLua()
        end, 0)

        local sprite = render:getSprite()
        sprite:setOpacityModifyRGB(true)

        local texture = sprite:getTexture()
        texture:setAntiAliasTexParameters()

        local newSprite = cc.Sprite:createWithTexture(texture)
        newSprite:setScaleY(-1)
        newSprite:setPosition(0, rdHeight * 0.5 - rdPosY)

        anim:addChildFollowSlot("code_hero", newSprite)
        heroBody:addChild(render)

        for i, v in ipairs(condition) do
            local btnSp
            btnSp = img.createHeroHead(v.id, nil, true, true)
            btnHero[i] = CCMenuItemSprite:create(btnSp, nil)
            btnHero[i]:setAnchorPoint(ccp(1, 0))
            if i == 1 then
                btnHero[i]:setPosition(175, 112)
            else
                btnHero[i]:setScale(0.8)
                btnHero[i]:setPosition(258 + (i - 2) * 83, 112)
            end
            local menuHero = CCMenu:createWithItem(btnHero[i])
            menuHero:setPosition(0, 0)
            showHeroLayer:addChild(menuHero)

            local showNum = lbl.createFont2(16, "0/" .. v.num)
            showNum:setPosition(btnHero[i]:boundingBox():getMidX(), 100)
            showHeroLayer:addChild(showNum)
            setShader(btnHero[i], SHADER_GRAY, true)

            showAnim[i] = json.create(json.ui.yingxiong_hecheng2)
            showAnim[i]:setPosition(btnHero[i]:boundingBox():getMidX(), btnHero[i]:boundingBox():getMidY())
            showAnim[i]:setScale(btnHero[i]:getScale())
            showHeroLayer:addChild(showAnim[i], 1001)
            
            reddot[i] = img.createUISprite(img.ui.main_red_dot)
            reddot[i]:setPosition(btnHero[i]:boundingBox():getMaxX()-6, btnHero[i]:boundingBox():getMaxY()-6)
            reddot[i]:setVisible(false)
            showHeroLayer:addChild(reddot[i])
			if canForgeSelect(condition, i) then
				reddot[i]:setVisible(true)
			end

            local icon = img.createUISprite(img.ui.hero_equip_add)
            --icon:setScale(0.65)
            icon:setPosition(btnHero[i]:boundingBox():getMaxX() - 23, btnHero[i]:boundingBox():getMinY() + 23)
            showHeroLayer:addChild(icon)
            icon:runAction(CCRepeatForever:create(CCSequence:createWithTwoActions(
                CCFadeTo:create(0.5, 255 * 0.3), CCFadeTo:create(0.5, 255))))
				
			local function updateButtonFunc(isLoadingHero)
				showNum:setString(#v.select .. "/" .. v.num)
				if #v.select < v.num then
					setShader(btnHero[i], SHADER_GRAY, true)
					showNum:setColor(ccc3(0xff, 0xff, 0xff))
				else
					clearShader(btnHero[i], true)
					showNum:setColor(ccc3(0xc3, 0xff, 0x42))
				end
				if not isLoadingHero then
					for j, vv in ipairs(condition) do
						if canForgeSelect(condition, j) then
							reddot[j]:setVisible(true)
						else
							reddot[j]:setVisible(false)
						end
					end
				end
			end
			
			updateButtonFunc(true)
            
            btnHero[i]:registerScriptTapHandler(function()
				local selFull = {}
				for j=1, #condition do
					if j ~= i then
						for k=1, #condition[j].select do
							selFull[#selFull+1] = condition[j].select[k]
						end
					end
				end
                layer:addChild(require("ui.foodbag.main").createSelectBoard(v.id, v.num, v.isHost, true, true, selFull, v.select, updateButtonFunc), 1000)
            end)
        end
    end

    local function onSelect(pos)
        loadHero(heroTable[pos].id)
        local blackBoard = img.createUISprite(img.ui.hero_head_shade)
        blackBoard:setScale(80/94)
        blackBoard:setOpacity(120)
        blackBoard:setPosition(headIcons[pos]:getPositionX(), headIcons[pos]:getPositionY())
        blackBatch:addChild(blackBoard, 0, pos)

        local selectIcon = img.createUISprite(img.ui.hook_btn_sel)
        selectIcon:setPosition(headIcons[pos]:getPositionX(), headIcons[pos]:getPositionY())
        selectBatch:addChild(selectIcon, 0, pos)
    end

    local function createHerolist()
        arrayclear(headIcons)
        arrayclear(heroTable)
        scroll:getContainer():removeAllChildrenWithCleanup(true)

        for _, v in pairs(cfghero) do
            if v.showInForge and v.showInForge == 1 and bit.band(v.forgemask, bit.blshift(1, player.sid)) > 0 then
                if not defaultGroup or v.group == defaultGroup then
                    heroTable[#heroTable + 1] = {
                        id = _,
                        qlt = v.qlt,
                        group = v.group,
                    }
                end
            end
        end
        for i=1, #heroTable do
            for j=i+1, #heroTable do
                if heroTable[i].qlt < heroTable[j].qlt then
                    heroTable[i], heroTable[j] = heroTable[j], heroTable[i]
                end
            end
        end

        local SCROLLCONTENT_HEIGHT = math.ceil(#heroTable/4) * 84 + 10 
        scroll:setContentSize(CCSizeMake(SCROLLVIEW_WIDTH, SCROLLCONTENT_HEIGHT))
        scroll:setContentOffset(ccp(0, SCROLLVIEW_HEIGHT - SCROLLCONTENT_HEIGHT))

        local iconBgBatch = img.createBatchNodeForUI(img.ui.herolist_head_bg)
        scroll:getContainer():addChild(iconBgBatch, 1)
        local groupBgBatch = img.createBatchNodeForUI(img.ui.herolist_group_bg)
        scroll:getContainer():addChild(groupBgBatch , 3)
        local starBatch = img.createBatchNodeForUI(img.ui.star_s)
        scroll:getContainer():addChild(starBatch, 3)
        local star1Batch = img.createBatchNodeForUI(img.ui.hero_star_orange)
        scroll:getContainer():addChild(star1Batch, 3)
        blackBatch = img.createBatchNodeForUI(img.ui.hero_head_shade)
        scroll:getContainer():addChild(blackBatch, 4)
        selectBatch = img.createBatchNodeForUI(img.ui.hook_btn_sel)
        scroll:getContainer():addChild(selectBatch, 5)

        for i, v in ipairs(heroTable) do
            local x, y = 53 + ((i-1)%4) * 84, SCROLLCONTENT_HEIGHT - math.ceil(i/4) * 84 + 30

            local heroBg = img.createUISprite(img.ui.herolist_head_bg)
            heroBg:setScale(0.8)
            heroBg:setPosition(x, y)
            iconBgBatch:addChild(heroBg)

			local headIcon = CCSprite:create()
			headIcon:setContentSize(CCSizeMake(78, 78))
            local headIconIcon = img.createHeroHeadIcon(v.id)
			headIconIcon:setPosition(78 / 2, 78 / 2)
			img.fixOfficialScale(headIconIcon, "hero", v.id)
			headIcon:addChild(headIconIcon)
            headIcons[i] = headIcon
            headIcons[i]:setScale(0.8)
            headIcons[i]:setPosition(x, y)
            scroll:getContainer():addChild(headIcons[i], 2)

            local groupBg = img.createUISprite(img.ui.herolist_group_bg)
            groupBg:setScale(0.42 * 0.8)
            groupBg:setPosition(x - 24, y + 24)
            groupBgBatch:addChild(groupBg)

            local groupIcon = img.createUISprite(img.ui["herolist_group_" .. v.group])
            groupIcon:setScale(0.42 * 0.8)
            groupIcon:setPosition(x - 24, y + 25)
            scroll:getContainer():addChild(groupIcon, 3)

            local qlt = v.qlt
            if qlt <= 5 then
                for i = qlt, 1, -1 do
                    local star = img.createUISprite(img.ui.star_s)
                    star:setScale(0.8)
                    star:setPosition(x + (i-(qlt+1)/2)*12*0.8, y - 26)
                    starBatch:addChild(star)
                end
            elseif qlt == 6 then
                local star = img.createUISprite(img.ui.hero_star_orange)
                star:setScale(0.8 * 0.75)
                star:setPosition(x, y - 24)
                star1Batch:addChild(star)
            end

            if hostId and v.id == hostId then
                onSelect(i)
            end

            --redDot
            local lcond = getCondition(v.id, true)

            local redDotFlag = canForge(lcond)
            
            if redDotFlag then
                local icon = img.createUISprite(img.ui.main_red_dot)
                headIcon:addChild(icon, 100)
                icon:setPosition(headIcon:getContentSize().width, headIcon:getContentSize().height)
            end
        end
        if hostId then
            loadHero(hostId)
        end
    end

    local btnGroup = {}
    for i=1, 6 do
        local btnGroupSp = img.createUISprite(img.ui.devour_circle_bg)
        local starIcon = img.createUISprite(img.ui["herolist_group_" .. i])
        starIcon:setPosition(btnGroupSp:getContentSize().width/2, btnGroupSp:getContentSize().height/2 + 2)
        starIcon:setScale(0.74)
        btnGroupSp:addChild(starIcon)

        btnGroup[i] = CCMenuItemSprite:create(btnGroupSp, nil)
        local menuGroup = CCMenu:createWithItem(btnGroup[i])
        menuGroup:setPosition(0, 0)
        board:addChild(menuGroup)
        btnGroup[i]:setPosition(38 + 50 * i, 46)
        
        btnGroup[i].select = img.createUISprite(img.ui.bag_dianji)
        btnGroup[i].select:setPosition(btnGroup[i]:getContentSize().width/2, btnGroup[i]:getContentSize().height/2 + 2)
        btnGroup[i]:addChild(btnGroup[i].select)
        btnGroup[i].select:setVisible(false)
        btnGroup[i]:registerScriptTapHandler(function()
            --if defaultGroup == i then
                --defaultGroup = nil
                --btnGroup[i].select:setVisible(false)
            --else
                defaultGroup = i
                for j=1, 6 do
                    btnGroup[j].select:setVisible(false)
                end
                btnGroup[defaultGroup].select:setVisible(true)
            --end
            createHerolist()
        end)
    end
    defaultGroup = 1
    btnGroup[1].select:setVisible(true)
    createHerolist()

    local lasty
    local function onTouchBegin(x, y)
        lasty = y
        return true 
    end

    local function onTouchMoved(x, y)
        return true
    end

    local function onTouchEnd(x, y)
        if math.abs(y - lasty) > 10 then
            return
        end
        local pointOnScroll = scroll:getContainer():convertToNodeSpace(ccp(x, y))

        for i, v in ipairs(headIcons) do
            if v:boundingBox():containsPoint(pointOnScroll) then
                onSelect(i)
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
 
    local btnForgeSp = img.createLogin9Sprite(img.login.button_9_gold)
    btnForgeSp:setPreferredSize(CCSize(155, 55))
    local labForge = lbl.createFont1(20, i18n.global.heroforge_btn_text.string, ccc3(0x6a, 0x3d, 0x25))
    labForge:setPosition(btnForgeSp:getContentSize().width/2, btnForgeSp:getContentSize().height/2)
    btnForgeSp:addChild(labForge)

    local btnForge = SpineMenuItem:create(json.ui.button, btnForgeSp)
    btnForge:setPosition(253, 52)
    local menuForge = CCMenu:createWithItem(btnForge)
    menuForge:setPosition(0, 0)
    bg:addChild(menuForge)

    btnForge:registerScriptTapHandler(function()
        local hids = {}
        if not condition then
            return
        end
        for i, v in ipairs(condition) do
            if #v.select >= v.num then
                for j, k in ipairs(v.select) do
                    hids[#hids + 1] = k
                end
            else
                return
            end
        end
        local params = {
            sid = player.sid,
            id = hostId,
            hids = hids,
        }
        addWaitNet()
        net:hero_mix(params, function(__data)
            delWaitNet()

            tbl2string(__data)
            audio.play(audio.hero_forge)
            if __data.status < 0 then
                showToast("status:" .. __data.status)
                return
            end
            
            local activityData = require "data.activity"
            local IDS = activityData.IDS
            local tmp_status = activityData.getStatusById(IDS.FORGE_1.ID)
            if cfghero[__data.hero.id].qlt == 5 then
                tmp_status = activityData.getStatusById(IDS.FORGE_2.ID)
            end
            if tmp_status and tmp_status.limits and tmp_status.limits > 0 then
                tmp_status.limits = tmp_status.limits - 1
            end

            if cfghero[__data.hero.id].qlt == 5 then
                local tmp_status = activityData.getStatusById(IDS.HERO_SUMMON_1.ID)
                if cfghero[__data.hero.id].group == 2 then
                    tmp_status = activityData.getStatusById(IDS.HERO_SUMMON_2.ID)
                end
                if cfghero[__data.hero.id].group == 3 then
                    tmp_status = activityData.getStatusById(IDS.HERO_SUMMON_3.ID)
                end
                if cfghero[__data.hero.id].group == 4 then
                    tmp_status = activityData.getStatusById(IDS.HERO_SUMMON_4.ID)
                end
                if cfghero[__data.hero.id].group == 5 then
                    tmp_status = activityData.getStatusById(IDS.HERO_SUMMON_5.ID)
                end
                if cfghero[__data.hero.id].group == 6 then
                    tmp_status = activityData.getStatusById(IDS.HERO_SUMMON_6.ID)
                end
                if tmp_status and tmp_status.limits and tmp_status.limits < tmp_status.cfg.parameter[1].num then
                    tmp_status.limits = tmp_status.limits + 1
                    local tmp_status7 = activityData.getStatusById(IDS.HERO_SUMMON_7.ID)
                    if tmp_status.limits == tmp_status.cfg.parameter[1].num and tmp_status7.limits < #tmp_status7.cfg.parameter then
                        tmp_status7.limits = tmp_status7.limits + 1
                    end
                end
            end
            heros.add(__data.hero)
            local heroData = heros.find(__data.hero.hid)
            local hostHero = nil
			if hids[1] >= 0 then
				hostHero = heros.find(hids[1])
			end
			if hostHero then
				heroData.equips = hostHero.equips
			end
            local tmpHids = {}
            for i=2, #hids do
				--if hids[i] >= 0 then
					tmpHids[#tmpHids + 1] = hids[i]
				--end
            end
            local exp, evolve, rune = heros.decompose(tmpHids)
            bag.items.add({ id = ITEM_ID_HERO_EXP, num = exp})
            bag.items.add({ id = ITEM_ID_EVOLVE_EXP, num = evolve})
            local reward = {items = {}, equips = {}}
            if exp > 0 then
                table.insert(reward.items,{ id = ITEM_ID_HERO_EXP, num = exp})
            end
            if evolve > 0 then
                table.insert(reward.items,{ id = ITEM_ID_EVOLVE_EXP, num = evolve})
            end
            --bag.items.add({ id = ITEM_ID_RUNE_COIN, num = rune})
            for i, v in ipairs(hids) do
                if i == 1 then
					if v >= 0 then
						heros.del(v, true)
					else
						food.modCount(-v, -1)
					end
                elseif v >= 0 then
                    local heroData = heros.find(v)
                    if heroData then
                        for j, k in ipairs(heroData.equips) do
                            if cfgequip[k].pos == EQUIP_POS_JADE then
                                bag.items.addAll(cfgequip[k].jadeUpgAll)
                                if cfgequip[k].jadeUpgAll[1].num > 0 then
                                    table.insert(reward.items,{ id = cfgequip[k].jadeUpgAll[1].id, num = cfgequip[k].jadeUpgAll[1].num})
                                end
                                if cfgequip[k].jadeUpgAll[2].num > 0 then
                                    table.insert(reward.items,{ id = cfgequip[k].jadeUpgAll[2].id, num = cfgequip[k].jadeUpgAll[2].num})
                                end
                            else
                                table.insert(reward.equips,{ id = k, num = 1})
                            end
                        end
                    end
                    heros.del(v)
				else
					food.modCount(-v, -1)
                end
            end

            anim:playAnimation("animation")
            for i=1, #showAnim do
                showAnim[i]:playAnimation("animation")
            end

            showHeroLayer:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(1.5),
                CCCallFunc:create(function() 
                    layer:addChild(createBoardForRewards(heroData.hid, reward), 1002)
                    loadHero(hostId) 
                    createHerolist()
                end)))
        end)
    end)

    addBackEvent(layer)
    function layer.onAndroidBack()
        replaceScene(require("ui.town.main").create())
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
        elseif event == "cleanup" then
            img.unload(img.packedOthers.ui_hero_forge_bg)
            img.load(img.packedOthers.ui_hero_forge)
        end
    end)
 
    return layer
end 

return ui
