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
    local item = img.createUI9Sprite(img.ui.botton_fram_2)
    item:setPreferredSize(CCSizeMake(575, 82))
    local item_w = item:getContentSize().width
    local item_h = item:getContentSize().height

    -- rank 
    local rank
    if _idx < 4 then
        rank = img.createUISprite(icon_rank[_idx])
    else
        rank = lbl.createFont1(18, "" .. _idx, ccc3(0x51, 0x27, 0x12))
    end
    rank:setPosition(CCPoint(46, item_h/2))
    item:addChild(rank)
    ---- flag
    local flag = img.createPlayerHead(guildObj.logo)
    flag:setScale(0.7)
    flag:setPosition(CCPoint(117, item_h/2))
    item:addChild(flag)

    -- name
    local lbl_name = lbl.createFontTTF(20, guildObj.name, ccc3(0x51, 0x27, 0x12))
    lbl_name:setAnchorPoint(CCPoint(0, 0))
    lbl_name:setPosition(CCPoint(220, item:getContentSize().height/2 - 12))
    item:addChild(lbl_name)

    local lvbottom = img.createUISprite(img.ui.main_lv_bg)
    lvbottom:setPosition(CCPoint(175, item:getContentSize().height/2))
    item:addChild(lvbottom)
    local lvlab = lbl.createFont1(14, string.format("%d", guildObj.lv), ccc3(255, 246, 223))
    lvlab:setPosition(CCPoint(lvbottom:getContentSize().width/2, 
                                    lvbottom:getContentSize().height/2))
    lvbottom:addChild(lvlab)

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
        local rank
        if guildObj.rank < 4 then
            rank = img.createUISprite(icon_rank[guildObj.rank])
        else
            rank = lbl.createFont1(18, "" .. guildObj.rank, ccc3(0x51, 0x27, 0x12))
        end
        rank:setPosition(CCPoint(offset_x+46, item_h/2))
        item:addChild(rank)
        
    end
    -- flag
    local flag = img.createPlayerHead(guildObj.logo)
    flag:setScale(0.7)
    flag:setPosition(CCPoint(offset_x+117, item_h/2))
    item:addChild(flag)

    -- name
    local lbl_name = lbl.createFontTTF(18, guildObj.name, ccc3(0x51, 0x27, 0x12))
    lbl_name:setAnchorPoint(CCPoint(0, 0))
    lbl_name:setPosition(CCPoint(220, item:getContentSize().height/2 - 12))
    item:addChild(lbl_name)

    -- lv
    local lvbottom = img.createUISprite(img.ui.main_lv_bg)
    lvbottom:setPosition(CCPoint(190, item:getContentSize().height/2))
    item:addChild(lvbottom)
    local lvlab = lbl.createFont1(14, string.format("%d", guildObj.lv), ccc3(255, 246, 223))
    lvlab:setPosition(CCPoint(lvbottom:getContentSize().width/2, 
                                    lvbottom:getContentSize().height/2))
    lvbottom:addChild(lvlab)

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
    local lbl_title = lbl.createFont1(24, i18n.global.friendboss_integral_rank.string, ccc3(0xe6, 0xd0, 0xae))
    lbl_title:setPosition(CCPoint(board_bg_w/2, board_bg_h-29))
    board_bg:addChild(lbl_title, 2)
    local lbl_title_shadowD = lbl.createFont1(24, i18n.global.friendboss_integral_rank.string, ccc3(0x59, 0x30, 0x1b))
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
            height = 320,
        }
        local lineScroll = require "ui.lineScroll"
        return lineScroll.create(scroll_params)
    end

    local function showList(listObj)
        local scroll = createScroll()
        scroll:setAnchorPoint(CCPoint(0, 0))
        scroll:setPosition(CCPoint(0, 82))
        board:addChild(scroll)
        board.scroll = scroll
        --drawBoundingbox(board, scroll)
        scroll.addSpace(4)
        for ii=1,#listObj-1 do
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
            sid = player.sid,
            uid = player.uid,
        }
        addWaitNet()
        net:frd_boss_rank(gParams, function(__data)
            delWaitNet()
            tbl2string(__data)
            if #__data.assits > 1 then
                showList(__data.assits or {})
                -- self
                --if __data.assits[#__data.assits].score > 0 then
                --end
            end
            local self_item = createSelfItem(__data.assits[#__data.assits])
            self_item:setPosition(CCPoint(board_w/2, 36))
            board:addChild(self_item, 3)
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
