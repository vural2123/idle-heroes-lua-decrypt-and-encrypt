local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local i18n = require "res.i18n"
local json = require "res.json"
local audio = require "res.audio"
local player = require "data.player"
local net = require "net.netClient"
local lineCreate = require("ui.guildFight.lineCreate")

local droidhangComponents = require("dhcomponents.DroidhangComponents")

local final_8 = class("final_8", function ()
    return cc.LayerColor:create(cc.c4b(0, 0, 0, POPUP_DARK_OPACITY))
end)

function final_8.create(uiParams)
    return final_8.new(uiParams)
end

function final_8:ctor(resData)
    local BG_WIDTH = 786
    local BG_HEIGHT = 470

    -- bg
    local bg = img.createUI9Sprite(img.ui.tips_bg)
    bg:setPreferredSize(CCSize(BG_WIDTH, BG_HEIGHT))
    bg:setScale(0.1 * view.minScale)
    bg:setAnchorPoint(ccp(0.5,0.5))
     bg:setPosition(view.midX, view.midY)
    bg:runAction(CCEaseBackOut:create(CCScaleTo:create(0.3, view.minScale)))
    self:addChild(bg)
    self.bg = bg

    -- closeBtn
    local closeBtn0 = img.createUISprite(img.ui.close)
    local closeBtn = SpineMenuItem:create(json.ui.button, closeBtn0)
    closeBtn:setPosition(BG_WIDTH-23, BG_HEIGHT-26)
    local closeMenu = CCMenu:createWithItem(closeBtn)
    closeMenu:setPosition(0, 0)
    bg:addChild(closeMenu)
    closeBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        self.onAndroidBack()
    end)

    -- title
    local title = i18n.global.guildFight_final_8_4.string
    local titleLabel = lbl.createFont1(24, title, ccc3(0xff, 0xe3, 0x86))
    titleLabel:setPosition(BG_WIDTH/2, BG_HEIGHT-36)
    bg:addChild(titleLabel)

    -- line
    local line = img.createUISprite(img.ui.help_line)
    line:setScaleX(730/line:getContentSize().width)
    line:setPosition(BG_WIDTH/2, BG_HEIGHT-64)
    bg:addChild(line)

    addBackEvent(self)

    function self.onAndroidBack()
        self:removeFromParent()
    end

    self:registerScriptHandler(function(event)
        if event == "enter" then
            self.notifyParentLock()
        elseif event == "exit" then
            self.notifyParentUnlock()
        end
    end)

    self:setTouchEnabled(true)
    self:setTouchSwallowEnabled(true)

    --detail
    local function showItem(itemBg, itemData)
        if not itemData or not itemData.logo then
            return
        end
        -- body
        local showHead = img.createGFlag(itemData.logo)
        showHead:setScale(0.55)
        itemBg:addChild(showHead)
        droidhangComponents:mandateNode(showHead, "FwkG_1MPPQq")
    
        local showName = lbl.createFontTTF(14, itemData.name, ccc3(0x72, 0x48, 0x35))
        showName:setAnchorPoint(ccp(0, 0.5))
        itemBg:addChild(showName)
        droidhangComponents:mandateNode(showName, "FwkG_FUgf83")

        local serverBg = img.createUISprite(img.ui.anrea_server_bg)
        serverBg:setScale(0.6)
        itemBg:addChild(serverBg)
        droidhangComponents:mandateNode(serverBg, "FwkG_2xcuvx")

        local serverLabel = lbl.createFont1(16, getSidname(itemData.sid), ccc3(255, 251, 215))
        serverLabel:setPosition(serverBg:getContentSize().width * 0.5, serverBg:getContentSize().height * 0.5)
        serverBg:addChild(serverLabel)
    end

    local function findGuild(id)
        return resData.guilds[id]
    end

    local data = {teams = {}, wins = {}, logIds = {}}
    local align = resData.align2 or {}
    if align then
        for i, info in ipairs(align) do
            data.teams[i * 2 - 1] = findGuild(align[i].atk)
            data.teams[i * 2] = findGuild(align[i].def)
            data.wins[i] = align[i].win
            data.logIds[i] = align[i].logid
        end
    end

    local batCount = 4
    if #align < batCount then
        local hashMap = {}
        for _, info in ipairs(align) do
            hashMap[info.atk] = true
            hashMap[info.def] = true
        end

        for i=#align + 1, batCount do
            local itemId
            for idx = 1, batCount * 2 do
                if not hashMap[idx] then
                    itemId = idx
                    break
                end
            end

            if itemId then
                hashMap[itemId] = true
                table.insert(data.teams, findGuild(itemId))
                table.insert(data.teams, {})
                table.insert(data.wins, true)
            else
                table.insert(data.teams, {})
                table.insert(data.teams, {})
            end
        end
    end

    for i = 1, batCount do
        local championBg = img.createUI9Sprite(img.ui.guildFight_bar_bg)
        championBg:setPreferredSize(CCSizeMake(196, 66))
        bg:addChild(championBg, 10)
        droidhangComponents:mandateNode(championBg, string.format("FwkG_pnQl0m%d", i))

        local teamLeftBg = img.createUI9Sprite(img.ui.botton_fram_2)
        teamLeftBg:setPreferredSize(CCSizeMake(196, 66))
        bg:addChild(teamLeftBg, 10)
        droidhangComponents:mandateNode(teamLeftBg, string.format("FwkG_JELXey%d", i))

        local teamRightBg = img.createUI9Sprite(img.ui.botton_fram_2)
        teamRightBg:setPreferredSize(CCSizeMake(196, 66))
        bg:addChild(teamRightBg, 10)
        droidhangComponents:mandateNode(teamRightBg, string.format("FwkG_3kpHBn%d", i))

        if data.wins[i] then
            showItem(championBg, data.teams[i * 2 - 1])
        else
            showItem(championBg, data.teams[i * 2])
        end

        showItem(teamLeftBg, data.teams[i * 2 - 1])
        showItem(teamRightBg, data.teams[i * 2])

        if data.logIds[i] then
            local btnVideoSprite = img.createUISprite(img.ui.arena_button_video)
            local btnVideo = SpineMenuItem:create(json.ui.button, btnVideoSprite)
            btnVideo:setPosition(52, 49)
            local menuVideo = CCMenu:createWithItem(btnVideo)
            menuVideo:setPosition(0, 0)
            bg:addChild(menuVideo, 100)
            btnVideo:registerScriptTapHandler(function()
                audio.play(audio.button)

                local params = {
                    sid = player.sid,
                    log_id = data.logIds[i],
                }

                addWaitNet()
                net:guild_fight_log(params, function(__data)
                    delWaitNet()
                    
                    tbl2string(__data)

                    self:addChild(require("ui.guildFight.videoDetail").create(data.wins[i], data.teams[i*2-1], data.teams[i*2], __data), 100)
                end)
            end)

            droidhangComponents:mandateNode(btnVideo, "TTxM_abvjvi_8_"..i)
        end
    end

    local vecArray = {cc.p(0,0), cc.p(23,0), cc.p(23,-38), cc.p(46,-38), cc.p(46,-22), cc.p(69,-22)}
    local line0 = lineCreate.create(vecArray, data.wins[1] == true)
    bg:addChild(line0)
    droidhangComponents:mandateNode(line0, "iKt6_kF4hVm")

    local vecArray = {cc.p(0,0), cc.p(23,0), cc.p(23,38), cc.p(46,38), cc.p(46,54), cc.p(69,54)}
    local line1 = lineCreate.create(vecArray, data.wins[1] ~= true)
    bg:addChild(line1)
    droidhangComponents:mandateNode(line1, "iKt6_3nqNGx")

    local vecArray = {cc.p(0,0), cc.p(23,0), cc.p(23,-38), cc.p(46,-38), cc.p(46,22), cc.p(69,22)}
    local line2 = lineCreate.create(vecArray, data.wins[2] == true)
    bg:addChild(line2)
    droidhangComponents:mandateNode(line2, "B9RK_0nmrwq")

    local vecArray = {cc.p(0,0), cc.p(23,0), cc.p(23,38), cc.p(46,38), cc.p(46,98), cc.p(69,98)}
    local line3 = lineCreate.create(vecArray, data.wins[2] ~= true)
    bg:addChild(line3)
    droidhangComponents:mandateNode(line3, "B9RK_aqGjXe")

    local vecArray = {cc.p(0,0), cc.p(-23,0), cc.p(-23,-38), cc.p(-46,-38), cc.p(-46,-98), cc.p(-69,-98)}
    local line4 = lineCreate.create(vecArray, data.wins[3] == true)
    bg:addChild(line4)
    droidhangComponents:mandateNode(line4, "x1R2_b5Hpj1")

    local vecArray = {cc.p(0,0), cc.p(-23,0), cc.p(-23,38), cc.p(-46,38), cc.p(-46,-22), cc.p(-69,-22)}
    local line5 = lineCreate.create(vecArray, data.wins[3] ~= true)
    bg:addChild(line5)
    droidhangComponents:mandateNode(line5, "x1R2_XKKdxJ")

    local vecArray = {cc.p(0,0), cc.p(-23,0), cc.p(-23,-38), cc.p(-46,-38), cc.p(-46,-58), cc.p(-69,-58)}
    local line6 = lineCreate.create(vecArray, data.wins[4] == true)
    bg:addChild(line6)
    droidhangComponents:mandateNode(line6, "GBXp_FiOjdx")

    local vecArray = {cc.p(0,0), cc.p(-23,0), cc.p(-23,38), cc.p(-46,38), cc.p(-46,18), cc.p(-69,18)}
    local line7 = lineCreate.create(vecArray, data.wins[4] ~= true)
    bg:addChild(line7)
    droidhangComponents:mandateNode(line7, "GBXp_epHFbO")

    -- local tempBg = cc.Sprite:create("temp.png")
    -- tempBg:setPosition(bg:getContentSize().width * 0.5, bg:getContentSize().height * 0.5)
    -- tempBg:setOpacity(100)
    -- bg:addChild(tempBg)
end

return final_8
