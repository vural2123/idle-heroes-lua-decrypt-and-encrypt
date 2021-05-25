-- 展示提示信息的弹窗

local ui = {}

require "common.const"
require "common.func"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local audio = require "res.audio"
local i18n = require "res.i18n"

-- 分隔符
local DELIMITER_1 = "###" -- 大段分隔符
local DELIMITER_2 = ":::" -- 小标题和内容分隔符
local DELIMITER_3 = "|||" -- 内容分隔符

-- 背景框大小
local BG_WIDTH   = 666
local BG_HEIGHT  = 415

-- 滑动区域大小
local SCROLL_MARGIN_TOP     = 70
local SCROLL_MARGIN_BOTTOM  = 70
local SCROLL_VIEW_WIDTH     = BG_WIDTH
local SCROLL_VIEW_HEIGHT    = BG_HEIGHT - SCROLL_MARGIN_TOP - SCROLL_MARGIN_BOTTOM

function ui.create(content, title, handler)
    local layer = CCLayer:create()

    -- dark bg
    local darkbg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    layer:addChild(darkbg)

    -- bg
    local bg = img.createUI9Sprite(img.ui.tips_bg)
    bg:setPreferredSize(CCSize(BG_WIDTH, BG_HEIGHT))
    bg:setScale(view.minScale * 0.1)
    bg:setAnchorPoint(ccp(0.5,0.5))
    bg:setPosition(view.midX, view.midY)
    bg:runAction(CCEaseBackOut:create(CCScaleTo:create(0.3, view.minScale)))
    layer:addChild(bg)
    
    -- closeBtn
    local closeBtn0 = img.createUISprite(img.ui.close)
    local closeBtn = SpineMenuItem:create(json.ui.button, closeBtn0)
    closeBtn:setPosition(BG_WIDTH-23, BG_HEIGHT-26)
    local closeMenu = CCMenu:createWithItem(closeBtn)
    closeMenu:setPosition(0, 0)
    bg:addChild(closeMenu)
    closeBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer.onAndroidBack()
    end)

    -- title
    title = title or i18n.global.help_title.string
    local titleLabel = lbl.createFont1(24, title, ccc3(0xff, 0xe3, 0x86))
    titleLabel:setPosition(BG_WIDTH/2, BG_HEIGHT-36)
    bg:addChild(titleLabel)

    -- line
    local line = img.createUISprite(img.ui.help_line)
    line:setScaleX(610/line:getContentSize().width)
    line:setPosition(BG_WIDTH/2, BG_HEIGHT-64)
    bg:addChild(line)

    -- scroll
    local scroll = CCScrollView:create()
    scroll:setDirection(kCCScrollViewDirectionVertical)
    scroll:setViewSize(CCSize(SCROLL_VIEW_WIDTH, SCROLL_VIEW_HEIGHT))
    scroll:setPosition(0, SCROLL_MARGIN_BOTTOM)
    bg:addChild(scroll)

    local btnBuy0 = img.createLogin9Sprite(img.login.button_9_small_gold)
    btnBuy0:setPreferredSize(CCSize(80, 50))
    local lblBuy = CCLabelTTF:create("Buy", "", 22)
    lblBuy:setColor(ccc3(0x63,0x34,0x18))
    lblBuy:setPosition(CCPoint(btnBuy0:getContentSize().width/2, btnBuy0:getContentSize().height/2))
    btnBuy0:addChild(lblBuy)
    local btnBuy = SpineMenuItem:create(json.ui.button, btnBuy0)
    btnBuy:setPosition(CCPoint(BG_WIDTH/2, 35))
    local btnBuyMenu = CCMenu:createWithItem(btnBuy)
    btnBuyMenu:setPosition(ccp(0, 0))
    bg:addChild(btnBuyMenu)
    btnBuy:registerScriptTapHandler(function()
        audio.play(audio.button)
        if handler then
            handler()
        end
        layer.onAndroidBack()
    end)

    -- content
    local contentDetail
    if content then
        contentDetail = {}
        local blocks = string.split(content, DELIMITER_1)
        for _, block in ipairs(blocks) do
            local blockParts = string.split(block, DELIMITER_2)
            if #blockParts > 1 then
                table.insert(contentDetail, {
                    title = blockParts[1],
                    lines = string.split(blockParts[2], DELIMITER_3),
                })
            else
                table.insert(contentDetail, {
                    title = nil,
                    lines = string.split(blockParts[1], DELIMITER_3),
                })
            end
        end
    end

    -- 构建alignLabels的参数
    local labels = {}
    if contentDetail then
        for i, detail in ipairs(contentDetail) do
            -- title
            if detail.title then
                labels[#labels+1] = {
                    label = lbl.createMix({
                        kind = "ttf",
                        font = 1, size = 22, text = detail.title, color = ccc3(0xfe, 0xeb, 0xca),
                        width = 610, align = kCCTextAlignmentLeft
                    }),
                    x = 30,
                    offsetY = op3(i == 1, 15, 25),
                }
            end
            -- lines
            for j, line in ipairs(detail.lines) do
                -- 一行
                labels[#labels+1] = {
                    label = lbl.createMix({
                        kind = "ttf",
                        font = 1, size = 22, text = line, color = ccc3(0xfe, 0xeb, 0xca),
                        width = 610, align = kCCTextAlignmentLeft
                    }),
                    x = 30,
                    offsetY = op3(j == 1, 16, 12),
                }
            end
        end
    end

    local container, currentY = alignLabels(labels)

    -- scroll content height
    local height = -currentY + 12
    if height < SCROLL_VIEW_HEIGHT then
        height = SCROLL_VIEW_HEIGHT
    end
    container:setPosition(0, height)
    scroll:setContentSize(CCSize(SCROLL_VIEW_WIDTH, height))
    scroll:addChild(container)
    scroll:setContentOffset(ccp(0, SCROLL_VIEW_HEIGHT-height))

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
