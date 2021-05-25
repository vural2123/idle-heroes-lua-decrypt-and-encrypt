local ui = {}

require "common.func"
local view = require "common.view"
local i18n = require "res.i18n"
local lbl = require "res.lbl"
local img = require "res.img"
local audio = require "res.audio"
local json = require "res.json"
local cfgstore = require "config.store"
local cfghero = require "config.hero"
local cfgequip = require "config.equip"
local cfgtalen = require "config.talen"
local player = require "data.player"
local activityData = require "data.activity"
local net = require "net.netClient"
local tipsequip = require "ui.tips.equip"
local tipsitem = require "ui.tips.item"
local herotips = require "ui.tips.hero"
local heros = require "data.heros"
local bag = require "data.bag"
local cfglifechange = require "config.lifechange"

local ItemType = {
    Item = 1,
    Equip = 2,
}

local operData = {}
local fiveData = {}

local function isSameGroup(a, b)
    if a <= 4 then
        return b <= 4
    else
        return a == b
    end
end

local function initHeros()
    local tmpheros = {}

    for i, v in ipairs(heros) do
        if v.wake and v.wake >= 4 and not v.hskills then
            tmpheros[#tmpheros + 1] = {
                hid = v.hid,
                id = v.id,
                lv = v.lv,
                wake = v.wake,
                star = v.star,
                isUsed = false,
                flag = v.flag or 0,
            }
        end
    end

    operData.heros = tmpheros
end

local function initfiveHeros(group)
    local tmpheros = {}

    for i, v in ipairs(heros) do
        if cfglifechange[v.id] and cfghero[v.id].maxStar == 5 and isSameGroup(cfghero[v.id].group, group) and cfghero[cfglifechange[v.id].nId] and bit.band(cfghero[cfglifechange[v.id].nId].forgemask, bit.blshift(1, player.sid)) > 0 then
            tmpheros[#tmpheros + 1] = {
                hid = v.hid,
                id = v.id,
                lv = v.lv,
                wake = v.wake,
                star = v.star,
                isUsed = false,
                flag = v.flag or 0,
            }
        end
    end

    fiveData.heros = tmpheros
end

