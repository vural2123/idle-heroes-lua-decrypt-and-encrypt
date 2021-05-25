-- 物品tips, 有回调则为handler(item)形式

local tips = {}

require "common.func"
require "common.const"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local audio = require "res.audio"
local cfgitem = require "config.item"
local cfgequip = require "config.equip"
local cfghero = require "config.hero"
local bagdata = require "data.bag"
local herosdata = require "data.heros"
local i18n = require "res.i18n"
local tipsequip = require "ui.tips.equip"

local TIPS_WIDTH = 360 -- tips背景框的宽度
local TIPS_MARGIN = 20 -- tips文字到背景边的距离
local SCROLL_HEIGHT = 320 -- middle区域scrollView的最大高度
local LABEL_WIDTH = TIPS_WIDTH - 2 * TIPS_MARGIN

local rate_type = nil
local RATE_CASINO = "casino"
local RATE_HCASINO = "hcasino"

function tips.createForShow(item)
    return tips.createLayer("show", item)
end

function tips.createForShowCasino(item)
    rate_type = RATE_CASINO
    return tips.createLayer("show", item)
end

function tips.createForShowHCasino(item)
    rate_type = RATE_HCASINO
    return tips.createLayer("show", item)
end

function tips.createForPb(pb)
    return tips.createForShow(tablecp(pb))
end

function tips.createForBag(item, handler1, handler2)
    return tips.createLayer("bag", item, nil, handler1, handler2)
end

function tips.createForMarket(item, handler1, handler2)
    return tips.createLayer("market", item, nil, handler1, handler2)
end

function tips.createForForge(item, handler1)
    return tips.createLayer("forge", item, nil, handler1)
end

function tips.createForJadeOn(jade, handler1)
    return tips.createLayer("jadeOn", jade, nil, handler1)
end

function tips.createForJadeOff(jade, handler1)
    return tips.createLayer("jadeOff", jade, nil, handler1)
end

function tips.createForJadeReplace(jade, handler1, handler2)
    return tips.createLayer("jadeReplace", jade, nil, handler1, handler2)
end

function tips.createForJadeCompare(jade, jade2, handler1)
    return tips.createLayer("jadeCompare", jade, jade2, handler1)
end


