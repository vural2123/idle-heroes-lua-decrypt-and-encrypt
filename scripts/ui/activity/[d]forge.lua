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
		IDS.FORGE_1.ID,
		IDS.FORGE_2.ID,
	}

    local layer = CCLayer:create()

    local event_des = {
        [1] = i18n.global.act_forge_task_6.string,
        [2] = i18n.global.act_forge_task_5.string,
    }

    local acts = {}
    for _, v in ipairs(act_ids) do
        local tmp_status = activityData.getStatusById(v)
		if tmp_status then
			acts[#acts+1] = tmp_status
		end
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

    --img.unload(img.packedOthers.ui_activity_forge)
    --img.unload(img.packedOthers.ui_activity_forge_cn)
    --if i18n.getCurrentLanguage() == kLanguageChinese then
        --img.load(img.packedOthers.ui_activity_forge_cn)
    --else
        img.load(img.packedOthers.ui_activity_forge)
    --end
    local banner
    if i18n.getCurrentLanguage() == kLanguageKorean then
        banner = img.createUISprite("activity_forge_board_kr.png")
    elseif i18n.getCurrentLanguage() == kLanguageChineseTW then
        banner = img.createUISprite("activity_forge_board_tw.png")
    elseif i18n.getCurrentLanguage() == kLanguageJapanese then
        banner = img.createUISprite("activity_forge_board_jp.png")
    elseif i18n.getCurrentLanguage() == kLanguageRussian then
        banner = img.createUISprite("activity_forge_board_ru.png")
    elseif i18n.getCurrentLanguage() == kLanguagePortuguese then
        banner = img.createUISprite("activity_forge_board_kp.png")
    elseif i18n.getCurrentLanguage() == kLanguageChinese then
        banner = img.createUISprite("activity_forge_board_cn.png")
    else
        banner = img.createUISprite(img.ui.activity_forge_board)
    end
    banner:setAnchorPoint(CCPoint(0.5, 1))
    banner:setPosition(CCPoint(board_w/2, board_h-10))
    board:addChild(banner)

    local lbl_cd_des = lbl.createFont2(14, i18n.global.activity_to_end.string)
    lbl_cd_des:setAnchorPoint(CCPoint(0, 0.5))
    lbl_cd_des:setPosition(CCPoint(322, 24))
    banner:addChild(lbl_cd_des)
    local lbl_cd = lbl.createFont2(14, "", ccc3(0xa5, 0xfd, 0x47))
    lbl_cd:setAnchorPoint(CCPoint(1, 0.5))
    lbl_cd:setPosition(CCPoint(lbl_cd_des:boundingBox():getMinX()-6, 24))
    banner:addChild(lbl_cd)

    if i18n.getCurrentLanguage() == kLanguageRussian then
        lbl_cd_des:setPosition(CCPoint(322-76, 24))
        lbl_cd:setAnchorPoint(CCPoint(0, 0.5))
        lbl_cd:setPosition(CCPoint(lbl_cd_des:boundingBox():getMaxX()+10, 24))
    end

    local function createItem(vpObj, i)
        local temp_item = img.createUI9Sprite(img.ui.bottom_border_2)
        temp_item:setPreferredSize(CCSizeMake(542, 114))
        local item_w = temp_item:getContentSize().width
        local item_h = temp_item:getContentSize().height
        -- description
        local lbl_des = lbl.create({font=1, size=14, text=vpObj.des, 
                    color=ccc3(0x61, 0x34, 0x2a), width=300, align=kCCTextAlignmentLeft})
        lbl_des:setAnchorPoint(CCPoint(0, 0.5))
        lbl_des:setPosition(CCPoint(22, item_h-22))
        temp_item:addChild(lbl_des)

        local limitLabel = lbl.createFont1(14, i18n.global.activity_limit.string, ccc3(0x73, 0x3b, 0x05))
        limitLabel:setPosition(CCPoint(466, item_h-46))
        temp_item:addChild(limitLabel)

        local limitLabel = lbl.createFont1(18, acts[i].cfg.mergeLimit - acts[i].limits .. "/" .. acts[i].cfg.mergeLimit, ccc3(0xa4, 0x45, 0x24))
        limitLabel:setPosition(CCPoint(466, 46))
        temp_item:addChild(limitLabel)
        -- icon
        --local head = img.createUISprite(vpObj.icon)
        --head:setScale(0.85)
        --head:setPosition(CCPoint(308, item_h/2))
        --temp_item:addChild(head)
        -- arrow
        --local icon_arrow = img.createUISprite(img.ui.arrow)
        --icon_arrow:setPosition(CCPoint(392, item_h/2))
        --temp_item:addChild(icon_arrow)
        -- rewards
        local start_x = 50
        local step_x = 68
        local rewards = vpObj.cfg.rewards
        for ii=1,#rewards do
            local _obj = rewards[ii]
            if _obj.type == ItemType.Equip then  -- equip
                local _item0 = img.createEquip(_obj.id, _obj.num)
                local _item = CCMenuItemSprite:create(_item0, nil)
                _item:setAnchorPoint(0.5, 0)
                _item:setScale(0.7)
                _item:setPosition(CCPoint(start_x+(ii-1)*step_x, 20))
                if acts[i].limits == 0 then
                    setShader(_item, SHADER_GRAY, true)
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
                _item:setAnchorPoint(0.5, 0)
                _item:setScale(0.7)
                _item:setPosition(CCPoint(start_x+(ii-1)*step_x, 20))
                if acts[i].limits == 0 then
                    setShader(_item, SHADER_GRAY, true)
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
        height = 235,
    }
    local scroll = lineScroll.create(scroll_params)
    scroll:setAnchorPoint(CCPoint(0, 0))
    scroll:setPosition(CCPoint(10, 6))
    board:addChild(scroll)
    layer.scroll = scroll

    --local function sortValue(_obj)
    --    return _obj.id
    --end
    --table.sort(acts, function(a, b)
    --    return sortValue(a) < sortValue(b)
    --end)
    
    local function showList(listObjs)
        for ii=1,#listObjs do
            if ii == 1 then
                scroll.addSpace(3)
            end
            local tmp_item = createItem(listObjs[ii], ii)
            tmp_item.obj = listObjs[ii]
            tmp_item.ax = 0.5
            tmp_item.px = scroll_params.width/2
            scroll.addItem(tmp_item)
            if ii ~= item_count then
                scroll.addSpace(0)
            end
        end
        scroll.setOffsetBegin()
    end
	for i=1, #acts do
		if i % 2 == 1 then
			acts[i].icon = img.ui.activity_forge_head_icon1
		else
			acts[i].icon = img.ui.activity_forge_head_icon2
		end
		acts[i].des = event_des[i]
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
