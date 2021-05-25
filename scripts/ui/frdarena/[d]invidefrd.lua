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
local friend = require "data.friend"

function ui.create(mbrs)
    local layer = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    -- board
    local board = img.createUI9Sprite(img.ui.dialog_1)
    board:setPreferredSize(CCSizeMake(646, 514))
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

    local showTitle = lbl.createFont1(26, i18n.global.frdpvp_invitable_list.string, ccc3(0xe6, 0xd0, 0xae))
    showTitle:setPosition(board:getContentSize().width/2, 486)
    board:addChild(showTitle, 1)
    
    local showTitleShade = lbl.createFont1(26, i18n.global.frdpvp_invitable_list.string, ccc3(0x59, 0x30, 0x1b))
    showTitleShade:setPosition(board:getContentSize().width/2, 484)
    board:addChild(showTitleShade)

    local teamnum = 0
    if mbrs then
        teamnum = #mbrs
    end

    local createinfoScroll = nil
    local scroll = nil

    local function createItem(_idx)
        local item = img.createUI9Sprite(img.ui.botton_fram_2)
        item:setPreferredSize(CCSizeMake(554, 78))
        local item_w = item:getContentSize().width
        local item_h = item:getContentSize().height

        local head = img.createPlayerHead(mbrs[_idx].logo)
        frdBtn = SpineMenuItem:create(json.ui.button, head)
        frdBtn:setScale(0.6)
        frdBtn:setPosition(CCPoint(40, item_h/2+1))
        local frdMenu = CCMenu:createWithItem(frdBtn)
        frdMenu:setPosition(0, 0)
        item:addChild(frdMenu)

        frdBtn:registerScriptTapHandler(function()
            audio.play(audio.button)
            local params = {}
            --params.logo = mbrs[_idx].logo
            --params.uid = mbrs[_idx].uid
            --params.name = mbrs[_idx].name
            --params.frd = mbrs[_idx]
            --layer:addChild((require"ui.tips.player1").create(params, "none", showFriends), 100)
            layer:addChild((require"ui.frdarena.mbrinfo").create(mbrs[_idx], "none"), 100)
        end)


        -- lv
        local lv_bg = img.createUISprite(img.ui.main_lv_bg)
        lv_bg:setPosition(CCPoint(92, item_h/2))
        item:addChild(lv_bg)
        local lbl_mem_lv = lbl.createFont1(14, mbrs[_idx].lv)
        lbl_mem_lv:setPosition(CCPoint(lv_bg:getContentSize().width/2, lv_bg:getContentSize().height/2))
        lv_bg:addChild(lbl_mem_lv)

        -- name
        local lbl_mem_name = lbl.createFontTTF(16, mbrs[_idx].name, ccc3(0x51, 0x27, 0x12))
        lbl_mem_name:setAnchorPoint(CCPoint(0, 0.5))
        lbl_mem_name:setPosition(CCPoint(123, 48))
        item:addChild(lbl_mem_name)

        -- status
        if mbrs[_idx].last then
            local last = mbrs[_idx].last
            if mbrs[_idx].last ~= 0 then 
                last = os.time()-mbrs[_idx].last
            end
            local lbl_mem_status = lbl.createFont1(14, friend.onlineStatus(last), ccc3(0x8a, 0x60, 0x4c))
            lbl_mem_status:setAnchorPoint(CCPoint(0, 0.5))
            lbl_mem_status:setPosition(CCPoint(123, 28))
            item:addChild(lbl_mem_status)
        end

        local invitebtn = img.createLogin9Sprite(img.login.button_9_small_gold)
        invitebtn:setPreferredSize(CCSizeMake(115, 38))
        local lblInvite = lbl.createFont1(16, i18n.global.frdpvp_team_invite.string, ccc3(0x73, 0x3b, 0x05))
        lblInvite:setPosition(CCPoint(invitebtn:getContentSize().width/2,
                                         invitebtn:getContentSize().height/2))
        invitebtn:addChild(lblInvite)
        local applyAgreBtn = SpineMenuItem:create(json.ui.button, invitebtn)
        applyAgreBtn:setPosition(CCPoint(480, item_h/2+1))

        local applyAgreMenu = CCMenu:createWithItem(applyAgreBtn)
        applyAgreMenu:setPosition(CCPoint(0, 0))
        item:addChild(applyAgreMenu)

        applyAgreBtn:registerScriptTapHandler(function()
            audio.play(audio.button)
            local param = {}
            param.sid = player.sid
            param.type = 1
            param.uid = mbrs[_idx].uid
            
            addWaitNet()
            net:gpvp_leaderop(param, function(__data)
                delWaitNet()
                tbl2string(__data)
                if __data.status ~= 0 then
                    showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                    return
                end
                applyAgreBtn:setEnabled(false)  
                setShader(applyAgreBtn, SHADER_GRAY, true) 
                --showToast("invite acce")
                --teamnum = teamnum - 1
                --requestslab:setString(string.format(i18n.global.friend_requesrs_rcvd.string, 0))
                --if teamnum == 0 then
                --    mbrs = nil
                --end
                --scroll:removeFromParentAndCleanup(true)
                --scroll = nil
                --createinfoScroll()

            end)
        end)

        return item
    end

    local space_height = 2
    local function createScroll()
        local scroll_params = {
            width = 562,
            height = 375,
        }
        local lineScroll = require "ui.lineScroll"
        return lineScroll.create(scroll_params)
    end

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
