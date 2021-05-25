local ui = {}

require "common.const"
require "common.func"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local audio = require "res.audio"
local i18n = require "res.i18n"
local tipsequip = require "ui.tips.equip"
local tipsitem = require "ui.tips.item"

-- 背景框大小
local BG_WIDTH   = 710
local BG_HEIGHT  = 512

local function calPercent(list)
    if not list or #list <= 0 then return end
    local base = list[1].hurt
    for ii=1,#list do
        list[ii].percent = list[ii].hurt * 100 / base
    end
end

function ui.create(uiParams)
    local layer = CCLayer:create()

    calPercent(uiParams.data)

    -- dark bg
    local darkbg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    layer:addChild(darkbg)

    -- board
    local board = img.createUI9Sprite(img.ui.tips_bg)
    board:setPreferredSize(CCSize(BG_WIDTH, BG_HEIGHT))
    board:setScale(view.minScale * 0.1)
    board:setAnchorPoint(ccp(0.5,0.5))
    board:setPosition(view.midX, view.midY)
    board:runAction(CCEaseBackOut:create(CCScaleTo:create(0.3, view.minScale)))
    layer:addChild(board)

    local function backEvent()
        audio.play(audio.button)
        layer:removeFromParentAndCleanup(true)
    end
    
    -- closeBtn
    local closeBtn0 = img.createUISprite(img.ui.close)
    local closeBtn = SpineMenuItem:create(json.ui.button, closeBtn0)
    closeBtn:setPosition(BG_WIDTH-23, BG_HEIGHT-26)
    local closeMenu = CCMenu:createWithItem(closeBtn)
    closeMenu:setPosition(0, 0)
    board:addChild(closeMenu)
    closeBtn:registerScriptTapHandler(function()
        backEvent()
    end)

    -- title
    local lbl_title_rank = lbl.createFont1(20, i18n.global.guildvice_dps_rank.string, ccc3(0xf9, 0xe3, 0x9a))
    lbl_title_rank:setPosition(CCPoint(99, 479))
    board:addChild(lbl_title_rank)
    local lbl_title_dps = lbl.createFont1(20, i18n.global.guildvice_dps_hurt.string, ccc3(0xf9, 0xe3, 0x9a))
    lbl_title_dps:setPosition(CCPoint(320, 479))
    board:addChild(lbl_title_dps)
    local lbl_title_reward = lbl.createFont1(20, i18n.global.guildvice_dps_reward.string, ccc3(0xf9, 0xe3, 0x9a))
    lbl_title_reward:setPosition(CCPoint(578, 479))
    board:addChild(lbl_title_reward)

    local lineScroll = require "ui.lineScroll"
    local scroll_params = {
        width = BG_WIDTH,
        height = 445,
    }
    local scroll = lineScroll.create(scroll_params)
    scroll:setAnchorPoint(CCPoint(0, 0))
    scroll:setPosition(CCPoint(0, 9))
    board:addChild(scroll)

    local function createItem(itemObj, rank)
        local item = CCSprite:create()
        item:setContentSize(CCSizeMake(704, 74))
        local item_l = img.createUISprite(img.ui.fight_hurts_bg_2)
        item_l:setAnchorPoint(CCPoint(1, 0))
        item_l:setPosition(CCPoint(352, 0))
        item:addChild(item_l)
        local item_r = img.createUISprite(img.ui.fight_hurts_bg_2)
        item_r:setFlipX(true)
        item_r:setAnchorPoint(CCPoint(0, 0))
        item_r:setPosition(CCPoint(352, 0))
        item:addChild(item_r)
        if rank%2 == 1 then
            item_l:setOpacity(0.7*255)
            item_r:setOpacity(0.7*255)
        end
        local item_w = item:getContentSize().width
        local item_h = item:getContentSize().height
        local tmp_rank
        if rank == 1 then
            tmp_rank = img.createUISprite(img.ui.arena_rank_1)
        elseif rank == 2 then
            tmp_rank = img.createUISprite(img.ui.arena_rank_2)
        elseif rank == 3 then
            tmp_rank = img.createUISprite(img.ui.arena_rank_3)
        else
            tmp_rank = lbl.createFont1(16, "" .. rank, ccc3(0xff, 0xff, 0xff))
        end
        tmp_rank:setPosition(CCPoint(55, item_h/2))
        item:addChild(tmp_rank)
        -- head
        local head = img.createPlayerHead(itemObj.logo)
        head:setScale(0.65)
        head:setPosition(CCPoint(125, item_h/2+1))
        item:addChild(head)
        -- pgb
        local pgb_bg = img.createUI9Sprite(img.ui.fight_hurts_bar_bg)
        pgb_bg:setPreferredSize(CCSize(276, 19))
        pgb_bg:setPosition(CCPoint(320, 21))
        item:addChild(pgb_bg)
        local pgb_fg = img.createUISprite(img.ui.guildvice_dps_fg)
        local pgb = createProgressBar(pgb_fg)
        pgb:setPosition(CCPoint(pgb_bg:getContentSize().width/2, pgb_bg:getContentSize().height/2))
        pgb_bg:addChild(pgb)
        pgb:setPercentage(itemObj.percent)
        -- name
        local lbl_mem_name = lbl.createFontTTF(20, itemObj.name)
        lbl_mem_name:setAnchorPoint(CCPoint(0, 0.5))
        lbl_mem_name:setPosition(CCPoint(183, 55))
        item:addChild(lbl_mem_name)
        -- hurts
        local lbl_hurt = lbl.createFont2(16, "" .. itemObj.hurt, ccc3(0xf8, 0xf2, 0xe2))
        lbl_hurt:setAnchorPoint(CCPoint(1, 0.5))
        lbl_hurt:setPosition(CCPoint(352, item_h/2-9))
        item:addChild(lbl_hurt)
        -- reward
        local r_container = CCSprite:create()
        r_container:setContentSize(CCSizeMake(189, 62))
        r_container:setPosition(CCPoint(578, item_h/2))
        item:addChild(r_container)
        local rewards = pbbag2reward(itemObj.reward)
        for ii=1,#rewards do
            if rewards[ii].type == 1 then
                local tmp_item0 = img.createItem(rewards[ii].id, rewards[ii].num)
                local tmp_item = CCMenuItemSprite:create(tmp_item0, nil)
                tmp_item:setScale(0.7)
                tmp_item:setPosition(CCPoint((ii-1)*65+31, 31))
                local tmp_item_menu = CCMenu:createWithItem(tmp_item)
                tmp_item_menu:setPosition(CCPoint(0, 0))
                r_container:addChild(tmp_item_menu)
                tmp_item:registerScriptTapHandler(function()
                    audio.play(audio.button)
                    local tmp_tip = tipsitem.createForShow({id=rewards[ii].id})
                    layer:addChild(tmp_tip, 100)
                end)
            elseif rewards[ii].type == 2 then
                local tmp_item0 = img.createEquip(rewards[ii].id, rewards[ii].num)
                local tmp_item = CCMenuItemSprite:create(tmp_item0, nil)
                tmp_item:setScale(0.7)
                tmp_item:setPosition(CCPoint((ii-1)*65+31, 31))
                local tmp_item_menu = CCMenu:createWithItem(tmp_item)
                tmp_item_menu:setPosition(CCPoint(0, 0))
                r_container:addChild(tmp_item_menu)
                tmp_item:registerScriptTapHandler(function()
                    audio.play(audio.button)
                    local tmp_tip = tipsequip.createById(rewards[ii].id)
                    layer:addChild(tmp_tip, 100)
                end)
            end
        end
        return item
    end

    local function showList(listObj)
        if not listObj or #listObj <= 0 then
            --local ui_empty = (require "ui.empty").create({text=i18n.global.empty_guildvice.string, color=ccc3(0xfe, 0xeb, 0xca)})
            --ui_empty:setPosition(CCPoint(355, 256))
            --board:addChild(ui_empty)
            return 
        end
        for ii=1,#listObj do
            local tmp_item = createItem(listObj[ii], ii)
            scroll.addItem(tmp_item)
        end
        scroll.setOffsetBegin()
    end
    showList(uiParams.data)

    layer:setTouchEnabled(true)
    layer:setTouchSwallowEnabled(true)

    return layer
end

return ui
