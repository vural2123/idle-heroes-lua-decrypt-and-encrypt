local ui = {}

require "common.func"
local view = require "common.view"
local i18n = require "res.i18n"
local lbl = require "res.lbl"
local img = require "res.img"
local audio = require "res.audio"
local json = require "res.json"
local cfgactivity = require "config.activity"
local cfgstore = require "config.store"
local player = require "data.player"
local activityData = require "data.activity"
local NetClient = require "net.netClient"
local netClient = NetClient:getInstance()
local tipsequip = require "ui.tips.equip"
local tipsitem = require "ui.tips.item"

local IDS = activityData.IDS
local ItemType = {
    Item = 1,
    Equip = 2,
}

local vp_ids = {
    IDS.VP_1.ID,
    IDS.VP_2.ID,
    IDS.VP_3.ID,
    IDS.VP_4.ID,
    --IDS.VP_5.ID,
    --IDS.VP_6.ID,
    --IDS.VP_7.ID,
}

function ui.create()
    local layer = CCLayer:create()

    local vps = {}
    for _, v in ipairs(vp_ids) do
        local tmp_status = activityData.getStatusById(v)
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

    img.unload(img.packedOthers.ui_activity_vp)
    --if i18n.getCurrentLanguage() == kLanguageChinese then
    --    img.load(img.packedOthers.ui_activity_vp_cn)
    --else
        img.load(img.packedOthers.ui_activity_vp)
    --end
    local banner
    if i18n.getCurrentLanguage() == kLanguageKorean then
        banner = img.createUISprite("activity_hw_board_kr.png")
    elseif i18n.getCurrentLanguage() == kLanguageChineseTW then
        banner = img.createUISprite("activity_hw_board_tw.png")
    elseif i18n.getCurrentLanguage() == kLanguageJapanese then
        banner = img.createUISprite("activity_hw_board_jp.png")
    elseif i18n.getCurrentLanguage() == kLanguageRussian then
        banner = img.createUISprite("activity_hw_board_ru.png")
    elseif i18n.getCurrentLanguage() == kLanguageChinese then
        banner = img.createUISprite("activity_hw_board_cn.png")
    elseif i18n.getCurrentLanguage() == kLanguagePortuguese then
        banner = img.createUISprite("activity_hw_board_pt.png")
    elseif i18n.getCurrentLanguage() == kLanguageSpanish then
        banner = img.createUISprite("activity_hw_board_sp.png")
    elseif i18n.getCurrentLanguage() == kLanguageTurkish then
        banner = img.createUISprite("activity_hw_board_tr.png")
    else
        banner = img.createUISprite(img.ui.activity_hw_board)
    end
    banner:setAnchorPoint(CCPoint(0.5, 1))
    banner:setPosition(CCPoint(board_w/2-10, board_h-8))
    board:addChild(banner)

    local lbl_cd_des = lbl.createFont2(14, i18n.global.activity_to_end.string)
    lbl_cd_des:setAnchorPoint(CCPoint(1, 0.5))
    lbl_cd_des:setPosition(CCPoint(205+310, 28))
    banner:addChild(lbl_cd_des)
    local lbl_cd = lbl.createFont2(14, "", ccc3(0xa5, 0xfd, 0x47))
    lbl_cd:setAnchorPoint(CCPoint(1, 0.5))
    lbl_cd:setPosition(CCPoint(lbl_cd_des:boundingBox():getMinX()-6, 28))
    banner:addChild(lbl_cd)

    if i18n.getCurrentLanguage() == kLanguageRussian then
        lbl_cd_des:setPosition(CCPoint(205+310-40, 28))
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
        -- vip scores
        local storeObj = cfgstore[cfgactivity[vpObj.id].storeId]
        local lbl_vip_des = lbl.createFont1(16, "VIP EXP", ccc3(0x73, 0x3b, 0x05))
        lbl_vip_des:setPosition(CCPoint(341, 60))
        temp_item:addChild(lbl_vip_des)
        local scores = storeObj.vipExp
        local lbl_vip_exp = lbl.createFont1(22, "+" .. scores, ccc3(0x9c, 0x45, 0x2d))
        lbl_vip_exp:setScaleX(0.7)
        lbl_vip_exp:setPosition(CCPoint(341, 36))
        temp_item:addChild(lbl_vip_exp)
        -- btn_buy
        local limitLabel = lbl.createFont1(16, i18n.global.limitact_limit.string .. vpObj.limits, ccc3(0x73, 0x3b, 0x05))
        limitLabel:setPosition(CCPoint(466, 68))
        temp_item:addChild(limitLabel)
        local btn0 = img.createLogin9Sprite(img.login.button_9_small_gold)
        btn0:setPreferredSize(CCSizeMake(117, 45))
        local item_price = storeObj.priceStr
        if isAmazon() then
        elseif APP_CHANNEL and APP_CHANNEL ~= "" then
            item_price = storeObj.priceCnStr
        elseif i18n.getCurrentLanguage() == kLanguageChinese then
            item_price = storeObj.priceCnStr
        end
        local shopData = require"data.shop"
        item_price = shopData.getPriceByPayId(storeObj.payId, item_price)
        local lbl_btn = lbl.createFontTTF(18, item_price, ccc3(0x73, 0x3b, 0x05))
        lbl_btn:setPosition(CCPoint(59, 23))
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
            addWaitNet().setTimeout(60)
            require("common.iap").pay(storeObj.payId, function(reward)
                delWaitNet()
                if reward then
                    require("data.bag").addRewards(reward)
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
        height = 279,
    }
    local scroll = lineScroll.create(scroll_params)
    scroll:setAnchorPoint(CCPoint(0, 0))
    scroll:setPosition(CCPoint(0, 0))
    board:addChild(scroll)
    layer.scroll = scroll

    local function sortValue(_obj)
        if _obj.limits <= 0 then
            return 10000 + _obj.id
        elseif _obj.id == IDS.VP_1.ID then
            return _obj.id - 100
        else
            return _obj.id
        end
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

    require("ui.activity.ban").addBan(layer, scroll)
    layer:setTouchSwallowEnabled(false)
    layer:setTouchEnabled(true)

    return layer
end

return ui
