local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local i18n = require "res.i18n"
local json = require "res.json"
local audio = require "res.audio"
local dataGuild = require "data.guild"
local dataPlayer = require "data.player"
local dataHeros = require "data.heros"
local net = require "net.netClient"
local player = require "data.player"
local gdata = require "data.guild"

local droidhangComponents = require("dhcomponents.DroidhangComponents")

local GoTypeEnum = {
    none = 0,--不跳转
	hook = 1,--副本挂机
	arena = 2,--竞技场
	guild = 3,--公会
	friend = 4,--好友
	achieve = 5,--成就
	herotask = 6,--酒馆任务
	task = 7,--每日任务
	midas = 8,--点金手
	trial = 9,--幻境之塔
	dare = 10,--活动副本--金币
	casino = 11,--许愿池, 赌场
	summon = 12,--酒馆, 英雄商店
	brave = 13,--勇者试炼
	blackmarket = 14,--黑市
	summonspe = 15,--先知之树
	herolist = 16,--英雄面板
	heromarket = 17,--英雄商店
	smith = 18,--铁匠铺
	devour = 19,--英雄分解
    heroforge = 20,--英雄合成
    brave_shop = 21,--, 勇者试炼商店
    dare_2 = 22,--活动副本--勇者
    dare_3 = 23,--活动副本--英雄
    pvp3_shop = 24,--冠军试炼商店
}

local gotoList = {
	{
		title = "1",--免费钻石
		items = {
			{name = "1", goType = GoTypeEnum.arena},
			{name = "2", goType = GoTypeEnum.herotask},
            {name = "3", goType = GoTypeEnum.task},
            {name = "4", goType = GoTypeEnum.hook},
            {name = "5", goType = GoTypeEnum.friend},
            {name = "6", goType = GoTypeEnum.achieve},
		},
	},
	{
		title = "2",--获得金币
		items = {
			{name = "1", goType = GoTypeEnum.hook},
            {name = "2", goType = GoTypeEnum.dare},
            {name = "3", goType = GoTypeEnum.midas},
            {name = "4", goType = GoTypeEnum.trial},
            {name = "5", goType = GoTypeEnum.guild},--公会BOSS
            {name = "6", goType = GoTypeEnum.task},
            {name = "7", goType = GoTypeEnum.casino},
		},
	},
    {
        title = "3",--获得英雄碎片
        items = {
            {name = "1", goType = GoTypeEnum.hook},
            {name = "2", goType = GoTypeEnum.dare_3},
            {name = "3", goType = GoTypeEnum.herotask},
            {name = "4", goType = GoTypeEnum.trial},
            {name = "5", goType = GoTypeEnum.guild},--公会商店
            {name = "6", goType = GoTypeEnum.heromarket},
            {name = "7", goType = GoTypeEnum.brave_shop},
            {name = "8", goType = GoTypeEnum.friend},
            {name = "9", goType = GoTypeEnum.casino},
            {name = "10", goType = GoTypeEnum.blackmarket},
            {name = "11", goType = GoTypeEnum.summonspe},
        },
    },
    {
        title = "4",--获得英雄经验
        items = {
            {name = "1", goType = GoTypeEnum.hook},
            {name = "2", goType = GoTypeEnum.dare_2},
            {name = "3", goType = GoTypeEnum.task},
            {name = "4", goType = GoTypeEnum.casino},
            {name = "5", goType = GoTypeEnum.blackmarket},
        },
    },
    {
        title = "5",--获得英雄进阶材料
        items = {
            {name = "1", goType = GoTypeEnum.trial},
            -- {name = "2", goType = GoTypeEnum.task},
            {name = "3", goType = GoTypeEnum.dare_3},
            -- {name = "4", goType = GoTypeEnum.casino},
            {name = "5", goType = GoTypeEnum.blackmarket},
            {name = "6", goType = GoTypeEnum.hook},
        },
    },
    {
        title = "6",--获得装备
        items = {
            {name = "1", goType = GoTypeEnum.hook},
            {name = "2", goType = GoTypeEnum.trial},
            {name = "3", goType = GoTypeEnum.casino},
            {name = "4", goType = GoTypeEnum.blackmarket},
            {name = "5", goType = GoTypeEnum.brave_shop},
            {name = "6", goType = GoTypeEnum.guild},
        },
    },
    {
        title = "7",--获得魔法之尘
        items = {
            {name = "1", goType = GoTypeEnum.hook},
            {name = "2", goType = GoTypeEnum.brave_shop},
            {name = "3", goType = GoTypeEnum.casino},
        },
    },
    {
        title = "8",--获得神器
        items = {
            {name = "1", goType = GoTypeEnum.hook},
            {name = "2", goType = GoTypeEnum.guild},
            {name = "3", goType = GoTypeEnum.casino},
        },
    },
    {
        title = "11",--获得先知宝珠
        items = {
            {name = "1", goType = GoTypeEnum.none},
            {name = "2", goType = GoTypeEnum.herotask},
            {name = "3", goType = GoTypeEnum.none},
            {name = "4", goType = GoTypeEnum.blackmarket},
            {name = "5", goType = GoTypeEnum.pvp3_shop},
        },
    },
    {
        title = "9",--提升英雄
        items = {
            {name = "1", goType = GoTypeEnum.herolist},
            {name = "2", goType = GoTypeEnum.heroforge},
            {name = "3", goType = GoTypeEnum.summon},
        },
    },
    {
        title = "10",--提升装备
        items = {
            {name = "1", goType = GoTypeEnum.smith},
            {name = "2", goType = GoTypeEnum.none},
        },
    },
}

