-- 公告

local ui = {}

require "config"
require "framework.init"
require "common.const"
require "common.func"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local i18n = require "res.i18n"
local audio = require "res.audio"
local pubsdata = require "data.pubs"
local net = require "net.netClient"

function ui.create()
    local layer = CCLayer:create()

    -- dark bg
    local darkBg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    layer:addChild(darkBg)

    -- bg
	local bg = img.createLogin9Sprite(img.login.login_home_notice_board)
    bg:setScale(view.minScale * 0.1)
    bg:setPosition(scalep(480, 288))
    bg:runAction(CCEaseBackOut:create(CCScaleTo:create(0.3, view.minScale)))
    layer:addChild(bg)

    local bg_w = bg:getContentSize().width
    local bg_h = bg:getContentSize().height

    local lbl_title = lbl.createFont2(22, i18n.global.setting_title_notice.string)
    lbl_title:setPosition(CCPoint(bg_w/2, bg_h-63))
    bg:addChild(lbl_title)

    -- closeBtn
    local closeBtn0 = img.createLoginSprite(img.login.button_close)
    local closeBtn = SpineMenuItem:create(json.ui.button, closeBtn0)
    closeBtn:setPosition(bg_w-23, bg_h-63)
    local closeMenu = CCMenu:createWithItem(closeBtn)
    closeMenu:setPosition(0, 0)
    bg:addChild(closeMenu)
    closeBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer.onAndroidBack()
    end)

    local pubs = pubsdata.getPub()

    local SCROLL_VIEW_W = 554
    local SCROLL_VIEW_H = 338
    local SCROLL_PADDING = 8
    local function createScroll()
        local lineScroll = require "ui.lineScroll"
        local params = {
            width = SCROLL_VIEW_W,
            height = SCROLL_VIEW_H,
        }
        return lineScroll.create(params)
    end

    local function showPubs(_pubs)
        local scroll = createScroll()
        scroll:setAnchorPoint(CCPoint(0, 0))
        scroll:setPosition(CCPoint(41, 48))
        bg:addChild(scroll)
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

    addBackEvent(layer)

    function layer.onAndroidBack()
        layer:removeFromParent()
    end

    layer:registerScriptHandler(function(event)
        if event == "enter" then
            layer.notifyParentLock()
        elseif event == "exit" then
            layer.notifyParentUnlock()
        end
    end)

    layer:setTouchEnabled(true)
    layer:setTouchSwallowEnabled(true)

    return layer
end

return ui
