-- 启动后用户帐号确认界面

local ui = {}

local cjson = json

require "config"
require "framework.init"
require "common.const"
require "common.func"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local i18n = require "res.i18n"
local audio = require "res.audio"
--local net = require "net.netClient"
local userdata = require "data.userdata"

local TAG_POPUP_SWITCH = 100
local TAG_POPUP_NOTICE = 101
local TAG_POPUP_REPAIR = 102

-- 创建页面
function ui.create()
    local layer = CCLayer:create()

    img.loadAll(img.packedLogin.common)
    img.loadAll(img.packedLogin.home)
    local loadingImgs = img.getLoadingImgs()

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

    schedule(layer, 0.5, function()
        local frames = img.getFramesOfLoading(loadingImgs)
        local animation = display.newAnimation(frames, 2.0 / 50)
        sprite:playAnimationForever(animation)
    end)

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

    function layer.fadeHint()
        if not tolua.isnull(hint) and not tolua.isnull(hintBg) then
            local t = 1
            hint:runAction(CCRepeatForever:create(createSequence({
                CCFadeTo:create(t, 255 * 0.1),
                CCFadeTo:create(t, 255),
            })))
            hintBg:runAction(CCRepeatForever:create(createSequence({
                CCFadeTo:create(t, 255 * 0.2),
                CCFadeTo:create(t, 255),
            })))
        end
    end

    -- version label
    local vlabel = lbl.createFont2(16, getVersion(), ccc3(0xff, 0xfb, 0xd9), true)
    vlabel:setAnchorPoint(ccp(1, 0))
    vlabel:setPosition(view.maxX, scaley(2))
    layer:addChild(vlabel, 1)
    autoLayoutShift(vlabel)

    -- 加一个层，在匹配最佳网关的期间阻塞掉用户输入
    local ban = CCLayer:create()
    ban:setTouchEnabled(true)
    ban:setTouchSwallowEnabled(true)
    layer:addChild(ban, 100)

    -- init gate
    local inited, started
    schedule(layer, function()
        if not isNetAvailable() then
            ui.popErrorDialog(i18n.global.error_network_unavailable.string)
            return
        end
        layer.setHint(i18n.global.get_best_gate_server.string)
        require("ui.login.gate").init(function(status, gate)
            if status ~= "ok" then
                ui.popErrorDialog(i18n.global.get_best_gate_server_fail.string)
                if reportRIpException then
                    reportRIpException()
                end
                return
            end
            schedule(layer, 2.0, function()
                ui.pullNotice(layer, gate, function(status)
                    inited = true
                    layer.setHint("")
                    schedule(layer, 0.5, function()
                        ui.popWelcome(layer)
                    end)
                    schedule(layer, 2.0, function()
                        ui.popNotice(layer)
                        if ban and not tolua.isnull(ban) then
                            ban:removeFromParent()
                        end
                        layer.setHint(i18n.global.start_game.string)
                        layer.fadeHint()
                    end)
                end)
            end)
        end)
    end)

    -- 帐号切换按钮
    local accountBtn0 = img.createLoginSprite(img.login.login_btn_switch)
    local accountBtn = SpineMenuItem:create(json.ui.button, accountBtn0)
    accountBtn:setScale(view.minScale)
    accountBtn:setPosition(scalep(919, 540))
    local accountMenu = CCMenu:createWithItem(accountBtn)
    accountMenu:setPosition(0, 0)
    layer:addChild(accountMenu)
    accountBtn:registerScriptTapHandler(function()
        if inited and not started then
            audio.play(audio.button)
            ui.popSwitchDialog(layer, function(account)
                schedule(layer, 0.3, function()
                    ui.popWelcome(layer, account)
                end)
            end)
        end
    end)

    -- 公告按钮
    local noticeBtn0 = img.createLoginSprite(img.login.login_btn_notice)
    local noticeBtn = SpineMenuItem:create(json.ui.button, noticeBtn0)
    noticeBtn:setScale(view.minScale)
    noticeBtn:setPosition(scalep(858, 540))
    local noticeMenu = CCMenu:createWithItem(noticeBtn)
    noticeMenu:setPosition(0, 0)
    layer:addChild(noticeMenu)
    noticeBtn:registerScriptTapHandler(function()
        if inited and not started then
            audio.play(audio.button)
            ui.popNotice(layer)
        end
    end)

    -- 修复模式按钮
    local repairBtn0 = img.createLoginSprite(img.login.login_btn_repair)
    local repairBtn = SpineMenuItem:create(json.ui.button, repairBtn0)
    repairBtn:setScale(view.minScale)
    repairBtn:setPosition(scalep(39, 540))
    local repairMenu = CCMenu:createWithItem(repairBtn)
    repairMenu:setPosition(0, 0)
    layer:addChild(repairMenu)
    repairBtn:registerScriptTapHandler(function()
        if inited and not started then
            audio.play(audio.button)
            ui.popRepairDialog(layer, function()
                if inited and not started then
                    started = true
                    ui.goUpdate(layer)
                end
            end)
        end
    end)

    autoLayoutShift(accountBtn)
    autoLayoutShift(noticeBtn, nil, nil, nil, true)
    autoLayoutShift(repairBtn)

    addBackEvent(layer)

    function layer.onAndroidBack()
        exitGame(layer)
    end

    layer:registerScriptHandler(function(event)
        if event == "enter" then
            layer.notifyParentLock()
        elseif event == "exit" then
            layer.notifyParentUnlock()
        end
    end)

    local function onTouch(eventType, x, y)
        if eventType == "began" then
            return true
        elseif eventType == "moved" then
            return
        elseif inited and not started and y < scaley(500) then
            started = true
            img.unloadFramesOfLoading(loadingImgs)
            ui.goUpdate(layer, getVersion())
        end
    end

    if APP_CHANNEL and APP_CHANNEL == "TX" then
        accountBtn:setVisible(false)
        repairBtn:setVisible(false)
        noticeBtn:setVisible(false)
        hint:setVisible(false)
        local txlogin = require("ui.login.txlogin").create()
        txlogin:setScale(view.minScale)
        txlogin:setAnchorPoint(ccp(0, 0))
        txlogin:setPosition(scalep(0, 0))
        layer:addChild(txlogin, 200)
    elseif APP_CHANNEL and APP_CHANNEL == "MSDK" then
        local player = require"data.player"
        player.uid = nil
        player.sid = nil
        --layer:setTouchEnabled(false)
        accountBtn:setVisible(false)
        repairBtn:setVisible(false)
        noticeBtn:setVisible(false)
        hint:setVisible(false)
        local btn_logout0 = img.createLogin9Sprite(img.login.button_9_gold)
        btn_logout0:setPreferredSize(CCSizeMake(80, 48))
        local lbl_logout = lbl.createMixFont1(18, "注销", ccc3(0x83, 0x41, 0x1d))
        lbl_logout:setPosition(CCPoint(40, 24))
        btn_logout0:addChild(lbl_logout)
        local btn_logout = SpineMenuItem:create(json.ui.button, btn_logout0)
        btn_logout:setScale(view.minScale)
        btn_logout:setPosition(scalep(919, 540))
        local btn_logout_menu = CCMenu:createWithItem(btn_logout)
        btn_logout_menu:setPosition(CCPoint(0, 0))
        layer:addChild(btn_logout_menu)
        autoLayoutShift(btn_logout)
        btn_logout:setVisible(false)
        btn_logout:registerScriptTapHandler(function()
            audio.play(audio.button)
            local lparams = {
                which = "logout",
            }
            local lparamStr = cjson.encode(lparams)
            SDKHelper:getInstance():login(lparamStr, function(data)
                print("msdk logout data:", data)
                btn_logout:setVisible(false)
                hint:setVisible(false)
                local txlogin = require("ui.login.txlogin").create()
                txlogin:setScale(view.minScale)
                txlogin:setAnchorPoint(ccp(0, 0))
                txlogin:setPosition(scalep(0, 0))
                layer:addChild(txlogin, 200)
            end)
        end)
        SDKHelper:getInstance():initGame("", function(data)
            print("msdk initGame data:", data)
            if data and data == "wxcall2" then
                userdata.setString(userdata.keys.txwhich, "wx")
                require("ui.login.home").goUpdate(layer, getVersion())
            elseif data and data == "qqcall2" then
                userdata.setString(userdata.keys.txwhich, "qq")
                require("ui.login.home").goUpdate(layer, getVersion())
            end
            local player = require"data.player"
            if player.uid and player.sid then  -- 在游戏内，不做处理
                return
            end
            --local data = cjson.decode(ldata)
            if data and data == "wxcall" then
                userdata.setString(userdata.keys.txwhich, "wx")
                require("ui.login.home").goUpdate(layer, getVersion())
            elseif data and data == "qqcall" then
                userdata.setString(userdata.keys.txwhich, "qq")
                require("ui.login.home").goUpdate(layer, getVersion())
            end
        end)
        schedule(layer, 0.5, function()
        local params = {
            which = "",
        }
        print("start to check login")
        local paramStr = cjson.encode(params)
        SDKHelper:getInstance():login(paramStr, function(ldata)
            print("msdk prelogin data:", ldata)
            local data = cjson.decode(ldata)
            if data and data.platform == "none" then
                btn_logout:setVisible(false)
                local txlogin = require("ui.login.txlogin").create()
                txlogin:setScale(view.minScale)
                txlogin:setAnchorPoint(ccp(0, 0))
                txlogin:setPosition(scalep(0, 0))
                layer:addChild(txlogin, 200)
            elseif data and data.platform == "qq" then
                userdata.setString(userdata.keys.txwhich, "qq")
                btn_logout:setVisible(true)
                hint:setVisible(true)
                layer.setHint(i18n.global.start_game.string)
                layer:setTouchEnabled(true)
            elseif data and data.platform == "wx" then
                userdata.setString(userdata.keys.txwhich, "wx")
                btn_logout:setVisible(true)
                hint:setVisible(true)
                layer.setHint(i18n.global.start_game.string)
                layer:setTouchEnabled(true)
            elseif data and data.platform == "wxcall" then
                userdata.setString(userdata.keys.txwhich, "wx")
                require("ui.login.home").goUpdate(layer, getVersion())
            elseif data and data.platform == "qqcall" then
                userdata.setString(userdata.keys.txwhich, "qq")
                require("ui.login.home").goUpdate(layer, getVersion())
            end
            inited = true
            if ban and not tolua.isnull(ban) then
                ban:removeFromParent()
            end
        end)
        end)
    elseif isChannel() then
        accountBtn:setVisible(false)
        repairBtn:setVisible(false)
        noticeBtn:setVisible(false)
    end

    layer:registerScriptTouchHandler(onTouch)
    layer:setTouchEnabled(true)

    return layer