local gotoHelper = class("gotoHelper", function ()
	return cc.LayerColor:create(cc.c4b(0, 0, 0, POPUP_DARK_OPACITY))
end)

function gotoHelper.create(uiParams)
	return gotoHelper.new(uiParams)
end

function gotoHelper:ctor(uiParams)
    local BG_WIDTH   = 760
    local BG_HEIGHT  = 470

    local bg = img.createLogin9Sprite(img.login.dialog)
    bg:setPreferredSize(CCSize(BG_WIDTH, BG_HEIGHT))
    bg:setScale(view.minScale * 0.1)
    bg:setAnchorPoint(ccp(0.5,0.5))
    bg:setPosition(scalep(960/2, 576/2))
    bg:runAction(CCEaseBackOut:create(CCScaleTo:create(0.3, view.minScale)))
    self:addChild(bg)
    self.bg = bg

    local showTitle = lbl.createFont1(26, i18n.global.gotoHelper_enter_title_2.string, ccc3(0xe6, 0xd0, 0xae))
    showTitle:setPosition(bg:getContentSize().width/2, BG_HEIGHT - 30)
    bg:addChild(showTitle, 1)
    
    local showTitleShade = lbl.createFont1(26, i18n.global.gotoHelper_enter_title_2.string, ccc3(0x59, 0x30, 0x1b))
    showTitleShade:setPosition(bg:getContentSize().width/2, BG_HEIGHT - 32)
    bg:addChild(showTitleShade)

    --init left
    self:initLeft()

    local function onTouch(eventType, x, y)
        if eventType == "began" then
            return true
        end
    end

    self:registerScriptTouchHandler(onTouch , false , -128 , false)
    self:setTouchEnabled(true)

    local function backEvent()
        self:removeFromParentAndCleanup(true)
    end

    -- close btn
    local close0 = img.createUISprite(img.ui.close)
    local closeBtn = SpineMenuItem:create(json.ui.button, close0)
    droidhangComponents:mandateNode(closeBtn, "r1TO_IJ8gKV")
    local closeMenu = CCMenu:createWithItem(closeBtn)
    closeMenu:setPosition(CCPoint(0, 0))
    bg:addChild(closeMenu, 1)
    closeBtn:registerScriptTapHandler(function()     
        audio.play(audio.button)
        backEvent()
    end)

    addBackEvent(self)
    function self.onAndroidBack()
        backEvent()
    end
    self:registerScriptHandler(function(event)
        if event == "cleanup" then
        elseif event == "enter" then
            self.notifyParentLock()
        elseif event == "exit" then
            self.notifyParentUnlock()
        end
    end)

end

