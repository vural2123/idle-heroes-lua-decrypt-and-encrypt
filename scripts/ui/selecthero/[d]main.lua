
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
local hookdata = require "data.hook"
local trialdata = require "data.trial"
local arenaData = require "data.arena"
local arenabData = require "data.arenab"
local achieveData = require "data.achieve"
local petBattle = require "ui.pet.petBattle"
local arenacData = require "data.arenac"
local loadoutData = require "ui.loadout.data"
local cui = require "ui.custom"
local ccamp = require "fight.helper.ccamp"

-- 0 is normal
-- 1 is PveRaid battle select
local LAST_TYPE = 0
local LOADOUT = 0

local function getHero(hid)
	if hid and hid > 0 then
		if LAST_TYPE == 1 then
			return arenacData.getHero(hid)
		else
			return heros.find(hid)
		end
	end
end
	
local function getHeroes()
	if LAST_TYPE == 1 then
		return arenacData.getHeroes()
	else
		return heros
	end
end

local function getCampHids(params, isInit)
    tbl2string(params)
    local hids = {}
	local ldid = 0
    if params.type == "pve" then
        hids = userdata.getSquadNormal()
		ldid = loadoutData.getSquad("Normal")
    elseif params.type == "trial" then
        hids = userdata.getSquadTrial()
		ldid = loadoutData.getSquad("Trial")
    elseif params.type == "ArenaAtk" then
        hids = userdata.getSquadArenaatk()
		ldid = loadoutData.getSquad("Arenaatk")
    elseif params.type == "ArenaDef" then
        hids = userdata.getSquadArenadef()
		ldid = loadoutData.getSquad("Arenadef")
	elseif params.type == "ArenabAtk" then
        hids = userdata.getSquadArenabatk()
		ldid = loadoutData.getSquad("Arenabatk")
    elseif params.type == "ArenabDef" then
        hids = userdata.getSquadArenabdef()
		ldid = loadoutData.getSquad("Arenabdef")
    elseif params.type == "FrdArena" then
        hids = userdata.getSquadFrdArena()
		ldid = loadoutData.getSquad("FrdArena")
    elseif params.type == "guildVice" then
        hids = userdata.getSquadGuildBoss()
		ldid = loadoutData.getSquad("GuildBoss")
    elseif params.type == "guildGray" then
        hids = userdata.getSquadGuildGray()
		ldid = loadoutData.getSquad("GuildGray")
    elseif params.type == "challenge" then
        hids = userdata.getSquadDailyFight()
		ldid = loadoutData.getSquad("DailyFight")
    elseif params.type == "airisland" then
        hids = userdata.getSquadAirisland()
		ldid = loadoutData.getSquad("Airisland")
    elseif params.type == "friend" then
        hids = userdata.getSquadFriend()
		ldid = loadoutData.getSquad("Friend")
    elseif params.type == "guildmill" then
        hids = userdata.getSquadguildmilldef()
		ldid = loadoutData.getSquad("guildmilldef")
    elseif params.type == "guildmillharry" then
        hids = userdata.getSquadguildmill()
		ldid = loadoutData.getSquad("guildmill")
    elseif params.type == "guildFight" then
        hids = userdata.getGuildFight()
		ldid = loadoutData.getSquad("_GuildFight")
    elseif params.type == "frdpk" then
        hids = userdata.getSquadFrdpk()
		ldid = loadoutData.getSquad("Frdpk")
    elseif params.type == "brokenboss" then
        hids = userdata.getSquadBrokenboss()
		ldid = loadoutData.getSquad("Brokenboss")
    elseif params.type == "sweepforbrokenboss" then
        hids = userdata.getSquadSweepforbrokenboss()
		ldid = loadoutData.getSquad("Sweepforbrokenboss")
    elseif params.type == "sweepforairisland" then
        hids = userdata.getSquadSweepforairisland()
		ldid = loadoutData.getSquad("Sweepforairisland")
    elseif params.type == "sweepforcomisland" then
        hids = userdata.getSquadSweepforcomisland()
		ldid = loadoutData.getSquad("Sweepforcomisland")
    elseif params.type == "sweepforfboss" then
        hids = userdata.getSquadSweepforfboss()
		ldid = loadoutData.getSquad("Sweepforfboss")
    end
	if isInit and ldid and ldid > 0 then
		local lderror = loadoutData.checkValid(ldid)
		if lderror and lderror == 0 then
			LOADOUT = ldid
		end
	end
    return hids
end

