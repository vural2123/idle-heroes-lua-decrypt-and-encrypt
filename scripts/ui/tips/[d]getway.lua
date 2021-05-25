-- 获得物品途径tips

local tips = {}

require "common.func"
require "common.const"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local audio = require "res.audio"
local cfgitem = require "config.item"
local cfgequip = require "config.equip"
local cfghero = require "config.hero"
local bagdata = require "data.bag"
local herosdata = require "data.heros"
local i18n = require "res.i18n"
local player = require "data.player"
local gdata = require "data.guild"

local TIPS_WIDTH = 360 -- tips背景框的宽度
local TIPS_MARGIN = 23 -- tips文字到背景边的距离
local MAX_WAY = 6   --超过MAX_WAY支持滚动
local SCROLL_HEIGHT = 6*70 -- scrollView的最大高度
local LABEL_WIDTH = TIPS_WIDTH - 2 * TIPS_MARGIN

local GoTypeEnum = {
    none = 0,--不跳转
    arenaTickte = 1, --钻石购买
	blackmarket = 2,--黑市
	herotask = 3,--酒馆任务
	casino = 4,--许愿池, 赌场
	arena = 5,--竞技场
	hook = 6,--副本挂机
    summon = 7, --召唤界面
	summonspe = 8,--先知之树
	heromarket = 9,--英雄商店
	trial = 10,--幻境之塔
    casinoshop = 11, --幸运商店
	brave = 12,--勇者试炼
	achieve = 13,--成就
	task = 14,--每日任务
	guild = 15,--公会
	midas = 16,--点金手
    solo = 17, --地牢
    shopbuy = 18, --商城
    airland = 19, --悬空岛
	smith = 20,--铁匠铺
    devour = 21,--英雄分解
    guildshop = 22, --公会商店
    commoncasino = 23, --普通许愿池
    highcasino = 24, --高级许愿池
	dare = 25,--活动副本
    --loginreward = 26, --登录奖励
    brave_shop = 27,--, 勇者试炼商店
    pvp3 = 28, --冠军的试炼
    pvp3_shop = 29,--冠军试炼商店
    casinoTickte = 30, --钻石购买
    hookmain = 31, -- 挂机不跳关卡
}

function tips.checkUnlock(goType)
    if goType == GoTypeEnum.hook then--副本挂机
        return 0
    elseif goType == GoTypeEnum.hookmain then--副本挂机不跳关卡
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
    elseif goType == GoTypeEnum.casino then--许愿池
        return 0
    --elseif goType == GoTypeEnum.loginreward then--登录奖励
    --    return 0
    elseif goType == GoTypeEnum.arenaTickte then--竞技场门票购买
        return 0
    elseif goType == GoTypeEnum.casinoTickte then--许愿币购买
        return 0
    elseif goType == GoTypeEnum.trial then--幻境之塔
        if BUILD_ENTRIES_ENABLE and player.lv() < UNLOCK_TRIAL_LEVEL then
            return UNLOCK_TRIAL_LEVEL
        end
    elseif goType == GoTypeEnum.dare then--活动副本--金币
        if BUILD_ENTRIES_ENABLE and player.lv() < 20 then
            return 20
        end
    elseif goType == GoTypeEnum.commoncasino then--许愿池
        if BUILD_ENTRIES_ENABLE and player.lv() < UNLOCK_CASINO_LEVEL then
            return UNLOCK_CASINO_LEVEL
        end
    elseif goType == GoTypeEnum.highcasino then--高级许愿池
        if BUILD_ENTRIES_ENABLE and player.lv() < UNLOCK_ADVANCED_CASINO_LEVEL and player.vipLv() < 3 then
            return UNLOCK_ADVANCED_CASINO_LEVEL
        end
    elseif goType == GoTypeEnum.airland then--空岛
        if BUILD_ENTRIES_ENABLE and player.lv() < UNLOCK_AIRISLAND_LEVEL then
            return UNLOCK_AIRISLAND_LEVEL
        end
    elseif goType == GoTypeEnum.solo then--地牢
        if BUILD_ENTRIES_ENABLE and player.lv() < UNLOCK_SOLO_LEVEL then
            return UNLOCK_SOLO_LEVEL
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
    elseif goType == GoTypeEnum.pvp3 then--勇者试炼商店
        if BUILD_ENTRIES_ENABLE and player.lv() < UNLOCK_ARENA_LEVEL then
            return UNLOCK_ARENA_LEVEL
        end
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

local function searchHookDrop(thing, ctype)
    local cfgpoker = require "config.poker"
    local hookdata = require "data.hook"
    local stage_id = hookdata.getPveStageId()
    if not stage_id then
        return
    end
    for ii=stage_id, 1, -1 do
        local cfg = cfgpoker[ii]
        if not cfg then return end
        for jj=1, #cfg.yes do
            if thing.id == cfg.yes[jj].id and ctype == cfg.yes[jj].type then
                return ii
            end
        end
    end
    for ii=stage_id, #cfgpoker do
        local cfg = cfgpoker[ii]
        if not cfg then return end
        for jj=1, #cfg.yes do
            if thing.id == cfg.yes[jj].id and ctype == cfg.yes[jj].type then
                return ii
            end
        end
    end
    return
