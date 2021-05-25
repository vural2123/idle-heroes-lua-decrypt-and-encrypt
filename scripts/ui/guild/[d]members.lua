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
local gdata = require "data.guild"
local i18n = require "res.i18n"
local tipsequip = require "ui.tips.equip"
local tipsitem = require "ui.tips.item"
local dialog = require "ui.dialog"
local board2 = require "ui.guild.board2"
local gitem = require "ui.guild.gitem"
local NetClient = require "net.netClient"
local netClient = NetClient:getInstance()

local space_height = 5

local function memOpt(mtype, muid, callback)
    local params = {
        sid = player.sid,
        type = mtype,
        muid = muid,
    }
    addWaitNet()
    netClient:gmember_opt(params, callback)
end

local function guildSync()
    local gparams = {
        sid = player.sid,
    }
    addWaitNet()
    netClient:guild_sync(gparams, function(__data)
        delWaitNet()
        tbl2string(__data)
        if __data .status ~= 0 then
            showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
            return
        end
        gdata.init(__data)
        replaceScene((require"ui.guild.main").create())
    end)
end

function ui.create(params)
    local layer = board2.create(board2.TAB.MEMBER)
    local board = layer.board
    local board_w = board:getContentSize().width
    local board_h = board:getContentSize().height

    layer.setTitle(i18n.global.guild_memopt_dlg_title.string)

    -- members
    local mem_container = CCSprite:create()
    mem_container:setContentSize(CCSizeMake(634, 440))
    mem_container:setAnchorPoint(CCPoint(0.5, 0))
    mem_container:setPosition(CCPoint(board_w/2, 0))
    board:addChild(mem_container)
    local container_w = mem_container:getContentSize().width
    local container_h = mem_container:getContentSize().height
    local function createScroll()
        local scroll_params = {
            width = 634,
            height = 436,
        }
        local lineScroll = require "ui.lineScroll"
        return lineScroll.create(scroll_params)
    end
    
    local function createItem(memObj)
        local item = img.createUI9Sprite(img.ui.botton_fram_2)
        item:setPreferredSize(CCSizeMake(614, 79))
        local item_w = item:getContentSize().width
        local item_h = item:getContentSize().height

        -- head
        local head = img.createPlayerHead(memObj.logo)
        head:setScale(0.65)
        head:setPosition(CCPoint(39, item_h/2+1))
        item:addChild(head)
        -- lv
        local lv_bg = img.createUISprite(img.ui.main_lv_bg)
        lv_bg:setPosition(CCPoint(92, item_h/2))
        item:addChild(lv_bg)
        local lbl_mem_lv = lbl.createFont1(14, memObj.lv)
        lbl_mem_lv:setPosition(CCPoint(lv_bg:getContentSize().width/2, lv_bg:getContentSize().height/2))
        lv_bg:addChild(lbl_mem_lv)
        -- name
        local lbl_mem_name = lbl.createFontTTF(20, memObj.name, ccc3(0x51, 0x27, 0x12))
        lbl_mem_name:setAnchorPoint(CCPoint(0, 0))
        lbl_mem_name:setPosition(CCPoint(122, item_h/2))
        item:addChild(lbl_mem_name)
        -- title
        local lbl_mem_title = lbl.createFont1(14, gdata.getTitleStr(memObj.title), ccc3(0x8a, 0x60, 0x4c))
        lbl_mem_title:setAnchorPoint(CCPoint(0, 1))
        lbl_mem_title:setPosition(CCPoint(122, item_h/2))
        item:addChild(lbl_mem_title)
        -- status
        local lbl_mem_status = lbl.createFont1(16, gdata.onlineStatus(memObj.last), ccc3(0x8a, 0x60, 0x4c))
        lbl_mem_status:setAnchorPoint(CCPoint(1, 0.5))
        lbl_mem_status:setPosition(CCPoint(item_w-25, item_h/2))
        item:addChild(lbl_mem_status)

        return item
    end

    local items = {}

    local function showList(listObj)
        mem_container:removeAllChildrenWithCleanup(true)
        arrayclear(items)
        local scroll = createScroll()
        scroll:setAnchorPoint(CCPoint(0, 0))
        scroll:setPosition(CCPoint(0, 2))
        mem_container:addChild(scroll)
        mem_container.scroll = scroll
        --drawBoundingbox(mem_container, scroll)
        scroll.addSpace(8)
        for ii=1,#listObj do
            local tmp_item = createItem(listObj[ii])
            tmp_item.memObj = listObj[ii]
            tmp_item.ax = 0.5
            tmp_item.ay = 0.5
            tmp_item.px = 317
            scroll.addItem(tmp_item)
            items[#items+1] = tmp_item
            if ii ~= #listObj then
                scroll.addSpace(space_height)
            end
        end
        scroll.setOffsetBegin()
    end
    showList(gdata.members or {})

    local function onClickItem(itemObj)
        audio.play(audio.button)
        if not itemObj or tolua.isnull(itemObj) then return end
        local memObj = itemObj.memObj
        local mParams = {
            name = memObj.name,
            logo = memObj.logo,
            lv = memObj.lv,
            uid = memObj.uid,
            guild = gdata.guildObj.name,
            power = 1000,
            defens = {},
        }
        local infolayer
        if memObj.uid == player.uid then
            infolayer = (require "ui.tips.player").create(mParams)
            layer:addChild(infolayer, 1000)
            return
        else
            mParams.buttons = {}
            infolayer = (require "ui.tips.player").create(mParams)
        end
        local info_board = infolayer.board
        local info_board_w = info_board:getContentSize().width
        local info_board_h = info_board:getContentSize().height
        if gdata.selfTitle() == gdata.TITLE.PRESIDENT then
            if memObj.title == gdata.TITLE.RESIDENT then
                local btn_appoint0 = img.createLogin9Sprite(img.login.button_9_small_gold)
                btn_appoint0:setPreferredSize(CCSizeMake(150, 50))
                local lbl_appoint = lbl.createFont1(16, i18n.global.guild_memopt_btn_assign2.string, ccc3(0x73, 0x3b, 0x05))
                lbl_appoint:setPosition(CCPoint(btn_appoint0:getContentSize().width/2, btn_appoint0:getContentSize().height/2))
                btn_appoint0:addChild(lbl_appoint)
                local btn_appoint = SpineMenuItem:create(json.ui.button, btn_appoint0)
                btn_appoint:setPosition(CCPoint(100, 46))
                local btn_appoint_menu = CCMenu:createWithItem(btn_appoint)
                btn_appoint_menu:setPosition(CCPoint(0, 0))
                info_board:addChild(btn_appoint_menu)
                btn_appoint:registerScriptTapHandler(function()
                    audio.play(audio.button)
                    memOpt(1, memObj.uid, function(__data)
                        delWaitNet()
                        tbl2string(__data)
                        if __data.status ~= 0 then
                            if __data.status == -1 then
                                showToast(i18n.global.guild_memopt_mem_offical_limit.string)
                                return
                            end
                            showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                            return
                        end
                        memObj.title = gdata.TITLE.OFFICER
                        showToast("Ok.")
                        infolayer:removeFromParentAndCleanup(true)
                        showList(gdata.members or {})
                    end)
                end)
            elseif memObj.title == gdata.TITLE.OFFICER then
                local btn_appoint0 = img.createLogin9Sprite(img.login.button_9_small_gold)
                btn_appoint0:setPreferredSize(CCSizeMake(150, 50))
                local lbl_appoint = lbl.createFont1(16, i18n.global.guild_memopt_btn_assign3.string, ccc3(0x73, 0x3b, 0x05))
                lbl_appoint:setPosition(CCPoint(btn_appoint0:getContentSize().width/2, btn_appoint0:getContentSize().height/2))
                btn_appoint0:addChild(lbl_appoint)
                local btn_appoint = SpineMenuItem:create(json.ui.button, btn_appoint0)
                btn_appoint:setPosition(CCPoint(100, 46))
                local btn_appoint_menu = CCMenu:createWithItem(btn_appoint)
                btn_appoint_menu:setPosition(CCPoint(0, 0))
                info_board:addChild(btn_appoint_menu)
                btn_appoint:registerScriptTapHandler(function()
                    audio.play(audio.button)
                    memOpt(2, memObj.uid, function(__data)
                        delWaitNet()
                        tbl2string(__data)
                        if __data.status ~= 0 then
                            showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                            return
                        end
                        memObj.title = gdata.TITLE.RESIDENT
                        showToast("Ok.")
                        infolayer:removeFromParentAndCleanup(true)
                        showList(gdata.members or {})
                    end)
                end)
            end
            local btn_transfer0 = img.createLogin9Sprite(img.login.button_9_small_gold)
            btn_transfer0:setPreferredSize(CCSizeMake(150, 50))
            local lbl_transfer = lbl.createFont1(16, i18n.global.guild_memopt_btn_assign1.string, ccc3(0x73, 0x3b, 0x05))
            lbl_transfer:setPosition(CCPoint(btn_transfer0:getContentSize().width/2, btn_transfer0:getContentSize().height/2))
            btn_transfer0:addChild(lbl_transfer)
            local btn_transfer = SpineMenuItem:create(json.ui.button, btn_transfer0)
            btn_transfer:setPosition(CCPoint(262, 46))
            local btn_transfer_menu = CCMenu:createWithItem(btn_transfer)
            btn_transfer_menu:setPosition(CCPoint(0, 0))
            info_board:addChild(btn_transfer_menu)
            btn_transfer:registerScriptTapHandler(function()
                audio.play(audio.button)
                local function transfer()
                    memOpt(3, memObj.uid, function(__data)
                        delWaitNet()
                        tbl2string(__data)
                        if __data.status ~= 0 then
                            showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                            return
                        end
                        memObj.title = gdata.TITLE.PRESIDENT
                        gdata.deInit()
                        guildSync()
                    end)
                end
                local function process_dialog(data)
                    layer:removeChildByTag(dialog.TAG)
                    if data.selected_btn == 2 then
                        transfer()
                    end
                end
                local params = {
                    title = "",
                    body = i18n.global.guild_memopt_assign_tip.string,
                    btn_count = 2,
                    btn_color = {
                        [1] = dialog.COLOR_BLUE,
                        [2] = dialog.COLOR_GOLD,
                    },
                    btn_text = {
                        [1] = i18n.global.dialog_button_cancel.string,
                        [2] = i18n.global.dialog_button_confirm.string,
                    },
                    callback = process_dialog,
                }
                local dialog_ins = dialog.create(params, true)
                dialog_ins:setAnchorPoint(CCPoint(0,0))
                dialog_ins:setPosition(CCPoint(0,0))
                layer:addChild(dialog_ins, 10000, dialog.TAG)
            end)

            local btn_chase0 = img.createLogin9Sprite(img.login.button_9_small_gold)
            btn_chase0:setPreferredSize(CCSizeMake(150, 50))
            local lbl_chase = lbl.createFont1(16, i18n.global.guild_memopt_btn_chase.string, ccc3(0x73, 0x3b, 0x05))
            lbl_chase:setPosition(CCPoint(btn_chase0:getContentSize().width/2, btn_chase0:getContentSize().height/2))
            btn_chase0:addChild(lbl_chase)
            local btn_chase = SpineMenuItem:create(json.ui.button, btn_chase0)
            btn_chase:setPosition(CCPoint(424, 46))
            local btn_chase_menu = CCMenu:createWithItem(btn_chase)
            btn_chase_menu:setPosition(CCPoint(0, 0))
            info_board:addChild(btn_chase_menu)
            btn_chase:registerScriptTapHandler(function()
                audio.play(audio.button)
                memOpt(6, memObj.uid, function(__data)
                    delWaitNet()
                    tbl2string(__data)
                    if __data.status ~= 0 then
                        showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                        return
                    end
                    gdata.removeMemByUid(memObj.uid)
                    infolayer:removeFromParentAndCleanup(true)
                    showList(gdata.members or {})
                end)
            end)
        elseif gdata.selfTitle() == gdata.TITLE.OFFICER then
            if memObj.title <= gdata.TITLE.RESIDENT then
                local btn_chase0 = img.createLogin9Sprite(img.login.button_9_small_gold)
                btn_chase0:setPreferredSize(CCSizeMake(150, 50))
                local lbl_chase = lbl.createFont1(16, i18n.global.guild_memopt_btn_chase.string, ccc3(0x73, 0x3b, 0x05))
                lbl_chase:setPosition(CCPoint(btn_chase0:getContentSize().width/2, btn_chase0:getContentSize().height/2))
                btn_chase0:addChild(lbl_chase)
                local btn_chase = SpineMenuItem:create(json.ui.button, btn_chase0)
                btn_chase:setPosition(CCPoint(424, 46))
                local btn_chase_menu = CCMenu:createWithItem(btn_chase)
                btn_chase_menu:setPosition(CCPoint(0, 0))
                info_board:addChild(btn_chase_menu)
                btn_chase:registerScriptTapHandler(function()
                    audio.play(audio.button)
                    memOpt(6, memObj.uid, function(__data)
                        delWaitNet()
                        tbl2string(__data)
                        if __data.status ~= 0 then
                            showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                            return
                        end
                        gdata.removeMemByUid(memObj.uid)
                        infolayer:removeFromParentAndCleanup(true)
                        showList(gdata.members or {})
                    end)
                end)
            end
        end
        layer:addChild(infolayer, 1000)
    end

    -- touch event
    local touchbeginx, touchbeginy
    local isclick
    local last_touch_sprite = nil
    local function onTouchBegan(x, y)
        touchbeginx, touchbeginy = x, y
        isclick = true
        if mem_container.scroll and not tolua.isnull(mem_container.scroll) then
            local p0 = mem_container.scroll.content_layer:convertToNodeSpace(ccp(x, y))
            for ii=1,#items do
                if items[ii]:boundingBox():containsPoint(p0) then
                    playAnimTouchBegin(items[ii])
                    last_touch_sprite = items[ii]
                    break
                end
            end
        end
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
        if last_touch_sprite and not tolua.isnull(last_touch_sprite) then
            playAnimTouchEnd(last_touch_sprite)
            last_touch_sprite = nil
        end
        if isclick and mem_container.scroll and not tolua.isnull(mem_container.scroll) then
            local p0 = mem_container.scroll.content_layer:convertToNodeSpace(ccp(x, y))
            for ii=1,#items do
                if items[ii]:boundingBox():containsPoint(p0) then
                    audio.play(audio.button)
                    onClickItem(items[ii])
                    break
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
    layer:setTouchSwallowEnabled(true)

    return layer
end

return ui
