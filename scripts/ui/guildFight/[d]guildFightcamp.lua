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

local function createItem(player, _idx, mask)
    local item = img.createUI9Sprite(img.ui.botton_fram_2)
    item:setPreferredSize(CCSizeMake(574, 102))
    local item_w = item:getContentSize().width
    local item_h = item:getContentSize().height

    local rank = lbl.createFont1(18, "" .. _idx, ccc3(0x51, 0x27, 0x12))
    rank:setPosition(CCPoint(46, item_h/2))
    item:addChild(rank)

    local hids = {}
    local pheroes = player.camp or {}
    for i, v in ipairs(pheroes) do
        hids[v.pos] = v
    end

    local dx = 78
    local sx0 = 115
    local sx1 = sx0 + dx + 90
    local sxAry = {sx0, sx0 + dx, sx1, sx1 + dx, sx1 + dx * 2, sx1 + dx * 3}
    for i=1, 6 do
        local showHero

        local hideFlag = false
        if mask then
            for _, uid in ipairs(mask) do
                if uid == player.uid then
                    hideFlag = true
                    break
                end
            end
        end

        if hideFlag then
            showHero = img.createUISprite(img.ui.herolist_head_bg)
            local icon = img.createUISprite(img.ui.arena_new_question)
            icon:setPosition(showHero:getContentSize().width * 0.5, showHero:getContentSize().height * 0.5)
            showHero:addChild(icon)
        else
            if hids[i] then
                --showHero = img.createHeroHead(hids[i].id, hids[i].lv, true, true, hids[i].wake,nil,require("data.pet").getPetID(hids))
                local param = {
                    id = hids[i].id,
                    lv = hids[i].lv,
                    showGroup = true,
                    showStar = true,
                    wake = hids[i].wake,
                    orangeFx = nil,
                    petID = require("data.pet").getPetID(hids),
                    hskills = hids[i].hskills,
                    skin = hids[i].skin,
                }
                showHero = img.createHeroHeadByParam(param)
            else
                showHero = img.createUISprite(img.ui.herolist_head_bg)
            end
        end

        showHero:setAnchorPoint(ccp(0.5, 0.5))
        showHero:setScale(0.75)
        showHero:setPosition(sxAry[i], item:getContentSize().height * 0.5+1)
        item:addChild(showHero)
    end
    
    return item
end

function ui.create(mbrs, mask)
    local layer = CCLayer:create()
    -- dark bg
    local darkbg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    layer:addChild(darkbg)
    -- board_bg
    local board_bg = img.createUI9Sprite(img.ui.dialog_1)
    board_bg:setPreferredSize(CCSizeMake(664, 552))
    board_bg:setScale(view.minScale)
    board_bg:setPosition(view.midX, view.midY)
    layer:addChild(board_bg)
    local board_bg_w = board_bg:getContentSize().width
    local board_bg_h = board_bg:getContentSize().height

    -- anim
    board_bg:setScale(0.5*view.minScale)
    board_bg:runAction(CCScaleTo:create(0.15, 1*view.minScale, 1*view.minScale))

    -- title
    local lbl_title = lbl.createFont1(24, i18n.global.guildfight_camp.string, ccc3(0xe6, 0xd0, 0xae))
    lbl_title:setPosition(CCPoint(board_bg_w/2, board_bg_h-29))
    board_bg:addChild(lbl_title, 2)
    local lbl_title_shadowD = lbl.createFont1(24, i18n.global.guildfight_camp.string, ccc3(0x59, 0x30, 0x1b))
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
    board:setPreferredSize(CCSizeMake(598, 450))
    board:setAnchorPoint(CCPoint(0.5, 0))
    board:setPosition(CCPoint(board_bg_w/2, 38))
    board_bg:addChild(board)
    local board_w = board:getContentSize().width
    local board_h = board:getContentSize().height

    local function createScroll()
        local scroll_params = {
            width = 604,
            height = 436,
        }
        local lineScroll = require "ui.lineScroll"
        return lineScroll.create(scroll_params)
    end

    local function showList(listObj)
        local scroll = createScroll()
        scroll:setAnchorPoint(CCPoint(0, 0))
        scroll:setPosition(CCPoint(-3, 5))
        board:addChild(scroll)
        board.scroll = scroll
        --drawBoundingbox(board, scroll)
        scroll.addSpace(4)
        for ii=1,#listObj do
            local tmp_item = createItem(listObj[ii], ii, mask)
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

    showList(mbrs)

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
