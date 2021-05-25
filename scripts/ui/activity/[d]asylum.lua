local ui = {}

require "common.func"
local view = require "common.view"
local i18n = require "res.i18n"
local lbl = require "res.lbl"
local img = require "res.img"
local audio = require "res.audio"
local json = require "res.json"
local cfghero = require "config.hero"
local cfgequip = require "config.equip"
local player = require "data.player"
local activityData = require "data.activity"
local NetClient = require "net.netClient"
local netClient = NetClient:getInstance()
local tipsequip = require "ui.tips.equip"
local tipsitem = require "ui.tips.item"
local bag = require "data.bag"
local heros = require "data.heros"

local IDS = activityData.IDS
local ItemType = {
    Item = 1,
    Equip = 2,
}

local vp_ids = {
    IDS.ASYLUM_1.ID,
    IDS.ASYLUM_2.ID,
    IDS.ASYLUM_3.ID,
    --IDS.ASYLUM_4.ID,
    --IDS.ASYLUM_5.ID,
    --IDS.ASYLUM_6.ID,
}

local operData = {}

local function initHeros()
    local tmpheros = {}

    for i, v in ipairs(heros) do
        tmpheros[#tmpheros + 1] = {
            hid = v.hid,
            id = v.id,
            lv = v.lv,
            isUsed = false,
            flag = v.flag or 0,
        }
    end

    operData.heros = tmpheros
end

