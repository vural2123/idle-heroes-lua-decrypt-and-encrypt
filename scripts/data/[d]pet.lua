local pet = {}

require "common.const"
require "common.func"

local petMain = require "ui.pet.main"
local petConf = require "config.pet"

pet.data  = {}
pet.sele  = nil --战宠选中宠物出战的临时存储值

function pet.showRedDot()
--[[
	local petData = petMain.TestData 
	local consumData = petMain.consumData
	for k,v in pairs(petConf) do
		local haveItem = false
		for l,n in pairs(petData) do
			if k == n["id"] then
				haveItem = true
			end				
		end
		
		if not haveItem then
			local itemType = v["activaty"][1]["type"] 
			local count = v["activaty"][1]["count"]
			if consumData[itemType] >= count then
				return true
			end
		end
	end
	]]
	return false
end

function pet.initData()
	--选中的队伍1
	print("宠物数据的初始化")

end

function pet.ruleData(data)
	--这个ID有一套和策划约定的潜规则，转换成等级。这里做个转换，避免UI界面各个地方都写转换
	--这个潜规则当id大于700的时候，潜规则变化[7001,7031,7061,7091]
	--
	for key,val in pairs(data) do
		val.buffLv = {}
		for k,v in pairs(val.skl) do
			--小于700遵循一套潜规则，大于700另外遵循一套，原因是服务器不支持id过长导致的双潜规则
			if val.id < 700 then
				local lv = v- (math.floor(val.id/100)*10000+1000*k)
				val.buffLv[k] = lv
			else
				local lv = v - (math.floor(val.id/100)*1000+30*(k-1))
				val.buffLv[k] = lv
			end
		end
	end

	return data 
end

--做一些数据兼容处理
function pet.setData(data)
	pet.data = data

	-- 创建另外一个数据，主要是为了兼容和服务器数据
	-- 服务器认定宠物是0星开始，
	-- 但由于客户端一直在数据层认定为是1开始，修改量巨大，所以这里做一个兼容，避免UI表层逻辑代码大量修改
	for k,v in pairs(pet.data) do
		v.advanced = v.star + 1
	end
	--服务器返回的buff光环是ID，
	pet.data = pet.ruleData(pet.data)
end

--用于激活的时候手动添加数据
function pet.addData(petId)
    local data = {}
    data.id         = petId
    data.lv         = 1
    data.advanced   = 1
    data.star       = 0
    data.buffLv     = {}
    data.buffLv[1]  = 1
    data.skl        = {}
    data.skl[1]     = petConf[petId].pasSkillId[1]
    print("data.skl[1] == "..data.skl[1])
	table.insert( pet.data , data )
end

--返回id的数据
function pet.getData(petId)
	for k,v in pairs(pet.data) do
		if tonumber(v.id) == tonumber(petId) then
			return pet.data[k]
		end
	end
	return nil
end

--刷新
function pet.refreshData()
	for k,v in pairs(pet.data) do
		v.advanced = v.star + 1

		for i=1,v.advanced do
			if v.skl[i] == nil then
				v.skl[i] = petConf[v.id].pasSkillId[i]
			end
		end
	end

	pet.data = pet.ruleData(pet.data)
	
end


--重置某个宠物2
function pet.Reset(id)
	for k,v in pairs(pet.data) do
		if v.id == id then
			v.advanced = 1
			v.star = 0
			v.skl = {}
			v.buffLv = {}
			v.skl[1] = petConf[v.id].pasSkillId[1]
			v.buffLv[1] = 1
		end
	end
end

function pet.coutRsult(id,status)
	if status >= 0 then
		return
	end
	--特殊的报错
	if id == 3 and status == -3 then
		showToast(string.format(i18n.global.pet_smaterial_not_enough.string))
		return
	end
	showToast("op = "..id.." status = "..status)
end

function pet.getPetID(hids)
    if not hids  then return nil end
    for k, v in pairs(hids) do
        if v.pos == 7 then
            return v.id
        end
    end
    return nil
end

function pet.getPetIDFromCamp(camp)
    for _, v in ipairs(camp) do
        if v and v.pos == 7 then
            return v.id
        end
    end
    return nil
end

return pet
