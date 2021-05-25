-- 热更新

local ui = {}
            
local cjson = json

require "config"
require "framework.init"
require "common.const"
require "common.func"
local view = require "common.view"
local fileOpt = require "common.fileOpt"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local i18n = require "res.i18n"
local audio = require "res.audio"
local net = require "net.netClient"
local userdata = require "data.userdata"
local heartbeat = require "data.heartbeat"

-- checkFile: 是不是检测文件完整性
-- sid: sid 可选
-- time: 背景动画的时间轴
-- extra: table  额外信息
function ui.create(checkFile, sid, time, extra)
    local layer = CCLayer:create()

    img.loadAll(img.packedLogin.common)
    img.loadAll(img.packedLogin.home)
    local loadingImgs = img.getLoadingImgs()

    audio.stopBackgroundMusic()
    CCDirector:sharedDirector():getScheduler():setTimeScale(1)

    local suffix = "_us"
    if isAmazon() then
        suffix = "_us"
    elseif isOnestore() then
        suffix = "_us"
    elseif APP_CHANNEL and APP_CHANNEL ~= "" then
        suffix = "_cn"
    end
    -- bg
    local sprite = CCSprite:create(loadingImgs[1])
    sprite:setPosition(CCPoint(view.midX, view.midY))
    sprite:setScale(view.minScale)
    layer:addChild(sprite)

    local slogo = CCSprite:create(string.format("LOADING/Logo%s.png", suffix))
    slogo:setPosition(CCPoint(343, 583))
    sprite:addChild(slogo)

    --schedule(layer, function()
    --    local frames = img.getFramesOfLoading(loadingImgs)
    --    local animation = display.newAnimation(frames, 2.0 / 50)
    --    sprite:playAnimationForever(animation)
    --end)

    -- 提示文本
    local hintBg = img.createLogin9Sprite(img.login.text_border_2)
    local hintWidth = view.physical.w
    hintBg:setPreferredSize(CCSize(hintWidth, 38 * view.minScale))
    hintBg:setAnchorPoint(ccp(0.0, 0))
    hintBg:setPosition(0, 0)
    layer:addChild(hintBg)
    local hint = lbl.createMixFont2(18, "", ccc3(0xff, 0xf7, 0xe5), true)
    hint:setPosition(view.midX, scaley(17))
    layer:addChild(hint)

    autoLayoutShift(hint)

    function layer.setHint(text)
        if not tolua.isnull(hint) then
            hint:setString(text)
        end
    end

    -- progress bg
    local progressBg = img.createLogin9Sprite(img.login.login_bar_bg)
    progressBg:setPreferredSize(CCSizeMake(960, 4))
    progressBg:setScaleX(view.xScale)
    progressBg:setScaleY(view.minScale)
    progressBg:setAnchorPoint(ccp(0.5, 0))
    progressBg:setPosition(view.midX, 0)
    layer:addChild(progressBg)  

    -- progress fg
    local progress0 = img.createLoginSprite(img.login.login_bar_fg)
    local progress = createProgressBar(progress0)
    progress:setScaleX(view.xScale)
    progress:setScaleY(view.minScale)
    progress:setPosition(view.midX, progressBg:boundingBox():getMidY())
    layer:addChild(progress)  
                             
    function layer.setPercentageForProgress(percentage)
        if not tolua.isnull(progress) then
            progress:setPercentage(percentage)
        end
    end

    -- version label
    local vlabel = lbl.createFont2(16, getVersion(), ccc3(0xff, 0xfb, 0xd9), true)
    vlabel:setAnchorPoint(ccp(1, 0)) 
    vlabel:setPosition(view.maxX, scaley(2))
    layer:addChild(vlabel, 1)

    autoLayoutShift(vlabel)

    net:close()
    net:setDialogEnable(false)
    heartbeat.stop()

    schedule(layer, function()
        local isDone = false
        local isSwitchServer = sid ~= nil
        require("ui.login.auth").start({sid = sid, extra = extra}, function(status, uid, sid)
            if not isDone then
                isDone = true
                if status == "ok" then
                    if isSwitchServer then
                        userdata.clearWhenSwitchAccount()
                    end
                    ui.check(layer, checkFile, uid, sid)
                else
                    ui.popErrorDialog(status, checkFile)
                end
            end
        end, layer.setHint)
        schedule(layer, NET_TIMEOUT, function()
            if not isDone then
                isDone = true
                ui.popErrorDialog(i18n.global.error_network_timeout.string, checkFile)
            end
        end)
    end)

    return layer
end

