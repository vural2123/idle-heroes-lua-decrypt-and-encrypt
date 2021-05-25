local ui = {}

require "common.func"
require "common.const"
local view = require "common.view"
local img = require "res.img"
local i18n = require "res.i18n"
local lbl = require "res.lbl"
local json = require "res.json"
local audio = require "res.audio"
local cfgvip = require "config.vip"
local player = require "data.player"
local bagdata = require "data.bag"
local daredata = require "data.dare"
local tipsequip = require "ui.tips.equip"
local tipsitem = require "ui.tips.item"
local NetClient = require "net.netClient"
local netClient = NetClient:getInstance()

local buy_cost = {
    [1] = 50,
    [2] = 50,
    [3] = 50,
    [4] = 50,
    [5] = 50,
    [6] = 50,
    [7] = 50,
    [8] = 50,
}

function ui.create(uiParams)
    local _type = uiParams.type
    local dares = daredata.getDare(_type)
    local stages = daredata.getStage(_type)
    table.sort(stages, daredata.sort)
    local layer = CCLayer:create()
    -- dark bg
    local darkbg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    layer:addChild(darkbg)
    -- board
    local board= img.createUI9Sprite(img.ui.dialog_1)
    board:setPreferredSize(CCSizeMake(660, 465))
    board:setScale(view.minScale)
    board:setPosition(view.midX-0*view.minScale, view.midY)
    layer:addChild(board)
    layer.board = board
    local board_w = board:getContentSize().width
    local board_h = board:getContentSize().height

    -- anim
    if uiParams and uiParams._anim then
        board:setScale(0.5*view.minScale)
        board:runAction(CCScaleTo:create(0.15, 1*view.minScale, 1*view.minScale))
    end

    -- title
    local title_str = {
        [daredata.Type.COIN] = i18n.global.dare_main_coin.string,
        [daredata.Type.EXP] = i18n.global.dare_main_exp.string,
        [daredata.Type.SOUL] = i18n.global.dare_main_soul.string,
    }
    local lbl_title = lbl.createFont1(24, title_str[_type], ccc3(0xe6, 0xd0, 0xae))
    lbl_title:setPosition(CCPoint(board_w/2, board_h-29))
    board:addChild(lbl_title, 2)
    local lbl_title_shadowD = lbl.createFont1(24, title_str[_type], ccc3(0x59, 0x30, 0x1b))
    lbl_title_shadowD:setPosition(CCPoint(board_w/2, board_h-31))
    board:addChild(lbl_title_shadowD)

    local function backEvent()
        audio.play(audio.button)
        layer:removeFromParentAndCleanup(true)
    end
    -- btn_close
    local btn_close0 = img.createUISprite(img.ui.close)
    local btn_close = SpineMenuItem:create(json.ui.button, btn_close0)
    btn_close:setPosition(CCPoint(board_w-25, board_h-28))
    local btn_close_menu = CCMenu:createWithItem(btn_close)
    btn_close_menu:setPosition(CCPoint(0, 0))
    board:addChild(btn_close_menu, 100)
    layer.btn_close = btn_close
    btn_close:registerScriptTapHandler(function()
        backEvent()
    end)

    local lbl_times_des = lbl.createMixFont1(16, i18n.global.dare_stage_times_des.string, ccc3(0x6f, 0x4c, 0x38))
    lbl_times_des:setAnchorPoint(CCPoint(1, 0.5))
    lbl_times_des:setPosition(CCPoint(174, 380))
    board:addChild(lbl_times_des)
    local times_bg = img.createUI9Sprite(img.ui.select_hero_camp_bg)
    times_bg:setPreferredSize(CCSizeMake(102, 35))
    times_bg:setPosition(CCPoint(233, 380))
    board:addChild(times_bg, 10)
    local lbl_times = lbl.createFont2(16, "", ccc3(255, 246, 223))
    lbl_times:setPosition(CCPoint(38, 18))
    times_bg:addChild(lbl_times)
    local btn_buy0 = img.createUISprite(img.ui.main_icon_plus)
    local btn_buy = SpineMenuItem:create(json.ui.button, btn_buy0)
    btn_buy:setPosition(CCPoint(88, 18))
    local btn_buy_menu = CCMenu:createWithItem(btn_buy)
    btn_buy_menu:setPosition(CCPoint(0, 0))
    times_bg:addChild(btn_buy_menu)
    local function updateTimes()
        local tmp_times_str = (2+dares.buy-dares.fight) .. "/" .. (2+dares.buy)
        lbl_times:setString(tmp_times_str)
    end
    updateTimes()
    btn_buy:registerScriptTapHandler(function()
        audio.play(audio.button)
        -- check buy
        if dares.buy >= cfgvip[player.vipLv()].dareTime then
            showToast(string.format(i18n.global.dare_vip_buy.string, player.vipLv(), cfgvip[player.vipLv()].dareTime))
            return
        end
        ui.showBuy(layer, _type, updateTimes)
        if true then return end
        -- check gems
        if bagdata.gem() < buy_cost[dares.buy+1] then
            showToast(i18n.global.gboss_fight_st6.string)
            return
        end
        local dialog = require "ui.dialog"
        local function process_dialog(__data)
            if __data.selected_btn == 2 then
                -- button confirm
                layer:removeChildByTag(dialog.TAG)
                local nParams = {
                    sid = player.sid,
                    type = _type,
                    num = 1,
                }
                addWaitNet()
                netClient:dare_buy(nParams, function(__data)
                    delWaitNet()
                    tbl2string(__data)
                    if __data.status ~= 0 then
                        showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                        return
                    end
                    bagdata.subGem(buy_cost[dares.buy+1])
                    dares.buy = dares.buy + 1
                    updateTimes()
                    showToast(i18n.global.toast_buy_okay.string)
                end)
            elseif __data.selected_btn == 1 then
                -- button Cancel
                layer:removeChildByTag(dialog.TAG)
            end
        end
        local dialog_params = {
            title = "",
            body = string.format(i18n.global.dare_buy_tip.string, buy_cost[dares.buy+1]),
            btn_count = 2,
            btn_color = {
                [1] = dialog.COLOR_BLUE,
                [2] = dialog.COLOR_GOLD,
            },
            btn_text = {
                [1] = i18n.global.dialog_button_cancel.string,
                [2] = i18n.global.dialog_button_confirm.string,
            },
            selected_btn = 0,
            callback = process_dialog,
        }
        local dialog_ins = dialog.create(dialog_params)
        layer:addChild(dialog_ins, 1000, dialog.TAG)
    end)

    local lbl_reset_des = lbl.createMixFont1(16, i18n.global.dare_stage_reset_des.string, ccc3(0x6f, 0x4c, 0x38))
    lbl_reset_des:setAnchorPoint(CCPoint(1, 0.5))
    lbl_reset_des:setPosition(CCPoint(537, 380))
    board:addChild(lbl_reset_des)
    local lbl_cd = lbl.createFont2(16, "", ccc3(0xa5, 0xfd, 0x47))
    lbl_cd:setPosition(CCPoint(585, 380))
    board:addChild(lbl_cd)
    local last_update_cd = os.time()
    local function updateCD(ticks)
        if os.time() - last_update_cd < 0.5 then return end
        last_update_cd = os.time()
        local tmp_time = daredata.cd - (os.time() - daredata.pull_time)
        if tmp_time < 0 then
            daredata.reset()
            tmp_time = daredata.cd
            updateTimes()
        end
        local tmp_time_str = time2string(tmp_time)
        lbl_cd:setString(tmp_time_str)
    end
    updateCD()

    local curlv = 1
    local function createItem(itemObj, idx)
        local item = img.createUI9Sprite(img.ui.botton_fram_2)
        item:setPreferredSize(CCSizeMake(580, 88))
        local item_w = item:getContentSize().width
        local item_h = item:getContentSize().height
        -- difficulty
        local icon_difficulty = img.createUISprite(img.ui["dare_icon_stage" .. itemObj.difficulty])
        icon_difficulty:setPosition(CCPoint(50, item_h/2))
        item:addChild(icon_difficulty)
        -- reward
        local rcontainer = CCSprite:create()
        rcontainer:setContentSize(CCSizeMake(137, 63))
        rcontainer:setPosition(CCPoint(202, item_h/2))
        item:addChild(rcontainer)
        for ii=1,2 do
            if itemObj.reward and itemObj.reward[ii] then
                local tmp_obj = itemObj.reward[ii]
                local tmp_item
                if tmp_obj.type == 1 then  -- item
                    local tmp_item0 = img.createItem(tmp_obj.id, tmp_obj.num)
                    tmp_item = CCMenuItemSprite:create(tmp_item0, nil)
                elseif tmp_obj.type == 2 then  -- equip
                    local tmp_item0 = img.createEquip(tmp_obj.id, tmp_obj.num)
                    tmp_item = CCMenuItemSprite:create(tmp_item0, nil)
                end
                tmp_item:setScale(0.75)
                tmp_item:setPosition(CCPoint(32+(ii-1)*71, 32))
                tmp_item:registerScriptTapHandler(function()
                    audio.play(audio.button)
                    local tmp_tip
                    if tmp_obj.type == 1 then  -- item
                        tmp_tip = tipsitem.createForShow({id=tmp_obj.id})
                        layer:addChild(tmp_tip, 100)
                    elseif tmp_obj.type == 2 then  -- equip
                        tmp_tip = tipsequip.createById(tmp_obj.id)
                        layer:addChild(tmp_tip, 100)
                    end
                end)
                local tmp_item_menu = CCMenu:createWithItem(tmp_item)
                tmp_item_menu:setPosition(CCPoint(0, 0))
                rcontainer:addChild(tmp_item_menu)
            end
        end
        -- power
        local power_icon = img.createUISprite(img.ui.power_icon)
        power_icon:setScale(0.5)
        power_icon:setPosition(CCPoint(321, item_h/2))
        item:addChild(power_icon)
        local lbl_power = lbl.createFont1(18, num2KM(itemObj.power), ccc3(0x73, 0x3b, 0x05))
        lbl_power:setPosition(CCPoint(375, item_h/2))
        item:addChild(lbl_power)
        -- button
        local btn_ch0 = img.createLogin9Sprite(img.login.button_9_small_gold)
        btn_ch0:setPreferredSize(CCSizeMake(118, 45))
        if player.lv() >= itemObj.lv[1] then
            curlv = idx
            local lbl_btn_ch = lbl.createFont1(16, i18n.global.act_bboss_sweep.string, ccc3(0x73, 0x3b, 0x05))
            lbl_btn_ch:setPosition(CCPoint(59, 23))
            btn_ch0:addChild(lbl_btn_ch)
            local btn_ch = SpineMenuItem:create(json.ui.button, btn_ch0)
            btn_ch:setPosition(CCPoint(500, item_h/2))
            local btn_ch_menu = CCMenu:createWithItem(btn_ch)
            btn_ch_menu:setPosition(CCPoint(0, 0))
            item:addChild(btn_ch_menu)
            btn_ch:registerScriptTapHandler(function()
                disableObjAWhile(btn_ch)
                audio.play(audio.button)
                -- check fight times
                if dares.fight >= dares.buy+2 then
                    showToast(i18n.global.dare_times0.string)
                    return
                end
                layer:addChild(require("ui.selecthero.main").create({type = "challenge", data={type=_type, id=idx}}))
            end)
        else
            local lbl_btn_ch = lbl.createFont1(16, "Lv" .. itemObj.lv[1], ccc3(0x73, 0x3b, 0x05))
            lbl_btn_ch:setPosition(CCPoint(59, 23))
            btn_ch0:addChild(lbl_btn_ch)
            setShader(btn_ch0, SHADER_GRAY, true)
            btn_ch0:setPosition(CCPoint(500, item_h/2))
            item:addChild(btn_ch0)
        end

        return item
    end

    -- scroll_bg
    local SCROLL_VIEW_W = 600
    local SCROLL_VIEW_H = 314
    local scroll_bg = img.createUI9Sprite(img.ui.inner_bg)
    scroll_bg:setPreferredSize(CCSizeMake(SCROLL_VIEW_W, SCROLL_VIEW_H+8))
    scroll_bg:setAnchorPoint(CCPoint(0.5, 0))
    scroll_bg:setPosition(CCPoint(board_w/2, 32))
    board:addChild(scroll_bg)
    local lineScroll = require "ui.lineScroll"
    local scroll_params = {
        width = SCROLL_VIEW_W,
        height = SCROLL_VIEW_H,
    }
    local scroll = lineScroll.create(scroll_params)
    scroll:setAnchorPoint(CCPoint(0, 0))
    scroll:setPosition(CCPoint(0, 4))
    scroll_bg:addChild(scroll)

    local function showList(listObj)
        if not listObj or #listObj <= 0 then return end
        scroll.addSpace(6)
        for ii=1,#listObj do
            local tmp_item = createItem(listObj[ii], ii)
            tmp_item.ax = 0.5
            tmp_item.px = SCROLL_VIEW_W/2
            scroll.addItem(tmp_item)
            scroll.addSpace(2)
        end
        if curlv < 6 then
            scroll.setOffsetBegin()
        else
            scroll:setContentOffset(ccp(0, 0))
        end
    end
    showList(stages)


    layer:setTouchEnabled(true)
    layer:setTouchSwallowEnabled(true)

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
    
    local function onUpdate(ticks)
        updateCD(ticks)
    end
    layer:scheduleUpdateWithPriorityLua(onUpdate, 0)

    return layer
