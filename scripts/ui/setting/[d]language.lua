local ui = {}

require "common.func"
require "common.const"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local audio = require "res.audio"
local i18n = require "res.i18n"
local player = require "data.player"
local userdata = require "data.userdata"

local lggs = {
    [1] = {
        name = "English",
        icon = img.ui.setting_lgg_en,
        lbl_method = lbl.createOptionEnglish,
        language = kLanguageEnglish,
    },
    [2] = {
        name = "Русский",
        icon = img.ui.setting_lgg_ru,
        lbl_method = lbl.createOptionRussian,
        language = kLanguageRussian,
    },
    --[3] = {
    --    name = "Deutsch",
    --    icon = img.ui.setting_lgg_de,
    --    lbl_method = lbl.createOptionGerman,
    --    language = kLanguageGerman,
    --},
    --[4] = {
    --    name = "Français",
    --    icon = img.ui.setting_lgg_fr,
    --    lbl_method = lbl.createOptionFrench,
    --    language = kLanguageFrench,
    --},
    --[5] = {
    --    name = "Türkiye",
    --    icon = img.ui.setting_lgg_tr,
    --    lbl_method = lbl.createOptionTur,
    --    language = kLanguageSpanish,
    --},
    --[6] = {
    --    name = "Português(BR)",
    --    icon = img.ui.setting_lgg_pt,
    --    lbl_method = lbl.createOptionPortuguese,
    --    language = kLanguagePortuguese,
    --},
    --[7] = {
    --    name = "繁體中文",
    --    icon = img.ui.setting_lgg_hk,
    --    lbl_method = lbl.createOptionChineseTraditional,
    --    language = kLanguageChineseTW,
    --},
    --[8] = {
    --    name = "日本語",
    --    icon = img.ui.setting_lgg_jp,
    --    lbl_method = lbl.createOptionJapanese,
    --    language = kLanguageJapanese,
    --},
    --[9] = {
    --    name = "한국어",
    --    icon = img.ui.setting_lgg_kr,
    --    lbl_method = lbl.createOptionKorean,
    --    language = kLanguageKorean,
    --},
    [3] = {
        name = "简体中文",
        icon = img.ui.setting_lgg_cn,
        lbl_method = lbl.createOptionChineseSimplified,
        language = kLanguageChinese,
    },
    [4] = {
        name = "繁體中文",
        icon = img.ui.setting_lgg_hk,
        lbl_method = lbl.createOptionChineseTraditional,
        language = kLanguageChineseTW,
    },
    [5] = {
        name = "Français",
        icon = img.ui.setting_lgg_fr,
        lbl_method = lbl.createOptionFrench,
        language = kLanguageFrench,
    },
    [6] = {
        name = "Português(BR)",
        icon = img.ui.setting_lgg_pt,
        lbl_method = lbl.createOptionPortuguese,
        language = kLanguagePortuguese,
    },
    [7] = {
        name = "Español",
        icon = img.ui.setting_lgg_es,
        lbl_method = lbl.createOptionSpanish,
        language = kLanguageSpanish,
    },
    [8] = {
        name = "Türkçe",
        icon = img.ui.setting_lgg_tr,
        lbl_method = lbl.createOptionTur,
        language = kLanguageTurkish,
    },
    [9] = {
        name = "日本語",
        icon = img.ui.setting_lgg_jp,
        lbl_method = lbl.createOptionJapanese,
        language = kLanguageJapanese,
    },
    [10] = {
        name = "한국어",
        icon = img.ui.setting_lgg_kr,
        lbl_method = lbl.createOptionKorean,
        language = kLanguageKorean,
    },
    [11] = {
        name = "Deutsch",
        icon = img.ui.setting_lgg_de,
        lbl_method = lbl.createOptionGerman,
        language = kLanguageGerman,
    },
    [12] = {
        name = "Italiano",
        icon = img.ui.setting_lgg_it,
        lbl_method = lbl.createOptionItalian,
        language = kLanguageItalian,
    },
    [13] = {
        name = "ภาษาไทย",
        icon = img.ui.setting_lgg_th,
        lbl_method = lbl.createOptionThai,
        language = kLanguageThai,
    },
    [14] = {
        name = "Tiếng Việt",
        icon = img.ui.setting_lgg_vi,
        lbl_method = lbl.createOptionVi,
        language = kLanguageVietnamese,
    },
    [15] = {
        name = "Melayu",
        icon = img.ui.setting_lgg_ms,
        lbl_method = lbl.createOptionMs,
        language = kLanguageMalay,
    },
    --[16] = {
    --    name = "اللغة العربية",
    --    icon = img.ui.setting_lgg_en,
    --    lbl_method = lbl.createOptionAr,
    --    language = kLanguageArabic,
    --},
}