function gotoHelper:initLeft()
    local bg = self.bg

	-- 滑动区域大小
    local SCROLL_MARGIN_TOP     = 14
    local SCROLL_MARGIN_BOTTOM  = 34
    local SCROLL_VIEW_WIDTH     = 235
    local SCROLL_VIEW_HEIGHT    = 410 - SCROLL_MARGIN_TOP - SCROLL_MARGIN_BOTTOM + 6

    local scroll = CCScrollView:create()
    scroll:setDirection(kCCScrollViewDirectionVertical)
    scroll:setViewSize(CCSize(SCROLL_VIEW_WIDTH, SCROLL_VIEW_HEIGHT))
    scroll:setPosition(20, SCROLL_MARGIN_BOTTOM)
    bg:addChild(scroll, 2)

    local function createItem(title)
        local bg = img.createLogin9Sprite(img.login.button_9_small_mwhite)
    	bg:setPreferredSize(CCSizeMake(206, 72))

    	local bg2 = img.createLogin9Sprite(img.login.button_9_small_gold)
    	bg2:setAnchorPoint(0, 0)
    	bg2:setPreferredSize(CCSizeMake(206, 72))
    	bg2:setOpacity(0)
    	bg:addChild(bg2)

        local title = lbl.createMix({
            font = 1, size = 16, text = i18n.global["gotoHelper_title_"..title].string,
            color = ccc3(0x73, 0x3b, 0x05), width = 180
        })
        title:setPosition(CCPoint(bg:getContentSize().width/2, bg:getContentSize().height/2))
        bg:addChild(title)

    	bg.setSelected = function (sel)
    		if sel then
    			bg2:setOpacity(255)
    		else
    			bg2:setOpacity(0)
    		end
    	end
        
        return bg
    end

    local height = 0
    local itemAry = {}
    for i,v in ipairs(gotoList) do
        local item = createItem(v.title)

        height = height + item:getContentSize().height + 6
        table.insert(itemAry, item)
        scroll:addChild(item)
    end

    local sy = height - 4
    for _, item in ipairs(itemAry) do
        item:setAnchorPoint(0.5, 0.5)
        item:setPosition(SCROLL_VIEW_WIDTH * 0.5, sy - item:getContentSize().height * 0.5)
        sy = sy - item:getContentSize().height - 6
    end

    self.itemAry = itemAry

    scroll:setContentSize(CCSize(SCROLL_VIEW_WIDTH, height))
    scroll:setContentOffset(ccp(0, SCROLL_VIEW_HEIGHT-height))

    local touchNode = cc.Layer:create()
    bg:addChild(touchNode, 1)

    local lasty
    local function onTouchBegan(x, y)
        lasty = y
        return true 
    end

    local function onTouchMoved(x, y)
        return true
    end

    local function onTouchEnded(x, y)
        if math.abs(y - lasty) > 10 then
            return
        end
        local pointOnScroll = scroll:getContainer():convertToNodeSpace(ccp(x, y))
        for i, v in ipairs(itemAry) do
            if v:boundingBox():containsPoint(pointOnScroll) then
                audio.play(audio.button)
                self:onPage(i)
                break
            end
        end

        return true
    end

    local function onTouch(eventType, x, y)
        if eventType == "began" then   
            return onTouchBegan(x, y)
        elseif eventType == "moved" then
            return onTouchMoved(x, y)
        else
            return onTouchEnded(x, y)
        end
    end

    touchNode:registerScriptTouchHandler(onTouch)
    touchNode:setTouchEnabled(true)

    self:onPage(1)
end

