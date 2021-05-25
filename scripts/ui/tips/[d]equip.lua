-- 装备tips, 有回调则为handler(equip)形式
-- equip = { id, num, owner(装备所有者), hero(英雄面板当前英雄) } 
--     除id外其他可选

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
local cfgpoker = require "config.poker"
local bagdata = require "data.bag"
local herosdata = require "data.heros"
local i18n = require "res.i18n"
local attrHelper = require "fight.helper.attr"

local TIPS_WIDTH = 360 -- tips背景框的宽度
local TIPS_MARGIN = 20 -- tips文字到背景边的距离
local SCROLL_HEIGHT = 320 -- middle区域scrollView的最大高度
local LABEL_WIDTH = TIPS_WIDTH - 2 * TIPS_MARGIN

local rate_type = nil
local RATE_CASINO = "casino"
local RATE_HCASINO = "hcasino"

function tips.createForShow(equip)
    return tips.createLayer("show", equip)
end

function tips.createForShowCasino(equip)
    rate_type = RATE_CASINO
    return tips.createLayer("show", equip)
end

function tips.createForShowHCasino(equip)
    rate_type = RATE_HCASINO
    return tips.createLayer("show", equip)
end

function tips.createById(id)
    return tips.createForShow({id = id})
end

function tips.createForPb(pb)
    return tips.createForShow(pb)
end

function tips.createForHero(equip, handler1, handler2, handler3)
    return tips.createLayer("hero", equip, handler1, handler2, handler3)
end

function tips.createForBag(equip, handler)
    return tips.createLayer("bag", equip, handler)
end

function tips.createForSmith(equip)
    return tips.createLayer("smith", equip)
end

function tips.createForSkin(equip, handler1, handler2, handler3)
    return tips.createLayer("skin", equip, handler1, handler2, handler3)
end

function tips.createForTreasureLevelUp(equip, handler1, handler2)
    return tips.createLayer("treasureLevelUp", equip, handler1, handler2)
end




