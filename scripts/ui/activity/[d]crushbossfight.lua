local ui = {}

require "common.func"
require "common.const"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local audio = require "res.audio"
local cfgitem = require "config.item"
local cfgequip = require "config.equip"
local cfgfriendstage = require "config.brokenboss"
local cfgmonster = require "config.monster"
local player = require "data.player"
local i18n = require "res.i18n"
local tipsequip = require "ui.tips.equip"
local tipsitem = require "ui.tips.item"
local selecthero = require "ui.selecthero.main"
local net = require "net.netClient"
local friendboss = require "data.friendboss"
local bag = require "data.bag"

function ui.create(doorId, handler)
    local layer = CCLayer:create()

    -- dark bg
    local darkbg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    layer:addChild(darkbg)
    -- board_bg
    local board_bg = img.createUI9Sprite(img.ui.dialog_1)
    board_bg:setPreferredSize(CCSizeMake(735, 470))
    board_bg:setScale(view.minScale)
    board_bg:setPosition(view.midX, view.midY)
    layer:addChild(board_bg)
    local board_bg_w = board_bg:getContentSize().width
    local board_bg_h = board_bg:getContentSize().height

    -- anim
    board_bg:setScale(0.5*view.minScale)
    board_bg:runAction(CCScaleTo:create(0.15, 1*view.minScale, 1*view.minScale))

    -- title
    local lbl_title = lbl.createFont1(24, i18n.global.friendboss_enemy_line.string, ccc3(0xe6, 0xd0, 0xae))
    lbl_title:setPosition(CCPoint(board_bg_w/2, board_bg_h-29))
    board_bg:addChild(lbl_title, 2)
    local lbl_title_shadowD = lbl.createFont1(24, i18n.global.friendboss_enemy_line.string, ccc3(0x59, 0x30, 0x1b))
    lbl_title_shadowD:setPosition(CCPoint(board_bg_w/2, board_bg_h-31))
    board_bg:addChild(lbl_title_shadowD)

    local heroCampBg = img.createUI9Sprite(img.ui.select_hero_camp_bg)
    heroCampBg:setPreferredSize(CCSize(678, 230))
    heroCampBg:setPosition(367, 280)
    board_bg:addChild(heroCampBg, 1)

    local selectTeamBg = img.createUI9Sprite(img.ui.select_tab_tab_bg)
    selectTeamBg:setPreferredSize(CCSize(665, 37))
    selectTeamBg:setPosition(340, 200)
    heroCampBg:addChild(selectTeamBg)

    local enegyBottom = img.createUI9Sprite(img.ui.main_coin_bg)
    enegyBottom:setPreferredSize(CCSizeMake(138, 40))
    enegyBottom:setPosition(CCPoint(80, selectTeamBg:getContentSize().height/2-2))
    selectTeamBg:addChild(enegyBottom)

    local tick_num = 0
    if bag.items.find(ITEM_ID_BROKEN) then
        tick_num = bag.items.find(ITEM_ID_BROKEN).num
    end
    local enegy = string.format("%d", tick_num) 
    local showEnegy = lbl.createFont2(18, enegy, ccc3(255, 246, 223))
    showEnegy:setPosition(CCPoint(enegyBottom:getContentSize().width/2+5, 
                                enegyBottom:getContentSize().height/2+2))
    enegyBottom:addChild(showEnegy)

    local enegyIcon = img.createUISprite(img.ui.friends_enegy)
    local enegyIcon = img.createItemIcon2(ITEM_ID_BROKEN)
    enegyIcon:setPosition(8, enegyBottom:getContentSize().height/2+4)
    enegyBottom:addChild(enegyIcon)

    local function showRewardlayer(reward, num)
        handler(-num)
        layer:getParent():addChild((require"ui.hook.drops").create(reward, i18n.global.mail_rewards.string), 1000)
        layer:removeFromParent()
    end

    local buyCount = 1
    local function selectSweepnumLayer(__data)
        local sweepLayer = CCLayer:create()
        buyCount = 1
        -- dark bg
        local sweepdarkbg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
        sweepLayer:addChild(sweepdarkbg)
        -- board_bg
        local sweepboard_bg = img.createUI9Sprite(img.ui.dialog_1)
        sweepboard_bg:setPreferredSize(CCSizeMake(470, 380))
        sweepboard_bg:setScale(view.minScale)
        sweepboard_bg:setPosition(scalep(960/2, 576/2))
        sweepLayer:addChild(sweepboard_bg)
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
        edit:setText("1")
        edit:setFontColor(ccc3(0x94, 0x62, 0x42))
        edit:setPosition(scalep(960/2, 308))
        --edit:setVisible(false)
        sweepLayer:addChild(edit, 1000)
        sweepLayer.edit = edit
        -- anim
        --sweepboard_bg:setScale(0.5)
        --sweepboard_bg:runAction(CCScaleTo:create(0.15, 1, 1))

        -- title
        local sweeplbl_title = lbl.createFont1(24, i18n.global.act_bboss_sweep.string, ccc3(0xe6, 0xd0, 0xae))
        sweeplbl_title:setPosition(CCPoint(sweepboard_bg_w/2, sweepboard_bg_h-29))
        sweepboard_bg:addChild(sweeplbl_title, 2)
        local sweeplbl_title_shadowD = lbl.createFont1(24, i18n.global.act_bboss_sweep.string, ccc3(0x59, 0x30, 0x1b))
        sweeplbl_title_shadowD:setPosition(CCPoint(sweepboard_bg_w/2, sweepboard_bg_h-31))
        sweepboard_bg:addChild(sweeplbl_title_shadowD)
        
        local sweeplbl = lbl.createMixFont1(18, i18n.global.act_bboss_sweep_lable.string, ccc3(0x73, 0x3b, 0x05))
        sweeplbl:setPosition(CCPoint(sweepboard_bg_w/2, 275))
        sweepboard_bg:addChild(sweeplbl)

        -- ticket icon
        local icon_ticket = img.createItem(ITEM_ID_TRIAL_TL)--img.createUISprite(img.ui.casino_chip)
        icon_ticket:setPosition(CCPoint(board_bg_w/2, 309))
        board_bg:addChild(icon_ticket)

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

        local icon_broken = img.createItemIcon2(ITEM_ID_BROKEN)
        icon_broken:setScale(0.8)
        icon_broken:setPosition(CCPoint(30, broken_bg:getContentSize().height/2))
        broken_bg:addChild(icon_broken)
        local brokennum = 0
        if bag.items.find(ITEM_ID_BROKEN) then
            brokennum = bag.items.find(ITEM_ID_BROKEN).num  
        end
        local lbl_pay = lbl.createFont2(16, brokennum)
        lbl_pay:setPosition(CCPoint(100, broken_bg:getContentSize().height/2))
        broken_bg:addChild(lbl_pay)

        --local function updatePay(_count)
        --    local tmp_str = num2KM(bag.gem()) .. "/" .. num2KM(_count*COST_PER_TICKET)
        --    lbl_pay:setString(tmp_str)
        --end

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
                --updatePay(tmp_ticket_count)
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
                --updatePay(0)
                buyCount = 1
                return
            end
            local ticket_count = checkint(edt_txt)
            if ticket_count <= 1 then
                edit_tickets:setText(1)
                --updatePay(0)
                buyCount = 1
                return
            else
                ticket_count = ticket_count - 1
                edit_tickets:setText(ticket_count)
                --updatePay(ticket_count)
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
                --updatePay(0)
                buyCount = 0
                return
            end
            local ticket_count = checkint(edt_txt)
            if ticket_count < 0 then
                edit_tickets:setText(0)
                --updatePay(0)
                buyCount = 0
                return
            else
                local tmp_gem_cost = ticket_count+1
                if tmp_gem_cost > brokennum then
                    --local gotoStoreDialog = require "uikit.gotoStoreDialog"
                    --gotoStoreDialog.show(layer, "casino")
                    return
                end
                ticket_count = ticket_count + 1
                edit_tickets:setText(ticket_count)
                --updatePay(ticket_count)
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
            if buyCount > brokennum then 
                showToast(i18n.global.tips_act_ticket_lack.string)
                return
            end
            layer:addChild(selecthero.create({type = "sweepforbrokenboss", stage = __data.id, num = buyCount, callback = showRewardlayer}))
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

    local battleBtn = nil 

    local function initenemy()
        local gParams = {
            sid = player.sid,
            id = doorId,
        }
        addWaitNet()
    
        net:bboss_syn(gParams, function(__data)
            delWaitNet()
            tbl2string(__data)

            if __data.status == -2 then
                showToast(i18n.global.friendboss_boss_die.string)
                layer:removeFromParentAndCleanup(true)
                return
            end

            if __data.status ~= 0 then
                showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                return
            end
           
            bossId = __data.id
            local cfgbrokenboss = require "config.brokenboss"
            local sx = 25
            local px = 90
            if #cfgfriendstage[__data.id].monster == 5 then
                sx = 70
            end
            if #cfgfriendstage[__data.id].monster == 4 then
                sx = 70 + 45
            end
            if #cfgfriendstage[__data.id].monster == 3 then
                sx = 70 + 90
            end
            if #cfgfriendstage[__data.id].monster == 2 then
                sx = 70 + 135
            end
            if #cfgfriendstage[__data.id].monster == 1 then
                sx = 70 + 180
            end
            for ii = 1,#cfgfriendstage[__data.id].monster do 
                local info = cfgmonster[cfgfriendstage[__data.id].monster[ii]]
                local bossIcon = img.createHeroHead(info.heroLink, info.lvShow, true, info.star)
                bossIcon:setScale(0.85)
                bossIcon:setPosition(sx+px*ii, 120)
                heroCampBg:addChild(bossIcon)
            end

            -- power bar
            local bloodBar = img.createUI9Sprite(img.ui.fight_hurts_bar_bg)
            bloodBar:setPreferredSize(CCSize(290, 22))
            
            bloodBar:setPosition(340, 40)
            heroCampBg:addChild(bloodBar)

            local progress0 = img.createUISprite(img.ui.friends_boss_blood)
            local bloodProgress = createProgressBar(progress0)
            bloodProgress:setPosition(bloodBar:getContentSize().width/2, bloodBar:getContentSize().height/2)
            bloodProgress:setPercentage(__data.hp)
            bloodBar:addChild(bloodProgress)

            local progressStr = string.format("%d%%", __data.hp)
            local progressLabel = lbl.createFont2(16, progressStr, ccc3(255, 246, 223))
            progressLabel:setPosition(CCPoint(145, bloodBar:getContentSize().height/2+5))
            bloodBar:addChild(progressLabel)

            local sweepSprite = img.createLogin9Sprite(img.login.button_9_small_green)
            sweepSprite:setPreferredSize(CCSize(170, 56))
            local sweeplab = lbl.createFont1(22, i18n.global.act_bboss_sweep.string, ccc3(0x1d, 0x67, 0x00))
            sweeplab:setPosition(CCPoint(sweepSprite:getContentSize().width/2,
                                            sweepSprite:getContentSize().height/2))
            sweepSprite:addChild(sweeplab)

            sweepBtn = SpineMenuItem:create(json.ui.button, sweepSprite)
            sweepBtn:setPosition(CCPoint(367-95, 90))
            
            local sweepMenu = CCMenu:createWithItem(sweepBtn)
            sweepMenu:setPosition(0,0)
            board_bg:addChild(sweepMenu)

            sweepBtn:registerScriptTapHandler(function()
                disableObjAWhile(sweepBtn)
                audio.play(audio.button) 
                if player.lv() < UNLOCK_ACT_BROKEN then
                    showToast(string.format(i18n.global.func_need_lv.string, UNLOCK_ACT_BROKEN))
                    return
                end
                layer:addChild(selectSweepnumLayer(__data))
            end)

            local battleSprite = img.createLogin9Sprite(img.login.button_9_small_gold)
            battleSprite:setPreferredSize(CCSize(170, 56))
            local battlelab = lbl.createFont1(22, i18n.global.trial_stage_btn_battle.string, ccc3(0x7e, 0x27, 0x00))
            battlelab:setPosition(CCPoint(battleSprite:getContentSize().width/2,
                                            battleSprite:getContentSize().height/2))
            battleSprite:addChild(battlelab)

            battleBtn = SpineMenuItem:create(json.ui.button, battleSprite)
            battleBtn:setPosition(CCPoint(367+95, 90))
            
            local battleMenu = CCMenu:createWithItem(battleBtn)
            battleMenu:setPosition(0,0)
            board_bg:addChild(battleMenu)

            battleBtn:registerScriptTapHandler(function()
                disableObjAWhile(battleBtn)
                audio.play(audio.button) 
                if player.lv() < UNLOCK_ACT_BROKEN then
                    showToast(string.format(i18n.global.func_need_lv.string, UNLOCK_ACT_BROKEN))
                    return
                end
                layer:addChild(selecthero.create({type = "brokenboss", stage = __data.id}))
            end)

            if __data.cd then
                refcd = __data.cd
                pull_ref_time = os.time()
                layer:scheduleUpdateWithPriorityLua(onUpdate, 0)
            end
            if __data.hp == 0 and bossId and cfgbrokenboss[bossId].next == nil then
                setShader(battleBtn, SHADER_GRAY, true)
                battleBtn:setEnabled(false)
                setShader(sweepBtn, SHADER_GRAY, true)
                sweepBtn:setEnabled(false)
            end
        end)
    end

    initenemy()

    local function backEvent()
        audio.play(audio.button)
        layer:removeFromParentAndCleanup(true)
    end

    -- btn_close
    local btn_close0 = img.createUISprite(img.ui.close)
    local btn_close = SpineMenuItem:create(json.ui.button, btn_close0)
    btn_close:setPosition(CCPoint(board_bg_w-25, board_bg_h-28))
    local btn_close_menu = CCMenu:createWithItem(btn_close)
    btn_close_menu:setPosition(CCPoint(0, 0))
    board_bg:addChild(btn_close_menu, 100)
    btn_close:registerScriptTapHandler(function()
        backEvent()
    end)

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

    return layer
end

return ui
