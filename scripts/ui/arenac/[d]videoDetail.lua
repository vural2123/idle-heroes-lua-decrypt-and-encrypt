local ui = {}

require "common.const"
require "common.func"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local audio = require "res.audio"
local i18n = require "res.i18n"
local playerData = require "data.player"
local net = require "net.netClient"

-- 背景框大小
local BG_WIDTH   = 880
local BG_HEIGHT  = 520

-- 滑动区域大小
local SCROLL_MARGIN_TOP     = 10
local SCROLL_MARGIN_BOTTOM  = 10
local SCROLL_VIEW_WIDTH     = BG_WIDTH
local SCROLL_VIEW_HEIGHT    = BG_HEIGHT - SCROLL_MARGIN_TOP - SCROLL_MARGIN_BOTTOM

local function createItemDetail(round, winFlag, leftFlag, player)
	local bg
	local bkgWidth = 342
	--local resultIcon
	if winFlag == true then
		bg = img.createUI9Sprite(img.ui.arena_new_video_bg_win)
    	bg:setPreferredSize(CCSize(bkgWidth, bg:getContentSize().height))
    	bg:setAnchorPoint(ccp(0.5,0.5))

        resultIcon = img.createUISprite(img.ui.arena_icon_win)
    else
    	bg = img.createUI9Sprite(img.ui.arena_new_video_bg_lose)
    	bg:setPreferredSize(CCSize(bkgWidth, bg:getContentSize().height))
    	bg:setAnchorPoint(ccp(0.5,0.5))

        resultIcon = img.createUISprite(img.ui.arena_icon_lost)
	end

    bg:addChild(resultIcon)

    local playerLogo = img.createPlayerHeadForArena(player.logo)
    playerLogo:setScale(0.65)
    bg:addChild(playerLogo)

    local showName = lbl.createFontTTF(16, player.name)
    bg:addChild(showName)

    local player_lv_bg = img.createUISprite(img.ui.main_lv_bg)
    local lbl_player_lv = lbl.createFont2(14, "" .. player.lv)
    lbl_player_lv:setPosition(CCPoint(player_lv_bg:getContentSize().width/2, player_lv_bg:getContentSize().height/2))
    player_lv_bg:addChild(lbl_player_lv)
    bg:addChild(player_lv_bg)

    local hids = {}
    local pheroes = player.camp or {}
    --tbl2string(pheroes)
    for i, v in ipairs(pheroes) do
        hids[v.pos] = v
    end
    tbl2string(hids)

    local sx, dx = 38, 53
    for i=1, 6 do
        local showHero
        if hids[i] then
            --showHero = img.createHeroHead(hids[i].id, hids[i].lv, true, true, hids[i].wake,nil,require("data.pet").getPetID(hids))
            local param = {
                id = hids[i].id,
                lv = hids[i].lv,
                showGroup = true,
                showStar = true,
                wake = hids[i].wake,
                orangeFx = nil,
                petID = require("data.pet").getPetID(hids),
                hid = nil,
                skin = hids[i].skin
            }
            showHero = img.createHeroHeadByParam(param)
        else
            showHero = img.createUISprite(img.ui.herolist_head_bg)
        end
        showHero:setAnchorPoint(ccp(0.5, 0.5))
        showHero:setScale(0.55)
        showHero:setPosition(sx + (i - 1) * dx, 42)
        bg:addChild(showHero)
    end

	if leftFlag then
        resultIcon:setPosition(bkgWidth - 45, 114)

        showName:setAnchorPoint(ccp(0, 0))
        player_lv_bg:setAnchorPoint(CCPoint(0, 1))

        playerLogo:setPosition(44, 114)
        showName:setPosition(81, 114 + 3)
        player_lv_bg:setPosition(81, 114)
	else
        resultIcon:setPosition(45, 114)

        showName:setAnchorPoint(ccp(1, 0))
        player_lv_bg:setAnchorPoint(CCPoint(1, 1))

        playerLogo:setPosition(bkgWidth - 44, 114)
        showName:setPosition(bkgWidth - 81, 114 + 3)
        player_lv_bg:setPosition(bkgWidth - 81, 114)
	end

	return bg
end

