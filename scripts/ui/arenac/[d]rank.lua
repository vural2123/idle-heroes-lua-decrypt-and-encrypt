local ui = {}

require "common.func"
require "common.const"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local audio = require "res.audio"
local cfgitem = require "config.item"
local cfgequip = require "config.equip"
local player = require "data.player"
local i18n = require "res.i18n"
local tipsequip = require "ui.tips.equip"
local tipsitem = require "ui.tips.item"
local net = require "net.netClient"

local space_height = 1

local icon_rank = {
    [1] = img.ui.arena_rank_1,
    [2] = img.ui.arena_rank_2,
    [3] = img.ui.arena_rank_3,
}

local function createItem(guildObj, _idx)
    local IMG = { img.ui.arena_frame1, img.ui.arena_frame3, img.ui.arena_frame5 }

    local item
    -- rank 
    local rank
    if _idx < 4 then
        item = img.createUI9Sprite(IMG[_idx])
        rank = img.createUISprite(icon_rank[_idx])
    else
        item = img.createUI9Sprite(img.ui.botton_fram_2)
        rank = lbl.createFont1(18, "" .. _idx, ccc3(0x51, 0x27, 0x12))
    end
    item:setPreferredSize(CCSizeMake(575, 82))
    local item_w = item:getContentSize().width
    local item_h = item:getContentSize().height

    rank:setPosition(CCPoint(46, item_h/2))
    item:addChild(rank)
    ---- flag
    --local flag = img.createPlayerHeadForArena(guildObj.logo, guildObj.lv)
    --flag:setScale(0.7)
    --flag:setPosition(CCPoint(117, item_h/2))
    --item:addChild(flag)
    for j=1,#guildObj.mbrs do
        local playerHead = img.createPlayerHead(guildObj.mbrs[j].logo, guildObj.mbrs[j].lv)
        playerHead:setScale(0.66)
        playerHead:setPosition(98+(j-1)*60, item:getContentSize().height/2+1)
        item:addChild(playerHead)
    end

    -- name
    local lbl_name = lbl.createFontTTF(16, guildObj.name, ccc3(0x51, 0x27, 0x12))
    lbl_name:setAnchorPoint(CCPoint(0, 0))
    lbl_name:setPosition(CCPoint(257, 49))
    item:addChild(lbl_name)

    local showPowerBg = img.createUI9Sprite(img.ui.arena_frame7)
    showPowerBg:setPreferredSize(CCSize(130, 28))
    showPowerBg:setAnchorPoint(ccp(0, 0))
    showPowerBg:setPosition(259, 18)
    item:addChild(showPowerBg)
    local showPowerIcon = img.createUISprite(img.ui.power_icon)
    showPowerIcon:setScale(0.45)
    showPowerIcon:setPosition(270, 33)
    item:addChild(showPowerIcon)
    local showPower = lbl.createFont2(16, guildObj.power)
    showPower:setAnchorPoint(ccp(0, 0))
    showPower:setPosition(300, 22)
    item:addChild(showPower)

    local serverBg = img.createUISprite(img.ui.anrea_server_bg)
    serverBg:setScale(0.78)
    serverBg:setPosition(430, 84 * 0.5)
    item:addChild(serverBg)
    local serverLabel = lbl.createFont1(16, getSidname(guildObj.sid), ccc3(255, 251, 215))
    serverLabel:setPosition(serverBg:getContentSize().width * 0.5, serverBg:getContentSize().height * 0.5)
    serverBg:addChild(serverLabel)

    -- score
    local lbl_lv_des = lbl.createFont1(14, i18n.global.arena_main_score.string, ccc3(0x8a, 0x60, 0x4c))
    lbl_lv_des:setPosition(CCPoint(517, 53))
    item:addChild(lbl_lv_des)
    local lbl_lv = lbl.createFont1(24, guildObj.score, ccc3(0x9c, 0x45, 0x2d))
    lbl_lv:setPosition(CCPoint(517, 32))
    item:addChild(lbl_lv)

    return item
end

local function createSelfItem(guildObj, _idx)
    local item = img.createUI9Sprite(img.ui.item_yellow)
    item:setPreferredSize(CCSizeMake(606, 82))
    local item_w = item:getContentSize().width
    local item_h = item:getContentSize().height

    local offset_x = 13
    if guildObj.score > 0 then
        -- rank 
        --local rank
        --if guildObj.rank < 4 then
        --    rank = img.createUISprite(icon_rank[guildObj.rank])
        --else
        --    rank = lbl.createFont1(18, "" .. guildObj.rank, ccc3(0x51, 0x27, 0x12))
        --end
        --rank:setPosition(CCPoint(offset_x+46, item_h/2))
        --item:addChild(rank)
        
    end

    for j=1,#guildObj.mbrs do
        local playerHead = img.createPlayerHead(guildObj.mbrs[j].logo, guildObj.mbrs[j].lv)
        playerHead:setScale(0.66)
        playerHead:setPosition(98+(j-1)*60, item:getContentSize().height/2+1)
        item:addChild(playerHead)
    end

    -- name
    local lbl_name = lbl.createFontTTF(18, guildObj.name, ccc3(0x51, 0x27, 0x12))
    lbl_name:setAnchorPoint(CCPoint(0, 0))
    lbl_name:setPosition(CCPoint(257, 49))
    item:addChild(lbl_name)

    local showPowerBg = img.createUI9Sprite(img.ui.arena_frame7)
    showPowerBg:setPreferredSize(CCSize(130, 28))
    showPowerBg:setAnchorPoint(ccp(0, 0))
    showPowerBg:setPosition(259, 18)
    item:addChild(showPowerBg)
    local showPowerIcon = img.createUISprite(img.ui.power_icon)
    showPowerIcon:setScale(0.45)
    showPowerIcon:setPosition(270, 33)
    item:addChild(showPowerIcon)
    local showPower = lbl.createFont2(16, guildObj.power)
    showPower:setAnchorPoint(ccp(0, 0))
    showPower:setPosition(300, 22)
    item:addChild(showPower)

    -- score
    local lbl_lv_des = lbl.createFont1(14, i18n.global.arena_main_score.string, ccc3(0x8a, 0x60, 0x4c))
    lbl_lv_des:setPosition(CCPoint(530, 53))
    item:addChild(lbl_lv_des)
    local lbl_lv = lbl.createFont1(22, guildObj.score, ccc3(0x9c, 0x45, 0x2d))
    lbl_lv:setPosition(CCPoint(530, 32))
    item:addChild(lbl_lv)

    return item