end

function ui.showBuy(parentLayer, _type, callback)
    local layer = CCLayer:create()
    local buyCount = 1
	
	local tdares = daredata.getDare(_type)
	buyCount = math.max(1, cfgvip[player.vipLv()].dareTime - tdares.buy)
	
    -- dark bg
    local sweepdarkbg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    layer:addChild(sweepdarkbg)
    -- board_bg
    local sweepboard_bg = img.createUI9Sprite(img.ui.dialog_1)
    sweepboard_bg:setPreferredSize(CCSizeMake(470, 380))
    sweepboard_bg:setScale(view.minScale)
    sweepboard_bg:setPosition(scalep(960/2, 576/2))
    layer:addChild(sweepboard_bg)
    local sweepboard_bg_w = sweepboard_bg:getContentSize().width
    local sweepboard_bg_h = sweepboard_bg:getContentSize().height

    -- edit
    local edit0 = img.createLogin9Sprite(img.login.input_border)
    local edit = CCEditBox:create(CCSizeMake(156*view.minScale, 40*view.minScale), edit0)
    edit:setInputMode(kEditBoxInputModeNumeric)
    edit:setReturnType(kKeyboardReturnTypeDone)
    edit:setMaxLength(5)
    edit:setFont("", 16*view.minScale)
    --edit:setPlaceHolder("0")
    edit:setText(""..buyCount)
    edit:setFontColor(ccc3(0x94, 0x62, 0x42))
    edit:setPosition(scalep(960/2, 308))
    --edit:setVisible(false)
    layer:addChild(edit, 1000)
    layer.edit = edit
    -- anim
    --sweepboard_bg:setScale(0.5)
    --sweepboard_bg:runAction(CCScaleTo:create(0.15, 1, 1))

    -- title
    local sweeplbl = lbl.createMixFont1(18, i18n.global.dare_buy_times.string, ccc3(0x73, 0x3b, 0x05))
    sweeplbl:setPosition(CCPoint(sweepboard_bg_w/2, 275))
    sweepboard_bg:addChild(sweeplbl)

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

    local icon_broken = img.createItemIcon2(ITEM_ID_GEM)
    icon_broken:setScale(0.8)
    icon_broken:setPosition(CCPoint(30, broken_bg:getContentSize().height/2))
    broken_bg:addChild(icon_broken)
    local tGem = 0
    if bagdata.items.find(ITEM_ID_GEM) then
        tGem = bagdata.items.find(ITEM_ID_GEM).num  
    end
    local lbl_pay = lbl.createFont2(16, tGem)
    lbl_pay:setPosition(CCPoint(100, broken_bg:getContentSize().height/2))
    broken_bg:addChild(lbl_pay)

    local function updatePay(_count)
        local tmp_str = num2KM(bagdata.gem()) .. "/" .. num2KM(_count*50)
        lbl_pay:setString(tmp_str)
    end
    updatePay(buyCount)

    local edit_tickets = layer.edit
    edit_tickets:registerScriptEditBoxHandler(function(eventType)
        if eventType == "returnSend" then
        elseif eventType == "return" then
        elseif eventType == "ended" then
            local tmp_ticket_count = edit_tickets:getText()
            tmp_ticket_count = string.trim(tmp_ticket_count)
            tmp_ticket_count = checkint(tmp_ticket_count)
            if tmp_ticket_count <= 0 then
                tmp_ticket_count = 0
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
            edt_txt = 0
            edit_tickets:setText(0)
            updatePay(0)
            buyCount = 0
            return
        end
        local ticket_count = checkint(edt_txt)
        if ticket_count <= 0 then
            edit_tickets:setText(0)
            updatePay(0)
            buyCount = 0
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
            local dares = daredata.getDare(_type)
            -- check buy
            if dares.buy + ticket_count >= cfgvip[player.vipLv()].dareTime then
                showToast(string.format(i18n.global.dare_vip_buy.string, player.vipLv(), cfgvip[player.vipLv()].dareTime))
                return
            end
            local tmp_gem_cost = ticket_count+1
            ticket_count = ticket_count + 1
            edit_tickets:setText(ticket_count)
            updatePay(ticket_count)
            buyCount = ticket_count
        end
    end)

    local function sweepbackEvent()
        audio.play(audio.button)
        layer:removeFromParentAndCleanup(true)
    end

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
        local edt_txt = edit_tickets:getText()
        edt_txt = string.trim(edt_txt)
        if edt_txt == "" then
            sweepbackEvent()
            return
        end
        local ticket_count = checkint(edt_txt)
        if ticket_count <= 0 then
            sweepbackEvent()
            return
        end
        local dares = daredata.getDare(_type)
        -- check buy
        if dares.buy + ticket_count > cfgvip[player.vipLv()].dareTime then
            showToast(string.format(i18n.global.dare_vip_buy.string, player.vipLv(), cfgvip[player.vipLv()].dareTime))
            return
        end
        -- check gems
        if bagdata.gem() < 50 * ticket_count then
            showToast(i18n.global.gboss_fight_st6.string)
            return
        end
        local nParams = {
            sid = player.sid,
            type = _type,
            num = ticket_count,
        }
        addWaitNet()
        netClient:dare_buy(nParams, function(__data)
            delWaitNet()
            tbl2string(__data)
            if __data.status ~= 0 then
                showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                return
            end
            bagdata.subGem(50*ticket_count)
            dares.buy = dares.buy + ticket_count
            if callback then
                callback()
            end
            showToast(i18n.global.toast_buy_okay.string)
            sweepbackEvent()
        end)
    end)

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

    layer:setTouchEnabled(true)
    layer:setTouchSwallowEnabled(true)

    addBackEvent(layer)
    function layer.onAndroidBack()
        sweepbackEvent()
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
    parentLayer:addChild(layer, 1000)
end

return ui