function ui.check(layer, checkFile, uid, sid)
    local v, uv, cv, compare = getVersionDetail()
    print("ui.login.update version", v, "userVersion", uv, "codeVersion", cv, compare)
    if compare < 0 then
        fileOpt.rmfile(CCFileUtils:sharedFileUtils():getWritablePath() .. uv)
        userdata.setString(userdata.keys.version, v)
    end
    if checkFile then
        layer.setHint(i18n.global.filecheck_list.string)
    else
        layer.setHint(i18n.global.update_check.string)
    end
    local isDone = false
    local upName = ui.getPackageName()
    net:up({sid = sid, vsn = op3(checkFile, cv, v), packagename = upName}, function(data)
        if isDone then return end
        isDone = true
        if data.status ~= 0 then
            if checkFile then
                layer.setHint(i18n.global.filecheck_fail.string .. " net:up " .. data.status)
            else
                layer.setHint(i18n.global.update_fail.string .. " net:up " .. data.status)
            end
            return
        end
        if compareVersion(data.vsn, op3(checkFile, cv, v)) <= 0 then -- 已经是最新
            print("ui.login.update latest")
            layer:addChild(require("ui.login.loading").create(uid, sid))
            return
        end
        if data.lv == 2 then -- 需更新大版本
            print("ui.login.update gotoAppStore")
            net:close()
            gotoAppStore(data.vsn)
            return
        end
        if data.lv == 0 then -- 需要更新
            print("ui.login.update needUpdate")
            net:close()
            ui.update(layer, checkFile, op3(checkFile, cv, v), data)
            return
        end
    end)
    schedule(layer, NET_TIMEOUT*20, function()
        if not isDone then
            isDone = true
            ui.popErrorDialog(i18n.global.error_network_timeout.string, checkFile)
        end
    end)
end