end

-- 切换到更新界面
function ui.goUpdate(layer, version)
    local time = 0
    if layer and layer.bg and not tolua.isnull(layer.bg) then
        time = layer.bg:getFrameTime()
        layer.bg:unscheduleUpdate()
    end
    --if not isChannel() then
    --    layer.bg:unscheduleUpdate()
    --else
    --    time = 0
    --end
    if version then
        --local tscene = require("ui.login.update").create(false, nil, time)
        --tscene.nocheck = true
        --replaceScene(tscene)
        replaceScene(require("ui.login.update").create(false, nil, time))
    else
        --local tscene = require("ui.login.update").create(true, nil, time)
        --tscene.nocheck = true
        --replaceScene(tscene)
        replaceScene(require("ui.login.update").create(true, nil, time))
    end
end

-- 弹出错误对话框
function ui.popErrorDialog(text)
    if isChannel() then
        replaceScene(require("ui.login.home").create())
        return
    end
    popReconnectDialog(text, function()
        replaceScene(require("ui.login.home").create())
    end)
end

-- 弹出切换帐号对话框
function ui.popSwitchDialog(layer, onSuccess)
    if not layer:getChildByTag(TAG_POPUP_SWITCH) then
        layer:addChild(require("ui.login.input").create(onSuccess), 1000)
    end
