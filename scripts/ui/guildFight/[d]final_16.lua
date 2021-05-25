local final_16 = class("final_16", function ()
    return cc.LayerColor:create(cc.c4b(0, 0, 0, POPUP_DARK_OPACITY))
end)

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


function final_16.create(uiParams)
    return final_16.new(uiParams)
end

local space_height = 0

function final_16:ctor(resData)
    local BG_WIDTH = 786
    local BG_HEIGHT = 470

    --self:setScale(view.minScale)
    --self:ignoreAnchorPointForPosition(false)
    --self:setAnchorPoint(cc.p(0.5, 0.5))
    --self:setPosition(scalep(480, 288))

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
    local title = i18n.global.guildFight_final_16_8.string
    local titleLabel = lbl.createFont1(24, title, ccc3(0xff, 0xe3, 0x86))
    titleLabel:setPosition(BG_WIDTH/2, BG_HEIGHT-36)
    bg:addChild(titleLabel)

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

    local function findGuild(id)
        return resData.guilds[id] or {}
    end

    local data = {teams = {}, wins = {}, logIds = {}}
    local align = resData.align1 or {}
    if align then
        for i, info in ipairs(align) do
            data.teams[i * 2 - 1] = findGuild(align[i].atk)
            data.teams[i * 2] = findGuild(align[i].def)
            data.wins[i] = align[i].win
            data.logIds[i] = align[i].logid
        end
    end

    local batCount = 8
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

    local function createScroll()
        local scroll_params = {
            width = 760,
            height = 400,
        }
        local lineScroll = require "ui.lineScroll"
        return lineScroll.create(scroll_params)
    end

    local function createItem(_idx)
        local item = img.createUISprite(img.ui.fight_hurts_bg_2)
        --item:setPreferredSize(CCSizeMake(376, 74))
        local item_w = item:getContentSize().width
        local item_h = item:getContentSize().height
        local item1 = CCSprite:create()
        local item2 = img.createUISprite(img.ui.fight_hurts_bg_2)
        --item2:setScaleX(376/352)
        --item2:setScaleY(74/81)
        item2:setAnchorPoint(0,0.5)
        item2:setPosition(352, item_h/2)
        item2:setFlipX(true)
        item:addChild(item2)
        
        if _idx%2 == 0 then
            item:setOpacity(70)
            item2:setOpacity(70)
        end

        local line = img.createUISprite(img.ui.guildFight_line168)
        line:setPosition(344, item_h/2)
        item:addChild(line)

        -- logo
        local llogo = img.createGFlag(data.teams[_idx*2-1].logo)
        llogo:setScale(0.8)
        llogo:setPosition(44, item_h/2)
        item:addChild(llogo)
        if data.teams[_idx*2].logo then
            local rlogo = img.createGFlag(data.teams[_idx*2].logo)
            rlogo:setScale(0.8)
            rlogo:setPosition(644, item_h/2)
            item:addChild(rlogo)

            local rname = lbl.createMixFont1(16, data.teams[_idx*2].name, ccc3(255, 246, 223))
            rname:setAnchorPoint(1, 0.5)
            rname:setPosition(644-48-3, 56)
            item:addChild(rname)

            local rsevbg = img.createUISprite(img.ui.anrea_server_bg)
            rsevbg:setScale(0.9)
            rsevbg:setPosition(644-70, 30)
            item:addChild(rsevbg)
            local rsevlab = lbl.createFont1(16, getSidname(data.teams[_idx*2].sid), ccc3(0xf7, 0xea, 0xd1))
            rsevlab:setPosition(rsevbg:getContentSize().width/2, rsevbg:getContentSize().height/2)
            rsevbg:addChild(rsevlab)
        end

        --name
        local lname = lbl.createMixFont1(16, data.teams[_idx*2-1].name, ccc3(255, 246, 223))
        lname:setAnchorPoint(0, 0.5)
        lname:setPosition(92, 56)
        item:addChild(lname)

        -- server
        local lsevbg = img.createUISprite(img.ui.anrea_server_bg)
        lsevbg:setScale(0.9)
        lsevbg:setPosition(114, 30)
        item:addChild(lsevbg)
        local lsevlab = lbl.createFont1(16, string.format("S%d", data.teams[_idx*2-1].sid), ccc3(0xf7, 0xea, 0xd1))
        lsevlab:setPosition(lsevbg:getContentSize().width/2, lsevbg:getContentSize().height/2)
        lsevbg:addChild(lsevlab)

        -- win
        local lshowResult = nil
        local rshowResult = nil
        if data.wins[_idx] == true then
            lshowResult = img.createUISprite(img.ui.arena_icon_win)
            rshowResult = img.createUISprite(img.ui.arena_icon_lost)
        else
            lshowResult = img.createUISprite(img.ui.arena_icon_lost)
            rshowResult = img.createUISprite(img.ui.arena_icon_win)
        end
        lshowResult:setPosition(300, item_h/2)
        item:addChild(lshowResult)
        if data.teams[_idx*2].logo then
            rshowResult:setPosition(644-256, item_h/2)
            item:addChild(rshowResult)
        end

        if data.teams[_idx*2].logo and data.logIds[_idx] then
            local btnVideoSprite = img.createUISprite(img.ui.arena_button_video)
            local btnVideo = SpineMenuItem:create(json.ui.button, btnVideoSprite)
            btnVideo:setPosition(714, item_h/2)
            local menuVideo = CCMenu:createWithItem(btnVideo)
            menuVideo:setPosition(0, 0)
            item:addChild(menuVideo, 100)
            btnVideo:registerScriptTapHandler(function()
                audio.play(audio.button)

                local params = {
                   sid = player.sid,
                   log_id = data.logIds[_idx],
                }

                addWaitNet()
                net:guild_fight_log(params, function(__data)
                   delWaitNet()
                    
                   tbl2string(__data)

                   self:addChild(require("ui.guildFight.videoDetail").create(data.wins[_idx], data.teams[_idx*2-1], data.teams[_idx*2], __data), 100)
                end)
            end)
        end

        return item
    end

    local tlayer = CCLayer:create()
    local scroll = createScroll()
    scroll:setAnchorPoint(CCPoint(0, 0))
    scroll:setPosition(CCPoint(0, 8))
    bg:addChild(scroll)
    --board.scroll = scroll
    -- drawBoundingbox(bg, scroll)
    scroll.addSpace(4)
    for i=1, batCount do
        if data.teams[i*2-1].logo then
            local tmp_item = createItem(i)
            tmp_item.ax = 1
            tmp_item.px = 365
            scroll.addItem(tmp_item)
            if ii ~= batCount then
                scroll.addSpace(space_height)
            end
        end
    end
    scroll.setOffsetBegin()
end

return final_16