local function createSelectBoard(condition, callfunc)
    local layer = CCLayerColor:create(ccc4(0, 0, 0, 210))

    local headData = {}
    
    for i, v in ipairs(operData.heros) do
        if v.isUsed == false then
            if cfghero[v.id].job == condition.job and cfghero[v.id].maxStar == condition.qlt 
                and cfghero[v.id].group == condition.group then
                headData[#headData + 1] = v
            elseif cfghero[v.id].group == condition.group and cfghero[v.id].maxStar == condition.qlt 
                and condition.job == 0 then
                headData[#headData + 1] = v
            elseif cfghero[v.id].job == condition.job and cfghero[v.id].maxStar == condition.qlt
                and condition.group == 0 then
                headData[#headData + 1] = v
            elseif cfghero[v.id].job == condition.job and cfghero[v.id].group == condition.group
                and condition.qlt == 0 then
                headData[#headData + 1] = v
            end
        else
            for j, k in ipairs(condition.select) do
                if k == v.hid then
                    headData[#headData + 1] = v
                    break
                end
            end
        end
    end

    local board = img.createUI9Sprite(img.ui.tips_bg)
    board:setPreferredSize(CCSize(520, 420))
    board:setScale(view.minScale)
    board:setPosition(scalep(480, 288))
    layer:addChild(board)
 
    local showTitle = lbl.createFont1(20, i18n.global.heroforge_board_title.string, ccc3(0xff, 0xe3, 0x86))
    showTitle:setPosition(260, 386)
    board:addChild(showTitle)

    local showFgline = img.createUI9Sprite(img.ui.hero_enchant_info_fgline)
    showFgline:setPreferredSize(CCSize(453, 1))
    showFgline:setPosition(260, 354)
    board:addChild(showFgline)

    local tmpSelect = {} --未确定，临时选中英雄hid
    local showHeads = {}
    local curSelect = {} --已确定，选中英雄hid
    local function backEvent()
        for i, v in ipairs(headData) do
            if #tmpSelect == 0 and #curSelect ~= 0 then 
                for z=i,#curSelect do
                    if v.hid == curSelect[z] then
                        v.isUsed = true 
                        break
                    end
                end
            end
            for j=1, #tmpSelect do
                if v.hid == tmpSelect[j]  then 
                    local curflag = false
                    for z=i,#curSelect do
                        if v.hid == curSelect[z] then
                            curflag = true
                            break
                        end
                    end
                    if curflag == false then
                        v.isUsed = false
                        break
                    end
                end
            end
        end
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
        showHeads[i] = img.createHeroHead(v.id, v.lv, true, true)
        showHeads[i]:setScale(0.8)
        showHeads[i]:setAnchorPoint(ccp(0, 0))
        showHeads[i]:setPosition(2 + 84 * (y - 1), height - 84 * x - 5)
        scroll:getContainer():addChild(showHeads[i])
    
        local showJob = img.createUISprite(img.ui["job_" .. cfghero[v.id].job])
        showJob:setPosition(17, 52)
        showHeads[i]:addChild(showJob, 3)

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

    for i, v in ipairs(headData) do
        for j, k in ipairs(condition.select) do
            if k == v.hid then
                onSelect(i)
                curSelect[#curSelect + 1] = v.hid
            end
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
                if not headData[i].isUsed and #tmpSelect < condition.num then
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
        condition.select = tmpSelect
        layer:removeFromParentAndCleanup(true)
        callfunc()
    end)

    board:setScale(0.5)
    local anim_arr = CCArray:create()
    anim_arr:addObject(CCScaleTo:create(0.15, 1*view.minScale, 1*view.minScale))
    anim_arr:addObject(CCDelayTime:create(0.15))
    anim_arr:addObject(CCCallFunc:create(function()
    
    end))
    board:runAction(CCSequence:create(anim_arr))

    return layer
end

function ui.createOplayer(pos, vps, getgrayfunc)
    local layer = CCLayer:create()

    --dark bg
    local darkbg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    darkbg:setScale(2)
    layer:addChild(darkbg)

    local showReward = {}
    local showHero = {}
    
    local showPowerBg = CCSprite:create()
    showPowerBg:setContentSize(CCSize(960, 576))
    showPowerBg:setScale(view.minScale)
    showPowerBg:setPosition(scalep(480, 576/2))
    layer:addChild(showPowerBg)

    ---- anim
    showPowerBg:setScale(0.5*view.minScale)
    showPowerBg:runAction(CCScaleTo:create(0.15, view.minScale, view.minScale))

    local lbg = img.createUISprite(img.ui.herotask_dialog)
    lbg:setAnchorPoint(1, 0.5)
    lbg:setPosition(480, 576/2)
    showPowerBg:addChild(lbg)
    
    local rbg = img.createUISprite(img.ui.herotask_dialog)
    rbg:setFlipX(true)
    rbg:setAnchorPoint(0, 0.5)
    rbg:setPosition(lbg:boundingBox():getMaxX()-1, 576/2)
    showPowerBg:addChild(rbg)

    local board = img.createUI9Sprite(img.ui.select_hero_camp_bg)
    board:setPreferredSize(CCSize(622, 182))
    board:setAnchorPoint(ccp(0.5, 0))
    board:setPosition(480, 315)
    showPowerBg:addChild(board)

    local titleCondition = lbl.createFont1(18, i18n.global.mail_rewards.string, ccc3(0x5b, 0x27, 0x06))
    titleCondition:setPosition(480, 465)
    showPowerBg:addChild(titleCondition)

    local showLfgline = img.createUISprite(img.ui.herotask_fgline)
    showLfgline:setAnchorPoint(ccp(1, 0.5))
    showLfgline:setPosition(titleCondition:boundingBox():getMinX() - 30, titleCondition:boundingBox():getMidY())
    showPowerBg:addChild(showLfgline)

    local showRfgline = img.createUISprite(img.ui.herotask_fgline)
    showRfgline:setAnchorPoint(ccp(0, 0.5))
    showRfgline:setFlipX(true)
    showRfgline:setPosition(titleCondition:boundingBox():getMaxX() + 30, titleCondition:boundingBox():getMidY())
    showPowerBg:addChild(showRfgline)
    
    local labTip = lbl.createMixFont1(16, i18n.global.asylum_put_tip.string, ccc3(0x73, 0x3b, 0x05))
    labTip:setPosition(480, 285)
    showPowerBg:addChild(labTip)

    local cfgact = vps[pos].cfg

    local ox = 480+52 - 52*#cfgact.rewards
    local showReward = {}
    for i,v in ipairs(cfgact.rewards) do
        local showRewardSprite = nil
        if v.type == 1 then
            showRewardSprite = img.createItem(v.id, v.num)
        else
            showRewardSprite = img.createEquip(v.id, v.num)
        end
        showReward[i] = CCMenuItemSprite:create(showRewardSprite, nil)
        showReward[i]:setPosition(ox+(i-1)*105, 387)
        local menuReward = CCMenu:createWithItem(showReward[i])
        menuReward:setPosition(0, 0)
        showPowerBg:addChild(menuReward)
        
        showReward[i]:registerScriptTapHandler(function()
            audio.play(audio.button)
            if v.type == 1 then
                local tips = require("ui.tips.item").createForShow(v)
                layer:addChild(tips, 10000)
            else
                local tips = require("ui.tips.equip").createById(v.id)
                layer:addChild(tips, 10000)
            end
        end)
    end

    local condition = cfgact.parameter
    local sx = 518 - (#condition-1)*48 

    if cfgact.extra then
        sx = 518 - (#condition+#cfgact.extra-1)*48
          
        for i=1,#cfgact.extra do 
            local icon1 = img.createItem(cfgact.extra[i].id, cfgact.extra[i].num)
            local btnIcon1 = CCMenuItemSprite:create(icon1, nil)
            btnIcon1:setAnchorPoint(1, 0)
            btnIcon1:setScale(0.9)
            btnIcon1:setPosition(sx+(#condition+i-1)*96, 174)
            local menuIcon1 = CCMenu:createWithItem(btnIcon1)
            menuIcon1:setPosition(0, 0)
            showPowerBg:addChild(menuIcon1)
            
            btnIcon1:registerScriptTapHandler(function()
                audio.play(audio.button)
                local tips = require("ui.tips.item").createForShow({id = cfgact.extra[i].id, num = cfgact.extra[i].num})
                layer:addChild(tips, 10000)
            end)
            
            if cfgact.extra[i].id == ITEM_ID_COIN then
                if cfgact.extra[i].num > bag.coin() then 
                    icon1.lblNum:setColor(ccc3(255,44,44))
                end
            else
                if cfgact.extra[i].num > bag.gem() then 
                    icon1.lblNum:setColor(ccc3(255,44,44))
                end
            end
        end
    end

    local btnHero = {}

    initHeros()

    for i,v in ipairs(condition) do
        v.select = {}
        local id = 1000*v.qlt+100*v.group+99          
        if v.group == 0 then
            id = 1000*v.qlt+100*9+99
        end
        local btnSp
        btnSp = img.createHeroHead(id, nil, true, true)
        if v.job ~= 0 then
            local showJob = img.createUISprite(img.ui["job_" .. v.job])
            showJob:setPosition(15, 52)
            btnSp:addChild(showJob, 3)
        end

        btnHero[i] = CCMenuItemSprite:create(btnSp, nil)
        btnHero[i]:setAnchorPoint(ccp(1, 0))
        btnHero[i]:setScale(0.8)

        btnHero[i]:setPosition(sx + (i - 1) * 95, 174)

        local menuHero = CCMenu:createWithItem(btnHero[i])
        menuHero:setPosition(0, 0)
        showPowerBg:addChild(menuHero)

        local showNum = lbl.createFont2(16, "0/" .. v.num)
        showNum:setPosition(btnHero[i]:boundingBox():getMidX(), 162)
        showPowerBg:addChild(showNum)
        setShader(btnHero[i], SHADER_GRAY, true)

        local icon = img.createUISprite(img.ui.hero_equip_add)
        icon:setPosition(btnHero[i]:boundingBox():getMaxX() - 23, btnHero[i]:boundingBox():getMaxY() - 23)
        showPowerBg:addChild(icon)
        icon:runAction(CCRepeatForever:create(CCSequence:createWithTwoActions(
            CCFadeTo:create(0.5, 255 * 0.3), CCFadeTo:create(0.5, 255))))
        
        btnHero[i]:registerScriptTapHandler(function() 
            audio.play(audio.button)
            local function func()
                showNum:setString(#v.select .. "/" .. v.num)
                if #v.select < v.num then
                    setShader(btnHero[i], SHADER_GRAY, true)
                    showNum:setColor(ccc3(0xff, 0xff, 0xff))
                else
                    clearShader(btnHero[i], true)
                    showNum:setColor(ccc3(0xc3, 0xff, 0x42))
                end
                --for j, vv in ipairs(operData.condition) do
                --    if numforhero(vv) >= vv.num - #vv.select then
                --        reddot[j]:setVisible(true)
                --    else
                --        reddot[j]:setVisible(false)
                --    end
                --end
            end
            layer:addChild(createSelectBoard(v, func), 1000)
        end)
    end

    local function createSurebuy(vpObj, cfgObj, callback)
        local params = {}
        params.btn_count = 0
        params.body = string.format(i18n.global.asylum_submit_sure.string, 20)
        local board_w = 474

        local dialoglayer = require("ui.dialog").create(params) 

        local btnYesSprite = img.createLogin9Sprite(img.login.button_9_small_gold)
        btnYesSprite:setPreferredSize(CCSize(153, 50))
        local btnYes = SpineMenuItem:create(json.ui.button, btnYesSprite)
        btnYes:setPosition(board_w/2+95, 100)
        local labYes = lbl.createFont1(18, i18n.global.board_confirm_yes.string, ccc3(0x73, 0x3b, 0x05))
        labYes:setPosition(btnYes:getContentSize().width/2, btnYes:getContentSize().height/2)
        btnYesSprite:addChild(labYes)
        local menuYes = CCMenu:create()
        menuYes:setPosition(0, 0)
        menuYes:addChild(btnYes)
        dialoglayer.board:addChild(menuYes)

        local btnNoSprite = img.createLogin9Sprite(img.login.button_9_small_gold)
        btnNoSprite:setPreferredSize(CCSize(153, 50))
        local btnNo = SpineMenuItem:create(json.ui.button, btnNoSprite)
        btnNo:setPosition(board_w/2-95, 100)
        local labNo = lbl.createFont1(18, i18n.global.board_confirm_no.string, ccc3(0x73, 0x3b, 0x05))
        labNo:setPosition(btnNo:getContentSize().width/2, btnNo:getContentSize().height/2)
        btnNoSprite:addChild(labNo)
        local menuNo = CCMenu:create()
        menuNo:setPosition(0, 0)
        menuNo:addChild(btnNo)
        dialoglayer.board:addChild(menuNo)

        btnYes:registerScriptTapHandler(function()
            dialoglayer:removeFromParentAndCleanup(true)
            if cfgact.extra then
                --if cfgact.extra[1].num > bag.gem() then
                --    showToast(i18n.global.gboss_fight_st6.string)
                --    return
                --end
                --if cfgact.extra[2].num > bag.coin() then
                --    showToast(i18n.global.toast_hero_need_coin.string)
                --    return
                --end
                for i=1,#cfgact.extra do 
                    if cfgact.extra[i].id == ITEM_ID_COIN then
                        if cfgact.extra[i].num > bag.coin() then
                            showToast(i18n.global.toast_hero_need_coin.string)
                            return
                        end
                    end
                    if cfgact.extra[i].id == ITEM_ID_GEM then
                        if cfgact.extra[i].num > bag.gem() then
                            showToast(i18n.global.gboss_fight_st6.string)
                            return
                        end
                    end
                end
            end
            --local itemObj = bagData.items.find(ITEM_ID_TINYSNOWMAN)
            --if not itemObj then
            --    itemObj = {id=ITEM_ID_TINYSNOWMAN, num=0}
            --end
            --if itemObj.num < cfgObj.instruct then
            --    showToast(i18n.global.snowman_not_enough.string)
            --    return
            --end
            local hids = {}
            if not condition then
                return
            end
            for i, v in ipairs(condition) do
                if #v.select >= v.num then
                    for j, k in ipairs(v.select) do
                        hids[#hids + 1] = k
                    end
                else
                    showToast(i18n.global.hero_wake_no_hero.string)
                    return
                end
            end

            local param = {
                sid = player.sid,
                id = IDS.ASYLUM_1.ID+pos-1,
                hids = hids,
            }
            tbl2string(param)
            addWaitNet()
            netClient:shield_change(param, function(__data)
                delWaitNet()
                tbl2string(__data)
                if __data.status < 0 then
                    showToast("status:" .. __data.status)
                    return
                end
                if __data.status == -1 then
                    showToast(i18n.global.actitem_onlyone.string)
                    return
                end
                if __data.status == -2 then
                    showToast(i18n.global.hero_wake_no_hero.string)
                    return
                end
                vps[pos].limits = vps[pos].limits - 1
                --if vpObj.limits == 0 then
                --    callback()
                --end
                --itemObj.num = itemObj.num - cfgObj.instruct
                --updateCoin()
                if cfgact.extra then
                    for ii=1,#cfgact.extra do 
                        if cfgact.extra[ii].id == ITEM_ID_COIN then
                            bag.subCoin(cfgact.extra[ii].num)
                        end
                        if cfgact.extra[ii].id == ITEM_ID_GEM then
                            bag.subGem(cfgact.extra[ii].num)
                        end
                    end
                end
                --local exp, evolve = heros.decompose(hids)
                --bag.items.add({ id = ITEM_ID_HERO_EXP, num = exp})
                --bag.items.add({ id = ITEM_ID_EVOLVE_EXP, num = evolve})
                -- show affix
                local reward = {items = {}, equips = {}}
                local returnflag = false
                --if exp > 0 then
                --    table.insert(reward.items,{ id = ITEM_ID_HERO_EXP, num = exp})
                --end
                --if evolve > 0 then
                --    table.insert(reward.items,{ id = ITEM_ID_EVOLVE_EXP, num = evolve})
                --end
                --bag.items.add({ id = ITEM_ID_RUNE_COIN, num = rune})
                for i, v in ipairs(hids) do
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
                                returnflag = true
                            end
                        end
                        heros.del(v)
                    --end
                end
                --layer:addChild(createBoardForRewards(heroData.hid, reward), 1002)
                if returnflag then 
                    layer:getParent():getParent():getParent():addChild((require"ui.hook.drops").create(reward, i18n.global.material_return.string), 1000)
                end

                if __data.reward then
                    bag.addRewards(__data.reward)
                    local rewardsKit = require "ui.reward"
                    CCDirector:sharedDirector():getRunningScene():addChild(rewardsKit.showReward(__data.reward), 100000)
                end
                layer:removeFromParentAndCleanup()
                getgrayfunc(pos)
            end)
            audio.play(audio.button)
        end)
        btnNo:registerScriptTapHandler(function()
            dialoglayer:removeFromParentAndCleanup(true)
            audio.play(audio.button)
        end)

        local function diabackEvent()
            dialoglayer:removeFromParentAndCleanup(true)
        end

        function dialoglayer.onAndroidBack()
            diabackEvent()
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
    
    local submit = img.createLogin9Sprite(img.login.button_9_small_gold)
    submit:setPreferredSize(CCSize(148, 54))
    local submitlab = lbl.createFont1(16, i18n.global.frdpvp_team_submit.string, ccc3(0x73, 0x3b, 0x05))
    submitlab:setPosition(CCPoint(submit:getContentSize().width/2, submit:getContentSize().height/2))
    submit:addChild(submitlab)
    
    local submitBtn = SpineMenuItem:create(json.ui.button, submit)
    submitBtn:setPosition(480, 90)
    local submitMenu = CCMenu:createWithItem(submitBtn)
    submitMenu:setPosition(0, 0)
    showPowerBg:addChild(submitMenu)
    submitBtn:registerScriptTapHandler(function()
       audio.play(audio.button)
       --layer:getParent():getParent():addChild(ui.createOplayer(), 1000)
        local surelayer = createSurebuy()
        layer:addChild(surelayer, 1000)
    end)

    local function backEvent()
        layer:removeFromParentAndCleanup()
    end

    -- close btn
    local close0 = img.createUISprite(img.ui.close)
    local closeBtn = SpineMenuItem:create(json.ui.button, close0)
    closeBtn:setPosition(CCPoint(814, 525))
    local closeMenu = CCMenu:createWithItem(closeBtn)
    closeMenu:setPosition(CCPoint(0, 0))
    showPowerBg:addChild(closeMenu)
    closeBtn:registerScriptTapHandler(function()     
        backEvent()
    end)

    function layer.onAndroidBack()
        backEvent()
    end

    addBackEvent(layer)

    local function onEnter()
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

    layer:setTouchEnabled(true)

    return layer
end

function ui.create()
    local layer = CCLayer:create()

    local vps = {}
    for _, v in ipairs(vp_ids) do
        local tmp_status = activityData.getStatusById(v)
		if tmp_status then
			vps[#vps+1] = tmp_status
		else
			break
		end
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

    img.load(img.packedOthers.ui_activity_asylum)
    local banner = img.createUISprite("activity_asylum.png")
    banner:setAnchorPoint(CCPoint(0.5, 1))
    banner:setPosition(CCPoint(board_w/2-10, board_h-4))
    board:addChild(banner)

    local titlebg = img.createUISprite(img.ui.activity_asylum_title)
    titlebg:setAnchorPoint(0.5, 1)
    titlebg:setPosition(board_w/2, board_h-4)
    board:addChild(titlebg, 1)

    local titleLab = lbl.createFont2(18, i18n.global.activity_asylum_title.string, ccc3(0xf6, 0xd6, 0x6c))
    titleLab:setPosition(CCPoint(board_w/2, board_h-20))
    board:addChild(titleLab, 1)

    local lbl_cd = lbl.createFont2(14, "", ccc3(0xa5, 0xfd, 0x47))
    lbl_cd:setAnchorPoint(CCPoint(0, 0.5))
    lbl_cd:setPosition(CCPoint(250, 380))
    banner:addChild(lbl_cd)
    local lbl_cd_des = lbl.createFont2(14, i18n.global.activity_to_end.string)
    lbl_cd_des:setAnchorPoint(CCPoint(0, 0.5))
    lbl_cd_des:setPosition(CCPoint(321, 380))
    banner:addChild(lbl_cd_des)

    if i18n.getCurrentLanguage() == kLanguageRussian then
        lbl_cd_des:setPosition(CCPoint(250-40, 380))
        lbl_cd:setAnchorPoint(CCPoint(0, 0.5))
        lbl_cd:setPosition(CCPoint(lbl_cd_des:boundingBox():getMaxX()+10, 380))
    end

    local SCROLL_CONTAINER_SIZE = #vp_ids * 180 + 30        
    local scrollUI = require "ui.pet.scrollUI"
    local Scroll = scrollUI.create()
    Scroll:setDirection(kCCScrollViewDirectionHorizontal)
    Scroll:setPosition(-8, 75)
	Scroll:setTouchEnabled(false)
    Scroll:setViewSize(CCSize(564, 290))
    Scroll:setContentSize(CCSize(SCROLL_CONTAINER_SIZE+20, 290))
    board:addChild(Scroll)
    --drawBoundingbox(board, Scroll)
    
    local sign = {}
    local sell = {}
    local heroBody = {}
    local bottom = {}
    local btn = {} 
    local acceMenu = {}
    local selectPos = 1

    local function setBtnStatus()
        for i=selectPos,selectPos+2 do
            if vps[i].limits == 0 then
                btn[i-selectPos+1]:setVisible(false)
            else
                btn[i-selectPos+1]:setVisible(true)
            end
        end
    end

    local function getgrayfunc(pos)
        print("debug:pos=", pos, selectPos)
        sign[pos]:setVisible(false)
        sell[pos]:setVisible(true)
        if btn[pos-selectPos+1] then
            btn[pos-selectPos+1]:setVisible(false)
        end
    end

    local dx = 154
    local posx = {board_w/2-154-8, board_w/2-8, board_w/2+154-8, board_w/2+300, board_w/2+454, board_w/2+608}
    local function createItem(pos)
        sign[pos] = img.createUISprite(img.ui.activity_asylum_a)
        sign[pos]:setPosition(posx[pos]+8, 315-75)
        Scroll:getContainer():addChild(sign[pos])

        sell[pos] = img.createUISprite(img.ui.activity_asylum_tick)
        sell[pos]:setPosition(posx[pos]+8, 315-75)
        Scroll:getContainer():addChild(sell[pos])
        sell[pos]:setVisible(false)

        bottom[pos] = img.createUISprite(img.ui.activity_asylum_bottom)
        bottom[pos]:setPosition(posx[pos]+8, 122-75)
        Scroll:getContainer():addChild(bottom[pos])

        local cfgact = vps[pos].cfg
        local cfgitem = require "config.item"

        heroBody[pos] = json.createSpineHero(cfgact.instruct)
        heroBody[pos]:setScale(0.38)
        heroBody[pos]:setPosition(posx[pos]+8, 116-75)
        Scroll:getContainer():addChild(heroBody[pos])

        if vps[pos].limits == 0 then
            getgrayfunc(pos)
        end
    end

    for i = 1,#vp_ids do
        createItem(i)
    end

    local function createBtn(pos)
        local spritebtn = img.createLogin9Sprite(img.login.button_9_small_gold)
        spritebtn:setPreferredSize(CCSize(125, 42))
        local accelab = lbl.createFont1(16, i18n.global.asylum_btn_acce.string, ccc3(0x73, 0x3b, 0x05))
        accelab:setPosition(CCPoint(spritebtn:getContentSize().width/2, spritebtn:getContentSize().height/2))
        spritebtn:addChild(accelab)
        
        btn[pos] = SpineMenuItem:create(json.ui.button, spritebtn)
        btn[pos]:setPosition(posx[pos], 50)
        acceMenu[pos] = CCMenu:createWithItem(btn[pos])
        acceMenu[pos]:setPosition(0, 0)
        board:addChild(acceMenu[pos])

        btn[pos]:registerScriptTapHandler(function()
           audio.play(audio.button)
           layer:getParent():getParent():addChild(ui.createOplayer(pos+selectPos-1, vps, getgrayfunc), 1000)
        end)
    end

    for i = 1,3 do
        createBtn(i)
    end

    setBtnStatus()
    local last_update = os.time() - 1
    local function onUpdate(ticks)
        if os.time() - last_update < 1 then return end
        last_update = os.time()
        local remain_cd = vps[1].cd - (os.time() - activityData.pull_time)
        if remain_cd >= 0 then
            local time_str = time2string(remain_cd)
            lbl_cd:setString(time_str)
        else
        end
    end

    local btnInfoSprite = img.createUISprite(img.ui.btn_help)
    local btnInfo = SpineMenuItem:create(json.ui.button, btnInfoSprite)
    btnInfo:setPosition(525, board_h-38)
    local menuInfo = CCMenu:createWithItem(btnInfo)
    menuInfo:setPosition(0, 0)
    board:addChild(menuInfo, 100)
    btnInfo:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer:getParent():getParent():addChild(require("ui.help").create(i18n.global.help_asylum.string, i18n.global.help_title.string), 1000)
    end)

    local leftraw = img.createUISprite(img.ui.hero_raw)
    local btnLeftraw = SpineMenuItem:create(json.ui.button, leftraw)
    btnLeftraw:setScale(0.85)
    btnLeftraw:setPosition(18, 198)
    local menuLeftraw = CCMenu:createWithItem(btnLeftraw)
    menuLeftraw:setPosition(0, 0)
    board:addChild(menuLeftraw, 1)
    if selectPos <= 1 then
        setShader(btnLeftraw, SHADER_GRAY, true)
        btnLeftraw:setEnabled(false)
    end

    local rightraw = img.createUISprite(img.ui.hero_raw)
    rightraw:setFlipX(true)
    local btnRightraw = SpineMenuItem:create(json.ui.button, rightraw)
    btnRightraw:setScale(0.85)
    btnRightraw:setPosition(26+510, 198)
    local menuRightraw = CCMenu:createWithItem(btnRightraw)
    menuRightraw:setPosition(0, 0)
    board:addChild(menuRightraw, 1)

    if selectPos >= #vp_ids-2 then
        setShader(btnRightraw, SHADER_GRAY, true)
        btnRightraw:setEnabled(false)
    end


    local function moveLeft()
        if selectPos < #vp_ids-2 then
            selectPos = selectPos + 1
        else
            return
        end
        setBtnStatus() 
        if selectPos == 2 then
            clearShader(btnLeftraw, true)
            btnLeftraw:setEnabled(true)
        end
        if selectPos >= #vp_ids-2 then
            setShader(btnRightraw, SHADER_GRAY, true)
            btnRightraw:setEnabled(false)
        end
        for i = 1,#vp_ids do
            sign[i]:runAction(CCMoveBy:create(0.1, CCPoint(-154, 0)))
            sell[i]:runAction(CCMoveBy:create(0.1, CCPoint(-154, 0)))
            bottom[i]:runAction(CCMoveBy:create(0.1, CCPoint(-154, 0)))
            heroBody[i]:runAction(CCMoveBy:create(0.1, CCPoint(-154, 0)))
        end
    end

    local function moveRight()
        if selectPos > 1 then
            selectPos = selectPos - 1
        else
            return
        end
        setBtnStatus() 
        if selectPos == #vp_ids-3 then
            clearShader(btnRightraw, true)
            btnRightraw:setEnabled(true)
        end
        if selectPos <= 1 then
            setShader(btnLeftraw, SHADER_GRAY, true)
            btnLeftraw:setEnabled(false)
        end
        for i = 1,#vp_ids do
            sign[i]:runAction(CCMoveBy:create(0.1, CCPoint(154, 0)))
            sell[i]:runAction(CCMoveBy:create(0.1, CCPoint(154, 0)))
            bottom[i]:runAction(CCMoveBy:create(0.1, CCPoint(154, 0)))
            heroBody[i]:runAction(CCMoveBy:create(0.1, CCPoint(154, 0)))
        end
    end

    btnLeftraw:registerScriptTapHandler(function()
        audio.play(audio.button)
        moveRight()
    end)

    btnRightraw:registerScriptTapHandler(function()
        audio.play(audio.button)
        moveLeft()
    end)


    local touchbeginx, touchbeginy
    local isclick
    local function onTouchBegin(x, y)
        touchbeginx = x
        isclick = true
        return true
    end

    local function onTouchMoved(x, y)
        local p0 = board:convertToNodeSpace(ccp(touchbeginx, y))
        local p1 = board:convertToNodeSpace(ccp(x, y))
        if isclick and math.abs(p1.x-p0.x) > 10  then
            isclick = false
            if Scroll:boundingBox():containsPoint(p1) then
                if p1.x - p0.x >= 10 then
                    moveRight()
                end
                if p0.x - p1.x >= 10 then
                    moveLeft()
                end
            end
        end
    end

    local function onTouchEnd(x, y)
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

    board:registerScriptTouchHandler(onTouch)
    board:setTouchSwallowEnabled(false)
    board:setTouchEnabled(true)

    layer:scheduleUpdateWithPriorityLua(onUpdate, 0)
    --img.unload(img.packedOthers.ui_activity_summon_score)
    --require("ui.activity.ban").addBan(layer, scroll)
    --layer:setTouchSwallowEnabled(false)
    --layer:setTouchEnabled(true)

    return layer
end

return ui
