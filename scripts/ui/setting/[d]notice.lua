local ui = {}

require "common.func"
require "common.const"
local view = require "common.view"
local img = require "res.img"
local i18n = require "res.i18n"
local lbl = require "res.lbl"
local json = require "res.json"
local audio = require "res.audio"
local player = require "data.player"
local userdata = require "data.userdata"
local pubsdata = require "data.pubs"

function ui.create(_anim)
    local boardlayer = require "ui.setting.board"
    local layer = boardlayer.create(boardlayer.TAB.PUB, _anim)
    local board = layer.inner_board
    local board_w = board:getContentSize().width
    local board_h = board:getContentSize().height

    layer.setTitle(i18n.global.setting_title_notice.string)

    -- btn_help
    local btn_help0 = img.createLogin9Sprite(img.login.button_9_small_mwhite)
    btn_help0:setPreferredSize(CCSizeMake(210, 42))
    local help_sel = img.createLogin9Sprite(img.login.button_9_small_gold)
    help_sel:setPreferredSize(CCSizeMake(210, 42))
    help_sel:setPosition(CCPoint(btn_help0:getContentSize().width/2, btn_help0:getContentSize().height/2))
    btn_help0:addChild(help_sel)
    help_sel:setVisible(false)
    local lbl_help = lbl.createFont1(18, i18n.global.setting_btn_help.string, ccc3(0x73, 0x3b, 0x05))
    lbl_help:setPosition(CCPoint(btn_help0:getContentSize().width/2, btn_help0:getContentSize().height/2+2))
    btn_help0:addChild(lbl_help)
    local btn_help = SpineMenuItem:create(json.ui.button, btn_help0)
    btn_help:setPosition(CCPoint(370-215, 380))
    local btn_help_menu = CCMenu:createWithItem(btn_help)
    btn_help_menu:setPosition(CCPoint(0, 0))
    board:addChild(btn_help_menu)
    btn_help:registerScriptTapHandler(function()
        audio.play(audio.button)
        local parentObj = layer:getParent()
        layer:removeFromParentAndCleanup(true)
        parentObj:addChild((require"ui.setting.help").create(), 1000)
    end)

    -- btn_faq
    local btn_faq0 = img.createLogin9Sprite(img.login.button_9_small_mwhite)
    btn_faq0:setPreferredSize(CCSizeMake(210, 42))
    local faq_sel = img.createLogin9Sprite(img.login.button_9_small_gold)
    faq_sel:setPreferredSize(CCSizeMake(210, 42))
    faq_sel:setPosition(CCPoint(btn_faq0:getContentSize().width/2, btn_faq0:getContentSize().height/2+2))
    btn_faq0:addChild(faq_sel)
    faq_sel:setVisible(false)
    local faq_str = "FAQ"
    if i18n.getCurrentLanguage() == kLanguageTurkish then
        faq_str = "SSS"
    end
    local lbl_faq = lbl.createFont1(18, faq_str, ccc3(0x94, 0x62, 0x42))
    lbl_faq:setPosition(CCPoint(btn_faq0:getContentSize().width/2, btn_faq0:getContentSize().height/2))
    btn_faq0:addChild(lbl_faq)
    local btn_faq = SpineMenuItem:create(json.ui.button, btn_faq0)
    btn_faq:setPosition(CCPoint(370, 380))
    local btn_faq_menu = CCMenu:createWithItem(btn_faq)
    btn_faq_menu:setPosition(CCPoint(0, 0))
    board:addChild(btn_faq_menu)
    btn_faq:registerScriptTapHandler(function()
        audio.play(audio.button)
        local parentObj = layer:getParent()
        layer:removeFromParentAndCleanup(true)
        parentObj:addChild((require"ui.setting.faq").create(), 1000)
    end)

    -- btn_notice
    local btn_notice0 = img.createLogin9Sprite(img.login.button_9_small_mwhite)
    btn_notice0:setPreferredSize(CCSizeMake(210, 42))
    local notice_sel = img.createLogin9Sprite(img.login.button_9_small_gold)
    notice_sel:setPreferredSize(CCSizeMake(210, 42))
    notice_sel:setPosition(CCPoint(btn_notice0:getContentSize().width/2, btn_notice0:getContentSize().height/2+2))
    btn_notice0:addChild(notice_sel)
    local lbl_notice = lbl.createFont1(18, i18n.global.setting_title_notice.string, ccc3(0x73, 0x3b, 0x05))
    lbl_notice:setPosition(CCPoint(btn_notice0:getContentSize().width/2, btn_notice0:getContentSize().height/2))
    btn_notice0:addChild(lbl_notice)
    local btn_notice = SpineMenuItem:create(json.ui.button, btn_notice0)
    btn_notice:setPosition(CCPoint(370+215, 380))
    local btn_notice_menu = CCMenu:createWithItem(btn_notice)
    btn_notice_menu:setPosition(CCPoint(0, 0))
    board:addChild(btn_notice_menu)
    btn_notice:setEnabled(false)

    -- pboard
    local pboard = img.createUI9Sprite(img.ui.botton_fram_2)
    pboard:setPreferredSize(CCSizeMake(680, 330))
    pboard:setAnchorPoint(CCPoint(0.5, 0))
    pboard:setPosition(CCPoint(board_w/2, 23))
    board:addChild(pboard)
    local pboard_w = pboard:getContentSize().width
    local pboard_h = pboard:getContentSize().height

    local pubs = pubsdata.getPub()

    local SCROLL_VIEW_W = 680
    local SCROLL_VIEW_H = 319
    local SCROLL_PADDING = 23
    local function createScroll()
        local lineScroll = require "ui.lineScroll"
        local params = {
            width = SCROLL_VIEW_W,
            height = SCROLL_VIEW_H - SCROLL_PADDING,
        }
        return lineScroll.create(params)
    end

    local function showPubs(_pubs)
        local scroll = createScroll()
        scroll:setAnchorPoint(CCPoint(0, 0))
        scroll:setPosition(CCPoint(0, SCROLL_PADDING-5))
        pboard:addChild(scroll)
        for ii=1,#_pubs do
            local lbl_pub_title = lbl.createMix({font=1, size=18, text=_pubs[ii].title, color=ccc3(0x94, 0x00, 0x00),
                        width=SCROLL_VIEW_W-SCROLL_PADDING*2, align=kCCTextAlignmentLeft})
            lbl_pub_title.ax = 0
            lbl_pub_title.px = SCROLL_PADDING
            scroll.addItem(lbl_pub_title)
            for jj=1,#_pubs[ii].sub do
                local lbl_sub_title = lbl.createMix({font=1, size=16, text=_pubs[ii].sub[jj].title, color=ccc3(0x4e, 0x23, 0x10),
                            width=SCROLL_VIEW_W-8*2, align=kCCTextAlignmentLeft})
                lbl_sub_title.ax = 0
                lbl_sub_title.px = SCROLL_PADDING
                scroll.addItem(lbl_sub_title)
                --scroll.addSpace(5)
                local sub_contents = _pubs[ii].sub[jj].content or {}
                for kk=1,#sub_contents do
                    local lbl_sub_content = lbl.createMix({font=1, size=16, text=sub_contents[kk], color=ccc3(0x4e, 0x23, 0x10),
                                width=SCROLL_VIEW_W-8*2, align=kCCTextAlignmentLeft})
                    lbl_sub_content.height = lbl_sub_content:getContentSize().height
                    lbl_sub_content.ax = 0
                    lbl_sub_content.px = SCROLL_PADDING
                    scroll.addItem(lbl_sub_content)
                end
                scroll.addSpace(10)
            end
            scroll.addSpace(5)
        end
        scroll.setOffsetBegin()
    end
    showPubs(pubs)

    return layer
end

return ui