-- tips顶部内容：主要是大图标，战力显示等
function tips.createHeader(layer, equip, btn1text, btn1handler, btn2text, btn2handler, levelUphandler)
    local container = CCLayer:create()
    local currentY = 0

    -- name
    local name = lbl.createMix({
        font = 1, size = 18, text = i18n.equip[equip.id].name, 
        width = LABEL_WIDTH, align = kCCTextAlignmentLeft,
        color = lbl.qualityColors[cfgequip[equip.id].qlt],
    })
    name:setAnchorPoint(ccp(0, 1))
    name:setPosition(TIPS_MARGIN, currentY)
    container:addChild(name)
    currentY = name:boundingBox():getMinY()

    -- icon
    local icon
    if cfgequip[equip.id].pos == EQUIP_POS_SKIN then
        icon = img.createSkinEquip(equip.id)
    else 
        icon = img.createEquip(equip.id)
    end
    icon:setScale(0.9)
    icon:setAnchorPoint(ccp(0, 0.5))
    icon:setPosition(TIPS_MARGIN, currentY-49)
    container:addChild(icon)
    currentY = icon:boundingBox():getMinY()

    ---- 战斗力
    --local power = lbl.createMixFont1(18, i18n.global.tips_power.string, ccc3(0xf0, 0xd9, 0x66))
    --power:setAnchorPoint(ccp(0, 1))
    --power:setPosition(TIPS_MARGIN+96, icon:boundingBox():getMaxY())
    --container:addChild(power)

    ---- 战斗力数字
    --local num = lbl.createMixFont2(28, attrHelper.equipPower(equip.id), ccc3(0xfb, 0xfb, 0xfb))
    --num:setAnchorPoint(ccp(0, 0.5))
    --num:setPosition(power:boundingBox():getMinX()-4, icon:boundingBox():getMidY())
    --container:addChild(num)

    -- 装备位置
    local pos = lbl.createMixFont1(18, i18n.global["equip_pos_" .. cfgequip[equip.id].pos].string, ccc3(0xfb, 0xfb, 0xfb))
    pos:setAnchorPoint(ccp(0, 0))
    pos:setPosition(TIPS_MARGIN+96, icon:boundingBox():getMidY())
    container:addChild(pos)

    -- 赌场要显示概率
    local rate = nil
    if rate_type and rate_type == RATE_CASINO then
        local casinodata = require "data.casino"
        rate = casinodata.getRateById(equip.id, 2)
    elseif rate_type and rate_type == RATE_HCASINO then
        local casinodata = require "data.highcasino"
        rate = casinodata.getRateById(equip.id, 2)
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
	
	if cfgequip[equip.id].pos == EQUIP_POS_SKIN and levelUphandler then
		local btn0 = img.createUISprite(img.ui.treasure_up)
		local btn = SpineMenuItem:create(json.ui.button, btn0)
		btn:setPosition(TIPS_WIDTH-TIPS_MARGIN - btn0:getContentSize().width * 0.5, icon:boundingBox():getMidY())
		local btnMenu = CCMenu:createWithItem(btn)
		btnMenu:setPosition(0, 0)
		container:addChild(btnMenu)
		btn:registerScriptTapHandler(function()
			--audio.play(audio.button)
			levelUphandler()
			--local upgrade = require "ui.treasure.upgrade"
			--layer:addChild(upgrade.create(equip, levelUphandler), 1000)
		end)
		--if equip.num < 3 then require("ui.custom").setButtonEnabled(btn, false) end
	end

    -- 英雄图标
    if equip.owner then
        if cfgequip[equip.id].pos == EQUIP_POS_TREASURE then
            if cfgequip[equip.id].treasureNext and levelUphandler then
                local btn0 = img.createUISprite(img.ui.treasure_up)
                local btn = SpineMenuItem:create(json.ui.button, btn0)
                btn:setPosition(TIPS_WIDTH-TIPS_MARGIN - btn0:getContentSize().width * 0.5, icon:boundingBox():getMidY())
                local btnMenu = CCMenu:createWithItem(btn)
                btnMenu:setPosition(0, 0)
                container:addChild(btnMenu)
                btn:registerScriptTapHandler(function()
                    audio.play(audio.button)
                    local upgrade = require "ui.treasure.upgrade"
                    layer:addChild(upgrade.create(equip, levelUphandler), 1000)
                end)
            end
        else
            --local head = img.createHeroHead(equip.owner.id, equip.owner.lv, true, true, equip.owner.wake)
            local param = {
                id = equip.owner.id,
                lv = equip.owner.lv,
                showGroup = true,
                showStar = true,
                wake = equip.owner.wake,
                orangeFx = nil,
                petID = nil,
                hskills = equip.owner.hskills,
                hid = equip.owner.hid
            }
            local head = img.createHeroHeadByParam(param)
            head:setScale(0.8)
            head:setAnchorPoint(ccp(1, 0.5))
            head:setPosition(TIPS_WIDTH-TIPS_MARGIN, icon:boundingBox():getMidY())
            container:addChild(head)
        end
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
function tips.createMiddle(equip, btn1text, btn1handler, btn2text, btn2handler)
    local labels = {}
    local owner = equip.owner

    -- 固定属性
    for i = 1, 3 do
        local attr = cfgequip[equip.id]["base" .. i]
        if attr then
            local name, value = buffString(attr.type, math.abs(attr.num))
            local attr_str = "+" .. value .. " " .. name
            if attr.num < 0 then
                attr_str = "-" .. value .. " " .. name
            end
            labels[#labels+1] = {
                label = lbl.createMixFont1(18, attr_str, ccc3(0xfb, 0xfb, 0xfb)),
                x = TIPS_MARGIN,
                offsetY = op3(i == 1, 0, 2),
            }
        end
    end

    -- 激活属性
    if cfgequip[equip.id].job or cfgequip[equip.id].group then
        local activated = false
        if owner and (arraycontains(cfgequip[equip.id].job, cfghero[owner.id].job)
            or cfgequip[equip.id].group == cfghero[owner.id].group) then
            activated = true
        end
        local titleArr = {}
        if cfgequip[equip.id].job then
            for _, id in ipairs(cfgequip[equip.id].job) do
                if cfgequip[equip.id].job then
                    titleArr[#titleArr+1] = i18n.global["job_" .. id].string
                end
            end
        elseif cfgequip[equip.id].group then
            titleArr[#titleArr+1] = i18n.global["hero_group_" .. cfgequip[equip.id].group].string
        end

        labels[#labels+1] = {
            label = lbl.createMix({
                font = 1, size = 18, 
                text = i18n.global.tips_activate.string .. table.concat(titleArr, ","),
                color = op3(activated, ccc3(0xed, 0xcb, 0x1f), ccc3(0x7f, 0x7f, 0x7f)),
                width = LABEL_WIDTH, align = kCCTextAlignmentLeft,
            }),
            x = TIPS_MARGIN,
            offsetY = 10,
        }
        local attrColor = op3(activated, ccc3(0xfb, 0xfb, 0xfb), ccc3(0x7f, 0x7f, 0x7f))
        for i = 1, 3 do
            local attr = cfgequip[equip.id]["act" .. i]
            if attr then
                local name, value = buffString(attr.type, math.abs(attr.num))
                local attr_str = "+" .. value .. " " .. name
                if attr.num < 0 then
                    attr_str = "-" .. value .. " " .. name
                end
                labels[#labels+1] = {
                    label = lbl.createMixFont1(18, attr_str, attrColor),
                    x = TIPS_MARGIN,
                    offsetY = op3(i == 1, 4, 2),
                }
            end
        end
    end

    -- 套装属性
    if cfgequip[equip.id].form then
        local sum = #cfgequip[equip.id].form
        local num = 0
        if owner then
            for _, id in ipairs(owner.equips) do
                if arrayequal(cfgequip[id].form, cfgequip[equip.id].form) then
                    num = num + 1
                end
            end
        end
        local titleText
        if num > 0 then
            titleText = i18n.equip[equip.id].suitName .. " (" .. num .. "/" .. sum .. ")"
        else
            titleText = i18n.equip[equip.id].suitName .. " (" .. sum .. ")"
        end
        labels[#labels+1] = {
            label = lbl.createMix({
                font = 1, size = 18, text = titleText,
                color = ccc3(0xed, 0xcb, 0x1f),
                width = LABEL_WIDTH, align = kCCTextAlignmentLeft,
            }),
            x = TIPS_MARGIN,
            offsetY = 10,
        }
        for i = 1, 3 do
            local attr = cfgequip[equip.id]["suit" .. i]
            if attr then
                local attr = cfgequip[equip.id]["suit" .. i]
                local name, value = buffString(attr.type, math.abs(attr.num))
                local attr_str = "+" .. value .. " " .. name
                if attr.num < 0 then
                    attr_str = "-" .. value .. " " .. name
                end
                local attrColor = op3(num >= i+1, ccc3(0x7e, 0xe7, 0x30), ccc3(0x7f, 0x7f, 0x7f))
                labels[#labels+1] = {
                    label = lbl.createMixFont1(18, attr_str, attrColor),
                    x = TIPS_MARGIN,
                    offsetY = op3(i == 1, 4, 2),
                }
            end
        end
    end

    -- 骚包描述
    if i18n.equip[equip.id].explain then
        labels[#labels+1] = {
            label = lbl.createMix({
                font = 1, size = 18, text = i18n.equip[equip.id].explain,
                color = ccc3(0xff, 0xf2, 0x98),
                width = LABEL_WIDTH, align = kCCTextAlignmentLeft,
            }),
            x = TIPS_MARGIN,
            offsetY = 10,
        }
    end

    ---- 穿戴等级
    --labels[#labels+1] = {
    --    label = lbl.createMix({
    --        font = 1, size = 18, 
    --        text = i18n.global.tips_require_lv.string .. cfgequip[equip.id].lv,
    --        color = op3(hero and hero.lv > cfgequip[equip.id].lv, 
    --                    ccc3(0xff, 0xff, 0xff), ccc3(0xfa, 0x35, 0x35)),
    --    }),
    --    x = TIPS_MARGIN,
    --    offsetY = 10,
    --}

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
function tips.createFooter(equip, btn1text, btn1handler, btn2text, btn2handler)
    local container
    local btnW, btnH = 130, 50
    if btn1text or btn2text then
        container = CCLayer:create()
        container:ignoreAnchorPointForPosition(false)
        container:setContentSize(CCSize(TIPS_WIDTH, btnH))
    end

    if btn1text then
        local btn0
        
        if cfgequip[equip.id].pos == 7 and cfgequip[equip.id].powerful == nil and equip.flag and equip.flag == true then 
            btn0 = img.createLogin9Sprite(img.login.button_9_small_orange)
        else
            btn0 = img.createLogin9Sprite(img.login.button_9_small_gold)
        end
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
            if btn1handler then btn1handler(equip) end
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
            if btn2handler then btn2handler(equip) end
        end)
    end

    return container
end

-- 将tips.createHeader, tips.createMiddle, tips.createFooter组合在一起，并包上tips背景框
function tips.create(superLayer, equip, btn1text, btn1handler, btn2text, btn2handler, levelUphandler)
    local container = CCLayer:create()

    local header = tips.createHeader(superLayer, equip, btn1text, btn1handler, btn2text, btn2handler, levelUphandler)
    local middle = tips.createMiddle(equip, btn1text, btn1handler, btn2text, btn2handler)
    local footer = tips.createFooter(equip, btn1text, btn1handler, btn2text, btn2handler)

    
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

--function tips.createForSmith(equip)
--    local header = tips.createHeader(equip, btn1text, btn1handler, btn2text, btn2handler)
--    local middle = tips.createMiddle(equip, btn1text, btn1handler, btn2text, btn2handler)

--    local container = CCLayer:create()
--    local currentY = 0

--    if header then
--        header:setAnchorPoint(ccp(0, 1))
--        header:setPosition(0, currentY)
--        container:addChild(header)
--        currentY = header:boundingBox():getMinY()
--        --drawBoundingbox(container, header, ccc4f(1, 0, 0, 1))
--    end

--    if middle then
--        local size = middle:getContentSize()
--        middle:setViewSize(CCSize(size.width, size.height))
--        middle:setTouchEnabled(false)
--        middle:setContentOffset(ccp(0, 0))
--        middle:setAnchorPoint(ccp(0, 1))
--        middle:setPosition(0, currentY-13)
--        container:addChild(middle)
--        currentY = middle:boundingBox():getMinY()
--        --drawBoundingbox(container, middle, ccc4f(0, 1, 0, 1))
--    end

--    local cHeight = 15 - currentY
--    local vHeight = 208
--    cHeight = op3(cHeight < vHeight, vHeight, cHeight)

--    local scroll = CCScrollView:create()
--    scroll:setDirection(kCCScrollViewDirectionVertical)
--    scroll:setContentSize(CCSize(TIPS_WIDTH, cHeight))
--    scroll:setViewSize(CCSize(TIPS_WIDTH, vHeight))
--    scroll:setTouchEnabled(cHeight > vHeight)
--    scroll:setContentOffset(ccp(0, vHeight - cHeight))
--    container:setPosition(0, cHeight)
--    scroll:getContainer():addChild(container)

--    local bg = img.createUI9Sprite(img.ui.tips_bg)
--    bg:setPreferredSize(CCSize(390, vHeight+30))
--    scroll:setPosition(0, 15)
--    bg:addChild(scroll)
--    --drawBoundingbox(bg, scroll, ccc4f(0, 0, 1, 1))

--    return bg
--end

function tips.createForDrop(equip, can, cannot)
    local h = 330
    local bg = img.createUI9Sprite(img.ui.tips_bg)
    bg:setPreferredSize(CCSize(TIPS_WIDTH, h))

    local hint = lbl.createMixFont1(16, i18n.global.tips_drop_hint.string, ccc3(0xff, 0xf6, 0xdf))
    hint:setAnchorPoint(ccp(0, 1))
    hint:setPosition(25, h-22)
    bg:addChild(hint)

    local box = img.createUI9Sprite(img.ui.smith_drop_bg)
    box:setAnchorPoint(ccp(0.5, 1))
    box:setPreferredSize(CCSize(TIPS_WIDTH-50, h-86))
    box:setPosition(TIPS_WIDTH/2, h-60)
    bg:addChild(box)

    for i, stage in ipairs(arraymerge(can, cannot)) do
        local disable = arraycontains(cannot, stage)
        local btnW, btnH = TIPS_WIDTH-66, 72
        local btn0
        if disable then
            btn0 = img.createLogin9Sprite(img.login.button_9_small_grey)
        else
            btn0 = img.createLogin9Sprite(img.login.button_9_small_mwhite)
        end
        btn0:setPreferredSize(CCSize(btnW, btnH))
        local btn = SpineMenuItem:create(json.ui.button, btn0)
        btn:setPosition(TIPS_WIDTH/2, h-27-i*78)
        btn:setEnabled(not disable)
        local fort, num = require("data.hook").getFortStageByStageId(stage)
        local text = string.format(i18n.global.tips_go_hook.string, fort, num)
        local btnLbl = lbl.createFont1(18, text, ccc3(0x73, 0x3b, 0x05))
        btnLbl:setPosition(btnW/2, btnH/2)
        btn0:addChild(btnLbl)
        if disable then setShader(btnLbl, SHADER_GRAY, true) end
        local btnMenu = CCMenu:createWithItem(btn)
        btnMenu:setPosition(0, 0)
        bg:addChild(btnMenu)
        btn:registerScriptTapHandler(function()
            audio.play(audio.button)
            if require("data.hook").getHookStage() == stage then
                showToast(i18n.global.hook_already_hooked.string)
                return
            end
            replaceScene(require("ui.hook.map").create({pop_layer = "stage", stage_id = stage}))
        end)
    end

    return bg
end

-- 为tips加上全屏黑背景
function tips.createLayer(kind, equip, handler1, handler2, handler3)
    local layer = CCLayer:create()

    local tips1, tips2

    local function createTips(kind, equip, handler1, handler2, handler3)
        if kind == "show" then
            tips1 = tips.create(layer, equip)
        elseif kind == "bag" then
            if cfgequip[equip.id].price and cfgequip[equip.id].price > 0 then
                tips1 = tips.create(layer, equip, i18n.global.tips_sell.string, handler1)
            else
                tips1 = tips.create(layer, equip)
            end

            if cfgequip[equip.id].getWays then
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
                            getwaytips = (require "ui.tips.getway").createLayer(equip, 2)
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
        elseif kind == "skin" then
            --if (cfgequip[equip.id].powerful and cfgequip[equip.id].powerful ~= 0) or equip.flag == false then
			if (cfgequip[equip.id].powerful and cfgequip[equip.id].powerful ~= 0) and handler3 then
				handler3 = nil
			end
			if equip.flag == false then
                tips1 = tips.create(layer, equip, i18n.global.ui_decompose_preview.string, handler1)
            else
				if handler3 and handler2 then
					tips1 = tips.create(layer, equip, i18n.global.devour_btn.string, handler2, i18n.global.ui_decompose_preview.string, handler1, handler3)
                elseif handler2 then
                    tips1 = tips.create(layer, equip, i18n.global.devour_btn.string, handler2, i18n.global.ui_decompose_preview.string, handler1)
                else
                    tips1 = tips.create(layer, equip, i18n.global.ui_decompose_preview.string, handler1)
                end
            end
        elseif kind == "smith" then
            local can, cannot = tips.dropStages(equip.id)
            tips1 = tips.createForDrop(equip, can, cannot)
            tips1:setVisible(false)
            tips2 = tips.create(layer, equip, i18n.global.tips_drop.string, function()
                audio.play(audio.button)
                if #can + #cannot == 0 then
                    showToast(i18n.global.tips_no_drop.string)
                    return
                end
                tips1:setVisible(true)
            end)
        elseif kind == "hero" then
            if cfgequip[equip.id].pos == EQUIP_POS_JADE then -- 水晶
                if isJadeUpgradable(equip.id) then
                    tips1 = tips.create(layer, equip, i18n.global.tips_recast.string, handler1, 
                                               i18n.global.tips_upgrade.string, handler2)
                else
                    tips1 = tips.create(layer, equip, i18n.global.tips_recast.string, handler1)
                end
            elseif equip.hero and equip.hero == equip.owner then
                if tips.existsAvailableEquipInBag(equip.hero, cfgequip[equip.id].pos) then
                    -- 点击的是英雄身上的这个装备，且背包中有可替换的装备，则tips上要显示替换按钮
                    tips1 = tips.create(layer, equip, i18n.global.tips_take_off.string, handler1, 
                                               i18n.global.tips_replace.string, handler2, handler3)
                else
                    -- 点击的是英雄身上的这个装备，且背包中无可替换的装备，则tips上只显示脱下按钮
                    tips1 = tips.create(layer, equip, i18n.global.tips_take_off.string, handler1, nil, nil, handler3)
                end
            else 
                local equip2
                for _, id in ipairs(equip.hero.equips) do
                    if cfgequip[id].pos == cfgequip[equip.id].pos then
                        equip2 = { id = id, owner = equip.hero }
                        break
                    end
                end
                if equip2 then -- 点击的是背包格中的装备，且英雄该位置有穿戴，则显示tips对比
                    tips1 = tips.create(layer, equip, i18n.global.tips_replace.string, handler1)
                    tips2 = tips.create(layer, equip2)
                else -- 点击的是背包格中的装备，且英雄该位置无穿戴，则tips上显示穿上按钮
                    tips1 = tips.create(layer, equip, i18n.global.tips_put_on.string, handler1)
                end
            end
        elseif kind == "treasureLevelUp" then
            tips1 = tips.create(layer, equip, i18n.global.treasure_material_put_one.string, handler1, i18n.global.treasure_material_put_ten.string, handler2)
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
    end

    createTips(kind, equip, handler1, handler2, handler3)

    --刷新
    layer.refresh = function (newEquip)
        if tips1 then
            tips1:removeFromParent()
            tips1 = nil
        end
        if tips2 then
            tips2:removeFromParent()
            tips2 = nil
        end

        createTips(kind, newEquip, handler1, handler2, handler3)
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
            if (tips1:isVisible() and tips1:boundingBox():containsPoint(ccp(x, y)))
                or (tips2 and (not tolua.isnull(tips2)) and tips2:boundingBox():containsPoint(ccp(x, y))) then
                -- do nothing
            else
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

-- 背包中有没有该英雄在该位置能穿的装备
function tips.existsAvailableEquipInBag(hero, pos)
    for i, eq in ipairs(bagdata.equips) do
        if cfgequip[eq.id].pos == pos and hero.lv >= cfgequip[eq.id].lv then
            return true
        end
    end
    return false
end

-- 取装备的掉落关卡
function tips.dropStages(id)
    local max = require("data.hook").getMaxHookStage()
    local num = 3
    local can, cannot = {}, {}
    -- 找num个能挂的
    if max > 0 and max <= #cfgpoker then
        for i = max, 1, -1 do
            for _, info in ipairs(cfgpoker[i].yes) do
                if info.id == id and info.type == 2 then
                    table.insert(can, 1, i)
                    break
                end
            end
            if #can == num then break end
        end
    end
    -- 找num个不能挂的
    if max + 1 > 0 and max + 1 <= #cfgpoker then
        for i = max+1, #cfgpoker do
            for _, info in ipairs(cfgpoker[i].yes) do
                if info.id == id and info.type == 2 then
                    table.insert(cannot, i)
                    break
                end
            end
            if #cannot == num then break end
        end
    end
    -- 保证返回3个或3个以内
    if #can + #cannot <= 3 then
        return can, cannot
    elseif #can == 1 then
        return can, {cannot[1], cannot[2]}
    elseif #can == 2 then
        return can, {cannot[1]}
    elseif #can == 3 then
        return {can[2], can[3]}, {cannot[1]}
    end
    return can, cannot
end

return tips
