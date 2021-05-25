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

	local act_ids = {
		IDS.HERO_SUMMON_1.ID,
		IDS.HERO_SUMMON_2.ID,
		IDS.HERO_SUMMON_3.ID,
		IDS.HERO_SUMMON_4.ID,
		IDS.HERO_SUMMON_5.ID,
		IDS.HERO_SUMMON_6.ID,
		IDS.HERO_SUMMON_7.ID,
	}

    local layer = CCLayer:create()

    local event_des = {
        [1] = i18n.global.act_hero_summon_1.string,
        [2] = i18n.global.act_hero_summon_2.string,
        [3] = i18n.global.act_hero_summon_3.string,
        [4] = i18n.global.act_hero_summon_4.string,
        [5] = i18n.global.act_hero_summon_5.string,
        [6] = i18n.global.act_hero_summon_6.string,
        [7] = i18n.global.act_hero_summon_7.string,
    }

    local acts = {}
    for _, v in ipairs(act_ids) do
        local tmp_status = activityData.getStatusById(v)
		local curidx = #acts + 1
        acts[curidx] = tmp_status
		tmp_status.des = event_des[curidx] or ""
    end

    table.sort(acts, function(a, b)
        return a.id > b.id
    end)

    local board = CCSprite:create()
    board:setContentSize(CCSizeMake(570, 438))
    board:setScale(view.minScale)
    board:setAnchorPoint(CCPoint(0, 0))
    board:setPosition(scalep(352, 57))
    layer:addChild(board)
    --drawBoundingbox(layer, board)
    local board_w = board:getContentSize().width
    local board_h = board:getContentSize().height

    img.unload(img.packedOthers.ui_activity_hero_summon)
    img.unload(img.packedOthers.ui_activity_hero_summon_cn)
    if i18n.getCurrentLanguage() == kLanguageChinese then
        img.load(img.packedOthers.ui_activity_hero_summon_cn)
    else
        img.load(img.packedOthers.ui_activity_hero_summon)
    end
    local banner
    if i18n.getCurrentLanguage() == kLanguageKorean then
        banner = img.createUISprite("activity_hero_summon_kr.png")
    elseif i18n.getCurrentLanguage() == kLanguageJapanese then
        banner = img.createUISprite("activity_hero_summon_jp.png")
    elseif i18n.getCurrentLanguage() == kLanguageRussian then
        banner = img.createUISprite("activity_hero_summon_ru.png")
    elseif i18n.getCurrentLanguage() == kLanguageChineseTW then
        banner = img.createUISprite("activity_hero_summon_tw.png")
    else
        banner = img.createUISprite(img.ui.activity_hero_summon)
    end
    banner:setAnchorPoint(CCPoint(0.5, 1))
    banner:setPosition(CCPoint(board_w/2, board_h-10))
    board:addChild(banner)

    local lbl_cd_des = lbl.createFont2(14, i18n.global.activity_to_end.string)
    lbl_cd_des:setAnchorPoint(CCPoint(0, 0.5))
    lbl_cd_des:setPosition(CCPoint(104, 24))
    banner:addChild(lbl_cd_des)
    local lbl_cd = lbl.createFont2(14, "", ccc3(0xa5, 0xfd, 0x47))
    lbl_cd:setAnchorPoint(CCPoint(1, 0.5))
    lbl_cd:setPosition(CCPoint(lbl_cd_des:boundingBox():getMinX()-6, 24))
    banner:addChild(lbl_cd)
    if i18n.getCurrentLanguage() == kLanguageRussian then
        lbl_cd_des:setPosition(CCPoint(104-40, 24))
        lbl_cd:setAnchorPoint(CCPoint(0, 0.5))
        lbl_cd:setPosition(CCPoint(lbl_cd_des:boundingBox():getMaxX()+10, 24))
    end

    local function createItem(vpObj, i)
        local temp_item = nil
        if i == 1 then
            temp_item = img.createUI9Sprite(img.ui.task_all_bg)
        else
            temp_item = img.createUI9Sprite(img.ui.bottom_border_2)
        end
        temp_item:setPreferredSize(CCSizeMake(542, 84))
        local item_w = temp_item:getContentSize().width
        local item_h = temp_item:getContentSize().height
        -- description
        local lbl_des = lbl.create({font=1, size=16, text=vpObj.des, 
                    color=ccc3(0x61, 0x34, 0x2a), width=300, align=kCCTextAlignmentLeft})
        lbl_des:setAnchorPoint(CCPoint(0, 0.5))
        lbl_des:setPosition(CCPoint(18, 55))
        temp_item:addChild(lbl_des)

        local pgb_bg = img.createUI9Sprite(img.ui.playerInfo_process_bar_bg)
        pgb_bg:setPreferredSize(CCSizeMake(203, 20))
        pgb_bg:setPosition(CCPoint(120, 26))
        temp_item:addChild(pgb_bg)
        local pgb_fg = img.createUISprite(img.ui.activity_pgb_casino)
        local pgb = createProgressBar(pgb_fg)
        pgb:setPosition(CCPoint(pgb_bg:getContentSize().width/2, pgb_bg:getContentSize().height/2))
        pgb_bg:addChild(pgb)
        local numerator = 0
        if i > 1 then
            numerator = vpObj.cfg.parameter[1].num
        else
            numerator = #vpObj.cfg.parameter
        end
        pgb:setPercentage(vpObj.limits*100/numerator)
        local lbl_pgb = lbl.createFont2(14, vpObj.limits .. "/" .. numerator)
        lbl_pgb:setAnchorPoint(CCPoint(0.5, 0))
        lbl_pgb:setPosition(CCPoint(pgb_bg:getContentSize().width/2, pgb_bg:getContentSize().height/2))
        pgb_bg:addChild(lbl_pgb)
        -- rewards
        local start_x = 50
        local step_x = 68
        local r_pos = { [1] = 490, [2] = 420, [3] = 350, [4] = 280,}
        local rewards = vpObj.cfg.rewards
        for ii=1,#rewards do
            local _obj = rewards[ii]
            if _obj.type == ItemType.Equip then  -- equip
                local _item0 = img.createEquip(_obj.id, _obj.num)
                local _item = CCMenuItemSprite:create(_item0, nil)
                _item:setScale(0.7)
                _item:setPosition(CCPoint(r_pos[ii], item_h/2))
                if i > 1 and vpObj.limits == vpObj.cfg.parameter[1].num then
                    local _mask = img.createUISprite(img.ui.hook_btn_mask)
                    _mask:setPosition(CCPoint(_item0:getContentSize().width/2, _item0:getContentSize().height/2))
                    _item0:addChild(_mask, 100)
                    local _sel = img.createUISprite(img.ui.hook_btn_sel)
                    _sel:setPosition(CCPoint(_item0:getContentSize().width/2, _item0:getContentSize().height/2))
                    _item0:addChild(_sel, 100)
                end
                if i == 1 and vpObj.limits == #vpObj.cfg.parameter then
                    local _mask = img.createUISprite(img.ui.hook_btn_mask)
                    _mask:setPosition(CCPoint(_item0:getContentSize().width/2, _item0:getContentSize().height/2))
                    _item0:addChild(_mask, 100)
                    local _sel = img.createUISprite(img.ui.hook_btn_sel)
                    _sel:setPosition(CCPoint(_item0:getContentSize().width/2, _item0:getContentSize().height/2))
                    _item0:addChild(_sel, 100)
                end
                local _item_menu = CCMenu:createWithItem(_item)
                _item_menu:setPosition(CCPoint(0, 0))
                temp_item:addChild(_item_menu)
                _item:registerScriptTapHandler(function()
                    audio.play(audio.button)
                    layer:getParent():getParent():addChild(tipsequip.createById(_obj.id), 1000)
                end)
            elseif _obj.type == ItemType.Item then
                local _item0 = img.createItem(_obj.id, _obj.num)
                local _item = CCMenuItemSprite:create(_item0, nil)
                _item:setScale(0.7)
                _item:setPosition(CCPoint(r_pos[ii], item_h/2))
                if i > 1 and vpObj.limits == vpObj.cfg.parameter[1].num then
                    local _mask = img.createUISprite(img.ui.hook_btn_mask)
                    _mask:setPosition(CCPoint(_item0:getContentSize().width/2, _item0:getContentSize().height/2))
                    _item0:addChild(_mask, 100)
                    local _sel = img.createUISprite(img.ui.hook_btn_sel)
                    _sel:setPosition(CCPoint(_item0:getContentSize().width/2, _item0:getContentSize().height/2))
                    _item0:addChild(_sel, 100)
                end
                if i == 1 and vpObj.limits == #vpObj.cfg.parameter then
                    local _mask = img.createUISprite(img.ui.hook_btn_mask)
                    _mask:setPosition(CCPoint(_item0:getContentSize().width/2, _item0:getContentSize().height/2))
                    _item0:addChild(_mask, 100)
                    local _sel = img.createUISprite(img.ui.hook_btn_sel)
                    _sel:setPosition(CCPoint(_item0:getContentSize().width/2, _item0:getContentSize().height/2))
                    _item0:addChild(_sel, 100)
                end
                local _item_menu = CCMenu:createWithItem(_item)
                _item_menu:setPosition(CCPoint(0, 0))
                temp_item:addChild(_item_menu)
                _item:registerScriptTapHandler(function()
                    audio.play(audio.button)
                    layer:getParent():getParent():addChild(tipsitem.createForShow({id=_obj.id}), 1000)
                end)
            end
        end

        return temp_item
    end

    local lineScroll = require "ui.lineScroll"
    local scroll_params = {
        width = 550,
        height = 220,
    }
    local scroll = lineScroll.create(scroll_params)
    scroll:setAnchorPoint(CCPoint(0, 0))
    scroll:setPosition(CCPoint(10, 3))
    board:addChild(scroll)
    layer.scroll = scroll

    local function showList(listObjs)
        for ii=1,#listObjs do
            if ii == 1 then
                scroll.addSpace(3)
            end
            if ii == 2 then
                scroll.addSpace(3)
            end
            local tmp_item = createItem(listObjs[ii], ii)
            tmp_item.obj = listObjs[ii]
            tmp_item.ax = 0.5
            tmp_item.px = scroll_params.width/2
            scroll.addItem(tmp_item)
        end
        scroll.setOffsetBegin()
    end
	showList(acts)
	
	local act_st = acts[1]

    local last_update = os.time() - 1
    local function onUpdate(ticks)
        if os.time() - last_update < 1 then return end
        last_update = os.time()
        local remain_cd = act_st.cd - (os.time() - activityData.pull_time)
        if remain_cd >= 0 then
            local time_str = time2string(remain_cd)
            lbl_cd:setString(time_str)
        else
        end
    end
    layer:scheduleUpdateWithPriorityLua(onUpdate, 0)

    --img.unload(img.packedOthers.ui_activity_summon)
    require("ui.activity.ban").addBan(layer, scroll)
    layer:setTouchSwallowEnabled(false)
    layer:setTouchEnabled(true)
    return layer
end

return ui