function ui.update(layer, checkFile, oldV, upInfo)
    local newV = upInfo.vsn
    local oldDir = CCFileUtils:sharedFileUtils():getWritablePath() .. oldV .. "/"
    local newDir = CCFileUtils:sharedFileUtils():getWritablePath() .. newV .. "/"
    -- 成功后
    local function onSuccess()
        fileOpt.rmfile(CCFileUtils:sharedFileUtils():getWritablePath() .. oldV)
        userdata.setString(userdata.keys.version, newV)
        if not tolua.isnull(layer) then
            schedule(layer, function()
                --local time = layer.bg:getFrameTime()
                --layer.bg:unscheduleUpdate()
                ui.refresh(newV)
                local tscene = require("ui.login.update").create(false, nil, time)
                tscene.nocheck = true
                replaceScene(tscene)
                --replaceScene(require("ui.login.update").create(false, nil, time))
            end)
        end
    end
    -- 更新第i个文件
    local function updateFile(i)
        local info = upInfo.files[i]
        local percent = math.floor(i / #upInfo.files * 100)
        if checkFile then
            layer.setHint(i18n.global.filechecking.string .. " " .. percent .. "%")
        else
            layer.setHint(i18n.global.updating.string .. " " .. percent .. "%")
        end
        if layer.setPercentageForProgress then
            layer.setPercentageForProgress(percent)
        end
        local function goNext(i)
            if i < #upInfo.files then 
                updateFile(i+1) 
            else 
                onSuccess() 
            end
        end
        if ui.checkFile(newDir, info) then
            -- 新版本更新目录下有, 啥也不用做
            goNext(i)
        elseif ui.checkFile(oldDir, info) and ui.copyFile(oldDir, newDir, info) then
            -- 旧版本更新目录下有, 且拷贝成功
            goNext(i)
        else
            -- 网络下载
            ui.downFile(newDir, upInfo.prefix, info, function(status)
                if status == "ok" then
                    goNext(i)
                else
                    -- 出错
                    local err
                    if checkFile then
                        err = i18n.global.filecheck_fail.string
                    else
                        err = i18n.global.update_fail.string
                    end
                    layer.setHint(err)
                    ui.popErrorDialog(err, checkFile)
                end
            end)
        end
    end
    -- 开始更新
    if upInfo.upList and upInfo.upList ~= "" then
        local listfile = upInfo.prefix .. upInfo.upList
        ui.getHttpContent(listfile, function(data)
            if not data then
                -- 出错
                local err
                if checkFile then
                    err = i18n.global.filecheck_fail.string
                else
                    err = i18n.global.update_fail.string
                end
                layer.setHint(err)
                ui.popErrorDialog(err, checkFile)
                return
            end
            local tfiles = cjson.decode(data)
            upInfo.files = tfiles
            if upInfo.files and #upInfo.files > 0 then
                updateFile(1)
            else 
                onSuccess()
            end
        end)
    else
        if upInfo.files and #upInfo.files > 0 then
            updateFile(1)
        else 
            onSuccess()
        end
    end
end

function ui.checkFile(dir, info)
    local file = dir .. info.path
    return fileOpt.isFile(file) and crypto.md5file(file) == info.md5 
end

function ui.copyFile(oldDir, newDir, info)
    if fileOpt.cpfile(oldDir .. info.path, newDir .. info.path)
        and ui.checkFile(newDir, info) then
        return true
    end
    return false
end

function ui.getHttpContent(url, handler)
    local function sendRequest(count)
        local request = CCHTTPRequest:createWithUrl(function(event)
            if event.name ~= "inprogress" then
                if event.name == "completed" 
                    and event.request:getResponseStatusCode() == 200 then
                    local data = event.request:getResponseData()
                    handler(data)
                    return
                end
                -- 出错处理 最多尝试2次
                if count == 2 then
                    handler()
                else
                    sendRequest(count+1)
                end
            end
        end, url, kCCHTTPRequestMethodGET)
        request:setTimeout(180*count)
        request:start()
    end
    sendRequest(1)
end

function ui.downFile(dir, prefix, info, handler)
    local function sendRequest(count)
        local request = CCHTTPRequest:createWithUrl(function(event)
            if event.name ~= "inprogress" then
                if event.name == "completed" 
                    and event.request:getResponseStatusCode() == 200 then
                    local data = event.request:getResponseData()
                    if fileOpt.writeFile(data, dir .. info.path)
                        and ui.checkFile(dir, info) then
                        handler("ok")
                        return
                    end
                end
                -- 出错处理 最多尝试2次
                if count == 2 then
                    handler("error")
                else
                    sendRequest(count+1)
                end
            end
        end, prefix .. info.md5, kCCHTTPRequestMethodGET)
        request:setTimeout(180*count)
        request:start()
    end
    sendRequest(1)
end

function ui.refresh(version)
    local nativeUpdateComponent = require("dhcomponents.NativeUpdateComponent")
    if not nativeUpdateComponent:isModify() then
        ui.refreshSearchPaths(version)
    end
    
    ui.clearLoaded()
    ui.loadBasic()
end

function ui.refreshSearchPaths(version)
    local fUtil = CCFileUtils:sharedFileUtils()
    fUtil:removeAllPaths()
    local appDir = ui.getAppDir()
    local suffix = op3(HHUtils:isCryptoEnabled(), "/", "_raw/")
    if version then
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

function ui.getAppDir()
    local file = "scripts/main.lua"
    local path = CCFileUtils:sharedFileUtils():fullPathForFilename(file)
    return path:sub(1, -#file-1)
end

function ui.clearLoaded()
    -- some states
    net:close()
    -- resources
    DHSkeletonDataCache:getInstance():purgeCache()
    CCSpriteFrameCache:sharedSpriteFrameCache():removeSpriteFrames()
    CCTextureCache:sharedTextureCache():removeAllTextures()
    CCLabelBMFont:purgeCachedData()
    -- scripts
    local whitelist = {
        "string", "io", "pb", "bit", "os", "debug", "table", "math", "package", 
        "coroutine", "pack", "jit", "jit.util", "jit.opt", "main", 
    }
    for p, _ in pairs(package.loaded) do
        if not arraycontains(whitelist, p) then
            package.loaded[p] = nil
        end
    end
end

function ui.loadBasic()
    require "config"
    require "framework.init"
    require "version"
    require "common.const"
    require "common.func"
end

function ui.popErrorDialog(text, checkFile)
    popReconnectDialog(text, function()
        local tscene = require("ui.login.update").create(checkFile)
        tscene.nocheck = true
        replaceScene(tscene)
        --replaceScene(require("ui.login.update").create(checkFile))
    end)
end

function ui.getPackageName()
    if not isChannel() then
        if APP_CHANNEL and APP_CHANNEL == "IAS" then
            return "adtt"
        elseif not HHUtils:isReleaseMode() then    -- lan
            return "ad"
        elseif device.platform == "android" then
            return "ad_google"
        elseif device.platform == "ios" then
            return "ad_ios"
        end
        return
    end
    local sdkcfg = require"common.sdkcfg"
    if sdkcfg[APP_CHANNEL] and sdkcfg[APP_CHANNEL].upName then
        return sdkcfg[APP_CHANNEL].upName
    end
    return
end

return ui