-- tips顶部内容：主要是大图标，基本信息等
function tips.createHeader(item, showUnsell, btn1text, btn1handler, btn2text, btn2handler)
    local container = CCLayer:create()
    local currentY = 0

    -- name
    local name = lbl.createMix({
        font = 1, size = 18, text = i18n.item[item.id].name, 
        width = LABEL_WIDTH, align = kCCTextAlignmentLeft,
        color = lbl.qualityColors[cfgitem[item.id].qlt],
    })
    name:setAnchorPoint(ccp(0, 1))
    name:setPosition(TIPS_MARGIN, currentY)
    container:addChild(name)
    currentY = name:boundingBox():getMinY()

    -- icon
    local icon = img.createItem(item.id)
    icon:setScale(0.9)
    icon:setAnchorPoint(ccp(0, 0.5))
    icon:setPosition(TIPS_MARGIN, currentY-49)
    container:addChild(icon)
    currentY = icon:boundingBox():getMinY()

    -- 简短描述
    local brief = lbl.createMix({
        font = 1, size = 18, text = i18n.item[item.id].brief, 
        width = LABEL_WIDTH-icon:getContentSize().width, align = kCCTextAlignmentLeft,
    })
    brief:setAnchorPoint(ccp(0, 1))
    brief:setPosition(TIPS_MARGIN+96, icon:boundingBox():getMaxY())
    container:addChild(brief)

    -- 赌场要显示概率
    local rate = nil
    if rate_type and rate_type == RATE_CASINO then
        local casinodata = require "data.casino"
        rate = casinodata.getRateById(item.id, 1)
    elseif rate_type and rate_type == RATE_HCASINO then
        local casinodata = require "data.highcasino"
        rate = casinodata.getRateById(item.id, 1)
    end
    rate_type = nil
    if rate and rate > 0 then
        local lbl_rate = lbl.createMix({
            font = 1, size = 16, text = i18n.global.casino_item_rate.string .. ":" .. rate .. "%", 
            width = LABEL_WIDTH-icon:getContentSize().width, align = kCCTextAlignmentLeft,
        })
        lbl_rate:setAnchorPoint(ccp(0, 0))
        lbl_rate:setPosition(TIPS_MARGIN+96, icon:boundingBox():getMinY())
        container:addChild(lbl_rate)
    end

    -- 已装备标识
    if item.owner then
        local head = img.createHeroHead(item.owner.id, item.owner.lv, true, true)
        head:setScale(0.8)
        head:setAnchorPoint(ccp(1, 0.5))
        head:setPosition(TIPS_WIDTH-TIPS_MARGIN, icon:boundingBox():getMidY())
        container:addChild(head)
    end

    -- 描述
    local explain = i18n.item[item.id].explain 
    if explain and explain ~= "" then
        local label = lbl.createMix({
            font = 1, size = 18, text = explain, color = ccc3(0xff, 0xf2, 0x98),
            width = LABEL_WIDTH, align = kCCTextAlignmentLeft,
        })
        label:setAnchorPoint(ccp(0, 1))
        label:setPosition(TIPS_MARGIN, currentY-15)
        container:addChild(label)
        currentY = label:boundingBox():getMinY()
    end

    local height = - currentY

    local layer = CCLayer:create()
    layer:ignoreAnchorPointForPosition(false)
    layer:setContentSize(CCSize(TIPS_WIDTH, height))
    container:setPosition(0, height)
    layer:addChild(container)

    return layer
end

-- tips中部是一个scrollView，放各种文本
function tips.createMiddle(item, showUnsell, btn1text, btn1handler, btn2text, btn2handler)
    local labels = {}

    -- 魂玉属性和值
    if cfgitem[item.id].type == ITEM_KIND_JADE then
        for i, bonus in ipairs(cfgitem[item.id].JadeBonus) do
            local name, value = buffString(bonus.type, bonus.num)
            labels[#labels+1] = {
                label = lbl.createMixFont1(18, "+" .. value .. " " .. name, ccc3(0x7e, 0xe7, 0x30)),
                x = TIPS_MARGIN,
                offsetY = op3(attrNum == 1, 0, 2),
            }
        end
    end

    -- 显示不能出售字样
    if showUnsell and cfgitem[item.id].recovery ~= 1 then
        labels[#labels+1] = {
            label = lbl.createMixFont1(18, i18n.global.tips_unsellable.string, ccc3(0xfa, 0x35, 0x35)),
            x = TIPS_MARGIN,
            offsetY = op3(cfgitem[item.id].type == ITEM_KIND_JADE, 10, 0),
        }
    end

    local container, currentY = alignLabels(labels)
    local cHeight = - currentY
    local vHeight = op3(cHeight < SCROLL_HEIGHT, cHeight, SCROLL_HEIGHT)

    local scroll = CCScrollView:create()
    scroll:setDirection(kCCScrollViewDirectionVertical)
    scroll:ignoreAnchorPointForPosition(false)
    scroll:setContentSize(CCSize(TIPS_WIDTH, cHeight))
    scroll:setViewSize(CCSize(TIPS_WIDTH, vHeight))
    scroll:setTouchEnabled(cHeight > vHeight)
    scroll:setContentOffset(ccp(0, vHeight - cHeight))
    container:setPosition(0, cHeight)
    scroll:getContainer():addChild(container)

    return scroll
end

