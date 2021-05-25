local ui = {}

require "common.func"
require "common.const"
local view = require "common.view"
local img = require "res.img"
local i18n = require "res.i18n"
local lbl = require "res.lbl"
local json = require "res.json"
local audio = require "res.audio"
local cfgitem = require "config.item"
local cfgequip = require "config.equip"
local cfgguildboss = require "config.guildboss"
local player = require "data.player"
local gdata = require "data.guild"
local gbossdata = require "data.gboss"
local i18n = require "res.i18n"
local tipsequip = require "ui.tips.equip"
local tipsitem = require "ui.tips.item"
local dialog = require "ui.dialog"
local rewards = require "ui.reward"
local NetClient = require "net.netClient"
local netClient = NetClient:getInstance()

local cur_page = 1

function ui.create(uiParams)
    local layer = CCLayer:create()
    -- dark bg
    local darkbg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY*0.6))
    layer:addChild(darkbg)
    -- board
    local board = img.createUISprite(img.ui.guildvice_bg)
    board:setScale(view.minScale)
    board:setPosition(CCPoint(view.midX, view.midY))
    layer:addChild(board)
    local board_w = board:getContentSize().width
    local board_h = board:getContentSize().height

    -- title
    local lbl_title = lbl.createFont1(22, i18n.global.guildvice_vice_title.string, ccc3(0xfa, 0xd8, 0x69))
    lbl_title:setPosition(CCPoint(board_w/2, board_h-37))
    board:addChild(lbl_title)

    local function backEvent()
        audio.play(audio.button)
        layer:removeFromParentAndCleanup(true)
    end

    -- btn_close
    local btn_close0 = img.createUISprite(img.ui.close)
    local btn_close = SpineMenuItem:create(json.ui.button, btn_close0)
    btn_close:setPosition(CCPoint(board_w-33, board_h-74))
    local btn_close_menu = CCMenu:createWithItem(btn_close)
    btn_close_menu:setPosition(CCPoint(0, 0))
    board:addChild(btn_close_menu, 100)
    btn_close:registerScriptTapHandler(function()
        backEvent()
    end)

    -- btn_help
    local btn_help0 = img.createUISprite(img.ui.btn_help)
    local btn_help = SpineMenuItem:create(json.ui.button, btn_help0)
    btn_help:setPosition(CCPoint(board_w - 75, board_h - 123))
    local btn_help_menu = CCMenu:createWithItem(btn_help)
    btn_help_menu:setPosition(CCPoint(0, 0))
    board:addChild(btn_help_menu, 100)
    btn_help:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer:addChild((require"ui.help").create(i18n.global.guildvice_help.string), 1000)
    end)

    -- btn_left
    local btn_left0 = img.createUISprite(img.ui.gemstore_next_icon1)
    btn_left0:setFlipX(true)
    local btn_left = SpineMenuItem:create(json.ui.button, btn_left0)
    btn_left:setPosition(CCPoint(77, 270))
    local btn_left_menu = CCMenu:createWithItem(btn_left)
    btn_left_menu:setPosition(CCPoint(0, 0))
    board:addChild(btn_left_menu, 100)

    -- btn_right
    local btn_right0 = img.createUISprite(img.ui.gemstore_next_icon1)
    local btn_right = SpineMenuItem:create(json.ui.button, btn_right0)
    btn_right:setPosition(CCPoint(board_w-77, 270))
    local btn_right_menu = CCMenu:createWithItem(btn_right)
    btn_right_menu:setPosition(CCPoint(0, 0))
    board:addChild(btn_right_menu, 100)

    cur_page = gbossdata.getCurPage()

    local cur_bossid = gbossdata.id
    local function createItem(bossid)
        local item = CCSprite:create()
        item:setContentSize(CCSizeMake(165, 197))
        local item_w = item:getContentSize().width
        local item_h = item:getContentSize().height
        --if bossid <= cur_bossid and gdata.Lv() >= cfgguildboss[bossid].lv then
        if bossid <= cur_bossid then
            local item_box = img.createUI9Sprite(img.ui.guildvice_card_box)
            item_box:setPreferredSize(CCSizeMake(156, 177))
            item_box:setAnchorPoint(CCPoint(0.5, 1))
            item_box:setPosition(CCPoint(item_w/2, item_h))
            item:addChild(item_box)
            print("bossid:", bossid)
            local item_bg = img.createViceMap(cfgguildboss[bossid].show) --img.createUISprite(img.ui.guildvice_card_bg)
            item_bg:setScale(146/174)
            item_bg:setAnchorPoint(CCPoint(0.5, 0.5))
            item_bg:setPosition(CCPoint(item_box:getContentSize().width/2, item_box:getContentSize().height/2))
            item_box:addChild(item_bg, -1)
            --local item_boss = json.createSpineMons(cfgguildboss[bossid].show)
            --item_boss:setScale(0.45)
            --item_boss:setPosition(CCPoint(item_box:getContentSize().width/2, 0))
            --item_box:addChild(item_boss)
            local item_mask = img.createUISprite(img.ui.guildvice_card_mask)
            item_mask:setPosition(CCPoint(item_box:getContentSize().width/2, item_box:getContentSize().height/2))
            item_box:addChild(item_mask)
            local item_lbl = img.createUISprite(img.ui.guildvice_card_lbl)
            item_lbl:setScale(172/218)
            item_lbl:setAnchorPoint(CCPoint(0.5, 0))
            item_lbl:setPosition(CCPoint(item_w/2, 0))
            item:addChild(item_lbl)
            local lbl_seq = lbl.createFont2(18, "" .. bossid)
            lbl_seq:setPosition(CCPoint(item_w/2, 18))
            item:addChild(lbl_seq, 5)
            if bossid < cur_bossid then
                --item_boss:setPause(true)
                --setShader(item_boss, SHADER_GRAY, true)
                setShader(item, SHADER_GRAY, true)
                local item_icon = img.createUISprite(img.ui.guildvice_icon_dead)
                item_icon:setPosition(CCPoint(item_mask:getContentSize().width/2, item_mask:getContentSize().height/2))
                item_mask:addChild(item_icon, 3)
            elseif bossid == cur_bossid then
                local item_icon = img.createUISprite(img.ui.guildvice_icon_fight)
                item_icon:setPosition(CCPoint(item_mask:getContentSize().width/2, item_mask:getContentSize().height/2))
                item_mask:addChild(item_icon, 3)
                local item_cd = lbl.createFont2(16, "", ccc3(0xa5, 0xfd, 0x47))
                item_cd:setPosition(CCPoint(item_box:getContentSize().width/2, 48))
                item_box:addChild(item_cd)
                local item_last_update = os.time()
                local function onItemUpdate(ticks)
                    if os.time() - item_last_update < 1 then return end
                    item_last_update = os.time()
                    local boss_cd = gbossdata.cd
                    local remain_cd = boss_cd - (os.time() - gbossdata.pull_time)
                    if remain_cd >= 0 then
                        item_cd:setVisible(true)
                        local time_str = time2string(remain_cd)
                        item_cd:setString(time_str)
                    else
                        item_cd:setVisible(false)
                    end
                end
                item_box:scheduleUpdateWithPriorityLua(onItemUpdate, 0)
            end
        else
            local item_bg = img.createUISprite(img.ui.guildvice_card_unlock)
            item_bg:setPosition(CCPoint(item_w/2, item_h/2))
            item:addChild(item_bg)
            --local lbl_seq = lbl.createFont2(18, "Lv " .. cfgguildboss[bossid].lv)
            local lbl_seq = lbl.createFont2(18, "" .. bossid)
            lbl_seq:setPosition(CCPoint(item_bg:getContentSize().width/2, 20))
            item_bg:addChild(lbl_seq)
        end
        return item
    end

    local container = CCSprite:create()
    container:setContentSize(CCSizeMake(board_w, board_h))
    container:setAnchorPoint(CCPoint(0, 0))
    container:setPosition(CCPoint(0, 0))
    board:addChild(container)

    local pages = gbossdata.getPages()
    if cur_page > pages then cur_page = pages end

    local page_container = CCSprite:create()
    page_container:setContentSize(CCSizeMake(board_w, 70))
    page_container:setAnchorPoint(CCPoint(0, 0))
    page_container:setPosition(CCPoint(0, 0))
    board:addChild(page_container, 2)
    local function updatePageRoot(pageid)
        page_container:removeAllChildrenWithCleanup(true)
        local offsetx = board_w/2 - (pages - 1)*32/2
        for ii=1,pages do
            local page_bg = img.createUISprite(img.ui.shop_circle_dark)
            local page_posx = offsetx + (ii-1)*32
            page_bg:setPosition(CCPoint(page_posx, 48))
            page_container:addChild(page_bg)
            if ii == pageid then
                local page_on = img.createUISprite(img.ui.shop_circle_light)
                page_on:setPosition(CCPoint(page_bg:getContentSize().width/2, page_bg:getContentSize().height/2))
                page_bg:addChild(page_on)
            end
        end
    end
    
    local function gotoInfo(gParams)
        local nParam = {
            sid = player.sid,
            id = gParams.idx,
        }
        addWaitNet()
        netClient:gboss_rank(nParam, function(__data)
            delWaitNet()
            tbl2string(__data)
            layer:addChild((require"ui.guildVice.info").create({data=__data.ranks}), 1000)
        end)
    end

    local function onClickItem(idx)
        audio.play(audio.button)
        local bossid = gbossdata.id
        if idx < bossid then
            local nParam = {
                sid = player.sid,
                id = idx,
            }
            addWaitNet()
            netClient:gboss_rank(nParam, function(__data)
                delWaitNet()
                tbl2string(__data)
                layer:addChild((require"ui.guildVice.stats").create({data=__data.ranks}), 1000)
            end)
        elseif idx > bossid then
            showToast(i18n.global.hook_pve_tip.string)
        --elseif gdata.Lv() < cfgguildboss[idx].lv then
        --    showToast(string.format(i18n.global.need_guild_lv.string, cfgguildboss[idx].lv))
        else
            gotoInfo({idx=idx})
        end
    end
    
    local function showPage(pageid)
        container:removeAllChildrenWithCleanup(true)
        for ii=(pageid-1)*8+1, pageid*8 do
            if ii > #cfgguildboss then break end
            local tmp_item = createItem(ii)
            local px = (ii-(pageid-1)*8-1)%4 * 178 + 206
            local py = math.floor((ii-(pageid-1)*8-1)/4) * (0-216) + 380
            --local btn_item = HHMenuItem:createWithScale(tmp_item, 1)
            local btn_item = SpineMenuItem:create(json.ui.button, tmp_item)
            btn_item:setPosition(CCPoint(px, py))
            local btn_item_menu = CCMenu:createWithItem(btn_item)
            btn_item_menu:setPosition(CCPoint(0, 0))
            container:addChild(btn_item_menu)
            btn_item:registerScriptTapHandler(function()
                onClickItem(ii)
            end)
        end
        updatePageRoot(pageid)
    end
    showPage(cur_page)

    btn_left:registerScriptTapHandler(function()
        audio.play(audio.button)
        cur_page = cur_page - 1
        if cur_page < 1 then
            cur_page = pages
        end
        showPage(cur_page)
    end)
    btn_right:registerScriptTapHandler(function()
        audio.play(audio.button)
        cur_page = cur_page + 1
        if cur_page > pages then
            cur_page = 1
        end
        showPage(cur_page)
    end)

    layer:setTouchEnabled(true)
    layer:setTouchSwallowEnabled(true)

    if uiParams and uiParams.from_layer == "info" then
        --if gdata.Lv() >= cfgguildboss[gbossdata.id].lv then
            schedule(layer, function()
                gotoInfo({idx=gbossdata.id})
            end)
        --end
    end

    return layer
end

return ui
