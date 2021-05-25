local ui = {}

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
local heros = require "data.heros"
local bag = require "data.bag"
local player = require "data.player"
local frdarena = require "data.arenac"

function ui.create()
    local layer = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))

    local board_w = 840
    local board_h = 540
    local board = img.createLogin9Sprite(img.login.dialog)
    board:setPreferredSize(CCSize(board_w, board_h))
    board:setScale(view.minScale)
    board:setPosition(view.midX, view.midY)
    layer:addChild(board)

    --inner bg
    local innerBg = img.createUI9Sprite(img.ui.bag_btn_inner_bg)
    innerBg:setPreferredSize(CCSizeMake(780, 375))
    innerBg:setAnchorPoint(0, 0)
    innerBg:setPosition(29, 90)
    board:addChild(innerBg)

    local showTitle = lbl.createFont1(26, i18n.global.frdpvp_team_lobby.string, ccc3(0xe6, 0xd0, 0xae))
    showTitle:setPosition(board:getContentSize().width/2, 511)
    board:addChild(showTitle, 1)
    
    local showTitleShade = lbl.createFont1(26, i18n.global.frdpvp_team_lobby.string, ccc3(0x59, 0x30, 0x1b))
    showTitleShade:setPosition(board:getContentSize().width/2, 509)
    board:addChild(showTitleShade)

    local btnCloseSprite = img.createUISprite(img.ui.close)
    local btnClose = SpineMenuItem:create(json.ui.button, btnCloseSprite)
    btnClose:setPosition(815, 513)
    local menuClose = CCMenu:createWithItem(btnClose)
    menuClose:setPosition(0, 0)
    board:addChild(menuClose)
    btnClose:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer:removeFromParentAndCleanup(true)
    end)

    local teams = {}
    local items = {}
    local function createItem(teamObj, _idx)
        local item = img.createUI9Sprite(img.ui.botton_fram_2)
        item:setPreferredSize(CCSizeMake(735, 88))
        items[_idx] = item
        local item_w = item:getContentSize().width
        local item_h = item:getContentSize().height

        local headdx = 65
        local head
        for i=1,3 do
            if teamObj.mbrs[i] then
                head = img.createPlayerHeadForArena(teamObj.mbrs[i].logo, teamObj.mbrs[i].lv)
                if teamObj.leader == teamObj.mbrs[i].uid then
                    local teamIcon = img.createUISprite(img.ui.friend_pvp_captain)
                    teamIcon:setAnchorPoint(0, 1)
                    teamIcon:setPosition(0, head:getContentSize().height)
                    head:addChild(teamIcon)
                end
            else
                head = img.createUI9Sprite(img.ui.friend_pvp_blackpl)
                head:setOpacity(255*0.7)
            end
            head:setScale(0.65)
            head:setPosition(CCPoint(48+(i-1)*headdx, item_h/2+1))
            item:addChild(head)
        end

        -- name
        local lbl_mem_name = lbl.createFontTTF(16, teamObj.name, ccc3(0x51, 0x27, 0x12))
        lbl_mem_name:setAnchorPoint(CCPoint(0, 0))
        lbl_mem_name:setPosition(CCPoint(220, 51))
        item:addChild(lbl_mem_name)

        powerBg = img.createUI9Sprite(img.ui.arena_frame7)
        powerBg:setPreferredSize(CCSize(146, 28))
        powerBg:setAnchorPoint(ccp(0.5, 0))
        powerBg:setPosition(220+73, 20)
        item:addChild(powerBg)

        local showPowerIcon = img.createUISprite(img.ui.power_icon)
        showPowerIcon:setScale(0.5)
        showPowerIcon:setPosition(220+70-56, 34)
        item:addChild(showPowerIcon)

        local showPower = lbl.createFont2(16, teamObj.power)
        showPower:setPosition(220+73, 34)
        item:addChild(showPower)
        
        local lblNeedPower = lbl.createFont1(14, "need power", ccc3(0x9a, 0x6a, 0x52))
        lblNeedPower:setAnchorPoint(0.5, 0)
        lblNeedPower:setPosition(455, 50)
        item:addChild(lblNeedPower)

        local needPower = lbl.createFont1(20, teamObj.need_power, ccc3(0x51, 0x27, 0x12))
        needPower:setAnchorPoint(0.5, 0)
        needPower:setPosition(455, 24)
        item:addChild(needPower)

        local applySp = img.createLogin9Sprite(img.login.button_9_small_gold)
        applySp:setPreferredSize(CCSizeMake(116, 42))
        --local applyAgre = img.createUISprite(img.ui.friends_tick)
        --applyAgre:setPosition(CCPoint(tickbtn:getContentSize().width/2,
        --                                 tickbtn:getContentSize().height/2))
        --tickbtn:addChild(applyAgre)
        local applylbl = lbl.createFont1(16, i18n.global.guild_btn_apply.string, ccc3(0x73, 0x3b, 0x05))
        applylbl:setPosition(CCPoint(applySp:getContentSize().width/2,
                                         applySp:getContentSize().height/2+1))
        applySp:addChild(applylbl)

        local applyAgreBtn = SpineMenuItem:create(json.ui.button, applySp)
        applyAgreBtn:setPosition(CCPoint(650, item_h/2+1))

        local applyAgreMenu = CCMenu:createWithItem(applyAgreBtn)
        applyAgreMenu:setPosition(CCPoint(0, 0))
        item:addChild(applyAgreMenu)
        
        applyAgreBtn:registerScriptTapHandler(function()
            audio.play(audio.button)
            local param = {}
            param.sid = player.sid + 256
            param.type = 1
            param.teamid = teamObj.id
            
            tbl2string(param)
            addWaitNet()
            net:gpvp_mbrop(param, function(__data)
                delWaitNet()
                tbl2string(__data)
                if __data.status ~= 0 then
                    showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                    return
                end
                setShader(applyAgreBtn, SHADER_GRAY, true)
                applyAgreBtn:setEnabled(false)
            end)
        end)
        return item
    end

    local function createScroll()
        local scroll_params = {
            width = 738,
            height = 275,
        }
        local lineScroll = require "ui.lineScroll"
        return lineScroll.create(scroll_params)
    end

    local scroll = nil
    local space_height = 2
    local function initData(data)
        items = {}
        if scroll then 
            scroll:removeFromParentAndCleanup(true)
            scroll = nil
        end 
        if data.team then
            scroll = createScroll()
            scroll:setAnchorPoint(CCPoint(0, 0))
            scroll:setPosition(CCPoint(50, 105))
            board:addChild(scroll)
            --drawBoundingbox(board, scroll)
            for ii=1,#data.team do
                local tmp_item = createItem(data.team[ii], ii)
                --tmp_item.guildObj = params.mbrs[ii]
                tmp_item.ax = 0.5
                tmp_item.px = 738/2
                scroll.addItem(tmp_item)
                if ii ~= #data.team then
                    scroll.addSpace(space_height)
                end
            end
            scroll:setOffsetBegin()
        end
    end
    
    local editId0 = img.createLogin9Sprite(img.login.input_border)
    local editId = CCEditBox:create(CCSizeMake(324*view.minScale, 38*view.minScale), editId0)
    editId:setInputMode(kEditBoxInputModeNumeric)
    --editId:setInputFlag(kEditBoxInputFlagPassword)
    editId:setReturnType(kKeyboardReturnTypeDone)
    editId:setMaxLength(9)
    editId:setFont("", 16*view.minScale)
    editId:setPlaceHolder(i18n.global.friend_find_id.string)
    --editId:setText(string.format("%d", 0))
    editId:setFontColor(ccc3(0x94, 0x62, 0x42))
    editId:setPosition(scalep(274, 438))
    layer:addChild(editId)
    editId:setVisible(false)

    --local edit_chips = editId
    --edit_chips:registerScriptEditBoxHandler(function(eventType)
    --    if eventType == "returnSend" then
    --    elseif eventType == "return" then
    --    elseif eventType == "ended" then
    --        local tmp_chip_count = edit_chips:getText()
    --        tmp_chip_count = string.trim(tmp_chip_count)
    --        tmp_chip_count = checkint(tmp_chip_count)
    --        if tmp_chip_count <= 0 then
    --            tmp_chip_count = 0
    --        elseif tmp_chip_count > 999999 then
    --            tmp_chip_count = 0
    --        end
    --        edit_chips:setText(tmp_chip_count)
    --    elseif eventType == "began" then
    --    elseif eventType == "changed" then
    --    end
    --end)

    -- applay btn
    local apply = img.createLogin9Sprite(img.login.button_9_small_gold)
    apply:setPreferredSize(CCSizeMake(160, 40))
    local applylab = lbl.createFont1(16, i18n.global.guild_btn_apply.string, ccc3(0x73, 0x3b, 0x05))
    applylab:setPosition(CCPoint(apply:getContentSize().width/2,
                                     apply:getContentSize().height/2+1))
    apply:addChild(applylab)
    local applyBtn = SpineMenuItem:create(json.ui.button, apply)
    applyBtn:setAnchorPoint(0.5, 0)
    applyBtn:setPosition(CCPoint(707, 398))
    
    local applyMenu = CCMenu:createWithItem(applyBtn)
    applyMenu:setPosition(CCPoint(0, 0))
    board:addChild(applyMenu)

    applyBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        if editId:getText() == "" then
            showToast(i18n.global.input_empty.string)
            return
        end
        local inputTeamid = tonumber(editId:getText())
        local params = {
            sid = player.sid + 256,
            type = 1,
            teamid = inputTeamid
        }
        tbl2string(params)
        addWaitNet()
        net:gpvp_mbrop(params,function(__data)
            delWaitNet()
            tbl2string(__data)
            if __data.status == -1 then
                showToast(i18n.global.frdpvp_team_fighting.string)
                return
            end
            if __data.status < 0 then
                showToast("status:" .. __data.status)
                return
            end
            showToast(i18n.global.friend_apply_succese.string)
        end)
        
    end)

    -- create btn
    local create = img.createLogin9Sprite(img.login.button_9_small_gold)
    create:setPreferredSize(CCSizeMake(162, 52))
    local createlab = lbl.createFont1(16, i18n.global.goto_guild_create.string, ccc3(0x73, 0x3b, 0x05))
    createlab:setPosition(CCPoint(create:getContentSize().width/2,
                                     create:getContentSize().height/2+1))
    create:addChild(createlab)
    local createBtn = SpineMenuItem:create(json.ui.button, create)
    createBtn:setAnchorPoint(0.5, 0)
    createBtn:setPosition(CCPoint(board_w/2-174, 27))
    
    local createMenu = CCMenu:createWithItem(createBtn)
    createMenu:setPosition(CCPoint(0, 0))
    board:addChild(createMenu)

    createBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer:addChild(require("ui.arenac.createteam").create())
    end)

    -- invited btn
    local invited = img.createLogin9Sprite(img.login.button_9_small_gold)
    invited:setPreferredSize(CCSizeMake(162, 52))
    addRedDot(invited, {
        px=invited:getContentSize().width-7,
        py=invited:getContentSize().height-7,
    })
    delRedDot(invited)

    local invitedlab = lbl.createFont1(16, i18n.global.frdpvp_team_invite.string, ccc3(0x73, 0x3b, 0x05))
    invitedlab:setPosition(CCPoint(invited:getContentSize().width/2,
                                     invited:getContentSize().height/2+1))
    invited:addChild(invitedlab)
    local invitedBtn = SpineMenuItem:create(json.ui.button, invited)
    invitedBtn:setAnchorPoint(0.5, 0)
    invitedBtn:setPosition(CCPoint(board_w/2, 27))
    
    local invitedMenu = CCMenu:createWithItem(invitedBtn)
    invitedMenu:setPosition(CCPoint(0, 0))
    board:addChild(invitedMenu)

    layer:scheduleUpdateWithPriorityLua(function()
        if frdarena.showinvitRed == true then
            addRedDot(invited, {
                px=invited:getContentSize().width-7,
                py=invited:getContentSize().height-7,
            })
        else
            delRedDot(invited)
        end
    end)
    invitedBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        
        local param = {}
        param.sid = player.sid + 256

        addWaitNet()
        net:gpvp_invitelist(param, function(__data)
            delWaitNet()
            tbl2string(__data)
            layer:addChild(require("ui.arenac.teaminvited").create(__data))
            frdarena.showinvitRed = false
        end)
    end)
    
    -- refresh btn
    local refresh = img.createLogin9Sprite(img.login.button_9_small_green)
    refresh:setPreferredSize(CCSizeMake(162, 52))
    local refreshlab = lbl.createFont1(16, i18n.global.casino_btn_refresh.string, ccc3(0x1d, 0x67, 0x00))
    refreshlab:setPosition(CCPoint(refresh:getContentSize().width/2,
                                     refresh:getContentSize().height/2+1))
    refresh:addChild(refreshlab)
    local refreshBtn = SpineMenuItem:create(json.ui.button, refresh)
    refreshBtn:setAnchorPoint(0.5, 0)
    refreshBtn:setPosition(CCPoint(board_w/2+174, 27))
    
    local refreshMenu = CCMenu:createWithItem(refreshBtn)
    refreshMenu:setPosition(CCPoint(0, 0))
    board:addChild(refreshMenu)

    refreshBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        local params = {
            sid = player.sid + 256,
        }
        addWaitNet()
        net:gpvp_refresh(params,function(__data)
            delWaitNet()
            tbl2string(__data)
            initData(__data)
        end)
    end)

    -- touch event
    local touchbeginx, touchbeginy
    local isclick
    local last_touch_sprite = nil
    local function onTouchBegan(x, y)
        touchbeginx, touchbeginy = x, y
        isclick = true
        if scroll and not tolua.isnull(scroll) then
            local obj = scroll.content_layer
            local p0 = obj:convertToNodeSpace(ccp(x, y))
            for ii=1,#items do
                if items[ii] and items[ii]:boundingBox():containsPoint(p0) then
                    --playAnimTouchBegin(items[ii])
                    last_touch_sprite = items[ii]
                end
            end
        end
        return true
    end
    local function onTouchMoved(x, y)
        if isclick and (math.abs(touchbeginx-x) > 10 or math.abs(touchbeginy-y) > 10) then
            isclick = false
            if last_touch_sprite and not tolua.isnull(last_touch_sprite) then
                --playAnimTouchEnd(last_touch_sprite)
                last_touch_sprite = nil
            end
        end
    end

    local function onTouchEnded(x, y)
        if isclick then
            if last_touch_sprite and not tolua.isnull(last_touch_sprite) then
                --playAnimTouchEnd(last_touch_sprite)
                last_touch_sprite = nil
            end
            if scroll and not tolua.isnull(scroll) then
                local obj = scroll.content_layer
                local p0 = obj:convertToNodeSpace(ccp(x, y))
                for ii=1,#items do
                    if items[ii] and items[ii]:boundingBox():containsPoint(p0) then
                        if last_selet_item ~= items[ii] then
                            audio.play(audio.button)
                            local params = {
                                sid = player.sid + 256,
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

                                layer:addChild(require("ui.arenac.teaminfotips").create(__data.grp))
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
    layer:setTouchEnabled(true)

    addBackEvent(layer)
    function layer.onAndroidBack()
        layer:removeFromParentAndCleanup(true)
    end
    local function onEnter()
        print("onEnter")
        local params = {
            sid = player.sid + 256,
        }
        addWaitNet()
        net:gpvp_refresh(params,function(__data)
            delWaitNet()
            tbl2string(__data)
            teams = __data.team
            initData(__data)
        end)

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
        editId:setVisible(true)
    end))
    board:runAction(CCSequence:create(anim_arr))

    return layer
end

return ui
