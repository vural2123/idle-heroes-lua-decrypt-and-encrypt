local ui = {}

require "common.func"
local view = require "common.view"
local i18n = require "res.i18n"
local lbl = require "res.lbl"
local img = require "res.img"
local audio = require "res.audio"
local json = require "res.json"
local cfgheromarket = require "config.heromarket"
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

function ui.create()
    local layer = CCLayer:create()

    local HMIDS = { 57, 58,}
    local act = activityData.getStatusById(IDS.EXCHANGE.ID)

    local board = CCSprite:create()
    board:setContentSize(CCSizeMake(570, 438))
    board:setScale(view.minScale)
    board:setAnchorPoint(CCPoint(0, 0))
    board:setPosition(scalep(352, 57))
    layer:addChild(board)
    --drawBoundingbox(layer, board)
    local board_w = board:getContentSize().width
    local board_h = board:getContentSize().height

    --img.unload(img.packedOthers.ui_activity_exchange)
    --img.unload(img.packedOthers.ui_activity_exchange_cn)
    --if i18n.getCurrentLanguage() == kLanguageChinese then
    --    img.load(img.packedOthers.ui_activity_exchange_cn)
    --else
    img.load(img.packedOthers.ui_activity_exchange)
    --end
    local banner
    if i18n.getCurrentLanguage() == kLanguageKorean then
        banner = img.createUISprite("activity_exchange_board_kr.png")
    elseif i18n.getCurrentLanguage() == kLanguageChineseTW then
        banner = img.createUISprite("activity_exchange_board_tw.png")
    elseif i18n.getCurrentLanguage() == kLanguageJapanese then
        banner = img.createUISprite("activity_exchange_board_jp.png")
    elseif i18n.getCurrentLanguage() == kLanguageRussian then
        banner = img.createUISprite("activity_exchange_board_ru.png")
    elseif i18n.getCurrentLanguage() == kLanguageChinese then
        banner = img.createUISprite("activity_exchange_board_cn.png")
    else
        banner = img.createUISprite(img.ui.activity_exchange_board)
    end
    banner:setAnchorPoint(CCPoint(0.5, 1))
    banner:setPosition(CCPoint(board_w/2, board_h-8))
    board:addChild(banner)


    local lbl_cd = lbl.createFont2(14, "", ccc3(0xa5, 0xfd, 0x47))
    lbl_cd:setAnchorPoint(CCPoint(0, 0.5))
    lbl_cd:setPosition(CCPoint(106, 32))
    banner:addChild(lbl_cd)
    local lbl_cd_des = lbl.createFont2(14, i18n.global.activity_to_end.string)
    lbl_cd_des:setAnchorPoint(CCPoint(0, 0.5))
    lbl_cd_des:setPosition(CCPoint(182, 32))
    banner:addChild(lbl_cd_des)

    if i18n.getCurrentLanguage() == kLanguageRussian then
        lbl_cd_des:setPosition(CCPoint(106-40, 32))
        lbl_cd:setAnchorPoint(CCPoint(0, 0.5))
        lbl_cd:setPosition(CCPoint(lbl_cd_des:boundingBox():getMaxX()+10, 32))
    end

    local cboard = img.createUI9Sprite(img.ui.bottom_border_2)
    cboard:setPreferredSize(CCSizeMake(548, 215))
    cboard:setAnchorPoint(CCPoint(0, 0))
    cboard:setPosition(CCPoint(10, 4))
    board:addChild(cboard)
    local cboard_w = cboard:getContentSize().width
    local cboard_h = cboard:getContentSize().height

    local txt_des = "CURRENT CONVERTIBLE HERO"
    --local txt_go = "EXCHANGE"
    local txt_go = i18n.global.pumpkin_btn_get.string
    if i18n.getCurrentLanguage() == kLanguageChinese 
        or i18n.getCurrentLanguage() == kLanguageChineseTW then
        txt_des = "限时兑换英雄无法刷新重置购买"
        --txt_go = "去兑换"
    end
    local lbl_des = lbl.createMixFont1(16, txt_des, ccc3(0x73, 0x3b, 0x05))
    lbl_des:setPosition(CCPoint(cboard_w/2, 182))
    cboard:addChild(lbl_des)
    lbl_des:setVisible(false)

    local count = #HMIDS
    local item_w = 78
    local item_h = 78
    local space_x = 10
    local container_w = (item_w + space_x)*count - space_x
    local start_x = 39

    local container = CCSprite:create()
    container:setContentSize(CCSizeMake(container_w, item_h))
    container:setPosition(CCPoint(cboard_w/2, 122))
    cboard:addChild(container)
    for ii=1,count do
        local cfgObj = cfgheromarket[HMIDS[ii]]
        local _obj = {id = cfgObj.excelId, num = cfgObj.count, type = cfgObj.type }
        if _obj.type == ItemType.Equip then  -- equip
            local _item0 = img.createEquip(_obj.id, _obj.num)
            local _item = CCMenuItemSprite:create(_item0, nil)
            _item:setScale(0.8)
            _item:setPosition(CCPoint(start_x+(ii-1)*(item_w+space_x), item_h/2+16))
            local _item_menu = CCMenu:createWithItem(_item)
            _item_menu:setPosition(CCPoint(0, 0))
            container:addChild(_item_menu)
            _item:registerScriptTapHandler(function()
                audio.play(audio.button)
                layer:getParent():getParent():addChild(tipsequip.createById(_obj.id), 1000)
            end)
        elseif _obj.type == ItemType.Item then
            local _item0 = img.createItem(_obj.id, _obj.num)
            local _item = CCMenuItemSprite:create(_item0, nil)
            _item:setScale(0.8)
            _item:setPosition(CCPoint(start_x+(ii-1)*(item_w+space_x), item_h/2+16))
            local _item_menu = CCMenu:createWithItem(_item)
            _item_menu:setPosition(CCPoint(0, 0))
            container:addChild(_item_menu)
            _item:registerScriptTapHandler(function()
                audio.play(audio.button)
                layer:getParent():getParent():addChild(tipsitem.createForShow({id=_obj.id}), 1000)
            end)
        end
    end

    local btn_go0 = img.createLogin9Sprite(img.login.button_9_small_gold)
    btn_go0:setPreferredSize(CCSizeMake(152, 45))
    local lbl_go = lbl.createMixFont1(16, txt_go, ccc3(0x73, 0x3b, 0x05))
    lbl_go:setPosition(CCPoint(btn_go0:getContentSize().width/2, btn_go0:getContentSize().height/2))
    btn_go0:addChild(lbl_go)
    local btn_go = SpineMenuItem:create(json.ui.button, btn_go0)
    btn_go:setPosition(CCPoint(cboard_w/2, 60))
    local btn_go_menu = CCMenu:createWithItem(btn_go)
    btn_go_menu:setPosition(CCPoint(0, 0))
    cboard:addChild(btn_go_menu)
    btn_go:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer:getParent():getParent():addChild(require("ui.heromarket.main").create(), 1000)  
    end)

    local last_update = os.time() - 1
    local function onUpdate(ticks)
        if os.time() - last_update < 1 then return end
        last_update = os.time()
        local remain_cd = act.cd - (os.time() - activityData.pull_time)
        if remain_cd >= 0 then
            local time_str = time2string(remain_cd)
            lbl_cd:setString(time_str)
        else
        end
    end
    layer:scheduleUpdateWithPriorityLua(onUpdate, 0)

    --img.unload(img.packedOthers.ui_activity_exchange)
    --require("ui.activity.ban").addBan(layer, scroll)
    layer:setTouchSwallowEnabled(false)
    layer:setTouchEnabled(true)
    return layer
end

return ui
