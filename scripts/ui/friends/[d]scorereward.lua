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
local cfgassist = require "config.assistrank"
local player = require "data.player"
local i18n = require "res.i18n"
local tipsequip = require "ui.tips.equip"
local tipsitem = require "ui.tips.item"
local friendboss = require "data.friendboss"

local space_height = 1

local icon_rank = {
    [1] = img.ui.arena_rank_1,
    [2] = img.ui.arena_rank_2,
    [3] = img.ui.arena_rank_3,
}

local function createItem(rewardObj, _idx, layer, currank)
    local item = img.createUI9Sprite(img.ui.botton_fram_2)
    item:setPreferredSize(CCSizeMake(575, 82))
    local item_w = item:getContentSize().width
    local item_h = item:getContentSize().height

    -- rank 
    local rank
    if _idx < 4 then
        rank = img.createUISprite(icon_rank[_idx])
    else
        --rank = lbl.createFont1(18, "" .. _idx, ccc3(0x51, 0x27, 0x12))
        rank = lbl.createFont1(18, currank+1 .. "-" .. rewardObj.rank, ccc3(0x51, 0x27, 0x12))
    end
    rank:setPosition(CCPoint(60, item_h/2))
    item:addChild(rank)

    local offset_x = 155
    for i=1,#rewardObj.rewards do
        local tmp_item
        local itemObj = rewardObj.rewards[i]
        if itemObj.type == 1 then  -- item
            local tmp_item0 = img.createItem(itemObj.id, itemObj.num)
            tmp_item = SpineMenuItem:create(json.ui.button, tmp_item0)
        elseif itemObj.type == 2 then  -- equip
            local tmp_item0 = img.createEquip(itemObj.id, itemObj.num)
            tmp_item = SpineMenuItem:create(json.ui.button, tmp_item0)
        end
        
        tmp_item:setScale(0.7)
        tmp_item:setPosition(CCPoint(offset_x+(i-1)*70, item_h/2))
        local tmp_item_menu = CCMenu:createWithItem(tmp_item)
        tmp_item_menu:setPosition(CCPoint(0, 0))
        item:addChild(tmp_item_menu)

        tmp_item:registerScriptTapHandler(function()
            audio.play(audio.button)
            local tmp_tip
            if itemObj.type == 1 then  -- item
                tmp_tip = tipsitem.createForShow({id=itemObj.id})
                layer:addChild(tmp_tip, 100)
            elseif itemObj.type == 2 then  -- equip
                tmp_tip = tipsequip.createById(itemObj.id)
                layer:addChild(tmp_tip, 100)
            end
            tmp_tip.setClickBlankHandler(function()
                tmp_tip:removeFromParentAndCleanup(true)
            end)
        end)
    end

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
    local lbl_title = lbl.createFont1(24, i18n.global.friendboss_integral_reward.string, ccc3(0xe6, 0xd0, 0xae))
    lbl_title:setPosition(CCPoint(board_bg_w/2, board_bg_h-29))
    board_bg:addChild(lbl_title, 2)
    local lbl_title_shadowD = lbl.createFont1(24, i18n.global.friendboss_integral_reward.string, ccc3(0x59, 0x30, 0x1b))
    lbl_title_shadowD:setPosition(CCPoint(board_bg_w/2, board_bg_h-31))
    board_bg:addChild(lbl_title_shadowD)

    json.load(json.ui.clock)
    local clockIcon = DHSkeletonAnimation:createWithKey(json.ui.clock)
    clockIcon:scheduleUpdateLua()
    clockIcon:playAnimation("animation", -1)
    clockIcon:setPosition(42, 430)
    board_bg:addChild(clockIcon, 100)

    local timeLab = string.format("%02d:%02d:%02d",math.floor(0/3600),math.floor((0%3600)/60),math.floor(0%60))
    local showTimeLab = lbl.createFont2(16, "", ccc3(0xa5, 0xfd, 0x47))
    showTimeLab:setAnchorPoint(0, 0.5)
    showTimeLab:setPosition(67, 430)
    board_bg:addChild(showTimeLab)
    
    local rewardLab = lbl.createMixFont1(16, i18n.global.friendboss_score_text.string, ccc3(0x73, 0x3b, 0x05))
    rewardLab:setAnchorPoint(0, 0.5)
    rewardLab:setPosition(150, 430)
    board_bg:addChild(rewardLab)

    -- todo
    rewardLab:setVisible(false)

    local function onUpdate(ticks)
        if friendboss.rcd then
            cd = math.max(0, friendboss.rcd + friendboss.pull_time - os.time())
            if cd > 0 then
                timeLab = string.format("%02d:%02d:%02d",math.floor(cd/3600),math.floor((cd%3600)/60),math.floor(cd%60))
                showTimeLab:setString(timeLab)
            else
                friendboss.rcd = friendboss.rcd + 7*24*3600 
                timeLab = string.format("%02d:%02d:%02d",math.floor(cd/3600),math.floor((cd%3600)/60),math.floor(cd%60))
                showTimeLab:setString(timeLab)
            end
        end
    end
    layer:scheduleUpdateWithPriorityLua(onUpdate, 0)

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
    board:setPreferredSize(CCSizeMake(604, 360))
    board:setAnchorPoint(CCPoint(0.5, 0))
    board:setPosition(CCPoint(board_bg_w/2, 38))
    board_bg:addChild(board)
    local board_w = board:getContentSize().width
    local board_h = board:getContentSize().height

    local function createScroll()
        local scroll_params = {
            width = 604,
            height = 350,
        }
        local lineScroll = require "ui.lineScroll"
        return lineScroll.create(scroll_params)
    end

    local function showList(listObj)
        local scroll = createScroll()
        scroll:setAnchorPoint(CCPoint(0, 0))
        scroll:setPosition(CCPoint(0, 2))
        board:addChild(scroll)
        board.scroll = scroll
        --drawBoundingbox(board, scroll)
        scroll.addSpace(4)
        for ii=1,#listObj do
            local tmp_item = nil
            if ii > 2 then 
                tmp_item = createItem(listObj[ii], ii, layer, listObj[ii-1].rank)
            else
                tmp_item = createItem(listObj[ii], ii, layer)
            end
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
    showList(cfgassist or {})

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

