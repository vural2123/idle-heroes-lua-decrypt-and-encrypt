local solo = {}

local cfghero 	 = require "config.hero"
local cfgMonster = require "config.monster"
local cfgSpk     = require "config.spk"
local cfgSpkWave = require "config.spkwave"
local cfgMonster = require "config.monster"
local cfgDrug    = require "config.spkdrug"
local cfgTrader  = require "config.spktrader"
local heros 	 = require "data.heros"
local userdata   = require "data.userdata"

-- 获取红点状态
function solo.initRedDot(reddot)
	solo.reddot = bit.band(0x02,reddot)
	print("单挑赛红点"..solo.reddot)
end

-- 判断是否显示红点
function solo.showRedDot(reddot)
	if solo.reddot and solo.reddot ~= 0 then
        return true
    end
    return false
end

-- function solo.getAutoState()
-- 	print("自动化判断")
-- 	-- local state = userdata.getString("soloAuto","0")
-- 	-- print("是否自动战斗"..state)
-- 	-- if state == "0" then
-- 	-- 	solo.setAutoState(false)
-- 	-- elseif state == "1" then
-- 	-- 	solo.setAutoState(true)
-- 	-- end
-- end

function solo.init()
	solo.isPull   	= true 	--是否有同步过单挑赛数据
	solo.status   	= nil 	--单挑赛的状态
	solo.cd       	= nil   --单挑赛的CD(根据状态而定是结束时间还是开始时间)
	solo.estage   	= nil   --单挑赛的波次ID(对应spkwave表)
	solo.wave     	= nil   --单挑赛的波次数值
	solo.buf      	= nil   --单挑赛的buffID(对应spkdrug表)
	solo.trader   	= nil 	--单挑赛的商人ID(对应spktrader表)
	solo.reward   	= nil   --单挑赛的奖励
	solo.select   	= nil   --选择的英雄序列
	solo.heroList 	= {}	--单挑赛当前出战英雄队列的信息
	solo.bossList 	= {}	--单挑赛当前boss队列的信息
	solo.traderList = {}	--单挑赛扫荡的商人列表
	solo.milk     	= {}    --单挑赛牛奶药剂
	solo.angel    	= {}    --单挑赛天使药剂
	solo.evil     	= {}    --单挑赛恶魔药剂
	solo.power    	= 0     --单挑赛力量药剂
	solo.crit     	= 0     --单挑赛暴击药剂
	solo.speed    	= 0     --单挑赛速度药剂(改为暴击伤害)
	solo.level      = 0     --单挑赛难度
	solo.levelStage = 100  	--单挑赛难度梯度
	-- 判断是否为自动状态
	local state = userdata.getString("soloAuto","0")
	if state == "0" then
		solo.setAutoState(false)
	elseif state == "1" then
		solo.setAutoState(true)
	end
end

-- 设置出战英雄
function solo.setBattleList(hids)
	for i,v in ipairs(hids) do
	    local heroInfo = heros.find(v)
	    heroInfo.hp    = 100
        heroInfo.mp    = heroInfo.energy or 0
      	heroInfo.speed = 0
      	heroInfo.power = 0
      	heroInfo.crit  = 0
        heroInfo.group = cfghero[heroInfo.id].group
        heroInfo.qlt   = cfghero[heroInfo.id].qlt
        table.insert(solo.heroList,heroInfo)
	end
end

-- 设置/获取是否有同步过单挑赛的数据
function solo.setIsPull(isPull)
	solo.isPull = isPull
end

function solo.getIsPull()
	return solo.isPull
end

