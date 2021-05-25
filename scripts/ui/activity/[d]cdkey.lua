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

local IDS = activityData.IDS
local ItemType = {
    Item = 1,
    Equip = 2,
}

function ui.create()
    local layer = CCLayer:create()

    local HMIDS = { 25, 26,}
    local act = activityData.getStatusById(IDS.CDKEY.ID)

    local toasts = {
        ["0"] = "兑换成功，请前往邮件领取",
        ["-1"] = "兑换码不存在",
        ["-2"] = "该兑换码已经被使用",
        ["-3"] = "该兑换码已经过期",
        ["-4"] = "同一种类型的礼包码同一个玩家只能领取一次",
        ["-5"] = "还未达到领取时间",
        ["-7"] = "该类礼包码尚未更新",
        ["-8"] = "设置兑换码状态失败",
        ["unknown"] = "未知错误",
    }
    if isOnestore() then
        toasts = {
            ["0"] = "수령한 아이템은 메일함에서 확인가능합니다.",
            ["-1"] = "해당 쿠폰은 사용이 불가능합니다",
            ["-2"] = "이미 사용된 쿠폰입니다",
            ["-3"] = "유효기간이 지난 쿠폰입니다",
            ["-4"] = "동일한 유형의 선물 패키지 코드는 동일한 유저가 한 번만 수령 가능합니다",
            ["-5"] = "업데이트 후 다시 교환해주세요",
            ["-7"] = "패키지 코드가 존재하지 않습니다",
            ["-8"] = "활성화 코드 상태 설정 실패",
            ["unknown"] = "시스템 에러",
        }
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

    --img.unload(img.packedOthers.ui_activity_cdkey)
    --img.unload(img.packedOthers.ui_activity_cdkey)
    --if i18n.getCurrentLanguage() == kLanguageChinese 
    --    or i18n.getCurrentLanguage() == kLanguageChineseTW then
    --    img.load(img.packedOthers.ui_activity_exchange_cn)
    --else
    --    img.load(img.packedOthers.ui_activity_exchange)
    --end
    img.load(img.packedOthers.ui_activity_cdkey)
    local banner
    if isOnestore() then
        banner = img.createUISprite("activity_cdkey_board_kr.png")
    else
        banner = img.createUISprite(img.ui.activity_cdkey_board)
    end
    banner:setAnchorPoint(CCPoint(0.5, 1))
    banner:setPosition(CCPoint(board_w/2, board_h-8))
    board:addChild(banner)

    local cboard = img.createUI9Sprite(img.ui.bottom_border_2)
    cboard:setPreferredSize(CCSizeMake(548, 201))
    cboard:setAnchorPoint(CCPoint(0, 0))
    cboard:setPosition(CCPoint(10, 4))
    board:addChild(cboard)
    local cboard_w = cboard:getContentSize().width
    local cboard_h = cboard:getContentSize().height

    local txt_des = "please input a 12-digit redemption code"
    local txt_go = "EXCHANGE"
    txt_des = "请输入礼包兑换码"
    txt_go = "兑换"
    if isOnestore() then
        txt_des = "쿠폰 번호를 입력해주세요"
        txt_go = "교환"
    elseif i18n.getCurrentLanguage() == kLanguageChinese 
        or i18n.getCurrentLanguage() == kLanguageChineseTW then
        txt_des = "请输入礼包兑换码"
        txt_go = "兑换"
    end
    local lbl_des = lbl.createMixFont1(16, txt_des, ccc3(0x73, 0x3b, 0x05))
    lbl_des:setPosition(CCPoint(cboard_w/2, 166))
    cboard:addChild(lbl_des)

    -- input
    local edit_bg = img.createLogin9Sprite(img.login.input_border)
    local edit_msg = CCEditBox:create(CCSizeMake(350, 44), edit_bg)
    edit_msg:setReturnType(kKeyboardReturnTypeDone)
    edit_msg:setFont("", 18)
    edit_msg:setFontColor(ccc3(0x0, 0x0, 0x0))
    edit_msg:setPlaceHolder("")
    --edit_msg:setAnchorPoint(CCPoint(0, 0))
    edit_msg:setPosition(CCPoint(cboard_w/2, 113))
    cboard:addChild(edit_msg, 100)

    local btn_go0 = img.createLogin9Sprite(img.login.button_9_small_gold)
    btn_go0:setPreferredSize(CCSizeMake(152, 45))
    local lbl_go = lbl.createMixFont1(16, txt_go, ccc3(0x73, 0x3b, 0x05))
    lbl_go:setPosition(CCPoint(btn_go0:getContentSize().width/2, btn_go0:getContentSize().height/2))
    btn_go0:addChild(lbl_go)
    local btn_go = SpineMenuItem:create(json.ui.button, btn_go0)
    btn_go:setPosition(CCPoint(cboard_w/2, 50))
    local btn_go_menu = CCMenu:createWithItem(btn_go)
    btn_go_menu:setPosition(CCPoint(0, 0))
    cboard:addChild(btn_go_menu)
    btn_go:registerScriptTapHandler(function()
        disableObjAWhile(btn_go)
        audio.play(audio.button)
        local code = edit_msg:getText()
        code = string.trim(code)
        --if #code ~= 12 then
        --    showToast(toasts["-1"])
        --    return
        --end
        local params = {
            sid = player.sid,
            key = code,
        }
        addWaitNet()
        netClient:cdkey(params, function(__data)
            tbl2string(__data)
            delWaitNet()
            local ss = __data.status .. ""
            if toasts[ss] then
                showToast(toasts[ss])
            else
                showToast(toasts["unknown"])
            end
        end)
    end)

    img.unload(img.packedOthers.ui_activity_cdkey)
    --require("ui.activity.ban").addBan(layer, scroll)
    layer:setTouchSwallowEnabled(false)
    layer:setTouchEnabled(true)
    return layer
end

return ui
