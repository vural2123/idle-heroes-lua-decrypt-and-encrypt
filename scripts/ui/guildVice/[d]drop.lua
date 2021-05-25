local ui = {}

require "common.const"
require "common.func"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local audio = require "res.audio"
local i18n = require "res.i18n"
local cfgguildboss = require "config.guildboss"
local tipsequip = require "ui.tips.equip"
local tipsitem = require "ui.tips.item"

-- 背景框大小
local BG_WIDTH   = 662
local BG_HEIGHT  = 412
local font1 = ccc3(255, 246, 223)

function ui.create(uiParams)
    local bossid = uiParams.bossid
    local cfg = cfgguildboss[bossid]
    local layer = CCLayer:create()

    -- dark bg
    local darkbg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    layer:addChild(darkbg)

    -- bg
    local bg = img.createUI9Sprite(img.ui.tips_bg)
    bg:setPreferredSize(CCSize(BG_WIDTH, BG_HEIGHT))
    bg:setScale(view.minScale * 0.1)
    bg:setAnchorPoint(ccp(0.5,0.5))
    bg:setPosition(view.midX, view.midY)
    bg:runAction(CCEaseBackOut:create(CCScaleTo:create(0.3, view.minScale)))
    layer:addChild(bg)
    
    -- closeBtn
    local closeBtn0 = img.createUISprite(img.ui.close)
    local closeBtn = SpineMenuItem:create(json.ui.button, closeBtn0)
    closeBtn:setPosition(BG_WIDTH-23, BG_HEIGHT-26)
    local closeMenu = CCMenu:createWithItem(closeBtn)
    closeMenu:setPosition(0, 0)
    bg:addChild(closeMenu)
    closeBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer.onAndroidBack()
    end)

    -- title
    local titleLabel = lbl.createFont1(24, i18n.global.guildvice_drop_title.string, ccc3(0xff, 0xe3, 0x86))
    titleLabel:setPosition(BG_WIDTH/2, BG_HEIGHT-36)
    bg:addChild(titleLabel)

    -- line
    local line = img.createUISprite(img.ui.help_line)
    line:setScaleX(610/line:getContentSize().width)
    line:setPosition(BG_WIDTH/2, BG_HEIGHT-64)
    bg:addChild(line)

    local lineScroll = require "ui.lineScroll"
    local scroll_params = {
        width = BG_WIDTH,
        height = 330,
    }
    local scroll = lineScroll.create(scroll_params)
    scroll:setAnchorPoint(CCPoint(0, 0))
    scroll:setPosition(CCPoint(0, 10))
    bg:addChild(scroll)

    local function createBtnItem(itemObj)
        if itemObj.type == 1 then
            local tmp_item0 = img.createItem(itemObj.id, itemObj.num)
            local tmp_item = CCMenuItemSprite:create(tmp_item0, nil)
            tmp_item:setScale(0.7)
            tmp_item:registerScriptTapHandler(function()
                audio.play(audio.button)
                local tmp_tip = tipsitem.createForShow({id=itemObj.id})
                layer:addChild(tmp_tip, 100)
            end)
            return tmp_item
        elseif itemObj.type == 2 then
            local tmp_item0 = img.createEquip(itemObj.id, itemObj.num)
            local tmp_item = CCMenuItemSprite:create(tmp_item0, nil)
            tmp_item:setScale(0.7)
            tmp_item:registerScriptTapHandler(function()
                audio.play(audio.button)
                local tmp_tip = tipsequip.createById(itemObj.id)
                layer:addChild(tmp_tip, 100)
            end)
            return tmp_item
        end
    end

    local offset_x = 44
    scroll.addSpace(9)
    -- plain reward
    local lbl_p_reward = lbl.createFont1(16, i18n.global.guildvice_drop_each.string, font1)
    lbl_p_reward.ax = 0
    lbl_p_reward.px = offset_x
    scroll.addItem(lbl_p_reward)
    scroll.addSpace(8)
    local p_container = CCSprite:create()
    p_container:setContentSize(CCSizeMake(BG_WIDTH, 60))
    p_container.ax = 0
    p_container.px = offset_x
    scroll.addItem(p_container)
    for ii=1,#cfg.reward do
        local tmp_item = createBtnItem(cfg.reward[ii])
        tmp_item:setPosition(CCPoint(30+(ii-1)*65, 30))
        local tmp_item_menu = CCMenu:createWithItem(tmp_item)
        tmp_item_menu:setPosition(CCPoint(0, 0))
        p_container:addChild(tmp_item_menu)
    end
    scroll.addSpace(24)
    -- kill reward
    local lbl_k_reward = lbl.createFont1(16, i18n.global.guildvice_drop_kill.string, font1)
    lbl_k_reward.ax = 0
    lbl_k_reward.px = offset_x
    scroll.addItem(lbl_k_reward)
    scroll.addSpace(8)
    -- rank 1
    local r1_container = CCSprite:create()
    r1_container:setContentSize(CCSizeMake(BG_WIDTH, 60))
    r1_container.ax = 0
    r1_container.px = offset_x
    scroll.addItem(r1_container)
    local rank1_icon = img.createUISprite(img.ui.arena_rank_1)
    rank1_icon:setPosition(CCPoint(20, 30))
    r1_container:addChild(rank1_icon)
    for ii=1,#cfg.final1 do
        local tmp_item = createBtnItem(cfg.final1[ii])
        tmp_item:setPosition(CCPoint(92+(ii-1)*65, 30))
        local tmp_item_menu = CCMenu:createWithItem(tmp_item)
        tmp_item_menu:setPosition(CCPoint(0, 0))
        r1_container:addChild(tmp_item_menu)
    end
    scroll.addSpace(15)
    -- rank 2
    local r2_container = CCSprite:create()
    r2_container:setContentSize(CCSizeMake(BG_WIDTH, 60))
    r2_container.ax = 0
    r2_container.px = offset_x
    scroll.addItem(r2_container)
    local rank2_icon = img.createUISprite(img.ui.arena_rank_2)
    rank2_icon:setPosition(CCPoint(20, 30))
    r2_container:addChild(rank2_icon)
    for ii=1,#cfg.final2 do
        local tmp_item = createBtnItem(cfg.final2[ii])
        tmp_item:setPosition(CCPoint(92+(ii-1)*65, 30))
        local tmp_item_menu = CCMenu:createWithItem(tmp_item)
        tmp_item_menu:setPosition(CCPoint(0, 0))
        r2_container:addChild(tmp_item_menu)
    end
    scroll.addSpace(15)
    -- rank 3
    local r3_container = CCSprite:create()
    r3_container:setContentSize(CCSizeMake(BG_WIDTH, 60))
    r3_container.ax = 0
    r3_container.px = offset_x
    scroll.addItem(r3_container)
    local rank3_icon = img.createUISprite(img.ui.arena_rank_3)
    rank3_icon:setPosition(CCPoint(20, 30))
    r3_container:addChild(rank3_icon)
    for ii=1,#cfg.final3 do
        local tmp_item = createBtnItem(cfg.final3[ii])
        tmp_item:setPosition(CCPoint(92+(ii-1)*65, 30))
        local tmp_item_menu = CCMenu:createWithItem(tmp_item)
        tmp_item_menu:setPosition(CCPoint(0, 0))
        r3_container:addChild(tmp_item_menu)
    end
    scroll.addSpace(15)
    -- rank 4-10
    local r4_container = CCSprite:create()
    r4_container:setContentSize(CCSizeMake(BG_WIDTH, 60))
    r4_container.ax = 0
    r4_container.px = offset_x
    scroll.addItem(r4_container)
    local rank4_icon = lbl.createFont1(16, "4-10")
    rank4_icon:setPosition(CCPoint(20, 30))
    r4_container:addChild(rank4_icon)
    for ii=1,#cfg.final10 do
        local tmp_item = createBtnItem(cfg.final10[ii])
        tmp_item:setPosition(CCPoint(92+(ii-1)*65, 30))
        local tmp_item_menu = CCMenu:createWithItem(tmp_item)
        tmp_item_menu:setPosition(CCPoint(0, 0))
        r4_container:addChild(tmp_item_menu)
    end
    scroll.addSpace(15)
    -- rank 11-15
    local r11_container = CCSprite:create()
    r11_container:setContentSize(CCSizeMake(BG_WIDTH, 60))
    r11_container.ax = 0
    r11_container.px = offset_x
    scroll.addItem(r11_container)
    local rank11_icon = lbl.createFont1(16, "11-15")
    rank11_icon:setPosition(CCPoint(20, 30))
    r11_container:addChild(rank11_icon)
    for ii=1,#cfg.final15 do
        local tmp_item = createBtnItem(cfg.final15[ii])
        tmp_item:setPosition(CCPoint(92+(ii-1)*65, 30))
        local tmp_item_menu = CCMenu:createWithItem(tmp_item)
        tmp_item_menu:setPosition(CCPoint(0, 0))
        r11_container:addChild(tmp_item_menu)
    end
    scroll.addSpace(15)
    -- rank 16-20
    local r16_container = CCSprite:create()
    r16_container:setContentSize(CCSizeMake(BG_WIDTH, 60))
    r16_container.ax = 0
    r16_container.px = offset_x
    scroll.addItem(r16_container)
    local rank16_icon = lbl.createFont1(16, "16-20")
    rank16_icon:setPosition(CCPoint(20, 30))
    r16_container:addChild(rank16_icon)
    for ii=1,#cfg.final20 do
        local tmp_item = createBtnItem(cfg.final20[ii])
        tmp_item:setPosition(CCPoint(92+(ii-1)*65, 30))
        local tmp_item_menu = CCMenu:createWithItem(tmp_item)
        tmp_item_menu:setPosition(CCPoint(0, 0))
        r16_container:addChild(tmp_item_menu)
    end
    scroll.addSpace(15)
    -- rank 21-30
    local r21_container = CCSprite:create()
    r21_container:setContentSize(CCSizeMake(BG_WIDTH, 60))
    r21_container.ax = 0
    r21_container.px = offset_x
    scroll.addItem(r21_container)
    local rank21_icon = lbl.createFont1(16, "21-N")
    rank21_icon:setPosition(CCPoint(20, 30))
    r21_container:addChild(rank21_icon)
    for ii=1,#cfg.final30 do
        local tmp_item = createBtnItem(cfg.final30[ii])
        tmp_item:setPosition(CCPoint(92+(ii-1)*65, 30))
        local tmp_item_menu = CCMenu:createWithItem(tmp_item)
        tmp_item_menu:setPosition(CCPoint(0, 0))
        r21_container:addChild(tmp_item_menu)
    end
    scroll.addSpace(15)

    scroll.setOffsetBegin()

    addBackEvent(layer)

    function layer.onAndroidBack()
        layer:removeFromParent()
    end

    layer:registerScriptHandler(function(event)
        if event == "enter" then
            layer.notifyParentLock()
        elseif event == "exit" then
            layer.notifyParentUnlock()
        end
    end)

    layer:setTouchEnabled(true)
    layer:setTouchSwallowEnabled(true)
    return layer
end

return ui
