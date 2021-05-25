
local ui = {}

require "common.func"
local view = require "common.view"
local i18n = require "res.i18n"
local lbl = require "res.lbl"
local img = require "res.img"
local audio = require "res.audio"
local json = require "res.json"
local cfgstore = require "config.store"
local player = require "data.player"
local bagData = require "data.bag"
local activityData = require "data.activity"
local NetClient = require "net.netClient"
local netClient = NetClient:getInstance()
local tipsequip = require "ui.tips.equip"
local tipsitem = require "ui.tips.item"
local uirewards = require "ui.reward"

local IDS = activityData.IDS
local ItemType = {
    Item = 1,
    Equip = 2,
}

local vp_ids = {
    IDS.CHRISTMAS_1.ID,
    IDS.CHRISTMAS_2.ID,
    IDS.CHRISTMAS_3.ID,
    IDS.CHRISTMAS_4.ID,
    IDS.CHRISTMAS_5.ID,
    IDS.CHRISTMAS_6.ID,
    IDS.CHRISTMAS_7.ID,
    IDS.CHRISTMAS_8.ID,
    IDS.CHRISTMAS_9.ID,
    IDS.CHRISTMAS_10.ID,
    IDS.CHRISTMAS_11.ID,
    IDS.CHRISTMAS_12.ID,
    IDS.CHRISTMAS_13.ID,
}

