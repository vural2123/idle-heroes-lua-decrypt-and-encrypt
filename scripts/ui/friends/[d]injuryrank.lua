local ui = {}

require "common.const"
require "common.func"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local audio = require "res.audio"
local i18n = require "res.i18n"
local player = require "data.player"
local net = require "net.netClient"

local space_height = 0

-- 背景框大小
local BG_WIDTH   = 604
local BG_HEIGHT  = 514

local perall = 0

local icon_rank = {
    [1] = img.ui.arena_rank_1,
    [2] = img.ui.arena_rank_2,
    [3] = img.ui.arena_rank_3,
}

local function createItem(rewardObj, _idx, layer)

    local item = img.createUI9Sprite(img.ui.fight_hurts_bg_1)
    item:setPreferredSize(CCSizeMake(288, 76))
    local item_w = item:getContentSize().width
    local item_h = item:getContentSize().height

    local item1 = CCSprite:create()
    --item1:setContentSize(CCSize(288, 76))
    local item2 = img.createUISprite(img.ui.fight_hurts_bg_1)
    --item2:setPreferredSize(CCSizeMake(288, 76))
    item2:setScaleX(288/352)
    item2:setScaleY(76/62)
    item2:setAnchorPoint(0,0.5)
    item2:setPosition(item_w, item_h/2)
    --item1:addChild(item2)
    item2:setFlipX(true)
    item:addChild(item2)
    --drawBoundingbox(item, item1)
    
    if _idx%2 == 0 then
        item:setOpacity(70)
        item2:setOpacity(70)
    end
    
    local rank
    if _idx < 4 then
        rank = img.createUISprite(icon_rank[_idx])
    else
        rank = lbl.createFont2(18, "" .. _idx, lbl.whiteColor)
    end
    rank:setPosition(CCPoint(75, item_h/2))
    item:addChild(rank)

    ---- flag
    local flag = img.createPlayerHead(rewardObj.logo)
    flag:setScale(0.7)
    flag:setPosition(CCPoint(200, item_h/2))
    item:addChild(flag)

    -- name
    local lbl_name = lbl.createFontTTF(20, rewardObj.name, ccc3(255, 246, 223))
    lbl_name:setAnchorPoint(CCPoint(0, 0))
    lbl_name:setPosition(CCPoint(280, 40))
    item:addChild(lbl_name)


    -- power bar
    local bloodBar = img.createUISprite(img.ui.fight_hurts_bar_bg)
    bloodBar:setAnchorPoint(0, 0.5) 
    bloodBar:setPosition(280, 23)
    item:addChild(bloodBar)

    if _idx == 1 then
        perall = rewardObj.injury  
    end

    local progress0 = img.createUISprite(img.ui.fight_hurts_bar_fg_1)
    local bloodProgress = createProgressBar(progress0)
    bloodProgress:setPosition(bloodBar:getContentSize().width/2, bloodBar:getContentSize().height/2)
    bloodProgress:setPercentage(rewardObj.injury/perall*100)
    bloodBar:addChild(bloodProgress)


    local progressStr = string.format("%.0f", rewardObj.injury)
    local progressLabel = lbl.createFont2(16, progressStr, ccc3(255, 246, 223))
    progressLabel:setPosition(CCPoint(108, bloodBar:getContentSize().height/2+5))
    bloodBar:addChild(progressLabel)

    return item
end

function ui.create()
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
    
    -- title
    local titleLabel = lbl.createFont1(24, i18n.global.friendboss_injury_statistics.string, ccc3(0xff, 0xe3, 0x86))
    titleLabel:setPosition(BG_WIDTH/2, BG_HEIGHT-36)
    bg:addChild(titleLabel)

    local function createScroll()
        local scroll_params = {
            width = 600,
            height = 430,
        }
        local lineScroll = require "ui.lineScroll"
        return lineScroll.create(scroll_params)
    end

    local function showList(listObj)
        local scroll = createScroll()
        scroll:setAnchorPoint(CCPoint(0, 0))
        scroll:setPosition(CCPoint(1, 15))
        bg:addChild(scroll)
        bg.scroll = scroll
        --drawBoundingbox(bg, scroll)
        scroll.addSpace(4)
        for ii=1,#listObj do
            local tmp_item = createItem(listObj[ii], ii, layer)
            tmp_item.guildObj = listObj[ii]
            tmp_item.ax = 1
            tmp_item.px = 302
            scroll.addItem(tmp_item)
            if ii ~= #listObj then
                scroll.addSpace(space_height)
            end
        end
        scroll.setOffsetBegin()
    end
    
    local function compareassits(a, b)
        local injury1, injury2 = a.injury , b.injury
        if injury1 > injury2 then
            return true
        end
    end

    local function init()
        local gParams = {
            sid = player.sid,
        }
        addWaitNet()
        net:frd_boss_static(gParams, function(__data)
            delWaitNet()
            tbl2string(__data)
            if __data.assits then 
                local assistsdata = __data.assits
                table.sort(assistsdata, compareassits)
                
                showList(assistsdata)
            else
                local empty = require "ui.empty"
                local emptyBox = empty.create({text = i18n.global.empty_injury.string})
                emptyBox:setPosition(bg:getContentSize().width/2, bg:getContentSize().height/2)            
                bg:addChild(emptyBox)
            end
        end)
    end
    init()  

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
