local ui = {}

require "common.func"
local view = require "common.view"
local i18n = require "res.i18n"
local lbl = require "res.lbl"
local img = require "res.img"
local audio = require "res.audio"
local json = require "res.json"
local cfgstore = require "config.store"
local player = require "data.player"
local bagdata = require "data.bag"
local activityData = require "data.activity"
local NetClient = require "net.netClient"
local netClient = NetClient:getInstance()
local tipsequip = require "ui.tips.equip"
local tipsitem = require "ui.tips.item"

local ItemType = {
	Item = 1,
	Equip = 2,
}

function ui.create()
	local IDS = activityData.IDS
	
    local layer = CCLayer:create()

    local vps = {}
	local vp_id = IDS.BLACKBOX_1.ID
    for i=0, 9 do
        local tmp_status = activityData.getStatusById(vp_id + i)
		if not tmp_status then break end
        vps[#vps+1] = tmp_status
    end

    local board = CCSprite:create()
    board:setContentSize(CCSizeMake(570, 438))
    board:setScale(view.minScale)
    board:setAnchorPoint(CCPoint(0, 0))
    board:setPosition(scalep(362, 60))
    layer:addChild(board)
    --drawBoundingbox(layer, board)
    local board_w = board:getContentSize().width
    local board_h = board:getContentSize().height

    img.load(img.packedOthers.ui_activity_blackbox)
    local banner = img.createUISprite("activity_chest_board.png")
    local bannerLabel
    if i18n.getCurrentLanguage() == kLanguageKorean then
        bannerLabel = img.createUISprite("activity_chest_kr.png")
    elseif i18n.getCurrentLanguage() == kLanguageChinese then
        bannerLabel = img.createUISprite("activity_chest_cn.png")
    elseif i18n.getCurrentLanguage() == kLanguageChineseTW then
        bannerLabel = img.createUISprite("activity_chest_tw.png")
    elseif i18n.getCurrentLanguage() == kLanguageJapanese then
        bannerLabel = img.createUISprite("activity_chest_jp.png")
    elseif i18n.getCurrentLanguage() == kLanguageRussian then
        bannerLabel = img.createUISprite("activity_chest_ru.png")
    elseif i18n.getCurrentLanguage() == kLanguagePortuguese then
        bannerLabel = img.createUISprite("activity_chest_pt.png")
    --elseif i18n.getCurrentLanguage() == kLanguageSpanish then
    --    banner = img.createUISprite("activity_blackbox_board_sp.png")
    else
        bannerLabel = img.createUISprite("activity_chest.png")
    end
    banner:setAnchorPoint(CCPoint(0.5, 1))
    banner:setPosition(CCPoint(board_w/2-10, board_h-8))
    board:addChild(banner)

    bannerLabel:setAnchorPoint(CCPoint(0.5, 1))
    bannerLabel:setPosition(CCPoint(board_w/2+80, board_h-30))
    board:addChild(bannerLabel)

    local lbl_cd_des = lbl.createFont2(14, i18n.global.activity_to_end.string)
    lbl_cd_des:setAnchorPoint(CCPoint(1, 0.5))
    lbl_cd_des:setPosition(CCPoint(225+180, 28))
    banner:addChild(lbl_cd_des)
    local lbl_cd = lbl.createFont2(14, "", ccc3(0xa5, 0xfd, 0x47))
    lbl_cd:setAnchorPoint(CCPoint(1, 0.5))
    lbl_cd:setPosition(CCPoint(lbl_cd_des:boundingBox():getMinX()-6, 28))
    banner:addChild(lbl_cd)

    if i18n.getCurrentLanguage() == kLanguageRussian then
        lbl_cd_des:setPosition(CCPoint(205+180-40, 28))
        lbl_cd:setAnchorPoint(CCPoint(0, 0.5))
        lbl_cd:setPosition(CCPoint(lbl_cd_des:boundingBox():getMaxX()+10, 28))
    end

    local function createItem(vpObj)
        local temp_item = img.createUI9Sprite(img.ui.bottom_border_2)
        temp_item:setPreferredSize(CCSizeMake(542, 90))
        local item_w = temp_item:getContentSize().width
        local item_h = temp_item:getContentSize().height
        -- rewards
        local start_x = 47
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
                    --layer:getParent():getParent():addChild(tipsequip.createById(_obj.id), 1000)
                    ui.createItemTip(layer, _obj.id)
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
                    --layer:getParent():getParent():addChild(tipsitem.createForShow({id=_obj.id}), 1000)
                    ui.createItemTip(layer, _obj.id)
                end)
            end
        end
        local cfgobj = vpObj.cfg
        -- btn_buy
        local limitLabel = lbl.createFont1(16, i18n.global.limitact_limit.string .. vpObj.limits, ccc3(0x73, 0x3b, 0x05))
        limitLabel:setPosition(CCPoint(466, 68))
        temp_item:addChild(limitLabel)
        local btn0 = img.createLogin9Sprite(img.login.button_9_small_gold)
        btn0:setPreferredSize(CCSizeMake(120, 45))
        local icon = img.createItemIcon2(ITEM_ID_GEM)
        icon:setScale(0.9)
        icon:setPosition(CCPoint(27, btn0:getContentSize().height/2))
        btn0:addChild(icon)
        local lbl_price = lbl.createFont2(14, cfgobj.extra[1].num)
        lbl_price:setPosition(CCPoint(27, 13))
        btn0:addChild(lbl_price)
        --local lbl_btn = lbl.createFont1(14, i18n.global.tips_buy.string, ccc3(0x73, 0x3b, 0x05))
        local lbl_btn = lbl.create({font=1, size=18, text=i18n.global.tips_buy.string, color=ccc3(0x73, 0x3b, 0x05),
                                pt={size=14}, es={size=14}
                            })
        lbl_btn:setPosition(CCPoint(75, 23))
        btn0:addChild(lbl_btn)
        local btn = SpineMenuItem:create(json.ui.button, btn0)
        btn:setPosition(CCPoint(466, 36))
        local btn_menu = CCMenu:createWithItem(btn)
        btn_menu:setPosition(CCPoint(0, 0))
        temp_item:addChild(btn_menu)
        if vpObj.status ~= 0 or vpObj.limits <= 0 then
            setShader(btn, SHADER_GRAY, true)
            btn:setEnabled(false)
            limitLabel:setVisible(false)
        end
        btn:registerScriptTapHandler(function()
            audio.play(audio.button)
            if bagdata.gem() < cfgobj.extra[1].num then
                showToast(i18n.global.gboss_fight_st6.string)
                return
            end
            addWaitNet().setTimeout(60)
            local params = {
                sid = player.sid,
                id = vpObj.id,
                num = 1,
            }
            netClient:exchange_act(params, function(__data)
                delWaitNet()
                tbl2string(__data)
                if __data.status ~= 0 then
                    showToast(i18n.global.gboss_fight_st6.string)
                    return
                end
                bagdata.subGem(cfgobj.extra[1].num)
                local reward = __data.affix
                if reward then
                    bagdata.addRewards(reward)
                    vpObj.limits = vpObj.limits - 1
                    if vpObj.limits <= 0 then
                        setShader(btn, SHADER_GRAY, true)
                        btn:setEnabled(false)
                        limitLabel:setVisible(false)
                    else
                        limitLabel:setString(i18n.global.limitact_limit.string .. vpObj.limits)
                    end
                    local rw = tablecp(reward)
                    arrayfilter(rw.items, function(t)
                        return t.id ~= ITEM_ID_VIP_EXP
                    end)
                    layer:addChild(require("ui.reward").createFloating(rw), 1000)
                end
            end)
        end)

        return temp_item
    end

    local lineScroll = require "ui.lineScroll"
    local scroll_params = {
        width = 550,
        height = 239,
    }
    local scroll = lineScroll.create(scroll_params)
    scroll:setAnchorPoint(CCPoint(0, 0))
    scroll:setPosition(CCPoint(0, 0))
    board:addChild(scroll)
    layer.scroll = scroll

    local function sortValue(_obj)
        return _obj.id
    end
    table.sort(vps, function(a, b)
        return sortValue(a) < sortValue(b)
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
            --if ii ~= item_count then
            --    scroll.addSpace(1)
            --end
        end
        scroll.setOffsetBegin()
    end
    showList(vps)

    local last_update = os.time() - 1
    local function onUpdate(ticks)
        if os.time() - last_update < 1 then return end
        last_update = os.time()
        local remain_cd = vps[1].cd - (os.time() - activityData.pull_time)
        if remain_cd >= 0 then
            local time_str = time2string(remain_cd)
            lbl_cd:setString(time_str)
        else
        end
    end
    layer:scheduleUpdateWithPriorityLua(onUpdate, 0)

    layer:registerScriptHandler(function(event)
        if event == "enter" then
        elseif event == "exit" then
            img.unload(img.packedOthers.ui_activity_blackbox)
        end
    end)

    require("ui.activity.ban").addBan(layer, scroll)
    layer:setTouchSwallowEnabled(false)
    layer:setTouchEnabled(true)

    return layer
end

function ui.createItemTip(parentLayer, itemId)
    local layer = CCLayer:create()
    local cfgitem = require "config.item"
    local itemObj = cfgitem[itemId]
    local giftId = itemObj.giftId
    local cfggift = require "config.gift"
    local giftObj = cfggift[giftId]
    if not giftObj or not giftObj.giftGoods or #giftObj.giftGoods < 1 then
        return
    end
    local start_x = 35
    local giftGoods = giftObj.giftGoods
    local bg = img.createUI9Sprite(img.ui.tips_bg)
    local bg_w = start_x +82*#giftGoods + 24*(#giftGoods-1) + start_x
    local bg_h = 35 + 82 + 35 + 40
    bg:setPreferredSize(CCSizeMake(bg_w, bg_h))
    bg:setScale(view.minScale)
    bg:setPosition(CCPoint(view.midX, view.midY))
    layer:addChild(bg)

    local tipstitle = lbl.createFont1(18, i18n.global.brave_baoxiang_tips.string, ccc3(0xff, 0xe4, 0x9c))
    tipstitle:setPosition(bg_w/2, 162)
    bg:addChild(tipstitle)

    local line = img.createUISprite(img.ui.help_line)
    line:setScaleX(bg_w*0.75/line:getContentSize().width)
    line:setPosition(CCPoint(bg_w/2, 142))
    bg:addChild(line)

    for ii=1,#giftGoods do
        local _obj = giftGoods[ii]
        if _obj.type == ItemType.Equip then  -- equip
            local _item0 = img.createEquip(_obj.id, _obj.num)
            local _item = CCMenuItemSprite:create(_item0, nil)
            _item:setScale(1.0)
            _item:setPosition(CCPoint(start_x+41+(ii-1)*106, 77))
            local _item_menu = CCMenu:createWithItem(_item)
            _item_menu:setPosition(CCPoint(0, 0))
            bg:addChild(_item_menu)
            _item:registerScriptTapHandler(function()
                audio.play(audio.button)
                layer:addChild(tipsequip.createById(_obj.id), 1000)
            end)
        elseif _obj.type == ItemType.Item then
            local _item0 = img.createItem(_obj.id, _obj.num)
            local _item = CCMenuItemSprite:create(_item0, nil)
            _item:setScale(1.0)
            _item:setPosition(CCPoint(start_x+41+(ii-1)*106, 77))
            local _item_menu = CCMenu:createWithItem(_item)
            _item_menu:setPosition(CCPoint(0, 0))
            bg:addChild(_item_menu)
            _item:registerScriptTapHandler(function()
                audio.play(audio.button)
                layer:addChild(tipsitem.createForShow({id=_obj.id}), 1000)
            end)
        end
    end
    
    -- 点击空白区域的回调
    local clickBlankHandler
    function layer.setClickBlankHandler(handler)
        clickBlankHandler = handler
    end

    local function onTouch(eventType, x, y)
        if eventType == "began" then   
            return true
        elseif eventType == "moved" then
            return 
        else
            if not bg:boundingBox():containsPoint(ccp(x, y)) then
                layer.onAndroidBack()
            end
        end
    end

    addBackEvent(layer)

    function layer.onAndroidBack()
        if clickBlankHandler then
            clickBlankHandler()
        else
            layer:removeFromParent()
        end
    end

    layer:registerScriptHandler(function(event)
        if event == "enter" then
            layer.notifyParentLock()
        elseif event == "exit" then
            layer.notifyParentUnlock()
        end
    end)

    layer:registerScriptTouchHandler(onTouch)
    layer:setTouchSwallowEnabled(false)
    layer:setTouchEnabled(true)
    parentLayer:getParent():getParent():addChild(layer, 999)
end

return ui