-- 设置单挑赛界面的进入时获取的数据
function solo.setMainData(data)
	solo.mainData   = data
	solo.status     = data.status
	solo.cd 	    = data.cd + os.time()
	solo.estage     = data.estage
	solo.wave 	    = data.wave
	solo.buf        = data.buf
	solo.trader     = data.seller
	solo.traderList = data.sellers or {}
	solo.heroList   = solo.convertHeroInfo(data.camp)
	solo.bossList   = solo.convertBossInfo(data.ehpp)
	-- solo.milk     = solo.getDrugList(data.save,"milk")
	-- solo.angel    = solo.getDrugList(data.save,"angel")
	-- solo.evil     = solo.getDrugList(data.save,"evil")

	data.bufs       = data.bufs or {}
	solo.milk       = solo.getDrugList(data.bufs,"milk")
	solo.angel      = solo.getDrugList(data.bufs,"angel")
	solo.evil       = solo.getDrugList(data.bufs,"evil")
	solo.power      = solo.getDrugNum(data.bufs,"power")
	solo.crit       = solo.getDrugNum(data.bufs,"crit")
	solo.speed      = solo.getDrugNum(data.bufs,"speed")
	solo.level      = solo.wave and math.floor((solo.wave - 1) / solo.levelStage) or 0
	solo.level      = solo.status == 2 and solo.level - 1 or solo.level

	print("aaaaa" .. solo.level)

	for i,v in ipairs(solo.heroList) do
		v.power = solo.power
		v.speed = solo.speed
		v.crit = solo.crit
	end

	if solo.buf then
		solo.wave = solo.wave - 1
	end
	print("设置后的时间为"..solo.cd)
	print("数据打印")
	-- tablePrint(data.save)
	-- tablePrint(solo.milk)
	-- tablePrint(solo.angel)
	-- tablePrint(solo.evil)
end

-- 从商人列表中移除某个商人id
function solo.removeTrader(traderID)
	for i,v in ipairs(solo.traderList) do
		if v == traderID then
			table.remove(solo.traderList,i)
			break
		end
	end
end

-- 添加某个属性buf的数量
function solo.addPotion(id)
	local iconID = cfgDrug[id].iconId
	if iconID == 3801 then
		--力量药剂
		solo.power = solo.power + 1 <= 20 and solo.power + 1 or 20
	elseif iconID == 3701 then
		--暴伤药剂
		solo.speed = solo.speed + 1 <= 20 and solo.speed + 1 or 20
	elseif iconID == 3901 then
		--暴击药剂
		solo.crit = solo.crit + 1 <= 20 and solo.crit + 1 or 20
	end
	for i,v in ipairs(solo.heroList) do
		v.speed = solo.speed
		v.power = solo.power
		v.crit  = solo.crit
		print("---power " .. solo.power)
		print("---speed " .. solo.speed)
		print("---crit " .. solo.crit)
	end
end

-- 获取存活的boss数据
function solo.getAliveBoss()
	local list = {}
	for i,v in ipairs(solo.bossList) do
		if v.hp > 0 then
			table.insert(list,v)	
		end
	end
	return list
end

-- 获取对应恢复药剂的列表
function solo.getDrugList(data,drug)
	local list = {}
	local drugType
	if data then
		for i,v in ipairs(data) do
			if v.num > 0 then
				if cfgDrug[v.id].iconId == 4001 then
					drugType = "milk"
				elseif cfgDrug[v.id].iconId == 4101 then
					drugType = "evil"
				elseif cfgDrug[v.id].iconId == 4201 then
					drugType = "angel"
				end
				if drug == drugType then
					for j=1,v.num do
						table.insert(list,v.id)
					end
				end
			end
		end
	end
	return list
end

-- 获得对应属性药剂的数量
function solo.getDrugNum(data,drug)
	local num = 0
	for i,v in ipairs(data) do
		if cfgDrug[v.id].iconId == 3801 and drug == "power" then
			num = v.num + num
		elseif cfgDrug[v.id].iconId == 3901 and drug == "crit" then
			num = v.num + num
		elseif cfgDrug[v.id].iconId == 3701 and drug == "speed" then
			num = v.num + num
		end
	end
	num = num > 20 and 20 or num
	return num
end

-- 获取难度等级
function solo.getStageLevel()
	local level = 0
	level = solo.wave ~= nil and math.floor((solo.wave - 1) / solo.levelStage) or 0

	return level
end

-- 获取要显示的波次
function solo.getShowWave()
	local wave = 1
	wave = solo.wave ~= nil and (solo.getWave() - 1) % 100 + 1 or 1
	return wave
end