local function createItem2(obj)
    local item = img.createUISprite(obj.icon)
    local lbl_lgg = lbl.createFontTTF(16, obj.name, ccc3(0xff, 0xff, 0xff))
    lbl_lgg:setPosition(CCPoint(item:getContentSize().width/2, -20))
    item:addChild(lbl_lgg)
    item.lbl_lgg = lbl_lgg
    local item_mask = img.createUISprite(img.ui.setting_lgg_mask)
    item_mask:setPosition(CCPoint(item:getContentSize().width/2,
                item:getContentSize().height/2))
    item_mask:setVisible(false)
    item:addChild(item_mask)
    item.item_mask = item_mask
    local item_sel = img.createUISprite(img.ui.hook_btn_sel)
    item_sel:setScale(0.6)
    item_sel:setPosition(CCPoint(item_mask:getContentSize().width/2,
                item_mask:getContentSize().height/2))
    item_mask:addChild(item_sel)
    return item
end

local function createItem(obj)
    local item = img.createUI9Sprite(img.ui.botton_fram_2)
    item:setPreferredSize(CCSizeMake(246, 70))
    local item_w = item:getContentSize().width
    local item_h = item:getContentSize().height
    -- current
    local item_sel = img.createUI9Sprite(img.ui.setting_server_sel)
    item_sel:setPreferredSize(CCSizeMake(246, 70))
    item_sel:setPosition(CCPoint(item_w/2, item_h/2))
    item_sel:setVisible(false)
    item:addChild(item_sel)
    item.item_sel = item_sel

    local lbl_lgg = lbl.createFontTTF(16, obj.name, ccc3(0x51, 0x27, 0x12))
    --lbl_lgg:setAnchorPoint(CCPoint(0, 0.5))
    lbl_lgg:setPosition(CCPoint(item_w/2, item_h/2))
    item:addChild(lbl_lgg)
    item.lbl_lgg = lbl_lgg

    return item
end

