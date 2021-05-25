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
local frdarena = require "data.frdarena"

function ui.create(data)
    local layer = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))

    local teams = data.team
    -- board
    local board = img.createUI9Sprite(img.ui.dialog_1)
    board:setPreferredSize(CCSizeMake(840, 540))
    board:setScale(view.minScale)
    board:setPosition(view.midX, view.midY)
    layer:addChild(board)
    local board_w = board:getContentSize().width
    local board_h = board:getContentSize().height

    --inner bg
    local innerBg = img.createUI9Sprite(img.ui.bag_btn_inner_bg)
    innerBg:setPreferredSize(CCSizeMake(785, 436))
    innerBg:setAnchorPoint(0, 0)
    innerBg:setPosition(25, 30)
    board:addChild(innerBg)

    local showTitle = lbl.createFont1(26, i18n.global.frdpvp_team_invite.string, ccc3(0xe6, 0xd0, 0xae))
    showTitle:setPosition(board:getContentSize().width/2, 516)
    board:addChild(showTitle, 1)
    
    local showTitleShade = lbl.createFont1(26, i18n.global.frdpvp_team_invite.string, ccc3(0x59, 0x30, 0x1b))
    showTitleShade:setPosition(board:getContentSize().width/2, 514)
    board:addChild(showTitleShade)

    local teamnum = 0
    if teams then
        teamnum = #teams
    end
    local requestslab = lbl.createFont1(16, string.format(i18n.global.friend_requesrs_rcvd.string, teamnum), ccc3(0x49, 0x26, 0x04))
    requestslab:setAnchorPoint(CCPoint(0, 0.5))
    requestslab:setPosition(58, 426)
    board:addChild(requestslab)

    -- deleteall btn
    local deleteall = img.createLogin9Sprite(img.login.button_9_small_gold)
    deleteall:setPreferredSize(CCSizeMake(206, 40))
    local deletealllab = lbl.createFont1(16, i18n.global.friend_apply_delete.string, ccc3(0x73, 0x3b, 0x05))
    deletealllab:setPosition(CCPoint(deleteall:getContentSize().width/2,
                                     deleteall:getContentSize().height/2+1))
    deleteall:addChild(deletealllab)
    local deleteallBtn = SpineMenuItem:create(json.ui.button, deleteall)
    deleteallBtn:setPosition(CCPoint(686, 426))
    
    local deleteallMenu = CCMenu:createWithItem(deleteallBtn)
    deleteallMenu:setPosition(CCPoint(0, 0))
    board:addChild(deleteallMenu)

    local createinfoScroll = nil
    local scroll = nil

    local items = {}
    local function createItem(_idx)
        local item = img.createUI9Sprite(img.ui.botton_fram_2)
        item:setPreferredSize(CCSizeMake(736, 88))
        items[_idx] = item
        local item_w = item:getContentSize().width
        local item_h = item:getContentSize().height

        local headdx = 65
        local head
        for i=1,3 do
            if teams[_idx].mbrs[i] then
                head = img.createPlayerHeadForArena(teams[_idx].mbrs[i].logo, teams[_idx].mbrs[i].lv)
            else
                head = img.createUI9Sprite(img.ui.friend_pvp_blackpl)
                head:setOpacity(255*0.7)
            end
            head:setScale(0.65)
            head:setPosition(CCPoint(48+(i-1)*headdx, item_h/2+1))
            item:addChild(head)
        end

        -- name
        local lbl_mem_name = lbl.createFontTTF(16, teams[_idx].name, ccc3(0x51, 0x27, 0x12))
        lbl_mem_name:setAnchorPoint(CCPoint(0, 0))
        lbl_mem_name:setPosition(CCPoint(220, 54))
        item:addChild(lbl_mem_name)

        powerBg = img.createUI9Sprite(img.ui.arena_frame7)
        powerBg:setPreferredSize(CCSize(146, 28))
        powerBg:setAnchorPoint(ccp(0.5, 0))
        powerBg:setPosition(220+73, 20)
        item:addChild(powerBg)

        local showPowerIcon = img.createUISprite(img.ui.power_icon)
        showPowerIcon:setScale(0.5)
        showPowerIcon:setPosition(220+73-54, 34)
        item:addChild(showPowerIcon)

        local showPower = lbl.createFont2(16, teams[_idx].power)
        showPower:setPosition(220+73, 34)
        item:addChild(showPower)
        
        local lblNeedPower = lbl.createFont1(14, "need power", ccc3(0x9a, 0x6a, 0x52))
        lblNeedPower:setAnchorPoint(0.5, 0)
        lblNeedPower:setPosition(455, 50)
        item:addChild(lblNeedPower)

        local needPower = lbl.createFont1(20, teams[_idx].need_power, ccc3(0x51, 0x27, 0x12))
        needPower:setAnchorPoint(0.5, 0)
        needPower:setPosition(455, 26)
        item:addChild(needPower)

        local tickbtn = img.createLogin9Sprite(img.login.button_9_small_green)
        tickbtn:setPreferredSize(CCSizeMake(85, 40))
        local applyAgre = img.createUISprite(img.ui.friends_tick)
        applyAgre:setPosition(CCPoint(tickbtn:getContentSize().width/2,
                                         tickbtn:getContentSize().height/2))
        tickbtn:addChild(applyAgre)
        local applyAgreBtn = SpineMenuItem:create(json.ui.button, tickbtn)
        applyAgreBtn:setPosition(CCPoint(584, item_h/2))

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
        applyNotagreBtn:setPosition(CCPoint(674, item_h/2))

        local applyNotagreMenu = CCMenu:createWithItem(applyNotagreBtn)
        applyNotagreMenu:setPosition(CCPoint(0, 0))
        item:addChild(applyNotagreMenu)

        applyAgreBtn:registerScriptTapHandler(function()
            audio.play(audio.button)
            local param = {}
            param.sid = player.sid
            param.type = 2
            param.teamid = teams[_idx].id

            addWaitNet()
            net:gpvp_mbrop(param, function(__data)
                delWaitNet()
                tbl2string(__data)
                if __data.status == -4 then
                    showToast(i18n.global.frdpvp_team_teamfull.string)
                    return
                end
                if __data.status == -2 then
                    showToast(i18n.global.frdpvp_team_noteam.string)
                    return
                end
                if __data.status ~= 0 then
                    showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                    return
                end
                frdarena.jointeam(teams[_idx])
                teamnum = teamnum - 1
                requestslab:setString(string.format(i18n.global.friend_requesrs_rcvd.string, teamnum))
                table.remove(teams, _idx)                   
                if teamnum == 0 then
                    teams = nil
                end
                scroll:removeFromParentAndCleanup(true)
                scroll = nil
                createinfoScroll()

                local params = {
                    sid = player.sid        
                }
                addWaitNet()
                net:gpvp_sync(params, function(__data)
                    delWaitNet()
                    tbl2string(__data)
                    --local __data = layer.__data
                    local frdarenaData = require "data.frdarena"
                    frdarenaData.init(__data)
                    replaceScene(require("ui.frdarena.main").create())
                end)
            end)
        end)

        applyNotagreBtn:registerScriptTapHandler(function()
            audio.play(audio.button)
            local param = {}
            param.sid = player.sid
            param.type = 4
            param.teamid = teams[_idx].id
            
            tbl2string(param)
            addWaitNet()
            net:gpvp_mbrop(param, function(__data)
                delWaitNet()
                tbl2string(__data)
                if __data.status ~= 0 then
                    showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                    return
                end
                teamnum = teamnum - 1
                requestslab:setString(string.format(i18n.global.friend_requesrs_rcvd.string, teamnum))
                table.remove(teams, _idx)                   
                if teamnum == 0 then
                    teams = nil
                end
                scroll:removeFromParentAndCleanup(true)
                scroll = nil
                createinfoScroll()
            end)
        end)
        return item
    end

    local function createScroll()
        local scroll_params = {
            width = 748,
            height = 358,
        }
        local lineScroll = require "ui.lineScroll"
        return lineScroll.create(scroll_params)
    end

    deleteallBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        
        if teams == nil then
            return
        end

        local param = {}
        param.sid = player.sid
        param.type = 4
        param.teamid = 0
        
        addWaitNet()
        net:gpvp_mbrop(param, function(__data)
            delWaitNet()
            tbl2string(__data)
            if __data.status ~= 0 then
                showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                return
            end
            requestslab:setString(string.format(i18n.global.friend_requesrs_rcvd.string, 0))
            teams = nil
            scroll:removeFromParentAndCleanup(true)
            scroll = nil
        end)
    end)


    function createinfoScroll()
        if teams then
            scroll = createScroll()
            scroll:setAnchorPoint(CCPoint(0, 0))
            scroll:setPosition(CCPoint(48, 45))
            board:addChild(scroll)
            --board.scroll = scroll
            --drawBoundingbox(board, scroll)

            for ii=1,#teams do
                local tmp_item = createItem(ii)
                --tmp_item.guildObj = params.teams[ii]
                tmp_item.ax = 0.5
                tmp_item.ay = 0.5
                tmp_item.px = 748/2
                scroll.addItem(tmp_item)
                if ii ~= #teams then
                    scroll.addSpace(10)
                end
            end
            scroll:setOffsetBegin()
        end
    end
    
    createinfoScroll()

    local btnCloseSprite = img.createUISprite(img.ui.close)
    local btnClose = SpineMenuItem:create(json.ui.button, btnCloseSprite)
    btnClose:setPosition(board_w-25, board_h-28)
    local menuClose = CCMenu:createWithItem(btnClose)
    menuClose:setPosition(0, 0)
    board:addChild(menuClose)
    btnClose:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer:removeFromParentAndCleanup(true)
    end)

    -- touch event
    local touchbeginx, touchbeginy
    local isclick
    local last_touch_sprite = nil
    local function onTouchBegan(x, y)
        touchbeginx, touchbeginy = x, y
        isclick = true
        --if current_tab ~= TAB.NEW then
            if scroll and not tolua.isnull(scroll) then
                local obj = scroll.content_layer
                local p0 = obj:convertToNodeSpace(ccp(x, y))
                for ii=1,#items do
                    if items[ii]:boundingBox():containsPoint(p0) then
                        playAnimTouchBegin(items[ii])
                        last_touch_sprite = items[ii]
                    end
                end
            end
        --end
        return true
    end
    local function onTouchMoved(x, y)
        if isclick and (math.abs(touchbeginx-x) > 10 or math.abs(touchbeginy-y) > 10) then
            isclick = false
            if last_touch_sprite and not tolua.isnull(last_touch_sprite) then
                playAnimTouchEnd(last_touch_sprite)
                last_touch_sprite = nil
            end
        end
    end

    local function onTouchEnded(x, y)
        if isclick then
            if last_touch_sprite and not tolua.isnull(last_touch_sprite) then
                playAnimTouchEnd(last_touch_sprite)
                last_touch_sprite = nil
            end
            if scroll and not tolua.isnull(scroll) then
                local obj = scroll.content_layer
                local p0 = obj:convertToNodeSpace(ccp(x, y))
                for ii=1,#items do
                    if items[ii]:boundingBox():containsPoint(p0) then
                        if last_selet_item ~= items[ii] then
                            audio.play(audio.button)
                            local params = {
                                sid = player.sid,
                                grp_id = teams[ii].id,
                            }
                            tbl2string(params)
                            addWaitNet()
                            net:gpvp_grp(params, function(__data)
                                delWaitNet()
                                
                                tbl2string(__data)
                                if __data.status ~= 0 then
                                    showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                                    return
                                end
                                layer:addChild(require("ui.frdarena.teaminfotips").create(__data.grp))
                            end)

                            --if last_selet_item then
                            --    last_selet_item.focus:setVisible(false)
                            --end
                            --items[ii].focus:setVisible(true)
                            last_selet_item = nil
                            --showContent(items[ii].mailObj)
                            --items[ii].setRead()
                        end
                    end
                end
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
    layer:registerScriptTouchHandler(onTouch , false , -128 , false)

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

    board:setScale(0.5*view.minScale)
    local anim_arr = CCArray:create()
    anim_arr:addObject(CCScaleTo:create(0.15, 1*view.minScale, 1*view.minScale))
    anim_arr:addObject(CCDelayTime:create(0.15))
    anim_arr:addObject(CCCallFunc:create(function()
    end))
    board:runAction(CCSequence:create(anim_arr))

    layer:setTouchEnabled(true)

    return layer
end

return ui
