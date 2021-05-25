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
	
    local layer = CCLayer:create()

    local st1 = activityData.getStatusById(IDS.SCORE_FIGHT.ID)
    local st2 = activityData.getStatusById(IDS.SCORE_FIGHT2.ID)
    local st3 = activityData.getStatusById(IDS.SCORE_FIGHT3.ID)

    local dot1 = 3
    local dot2 = 6
    local dot1Limit = st1.cfg.parameter[1].qlt
    local dot2Limit = st2.cfg.parameter[1].qlt

    local board = CCSprite:create()
    board:setContentSize(CCSizeMake(570, 438))
    board:setScale(view.minScale)
    board:setAnchorPoint(CCPoint(0, 0))
    board:setPosition(scalep(362, 60))
    layer:addChild(board)
    --drawBoundingbox(layer, board)
    local board_w = board:getContentSize().width
    local board_h = board:getContentSize().height

    img.unload(img.packedOthers.ui_activity_fight)
    img.unload(img.packedOthers.ui_activity_fight_cn)
    if i18n.getCurrentLanguage() == kLanguageChinese  then
        img.load(img.packedOthers.ui_activity_fight_cn)
    else
        img.load(img.packedOthers.ui_activity_fight)
    end
    local banner 
    if i18n.getCurrentLanguage() == kLanguageKorean then
        banner = img.createUISprite("activity_fight_board_kr.png")
    elseif i18n.getCurrentLanguage() == kLanguageJapanese then
        banner = img.createUISprite("activity_fight_board_jp.png")
    elseif i18n.getCurrentLanguage() == kLanguageChineseTW then
        banner = img.createUISprite("activity_fight_board_tw.png")
    elseif i18n.getCurrentLanguage() == kLanguageRussian then
        banner = img.createUISprite("activity_fight_board_ru.png")
    else
        banner = img.createUISprite(img.ui.activity_fight_board)
    end
    banner:setAnchorPoint(CCPoint(0.5, 1))
    banner:setPosition(CCPoint(board_w/2-10, board_h-8))
    board:addChild(banner)

    local lbl_cd = lbl.createFont2(14, "", ccc3(0xa5, 0xfd, 0x47))
    lbl_cd:setAnchorPoint(CCPoint(0, 0.5))
    lbl_cd:setPosition(CCPoint(409, 27))
    banner:addChild(lbl_cd)
    local lbl_cd_des = lbl.createFont2(14, i18n.global.activity_to_end.string)
    lbl_cd_des:setAnchorPoint(CCPoint(0, 0.5))
    lbl_cd_des:setPosition(CCPoint(409+82, 27))
    banner:addChild(lbl_cd_des)

    if i18n.getCurrentLanguage() == kLanguageRussian then
        lbl_cd_des:setPosition(CCPoint(409-40, 27))
        lbl_cd:setAnchorPoint(CCPoint(0, 0.5))
        lbl_cd:setPosition(CCPoint(lbl_cd_des:boundingBox():getMaxX()+10, 27))
    end

    local function createItem(itemObj, pos)
        local temp_item = img.createUI9Sprite(img.ui.bottom_border_2)
        temp_item:setPreferredSize(CCSizeMake(542, 84))
        local item_w = temp_item:getContentSize().width
        local item_h = temp_item:getContentSize().height
        -- des
        local des_str = i18n.arena[1].name .. i18n.global.casino_log_gain.string .. " " .. itemObj.parameter[1].qlt .. " " .. i18n.global.arena_main_score.string
        if pos > dot1 and pos <= dot2 then
            des_str = i18n.arena[2].name .. i18n.global.casino_log_gain.string .. " " .. itemObj.parameter[1].qlt .. " " .. i18n.global.arena_main_score.string
        end
        if pos > dot2 then
            des_str = i18n.global.act_hero_summon_7.string
        end
        local lbl_des = lbl.createMixFont1(16, des_str, ccc3(0x5d, 0x2d, 0x12))
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
        if pos <= dot1 then
            if st1.limits >= itemObj.parameter[1].qlt then
                numerator = itemObj.parameter[1].qlt
            else
                numerator = st1.limits
            end
        elseif pos <= dot2 then
            if st2.limits >= itemObj.parameter[1].qlt then
                numerator = itemObj.parameter[1].qlt
            else
                numerator = st2.limits
            end
        else
            --print("debug:st1.limits,dot1Limit, st2.limits, dot2Limit:", st1.limits, dot1Limit, st2.limits, dot2Limit)
            if st1.limits >= dot1Limit and st2.limits >= dot2Limit then
                st3.limits = 1
                numerator = 1
            else
                numerator = st3.limits
            end
        end
        --end
        local lbl_pgb = lbl.createFont2(14, numerator .. "/" .. itemObj.parameter[1].qlt)
        lbl_pgb:setAnchorPoint(CCPoint(0.5, 0))
        lbl_pgb:setPosition(CCPoint(pgb_bg:getContentSize().width/2, pgb_bg:getContentSize().height/2))
        pgb_bg:addChild(lbl_pgb)
        if pos <= dot2 then
            pgb:setPercentage(numerator*100/itemObj.parameter[1].qlt)
        else
            pgb:setPercentage(numerator*100/1)
            lbl_pgb:setString(numerator .. "/" .. 1)
        end
        -- rewards
        local max_x = 486
        local step_x = 68
        local rewards_count = #itemObj.rewards
        for ii=rewards_count, 1, -1 do
            local _obj = itemObj.rewards[ii]
            local stlimits = 0
            local finishnum = 0 
            if pos <= dot1 then
                stlimits = st1.limits
                finishnum = itemObj.parameter[1].qlt
            elseif pos <= dot2 then
                stlimits = st2.limits
                finishnum = itemObj.parameter[1].qlt
            else
                stlimits = st3.limits
                finishnum = 1
            end
            if _obj.type == ItemType.Equip then  -- equip
                local _item0 = img.createEquip(_obj.id, _obj.num)
                if stlimits >= finishnum then
                    local _mask = img.createUISprite(img.ui.hook_btn_mask)
                    _mask:setPosition(CCPoint(_item0:getContentSize().width/2, _item0:getContentSize().height/2))
                    _item0:addChild(_mask, 100)
                    local _sel = img.createUISprite(img.ui.hook_btn_sel)
                    _sel:setPosition(CCPoint(_item0:getContentSize().width/2, _item0:getContentSize().height/2))
                    _item0:addChild(_sel, 100)
                end
                local _item = CCMenuItemSprite:create(_item0, nil)
                _item:setScale(0.7)
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
                --if st1.limits >= itemObj.instruct then
                if stlimits >= finishnum then
                    local _mask = img.createUISprite(img.ui.hook_btn_mask)
                    _mask:setPosition(CCPoint(_item0:getContentSize().width/2, _item0:getContentSize().height/2))
                    _item0:addChild(_mask, 100)
                    local _sel = img.createUISprite(img.ui.hook_btn_sel)
                    _sel:setPosition(CCPoint(_item0:getContentSize().width/2, _item0:getContentSize().height/2))
                    _item0:addChild(_sel, 100)
                end
                --end
                local _item = CCMenuItemSprite:create(_item0, nil)
                _item:setScale(0.7)
                _item:setPosition(CCPoint(max_x-(rewards_count-ii)*step_x, item_h/2))
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
        height = 221,
    }
    local scroll = lineScroll.create(scroll_params)
    scroll:setAnchorPoint(CCPoint(0, 0))
    scroll:setPosition(CCPoint(0, 3))
    board:addChild(scroll)
    layer.scroll = scroll

    local items = {}
    for ii=2,0,-1 do
        items[#items+1] = clone(activityData.find(st1.id - ii).cfg)
    end
    for ii=2,0,-1 do
        items[#items+1] = clone(activityData.find(st2.id - ii).cfg)
    end
    items[#items+1] = clone(st3.cfg)
    
    local function showList(listObjs)
        for ii=1,#listObjs do
            --if ii == 1 then
            --    scroll.addSpace(3)
            --end
            local tmp_item = createItem(listObjs[ii], ii)
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
    tbl2string(items)
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