-- tips底部内容：主要是按钮
function tips.createFooter(item, showUnsell, btn1text, btn1handler, btn2text, btn2handler)
    local container
    local btnW, btnH = 130, 50
    if btn1text or btn2text then
        container = CCLayer:create()
        container:ignoreAnchorPointForPosition(false)
        container:setContentSize(CCSize(TIPS_WIDTH, btnH))
    end

    if btn1text then
        local btn0 = img.createLogin9Sprite(img.login.button_9_small_gold)
        btn0:setPreferredSize(CCSize(btnW, btnH))
        local btn = SpineMenuItem:create(json.ui.button, btn0)
        btn:setPosition(op3(btn2text, TIPS_WIDTH/2-75, TIPS_WIDTH/2), btnH/2)
        local btnLbl = lbl.createFont1(18, btn1text, ccc3(0x73, 0x3b, 0x05))
        btnLbl:setPosition(btnW/2, btnH/2)
        btn0:addChild(btnLbl)
        local btnMenu = CCMenu:createWithItem(btn)
        btnMenu:setPosition(0, 0)
        container:addChild(btnMenu)
        btn:registerScriptTapHandler(function()
            audio.play(audio.button)
            if btn1handler then btn1handler(item) end
        end)
    end

    if btn2text then
        local btn0 = img.createLogin9Sprite(img.login.button_9_small_gold)
        btn0:setPreferredSize(CCSize(btnW, btnH))
        local btn = SpineMenuItem:create(json.ui.button, btn0)
        btn:setPosition(TIPS_WIDTH/2+75, btnH/2)
        local btnLbl = lbl.createFont1(18, btn2text, ccc3(0x73, 0x3b, 0x05))
        btnLbl:setPosition(btnW/2, btnH/2)
        btn0:addChild(btnLbl)
        local btnMenu = CCMenu:createWithItem(btn)
        btnMenu:setPosition(0, 0)
        container:addChild(btnMenu)
        btn:registerScriptTapHandler(function()
            audio.play(audio.button)
            if btn2handler then btn2handler(item) end
        end)
    end

    return container
end

-- 将tips.createHeader, tips.createMiddle, tips.createFooter组合在一起，并包上tips背景框
function tips.create(item, showUnsell, btn1text, btn1handler, btn2text, btn2handler)
    local header = tips.createHeader(item, showUnsell, btn1text, btn1handler, btn2text, btn2handler)
    local middle = tips.createMiddle(item, showUnsell, btn1text, btn1handler, btn2text, btn2handler)
    local footer = tips.createFooter(item, showUnsell, btn1text, btn1handler, btn2text, btn2handler)

    local container = CCLayer:create()
    local currentY = 0

    if header then
        header:setAnchorPoint(ccp(0, 1))
        header:setPosition(0, currentY-17)
        container:addChild(header)
        currentY = header:boundingBox():getMinY()
        --drawBoundingbox(container, header, ccc4f(1, 0, 0, 1))
    end

    if middle then
        middle:setAnchorPoint(ccp(0, 1))
        middle:setPosition(0, currentY-13)
        container:addChild(middle)
        currentY = middle:boundingBox():getMinY()
        --drawBoundingbox(container, middle, ccc4f(0, 1, 0, 1))
    end

    if footer then
        footer:setAnchorPoint(ccp(0, 1))
        footer:setPosition(0, currentY-17)
        container:addChild(footer)
        currentY = footer:boundingBox():getMinY()
        --drawBoundingbox(container, footer, ccc4f(0, 0, 1, 1))
    end

    local height = 30 - currentY

    local bg = img.createUI9Sprite(img.ui.tips_bg)
    bg:setPreferredSize(CCSize(TIPS_WIDTH, height))
    container:setPosition(0, height)
    bg:addChild(container)

    return bg
end