end

-- 拉取公告
function ui.pullNotice(layer, gate, handler)
    layer.setHint(i18n.global.pull_notice.string)
    local pubs = require "data.pubs"
    local param
    if pubs.init() then
        param = { sid = 0, language = pubs.language, vsn = pubs.vsn }
    else
        param = { sid = 0, language = i18n.getCurrentLanguage(), vsn = 0 }
    end
    local isDone = false
    local net = require "net.netClient"
    net:connect({ host = gate.host, port = gate.port }, function()
        if isDone then return end
        net:pub(param, function(data)
            if not isDone then
                isDone = true
                if data.status < 0 then
                    layer.setHint(i18n.global.pull_notice_fail.string .. data.status)
                    return
                end
                if data.status ~= 1 then
                    pubs.save(data.language, data.vsn, data.pub)
                end
                pubs.print()
                net:close(function()
                    if data.status == 1 then
                        handler("cache")
                    else
                        handler("ok")
                    end
                end)
            end
        end)
    end)
    schedule(layer, NET_TIMEOUT, function()
        if not isDone then
            isDone = true
            net:close(function()
                ui.popErrorDialog(i18n.global.pull_notice_fail.string .. ": timeout")
            end)
        end
    end)
end

-- 弹出公告
function ui.popNotice(layer)
    if APP_CHANNEL  and APP_CHANNEL == "MSDK" then
        if ui.popped_notice then return end
        ui.popped_notice = true
    end
    if not layer:getChildByTag(TAG_POPUP_NOTICE) then
        layer:addChild(require("ui.login.notice").create(), 300)
    end
