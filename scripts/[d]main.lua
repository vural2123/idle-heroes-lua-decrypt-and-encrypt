function tracebackex()  
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
    return ret  
end

local function getBigVersion()
    require"version"
    return VERSION_CODE
end

local function getUserVersion()
    local version = CCUserDefault:sharedUserDefault():getStringForKey("aaVersion")
    return version
end
    
local function str_split(input, delimiter)
    input = tostring(input)
    delimiter = tostring(delimiter)
    if (input=='') then return false end
    if (delimiter=='') then return false end
    local pos, arr = 0, {}
    -- for each divider found
    for st,sp in function() return string.find(input, delimiter, pos, true) end do
        table.insert(arr, string.sub(input, pos, st-1))
        pos = sp+1
    end
    table.insert(arr, string.sub(input, pos))
    return arr
end
    
local function math_round(value)
    return math.floor(value+0.5)
end

local uVersion = getUserVersion()
local bVersion = getBigVersion()

local function mgetVersion()
    if not uVersion then
        CCUserDefault:sharedUserDefault():setStringForKey("aaVersion", bVersion)
        CCUserDefault:sharedUserDefault():flush()
        uVersion = bVersion
        return bVersion
    end
    local o_arr = str_split(uVersion, ".")
    local v_arr = str_split(bVersion, ".")
    for ii=1,#v_arr do
        if o_arr and v_arr and o_arr[ii] and v_arr[ii] then
            if math_round(o_arr[ii]) < math_round(v_arr[ii]) then
                return bVersion
            elseif math_round(o_arr[ii]) > math_round(v_arr[ii]) then
                return uVersion
            end
        end
    end
    return bVersion
end

--[[
--  比较上次更新版本 和 当前最大版本是否一致,
--  不一致是因为上一次发布了新的大版本，需要
--  更新历史存档版本号
-- ]]
local function cmpVersion()
    local mVersion = mgetVersion()
    if uVersion ~= mVersion then
        print("code_version > user version")
        if uVersion and uVersion ~= "" then
            local fUtil = CCFileUtils:sharedFileUtils()
            local upDir = fUtil:getWritablePath() .. uVersion
            local fileOpt = require "common.fileOpt"
            if fileOpt.isDir(upDir) then
                fileOpt.rmdir(upDir)
            end
        end
        CCUserDefault:sharedUserDefault():setStringForKey("aaVersion", mVersion)
        CCUserDefault:sharedUserDefault():flush()
    end
end
cmpVersion()

function __G__TRACKBACK__(msg)
    local traceback_str = tracebackex()
    print("----------------------------------------")
    print("LUA ERROR: " .. tostring(msg))
    --print(debug.traceback())
    print(traceback_str)
    print("----------------------------------------")
    -- our report
    require "common.func"
    reportException(tostring(msg), tostring(msg) .. "\n" .. traceback_str)
end

local function getAppDir()
   local prefix = "scripts/"
   if not HHUtils:isCryptoEnabled() then
       prefix = "scripts_raw/"
   end
   local file = prefix .. "main.lua"
   local path = CCFileUtils:sharedFileUtils():fullPathForFilename(file)
   return path:sub(1, -#file-1)
end

local function refreshSearchPaths(version)
   local fileOpt = require "common.fileOpt"
   local fUtil = CCFileUtils:sharedFileUtils()
   fUtil:removeAllPaths()
   local appDir = getAppDir()
   local suffix = "/"
   if not HHUtils:isCryptoEnabled() then
       suffix = "_raw/"
   end
   if version and version ~= "" then
       local upDir = fUtil:getWritablePath() .. version
       if fileOpt.isDir(upDir) then
           fUtil:addSearchPath(upDir .. "/scripts" .. suffix)
           fUtil:addSearchPath(upDir .. "/res" .. suffix)
       end
   end
   fUtil:addSearchPath(appDir .. "scripts" .. suffix)
   fUtil:addSearchPath(appDir .. "res" .. suffix)
   fUtil:printSearchPaths()
end

local version = CCUserDefault:sharedUserDefault():getStringForKey("aaVersion")
refreshSearchPaths(version)

--[[SERVER_MODE = 0

function prequire(path)
	if path and SERVER_MODE and SERVER_MODE > 0 then
		local extraPath = "s" .. SERVER_MODE .. "." .. path
		local status, lib = pcall(require, extraPath)
		if(status) then
			return lib
		end
	end
    
    return require(path)
end--]]

local function main()
    collectgarbage("setpause", 100)
    collectgarbage("setstepmul", 5000)

    -- random seed
    math.randomseed(tonumber(tostring(os.time()):reverse():sub(1,6)))
    
    -- fps stats
    CCDirector:sharedDirector():setDisplayStats(false)

    -- payment
    DHPayment:getInstance():init(PAYMENT_GOOGLE)

    local scene = CCScene:create()
    scene:addChild(require("ui.login.logo").create())

    if CCDirector:sharedDirector():getRunningScene() then
        CCDirector:sharedDirector():replaceScene(scene)
    else
        CCDirector:sharedDirector():runWithScene(scene)
    end
end

xpcall(main, __G__TRACKBACK__)