function gotoHelper:checkUnlock(goType)
    if goType == GoTypeEnum.hook then--副本挂机
        return 0
    elseif goType == GoTypeEnum.arena then--竞技场
        if BUILD_ENTRIES_ENABLE and player.lv() < UNLOCK_ARENA_LEVEL then
            return UNLOCK_ARENA_LEVEL
        end
    elseif goType == GoTypeEnum.guild then--公会
        if BUILD_ENTRIES_ENABLE and player.lv() < UNLOCK_GUILD_LEVEL then
            return UNLOCK_GUILD_LEVEL
        end
    elseif goType == GoTypeEnum.friend then--好友
        return 0
    elseif goType == GoTypeEnum.achieve then--成就
        return 0
    elseif goType == GoTypeEnum.herotask then--酒馆任务
        if BUILD_ENTRIES_ENABLE and player.lv() < UNLOCK_TAVERN_LEVEL then
            return UNLOCK_TAVERN_LEVEL
        end
    elseif goType == GoTypeEnum.task then--每日任务
        if BUILD_ENTRIES_ENABLE and player.lv() < UNLOCK_TASK_LEVEL then
            return 0
        end
    elseif goType == GoTypeEnum.midas then--点金手
        return 0
    elseif goType == GoTypeEnum.trial then--幻境之塔
        if BUILD_ENTRIES_ENABLE and player.lv() < UNLOCK_TRIAL_LEVEL then
            return UNLOCK_TRIAL_LEVEL
        end
    elseif goType == GoTypeEnum.dare then--活动副本--金币
        if BUILD_ENTRIES_ENABLE and player.lv() < 20 then
            return 20
        end
    elseif goType == GoTypeEnum.casino then--许愿池, 赌场
        if BUILD_ENTRIES_ENABLE and player.lv() < UNLOCK_CASINO_LEVEL then
            return UNLOCK_CASINO_LEVEL
        end
    elseif goType == GoTypeEnum.summon then--酒馆
        return 0
    elseif goType == GoTypeEnum.brave then--勇者试炼
        if BUILD_ENTRIES_ENABLE and player.lv() < UNLOCK_HERO_BRAVE then
            return UNLOCK_HERO_BRAVE
        end
    elseif goType == GoTypeEnum.blackmarket then--黑市
        if BUILD_ENTRIES_ENABLE and player.lv() < UNLOCK_BLACKMARKET_LEVEL then
            return UNLOCK_BLACKMARKET_LEVEL
        end
    elseif goType == GoTypeEnum.summonspe then--先知之树
        if BUILD_ENTRIES_ENABLE and player.lv() < UNLOCK_GTREE_LEVEL then
            return UNLOCK_GTREE_LEVEL
        end
    elseif goType == GoTypeEnum.herolist then--英雄面板
        return 0
    elseif goType == GoTypeEnum.heromarket then--英雄商店
        return 0
    elseif goType == GoTypeEnum.smith then--铁匠铺
        return 0
    elseif goType == GoTypeEnum.devour then--英雄分解
        return 0
    elseif goType == GoTypeEnum.heroforge then--英雄合成
        return 0
    elseif goType == GoTypeEnum.pvp3_shop then--冠军试炼商店
        return 0
    elseif goType == GoTypeEnum.brave_shop then--勇者试炼商店
        if BUILD_ENTRIES_ENABLE and player.lv() < UNLOCK_HERO_BRAVE then
            return UNLOCK_HERO_BRAVE
        end
    elseif goType == GoTypeEnum.dare_2 then--活动副本--勇者
        if BUILD_ENTRIES_ENABLE and player.lv() < 25 then
            return 25
        end
    elseif goType == GoTypeEnum.dare_3 then--活动副本--英雄
        if BUILD_ENTRIES_ENABLE and player.lv() < 30 then
            return 30
        end
    else
        return 100--未定义
    end

    return 0
end

