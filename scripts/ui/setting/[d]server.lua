local ui = {}

require "common.func"
require "common.const"
local view = require "common.view"
local img = require "res.img"
local i18n = require "res.i18n"
local lbl = require "res.lbl"
local json = require "res.json"
local audio = require "res.audio"
local player = require "data.player"
local userdata = require "data.userdata"
local NetClient = require "net.netClient"
local netClient = NetClient:getInstance()

-- test data
local slist = {
    [1] = {
        sid = 3, sname = "s3", pname = "anney", plogo = 2, plv=5, flag=1,
    },
    [2] = {
        sid = 5, sname = "s5", pname = "jim", plogo = 3, plv=7, flag=0,
    },
    [3] = {
        sid = 2, sname = "s2", pname = "jim2", plogo = 5, plv=9, flag=0,
    },
}

local function sortValue(serverObj)
    if not serverObj then return 0 end
    if serverObj.sid == player.sid then
        return 100000
    elseif serverObj.pname and serverObj.pname ~= nil and serverObj.pname ~= "" then
        return 80000 + serverObj.sid
    else
        return serverObj.sid
    end
end

local function processServers(servers)
    --if true then return servers end   -- test
    local rlist = {}
    local marksid = {}
    for ii=1,#servers do
        local tobj = servers[ii]
        if not marksid["" .. tobj.sid] then
            rlist[#rlist+1] = tobj
            marksid["" .. tobj.sid] = tobj
        else
            if not marksid["" .. tobj.sid].extra then
                marksid["" .. tobj.sid].extra = {}
                local textra = marksid["" .. tobj.sid].extra
                textra[#textra+1] = marksid["" .. tobj.sid]
            end
            local textra = marksid["" .. tobj.sid].extra
            textra[#textra+1] = tobj
        end
    end
    return rlist
end

function ui.pull(callback)
    local params = {
        sid = player.sid,
    }
    addWaitNet()
    netClient:servers(params, function(__data)
        delWaitNet()
        tbl2string(__data)
        local servers = processServers(__data.servers)
        if callback then
            callback(servers)
        end
    end)
end

function ui.create()
    local boardlayer = require "ui.setting.board"
    local layer = boardlayer.create(boardlayer.TAB.SERVER)
    local board = layer.inner_board
    local board_w = board:getContentSize().width
    local board_h = board:getContentSize().height

    layer.setTitle(i18n.global.setting_title_servers.string)

    local function createScroll()
        local scroll_params = {
            width = 691,
            height = 385,
        }
        local lineScroll = require "ui.lineScroll"
        return lineScroll.create(scroll_params)
    end

    local function createItem(serverObj)
        local item = img.createUI9Sprite(img.ui.botton_fram_2)
        item:setPreferredSize(CCSizeMake(336, 86))
        local item_w = item:getContentSize().width
        local item_h = item:getContentSize().height
        -- current
        local current = img.createUI9Sprite(img.ui.setting_server_sel)
        current:setPreferredSize(CCSizeMake(336, 86))
        current:setPosition(CCPoint(item_w/2, item_h/2))
        current:setVisible(serverObj.sid== player.sid)
        item:addChild(current)
        -- focus
        local focus = img.createUI9Sprite(img.ui.setting_server_focus)
        focus:setPreferredSize(CCSizeMake(342, 92))
        focus:setPosition(CCPoint(item_w/2, item_h/2+2))
        focus:setVisible(false)
        item:addChild(focus)
        item.focus = focus
        -- sname
        local lbl_sname = lbl.createFont1(22, serverObj.sname, ccc3(0x51, 0x27, 0x12))
        lbl_sname:setAnchorPoint(CCPoint(0, 0.5))
        lbl_sname:setPosition(CCPoint(22, item_h/2))
        item:addChild(lbl_sname)
        -- pname
        if not serverObj.extra and serverObj.pname then
            local lbl_pname = lbl.createFontTTF(22, serverObj.pname, ccc3(0x51, 0x27, 0x12))
            lbl_pname:setAnchorPoint(CCPoint(1, 0.5))
            lbl_pname:setPosition(CCPoint(256, item_h/2))
            item:addChild(lbl_pname)
        end
        if serverObj.extra then
            local head = img.createPlayerHead(118)
            head:setScale(0.7)
            head:setPosition(CCPoint(292, item_h/2+2))
            item:addChild(head)
        elseif serverObj.plogo then
            local head = img.createPlayerHead(serverObj.plogo, serverObj.plv)
            head:setScale(0.7)
            head:setPosition(CCPoint(292, item_h/2+2))
            item:addChild(head)
        end
        if serverObj.flag then
            if bit.band(0x02, serverObj.flag) > 0 then
                local icon_new = img.createUISprite(img.ui.setting_icon_new)
                --icon_new:setAnchorPoint(CCPoint(0, 1))
                icon_new:setPosition(CCPoint(lbl_sname:boundingBox():getMaxX()+23, item_h/2))
                item:addChild(icon_new)
            end
        end
        item.height = item_h
        return item
    end

    local list_items = {}
    local function showList(listObj)
        table.sort(listObj, function(a, b)
            return sortValue(a) > sortValue(b)
        end)
        if not listObj or #listObj == 0 then return end
        arrayclear(list_items)
        local scroll = createScroll()
        scroll:setAnchorPoint(CCPoint(0, 0))
        scroll:setPosition(CCPoint(23, 16))
        board:addChild(scroll)
        board.scroll = scroll
        for ii=1,#listObj,2 do
            local tmp_item = CCSprite:create()
            tmp_item:setContentSize(CCSizeMake(685, 90))
            local tmp_server_item = createItem(listObj[ii])
            tmp_server_item.container = tmp_item
            tmp_server_item.obj = listObj[ii]
            list_items[#list_items+1] = tmp_server_item
            tmp_server_item:setPosition(CCPoint(169, 45))
            tmp_item:addChild(tmp_server_item)
            if listObj[ii+1] then
                local tmp_server_item2 = createItem(listObj[ii+1])
                tmp_server_item2.container = tmp_item
                tmp_server_item2.obj = listObj[ii+1]
                list_items[#list_items+1] = tmp_server_item2
                tmp_server_item2:setPosition(CCPoint(517, 45))
                tmp_item:addChild(tmp_server_item2)
            end
            scroll.addItem(tmp_item)
        end
        scroll.setOffsetBegin()
    end
    ui.pull(showList)

    local function showRoleList(roles)
    end

    local function onClickItem(itemObj)
        audio.play(audio.button)
        if last_sel_sprite and not tolua.isnull(last_sel_sprite) then
            last_sel_sprite.focus:setVisible(false)
        end
        itemObj.focus:setVisible(true)
        last_sel_sprite = itemObj
        -- 是否是合服
        if itemObj.obj.extra then
            layer:addChild((require"ui.setting.roles").create(itemObj.obj.extra), 10000)
            return
        end
        if itemObj.obj.sid == player.sid then
            if player.uid == itemObj.obj.uid then
                return 
            end
        end
        replaceScene((require "ui.login.update").create(nil, itemObj.obj.sid, nil, {uid=itemObj.obj.uid}))
    end

    -- touch event
    local touchbeginx, touchbeginy
    local isclick
    local last_touch_sprite = nil
    local function onTouchBegan(x, y)
        touchbeginx, touchbeginy = x, y
        isclick = true
        if not board.scroll or tolua.isnull(board.scroll) then
            isclick = false
            return false
        end
        local content_layer = board.scroll.content_layer
        local p0 = board:convertToNodeSpace(ccp(x, y))
        if not board.scroll:boundingBox():containsPoint(p0) then
            isclick = false
            return false
        end
        for ii=1,#list_items do
            local p1 = list_items[ii].container:convertToNodeSpace(ccp(x, y))
            if list_items[ii]:boundingBox():containsPoint(p1) then
                playAnimTouchBegin(list_items[ii])
                last_touch_sprite = list_items[ii]
                break
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
        if not board.scroll or tolua.isnull(board.scroll) then
            return
        end
        if isclick then
            local content_layer = board.scroll.content_layer
            for ii=1,#list_items do
                local p0 = list_items[ii].container:convertToNodeSpace(ccp(x, y))
                if list_items[ii]:boundingBox():containsPoint(p0) then
                    onClickItem(list_items[ii])
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
