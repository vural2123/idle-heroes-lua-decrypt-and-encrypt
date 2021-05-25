local ui = {}

require "common.func"
require "common.const"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local audio = require "res.audio"
local i18n = require "res.i18n"
local player = require "data.player"
local userdata = require "data.userdata"
local net = require "net.netClient"
local frdarena = require "data.arenac"

function ui.create(mbrs)
    local layer = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    -- board
    local board = img.createUI9Sprite(img.ui.dialog_1)
    board:setPreferredSize(CCSizeMake(642, 514))
    board:setScale(view.minScale)
    board:setPosition(view.midX, view.midY)
    layer:addChild(board)
    local board_w = board:getContentSize().width
    local board_h = board:getContentSize().height

    --inner bg
    local innerBg = img.createUI9Sprite(img.ui.bag_btn_inner_bg)
    innerBg:setPreferredSize(CCSizeMake(596, 416))
    innerBg:setAnchorPoint(0, 0)
    innerBg:setPosition(25, 30)
    board:addChild(innerBg)

    local showTitle = lbl.createFont1(26, i18n.global.frdpvp_team_invite.string, ccc3(0xe6, 0xd0, 0xae))
    showTitle:setPosition(board:getContentSize().width/2, 486)
    board:addChild(showTitle, 1)
    
    local showTitleShade = lbl.createFont1(26, i18n.global.frdpvp_team_invite.string, ccc3(0x59, 0x30, 0x1b))
    showTitleShade:setPosition(board:getContentSize().width/2, 484)
    board:addChild(showTitleShade)

    local teamnum = 0
    if mbrs then
        teamnum = #mbrs
    end
    local requestslab = lbl.createFont1(16, string.format(i18n.global.friend_requesrs_rcvd.string, teamnum), ccc3(0x49, 0x26, 0x04))
    requestslab:setAnchorPoint(CCPoint(0, 0.5))
    requestslab:setPosition(50, 405)
    board:addChild(requestslab)

    -- deleteall btn
    local deleteall = img.createLogin9Sprite(img.login.button_9_small_gold)
    deleteall:setPreferredSize(CCSizeMake(206, 40))
    local deletealllab = lbl.createFont1(16, i18n.global.friend_apply_delete.string, ccc3(0x73, 0x3b, 0x05))
    deletealllab:setPosition(CCPoint(deleteall:getContentSize().width/2,
                                     deleteall:getContentSize().height/2+1))
    deleteall:addChild(deletealllab)
    local deleteallBtn = SpineMenuItem:create(json.ui.button, deleteall)
    deleteallBtn:setPosition(CCPoint(497, 405))
    
    local deleteallMenu = CCMenu:createWithItem(deleteallBtn)
    deleteallMenu:setPosition(CCPoint(0, 0))
    board:addChild(deleteallMenu)

    local createinfoScroll = nil
    local scroll = nil

    local function createItem(_idx)
        local item = img.createUI9Sprite(img.ui.botton_fram_2)
        item:setPreferredSize(CCSizeMake(554, 90))
        local item_w = item:getContentSize().width
        local item_h = item:getContentSize().height

        local head = img.createPlayerHead(mbrs[_idx].logo)
        headBtn = SpineMenuItem:create(json.ui.button, head)
        headBtn:setScale(0.65)
        headBtn:setPosition(CCPoint(48, item_h/2+1))
        local headMenu = CCMenu:createWithItem(headBtn)
        headMenu:setPosition(0, 0)
        item:addChild(headMenu)

        headBtn:registerScriptTapHandler(function()
            audio.play(audio.button)
            --local params = {}
            --params.logo = mbrs[_idx].logo
            --params.uid = mbrs[_idx].uid
            --params.name = mbrs[_idx].name
            --params.frd = mbrs[_idx]
            layer:addChild((require"ui.arenac.mbrinfo").create(mbrs[_idx], "none"), 100)
        end)

        -- lv
        local lv_bg = img.createUISprite(img.ui.main_lv_bg)
        lv_bg:setPosition(CCPoint(106, item_h/2))
        item:addChild(lv_bg)
        local lbl_mem_lv = lbl.createFont1(14, mbrs[_idx].lv)
        lbl_mem_lv:setPosition(CCPoint(lv_bg:getContentSize().width/2, lv_bg:getContentSize().height/2))
        lv_bg:addChild(lbl_mem_lv)

        -- name
        local lbl_mem_name = lbl.createFontTTF(16, mbrs[_idx].name, ccc3(0x51, 0x27, 0x12))
        lbl_mem_name:setAnchorPoint(CCPoint(0, 0))
        lbl_mem_name:setPosition(CCPoint(136, 52))
        item:addChild(lbl_mem_name)

        powerBg = img.createUI9Sprite(img.ui.arena_frame7)
        powerBg:setPreferredSize(CCSize(147, 28))
        powerBg:setAnchorPoint(ccp(0, 0))
        powerBg:setPosition(136, 21)
        item:addChild(powerBg)

        local showPowerIcon = img.createUISprite(img.ui.power_icon)
        showPowerIcon:setScale(0.45)
        showPowerIcon:setPosition(136+14, 35)
        item:addChild(showPowerIcon)

        local showPower = lbl.createFont2(16, mbrs[_idx].power)
        showPower:setPosition(214, 35)
        item:addChild(showPower)
        
        local tickbtn = img.createLogin9Sprite(img.login.button_9_small_green)
        tickbtn:setPreferredSize(CCSizeMake(85, 40))
        local applyAgre = img.createUISprite(img.ui.friends_tick)
        applyAgre:setPosition(CCPoint(tickbtn:getContentSize().width/2,
                                         tickbtn:getContentSize().height/2))
        tickbtn:addChild(applyAgre)
        local applyAgreBtn = SpineMenuItem:create(json.ui.button, tickbtn)
        applyAgreBtn:setPosition(CCPoint(398, item_h/2+1))

        local applyAgreMenu = CCMenu:createWithItem(applyAgreBtn)
        applyAgreMenu:setPosition(CCPoint(0, 0))
        item:addChild(applyAgreMenu)
        
        local xbtn = img.createLogin9Sprite(img.login.button_9_small_orange)
        xbtn:setPreferredSize(CCSizeMake(85, 40))
        local applyNotagre = img.createUISprite(img.ui.friends_x)
        applyNotagre:setPosition(CCPoint(xbtn:getContentSize().width/2,
                                         xbtn:getContentSize().height/2))
        xbtn:addChild(applyNotagre)
        local applyNotagreBtn = SpineMenuItem:create(json.ui.button, xbtn)
        applyNotagreBtn:setPosition(CCPoint(488, item_h/2+1))

        local applyNotagreMenu = CCMenu:createWithItem(applyNotagreBtn)
        applyNotagreMenu:setPosition(CCPoint(0, 0))
        item:addChild(applyNotagreMenu)

        applyAgreBtn:registerScriptTapHandler(function()
            audio.play(audio.button)
            local param = {}
            param.sid = player.sid + 0x100
            param.type = 2
            param.uid = mbrs[_idx].uid
            
            if #frdarena.team >= 3 then
                showToast(i18n.global.frdpvp_team_teamfull.string)
                return 
            end
            addWaitNet()
            net:gpvp_leaderop(param, function(__data)
                delWaitNet()
                tbl2string(__data)
                if __data.status == -3 then
                    showToast(i18n.global.frdpvp_team_teamfull.string)
                    return
                end
                if __data.status == -2 then
                    showToast(i18n.global.frdpvp_team_inteam.string)
                    return
                end
                if __data.status ~= 0 then
                    showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                    return
                end
                
                frdarena.addTeammate(mbrs[_idx])
                teamnum = teamnum - 1
                requestslab:setString(string.format(i18n.global.friend_requesrs_rcvd.string, teamnum))
                table.remove(mbrs, _idx)                   
                if teamnum == 0 then
                    mbrs = nil
                end
                scroll:removeFromParentAndCleanup(true)
                scroll = nil
                createinfoScroll()
            end)
        end)

        applyNotagreBtn:registerScriptTapHandler(function()
            audio.play(audio.button)
            local param = {}
            param.sid = player.sid + 0x100
            param.type = 4
            param.uid = mbrs[_idx].uid
            
            addWaitNet()
            net:gpvp_leaderop(param, function(__data)
                delWaitNet()
                tbl2string(__data)
                if __data.status ~= 0 then
                    showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                    return
                end
                teamnum = teamnum - 1
                requestslab:setString(string.format(i18n.global.friend_requesrs_rcvd.string, teamnum))
                table.remove(mbrs, _idx)                   
                if teamnum == 0 then
                    mbrs = nil
                end
                scroll:removeFromParentAndCleanup(true)
                scroll = nil
                createinfoScroll()
            end)
        end)
        return item
    end

    local space_height = 2
    local function createScroll()
        local scroll_params = {
            width = 562,
            height = 321,
        }
        local lineScroll = require "ui.lineScroll"
        return lineScroll.create(scroll_params)
    end

    deleteallBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        
        if mbrs == nil then
            return
        end

        local param = {}
        param.sid = player.sid + 256
        param.type = 4
        param.uid = 0
        
        addWaitNet()
        net:gpvp_leaderop(param, function(__data)
            delWaitNet()
            tbl2string(__data)
            if __data.status ~= 0 then
                showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                return
            end
            requestslab:setString(string.format(i18n.global.friend_requesrs_rcvd.string, 0))
            mbrs = nil
            scroll:removeFromParentAndCleanup(true)
            scroll = nil
        end)
    end)


    function createinfoScroll()
        if mbrs then
            scroll = createScroll()
            scroll:setAnchorPoint(CCPoint(0, 0))
            scroll:setPosition(CCPoint(42, 50))
            board:addChild(scroll)
            --board.scroll = scroll
            --drawBoundingbox(board, scroll)
            for ii=1,#mbrs do
                local tmp_item = createItem(ii)
                --tmp_item.guildObj = params.mbrs[ii]
                tmp_item.ax = 0.5
                tmp_item.px = 562/2
                scroll.addItem(tmp_item)
                if ii ~= #mbrs then
                    scroll.addSpace(space_height)
                end
            end
            scroll:setOffsetBegin()
        end
    end
    
    createinfoScroll()

    local btnCloseSprite = img.createUISprite(img.ui.close)
    local btnClose = SpineMenuItem:create(json.ui.button, btnCloseSprite)
    btnClose:setPosition(615, 485)
    local menuClose = CCMenu:createWithItem(btnClose)
    menuClose:setPosition(0, 0)
    board:addChild(menuClose)
    btnClose:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer:removeFromParentAndCleanup(true)
    end)

    addBackEvent(layer)
    function layer.onAndroidBack()
        layer:removeFromParentAndCleanup(true)
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

    layer:registerScriptTouchHandler(function() return true end)
    layer:setTouchEnabled(true)

    board:setScale(0.5*view.minScale)
    local anim_arr = CCArray:create()
    anim_arr:addObject(CCScaleTo:create(0.15, 1*view.minScale, 1*view.minScale))
    anim_arr:addObject(CCDelayTime:create(0.15))
    anim_arr:addObject(CCCallFunc:create(function()
    end))
    board:runAction(CCSequence:create(anim_arr))

    return layer
end

return ui