function ui.create()
    local layer = CCLayer:create()
    -- dark bg
    local darkbg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    layer:addChild(darkbg)
    -- board
    local board= img.createUI9Sprite(img.ui.tips_bg)
    board:setPreferredSize(CCSizeMake(618, 450))
    board:setScale(view.minScale)
    board:setPosition(view.midX-5*view.minScale, view.midY)
    layer:addChild(board)
    layer.board = board
    local board_w = board:getContentSize().width
    local board_h = board:getContentSize().height

    -- anim
    board:setScale(0.5*view.minScale)
    board:runAction(CCScaleTo:create(0.15, 1*view.minScale, 1*view.minScale))

    -- title
    local lbl_title = lbl.createFont1(24, i18n.global.setting_chose_lgg.string, ccc3(0xff, 0xea, 0x88))
    lbl_title:setPosition(CCPoint(board_w/2, board_h-36))
    board:addChild(lbl_title)

    local function backEvent()
        audio.play(audio.button)
        layer:removeFromParentAndCleanup(true)
    end
    -- btn_close
    local btn_close0 = img.createUISprite(img.ui.close)
    local btn_close = SpineMenuItem:create(json.ui.button, btn_close0)
    btn_close:setPosition(CCPoint(board_w-28, board_h-28))
    local btn_close_menu = CCMenu:createWithItem(btn_close)
    btn_close_menu:setPosition(CCPoint(0, 0))
    board:addChild(btn_close_menu, 100)
    layer.btn_close = btn_close
    btn_close:registerScriptTapHandler(function()
        backEvent()
    end)

    -- line
    local line = img.createUISprite(img.ui.help_line)
    line:setScaleX(520/line:getContentSize().width)
    line:setPosition(board_w/2, board_h-64)
    board:addChild(line)

    local current_language = i18n.getCurrentLanguage()
    local last_sel_item = nil

    local lineScroll = require "ui.lineScroll"
    local params = {
        width = 524,
        height = 364,
    }
    local scroll = lineScroll.create(params)
    scroll:setAnchorPoint(CCPoint(0, 0))
    scroll:setPosition(CCPoint(47, 12))
    board:addChild(scroll)
    local lgg_items = {}
    local obj_count = #lggs
    local offset_x = 5
    local offset_y = 15
    local item_width = 270
    local item_height = 80
    local ITEM_PER_ROW = 2
    local rows = math.floor((obj_count+ITEM_PER_ROW-1)/ITEM_PER_ROW)
    if offset_y+item_height*rows > scroll.height then
        scroll:setContentSize(CCSizeMake(scroll.width, offset_y+item_height*rows))
        scroll:setContentOffset(CCPoint(0, scroll.height - (offset_y+item_height*rows)))
    end
    scroll.content_layer:setPosition(CCPoint(0, scroll:getContentSize().height))
    for ii=1,#lggs do
        local item = createItem(lggs[ii])
        if current_language == lggs[ii].language then
            item.item_sel:setVisible(true)
            --item.lbl_lgg:setColor(ccc3(0xff, 0xea, 0x88))
            last_sel_item = item
        end
        item.obj = lggs[ii]
        lgg_items[#lgg_items+1] = item
        item:setAnchorPoint(CCPoint(0,1))
        local cur_column = (ii-1)%ITEM_PER_ROW
        local cur_row = math.floor((ii+ITEM_PER_ROW-1)/ITEM_PER_ROW) - 1
        item:setPosition(CCPoint(offset_x+cur_column*item_width,
                    0 - offset_y - cur_row*item_height))
        scroll.content_layer:addChild(item)
    end

    local function switchLanguage(which)
        local sel_language = which
        local old_language = i18n.getCurrentLanguage()
        if sel_language == old_language then 
            --local townlayer = require "uilayer.townlayer"
            --replaceScene(townlayer.create(nil, "accountOptionlayer"))
            return 
        end
        i18n.switchLanguage(sel_language)
        local townlayer = require "ui.town.main"
        replaceScene(townlayer.create({from_layer="language"}))
    end

    local function onOptionSel(which)
        for ii=1,#lgg_items do
            if ii == which then
                lgg_items[ii].item_sel:setVisible(true)
                --lgg_items[ii].lbl_lgg:setColor(ccc3(0xff, 0xea, 0x88))
                last_sel_item = lgg_items[ii]
            else
                lgg_items[ii].item_sel:setVisible(false)
                --lgg_items[ii].lbl_lgg:setColor(ccc3(0xff, 0xff, 0xff))
            end
        end
        current_language = lgg_items[which].obj.language
    end
    
    -- for touch
    local touchbeginx, touchbeginy
    local isclick
    local function onTouchBegan(x, y)
        touchbeginx, touchbeginy = x, y
        isclick = true
        return true
    end

    local function onTouchMoved(x, y)
        if isclick and (math.abs(touchbeginx-x) > 10 or math.abs(touchbeginy-y) > 10) then
            isclick = false
        end
    end

    local function onTouchEnded(x, y)
        local p0 = board:convertToNodeSpace(ccp(x, y))
        if isclick and scroll:boundingBox():containsPoint(p0) then
            local p1 = scroll.content_layer:convertToNodeSpace(ccp(x, y))
            for ii=1,#lgg_items do
                if lgg_items[ii]:boundingBox():containsPoint(p1) then
                    if last_sel_item and last_sel_item == lgg_items[ii] then
                        return
                    end
                    audio.play(audio.button)
                    onOptionSel(ii)
                    switchLanguage(current_language)
                end
            end
        end
    end
    local function onTouch(eventType, x, y)
        if eventType == "began" then   
            return onTouchBegan(x, y)
        elseif eventType == "moved" then
            return onTouchMoved(x, y)
        else
            return onTouchEnded(x, y)
        end
    end
    layer:registerScriptTouchHandler(onTouch , false , -128 , false)
    layer:setTouchEnabled(true)
    layer:setTouchSwallowEnabled(true)

    addBackEvent(layer)
    function layer.onAndroidBack()
        backEvent()
    end
    local function onEnter()
        print("onEnter")
        layer.notifyParentLock()
    end
    local function onExit()
        layer.notifyParentUnlock()
    end
    layer:registerScriptHandler(function(event)
        if event == "enter" then
            onEnter()
        elseif event == "exit" then
            onExit()
        end
    end)

    return layer
end

return ui
