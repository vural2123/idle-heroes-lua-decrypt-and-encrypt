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
    IDS.SPRINGBABY_1.ID,
    IDS.SPRINGBABY_2.ID,
    IDS.SPRINGBABY_3.ID,
    IDS.SPRINGBABY_4.ID,
    IDS.SPRINGBABY_5.ID,
    IDS.SPRINGBABY_6.ID,
    IDS.SPRINGBABY_7.ID,
    IDS.SPRINGBABY_8.ID,
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

    img.unload(img.packedOthers.ui_activity_spring)
    img.unload(img.packedOthers.ui_activity_spring_cn)
    if i18n.getCurrentLanguage() == kLanguageChinese 
        or i18n.getCurrentLanguage() == kLanguageChineseTW then
        img.load(img.packedOthers.ui_activity_spring_cn)
    else
        img.load(img.packedOthers.ui_activity_spring)
    end
    local banner = img.createUISprite(img.ui.activity_spring_board)
    banner:setAnchorPoint(CCPoint(0.5, 1))
    banner:setPosition(CCPoint(board_w/2-10, board_h-8))
    board:addChild(banner)

    local lbl_cd = lbl.createFont2(14, "", ccc3(0xa5, 0xfd, 0x47))
    lbl_cd:setAnchorPoint(CCPoint(0, 0.5))
    lbl_cd:setPosition(CCPoint(220, 74))
    banner:addChild(lbl_cd)
    local lbl_cd_des = lbl.createFont2(14, i18n.global.activity_to_end.string)
    lbl_cd_des:setAnchorPoint(CCPoint(0, 0.5))
    lbl_cd_des:setPosition(CCPoint(295, 74))
    banner:addChild(lbl_cd_des)

    local coin_bg = img.createUI9Sprite(img.ui.main_coin_bg) 
    coin_bg:setPreferredSize(CCSizeMake(174, 40))
    coin_bg:setPosition(CCPoint(banner:getContentSize().width/2, 40))
    banner:addChild(coin_bg)
    local coin_icon = img.createItemIcon2(ITEM_ID_SPRINGBABY)
    --coin_icon:setScale(0.9)
    coin_icon:setPosition(CCPoint(8, coin_bg:getContentSize().height/2+3))
    coin_bg:addChild(coin_icon)
    local lbl_coin = lbl.createFont2(16, "12345")
    lbl_coin:setPosition(CCPoint(92, coin_bg:getContentSize().height/2+3))
    coin_bg:addChild(lbl_coin)
    local function updateCoin()
        local itemObj = bagData.items.find(ITEM_ID_SPRINGBABY)
        if not itemObj then
            itemObj = {id=ITEM_ID_SPRINGBABY, num=0}
        end
        lbl_coin:setString(itemObj.num)
    end
    updateCoin()

    local function createItem(vpObj)
        local cfgObj = vpObj.cfg
        local temp_item = img.createUISprite(img.ui.casino_shop_frame)
        local item_w = temp_item:getContentSize().width
        local item_h = temp_item:getContentSize().height
        -- rewards
        local rewards = cfgObj.rewards
        local _obj = rewards[1]
        if _obj.type == ItemType.Equip then  -- equip
            local _item0 = img.createEquip(_obj.id, _obj.num)
            local _item = CCMenuItemSprite:create(_item0, nil)
            _item:setScale(0.9)
            _item:setPosition(CCPoint(item_w/2, item_h/2+9))
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
            _item:setScale(0.9)
            _item:setPosition(CCPoint(item_w/2, item_h/2+9))
            local _item_menu = CCMenu:createWithItem(_item)
            _item_menu:setPosition(CCPoint(0, 0))
            temp_item:addChild(_item_menu)
            _item:registerScriptTapHandler(function()
                audio.play(audio.button)
                layer:getParent():getParent():addChild(tipsitem.createForShow({id=_obj.id}), 1000)
            end)
        end
        -- btn
        local btn0 = img.createUISprite(img.ui.casino_shop_btn)
        local icon = img.createItemIcon2(ITEM_ID_SPRINGBABY)
        icon:setScale(0.8)
        icon:setPosition(CCPoint(27, btn0:getContentSize().height/2))
        btn0:addChild(icon)
        local lbl_price = lbl.createFont2(16, cfgObj.instruct)
        lbl_price:setPosition(CCPoint(74, btn0:getContentSize().height/2))
        btn0:addChild(lbl_price)
        local btn = SpineMenuItem:create(json.ui.button, btn0)
        btn:setPosition(CCPoint(item_w/2, 4))
        local btn_menu = CCMenu:createWithItem(btn)
        btn_menu:setPosition(CCPoint(0, 0))
        temp_item:addChild(btn_menu)
        btn:registerScriptTapHandler(function()
            audio.play(audio.button)
            local itemObj = bagData.items.find(ITEM_ID_SPRINGBABY)
            if not itemObj then
                itemObj = {id=ITEM_ID_SPRINGBABY, num=0}
            end
            if itemObj.num < cfgObj.instruct then
                showToast(i18n.global.springbb_not_enough.string)
                return
            end
            local param = {
                sid = player.sid,
                id = vpObj.id,
            }
            addWaitNet()
            netClient:exchange_act(param, function(__data)
                tbl2string(__data)
                if __data.status ~= 0 then
                    delWaitNet()
                    showToast(i18n.global.springbb_not_enough.string)
                    return
                end
                itemObj.num = itemObj.num - cfgObj.instruct
                delWaitNet()
                updateCoin()
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
    scroll:setPosition(CCPoint(5, 3))
    board:addChild(scroll)
    layer.scroll = scroll

    local function sortValue(_obj)
        if _obj.limits <= 0 then
            return 10000 + _obj.id
        else
            return _obj.id
        end
    end
    --table.sort(vps, function(a, b)
    --    return sortValue(a) < sortValue(b)
    --end)
    local ITEM_PER_ROW = 3
    local start_x = 101
    local step_x = 170
    local start_y = -73
    local step_y = -161
    local function showList(listObjs)
        for ii=1,#listObjs do
            --if ii == 1 then
            --    scroll.addSpace(3)
            --end
            local _x = start_x + (ii-1)%ITEM_PER_ROW * step_x
            local _y = start_y + math.floor((ii+ITEM_PER_ROW-1)/ITEM_PER_ROW-1) * step_y
            local tmp_item = createItem(listObjs[ii])
            tmp_item.obj = listObjs[ii]
            tmp_item:setPosition(CCPoint(_x, _y))
            scroll.content_layer:addChild(tmp_item)
        end
        local content_h = 0 - start_y - math.floor((#listObjs+ITEM_PER_ROW-1)/ITEM_PER_ROW-1)*step_y - step_y/2
        scroll:setContentSize(CCSizeMake(scroll.width, content_h))
        scroll.content_layer:setPosition(CCPoint(0, content_h))
        scroll:setContentOffset(CCPoint(0, scroll.height-content_h))
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
