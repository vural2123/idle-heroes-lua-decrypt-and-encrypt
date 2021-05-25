local ui = {}

require "common.func"

local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local audio = require "res.audio"
local i18n = require "res.i18n"
local cfgmill = require "config.mill"
local tipsequip = require "ui.tips.equip"
local tipsitem = require "ui.tips.item"
local selecthero = require "ui.selecthero.main"
local cfgmilllv = require "config.milllv"
local net = require "net.netClient"
local guildmill = require "data.guildmill"
local player = require "data.player"
local bag = require "data.bag"
local cui = require "ui.custom"

function ui.create()
    local layer = CCLayer:create()

    local upflag = false

    local isorder = nil
    local noorder = nil
    local orderlayer = nil
    local orderTasklab = nil 
    local recTimeLabel = nil

    local function completeTipsLayer(rewads)
        local comlayer = CCLayerColor:create(ccc4(0,0,0,POPUP_DARK_OPACITY))

        json.load(json.ui.npc_order)
        local aniOrder = DHSkeletonAnimation:createWithKey(json.ui.npc_order)
        aniOrder:setScale(view.minScale)
        aniOrder:scheduleUpdateLua()
        aniOrder:playAnimation("in")
        aniOrder:appendNextAnimation("stand", -1)
        aniOrder:setPosition(scalep(480, 576/2-20))
        comlayer:addChild(aniOrder, 1000)

        local tipsLab = lbl.createFont2(24, i18n.global.guild_mill_tip_compele.string, ccc3(0xfd, 0xe1, 0x69))
        aniOrder:addChildFollowSlot("code_1", tipsLab) 

        local ok0 = img.createLogin9Sprite(img.login.button_9_small_gold)
        ok0:setPreferredSize(CCSizeMake(160, 52))
        local okLab = lbl.createFont1(18, i18n.global.summon_comfirm.string, ccc3(0x73, 0x3b, 0x05))
        okLab:setPosition(CCPoint(ok0:getContentSize().width/2, 
                                        ok0:getContentSize().height/2))
        ok0:addChild(okLab)
        local okBtn = SpineMenuItem:create(json.ui.button, ok0)
        local okMenu = CCMenu:createWithItem(okBtn)
        okMenu:setPosition(CCPoint(0, 0))
        aniOrder:addChildFollowSlot("code_2", okMenu) 
        okBtn:registerScriptTapHandler(function()     
            audio.play(audio.button)
            comlayer:removeFromParentAndCleanup()
            local rewardsKit = require "ui.reward"
            CCDirector:sharedDirector():getRunningScene():addChild(rewardsKit.showReward(rewads), 100000)
        end)

        comlayer:setTouchEnabled(true)

        return comlayer
    end

    local function init()
        local param = {}
        param.sid = player.sid

        addWaitNet()
        net:gmill_sync(param, function(__data)
            delWaitNet()
            tbl2string(__data)
            guildmill.initorder(__data)
            if guildmill.order then
                guildmill.sortOrder()
                orderlayer = isorder()
                orderTasklab = lbl.createMixFont1(16, string.format(i18n.global.gmill_order_tasknum.string, #guildmill.order), ccc3(0x4e, 0x34, 0x20))
                orderTasklab:setAnchorPoint(0, 0.5)
                orderTasklab:setPosition(CCPoint(50, 410))
                layer:addChild(orderTasklab)
            else
                orderlayer = noorder()
            end
            local recTimeStr = string.format("%02d:%02d:%02d", 0, 0, 0)
            recTimeLabel = lbl.createFont2(16, recTimeStr, ccc3(0xc3, 0xff, 0x42))
            recTimeLabel:setAnchorPoint(1, 0.5)
            recTimeLabel:setPosition(CCPoint(490, 408))
            layer:addChild(recTimeLabel)
            recTimeLabel:setVisible(false)
            layer:addChild(orderlayer)
            if __data.rewards then
                local tmp_bag = {
                    items = {},
                    equips = {},
                }
                if __data.rewards[1].items then
                    for ii=1,#__data.rewards[1].items do
                        local tbl_p = tmp_bag.items
                        tbl_p[#tbl_p+1] = {id=__data.rewards[1].items[ii].id, num=__data.rewards[1].items[ii].num}
                    end
                elseif __data.rewards[1].equips then
                    for ii=1,#__data.rewards[1].equips do
                        local tbl_p = tmp_bag.equips
                        tbl_p[#tbl_p+1] = {id=__data.rewards[1].equips[ii].id, num=__data.rewards[1].equips[ii].num}
                    end
                end
                bag.addRewards(__data.rewards[1])

                schedule(layer, 0.2, function()
                    local comlayer = completeTipsLayer(tmp_bag)
                    CCDirector:sharedDirector():getRunningScene():addChild(comlayer, 1000)
                end)
            end
        end)
    end
    init()

    -- title
    local title = lbl.createFont1(24, i18n.global.gmill_order_title.string, ccc3(0xe6, 0xd0, 0xae))
    title:setPosition(CCPoint(360, 492))
    layer:addChild(title, 1)
    local title_shadowD = lbl.createFont1(24, i18n.global.gmill_order_title.string, ccc3(0x59, 0x30, 0x1b))
    title_shadowD:setPosition(CCPoint(360, 490))
    layer:addChild(title_shadowD)

    local recvorderSprite = img.createLogin9Sprite(img.login.button_9_small_green)
    recvorderSprite:setPreferredSize(CCSizeMake(160, 40))

    local recvorderlab = lbl.createFont1(16, i18n.global.gmill_receive_order.string, ccc3(0x1d, 0x67, 0x00))
    recvorderlab:setPosition(CCPoint(recvorderSprite:getContentSize().width/2,
                                    recvorderSprite:getContentSize().height/2))
    recvorderSprite:addChild(recvorderlab)

    local recvorderBtn = SpineMenuItem:create(json.ui.button, recvorderSprite)
    recvorderBtn:setAnchorPoint(1, 0)
    recvorderBtn:setPosition(CCPoint(668, 390))
    local recvorderMenu = CCMenu:createWithItem(recvorderBtn)
    recvorderMenu:setPosition(0,0)
    layer:addChild(recvorderMenu)

    recvorderBtn:registerScriptTapHandler(function()
        audio.play(audio.button) 
        local param = {}
        param.sid = player.sid

        addWaitNet()
        net:gmill_order(param, function(__data)
            delWaitNet()
            tbl2string(__data)
            if __data.status ~= 0 then
                showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                return
            end
            guildmill.order = {}
            guildmill.order = __data.orders
            
            --guildmill.sortOrder()
            guildmill.ecd = 8*3600-600
            guildmill.pull_ecd_time = os.time()
            setShader(recvorderBtn, SHADER_GRAY, true)
            recvorderBtn:setEnabled(false)
            
            if guildmill.pull_ocd_time == nil then
                guildmill.pull_ocd_time = {}
                for i=1,#guildmill.order do 
                    guildmill.pull_ocd_time[i] = os.time()
                end
            end
            orderlayer:removeFromParentAndCleanup(true)
            orderlayer = nil
            orderlayer = isorder()
            layer:addChild(orderlayer)
            if orderTasklab == nil then 
                orderTasklab = lbl.createMixFont1(16, string.format(i18n.global.gmill_order_tasknum.string, #guildmill.order), ccc3(0x4e, 0x34, 0x20))
                orderTasklab:setAnchorPoint(0, 0.5)
                orderTasklab:setPosition(CCPoint(50, 410))
                layer:addChild(orderTasklab)
            else
                orderTasklab:setString(string.format(i18n.global.gmill_order_tasknum.string, #guildmill.order))
            end
        end)
    end)
	
	local btnStartAll, btnStartAllMenu = cui.createButton(0, i18n.global.act_bboss_sweep.string, 160, 40)
	
	btnStartAll:setPosition(CCPoint(310, 410))
	local btnState = 1
	
	layer:addChild(btnStartAllMenu)
	
	local function updateWhichButton()
		local wantState = 2
		if guildmill.order and #guildmill.order > 0 then
			for _, v in pairs(guildmill.order) do
				if not v.cd then
					wantState = 1
					break
				end
			end
		end
		
		if wantState ~= btnState then
			if wantState == 1 then
				clearShader(btnStartAll, true)
				btnStartAll:setEnabled(true)
			else
				setShader(btnStartAll, SHADER_GRAY, true)
				btnStartAll:setEnabled(false)
			end
			btnState = wantState
		end
	end
	
	updateWhichButton()
	
	local startOrderArr = {}
	
	btnStartAll:registerScriptTapHandler(function()
        audio.play(audio.button) 
		local params = {
			sid = player.sid,
			mid = 0,
		}
		addWaitNet()
		net:gmill_start(params, function(__data)
			delWaitNet()
			tbl2string(__data)
			if __data.status ~= 0 then
				showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
				return
			end
			for _, v in ipairs(startOrderArr) do
				v()
			end
			startOrderArr = {}
		end)
    end)
	
    function noorder()
        local noorderlayer = CCLayer:create()
        
        local empty = require "ui.empty"
        local emptyBox = empty.create({text = i18n.global.gmill_noorder.string})
        emptyBox:setPosition(360, 220)
        noorderlayer:addChild(emptyBox)

        return noorderlayer
    end

    function isorder()
        local isorderlayer = CCLayer:create()
        
        local itemNum = #guildmill.order
        --local SCROLL_CONTAINER_SIZE = math.max(itemNum * 220 + 30,930)        
        local SCROLL_CONTAINER_SIZE = itemNum * 250        
        
        local Scroll = CCScrollView:create()
        Scroll:setDirection(kCCScrollViewDirectionHorizontal)
        --Scroll:setAnchorPoint(ccp(0, 0))
        Scroll:setPosition(51, 552-500)
        Scroll:setViewSize(CCSize(616,330))
        Scroll:setContentSize(CCSize(SCROLL_CONTAINER_SIZE+20,400))
        isorderlayer:addChild(Scroll)

        local itemBg = {}
        local timebg = {}
        local progressLabel = {}
        local cliamdBtn = {}
        local powerProgress = {}
		startOrderArr = {}

        local function createItem(pos)
            print("pos:", pos)
            itemBg[pos] = img.createUI9Sprite(img.ui.botton_fram_2)
            itemBg[pos]:setPreferredSize(CCSizeMake(244, 322)) 
            itemBg[pos]:setPosition(-248 + 250 * pos+itemBg[pos]:getContentSize().width/2,
                                    itemBg[pos]:getContentSize().height/2)
            Scroll:getContainer():addChild(itemBg[pos])

            local orderID = guildmill.order[pos].id
            local ordericon = img.createUISprite(img.ui["guild_mill_order" .. cfgmill[orderID].resId])
            ordericon:setScale(0.8)
            ordericon:setPosition(itemBg[pos]:getContentSize().width/2, 238)
            itemBg[pos]:addChild(ordericon)

            local line = img.createUI9Sprite(img.ui.gemstore_fgline)
            line:setPreferredSize(CCSize(218, 2))
            line:setPosition(CCPoint(244/2, 174))
            itemBg[pos]:addChild(line)

            local dx = 14
            local sx = 45 - dx/2*(orderID-1)
            for i = 1,orderID do
                local star = img.createUISprite(img.ui.guild_mill_star_s)
                star:setPosition(sx+dx*(i-1), 10)
                ordericon:addChild(star, 1)
            end

            json.load(json.ui.clock)
            local clockIcon = DHSkeletonAnimation:createWithKey(json.ui.clock)
            clockIcon:scheduleUpdateLua()
            clockIcon:playAnimation("animation", -1)
            clockIcon:setPosition(28, 292)
            itemBg[pos]:addChild(clockIcon, 100)

            local timelab = lbl.createFont1(16, cfgmill[orderID].time .. i18n.global.herotask_time.string, ccc3(0x94, 0x6b, 0x4a))
            timelab:setAnchorPoint(0, 0.5)
            timelab:setPosition(clockIcon:boundingBox():getMaxX()+25, 292)
            itemBg[pos]:addChild(timelab)

            timebg[pos] = img.createUI9Sprite(img.ui.guild_mill_timebg)
            timebg[pos]:setPreferredSize(CCSizeMake(211, 34))
            --timebg:setAnchorPoint(0, 0.5)
            timebg[pos]:setPosition(244/2, 54)
            itemBg[pos]:addChild(timebg[pos])
            timebg[pos]:setVisible(false)

            local progress0 = img.createUISprite(img.ui.herotask_time_shortfg)
            powerProgress[pos] = createProgressBar(progress0)
            powerProgress[pos]:setScaleX(208/powerProgress[pos]:getContentSize().width)
            powerProgress[pos]:setScaleY(30/powerProgress[pos]:getContentSize().height)
            powerProgress[pos]:setPosition(timebg[pos]:getContentSize().width/2, timebg[pos]:getContentSize().height/2)
            powerProgress[pos]:setPercentage(0/100*100)
            timebg[pos]:addChild(powerProgress[pos])

            local progressStr = string.format("%02d:%02d:%02d", cfgmill[orderID].time, 0, 0)
            progressLabel[pos] = lbl.createFont2(16, progressStr, ccc3(255, 246, 223))
            progressLabel[pos]:setPosition(CCPoint(timebg[pos]:getContentSize().width/2,
                                            timebg[pos]:getContentSize().height/2))
            timebg[pos]:addChild(progressLabel[pos])

            -- cliamd btn
            local cliamdSprite = img.createLogin9Sprite(img.login.button_9_small_green)
            cliamdSprite:setPreferredSize(CCSizeMake(140, 48))
            cliamdBtn[pos] = SpineMenuItem:create(json.ui.button, cliamdSprite)
            local cliamdlab = lbl.createFont1(20, i18n.global.task_btn_claim.string, ccc3(0x1d, 0x67, 0x00))
            cliamdlab:setPosition(CCPoint(cliamdSprite:getContentSize().width/2, cliamdSprite:getContentSize().height/2+2))
            cliamdSprite:addChild(cliamdlab)
            --cliamdBtn[pos]:setAnchorPoint(CCPoint(0.5, 0.5))
            cliamdBtn[pos]:setPosition(244/2, 54)
            cliamdBtn[pos]:setVisible(false)
            local cliamdMenu = CCMenu:createWithItem(cliamdBtn[pos])
            cliamdMenu:setPosition(0, 0)
            itemBg[pos]:addChild(cliamdMenu)
            cliamdBtn[pos]:registerScriptTapHandler(function()
                audio.play(audio.button)
                local param = {}
                param.sid = player.sid
                param.mid = guildmill.order[pos].mid

                addWaitNet()
                net:gmill_claim(param, function(__data)
                    delWaitNet()
                    tbl2string(__data)
                    if __data.status ~= 0 then
                        showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                        return
                    end
                    local tmp_bag = {
                        items = {},
                        equips = {},
                    }
                    if __data.reward.items then
                        for ii=1,#__data.reward.items do
                            local tbl_p = tmp_bag.items
                            tbl_p[#tbl_p+1] = {id=__data.reward.items[ii].id, num=__data.reward.items[ii].num}
                        end
                    elseif __data.reward.equips then
                        for ii=1,#__data.reward.equips do
                            local tbl_p = tmp_bag.equips
                            tbl_p[#tbl_p+1] = {id=__data.reward.equips[ii].id, num=__data.reward.equips[ii].num}
                        end
                    end
                    local rewardsKit = require "ui.reward"
                    CCDirector:sharedDirector():getRunningScene():addChild(rewardsKit.showReward(tmp_bag), 100000)
                    bag.addRewards(__data.reward)

                    --guildmill.order[pos].rewards = nil
                    --guildmill.order[pos] = nil
                    table.remove(guildmill.order, pos)
                    table.remove(guildmill.pull_ocd_time, pos)

                    tbl2string(guildmill.order)
                    orderlayer:removeFromParentAndCleanup(true)
                    orderlayer = nil
                    --orderlayer = noorder()
                    --layer:addChild(orderlayer)

                    if guildmill.order and #guildmill.order > 0 then
                        orderlayer = isorder()
                        --orderTasklab = lbl.createMixFont1(16, string.format(i18n.global.gmill_order_tasknum.string, #guildmill.order), ccc3(0x4e, 0x34, 0x2e))
                        --orderTasklab:setAnchorPoint(0, 0.5)
                        --orderTasklab:setPosition(CCPoint(50, 410))
                        --layer:addChild(orderTasklab)

                        --local recTimeStr = string.format("%02d:%02d:%02d", 0, 0, 0)
                        --recTimeLabel = lbl.createFont2(16, recTimeStr, ccc3(0xc3, 0xff, 0x42))
                        --recTimeLabel:setAnchorPoint(1, 0.5)
                        --recTimeLabel:setPosition(CCPoint(470, 408))
                        --layer:addChild(recTimeLabel)
                        --recTimeLabel:setVisible(false)
                    else
                        orderlayer = noorder()
                    end
                    orderTasklab:setString(string.format(i18n.global.gmill_order_tasknum.string, #guildmill.order))
                    layer:addChild(orderlayer)
                        --layer.aniOrderhuxi:removeFromParent()
                    --itemBg[pos].aniOrderhuxi = nil
                end)
            end)

            local startorder = nil
            local uporder = nil
            local tmp_item = {}

            local rewardObj = cfgmill[orderID].reward

            local offset_x = 92
            for ii=1,#rewardObj do
                local itemObj = {}  
                itemObj.id = rewardObj[ii].id
                if guildmill.order.rewards and upflag == false then
                    for ii=1,#guildmill.order.rewards.items do
                        if guildmill.order.rewards.items[ii].id == itemObj.id then
                            itemObj.num = guildmill.order.rewards.items[ii].num
                        end
                    end
                else
                    if guildmill.order[pos].mlv then
                        itemObj.num = math.floor(rewardObj[ii].num*cfgmilllv[guildmill.order[pos].mlv].effec+0.5)
                    else
                        itemObj.num = math.floor(rewardObj[ii].num*cfgmilllv[guildmill.lv].effec+0.5)
                    end
                end
                local tmp_item0 = img.createItem(itemObj.id, itemObj.num)
                tmp_item[ii] = SpineMenuItem:create(json.ui.button, tmp_item0)
                
                tmp_item[ii]:setScale(0.65)
                -- 487+20-226, 520-485
                tmp_item[ii]:setPosition(CCPoint(offset_x+(ii-1)*64, 125))
                local tmp_item_menu = CCMenu:createWithItem(tmp_item[ii])
                tmp_item_menu:setPosition(CCPoint(0, 0))
                itemBg[pos]:addChild(tmp_item_menu)

                tmp_item[ii]:registerScriptTapHandler(function()
                    audio.play(audio.button)
                    local tmp_tip
                    tmp_tip = tipsitem.createForShow({id=itemObj.id})
                    isorderlayer:getParent():getParent():getParent():addChild(tmp_tip, 10000)
                    tmp_tip.setClickBlankHandler(function()
                        tmp_tip:removeFromParentAndCleanup(true)
                    end)
                end)
            end

            -- upgrade btn
            local upgradeSprite = img.createUISprite(img.ui.guild_mill_orderup)
            --upgradeSprite:setPreferredSize(CCSizeMake(160, 52))
            local upgradeBtn = SpineMenuItem:create(json.ui.button, upgradeSprite)
            --local upgradeGem = img.createItemIcon2(ITEM_ID_GEM)
            --upgradeGem:setScale(0.9)
            --upgradeGem:setPosition(30, upgradeSprite:getContentSize().height/2+3)
            --upgradeSprite:addChild(upgradeGem)

            --local upgradeGemlab = lbl.createFont2(16, string.format("%d", cfgmill[orderID].upCost), ccc3(255, 246, 223))
            --upgradeGemlab:setPosition(upgradeGem:getContentSize().width/2, 0) 
            --upgradeGem:addChild(upgradeGemlab)

            --local upgradelab = lbl.createFont1(20, i18n.global.gskill_btn_up.string, ccc3(0x1d, 0x67, 0x00))
            --upgradelab:setPosition(CCPoint(upgradeSprite:getContentSize().width*3/5, upgradeSprite:getContentSize().height/2))
            --upgradeSprite:addChild(upgradelab)
            --upgradeBtn:setAnchorPoint(CCPoint(0.5, 0))
            upgradeBtn:setPosition(210, 286)
            local upgradeMenu = CCMenu:createWithItem(upgradeBtn)
            upgradeMenu:setPosition(0, 0)
            itemBg[pos]:addChild(upgradeMenu)

            -- start btn
            local startSprite = img.createLogin9Sprite(img.login.button_9_small_gold)
            startSprite:setPreferredSize(CCSizeMake(140, 48))
            local startBtn = SpineMenuItem:create(json.ui.button, startSprite)
            local startlab = lbl.createFont1(20, i18n.global.herotask_start_btn.string, ccc3(0x73, 0x3b, 0x05))
            startlab:setPosition(CCPoint(startSprite:getContentSize().width/2, upgradeSprite:getContentSize().height/2+4))
            startSprite:addChild(startlab)
            --startBtn:setAnchorPoint(CCPoint(0.5, 0))
            startBtn:setPosition(244/2, 54)
            local startMenu = CCMenu:createWithItem(startBtn)
            startMenu:setPosition(0, 0)
            itemBg[pos]:addChild(startMenu)

            -- 确认是否用钻石升级
            local function createCostDiamond()
                local params = {}
                params.btn_count = 0
                params.body = string.format(i18n.global.gmill_order_sure.string, cfgmill[orderID].upCost)
                local board_w = 474

                local dialoglayer = require("ui.dialog").create(params) 

                local btnYesSprite = img.createLogin9Sprite(img.login.button_9_small_gold)
                btnYesSprite:setPreferredSize(CCSize(153, 50))
                local btnYes = SpineMenuItem:create(json.ui.button, btnYesSprite)
                btnYes:setPosition(board_w/2+95, 100)
                local labYes = lbl.createFont1(18, i18n.global.board_confirm_yes.string, ccc3(0x73, 0x3b, 0x05))
                labYes:setPosition(btnYes:getContentSize().width/2, btnYes:getContentSize().height/2)
                btnYesSprite:addChild(labYes)
                local menuYes = CCMenu:create()
                menuYes:setPosition(0, 0)
                menuYes:addChild(btnYes)
                dialoglayer.board:addChild(menuYes)

                local btnNoSprite = img.createLogin9Sprite(img.login.button_9_small_gold)
                btnNoSprite:setPreferredSize(CCSize(153, 50))
                local btnNo = SpineMenuItem:create(json.ui.button, btnNoSprite)
                btnNo:setPosition(board_w/2-95, 100)
                local labNo = lbl.createFont1(18, i18n.global.board_confirm_no.string, ccc3(0x73, 0x3b, 0x05))
                labNo:setPosition(btnNo:getContentSize().width/2, btnNo:getContentSize().height/2)
                btnNoSprite:addChild(labNo)
                local menuNo = CCMenu:create()
                menuNo:setPosition(0, 0)
                menuNo:addChild(btnNo)
                dialoglayer.board:addChild(menuNo)

                
                btnYes:registerScriptTapHandler(function()
                    dialoglayer:removeFromParentAndCleanup(true)
                    if bag.gem() < cfgmill[orderID].upCost then
                        showToast(i18n.global.summon_gem_lack.string)
                        return 
                    end

                    local param = {}
                    param.sid = player.sid
                    param.mid = guildmill.order[pos].mid

                    addWaitNet()
                    net:gmill_uporder(param, function(__data)
                        delWaitNet()
                        tbl2string(__data)
                        if __data.status ~= 0 then
                            showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                            return
                        end
                        upflag = true

                        --json.load(json.ui.mofang_upgrade_down)
                        --local aniOrderdown = DHSkeletonAnimation:createWithKey(json.ui.mofang_upgrade_down)
                        --aniOrderdown:scheduleUpdateLua()
                        --aniOrderdown:playAnimation("animation")
                        --aniOrderdown:setPosition(itemBg[pos]:getContentSize().width/2, itemBg[pos]:getContentSize().height/2)
                        --itemBg[pos]:addChild(aniOrderdown, -1)

                        --json.load(json.ui.mofang_upgrade_up)
                        --local aniOrderup = DHSkeletonAnimation:createWithKey(json.ui.mofang_upgrade_up)
                        --aniOrderup:scheduleUpdateLua()
                        --aniOrderup:playAnimation(string.format("%d", guildmill.order[pos].id+1) .. "xing")
                        --aniOrderup:setPosition(itemBg[pos]:getContentSize().width/2, itemBg[pos]:getContentSize().height/2)
                        --itemBg[pos]:addChild(aniOrderup, -1)

                        guildmill.order[pos].id = guildmill.order[pos].id + 1
                        bag.subGem(cfgmill[orderID].upCost)
                        orderID = guildmill.order[pos].id

                        uporder()
                    end)
                    audio.play(audio.button)
                end)
                btnNo:registerScriptTapHandler(function()
                    dialoglayer:removeFromParentAndCleanup(true)
                    audio.play(audio.button)
                end)

                local function backEvent()
                    dialoglayer:removeFromParentAndCleanup(true)
                end

                function dialoglayer.onAndroidBack()
                    backEvent()
                end

                addBackEvent(dialoglayer)
                
                local function onEnter()
                    dialoglayer.notifyParentLock()
                end

                local function onExit()
                    dialoglayer.notifyParentUnlock()
                end

                dialoglayer:registerScriptHandler(function(event) 
                    if event == "enter" then 
                        onEnter()
                    elseif event == "exit" then
                        onExit()
                    end
                end)
                return dialoglayer
            end

            upgradeBtn:registerScriptTapHandler(function()
                audio.play(audio.button)
                local dialog = createCostDiamond()
                layer:getParent():getParent():addChild(dialog, 1300)
            end)

            startBtn:registerScriptTapHandler(function()
                disableObjAWhile(startBtn)
                audio.play(audio.button)
                local params = {
                    sid = player.sid,
                    mid = guildmill.order[pos].mid,
                }
                addWaitNet()
                net:gmill_start(params, function(__data)
                    delWaitNet()
                    tbl2string(__data)
                    if __data.status ~= 0 then
                        showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                        return
                    end
                    startorder()
                end)

                --camplayer = selecthero.create({type = "guildmill", callBack = startorder})  
                --isorderlayer:getParent():getParent():getParent():addChild(camplayer, 10011)
            end)

            if cfgmill[orderID].upCost == 0 then
                upgradeBtn:setVisible(false)
            end

            function startorder()
                --cliamdBtn[pos]:setVisible(true) 
                upgradeBtn:setVisible(false)
                startBtn:setVisible(false)
                --if camplayer and not tolua.isnull(camplayer) then 
                --    camplayer:removeFromParentAndCleanup(true)
                --    camplayer = nil
                --end
                if guildmill.order[pos].cd == nil then
                    if guildmill.pull_ocd_time == nil then
                        guildmill.pull_ocd_time = {}
                    end
                    guildmill.pull_ocd_time[pos] = os.time()
                    guildmill.order[pos].cd = cfgmill[guildmill.order[pos].id].time*3600 - 600
                end
                if guildmill.order[pos].cd == 0 then
                    --cliamdlab:setString(i18n.global.task_btn_claim.string)
                    
                    cliamdBtn[pos]:setVisible(true)
                    local timeLab = string.format("%02d:%02d:%02d",math.floor(0/3600),math.floor((0%3600)/60),math.floor(0%60))
                    progressLabel[pos]:setString(timeLab)
                    powerProgress[pos]:setPercentage((1-guildmill.order[pos].cd/(cfgmill[orderID].time*3600-600))*100)
                else
                    cliamdBtn[pos]:setEnabled(false)
                    --setShader(cliamdBtn, SHADER_GRAY, true)
                end
            end
			
			if guildmill.order[pos].cd == nil then
				startOrderArr[#startOrderArr + 1] = startorder
			end
			
            function uporder()
                ordericon:removeFromParent()
                ordericon = nil
                ordericon = img.createUISprite(img.ui["guild_mill_order" .. cfgmill[orderID].resId])
                ordericon:setScale(0.8)
                ordericon:setPosition(itemBg[pos]:getContentSize().width/2, 238)
                itemBg[pos]:addChild(ordericon)

                sx = 45 - dx/2*(orderID-1)
                for iii = 1,orderID do
                    local star = img.createUISprite(img.ui.guild_mill_star_s)
                    star:setPosition(sx+dx*(iii-1), 10)
                    ordericon:addChild(star, 1)
                end

                timelab:setString(cfgmill[orderID].time .. i18n.global.herotask_time.string)

                if cfgmill[orderID].upCost == 0 then
                    upgradeBtn:setVisible(false)
                end

                local rewardObj = cfgmill[orderID].reward

                local offset_x = 92
                for ii=1,#rewardObj do
                    if tmp_item[ii] then
                        tmp_item[ii]:removeFromParent()
                        tmp_item[ii] = nil
                    end
                    local itemObj = {}  
                    itemObj.id = rewardObj[ii].id
                    if guildmill.order.rewards and upflag == false then
                        for ii=1,#guildmill.order.rewards.items do
                            if guildmill.order.rewards.items[ii].id == itemObj.id then
                                itemObj.num = guildmill.order.rewards.items[ii].num
                            end
                        end
                    else
                        if guildmill.order[pos].mlv then
                            itemObj.num = math.floor(rewardObj[ii].num*cfgmilllv[guildmill.order[pos].mlv].effec+0.5)
                        else
                            itemObj.num = math.floor(rewardObj[ii].num*cfgmilllv[guildmill.lv].effec+0.5)
                        end
                    end
                    local tmp_item0 = img.createItem(itemObj.id, itemObj.num)
                    tmp_item[ii] = SpineMenuItem:create(json.ui.button, tmp_item0)
                    
                    tmp_item[ii]:setScale(0.65)
                    -- 487+20-226, 520-485
                    tmp_item[ii]:setPosition(CCPoint(offset_x+(ii-1)*64, 125))
                    local tmp_item_menu = CCMenu:createWithItem(tmp_item[ii])
                    tmp_item_menu:setPosition(CCPoint(0, 0))
                    itemBg[pos]:addChild(tmp_item_menu)

                    tmp_item[ii]:registerScriptTapHandler(function()
                        audio.play(audio.button)
                        local tmp_tip
                        tmp_tip = tipsitem.createForShow({id=itemObj.id})
                        isorderlayer:getParent():getParent():getParent():addChild(tmp_tip, 10000)
                        tmp_tip.setClickBlankHandler(function()
                            tmp_tip:removeFromParentAndCleanup(true)
                        end)
                    end)
                end
            end

            if guildmill.order[pos].cd ~= nil then
                startorder()
            end
        end

        for i=1,itemNum do
            createItem(i)
        end
        --local camplayer = nil

        local aniflag = true
        local function onUpdate(ticks)
			updateWhichButton()
            if guildmill.order == nil then
                return
            end
            for ii=1,#guildmill.order do
                if guildmill.order[ii].cd and guildmill.pull_ocd_time[ii] and progressLabel[ii] and not tolua.isnull(progressLabel[ii]) then
                    cd = math.max(0, guildmill.order[ii].cd + guildmill.pull_ocd_time[ii] - os.time())
                    if cd > 0 then
                        timebg[ii]:setVisible(true)
                        local timeLab = string.format("%02d:%02d:%02d",math.floor(cd/3600),math.floor((cd%3600)/60),math.floor(cd%60))
                        progressLabel[ii]:setString(timeLab)
                        powerProgress[ii]:setPercentage((1-cd/(60*60*cfgmill[guildmill.order[ii].id].time-600))*100)
                    else
                        local timeLab = string.format("%02d:%02d:%02d",math.floor(cd/3600),math.floor((cd%3600)/60),math.floor(cd%60))
                        progressLabel[ii]:setString(timeLab)
                        timebg[ii]:setVisible(false)
                        cliamdBtn[ii]:setVisible(true)
                        cliamdBtn[ii]:setEnabled(true)
                        --clearShader(cliamdBtn, true)

                        if aniflag then
                            aniflag = false
                            --json.load(json.ui.mofang_upgrade_huxi)
                            --local aniOrderhuxi = DHSkeletonAnimation:createWithKey(json.ui.mofang_upgrade_huxi)
                            --aniOrderhuxi:scheduleUpdateLua()
                            --aniOrderhuxi:playAnimation("animation", -1)
                            --aniOrderhuxi:setPosition(timebg[ii]:getContentSize().width/2, timebg[ii]:getContentSize().height/2)
                            --itemBg[ii]:addChild(aniOrderhuxi, 100)
                            --itemBg[ii].aniOrderhuxi = aniOrderhuxi

                            --json.load(json.ui.mofang_upgrade_line)
                            --local aniOrderline = DHSkeletonAnimation:createWithKey(json.ui.mofang_upgrade_line)
                            --aniOrderline:scheduleUpdateLua()
                            --aniOrderline:playAnimation("animation")
                            --aniOrderline:setPosition(timebg[ii]:getContentSize().width/2,
                            --                        timebg[ii]:getContentSize().height/2)
                            --timebg[ii]:addChild(aniOrderline)
                        end
                    end
                end
            end
        end
        isorderlayer:scheduleUpdateWithPriorityLua(onUpdate, 0)

        return isorderlayer
    end

    local function onUpdateForecd(ticks)
        if recTimeLabel and guildmill.ecd and guildmill.pull_ecd_time then
            cd = math.max(0, guildmill.ecd + guildmill.pull_ecd_time - os.time())
            if cd > 0 then
                local timeLab = string.format("%02d:%02d:%02d",math.floor(cd/3600),math.floor((cd%3600)/60),math.floor(cd%60))
                recTimeLabel:setString(timeLab)
                recTimeLabel:setVisible(true)
                setShader(recvorderBtn, SHADER_GRAY, true)
                recvorderBtn:setEnabled(false)
            else
                recvorderBtn:setEnabled(true)
                clearShader(recvorderBtn, true)
                recTimeLabel:setVisible(false)
            end
        end
    end
    layer:scheduleUpdateWithPriorityLua(onUpdateForecd, 0)

    return layer
end

return ui
