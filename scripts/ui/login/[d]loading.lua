-- 启动后的loading

local ui = {}

require "common.const"
require "common.func"
local view = require "common.view"
local img = require "res.img"
local json = require "res.json"
local lbl = require "res.lbl"
local audio = require "res.audio"
local i18n = require "res.i18n"
local net = require "net.netClient"
local userdata = require "data.userdata"
local heartbeat = require "data.heartbeat"

-- init shaders
ShaderManager:getInstance():init(require("data.shaders"))

local function sync_unpack(data, i, j)
    local res = { }
    while i <= j do
        res[#res + 1] = data[i]
        i = i + 1
    end
    return res
end

local function sync_sline(data)
    local ci = 1
    local ct = 0
    local hids = nil
    while data[ci] do
        ct = data[ci]
        ci = ci + 1
        if ct == 1 then
            hids = sync_unpack(data, ci, ci + 6)
            userdata.setSquadNormal(hids)
            ci = ci + 7
        elseif ct == 2 then
            hids = sync_unpack(data, ci, ci + 6)
            userdata.setSquadTrial(hids)
            ci = ci + 7
        elseif ct == 3 then
            hids = sync_unpack(data, ci, ci + 6)
            userdata.setSquadArenaatk(hids)
            ci = ci + 7
        elseif ct == 4 then
            hids = sync_unpack(data, ci, ci + 6)
            userdata.setSquadArenadef(hids)
            ci = ci + 7
        elseif ct == 5 then
            hids = sync_unpack(data, ci, ci + 6)
            userdata.setSquadFrdArena(hids)
            ci = ci + 7
        elseif ct == 6 then
            hids = sync_unpack(data, ci, ci + 6)
            userdata.setSquadGuildBoss(hids)
            ci = ci + 7
        elseif ct == 7 then
            hids = sync_unpack(data, ci, ci + 6)
            userdata.setSquadDailyFight(hids)
            ci = ci + 7
        elseif ct == 8 then
            hids = sync_unpack(data, ci, ci + 6)
            userdata.setSquadFriend(hids)
            ci = ci + 7
        elseif ct == 9 then
            hids = sync_unpack(data, ci, ci + 6)
            userdata.setSquadguildmill(hids)
            ci = ci + 7
        elseif ct == 10 then
            hids = sync_unpack(data, ci, ci + 6)
            userdata.setSquadguildmilldef(hids)
            ci = ci + 7
        elseif ct == 11 then
            hids = sync_unpack(data, ci, ci + 6)
            userdata.setGuildFight(hids)
            ci = ci + 7
        elseif ct == 12 then
            hids = sync_unpack(data, ci, ci + 6)
            userdata.setSquadFrdpk(hids)
            ci = ci + 7
        elseif ct == 13 then
            hids = sync_unpack(data, ci, ci + 6)
            userdata.setSquadBrokenboss(hids)
            ci = ci + 7
        elseif ct == 14 then
            hids = sync_unpack(data, ci, ci + 6)
            userdata.setSquadSweepforbrokenboss(hids)
            ci = ci + 7
        elseif ct == 15 then
            hids = sync_unpack(data, ci, ci + 20)
            userdata.setSquadArena3v3Def(hids)
            ci = ci + 21
        elseif ct == 16 then
            hids = sync_unpack(data, ci, ci + 20)
            userdata.setSquadArena3v3Atk(hids)
            ci = ci + 21
        elseif ct == 17 then
            hids = sync_unpack(data, ci, ci + 6)
            userdata.setSquadAirisland(hids)
            ci = ci + 7
        elseif ct == 18 then
            hids = sync_unpack(data, ci, ci + 6)
            userdata.setSquadSweepforairisland(hids)
            ci = ci + 7
        elseif ct == 19 then
            hids = sync_unpack(data, ci, ci + 6)
            userdata.setSquadGuildGray(hids)
            ci = ci + 7
        elseif ct == 20 then
            hids = sync_unpack(data, ci, ci + 6)
            userdata.setSquadSweepforfboss(hids)
            ci = ci + 7
        elseif ct == 21 then
            hids = sync_unpack(data, ci, ci + 6)
            userdata.setSquadSweepforcomisland(hids)
            ci = ci + 7
        elseif ct == 22 then
            --hids = sync_unpack(data, ci, ci + 6)
            --userdata.setSquadSweepforcomisland(hids)
            ci = ci + 7
        elseif ct == 23 then
            hids = sync_unpack(data, ci, ci + 6)
            userdata.setSquadArenabatk(hids)
            ci = ci + 7
        elseif ct == 24 then
            hids = sync_unpack(data, ci, ci + 6)
            userdata.setSquadArenabdef(hids)
            ci = ci + 7
        end
    end
end

-- 创建页面
function ui.create(uid, sid)
    local layer = CCLayer:create()

    local parent

    function layer.setHint(text)
        if not parent and not tolua.isnull(layer) then
            parent = layer:getParent()
        end
        if parent and parent.setHint then
            parent.setHint(text)
        end
    end

    function layer.setPercentageForProgress(percentage)
        if not parent and not tolua.isnull(layer) then
            parent = layer:getParent()
        end
        if parent and parent.setPercentageForProgress then
            parent.setPercentageForProgress(percentage)
        end
    end

    net:setDialogEnable(true)
    heartbeat.run(sid)

    -- 拉取帐单校验
    function layer.checkIAP()
        require("data.player").init(uid, sid)
        require("common.iap").pull(function(reward)
            if reward then
                require("data.bag").addRewards(reward)
            end 
            layer.sync()
        end)
    end
    layer:runAction(CCCallFunc:create(layer.checkIAP))

    -- 拉取玩家的游戏数据
    function layer.sync()
        layer.setHint(i18n.global.sync_data.string)
        local isDone = false
        local sync_param = {
            sid = sid,
            idfa = HHUtils:getAdvertisingId(),
            keychain = HHUtils:getUniqKC(),
            idfv = HHUtils:getUniqFv(),
        }
        net:sync(sync_param, function(data)
            print("------------------------------sysnc data:")
            tbl2string(data)
            if not isDone then
                isDone = true
                if data.status ~= 0 then
                    layer.setHint(i18n.global.sync_data_fail.string .. data.status)
                    return
                end
                -- 初始化各种数据
                local playerdata = require "data.player"
                playerdata.init(uid, sid, data.player)
                if data.final_rank then
                    playerdata.final_rank = data.final_rank
                else
                    playerdata.final_rank = nil
                end
                if data.hide_vip then
                    playerdata.hide_vip = data.hide_vip
                else
                    playerdata.hide_vip = nil
                end
                if data.chatblocks then
                    playerdata.chatblocks = data.chatblocks
                else
                    playerdata.chatblocks = 0
                end
                playerdata.print()
                playerdata.buy_hlimit = data.buy_hlimit or 0
                local bagdata = require "data.bag"
                bagdata.init(data.bag)
                bagdata.print()
                local herosdata = require "data.heros"
                herosdata.init(data.heroes)
                herosdata.adaptreplace(data.sreplace)
                herosdata.print()
                local gachadata = require "data.gacha"
                gachadata.init(data.gacha)
                gachadata.initspacesummon(data.space_gacha)
                gachadata.print()
                local herobook = require "data.herobook"
                herobook.init(data.hero_ids)
                herobook.print()
                local rateus = require "data.rateus"
                rateus.init(data.rate_us)
                rateus.print()
                local videoad = require "data.videoad"
                videoad.init(data.video_ad)
                videoad.print()
                local trialdata = require "data.trial"
                trialdata.init(data.trial)
                local chatdata = require "data.chat"
                chatdata.deSync()
                chatdata.registEvent()
                if data.htask then
                    local herotaskData = require "data.herotask"
                    herotaskData.init(data.htask)
                end
                local mail = require "data.mail"
                mail.init(data.mails)
                --mail.print()
                mail.registEvent()
                local midas = require "data.midas"
                midas.init(data.midas_cd, data.midas_flag)
                midas.print()
                local achieveData = require "data.achieve"
                achieveData.init(data.achieve)
                local databrave = require "data.brave"
                databrave.clear()
                if data.reddot then
                    databrave.initRedDot(data.reddot)
                end
                if data.tasks then
                    tbl2string(data.tasks)
                    local taskdata = require "data.task"
                    taskdata.syncInit({tasks=data.tasks})
                    taskdata.setCD(data.task_cd or 3600*2400)
                end
                if data.online then
                    local onlinedata = require "data.online"
                    onlinedata.sync(data.online)
                end
                -- activities
                if data.acts then
                    local activityData = require "data.activity"
                    print("****activity****")
                    tbl2string(data.acts)
                    activityData.initgrp(data.activitygrp)
                    activityData.init({status=data.acts})
                    activityData.print()
                end
                -- limitactivities
                if data.limitacts then
                    print("--------------------limitactivity status--------------")
                    tbl2string(data.limitacts)
                    local limitactivityData = require "data.activitylimit"
                    limitactivityData.init({status=data.limitacts})
                else
                    local limitactivityData = require "data.activitylimit"
                    limitactivityData.init({status=nil})
                end
                local hook = require "data.hook"
                print("sync ------------- hook")
                if data.hook then
                    tbl2string(data.hook)
                end
                hook.init(data.hook)
                local friend = require "data.friend"
                if data.friends then
                    friend.init(data.friends)
                end
                friend.registEvent()
                local frdboss = require "data.friendboss"
                if data.frd_boss then
                    frdboss.init(data.frd_boss)
                end
                frdboss.registEvent()
                local frdarena = require "data.frdarena"
                frdarena.registEvent()
                local gdata = require "data.guild"
                gdata.deInit()
                gdata.Listen()
                local gmilldata = require "data.guildmill"
                if data.reddot then
                    gmilldata.initRedDot(data.reddot)
                end
                local shop = require "data.shop"
                shop.init(data.pay_num)
                if data.subscribed and data.subscribed == 1 then
                    shop.setPay(33, 1)
                else
                    shop.setPay(33, 0)
                end
                shop.print()
                local monthlogin = require "data.monthlogin"
                if data.alogin then
                    monthlogin.init(data.alogin)
                    monthlogin.print()
                end
                local smith = require "ui.smith.main"
                smith.equipformulas.init()
                local airData = require "data.airisland"
                if data.reddot then
                    airData.initRedDot(data.reddot)
                end

                if data.cds then
                    require("data.cd").initCDS(data.cds)
                end
                -- 公会科技技能, 英雄面板展示，先初始化
                require("data.gskill").sync(data.gskls)
                require("data.gskill").initCode(data.gsklcode)
                
				if data.sline then
					sync_sline(data.sline)
				end
				
				playerdata.skinicons = {}
				if data.skinicon then
					for _, v in ipairs(data.skinicon) do
						playerdata.skinicons[v] = 1
					end
				end
				require("data.head").forceRed = nil
				
				if data.iron and data.iron ~= 0 then
					playerdata.iron = os.time() + data.iron
				else
					playerdata.iron = nil
				end
                
				local pepe = data.pepe or 0
                playerdata.code = bit.band(pepe, 1)
				playerdata.pepemod = bit.brshift(pepe, 8)
                
                require("ui.foodbag.data").init(data.foodbag)

                --宠物
                local pet = require "data.pet"
                pet.data  = {}
                pet.initData()
                if data.pets then
                    --做一些数据兼容处理，如果要读pet代码，必须了解
                    pet.setData(data.pets)
                end
                --单挑赛
                local solo = require "data.solo"
                if data.reddot then
                    solo.initRedDot(data.reddot)
                end
                --空岛
                local airData = require "data.airisland"
                airData.setCount()

                -- 教程
                local tutorial = require "data.tutorial"
                tutorial.init(data.tutorial, data.tutorial2)
                tutorial.print()
				
                --防沉迷
                if not isChannel() then
                    local preventAddiction = require("data.preventaddiction")
                    if data.identity then
                        preventAddiction.init(data.identity.online_time, data.identity.adult)
                    else
                        preventAddiction.init(0,0)
                    end
                end

                layer.sync2()
            end
        end)
        -- sync超时处理
        schedule(layer, NET_TIMEOUT, function()
            if not isDone then
                isDone = true
                ui.popErrorDialog(i18n.global.sync_data_fail.string .. ": timeout")
            end
        end)
    end
	
	function layer.sync2()
        layer.setHint(i18n.global.sync_data.string)
        local isDone = false
        local sync_param = {
            sid = sid + 0x100,
        }
        net:achieve(sync_param, function(data)
            if not isDone then
                isDone = true
                
				local loadout = require "ui.loadout.data"
				loadout.init(data.id, data.num)
				
                -- 加载游戏资源
                layer.loadUI()
            end
        end)
        -- sync超时处理
        schedule(layer, NET_TIMEOUT, function()
            if not isDone then
                isDone = true
                ui.popErrorDialog(i18n.global.sync_data_fail.string .. ": timeout")
            end
        end)
    end

    -- 加载ui资源
    function layer.loadUI()
        layer.setHint(i18n.global.load_resource.string)
        local beginTime = os.time()
        -- 获得资源列表
        local imgList, jsonList = img.getLoadListForUI(), json.getLoadListForUI()
        local sum, num = #imgList, 0
        img.loadAsync(imgList, function()
            num = num + 1
            if layer.setPercentageForProgress then
                layer.setPercentageForProgress(num/sum*100)
            end
            -- 图片加载完了，开始加载json
            if num == sum and not tolua.isnull(layer) then
                schedule(layer, function()
                    json.loadAll(jsonList)
                    json.initUnits(img.initUnits())
                    -- 至少在loading界面停留1.5s
                    local delay = 0.01
                    local endTime = os.time()
                    if endTime - beginTime < 1.5 then
                        delay = 1.5 - (endTime - beginTime)
                    end
                    schedule(layer, delay, function()
                        -- go to town
                        replaceScene(require("ui.town.main").create())
                        -- background music
                        audio.playBackgroundMusic(audio.ui_bg)
                        -- unload 
                        --img.unloadAll()
                        --json.unloadAll()
                    end)
                end)
            end
            --CCTextureCache:sharedTextureCache():dumpCachedTextureInfo()
        end)
    end

    return layer
end

-- 弹出错误对话框
function ui.popErrorDialog(text)
    popReconnectDialog(text, function()
        replaceScene(require("ui.login.update").create())
    end)
end

return ui
