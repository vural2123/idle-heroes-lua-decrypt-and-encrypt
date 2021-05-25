local ui = {}

require "common.func"

local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local audio = require "res.audio"
local particle = require "res.particle"
local i18n = require "res.i18n"
local net = require "net.netClient"
local player = require "data.player"
local bag = require "data.bag"
local friend = require "data.friend"
local friendboss = require "data.friendboss"
local cfgfriendstage = require "config.friendstage"
local cfgmonster = require "config.monster"
local reward = require "ui.reward"
local tipsequip = require "ui.tips.equip"
local tipsitem = require "ui.tips.item"
local selecthero = require "ui.selecthero.main"

local TAB = {
    LIST = 1,
    FIND = 2,
    APPL = 3,
    NPC  = 4,
}
local currentTab = TAB.LIST
local titles = {
    [TAB.LIST] = i18n.global.friend_friend_list.global,
    [TAB.FIND] = i18n.global.friend_friend_apply.global,
    [TAB.APPL] = i18n.global.friend_apply_list.global,
    [TAB.NPC] = i18n.global.friend_apply_list.global,
}

local frdBoss = {}

local function createPopupPieceBatchSummonResult(type, id, count)
    local params = {}
    params.title = i18n.global.reward_will_get.string
    params.btn_count = 0

    local dialog = require("ui.dialog").create(params) 

    local back = img.createLogin9Sprite(img.login.button_9_small_gold)
    back:setPreferredSize(CCSize(153, 50))
    local comfirlab = lbl.createFont1(22, i18n.global.summon_comfirm.string, lbl.buttonColor)
    comfirlab:setPosition(CCPoint(back:getContentSize().width/2,
                                    back:getContentSize().height/2))
    back:addChild(comfirlab)
    local backBtn = SpineMenuItem:create(json.ui.button, back)
    backBtn:setPosition(CCPoint(dialog.board:getContentSize().width/2, 80))
    local menu = CCMenu:createWithItem(backBtn)
    menu:setPosition(0, 0)
    dialog.board:addChild(menu)

    dialog.board.tipsTag = false
    if type == "item" then
        local item = img.createItem(id, count)
        itemBtn = SpineMenuItem:create(json.ui.button, item)
        itemBtn:setScale(0.85)
        itemBtn:setPosition(dialog.board:getContentSize().width/2, 185)
        local iconMenu = CCMenu:createWithItem(itemBtn)
        iconMenu:setPosition(0, 0)
        dialog.board:addChild(iconMenu)

        itemBtn:registerScriptTapHandler(function()
            audio.play(audio.button)
            if dialog.board.tipsTag == false then
                dialog.board.tipsTag = true
                tips = tipsitem.createForShow({id = id, num = count})
                dialog:addChild(tips, 200)
                tips.setClickBlankHandler(function()
                    tips:removeFromParent()
                    dialog.board.tipsTag = false
                end)
            end
        end)
    else
        local equip = img.createEquip(id, count)
        equipBtn = SpineMenuItem:create(json.ui.button, equip)
        equipBtn:setScale(0.85)
        equipBtn:setPosition(dialog.board:getContentSize().width/2, 185)
        local iconMenu = CCMenu:createWithItem(equipBtn)
        iconMenu:setPosition(0, 0)
        dialog.board:addChild(iconMenu)

        equipBtn:registerScriptTapHandler(function()
            audio.play(audio.button)
            if dialog.board.tipsTag == false then
                dialog.board.tipsTag = true
                tips = tipsequip.createForShow({id = id})
                dialog:addChild(tips, 200)
                tips.setClickBlankHandler(function()
                    tips:removeFromParent()
                    dialog.board.tipsTag = false
                end)
            end
        end)
    end
    backBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        dialog:removeFromParentAndCleanup()
    end)
    return dialog
end

