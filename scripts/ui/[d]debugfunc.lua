local ui = {}

local function reportMe(detail)
	detail = string.gsub(detail, "/data/data/com.droidhang.rd/files", "")
    CCDirector:sharedDirector():getRunningScene():addChild((require"ui.help").create(detail, ""), 1000000)
end

local function onException(msg)
	local ret = ""  
	local level = 3
	while true do
		--get stack info  
		local info = debug.getinfo(level, "Sln")
		if not info then break end
		if info.what == "C" then  -- C function
			ret = ret .. tostring(level) .. "\tC function\n"
		else  -- Lua function
			ret = ret .. string.format("\t[%s]:%d `%s`\n", info.source, info.currentline, info.name or "")
		end
		level = level + 1
	end
	local show = tostring(msg or "") .. "\n" .. ret
	if ui.lastReportMode then
		ui.lastReportMode(show)
	else
		reportMe(show)
	end
end

function ui.call(fn, reportMode)
	ui.lastReportMode = reportMode
	xpcall(fn, onException)
end

return ui