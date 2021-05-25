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
local cfgarena = require "config.arena"
local cfgequip = require "config.equip"
local heros = require "data.heros"
local bag = require "data.bag"
local player = require "data.player"
local arenaData = require "data.arenab"

function ui.create()
    local layer = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))

    local board = img.createLogin9Sprite(img.login.dialog)
    board:setPreferredSize(CCSize(746, 520))
    board:setScale(view.minScale)
    board:setPosition(view.midX, view.midY)
    layer:addChild(board)

    local showTitle = lbl.createFont1(26, i18n.global.arena_rivals_title.string, ccc3(0xe6, 0xd0, 0xae))
    showTitle:setPosition(board:getContentSize().width/2, 490)
    board:addChild(showTitle, 1)
    
    local showTitleShade = lbl.createFont1(26, i18n.global.arena_rivals_title.string, ccc3(0x59, 0x30, 0x1b))
    showTitleShade:setPosition(board:getContentSize().width/2, 488)
    board:addChild(showTitleShade)
 
    local btnCloseSprite = img.createUISprite(img.ui.close)
    local btnClose = SpineMenuItem:create(json.ui.button, btnCloseSprite)
    btnClose:setPosition(721, 492)
    local menuClose = CCMenu:createWithItem(btnClose)
    menuClose:setPosition(0, 0)
    board:addChild(menuClose)
    btnClose:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer:removeFromParentAndCleanup(true)
    end)

    local titlePower = lbl.createMixFont1(15, i18n.global.arena_rivals_info.string, ccc3(0x60, 0x3c, 0x26))
    titlePower:setAnchorPoint(ccp(0, 0))
    titlePower:setPosition(35, 436)
    board:addChild(titlePower)

    local refreshBg = img.createUI9Sprite(img.ui.select_tab_tab_bg)
    refreshBg:setAnchorPoint(ccp(0, 0))
    refreshBg:setPreferredSize(CCSize(679, 37))
    refreshBg:setPosition(35, 384)
    board:addChild(refreshBg)

    local showPowerBg = img.createUISprite(img.ui.select_hero_power_bg)
    showPowerBg:setAnchorPoint(ccp(0, 0.5))
    showPowerBg:setPosition(0, 19)
    refreshBg:addChild(showPowerBg)

    local powerIcon = img.createUISprite(img.ui.power_icon)
    powerIcon:setScale(0.46)
    powerIcon:setPosition(27, 21)
    showPowerBg:addChild(powerIcon)

    local showPower = lbl.createFont2(20, arenaData.power)
    showPower:setAnchorPoint(ccp(0, 0.5))
    showPower:setPosition(powerIcon:boundingBox():getMaxX() + 15, powerIcon:boundingBox():getMidY())
    showPowerBg:addChild(showPower)

    local btnRefreshSp = img.createLogin9Sprite(img.login.button_9_small_green)
    btnRefreshSp:setPreferredSize(CCSize(115, 46))
    local labRefresh = lbl.createFont1(16, i18n.global.arena_rivals_refresh.string, ccc3(0x23, 0x62, 0x05))
    labRefresh:setPosition(btnRefreshSp:getContentSize().width/2, btnRefreshSp:getContentSize().height/2)
    btnRefreshSp:addChild(labRefresh)
    
    local btnRefresh = SpineMenuItem:create(json.ui.button, btnRefreshSp)
    local menuRefresh = CCMenu:createWithItem(btnRefresh)
    menuRefresh:setPosition(0, 0)
    refreshBg:addChild(menuRefresh)
    btnRefresh:setPosition(622, 19)

    local innerBg = img.createUI9Sprite(img.ui.inner_bg)
    innerBg:setPreferredSize(CCSize(681, 334))
    innerBg:setAnchorPoint(ccp(0, 0))
    innerBg:setPosition(33, 32)
    board:addChild(innerBg)

    local oppoLayer = CCLayer:create()
    innerBg:addChild(oppoLayer)

    local function loadRivals(Rivals)
        oppoLayer:removeAllChildrenWithCleanup(true)

        for i, v in ipairs(Rivals) do
            if i > 3 then
                break
            end

            local oppoBg = img.createUI9Sprite(img.ui.botton_fram_2)
            oppoBg:setPreferredSize(CCSize(655, 95))
            oppoBg:setAnchorPoint(ccp(0, 0))
            oppoBg:setPosition(13, innerBg:getContentSize().height - 105 * i - 5)
            oppoLayer:addChild(oppoBg)
            
            local showName = lbl.createFontTTF(18, v.name, ccc3(0x51, 0x27, 0x12))
            showName:setAnchorPoint(ccp(0, 0))
            showName:setPosition(98, 57)
            oppoBg:addChild(showName)

            local playerHeadSprite = img.createPlayerHead(v.logo, v.lv)
            playerHeadSprite:setScale(0.8)
            local playerHead = CCMenuItemSprite:create(playerHeadSprite, nil) 
            local menuPlayerHead = CCMenu:createWithItem(playerHead)
            menuPlayerHead:setPosition(0, 0)
            playerHead:setPosition(56, 57)
            oppoBg:addChild(menuPlayerHead)
            playerHead:registerScriptTapHandler(function()
                audio.play(audio.button)
				v.iron = true
                layer:addChild(require("ui.tips.player").create(v), 100)
            end)

            local powerBg = img.createUI9Sprite(img.ui.arena_frame7)
            powerBg:setPreferredSize(CCSize(196, 28))
            powerBg:setAnchorPoint(ccp(0, 0))
            powerBg:setPosition(98, 19)
            oppoBg:addChild(powerBg)

            local powerIcon = img.createUISprite(img.ui.power_icon)
            powerIcon:setScale(0.5)
            powerIcon:setPosition(15, 14)
            powerBg:addChild(powerIcon)

            local showPower = lbl.createFont2(16, v.power)
            showPower:setAnchorPoint(ccp(0, 0.5))
            showPower:setPosition(43, 14)
            powerBg:addChild(showPower)

            local titleScore = lbl.createFont1(14, i18n.global.arena_rivals_score.string ,ccc3(0x9a, 0x6a, 0x52))
            titleScore:setPosition(394, 57)
            oppoBg:addChild(titleScore)
            
            local showScore = lbl.createFont1(22, v.score, ccc3(0xa4, 0x2f, 0x28))
            showScore:setPosition(394, 38)
            oppoBg:addChild(showScore)
            
            local btnBattleSp = img.createLogin9Sprite(img.login.button_9_small_gold)
            btnBattleSp:setPreferredSize(CCSize(136, 52))

            local labFight = lbl.createFont1(16, i18n.global.arena_rivals_fight.string, ccc3(0x73, 0x3b, 0x05))
            --labFight:setPosition(90, 26)
			labFight:setPosition(68, 26)
            btnBattleSp:addChild(labFight)

            local btnBattle = SpineMenuItem:create(json.ui.button, btnBattleSp)
            local menuBattle = CCMenu:createWithItem(btnBattle)
            menuBattle:setPosition(0, 0)
            oppoBg:addChild(menuBattle)
            btnBattle:setPosition(574, 47)

            btnBattle:registerScriptTapHandler(function() 
                disableObjAWhile(btnBattle)
                audio.play(audio.button)
                --layer:addChild(require("ui.selecthero.main").create({type = "ArenabAtk", info = v, cost = 0}))
				local params = {
					sid = player.sid,
					--camp = content.hids,
					uid = v.uid,
					id = 5,
				}

				addWaitNet()
				net:pvp_fight(params, function(__data)
					delWaitNet()
					
					if __data.status == -3 then
						showToast(i18n.global.event_processing.string)
						return
					elseif __data.status < 0 then
						showToast("status:" .. __data.status)
						return 
					end

					local video = __data.video
					video.atk.name = player.name
					video.atk.lv = player.lv()
					video.atk.logo = player.logo
					video.atk.score = arenaData.score

					arenaData.update(video.ascore)
				   
					local tmp = video.def.camp
					video.def = {}
					video.def = clone(v)
					video.def.camp = tmp

					local ccamp = require "fight.helper.ccamp"
					ccamp.processCamp(video, nil, 2)
					
					if video.rewards and video.select then
						bag.addRewards(video.rewards[video.select])
					end
					if not video.win then
						arenaData.fight = arenaData.fight + 1
					end
					
					video.from_layer = "task"
					arenaData.rivals = {}

					if arenaSkip() == "enable" then
						if video.win then
							CCDirector:sharedDirector():getRunningScene():addChild(require("fight.pvpb.win").create(__data.video), 1000)
						else
							CCDirector:sharedDirector():getRunningScene():addChild(require("fight.pvpb.lose").create(__data.video), 1000)
						end
					else
						replaceScene(require("fight.pvpb.loading").create(__data.video))
					end
				end)
            end)
        end
    end

    local function onRefresh()
        local Rivals = arenaData.refresh()
        if #Rivals <= 0 then
            local params = {
                sid = player.sid,
                id = 5,
            }
            addWaitNet()
            net:pvp_refresh(params, function(__data)
                delWaitNet()
                
                if __data.status and __data.status == -1 then
                    showToast(i18n.global.iron_players.string)
                    return
                end
                arenaData.rivals = __data.rivals
                Rivals = arenaData.refresh()
                loadRivals(Rivals)
            end)
        else
			loadRivals(Rivals)
		end
    end

    btnRefresh:registerScriptTapHandler(function()
        audio.play(audio.button)
        onRefresh()
    end)

    layer:registerScriptTouchHandler(function() return true end)
    layer:setTouchEnabled(true)
  
    addBackEvent(layer)
    function layer.onAndroidBack()
        layer:removeFromParentAndCleanup(true)
    end
    local function onEnter()
        print("onEnter")
        onRefresh()
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
