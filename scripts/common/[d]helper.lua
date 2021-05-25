
local helper = {}

local lowMemoryFlag = false
local resMap = {}

-- 判断是否低内存
function helper.isLowMem()
    if lowMemoryFlag then
        return true
    end

    if HHUtils:isLowMemory() then
        lowMemoryFlag = true
        return true
    end
    return false
    --return true
end

function helper.loadResource(resName)
	if resMap[resName] then
		return false
	end
	resMap[resName] = true
	return true
end

function helper.unloadResource(resName)
	resMap[resName] = nil
end

function helper.getJsonCacheCount()
	return 10000
	-- if helper.isLowMem() then
	-- 	return 18
	-- else
	-- 	return 40
	-- end
end

function helper.checkMemory()
	if helper.isLowMem() then
		collectgarbage("collect")
	end
end

return helper