function gotoHelper:playGoTo(goType)
    local unlockLv = self:checkUnlock(goType)
    if unlockLv > 0 then
        showToast(string.format(i18n.global.func_need_lv.string, unlockLv))
        return
    end

    local hold
    local layer = self:getParent()

    local function removeSelf()
        if tolua.isnull(self) then
            return
        end

        self:runAction(cc.RemoveSelf:create(true))
    end

    if goType == GoTypeEnum.hook then
        replaceScene(require("ui.hook.main").create())
    elseif goType == GoTypeEnum.arena then
        layer:addChild((require"ui.arena.entrance").create(), 1000)
    elseif goType == GoTypeEnum.guild then--公会
        if player.gid and player.gid > 0 and not gdata.IsInit() then
            hold = true

            local gparams = {
                sid = player.sid,
            }
            addWaitNet()
            netClient:guild_sync(gparams, function(__data)
                delWaitNet()
                tbl2string(__data)
                if __data .status ~= 0 then
                    showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                    return
                end
                gdata.init(__data)
                replaceScene((require"ui.guild.main").create())

                removeSelf()
            end)
        elseif player.gid and player.gid > 0 and gdata.IsInit() then
            replaceScene((require"ui.guild.main").create())
        else
            layer:addChild((require"ui.guild.recommend").create(1, true), 1000)
        end
    elseif goType == GoTypeEnum.friend then--好友
        local friends = require "ui.friends.main"
        layer:addChild(friends.create(),200)
    elseif goType == GoTypeEnum.achieve then--成就
        layer:addChild(require("ui.achieve.main").create(), 1000)
    elseif goType == GoTypeEnum.herotask then--酒馆任务
        replaceScene(require("ui.herotask.main").create())
    elseif goType == GoTypeEnum.task then--每日任务
        layer:addChild(require("ui.task.main").create(true), 1000)
    elseif goType == GoTypeEnum.midas then--点金手
        layer:addChild(require("ui.midas.main").create(), 1000)
    elseif goType == GoTypeEnum.trial then--幻境之塔
        replaceScene(require("ui.trial.main").create())
    elseif goType == GoTypeEnum.dare or goType == GoTypeEnum.dare_2 or goType == GoTypeEnum.dare_3 then--活动副本
        hold = true

        local daredata = require "data.dare"
        local nParams = {
            sid = player.sid,
        }
        addWaitNet()
        netClient:dare_sync(nParams, function(__data)
            delWaitNet()
            tbl2string(__data)
            daredata.sync(__data)
            layer:addChild((require"ui.dare.main").create(_params), 1000)

            removeSelf()
        end)
    elseif goType == GoTypeEnum.casino then--许愿池, 赌场
        hold = true

        local params = {
            sid = player.sid,
            type = 1,
        }
        addWaitNet()
        local casinodata = require"data.casino"
        casinodata.pull(params, function(__data)
            delWaitNet()
            tbl2string(__data)
            if __data.status ~= 0 then
                showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                return
            end
            casinodata.init(__data)
            replaceScene(require("ui.casino.main").create())

            removeSelf()
        end)
    elseif goType == GoTypeEnum.summon then--酒馆
        replaceScene(require("ui.summon.main").create())
    elseif goType == GoTypeEnum.brave then--勇者试炼, 勇者试炼商店
        local databrave = require "data.brave"
        if (not databrave.isPull) or databrave.cd < os.time() then
            hold = true

            local params = {
                sid = player.sid,
            }
            addWaitNet()
            netClient:sync_brave(params, function(__data)
                delWaitNet()
        
                tbl2string(__data)
                databrave.init(__data)
                if layer and not tolua.isnull(layer) then
                    layer:addChild(require("ui.brave.main").create(), 1000)

                    removeSelf()
                end
            end)
        else
            layer:addChild(require("ui.brave.main").create(), 1000)
        end
    elseif goType == GoTypeEnum.blackmarket then--黑市
        replaceScene(require("ui.blackmarket.main").create())
    elseif goType == GoTypeEnum.summonspe then--先知之树
        layer:addChild((require"ui.summonspe.main").create(), 1000)
    elseif goType == GoTypeEnum.herolist then--英雄面板
        replaceScene(require("ui.herolist.main").create())
    elseif goType == GoTypeEnum.heromarket then--英雄商店
        layer:addChild(require("ui.heromarket.main").create(), 1000) 
    elseif goType == GoTypeEnum.smith then--铁匠铺
        replaceScene(require("ui.smith.main").create())
    elseif goType == GoTypeEnum.devour then--英雄分解
        replaceScene(require("ui.devour.main").create())
    elseif goType == GoTypeEnum.heroforge then--英雄合成
        replaceScene(require("ui.heroforge.main").create())
    elseif goType == GoTypeEnum.brave_shop then--勇者试炼商店
        local shop = require "ui.braveshop.main"
        layer:addChild(shop.create(), 1000)
    elseif goType == GoTypeEnum.pvp3_shop then--冠军的试炼商店
        local shop = require "ui.arena.shop"
        layer:addChild(shop.create(), 1000)
    end

    if not hold then
         removeSelf()
     end 
end

