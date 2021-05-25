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
local player = require "data.player"
local bagdata = require "data.bag"
local gdata = require "data.guild"
local i18n = require "res.i18n"
local tipsequip = require "ui.tips.equip"
local tipsitem = require "ui.tips.item"
local dialog = require "ui.dialog"
local board1 = require "ui.guild.board1"
local NetClient = require "net.netClient"
local netClient = NetClient:getInstance()

function ui.create()
    local layer = CCLayer:create()
    -- dark bg
    local darkbg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    layer:addChild(darkbg)

    local bg = img.createUI9Sprite(img.ui.dialog_1)
    bg:setPreferredSize(CCSizeMake(706, 496))
    bg:setScale(view.minScale)
    bg:setPosition(CCPoint(view.midX, view.midY-0*view.minScale))
    layer:addChild(bg)
    local bg_w = bg:getContentSize().width
    local bg_h = bg:getContentSize().height

    bg:setScale(0.5*view.minScale)
    local anim_arr = CCArray:create()
    anim_arr:addObject(CCScaleTo:create(0.15, 1*view.minScale, 1*view.minScale))
    -- anim
    bg:runAction(CCSequence:create(anim_arr))

    local function backEvent()
        audio.play(audio.button)
        layer:removeFromParentAndCleanup(true)
    end

    -- btn_close
    local btn_close0 = img.createUISprite(img.ui.close)
    local btn_close = SpineMenuItem:create(json.ui.button, btn_close0)
    btn_close:setPosition(CCPoint(bg_w-25, bg_h-28))
    local btn_close_menu = CCMenu:createWithItem(btn_close)
    btn_close_menu:setPosition(CCPoint(0, 0))
    bg:addChild(btn_close_menu, 100)
    btn_close:registerScriptTapHandler(function()
        backEvent()
    end)

    -- title
    local lbl_title = lbl.createFont1(24, i18n.global.guild_modify_board_title.string, ccc3(0xe6, 0xd0, 0xae))
    lbl_title:setPosition(CCPoint(bg_w/2, bg_h-29))
    bg:addChild(lbl_title, 2)
    local lbl_title_shadowD = lbl.createFont1(24, i18n.global.guild_modify_board_title.string, ccc3(0x59, 0x30, 0x1b))
    lbl_title_shadowD:setPosition(CCPoint(bg_w/2, bg_h-31))
    bg:addChild(lbl_title_shadowD)

    -- board
    local board = img.createUI9Sprite(img.ui.bag_btn_inner_bg)
    board:setPreferredSize(CCSizeMake(640, 388))
    board:setAnchorPoint(CCPoint(0.5, 0))
    board:setPosition(CCPoint(bg_w/2, 36))
    bg:addChild(board)
    layer.board = board
    local board_w = board:getContentSize().width
    local board_h = board:getContentSize().height

    local x_offset = -70
    -- name
    --local lbl_name_des = lbl.createFont1(22, i18n.global.guild_create_guild_name.string, ccc3(0x49, 0x26, 0x04))
    --lbl_name_des:setAnchorPoint(CCPoint(1, 0.5))
    --lbl_name_des:setPosition(CCPoint(x_offset+136, 329))
    --board:addChild(lbl_name_des)
    local name_bg = img.createLogin9Sprite(img.login.input_border)
    name_bg:setPreferredSize(CCSizeMake(455, 40))
    name_bg:setAnchorPoint(CCPoint(0, 0.5))
    name_bg:setPosition(CCPoint(x_offset+132, 334))
    board:addChild(name_bg)
    local lbl_name = lbl.createFontTTF(18, gdata.guildObj.name or "", ccc3(0x49, 0x26, 0x04))
    lbl_name:setAnchorPoint(CCPoint(0, 0.5))
    lbl_name:setPosition(CCPoint(15, name_bg:getContentSize().height/2))
    name_bg:addChild(lbl_name)
    local btn_name0 = img.createLogin9Sprite(img.login.button_9_small_gold)
    btn_name0:setPreferredSize(CCSizeMake(60, 42))
    local icon_name = img.createUISprite(img.ui.guild_icon_edit)
    icon_name:setPosition(CCPoint(btn_name0:getContentSize().width/2, btn_name0:getContentSize().height/2+1))
    btn_name0:addChild(icon_name)
    local btn_name = SpineMenuItem:create(json.ui.button, btn_name0)
    btn_name:setPosition(CCPoint(x_offset+622, 334))
    local btn_name_menu = CCMenu:createWithItem(btn_name)
    btn_name_menu:setPosition(CCPoint(0, 0))
    board:addChild(btn_name_menu)
    btn_name:registerScriptTapHandler(function()
        audio.play(audio.button)
        local gname = require "ui.guild.gname"
        local function onName(_str)
            local name_str = _str or ""
            name_str = string.trim(name_str)
            if isBanWord(name_str) then 
                showToast(i18n.global.input_invalid_char.string)
                return 
            end
            if containsInvalidChar(name_str) then
                showToast(i18n.global.input_invalid_char.string)
                return
            end
            if name_str == lbl_name:getString() then return end
            if not name_str or name_str == "" then
                showToast(i18n.global.guild_create_name_empty.string)
                return
            end
            if #name_str > 16 then
                showToast(string.format(i18n.global.guild_name_length.string, 16))
                return
            end
            local gParams = {
                sid = player.sid,
                name = name_str,
            }
            addWaitNet()
            netClient:guild_name(gParams, function(__data)
                delWaitNet()
                tbl2string(__data)
                if __data.status ~= 0 then
                    if __data.status == -1 then
                        showToast(i18n.global.guild_name_24h.string)
                        return
                    elseif __data.status == -2 then
                        showToast(string.format(i18n.global.guild_modify_name_cost.string, gdata.NAME_COST))
                        return
                    elseif __data.status == -11 then
                        showToast(i18n.global.input_invalid_char.string)
                        return
                    elseif __data.status == -3 then
                        showToast(i18n.global.guild_name_exist.string)
                        return
                    end
                    showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                    return
                end
                bagdata.subGem(gdata.NAME_COST)
                gdata.guildObj.name = name_str
                lbl_name:setString(name_str)
                showToast(i18n.global.guild_modify_ok.string)
            end)
        end
        layer:addChild(gname.create(onName), 1000)
    end)

    -- flag
    local sel_flag = 1
    if gdata.guildObj and gdata.guildObj.logo then
        sel_flag = gdata.guildObj.logo
    end
    --local lbl_flag_des = lbl.createFont1(22, i18n.global.guild_create_flag_des.string, ccc3(0x49, 0x26, 0x04))
    --lbl_flag_des:setAnchorPoint(CCPoint(1, 0.5))
    --lbl_flag_des:setPosition(CCPoint(x_offset+136, 265))
    --board:addChild(lbl_flag_des)
    local flag_container = CCSprite:create()
    flag_container:setContentSize(CCSizeMake(70, 73))
    flag_container:setPosition(CCPoint(x_offset+168, 264))
    board:addChild(flag_container)
    local function updateFlag(_flag)
        flag_container:removeAllChildrenWithCleanup(true)
        local guild_flag = img.createGFlag(_flag)
        guild_flag:setAnchorPoint(CCPoint(0, 0))
        guild_flag:setPosition(CCPoint(0, 0))
        flag_container:addChild(guild_flag)
        flag_container.flag = guild_flag
        sel_flag = _flag
    end
    local function netUpdateFlag(_flag)
        if _flag == sel_flag then return end
        local gParams = {
            sid = player.sid,
            id = _flag,
        }
        addWaitNet()
        netClient:guild_flag(gParams, function(__data)
            delWaitNet()
            tbl2string(__data)
            if __data.status ~= 0 then
                showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                return
            end
            updateFlag(_flag)
            gdata.guildObj.logo = _flag
            showToast(i18n.global.guild_modify_ok.string)
        end)
    end
    --updateFlag(gdata.guildObj.logo)
    updateFlag(sel_flag)
    local btn_flag0 = img.createLogin9Sprite(img.login.button_9_small_gold)
    btn_flag0:setPreferredSize(CCSizeMake(146, 50))
    local lbl_flag = lbl.createFont1(18, i18n.global.guild_create_flag_sel.string, ccc3(0x73, 0x3b, 0x05))
    lbl_flag:setPosition(CCPoint(btn_flag0:getContentSize().width/2, btn_flag0:getContentSize().height/2))
    btn_flag0:addChild(lbl_flag)
    local btn_flag = SpineMenuItem:create(json.ui.button, btn_flag0)
    btn_flag:setPosition(CCPoint(x_offset+313, 270))
    local btn_flag_menu = CCMenu:createWithItem(btn_flag)
    btn_flag_menu:setPosition(CCPoint(0, 0))
    board:addChild(btn_flag_menu)
    btn_flag:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer:addChild((require"ui.guild.flag").create(function(_flag)
            netUpdateFlag(_flag)
        end, sel_flag), 1000)
    end)

    -- notice
    --local lbl_notice_des = lbl.createFont1(22, i18n.global.guild_create_notice_des.string, ccc3(0x49, 0x26, 0x04))
    --lbl_notice_des:setAnchorPoint(CCPoint(1, 0.5))
    --lbl_notice_des:setPosition(CCPoint(x_offset+136, 207))
    --board:addChild(lbl_notice_des)
    local btn_notice0 = img.createLogin9Sprite(img.login.input_border)
    btn_notice0:setPreferredSize(CCSizeMake(518, 110))
    local btn_notice = CCMenuItemSprite:create(btn_notice0, nil)
    btn_notice:setAnchorPoint(CCPoint(0, 0))
    btn_notice:setPosition(CCPoint(x_offset+132, 108))
    local btn_notice_menu = CCMenu:createWithItem(btn_notice)
    btn_notice_menu:setPosition(CCPoint(0, 0))
    board:addChild(btn_notice_menu)
    local lbl_notice = lbl.create({kind="ttf", size=18, text=gdata.guildObj.notice or "", color=ccc3(0x70, 0x4a, 0x2b),})
    lbl_notice:setHorizontalAlignment(kCCTextAlignmentLeft)
    lbl_notice:setDimensions(CCSizeMake(488, 0))
    lbl_notice:setAnchorPoint(CCPoint(0, 1))
    lbl_notice:setPosition(CCPoint(15, btn_notice:getContentSize().height-15))
    btn_notice:addChild(lbl_notice)

    btn_notice:registerScriptTapHandler(function()
        audio.play(audio.button)
        local inputlayer = require "ui.inputlayer"
        local function onNotice(_str)
            local notice_str = _str or ""
            notice_str = string.trim(notice_str)
            if isBanWord(notice_str) then 
                showToast(i18n.global.input_invalid_char.string)
                return 
            end
            if containsInvalidChar(notice_str) then
                showToast(i18n.global.input_invalid_char.string)
                return
            end
            if notice_str == lbl_notice:getString() then return end
            local gParams = {
                sid = player.sid,
                notice = notice_str,
            }
            addWaitNet()
            netClient:guild_notice(gParams, function(__data)
                delWaitNet()
                tbl2string(__data)
                if __data.status ~= 0 then
                    showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                    return
                end
                gdata.guildObj.notice = gParams.notice
                lbl_notice:setString(notice_str)
                showToast(i18n.global.guild_modify_ok.string)
            end)
        end
        layer:addChild(inputlayer.create(onNotice, lbl_notice:getString()), 1000)
    end)

    -- btn_dissmiss  president
    local btn_dissmiss0 = img.createLogin9Sprite(img.login.button_9_small_orange)
    btn_dissmiss0:setPreferredSize(CCSizeMake(196, 50))
    local lbl_dissmiss = lbl.createFont1(16, i18n.global.guild_admin_dismiss.string, ccc3(0x83, 0x34, 0x15))
    lbl_dissmiss:setPosition(CCPoint(btn_dissmiss0:getContentSize().width/2, btn_dissmiss0:getContentSize().height/2))
    btn_dissmiss0:addChild(lbl_dissmiss)
    local btn_dissmiss = SpineMenuItem:create(json.ui.button, btn_dissmiss0)
    btn_dissmiss:setPosition(CCPoint(board_w/2, 56))
    local btn_dissmiss_menu = CCMenu:createWithItem(btn_dissmiss)
    btn_dissmiss_menu:setPosition(CCPoint(0, 0))
    board:addChild(btn_dissmiss_menu)
    -- btn_cancel  president
    local btn_cancel0 = img.createLogin9Sprite(img.login.button_9_small_green)
    btn_cancel0:setPreferredSize(CCSizeMake(196, 50))
    local lbl_cancel = lbl.createFont1(18, i18n.global.guild_admin_undismiss.string, ccc3(0x1d, 0x67, 0x00))
    lbl_cancel:setPosition(CCPoint(btn_cancel0:getContentSize().width/2, btn_cancel0:getContentSize().height/2))
    btn_cancel0:addChild(lbl_cancel)
    local btn_cancel = SpineMenuItem:create(json.ui.button, btn_cancel0)
    btn_cancel:setPosition(CCPoint(board_w/2, 56))
    local btn_cancel_menu = CCMenu:createWithItem(btn_cancel)
    btn_cancel_menu:setPosition(CCPoint(0, 0))
    board:addChild(btn_cancel_menu)
    local lbl_cancel_cd = lbl.createFont2(16, "", ccc3(0xb5, 0xff, 0x5e))
    lbl_cancel_cd:setPosition(CCPoint(board_w/2, 93))
    lbl_cancel_cd:setVisible(false)
    board:addChild(lbl_cancel_cd)
    ---- btn_quit officer
    --local btn_quit0 = img.createLogin9Sprite(img.login.button_9_small_orange)
    --btn_quit0:setPreferredSize(CCSizeMake(196, 50))
    --local lbl_quit = lbl.createFont1(21, i18n.global.guild_admin_quit.string, ccc3(0x83, 0x34, 0x15))
    --lbl_quit:setPosition(CCPoint(btn_quit0:getContentSize().width/2, btn_quit0:getContentSize().height/2))
    --btn_quit0:addChild(lbl_quit)
    --local btn_quit = SpineMenuItem:create(json.ui.button, btn_quit0)
    --btn_quit:setPosition(CCPoint(board_w/2, 62))
    --local btn_quit_menu = CCMenu:createWithItem(btn_quit)
    --btn_quit_menu:setPosition(CCPoint(0, 0))
    --board:addChild(btn_quit_menu)

    local self_title = gdata.selfTitle()
    if self_title == gdata.TITLE.PRESIDENT then
        if gdata.guildObj.dismiss_cd and gdata.guildObj.dismiss_cd > (os.time() - gdata.last_pull)then
            btn_dissmiss:setVisible(false)
            --btn_quit:setVisible(false)
            btn_cancel:setVisible(true)
            lbl_cancel_cd:setVisible(true)
        else
            --btn_quit:setVisible(false)
            btn_dissmiss:setVisible(true)
            btn_cancel:setVisible(false)
            lbl_cancel_cd:setVisible(false)
        end
    elseif self_title == gdata.TITLE.OFFICER then
            --btn_quit:setVisible(true)
            btn_dissmiss:setVisible(false)
            btn_cancel:setVisible(false)
            lbl_cancel_cd:setVisible(false)
    end

    btn_dissmiss:registerScriptTapHandler(function()
        audio.play(audio.button)
        local function doDismiss()
            local gParams = {
                sid = player.sid,
                dismiss = 1,
            }
            addWaitNet()
            netClient:guild_dismiss(gParams, function(__data)
                delWaitNet()
                tbl2string(__data)
                if __data.status == -1 then
                    showToast(i18n.global.guild_dissmiss_toast.string)
                    return
                end
                if __data.status ~= 0 then
                    showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                    return
                end
                gdata.guildObj.dismiss_cd = 3600 * 2 + os.time() - gdata.last_pull
                btn_dissmiss:setVisible(false)
                btn_cancel:setVisible(true)
                lbl_cancel_cd:setVisible(true)
            end)
        end
        local function process_dialog(__data)
            layer:removeChildByTag(dialog.TAG)
            if __data.selected_btn == 2 then
                -- button confirm
                doDismiss()
            elseif __data.selected_btn == 1 then
                -- button Cancel
            end
        end
        local dialog_params = {
            title = "",
            body = string.format(i18n.global.guild_admin_dlg_body.string, 2),
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

    btn_cancel:registerScriptTapHandler(function()
        audio.play(audio.button)
        local gParams = {
            sid = player.sid,
            nodismiss = 1,
        }
        addWaitNet()
        netClient:guild_dismiss(gParams, function(__data)
            delWaitNet()
            tbl2string(__data)
            if __data.status ~= 0 then
                showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                return
            end
            gdata.guildObj.dismiss_cd = nil
            btn_dissmiss:setVisible(true)
            btn_cancel:setVisible(false)
            lbl_cancel_cd:setVisible(false)
        end)
    end)

    --btn_quit:registerScriptTapHandler(function()
    --    audio.play(audio.button)
    --    local dialog = require "ui.dialog"
    --    local function process_dialog(data)
    --        layer:removeChildByTag(dialog.TAG)
    --        if data.selected_btn == 2 then
    --            local gParams = {
    --                sid = player.sid,
    --            }
    --            addWaitNet(function()
    --                delWaitNet()
    --                showToast(i18n.global.error_network_timeout.string)
    --            end)
    --            netClient:guild_leave(gParams, function(__data)
    --                delWaitNet()
    --                tbl2string(__data)
    --                if __data.status ~= 0 then
    --                    showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
    --                    return
    --                end
    --                player.gid = 0
    --                replaceScene((require"ui.town.main").create())
    --            end)
    --        elseif data.selected_btn == 1 then
    --        end
    --    end
    --    local params = {
    --        title = "",
    --        body = i18n.global.guild_dlg_quit_body.string,
    --        btn_count = 2,
    --        btn_color = {
    --            [1] = dialog.COLOR_BLUE,
    --            [2] = dialog.COLOR_GOLD,
    --        },
    --        btn_text = {
    --            [1] = i18n.global.dialog_button_cancel.string,
    --            [2] = i18n.global.dialog_button_confirm.string,
    --        },
    --        callback = process_dialog,
    --    }
    --    local dialog_ins = dialog.create(params, true)
    --    dialog_ins:setAnchorPoint(CCPoint(0,0))
    --    dialog_ins:setPosition(CCPoint(0,0))
    --    layer:addChild(dialog_ins, 10000, dialog.TAG)
    --end)

    local last_update = os.time()
    local function onUpdate(ticks)
        if os.time() - last_update < 1 then return end
        last_update = os.time()
        local self_title = gdata.selfTitle()
        if self_title < gdata.TITLE.PRESIDENT then return end
        if gdata.guildObj.dismiss_cd then
            local remain_time = gdata.guildObj.dismiss_cd - (os.time() - gdata.last_pull)
            if remain_time < 0 then
                gdata.deInit()
                player.gid = 0 
                replaceScene((require"ui.town.main").create())
                return
            end
            local time_str = time2string(remain_time) 
            lbl_cancel_cd:setString(time_str)
            btn_dissmiss:setVisible(false)
            --btn_quit:setVisible(false)
            btn_cancel:setVisible(true)
            lbl_cancel_cd:setVisible(true)
        else
            --btn_quit:setVisible(false)
            btn_dissmiss:setVisible(true)
            btn_cancel:setVisible(false)
            lbl_cancel_cd:setVisible(false)
        end
    end
    
    layer:scheduleUpdateWithPriorityLua(onUpdate, 0)
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
