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
	local st1 = activityData.getStatusById(IDS.SCORE_TARVEN_4.ID)
    local st2 = activityData.getStatusById(IDS.SCORE_TARVEN_5.ID)
    local st3 = activityData.getStatusById(IDS.SCORE_TARVEN_6.ID)
    local st4 = activityData.getStatusById(IDS.SCORE_TARVEN_7.ID)
	local MaxPoints = {
		[IDS.SCORE_TARVEN_4.ID] = st1.cfg.instruct,
		[IDS.SCORE_TARVEN_5.ID] = st2.cfg.instruct,
		[IDS.SCORE_TARVEN_6.ID] = st3.cfg.instruct,
		[IDS.SCORE_TARVEN_7.ID] = st4.cfg.instruct,
	}

    local layer = CCLayer:create()

    st1.instruct= MaxPoints[IDS.SCORE_TARVEN_4.ID]
    st1.des = string.format(i18n.global.scoretarven_item_des.string, 4)
    st2.instruct= MaxPoints[IDS.SCORE_TARVEN_5.ID]
    st2.des = string.format(i18n.global.scoretarven_item_des.string, 5)
    st3.instruct= MaxPoints[IDS.SCORE_TARVEN_6.ID]
    st3.des = string.format(i18n.global.scoretarven_item_des.string, 6)
    st4.instruct= MaxPoints[IDS.SCORE_TARVEN_7.ID]
    st4.des = string.format(i18n.global.scoretarven_item_des.string, 7)

    local board = CCSprite:create()
    board:setContentSize(CCSizeMake(570, 438))
    board:setScale(view.minScale)
    board:setAnchorPoint(CCPoint(0, 0))
    board:setPosition(scalep(362, 60))
    layer:addChild(board)
    --drawBoundingbox(layer, board)
    local board_w = board:getContentSize().width
    local board_h = board:getContentSize().height

    img.unload(img.packedOthers.ui_activity_tarven)
    img.unload(img.packedOthers.ui_activity_tarven_cn)
    if i18n.getCurrentLanguage() == kLanguageChinese then
        img.load(img.packedOthers.ui_activity_tarven_cn)
    else
        img.load(img.packedOthers.ui_activity_tarven)
    end
    local banner
    if i18n.getCurrentLanguage() == kLanguageKorean then
        banner = img.createUISprite("activity_tarven_board_kr.png")
    elseif i18n.getCurrentLanguage() == kLanguageJapanese then
        banner = img.createUISprite("activity_tarven_board_jp.png")
    elseif i18n.getCurrentLanguage() == kLanguageRussian then
        banner = img.createUISprite("activity_tarven_board_ru.png")
    elseif i18n.getCurrentLanguage() == kLanguageChineseTW then
        banner = img.createUISprite("activity_tarven_board_tw.png")
    elseif i18n.getCurrentLanguage() == kLanguagePortuguese then
        banner = img.createUISprite("activity_tarven_board_pt.png")
    else
        banner = img.createUISprite(img.ui.activity_tarven_board)
    end
    banner:setAnchorPoint(CCPoint(0.5, 1))
    banner:setPosition(CCPoint(board_w/2-10, board_h-8))
    board:addChild(banner)

    local lbl_cd = lbl.createFont2(16, "", ccc3(0xa5, 0xfd, 0x47))
    lbl_cd:setAnchorPoint(CCPoint(1, 0.5))
    lbl_cd:setPosition(CCPoint(363, 30))
    banner:addChild(lbl_cd)
    local lbl_cd_des = lbl.createFont2(16, i18n.global.activity_to_end.string)
    lbl_cd_des:setAnchorPoint(CCPoint(0, 0.5))
    lbl_cd_des:setPosition(CCPoint(368, 30))
    banner:addChild(lbl_cd_des)

    local function createItem(itemObj)
        local temp_item = img.createUI9Sprite(img.ui.bottom_border_2)
        temp_item:setPreferredSize(CCSizeMake(542, 102))
        local item_w = temp_item:getContentSize().width
        local item_h = temp_item:getContentSize().height
        -- des
        local lbl_des = lbl.createMixFont1(14, itemObj.des, ccc3(0x5d, 0x2d, 0x12))
        lbl_des:setAnchorPoint(CCPoint(0, 0.5))
        lbl_des:setPosition(CCPoint(23, 67))
        temp_item:addChild(lbl_des)
        -- pgb
        local pgb_bg = img.createUI9Sprite(img.ui.playerInfo_process_bar_bg)
        pgb_bg:setPreferredSize(CCSizeMake(203, 20))
        pgb_bg:setPosition(CCPoint(125, 36))
        temp_item:addChild(pgb_bg)
        local pgb_fg = img.createUISprite(img.ui.activity_pgb_casino)
        local pgb = createProgressBar(pgb_fg)
        pgb:setPosition(CCPoint(pgb_bg:getContentSize().width/2, pgb_bg:getContentSize().height/2))
        pgb_bg:addChild(pgb)
        local numerator = 0
        if itemObj.limits >= itemObj.instruct then
            numerator = itemObj.instruct
        else
            numerator = itemObj.limits
        end
        pgb:setPercentage(numerator*100/itemObj.instruct)
        local lbl_pgb = lbl.createFont2(14, numerator .. "/" .. itemObj.instruct)
        lbl_pgb:setAnchorPoint(CCPoint(0.5, 0))
        lbl_pgb:setPosition(CCPoint(pgb_bg:getContentSize().width/2, pgb_bg:getContentSize().height/2))
        pgb_bg:addChild(lbl_pgb)
        -- rewards
        local max_x = 488
        local step_x = 73
        itemObj.rewards = itemObj.cfg.rewards
        local rewards_count = #itemObj.rewards
        for ii=rewards_count, 1, -1 do
            local _obj = itemObj.rewards[ii]
            if _obj.type == ItemType.Equip then  -- equip
                local _item0 = img.createEquip(_obj.id, _obj.num)
                if itemObj.limits >= itemObj.instruct then
                    local _mask = img.createUISprite(img.ui.hook_btn_mask)
                    _mask:setPosition(CCPoint(_item0:getContentSize().width/2, _item0:getContentSize().height/2))
                    _item0:addChild(_mask, 100)
                    local _sel = img.createUISprite(img.ui.hook_btn_sel)
                    _sel:setPosition(CCPoint(_item0:getContentSize().width/2, _item0:getContentSize().height/2))
                    _item0:addChild(_sel, 100)
                end
                local _item = CCMenuItemSprite:create(_item0, nil)
                _item:setScale(0.8)
                _item:setPosition(CCPoint(max_x-(rewards_count-ii)*step_x, item_h/2))
                local _item_menu = CCMenu:createWithItem(_item)
                _item_menu:setPosition(CCPoint(0, 0))
                temp_item:addChild(_item_menu)
                _item:registerScriptTapHandler(function()
                    audio.play(audio.button)
                    layer:getParent():getParent():addChild(tipsequip.createById(_obj.id), 1000)
                end)
            elseif _obj.type == ItemType.Item then
                local _item0 = img.createItem(_obj.id, _obj.num)
                if itemObj.limits >= itemObj.instruct then
                    local _mask = img.createUISprite(img.ui.hook_btn_mask)
                    _mask:setPosition(CCPoint(_item0:getContentSize().width/2, _item0:getContentSize().height/2))
                    _item0:addChild(_mask, 100)
                    local _sel = img.createUISprite(img.ui.hook_btn_sel)
                    _sel:setPosition(CCPoint(_item0:getContentSize().width/2, _item0:getContentSize().height/2))
                    _item0:addChild(_sel, 100)
                end
                local _item = CCMenuItemSprite:create(_item0, nil)
                _item:setScale(0.8)
                _item:setPosition(CCPoint(max_x-(rewards_count-ii)*step_x, item_h/2+2))
                local _item_menu = CCMenu:createWithItem(_item)
                _item_menu:setPosition(CCPoint(0, 0))
                temp_item:addChild(_item_menu)
                _item:registerScriptTapHandler(function()
                    audio.play(audio.button)
                    layer:getParent():getParent():addChild(tipsitem.createForShow({id=_obj.id}), 1000)
                end)
            end
        end

        temp_item.height = item_h
        return temp_item
    end

    local lineScroll = require "ui.lineScroll"
    local scroll_params = {
        width = 550,
        height = 218,
    }
    local scroll = lineScroll.create(scroll_params)
    scroll:setAnchorPoint(CCPoint(0, 0))
    scroll:setPosition(CCPoint(0, 3))
    board:addChild(scroll)
    layer.scroll = scroll

    local items = {
        [1] = st1,
        [2] = st2,
        [3] = st3,
        [4] = st4,
    }

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

    local last_update = os.time() - 1
    local function onUpdate(ticks)
        if os.time() - last_update < 1 then return end
        last_update = os.time()
        local remain_cd = st1.cd - (os.time() - activityData.pull_time)
        if remain_cd >= 0 then
            local time_str = time2string(remain_cd)
            lbl_cd:setString(time_str)
        else
        end
    end
    layer:scheduleUpdateWithPriorityLua(onUpdate, 0)

    --img.unload(img.packedOthers.ui_activity_casino)
    require("ui.activity.ban").addBan(layer, scroll)
    layer:setTouchSwallowEnabled(false)
    layer:setTouchEnabled(true)
    return layer
end

return ui
