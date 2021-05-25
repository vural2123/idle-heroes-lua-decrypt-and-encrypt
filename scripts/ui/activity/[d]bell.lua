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
local bagData = require "data.bag"
local activityData = require "data.activity"
local NetClient = require "net.netClient"
local netClient = NetClient:getInstance()
local tipsequip = require "ui.tips.equip"
local tipsitem = require "ui.tips.item"
local uirewards = require "ui.reward"

local IDS = activityData.IDS
local ItemType = {
    Item = 1,
    Equip = 2,
}

local vp_ids = {
    IDS.FISHBABY_1.ID,
    IDS.FISHBABY_2.ID,
    IDS.FISHBABY_3.ID,
    IDS.FISHBABY_4.ID,
    IDS.FISHBABY_5.ID,
    IDS.FISHBABY_6.ID,
    IDS.FISHBABY_7.ID,
    IDS.FISHBABY_8.ID,
    IDS.FISHBABY_9.ID,
    IDS.FISHBABY_10.ID,
    IDS.FISHBABY_11.ID,
}

local STATE = {
    LOCK = 1,
    GET = 2,
    FINISH = 3,
}

local function getVpState(vpObj)
    if vpObj.limits < 1 then return STATE.FINISH end
    return STATE.GET
end

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

    img.unload(img.packedOthers.ui_activity_fish)
    img.unload(img.packedOthers.ui_activity_fish_cn)
    if i18n.getCurrentLanguage() == kLanguageChinese 
        or i18n.getCurrentLanguage() == kLanguageChineseTW then
        img.load(img.packedOthers.ui_activity_fish_cn)
    else
        img.load(img.packedOthers.ui_activity_fish)
    end
    local banner
    if i18n.getCurrentLanguage() == kLanguageKorean then
        banner = img.createUISprite("activity_newyear_board_kr.png")
    elseif i18n.getCurrentLanguage() == kLanguageRussian then
        banner = img.createUISprite("activity_newyear_board_ru.png")
    elseif i18n.getCurrentLanguage() == kLanguageJapanese then
        banner = img.createUISprite("activity_newyear_board_jp.png")
    else
        banner = img.createUISprite(img.ui.activity_newyear_board)
    end
    banner:setAnchorPoint(CCPoint(0.5, 1))
    banner:setPosition(CCPoint(board_w/2-10, board_h-8))
    board:addChild(banner)

    local lbl_cd = lbl.createFont2(14, "", ccc3(0xa5, 0xfd, 0x47))
    lbl_cd:setAnchorPoint(CCPoint(0, 0.5))
    lbl_cd:setPosition(CCPoint(213+75, 30))
    banner:addChild(lbl_cd)
    local lbl_cd_des = lbl.createFont2(14, i18n.global.activity_to_end.string)
    lbl_cd_des:setAnchorPoint(CCPoint(0, 0.5))
    lbl_cd_des:setPosition(CCPoint(295+75, 30))
    banner:addChild(lbl_cd_des)

    local coin_bg = img.createUI9Sprite(img.ui.main_coin_bg) 
    coin_bg:setPreferredSize(CCSizeMake(174, 40))
    coin_bg:setPosition(CCPoint(banner:getContentSize().width/2+75, 60))
    banner:addChild(coin_bg)
    local coin_icon = img.createItemIcon2(ITEM_ID_MAGICGLIM)
    --coin_icon:setScale(0.9)
    coin_icon:setPosition(CCPoint(8, coin_bg:getContentSize().height/2+3))
    coin_bg:addChild(coin_icon)
    local lbl_coin = lbl.createFont2(16, "12345")
    lbl_coin:setPosition(CCPoint(92, coin_bg:getContentSize().height/2+3))
    coin_bg:addChild(lbl_coin)
    local function updateCoin()
        local itemObj = bagData.items.find(ITEM_ID_MAGICGLIM)
        if not itemObj then
            itemObj = {id=ITEM_ID_MAGICGLIM, num=0}
        end
        lbl_coin:setString(itemObj.num)
    end
    updateCoin()

    local btns = {}
    local btns_lock = {}
    local function createItem(vpObj)
        local cfgObj = vpObj.cfg
        local temp_item = img.createUI9Sprite(img.ui.bottom_border_2)
        temp_item:setPreferredSize(CCSizeMake(542, 86))
        local item_w = temp_item:getContentSize().width
        local item_h = temp_item:getContentSize().height
        -- rewards
        local start_x = 47
        local step_x = 66
        local rewards = cfgObj.rewards
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
        -- btn
        --local limitLabel = lbl.createFont1(16, i18n.global.limitact_limit.string .. vpObj.limits, ccc3(0x73, 0x3b, 0x05))
        --limitLabel:setPosition(CCPoint(458, 68))
        --temp_item:addChild(limitLabel)
        local btn0 = img.createLogin9Sprite(img.login.button_9_small_gold)
        btn0:setPreferredSize(CCSizeMake(120, 45))
        local icon = img.createItemIcon2(ITEM_ID_MAGICGLIM)
        icon:setScale(0.9)
        icon:setPosition(CCPoint(27, btn0:getContentSize().height/2))
        btn0:addChild(icon)
        local lbl_price = lbl.createFont2(14, cfgObj.extra[1].num)
        lbl_price:setPosition(CCPoint(27, 13))
        btn0:addChild(lbl_price)
        local lbl_btn = lbl.createMixFont1(14, i18n.global.task_btn_claim.string, ccc3(0x73, 0x3b, 0x05))
        lbl_btn:setPosition(CCPoint(75, btn0:getContentSize().height/2))
        btn0:addChild(lbl_btn)
        local btn = SpineMenuItem:create(json.ui.button, btn0)
        btn:setPosition(CCPoint(458, 43))
        local btn_menu = CCMenu:createWithItem(btn)
        btn_menu:setPosition(CCPoint(0, 0))
        temp_item:addChild(btn_menu)
        btns[vpObj.id] = btn
        local icon_recv = img.createUISprite(img.ui.achieve_calim)
        icon_recv:setPosition(CCPoint(458, item_h/2))
        temp_item:addChild(icon_recv)
        local btn_lock0 = img.createLogin9Sprite(img.login.button_9_small_gold)
        btn_lock0:setPreferredSize(CCSizeMake(120, 45))
        local icon2 = img.createItemIcon2(ITEM_ID_MAGICGLIM)
        icon2:setScale(0.9)
        icon2:setPosition(CCPoint(27, btn_lock0:getContentSize().height/2))
        btn_lock0:addChild(icon2)
        local lbl_price2 = lbl.createFont2(14, cfgObj.extra[1].num)
        lbl_price2:setPosition(CCPoint(27, 13))
        btn_lock0:addChild(lbl_price2)
        local iconx = img.createUISprite(img.ui.devour_icon_lock)
        iconx:setPosition(CCPoint(75, btn_lock0:getContentSize().height/2))
        btn_lock0:addChild(iconx)
        local btn_lock = SpineMenuItem:create(json.ui.button, btn_lock0)
        btn_lock:setPosition(CCPoint(458, 43))
        local btn_lock_menu = CCMenu:createWithItem(btn_lock)
        btn_lock_menu:setPosition(CCPoint(0, 0))
        temp_item:addChild(btn_lock_menu)
        btns_lock[vpObj.id] = btn_lock
        btn_lock:registerScriptTapHandler(function()
            audio.play(audio.button)
            showToast(i18n.global.unlock_last.string)
        end)
        local vstate = getVpState(vpObj)
        if vstate == STATE.LOCK then
            btn_lock:setVisible(true)
            icon_recv:setVisible(false)
            btn:setVisible(false)
        elseif vstate == STATE.GET then
            btn_lock:setVisible(false)
            icon_recv:setVisible(false)
            btn:setVisible(true)
        elseif vstate == STATE.FINISH then
            icon_recv:setVisible(true)
            btn:setVisible(false)
            btn_lock:setVisible(false)
        end
        btn:registerScriptTapHandler(function()
            audio.play(audio.button)
            local itemObj = bagData.items.find(ITEM_ID_MAGICGLIM)
            if not itemObj then
                itemObj = {id=ITEM_ID_MAGICGLIM, num=0}
            end
            local vpstate = getVpState(vpObj)
            if vpstate == STATE.LOCK then
                showToast(i18n.global.unlock_last.string)
                return
            elseif itemObj.num < cfgObj.extra[1].num then
                showToast(i18n.global.pet_smaterial_not_enough.string)
                return
            end
            local param = {
                sid = player.sid,
                id = vpObj.id,
                num = 1,
            }
            addWaitNet()
            netClient:exchange_act(param, function(__data)
                tbl2string(__data)
                if __data.status ~= 0 then
                    delWaitNet()
                    showToast(i18n.global.pet_smaterial_not_enough.string)
                    return
                end
                itemObj.num = itemObj.num - cfgObj.extra[1].num
                vpObj.limits = vpObj.limits - 1
                delWaitNet()
                updateCoin()
                --setShader(btn, SHADER_GRAY, true)
                btn:setEnabled(false)
                btn:setVisible(false)
                btn_lock:setVisible(false)
                icon_recv:setVisible(true)
                --limitLabel:setVisible(false)
                if btns[vpObj.id+1] then
                    --clearShader(btns[vpObj.id+1], true)
                    btns[vpObj.id+1]:setVisible(true)
                    btns[vpObj.id+1]:setEnabled(true)
                end
                if btns_lock[vpObj.id+1] then
                    btns_lock[vpObj.id+1]:setVisible(false)
                    btns_lock[vpObj.id+1]:setEnabled(false)
                end
                -- show affix
                if __data.affix then
                    bagData.addRewards(__data.affix)
                    CCDirector:sharedDirector():getRunningScene():addChild(uirewards.createFloating(__data.affix), 100000)
                end
            end)
        end)

        return temp_item
    end

    local lineScroll = require "ui.lineScroll"
    local scroll_params = {
        width = 550,
        height = 215,
    }
    local scroll = lineScroll.create(scroll_params)
    scroll:setAnchorPoint(CCPoint(0, 0))
    scroll:setPosition(CCPoint(0, 3))
    board:addChild(scroll)
    layer.scroll = scroll

    local function sortValue(_obj)
        if _obj.limits <= 0 then
            return 10000 + _obj.id
        else
            return _obj.id
        end
    end
    table.sort(vps, function(a, b)
        return sortValue(a) < sortValue(b)
    end)
    local ITEM_PER_ROW = 1
    local start_x = 101
    local step_x = 170
    local start_y = -73
    local step_y = -161
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
