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

local final_2 = class("final_2", function ()
	return cc.LayerColor:create(cc.c4b(0, 0, 0, POPUP_DARK_OPACITY))
end)

function final_2.create(uiParams)
	return final_2.new(uiParams)
end

function final_2:ctor(resData)
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
    local title = i18n.global.guildFight_final_2_1.string
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
    local championBg = img.createUI9Sprite(img.ui.guildFight_champion_bg)
    bg:addChild(championBg, 10)
    droidhangComponents:mandateNode(championBg, "vf8U_66TWCh")

    local teamLeftBg = img.createUI9Sprite(img.ui.guildFight_bar_bg)
    teamLeftBg:setPreferredSize(CCSizeMake(286, 124))
    bg:addChild(teamLeftBg, 10)
    droidhangComponents:mandateNode(teamLeftBg, "zFFL_7ohsyz")

    local teamRightBg = img.createUI9Sprite(img.ui.guildFight_bar_bg)
    teamRightBg:setPreferredSize(CCSizeMake(286, 124))
    bg:addChild(teamRightBg, 10)
    droidhangComponents:mandateNode(teamRightBg, "Va4x_U08qgH")

    local function showItem(itemBg, itemData)
    	if not itemData or not itemData.logo then
            return
        end

    	-- body
    	local showHead = img.createGFlag(itemData.logo)
        showHead:setScale(0.8)
        itemBg:addChild(showHead)
        droidhangComponents:mandateNode(showHead, "rMQ4_tvyxAT")
    
        local showName = lbl.createFontTTF(18, itemData.name, ccc3(0x72, 0x48, 0x35))
        showName:setAnchorPoint(ccp(0, 0.5))
        itemBg:addChild(showName)
        droidhangComponents:mandateNode(showName, "rMQ4_A269NH")

        local serverBg = img.createUISprite(img.ui.anrea_server_bg)
        itemBg:addChild(serverBg)
        droidhangComponents:mandateNode(serverBg, "rMQ4_Xu1oZv")

        local serverLabel = lbl.createFont1(16, getSidname(itemData.sid), ccc3(255, 251, 215))
        serverLabel:setPosition(serverBg:getContentSize().width * 0.5, serverBg:getContentSize().height * 0.5)
        serverBg:addChild(serverLabel)
    end

    local data = {}

    local function findGuild(id)
        return resData.guilds[id]
    end

    local align4 = resData.align4 or {}
    if align4 then
        data.teams = {findGuild(align4[1].atk), findGuild(align4[1].def)}
        data.wins = {align4[1].win}
        data.logIds = {align4[1].logid}
    else
        data.teams = {{}, {}}
    end

    if data.wins[1] then
    	showItem(championBg, data.teams[1])
    else
    	showItem(championBg, data.teams[2])
    end

    showItem(teamLeftBg, data.teams[1])
    showItem(teamRightBg, data.teams[2])

    local vecArray = {cc.p(0,0), cc.p(0,26), cc.p(180,26), cc.p(180,52)}
    local lineLeft = lineCreate.create(vecArray, data.wins[1] == true)
    bg:addChild(lineLeft)
    droidhangComponents:mandateNode(lineLeft, "I4xM_WAmyZ2_xx")

    local vecArray = {cc.p(0,0), cc.p(0,26), cc.p(-180,26), cc.p(-180,52)}
    local lineRight = lineCreate.create(vecArray, data.wins[1] ~= true)
    bg:addChild(lineRight)
    droidhangComponents:mandateNode(lineRight, "I4xM_abvjvi")

    if data.logIds then
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
                log_id = data.logIds[1],
            }

            addWaitNet()
            net:guild_fight_log(params, function(__data)
                delWaitNet()
                
                tbl2string(__data)

                self:addChild(require("ui.guildFight.videoDetail").create(data.wins[1], data.teams[1], data.teams[2], __data), 100)
            end)
        end)

        droidhangComponents:mandateNode(btnVideo, "TTxM_abvjvi")
    end

    -- local tempBg = cc.Sprite:create("temp.png")
    -- tempBg:setPosition(bg:getContentSize().width * 0.5, bg:getContentSize().height * 0.5)
    -- tempBg:setOpacity(100)
    -- bg:addChild(tempBg, 20)
end

return final_2
