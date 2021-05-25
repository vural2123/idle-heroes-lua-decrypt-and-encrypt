local String = {}

function String.getGrowthString(str, value)
	local eps = 0.0001
	local count = 0
	if value - math.floor(value) < eps then
		str, count = string.gsub(str, "%%d", string.format("%.0f", value))
	elseif value * 10 - math.floor(value * 10) < eps then
		str, count = string.gsub(str, "%%d", string.format("%.1f", value))
	else
		str, count = string.gsub(str, "%%d", string.format("%.2f", value))
	end
	
	if count <= 0 then
		local pValue = value * 100
		if pValue - math.floor(pValue) < eps then
			str, count = string.gsub(str, "%%p", string.format("%.0f", pValue).."%%")
		elseif pValue * 10 - math.floor(pValue * 10) < eps then
			str, count = string.gsub(str, "%%p", string.format("%.1f", pValue).."%%")
		else
			str, count = string.gsub(str, "%%p", string.format("%.2f", pValue).."%%")
		end
	end
	return str
end

function String.endWith(str, pattern)
	if not str or not pattern then
		return false
	end
	local len = string.len(str)
	local pLen = string.len(pattern)
	return string.find(str, pattern, len - pLen)
end

function String.split(str, pattern)
	local nFindStartIndex = 1
	local nSplitIndex = 1
	local nSplitArray = {}
	while true do
		local nFindLastIndex = string.find(str, pattern, nFindStartIndex)
			if not nFindLastIndex then
			nSplitArray[nSplitIndex] = string.sub(str, nFindStartIndex, string.len(str))
			break
		end
		nSplitArray[nSplitIndex] = string.sub(str, nFindStartIndex, nFindLastIndex - 1)
		nFindStartIndex = nFindLastIndex + string.len(pattern)
		nSplitIndex = nSplitIndex + 1
	end
	return nSplitArray
end

return String