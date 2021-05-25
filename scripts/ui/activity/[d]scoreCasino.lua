local ui = {}

require "common.func"
local view = require "common.view"
local i18n = require "res.i18n"
local lbl = require "res.lbl"
local img = require "res.img"
local audio = require "res.audio"
local json = require "res.json"
local player = require "data.player"
local activityData = require "data.activity"
local NetClient = require "net.netClient"
local netClient = NetClient:getInstance()
local tipsequip = require "ui.tips.equip"
local tipsitem = require "ui.tips.item"

function ui.create()
	local IDS = activityData.IDS
	local ItemType = {
		Item = 1,
		Equip = 2,
	}
	local st1 = activityData.getStatusById(IDS.SCORE_CASINO.ID)
	local MaxPoints = st1.cfg.instruct

    local layer = CCLayer:create()

    local board = CCSprite:create()
    board:setContentSize(CCSizeMake(570, 438))
    board:setScale(view.minScale)
    board:setAnchorPoint(CCPoint(0, 0))
    board:setPosition(scalep(362, 60))
    layer:addChild(board)
    --drawBoundingbox(layer, board)
    local board_w = board:getContentSize().width
    local board_h = board:getContentSize().height

    img.unload(img.packedOthers.ui_activity_casino)
    img.unload(img.packedOthers.ui_activity_casino_cn)
    if i18n.getCurrentLanguage() == kLanguageChinese then 
        img.load(img.packedOthers.ui_activity_casino_cn)
    else
        img.load(img.packedOthers.ui_activity_casino)
    end
    local banner
    if i18n.getCurrentLanguage() == kLanguageKorean then
        banner = img.createUISprite("activity_casino_board_kr.png")
    elseif i18n.getCurrentLanguage() == kLanguageJapanese then
        banner = img.createUISprite("activity_casino_board_jp.png")
    elseif i18n.getCurrentLanguage() == kLanguageRussian then
        banner = img.createUISprite("activity_casino_board_ru.png")
    elseif i18n.getCurrentLanguage() == kLanguageChineseTW then
        banner = img.createUISprite("activity_casino_board_tw.png")
    elseif i18n.getCurrentLanguage() == kLanguagePortuguese then
        banner = img.createUISprite("activity_casino_board_kp.png")
    else
        banner = img.createUISprite(img.ui.activity_casino_board)
    end
    banner:setAnchorPoint(CCPoint(0.5, 1))
    banner:setPosition(CCPoint(board_w/2-10, board_h-8))
    board:addChild(banner)

    local item_des = "GET %s POINTS"
    if i18n.getCurrentLanguage() == kLanguageChinese 
        or i18n.getCurrentLanguage() == kLanguageChineseTW then
        item_des = "获得 %s 积分"
    end
    item_des = i18n.global.spesummon_gain.string .. " %s " .. i18n.global.arena_main_score.string

    local function createItem(itemObj)
        local temp_item = img.createUI9Sprite(img.ui.bottom_border_2)
        temp_item:setPreferredSize(CCSizeMake(542, 84))
        local item_w = temp_item:getContentSize().width
        local item_h = temp_item:getContentSize().height
        -- des
        local lbl_des = lbl.createFont1(16, string.format(item_des, itemObj.instruct), ccc3(0x5d, 0x2d, 0x12))
        lbl_des:setAnchorPoint(CCPoint(0, 0.5))
        lbl_des:setPosition(CCPoint(18, 55))
        temp_item:addChild(lbl_des)
        -- pgb
        local pgb_bg = img.createUI9Sprite(img.ui.playerInfo_process_bar_bg)
        pgb_bg:setPreferredSize(CCSizeMake(203, 20))
        pgb_bg:setPosition(CCPoint(120, 26))
        temp_item:addChild(pgb_bg)
        local pgb_fg = img.createUISprite(img.ui.activity_pgb_casino)
        local pgb = createProgressBar(pgb_fg)
        pgb:setPosition(CCPoint(pgb_bg:getContentSize().width/2, pgb_bg:getContentSize().height/2))
        pgb_bg:addChild(pgb)
        local numerator = 0
        if st1.limits >= itemObj.instruct then
            numerator = itemObj.instruct
        else
            numerator = st1.limits
        end
        pgb:setPercentage(numerator*100/itemObj.instruct)
        local lbl_pgb = lbl.createFont2(14, numerator .. "/" .. itemObj.instruct)
        lbl_pgb:setAnchorPoint(CCPoint(0.5, 0))
        lbl_pgb:setPosition(CCPoint(pgb_bg:getContentSize().width/2, pgb_bg:getContentSize().height/2))
        pgb_bg:addChild(lbl_pgb)
        -- rewards
        local r_pos = { [1] = 292, [2] = 357,}
        for ii=1,#itemObj.rewards do
            local _obj = itemObj.rewards[ii]
            if _obj.type == ItemType.Equip then  -- equip
                local _item0 = img.createEquip(_obj.id, _obj.num)
                local _item = CCMenuItemSprite:create(_item0, nil)
                _item:setScale(0.7)
                _item:setPosition(CCPoint(r_pos[ii], item_h/2))
                local _item_menu = CCMenu:createWithItem(_item)
                _item_menu:setPosition(CCPoint(0, 0))
                temp_item:addChild(_item_menu)
                _item:registerScriptTapHandler(function()
                    audio.play(audio.button)
                    layer:addChild(tipsequip.createById(_obj.id), 100)
                end)
            elseif _obj.type == ItemType.Item then
                local _item0 = img.createItem(_obj.id, _obj.num)
                local _item = CCMenuItemSprite:create(_item0, nil)
                _item:setScale(0.7)
                _item:setPosition(CCPoint(r_pos[ii], item_h/2))
                local _item_menu = CCMenu:createWithItem(_item)
                _item_menu:setPosition(CCPoint(0, 0))
                temp_item:addChild(_item_menu)
                _item:registerScriptTapHandler(function()
                    audio.play(audio.button)
                    layer:getParent():getParent():addChild(tipsitem.createForShow({id=_obj.id}), 1000)
                end)
            end
        end
        -- received
        if st1.limits >= itemObj.instruct then
            local icon_recv = img.createUISprite(img.ui.achieve_calim)
            icon_recv:setPosition(CCPoint(468, item_h/2))
            temp_item:addChild(icon_recv)
        end

        temp_item.height = item_h
        return temp_item
    end

    local lineScroll = require "ui.lineScroll"
    local scroll_params = {
        width = 550,
        height = 241,
    }
    local scroll = lineScroll.create(scroll_params)
    scroll:setAnchorPoint(CCPoint(0, 0))
    scroll:setPosition(CCPoint(0, 3))
    board:addChild(scroll)
    layer.scroll = scroll

    local items = {}
    for ii=9,0,-1 do
		local sti = activityData.find(st1.id - ii)
        if sti and sti.cfg then
            items[#items+1] = clone(sti.cfg)
        end
    end
    local function sortValue(_obj)
        if _obj.instruct <= st1.limits then
            return 10000 + _obj.instruct
        else
            return _obj.instruct
        end
    end
    table.sort(items, function(a, b)
        return sortValue(a) < sortValue(b)
        --if a.instruct >= st1.limits and b.instruct >= st1.limits then
        --    return a.instruct < b.instruct
        --elseif a.instruct >= st1.limits and b.instruct < st1.limits then
        --    return true
        --elseif a.instruct < st1.limits and b.instruct >= st1.limits then
        --    return false
        --elseif a.instruct < st1.limits and b.instruct < st1.limits then
        --    return a.instruct < b.instruct
        --end
    end)

    local function showList(listObjs)
        for ii=1,#listObjs do
            --if ii == 1 then
            --    scroll.addSpace(3)
            --end
            local tmp_item = createItem(listObjs[ii])
            tmp_item.obj = listObjs[ii]
            tmp_item.ax = 0.5
            tmp_item.px = scroll_params.width/2
            scroll.addItem(tmp_item)
            if ii ~= item_count then
                scroll.addSpace(3)
            end
        end
        scroll.setOffsetBegin()
    end
    showList(items)

    --img.unload(img.packedOthers.ui_activity_casino)
    require("ui.activity.ban").addBan(layer, scroll)
    layer:setTouchSwallowEnabled(false)
    layer:setTouchEnabled(true)
    return layer
end

return ui
