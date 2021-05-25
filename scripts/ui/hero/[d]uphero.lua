local uphero = {}

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
local cfgexphero = require "config.exphero"
local heros = require "data.heros"
local bag = require "data.bag"
local player = require "data.player"
local cfgtalen = require "config.talen"
local food = require "ui.foodbag.data"

local function getMaxWake()
    if player.isSeasonal() then
        return 7
    end
    return 7
end


local function getCondition(hid, id, exstar)
    local condition = {}
    local disillusMaterial = nil

    if exstar >= 5 then
        disillusMaterial = cfgtalen[exstar-4].heroMaterial[1]
    elseif exstar >= 4 then
        local nextId = cfghero[id].nId
        disillusMaterial = cfghero[nextId].disillusMaterial[1]
    else
        disillusMaterial = cfghero[id].disillusMaterial[exstar]
    end
    for i, v in ipairs(disillusMaterial.disi) do
        local isFind = false
        
        if v == 5799 then
            v = cfghero[id].fiveStarId
        end
        for j, k in ipairs(condition) do
            --print("debugv:", k.id, v)
            if k.id == v then
                k.num = k.num + 1
                isFind = true
                break
            end
        end
        
        if not isFind then
            condition[#condition + 1] = { id = v, num = 1, select = {}}
        end
    end
	
	local usedUp = {}
	usedUp[hid] = 1
	for _, v in ipairs(condition) do
		local best = food.getBestFodder(v.id, v.num, v.isHost, true, true, usedUp, 2)
		if #best > 0 then
			for u, k in ipairs(best) do
				v.select[#v.select + 1] = k.hid
			end
			food.appendNotThis(best, usedUp, true)
		end
	end
	
    return condition
end

function uphero.create(heroData, callfuncstar, superlayer)
    local layer = CCLayer:create()

    local w_board = 428
    local h_board = 503
    local board = img.createUI9Sprite(img.ui.hero_bg)
    board:setPreferredSize(CCSize(428, 503))
    board:setAnchorPoint(ccp(0, 0))
    board:setPosition(465, 35 - 20)
    layer:addChild(board)

    local titleStr = i18n.global.hero_wake_title.string
    if heroData.wake and heroData.wake >= 4 then
        titleStr = i18n.global.hero_talen_title.string
    end
    local titleShade = lbl.createFont1(24, titleStr, ccc3(0x59, 0x30, 0x1b))
    titleShade:setPosition(214, 472)
    board:addChild(titleShade)
    local title = lbl.createFont1(24, titleStr, ccc3(0xe6, 0xd0, 0xae))
    title:setPosition(214, 474)
    board:addChild(title)

    local upboard = img.createUI9Sprite(img.ui.hero_up_bottom)
    upboard:setPreferredSize(CCSize(388, 208))
    upboard:setAnchorPoint(0.5, 0)
    upboard:setPosition(w_board/2, 236)
    board:addChild(upboard)
    
	local condition = nil
    local advancedBtn = nil
    local showAnim = {}
    local aniskill = {}
    local upherolayer = nil
    local function createupherolayer(id, exstar, hid)
        local herolayer = CCLayer:create()

        local line = img.createUI9Sprite(img.ui.hero_up_line_deep)
        line:setPreferredSize(CCSize(315, 4))
        line:setPosition(w_board/2, 381)
        herolayer:addChild(line)

        -- 赋能公共部分
        if exstar >= 5 then 

        end

        if exstar == getMaxWake()+1 then
            json.load(json.ui.lv10plus_hero)
            local energizeStar = DHSkeletonAnimation:createWithKey(json.ui.lv10plus_hero)
            energizeStar:scheduleUpdateLua()
            energizeStar:playAnimation("animation", -1)
            energizeStar:setPosition(w_board/2, 400)
            herolayer:addChild(energizeStar)
            local energizeStarLab = lbl.createFont2(26, exstar-4)
            energizeStarLab:setPosition(energizeStar:getContentSize().width/2, -2)
            energizeStar:addChild(energizeStarLab)
            if exstar == getMaxWake()+1 then
                energizeStarLab:setString(exstar-4-1)
            end

            line:setPosition(w_board/2, 360)

            local iconleFlower = img.createUISprite(img.ui.hero_energize_flower)
            iconleFlower:setScale(0.86)
            iconleFlower:setFlipX(true)
            iconleFlower:setPosition(w_board/2-110, 400)
            herolayer:addChild(iconleFlower)
            local iconRFlower = img.createUISprite(img.ui.hero_energize_flower)
            iconRFlower:setScale(0.86)
            iconRFlower:setPosition(w_board/2+110, 400)
            herolayer:addChild(iconRFlower)

            local fgLine = img.createUI9Sprite(img.ui.hero_panel_fgline)
            fgLine:setPreferredSize(CCSize(356, 4))
            fgLine:setPosition(w_board/2, 355)
            herolayer:addChild(fgLine)

            local fazhen = img.createUISprite(img.ui.hero_energize_fazhen)
            fazhen:setPosition(w_board/2, 210)
            herolayer:addChild(fazhen)

            local skillIconBg = {}
            local skillTips = {}
            local px = {54, 135, 217}
            local py = {195, 55, 196}
            local skill1IconBg = nil
            local skill2IconBg = nil
            local skill3IconBg = nil
            local curLev = exstar - 5
            local skill1Id = heros.getHeroSkill(hid, 1)
            if skill1Id == 0 then skill1Id = 6100 end
            local sprskill1IconBg = img.createUISprite(img.ui.hero_skill_bg)
            skill1IconBg = CCMenuItemSprite:create(sprskill1IconBg, nil)
            skill1IconBg:setScale(0.65)
            local menuskill1IconBg = CCMenu:createWithItem(skill1IconBg)
            menuskill1IconBg:setPosition(0, 0)
            skill1IconBg:setPosition(px[1], py[1])
            fazhen:addChild(menuskill1IconBg, 100)
            local skill1Icon = img.createSkill(skill1Id)
            skill1Icon:setPosition(skill1IconBg:getContentSize().width/2, skill1IconBg:getContentSize().height/2)
            skill1IconBg:addChild(skill1Icon)
            skill1IconBg:registerScriptTapHandler(function()
                audio.play(audio.button)
                local function fnCallback()
                    if upherolayer then
                        upherolayer:removeFromParentAndCleanup()
                        upherolayer = nil
                    end
                    upherolayer = createupherolayer(heroData.id, heroData.wake + 1, heroData.hid)
                    board:addChild(upherolayer)
                end
                local talenSkill = require "ui.hero.talenskill"
                local talenUi = talenSkill.create(curLev, 1, hid, fnCallback)
                superlayer:addChild(talenUi, 2000)
            end)
            local skill2Id = heros.getHeroSkill(hid, 2)
            if skill2Id == 0 then skill2Id = 6100 end
            local sprskill2IconBg = img.createUISprite(img.ui.hero_skill_bg)
            skill2IconBg = CCMenuItemSprite:create(sprskill2IconBg, nil)
            skill2IconBg:setScale(0.65)
            local menuskill2IconBg = CCMenu:createWithItem(skill2IconBg)
            menuskill2IconBg:setPosition(0, 0)
            skill2IconBg:setPosition(px[2], py[2])
            fazhen:addChild(menuskill2IconBg, 100)
            local skill2Icon = img.createSkill(skill2Id)
            skill2Icon:setPosition(skill2IconBg:getContentSize().width/2, skill2IconBg:getContentSize().height/2)
            skill2IconBg:addChild(skill2Icon)
            skill2IconBg:registerScriptTapHandler(function()
                audio.play(audio.button)
                local function fnCallback()
                    if upherolayer then
                        upherolayer:removeFromParentAndCleanup()
                        upherolayer = nil
                    end
                    upherolayer = createupherolayer(heroData.id, heroData.wake + 1, heroData.hid)
                    board:addChild(upherolayer)
                end
                local talenSkill = require "ui.hero.talenskill"
                local talenUi = talenSkill.create(curLev, 2, hid, fnCallback)
                superlayer:addChild(talenUi, 2000)
            end)
            local skill3Id = heros.getHeroSkill(hid, 3)
            if skill3Id == 0 then skill3Id = 6100 end
            local sprskill3IconBg = img.createUISprite(img.ui.hero_skill_bg)
            skill3IconBg = CCMenuItemSprite:create(sprskill3IconBg, nil)
            skill3IconBg:setScale(0.65)
            local menuskill3IconBg = CCMenu:createWithItem(skill3IconBg)
            menuskill3IconBg:setPosition(0, 0)
            skill3IconBg:setPosition(px[3], py[3])
            fazhen:addChild(menuskill3IconBg, 100)
            local skill3Icon = img.createSkill(skill3Id)
            skill3Icon:setPosition(skill3IconBg:getContentSize().width/2, skill3IconBg:getContentSize().height/2)
            skill3IconBg:addChild(skill3Icon)
            skill3IconBg:registerScriptTapHandler(function()
                audio.play(audio.button)
                local function fnCallback()
                    if upherolayer then
                        upherolayer:removeFromParentAndCleanup()
                        upherolayer = nil
                    end
                    upherolayer = createupherolayer(heroData.id, heroData.wake + 1, heroData.hid)
                    board:addChild(upherolayer)
                end
                local talenSkill = require "ui.hero.talenskill"
                local talenUi = talenSkill.create(curLev, 3, hid, fnCallback)
                superlayer:addChild(talenUi, 2000)
            end)


            line:setVisible(false)
            upboard:setVisible(false)
            if advancedBtn then
                advancedBtn:setVisible(false)
            end

            local wakefullStr = i18n.global.hero_talen_talen_full.string
            local wakefulltip = lbl.createMixFont1(16, wakefullStr, ccc3(0x73, 0x3b, 0x05))
            wakefulltip:setPosition(w_board/2, 58)
            herolayer:addChild(wakefulltip)

            local function onTouch(eventType, x, y)
                return true
            end
            herolayer:registerScriptTouchHandler(onTouch)
            herolayer:setTouchEnabled(true)
            herolayer:setTouchSwallowEnabled(false)

            return herolayer
        end

        if exstar == 4 and cfghero[id].nId == nil then
            local redstar = exstar
            local sx1 = w_board/2 - 15*(redstar-1)
            local dx = 30
            if redstar == getMaxWake()+1 then
            else
                for i = 1,redstar do
                    local starIcon1 = img.createUISprite(img.ui.hero_star_orange)
                    starIcon1:setScale(0.9)
                    starIcon1:setPosition(sx1+(i-1)*dx, 407)
                    herolayer:addChild(starIcon1)
                end
            end

            local wakefullStr = i18n.global.hero_wake_wake_full.string
            local wakefulltip = lbl.createMixFont1(16, wakefullStr, ccc3(0xda, 0xce, 0xb0))
            wakefulltip:setPosition(w_board/2, 324)
            herolayer:addChild(wakefulltip)
            if heroData.wake >= 4 then
                wakefullStr = i18n.global.hero_talen_talen_full.string
                wakefulltip:setString(wakefullStr)
                wakefulltip:setPosition(w_board/2, 310)
            end

            local costbg = img.createUI9Sprite(img.ui.hero_evolve_cost_bg)
            costbg:setPreferredSize(CCSize(186, 32))
            costbg:setPosition(w_board/2 + 75, 118)
            herolayer:addChild(costbg)
            local stoneIcon = img.createItemIcon(ITEM_ID_EVOLVE_EXP)
            stoneIcon:setScale(0.55)
            stoneIcon:setPosition(7, costbg:getContentSize().height/2)
            costbg:addChild(stoneIcon)
            local evolvenum = 0
            if bag.items.find(ITEM_ID_EVOLVE_EXP) then
                evolvenum = bag.items.find(ITEM_ID_EVOLVE_EXP).num
            end
            local showEvolveAll = lbl.createFont2(16, string.format("%d/%d", evolvenum, 0), ccc3(0xff, 0xf7, 0xe5))
            showEvolveAll:setPosition(costbg:getContentSize().width/2 + 5, costbg:getContentSize().height/2 + 2)
            costbg:addChild(showEvolveAll)


            return herolayer 
        end

        condition = getCondition(hid, id, exstar)
        -- 赋能界面
        if exstar >= 5 then
            json.load(json.ui.lv10plus_hero)
            local energizeStar = DHSkeletonAnimation:createWithKey(json.ui.lv10plus_hero)
            energizeStar:scheduleUpdateLua()
            energizeStar:playAnimation("animation", -1)
            energizeStar:setPosition(w_board/2, 400)
            herolayer:addChild(energizeStar)
            local energizeStarLab = lbl.createFont2(26, exstar-4)
            energizeStarLab:setPosition(energizeStar:getContentSize().width/2, 0)
            energizeStar:addChild(energizeStarLab)
            energizeStar:setScale(0.72)
            if exstar == getMaxWake()+1 then
                energizeStarLab:setString(exstar-4-1)
            end

            line:setPosition(w_board/2, 360)

            local iconleFlower = img.createUISprite(img.ui.hero_energize_flower)
            iconleFlower:setScale(0.86)
            iconleFlower:setFlipX(true)
            iconleFlower:setPosition(w_board/2-85, 400)
            herolayer:addChild(iconleFlower)
            local iconRFlower = img.createUISprite(img.ui.hero_energize_flower)
            iconRFlower:setScale(0.86)
            iconRFlower:setPosition(w_board/2+85, 400)
            herolayer:addChild(iconRFlower)
            --[[local skillDetail = img.createUISprite(img.ui.hero_energize_skillbtn)
            local skillDetailBtn = SpineMenuItem:create(json.ui.button, skillDetail)
            skillDetailBtn:setPosition(CCPoint(w_board/2+138, 395))
            local skillDetailMenu = CCMenu:createWithItem(skillDetailBtn)
            skillDetailMenu:setPosition(0, 0)
            board:addChild(skillDetailMenu)

            skillDetailBtn:registerScriptTapHandler(function()
                audio.play(audio.button)
                local talenSkill = require "ui.hero.talenskill"
                superlayer:addChild(talenSkill.create(exstar-4-1), 2000)
            end)--]]
            local skill1IconBg = nil
            local skill2IconBg = nil
            local skill3IconBg = nil
            local curLev = exstar - 5
            local upboardc = img.createUI9Sprite(img.ui.hero_up_bottom)
            upboardc:setPreferredSize(CCSize(138, 208))
            upboardc:setPosition(188 / 2 + 10, 128)
            board:addChild(upboardc)
            local skill1Id = heros.getHeroSkill(hid, 1)
            if skill1Id == 0 then skill1Id = 6100 end
            local sprskill1IconBg = img.createUISprite(img.ui.hero_skill_bg)
            skill1IconBg = CCMenuItemSprite:create(sprskill1IconBg, nil)
            skill1IconBg:setScale(0.65)
            local menuskill1IconBg = CCMenu:createWithItem(skill1IconBg)
            menuskill1IconBg:setPosition(0, 0)
            skill1IconBg:setPosition(188 / 2 + 10, 186)
            herolayer:addChild(menuskill1IconBg, 100)
            local skill1Icon = img.createSkill(skill1Id)
            skill1Icon:setPosition(skill1IconBg:getContentSize().width/2, skill1IconBg:getContentSize().height/2)
            skill1IconBg:addChild(skill1Icon)
            if curLev < 1 then
                setShader(skill1IconBg, SHADER_GRAY, true)
                local showLock = img.createUISprite(img.ui.devour_icon_lock)
                showLock:setPosition(skill1IconBg:getContentSize().width/2, skill1IconBg:getContentSize().height/2)
                skill1IconBg:addChild(showLock)
            end
            skill1IconBg:registerScriptTapHandler(function()
                audio.play(audio.button)
                local function fnCallback()
                    if upherolayer then
                        upherolayer:removeFromParentAndCleanup()
                        upherolayer = nil
                    end
                    upherolayer = createupherolayer(heroData.id, heroData.wake + 1, heroData.hid)
                    board:addChild(upherolayer)
                end
                local talenSkill = require "ui.hero.talenskill"
                local talenUi = talenSkill.create(curLev, 1, hid, fnCallback)
                superlayer:addChild(talenUi, 2000)
            end)
            local upboardc = img.createUI9Sprite(img.ui.hero_up_bottom)
            upboardc:setPreferredSize(CCSize(138, 208))
            upboardc:setPosition(188 / 2 + 10, 128)
            board:addChild(upboardc)
            local skill2Id = heros.getHeroSkill(hid, 2)
            if skill2Id == 0 then skill2Id = 6100 end
            local sprskill2IconBg = img.createUISprite(img.ui.hero_skill_bg)
            skill2IconBg = CCMenuItemSprite:create(sprskill2IconBg, nil)
            skill2IconBg:setScale(0.65)
            local menuskill2IconBg = CCMenu:createWithItem(skill2IconBg)
            menuskill2IconBg:setPosition(0, 0)
            skill2IconBg:setPosition(188 / 2 + 10, 126)
            herolayer:addChild(menuskill2IconBg, 100)
            local skill2Icon = img.createSkill(skill2Id)
            skill2Icon:setPosition(skill2IconBg:getContentSize().width/2, skill2IconBg:getContentSize().height/2)
            skill2IconBg:addChild(skill2Icon)
            if curLev < 2 then
                setShader(skill2IconBg, SHADER_GRAY, true)
                local showLock = img.createUISprite(img.ui.devour_icon_lock)
                showLock:setPosition(skill2IconBg:getContentSize().width/2, skill2IconBg:getContentSize().height/2)
                skill2IconBg:addChild(showLock)
            end
            skill2IconBg:registerScriptTapHandler(function()
                audio.play(audio.button)
                local function fnCallback()
                    if upherolayer then
                        upherolayer:removeFromParentAndCleanup()
                        upherolayer = nil
                    end
                    upherolayer = createupherolayer(heroData.id, heroData.wake + 1, heroData.hid)
                    board:addChild(upherolayer)
                end
                local talenSkill = require "ui.hero.talenskill"
                local talenUi = talenSkill.create(curLev, 2, hid, fnCallback)
                superlayer:addChild(talenUi, 2000)
            end)
            local upboardc = img.createUI9Sprite(img.ui.hero_up_bottom)
            upboardc:setPreferredSize(CCSize(138, 208))
            upboardc:setPosition(188 / 2 + 10, 128)
            board:addChild(upboardc)
            local skill3Id = heros.getHeroSkill(hid, 3)
            if skill3Id == 0 then skill3Id = 6100 end
            local sprskill3IconBg = img.createUISprite(img.ui.hero_skill_bg)
            skill3IconBg = CCMenuItemSprite:create(sprskill3IconBg, nil)
            skill3IconBg:setScale(0.65)
            local menuskill3IconBg = CCMenu:createWithItem(skill3IconBg)
            menuskill3IconBg:setPosition(0, 0)
            skill3IconBg:setPosition(188 / 2 + 10, 66)
            herolayer:addChild(menuskill3IconBg, 100)
            local skill3Icon = img.createSkill(skill3Id)
            skill3Icon:setPosition(skill3IconBg:getContentSize().width/2, skill3IconBg:getContentSize().height/2)
            skill3IconBg:addChild(skill3Icon)
            if curLev < 3 then
                setShader(skill3IconBg, SHADER_GRAY, true)
                local showLock = img.createUISprite(img.ui.devour_icon_lock)
                showLock:setPosition(skill3IconBg:getContentSize().width/2, skill3IconBg:getContentSize().height/2)
                skill3IconBg:addChild(showLock)
            end
            skill3IconBg:registerScriptTapHandler(function()
                audio.play(audio.button)
                local function fnCallback()
                    if upherolayer then
                        upherolayer:removeFromParentAndCleanup()
                        upherolayer = nil
                    end
                    upherolayer = createupherolayer(heroData.id, heroData.wake + 1, heroData.hid)
                    board:addChild(upherolayer)
                end
                local talenSkill = require "ui.hero.talenskill"
                local talenUi = talenSkill.create(curLev, 3, hid, fnCallback)
                superlayer:addChild(talenUi, 2000)
            end)

            line:setPosition(w_board/2, 362)
            local levelLab = lbl.createMixFont1(16, i18n.global.hero_wake_level_up.string, ccc3(0xfd, 0xeb, 0x87))
            levelLab:setAnchorPoint(1, 0.5)
            levelLab:setPosition(w_board/2-40, 337)
            herolayer:addChild(levelLab)
            local levelCap = lbl.createFont1(16, cfgtalen[exstar-4].addMaxLv, ccc3(0x9d, 0xf4, 0x26))
            levelCap:setAnchorPoint(0, 0.5)
            levelCap:setPosition(CCPoint(levelLab:boundingBox():getMaxX() + 15, 337))
            herolayer:addChild(levelCap)
            for ii = 1, #cfgtalen[exstar-4].base do 
                local cfgvalue = math.abs(cfgtalen[exstar-4].base[ii].num)
                if exstar - 4 > 1 then
                    cfgvalue = math.abs(cfgtalen[exstar-4].base[ii].num) - math.abs(cfgtalen[exstar-5].base[ii].num)
                end
                local name1, value1 = buffString(cfgtalen[exstar-4].base[ii].type, cfgvalue)
                local attrLab1 = lbl.createMixFont1(16, name1 .. ":", ccc3(0xfd, 0xeb, 0x87))
                attrLab1:setAnchorPoint(1, 0.5)
                attrLab1:setPosition(w_board/2-40, 337 - 28*ii)
                herolayer:addChild(attrLab1)
                local attrNum1 = lbl.createFont1(16, "+" .. value1, ccc3(0x9d, 0xf4, 0x26))
                attrNum1:setAnchorPoint(0, 0.5)
                attrNum1:setPosition(CCPoint(attrLab1:boundingBox():getMaxX() + 15, 337 - 28*ii))
                herolayer:addChild(attrNum1)
            end

            local unlockLab = lbl.createMixFont1(16, i18n.global.hero_unlock.string, ccc3(0xfd, 0xeb, 0x87))
            unlockLab:setPosition(280+35, 337)
            herolayer:addChild(unlockLab)

            local levelCap = lbl.createFont1(16, cfgtalen[exstar-4].addMaxLv, ccc3(0x9d, 0xf4, 0x26))
            local skillId = 6100
            local skillIconBg = img.createUISprite(img.ui.hero_skill_bg)
            skillIconBg:setScale(0.75)
            skillIconBg:setPosition(280+35, 295)
            herolayer:addChild(skillIconBg, 100)
            local skillIcon = img.createSkill(skillId)
            skillIcon:setPosition(skillIconBg:getContentSize().width/2, skillIconBg:getContentSize().height/2)
            skillIconBg:addChild(skillIcon)
            local skillTips = require("ui.tips.skill").create(skillId)
            skillTips:setAnchorPoint(ccp(1, 0))
            skillTips:setPosition(409, skillIconBg:boundingBox():getMaxY())
            herolayer:addChild(skillTips)
            skillTips:setVisible(false)

            local selectsx = 170
            if #condition == 3 then
                selectsx = selectsx + 40
            end
            if #condition == 2 then
                selectsx = selectsx + 80
            end
            if #condition == 1 then
                selectsx = selectsx + 120
            end
            for i, v in ipairs(condition) do
                local btnSp
                btnSp = img.createHeroHead(v.id, nil, true, true)
                local btnHero = CCMenuItemSprite:create(btnSp, nil)
                btnHero:setScale(0.67)
                btnHero:setPosition(selectsx + (i-1) * 80, 196)
                local menuHero = CCMenu:createWithItem(btnHero)
                menuHero:setPosition(0, 0)
                herolayer:addChild(menuHero)

                local showNum = lbl.createFont2(16, "0/" .. v.num)
                showNum:setPosition(btnHero:boundingBox():getMidX(), 154)
                herolayer:addChild(showNum)
                setShader(btnHero, SHADER_GRAY, true)

                json.load(json.ui.sheng_xing2)
                showAnim[i] = DHSkeletonAnimation:createWithKey(json.ui.sheng_xing2)
                showAnim[i]:scheduleUpdateLua()
                showAnim[i]:stopAnimation()
                --showAnim[i]:playAnimation("animation", -1)
                showAnim[i]:setPosition(btnHero:boundingBox():getMidX(), btnHero:boundingBox():getMidY())
                --showAnim[i]:setScale(btnHero:getScale())
                herolayer:addChild(showAnim[i], 1001)
                
                local icon = img.createUISprite(img.ui.hero_equip_add)
                icon:setScale(0.8)
                icon:setPosition(btnHero:boundingBox():getMaxX() - 18, btnHero:boundingBox():getMaxY() - 18)
                herolayer:addChild(icon)
                icon:runAction(CCRepeatForever:create(CCSequence:createWithTwoActions(
                    CCFadeTo:create(0.5, 255 * 0.3), CCFadeTo:create(0.5, 255))))
					
				local function func()
					showNum:setString(#v.select .. "/" .. v.num)
					if #v.select < v.num then
						setShader(btnHero, SHADER_GRAY, true)
						showNum:setColor(ccc3(0xff, 0xff, 0xff))
					else
						clearShader(btnHero, true)
						showNum:setColor(ccc3(0xc3, 0xff, 0x42))
					end
				end
                
                btnHero:registerScriptTapHandler(function() 
                    local selFull = { hid }
					for j, k in ipairs(condition) do
						if j ~= i then
							for _, w in ipairs(k.select) do
								selFull[#selFull + 1] = w
							end
						end
					end
                    superlayer:addChild(require ("ui.foodbag.main").createSelectBoard(v.id, v.num, false, true, true, selFull, v.select, func), 2000)
                end)
				
				func()
            end

            local costbg = img.createUI9Sprite(img.ui.hero_evolve_cost_bg)
            costbg:setPreferredSize(CCSize(185, 32))
            costbg:setPosition(w_board/2 + 75, 118)
            herolayer:addChild(costbg)
            local stoneIcon = img.createItemIcon(ITEM_ID_EVOLVE_EXP)
            stoneIcon:setScale(0.55)
            stoneIcon:setPosition(7, costbg:getContentSize().height/2)
            costbg:addChild(stoneIcon)
            local evolvenum = 0
            if bag.items.find(ITEM_ID_EVOLVE_EXP) then
                evolvenum = bag.items.find(ITEM_ID_EVOLVE_EXP).num
            end

            local stoneMaterial = 0
            stoneMaterial = cfgtalen[exstar-4].stoneMaterial
            local showEvolveAll = lbl.createFont2(16, string.format("%d/%d", evolvenum, stoneMaterial), ccc3(0xff, 0xf7, 0xe5))
            showEvolveAll:setPosition(costbg:getContentSize().width/2 + 5, costbg:getContentSize().height/2)
            costbg:addChild(showEvolveAll)

            local function onTouch(eventType, x, y)
                return true
            end
            herolayer:registerScriptTouchHandler(onTouch)
            herolayer:setTouchEnabled(true)
            herolayer:setTouchSwallowEnabled(false)
            return herolayer 
        end

        local sx1 = 90
        local dx = 25
        local sx2 = 265
        
        for i = 1,exstar do
            local starIcon1 = img.createUISprite(img.ui.hero_star_orange)
            starIcon1:setScale(0.9)
            starIcon1:setPosition(sx1+(i-1)*dx, 407)
            herolayer:addChild(starIcon1)
            --local starIcon2 = img.createUISprite(img.ui.hero_star_orange)
            --starIcon2:setScale(0.9)
            --starIcon2:setPosition(sx2+(i-1)*dx, 407)
            --herolayer:addChild(starIcon2)
        end
        for i = exstar+1,4 do
            local starIcon1 = img.createUISprite(img.ui.hero_up_nstar)
            --starIcon1:setScale(0.9)
            starIcon1:setPosition(sx1+(i-1)*dx, 407)
            herolayer:addChild(starIcon1)
            if i ~= exstar+1 then
                local starIcon2 = img.createUISprite(img.ui.hero_up_nstar)
                --starIcon2:setScale(0.9)
                starIcon2:setPosition(sx2+(i-1)*dx, 407)
                herolayer:addChild(starIcon2)
            end
        end
        if exstar == 4 and player.isSeasonal() then
            json.load(json.ui.lv10plus_hero)
            local energizeStar = DHSkeletonAnimation:createWithKey(json.ui.lv10plus_hero)
            energizeStar:scheduleUpdateLua()
            energizeStar:playAnimation("animation", -1)
            energizeStar:setPosition(sx2+dx, 407)
            energizeStar:setScale(0.65)
            herolayer:addChild(energizeStar)
            local energizeStarLab = lbl.createFont2(26, 3)
            energizeStarLab:setPosition(energizeStar:getContentSize().width/2, -2)
            energizeStar:addChild(energizeStarLab)
            --line:setPosition(w_board/2, 360)
            --[[local iconleFlower = img.createUISprite(img.ui.hero_energize_flower)
            iconleFlower:setScale(0.86)
            iconleFlower:setFlipX(true)
            iconleFlower:setPosition(sx2+dx-110, 407)
            herolayer:addChild(iconleFlower)
            local iconRFlower = img.createUISprite(img.ui.hero_energize_flower)
            iconRFlower:setScale(0.86)
            iconRFlower:setPosition(sx2+dx+110, 407)
            herolayer:addChild(iconRFlower)--]]
        elseif exstar == 4 then
            local starIcon2 = img.createUISprite(img.ui.hero_star_ten)
            starIcon2:setScale(0.9)
            starIcon2:setPosition(sx2+dx, 407)
            herolayer:addChild(starIcon2)
        else
            for i = 1,exstar+1 do
                local starIcon2 = img.createUISprite(img.ui.hero_star_orange)
                starIcon2:setScale(0.9)
                starIcon2:setPosition(sx2+(i-1)*dx, 407)
                herolayer:addChild(starIcon2)
            end
        end
        
        -- raw
        local starraw = img.createUISprite(img.ui.hero_btn_raw)
        starraw:setScale(0.33)
        starraw:setPosition(w_board/2, 407)
        herolayer:addChild(starraw)

        local skillraw = img.createUISprite(img.ui.hero_btn_raw)
        skillraw:setScale(0.75)
        skillraw:setPosition(w_board/2, 337)
        herolayer:addChild(skillraw)

        -- skill
        local skillId1 = cfghero[id].actSkillId
        local skillId2 = cfghero[id].actSkillId
        local nextId = nil
        if exstar >= 4 then
            nextId = cfghero[id].nId
            skillId2 = cfghero[nextId].actSkillId
        else
            if heroData.wake then
                skillId1 = cfghero[id].disillusSkill[heroData.wake].disi[1]
            end
            if skillId1 ~= cfghero[id].disillusSkill[exstar].disi[1] then
                skillId2 = cfghero[id].disillusSkill[exstar].disi[1]
            end
            if skillId1 == skillId2 then
                for i=1, 3 do
                    if heroData.wake then
                        skillId1 = cfghero[id].disillusSkill[heroData.wake].disi[i+1]
                    else
                        skillId1 = cfghero[id]["pasSkill" .. i .. "Id"]
                    end
                    if skillId1 ~= cfghero[id].disillusSkill[exstar].disi[i+1] then
                        skillId2 = cfghero[id].disillusSkill[exstar].disi[i+1]
                        break
                    end
                end
            end
        end
		
		if heroData.hskills then
			skillId1 = 6100
			skillId2 = 6100
		end

        local skillIconBg1 = img.createUISprite(img.ui.hero_skill_bg)
        skillIconBg1:setScale(0.75)
        skillIconBg1:setPosition(130, 337)
        herolayer:addChild(skillIconBg1, 100)
        local skillIcon1 = img.createSkill(skillId1)
        skillIcon1:setPosition(skillIconBg1:getContentSize().width/2, skillIconBg1:getContentSize().height/2)
        skillIconBg1:addChild(skillIcon1)

        json.load(json.ui.sheng_xing1)
        aniskill[1] = DHSkeletonAnimation:createWithKey(json.ui.sheng_xing1)
        aniskill[1]:scheduleUpdateLua()
        aniskill[1]:setPosition(skillIconBg1:boundingBox():getMidX(), skillIconBg1:boundingBox():getMidY())
        aniskill[1]:setVisible(false)
        herolayer:addChild(aniskill[1], 100)

        local skillTips1 = require("ui.tips.skill").create(skillId1)
        skillTips1:setAnchorPoint(ccp(1, 0))
        skillTips1:setPosition(409, skillIconBg1:boundingBox():getMaxY())
        herolayer:addChild(skillTips1)
        skillTips1:setVisible(false)

        local skillIconBg2 = img.createUISprite(img.ui.hero_skill_bg)
        skillIconBg2:setScale(0.75)
        skillIconBg2:setPosition(297, 337)
        herolayer:addChild(skillIconBg2, 100)
        local skillIcon2 = img.createSkill(skillId2)
        skillIcon2:setPosition(skillIconBg2:getContentSize().width/2, skillIconBg2:getContentSize().height/2)
        skillIconBg2:addChild(skillIcon2)

        if exstar < 4 then
            local skillLB1 = img.createUISprite(img.ui.hero_skilllevel_bg)
            skillLB1:setPosition(skillIconBg1:getContentSize().width-15, skillIconBg1:getContentSize().height-15)
            skillIconBg1:addChild(skillLB1)
            local skilllab1 = lbl.createFont1(18, "2", ccc3(255, 246, 223))
            skilllab1:setPosition(skillLB1:getContentSize().width/2, skillLB1:getContentSize().height/2)
            skillLB1:addChild(skilllab1)
            local skillLB2 = img.createUISprite(img.ui.hero_skilllevel_bg)
            skillLB2:setPosition(skillIconBg2:getContentSize().width-15, skillIconBg2:getContentSize().height-15)
            skillIconBg2:addChild(skillLB2)
            local skilllab2 = lbl.createFont1(18, "3", ccc3(255, 246, 223))
            skilllab2:setPosition(skillLB2:getContentSize().width/2, skillLB2:getContentSize().height/2)
            skillLB2:addChild(skilllab2)
        end

        aniskill[2] = DHSkeletonAnimation:createWithKey(json.ui.sheng_xing1)
        aniskill[2]:scheduleUpdateLua()
        aniskill[2]:setVisible(false)
        --aniskill[2]:playAnimation("animation", -1)
        aniskill[2]:setPosition(skillIconBg2:boundingBox():getMidX(), skillIconBg2:boundingBox():getMidY())
        herolayer:addChild(aniskill[2], 100)
        local skillTips2 = require("ui.tips.skill").create(skillId2)
        skillTips2:setAnchorPoint(ccp(1, 0))
        skillTips2:setPosition(409, skillIconBg2:boundingBox():getMaxY())
        herolayer:addChild(skillTips2)
        skillTips2:setVisible(false)

        local function onTouch(eventType, x, y)
            local point = herolayer:convertToNodeSpace(ccp(x, y))
            --for i, v in ipairs(showSkill) do
                if skillIconBg1:boundingBox():containsPoint(point) then
                    skillTips1:setVisible(true)
                else
                    skillTips1:setVisible(false)
                end
                if skillIconBg2:boundingBox():containsPoint(point) then
                    skillTips2:setVisible(true)
                else
                    skillTips2:setVisible(false)
                end
            --end

            if eventType ~= "began" and eventType ~= "moved" then
                --for i, v in ipairs(skillTips) do
                    skillTips1:setVisible(false)
                    skillTips2:setVisible(false)
                --end
            end
            return true
        end
        herolayer:registerScriptTouchHandler(onTouch)
        herolayer:setTouchEnabled(true)
        herolayer:setTouchSwallowEnabled(false)

        local attrlab = lbl.createMixFont1(14, i18n.global.hero_wake_attr_up_out.string, ccc3(255, 246, 223))
        attrlab:setPosition(w_board/2-22, 289)
        herolayer:addChild(attrlab)
        local toattr = lbl.createFont1(14, "20%", ccc3(0x9d, 0xf4, 0x26))
        toattr:setAnchorPoint(0, 0.5)
        toattr:setPosition(CCPoint(attrlab:boundingBox():getMaxX() + 10, 288))
        herolayer:addChild(toattr)

        local lvMax = cfghero[heroData.id]["starLv" .. (heroData.star + 1)] or cfghero[heroData.id].maxLv
        if heroData.wake then
            lvMax = lvMax + heroData.wake*20
        end
        local lvlab = lbl.createMixFont1(14, i18n.global.hero_wake_level_up_out.string, ccc3(255,246, 223))
        lvlab:setPosition(w_board/2-21, 270)
        herolayer:addChild(lvlab)
        local tolv = lbl.createFont1(14, lvMax+20, ccc3(0x9d, 0xf4, 0x26))
        tolv:setAnchorPoint(0, 0.5)
        tolv:setPosition(CCPoint(lvlab:boundingBox():getMaxX() + 10, 269))
        herolayer:addChild(tolv)
        if exstar == 4 then
            toattr:setString("30%")
            if player.isSeasonal() then
                tolv:setString(290)
            else
                tolv:setString(lvMax+50)
            end
        end

        -- marti
        local selectsx = 95
        if #condition == 3 then
            selectsx = selectsx + 40
        end
        if #condition == 2 then
            selectsx = selectsx + 80
        end
        if #condition == 1 then
            selectsx = selectsx + 120
        end
        for i, v in ipairs(condition) do
            local btnSp
            btnSp = img.createHeroHead(v.id, nil, true, true)
            local btnHero = CCMenuItemSprite:create(btnSp, nil)
            btnHero:setScale(0.67)
            btnHero:setPosition(selectsx + (i-1) * 80, 196)
            local menuHero = CCMenu:createWithItem(btnHero)
            menuHero:setPosition(0, 0)
            herolayer:addChild(menuHero)

            local showNum = lbl.createFont2(16, "0/" .. v.num)
            showNum:setPosition(btnHero:boundingBox():getMidX(), 154)
            herolayer:addChild(showNum)
            setShader(btnHero, SHADER_GRAY, true)

            json.load(json.ui.sheng_xing2)
            showAnim[i] = DHSkeletonAnimation:createWithKey(json.ui.sheng_xing2)
            showAnim[i]:scheduleUpdateLua()
            showAnim[i]:stopAnimation()
            --showAnim[i]:playAnimation("animation", -1)
            showAnim[i]:setPosition(btnHero:boundingBox():getMidX(), btnHero:boundingBox():getMidY())
            --showAnim[i]:setScale(btnHero:getScale())
            herolayer:addChild(showAnim[i], 1001)
            
            local icon = img.createUISprite(img.ui.hero_equip_add)
            icon:setScale(0.8)
            icon:setPosition(btnHero:boundingBox():getMaxX() - 18, btnHero:boundingBox():getMaxY() - 18)
            herolayer:addChild(icon)
            icon:runAction(CCRepeatForever:create(CCSequence:createWithTwoActions(
                CCFadeTo:create(0.5, 255 * 0.3), CCFadeTo:create(0.5, 255))))
				
			local function func()
				showNum:setString(#v.select .. "/" .. v.num)
				if #v.select < v.num then
					setShader(btnHero, SHADER_GRAY, true)
					showNum:setColor(ccc3(0xff, 0xff, 0xff))
				else
					clearShader(btnHero, true)
					showNum:setColor(ccc3(0xc3, 0xff, 0x42))
				end
			end
            
            btnHero:registerScriptTapHandler(function() 
				local selFull = { hid }
				for j, k in ipairs(condition) do
					if j ~= i then
						for _, w in ipairs(k.select) do
							selFull[#selFull + 1] = w
						end
					end
				end
                superlayer:addChild(require ("ui.foodbag.main").createSelectBoard(v.id, v.num, false, true, true, selFull, v.select, func), 2000)
            end)
			
			func()
        end

        -- costevolve
        local costbg = img.createUI9Sprite(img.ui.hero_evolve_cost_bg)
        costbg:setPreferredSize(CCSize(185, 32))
        costbg:setPosition(w_board/2, 118)
        herolayer:addChild(costbg)
        local stoneIcon = img.createItemIcon(ITEM_ID_EVOLVE_EXP)
        stoneIcon:setScale(0.55)
        stoneIcon:setPosition(7, costbg:getContentSize().height/2)
        costbg:addChild(stoneIcon)
        local evolvenum = 0
        if bag.items.find(ITEM_ID_EVOLVE_EXP) then
            evolvenum = bag.items.find(ITEM_ID_EVOLVE_EXP).num
        end
        
        local stoneMaterial = 0
        if exstar >= 4 then
            stoneMaterial = cfghero[nextId].stoneMaterial[1]
        else
            stoneMaterial = cfghero[id].stoneMaterial[exstar]
        end
        local showEvolveAll = lbl.createFont2(16, string.format("%d/%d", evolvenum, stoneMaterial), ccc3(0xff, 0xf7, 0xe5))
        showEvolveAll:setPosition(costbg:getContentSize().width/2 + 5, costbg:getContentSize().height/2)
        costbg:addChild(showEvolveAll)

        return herolayer
    end

    local wake = 0
    if heroData.wake then
        wake = heroData.wake
    end

    upherolayer = createupherolayer(heroData.id, wake+1, heroData.hid)
    board:addChild(upherolayer)

    local advancedSprite = img.createLogin9Sprite(img.login.button_9_small_gold)
    advancedSprite:setPreferredSize(CCSizeMake(185, 54))
    advancedBtn = SpineMenuItem:create(json.ui.button, advancedSprite)
    if wake + 1 >= 5 then advancedBtn:setPosition(CCPoint(w_board/2 + 75, 60))
    else advancedBtn:setPosition(CCPoint(w_board/2, 60)) end

    local receiptallMenu = CCMenu:createWithItem(advancedBtn)
    receiptallMenu:setPosition(0, 0)
    board:addChild(receiptallMenu)
    if wake == getMaxWake() then
        advancedBtn:setVisible(false)
    end

    local advancedStr = i18n.global.hero_wake_btn.string
    if wake >= 4 then
        advancedStr = i18n.global.hero_btn_talenl.string
    end
    local advancedLab = lbl.createFont1(18, advancedStr, ccc3(0x73, 0x3b, 0x05))
    advancedLab:setPosition(CCPoint(advancedBtn:getContentSize().width/2, advancedBtn:getContentSize().height/2))
    advancedSprite:addChild(advancedLab)

    advancedBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        if (wake == 3 and cfghero[heroData.id].nId == nil) then
            showToast(i18n.global.hero_wake_wake_full.string)
            return 
        end
        if wake == getMaxWake() then
            showToast(i18n.global.hero_talen_talen_full.string)
            return 
        end
        local evolvenum = 0
        if bag.items.find(ITEM_ID_EVOLVE_EXP) then
            evolvenum = bag.items.find(ITEM_ID_EVOLVE_EXP).num
        end
        
        -- 附能
        if wake >= 4 then
            if evolvenum < cfgtalen[wake-3].stoneMaterial then
                showToast(i18n.global.toast_hero_need_evolve.string)
                return
            end
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
                    showToast(i18n.global.hero_wake_no_hero.string)
                    return
                end
            end
            -- 赋能
            local params = {
                sid = player.sid,
                hid = heroData.hid,
                source = hids
            }
            tbl2string(params)
            addWaitNet()
            net:hero_talen(params, function(__data)
                delWaitNet()
                tbl2string(__data)
                if __data.status < 0 then
                    showToast("status:" .. __data.status)
                    return
                end
                local ban = CCLayer:create()
                ban:setTouchEnabled(true)
                ban:setTouchSwallowEnabled(true)
                layer:addChild(ban, 2000)
                for i=1,#condition do
                    showAnim[i]:playAnimation("animation")
                end
                --for i=1,2 do
                --    aniskill[i]:setVisible(true)
                --    aniskill[i]:playAnimation("animation")
                --end
				local tempHids = {}
				for _, v in ipairs(hids) do
					--if v >= 0 then
						tempHids[#tempHids + 1] = v
					--end
				end
                local exp = heros.decomposeForwake(tempHids)
                bag.items.add({ id = ITEM_ID_HERO_EXP, num = exp})

                bag.items.sub({ id = ITEM_ID_EVOLVE_EXP, num = cfgtalen[wake-3].stoneMaterial})
                local preHero = clone(heroData)
                heros.wakeUp(heroData.hid, heroData.id) 
                wake = wake + 1

                for i, v in ipairs(hids) do
					if v >= 0 then
						local heroData = heros.find(v)
						if heroData then
							for j, k in ipairs(heroData.equips) do
								if cfgequip[k].pos == EQUIP_POS_JADE then
									bag.items.addAll(cfgequip[k].jadeUpgAll)
								end
							end
						end
						heros.del(v)
					else
						food.modCount(-v, -1)
					end
                end
                callfuncstar(hids)
                schedule(board, 2, function()
                    if upherolayer then
                        upherolayer:removeFromParentAndCleanup()
                        upherolayer = nil
                    end
                    local talentips = require "ui.hero.talentips"
                    superlayer:addChild(talentips.create(heroData, preHero), 2000)
                    upherolayer = createupherolayer(heroData.id, wake+1, heroData.hid)
                    board:addChild(upherolayer)
                    ban:removeFromParent()
                end)
            end)
            return
        end
        if wake == 3 then
            if evolvenum < cfghero[cfghero[heroData.id].nId].stoneMaterial[1] then
                showToast(i18n.global.toast_hero_need_evolve.string)
                return
            end
        else
            if evolvenum < cfghero[heroData.id].stoneMaterial[wake+1] then
                showToast(i18n.global.toast_hero_need_evolve.string)
                return
            end
        end
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
                showToast(i18n.global.hero_wake_no_hero.string)
                return
            end
        end
        local params = {
            sid = player.sid,
            hid = heroData.hid,
            source = hids
        }
        tbl2string(params)
        addWaitNet()
        net:hero_wake(params, function(__data)
            delWaitNet()
            tbl2string(__data)
            if __data.status < 0 then
                showToast("status:" .. __data.status)
                return
            end
            local activityData = require "data.activity"
            local IDS = activityData.IDS
            local ban = CCLayer:create()
            ban:setTouchEnabled(true)
            ban:setTouchSwallowEnabled(true)
            layer:addChild(ban, 2000)
            for i=1,#condition do
                showAnim[i]:playAnimation("animation")
            end
            for i=1,2 do
                aniskill[i]:setVisible(true)
                aniskill[i]:playAnimation("animation")
            end
			local tempHids = {}
			for _, v in ipairs(hids) do
				--if v >= 0 then
					tempHids[#tempHids + 1] = v
				--end
			end
            local exp = heros.decomposeForwake(tempHids)
            bag.items.add({ id = ITEM_ID_HERO_EXP, num = exp})
            if wake == 3 then
                bag.items.sub({ id = ITEM_ID_EVOLVE_EXP, num = cfghero[cfghero[heroData.id].nId].stoneMaterial[1]})
            else
                bag.items.sub({ id = ITEM_ID_EVOLVE_EXP, num = cfghero[heroData.id].stoneMaterial[wake+1]})
            end
            local preHero = clone(heroData)
            heros.wakeUp(heroData.hid, heroData.id) 
            wake = wake + 1

            -- achieve
            local achieveData = require "data.achieve"
            if wake == 3 then
                achieveData.add(ACHIEVE_TYPE_WAKE9, 1)
            end
            if wake == 4 then
                achieveData.add(ACHIEVE_TYPE_WAKE10, 1)
            end
            -- activity
            if wake >= 3 and wake <= 4 then 
                local tmp_status = activityData.getStatusById(IDS.AWAKING_GLORY_2.ID)
                if cfghero[heroData.id].maxStar == 10 then
                    tmp_status = activityData.getStatusById(IDS.AWAKING_GLORY_1.ID)
                end
                if tmp_status and tmp_status.limits and tmp_status.limits > 0 then
                    tmp_status.limits = tmp_status.limits - 1
                end
            end

            for i, v in ipairs(hids) do
				if v >= 0 then
					local heroData = heros.find(v)
					if heroData then
						for j, k in ipairs(heroData.equips) do
							if cfgequip[k].pos == EQUIP_POS_JADE then
								bag.items.addAll(cfgequip[k].jadeUpgAll)
							end
						end
					end
					heros.del(v)
				else
					food.modCount(-v, -1)
				end
            end
            callfuncstar(hids)
            if wake == 4 then
                titleShade:setString(i18n.global.hero_talen_title.string) 
                title:setString(i18n.global.hero_talen_title.string) 
                advancedLab:setString(i18n.global.hero_btn_talenl.string)
            end
            schedule(board, 2, function()
                if upherolayer then
                    upherolayer:removeFromParentAndCleanup()
                    upherolayer = nil
                end
                local upherotips = require "ui.hero.upherotips"
                superlayer:addChild(upherotips.create(heroData, preHero), 2000)
                local upwake = wake + 1
                if upwake == 5 and player.isSeasonal() then upwake = getMaxWake() + 1 end
                upherolayer = createupherolayer(heroData.id, upwake, heroData.hid)
                board:addChild(upherolayer)
                ban:removeFromParent()
            end)
        end)
    end)

    return layer
end

return uphero