end

-- ctype: 1物品 2装备
function tips.createLayer(thing, ctype)
    local layer = CCLayer:create()
       
    local cfg
    if ctype == 1 then
        cfg = cfgitem[thing.id].getWays
    else
        cfg = cfgequip[thing.id].getWays
    end
    --cfg = {1 , 2, 3 , 4, 5, 6 ,7}
    local container = CCLayer:create()
    local currentY = 0

    local name = lbl.createMix({
        font = 1, size = 18, text = i18n.global.item_getway_tips.string, 
        width = LABEL_WIDTH, align = kCCTextAlignmentLeft,
        color = ccc3(255, 246, 223),
    })
    name:setAnchorPoint(ccp(0, 1))
    name:setPosition(TIPS_MARGIN+12, currentY-18)
    container:addChild(name)
    currentY = name:boundingBox():getMinY()

    local btnBg = img.createUI9Sprite(img.ui.smith_drop_bg)
    btnBg:setPreferredSize(CCSize(314, op3(#cfg <= MAX_WAY, 70*#cfg+25, SCROLL_HEIGHT)))
    btnBg:setAnchorPoint(ccp(0, 1))
    btnBg:setPosition(TIPS_MARGIN, currentY-15)
    container:addChild(btnBg)

    local function gotoLayer(goType)
        local unlockLv = tips.checkUnlock(goType)
        if unlockLv > 0 then
            if goType == GoTypeEnum.highcasino then--高级许愿池,
                showToast(string.format(i18n.global.func_need_lv.string, unlockLv) .. "\n" .. string.format(i18n.global.func_need_lv_vip.string, 3))
            else
                showToast(string.format(i18n.global.func_need_lv.string, unlockLv))
            end
            return
        end

        local hold
        if goType == GoTypeEnum.hook then
            local t_stage = searchHookDrop(thing, ctype)
            if not t_stage then
                --showToast("hook stage unlock")
                showToast(string.format(i18n.global.hook_stage_unlock.string, ""))
                return
            end
            local hookdata = require "data.hook"
            local stage_id = hookdata.getPveStageId()
            if t_stage > stage_id then
                local ff, ss = hookdata.getFortStageByStageId(t_stage)
                --showToast("hook stage unlock")
                showToast(string.format(i18n.global.hook_stage_unlock.string, ff .. "-" .. ss))
                return
            end
            replaceScene(require("ui.hook.main").create({pop_layer="stage",stage_id=t_stage}))
        elseif goType == GoTypeEnum.arena then
            layer:addChild((require"ui.arena.entrance").create(), 1000)
        elseif goType == GoTypeEnum.hookmain then
            replaceScene(require("ui.hook.main").create())
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

                    --removeSelf()
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
        elseif goType == GoTypeEnum.casino then--许愿池
            layer:addChild(require("ui.casino.selectcasino").create(), 1000)
        --elseif goType == GoTypeEnum.loginreward then--登录奖励
        --    layer:addChild(require("ui.activity.main").create(), 1000)
        elseif goType == GoTypeEnum.arenaTickte then--竞技场门票
            layer:addChild(require("ui.arena.buy").create(), 1000)
        elseif goType == GoTypeEnum.casinoTickte then--许愿币
            layer:addChild(require("ui.casino.chip").create(), 1000)
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

                --removeSelf()
            end)
        elseif goType == GoTypeEnum.commoncasino then--许愿池, 赌场
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

                --removeSelf()
            end)
        elseif goType == GoTypeEnum.highcasino then--高级许愿池,
            hold = true

            local params = {
                sid = player.sid,
                type = 1,
                up = true,
            }
            addWaitNet()
            local highcasinodata = require"data.highcasino"
            highcasinodata.pull(params, function(__data)
                delWaitNet()
                tbl2string(__data)
                if __data.status ~= 0 then
                    showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                    return
                end
                highcasinodata.init(__data)
                replaceScene(require("ui.highcasino.main").create())
            end)
        elseif goType == GoTypeEnum.airland then--空岛,
            local params = {
                sid = player.sid,
            }
            addWaitNet()
            netClient:island_sync(params, function(__data)
                delWaitNet()
        
                tbl2string(__data)
                local airData = require "data.airisland"
                airData.setData(__data)
                replaceScene(require("ui.airisland.main1").create(__data))
            end)
        elseif goType == GoTypeEnum.solo then--地牢,
            addWaitNet()
            local params = {sid = player.sid}
            net:spk_sync(params, function (data) 
                delWaitNet()
                print("时间为"..data.cd)
                print("返回数据")
                tablePrint(data)
                tbl2string(data)
                local soloData = require("data.solo")
                soloData.init()
                if data.status == 1 or data.status == 2 then      --进入单挑赛界面
                    if soloData.getStatus() == 0 then
                        soloData.setSelectOrder(nil)
                    end
                    soloData.setMainData(data)
                    replaceScene(require("ui.solo.main").create())    
                elseif data.status == 0 then  --不能进入
                    soloData.setSelectOrder(nil)
                    soloData.setMainData(data)
                    replaceScene(require("ui.solo.noStartUI").create())
                end
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

                        --removeSelf()
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
        elseif goType == GoTypeEnum.pvp3 then--冠军的试炼商店
            local pvp3layer = (require "ui.arena.entrance").create(2)
            layer:addChild(pvp3layer, 1000)
        end
        
    end

    local btnGetway = {}
    local function createScrollLayer()
        local sccontainer = CCLayer:create()
        
        for i =1,#cfg do
            local btnGetwaysp = img.createLogin9Sprite(img.login.button_9_small_mwhite)
            btnGetwaysp:setPreferredSize(CCSize(290, 68))
            local labGetway = lbl.createFont1(20, i18n.itemgetways[cfg[i]].name, ccc3(0x76, 0x25, 0x05))
            labGetway:setPosition(btnGetwaysp:getContentSize().width/2, btnGetwaysp:getContentSize().height/2)
            btnGetwaysp:addChild(labGetway)

            btnGetway[i] = SpineMenuItem:create(json.ui.button, btnGetwaysp)
            btnGetway[i]:setPosition(TIPS_MARGIN+157, -(i-1)*70-52)
            local menuGetway = CCMenu:createWithItem(btnGetway[i])
            menuGetway:setPosition(0, 0)
            sccontainer:addChild(menuGetway)

            btnGetway[i]:registerScriptTapHandler(function()
                audio.play(audio.button)
                
                gotoLayer(cfg[i])
            end)
        end

        local ccurrentY = #cfg * 70 + 22
        local cHeight = ccurrentY
        local vHeight = op3(#cfg <= MAX_WAY, cHeight, SCROLL_HEIGHT)

        local scroll = CCScrollView:create()
        scroll:setDirection(kCCScrollViewDirectionVertical)
        scroll:ignoreAnchorPointForPosition(false)
        scroll:setContentSize(CCSize(TIPS_WIDTH, cHeight))
        scroll:setViewSize(CCSize(TIPS_WIDTH, vHeight))
        scroll:setTouchEnabled(cHeight > vHeight)
        scroll:setContentOffset(ccp(0, vHeight - cHeight))
        sccontainer:setPosition(0, cHeight)
        scroll:getContainer():addChild(sccontainer)

        return scroll
    end

    local scrollLayer = createScrollLayer() 
    scrollLayer:setAnchorPoint(ccp(0, 1))
    scrollLayer:setPosition(0, currentY-13)
    container:addChild(scrollLayer)
    --currentY = scrollLayer:boundingBox():getMinY()

    currentY = btnBg:boundingBox():getMinY()

    local height = 27 - currentY
    local bg = img.createUI9Sprite(img.ui.tips_bg)
    bg:setPreferredSize(CCSize(TIPS_WIDTH, height))
    --bg:setAnchorPoint(ccp(0, 0.5))
    container:setPosition(0, height)
    bg:addChild(container)

    bg:setScale(view.minScale)
    bg:setPosition(view.physical.w/2+bg:getPreferredSize().width/2*view.minScale, view.physical.h/2)
    layer:addChild(bg)

    bg:setScale(0.5*view.minScale)
    bg:runAction(CCScaleTo:create(0.15, 1*view.minScale, 1*view.minScale))

    layer.bg = bg

    -- 点击空白区域的回调
    local clickBlankHandler
    function layer.setClickBlankHandler(handler)
        clickBlankHandler = handler
    end

    local function onTouch(eventType, x, y)
        if eventType == "began" then   
            return true
        elseif eventType == "moved" then
            return 
        else
            --if not tips1:boundingBox():containsPoint(ccp(x, y))
            --    and (tips2 == nil or not tips2:boundingBox():containsPoint(ccp(x, y))) then
                --layer.onAndroidBack()
            --end
        end
    end

    addBackEvent(layer)

    function layer.onAndroidBack()
        if clickBlankHandler then
            clickBlankHandler()
        else
            layer:removeFromParent()
        end
    end

    layer:registerScriptHandler(function(event)
        if event == "enter" then
            layer.notifyParentLock()
        elseif event == "exit" then
            layer.notifyParentUnlock()
        end
    end)

    layer:registerScriptTouchHandler(onTouch)
    --layer:setTouchEnabled(true)
    layer:setTouchSwallowEnabled(true)

    return layer
end

return tips