function ui.create(uiParams)
    local layer = CCLayerColor:create(ccc4(0,0,0,POPUP_DARK_OPACITY))
    
    local borders = {}
    local icons = {}

    local LIMIT_FRIEND = 30
    local showFriends = nil

    currentTab = TAB.LIST
    
    if uiParams and uiParams.from_layer == "frdboss_self" then
        currentTab = TAB.NPC
    end
    -- board
    local board_w = 642+40
    local board_h = 515

    local board = img.createUI9Sprite(img.ui.dialog_1)
    board:setPreferredSize(CCSizeMake(board_w, board_h))
    board:setScale(view.minScale)
    board:setPosition(view.physical.w/2, view.physical.h/2)
    layer:addChild(board)

    -- anim
    board:setScale(0.5*view.minScale)
    board:runAction(CCScaleTo:create(0.15, 1*view.minScale, 1*view.minScale))

    local bottom = img.createUI9Sprite(img.ui.bag_btn_inner_bg)
    bottom:setPreferredSize(CCSizeMake(596+40, 422))
    bottom:setAnchorPoint(0, 0)
    bottom:setPosition(CCPoint(184-161, 545-516))
    board:addChild(bottom)

    -- list tab
    local listTab0 = img.createUISprite(img.ui.friends_tab_list_0)
    local listTab1 = img.createUISprite(img.ui.friends_tab_list_1)
    
    local listTab = CCMenuItemSprite:create(listTab0 ,nil ,listTab1)
    listTab:setAnchorPoint(0, 0)
    listTab:setPosition(CCPoint(746-148+57, 545 - 216))
    listTab:setEnabled(currentTab ~= TAB.LIST)
    --addRedDot(listTab, {
    --    px=listTab:getContentSize().width-15,
    --    py=listTab:getContentSize().height-15,
    --})
    --delRedDot(listTab)

    local listMenu = CCMenu:createWithItem(listTab)
    listMenu:setPosition(0 ,0)
    board:addChild(listMenu, 3)

    -- find tab
    local findTab0 = img.createUISprite(img.ui.friends_tab_query_0)
    local findTab1 = img.createUISprite(img.ui.friends_tab_query_1)
    
    local findTab = CCMenuItemSprite:create(findTab0 ,nil ,findTab1)
    findTab:setAnchorPoint(0, 0)
    findTab:setPosition(CCPoint(746-148+57, 545 - 308))
    findTab:setEnabled(currentTab ~= TAB.FIND)
    local findMenu = CCMenu:createWithItem(findTab)
    findMenu:setPosition(0 ,0)
    board:addChild(findMenu, 3)

    -- find tab
    local applyTab0 = img.createUISprite(img.ui.friends_tab_req_0)
    local applyTab1 = img.createUISprite(img.ui.friends_tab_req_1)
    
    local applyTab = CCMenuItemSprite:create(applyTab0 ,nil ,applyTab1)
    applyTab:setAnchorPoint(0, 0)
    applyTab:setPosition(CCPoint(746-148+57, 545 - 400))
    applyTab:setEnabled(currentTab ~= TAB.APPL)
    --addRedDot(applyTab, {
    --    px=applyTab:getContentSize().width-15,
    --    py=applyTab:getContentSize().height-15,
    --})
    --delRedDot(applyTab)
    local applyMenu = CCMenu:createWithItem(applyTab)
    applyMenu:setPosition(0 ,0)
    board:addChild(applyMenu, 3)

    -- FIND ID Edit Box
    local inputBg = img.createUI9Sprite(img.ui.input_box)
    local inputFind = CCEditBox:create(CCSizeMake(350*view.minScale, 38*view.minScale), inputBg)
    inputFind:setInputFlag(kEditBoxInputFlagInitialCapsSentence)
    inputFind:setReturnType(kKeyboardReturnTypeDone)
    inputFind:setMaxLength(50)
    inputFind:setFont("", 16*view.minScale)
    inputFind:setPlaceHolder(i18n.global.friend_find_id.string)
    inputFind:setFontColor(ccc3(0x80, 0x7c, 0x70))
    inputFind:setFontSize(20)
    inputFind:setAnchorPoint(0, 0)
    inputFind:setPosition(scalep(217, 576-156))
    layer:addChild(inputFind)
    

    -- find tab
    local npcTab0 = img.createUISprite(img.ui.friends_tab_help_0)
    local npcTab1 = img.createUISprite(img.ui.friends_tab_help_1)
    
    local npcTab = CCMenuItemSprite:create(npcTab0 ,nil ,npcTab1)
    npcTab:setAnchorPoint(0, 0)
    npcTab:setPosition(CCPoint(746-148+57, 545 - 492))
    npcTab:setEnabled(currentTab ~= TAB.NPC)
    addRedDot(npcTab, {
        px=npcTab:getContentSize().width-15,
        py=npcTab:getContentSize().height-15,
    })
    delRedDot(npcTab)
    local npcMenu = CCMenu:createWithItem(npcTab)
    npcMenu:setPosition(0 ,0)
    board:addChild(npcMenu, 3)

    local function init(callBack)
        -- sync
        --local param = {}
        --param.sid = player.sid
        --addWaitNet()
        --net:frd_sync(param, function(__data)
        --    delWaitNet()
        --    --tbl2string(__data)
        --    friend.init(__data)    
        --    if callBack then
                callBack()
            --end
        --end)
    end
    
    local enegyToast = img.createUI9Sprite(img.ui.tips_bg)
    enegyToast:setPreferredSize(CCSizeMake(410, 68))
    enegyToast:setPosition(board:getContentSize().width/2, 485)
    enegyToast:setVisible(false)
    board:addChild(enegyToast, 1000)

    frdBoss.showenegyTimeLab = lbl.createFont2(16, "", ccc3(0xa5, 0xfd, 0x47))
    frdBoss.showenegyTimeLab:setAnchorPoint(0, 0.5)
    frdBoss.showenegyTimeLab:setPosition(enegyToast:getContentSize().width/2+30, enegyToast:getContentSize().height/2)
    enegyToast:addChild(frdBoss.showenegyTimeLab)

    frdBoss.tlrecoverlab = lbl.createFont1(16, i18n.global.friendboss_enegy_recovery.string, ccc3(255, 246, 223))
    frdBoss.tlrecoverlab:setAnchorPoint(1, 0.5)
    frdBoss.tlrecoverlab:setPosition(CCPoint(frdBoss.showenegyTimeLab:boundingBox():getMinX() - 10, enegyToast:getContentSize().height/2))
    enegyToast:addChild(frdBoss.tlrecoverlab)

    frdBoss.enegyFull = lbl.createMixFont1(16, i18n.global.friendboss_enegy_full.string, ccc3(255, 246, 223))
    frdBoss.enegyFull:setPosition(enegyToast:getContentSize().width/2, enegyToast:getContentSize().height/2)
    frdBoss.enegyFull:setVisible(false)
    enegyToast:addChild(frdBoss.enegyFull)

    local enegyFlag = false
    local enegyNum = friendboss.enegy
    local function onUpdate(ticks)
        if currentTab == TAB.LIST then
            local tmp_list_msg = friend.fetchListMsg()
            local tmp_loved_msg = friend.fetchLovedMsg()
            if enegyFlag == true then
                if friendboss.tcd then
                    cd = math.max(0, friendboss.tcd + friendboss.pull_tcd_time - os.time())
                    if cd > 0 then
                        local timeLab = string.format("%02d:%02d:%02d",math.floor(cd/3600),math.floor((cd%3600)/60),math.floor(cd%60))
                        frdBoss.showenegyTimeLab:setString(timeLab)
                    else
                        if friendboss.enegy <= 9 then
                            friendboss.tcd = friendboss.tcd + 2*3600
                            friendboss.addEnegy()
                            frdBoss.enegylab:setString(string.format("%d/10", friendboss.enegy))

                            if friendboss.tcd == nil then
                                frdBoss.showenegyTimeLab:setVisible(false)
                                frdBoss.tlrecoverlab:setVisible(false)
                                frdBoss.enegyFull:setVisible(true)
                            end
                        else
                            frdBoss.showenegyTimeLab:setVisible(false)
                            frdBoss.tlrecoverlab:setVisible(false)
                            frdBoss.enegyFull:setVisible(true)
                        end
                    end
                else
                    frdBoss.showenegyTimeLab:setVisible(false)
                    frdBoss.tlrecoverlab:setVisible(false)
                    frdBoss.enegyFull:setVisible(true)
                end
            end
            if enegyNum ~= friendboss.enegy and frdBoss.enegylab then
                enegyNum = friendboss.enegy
                frdBoss.enegylab:setString(string.format("%d/10", friendboss.enegy))
            end
        elseif currentTab == TAB.APPL then
            local tmp_apply_msg = friend.fetchApplyMsg()
        elseif currentTab == TAB.NPC then  
            if friendboss.scd and friendboss.pull_scd_time and frdBoss.showTimeLab and not tolua.isnull(frdBoss.showTimeLab) then
                cd = math.max(0, friendboss.scd + friendboss.pull_scd_time - os.time())
                if cd > 0 then
                    local timeLab = string.format("%02d:%02d:%02d",math.floor(cd/3600),math.floor((cd%3600)/60),math.floor(cd%60))
                    frdBoss.showTimeLab:setString(timeLab)
                else
                    frdBoss.recoverlab:setVisible(false)
                    frdBoss.showTimeLab:setVisible(false)
                    frdBoss.searchBtn:setEnabled(true)
                    clearShader(frdBoss.searchBtn, true)
                end
            end
        end
        -- check reddot
        --if friend.showListRedDot() then
        --    addRedDot(listTab, {
        --        px=listTab:getContentSize().width-15,
        --        py=listTab:getContentSize().height-15,
        --    })
        --else
        --    delRedDot(listTab)
        --end
        if friendboss.showBossRedDot() then
            addRedDot(npcTab, {
                px=npcTab:getContentSize().width-15,
                py=npcTab:getContentSize().height-15,
            })
        else
            delRedDot(npcTab)
        end

    end

    -- container 
    local container_w = 730+56-226
    local container_h = 506-44
    local container = CCSprite:create()
    container:setContentSize(CCSizeMake(container_w, container_h))
    container:setPosition(CCPoint(42+container_w/2, 38+container_h/2))
    board:addChild(container, 2)
    --drawBoundingbox(board, container)


    layer:scheduleUpdateWithPriorityLua(onUpdate, 0)

    local VIEW_WIDTH = 556+40
    local VIEW_HEIGHT = 340
    local BORDER_HEIGHT = 88
    local MARGIN_TOP = 4
    local GAP_VERTICAL = 6


    local scroll = CCScrollView:create()
    scroll:setDirection(kCCScrollViewDirectionVertical)
    scroll:setAnchorPoint(0,0)
    scroll:setPosition(CCPoint(48, 42))
    scroll:setViewSize(CCSizeMake(VIEW_WIDTH, VIEW_HEIGHT))
    board:addChild(scroll)

    local function initcontainer()
        container:removeAllChildrenWithCleanup(true)
    end

    local function initScroll(num, keepOldPosition)
        if num < 4 then 
            num = 4
        end

        for i,_ in pairs(icons) do
            if icons[i].lvbottom then
                icons[i].lvbottom:removeFromParent()
            end
            if icons[i].name then
                icons[i].name:removeFromParent()
            end
            if icons[i].sendloveMenu then
                icons[i].sendloveMenu:removeFromParent()
            end
            if icons[i].recvloveMenu then
                icons[i].recvloveMenu:removeFromParent()
            end
            if icons[i].applyAgreMenu then
                icons[i].applyAgreMenu:removeFromParent()
            end
            if icons[i].applyNotagreMenu then
                icons[i].applyNotagreMenu:removeFromParent()
            end
            icons[i]:removeFromParent()
            icons[i].sendloveMenu = nil
            icons[i].recvloveMenu = nil
            icons[i].applyAgreMenu = nil
            icons[i].applyNotagreMenu = nil
            icons[i].lvbottom = nil
            icons[i].name = nil
            icons[i] = nil
        end
        
        local height = MARGIN_TOP + BORDER_HEIGHT*num + GAP_VERTICAL*(num-1) - BORDER_HEIGHT/2.5 + 20
        local contentOffsetY = scroll:getContentOffset().y
        contentOffsetY = VIEW_HEIGHT-height
        if not keepOldPosition then
            contentOffsetY = VIEW_HEIGHT-height
        elseif contentOffsetY > 0 then
            contentOffsetY = 0
        elseif contentOffsetY < VIEW_HEIGHT - height then
            contentOffsetY = VIEW_HEIGHT - height
        end
        if currentTab == TAB.FIND then
            contentOffsetY = contentOffsetY - 35
            scroll:setViewSize(CCSizeMake(VIEW_WIDTH, VIEW_HEIGHT-35))
        else
            scroll:setViewSize(CCSizeMake(VIEW_WIDTH, VIEW_HEIGHT))
        end
        scroll:setContentSize(CCSize(VIEW_WIDTH, height))
        scroll:setContentOffset(ccp(0, contentOffsetY))
    end

    local function getPositionY(pos)
        local y0 = scroll:getContentSize().height - BORDER_HEIGHT
        y = y0
        y = y - (pos-1) * (BORDER_HEIGHT+MARGIN_TOP)
        return y
    end

    local function initBorder(num)
        for i = 1, math.max(#borders, num) do
            if borders[i] ~= nil and i > num then
                borders[i]:removeFromParent()
                borders[i] = nil
            elseif borders[i] == nil and i <= num then
                borders[i] = img.createUI9Sprite(img.ui.botton_fram_2)
                borders[i]:setPreferredSize(CCSizeMake(482+56+40, 88))
                borders[i]:setAnchorPoint(CCPoint(0, 0))
                scroll:getContainer():addChild(borders[i])
            end
            if borders[i] ~= nil then
                local y = getPositionY(i)
                borders[i]:setPosition(4, y)
            end
        end
    end

    local function noFriends()
        --local nofriends = img.createUISprite(img.ui.mail_icon_nomail)
        --nofriends:setPosition(CCPoint(container_w/2, container_h/2+20))
        --container:addChild(nofriends)
        --local nofriendslab = lbl.createMixFont1(18, i18n.global.friend_not_have_frd.string, ccc3(0x51, 0x34, 0x1c))
        --nofriendslab:setPosition(CCPoint(container_w/2, container_h/2-50))
        --container:addChild(nofriendslab)
        local empty = require "ui.empty"
        local emptyBox = empty.create({text = i18n.global.friend_not_have_frd.string})
        emptyBox:setPosition(container_w/2, container_w/2-65)            
        container:addChild(emptyBox)
    end

    local enegyBottom = nil
    local enegyIcon = nil
    local function showList()
        initcontainer()

        local zhezhaodown = img.createUI9Sprite(img.ui.friends_zhezhao)
        zhezhaodown:setPreferredSize(CCSize(616, 33))
        zhezhaodown:setAnchorPoint(0.5, 0)
        zhezhaodown:setPosition(board_w/2-42, 2)
        container:addChild(zhezhaodown)

        -- title
        local title = lbl.createFont1(24, i18n.global.friend_friend_list.string, ccc3(0xe6, 0xd0, 0xae))
        title:setPosition(CCPoint(container:getContentSize().width/2-20, 506-58))
        container:addChild(title, 1)
        local title_shadowD = lbl.createFont1(24, i18n.global.friend_friend_list.string, ccc3(0x59, 0x30, 0x1b))
        title_shadowD:setPosition(CCPoint(container:getContentSize().width/2-20, 506-60))
        container:addChild(title_shadowD)

        -- 爱心
        local valueBottom = img.createUI9Sprite(img.ui.main_coin_bg)
        valueBottom:setPreferredSize(CCSizeMake(138, 40))
        valueBottom:setPosition(CCPoint(320-230, 506-135))
        container:addChild(valueBottom)

        local lovelab = lbl.createFont2(16, string.format("%d", bag.items.find(ITEM_ID_LOVE).num), ccc3(0xf8, 0xf2, 0xe2))
        lovelab:setPosition(CCPoint(valueBottom:getContentSize().width/2, 
                                    valueBottom:getContentSize().height/2+2))
        valueBottom:addChild(lovelab)

        local friendGift = img.createItemIcon2(ITEM_ID_LOVE)
        friendGift:setPosition(5, valueBottom:getContentSize().height/2+2)
        valueBottom:addChild(friendGift)
        
        -- 体力
        enegyBottom = img.createUI9Sprite(img.ui.main_coin_bg)
        enegyBottom:setPreferredSize(CCSizeMake(138, 40))
        enegyBottom:setPosition(CCPoint(480-230, 506-135))
        container:addChild(enegyBottom)

        enegyNum = friendboss.enegy
        frdBoss.enegylab = lbl.createFont2(16, string.format("%d/10", enegyNum), ccc3(0xf8, 0xf2, 0xe2))
        frdBoss.enegylab:setPosition(CCPoint(enegyBottom:getContentSize().width/2, 
                                    enegyBottom:getContentSize().height/2+2))
        enegyBottom:addChild(frdBoss.enegylab)

        enegyIcon = img.createUISprite(img.ui.friends_enegy)
        --local enegyBtn = SpineMenuItem:create(json.ui.button, enegyIcon)
        enegyIcon:setPosition(8, enegyBottom:getContentSize().height/2+4)
        enegyBottom:addChild(enegyIcon)

        --local enegyMenu = CCMenu:createWithItem(enegyBtn)
        --enegyMenu:setPosition(0, 0)
        --enegyBottom:addChild(enegyMenu)

        --enegyBtn:registerScriptTapHandler(function()
        --    audio.play(audio.button)
        
        --end)
        initScroll(0)
        initBorder(0)
        if friend.friends.friendsList == nil or #friend.friends.friendsList == 0 then
            title:setPosition(CCPoint(container:getContentSize().width/2, 506-58))
            title_shadowD:setPosition(CCPoint(container:getContentSize().width/2, 506-60))
            noFriends()
            return
        end
        
        -- 所有未领取爱心的好友uid
        local recvallUids = {}
        -- 所有还没有发送爱心的好友uid
        local sendallUids = {}
        
        local friendsLimitlab = lbl.createFont2(22, string.format("%d/%d", #friend.friends.friendsList, LIMIT_FRIEND))
        friendsLimitlab:setAnchorPoint(CCPoint(0, 0.5))
        friendsLimitlab:setPosition(CCPoint(title:boundingBox():getMaxX() + 10, 506-58))
        container:addChild(friendsLimitlab)

        initScroll(#friend.friends.friendsList, true)
        initBorder(#friend.friends.friendsList)

        
        for i,obj in ipairs(friend.friends.friendsList) do
            if obj.flag == 2 or obj.flag == 3  then
                recvallUids[#recvallUids+1] = obj.uid                
            end
            if obj.flag == 0 or obj.flag == 2 or obj.flag == 4 or obj.flag == 6 then
                sendallUids[#sendallUids+1] = obj.uid
            end
            
            icons[i] = img.createPlayerHead(obj.logo)
            icons[i].frdBtn = SpineMenuItem:create(json.ui.button, icons[i])
            icons[i].frdBtn:setScale(0.7)
            icons[i].frdBtn:setAnchorPoint(CCPoint(0, 0.5))
            icons[i].frdBtn:setPosition(CCPoint(15, 46))
            local frdMenu = CCMenu:createWithItem(icons[i].frdBtn)
            frdMenu:setPosition(0, 0)
            borders[i]:addChild(frdMenu)

            icons[i].frdBtn:registerScriptTapHandler(function()
                audio.play(audio.button)
                local params = {}
                params.logo = obj.logo
                params.uid = obj.uid
                params.name = obj.name
                params.frd = obj
                layer:addChild((require"ui.tips.player1").create(params, "del", showFriends), 100)
            end)
            
            icons[i].lvbottom = img.createUISprite(img.ui.main_lv_bg)
            icons[i].lvbottom:setPosition(CCPoint(107, 46))
            borders[i]:addChild(icons[i].lvbottom)
            
            local lvlab = lbl.createFont1(14, string.format("%d", obj.lv), ccc3(255, 246, 223))
            lvlab:setPosition(CCPoint(icons[i].lvbottom:getContentSize().width/2, 
                                            icons[i].lvbottom:getContentSize().height/2))
            icons[i].lvbottom:addChild(lvlab)

            icons[i].name = lbl.create({kind="ttf", size=18, text=obj.name, 
                                     color=ccc3(0x51, 0x27, 0x12)})
            icons[i].name:setAnchorPoint(CCPoint(0, 0.5))
            icons[i].name:setPosition(CCPoint(137, 58))
            borders[i]:addChild(icons[i].name)

            -- status
            if obj.last then
                local last = obj.last
                if obj.last ~= 0 then 
                    last = os.time()-obj.last
                end
                local lbl_mem_status = lbl.createFont1(14, friend.onlineStatus(last), ccc3(0x8a, 0x60, 0x4c))
                lbl_mem_status:setAnchorPoint(CCPoint(0, 0.5))
                lbl_mem_status:setPosition(CCPoint(137, 34))
                borders[i]:addChild(lbl_mem_status)
            end

            if obj.boss and obj.boss ~= 0 and player.lv() >= 36 then
				local bossParam = { id = obj.boss }
				if obj.boss < 0 then
					bossParam.id = -obj.boss
					bossParam.lv = "+"
				end
				
                local bossIcon = img.createHeroHeadByParam(bossParam) --img.createUISprite(img.ui.friends_boss_btn)
				bossIcon:setScale(0.6)
				
                icons[i].bossBtn = SpineMenuItem:create(json.ui.button, bossIcon)
                icons[i].bossBtn:setPosition(CCPoint(560-245, 252-208))
                icons[i].bossMenu = CCMenu:createWithItem(icons[i].bossBtn)
                icons[i].bossMenu:setPosition(CCPoint(0, 0))
                borders[i]:addChild(icons[i].bossMenu)

                icons[i].bossBtn:registerScriptTapHandler(function()
                    audio.play(audio.button)
                    local enemyline = require "ui.friends.enemyline"
                    layer:addChild(enemyline.create(obj.uid))
                end)
            end
            
            -- 好友切磋
            local fight = img.createUISprite(img.ui.friends_fight)
            icons[i].fightBtn = SpineMenuItem:create(json.ui.button, fight)
            icons[i].fightBtn:setPosition(CCPoint(670-282, 252-208))
            icons[i].fightMenu = CCMenu:createWithItem(icons[i].fightBtn)
            icons[i].fightMenu:setPosition(CCPoint(0, 0))
            borders[i]:addChild(icons[i].fightMenu)

            icons[i].fightBtn:registerScriptTapHandler(function()
                audio.play(audio.button)
                tbl2string(obj)
                layer:addChild(require("ui.selecthero.main").create({type = "frdpk", info = obj}))
            end)

            local bottom1 = img.createUISprite(img.ui.friends_circle_botton)

            json.load(json.ui.haoyou_heart)
            local aniheartLz = DHSkeletonAnimation:createWithKey(json.ui.haoyou_heart)
            aniheartLz:playAnimation("loop", -1)
            --aniheartLz:registerAnimation("end")
            --aniSummonLz:setScale(view.minScale)
            aniheartLz:scheduleUpdateLua()
            aniheartLz:setPosition(bottom1:getContentSize().width/2, bottom1:getContentSize().height/2)
            bottom1:addChild(aniheartLz)
            icons[i].aniheartLz = aniheartLz
            
            local recvlove1 = img.createItemIcon2(ITEM_ID_LOVE)
            local recvlove2 = img.createItemIcon2(ITEM_ID_LOVE)
            --recvlove:setPosition(CCPoint(bottom1:getContentSize().width/2,
            --                                 bottom1:getContentSize().height/2))
            --bottom1:addChild(recvlove)
            
            icons[i].aniheartLz:addChildFollowSlot("code_heart2", recvlove1)
            icons[i].aniheartLz:addChildFollowSlot("code_heart", recvlove2)

            icons[i].recvloveBtn = SpineMenuItem:create(json.ui.button, bottom1)
            icons[i].recvloveBtn:setPosition(CCPoint(582+115-233, 252-208))
            if obj.flag >= 4 then
                setShader(icons[i].recvloveBtn, SHADER_GRAY, true)
                icons[i].aniheartLz:stopAnimation()
                icons[i].recvloveBtn:setEnabled(false)
            elseif obj.flag == 0 or obj.flag == 1 then
                icons[i].recvloveBtn:setVisible(false)
            end

            icons[i].recvloveMenu = CCMenu:createWithItem(icons[i].recvloveBtn)
            icons[i].recvloveMenu:setPosition(CCPoint(0, 0))
            borders[i]:addChild(icons[i].recvloveMenu)
            
            local bottom2 = img.createUISprite(img.ui.friends_circle_botton)
            
            local sendlove = img.createUISprite(img.ui.friends_gift_1)
            sendlove:setPosition(CCPoint(bottom2:getContentSize().width/2,
                                                bottom2:getContentSize().height/2))
            bottom2:addChild(sendlove)
            icons[i].sendloveBtn = SpineMenuItem:create(json.ui.button, bottom2)
            icons[i].sendloveBtn:setPosition(CCPoint(670+96-238, 252-208))
            icons[i].sendloveMenu = CCMenu:createWithItem(icons[i].sendloveBtn)
            icons[i].sendloveMenu:setPosition(CCPoint(0, 0))
            borders[i]:addChild(icons[i].sendloveMenu)
            if obj.flag == 1 or obj.flag == 3 or obj.flag == 5 or obj.flag == 7 then
                setShader(icons[i].sendloveBtn, SHADER_GRAY, true)
                icons[i].sendloveBtn:setEnabled(false)
            end

            icons[i].recvloveBtn:registerScriptTapHandler(function()
                if friend.love >= LIMIT_FRIEND then
                    showToast(string.format(i18n.global.friend_love_limit.string, LIMIT_FRIEND))
                    return 
                end 

                local pbbag = {}
                pbbag.items = {}

                local param = {}
                param.sid = player.sid
                local uids = {}

                uids[#uids+1] = obj.uid
                param.recv = uids
                addWaitNet()
                
                net:frd_love(param, function(__data)
                    delWaitNet()
                    tbl2string(__data)
                    if __data.status == -1 then
                        showToast(i18n.global.friend_not_friends.string)
                        return
                    end
                    if __data.status == -2 then
                        showToast(string.format(i18n.global.friend_love_limit.string, LIMIT_FRIEND))
                        return
                    end
                    if __data.status < -1 then
                        showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                        return
                    end
                    obj.flag = obj.flag + 4
                    for ii=1,#recvallUids do
                        if recvallUids[ii] == obj.uid then
                            table.remove(recvallUids, ii)
                            break
                        end
                    end
                    bag.items.add({id = ITEM_ID_LOVE, num = __data.status})
                    lovelab:setString(string.format("%d", bag.items.find(ITEM_ID_LOVE).num))
                    friend.love = friend.love + __data.status
                    setShader(icons[i].recvloveBtn, SHADER_GRAY, true)
                    icons[i].recvloveBtn:setEnabled(false)
                    
                    --icons[i].aniheartLz:playAnimation("end")
                    icons[i].aniheartLz:stopAnimation()

                    pbbag.items[#pbbag.items+1] = {id = ITEM_ID_LOVE, num = __data.status}
                    local rewardlayer = reward.createFloating(pbbag, 1000)
                    layer:addChild(rewardlayer, 1000)

                    --showToast(i18n.global.friend_recv_seccese.string)
                    --loopparcl = particle.create("haoyou_heart_loop")
                    --aniheartLz:addChildFollowSlot("code_heart2", loopparcl) 
                    
                    --endparcl = particle.create("haoyou_heart_loop")
                    --aniheartLz:addChildFollowSlot("code_heart", endparcl) 
                    
                    --local function onpartUpdate(dt)

                    --    --loopparcl:
                    --end

                    --icons[i]:scheduleUpdateWithPriorityLua(onpartUpdate, 0)
                end)
                audio.play(audio.get_heart)
            end)
            icons[i].sendloveBtn:registerScriptTapHandler(function()
                audio.play(audio.button)

                icons[i].sendloveBtn:setEnabled(false)
                setShader(icons[i].sendloveBtn, SHADER_GRAY, true)

                local param = {}
                param.sid = player.sid
                param.send = obj.uid

                addWaitNet()
                net:frd_love(param, function(__data)
                    delWaitNet()
                    tbl2string(__data)
                    if __data.status == -2 then
                        return
                    end
                    if __data.status == -1 then
                        showToast(i18n.global.friend_not_friends.string)
                        return
                    end
                    if __data.status ~= 0 then
                        showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                        return
                    end
                    if friend.friends.friendsList[i] then
                        friend.friends.friendsList[i].flag = friend.friends.friendsList[i].flag + 1
                    end
                    for ii=1,#sendallUids do
                        if sendallUids[ii] == obj.uid then
                            table.remove(sendallUids, ii)
                            break
                        end
                    end
                    local task = require "data.task"
                    task.increment(task.TaskType.FRIEND_HEART)
                    showToast(i18n.global.friend_send_seccese.string)
                end)
            end)
        end

        -- 一键领取和发送爱心
        local recvallSprite = img.createLogin9Sprite(img.login.button_9_small_gold)
        recvallSprite:setPreferredSize(CCSizeMake(208, 42))

        local recvallBtn = SpineMenuItem:create(json.ui.button, recvallSprite)
        recvallBtn:setAnchorPoint(0, 0)
        recvallBtn:setPosition(CCPoint(510+56-186, 506-155))
        local receiptallMenu = CCMenu:createWithItem(recvallBtn)
        receiptallMenu:setPosition(0,0)
        container:addChild(receiptallMenu)
   
        local recvallLab = lbl.createFont1(16, i18n.global.friend_batch_receipt.string, ccc3(0x73, 0x3b, 0x05))
        recvallLab:setPosition(CCPoint(recvallBtn:getContentSize().width/2, recvallBtn:getContentSize().height/2+1))
        recvallSprite:addChild(recvallLab)

        recvallBtn:registerScriptTapHandler(function()
            if #recvallUids == 0 and #sendallUids == 0 then
                showToast(i18n.global.friend_no_sendandrec_love.string)
                return
            end
            if friend.love + #recvallUids > LIMIT_FRIEND and #sendallUids == 0 then
                showToast(string.format(i18n.global.friend_love_limit.string, LIMIT_FRIEND))
                return 
            end

            local function quicksend()
                local pbbag = {}
                pbbag.items = {}

                local param = {}
                param.sid = player.sid
                param.send = 10000

                addWaitNet()
                net:frd_love(param, function(__data)
                    delWaitNet()
                    tbl2string(__data)
                    if __data.status ~= 0 then
                        showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                        return
                    end
                    local sendlovecount = 0
                    for ii,obj in ipairs(friend.friends.friendsList) do
                        if obj.flag == 0 or obj.flag == 2 or obj.flag == 4 or obj.flag == 6 then
                            friend.friends.friendsList[ii].flag = friend.friends.friendsList[ii].flag + 1
                            sendlovecount = sendlovecount + 1
                            --assert(icons[ii], "ii:" .. ii .. "#icons" .. #icons)
                            if icons[ii] and icons[ii].sendloveBtn and not tolua.isnull(icons[ii].sendloveBtn) then
                                setShader(icons[ii].sendloveBtn, SHADER_GRAY, true)
                                icons[ii].sendloveBtn:setEnabled(false)
                            end
                        end 
                    end
                    local task = require "data.task"
                    task.increment(task.TaskType.FRIEND_HEART, sendlovecount)

                    sendallUids = {}
                end)
            end

            if #recvallUids ~= 0 and friend.love + #recvallUids <= LIMIT_FRIEND then
                local pbbag = {}
                pbbag.items = {}

                local param = {}
                param.sid = player.sid
                param.recv = recvallUids

                addWaitNet()
                net:frd_love(param, function(__data)
                    delWaitNet()
                    tbl2string(__data)
                    if __data.status == -1 then
                        showToast(i18n.global.friend_not_friends.string)
                        return
                    end
                    if __data.status == -2 then
                        showToast(string.format(i18n.global.friend_love_limit.string, LIMIT_FRIEND))
                        return
                    end

                    for i,obj in ipairs(friend.friends.friendsList) do
                        if obj.flag == 2 or obj.flag == 3  then
                            friend.friends.friendsList[i].flag = friend.friends.friendsList[i].flag + 4
                            if icons[i] and icons[i].recvloveBtn then
                                setShader(icons[i].recvloveBtn, SHADER_GRAY, true)
                                icons[i].aniheartLz:stopAnimation()
                                icons[i].recvloveBtn:setEnabled(false)
                            end
                        end 
                    end

                    bag.items.add({id = ITEM_ID_LOVE, num = __data.status})
                    lovelab:setString(string.format("%d", bag.items.find(ITEM_ID_LOVE).num))

                    pbbag.items[#pbbag.items+1] = {id = ITEM_ID_LOVE, num = __data.status}
                    local rewardlayer = reward.createFloating(pbbag, 1000)
                    layer:addChild(rewardlayer, 1000)

                    recvallUids = {}
                    if #sendallUids ~= 0 then
                        quicksend()
                    end
                end)
            else
                if #sendallUids ~= 0 then
                    quicksend()
                end
            end
            audio.play(audio.get_heart)
        end)
    end
    
    local function showFind()
        initcontainer()
        initScroll(0)
        initBorder(0)
        if friend.friends.friendsRecmd  then
            initScroll(#friend.friends.friendsRecmd, true)
            initBorder(#friend.friends.friendsRecmd)
            for i,obj in ipairs(friend.friends.friendsRecmd) do
                icons[i] = img.createPlayerHead(obj.logo)
                icons[i].frdBtn = SpineMenuItem:create(json.ui.button, icons[i])
                icons[i].frdBtn:setScale(0.7)
                icons[i].frdBtn:setAnchorPoint(CCPoint(0, 0.5))
                icons[i].frdBtn:setPosition(CCPoint(15, 46))
                local frdMenu = CCMenu:createWithItem(icons[i].frdBtn)
                frdMenu:setPosition(0, 0)
                borders[i]:addChild(frdMenu)

                icons[i].frdBtn:registerScriptTapHandler(function()
                    audio.play(audio.button)
                    local params = {}
                    params.logo = obj.logo
                    params.uid = obj.uid
                    params.name = obj.name
                    params.frd = obj
                    layer:addChild((require"ui.tips.player1").create(params, "add", showFriends), 100)
                end)

                local lvbottom = img.createUISprite(img.ui.main_lv_bg)
                lvbottom:setPosition(CCPoint(107, 46))
                borders[i]:addChild(lvbottom)
                
                local lvlab = lbl.createFont1(14, string.format("%d", obj.lv), ccc3(255, 246, 223))
                lvlab:setPosition(CCPoint(lvbottom:getContentSize().width/2, lvbottom:getContentSize().height/2))
                lvbottom:addChild(lvlab)

                local name = lbl.create({kind="ttf", size=18, text=obj.name, 
                                         color=ccc3(0x51, 0x27, 0x12)})
                name:setAnchorPoint(CCPoint(0, 0.5))
                name:setPosition(CCPoint(137, 46))
                borders[i]:addChild(name)

                local addbtn = img.createLogin9Sprite(img.login.button_9_small_gold)
                addbtn:setPreferredSize(CCSizeMake(100, 42))
                local addlab = lbl.createFont1(16, i18n.global.friend_apply.string, ccc3(0x73, 0x3b, 0x05))
                addlab:setPosition(CCPoint(addbtn:getContentSize().width/2,
                                                 addbtn:getContentSize().height/2+1))
                addbtn:addChild(addlab)
                icons[i].findAddBtn = SpineMenuItem:create(json.ui.button, addbtn)
                icons[i].findAddBtn:setAnchorPoint(0, 0)
                icons[i].findAddBtn:setPosition(CCPoint(514+56-110, 252-228))
                
                local findAddMenu = CCMenu:createWithItem(icons[i].findAddBtn)
                findAddMenu:setPosition(CCPoint(0, 0))
                borders[i]:addChild(findAddMenu)
                
                icons[i].findAddBtn:registerScriptTapHandler(function()
                    audio.play(audio.button)
                    local param = {}
                    param.sid = player.sid
                    param.apply = obj.uid
                    addWaitNet()
                    net:frd_op(param, function(__data)
                        delWaitNet()
                        tbl2string(__data) 
                        if __data.status == -1 then
                            showToast(i18n.global.friend_are_friend.string)
                            return
                        end
                        if __data.status ~= 0 then
                            showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                            return
                        end
                        friend.delFriendsRecmd(obj)
                        showFriends()
                        --setShader(icons[i].findAddBtn, SHADER_GRAY, true) 
                        --icons[i].findAddBtn:setEnabled(false)
                    end)
                end)
            end
        end
        local title = lbl.createFont1(24, i18n.global.friend_friend_apply.string, ccc3(0xe6, 0xd0, 0xae))
        title:setPosition(CCPoint(container:getContentSize().width/2, 506-58))
        container:addChild(title, 1)
        local title_shadowD = lbl.createFont1(24, i18n.global.friend_friend_apply.string, ccc3(0x59, 0x30, 0x1b))
        title_shadowD:setPosition(CCPoint(container:getContentSize().width/2, 506-60))
        container:addChild(title_shadowD)
   
        local recommdlab = lbl.createFont1(16, i18n.global.friend_recommend.string, ccc3(0x49, 0x26, 0x04))
        recommdlab:setAnchorPoint(CCPoint(0, 0.5))
        recommdlab:setPosition(CCPoint(10, 506-181))
        container:addChild(recommdlab)

        -- btn
        local addtoSprite = img.createLogin9Sprite(img.login.button_9_small_gold)
        addtoSprite:setPreferredSize(CCSizeMake(138, 46))

        local addtoBtn = SpineMenuItem:create(json.ui.button, addtoSprite)
        addtoBtn:setAnchorPoint(0, 0)
        addtoBtn:setPosition(CCPoint(580+53-226, 506-160))
        local addtoMenu = CCMenu:createWithItem(addtoBtn)
        addtoMenu:setPosition(0,0)
        container:addChild(addtoMenu)
   
        local addtoLab = lbl.createFont1(16, i18n.global.friend_apply.string, ccc3(0x73, 0x3b, 0x05))
        addtoLab:setPosition(CCPoint(addtoSprite:getContentSize().width/2, addtoSprite:getContentSize().height/2 + 1))
        addtoSprite:addChild(addtoLab)

        addtoBtn:registerScriptTapHandler(function()
            audio.play(audio.button)
            if inputFind:getText() == "" then
                showToast(i18n.global.friend_id_empty.string)
                return
            end
            if #inputFind:getText() ~= 8 then
                showToast(i18n.global.friend_no_id.string)
                return
            end
            if tonumber(inputFind:getText()) == nil then
                showToast(i18n.global.friend_input_id.string)
                return
            end
            if tonumber(inputFind:getText()) == player.uid then
                showToast(i18n.global.friend_not_yourself.string)
                return
            end
            local param = {}
            param.sid = player.sid
            param.apply = tonumber(inputFind:getText())

            addWaitNet()
            net:frd_op(param, function(__data)
                delWaitNet()
                tbl2string(__data) 
                if __data.status == -2 then
                    showToast(i18n.global.friend_no_id.string)
                    return
                end
                if __data.status == -1 then
                    showToast(i18n.global.friend_are_friend.string)
                    return
                end
                if __data.status ~= 0 then
                    showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                    return
                end
                showToast(i18n.global.friend_apply_succese.string)
            end)
        end)
    end

    local function showApply()
        initcontainer()
        initScroll(0)
        initBorder(0) 
        local applyUids = {}
        local requestsNum = 0
        if friend.friends.friendsApply then 
            initScroll(#friend.friends.friendsApply, true)
            initBorder(#friend.friends.friendsApply)
            requestsNum = #friend.friends.friendsApply
            for i,obj in ipairs(friend.friends.friendsApply) do
                applyUids[#applyUids+1] = obj.uid 
                icons[i] = img.createPlayerHead(obj.logo)
                icons[i].frdBtn = SpineMenuItem:create(json.ui.button, icons[i])
                icons[i].frdBtn:setScale(0.7)
                icons[i].frdBtn:setAnchorPoint(CCPoint(0, 0.5))
                icons[i].frdBtn:setPosition(CCPoint(15, 46))
                local frdMenu = CCMenu:createWithItem(icons[i].frdBtn)
                frdMenu:setPosition(0, 0)
                borders[i]:addChild(frdMenu)

                icons[i].frdBtn:registerScriptTapHandler(function()
                    audio.play(audio.button)
                    local params = {}
                    params.logo = obj.logo
                    params.uid = obj.uid
                    params.name = obj.name
                    layer:addChild((require"ui.tips.player1").create(params, "none"), 100)
                end)

                icons[i].lvbottom = img.createUISprite(img.ui.main_lv_bg)
                icons[i].lvbottom:setPosition(CCPoint(107, 46))
                borders[i]:addChild(icons[i].lvbottom)
            
                local lvlab = lbl.createFont1(14, string.format("%d", obj.lv), ccc3(255, 246, 223))
                lvlab:setPosition(CCPoint(icons[i].lvbottom:getContentSize().width/2, 
                                        icons[i].lvbottom:getContentSize().height/2))
                icons[i].lvbottom:addChild(lvlab)

                icons[i].name = lbl.create({kind="ttf", size=18, text=obj.name, 
                                         color=ccc3(0x51, 0x27, 0x12)})
                icons[i].name:setAnchorPoint(CCPoint(0, 0.5))
                icons[i].name:setPosition(CCPoint(137, 46))
                borders[i]:addChild(icons[i].name)

                local tickbtn = img.createLogin9Sprite(img.login.button_9_small_green)
                tickbtn:setPreferredSize(CCSizeMake(90, 42))
                local applyAgre = img.createUISprite(img.ui.friends_tick)
                applyAgre:setPosition(CCPoint(tickbtn:getContentSize().width/2,
                                                 tickbtn:getContentSize().height/2))
                tickbtn:addChild(applyAgre)
                local applyAgreBtn = SpineMenuItem:create(json.ui.button, tickbtn)
                applyAgreBtn:setAnchorPoint(0, 0)
                applyAgreBtn:setPosition(CCPoint(514+56-198, 252-228))
            
                icons[i].applyAgreMenu = CCMenu:createWithItem(applyAgreBtn)
                icons[i].applyAgreMenu:setPosition(CCPoint(0, 0))
                borders[i]:addChild(icons[i].applyAgreMenu)
            
                local xbtn = img.createLogin9Sprite(img.login.button_9_small_orange)
                xbtn:setPreferredSize(CCSizeMake(90, 42))
                local applyNotagrebtn1 = img.createUISprite(img.ui.friends_x)
                applyNotagrebtn1:setPosition(CCPoint(xbtn:getContentSize().width/2,
                                                  xbtn:getContentSize().height/2))
                xbtn:addChild(applyNotagrebtn1)
                local applyNotagrebtn = SpineMenuItem:create(json.ui.button, xbtn)
                applyNotagrebtn:setAnchorPoint(0, 0)
                applyNotagrebtn:setPosition(CCPoint(616+56-198, 252-228))
                icons[i].applyNotagreMenu = CCMenu:createWithItem(applyNotagrebtn)
                icons[i].applyNotagreMenu:setPosition(CCPoint(0, 0))
                borders[i]:addChild(icons[i].applyNotagreMenu)

                applyNotagrebtn:registerScriptTapHandler(function()
                    audio.play(audio.button)
                    local param = {}
                    param.sid = player.sid
                    local uids = {}
                    uids[#uids+1] = obj.uid
                    param.disagree = uids
                    addWaitNet()
                    net:frd_op(param, function(__data)
                        delWaitNet()
                        tbl2string(__data)
                        if __data.status ~= 0 then
                            showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                            return
                        end
                        friend.delFriendsApply(obj)
                        showFriends()
                    end)
                end)
                applyAgreBtn:registerScriptTapHandler(function()
                    audio.play(audio.button)
                    local param = {}
                    param.sid = player.sid
                    param.agree = obj.uid
                    addWaitNet()
                    net:frd_op(param, function(__data)
                        delWaitNet()
                        tbl2string(__data)
                        if __data.status == -4 or __data.status == -1 then
                            showToast(i18n.global.friend_are_friend.string)
                            friend.delFriendsApply(obj)
                            showFriends()
                            return
                        end
                        if __data.status == -5 then
                            -- 对方超过好友个数
                            showToast(string.format(i18n.global.friend_other_frd_full.string, LIMIT_FRIEND))
                            return
                        end    
                        if __data.status == -3 then
                            showToast(string.format(i18n.global.friend_friends_limit.string, LIMIT_FRIEND))
                            return
                        end
                        if __data.status ~= 0 then
                            showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                            return
                        end

                        friend.addFriendsList(obj)
                        friend.delFriendsApply(obj)
                        showFriends()
                    end)
                end)
            end
        end

        local title = lbl.createFont1(24, i18n.global.friend_apply_list.string, ccc3(0xe6, 0xd0, 0xae))
        title:setPosition(CCPoint(container:getContentSize().width/2, 506-58))
        container:addChild(title, 1)
        local title_shadowD = lbl.createFont1(24, i18n.global.friend_apply_list.string, ccc3(0x59, 0x30, 0x1b))
        title_shadowD:setPosition(CCPoint(container:getContentSize().width/2, 506-60))
        container:addChild(title_shadowD)

        local requestslab = lbl.createFont1(16, string.format(i18n.global.friend_requesrs_rcvd.string, requestsNum), ccc3(0x49, 0x26, 0x04))
        requestslab:setAnchorPoint(CCPoint(0, 0.5))
        requestslab:setPosition(CCPoint(10, 506-134))
        container:addChild(requestslab)

        local deleteallSprite = img.createLogin9Sprite(img.login.button_9_small_gold)
        deleteallSprite:setPreferredSize(CCSizeMake(208, 42))

        local deleteallBtn = SpineMenuItem:create(json.ui.button, deleteallSprite)
        deleteallBtn:setAnchorPoint(0, 0)
        deleteallBtn:setPosition(CCPoint(510+56-186, 506-155))
        local deleteallMenu = CCMenu:createWithItem(deleteallBtn)
        deleteallMenu:setPosition(0,0)
        container:addChild(deleteallMenu)
   
        local deleteallLab = lbl.createFont1(16, i18n.global.friend_apply_delete.string, ccc3(0x73, 0x3b, 0x05))
        deleteallLab:setPosition(CCPoint(deleteallSprite:getContentSize().width/2, deleteallSprite:getContentSize().height/2+1))
        deleteallSprite:addChild(deleteallLab)

        deleteallBtn:registerScriptTapHandler(function()
            audio.play(audio.button)
            if friend.friends.friendsApply == nil or #friend.friends.friendsApply == 0 then
                showToast(i18n.global.friend_no_application.string)
                return 
            end
            local param = {}
            param.sid = player.sid
            param.disagree = applyUids
            
            addWaitNet()
            net:frd_op(param, function(__data)
                delWaitNet()
                tbl2string(__data)
                if __data.status ~= 0 then
                    showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                    return
                end
                for _= 1,#friend.friends.friendsApply do
                    friend.delFriendsApply(friend.friends.friendsApply[1]) 
                end
                showFriends()
                --initBorder(0)
            end)
        end)
        
    end

    local progressLabel = nil
    local powerProgress = nil
    local function showNPC()
        initcontainer()
        initScroll(0)
        initBorder(0) 

        -- title
        local title = lbl.createFont1(24, i18n.global.friend_assist.string, ccc3(0xe6, 0xd0, 0xae))
        title:setPosition(CCPoint(container:getContentSize().width/2, 506-58))
        container:addChild(title, 1)
        local title_shadowD = lbl.createFont1(24, i18n.global.friend_assist.string, ccc3(0x59, 0x30, 0x1b))
        title_shadowD:setPosition(CCPoint(container:getContentSize().width/2, 506-60))
        container:addChild(title_shadowD)

        local function callBackself(hpp)
            progressLabel:setString(string.format("%d%%", hpp))
            powerProgress:setPercentage(hpp/100*100)
        end

        local function createBoss(id, hpp)
            local info = cfgmonster[cfgfriendstage[id].monster[1]]
            local boss = img.createHeroHead(info.heroLink, info.lvShow, true, info.star)
            --bossIconboss:setScale(0.85)
            boss:setPosition(489+20-226, 755-485)
            container:addChild(boss)

            -- power bar
            local powerBar = img.createUI9Sprite(img.ui.fight_hurts_bar_bg)
            powerBar:setPreferredSize(CCSize(290, 22))
            powerBar:setPosition(489+20-226, 683-485)
            container:addChild(powerBar)

            local progress0 = img.createUISprite(img.ui.friends_boss_blood)
            powerProgress = createProgressBar(progress0)
            powerProgress:setPosition(powerBar:getContentSize().width/2, powerBar:getContentSize().height/2)
            powerProgress:setPercentage(hpp/100*100)
            powerBar:addChild(powerProgress)

            local progressStr = string.format("%d%%", hpp)
            progressLabel = lbl.createFont2(16, progressStr, ccc3(255, 246, 223))
            progressLabel:setPosition(CCPoint(powerBar:getContentSize().width/2,
                                            powerBar:getContentSize().height/2+5))
            powerBar:addChild(progressLabel)

            local injurySprite = img.createUISprite(img.ui.fight_hurts)
            local injuryBtn = SpineMenuItem:create(json.ui.button, injurySprite)
            injuryBtn:setPosition(CCPoint(724+20-226, 580-275))
            local injuryMenu = CCMenu:createWithItem(injuryBtn)
            injuryMenu:setPosition(0,0)
            container:addChild(injuryMenu)

            injuryBtn:registerScriptTapHandler(function()
                audio.play(audio.button) 
                local injuryrank = require "ui.friends.injuryrank"
                layer:addChild(injuryrank.create())
            end)

            local combatLab = lbl.createFont1(16, i18n.global.friendboss_battle_reward.string, ccc3(0x73, 0x3b, 0x05))
            --rewardLab:setAnchorPoint(0, 0.5)
            combatLab:setPosition(487+20-226, 142)
            container:addChild(combatLab)

            local rewardObj = cfgfriendstage[id].finalReward

            local offset_x = 487+20-226
            for i=1,#rewardObj do
                local tmp_item
                local itemObj = rewardObj[i]
                if itemObj.type == 1 then  -- item
                    local tmp_item0 = img.createItem(itemObj.id, itemObj.num)
                    tmp_item = SpineMenuItem:create(json.ui.button, tmp_item0)
                elseif itemObj.type == 2 then  -- equip
                    local tmp_item0 = img.createEquip(itemObj.id, itemObj.num)
                    tmp_item = SpineMenuItem:create(json.ui.button, tmp_item0)
                end
                
                tmp_item:setScale(0.7)
                -- 487+20-226, 520-485
                tmp_item:setPosition(CCPoint(offset_x+(i-1)*70, 100))
                local tmp_item_menu = CCMenu:createWithItem(tmp_item)
                tmp_item_menu:setPosition(CCPoint(0, 0))
                container:addChild(tmp_item_menu)

                tmp_item:registerScriptTapHandler(function()
                    audio.play(audio.button)
                    local tmp_tip
                    if itemObj.type == 1 then  -- item
                        tmp_tip = tipsitem.createForShow({id=itemObj.id})
                        layer:addChild(tmp_tip, 100)
                    elseif itemObj.type == 2 then  -- equip
                        tmp_tip = tipsequip.createById(itemObj.id)
                        layer:addChild(tmp_tip, 100)
                    end
                    tmp_tip.setClickBlankHandler(function()
                        tmp_tip:removeFromParentAndCleanup(true)
                    end)
                end)
            end

            local battleSprite = img.createLogin9Sprite(img.login.button_9_small_gold)
            battleSprite:setPreferredSize(CCSizeMake(174, 54))

            local battlelab = lbl.createFont1(18, i18n.global.trial_stage_btn_battle.string, lbl.buttonColor)
            battlelab:setPosition(CCPoint(battleSprite:getContentSize().width/2,
                                            battleSprite:getContentSize().height/2))
            battleSprite:addChild(battlelab)

            local battleBtn = SpineMenuItem:create(json.ui.button, battleSprite)
            battleBtn:setAnchorPoint(0.5, 0)
            battleBtn:setPosition(CCPoint(487+20-226, 12))
            local battleMenu = CCMenu:createWithItem(battleBtn)
            battleMenu:setPosition(0,0)
            container:addChild(battleMenu)

            battleBtn:registerScriptTapHandler(function()
                disableObjAWhile(battleBtn)
                audio.play(audio.button) 
                layer:addChild((require "ui.friends.enemyline").create(player.uid, callBackself)) 
                --layer:addChild(selecthero.create({type = "friend", uid = player.uid}))
            end)
        end

        local function initFrdboss()
            --local bossinfo = {}
             
            local gParams = {
                sid = player.sid,
                uid = player.uid,
            }
            addWaitNet()

            net:frd_boss_st(gParams, function(__data)
                delWaitNet()
                tbl2string(__data)
                if __data.status == -2 then
                    showToast(i18n.global.friendboss_boss_die.string)
                    friendboss.upscd()
                    frdBoss.recoverlab:setVisible(false)
                    frdBoss.showTimeLab:setVisible(false)

                    return 
                end
                createBoss(__data.id, __data.hpp)
                frdBoss.recoverlab:setVisible(false)
                frdBoss.showTimeLab:setVisible(false)
                frdBoss.searchIcon:setVisible(false)
                frdBoss.searchmap:setVisible(false)
                frdBoss.searchBtn:setVisible(false)
            end)
            --return bossinfo 
        end
        
        local detailSprite = img.createUISprite(img.ui.btn_help)
        local detailBtn = SpineMenuItem:create(json.ui.button, detailSprite)
        --detailBtn:setScale(view.minScale)
        detailBtn:setPosition(736+20-186, 525-155)

        local detailMenu = CCMenu:create()
        detailMenu:setPosition(0, 0)
        container:addChild(detailMenu)
        detailMenu:addChild(detailBtn)

        detailBtn:registerScriptTapHandler(function()
            audio.play(audio.button)
            layer:addChild(require("ui.help").create(i18n.global.friendboss_help.string), 1000)
        end)

        local rankSprite = img.createLogin9Sprite(img.login.button_9_small_gold)
        rankSprite:setPreferredSize(CCSizeMake(206, 42))

        local ranklab = lbl.createFont1(16, i18n.global.friendboss_integral_rank.string, lbl.buttonColor)
        ranklab:setPosition(CCPoint(rankSprite:getContentSize().width/2,
                                        rankSprite:getContentSize().height/2+1))
        rankSprite:addChild(ranklab)                                

        local rankBtn = SpineMenuItem:create(json.ui.button, rankSprite)
        rankBtn:setAnchorPoint(0, 0.5)
        rankBtn:setPosition(CCPoint(208+20-226, 525-155))
        local rankMenu = CCMenu:createWithItem(rankBtn)
        rankMenu:setPosition(0,0)
        container:addChild(rankMenu)
        
        rankBtn:registerScriptTapHandler(function()
            audio.play(audio.button)
            layer:addChild((require "ui.friends.scorerank").create()) 

        end)
        local rewardSprite = img.createLogin9Sprite(img.login.button_9_small_gold)
        rewardSprite:setPreferredSize(CCSizeMake(206, 42))
        local rewardlab = lbl.createFont1(16, i18n.global.friendboss_integral_reward.string, lbl.buttonColor)
        rewardlab:setPosition(CCPoint(rewardSprite:getContentSize().width/2,
                                        rewardSprite:getContentSize().height/2+1))
        rewardSprite:addChild(rewardlab)                                

        local rewardBtn = SpineMenuItem:create(json.ui.button, rewardSprite)
        rewardBtn:setAnchorPoint(0, 0.5)
        rewardBtn:setPosition(CCPoint(422+20-226, 525-155))
        local rewardMenu = CCMenu:createWithItem(rewardBtn)
        rewardMenu:setPosition(0,0)
        container:addChild(rewardMenu)
        
        rewardBtn:registerScriptTapHandler(function()
            audio.play(audio.button)
            layer:addChild((require "ui.friends.scorereward").create()) 
        end)

        local npcboard = img.createUI9Sprite(img.ui.botton_fram_2)
        npcboard:setPreferredSize(CCSizeMake(592, 178))
        npcboard:setAnchorPoint(CCPoint(0, 0))
        npcboard:setPosition(208+21-226, 315-155)
        container:addChild(npcboard)

        local searchSprite = img.createLogin9Sprite(img.login.button_9_small_gold)
        searchSprite:setPreferredSize(CCSizeMake(174, 54))
        local searchlab = lbl.createFont1(18, i18n.global.friendboss_btn_search.string, lbl.buttonColor)
        searchlab:setPosition(CCPoint(searchSprite:getContentSize().width/2,
                                        searchSprite:getContentSize().height/2))
        searchSprite:addChild(searchlab)                                

        frdBoss.searchBtn = SpineMenuItem:create(json.ui.button, searchSprite)
        frdBoss.searchBtn:setAnchorPoint(0.5, 0)
        frdBoss.searchBtn:setPosition(CCPoint(487+20-206, 12))
        local searchMenu = CCMenu:createWithItem(frdBoss.searchBtn)
        searchMenu:setPosition(0,0)
        container:addChild(searchMenu)

        frdBoss.searchmap = img.createUISprite(img.ui.friends_search)
        frdBoss.searchmap:setPosition(487+22-206, 735-485)
        container:addChild(frdBoss.searchmap)

        json.load(json.ui.haoyouzhuzhan)
        frdBoss.searchIcon = DHSkeletonAnimation:createWithKey(json.ui.haoyouzhuzhan)
        frdBoss.searchIcon:scheduleUpdateLua()
        --frdBoss.searchIcon:playAnimation("animation", -1)
        frdBoss.searchIcon:setPosition(487+22-206, 700-485)
        container:addChild(frdBoss.searchIcon)

        local timeLab = string.format("%02d:%02d:%02d",math.floor(0/3600),math.floor((0%3600)/60),math.floor(0%60))
        frdBoss.showTimeLab = lbl.createFont2(16, "", ccc3(0xa5, 0xfd, 0x47))
        frdBoss.showTimeLab:setAnchorPoint(0, 0.5)
        frdBoss.showTimeLab:setPosition(440+20-206+65, 570-485)
        container:addChild(frdBoss.showTimeLab)

        -- 搜寻倒计时
        frdBoss.recoverlab = lbl.createFont1(16, i18n.global.friendboss_next_search.string, ccc3(0xff, 0xf6, 0xdf))
        frdBoss.recoverlab:setAnchorPoint(1, 0.5)
        frdBoss.recoverlab:setPosition(CCPoint(frdBoss.showTimeLab:boundingBox():getMinX() - 10, 570-485))
        container:addChild(frdBoss.recoverlab)

        --local bossInfo = {}
        local bossIcon = nil
        if friendboss.scd == nil then
            initFrdboss()

        else
            if friendboss.scd == 0 then
                frdBoss.recoverlab:setVisible(false)
                frdBoss.showTimeLab:setVisible(false)
            else
                frdBoss.searchIcon:setVisible(true)
                frdBoss.searchmap:setVisible(true)
                frdBoss.searchBtn:setVisible(true)
                frdBoss.searchBtn:setEnabled(false)
                setShader(frdBoss.searchBtn, SHADER_GRAY, true)
            end
        end
        
        frdBoss.searchBtn:registerScriptTapHandler(function()
            audio.play(audio.button)
            local gParams = {
                sid = player.sid,
            }
            frdBoss.searchIcon:playAnimation("animation")
            local ban = CCLayer:create()
            ban:setTouchEnabled(true)
            ban:setTouchSwallowEnabled(true)
            layer:addChild(ban, 1000)
            --frdBoss.searchBtn:setEnabled(false)
            layer:runAction(createSequence({
                CCDelayTime:create(2.0),CCCallFunc:create(function()
                    ban:removeFromParent()
                end)
            }))

            schedule(layer, 1, function()
                addWaitNet()

                net:frd_boss_search(gParams, function(__data)
                    delWaitNet()
                    tbl2string(__data)
                    if __data.status == -2 then
                        showToast(i18n.global.toast_frdboss_notdie.string)
                        return
                    elseif __data.status == -3 then
                        showToast(i18n.global.event_processing.string)
                        return
                    end

                    if __data.status == -1 then
                        return
                    end
                    if __data.status ~= 0 then
                        showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                        return
                    end
                    if __data.id then
                        frdBoss.searchBtn:setVisible(false)
                        frdBoss.searchIcon:setVisible(false)
                        frdBoss.searchmap:setVisible(false)
                        createBoss(__data.id, 100)
                        local achieveData = require "data.achieve"
                        achieveData.add(ACHIEVE_TYPE_FRDBOSS, 1) 

                        friendboss.scd = nil
                    else
                        --friendboss.addscd()
                        friendboss.scd = 8*3600-600
                        friendboss.pull_scd_time = os.time()
                        frdBoss.recoverlab:setVisible(true)
                        frdBoss.showTimeLab:setVisible(true)
						require("ui.custom").showFloatReward(__data.reward)
                        if __data.reward.equips then
                            bag.equips.addAll(__data.reward.equips)
                            --local pop = createPopupPieceBatchSummonResult("equip", __data.reward.equips[1].id, __data.reward.equips[1].num)
                            --layer:addChild(pop, 100)
                        end
                        if __data.reward.items then
                            bag.items.addAll(__data.reward.items)
                            --local pop = createPopupPieceBatchSummonResult("item", __data.reward.items[1].id, __data.reward.items[1].num)
                            --layer:addChild(pop, 100)
                        end
                        setShader(frdBoss.searchBtn, SHADER_GRAY, true)
                        frdBoss.searchBtn:setEnabled(false)
                    end
                end)
            end)
        end)
    end

    local function setTabstatus()
        listTab:setEnabled(currentTab ~= TAB.LIST)
        findTab:setEnabled(currentTab ~= TAB.FIND)
        applyTab:setEnabled(currentTab ~= TAB.APPL)
        npcTab:setEnabled(currentTab ~= TAB.NPC)

        inputFind:setVisible(currentTab == TAB.FIND) 
    end
    
    function showFriends()
        setTabstatus()
        if currentTab == TAB.LIST then
            showList()
        elseif currentTab == TAB.FIND then
            showFind()
        elseif currentTab == TAB.APPL then 
            showApply()
        else
            showNPC()
        end
    end

    listTab:registerScriptTapHandler(function()
        audio.play(audio.button)
        currentTab = TAB.LIST
        showFriends()
    end)
    findTab:registerScriptTapHandler(function()
        audio.play(audio.button)
        currentTab = TAB.FIND
        showFriends()
    end)
    applyTab:registerScriptTapHandler(function()
        audio.play(audio.button)
        currentTab = TAB.APPL
        showFriends()
    end)
    npcTab:registerScriptTapHandler(function()
        audio.play(audio.button)
        if player.lv() < 36 then
            showToast(string.format(i18n.global.func_need_lv.string, 36))
            return
        end
        currentTab = TAB.NPC
        showFriends()
    end)
    
    local function backEvent()
        audio.play(audio.button)
        if uiParams and uiParams.from_layer == "task" then
            replaceScene(require("ui.town.main").create({from_layer="task"}))  
        else
            layer:removeFromParentAndCleanup()
        end
    end

    -- close btn
    local close0 = img.createUISprite(img.ui.close)
    local closeBtn = SpineMenuItem:create(json.ui.button, close0)
    closeBtn:setPosition(CCPoint(746+56-148, 545-59))
    local closeMenu = CCMenu:createWithItem(closeBtn)
    closeMenu:setPosition(CCPoint(0, 0))
    board:addChild(closeMenu)
    closeBtn:registerScriptTapHandler(function()     
        backEvent()
    end)

    --touch 
    local touchbeginx, touchbeginy
    local isclick
    local last_touch_sprite = nil

    local function onTouchBegan(x, y)
        touchbeginx, touchbeginy = x, y
        isclick = true
        if enegyBottom and currentTab == TAB.LIST then
            local p0 = enegyBottom:convertToNodeSpace(ccp(x, y))
            if p0 and enegyIcon:boundingBox():containsPoint(p0) then
                enegyFlag = true
                audio.play(audio.button)
                enegyToast:setVisible(true)
                last_touch_sprite = enegyIcon
                last_touch_sprite._scale = 0.8 
                playAnimTouchBegin(last_touch_sprite)
                
            end
        end
        return true
    end

    local function onTouchMoved(x, y)
        return true
    end
    local function onTouchEnded(x, y)
        if isclick then
            if enegyFlag == true then
                enegyFlag = false
                if last_touch_sprite and not tolua.isnull(last_touch_sprite) then
                    playAnimTouchEnd(last_touch_sprite)
                    last_touch_sprite = nil
                end
                enegyToast:setVisible(false)
            end
        end
        
    end

    local function onTouch(eventType, x, y)
        if eventType == "began" then
            return onTouchBegan(x, y)
        elseif eventType == "moved" then
            return onTouchMoved(x, y)
        else
            return onTouchEnded(x, y)
        end
    end

    layer:registerScriptTouchHandler(function() return true end)
    layer:registerScriptTouchHandler(onTouch , false , -128 , false)
    layer:setTouchEnabled(true)
    
    function layer.onAndroidBack()
        backEvent()
    end

    addBackEvent(layer) 
    
    local function onEnter()
        layer.notifyParentLock()
        init(showFriends)
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
    return layer
end

return ui