end

function ui.create()
    local layer = CCLayer:create()
    -- dark bg
    local darkbg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    layer:addChild(darkbg)
    -- board_bg
    local board_bg = img.createUI9Sprite(img.ui.dialog_1)
    board_bg:setPreferredSize(CCSizeMake(662, 514))
    board_bg:setScale(view.minScale)
    board_bg:setPosition(view.midX, view.midY)
    layer:addChild(board_bg)
    local board_bg_w = board_bg:getContentSize().width
    local board_bg_h = board_bg:getContentSize().height

    -- anim
    board_bg:setScale(0.5*view.minScale)
    board_bg:runAction(CCScaleTo:create(0.15, 1*view.minScale, 1*view.minScale))

    -- title
    local lbl_title = lbl.createFont1(24, i18n.global.arena_hisrank_title.string, ccc3(0xe6, 0xd0, 0xae))
    lbl_title:setPosition(CCPoint(board_bg_w/2, board_bg_h-29))
    board_bg:addChild(lbl_title, 2)
    local lbl_title_shadowD = lbl.createFont1(24, i18n.global.arena_hisrank_title.string, ccc3(0x59, 0x30, 0x1b))
    lbl_title_shadowD:setPosition(CCPoint(board_bg_w/2, board_bg_h-31))
    board_bg:addChild(lbl_title_shadowD)

    local function backEvent()
        audio.play(audio.button)
        layer:removeFromParentAndCleanup(true)
    end
    -- btn_close
    local btn_close0 = img.createUISprite(img.ui.close)
    local btn_close = SpineMenuItem:create(json.ui.button, btn_close0)
    btn_close:setPosition(CCPoint(board_bg_w-25, board_bg_h-28))
    local btn_close_menu = CCMenu:createWithItem(btn_close)
    btn_close_menu:setPosition(CCPoint(0, 0))
    board_bg:addChild(btn_close_menu, 100)
    btn_close:registerScriptTapHandler(function()
        backEvent()
    end)

    -- board
    local board = img.createUI9Sprite(img.ui.inner_bg)
    board:setPreferredSize(CCSizeMake(604, 413))
    board:setAnchorPoint(CCPoint(0.5, 0))
    board:setPosition(CCPoint(board_bg_w/2, 38))
    board_bg:addChild(board)
    local board_w = board:getContentSize().width
    local board_h = board:getContentSize().height

    local function createScroll()
        local scroll_params = {
            width = 604,
            height = 400,
        }
        local lineScroll = require "ui.lineScroll"
        return lineScroll.create(scroll_params)
    end

    local function showList(listObj)
        local scroll = createScroll()
        scroll:setAnchorPoint(CCPoint(0, 0))
        scroll:setPosition(CCPoint(0, 5))
        board:addChild(scroll)
        board.scroll = scroll
        --drawBoundingbox(board, scroll)
        scroll.addSpace(4)
        for ii=1,#listObj do
            local tmp_item = createItem(listObj[ii], ii)
            tmp_item.guildObj = listObj[ii]
            tmp_item.ax = 0.5
            tmp_item.px = 302
            scroll.addItem(tmp_item)
            if ii ~= #listObj then
                scroll.addSpace(space_height)
            end
        end
        scroll.setOffsetBegin()
    end

    local function init()
        local gParams = {
            sid = player.sid + 256,
        }
        addWaitNet()
        net:gpvp_ranklist(gParams, function(__data)
            delWaitNet()
            tbl2string(__data)
            if __data.team then
                showList(__data.team)
            end
            --local self_item = createSelfItem(__data.team[#__data.team])
            --self_item:setPosition(CCPoint(board_w/2, 36))
            --board:addChild(self_item, 3)
        end)
    end
    
    init()

    layer:setTouchEnabled(true)
    layer:setTouchSwallowEnabled(true)

    addBackEvent(layer)
    function layer.onAndroidBack()
        backEvent()
    end
    local function onEnter()
        print("onEnter")
        layer.notifyParentLock()
    end
    local function onExit()
        layer.notifyParentUnlock()
    end
    layer:registerScriptHandler(function(event)
        if event == "enter" then
            onEnter()
        elseif event == "exit" then
            onExit()
        end
    end)

    return layer
end

return ui