--创建每个战斗记录面板
local function createItem(__data, round, videoId, orgData)
	-- __data = {
	-- 	atk = {
	-- 		name = "test",
	-- 		lv = 50,
	-- 		logo = 39,
	-- 	},
	-- 	def = {
	-- 		name = "right",
	-- 		lv = 100,
	-- 		logo = 39,
	-- 	},
	-- 	wins = {1, -1, 1},
	-- }

	if __data.wins[round] == nil then
		return
	end

	local frames
	if round == 1 then
		frames = __data.frames
	elseif round == 2 then
		frames = __data.frames1
	elseif round == 3 then
		frames = __data.frames2
	end

	local width = 806
	local height = 200
	local container = cc.Node:create()
	container:setAnchorPoint(CCPoint(0.5, 0.5))
	container:setContentSize(CCSize(width, height))

	local leftBg = createItemDetail(round, __data.wins[round] == true, true, __data.atk.mbrs[round])
	leftBg:setAnchorPoint(0, 0.5)
	leftBg:setPosition(0, height * 0.5)
	container:addChild(leftBg)

	local rightBg = createItemDetail(round, __data.wins[round] == false, false, __data.def.mbrs[round])
	rightBg:setAnchorPoint(0, 0.5)
	rightBg:setPosition(leftBg:getContentSize().width + 56, height * 0.5)
	container:addChild(rightBg)

	-- title
	local titleKeyAry = {i18n.global.round1_3v3.string, i18n.global.round2_3v3.string, i18n.global.round3_3v3.string}
    local titleKey = titleKeyAry[round]
    local titleLabel = lbl.createFont1(24, titleKey, ccc3(0xff, 0xe3, 0x86))
    titleLabel:setAnchorPoint(0.5, 1)
    titleLabel:setPosition(leftBg:getContentSize().width + 28, height + 6)
    container:addChild(titleLabel)

    -- vs icon
    local vsIcon = img.createUISprite(img.ui.arena_new_vs)
    vsIcon:setPosition(leftBg:getContentSize().width + 28, height * 0.5)
    container:addChild(vsIcon)

    -- btn
    local btn_vide0 = img.createUISprite(img.ui.arena_new_video_btn)
    local btn_vide = SpineMenuItem:create(json.ui.button, btn_vide0)
    local btn_video_menu = CCMenu:createWithItem(btn_vide)
    btn_video_menu:setPosition(CCPoint(0, 0))
    container:addChild(btn_video_menu)

    btn_vide:setPosition(rightBg:getPositionX() + rightBg:getContentSize().width + 40, height * 0.5)

    btn_vide:registerScriptTapHandler(function()
        audio.play(audio.button)

        --local newData = clone(__data)
        --newData.frames = frames
        --newData.win = __data.wins[round]

        --local function getNewCmp(camp)
        --    local res = {}
        --    local pheroes = camp or {}
        --    for _, v in ipairs(pheroes) do
        --        if v.pos >= (round - 1) * 6 + 1 and v.pos <= (round - 1) * 6 + 6 then
        --            local newValue = clone(v)
        --            newValue.pos = v.pos - (round - 1) * 6
        --            table.insert(res, newValue)
        --        end
        --    end
        --    return res
        --end

        --newData.atk.camp = getNewCmp(__data.atk.camp)
        --newData.def.camp = getNewCmp(__data.def.camp)

        --newData.from_layer = {video = {id = videoId, __data = orgData}}

        local params = {
            sid = playerData.sid + 256,
            vid = __data.vids[round],
        }

        tbl2string(params)
        addWaitNet()
        net:gpvp_video(params, function(_data)
            delWaitNet()
          
            tbl2string(_data)
            if _data.status < 0 then
                showToast("status:" .. _data.status)
                return 
            end
            local video1 = {}
            video1.atk = __data.atk.mbrs[round]
            video1.def = __data.def.mbrs[round]
            video1.win = __data.wins[round]
            video1.frames = _data.frames
            video1.hurts = _data.hurts
            -- pet
            processPetPosAtk2(video1)
            processPetPosDef2(video1)

            video1.from_layer = {video = {id = videoId, __data = orgData}}
            replaceScene(require("fight.pvpf3rep.loading").create(video1))
        end)
    end)

	return container
end

function ui.create(__data, videoId, orgData)
    local layer = CCLayer:create()

    -- dark bg
    local darkbg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    layer:addChild(darkbg)

    -- bg
    local bg = img.createUI9Sprite(img.ui.tips_bg)
    bg:setPreferredSize(CCSize(BG_WIDTH, BG_HEIGHT))
    bg:setScale(view.minScale * 0.1)
    bg:setAnchorPoint(ccp(0.5,0.5))
    bg:setPosition(view.midX, view.midY)
    bg:runAction(CCEaseBackOut:create(CCScaleTo:create(0.3, view.minScale)))
    layer:addChild(bg)
    
    -- closeBtn
    local closeBtn0 = img.createUISprite(img.ui.close)
    local closeBtn = SpineMenuItem:create(json.ui.button, closeBtn0)
    closeBtn:setPosition(BG_WIDTH-23, BG_HEIGHT-26)
    local closeMenu = CCMenu:createWithItem(closeBtn)
    closeMenu:setPosition(0, 0)
    bg:addChild(closeMenu, 1)
    closeBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer.onAndroidBack()
    end)

    local scroll = CCScrollView:create()
    scroll:setDirection(kCCScrollViewDirectionVertical)
    scroll:setViewSize(CCSize(SCROLL_VIEW_WIDTH, SCROLL_VIEW_HEIGHT))
    scroll:setPosition(0, SCROLL_MARGIN_BOTTOM)
    bg:addChild(scroll)

    local height = 0
    local itemAry = {}
    for i = 1, 3 do
        local item = createItem(__data.log, i, videoId, orgData)
        if not item then
            break
        end

        height = height + item:getContentSize().height + 4
        table.insert(itemAry, item)
        scroll:addChild(item)
    end

    local sy = height - 4 - 10 - 5
    for _, item in ipairs(itemAry) do
    	item:setAnchorPoint(0.5, 0.5)
    	item:setPosition(SCROLL_VIEW_WIDTH * 0.5, sy - item:getContentSize().height * 0.5)
    	sy = sy - item:getContentSize().height - 4
    end

    scroll:setContentSize(CCSize(SCROLL_VIEW_WIDTH, height))
    scroll:setContentOffset(ccp(0, SCROLL_VIEW_HEIGHT-height))

    addBackEvent(layer)

    function layer.onAndroidBack()
        layer:removeFromParent()
    end

    layer:registerScriptHandler(function(event)
        if event == "enter" then
            layer.notifyParentLock()
        elseif event == "exit" then
            layer.notifyParentUnlock()
        end
    end)

    layer:setTouchEnabled(true)
    layer:setTouchSwallowEnabled(true)

    return layer
end

return ui