function gotoHelper:onPage(index)
	if index == self.pageIndex then
		return
	end

	if self.pageIndex then
		self.itemAry[self.pageIndex].setSelected(false)
	end
	
	self.itemAry[index].setSelected(true)

	self.pageIndex = index

	if self.rightNode then
		self.rightNode:removeFromParent()
		self.rightNode = nil
	end

    local rightNode = cc.Node:create()
    self.bg:addChild(rightNode, 2)
    self.rightNode = rightNode

    -- 滑动区域大小
    local SCROLL_MARGIN_TOP     = 14
    local SCROLL_MARGIN_BOTTOM  = 34
    local SCROLL_VIEW_WIDTH     = 484
    local SCROLL_VIEW_HEIGHT    = 410 - SCROLL_MARGIN_TOP - SCROLL_MARGIN_BOTTOM

    local innerBg = img.createUI9Sprite(img.ui.inner_bg)
    innerBg:setPreferredSize(CCSize(SCROLL_VIEW_WIDTH, SCROLL_VIEW_HEIGHT + 4))
    innerBg:setAnchorPoint(ccp(0, 0))
    innerBg:setPosition(250, SCROLL_MARGIN_BOTTOM - 2)
    rightNode:addChild(innerBg)

    local scroll = CCScrollView:create()
    scroll:setDirection(kCCScrollViewDirectionVertical)
    scroll:setViewSize(CCSize(SCROLL_VIEW_WIDTH, SCROLL_VIEW_HEIGHT))
    scroll:setPosition(250, SCROLL_MARGIN_BOTTOM)
    rightNode:addChild(scroll)

    local function createItem(title, data)
        local bg = img.createUI9Sprite(img.ui.botton_fram_2)
        bg:setPreferredSize(CCSize(454, 82))

        local desc = lbl.createMix({
            font = 1, size = 16, text = i18n.global["gotoHelper_iteam_"..title.."_"..data.name].string,
            color = ccc3(0x73, 0x3b, 0x05), width = 290, align = kCCTextAlignmentLeft
        })
        desc:setAnchorPoint(0, 0.5)
        desc:setPosition(26, bg:getContentSize().height * 0.5)
        bg:addChild(desc)

        if data.goType ~= GoTypeEnum.none then
            local goto0 = img.createLogin9Sprite(img.login.button_9_small_green)
            goto0:setPreferredSize(CCSize(116, 42))
            local gotoLab = lbl.createFont1(16, i18n.global.task_btn_goto.string, ccc3(0x1b, 0x59, 0x02))
            gotoLab:setPosition(goto0:getContentSize().width/2, goto0:getContentSize().height/2)
            goto0:addChild(gotoLab)

            local gotoBtn = SpineMenuItem:create(json.ui.button, goto0)
            droidhangComponents:mandateNode(gotoBtn, "FJra_DcpJx6")
            gotoBtn:setPositionY(bg:getContentSize().height * 0.5)
            local gotoMenu = CCMenu:createWithItem(gotoBtn)
            gotoMenu:setPosition(CCPoint(0, 0))
            bg:addChild(gotoMenu, 1)
            gotoBtn:registerScriptTapHandler(function()     
                self:playGoTo(data.goType)
            end)

            if self:checkUnlock(data.goType) > 0 then
                setShader(gotoBtn, SHADER_GRAY, true)
            end
        end
        
        return bg
    end

    local height = 0
    local itemAry = {}
    local info = gotoList[index]
    for i, data in ipairs(info.items) do
        local item = createItem(info.title, data)

        height = height + item:getContentSize().height + 2
        table.insert(itemAry, item)
        scroll:addChild(item)
    end

    local sy = height - 4
    for _, item in ipairs(itemAry) do
        item:setAnchorPoint(0.5, 0.5)
        item:setPosition(SCROLL_VIEW_WIDTH * 0.5, sy - item:getContentSize().height * 0.5)
        sy = sy - item:getContentSize().height - 2
    end

    scroll:setContentSize(CCSize(SCROLL_VIEW_WIDTH, height + 10))
    scroll:setContentOffset(ccp(0, SCROLL_VIEW_HEIGHT-height - 10))
end

return gotoHelper