local function createSelectBoard(callfunc)
    local layer = CCLayerColor:create(ccc4(0, 0, 0, 210))

    local headData = {}

    initHeros()

    for i, v in ipairs(operData.heros) do
        headData[#headData + 1] = v
    end

    table.sort(headData, function (a, b)
        if a.id ~= b.id then
            return a.id < b.id
        else
            return a.lv < b.lv
        end
    end)

    local board = img.createUI9Sprite(img.ui.tips_bg)
    board:setPreferredSize(CCSize(520, 420))
    board:setScale(view.minScale)
    board:setPosition(view.midX, view.midY)
    layer:addChild(board)

    local showTitle = lbl.createFont1(20, i18n.global.heroforge_board_title.string, ccc3(0xff, 0xe3, 0x86))
    showTitle:setPosition(260, 386)
    board:addChild(showTitle)

    local showFgline = img.createUI9Sprite(img.ui.hero_enchant_info_fgline)
    showFgline:setPreferredSize(CCSize(453, 1))
    showFgline:setPosition(260, 354)
    board:addChild(showFgline)

    local tmpSelect = {}
    local showHeads = {}

    local function backEvent()
        layer:removeFromParentAndCleanup(true)
    end

    local btnCloseSp = img.createLoginSprite(img.login.button_close)
    local btnClose = SpineMenuItem:create(json.ui.button, btnCloseSp)
    btnClose:setPosition(495, 397)
    local menuClose = CCMenu:createWithItem(btnClose)
    menuClose:setPosition(0, 0)
    board:addChild(menuClose, 1000)
    btnClose:registerScriptTapHandler(function()
        audio.play(audio.button)
        backEvent()
    end)

    local height = 84 * math.ceil(#headData/5) 
    local scroll = CCScrollView:create()
    scroll:setDirection(kCCScrollViewDirectionVertical)
    scroll:setAnchorPoint(ccp(0, 0))
    scroll:setPosition(53, 113)
    scroll:setViewSize(CCSize(420, 225))
    scroll:setContentSize(CCSize(420, height+84))
    board:addChild(scroll)

    if #headData == 0 then
        local empty = require("ui.empty").create({ size = 16, text = i18n.global.empty_heromar.string, color = ccc3(255, 246, 223)})
        empty:setPosition(board:getContentSize().width/2, board:getContentSize().height/2)
        board:addChild(empty)
    end

    for i, v in ipairs(headData) do
        local x = math.ceil(i/5) 
        local y = i - (x - 1) * 5
        showHeads[i] = img.createHeroHead(v.id, v.lv, true, true, v.wake, nil, nil, nil, v.hskills)
        showHeads[i]:setScale(0.8)
        showHeads[i]:setAnchorPoint(ccp(0, 0))
        showHeads[i]:setPosition(2 + 84 * (y - 1), height - 84 * x - 5)
        scroll:getContainer():addChild(showHeads[i])
    
        if v.flag > 0 then
            local blackBoard = img.createUISprite(img.ui.hero_head_shade)
            blackBoard:setScale(88/94)
            blackBoard:setOpacity(120)
            blackBoard:setPosition(showHeads[i]:getContentSize().width/2, showHeads[i]:getContentSize().height/2)
            showHeads[i]:addChild(blackBoard, 101)
           
            local showLock = img.createUISprite(img.ui.devour_icon_lock)
            showLock:setPosition(showHeads[i]:getContentSize().width/2, showHeads[i]:getContentSize().height/2)
            showHeads[i]:addChild(showLock, 101)
        end
    end
    scroll:setContentOffset(ccp(0, 225 - height))

    local function onSelect(idx)
        if headData[idx].flag > 0 then
            local count = 0
            local text = ""
            if headData[idx].flag % 2 == 1 then
                text = text..i18n.global.toast_devour_arena.string
                count = count + 1
            end
            if math.floor((headData[idx].flag / 2)) % 2 == 1 then
                if count >= 1 then
                    text = text.."\n"
                end
                text = text..i18n.global.toast_devour_lock.string
                count = count + 1
            end
            if math.floor((headData[idx].flag / 4)) % 2 % 2 == 1 then
                if count >= 1 then
                    text = text.."\n"
                end
                text = text..i18n.global.toast_devour_3v3arena.string
                count = count + 1
            end
            if math.floor((headData[idx].flag / 8)) % 2 % 2 % 2 == 1 then
                if count >= 1 then
                    text = text.."\n"
                end
                text = text..i18n.global.toast_devour_frdarena.string
                count = count + 1
            end
            showToast(text)
            return
        end
        --callfunc(headData[idx])
        --layer:removeFromParentAndCleanup()
        headData[idx].isUsed = true
        tmpSelect[#tmpSelect + 1] = headData[idx]
        local blackBoard = img.createUISprite(img.ui.hero_head_shade)
        blackBoard:setScale(88/94)
        blackBoard:setOpacity(120)
        blackBoard:setPosition(showHeads[idx]:getContentSize().width/2, showHeads[idx]:getContentSize().height/2)
        showHeads[idx]:addChild(blackBoard, 0, 1)

        local selectIcon = img.createUISprite(img.ui.hook_btn_sel)
        selectIcon:setPosition(blackBoard:getContentSize().width/2, blackBoard:getContentSize().height/2)
        blackBoard:addChild(selectIcon)       
    end

    local function onUnselect(idx)
        for i, v in ipairs(tmpSelect) do
            if v.hid == headData[idx].hid then
                tmpSelect[i], tmpSelect[#tmpSelect] = tmpSelect[#tmpSelect], tmpSelect[i]
                tmpSelect[#tmpSelect] = nil
                break
            end
        end
        headData[idx].isUsed = false
        if showHeads[idx]:getChildByTag(1) then
            showHeads[idx]:removeChildByTag(1)
        end
    end

    local lasty
    local function onTouchBegin(x, y)
        lasty = y
        return true 
    end

    local function onTouchMoved(x, y)
        return true
    end

    local function onTouchEnd(x, y)
        local point = layer:convertToNodeSpace(ccp(x, y))
        local pointOnScroll = scroll:getContainer():convertToNodeSpace(ccp(x, y))

        if math.abs(y - lasty) > 10 then
            return
        end

        for i, v in ipairs(showHeads) do
            if v:boundingBox():containsPoint(pointOnScroll) then
                if not headData[i].isUsed and #tmpSelect < 1 then
                    onSelect(i) 
                elseif headData[i].isUsed == true then
                    onUnselect(i)
                end
            end
        end
        return true
    end

    local function onTouch(eventType, x, y)
        if eventType == "began" then
            return onTouchBegin(x, y)        
        elseif eventType == "moved" then
            return onTouchMoved(x, y)
        else
            return onTouchEnd(x, y)
        end
    end

    layer:registerScriptTouchHandler(onTouch)
    layer:setTouchEnabled(true)

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

    local btnSelectSp = img.createLogin9Sprite(img.login.button_9_small_gold)
    btnSelectSp:setPreferredSize(CCSize(150, 50))
    local labSelect = lbl.createFont1(16, i18n.global.heroforge_board_btn.string, ccc3(0x6a, 0x3d, 0x25))
    labSelect:setPosition(btnSelectSp:getContentSize().width/2, btnSelectSp:getContentSize().height/2)
    btnSelectSp:addChild(labSelect)

    local btnSelect = SpineMenuItem:create(json.ui.button, btnSelectSp)
    btnSelect:setPosition(260, 55)
    local menuSelect = CCMenu:createWithItem(btnSelect)
    menuSelect:setPosition(0, 0)
    board:addChild(menuSelect)

    btnSelect:registerScriptTapHandler(function()
        --condition.select = tmpSelect
        layer:removeFromParentAndCleanup(true)
        if tmpSelect and #tmpSelect ~= 0 then
            callfunc(tmpSelect[1])
        end
    end)

    board:setScale(0.5*view.minScale)
    local anim_arr = CCArray:create()
    anim_arr:addObject(CCScaleTo:create(0.15, view.minScale, view.minScale))
    anim_arr:addObject(CCDelayTime:create(0.15))
    anim_arr:addObject(CCCallFunc:create(function()
    
    end))
    board:runAction(CCSequence:create(anim_arr))

    return layer
end

local function createFiveSelectBoard(callfunc, fiveNum)
    local layer = CCLayerColor:create(ccc4(0, 0, 0, 210))

    local headData = {}

    --initHeros()

    for i, v in ipairs(fiveData.heros) do
        headData[#headData + 1] = v
    end

    table.sort(headData, function (a, b)
        if a.id ~= b.id then
            return a.id < b.id
        else
            return a.lv < b.lv
        end
    end)

    local board = img.createUI9Sprite(img.ui.tips_bg)
    board:setPreferredSize(CCSize(520, 420))
    board:setScale(view.minScale)
    board:setPosition(view.midX, view.midY)
    layer:addChild(board)

    local showTitle = lbl.createFont1(20, i18n.global.heroforge_board_title.string, ccc3(0xff, 0xe3, 0x86))
    showTitle:setPosition(260, 386)
    board:addChild(showTitle)

    local showFgline = img.createUI9Sprite(img.ui.hero_enchant_info_fgline)
    showFgline:setPreferredSize(CCSize(453, 1))
    showFgline:setPosition(260, 354)
    board:addChild(showFgline)

    local nowId = 0
    local tmpSelect = {}
    local showHeads = {}
    
    local function backEvent()
        layer:removeFromParentAndCleanup(true)
    end

    local btnCloseSp = img.createLoginSprite(img.login.button_close)
    local btnClose = SpineMenuItem:create(json.ui.button, btnCloseSp)
    btnClose:setPosition(495, 397)
    local menuClose = CCMenu:createWithItem(btnClose)
    menuClose:setPosition(0, 0)
    board:addChild(menuClose, 1000)
    btnClose:registerScriptTapHandler(function()
        backEvent()
        audio.play(audio.button)
    end)

    local height = 84 * math.ceil(#headData/5) 
    local scroll = CCScrollView:create()
    scroll:setDirection(kCCScrollViewDirectionVertical)
    scroll:setAnchorPoint(ccp(0, 0))
    scroll:setPosition(53, 113)
    scroll:setViewSize(CCSize(420, 225))
    scroll:setContentSize(CCSize(420, height))
    board:addChild(scroll)
    
    if #headData == 0 then
        local empty = require("ui.empty").create({ size = 16, text = i18n.global.empty_heromar.string, color = ccc3(255, 246, 223)})
        empty:setPosition(board:getContentSize().width/2, board:getContentSize().height/2)
        board:addChild(empty)
    end
    for i, v in ipairs(headData) do
        local x = math.ceil(i/5) 
        local y = i - (x - 1) * 5
        showHeads[i] = img.createHeroHead(v.id, v.lv, true, true, v.wake, nil, nil, nil, v.hskills)
        showHeads[i]:setScale(0.8)
        showHeads[i]:setAnchorPoint(ccp(0, 0))
        showHeads[i]:setPosition(2 + 84 * (y - 1), height - 84 * x - 5)
        scroll:getContainer():addChild(showHeads[i])
    
        if v.flag > 0 then
            local blackBoard = img.createUISprite(img.ui.hero_head_shade)
            blackBoard:setScale(88/94)
            blackBoard:setOpacity(120)
            blackBoard:setPosition(showHeads[i]:getContentSize().width/2, showHeads[i]:getContentSize().height/2)
            showHeads[i]:addChild(blackBoard)
           
            local showLock = img.createUISprite(img.ui.devour_icon_lock)
            showLock:setPosition(showHeads[i]:getContentSize().width/2, showHeads[i]:getContentSize().height/2)
            showHeads[i]:addChild(showLock)
        end
    end
    scroll:setContentOffset(ccp(0, 225 - height))

    local function onSelect(idx)
        if headData[idx].flag > 0 then
            local count = 0
            local text = ""
            if headData[idx].flag % 2 == 1 then
                text = text..i18n.global.toast_devour_arena.string
                count = count + 1
            end
            if math.floor((headData[idx].flag / 2)) % 2 == 1 then
                if count >= 1 then
                    text = text.."\n"
                end
                text = text..i18n.global.toast_devour_lock.string
                count = count + 1
            end
            if math.floor((headData[idx].flag / 4)) % 2 % 2 == 1 then
                if count >= 1 then
                    text = text.."\n"
                end
                text = text..i18n.global.toast_devour_3v3arena.string
                count = count + 1
            end
            if math.floor((headData[idx].flag / 8)) % 2 % 2 % 2 == 1 then
                if count >= 1 then
                    text = text.."\n"
                end
                text = text..i18n.global.toast_devour_frdarena.string
                count = count + 1
            end
            showToast(text)
            return
        end
        headData[idx].isUsed = true
        tmpSelect[#tmpSelect + 1] = headData[idx].hid
        local blackBoard = img.createUISprite(img.ui.hero_head_shade)
        blackBoard:setScale(88/94)
        blackBoard:setOpacity(120)
        blackBoard:setPosition(showHeads[idx]:getContentSize().width/2, showHeads[idx]:getContentSize().height/2)
        showHeads[idx]:addChild(blackBoard, 0, 1)

        local selectIcon = img.createUISprite(img.ui.hook_btn_sel)
        selectIcon:setPosition(blackBoard:getContentSize().width/2, blackBoard:getContentSize().height/2)
        blackBoard:addChild(selectIcon)       
    end
   
    local function onUnselect(idx)
        for i, v in ipairs(tmpSelect) do
            if v == headData[idx].hid then
                tmpSelect[i], tmpSelect[#tmpSelect] = tmpSelect[#tmpSelect], tmpSelect[i]
                tmpSelect[#tmpSelect] = nil
                break
            end
        end
        headData[idx].isUsed = false
        if showHeads[idx]:getChildByTag(1) then
            showHeads[idx]:removeChildByTag(1)
        end
    end
    
    --for i, v in ipairs(headData) do
    --    for j, k in ipairs(condition.select) do
    --        if k == v.hid then
    --            onSelect(i)
    --            curSelect[#curSelect + 1] = v.hid
    --        end
    --    end
    --end

    local lasty
    local function onTouchBegin(x, y)
        lasty = y
        return true 
    end

    local function onTouchMoved(x, y)
        return true
    end

    local function onTouchEnd(x, y)
        local point = layer:convertToNodeSpace(ccp(x, y))
        local pointOnScroll = scroll:getContainer():convertToNodeSpace(ccp(x, y))

        if math.abs(y - lasty) > 10 then
            return
        end

        for i, v in ipairs(showHeads) do
            if v:boundingBox():containsPoint(pointOnScroll) then
                if not headData[i].isUsed and #tmpSelect < fiveNum then
                    if nowId == 0 then
                        nowId = headData[i].id
                    end
                    if nowId ~= 0 and headData[i].id ~= nowId then
                        showToast(i18n.global.tenchange_toast_samehero.string)
                        return
                    end
                    onSelect(i) 
                elseif headData[i].isUsed == true then
                    onUnselect(i)
                    if #tmpSelect == 0 then
                        nowId = 0
                    end
                end
            end
        end
        return true
    end

    local function onTouch(eventType, x, y)
        if eventType == "began" then
            return onTouchBegin(x, y)        
        elseif eventType == "moved" then
            return onTouchMoved(x, y)
        else
            return onTouchEnd(x, y)
        end
    end

    layer:registerScriptTouchHandler(onTouch)
    layer:setTouchEnabled(true)

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

    local btnSelectSp = img.createLogin9Sprite(img.login.button_9_small_gold)
    btnSelectSp:setPreferredSize(CCSize(150, 50))
    local labSelect = lbl.createFont1(16, i18n.global.heroforge_board_btn.string, ccc3(0x6a, 0x3d, 0x25))
    labSelect:setPosition(btnSelectSp:getContentSize().width/2, btnSelectSp:getContentSize().height/2)
    btnSelectSp:addChild(labSelect)

    local btnSelect = SpineMenuItem:create(json.ui.button, btnSelectSp)
    btnSelect:setPosition(260, 55)
    local menuSelect = CCMenu:createWithItem(btnSelect)
    menuSelect:setPosition(0, 0)
    board:addChild(menuSelect)

    btnSelect:registerScriptTapHandler(function()
        --condition.select = tmpSelect
        layer:removeFromParentAndCleanup(true)
        if tmpSelect and #tmpSelect ~= 0 then
            callfunc(tmpSelect, nowId)
        end
    end)

    board:setScale(0.5*view.minScale)
    local anim_arr = CCArray:create()
    anim_arr:addObject(CCScaleTo:create(0.15, view.minScale, view.minScale))
    anim_arr:addObject(CCDelayTime:create(0.15))
    anim_arr:addObject(CCCallFunc:create(function()
    
    end))
    board:runAction(CCSequence:create(anim_arr))

    return layer

end

local function createBoardForRewards(hid, reward)
    local heroData = heros.find(hid)

    local params = {}
    params.title = i18n.global.reward_will_get.string
    params.btn_count = 0

    local dialog = require("ui.dialog").create(params) 

    local back = img.createLogin9Sprite(img.login.button_9_small_gold)
    back:setPreferredSize(CCSize(153, 50))
    local comfirlab = lbl.createFont1(18, i18n.global.summon_comfirm.string, lbl.buttonColor)
    comfirlab:setPosition(CCPoint(back:getContentSize().width/2,
                                    back:getContentSize().height/2))
    back:addChild(comfirlab)
    local backBtn = SpineMenuItem:create(json.ui.button, back)
    backBtn:setPosition(CCPoint(dialog.board:getContentSize().width/2, 80))
    local menu = CCMenu:createWithItem(backBtn)
    menu:setPosition(0, 0)
    dialog.board:addChild(menu)

    dialog.board.tipsTag = false
    local hero = img.createHeroHeadByHid(hid)
    heroBtn = SpineMenuItem:create(json.ui.button, hero)
    heroBtn:setScale(0.85)
    heroBtn:setPosition(dialog.board:getContentSize().width/2, 185)

    local iconMenu = CCMenu:createWithItem(heroBtn)
    iconMenu:setPosition(0, 0)
    dialog.board:addChild(iconMenu)
    heroBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        local heroInfo = clone(heroData.attr())
        heroInfo.lv = heroData.lv
        heroInfo.star = heroData.star
        heroInfo.id = heroData.id
        heroInfo.wake = heroData.wake
        local tips = herotips.create(heroInfo)
        dialog:addChild(tips, 1001)
    end)
    
    backBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        dialog:getParent():addChild((require"ui.hook.drops").create(reward, i18n.global.ui_decompose_preview.string), 1000)
        dialog:removeFromParentAndCleanup()
    end)
    dialog.setClickBlankHandler(function()
        dialog:getParent():addChild((require"ui.hook.drops").create(reward, i18n.global.ui_decompose_preview.string), 1000)
        dialog:removeFromParentAndCleanup()
    end)
    return dialog
end

function ui.create()
    local vp_ids = { activityData.IDS.TENCHANGE.ID }

    local layer = CCLayer:create()

    local vps = {}
    for _, v in ipairs(vp_ids) do
        local tmp_status = activityData.getStatusById(v)
        vps[#vps+1] = tmp_status
    end

    local board = CCSprite:create()
    board:setContentSize(CCSizeMake(570, 438))
    board:setScale(view.minScale)
    board:setAnchorPoint(CCPoint(0, 0))
    board:setPosition(scalep(362, 60))
    layer:addChild(board)
    --drawBoundingbox(layer, board)
    local board_w = board:getContentSize().width
    local board_h = board:getContentSize().height

    img.unload(img.packedOthers.ui_activity_change)
    img.unload(img.packedOthers.ui_activity_change_cn)
    if i18n.getCurrentLanguage() == kLanguageChinese then
        img.load(img.packedOthers.ui_activity_change_cn)
    else
        img.load(img.packedOthers.ui_activity_change)
    end
    local banner
    if i18n.getCurrentLanguage() == kLanguageKorean then
        banner = img.createUISprite("activity_change_kr.png")
    elseif i18n.getCurrentLanguage() == kLanguageChineseTW then
        banner = img.createUISprite("activity_change_tw.png")
    elseif i18n.getCurrentLanguage() == kLanguageJapanese then
        banner = img.createUISprite("activity_change_jp.png")
    elseif i18n.getCurrentLanguage() == kLanguageRussian then
        banner = img.createUISprite("activity_change_ru.png")
    elseif i18n.getCurrentLanguage() == kLanguagePortuguese then
        banner = img.createUISprite("activity_change_pt.png")
    elseif i18n.getCurrentLanguage() == kLanguageSpanish then
        banner = img.createUISprite("activity_change_sp.png")
    else
        banner = img.createUISprite(img.ui.activity_change)
    end
    banner:setAnchorPoint(CCPoint(0.5, 1))
    banner:setPosition(CCPoint(board_w/2-10, board_h-12))
    board:addChild(banner)

    local btnInfoSprite = img.createUISprite(img.ui.btn_help)
    local btnInfo = SpineMenuItem:create(json.ui.button, btnInfoSprite)
    btnInfo:setPosition(520, board_h-42)
    local menuInfo = CCMenu:createWithItem(btnInfo)
    menuInfo:setPosition(0, 0)
    board:addChild(menuInfo, 100)
    btnInfo:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer:getParent():getParent():addChild(require("ui.help").create(i18n.global.help_tenchange.string, i18n.global.help_title.string), 1000)
    end)

    --local lbl_cd_des = lbl.createFont2(14, i18n.global.activity_to_end.string)
    --lbl_cd_des:setAnchorPoint(CCPoint(1, 0.5))
    --lbl_cd_des:setPosition(CCPoint(150, 25))
    --banner:addChild(lbl_cd_des)
    --local lbl_cd = lbl.createFont2(14, "", ccc3(0xa5, 0xfd, 0x47))
    --lbl_cd:setAnchorPoint(CCPoint(1, 0.5))
    --lbl_cd:setPosition(CCPoint(lbl_cd_des:boundingBox():getMinX()-6, 25))
    --banner:addChild(lbl_cd)

    local temp_item = img.createUI9Sprite(img.ui.bottom_border_2)
    temp_item:setPreferredSize(CCSizeMake(548, 265))
    temp_item:setAnchorPoint(CCPoint(0.5, 1))
    temp_item:setPosition(CCPoint(board_w/2-10, board_h-166))
    board:addChild(temp_item)

    local tenflag = false
    local fiveflag = false
    local hostHid = 0
    local fiveGroup = 0
    local tenId = 0
    local fiveId = 0
    local fiveHids = {}
    local tenheroData = nil
    
    -- lbl
    local changetips = lbl.createMixFont1(16, i18n.global.tenchange_tips.string, ccc3(0x73, 0x3b, 0x05))
    changetips:setPosition(548/2, 238)
    temp_item:addChild(changetips)
    local changeIcon = img.createUISprite(img.ui.activity_ten_change)
    changeIcon:setPosition(198, 165)
    temp_item:addChild(changeIcon)
    local plusIcon = img.createUISprite(img.ui.activity_ten_plus)
    plusIcon:setPosition(378, 165)
    temp_item:addChild(plusIcon)

    -- itemicon
    local spStoneBg = img.createUISprite(img.ui.grid)
    local spStone = img.createItemIcon(73)
    spStone:setPosition(spStoneBg:getContentSize().width/2, spStoneBg:getContentSize().height/2)
    spStoneBg:addChild(spStone)
    --spStoneBg:setPosition(458, 165)
    local btnSpStone = CCMenuItemSprite:create(spStoneBg, nil)
    btnSpStone:setPosition(458, 165)
    local menubtnSpStone = CCMenu:createWithItem(btnSpStone)
    menubtnSpStone:setPosition(0, 0)
    temp_item:addChild(menubtnSpStone)

    btnSpStone:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer:getParent():getParent():addChild(tipsitem.createForShow({id=73}), 1000)
    end)
    --temp_item:addChild(spStoneBg)
    
    local stonenum = 0
    if bag.items.find(73) then
        stonenum = bag.items.find(73).num
    end

    local showStonenum = lbl.createFont2(16, string.format("%d/5", stonenum), ccc3(0xff, 0x74, 0x74))
    showStonenum:setPosition(458, 105)
    temp_item:addChild(showStonenum)

    local fiveNum = 5
    if stonenum < 5 then
        showStonenum:setColor(ccc3(0xff, 0x74, 0x74))
    else
        showStonenum:setColor(ccc3(0xff, 0xf7, 0xe5))
    end

    local showTennum = lbl.createFont2(16, "0/1", ccc3(0xff, 0x74, 0x74))
    showTennum:setPosition(98, 105)
    temp_item:addChild(showTennum)
    local showFivenum = lbl.createFont2(16, "0/" .. fiveNum, ccc3(0xff, 0x74, 0x74))
    showFivenum:setPosition(295, 105)
    temp_item:addChild(showFivenum)
    showFivenum:setVisible(false)
    -- ten star
    local tenSp = nil
    local btnTenhero = nil
    local menuTenHero = nil
    local createBtnten = nil
    -- five
    local fiveSp = nil
    local btnFivehero = nil
    local menuFiveHero = nil
    local createBtnfive = nil

    local function callfuncTen(herodata)
        if tenflag == false then
            tenflag = true
            clearShader(btnTenhero, true)
            showTennum:setString("1/1")
            showTennum:setColor(ccc3(0xff, 0xf7, 0xe5))
        end
        
        tenheroData = herodata
        fiveGroup = cfghero[herodata.id].group
        tenId = herodata.id
        initfiveHeros(fiveGroup)
        hostHid = herodata.hid

        menuTenHero:removeFromParentAndCleanup()
        menuTenHero = nil
        createBtnten(tenId, tenheroData.wake)

        fiveId = 0
        fiveHids = {}
        if tenheroData.wake > 4 then
            fiveNum = cfgtalen[tenheroData.wake-4].lifeChangeCount
        else
            fiveNum = 5
        end
        showFivenum:setVisible(true)
        showFivenum:setString(string.format("%d/" .. fiveNum, 0))
        menuFiveHero:removeFromParentAndCleanup()
        menuFiveHero = nil
        createBtnfive(9999, 0)

        menuFiveHero:removeFromParentAndCleanup()
        menuFiveHero = nil
        createBtnfive(5000+fiveGroup*100+99, 0)
    end

    createBtnten = function(id, tenwake)
        if tenwake == 4 then
            tenSp = img.createHeroHead(id, nil, true, false, tenwake, false) 
        else
            tenSp = img.createHeroHead(id, nil, true, true, tenwake, false) 
        end
        local bgSize = tenSp:getContentSize()
        if tenwake == 4 then
            local star = img.createUISprite(img.ui.hero_star_ten)
            star:setScale(0.75)
            star:setPosition(bgSize.width/2, 14)
            tenSp:addChild(star)
        end

        if id == 9999 then
            setShader(tenSp, SHADER_GRAY, true)
        end

        local icon = img.createUISprite(img.ui.hero_equip_add)
        icon:setPosition(tenSp:boundingBox():getMaxX()+23, tenSp:boundingBox():getMaxY() + 23)
        tenSp:addChild(icon)
        icon:runAction(CCRepeatForever:create(CCSequence:createWithTwoActions(
            CCFadeTo:create(0.5, 255 * 0.3), CCFadeTo:create(0.5, 255))))

        btnTenhero = CCMenuItemSprite:create(tenSp, nil)
        --btnTenhero:setScale(0.67)
        btnTenhero:setPosition(98, 165)
        menuTenHero = CCMenu:createWithItem(btnTenhero)
        menuTenHero:setPosition(0, 0)
        temp_item:addChild(menuTenHero)

        btnTenhero:registerScriptTapHandler(function()
            audio.play(audio.button)
            layer:getParent():getParent():addChild(createSelectBoard(callfuncTen), 2000)
        end)
    end
    createBtnten(9999, 4)


    local function callfuncFive(hids, id)
        if fiveflag == false then
            fiveflag = true
            clearShader(btnFivehero, true)
        end
        fiveId = id
        fiveHids = hids
        showFivenum:setString(string.format("%d/" .. fiveNum, #hids))
        if #hids < fiveNum then
            showFivenum:setColor(ccc3(0xff, 0x74, 0x74))
        else
            showFivenum:setColor(ccc3(0xff, 0xf7, 0xe5))
        end

        --if hids or #hids == 0 then
        menuFiveHero:removeFromParentAndCleanup()
        menuFiveHero = nil
        createBtnfive(id, #hids)
        --end
    end

    createBtnfive = function(id, num)
        fiveSp = img.createHeroHead(id, nil, true, true) 
        local fivebgSize = fiveSp:getContentSize()
        if id%100 == 99 or (num and num < fiveNum) then
            setShader(fiveSp, SHADER_GRAY, true)
        end
        if id ~= 5999 then
            local icon = img.createUISprite(img.ui.hero_equip_add)
            icon:setPosition(fiveSp:boundingBox():getMaxX()+23, fiveSp:boundingBox():getMaxY() + 23)
            fiveSp:addChild(icon)
            icon:runAction(CCRepeatForever:create(CCSequence:createWithTwoActions(
                CCFadeTo:create(0.5, 255 * 0.3), CCFadeTo:create(0.5, 255))))
        end
        btnFivehero = CCMenuItemSprite:create(fiveSp, nil)
        btnFivehero:setScale(0.9)
        btnFivehero:setPosition(295, 165)
        menuFiveHero = CCMenu:createWithItem(btnFivehero)
        menuFiveHero:setPosition(0, 0)
        temp_item:addChild(menuFiveHero)


        btnFivehero:registerScriptTapHandler(function()
            audio.play(audio.button)
            if fiveGroup == 0 then
                showToast(i18n.global.tenchange_toast_first.string)
                return
            end
            initfiveHeros(fiveGroup)
            layer:getParent():getParent():addChild(createFiveSelectBoard(callfuncFive, fiveNum), 2000)
        end)
    end
    createBtnfive(5999)

    local change = img.createLogin9Sprite(img.login.button_9_small_gold)
    change:setPreferredSize(CCSize(160, 52))
    local changelab = lbl.createFont1(18, i18n.global.space_summon_replace.string, lbl.buttonColor)
    changelab:setPosition(CCPoint(change:getContentSize().width/2,
                                    change:getContentSize().height/2))
    change:addChild(changelab)
    local changeBtn = SpineMenuItem:create(json.ui.button, change)
    changeBtn:setPosition(CCPoint(548/2, 55))
    local changeMenu = CCMenu:createWithItem(changeBtn)
    changeMenu:setPosition(0, 0)
    temp_item:addChild(changeMenu)

    json.load(json.ui.zhihuan_icon)
    local anim2Zhihuan = DHSkeletonAnimation:createWithKey(json.ui.zhihuan_icon)
    anim2Zhihuan:scheduleUpdateLua()
    anim2Zhihuan:playAnimation("zhihuan_image")
    anim2Zhihuan:setPosition(198, 165)
    temp_item:addChild(anim2Zhihuan, 1001)
    anim2Zhihuan:setVisible(false)

    local function createSurechange() 
        local params = {}
        params.title = "" 
        params.btn_count = 0
        local dialoglayer = require("ui.dialog").create(params) 

        local arrowSprite = img.createUISprite(img.ui.arrow)
        arrowSprite:setPosition(472/2, 180)
        dialoglayer.board:addChild(arrowSprite)

        local suretenSp = img.createHeroHead(tenheroData.id, tenheroData.lv, true, true, tenheroData.wake, false, nil, nil, tenheroData.hskills) 
        local btnSureTenhero = CCMenuItemSprite:create(suretenSp, nil)
        btnSureTenhero:setPosition(472/2-100, 180)
        local menuSureTenHero = CCMenu:createWithItem(btnSureTenhero)
        menuSureTenHero:setPosition(0, 0)
        dialoglayer.board:addChild(menuSureTenHero)

        btnSureTenhero:registerScriptTapHandler(function()
            --audio.play(audio.button)
            --local sureheroData = heros.find(tenheroData.hid)
            --local heroInfo = clone(sureheroData.attr())
            --heroInfo.lv = sureheroData.lv
            --heroInfo.star = sureheroData.star
            --heroInfo.id = sureheroData.id
            --heroInfo.wake = sureheroData.wake
            --local tips = herotips.create(heroInfo)
            --dialoglayer:addChild(tips, 1001)
        end)

        local surefiveSp = img.createHeroHead(cfglifechange[fiveId].nId, tenheroData.lv, true, true, tenheroData.wake, false) 
        local btnSureFivehero = CCMenuItemSprite:create(surefiveSp, nil)
        btnSureFivehero:setPosition(472/2+100, 180)
        local menuSureFiveHero = CCMenu:createWithItem(btnSureFivehero)
        menuSureFiveHero:setPosition(0, 0)
        dialoglayer.board:addChild(menuSureFiveHero)

        btnSureFivehero:registerScriptTapHandler(function()
            --audio.play(audio.button)
            --local tips = herotips.create(cfglifechange[fiveId].nId)
            --dialoglayer:addChild(tips, 1001)
        end)

        local btnYesSprite = img.createLogin9Sprite(img.login.button_9_small_gold)
        btnYesSprite:setPreferredSize(CCSize(153, 50))
        local btnYes = SpineMenuItem:create(json.ui.button, btnYesSprite)
        btnYes:setPosition(474/2+95, 80)
        local labYes = lbl.createFont1(18, i18n.global.dialog_button_confirm.string, ccc3(0x73, 0x3b, 0x05))
        labYes:setPosition(btnYes:getContentSize().width/2, btnYes:getContentSize().height/2)
        btnYesSprite:addChild(labYes)
        local menuYes = CCMenu:create()
        menuYes:setPosition(0, 0)
        menuYes:addChild(btnYes)
        dialoglayer.board:addChild(menuYes)

        local btnNoSprite = img.createLogin9Sprite(img.login.button_9_small_orange)
        btnNoSprite:setPreferredSize(CCSize(153, 50))
        local btnNo = SpineMenuItem:create(json.ui.button, btnNoSprite)
        btnNo:setPosition(474/2-95, 80)
        local labNo = lbl.createFont1(18, i18n.global.dialog_button_cancel.string, ccc3(0x73, 0x3b, 0x05))
        labNo:setPosition(btnNo:getContentSize().width/2, btnNo:getContentSize().height/2)
        btnNoSprite:addChild(labNo)
        local menuNo = CCMenu:create()
        menuNo:setPosition(0, 0)
        menuNo:addChild(btnNo)
        dialoglayer.board:addChild(menuNo)

        
        btnYes:registerScriptTapHandler(function()
            audio.play(audio.button)
            local params = {
                sid = player.sid,
                hostHid = hostHid,
                hids = fiveHids
            }
            addWaitNet()
            net:hero_change(params, function(__data)
                delWaitNet()
                tbl2string(__data)
                if __data.status < 0 then
                    showToast("status:" .. __data.status)
                    return
                end
                local animZhihuan = DHSkeletonAnimation:createWithKey(json.ui.zhihuan_icon)
                animZhihuan:scheduleUpdateLua()
                animZhihuan:playAnimation("zhihuan")
                animZhihuan:setPosition(tenSp:boundingBox():getMidX(), tenSp:boundingBox():getMidY())
                tenSp:addChild(animZhihuan, 1001)

                local animZhihuanright = DHSkeletonAnimation:createWithKey(json.ui.zhihuan_icon)
                animZhihuanright:scheduleUpdateLua()
                animZhihuanright:playAnimation("zhihuan_right")
                animZhihuanright:setPosition(fiveSp:boundingBox():getMidX(), fiveSp:boundingBox():getMidY())
                fiveSp:addChild(animZhihuanright, 1001)

                local animZhihuanright2 = DHSkeletonAnimation:createWithKey(json.ui.zhihuan_icon)
                animZhihuanright2:scheduleUpdateLua()
                animZhihuanright2:playAnimation("zhihuan_right")
                animZhihuanright2:setPosition(spStoneBg:getContentSize().width/2, spStoneBg:getContentSize().height/2)
                spStoneBg:addChild(animZhihuanright2, 1001)

                changeIcon:setVisible(false)
                anim2Zhihuan:setVisible(true)
                anim2Zhihuan:playAnimation("zhihuan_image")

                local ban = CCLayer:create()
                ban:setTouchEnabled(true)
                ban:setTouchSwallowEnabled(true)
                layer:addChild(ban, 2000)
                bag.items.sub({id = 73, num = 5})

                local exp, evolve, rune = heros.decomposeFortenchange(fiveHids)
                bag.items.add({ id = ITEM_ID_HERO_EXP, num = exp})
                bag.items.add({ id = ITEM_ID_EVOLVE_EXP, num = evolve})
                bag.items.add({ id = ITEM_ID_RUNE_COIN, num = rune})
                local reward = {items = {}, equips = {}}
                if exp > 0 then
                    table.insert(reward.items,{ id = ITEM_ID_HERO_EXP, num = exp})
                end
                if evolve > 0 then
                    table.insert(reward.items,{ id = ITEM_ID_EVOLVE_EXP, num = evolve})
                end
                if rune > 0 then
                    table.insert(reward.items,{ id = ITEM_ID_RUNE_COIN, num = rune})
                end

                for i, v in ipairs(fiveHids) do
                    --if i == 1 then
                    --    heros.del(v, true)
                    --else
                        local heroData = heros.find(v)
                        if heroData then
                            for j, k in ipairs(heroData.equips) do
                                if cfgequip[k].pos == EQUIP_POS_JADE then
                                    bag.items.addAll(cfgequip[k].jadeUpgAll)
                                    if cfgequip[k].jadeUpgAll[1].num > 0 then
                                        table.insert(reward.items,{ id = cfgequip[k].jadeUpgAll[1].id, num = cfgequip[k].jadeUpgAll[1].num})
                                    end
                                    if cfgequip[k].jadeUpgAll[2].num > 0 then
                                        table.insert(reward.items,{ id = cfgequip[k].jadeUpgAll[2].id, num = cfgequip[k].jadeUpgAll[2].num})
                                    end
                                else
                                    table.insert(reward.equips,{ id = k, num = 1})
                                end
                            end
                        end
                        heros.del(v)
                    --end
                end

                local cTenheroData = heros.find(tenheroData.hid)
                for _,v in ipairs(cTenheroData.equips) do
                    if cfgequip[v].pos == EQUIP_POS_SKIN then
                        bag.equips.returnbag({ id = getHeroSkin(cTenheroData.hid), num = 1})
                        table.remove(cTenheroData.equips, _)
                    end
                end
                heros.tenchange(tenheroData, fiveId)
                dialoglayer:removeFromParentAndCleanup(true)
                schedule(board, 2, function()
                    ban:removeFromParent()

                    layer:getParent():getParent():addChild(createBoardForRewards(hostHid, reward), 1002)

                    tenflag = false
                    fiveflag = false
                    hostHid = 0
                    fiveGroup = 0
                    fiveId = 0
                    fiveHids = {}
                    --setShader(tenSp, SHADER_GRAY, true)
                    --setShader(fiveSp, SHADER_GRAY, true)
                    menuTenHero:removeFromParentAndCleanup()
                    menuTenHero = nil
                    createBtnten(9999, 4)
                    menuFiveHero:removeFromParentAndCleanup()
                    menuFiveHero = nil
                    createBtnfive(5999)
                    showTennum:setString("0/1")
                    showTennum:setColor(ccc3(0xff, 0xf7, 0xe5))
                    showFivenum:setString("0/5")
                    showFivenum:setColor(ccc3(0xff, 0xf7, 0xe5))
                    stonenum = stonenum - 5
                    if stonenum < 5 then
                        showStonenum:setColor(ccc3(0xff, 0x74, 0x74))
                    end
                    showStonenum:setString(string.format("%d/5", stonenum))
                end)
            end)
        end)

        btnNo:registerScriptTapHandler(function()
            dialoglayer:removeFromParentAndCleanup(true)
            audio.play(audio.button)
        end)

        local function backEvent()
            dialoglayer:removeFromParentAndCleanup(true)
        end

        -- btn_close
        local btn_close0 = img.createUISprite(img.ui.close)
        local btn_close = SpineMenuItem:create(json.ui.button, btn_close0)
        --btn_close:setPosition(CCPoint(board_w-32, board_h-74))
        btn_close:setPosition(474-30, 327-28)
        local btn_close_menu = CCMenu:createWithItem(btn_close)
        btn_close_menu:setPosition(CCPoint(0, 0))
        dialoglayer.board:addChild(btn_close_menu, 100)
        btn_close:registerScriptTapHandler(function()
            audio.play(audio.button)
            backEvent()
        end)

        function dialoglayer.onAndroidBack()
            backEvent()
        end

        addBackEvent(dialoglayer)
        
        local function onEnter()
            dialoglayer.notifyParentLock()
        end

        local function onExit()
            dialoglayer.notifyParentUnlock()
        end

        dialoglayer:registerScriptHandler(function(event) 
            if event == "enter" then 
                onEnter()
            elseif event == "exit" then
                onExit()
            end
        end)
        return dialoglayer
    end

    changeBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        
        if fiveHids and #fiveHids < fiveNum then
            showToast(i18n.global.hero_wake_no_hero.string)
            return
        end

        local stonenum = 0
        if bag.items.find(73) then
            stonenum = bag.items.find(73).num
        end
        if stonenum < 5 then
            showToast(i18n.global.tenchange_toast_noitem.string)
            return 
        end
        if tenheroData.id == cfglifechange[fiveId].nId then
            showToast(i18n.global.tenchange_toast_nosamehero.string)
            return
        end

        local dialog = createSurechange()
        layer:getParent():getParent():addChild(dialog, 300)
    end)

    --local last_update = os.time() - 1
    --local function onUpdate(ticks)
    --    if os.time() - last_update < 1 then return end
    --    last_update = os.time()
    --    local remain_cd = vps[1].cd - (os.time() - activityData.pull_time)
    --    if remain_cd >= 0 then
    --        local time_str = time2string(remain_cd)
    --        lbl_cd:setString(time_str)
    --    else
    --    end
    
    --end
    --layer:scheduleUpdateWithPriorityLua(onUpdate, 0)

    --require("ui.activity.ban").addBan(layer, scroll)
    --layer:setTouchSwallowEnabled(false)
    --layer:setTouchEnabled(true)

    return layer
end

return ui