function ui.create()
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
    board:setPosition(scalep(352, 57))
    layer:addChild(board)
    --drawBoundingbox(layer, board)
    local board_w = board:getContentSize().width
    local board_h = board:getContentSize().height

    img.unload(img.packedOthers.ui_activity_christmas)
    img.unload(img.packedOthers.ui_activity_christmas_cn)
    if i18n.getCurrentLanguage() == kLanguageChinese then
        img.load(img.packedOthers.ui_activity_christmas_cn)
    else
        img.load(img.packedOthers.ui_activity_christmas)
    end
    local banner
    if i18n.getCurrentLanguage() == kLanguageKorean then
        banner = img.createUISprite("ui_christmas_board_kr.png")
    elseif i18n.getCurrentLanguage() == kLanguageChineseTW then
        banner = img.createUISprite("ui_christmas_board_tw.png")
    elseif i18n.getCurrentLanguage() == kLanguageJapanese then
        banner = img.createUISprite("ui_christmas_board_jp.png")
    elseif i18n.getCurrentLanguage() == kLanguageRussian then
        banner = img.createUISprite("ui_christmas_board_ru.png")
    elseif i18n.getCurrentLanguage() == kLanguagePortuguese then
        banner = img.createUISprite("ui_christmas_board_pt.png")
    else
        banner = img.createUISprite("ui_christmas_board.png")
    end
    banner:setAnchorPoint(CCPoint(0.5, 1))
    banner:setPosition(CCPoint(board_w/2, board_h-10))
    board:addChild(banner)

    local lbl_cd = lbl.createFont2(14, "", ccc3(0xa5, 0xfd, 0x47))
    lbl_cd:setAnchorPoint(CCPoint(0, 0.5))
    lbl_cd:setPosition(CCPoint(200+90, 20))
    banner:addChild(lbl_cd)
    local lbl_cd_des = lbl.createFont2(14, i18n.global.activity_to_end.string)
    lbl_cd_des:setAnchorPoint(CCPoint(0, 0.5))
    lbl_cd_des:setPosition(CCPoint(200+165, 20))
    banner:addChild(lbl_cd_des)

    if i18n.getCurrentLanguage() == kLanguageRussian then
        lbl_cd_des:setPosition(CCPoint(200+90-40, 20))
        lbl_cd:setAnchorPoint(CCPoint(0, 0.5))
        lbl_cd:setPosition(CCPoint(lbl_cd_des:boundingBox():getMaxX()+10, 20))
    end

    local coin_bg = img.createUI9Sprite(img.ui.main_coin_bg) 
    coin_bg:setPreferredSize(CCSizeMake(172, 38))
    coin_bg:setPosition(CCPoint(340, 52))
    banner:addChild(coin_bg)
    local coin_icon = img.createItemIcon2(ITEM_ID_ANNIVERSARY)
    --coin_icon:setScale(0.9)
    coin_icon:setPosition(CCPoint(8, coin_bg:getContentSize().height/2+3))
    coin_bg:addChild(coin_icon)
    local lbl_coin = lbl.createFont2(16, "12345")
    lbl_coin:setPosition(CCPoint(92, coin_bg:getContentSize().height/2+3))
    coin_bg:addChild(lbl_coin)
    local function updateCoin()
        local itemObj = bagData.items.find(ITEM_ID_ANNIVERSARY)
        if not itemObj then
            itemObj = {id=ITEM_ID_ANNIVERSARY, num=0}
        end
        lbl_coin:setString(itemObj.num)
    end
    updateCoin()

    local function createSurebuy(vpObj, cfgObj, callback)
        local params = {}
        params.btn_count = 0
        params.body = string.format(i18n.global.blackmarket_buy_sure.string, 20)
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
            local itemObj = bagData.items.find(ITEM_ID_ANNIVERSARY)
            if not itemObj then
                itemObj = {id=ITEM_ID_ANNIVERSARY, num=0}
            end
            if itemObj.num < cfgObj.extra[1].num then
                showToast(i18n.global.luckcoin_notenough.string)
                return
            end
            local param = {
                sid = player.sid,
                id = vpObj.id,
                num = 1,
            }
            addWaitNet()
            netClient:exchange_act(param, function(__data)
                delWaitNet()
                tbl2string(__data)
                if __data.status == -2 then
                    showToast(string.format(i18n.global.shop_onlytime.string, cfgObj.limitNum))
                    return
                end
                if __data.status ~= 0 then
                    showToast(i18n.global.luckcoin_notenough.string)
                    return
                end
                vpObj.limits = vpObj.limits - 1
                if vpObj.limits == 0 then
                    callback()
                end
                itemObj.num = itemObj.num - cfgObj.extra[1].num
                updateCoin()
                -- show affix
                if __data.affix then
                    bagData.addRewards(__data.affix)
                    CCDirector:sharedDirector():getRunningScene():addChild(uirewards.createFloating(__data.affix), 100000)
                end
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

    local buyCount = 1
    local function selectSweepnumLayer(vpObj, cfgObj, callback)
        local sweepLayer = CCLayer:create()
        buyCount = 1
        -- dark bg
        local sweepdarkbg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
        sweepLayer:addChild(sweepdarkbg)
        -- board_bg
        local sweepboard_bg = img.createUI9Sprite(img.ui.dialog_1)
        sweepboard_bg:setPreferredSize(CCSizeMake(370, 448))
        sweepboard_bg:setScale(view.minScale)
        sweepboard_bg:setPosition(scalep(960/2, 576/2))
        sweepLayer:addChild(sweepboard_bg)
        local sweepboard_bg_w = sweepboard_bg:getContentSize().width
        local sweepboard_bg_h = sweepboard_bg:getContentSize().height

        -- edit
        local edit0 = img.createLogin9Sprite(img.login.input_border)
        local edit = CCEditBox:create(CCSizeMake(160*view.minScale, 40*view.minScale), edit0)
        edit:setInputMode(kEditBoxInputModeNumeric)
        edit:setReturnType(kKeyboardReturnTypeDone)
        edit:setMaxLength(5)
        edit:setFont("", 16*view.minScale)
        --edit:setPlaceHolder("0")
        edit:setText("1")
        edit:setFontColor(ccc3(0x94, 0x62, 0x42))
        edit:setPosition(scalep(960/2, 272))
        --edit:setVisible(false)
        sweepLayer:addChild(edit, 1000)
        sweepLayer.edit = edit
        -- anim
        --sweepboard_bg:setScale(0.5)
        --sweepboard_bg:runAction(CCScaleTo:create(0.15, 1, 1))

        -- title
        local sweeplbl_title = lbl.createFont1(24, i18n.global.pumpkin_btn_get.string, ccc3(0xe6, 0xd0, 0xae))
        sweeplbl_title:setPosition(CCPoint(sweepboard_bg_w/2, sweepboard_bg_h-29))
        sweepboard_bg:addChild(sweeplbl_title, 2)
        local sweeplbl_title_shadowD = lbl.createFont1(24, i18n.global.pumpkin_btn_get.string, ccc3(0x59, 0x30, 0x1b))
        sweeplbl_title_shadowD:setPosition(CCPoint(sweepboard_bg_w/2, sweepboard_bg_h-31))
        sweepboard_bg:addChild(sweeplbl_title_shadowD)
        
        --local sweeplbl = lbl.createMixFont1(18, i18n.global.act_bboss_sweep_lable.string, ccc3(0x73, 0x3b, 0x05))
        --sweeplbl:setPosition(CCPoint(sweepboard_bg_w/2, 275))
        --sweepboard_bg:addChild(sweeplbl)

        -- icon
        local icon_thing
        if cfgObj.rewards[1].type == ItemType.Equip then  -- equip
            icon_thing = img.createEquip(cfgObj.rewards[1].id, cfgObj.rewards[1].num)
        elseif cfgObj.rewards[1].type == ItemType.Item then
            icon_thing = img.createItem(cfgObj.rewards[1].id, cfgObj.rewards[1].num)
        end
        icon_thing:setPosition(CCPoint(sweepboard_bg:getContentSize().width/2, 309))
        sweepboard_bg:addChild(icon_thing)

        local btn_sub0 = img.createUISprite(img.ui.btn_sub)
        local btn_sub = SpineMenuItem:create(json.ui.button, btn_sub0)
        btn_sub:setPosition(CCPoint(sweepboard_bg:getContentSize().width/2 - 111, 210))
        local btn_sub_menu = CCMenu:createWithItem(btn_sub)
        btn_sub_menu:setPosition(CCPoint(0, 0))
        sweepboard_bg:addChild(btn_sub_menu)
        
        local btn_add0 = img.createUISprite(img.ui.btn_add)
        local btn_add = SpineMenuItem:create(json.ui.button, btn_add0)
        btn_add:setPosition(CCPoint(sweepboard_bg:getContentSize().width/2 + 111, 210))
        local btn_add_menu = CCMenu:createWithItem(btn_add)
        btn_add_menu:setPosition(CCPoint(0, 0))
        sweepboard_bg:addChild(btn_add_menu)

        local broken_bg = img.createUI9Sprite(img.ui.casino_gem_bg)
        broken_bg:setPreferredSize(CCSizeMake(165, 34))
        broken_bg:setPosition(CCPoint(sweepboard_bg_w/2, 144))
        sweepboard_bg:addChild(broken_bg)

        local icon_broken = img.createItemIcon2(ITEM_ID_ANNIVERSARY)
        icon_broken:setScale(0.8)
        icon_broken:setPosition(CCPoint(30, broken_bg:getContentSize().height/2))
        broken_bg:addChild(icon_broken)
        local brokennum = 0
        if bagData.items.find(ITEM_ID_ANNIVERSARY) then
            brokennum = bagData.items.find(ITEM_ID_ANNIVERSARY).num  
        end
        local lbl_pay = lbl.createFont2(16, cfgObj.extra[1].num)
        lbl_pay:setPosition(CCPoint(100, broken_bg:getContentSize().height/2))
        broken_bg:addChild(lbl_pay)

        local function updatePay(_count)
            local tmp_str = _count*cfgObj.extra[1].num
            lbl_pay:setString(tmp_str)
        end

        local edit_tickets = sweepLayer.edit
        edit_tickets:registerScriptEditBoxHandler(function(eventType)
            if eventType == "returnSend" then
            elseif eventType == "return" then
            elseif eventType == "ended" then
                local tmp_ticket_count = edit_tickets:getText()
                tmp_ticket_count = string.trim(tmp_ticket_count)
                tmp_ticket_count = checkint(tmp_ticket_count)
                if tmp_ticket_count <= 1 then
                    tmp_ticket_count = 1
                end
                edit_tickets:setText(tmp_ticket_count)
                updatePay(tmp_ticket_count)
                buyCount = tmp_ticket_count
            elseif eventType == "began" then
            elseif eventType == "changed" then
            end
        end)

        btn_sub:registerScriptTapHandler(function()
            audio.play(audio.button)
            local edt_txt = edit_tickets:getText()
            edt_txt = string.trim(edt_txt)
            if edt_txt == "" then
                edt_txt = 1
                edit_tickets:setText(1)
                updatePay(0)
                buyCount = 1
                return
            end
            local ticket_count = checkint(edt_txt)
            if ticket_count <= 1 then
                edit_tickets:setText(1)
                updatePay(1)
                buyCount = 1
                return
            else
                ticket_count = ticket_count - 1
                edit_tickets:setText(ticket_count)
                updatePay(ticket_count)
                buyCount = ticket_count
            end
        end)
        btn_add:registerScriptTapHandler(function()
            audio.play(audio.button)
            local edt_txt = edit_tickets:getText()
            edt_txt = string.trim(edt_txt)
            if edt_txt == "" then
                edt_txt = 0
                edit_tickets:setText(0)
                updatePay(0)
                buyCount = 0
                return
            end
            local ticket_count = checkint(edt_txt)
            if ticket_count < 0 then
                edit_tickets:setText(0)
                updatePay(0)
                buyCount = 0
                return
            else
                local tmp_gem_cost = ticket_count+1
                if tmp_gem_cost > brokennum/cfgObj.extra[1].num then
                    --local gotoStoreDialog = require "uikit.gotoStoreDialog"
                    --gotoStoreDialog.show(layer, "casino")
                    return
                end
                ticket_count = ticket_count + 1
                edit_tickets:setText(ticket_count)
                updatePay(ticket_count)
                buyCount = ticket_count
            end
        end)

        local okSprite = img.createLogin9Sprite(img.login.button_9_small_gold)
        okSprite:setPreferredSize(CCSize(155, 45))
        local oklab = lbl.createFont1(18, i18n.global.dialog_button_confirm.string, ccc3(0x7e, 0x27, 0x00))
        oklab:setPosition(CCPoint(okSprite:getContentSize().width/2,
                                        okSprite:getContentSize().height/2))
        okSprite:addChild(oklab)

        local okBtn = SpineMenuItem:create(json.ui.button, okSprite)
        okBtn:setPosition(CCPoint(sweepboard_bg_w/2, 80))
        
        local okMenu = CCMenu:createWithItem(okBtn)
        okMenu:setPosition(0,0)
        sweepboard_bg:addChild(okMenu)

        okBtn:registerScriptTapHandler(function()
            disableObjAWhile(okBtn)
            audio.play(audio.button) 
            local itemObj = bagData.items.find(ITEM_ID_ANNIVERSARY)
            if not itemObj then
                itemObj = {id=ITEM_ID_ANNIVERSARY, num=0}
            end
            if itemObj.num < cfgObj.extra[1].num then
                showToast(i18n.global.luckcoin_notenough.string)
                return
            end
            if buyCount > brokennum/cfgObj.extra[1].num then 
                --showToast(i18n.global.tips_act_ticket_lack.string)
                showToast(i18n.global.luckcoin_notenough.string)
                return
            end
            local param = {
                sid = player.sid,
                id = vpObj.id,
                num = buyCount,
            }
            addWaitNet()
            netClient:exchange_act(param, function(__data)
                delWaitNet()
                tbl2string(__data)
                if __data.status == -2 then
                    showToast(string.format(i18n.global.shop_onlytime.string, cfgObj.limitNum))
                    return
                end
                if __data.status ~= 0 then
                    showToast(i18n.global.luckcoin_notenough.string)
                    return
                end
                brokennum = brokennum - cfgObj.extra[1].num*buyCount
                itemObj.num = itemObj.num - cfgObj.extra[1].num*buyCount
                updateCoin()
                vpObj.limits = vpObj.limits - buyCount
                if vpObj.limits == 0 then
                    callback()
                end
                -- show affix
                if __data.affix then
                    bagData.addRewards(__data.affix)
                    CCDirector:sharedDirector():getRunningScene():addChild(uirewards.createFloating(__data.affix), 100000)
                end
                sweepLayer:removeFromParentAndCleanup(true)
            end)
        end)

        local function sweepbackEvent()
            audio.play(audio.button)
            sweepLayer:removeFromParentAndCleanup(true)
        end

        -- btn_close
        local sweepbtn_close0 = img.createUISprite(img.ui.close)
        local sweepbtn_close = SpineMenuItem:create(json.ui.button, sweepbtn_close0)
        sweepbtn_close:setPosition(CCPoint(sweepboard_bg_w-25, sweepboard_bg_h-28))
        local sweepbtn_close_menu = CCMenu:createWithItem(sweepbtn_close)
        sweepbtn_close_menu:setPosition(CCPoint(0, 0))
        sweepboard_bg:addChild(sweepbtn_close_menu, 100)
        sweepbtn_close:registerScriptTapHandler(function()
            sweepbackEvent()
        end)

        sweepLayer:setTouchEnabled(true)
        sweepLayer:setTouchSwallowEnabled(true)

        addBackEvent(sweepLayer)
        function sweepLayer.onAndroidBack()
            sweepbackEvent()
        end
        local function onEnter()
            print("onEnter")
            sweepLayer.notifyParentLock()
        end
        local function onExit()
            sweepLayer.notifyParentUnlock()
        end
        sweepLayer:registerScriptHandler(function(event)
            if event == "enter" then
                onEnter()
            elseif event == "exit" then
                onExit()
            end
        end)
        return sweepLayer
    end

    local function createItem(vpObj)
        local cfgObj = vpObj.cfg
        local temp_item = img.createUISprite(img.ui.casino_shop_frame)
        local item_w = temp_item:getContentSize().width
        local item_h = temp_item:getContentSize().height
        -- rewards
        local rewards = cfgObj.rewards
        local _obj = rewards[1]
        local _item
        if _obj.type == ItemType.Equip then  -- equip
            local _item0 = img.createEquip(_obj.id, _obj.num)
            _item = CCMenuItemSprite:create(_item0, nil)
            _item:setScale(0.9)
            _item:setPosition(CCPoint(item_w/2, item_h/2+9))
            local _item_menu = CCMenu:createWithItem(_item)
            _item_menu:setPosition(CCPoint(0, 0))
            temp_item:addChild(_item_menu)
            _item:registerScriptTapHandler(function()
                audio.play(audio.button)
                layer:getParent():getParent():addChild(tipsequip.createById(_obj.id), 1000)
            end)
        elseif _obj.type == ItemType.Item then
            local _item0 = img.createItem(_obj.id, _obj.num)
            _item = CCMenuItemSprite:create(_item0, nil)
            _item:setScale(0.9)
            _item:setPosition(CCPoint(item_w/2, item_h/2+9))
            local _item_menu = CCMenu:createWithItem(_item)
            _item_menu:setPosition(CCPoint(0, 0))
            temp_item:addChild(_item_menu)
            _item:registerScriptTapHandler(function()
                audio.play(audio.button)
                layer:getParent():getParent():addChild(tipsitem.createForShow({id=_obj.id}), 1000)
            end)
        end
        -- btn
        local btn0 = img.createUISprite(img.ui.casino_shop_btn)
        local icon = img.createItemIcon2(ITEM_ID_ANNIVERSARY)
        icon:setScale(0.8)
        icon:setPosition(CCPoint(27, btn0:getContentSize().height/2))
        btn0:addChild(icon)
        local lbl_price = lbl.createFont2(16, cfgObj.extra[1].num)
        lbl_price:setPosition(CCPoint(74, btn0:getContentSize().height/2))
        btn0:addChild(lbl_price)
        local btn = SpineMenuItem:create(json.ui.button, btn0)
        btn:setPosition(CCPoint(item_w/2, 4))
        local btn_menu = CCMenu:createWithItem(btn)
        btn_menu:setPosition(CCPoint(0, 0))
        temp_item:addChild(btn_menu, 1)

        if vpObj.limits <= 1000 then
            local limittag = img.createUISprite(img.ui.blackmarket_limittag)
            limittag:setAnchorPoint(0, 0.5)
            limittag:setPosition(CCPoint(0, 107))
            temp_item:addChild(limittag)
        end

        local function setAlreadyBuy()
            setShader(_item, SHADER_GRAY, true)
            _item:setEnabled(false)
            local soldout = img.createUISprite(img.ui.blackmarket_soldout)
            --soldout:setAnchorPoint(0, 0)
            soldout:setPosition(CCPoint(_item:getContentSize().width/2, _item:getContentSize().height/2))
            _item:addChild(soldout)
            setShader(btn, SHADER_GRAY, true)
            btn:setEnabled(false)
        end

        if vpObj.limits == 0 then
            setAlreadyBuy()
        end

        btn:registerScriptTapHandler(function()
            audio.play(audio.button)
            if vpObj.limits == 1 then
                local surelayer = createSurebuy(vpObj, cfgObj, setAlreadyBuy)
                layer:getParent():getParent():addChild(surelayer, 1000)
            else
                local selectsweepnumlayer = selectSweepnumLayer(vpObj, cfgObj, setAlreadyBuy)
                layer:getParent():getParent():addChild(selectsweepnumlayer, 1000)
            end
        end)

        return temp_item
    end

    local lineScroll = require "ui.lineScroll"
    local scroll_params = {
        width = 550,
        height = 216,
    }
    local scroll = lineScroll.create(scroll_params)
    scroll:setAnchorPoint(CCPoint(0, 0))
	--scroll:setTouchEnabled(false)
    scroll:setPosition(CCPoint(5, 6))
    board:addChild(scroll)
    layer.scroll = scroll

    local function sortValue(_obj)
        if _obj.limits <= 0 then
            return 10000 + _obj.id
        else
            return _obj.id
        end
    end
    --table.sort(vps, function(a, b)
    --    return sortValue(a) < sortValue(b)
    --end)
    local ITEM_PER_ROW = 3
    local start_x = 101
    local step_x = 170
    local start_y = -28
    local step_y = -161
    local function showList(listObjs)
        for ii=1,#listObjs do
            --if ii == 1 then
            --    scroll.addSpace(3)
            --end
            local _x = start_x + (ii-1)%ITEM_PER_ROW * step_x
            local _y = start_y + math.floor((ii+ITEM_PER_ROW-1)/ITEM_PER_ROW-1) * step_y
            local tmp_item = createItem(listObjs[ii])
            tmp_item.obj = listObjs[ii]
            tmp_item:setPosition(CCPoint(_x+8, _y-55))
            scroll.content_layer:addChild(tmp_item)
        end
        local content_h = 60 - start_y - math.floor((#listObjs+ITEM_PER_ROW-1)/ITEM_PER_ROW-1)*step_y - step_y/2
        scroll:setContentSize(CCSizeMake(scroll.width, content_h))
        scroll.content_layer:setPosition(CCPoint(0, content_h))
        scroll:setContentOffset(CCPoint(0, scroll.height-content_h))
    end
    showList(vps)

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
    layer:scheduleUpdateWithPriorityLua(onUpdate, 0)

    require("ui.activity.ban").addBan(layer, scroll)
    layer:setTouchSwallowEnabled(false)
    layer:setTouchEnabled(true)

    return layer
end

return ui