-- 将获取的英雄数据转换成要用到的列表信息
function solo.convertHeroInfo(data)
	if data == nil then
		return {} 
	end
	local infoTable = {}
	for i,v in ipairs(data) do
		infoTable[i] 	   = {}
		infoTable[i].hid   = v.base.hid
		infoTable[i].id    = v.base.id
		infoTable[i].lv    = v.base.lv
		infoTable[i].star  = v.base.star
		infoTable[i].hp    = v.base.hpp or 100
		infoTable[i].mp    = v.base.energy
		infoTable[i].wake  = v.base.wake
		infoTable[i].skin  = v.base.skin
		infoTable[i].group = cfghero[infoTable[i].id].group
        infoTable[i].qlt   = cfghero[infoTable[i].id].qlt
        infoTable[i].speed = solo.speed or 0
        infoTable[i].power = solo.power or 0
        infoTable[i].crit  = solo.crit or 0
        infoTable[i].pos   = 1
        if v.buf then
	        for j,n in ipairs(v.buf) do
	            if cfgDrug[n.id].type == 1 then
	                infoTable[i].power = infoTable[i].power + n.num
	            elseif cfgDrug[n.id].type == 2 then
	                infoTable[i].speed = infoTable[i].speed + n.num
	            elseif cfgDrug[n.id].type == 3 then
	                infoTable[i].crit = infoTable[i].crit + n.num
	            end
			end
        end
	end
	return infoTable
end

-- 将获取的Boss数据转换成要用到的列表信息
function solo.convertBossInfo(data)
	if solo.estage == nil then
		return {}
	end
	local bossArr = cfgSpkWave[solo.estage].trial
	local infoTable = {}
	for i,v in ipairs(bossArr) do
		tablePrint(bossArr)
        infoTable[i]       = {}
        infoTable[i].id    = cfgMonster[v].heroLink
        infoTable[i].lv    = cfgMonster[v].lv
        infoTable[i].star  = cfgMonster[v].star
        infoTable[i].group = cfghero[cfgMonster[v].heroLink].group
        infoTable[i].qlt   = cfghero[cfgMonster[v].heroLink].qlt
        infoTable[i].hp    = data[i] or 100
        infoTable[i].pos   = cfgSpkWave[solo.estage].stand[i]
    end 
    return infoTable
end

-- 设置自动按钮状态
function solo.setAutoState(isAuto)
	solo.isAuto = isAuto
	if isAuto then
		userdata.setString("soloAuto","1")
	else
		userdata.setString("soloAuto","0")
	end
end

-- 获取自动状态
function solo.getAutoState()
	local isAuto = solo.isAuto or false
	return isAuto
end

-- 设置某个英雄的某种属性
function solo.setHeroProperty(heroOrder,property,value)
	solo.heroList[heroOrder][property] = value
end

-- 设置某个boss的某种属性
function solo.setBossProperty(bossOrder,property,value)
	solo.bossList[bossOrder][property] = value
end

-- 设置状态
function solo.setStatus(status)
	solo.status = status
end

function solo.getStatus()
	return solo.status
end

-- 设置波次数量
function solo.setWave(wave)
	solo.wave = wave
end

function solo.getWave()
	return solo.wave
end

-- 设置波次ID
function solo.setStage(stage)
	solo.estage = stage
end

function solo.getStage()
	return solo.estage
end

-- 设置药剂ID
function solo.setBuf(buf)
	solo.buf = buf
end

function solo.getBuf()
	return solo.buf
end

-- 获取药剂的类型
function solo.getBufType()
	if solo.getBuf() == nil then
		return
	end
	local bufStr  = {[4001] = "milk",[4101] = "evil",[4201] = "angel",[3801] = "power", [3701] = "speed",[3901] = "crit"}
	local bufType = bufStr[cfgDrug[solo.getBuf()].iconId]
	return bufType
end

-- 设置/获取商人ID
function solo.setTrader(trader)
	solo.trader = trader
end

function solo.getTrader()
	return solo.trader
end

-- 设置/获取宝箱信息
function solo.setReward(reward)
	solo.reward = reward
end

function solo.getReward()
	return solo.reward
end

-- 设置上次选中的英雄序列
function solo.setSelectOrder(order)
	solo.selectOrder = order
end

function solo.getSelectOrder()
	return solo.selectOrder
end

-- 刷新数据
function solo.refreshData(data)
	
end

-- 清除数据
function solo.clearData()
	for k,v in pairs(solo) do
		v = nil
	end
	solo = {}
end

return solo
