local skin = {}

require "common.func"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local i18n = require "res.i18n"
local audio = require "res.audio"
local net = require "net.netClient"
local cfghero = require "config.hero"
local cfgequip = require "config.equip"
local cfgexphero = require "config.exphero"
local heros = require "data.heros"
local bag = require "data.bag"
local player = require "data.player"
local scrollUI = require "ui.pet.scrollUI"

local operData = {}

function skin.create(heroData, callfuncSkin, superlayer)
    local layer = CCLayer:create()

    local w_board = 428
    local h_board = 503
    local board = img.createUI9Sprite(img.ui.hero_bg)
    board:setPreferredSize(CCSize(428, 503))
    board:setAnchorPoint(ccp(0, 0))
    board:setPosition(465, 35 - 20)
    layer:addChild(board)

    local titleShade = lbl.createFont1(24, i18n.global.main_btn_skin.string, ccc3(0x59, 0x30, 0x1b))
    titleShade:setPosition(214, 472)
    board:addChild(titleShade)
    local title = lbl.createFont1(24, i18n.global.main_btn_skin.string, ccc3(0xe6, 0xd0, 0xae))
    title:setPosition(214, 474)
    board:addChild(title)

    local fgLine = img.createUI9Sprite(img.ui.hero_panel_fgline)
    fgLine:setPreferredSize(CCSize(356, 4))
    fgLine:setPosition(214, 126)
    board:addChild(fgLine)

    local skinFlag = false
    local skinId = nil
    for _,v in ipairs(heroData.equips) do
        if cfgequip[v].pos == EQUIP_POS_SKIN then
            skinFlag = true
            skinId = v
        end
    end

    local function onUpNum(attr, nattr)
        local NAME = {
            "atk", "hp", "arm", "spd", "sklP", "hit", "miss", "crit", "critTime", "brk", "free", "decDmg", "trueAtk",
        }
        local showStat = {}
        for i, v in ipairs(NAME) do
            local preVal = attr[NAME[i]] 
            local aftVal = nattr[NAME[i]]
            if preVal ~= aftVal then
                local name, val = buffString(NAME[i], nattr[NAME[i]] - attr[NAME[i]], true)
                if aftVal > preVal then
                    showStat[#showStat + 1] = { text = name .. "    +" .. val }
                else
                    showStat[#showStat + 1] = { text = name .. "    " .. val, isRed = true }
                end
            end
        end

        local showLayer = CCLayer:create()
        if layer and not tolua.isnull(layer) then
            layer:addChild(showLayer)
        end
        for i, v in ipairs(showStat) do
            json.load(json.ui.hero_numbers)
            local anim = DHSkeletonAnimation:createWithKey(json.ui.hero_numbers)
            anim:scheduleUpdateLua()
            anim:setPosition(230, 230 + i * 24)
            showLayer:addChild(anim)

            local showNum = lbl.createFont2(16, v.text, ccc3(163, 255, 55))
            if v.isRed then
                anim:playAnimation("down")
                showNum:setColor(ccc3(255, 138, 106))
            else
                anim:playAnimation("up")
            end
            anim:addChildFollowSlot("code_numbers", showNum)
            
        end
        showLayer:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(2), CCRemoveSelf:create()))
    end

    local curPos = 1
    local headIcons = {}
    local tickIcon = {}
    local selectPos = 1
    local nowWearPos = 1

    if getHeroSkin(heroData.hid) then
        for i = 1, #cfghero[heroData.id].skinId do
            if cfghero[heroData.id].skinId[i] == getHeroSkin(heroData.hid) then
                selectPos = i
                nowWearPos = i
            end
        end
    end

    local skinName = lbl.createMixFont1(16, i18n.equip[cfghero[heroData.id].skinId[selectPos]].name, ccc3(0x73, 0x3b, 0x05))
    skinName:setPosition(w_board/2, 155)
    board:addChild(skinName)

    local visitSprite = img.createUISprite(img.ui.hero_skin_visit1)
    local visitBtn = SpineMenuItem:create(json.ui.button, visitSprite)
    visitBtn:setPosition(CCPoint(w_board/2+162, 416))
    local visitMenu = CCMenu:createWithItem(visitBtn)
    visitMenu:setPosition(0, 0)
    board:addChild(visitMenu, 1)

    local novisitSprite = img.createUISprite(img.ui.hero_skin_visit0)
    local novisitBtn = SpineMenuItem:create(json.ui.button, novisitSprite)
    novisitBtn:setPosition(CCPoint(w_board/2+162, 416))
    local novisitMenu = CCMenu:createWithItem(novisitBtn)
    novisitMenu:setPosition(0, 0)
    board:addChild(novisitMenu, 1)

    local function setVisitState()
        if heroData.visit == true then
            visitBtn:setVisible(true)
            novisitBtn:setVisible(false)
        else
            visitBtn:setVisible(false)
            novisitBtn:setVisible(true)
        end
    end

    local function setVisitFade()
        visitBtn:setVisible(false)
        novisitBtn:setVisible(false)
    end
    
    setVisitState()
    if skinFlag == false then
        setVisitFade()
    end

    visitBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        local params = {
            sid = player.sid,
            hid = heroData.hid,
        }
        tbl2string(params)
        addWaitNet()
        net:hero_skin_visit(params, function(__data)
            delWaitNet()
            tbl2string(__data)
            if __data.status < 0 then
                showToast("status:" .. __data.status)
                return
            end
            if getHeroSkin(heroData.hid, true) then
                for i = 1, #cfghero[heroData.id].skinId do
                    if cfghero[heroData.id].skinId[i] == getHeroSkin(heroData.hid, true) then
                        nowWearPos = i
                    end
                end
            end
            print("********nowWearPos:", nowWearPos)
            callfuncSkin(heroData.id, true, nowWearPos)
            heros.setVisit(heroData.hid, false)
            setVisitState()

        end)
    end)

    novisitBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        local params = {
            sid = player.sid,
            hid = heroData.hid,
        }
        tbl2string(params)
        addWaitNet()
        net:hero_skin_visit(params, function(__data)
            delWaitNet()
            tbl2string(__data)
            if __data.status < 0 then
                showToast("status:" .. __data.status)
                return
            end
            if getHeroSkin(heroData.hid, true) then
                for i = 1, #cfghero[heroData.id].skinId do
                    if cfghero[heroData.id].skinId[i] == getHeroSkin(heroData.hid, true) then
                        nowWearPos = i
                    end
                end
            end
            callfuncSkin(heroData.id, false, nowWearPos)
            heros.setVisit(heroData.hid, true)
            setVisitState()
        end)
    end)

    local offSprite = img.createLogin9Sprite(img.login.button_9_small_gold)
    offSprite:setPreferredSize(CCSizeMake(185, 54))
    local offBtn = SpineMenuItem:create(json.ui.button, offSprite)
    offBtn:setPosition(CCPoint(w_board/2, 73))
    local offMenu = CCMenu:createWithItem(offBtn)
    offMenu:setPosition(0, 0)
    board:addChild(offMenu, 1)
    local offLab = lbl.createFont1(18, i18n.global.tips_take_off.string, ccc3(0x73, 0x3b, 0x05))
    offLab:setPosition(CCPoint(offBtn:getContentSize().width/2, offBtn:getContentSize().height/2))
    offSprite:addChild(offLab)
    offBtn:setVisible(false)

    local wearSprite = img.createLogin9Sprite(img.login.button_9_small_gold)
    wearSprite:setPreferredSize(CCSizeMake(185, 54))
    local wearBtn = SpineMenuItem:create(json.ui.button, wearSprite)
    wearBtn:setPosition(CCPoint(w_board/2, 73))
    local receiptallMenu = CCMenu:createWithItem(wearBtn)
    receiptallMenu:setPosition(0, 0)
    board:addChild(receiptallMenu, 1)

    local wearLab = lbl.createFont1(18, i18n.global.tips_put_on.string, ccc3(0x73, 0x3b, 0x05))
    wearLab:setPosition(CCPoint(wearBtn:getContentSize().width/2, wearBtn:getContentSize().height/2))
    wearSprite:addChild(wearLab)

    local SCROLL_CONTAINER_SIZE = #cfghero[heroData.id].skinId * 180 + 30        

    local skinBg = CCSprite:create()
    skinBg:setContentSize(CCSize(360,240))
    skinBg:setPosition(82-50+180, 190+102)
    board:addChild(skinBg)

    local Scroll = scrollUI.create()
    Scroll:setDirection(kCCScrollViewDirectionHorizontal)
    Scroll:setPosition(0, 0)
	Scroll:setTouchEnabled(false)
    Scroll:setViewSize(CCSize(360, 240))
    Scroll:setContentSize(CCSize(SCROLL_CONTAINER_SIZE+20,240))
    --storeBuyLayer:addChild(Scroll)
    skinBg:addChild(Scroll)
    --drawBoundingbox(skinBg, Scroll)

    if bag.equips.find(cfghero[heroData.id].skinId[selectPos]) == nil or
        (bag.equips.find(cfghero[heroData.id].skinId[selectPos]) and bag.equips.find(cfghero[heroData.id].skinId[selectPos]).num == 0) then
        wearBtn:setEnabled(false)
        setShader(wearBtn, SHADER_GRAY, true)
    end

    for i = 1, #cfghero[heroData.id].skinId do
        headIcons[i] = img.createSkinIcon(cfghero[heroData.id].skinId[i])

        headIcons[i]:setPosition(15+165*(i+1-selectPos), 120)
        Scroll:getContainer():addChild(headIcons[i])
        if i ~= selectPos then
            headIcons[i]:setScale(0.7)
        end
        
        local restSkinBg = img.createUI9Sprite(img.ui.skin_restskinbg)
        restSkinBg:setPreferredSize(CCSize(152, 32))
        restSkinBg:setPosition(headIcons[i]:getContentSize().width/2, 20)
        headIcons[i]:addChild(restSkinBg)

        local skinnum = 0 
        if bag.equips.find(cfghero[heroData.id].skinId[i]) then
            skinnum = bag.equips.find(cfghero[heroData.id].skinId[i]).num
        end
        local restSkin = lbl.createMixFont1(16, skinnum, ccc3(255, 246, 223))
        restSkin:setPosition(headIcons[i]:getContentSize().width/2, 20)
        headIcons[i]:addChild(restSkin)
        headIcons[i].restSkin = restSkin

        local framBg = nil
        if cfgequip[cfghero[heroData.id].skinId[i]].powerful and cfgequip[cfghero[heroData.id].skinId[i]].powerful ~= 0 then
            framBg = img.createUISprite(img.ui.skin_frame_sp)
        else
            framBg = img.createUISprite(img.ui.skin_frame)
        end
        framBg:setPosition(headIcons[i]:getContentSize().width/2, headIcons[i]:getContentSize().height/2)
        headIcons[i]:addChild(framBg)

        --local pointer = img.createUISprite(img.ui.hero_skin_pointer)
        --pointer:setPosition(headIcons[i]:getContentSize().width/2, 0)
        --headIcons[i]:addChild(pointer)

        if cfghero[heroData.id].skinId[i] == skinId then
            tickIcon[i] = img.createUISprite(img.ui.login_month_finish)
            tickIcon[i]:setPosition(headIcons[i]:getContentSize().width/2+55, headIcons[i]:getContentSize().height/2+80)
            headIcons[i]:addChild(tickIcon[i], 2)
            offBtn:setVisible(true)
            wearBtn:setVisible(false)
        end
    end

    offBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        local params = {
            sid = player.sid,
            hid = heroData.hid,
        }
        tbl2string(params)
        addWaitNet()
        net:hero_skin_off(params, function(__data)
            delWaitNet()
            tbl2string(__data)
            if __data.status < 0 then
                showToast("status:" .. __data.status)
                return
            end
            if getHeroSkin(heroData.hid, true) then
                for i = 1, #cfghero[heroData.id].skinId do
                    if cfghero[heroData.id].skinId[i] == getHeroSkin(heroData.hid, true) then
                        nowWearPos = i
                    end
                end
            end
            tickIcon[nowWearPos]:setVisible(false)
            offBtn:setVisible(false)
            wearBtn:setVisible(true)

            setVisitFade()
            callfuncSkin(heroData.id, false, curPos)
            local attr = heroData.attr()
            bag.equips.returnbag({ id = cfghero[heroData.id].skinId[nowWearPos], num = 1})
            for i, v in ipairs(heroData.equips) do
                if v == cfghero[heroData.id].skinId[nowWearPos] then
                    table.remove(heroData.equips, i)
                    break
                end
            end
            local nattr = heroData.attr()
            onUpNum(attr, nattr)
            for ii = 1,#cfghero[heroData.id].skinId do
                local skinnum = 0 
                if bag.equips.find(cfghero[heroData.id].skinId[ii]) then
                    skinnum = bag.equips.find(cfghero[heroData.id].skinId[ii]).num
                end
                headIcons[ii].restSkin:setString(skinnum)
            end
            if bag.equips.find(cfghero[heroData.id].skinId[selectPos]) == nil or
                (bag.equips.find(cfghero[heroData.id].skinId[selectPos]) and
                bag.equips.find(cfghero[heroData.id].skinId[selectPos]).num == 0) then
                setShader(wearBtn, SHADER_GRAY, true)
            else
                wearBtn:setEnabled(true)
                clearShader(wearBtn, true)
            end
            --if skinnum == 1 then
                --wearBtn:setEnabled(true)
                --clearShader(wearBtn, true)
            --end
        end)
    end)

    wearBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        local params = {
            sid = player.sid,
            hid = heroData.hid,
            skinid = cfghero[heroData.id].skinId[selectPos],
        }
        tbl2string(params)
        addWaitNet()
        net:hero_skin_wear(params, function(__data)
            delWaitNet()
            tbl2string(__data)
            if __data.status < 0 then
                showToast("status:" .. __data.status)
                return
            end
            if tickIcon[selectPos] then
                tickIcon[selectPos]:setVisible(true)
            else
                tickIcon[selectPos] = img.createUISprite(img.ui.login_month_finish)
                tickIcon[selectPos]:setPosition(headIcons[selectPos]:getContentSize().width/2+55, headIcons[curPos]:getContentSize().height/2+80)
                headIcons[selectPos]:addChild(tickIcon[selectPos], 2)
            end
            offBtn:setVisible(true)
            wearBtn:setVisible(false)

            setVisitState()
            if heroData.visit == false then
                callfuncSkin(heroData.id, true, selectPos)
            end
            nowWearPos = selectPos
            local attr = heroData.attr()
            bag.equips.sub({ id = cfghero[heroData.id].skinId[selectPos], num = 1})
            if getHeroSkin(heroData.hid, true) then
                bag.equips.returnbag({ id = getHeroSkin(heroData.hid, true), num = 1})
                for ii, v in ipairs(heroData.equips) do
                    if v == getHeroSkin(heroData.hid, true) then
                        table.remove(heroData.equips, ii)
                        break
                    end
                end
            end
            heroData.equips[#heroData.equips+1] = cfghero[heroData.id].skinId[selectPos]
            local nattr = heroData.attr()
            onUpNum(attr, nattr)
            --local skinnum = 0 
            --if bag.equips.find(cfghero[heroData.id].skinId[selectPos]) then
            --    skinnum = bag.equips.find(cfghero[heroData.id].skinId[selectPos]).num
            --end
            --headIcons[selectPos].restSkin:setString(skinnum)
            for ii = 1,#cfghero[heroData.id].skinId do
                local skinnum = 0 
                if bag.equips.find(cfghero[heroData.id].skinId[ii]) then
                    skinnum = bag.equips.find(cfghero[heroData.id].skinId[ii]).num
                end
                headIcons[ii].restSkin:setString(skinnum)
                if tickIcon[ii] and ii ~= selectPos then
                    tickIcon[ii]:setVisible(false)
                end
            end
            if bag.equips.find(cfghero[heroData.id].skinId[selectPos]) == nil or
                (bag.equips.find(cfghero[heroData.id].skinId[selectPos]) and
                bag.equips.find(cfghero[heroData.id].skinId[selectPos]).num == 0) then
                wearBtn:setEnabled(false)
                setShader(wearBtn, SHADER_GRAY, true)
            else
                wearBtn:setEnabled(true)
                clearShader(wearBtn, true)
            end
			heros.checkskin(nil, heroData)
            --if skinnum == 0 then
                --wearBtn:setEnabled(false)
                --setShader(wearBtn, SHADER_GRAY, true)
            --end
        end)
    end)

    local function moveLeft()
        if selectPos < #cfghero[heroData.id].skinId then
            selectPos = selectPos + 1
        else
            return
        end
        for i = 1,#cfghero[heroData.id].skinId do
            if i == selectPos - 1 then
                local arr = CCArray:create()
                arr:addObject(CCMoveBy:create(0.1, CCPoint(-165, 0)))
                arr:addObject(CCScaleTo:create(0.1, 0.7))
                headIcons[i]:runAction(CCSpawn:create(arr))
            elseif i == selectPos then
                local arr = CCArray:create()
                arr:addObject(CCMoveBy:create(0.1, CCPoint(-165, 0)))
                arr:addObject(CCScaleTo:create(0.1, 1))
                headIcons[i]:runAction(CCSpawn:create(arr))
            else
                headIcons[i]:runAction(CCMoveBy:create(0.1, CCPoint(-165, 0)))
            end
        end
        if getHeroSkin(heroData.hid, true) then 
            if getHeroSkin(heroData.hid, true) ~= cfghero[heroData.id].skinId[selectPos] then
                offBtn:setVisible(false)
                wearBtn:setVisible(true)
                wearBtn:setEnabled(true)
                clearShader(wearBtn, true)
            else
                offBtn:setVisible(true)
                wearBtn:setVisible(false)
            end
        end
        if bag.equips.find(cfghero[heroData.id].skinId[selectPos]) == nil or
            (bag.equips.find(cfghero[heroData.id].skinId[selectPos]) and
            bag.equips.find(cfghero[heroData.id].skinId[selectPos]).num == 0) then
            wearBtn:setEnabled(false)
            setShader(wearBtn, SHADER_GRAY, true)
        else
            wearBtn:setEnabled(true)
            clearShader(wearBtn, true)
        end
        skinName:setString(i18n.equip[cfghero[heroData.id].skinId[selectPos]].name)
    end
    
    local function moveRight()
        if selectPos > 1 then
            selectPos = selectPos - 1
        else
            return
        end
        for i = 1,#cfghero[heroData.id].skinId do
            if i == selectPos+1 then
                local arr = CCArray:create()
                arr:addObject(CCMoveBy:create(0.1, CCPoint(165, 0)))
                arr:addObject(CCScaleTo:create(0.1, 0.7))
                headIcons[i]:runAction(CCSpawn:create(arr))
            elseif i == selectPos then
                local arr = CCArray:create()
                arr:addObject(CCMoveBy:create(0.1, CCPoint(165, 0)))
                arr:addObject(CCScaleTo:create(0.1, 1))
                headIcons[i]:runAction(CCSpawn:create(arr))
            else
                headIcons[i]:runAction(CCMoveBy:create(0.1, CCPoint(165, 0)))
            end
        end
        if getHeroSkin(heroData.hid, true) then 
            if getHeroSkin(heroData.hid, true) ~= cfghero[heroData.id].skinId[selectPos] then
                offBtn:setVisible(false)
                wearBtn:setVisible(true)
                wearBtn:setEnabled(true)
                clearShader(wearBtn, true)
            else
                offBtn:setVisible(true)
                wearBtn:setVisible(false)
            end
        end
        if bag.equips.find(cfghero[heroData.id].skinId[selectPos]) == nil or
            (bag.equips.find(cfghero[heroData.id].skinId[selectPos]) and bag.equips.find(cfghero[heroData.id].skinId[selectPos]).num == 0) then
            wearBtn:setEnabled(false)
            setShader(wearBtn, SHADER_GRAY, true)
        else
            wearBtn:setEnabled(true)
            clearShader(wearBtn, true)
        end
        skinName:setString(i18n.equip[cfghero[heroData.id].skinId[selectPos]].name)
    end

    local touchbeginx, touchbeginy
    local isclick
    local last_touch_sprite = nil
    local function onTouchBegin(x, y)
        touchbeginx = x
        
        isclick = true
        local p0 = skinBg:convertToNodeSpace(ccp(x, y))
        for _, icon in ipairs(headIcons) do
            --playAnimTouchBegin(headIcons[_])
            last_touch_sprite = headIcons[_]
        end
        return true 
    end

    local function onTouchMoved(x, y)
        local p0 = skinBg:convertToNodeSpace(ccp(touchbeginx, y))
        local p1 = skinBg:convertToNodeSpace(ccp(x, y))
        if isclick and math.abs(p1.x-p0.x) > 15  then
            isclick = false
            if last_touch_sprite and not tolua.isnull(last_touch_sprite) then
                --playAnimTouchEnd(last_touch_sprite)
                last_touch_sprite = nil
            end
            if Scroll:boundingBox():containsPoint(p1) then
                if p1.x - p0.x >= 15 then
                    moveRight()
                end
                if p0.x - p1.x >= 15 then
                    moveLeft()
                end
            end
        end
    end

    local function onTouchEnd(x, y)
        if isclick then
            if last_touch_sprite and not tolua.isnull(last_touch_sprite) then
                --playAnimTouchEnd(last_touch_sprite)
                last_touch_sprite = nil
            end 

            local p0 = skinBg:convertToNodeSpace(ccp(x, y))
            for ii=1,#headIcons do
                if headIcons[ii]:boundingBox():containsPoint(p0) then
                    audio.play(audio.button)
                    if ii == selectPos+1 then
                        moveLeft()
                        return
                    end
                    if ii == selectPos-1 then
                        moveRight()
                        return
                    end
                    local skindata = {id = cfghero[heroData.id].skinId[ii], num = 1}
                    local tipsEquip = require("ui.tips.equip").createForSkin(skindata, function()
                        superlayer:addChild(require("ui.skin.preview").create(skindata.id, i18n.equip[skindata.id].name), 10000)
                        superlayer:removeChildByTag(101)
                        --if layer and not tolua.isnull(layer) then
                        --    layer:removeFromParentAndCleanup(true)
                        --end
                    end)
                    superlayer:addChild(tipsEquip, 10000, 101)
                end
            end
        end
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

    skinBg:registerScriptTouchHandler(onTouch)
    skinBg:setTouchEnabled(true)

    return layer
end

return skin
