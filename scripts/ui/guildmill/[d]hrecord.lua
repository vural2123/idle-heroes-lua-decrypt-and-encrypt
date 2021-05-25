
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
local BG_WIDTH   = 620
local BG_HEIGHT  = 416

local perall = 0

local icon_rank = {
    [1] = img.ui.arena_rank_1,
    [2] = img.ui.arena_rank_2,
    [3] = img.ui.arena_rank_3,
}

local function createItem(rewardObj, _idx, layer)
    local item1 = CCSprite:create()
    item1:setContentSize(CCSize(288, 32))

    -- name
    local lbl_name = lbl.createFontTTF(18, rewardObj.name, ccc3(255, 246, 223))
    lbl_name:setPosition(CCPoint(295-190, 15))
    item1:addChild(lbl_name)

    -- coins
    local lbl_ser = lbl.createFontTTF(18, string.format("%d", rewardObj.sid), ccc3(0xff, 0xee, 0x5b))
    lbl_ser:setPosition(CCPoint(295, 15))
    item1:addChild(lbl_ser)

    -- win
    local flag = nil
    if rewardObj.win == true then
        flag = img.createUISprite(img.ui.guild_mill_win)
    else
        flag = img.createUISprite(img.ui.guild_mill_lose)
    end
    flag:setPosition(CCPoint(295+180, 15))
    item1:addChild(flag)

    return item1
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
    local titleLabel = lbl.createFont1(24, i18n.global.gmill_hrecord_title.string, ccc3(0xff, 0xe3, 0x86))
    titleLabel:setPosition(BG_WIDTH/2, BG_HEIGHT-36)
    bg:addChild(titleLabel)

    -- line
    local line = img.createUISprite(img.ui.help_line)
    line:setScaleX(590/line:getContentSize().width)
    --line:setPreferredSize(CCSize(528, 2))
    line:setPosition(CCPoint(BG_WIDTH/2, BG_HEIGHT-62))
    bg:addChild(line)

    -- vtitle
    local infobg = img.createUISprite(img.ui.guild_vtitle_bg)
    infobg:setPosition(BG_WIDTH/2, BG_HEIGHT-82)
    bg:addChild(infobg)

    local namelab = lbl.createFont1(18, i18n.global.guild_create_guild_name.string, ccc3(0xeb, 0xaa, 0x5e))
    namelab:setPosition(CCPoint(108, infobg:getContentSize().height/2))
    infobg:addChild(namelab)

    local serverlab = lbl.createFont1(18, i18n.global.setting_title_servers.string, ccc3(0xeb, 0xaa, 0x5e))
    serverlab:setPosition(CCPoint(295, infobg:getContentSize().height/2))
    infobg:addChild(serverlab)

    local timelab = lbl.createFont1(18, i18n.global.gmill_hrecord_result.string, ccc3(0xeb, 0xaa, 0x5e))
    timelab:setPosition(CCPoint(472, infobg:getContentSize().height/2))
    infobg:addChild(timelab)

    local function createScroll()
        local scroll_params = {
            width = 526,
            height = 306,
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
    
    --local function compareassits(a, b)
    --    local injury1, injury2 = a.injury , b.injury
    --    if injury1 > injury2 then
    --        return true
    --    end
    --end

    local function init()
        local gParams = {
            sid = player.sid,
        }
        addWaitNet()
        net:gmill_olog(gParams, function(__data)
            delWaitNet()
            tbl2string(__data)
            if __data.users then 
                local harrydata = __data.users
                --table.sort(assistsdata, compareassits)
                
                showList(harrydata)
            else
                local empty = require "ui.empty"
                local emptyBox = empty.create({text = i18n.global.gmill_hrecord_empty.string, color = ccc3(255, 246, 223)})
                emptyBox:setPosition(bg:getContentSize().width/2, bg:getContentSize().height/2-20)            
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
