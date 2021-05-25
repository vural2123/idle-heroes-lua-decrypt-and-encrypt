local ui = {}

require "common.func"
local view = require "common.view"
local i18n = require "res.i18n"
local lbl = require "res.lbl"
local img = require "res.img"
local audio = require "res.audio"
local json = require "res.json"
local player = require "data.player"
local shopData = require "data.shop"
local activityData = require "data.activity"
local NetClient = require "net.netClient"
local netClient = NetClient:getInstance()
local cfgstore = require "config.store"
local shop = require "data.shop"

local IDS = activityData.IDS

function ui.create()
    local layer = CCLayer:create()

    img.unload(img.packedOthers.ui_minicard)
    img.unload(img.packedOthers.ui_minicard_cn)
    if i18n.getCurrentLanguage() == kLanguageChinese then
        img.load(img.packedOthers.ui_minicard_cn)
    else
        img.load(img.packedOthers.ui_minicard)
    end
    local origin_price = "원가 $49.99"
    local sale_price = "$4.99"
    if isOnestore() then
        origin_price = "원가 60,500"
        sale_price = "6,050"
    end
    local board
    if i18n.getCurrentLanguage() == kLanguageKorean then
        board = img.createUISprite("minicard_board_kr.png")
    elseif i18n.getCurrentLanguage() == kLanguageChineseTW then
        board = img.createUISprite("minicard_board_tw.png")
    elseif i18n.getCurrentLanguage() == kLanguageJapanese then
        board = img.createUISprite("minicard_board_jp.png")
    elseif i18n.getCurrentLanguage() == kLanguageRussian then
        board = img.createUISprite("minicard_board_ru.png")
    elseif i18n.getCurrentLanguage() == kLanguageSpanish then
        board = img.createUISprite("minicard_board_ks.png")
    elseif i18n.getCurrentLanguage() == kLanguagePortuguese then
        board = img.createUISprite("minicard_board_kp.png")
    else
        board = img.createUISprite(img.ui.minicard_board)
    end
    board:setScale(view.minScale)
    board:setAnchorPoint(CCPoint(0, 0))
    board:setPosition(scalep(360, 64))
    layer:addChild(board)

    if i18n.getCurrentLanguage() == kLanguageKorean then
        --local lbl_origin_price = lbl.createFont1(18, origin_price, ccc3(0xff, 0xd6, 0x74))
        --lbl_origin_price:setPosition(CCPoint(342, 193))
        --board:addChild(lbl_origin_price)
        --local del_line = CCSprite:create()
        --del_line:setContentSize(CCSizeMake(lbl_origin_price:getContentSize().width - 40, 1))
        --del_line:setPosition(CCPoint(342, 193))
        --board:addChild(del_line)
        --drawBoundingbox(board, del_line, ccc4f(0xff/0xff, 0xd6/0xff, 0x74/0xff, 0.5))
        --local lbl_sale_price = lbl.createFont1(18, sale_price, ccc3(0xdd, 0xa8, 0x89))
        --lbl_sale_price:setPosition(CCPoint(342, 159))
        --board:addChild(lbl_sale_price)
    end

    local id = 32
    local item_price = cfgstore[id].priceStr 
    if isAmazon() then
    elseif APP_CHANNEL and APP_CHANNEL ~= "" then
        item_price = cfgstore[id].priceCnStr
    elseif i18n.getCurrentLanguage() == kLanguageChinese then
        item_price = cfgstore[id].priceCnStr
    end
    item_price = shop.getPrice(id, item_price)
    local costLab = lbl.createFontTTF(18, item_price, ccc3(0xff, 0xd6, 0x74))
    --costLab:setAnchorPoint(ccp(1, 0.5))
    costLab:setPosition(344, 152)
    board:addChild(costLab)

    local btn_buy0 = img.createLogin9Sprite(img.login.button_9_small_gold)
    btn_buy0:setPreferredSize(CCSizeMake(156, 52))
    local lbl_buy = lbl.createFont1(18, i18n.global.chip_btn_buy.string, ccc3(0x49, 0x26, 0x04))
    lbl_buy:setPosition(CCPoint(78, 26))
    btn_buy0:addChild(lbl_buy)
    local btn_buy = SpineMenuItem:create(json.ui.button, btn_buy0)
    btn_buy:setPosition(CCPoint(345, 103))
    local btn_buy_menu = CCMenu:createWithItem(btn_buy)
    btn_buy_menu:setPosition(CCPoint(0, 0))
    board:addChild(btn_buy_menu)
    local function checkBtn()
        if shopData.pay and shopData.pay[32] ~= 0 then
            btn_buy:setEnabled(false)
            setShader(btn_buy, SHADER_GRAY, true)
        else
            btn_buy:setEnabled(true)
            btn_buy:setVisible(true)
        end
    end
    checkBtn()

    btn_buy:registerScriptTapHandler(function()
        audio.play(audio.button)
        local gemShop = require "ui.shop.main"
        layer:getParent():getParent():addChild(gemShop.create(), 1001)
    end)

    layer:setTouchEnabled(true)
    layer:setTouchSwallowEnabled(false)

    local function onUpdate(ticks)
        checkBtn()
    end
    layer:scheduleUpdateWithPriorityLua(onUpdate, 0)

    return layer
end

return ui
