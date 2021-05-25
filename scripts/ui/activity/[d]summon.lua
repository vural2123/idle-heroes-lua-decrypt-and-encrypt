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
		IDS.SUMMON_HERO_1.ID,
		IDS.SUMMON_HERO_2.ID,
	}

    local layer = CCLayer:create()

    local acts = {}
    for _, v in ipairs(act_ids) do
        local tmp_status = activityData.getStatusById(v)
        acts[#acts+1] = tmp_status
    end

    local board = CCSprite:create()
    board:setContentSize(CCSizeMake(570, 438))
    board:setScale(view.minScale)
    board:setAnchorPoint(CCPoint(0, 0))
    board:setPosition(scalep(352, 57))
    layer:addChild(board)
    --drawBoundingbox(layer, board)
    local board_w = board:getContentSize().width
    local board_h = board:getContentSize().height

    img.load(img.packedOthers.ui_activity_summon)
    local bannerLabel
    if i18n.getCurrentLanguage() == kLanguageKorean then
        bannerLabel = img.createUISprite("activity_summon_kr.png")
    elseif i18n.getCurrentLanguage() == kLanguageChinese then
        bannerLabel = img.createUISprite("activity_summon_cn.png")
    elseif i18n.getCurrentLanguage() == kLanguageChineseTW then
        bannerLabel = img.createUISprite("activity_summon_tw.png")
    elseif i18n.getCurrentLanguage() == kLanguageJapanese then
        bannerLabel = img.createUISprite("activity_summon_jp.png")
    elseif i18n.getCurrentLanguage() == kLanguageRussian then
        bannerLabel = img.createUISprite("activity_summon_ru.png")
    elseif i18n.getCurrentLanguage() == kLanguagePortuguese then
        bannerLabel = img.createUISprite("activity_summon_pt.png")
    elseif i18n.getCurrentLanguage() == kLanguageSpanish then
        bannerLabel = img.createUISprite("activity_summon_sp.png")
    else
        bannerLabel = img.createUISprite("activity_summon.png")
    end
    --banner:setAnchorPoint(CCPoint(0.5, 1))
    --banner:setPosition(CCPoint(board_w/2, board_h-10))
    --board:addChild(banner)
    local banner = img.createUISprite(img.ui.activity_summon_board)
    banner:setAnchorPoint(CCPoint(0.5, 1))
    banner:setPosition(CCPoint(board_w/2, board_h-10))
    board:addChild(banner)

    bannerLabel:setAnchorPoint(CCPoint(0.5, 1))
    bannerLabel:setPosition(CCPoint(board_w/2+70, board_h-30))
    board:addChild(bannerLabel)


    local lbl_cd = lbl.createFont2(14, "", ccc3(0xa5, 0xfd, 0x47))
    lbl_cd:setAnchorPoint(CCPoint(0, 0.5))
    lbl_cd:setPosition(CCPoint(280, 20))
    banner:addChild(lbl_cd)
    local lbl_cd_des = lbl.createFont2(14, i18n.global.activity_to_end.string)
    lbl_cd_des:setAnchorPoint(CCPoint(0, 0.5))
    lbl_cd_des:setPosition(CCPoint(355, 20))
    banner:addChild(lbl_cd_des)

    if i18n.getCurrentLanguage() == kLanguageRussian then
        lbl_cd_des:setPosition(CCPoint(280-40, 20))
        lbl_cd:setAnchorPoint(CCPoint(0, 0.5))
        lbl_cd:setPosition(CCPoint(lbl_cd_des:boundingBox():getMaxX()+10, 20))
    end

    local function createItem(vpObj)
        local temp_item = img.createUI9Sprite(img.ui.bottom_border_2)
        temp_item:setPreferredSize(CCSizeMake(542, 95))
        local item_w = temp_item:getContentSize().width
        local item_h = temp_item:getContentSize().height
        -- hero
        local hero_id = vpObj.cfg.instruct
        print("================actid, hero_id:", vpObj.id, hero_id)
        local head0 = img.createHeroHead(hero_id, nil, true, true, nil, true)
        local head = CCMenuItemSprite:create(head0, nil)
        head:setScale(0.75)
        head:setPosition(CCPoint(65, item_h/2))
        local head_menu = CCMenu:createWithItem(head)
        head_menu:setPosition(CCPoint(0, 0))
        temp_item:addChild(head_menu)
        head:registerScriptTapHandler(function()
            audio.play(audio.button)
            local herotips = require "ui.tips.hero"
            local tips = herotips.create(hero_id)
            layer:getParent():getParent():addChild(tips, 1001)
        end)
        -- arrow
        local icon_arrow = img.createUISprite(img.ui.arrow)
        icon_arrow:setPosition(CCPoint(164, item_h/2))
        temp_item:addChild(icon_arrow)
        -- rewards
        local start_x = 254
        local step_x = 66
        local rewards = vpObj.cfg.rewards
        for ii=1,#rewards do
            local _obj = rewards[ii]
            if _obj.type == ItemType.Equip then  -- equip
                local _item0 = img.createEquip(_obj.id, _obj.num)
                local _item = CCMenuItemSprite:create(_item0, nil)
                _item:setScale(0.7)
                _item:setPosition(CCPoint(start_x+(ii-1)*step_x, item_h/2))
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
                _item:setPosition(CCPoint(start_x+(ii-1)*step_x, item_h/2))
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
        height = 206,
    }
    local scroll = lineScroll.create(scroll_params)
    scroll:setAnchorPoint(CCPoint(0, 0))
    scroll:setPosition(CCPoint(10, 3))
    board:addChild(scroll)
    layer.scroll = scroll

    local function sortValue(_obj)
        return _obj.id
    end
    table.sort(acts, function(a, b)
        return sortValue(a) < sortValue(b)
    end)
    
    local function showList(listObjs)
        for ii=1,#listObjs do
            if ii == 1 then
                scroll.addSpace(3)
            end
            local tmp_item = createItem(listObjs[ii])
            tmp_item.obj = listObjs[ii]
            tmp_item.ax = 0.5
            tmp_item.px = scroll_params.width/2
            scroll.addItem(tmp_item)
            if ii ~= item_count then
                scroll.addSpace(1)
            end
        end
        scroll.setOffsetBegin()
    end
    showList(acts)

    local last_update = os.time() - 1
    local function onUpdate(ticks)
        if os.time() - last_update < 1 then return end
        last_update = os.time()
        local remain_cd = acts[1].cd - (os.time() - activityData.pull_time)
        if remain_cd >= 0 then
            local time_str = time2string(remain_cd)
            lbl_cd:setString(time_str)
        else
        end
    end
    layer:scheduleUpdateWithPriorityLua(onUpdate, 0)

    img.unload(img.packedOthers.ui_activity_summon)
    require("ui.activity.ban").addBan(layer, scroll)
    layer:setTouchSwallowEnabled(false)
    layer:setTouchEnabled(true)
    return layer
end

return ui