-- 为tips加上全屏黑背景
function tips.createLayer(kind, item, item2, handler1, handler2)
    local layer = CCLayer:create()


    --print("item id=", item.id)
    
    function layer.onSkinPieceInfo()
        local id = cfgitem[item.id].equip.id
        local parent = layer:getParent()
        parent:addChild(require("ui.skin.preview").create(id, i18n.equip[id].name), 10000)
        layer.onAndroidBack()
    end

    function layer.onPieceInfo()
        local id = cfgitem[item.id].heroCost.id
        local zOrder = layer:getZOrder()
        local parent = layer:getParent()
        parent:addChild(require("ui.herolist.herobook").create(id), zOrder)
        layer.onAndroidBack()
    end

    local tips1, tips2
    if kind == "show" then
        if cfgitem[item.id].type == ITEM_KIND_HERO_PIECE and not isUniversalPiece(item.id) then
            tips1 = tips.create(item, false, i18n.global.tips_info.string, layer.onPieceInfo)
        elseif cfgitem[item.id].type == ITEM_KIND_SKIN_PIECE and item.id ~= ITEM_ID_PIECE_SKIN then  --皮肤碎片
            tips1 = tips.create(item, false, i18n.global.ui_decompose_preview.string, layer.onSkinPieceInfo)
        else
            tips1 = tips.create(item, false)
        end
    elseif kind == "bag" then
        if cfgitem[item.id].giftId and cfgitem[item.id].isAutoOpen == 2 then   -- 背包中的礼包
            tips1 = tips.create(item, true, i18n.global.tips_gift.string, handler1)
        elseif cfgitem[item.id].type == ITEM_KIND_HERO_PIECE then
            if isUniversalPiece(item.id) or item.id == ITEM_ID_PIECE_SKIN then
                -- 万能碎片
                if item.num >= cfgitem[item.id].heroCost.count then
                    tips1 = tips.create(item, true, i18n.global.tips_summon.string, handler1)
                else
                    tips1 = tips.create(item, true)
                end
            else
                -- 普通碎片
                if item.num >= cfgitem[item.id].heroCost.count then
                    tips1 = tips.create(item, false, i18n.global.tips_info.string, layer.onPieceInfo,
                                                     i18n.global.tips_summon.string, handler1)
                else
                    tips1 = tips.create(item, false, i18n.global.tips_info.string, layer.onPieceInfo,
                                                     i18n.global.tips_sell.string, handler1)
                end
            end
        elseif cfgitem[item.id].type == ITEM_KIND_SKIN_PIECE then--皮肤碎片
            if item.id == ITEM_ID_PIECE_SKIN then
                tips1 = tips.create(item, true, i18n.global.tips_forge.string, handler1)
            else
                if item.num >= cfgitem[item.id].equip.count then
                    tips1 = tips.create(item, false, i18n.global.ui_decompose_preview.string, layer.onSkinPieceInfo,
                                                     i18n.global.tips_forge.string, handler1)
                else
                    tips1 = tips.create(item, true, i18n.global.ui_decompose_preview.string, layer.onSkinPieceInfo)
                end
            end
        elseif cfgitem[item.id].type == ITEM_KIND_TREASURE_PIECE then--宝石碎片
            if item.num >= cfgitem[item.id].treasureCost.count then
                tips1 = tips.create(item, true, i18n.global.tips_summon.string, handler1)
            else
                tips1 = tips.create(item, true)
            end
        elseif cfgitem[item.id].recovery ~= 1 then
            -- 不可出售的普通物品
            tips1 = tips.create(item, true)
        else
            -- 可出售的普通物品
            tips1 = tips.create(item, false, i18n.global.tips_sell.string, handler1)
        end
        
        if cfgitem[item.id].getWays then
            -- 获取途径按钮
            local getwaytips = nil
            local getway0 = img.createUISprite(img.ui.bag_icon_getway)
            local getwayBtn = SpineMenuItem:create(json.ui.button, getway0)
            getwayBtn:setPosition(tips1:getContentSize().width-38, tips1:getContentSize().height - 35)
            local getwayBtnMenu = CCMenu:createWithItem(getwayBtn)
            getwayBtnMenu:setPosition(0, 0)
            tips1:addChild(getwayBtnMenu)
            getwayBtn:registerScriptTapHandler(function()
                audio.play(audio.button)
                if getwaytips == nil then
                    --tips1:setPosition(view.physical.w/2-tips1:getContentSize().width/2, view.physical.h/2)
                    tips1:runAction(CCMoveTo:create(0.1, CCPoint(view.physical.w/2-tips1:getContentSize().width/2*view.minScale, view.physical.h/2)))
                    schedule(layer, 0.1, function()
                        getwaytips = (require "ui.tips.getway").createLayer(item, 1)
                        tips2 = getwaytips.bg
                        layer:addChild(getwaytips)
                    end)
                else
                    --tips1:setPosition(view.physical.w/2, view.physical.h/2)
                    tips1:runAction(CCMoveTo:create(0.1, CCPoint(view.physical.w/2, view.physical.h/2)))
                    tips2 = nil
                    getwaytips:removeFromParentAndCleanup(true)
                    getwaytips = nil
                end
            end)
        end
    elseif kind == "market" then
        if cfgitem[item.id].type == ITEM_KIND_HERO_PIECE and not isUniversalPiece(item.id) then
            tips1 = tips.create(item, false, i18n.global.tips_info.string, layer.onPieceInfo,
                                             i18n.global.tips_buy.string, handler1)
        else
            tips1 = tips.create(item, false, i18n.global.tips_buy.string, handler1)
        end
    elseif kind == "forge" then
        tips1 = tips.create(item, false, i18n.global.tips_put_in.string, handler1)
    elseif kind == "jadeOn" then
        tips1 = tips.create(item, false, i18n.global.tips_put_on.string, handler1)
    elseif kind == "jadeOff" then
        tips1 = tips.create(item, false, i18n.global.tips_put_off.string, handler1)
    elseif kind == "jadeReplace" then
        tips1 = tips.create(item, false, i18n.global.tips_put_off.string, handler1,
                                         i18n.global.tips_replace.string, handler2)
    elseif kind == "jadeCompare" then
        tips1 = tips.create(item, false, i18n.global.tips_replace.string, handler1)
        tips2 = tips.create(item2, false)
    end

    if tips2 then
        tips1:setScale(view.minScale)
        tips1:setAnchorPoint(ccp(0, 1))
        layer:addChild(tips1)
        tips2:setScale(view.minScale)
        tips2:setAnchorPoint(ccp(1, 1))
        layer:addChild(tips2)
        local tips1h = tips1:getPreferredSize().height
        local tips2h = tips2:getPreferredSize().height
        local h = view.physical.h/2 + math.max(tips1h, tips2h)/2*view.minScale
        tips1:setPosition(view.physical.w/2+1, h)
        tips2:setPosition(view.physical.w/2, h)
    else
        tips1:setScale(view.minScale)
        tips1:setPosition(view.physical.w/2, view.physical.h/2)
        layer:addChild(tips1)
    end

    -- 点击空白区域的回调
    local clickBlankHandler
    function layer.setClickBlankHandler(handler)
        clickBlankHandler = handler
    end

    local function onTouch(eventType, x, y)
        if eventType == "began" then   
            return true
        elseif eventType == "moved" then
            return 
        else
            if not tips1:boundingBox():containsPoint(ccp(x, y))
                and (tips2 == nil or (tips2 and (not tolua.isnull(tips2)) and not tips2:boundingBox():containsPoint(ccp(x, y)))) then
                layer.onAndroidBack()
            end
        end
    end

    addBackEvent(layer)

    function layer.onAndroidBack()
        if clickBlankHandler then
            clickBlankHandler()
        else
            layer:removeFromParent()
        end
    end

    layer:registerScriptHandler(function(event)
        if event == "enter" then
            layer.notifyParentLock()
        elseif event == "exit" then
            layer.notifyParentUnlock()
        end
    end)

    layer:registerScriptTouchHandler(onTouch)
    layer:setTouchEnabled(true)
    layer:setTouchSwallowEnabled(true)

    return layer
end

return tips