local function initHerolistData(params)
    local params = params or {}
	local tmpheros = clone(getHeroes())
	
    local herolist = {}
    for i, v in ipairs(tmpheros) do
        if params.group then
            if cfghero[v.id].group == params.group then
                herolist[#herolist + 1] = v
            else
                for j=1, 6  do
                    if params.hids[j] == v.hid then
                        herolist[#herolist + 1] = v
                    end
                end
            end
        else
            herolist[#herolist + 1] = v
        end
    end

    for i, v in ipairs(herolist) do
        v.isUsed = false
    end

    table.sort(herolist, compareHero)

    local whitelist = getCampHids(params)
    whitelist = arraymerge(whitelist, params.hids)
    local tlist = herolistless(herolist, whitelist)
    return tlist
end

local function onHadleBattle(content)
    print(content.type)
    if #content.hids <= 0 then
        showToast(i18n.global.toast_selhero_needhero.string)
        return
    end
    print("统一加入宠物数据")
	local ov_petId = nil
	local ld = nil
	if LOADOUT > 0 then
		ld = loadoutData.get(LOADOUT)
		ov_petId = ld.petID
		if not ov_petId or ov_petId < 0 then ov_petId = 0 end
	end
    petBattle.addPetData(content.hids, ov_petId)
    print("统一加入宠物数据")
	
	if LOADOUT > 0 then
		if content.hids and #content.hids > 0 then
			content.hids[1].star = 0x100 + LOADOUT
		end
	end

    if content.type == "trial" then
        local params = {
            sid = player.sid,
            camp = content.hids,
        }
		
		if content.isBatch then
			params.sid = params.sid + 0x100
		end
      
        if trialdata.tl <= 0 then
            showToast(i18n.global.trial_need_tl.string)
            return
        end
    
        addWaitNet()
        net:trial_fight(params, function(__data)
            delWaitNet()
            tbl2string(__data)

            if __data.status < 0 then
                showToast("status:" .. __data.status)
                return 
            end
			
			if content.isBatch then
				local winCount = bit.brshift(__data.status, 4)
				local loseCount = bit.band(__data.status, 0xf)
				
				local cfgwavetrial = require("config.wavetrial")
				
				local fullReward = { equips = {}, items = {} }
				local function addRew(rtype, rid, rnum)
					local lsbag = nil
					if rtype == 1 then
						lsbag = fullReward.items
					elseif rtype == 2 then
						lsbag = fullReward.equips
					end
					if lsbag then
						for _, v in ipairs(lsbag) do
							if v.id == rid then
								v.num = v.num + rnum
								return
							end
						end
						lsbag[#lsbag + 1] = { id = rid, num = rnum }
					end
				end
				for i=1, winCount do
					local wave = cfgwavetrial[trialdata.stage]
					if wave and wave.reward then
						for _, v in ipairs(wave.reward) do
							addRew(v.type, v.id, v.num)
						end
					end
					trialdata.win()
				end
				bag.addRewards(fullReward)
				
				for i=1, loseCount do
					trialdata.lose()
				end
				
				replaceScene(require("ui.trial.main").create(fullReward))
				return
			end

            local video = __data.video
            video.stage = trialdata.stage
            if video.win == true then
                trialdata.win()
                bag.addRewards(video.reward)
                require("data.appsflyer").setAchieve(6001, video.stage)
            else
                trialdata.lose()
            end

            ccamp.processCamp(video)

            replaceScene(require("fight.trial.loading").create(video))
        end)
    elseif content.type == "ArenaDef" then
        local params = {
            sid = player.sid,
            id = 1,
            camp = content.hids,
        }

        addWaitNet()
        net:pvp_camp(params, function(__data)
            delWaitNet()
            
            if __data.status >= 0 then
                addWaitNet() 
                net:joinpvp_sync(params, function(__data)
                    delWaitNet()

                    if __data.status == -1 then
                        layer:addChild(require("ui.selecthero.main").create({ type = "ArenaDef" }), 10000)  
                    elseif __data.status == -2 then
                        showToast(i18n.global.event_processing.string)
                    else
                        local arenaData = require "data.arena"
                        arenaData.init(__data)
                        replaceScene(require("ui.arena.main").create())
                    end
                end)
            end
        end)
    elseif content.type == "pve" then
        local params = {
            sid = player.sid,
            camp = content.hids,
        }
		
		if content.isBatch then
			params.sid = params.sid + 0x100
		end

        tbl2string(params)
        addWaitNet()
        net:pve(params, function(__data)
            --tablePrint(__data)
            delWaitNet()
    
            tbl2string(__data)
            if __data.status < 0 then
                showToast("status:" .. __data.status)
                return 
            end
			
			local preLv = player.lv()
			local rewards = nil
			if __data.video then
				rewards = __data.video.reward
			end
            bag.addRewards(rewards)
            local curLv = player.lv()
			
			if content.isBatch then
				local winCount = bit.brshift(__data.status, 16)
				local advCount = bit.band(__data.status, 0xFFFF)
				for i=1, winCount do
					hookdata.pveWin(winCount)
				end
				hookdata.hook_stage = hookdata.hook_stage + advCount
				local video = { reward = rewards, preLv = preLv, curLv = curLv, isBatch = true }
				if __data.status > 0 then
					CCDirector:sharedDirector():getRunningScene():addChild(require("fight.pve.win").create(video), 1000)
				else
					CCDirector:sharedDirector():getRunningScene():addChild(require("fight.pve.lose").create(video), 1000)
				end
				return
			else
				require("data.tutorial").goNext("hook", 2, true) 

				local video = __data.video
				video.stage = hookdata.getPveStageId()
				video.preLv = preLv
				video.curLv = curLv

				if video.win then
					hookdata.pveWin()
				end
				
				ccamp.processCamp(video)
			
				replaceScene(require("fight.pve.loading").create(video))
			end
        end)
    elseif content.type == "airisland" then
        local airData = require "data.airisland" 
        if airData.data.vit.vit <= 0 then
            showToast(i18n.global.airisland_toast_noflr.string)
            return
        end
        local params = {
            sid = player.sid,
            camp = content.hids,
            pos = content.pos,
        }
        if content.cdk then
            params.cdk = content.cdk
        end
        tbl2string(params)
        addWaitNet()
        net:island_fight(params, function(__data)
            delWaitNet()

            tbl2string(__data)
            if __data.status == -5 then
                showToast(i18n.global.floatland_toast_overtime.string)
                return
            end
            if __data.status == -3 then
                showToast(i18n.global.airisland_toast_noflr.string)
                return
            end
            if __data.status ~= 0 then
                showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                return
            end

            local video = clone(__data)
            bag.addRewards(video.reward)
            video.uid = content.uid
            video.stage = content.stage
            video.curparams = params
            airData.changeVit(-1)
            if __data.win then
                --if pUid == player.uid then
                --    friendboss.upscd()
                --else
                --    friend.changebossst(pUid, false)
                --end
            end

			ccamp.processCamp(video)
            
            replaceScene(require("fight.airisland.loading").create(video))
        end)
    elseif content.type == "friend" then
        local friendboss = require "data.friendboss"
        if friendboss.enegy <= 0 then
            showToast(i18n.global.friendboss_no_enegy.string)
            return 
        end

        local params = {
            sid = player.sid,
            camp = content.hids,
            uid = content.uid,
        }
        tbl2string(params)
        addWaitNet()
        net:frd_boss_fight(params, function(__data)
            delWaitNet()

            tbl2string(__data)
            local friend = require "data.friend"
            if __data.status == -1 then
                showToast(i18n.global.friendboss_no_enegy.string)
                return
            elseif __data.status == -5 then
                showToast(i18n.global.event_processing.string)
                return
            end
            if __data.status == -3 then
                showToast(i18n.global.friendboss_boss_die.string)
                if pUid == player.uid then
                    friendboss.upscd()
                else
                    friend.changebossst(pUid, false)
                end
                return
            end
            if __data.status < 0 then
                showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                return
            end
			if __data.status > 0 then
				friend.bossdead(pUid)
			end

            local video = clone(__data)
            if video.rewards and video.select then
                bag.addRewards(video.rewards[video.select])
            end
            video.uid = content.uid
            video.stage = content.stage
            video.curparams = params
            friendboss.delEnegy(1)
            if __data.win then
                if pUid == player.uid then
                    friendboss.upscd()
                else
                    friend.changebossst(pUid, false)
                end
            end

            ccamp.processCamp(video)

            friendboss.video = clone(video)
            replaceScene(require("fight.frdboss.loading").create(video))
        end)
    elseif content.type == "guildmill" then
        local params = {
            sid = player.sid,
            camp = content.hids,
            --uid = content.uid,
        }
        addWaitNet()
        net:gmill_start(params, function(__data)
            delWaitNet()
            tbl2string(__data)
            if __data.status ~= 0 then
                showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                return
            end
            content.callBack()
        end)
    elseif content.type == "guildmillharry" then
        local params = {
            sid = player.sid,
            camp = content.hids,
            --uid = content.uid,
        }
        addWaitNet()
        net:gmill_fight(params, function(__data)
            delWaitNet()
            tbl2string(__data)
            if __data.status ~= 0 then
                showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                return
            end

            local video = clone(__data)
            local video = __data.video
            video.atk = {} 
            video.atk.name = player.name
            video.atk.lv = player.lv()
            video.atk.logo = player.logo
            
            if video.rewards then
                bag.addRewards(video.rewards[1])
            end

            if video.win then
                -- 好战者活动
                local activityData = require "data.activity"
                activityData.addScore(activityData.IDS.SCORE_FIGHT.ID, 1)
            end

            video.from_layer = {
                from_layer = "gmill"
            }
			
			ccamp.processCamp(video)

            replaceScene(require("fight.pvpgmill.loading").create(video))
        end)
    elseif content.type == "guildGray" then
        local params = {
            sid = player.sid,
            camp = content.hids,
            --uid = player.uid,
            --id = content.id,
        }

        tbl2string(params)
        addWaitNet()
        net:gfire_fight(params, function(__data)
            delWaitNet()
            
            if __data.status < 0 then
                --if __data.status == -1 then
                --    showToast(i18n.global.gboss_fight_st1.string)
                if __data.status == -2 then
                    showToast(i18n.global.gboss_fight_st5.string)
                elseif __data.status == -3 then
                    showToast(i18n.global.gboss_fight_st3.string)
                elseif __data.status == -4 then
                    showToast(i18n.global.gboss_fight_st4.string)
				elseif __data.status == -5 then
                    showToast(i18n.global.guildfire_changed.string)
                --elseif __data.status == -5 then
                --    showToast(i18n.global.gboss_fight_st5.string)
                --elseif __data.status == -6 then
                --    showToast(i18n.global.gboss_fight_st6.string)
                else 
                    showToast("status:" .. __data.status)
                end
                return 
            end

            local video = __data
            video.boss = content.id
            tbl2string(__data)
 
            ccamp.processCamp(video)

            --require("data.gboss").addBossExp(params.id)
            --require("data.guild").addExp(__data.exp or 0)
            --require("data.bag").subGem(content.gems)
            --require("data.gboss").addPlainReward(params.id)
            local cfgguildfire = require "config.guildfire"
            bag.addRewards(reward2Pbbag(cfgguildfire[content.id].reward))
            replaceScene(require("fight.grayboss.loading").create(video))
        end)
    elseif content.type == "guildVice" then
        local params = {
            sid = player.sid,
            camp = content.hids,
            uid = player.uid,
            id = content.id,
        }

        tbl2string(params)
        addWaitNet()
        net:gboss_fight(params, function(__data)
            delWaitNet()
            
            if __data.status < 0 then
                if __data.status == -1 then
                    showToast(i18n.global.gboss_fight_st1.string)
                elseif __data.status == -2 then
                    showToast(i18n.global.gboss_fight_st2.string)
                elseif __data.status == -3 then
                    showToast(i18n.global.gboss_fight_st3.string)
                elseif __data.status == -5 then
                    showToast(i18n.global.gboss_fight_st5.string)
                elseif __data.status == -6 then
                    showToast(i18n.global.gboss_fight_st6.string)
                else 
                    showToast("status:" .. __data.status)
                end
                return 
            end

            local video = __data
            video.boss = params.id
            tbl2string(__data)
 
            ccamp.processCamp(video)

            --require("data.gboss").addBossExp(params.id)
            require("data.guild").addExp(__data.exp or 0)
            require("data.bag").subGem(content.gems)
            require("data.gboss").addPlainReward(params.id)
            replaceScene(require("fight.gboss.loading").create(video))
        end)
    elseif content.type == "challenge" then
        local params = {
            sid = player.sid + 0x100,
            camp = content.hids,
            id = content.data.id,
            type = content.data.type,
        }

        tbl2string(params)
        addWaitNet()
        net:dare_fight(params, function(__data)
            delWaitNet()
           
            tbl2string(__data)
            if __data.status < 0 then
                showToast("status:" .. __data.status)
                return 
            end
			
			local winTimes = __data.status
			local dareData = require("data.dare")
			local dailytask = require "data.task"
			local darestage = require "config.darestage"
			local stages = __data.hskills or {}
			for i=1,winTimes do
				dareData.win(params.type)
				dailytask.increment(dailytask.TaskType.CHALLENGE, 1)
                local rewards = darestage[stages[i]].reward
                for i, v in ipairs(rewards) do
                    if v.type == 1 then
                        bag.items.add(v)
                    else
                        bag.equips.add(v)
                    end
                end
			end
			
			local video = { status = __data.status, stages = stages, type = params.type }

			if __data.status > 0 then
				CCDirector:sharedDirector():getRunningScene():addChild(require("fight.dare.win").create(video), 1000)
			else
				CCDirector:sharedDirector():getRunningScene():addChild(require("fight.dare.lose").create(video), 1000)
			end
        end)
    elseif content.type == "ArenaAtk" then
        local params = {
            sid = player.sid,
            camp = content.hids,
            uid = content.info.uid,
            id = 1,
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

            local arenaData = require "data.arena"
            local video = __data.video
            video.atk.name = player.name
            video.atk.lv = player.lv()
            video.atk.logo = player.logo
            video.atk.score = arenaData.score

            arenaData.update(video.ascore)
           
            local tmp = video.def.camp
            video.def = {}
            video.def = clone(content.info)
            video.def.camp = tmp

			ccamp.processCamp(video, nil, 2)
            
            if video.rewards and video.select then
                bag.addRewards(video.rewards[video.select])
            end
            arenaData.fight = arenaData.fight + 1
            bag.items.sub({ id = ITEM_ID_ARENA, num = content.cost})
            tbl2string(video)
            local achieveData = require "data.achieve"
            local activityData = require "data.activity"
            if video.win then
                achieveData.add(ACHIEVE_TYPE_ARENA_ATTACK, 1)
                -- 好战者活动
                activityData.addScore(activityData.IDS.SCORE_FIGHT.ID, 2)
            else
                activityData.addScore(activityData.IDS.SCORE_FIGHT.ID, 1)
            end

            local dailytask = require "data.task"
            dailytask.increment(dailytask.TaskType.ARENA, 1)
            video.from_layer = "task"

            if arenaSkip() == "enable" then
                if video.win then
                    CCDirector:sharedDirector():getRunningScene():addChild(require("fight.pvp.win").create(__data.video), 1000)
                else
                    CCDirector:sharedDirector():getRunningScene():addChild(require("fight.pvp.lose").create(__data.video), 1000)
                end
            else
                replaceScene(require("fight.pvp.loading").create(__data.video))
            end
        end)
	elseif content.type == "ArenabAtk" then
        local params = {
            sid = player.sid,
            camp = content.hids,
            uid = content.info.uid,
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
            video.atk.score = arenabData.score

            arenabData.update(video.ascore)
           
            local tmp = video.def.camp
            video.def = {}
            video.def = clone(content.info)
            video.def.camp = tmp

			ccamp.processCamp(video, nil, 2)
            
            if video.rewards and video.select then
                bag.addRewards(video.rewards[video.select])
            end
			if not video.win then
				arenabData.fight = arenabData.fight + 1
			end
			if content.cost and content.cost > 0 then
				bag.items.sub({ id = ITEM_ID_ARENA, num = content.cost})
			end
            tbl2string(video)

            video.from_layer = "task"

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
	elseif content.type == "ArenabDef" then
        local params = {
            sid = player.sid,
            id = 5,
            camp = content.hids,
        }

        addWaitNet()
        net:pvp_camp(params, function(__datap)
            delWaitNet()
            
            if __datap.status >= 0 then
				local ticketCost = 20
				local cfgarena = require "config.arena"
				if cfgarena[5].cost and #cfgarena[5].cost > 0 then
					ticketCost = cfgarena[5].cost[1]
				end
				bag.items.sub({ id = ITEM_ID_ARENA, num = ticketCost })
				addWaitNet()
                net:joinpvp_sync({ sid = player.sid + 0x200 }, function(__data)
                    delWaitNet()

                    if __data.status == -1 then
                        layer:addChild(require("ui.selecthero.main").create({ type = "ArenabDef" }), 10000)
                    elseif __data.status == -2 then
                        showToast(i18n.global.event_processing.string)
                    elseif __data.status >= 0 then
                        arenabData.init(__data)
						player.iron = os.time() + __datap.status
                        replaceScene(require("ui.arenab.main").create())
                    end
                end)
            end
        end)
    elseif content.type == "guildFight" then
        local params = {
            sid = player.sid,
            camp = content.hids,
        }
         addWaitNet()
         net:guild_fight_camp(params, function(__data)
             delWaitNet()
             tbl2string(__data)
            
             if __data.status ~= 0 then
                if __data.status == -4 then
                    showToast(i18n.global.guiidFight_toast_reg_end.string)
                elseif __data.status == -3 then
                    showToast(i18n.global.guiidFight_toast_is_out.string)
                elseif __data.status == -5 then
                    showToast(i18n.global.guildFight_settingteam_st5.string)
                elseif __data.status == -6 then
                    showToast(i18n.global.gfight_limitsetcamp.string)
                else
                    showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                end
                 
                return
             end
             if not tolua.isnull(content.layer) then
                 content.layer:removeFromParent()
             end

             content.callBack(content.hids)
         end)
    elseif content.type == "frdpk" then
        local params = {
            sid = player.sid,
            camp = content.hids,
            uid = content.info.uid,
        }

        addWaitNet()
        net:frd_pk(params, function(__data)
            tbl2string(__data)
            delWaitNet()

            if __data.status == -1 then
                showToast(i18n.global.toast_arena_nocamp.string)
                return
            end
            if __data.status < 0 then
                showToast("status:" .. __data.status)
                return 
            end

            local video = __data.video
            video.atk.name = player.name
            video.atk.lv = player.lv()
            video.atk.logo = player.logo
           
            local tmp = video.def.camp
            video.def = {}
            video.def = clone(content.info)
            video.def.camp = tmp

			ccamp.processCamp(video, nil, 2)
            
            video.from_layer = {
                from_layer = "frdpk"
            }
			if content.from_layer then
				video.from_layer.from_layer = content.from_layer
			end

            video.curparams = params
            video.info = content.info
            replaceScene(require("fight.frdpk.loading").create(video))
        end)
    elseif content.type == "brokenboss" then
        local tick_num = 0
        if bag.items.find(ITEM_ID_BROKEN) then
            tick_num = bag.items.find(ITEM_ID_BROKEN).num
        end
        if tick_num <= 0 then
            showToast(i18n.global.tips_act_ticket_lack.string)
            return 
        end

        local params = {
            sid = player.sid,
            camp = content.hids,
            id = content.stage,
        }
        tbl2string(params)
        addWaitNet()
        net:bboss_fight(params, function(__data)
            delWaitNet()

            tbl2string(__data)
            if __data.status == -2 then
                showToast(i18n.global.friendboss_boss_die.string)
            end
            if __data.status ~= 0 then
                showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                return
            end

            local video = clone(__data)
            if video.rewards and video.select then
                bag.addRewards(video.rewards[video.select])
            end
            video.uid = content.uid
            video.stage = content.stage
            bag.items.sub({id = ITEM_ID_BROKEN, num = 1})
            ccamp.processCamp(video)

            replaceScene(require("fight.broken.loading").create(video))
        end)
    elseif content.type == "sweepforbrokenboss" then
        local params = {
            sid = player.sid,
            camp = content.hids,
            id = content.stage,
            num = content.num,
        }
        tbl2string(params)
        addWaitNet()
        net:bboss_batch(params, function(__data)
            delWaitNet()
            tbl2string(__data)
            --if __data.status == -2 then
            --    showToast(i18n.global.friendboss_boss_die.string)
            --end
            if __data.status ~= 0 then
                showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                return
            end
            bag.items.sub({id = ITEM_ID_BROKEN, num = __data.num})
            bag.addRewards(__data.reward)
            content.callback(__data.reward, __data.num)
        end)
    elseif content.type == "sweepforfboss" then
        local params = {
            sid = player.sid,
            camp = content.hids,
            uid = content.uid,
            num = content.num,
        }
        addWaitNet()
        net:fboss_batch(params, function(__data)
            delWaitNet()
            tbl2string(__data)
            if __data.status == -3 then
                showToast(i18n.global.friendboss_boss_die.string)
                return 
            end
            if __data.status < 0 then
                showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                return
            end
			if __data.status > 0 then
				local frienddata = require "data.friend"
				frienddata.bossdead(content.uid)
			end
            bag.addRewards(__data.reward)
            content.callback(__data)
            if player.uid == content.uid then
                content.callback2(__data.hpps[1])
            end
            local friendboss = require "data.friendboss"
            friendboss.delEnegy(__data.num)
        end)
    elseif content.type == "sweepforcomisland" then
        local params = {
            sid = player.sid,
            camp = content.hids,
            --pos = content.pos,
            --num = content.num,
        }
        tbl2string(params)
        addWaitNet()
        net:island_sweep(params, function(__data)
            delWaitNet()
            tbl2string(__data)
            if __data.status == -3 then
                showToast(i18n.global.island_nosweepisland.string)
                return
            end
            if __data.status == -1 then
                showToast(i18n.global.airisland_toast_noflr.string)
                return
            end
            if __data.status ~= 0 then
                showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                return
            end
            --bag.items.sub({id = ITEM_ID_BROKEN, num = __data.num})
            local airData = require "data.airisland" 
            airData.calVit(__data.num)
            bag.addRewards(__data.reward)
            content.callback(__data.reward, __data.num)
            if __data.poss and #__data.poss > 0 then
                content.callback2(__data.poss)
            end
            --if content.pos ~= 0 then
            --    local flaghp = false
            --    for i = 1,#__data.hpps do
            --        if __data.hpps[i] ~= 0 then
            --            flaghp = true
            --            break
            --        end    
            --    end
            --    if flaghp == false then
            --        content.callback2(content.pos)
            --    end
            --end
        end)
    elseif content.type == "sweepforairisland" then
        local params = {
            sid = player.sid,
            camp = content.hids,
            pos = content.pos,
            num = content.num,
        }
        tbl2string(params)
        addWaitNet()
        net:island_batch(params, function(__data)
            delWaitNet()
            tbl2string(__data)
            --if __data.status == -2 then
            --    showToast(i18n.global.friendboss_boss_die.string)
            --end
            if __data.status ~= 0 then
                showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                return
            end
            --bag.items.sub({id = ITEM_ID_BROKEN, num = __data.num})
            local airData = require "data.airisland" 
            airData.changeVit(-__data.num)
            bag.addRewards(__data.reward)
            content.callback(__data.reward, __data.num)
            if content.pos == 0 and __data.hpps[1] == 0 then
                content.callback2(0)
            end
            if content.pos ~= 0 then
                local flaghp = false
                for i = 1,#__data.hpps do
                    if __data.hpps[i] ~= 0 then
                        flaghp = true
                        break
                    end    
                end
                if flaghp == false then
                    content.callback2(content.pos)
                end
            end
        end)
    elseif content.type == "FrdArena" then
        local params = {
            sid = player.sid,
            camp = content.hids,
        }
        addWaitNet()
        net:gpvp_set_camp(params, function(__data)
            delWaitNet()
            tbl2string(__data)
            if __data.status >= 0 then
                addWaitNet() 
                net:gpvp_sync(params, function(__data)
                    delWaitNet()

                    local frdarena = require "data.frdarena"
                    frdarena.init(__data)
                    replaceScene(require("ui.frdarena.main").create())
                end)
            end
        end)
    elseif content.type == "FrdArenac" then
        local params = {
            sid = player.sid + 0x100,
            camp = content.hids,
        }
        addWaitNet()
        net:gpvp_set_camp(params, function(__data)
            delWaitNet()
            tbl2string(__data)
            if __data.status >= 0 then
                addWaitNet() 
                net:gpvp_sync(params, function(__data)
                    delWaitNet()

                    local frdarena = require "data.arenac"
                    frdarena.init(__data)
                    replaceScene(require("ui.arenac.main").create())
                end)
            end
        end)
    end
end

function ui.create(params)
    local layer = CCLayer:create()
	if params and params.type then
		if params.type == "FrdArenaca" then
			LAST_TYPE = 1
		else
			LAST_TYPE = 0
		end
	end
    
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

    local showPowerBg = img.createUISprite(img.ui.select_hero_power_bg)
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
    showPowerBg:addChild(showPower)

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
    local showHeros = {}
    local hids = {}
    local headIcons = {}
    local herolist = initHerolistData(params)
	local hppBars = {}
	
	local ypos = 74 -- (74 is orig)
    for i=1, 6 do
        baseHeroBg[i] = img.createUI9Sprite(img.ui.herolist_withouthero_bg)
        baseHeroBg[i]:setPreferredSize(CCSize(84, 84))
        baseHeroBg[i]:setPosition(POSX[i], ypos)
        heroCampBg:addChild(baseHeroBg[i])
		
		if LAST_TYPE == 1 then
			local showHpBg = img.createUISprite(img.ui.fight_hp_bg.small)
			showHpBg:setPosition(baseHeroBg[i]:boundingBox():getMidX(), baseHeroBg[i]:boundingBox():getMinY() - 4)
			showHpBg:setScale(0.55)
			heroCampBg:addChild(showHpBg)
			local showHpFgSp = img.createUISprite(img.ui.fight_hp_fg.small)
			local showHpFg = createProgressBar(showHpFgSp)
			showHpFg:setPosition(showHpBg:getContentSize().width/2, showHpBg:getContentSize().height/2)
			showHpFg:setPercentage(0)
			showHpBg:addChild(showHpFg)
			hppBars[i] = showHpFg
		end
    end
	
    local function loadHeroCamps(hids)
        print("打印当前阵容")
        tablePrint(hids)
		
		local petId = nil
		if LOADOUT > 0 then
			local ld = loadoutData.get(LOADOUT)
			petId = ld.petID
			if petId and petId <= 0 then petId = nil end
			local thids = {}
			for tpos, tv in pairs(ld.stand) do
				thids[tpos] = tv.hid
			end
			hids = thids
		else
			petId = petBattle.getNowSele()
		end

        for i=1, 6 do
			local hpp = 0
            if hids[i] and hids[i] > 0 then
				local heroInfo = getHero(hids[i])
				if heroInfo then
					local param = {
						id = heroInfo.id,
						lv = heroInfo.lv,
						showGroup = true,
						showStar = 3,
						wake = heroInfo.wake,
						orangeFx = nil,
						petID = petId,
						hskills = heroInfo.hskills,
					}
					if LAST_TYPE == 0 then
						param.hid = hids[i]
					else
						param.skin = heroInfo.skin
					end
					showHeros[i] = img.createHeroHeadByParam(param)
					showHeros[i]:setScale(84/94)
					showHeros[i]:setPosition(POSX[i], 74)
					heroCampBg:addChild(showHeros[i])
					
					if LAST_TYPE == 1 and heroInfo.hpp then
						hpp = heroInfo.hpp
					end
					if (LAST_TYPE == 1 and hpp == 0) or LOADOUT > 0 then
						setShader(showHeros[i], SHADER_GRAY, true)
					end
				else
					hids[i] = 0
				end
            end
			if LAST_TYPE == 1 then
				hppBars[i]:setPercentage(hpp)
			end
        end
    end

    local btn_skip0 = img.createLogin9Sprite(img.login.button_9_small_gold)
    btn_skip0:setPreferredSize(CCSizeMake(180, 46))
    local skip_bg = img.createUISprite(img.ui.option_bg)
    skip_bg:setPosition(CCPoint(23, 24))
    btn_skip0:addChild(skip_bg)
    local skip_tick = img.createUISprite(img.ui.option_tick)
    skip_tick:setPosition(CCPoint(23, 24))
    btn_skip0:addChild(skip_tick)
    local lbl_skip = lbl.create({font=1, size=18, text=i18n.global.btn_skip_fight.string, color=ccc3(0x73, 0x3b, 0x05), fr={size=14}, ru={size=14}})
    lbl_skip:setPosition(CCPoint(100, 23))
    btn_skip0:addChild(lbl_skip)
    local btn_skip = SpineMenuItem:create(json.ui.button, btn_skip0)
    btn_skip:setPosition(CCPoint(515, 17))
    local btn_skip_menu = CCMenu:createWithItem(btn_skip)
    btn_skip_menu:setPosition(CCPoint(0, 0))
    selectTeamBg:addChild(btn_skip_menu)
    if not params then
        btn_skip:setVisible(false)
    elseif params.type == "ArenaAtk" or params.type == "ArenabAtk" then
        btn_skip:setVisible(true)
    --[[elseif params.type == "challenge" then
        btn_skip:setVisible(true)--]]
    else
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
	
	local btn_loadout0 = img.createLogin9Sprite(img.login.button_9_small_gold)
    btn_loadout0:setPreferredSize(CCSizeMake(180, 46))
    local loadout_bg = img.createUISprite(img.ui.option_bg)
    loadout_bg:setPosition(CCPoint(23, 24))
    btn_loadout0:addChild(loadout_bg)
    local loadout_tick = img.createUISprite(img.ui.option_tick)
    loadout_tick:setPosition(CCPoint(23, 24))
    btn_loadout0:addChild(loadout_tick)
    local lbl_loadout = lbl.createMix({
                font = 1, size = 16, text = i18n.global.none.string,
                color = ccc3(0x73, 0x3b, 0x05), width = 130, align = kCCTextAlignmentLeft
            })
	lbl_loadout:setAnchorPoint(ccp(0, 0.5))
    lbl_loadout:setPosition(CCPoint(46, 23))
    btn_loadout0:addChild(lbl_loadout)
    local btn_loadout = SpineMenuItem:create(json.ui.button, btn_loadout0)
    btn_loadout:setPosition(CCPoint(515 - 200, 17))
    local btn_loadout_menu = CCMenu:createWithItem(btn_loadout)
    btn_loadout_menu:setPosition(CCPoint(0, 0))
    selectTeamBg:addChild(btn_loadout_menu)
    --[[if not params then
        btn_loadout:setVisible(false)
    elseif params.type == "ArenaAtk" then
        btn_loadout:setVisible(true)
    else
        btn_loadout:setVisible(false)
    end--]]

    --宠物界面退出回调
    local function petCallBack()
        for k,v in pairs(showHeros) do
            v:removeFromParent()
        end
        showHeros = {}
        loadHeroCamps(hids)
    end
    --宠物按钮
    local spPet = img.createLogin9Sprite(img.login.button_9_small_purple)
    spPet:setPreferredSize(CCSizeMake(150, 46))
    local spIcon = img.createUISprite(img.ui.pet_leg)
    spPet:addChild(spIcon)
    local btnLal = lbl.createFont1(16, i18n.global.pet_battle_btn_lal.string, ccc3(0x5c, 0x19, 0x8e))
    spPet:addChild(btnLal)

    local btnPet = SpineMenuItem:create(json.ui.button, spPet)
    require("dhcomponents.DroidhangComponents"):mandateNode(btnPet,"yw_petBattle_btnPet")
    require("dhcomponents.DroidhangComponents"):mandateNode(spIcon,"yw_petBattle_spIcon")
    require("dhcomponents.DroidhangComponents"):mandateNode(btnLal,"yw_petBattle_btnLal")

    local menuPet = CCMenu:createWithItem(btnPet)
    menuPet:setPosition(0, 0)
    selectTeamBg:addChild(menuPet,1)
    btnPet:registerScriptTapHandler(function()
        btnPet:setEnabled(false)
        disableObjAWhile(btnPet)
        audio.play(audio.button)
        petBattle.create(layer, petCallBack)
    end)
    
    local herolistBg = img.createUI9Sprite(img.ui.tips_bg)
    herolistBg:setPreferredSize(CCSize(957, 112))
    herolistBg:setScale(view.minScale)
    herolistBg:setAnchorPoint(ccp(0.5, 1))
    herolistBg:setPosition(view.midX, view.minY + 0 * view.minScale)
    layer:addChild(herolistBg)

    SCROLLVIEW_WIDTH = 943 - 150
    SCROLLVIEW_HEIGHT = 112
    SCROLLCONTENT_WIDTH = #herolist * 90 + 8

    local scroll = CCScrollView:create()
    scroll:setDirection(kCCScrollViewDirectionHorizontal)
    scroll:setAnchorPoint(ccp(0, 0))
    scroll:setPosition(7, 0)
    scroll:setViewSize(CCSize(SCROLLVIEW_WIDTH, SCROLLVIEW_HEIGHT))
    scroll:setContentSize(CCSizeMake(SCROLLCONTENT_WIDTH, SCROLLVIEW_HEIGHT))
    herolistBg:addChild(scroll)

    local btnFilterSprite = img.createLogin9Sprite(img.login.button_9_small_gold)
    btnFilterSprite:setPreferredSize(CCSize(130, 70))
    local btnFilterIcon = lbl.createFont1(20, i18n.global.selecthero_btn_hero.string, ccc3(0x73, 0x3b, 0x05)) 
    btnFilterIcon:setPosition(btnFilterSprite:getContentSize().width/2, btnFilterSprite:getContentSize().height/2)
    btnFilterSprite:addChild(btnFilterIcon)

    local btnFilter = SpineMenuItem:create(json.ui.button, btnFilterSprite)
    btnFilter:setPosition(873, 56)
    local menuFilter = CCMenu:createWithItem(btnFilter)
    menuFilter:setPosition(0, 0)
    herolistBg:addChild(menuFilter, 1)
    
    local filterBg = img.createUI9Sprite(img.ui.tips_bg)
    filterBg:setPreferredSize(CCSize(122, 458))
    filterBg:setScale(view.minScale)
    filterBg:setAnchorPoint(ccp(1, 0))
    filterBg:setPosition(scalep(938, 110))
    layer:addChild(filterBg)

    local showHeroLayer = CCLayer:create()
    scroll:getContainer():addChild(showHeroLayer)

    --local iconBgBatch = img.createBatchNodeForUI(img.ui.herolist_head_bg)
    --scroll:getContainer():addChild(iconBgBatch, 1)
    --local groupBgBatch = img.createBatchNodeForUI(img.ui.herolist_group_bg)
    --scroll:getContainer():addChild(groupBgBatch , 3)
    --local starBatch = img.createBatchNodeForUI(img.ui.star_s)
    --scroll:getContainer():addChild(starBatch, 3)
    --blackBatch = CCNode:create()
    --scroll:getContainer():addChild(blackBatch, 4)
    --selectBatch = img.createBatchNodeForUI(img.ui.hook_btn_sel)
    --scroll:getContainer():addChild(selectBatch, 5)
    
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
        local star10Batch = img.createBatchNodeForUI(img.ui.hero_star_ten)
        showHeroLayer:addChild(star10Batch, 3)
        local star1Batch = img.createBatchNodeForUI(img.ui.hero_star_orange)
        showHeroLayer:addChild(star1Batch, 3)
        blackBatch = CCNode:create()
        showHeroLayer:addChild(blackBatch, 5)
        selectBatch = img.createBatchNodeForUI(img.ui.hook_btn_sel)
        showHeroLayer:addChild(selectBatch, 5)

        for i=1, #herolist do
            local x, y = 45 + (i-1) * 90 + 8, 56 
       
            local qlt = cfghero[herolist[i].id].maxStar
            local heroBg = nil
            if qlt == 10 then
                heroBg = img.createUISprite(img.ui.hero_star_ten_bg)
                heroBg:setPosition(x, y)
                heroBg:setScale(0.92)
                iconBgBatch1:addChild(heroBg)
                json.load(json.ui.lv10_framefx)
                --local aniten = DHSkeletonAnimation:createWithKey(json.ui.lv10_framefx)
                --aniten:playAnimation("animation", -1)
                --aniten:scheduleUpdateLua()
                --aniten:setScale(0.92)
                --aniten:setPosition(x, y)
                --showHeroLayer:addChild(aniten, 4)
            else
                heroBg = img.createUISprite(img.ui.herolist_head_bg)
                heroBg:setScale(0.92)
                heroBg:setPosition(x, y)
                iconBgBatch:addChild(heroBg)
            end

            --headIcons[i] = img.createHeroHeadByHid(herolist[i].hid)
			local h = getHero(herolist[i].hid)
			local cparam = {
				id = h.id,
				lv = h.lv,
				showGroup = true,
				showStar = true,
				wake = h.wake,
				hskills = h.hskills,
			}
			if LAST_TYPE == 0 then
				cparam.hid = herolist[i].hid
			else
				cparam.skin = h.skin
			end
			headIcons[i] = img.createHeroHeadByParam(cparam)
            headIcons[i]:setScale(0.92)
            headIcons[i]:setPosition(x, y)
            showHeroLayer:addChild(headIcons[i], 2)
			
			if LAST_TYPE == 1 then
				if not h.hpp or h.hpp <= 0 then
					setShader(headIcons[i], SHADER_GRAY, true)
				end
				local showHpBg = img.createUISprite(img.ui.fight_hp_bg.small)
				showHpBg:setPosition(headIcons[i]:boundingBox():getMidX(), headIcons[i]:boundingBox():getMinY() - 4)
				showHpBg:setScale(0.55)
				showHeroLayer:addChild(showHpBg)
				local showHpFgSp = img.createUISprite(img.ui.fight_hp_fg.small)
				local showHpFg = createProgressBar(showHpFgSp)
				showHpFg:setPosition(showHpBg:getContentSize().width/2, showHpBg:getContentSize().height/2)
				showHpFg:setPercentage(h.hpp or 0)
				showHpBg:addChild(showHpFg)
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
		if LOADOUT == 0 then
			local power = 0
			if LAST_TYPE == 0 then
				for i=1, 6 do
					if hids[i] and hids[i] > 0 then
						power = power + heros.power(hids[i])
					end
				end
			else
				for i=1, 6 do
					if hids[i] and hids[i] > 0 then
						local h = getHero(hids[i])
						if h and h.power then
							power = power + h.power
						end
					end
				end
			end

			showPower:setString(power)
			
			for i=1, 6 do 
				heroids[i] = nil
				local h = getHero(hids[i])
				if h then
					heroids[i] = h.id
				end
			end
		else
			local ld = loadoutData.get(LOADOUT)
			local power = 0
			if LAST_TYPE == 0 then
				for i=1, 6 do
					if ld.stand[i] then
						power = power + heros.power(ld.stand[i].hid, ld)
					end
				end
			else
				for i=1, 6 do
					if ld.stand[i] then
						local h = getHero(ld.stand[i].hid)
						if h and h.power then
							power = power + h.power
						end
					end
				end
			end

			showPower:setString(power)
			
			for i=1, 6 do 
				heroids[i] = nil
				if ld.stand[i] then
					local h = getHero(ld.stand[i].hid)
					if h then
						heroids[i] = h.id
					end
				end
			end
		end
		
		local showIcon = require("ui.selecthero.campLayer").checkUpdateForHeroids(heroids,true)

		if showIcon ~= -1 then
			campWidget.icon[showIcon]:setVisible(true)
		end
    end
	
	local function updateloadout(isCallback)
        if LOADOUT > 0 then
            loadout_tick:setVisible(true)
			cui.setButtonEnabled(btnPet, false)
			herolistBg:setVisible(false)
			filterBg:setVisible(false)
			lbl_loadout:setString(string.format(i18n.global.loadout_name.string, LOADOUT))
        else
            loadout_tick:setVisible(false)
			cui.setButtonEnabled(btnPet, true)
			herolistBg:setVisible(true)
			lbl_loadout:setString(i18n.global.none.string)
        end
		if isCallback then
			checkUpdate()
		end
    end
    
	local function loadoutcallback(thisIdx)
		LOADOUT = thisIdx
		updateloadout(true)
		for k,v in pairs(showHeros) do
            v:removeFromParent()
        end
        showHeros = {}
		loadHeroCamps(hids)
	end
    btn_loadout:registerScriptTapHandler(function()
        audio.play(audio.button)
		layer:addChild(require("ui.loadout.main").create(LOADOUT, loadoutcallback), 1000)
    end)

    local function onMoveUp(pos, tpos, isNotCallBack)
        checkUpdate()
        if not isNotCallBack then
            local heroInfo = getHero(hids[tpos])
            local param = {
                id = heroInfo.id,
                lv = heroInfo.lv,
                showGroup = true,
                showStar = 3,
                wake = heroInfo.wake,
                orangeFx = nil,
                petID = petBattle.getNowSele(),
                hskills = heroInfo.hskills,
            }
			if LAST_TYPE == 0 then
				param.hid = heroInfo.hid
			else
				param.skin = heroInfo.skin
			end
            showHeros[tpos] = img.createHeroHeadByParam(param)
            showHeros[tpos]:setScale(86/94)
            showHeros[tpos]:setPosition(POSX[tpos], 74)
            heroCampBg:addChild(showHeros[tpos])
			
			if LAST_TYPE == 1 then
				if not heroInfo.hpp or heroInfo.hpp <= 0 then
					setShader(showHeros[tpos], SHADER_GRAY, true)
				end
				hppBars[tpos]:setPercentage(heroInfo.hpp or 0)
			end
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
		if LOADOUT > 0 then return end
        local tpos
        for i=1, 6 do
            if not hids[i] or hids[i] == 0 then
                tpos = i
                break
            end
        end
		
		if LAST_TYPE == 1 and tpos then
			if not herolist[pos].hpp or herolist[pos].hpp <= 0 then
				return
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
                --lv = herolist[pos].lv,
                --showGroup = true,
                --showStar = nil,
                --wake = nil,
                --orangeFx = nil,
                --petID = petBattle.getNowSele(),
                --hid = herolist[pos].hid
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
        blackBatch:removeChildByTag(tpos)
        selectBatch:removeChildByTag(tpos)
    end

    local function moveDown(pos)
		if LOADOUT > 0 then return end
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
			
			if LAST_TYPE == 1 then
				hppBars[pos]:setPercentage(0)
			end
            
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
                --petID = petBattle.getNowSele(),
                --hid = herolist[tpos].hid
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
        
		if LOADOUT == 0 then
			for i=1, 6 do
				if hids[i] and showHeros[i] and showHeros[i]:boundingBox():containsPoint(point) then
					preSelect = i
				end
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
        if not scroll or tolua.isnull(scroll) then
            return
        end
		if LOADOUT > 0 then return end

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
                if math.abs(showHeros[preSelect]:getPositionX() - baseHeroBg[i]:getPositionX()) < 33
                    and math.abs(showHeros[preSelect]:getPositionY() - baseHeroBg[i]:getPositionY()) < 33 then
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

    layer.showHint = function ()
        if 1 then
            local bubble = img.createUI9Sprite(img.ui.tutorial_bubble)
            local bubbleMinWidth, bubbleMinHeight = 208, 82
            bubble:setScale(view.minScale)
            bubble:setAnchorPoint(ccp(0.5, 0))
            bubble:setPosition(scalep(215, 430))
            layer:addChild(bubble)
            -- text
            local label = lbl.createMix({
                font = 1, size = 16, text = i18n.global.tutorial_text_new_hit_1.string,
                color = ccc3(0x72, 0x48, 0x35), width = 350
            })
            local labelSize = label:boundingBox().size
            label:setAnchorPoint(ccp(0.5, 0.5))
            bubble:addChild(label)
            -- 大小调整
            local bubbleWidth = labelSize.width + 20
            if bubbleWidth < bubbleMinWidth then
                bubbleWidth = bubbleMinWidth
            end
            local bubbleHeight = labelSize.height + 5
            if bubbleHeight < bubbleMinHeight then
                bubbleHeight = bubbleMinHeight
            end
            bubble:setPreferredSize(CCSize(bubbleWidth, bubbleHeight))
            label:setPosition(bubbleWidth / 2, bubbleHeight / 2)

            local bubbleArrow = img.createUISprite(img.ui.tutorial_bubble_arrow)
            bubbleArrow:setRotation(-90)
            bubbleArrow:setPosition(bubbleWidth / 2, -6)
            bubble:addChild(bubbleArrow)

            bubble:setVisible(false)
            bubble:runAction(createSequence({
                CCDelayTime:create(0.4),
                CCShow:create(),
            }))
        end

        if 2 then
            local bubble = img.createUI9Sprite(img.ui.tutorial_bubble)
            local bubbleMinWidth, bubbleMinHeight = 208, 82
            bubble:setScale(view.minScale)
            bubble:setAnchorPoint(ccp(0.5, 1))
            bubble:setPosition(scalep(514, 280))
            layer:addChild(bubble)
            -- text
            local label = lbl.createMix({
                font = 1, size = 16, text = i18n.global.tutorial_text_new_hit_2.string,
                color = ccc3(0x72, 0x48, 0x35), width = 450
            })
            local labelSize = label:boundingBox().size
            label:setAnchorPoint(ccp(0.5, 0.5))
            bubble:addChild(label)
            -- 大小调整
            local bubbleWidth = labelSize.width + 20
            if bubbleWidth < bubbleMinWidth then
                bubbleWidth = bubbleMinWidth
            end
            local bubbleHeight = labelSize.height + 5
            if bubbleHeight < bubbleMinHeight then
                bubbleHeight = bubbleMinHeight
            end
            bubble:setPreferredSize(CCSize(bubbleWidth, bubbleHeight))
            label:setPosition(bubbleWidth / 2, bubbleHeight / 2)

            local bubbleArrow = img.createUISprite(img.ui.tutorial_bubble_arrow)
            bubbleArrow:setRotation(90)
            bubbleArrow:setPosition(bubbleWidth / 2, bubbleHeight + 6)
            bubble:addChild(bubbleArrow)

            bubble:setVisible(false)
            bubble:runAction(createSequence({
                CCDelayTime:create(0.8),
                CCShow:create(),
            }))
        end
    end

    if params.type == "pve" then--新手引导小提示
        local hookdata = require("data.hook")
        local pveStage = hookdata.getPveStageId()
        local stageId = 10
        if pveStage >= 3 and pveStage <= stageId then
            layer.showHint()
        end
    end

    btnBattle:registerScriptTapHandler(function()
        audio.play(audio.fight_start_button)
		if params.type == "pve" then
			loadoutData.setSquad("Normal", LOADOUT)
		elseif params.type == "trial" then
			loadoutData.setSquad("Trial", LOADOUT)
		elseif params.type == "ArenaAtk" then
			loadoutData.setSquad("Arenaatk", LOADOUT)
		elseif params.type == "ArenaDef" then
			loadoutData.setSquad("Arenadef", LOADOUT)
		elseif params.type == "ArenabAtk" then
			loadoutData.setSquad("Arenabatk", LOADOUT)
		elseif params.type == "ArenabDef" then
			loadoutData.setSquad("Arenabdef", LOADOUT)
		elseif params.type == "FrdArena" then
			loadoutData.setSquad("FrdArena", LOADOUT)
		elseif params.type == "guildVice" then
			loadoutData.setSquad("GuildBoss", LOADOUT)
		elseif params.type == "guildGray" then
			loadoutData.setSquad("GuildGray", LOADOUT)
		elseif params.type == "challenge" then
			loadoutData.setSquad("DailyFight", LOADOUT)
		elseif params.type == "airisland" then
			loadoutData.setSquad("Airisland", LOADOUT)
		elseif params.type == "friend" then
			loadoutData.setSquad("Friend", LOADOUT)
		elseif params.type == "guildmill" then
			loadoutData.setSquad("guildmilldef", LOADOUT)
		elseif params.type == "guildmillharry" then
			loadoutData.setSquad("guildmill", LOADOUT)
		elseif params.type == "guildFight" then
			loadoutData.setSquad("_GuildFight", LOADOUT)
		elseif params.type == "frdpk" then
			loadoutData.setSquad("Frdpk", LOADOUT)        
		elseif params.type == "brokenboss" then
			loadoutData.setSquad("Brokenboss", LOADOUT)
		elseif params.type == "sweepforbrokenboss" then
			loadoutData.setSquad("Sweepforbrokenboss", LOADOUT)
		elseif params.type == "sweepforairisland" then
			loadoutData.setSquad("Sweepforairisland", LOADOUT)
		elseif params.type == "sweepforcomisland" then
			loadoutData.setSquad("Sweepforcomisland", LOADOUT)
		elseif params.type == "sweepforfboss" then
			loadoutData.setSquad("Sweepforfboss", LOADOUT)
		end
		if LOADOUT == 0 then
			local cloneHids = clone(hids)
			--特殊加入第7位宠物标记
			cloneHids[7] = petBattle.getNowSele()

			if params.type == "pve" then
				userdata.setSquadNormal(cloneHids) 
			elseif params.type == "trial" then
				userdata.setSquadTrial(cloneHids)        
			elseif params.type == "ArenaAtk" then
				userdata.setSquadArenaatk(cloneHids)        
			elseif params.type == "ArenaDef" then
				userdata.setSquadArenadef(cloneHids)        
			elseif params.type == "ArenabAtk" then
				userdata.setSquadArenabatk(cloneHids)        
			elseif params.type == "ArenabDef" then
				userdata.setSquadArenabdef(cloneHids)        
			elseif params.type == "FrdArena" then
				userdata.setSquadFrdArena(cloneHids)        
			elseif params.type == "guildVice" then
				userdata.setSquadGuildBoss(cloneHids)
			elseif params.type == "guildGray" then
				userdata.setSquadGuildGray(cloneHids)
			elseif params.type == "challenge" then
				userdata.setSquadDailyFight(cloneHids)
			elseif params.type == "airisland" then
				userdata.setSquadAirisland(cloneHids)
			elseif params.type == "friend" then
				userdata.setSquadFriend(cloneHids)
			elseif params.type == "guildmill" then
				userdata.setSquadguildmilldef(cloneHids)
			elseif params.type == "guildmillharry" then
				userdata.setSquadguildmill(cloneHids)
			elseif params.type == "guildFight" then
				userdata.setGuildFight(cloneHids)
			elseif params.type == "frdpk" then
				userdata.setSquadFrdpk(cloneHids)        
			elseif params.type == "brokenboss" then
				userdata.setSquadBrokenboss(cloneHids)
			elseif params.type == "sweepforbrokenboss" then
				userdata.setSquadSweepforbrokenboss(cloneHids)
			elseif params.type == "sweepforairisland" then
				userdata.setSquadSweepforairisland(cloneHids)
			elseif params.type == "sweepforcomisland" then
				userdata.setSquadSweepforcomisland(cloneHids)
			elseif params.type == "sweepforfboss" then
				userdata.setSquadSweepforfboss(cloneHids)
			end
			local unit = {}
			for i=1, 6 do
				if hids[i] and hids[i] > 0 then
					unit[#unit + 1] = {
						hid = hids[i],
						pos = i,
					}
					-- 觉醒处理
					local hh = getHero(hids[i])
					if hh and hh.wake then
						unit[#unit].wake = hh.wake
					end
				end
			end
			params.hids = unit
		else
			local unit = {}
			local ld = loadoutData.get(LOADOUT)
			for i=1, 6 do
				if ld.stand[i] then
					unit[#unit + 1] = {
						hid = ld.stand[i].hid,
						pos = i
					}
					local hh = getHero(ld.stand[i].hid)
					if hh and hh.wake then
						unit[#unit].wake = hh.wake
					end
				end
			end
			params.hids = unit
		end
        params.layer = layer
        onHadleBattle(params)
    end)

    local function initLoad()
		LOADOUT = 0
        hids = getCampHids(params, true)
        petBattle.initData(hids)
        print("本次阵容 ---  = "..params.type)
        loadHeroCamps(hids)

        for i,v in ipairs(herolist) do
            for j=1, 6 do
                if v.hid == hids[j] then
                    onMoveUp(i, j, true)
                    herolist[i].isUsed = true
                end
            end
        end
    end
    createHerolist()
    initLoad()
	updateloadout()

    local function onEnter()
    
    end

    local function onExit()

    end

    layer:registerScriptHandler(function(event)
        if event == "enter" then
            onEnter()
        elseif event == "exit" then

        end
    end)
    
    local anim_duration = 0.2
    board:setPosition(CCPoint(view.midX, view.minY+576*view.minScale))
    board:runAction(CCMoveTo:create(anim_duration, CCPoint(view.midX, view.minY+130*view.minScale)))
    herolistBg:runAction(CCMoveTo:create(anim_duration, CCPoint(view.midX, view.minY+123*view.minScale)))
    darkbg:runAction(CCFadeTo:create(anim_duration, POPUP_DARK_OPACITY))

    local group
    local btnGroupList = {}
    for i=1, 6 do
        local btnGroupSpriteFg = img.createUISprite(img.ui["herolist_group_" .. i])
        local btnGroupSpriteBg = img.createUISprite(img.ui.herolist_group_bg)
        btnGroupSpriteFg:setPosition(btnGroupSpriteBg:getContentSize().width/2, btnGroupSpriteBg:getContentSize().height/2 + 2)
        btnGroupSpriteBg:addChild(btnGroupSpriteFg)
        btnGroupList[i] = HHMenuItem:createWithScale(btnGroupSpriteBg, 1)
        local btnGroupMenu = CCMenu:createWithItem(btnGroupList[i])
        btnGroupMenu:setPosition(0, 0)
        filterBg:addChild(btnGroupMenu, 10)
        btnGroupList[i]:setPosition(61, 52 + 70 * (i - 1))
        
        local showSelect = img.createUISprite(img.ui.herolist_select_icon)
        showSelect:setPosition(btnGroupList[i]:getContentSize().width/2, btnGroupList[i]:getContentSize().height/2 + 2)
        btnGroupList[i]:addChild(showSelect)
        btnGroupList[i].showSelect = showSelect
        showSelect:setVisible(false)

        btnGroupList[i]:registerScriptTapHandler(function()
            audio.play(audio.button)
            for j=1, 6 do
                btnGroupList[j]:unselected()
                btnGroupList[j].showSelect:setVisible(false)
            end
            if not group or i ~= group then
                group = i
                btnGroupList[i]:selected()
                btnGroupList[i].showSelect:setVisible(true)
            else
                group = nil
            end

            herolist = initHerolistData({ group = group , hids = hids})
            createHerolist()

            for i,v in ipairs(herolist) do
                for j=1, 6 do
                    if v.hid == hids[j] then
                        onMoveUp(i, j, true)
                        herolist[i].isUsed = true
                    end
                end
            end
        end)
    end

    filterBg:setVisible(false)
    btnFilter:registerScriptTapHandler(function()
        if filterBg:isVisible() == true then
            filterBg:setVisible(false)
        else
            filterBg:setVisible(true)
        end
    end)

    local function tutocallBack()
        local count = 0
        for i,v in ipairs(herolist) do
            for j=1, 6 do
                if v.hid == hids[j] then
                    count = count + 1
                end
            end
        end
        if count == 0 or count == 1 then
            hids = { 2, 1, 0, 0, 0, 0 ,-1}
            userdata.setSquadNormal(hids)
            hids = userdata.getSquadNormal()
            petBattle.initData(hids)
            --print("本次阵容 ---  = "..params.type)
            loadHeroCamps(hids)

            for i,v in ipairs(herolist) do
                for j=1, 6 do
                    if v.hid == hids[j] then
                        onMoveUp(i, j, true)
                        herolist[i].isUsed = true
                    end
                end
            end
        end
    end

    if #herolist > 2 then
        layer.tutocallBack = tutocallBack
    end
    require("ui.tutorial").show("ui.selected.pve", layer)

    return layer
end

return ui