end

-- 弹出修复模式对话框
function ui.popRepairDialog(layer, onConfirm)
    if not layer:getChildByTag(TAG_POPUP_REPAIR) then
        local pop = require("ui.dialog").create({
            body = i18n.global.repair_mode.string,
            btn_count = 2,
            btn_text = {
                [1] = i18n.global.dialog_button_cancel.string,
                [2] = i18n.global.dialog_button_confirm.string,
            },
            selected_btn = 0,
        })
        pop.setCallback(function(data)
            data.button:setEnabled(false)
            pop:removeFromParent()
            if data.selected_btn == 2 then
                onConfirm()
            end
        end)
        layer:addChild(pop, 100)
    end
end

-- 弹出欢迎
function ui.popWelcome(layer, account)
    account = account or userdata.getString(userdata.keys.account)
    if account ~= "" then
        local str = string.format(i18n.global.welcome_player.string, account)
        local label = lbl.createFontTTF(20, str, ccc3(0, 0, 0))
        local w, h = label:boundingBox().size.width + 150, 70
        local bg = img.createLogin9Sprite(img.login.login_welcome_bg)
        bg:setPreferredSize(CCSize(w, h))
        bg:setScale(view.minScale)
        bg:setAnchorPoint(ccp(0.5, 0))
        bg:setPosition(view.midX, view.physical.h)
        layer:addChild(bg, 500)
        local logo = img.createLoginSprite(img.login.login_welcome_logo)
        logo:setPosition(50, h / 2)
        bg:addChild(logo)
        label:setAnchorPoint(ccp(0, 0.5))
        label:setPosition(100, h / 2 - 1)
        bg:addChild(label)
        bg:runAction(createSequence({
            CCMoveTo:create(0.4, ccp(view.midX, view.physical.h - (h - 12) * view.minScale)),
            CCDelayTime:create(1.8),
            CCMoveTo:create(0.2, ccp(view.midX, view.physical.h)),
            CCRemoveSelf:create()
        }))
    end
end

return ui
