local ui = {}

-- diff with res.json
local cjson = json

require "common.func"
require "common.const"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local audio = require "res.audio"
local cfgitem = require "config.item"
local cfgequip = require "config.equip"
local cfgmail = require "config.mail"
local player = require "data.player"
local bagdata = require "data.bag"
local maildata = require "data.mail"
local i18n = require "res.i18n"
local tipsequip = require "ui.tips.equip"
local tipsitem = require "ui.tips.item"
local dialog = require "ui.dialog"
local rewards = require "ui.reward"

--for ii=1, 8 do       -- test data
--    local mailObj = {
--        id = 34,
--        mid = 100+ii,
--        flag = 0,
--        title = "Player's Message" .. ii,
--        send_time = os.time(),
--        read = 0,
--        from = "Player " .. ii,
--        content = [[Welcome to u, my Dear friend. tmp_item.mailObj = listObj[ii].
--        container:removeAllChildrenWithCleanup container:removeAllChildrenWithCleanup
--        container:removeAllChildrenWithCleanup
--        container:removeAllChildrenWithCleanup
--        ]],
--        content_o = [[o Welcome to u, my Dear friend. tmp_item.mailObj = listObj[ii].
--        container:removeAllChildrenWithCleanup container:removeAllChildrenWithCleanup
--        container:removeAllChildrenWithCleanup
--        container:removeAllChildrenWithCleanup
--        ]],
--    }     
--    maildata.addMails({[1]=mailObj})
--end
--for ii=1, 8 do       -- test data
--    local mailObj = {
--        id = 1,
--        mid = 200+ii,
--        flag = 0,
--        title = "test mail" .. ii,
--        send_time = os.time(),
--        read = 0,
--        from = "Sys",
--        content = [[Welcome to u, my Dear friend. tmp_item.mailObj = listObj[ii].
--        container:removeAllChildrenWithCleanup container:removeAllChildrenWithCleanup
--        container:removeAllChildrenWithCleanup
--        container:removeAllChildrenWithCleanup
--        ]]
--    }     
--    maildata.addMails({[1]=mailObj})
--end

local TAB = {
    INB = 1,
    SYS = 2,
    NEW = 3,
}
ui.TAB = TAB
local current_tab = TAB.SYS
local btn_size = CCSizeMake(160, 50)
local btn_size2 = CCSizeMake(130, 42)
local m_btn_color = ccc3(0x73, 0x3b, 0x05)

local input_content = nil   -- 写邮件离开时，非空确认
local function dropConfirm(parentObj, callback)
    if input_content ~= nil and input_content ~= "" then
        local function process_dialog(dialog_data)
            parentObj:removeChildByTag(dialog.TAG)
            if dialog_data.selected_btn == 2 then
                input_content = nil
                if callback then
                    callback()
                end
                return
            elseif dialog_data.selected_btn == 1 then
                return
            end
        end
        local dialog_params = {
            title = "",
            body = i18n.global.mail_leave_send.string,
            btn_count = 2,
            btn_text = {
                [1] = i18n.global.dialog_button_cancel.string,
                [2] = i18n.global.dialog_button_confirm.string,
            },
            btn_color = {
                [1] = dialog.COLOR_BLUE,
                [2] = dialog.COLOR_GOLD,
            },
            selected_btn = 0,
            callback = process_dialog,
        }
        local dialog_ins = dialog.create(dialog_params)
        parentObj:addChild(dialog_ins, 1000, dialog.TAG)
    else
        if callback then
            callback()
        end
    end
end

local function delAllSysRead(callback)
    local sys_mails = maildata.getSysMails()
    local d_ids = {}
    local d_mails = {}
    for ii=1,#sys_mails do
        local mailObj = sys_mails[ii]
        if not mailObj.affix then
            if mailObj.flag == 1 then
                d_ids[#d_ids+1] = mailObj.mid
                d_mails[#d_mails+1] = mailObj
            end
        else
            if mailObj.flag == 2 then
                d_ids[#d_ids+1] = mailObj.mid
                d_mails[#d_mails+1] = mailObj
            end
        end
    end
    if #d_ids <= 0 then return end
    local params = {
        sid = player.sid,
        deletes = d_ids
    }
    addWaitNet()
    netClient:op_mail(params, function(__data)
        delWaitNet()
        for ii=1,#d_mails do
            maildata.delSys(d_mails[ii])
        end
        if callback then
            callback()
        end
    end)
end

local function coupleBatchDel(parentObj, callback)
    local function process_dialog(dialog_data)
        parentObj:removeChildByTag(dialog.TAG)
        if dialog_data.selected_btn == 2 then
            delAllSysRead(callback)
            return
        elseif dialog_data.selected_btn == 1 then
            return
        end
    end
    local dialog_params = {
        title = "",
        body = i18n.global.mail_batch_del.string,
        btn_count = 2,
        btn_text = {
            [1] = i18n.global.dialog_button_cancel.string,
            [2] = i18n.global.dialog_button_confirm.string,
        },
        btn_color = {
            [1] = dialog.COLOR_BLUE,
            [2] = dialog.COLOR_GOLD,
        },
        selected_btn = 0,
        callback = process_dialog,
    }
    local dialog_ins = dialog.create(dialog_params)
    parentObj:addChild(dialog_ins, 1000, dialog.TAG)
end

local function processMailContent(mail_obj)
    mail_obj.type = mail_obj.id
    local body = ""
    if cfgmail[mail_obj.type] then
        local _type = mail_obj.type
        local cfgObj = cfgmail[mail_obj.type]
        local cont_params = cjson.decode(mail_obj.content)
        if type(cont_params) == "table" and cont_params["guildname"] then
            cont_params["guildname"] = replaceInvalidChars(cont_params["guildname"])
        end

        mail_obj.title = i18n.mail[mail_obj.type].name
        mail_obj.from = i18n.mail[mail_obj.type].from
        body = i18n.mail[mail_obj.type].content
        if _type == 1 then
            local tmp_stamp = checkint(cont_params["time"])                                                                  
            body = string.gsub(body, "#time#", os.date("%Y-%m-%d", tmp_stamp))
            body = string.gsub(body, "#id#", tostring(i18n.arena[cont_params["id"]].name))
            body = string.gsub(body, "#rank#", tostring(cont_params["rank"]))
        elseif _type == 2 then
            body = string.gsub(body, "#id#", tostring(i18n.arena[cont_params["id"]].name))
            body = string.gsub(body, "#rank#", tostring(cont_params["rank"]))
        elseif _type == 3 then
            body = string.gsub(body, "#member1#", tostring(cont_params["member1"]))
            body = string.gsub(body, "#member2#", tostring(cont_params["member2"]))
            body = string.gsub(body, "#guildname#", tostring(cont_params["guildname"]))
        elseif _type == 4 then
            body = string.gsub(body, "#guildname#", tostring(cont_params["guildname"]))
        elseif _type == 5 then
            body = string.gsub(body, "#guildname#", tostring(cont_params["guildname"]))
        elseif _type == 6 then
            body = string.gsub(body, "#guildname#", tostring(cont_params["guildname"]))
        elseif _type == 7 then
            body = string.gsub(body, "#guildname#", tostring(cont_params["guildname"]))
        --elseif _type == 9 then
        --    body = string.gsub(body, "#gems#", tostring(cont_params["gems"]))
        elseif _type == 10 then
            --body = string.gsub(body, "#content#", tostring(cont_params["content"]))
            body = tostring(cont_params["content"])
        elseif _type == 11 then
            body = string.gsub(body, "#content#", tostring(cont_params["content"]))
        elseif _type == 12 then
            body = string.gsub(body, "#date#", tostring(cont_params["date"]))
            body = string.gsub(body, "#gems#", tostring(cont_params["gems"]))
            --body = string.gsub(body, "#gems#", "50")
        elseif _type == 13 then
            body = string.gsub(body, "#number#", tostring(cont_params["number"]))
            body = string.gsub(body, "#day#", tostring(cont_params["day"]))
        elseif _type == 15 then
            body = string.gsub(body, "#level#", tostring(cont_params["level"]))
            body = string.gsub(body, "#gems#", tostring(cont_params["gems"]))
            body = string.gsub(body, "#gold#", tostring(cont_params["gold"]))
        elseif _type == 16 then
            local hero_id = checkint(cont_params["ID"])
            body = string.gsub(body, "#ID#", i18n.hero[hero_id].heroName)
        elseif _type == 17 then
            body = string.gsub(body, "#gems#", tostring(cont_params["gems"]))
        elseif _type == 18 then
            body = string.gsub(body, "#date#", tostring(cont_params["date"]))
        elseif _type == 21 then
            body = string.gsub(body, "#stage#", tostring(i18n.guildwar[cont_params["stage"]].stageName))
        elseif _type == 22 then
            body = string.gsub(body, "#number#", tostring(cont_params["number"]))
            body = string.gsub(body, "#stage#", tostring(i18n.guildwar[cont_params["stage"]].stageName))
        elseif _type == 26 then
            body = string.gsub(body, "#number#", tostring(cont_params["number"]))
        elseif _type == 27 then
            body = string.gsub(body, "#gems#", tostring(cont_params["gems"]))
            body = string.gsub(body, "#chip#", tostring(cont_params["chip"]))
        elseif _type == 29 then
            body = string.gsub(body, "#number#", tostring(cont_params["number"]))
        elseif _type == 32 then
            body = string.gsub(body, "#rank#", tostring(cont_params["rank"]))
        elseif _type == 38 then
            body = string.gsub(body, "#number#", tostring(cont_params["number"]))
        elseif _type == 40 then
            body = string.gsub(body, "#rank#", tostring(cont_params["rank"]))
        elseif _type == 41 then
            body = string.gsub(body, "#date#", tostring(cont_params["date"]))
            body = string.gsub(body, "#gems#", tostring(cont_params["gems"]))
        elseif _type == 42 then
            body = string.gsub(body, "#day#", tostring(cont_params["day"]))
        elseif _type == 45 then
            local hero_id = checkint(cont_params["ID"])
            body = string.gsub(body, "#ID#", i18n.hero[hero_id].heroName)
        elseif _type == 65 then
            local hero_id = checkint(cont_params["ID"])
            body = string.gsub(body, "#ID#", i18n.hero[hero_id].heroName)
        --elseif _type == 47 then
        --    body = string.gsub(body, "#number#", tostring(cont_params["number"]))
        elseif _type == 50 then
            body = string.gsub(body, "#rank#", tostring(cont_params["rank"]))
        elseif _type == 51 then
            body = string.gsub(body, "#rank#", tostring(cont_params["rank"]))
        elseif _type == 56 then
            body = string.gsub(body, "#guildname#", tostring(cont_params["guildname"]))
        elseif _type == 69 then
            body = string.gsub(body, "#number#", tostring(cont_params["number"]))
        elseif _type == 72 then
            body = string.gsub(body, "#platform#", tostring(cont_params["platform"]))
            body = string.gsub(body, "#price#", tostring(cont_params["price"]))
            body = string.gsub(body, "#order_id#", tostring(cont_params["order_id"]))
        elseif _type == 81 then
            body = string.gsub(body, "#rank#", tostring(cont_params["rank"]))
        elseif _type == 82 then
            body = string.gsub(body, "#rank#", tostring(cont_params["rank"]))
        elseif _type == 83 then
            body = string.gsub(body, "#rank#", tostring(cont_params["rank"]))
        elseif _type == 87 then
            body = string.gsub(body, "#chip#", tostring(cont_params["chip"]))
            body = string.gsub(body, "#gems#", tostring(cont_params["gems"]))
        elseif _type == 88 then
            body = string.gsub(body, "#key#", tostring(cont_params["key"]))
        elseif _type == 89 then
            body = string.gsub(body, "#key#", tostring(cont_params["key"]))
        elseif _type == 108 then
            body = string.gsub(body, "#level#", tostring(cont_params["level"]))
            body = string.gsub(body, "#number#", tostring(cont_params["number"]))
            body = string.gsub(body, "#day#", tostring(cont_params["day"]))
        elseif _type == 90001 then
            body = string.gsub(body, "<para>", "\n")
        elseif _type == 120 then
            body = string.gsub(body, "#level#", tostring(cont_params["level"]))
            body = string.gsub(body, "#number#", tostring(cont_params["number"]))
            body = string.gsub(body, "#day#", tostring(cont_params["day"]))
        elseif _type == 130 then
            body = string.gsub(body, "#content#", tostring(cont_params["content"]))
        elseif _type == 134 then
            body = string.gsub(body, "#level#", tostring(cont_params["level"]))
            body = string.gsub(body, "#number#", tostring(cont_params["number"]))
            body = string.gsub(body, "#day#", tostring(cont_params["day"]))
        end
        --for k,v in pairs(cont_params) do
        --    local pattern = "#" .. k .. "#"
        --    body = string.gsub(body, pattern, tostring(v))
        --end
    else
        body = mail_obj.content
    end
    mail_obj.body = body
end

local icons = {
    [1] = img.ui.mail_icon_gift,
    [2] = img.ui.mail_icon_gift_read,
    [3] = img.ui.mail_icon,
    [4] = img.ui.mail_icon_read,
}

local function createItem(mailObj)
    local item_bg = img.createUI9Sprite(img.ui.mail_item)
    item_bg:setPreferredSize(CCSizeMake(301, 79))
    local item_bg_w = item_bg:getContentSize().width
    local item_bg_h = item_bg:getContentSize().height
    -- read
    local item_read = img.createUI9Sprite(img.ui.mail_item_read)
    item_read:setPreferredSize(CCSizeMake(301, 79))
    item_read:setPosition(CCPoint(item_bg_w/2, item_bg_h/2))
    item_bg:addChild(item_read, 1)
    -- focus
    local item_focus = img.createUI9Sprite(img.ui.mail_item_hl)
    item_focus:setPreferredSize(CCSizeMake(301, 79))
    item_focus:setAnchorPoint(CCPoint(0, 0.5))
    item_focus:setPosition(CCPoint(0, item_bg_h/2))
    item_focus:setVisible(false)
    item_bg:addChild(item_focus, 2)
    item_bg.focus = item_focus
    -- icon
    local tmp_icon
    local tmp_icon_read
    if maildata.getTypeById(mailObj.id) == 1 then
        tmp_icon = icons[1]
        tmp_icon_read = icons[2]
    else
        tmp_icon = icons[3]
        tmp_icon_read = icons[4]
    end
    local icon = img.createUISprite(tmp_icon)
    icon:setPosition(CCPoint(42, item_bg_h/2))
    item_bg:addChild(icon, 3)
    local icon_read = img.createUISprite(tmp_icon_read)
    icon_read:setPosition(CCPoint(42, item_bg_h/2))
    item_bg:addChild(icon_read, 4)
    item_bg.icon_read = icon_read

    if mailObj.flag == 1 or mailObj.flag == 2 then
        item_read:setVisible(true)
        icon_read:setVisible(true)
    else
        item_read:setVisible(false)
        icon_read:setVisible(false)
    end

    function item_bg.setRead()
        item_read:setVisible(true)
        icon_read:setVisible(true)
        print("set read mid:" .. mailObj.mid)
        if mailObj.flag == 0 then
            mailObj.flag = 1
            maildata.read(mailObj.mid)
        end
    end
    
    -- title
    local tmp_title = i18n.global.mail_tab_system.string
    if current_tab == TAB.INB then
        --tmp_title = i18n.global.mail_tab_player.string
        tmp_title = string.format("From:%s", mailObj.from or "")
    elseif current_tab == TAB.SYS then
        tmp_title = i18n.global.mail_tab_system.string
    else
    end
    local lbl_title = lbl.create({kind="ttf", size=16, text=tmp_title, color=ccc3(0x51, 0x27, 0x12),})
    lbl_title:setAnchorPoint(CCPoint(0, 0))
    lbl_title:setPosition(CCPoint(80, 41))
    item_bg:addChild(lbl_title, 4)
    -- date
    local lbl_date = lbl.create({kind="ttf", size=16, text=os.date("%Y-%m-%d", mailObj.send_time), color=ccc3(0x51, 0x27, 0x12),})
    lbl_date:setAnchorPoint(CCPoint(0, 0))
    lbl_date:setPosition(CCPoint(80, 18))
    item_bg:addChild(lbl_date, 4)
    item_bg.height = item_bg_h
    return item_bg
end

--[[
--  params = {
--      tab = ui.TAB.XXX,
--      ------- if send mail to other --------
--      sendto = player's uid ,
--      content = "xxxxxxxxxx",
--  }
--]]
function ui.create(params)
    -- init titles
    local titles = {
        [TAB.INB] = i18n.global.mail_tab_player.string,
        [TAB.SYS] = i18n.global.mail_tab_system.string,
        [TAB.NEW] = i18n.global.mail_tab_new.string,
    }

    local layer = CCLayer:create()
    if current_tab == TAB.NEW then
        current_tab = TAB.SYS
    end
    current_tab = params and params.tab or current_tab

    -- dark bg
    local darkbg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    layer:addChild(darkbg)
    -- board
    local board = img.createUISprite(img.ui.mail_board)
    board:setScale(view.minScale)
    board:setPosition(view.midX-25*view.minScale, view.midY)
    layer:addChild(board)
    local board_w = board:getContentSize().width
    local board_h = board:getContentSize().height

    -- anim
    board:setScale(0.5*view.minScale)
    board:runAction(CCScaleTo:create(0.15, 1*view.minScale, 1*view.minScale))

    -- title
    local lbl_title = lbl.createFont3(34, "", ccc3(255, 246, 223))
    lbl_title:setAnchorPoint(CCPoint(0, 0.5))
    lbl_title:setPosition(CCPoint(102, 507))
    board:addChild(lbl_title)
    local function backEvent()
        dropConfirm(layer, function()
            audio.play(audio.button)
            layer:removeFromParentAndCleanup(true)
        end)
    end
    -- btn_close
    local btn_close0 = img.createUISprite(img.ui.mail_btn_close)
    local btn_close = SpineMenuItem:create(json.ui.button, btn_close0)
    btn_close:setPosition(CCPoint(795, 489))
    local btn_close_menu = CCMenu:createWithItem(btn_close)
    btn_close_menu:setPosition(CCPoint(0, 0))
    board:addChild(btn_close_menu, 100)
    btn_close:registerScriptTapHandler(function()
        backEvent()
    end)

    local tab_inb0 = img.createUISprite(img.ui.mail_btn_inbox)
    local tab_sys0 = img.createUISprite(img.ui.mail_btn_sys)
    local tab_new0 = img.createUISprite(img.ui.mail_btn_new)
    local tab_inb_hl = img.createUISprite(img.ui.mail_btn_inbox_hl)
    local tab_sys_hl = img.createUISprite(img.ui.mail_btn_sys_hl)
    local tab_new_hl = img.createUISprite(img.ui.mail_btn_new_hl)
   
    local tab_offset_x = 26
    local tab_offset_y = 408
    local tab_step_y = 75
    local tab_inb = HHMenuItem:create(tab_inb0)
    tab_inb:setPosition(CCPoint(board_w+tab_offset_x, tab_offset_y-tab_step_y*1))
    local tab_inb_menu = CCMenu:createWithItem(tab_inb)
    tab_inb_menu:setPosition(CCPoint(0, 0))
    board:addChild(tab_inb_menu, -1)
    tab_inb_hl:setPosition(CCPoint(board_w+tab_offset_x, tab_offset_y-tab_step_y*1))
    board:addChild(tab_inb_hl)
    
    local tab_sys = HHMenuItem:create(tab_sys0)
    tab_sys:setPosition(CCPoint(board_w+tab_offset_x, tab_offset_y-tab_step_y*0))
    local tab_sys_menu = CCMenu:createWithItem(tab_sys)
    tab_sys_menu:setPosition(CCPoint(0, 0))
    board:addChild(tab_sys_menu, -1)
    tab_sys_hl:setPosition(CCPoint(board_w+tab_offset_x, tab_offset_y-tab_step_y*0))
    board:addChild(tab_sys_hl)

    local tab_new = HHMenuItem:create(tab_new0)
    tab_new:setPosition(CCPoint(board_w+tab_offset_x, tab_offset_y-tab_step_y*2))
    local tab_new_menu = CCMenu:createWithItem(tab_new)
    tab_new_menu:setPosition(CCPoint(0, 0))
    board:addChild(tab_new_menu, -1)
    tab_new_hl:setPosition(CCPoint(board_w+tab_offset_x, tab_offset_y-tab_step_y*2))
    board:addChild(tab_new_hl)

    local container = CCSprite:create()
    container:setContentSize(CCSizeMake(730, 435))
    container:setPosition(CCPoint(422, 257))
    board:addChild(container, 2)
    --drawBoundingbox(board, container)
    local container_w = container:getContentSize().width
    local container_h = container:getContentSize().height

    local content_container = CCSprite:create()
    content_container:setContentSize(CCSizeMake(405, 435))
    content_container:setAnchorPoint(CCPoint(1, 1))
    content_container:setPosition(CCPoint(container:boundingBox():getMaxX(), container:boundingBox():getMaxY()))
    board:addChild(content_container, 1)
    --drawBoundingbox(board, content_container, ccc4f(0, 1, 1, 1))
    local content_container_w = content_container:getContentSize().width
    local content_container_h = content_container:getContentSize().height

    local onTabSel

    -- for touch
    local last_selet_item = nil
    local items = {}

    local function createContentScroll()
        local scroll_params = {
            width = 380,
            height = 336,
        }
        local lineScroll = require "ui.lineScroll"
        return lineScroll.create(scroll_params)
    end

    local function showTextContent(mailObj, isAffix)
        processMailContent(mailObj)
        -- txt bg
        local txt_bg = img.createUI9Sprite(img.ui.mail_content_bg)
        txt_bg:setPreferredSize(CCSizeMake(406, 356))
        txt_bg:setAnchorPoint(CCPoint(1, 1))
        txt_bg:setPosition(CCPoint(content_container_w, content_container_h))
        content_container:addChild(txt_bg)
        local txt_bg_w = txt_bg:getContentSize().width
        local txt_bg_h = txt_bg:getContentSize().height
        -- scroll
        local scroll = createContentScroll()
        scroll:setAnchorPoint(CCPoint(0, 0))
        scroll:setPosition(CCPoint(17, 10))
        txt_bg:addChild(scroll)
        scroll.addSpace(10)
        --drawBoundingbox(txt_bg, scroll)
        -- title
        local lbl_mail_title = lbl.create({kind="ttf", size=18, text=mailObj.title, 
                                        color=ccc3(0x83, 0x41, 0x1d),
                                        width = 358, align = kCCTextAlignmentCenter,
                                    })
        lbl_mail_title.ax = 0.5
        lbl_mail_title.px = 190
        scroll.addItem(lbl_mail_title)
        scroll.addSpace(16)
        -- body
        local lbl_body = lbl.create({kind="ttf", font=1, size=17, text=mailObj.body, 
                                        color=ccc3(0x83, 0x41, 0x1d),
                                        width = 358, align = kCCTextAlignmentLeft,
                                    })
        lbl_body.ax = 0.5
        lbl_body.px = 190
        scroll.addItem(lbl_body)
        scroll.addSpace(16)
        --drawBoundingbox(scroll.content_layer, lbl_body)
        -- from
        local lbl_from = lbl.create({kind="ttf", size=17, text=mailObj.from, color=ccc3(0x83, 0x41, 0x1d),})
        lbl_from.ax = 1
        lbl_from.px = 367
        scroll.addItem(lbl_from)
        scroll.addSpace(30)
        scroll.setOffsetBegin()

        if isAffix and mailObj.affix then
            -- split line
            local split_line = img.createUISprite(img.ui.mail_content_split)
            split_line.ax = 0.5
            split_line.px = 190
            scroll.addItem(split_line)
            scroll.addSpace(10)
            -- rewards
            local lbl_rewards = lbl.create({font=1, size=20, text=i18n.global.mail_rewards.string, color=ccc3(0x83, 0x41, 0x1d),})
            lbl_rewards.ax = 0.5
            lbl_rewards.px = 190
            scroll.addItem(lbl_rewards)
            scroll.addSpace(10)
            -- 已领取标签
            if mailObj.flag == 2 then      -- 已领取附件
                local icon_got = img.createUISprite(img.ui.mail_icon_got)
                icon_got:setPosition(CCPoint(380-45, split_line:getPositionY()))
                split_line:getParent():addChild(icon_got, 10)
            end
            local item_count = 0
            if mailObj.affix.items then
                item_count = item_count + #mailObj.affix.items
            end
            if mailObj.affix.equips then
                item_count = item_count + #mailObj.affix.equips
            end
            local affix_container_w = 361
            local affix_container_h = math.floor((item_count + 3)/4)*(85+7)
            local affix_container = CCSprite:create()
            affix_container:setContentSize(CCSizeMake(affix_container_w, affix_container_h))
            local off_x, off_y = 40, affix_container_h - 43
            local off_step = 91
            local item_idx = 0
            if mailObj.affix.items then
                for _, _obj in ipairs(mailObj.affix.items) do
                    item_idx = item_idx + 1
                    local tmp_item0 = img.createItem(_obj.id, _obj.num)
                    local tmp_item = CCMenuItemSprite:create(tmp_item0, nil)
                    tmp_item:setPosition(CCPoint(off_x+(item_idx-1)%4*off_step, off_y-math.floor((item_idx+3)/4-1)*off_step))
                    local tmp_item_menu = CCMenu:createWithItem(tmp_item)
                    tmp_item_menu:setPosition(CCPoint(0, 0))
                    affix_container:addChild(tmp_item_menu)
                    tmp_item:registerScriptTapHandler(function()
                        audio.play(audio.button)
                        layer:addChild(tipsitem.createForShow(_obj), 1000)
                    end)
                    --local grid = img.createUISprite(img.ui.grid)
                    --grid:setPosition(CCPoint(tmp_item:getContentSize().width/2, tmp_item:getContentSize().height/2))
                    --tmp_item:addChild(grid, -1)
                    if mailObj.flag == 2 then      -- 已领取附件
                        setShader(tmp_item, SHADER_GRAY, true)
                    end
                end
            end
            if mailObj.affix.equips then
                for _, _obj in ipairs(mailObj.affix.equips) do
                    item_idx = item_idx + 1
                    local tmp_item0 = img.createEquip(_obj.id, _obj.num)
                    local tmp_item = CCMenuItemSprite:create(tmp_item0, nil)
                    tmp_item:setPosition(CCPoint(off_x+(item_idx-1)%4*off_step, off_y-math.floor((item_idx+3)/4-1)*off_step))
                    local tmp_item_menu = CCMenu:createWithItem(tmp_item)
                    tmp_item_menu:setPosition(CCPoint(0, 0))
                    affix_container:addChild(tmp_item_menu)
                    tmp_item:registerScriptTapHandler(function()
                        audio.play(audio.button)
                        layer:addChild(tipsequip.createForShow(_obj), 1000)
                    end)
                    --local grid = img.createUISprite(img.ui.grid)
                    --grid:setPosition(CCPoint(tmp_item:getContentSize().width/2, tmp_item:getContentSize().height/2))
                    --tmp_item:addChild(grid, -1)
                    if mailObj.flag == 2 then      -- 已领取附件
                        setShader(tmp_item, SHADER_GRAY, true)
                    end
                end
            end
            affix_container.ax = 0.5
            affix_container.px = 190
            scroll.addItem(affix_container)
            scroll.addSpace(10)

            if mailObj.flag == 2 then      -- 已领取附件
                --local btn_get = img.createLogin9Sprite(img.login.button_9_small_blue)
                --btn_get:setPreferredSize(CCSizeMake(118, 42))
                --btn_get:setPosition(CCPoint(content_container_w/2+78, 34))
                --content_container:addChild(btn_get)
                --local lbl_get = lbl.createFont1(20, "GOTTEN", ccc3(0x83, 0x41, 0x1d))
                --lbl_get:setPosition(CCPoint(btn_get:getContentSize().width/2, btn_get:getContentSize().height/2))
                --btn_get:addChild(lbl_get)
                
                -- buttons
                local btn_del0 = img.createLogin9Sprite(img.login.button_9_small_gold)
                btn_del0:setPreferredSize(btn_size)
                local lbl_del = lbl.createFont1(18, i18n.global.mail_btn_del.string, m_btn_color)
                lbl_del:setPosition(CCPoint(btn_del0:getContentSize().width/2, btn_del0:getContentSize().height/2))
                btn_del0:addChild(lbl_del)
                local btn_del = SpineMenuItem:create(json.ui.button, btn_del0)
                btn_del:setPosition(CCPoint(content_container_w/2, 34))
                local btn_del_menu = CCMenu:createWithItem(btn_del)
                btn_del_menu:setPosition(CCPoint(0, 0))
                content_container:addChild(btn_del_menu)
                btn_del:registerScriptTapHandler(function()
                    audio.play(audio.button)
                    addWaitNet()
                    maildata.netDel(mailObj, function(__data)
                        delWaitNet()
                        tbl2string(__data)
                        if __data.status ~= 0 then
                            showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                            return
                        end
                        maildata.del(mailObj)
                        onTabSel(current_tab)
                    end)
                end)
            else        -- 可以领取附件
                local btn_get0 = img.createLogin9Sprite(img.login.button_9_small_gold)
                btn_get0:setPreferredSize(btn_size)
                local lbl_get = lbl.createFont1(18, i18n.global.mail_btn_get.string, m_btn_color)
                lbl_get:setPosition(CCPoint(btn_get0:getContentSize().width/2, btn_get0:getContentSize().height/2))
                btn_get0:addChild(lbl_get)
                local btn_get = SpineMenuItem:create(json.ui.button, btn_get0)
                btn_get:setPosition(CCPoint(content_container_w/2, 34))
                local btn_get_menu = CCMenu:createWithItem(btn_get)
                btn_get_menu:setPosition(CCPoint(0, 0))
                content_container:addChild(btn_get_menu)
                btn_get:registerScriptTapHandler(function()
                    audio.play(audio.button)
                    addWaitNet()
                    maildata.affix({mailObj.mid}, function(__data)
                        tbl2string(__data)
                        delWaitNet()
                        if __data.status ~= 0 then
                            showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                            return
                        end
                        mailObj.flag = 2
						local oldxp = checkLevelUp1(bagdata)
                        if __data.affix and __data.affix.items then
                            bagdata.items.addAll(__data.affix.items)
                            -- 处理好战者头像
                            processSpecialHead(__data.affix.items)
                        end
                        if __data.affix and __data.affix.equips then
                            bagdata.equips.addAll(__data.affix.equips)
                        end
                        -- show affix
						checkLevelUp2(bagdata, oldxp)
                        if __data.affix then
                            CCDirector:sharedDirector():getRunningScene():addChild(rewards.createFloating(__data.affix), 100000)
                        end
                        onTabSel(TAB.SYS)
                    end)
                end)
            end
        else  -- 文本邮件 删除
            -- buttons
            local btn_del0 = img.createLogin9Sprite(img.login.button_9_small_gold)
            btn_del0:setPreferredSize(btn_size)
            local lbl_del = lbl.createFont1(18, i18n.global.mail_btn_del.string, m_btn_color)
            lbl_del:setPosition(CCPoint(btn_del0:getContentSize().width/2, btn_del0:getContentSize().height/2))
            btn_del0:addChild(lbl_del)
            local btn_del = SpineMenuItem:create(json.ui.button, btn_del0)
            btn_del:setPosition(CCPoint(content_container_w/2, 34))
            local btn_del_menu = CCMenu:createWithItem(btn_del)
            btn_del_menu:setPosition(CCPoint(0, 0))
            content_container:addChild(btn_del_menu)
            btn_del:registerScriptTapHandler(function()
                audio.play(audio.button)
                addWaitNet()
                maildata.netDel(mailObj, function(__data)
                    delWaitNet()
                    tbl2string(__data)
                    if __data.status ~= 0 then
                        showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                        return
                    end
                    maildata.del(mailObj)
                    onTabSel(current_tab)
                end)
            end)
        end
        scroll.setOffsetBegin()
        -- todo set read
    end

    local function showAffixContent(mailObj)
        showTextContent(mailObj, true)
    end

    local function showPlayerContent(mailObj)
        -- txt bg
        local txt_bg = img.createUI9Sprite(img.ui.mail_content_bg)
        txt_bg:setPreferredSize(CCSizeMake(406, 356))
        txt_bg:setAnchorPoint(CCPoint(1, 1))
        txt_bg:setPosition(CCPoint(content_container_w, content_container_h))
        content_container:addChild(txt_bg)
        local txt_bg_w = txt_bg:getContentSize().width
        local txt_bg_h = txt_bg:getContentSize().height
        -- scroll
        local scroll = createContentScroll()
        scroll:setAnchorPoint(CCPoint(0, 0))
        scroll:setPosition(CCPoint(17, 10))
        txt_bg:addChild(scroll)
        scroll.addSpace(10)
        -- title
        local lbl_mail_title = lbl.create({kind="ttf", size=20, text=i18n.global.mail_playermail_title.string, color=ccc3(0x83, 0x41, 0x1d),})
        lbl_mail_title.ax = 0.5
        lbl_mail_title.px = 190
        scroll.addItem(lbl_mail_title)
        scroll.addSpace(16)
        -- body
        local lbl_body = lbl.create({kind="ttf", font=1, size=17, text=mailObj.content, 
            color=ccc3(0x83, 0x41, 0x1d),
            width = 358, align = kCCTextAlignmentLeft,
        })
        lbl_body.ax = 0.5
        lbl_body.px = 190
        scroll.addItem(lbl_body)
        scroll.addSpace(10)
        -- from
        local lbl_from = lbl.create({kind="ttf", size=20, text=mailObj.from, color=ccc3(0x83, 0x41, 0x1d),})
        lbl_from.ax = 1
        lbl_from.px = 367
        scroll.addItem(lbl_from)
        scroll.addSpace(10)
        if mailObj.content_o then
            local split_dot = "-----------------------------------------------------"
            -- split 1
            local split_line_1 = lbl.create({kind="ttf", size=17, text=split_dot, color=ccc3(0x83, 0x41, 0x1d),})
            split_line_1.ax = 0.5
            split_line_1.px = 190
            scroll.addItem(split_line_1)
            local lbl_o_m = lbl.create({kind="ttf", size=17, text=i18n.global.mail_old.string, color=ccc3(0x83, 0x41, 0x1d),})
            lbl_o_m:setPosition(CCPoint(split_line_1:getContentSize().width/2, split_line_1:getContentSize().height/2))
            split_line_1:addChild(lbl_o_m)
            local mbox = img.createUI9Sprite(img.ui.mail_lbl_bg)
            mbox:setPreferredSize(lbl_o_m:getContentSize())
            mbox:setPosition(CCPoint(lbl_o_m:getContentSize().width/2, lbl_o_m:getContentSize().height/2))
            lbl_o_m:addChild(mbox, -1)
            scroll.addSpace(10)
            -- body
            local lbl_body = lbl.create({kind="ttf", font=1, size=17, text=mailObj.content_o, 
                color=ccc3(0x83, 0x41, 0x1d),
                width = 358, align = kCCTextAlignmentLeft,
            })
            lbl_body.ax = 0.5
            lbl_body.px = 190
            scroll.addItem(lbl_body)
            scroll.addSpace(10)
            -- split 2
            --local split_line_2 = lbl.create({kind="ttf", size=17, text=split_dot, color=ccc3(0x83, 0x41, 0x1d),})
            --split_line_2.ax = 0.5
            --split_line_2.px = 200
            --scroll.addItem(split_line_2)
            --scroll.addSpace(16)
        end

        -- buttons
        local btn_shield0 = img.createLogin9Sprite(img.login.button_9_small_gold)
        btn_shield0:setPreferredSize(btn_size2)
        local lbl_shield = lbl.createFont1(16, i18n.global.chat_shield.string, m_btn_color)
        lbl_shield:setPosition(CCPoint(btn_shield0:getContentSize().width/2, btn_shield0:getContentSize().height/2))
        btn_shield0:addChild(lbl_shield)
        local btn_shield = SpineMenuItem:create(json.ui.button, btn_shield0)
        btn_shield:setPosition(CCPoint(content_container_w/2-135, 34))
        btn_shield:setVisible(false)
        local btn_shield_menu = CCMenu:createWithItem(btn_shield)
        btn_shield_menu:setPosition(CCPoint(0, 0))
        content_container:addChild(btn_shield_menu)
        btn_shield:registerScriptTapHandler(function()
            audio.play(audio.button)
            local dialog = require "ui.dialog"
            local function process_dialog(data)
                layer:removeChildByTag(dialog.TAG)
                if data.selected_btn == 2 then
                    addWaitNet()
                    maildata.block(mailObj.uid, function(__data)
                        delWaitNet()
                        tbl2string(__data)
                        if __data.status ~= 0 then
                            showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                            return
                        end
                        maildata.del(mailObj)
                        onTabSel(current_tab)
                    end)
                elseif data.selected_btn == 1 then
                end
            end
            local params = {
                title = "",
                body = i18n.global.chat_sure_shield.string,
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

        local btn_del0 = img.createLogin9Sprite(img.login.button_9_small_gold)
        btn_del0:setPreferredSize(btn_size)
        local lbl_del = lbl.createFont1(18, i18n.global.mail_btn_del.string, m_btn_color)
        lbl_del:setPosition(CCPoint(btn_del0:getContentSize().width/2, btn_del0:getContentSize().height/2))
        btn_del0:addChild(lbl_del)
        local btn_del = SpineMenuItem:create(json.ui.button, btn_del0)
        btn_del:setPosition(CCPoint(content_container_w/2-88, 34))
        local btn_del_menu = CCMenu:createWithItem(btn_del)
        btn_del_menu:setPosition(CCPoint(0, 0))
        content_container:addChild(btn_del_menu)
        btn_del:registerScriptTapHandler(function()
            audio.play(audio.button)
            addWaitNet()
            maildata.netDel(mailObj, function(__data)
                delWaitNet()
                tbl2string(__data)
                if __data.status ~= 0 then
                    showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                    return
                end
                maildata.del(mailObj)
                onTabSel(TAB.INB)
            end)
        end)

        local btn_reply0 = img.createLogin9Sprite(img.login.button_9_small_gold)
        btn_reply0:setPreferredSize(btn_size)
        local lbl_reply = lbl.createFont1(18, i18n.global.mail_btn_reply.string, m_btn_color)
        lbl_reply:setPosition(CCPoint(btn_reply0:getContentSize().width/2, btn_reply0:getContentSize().height/2))
        btn_reply0:addChild(lbl_reply)
        local btn_reply = SpineMenuItem:create(json.ui.button, btn_reply0)
        btn_reply:setPosition(CCPoint(content_container_w/2+88, 34))
        local btn_reply_menu = CCMenu:createWithItem(btn_reply)
        btn_reply_menu:setPosition(CCPoint(0, 0))
        content_container:addChild(btn_reply_menu)
        btn_reply:registerScriptTapHandler(function()
            disableObjAWhile(btn_reply, 2)
            audio.play(audio.button)
            if not params then
                params = {
                    sendto = mailObj.uid,
                    mid = mailObj.mid,
                    tab = TAB.NEW,
                    close = true,
                }
            end
            params.sendto = mailObj.uid or ""
            --onTabSel(TAB.NEW)
            layer:addChild(require("ui.mail.main").create(params), 1000)
        end)
        local mail_type = maildata.getTypeById(mailObj.id)
        if mail_type == maildata.TYPE.ALLPLAYER then
            btn_del:setPosition(CCPoint(content_container_w/2, 34))
            btn_reply:setEnabled(false)
            btn_reply:setVisible(false)
        end
        scroll.setOffsetBegin()
    end

    local function showLinkContent(mailObj, isAffix)
        processMailContent(mailObj)
        -- txt bg
        local txt_bg = img.createUI9Sprite(img.ui.mail_content_bg)
        txt_bg:setPreferredSize(CCSizeMake(406, 356))
        txt_bg:setAnchorPoint(CCPoint(1, 1))
        txt_bg:setPosition(CCPoint(content_container_w, content_container_h))
        content_container:addChild(txt_bg)
        local txt_bg_w = txt_bg:getContentSize().width
        local txt_bg_h = txt_bg:getContentSize().height
        -- scroll
        local scroll = createContentScroll()
        scroll:setAnchorPoint(CCPoint(0, 0))
        scroll:setPosition(CCPoint(17, 10))
        txt_bg:addChild(scroll)
        scroll.addSpace(10)
        -- title
        local lbl_mail_title = lbl.create({kind="ttf", size=20, text=mailObj.title, color=ccc3(0x83, 0x41, 0x1d),})
        lbl_mail_title.ax = 0.5
        lbl_mail_title.px = 190
        scroll.addItem(lbl_mail_title)
        scroll.addSpace(16)

        local body1, body2, link_text, link_url
        if mailObj.content then
            local cont_params = cjson.decode(mailObj.content)
            if type(cont_params) == "table" and cont_params["content1"] then
                body1 = cont_params["content1"]
            end
            if type(cont_params) == "table" and cont_params["content2"] then
                body2 = cont_params["content2"]
            end
            if type(cont_params) == "table" and cont_params["link_text"] then
                link_text = cont_params["link_text"]
            end
            if type(cont_params) == "table" and cont_params["link_url"] then
                link_url = cont_params["link_url"]
            end
        end
        -- body1
        if body1 then
            local lbl_body = lbl.create({kind="ttf", font=1, size=17, text=body1, 
                color=ccc3(0x83, 0x41, 0x1d),
                width = 358, align = kCCTextAlignmentLeft,
            })
            lbl_body.ax = 0.5
            lbl_body.px = 190
            scroll.addItem(lbl_body)
            scroll.addSpace(10)
        end
        -- link
        if link_text and link_url then
            local lbl_body = lbl.create({kind="ttf", font=1, size=17, text=link_text, 
                color=ccc3(0x00, 0x00, 0xf0),
                width = 300, align = kCCTextAlignmentLeft,
            })
            local link_node = CCSprite:create()
            link_node:setContentSize(CCSizeMake(300, lbl_body:getContentSize().height))
            local btn_link0 = CCSprite:create()
            btn_link0:setContentSize(CCSizeMake(300, lbl_body:getContentSize().height))
            local btn_link = CCMenuItemSprite:create(btn_link0, nil)
            btn_link:setPosition(CCPoint(link_node:getContentSize().width/2, link_node:getContentSize().height/2))
            local btn_link_menu = CCMenu:createWithItem(btn_link)
            btn_link_menu:setPosition(CCPoint(0, 0))
            link_node:addChild(btn_link_menu)
            lbl_body:setPosition(CCPoint(link_node:getContentSize().width/2, link_node:getContentSize().height/2))
            link_node:addChild(lbl_body)
            link_node.ax = 0.5
            link_node.px = 190
            scroll.addItem(link_node)
            scroll.addSpace(10)
            btn_link:registerScriptTapHandler(function()
                audio.play(audio.button)
                device.openURL(link_url)
            end)
        end
        -- body2
        if body2 then
            local lbl_body = lbl.create({kind="ttf", font=1, size=17, text=body2, 
                color=ccc3(0x83, 0x41, 0x1d),
                width = 358, align = kCCTextAlignmentLeft,
            })
            lbl_body.ax = 0.5
            lbl_body.px = 190
            scroll.addItem(lbl_body)
            scroll.addSpace(10)
        end
        -- from
        local lbl_from = lbl.create({kind="ttf", size=20, text=mailObj.from, color=ccc3(0x83, 0x41, 0x1d),})
        lbl_from.ax = 1
        lbl_from.px = 367
        scroll.addItem(lbl_from)
        scroll.addSpace(10)

        if isAffix and mailObj.affix then
            -- split line
            local split_line = img.createUISprite(img.ui.mail_content_split)
            split_line.ax = 0.5
            split_line.px = 190
            scroll.addItem(split_line)
            scroll.addSpace(10)
            -- rewards
            local lbl_rewards = lbl.create({font=1, size=20, text=i18n.global.mail_rewards.string, color=ccc3(0x83, 0x41, 0x1d),})
            lbl_rewards.ax = 0.5
            lbl_rewards.px = 190
            scroll.addItem(lbl_rewards)
            scroll.addSpace(10)
            -- 已领取标签
            if mailObj.flag == 2 then      -- 已领取附件
                local icon_got = img.createUISprite(img.ui.mail_icon_got)
                icon_got:setPosition(CCPoint(380-45, split_line:getPositionY()))
                split_line:getParent():addChild(icon_got, 10)
            end
            local item_count = 0
            if mailObj.affix.items then
                item_count = item_count + #mailObj.affix.items
            end
            if mailObj.affix.equips then
                item_count = item_count + #mailObj.affix.equips
            end
            local affix_container_w = 361
            local affix_container_h = math.floor((item_count + 3)/4)*(85+7)
            local affix_container = CCSprite:create()
            affix_container:setContentSize(CCSizeMake(affix_container_w, affix_container_h))
            local off_x, off_y = 40, affix_container_h - 43
            local off_step = 91
            local item_idx = 0
            if mailObj.affix.items then
                for _, _obj in ipairs(mailObj.affix.items) do
                    item_idx = item_idx + 1
                    local tmp_item0 = img.createItem(_obj.id, _obj.num)
                    local tmp_item = CCMenuItemSprite:create(tmp_item0, nil)
                    tmp_item:setPosition(CCPoint(off_x+(item_idx-1)%4*off_step, off_y-math.floor((item_idx+3)/4-1)*off_step))
                    local tmp_item_menu = CCMenu:createWithItem(tmp_item)
                    tmp_item_menu:setPosition(CCPoint(0, 0))
                    affix_container:addChild(tmp_item_menu)
                    tmp_item:registerScriptTapHandler(function()
                        audio.play(audio.button)
                        layer:addChild(tipsitem.createForShow(_obj), 1000)
                    end)
                    --local grid = img.createUISprite(img.ui.grid)
                    --grid:setPosition(CCPoint(tmp_item:getContentSize().width/2, tmp_item:getContentSize().height/2))
                    --tmp_item:addChild(grid, -1)
                    if mailObj.flag == 2 then      -- 已领取附件
                        setShader(tmp_item, SHADER_GRAY, true)
                    end
                end
            end
            if mailObj.affix.equips then
                for _, _obj in ipairs(mailObj.affix.equips) do
                    item_idx = item_idx + 1
                    local tmp_item0 = img.createEquip(_obj.id, _obj.num)
                    local tmp_item = CCMenuItemSprite:create(tmp_item0, nil)
                    tmp_item:setPosition(CCPoint(off_x+(item_idx-1)%4*off_step, off_y-math.floor((item_idx+3)/4-1)*off_step))
                    local tmp_item_menu = CCMenu:createWithItem(tmp_item)
                    tmp_item_menu:setPosition(CCPoint(0, 0))
                    affix_container:addChild(tmp_item_menu)
                    tmp_item:registerScriptTapHandler(function()
                        audio.play(audio.button)
                        layer:addChild(tipsequip.createForShow(_obj), 1000)
                    end)
                    --local grid = img.createUISprite(img.ui.grid)
                    --grid:setPosition(CCPoint(tmp_item:getContentSize().width/2, tmp_item:getContentSize().height/2))
                    --tmp_item:addChild(grid, -1)
                    if mailObj.flag == 2 then      -- 已领取附件
                        setShader(tmp_item, SHADER_GRAY, true)
                    end
                end
            end
            affix_container.ax = 0.5
            affix_container.px = 190
            scroll.addItem(affix_container)
            scroll.addSpace(10)
            
            if mailObj.flag == 2 then      -- 已领取附件
                --local btn_get = img.createLogin9Sprite(img.login.button_9_small_blue)
                --btn_get:setPreferredSize(CCSizeMake(118, 42))
                --btn_get:setPosition(CCPoint(content_container_w/2+78, 34))
                --content_container:addChild(btn_get)
                --local lbl_get = lbl.createFont1(20, "GOTTEN", ccc3(0x83, 0x41, 0x1d))
                --lbl_get:setPosition(CCPoint(btn_get:getContentSize().width/2, btn_get:getContentSize().height/2))
                --btn_get:addChild(lbl_get)
                
                -- buttons
                local btn_del0 = img.createLogin9Sprite(img.login.button_9_small_gold)
                btn_del0:setPreferredSize(btn_size)
                local lbl_del = lbl.createFont1(18, i18n.global.mail_btn_del.string, m_btn_color)
                lbl_del:setPosition(CCPoint(btn_del0:getContentSize().width/2, btn_del0:getContentSize().height/2))
                btn_del0:addChild(lbl_del)
                local btn_del = SpineMenuItem:create(json.ui.button, btn_del0)
                btn_del:setPosition(CCPoint(content_container_w/2, 34))
                local btn_del_menu = CCMenu:createWithItem(btn_del)
                btn_del_menu:setPosition(CCPoint(0, 0))
                content_container:addChild(btn_del_menu)
                btn_del:registerScriptTapHandler(function()
                    audio.play(audio.button)
                    addWaitNet()
                    maildata.netDel(mailObj, function(__data)
                        delWaitNet()
                        tbl2string(__data)
                        if __data.status ~= 0 then
                            showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                            return
                        end
                        maildata.del(mailObj)
                        onTabSel(current_tab)
                    end)
                end)
            else        -- 可以领取附件
                local btn_get0 = img.createLogin9Sprite(img.login.button_9_small_gold)
                btn_get0:setPreferredSize(btn_size)
                local lbl_get = lbl.createFont1(18, i18n.global.mail_btn_get.string, m_btn_color)
                lbl_get:setPosition(CCPoint(btn_get0:getContentSize().width/2, btn_get0:getContentSize().height/2))
                btn_get0:addChild(lbl_get)
                local btn_get = SpineMenuItem:create(json.ui.button, btn_get0)
                btn_get:setPosition(CCPoint(content_container_w/2, 34))
                local btn_get_menu = CCMenu:createWithItem(btn_get)
                btn_get_menu:setPosition(CCPoint(0, 0))
                content_container:addChild(btn_get_menu)
                btn_get:registerScriptTapHandler(function()
                    audio.play(audio.button)
                    addWaitNet()
                    maildata.affix({mailObj.mid}, function(__data)
                        tbl2string(__data)
                        delWaitNet()
                        if __data.status ~= 0 then
                            showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                            return
                        end
                        mailObj.flag = 2
						local oldxp = checkLevelUp1(bagdata)
                        if __data.affix and __data.affix.items then
                            bagdata.items.addAll(__data.affix.items)
                            -- 处理好战者头像
                            processSpecialHead(__data.affix.items)
                        end
                        if __data.affix and __data.affix.equips then
                            bagdata.equips.addAll(__data.affix.equips)
                        end
                        -- show affix
						checkLevelUp2(bagdata, oldxp)
                        if __data.affix then
                            CCDirector:sharedDirector():getRunningScene():addChild(rewards.createFloating(__data.affix), 100000)
                        end
                        onTabSel(TAB.SYS)
                    end)
                end)
            end
        else  -- 文本邮件 删除
            -- buttons
            local btn_del0 = img.createLogin9Sprite(img.login.button_9_small_gold)
            btn_del0:setPreferredSize(btn_size)
            local lbl_del = lbl.createFont1(18, i18n.global.mail_btn_del.string, m_btn_color)
            lbl_del:setPosition(CCPoint(btn_del0:getContentSize().width/2, btn_del0:getContentSize().height/2))
            btn_del0:addChild(lbl_del)
            local btn_del = SpineMenuItem:create(json.ui.button, btn_del0)
            btn_del:setPosition(CCPoint(content_container_w/2, 34))
            local btn_del_menu = CCMenu:createWithItem(btn_del)
            btn_del_menu:setPosition(CCPoint(0, 0))
            content_container:addChild(btn_del_menu)
            btn_del:registerScriptTapHandler(function()
                audio.play(audio.button)
                addWaitNet()
                maildata.netDel(mailObj, function(__data)
                    delWaitNet()
                    tbl2string(__data)
                    if __data.status ~= 0 then
                        showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                        return
                    end
                    maildata.del(mailObj)
                    onTabSel(current_tab)
                end)
            end)
        end
        scroll.setOffsetBegin()
    end

    local function processMailLink2(mailObj)
        local mail_body = i18n.mail[mailObj.id].content
        local cont_arr = string.split(mail_body, "|||")
        local mail_content = {
            content1 = cont_arr[1],
            link_text = cont_arr[2],
            link_url = cont_arr[3],
            content2 = cont_arr[4],
        }
        mailObj.content = cjson.encode(mail_content)
    end

    local function showContent(mailObj)
        content_container:removeAllChildrenWithCleanup(true)
        local mail_type = maildata.getTypeById(mailObj.id)
        if mail_type == maildata.TYPE.AFFIX then
            showAffixContent(mailObj)
        elseif mail_type == maildata.TYPE.ACTIVITY then
            showTextContent(mailObj)
        elseif mail_type == maildata.TYPE.GUILD then
            showTextContent(mailObj)
        elseif mail_type == maildata.TYPE.SYS then
            showTextContent(mailObj)
        elseif mail_type == maildata.TYPE.PLAYER then
            showPlayerContent(mailObj)
        elseif mail_type == maildata.TYPE.ALLPLAYER then
            showPlayerContent(mailObj)
        elseif mail_type == maildata.TYPE.LINK then
            showLinkContent(mailObj, true)
        elseif mail_type == maildata.TYPE.LINK2 then
            processMailLink2(mailObj)
            showLinkContent(mailObj, true)
        end
    end

    local function createListScroll(which)
        local scroll_height = 429
        if which == TAB.INB then
            scroll_height = 429
        elseif which == TAB.SYS then
            scroll_height = 429 - 54
        end
        local scroll_params = {
            width = 304,
            height = scroll_height,
        }
        local lineScroll = require "ui.lineScroll"
        return lineScroll.create(scroll_params)
    end

    local function showList(listObj, which)
        local list_bg = img.createUI9Sprite(img.ui.mail_list_bg)
        if which == TAB.INB then
            list_bg:setPreferredSize(CCSizeMake(314, 435))
        elseif which == TAB.SYS then
            list_bg:setPreferredSize(CCSizeMake(314, 435-54))
        end
        list_bg:setAnchorPoint(CCPoint(0, 0))
        list_bg:setPosition(CCPoint(0, 0))
        container:addChild(list_bg)
        local scroll = createListScroll(which)
        scroll:setAnchorPoint(CCPoint(0, 0))
        scroll:setPosition(CCPoint(5, 3))
        container:addChild(scroll, 2)
        container.list_scroll = scroll
        --drawBoundingbox(board, container, ccc4f(1, 0x00, 0x00, 1))
        --drawBoundingbox(container, scroll, ccc4f(1,0,1,1))
        arrayclear(items)
        scroll.addSpace(3)
        for ii=1,#listObj do
            local tmp_item = createItem(listObj[ii])
            tmp_item.mailObj = listObj[ii]
            tmp_item.ax = 0.5
            tmp_item.px = 152
            tmp_item.ay = 0.5
            scroll.addItem(tmp_item)
            items[#items+1] = tmp_item
            if ii ~= #listObj then
                scroll.addSpace(2)
            end
        end
        scroll.setOffsetBegin()
        if #items > 0 then
            showContent(items[1].mailObj)
            items[1].setRead()
            items[1].focus:setVisible(true)
            last_selet_item = items[1]
        end
        -- btn_batch_get
        if which == TAB.SYS then
            local btn_batch_get0 = img.createLogin9Sprite(img.login.button_9_small_gold)
            btn_batch_get0:setPreferredSize(CCSizeMake(258, 47))
            local lbl_batch_get = lbl.createFont1(18, i18n.global.mail_btn_batch.string, ccc3(0x73, 0x3b, 0x05))
            lbl_batch_get:setPosition(CCPoint(btn_batch_get0:getContentSize().width/2, btn_batch_get0:getContentSize().height/2))
            btn_batch_get0:addChild(lbl_batch_get)
            local btn_batch_get = SpineMenuItem:create(json.ui.button, btn_batch_get0)
            btn_batch_get:setPosition(CCPoint(133, container_h-23))
            local btn_batch_get_menu = CCMenu:createWithItem(btn_batch_get)
            btn_batch_get_menu:setPosition(CCPoint(0, 0))
            container:addChild(btn_batch_get_menu)
            btn_batch_get:registerScriptTapHandler(function()
                audio.play(audio.button)
                local mids = {}
                for ii=1,#listObj do
                    if listObj[ii].flag ~= 2 and maildata.getTypeById(listObj[ii].id) == 1 then
                        mids[#mids+1] = listObj[ii].mid
                    end
                end
                if #mids <= 0 then
                    showToast(i18n.global.mail_get_nothing.string)
                    return
                end
                addWaitNet()
                maildata.affix(mids, function(__data)
                    tbl2string(__data)
                    delWaitNet()
                    if __data.status ~= 0 then
                        showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                        return
                    end
					local oldxp = checkLevelUp1(bagdata)
                    if __data.affix and __data.affix.items then
                        bagdata.items.addAll(__data.affix.items)
                        -- 处理好战者头像
                        processSpecialHead(__data.affix.items)
                    end
                    if __data.affix and __data.affix.equips then
                        bagdata.equips.addAll(__data.affix.equips)
                    end
                    maildata.flagByMids(mids)
                    -- show affix
					checkLevelUp2(bagdata, oldxp)
                    if __data.affix then
                        if layer and not tolua.isnull(layer) then
                            layer:addChild(rewards.createFloating(__data.affix))
                        end
                    end
                    onTabSel(TAB.SYS)
                end)
            end)
            local btn_batch_del0 = img.createUISprite(img.ui.mail_icon_del)
            local btn_batch_del = SpineMenuItem:create(json.ui.button, btn_batch_del0)
            btn_batch_del:setPosition(CCPoint(292, container_h-25))
            local btn_batch_del_menu = CCMenu:createWithItem(btn_batch_del)
            btn_batch_del_menu:setPosition(CCPoint(0, 0))
            container:addChild(btn_batch_del_menu)
            btn_batch_del:registerScriptTapHandler(function()
                audio.play(audio.button)
                coupleBatchDel(layer, function()
                    onTabSel(TAB.SYS)
                end)
            end)
        end
    end

    local function showNomail()
        --local icon_nomail = img.createUISprite(img.ui.mail_icon_nomail)
        local icon_nomail = json.create(json.ui.mailbox)
        icon_nomail:playAnimation("animation", -1)
        icon_nomail:setPosition(CCPoint(container_w/2, container_h/2))
        container:addChild(icon_nomail)
        local lbl_nomail = lbl.createFont1(18, i18n.global.mail_empty.string, ccc3(0x93, 0x6c, 0x54))
        lbl_nomail:setPosition(CCPoint(container_w/2, container_h/2-20))
        container:addChild(lbl_nomail)
    end

    local function createInb()
        container:removeAllChildrenWithCleanup(true)
        local maillist = maildata.getPlayerMails()
        if not maillist or #maillist==0 then
            showNomail()
            return
        end
        showList(maillist, TAB.INB)
    end

    local function createSys()
        container:removeAllChildrenWithCleanup(true)
        local maillist = maildata.getSysMails()
        if not maillist or #maillist==0 then
            showNomail()
            return
        end
        showList(maillist, TAB.SYS)
    end

    local function createNew()
        -- 写邮件以新弹窗方式展示，不需要右tab
        tab_inb:setVisible(false)
        tab_inb_hl:setVisible(false)
        tab_sys:setVisible(false)
        tab_sys_hl:setVisible(false)
        tab_new:setVisible(false)
        tab_new_hl:setVisible(false)

        arrayclear(items)
        container:removeAllChildrenWithCleanup(true)
        -- bg
        local new_bg = img.createUI9Sprite(img.ui.mail_new_bg)
        new_bg:setPreferredSize(CCSizeMake(704, 356))
        new_bg:setPosition(CCPoint(container_w/2-5, 238))
        container:addChild(new_bg)
        local new_bg_w = new_bg:getContentSize().width
        local new_bg_h = new_bg:getContentSize().height
        -- ADDRESS
        local lbl_addr = lbl.createFont1(18, i18n.global.mail_address.string, ccc3(0x64, 0x30, 0x16))
        lbl_addr:setAnchorPoint(CCPoint(0, 0))
        lbl_addr:setPosition(CCPoint(36, 322))
        new_bg:addChild(lbl_addr)
        local sprite_addr_input = img.createLogin9Sprite(img.login.input_border)
        sprite_addr_input:setPreferredSize(CCSizeMake(636, 52))
        sprite_addr_input:setPosition(CCPoint(new_bg_w/2, 291))
        new_bg:addChild(sprite_addr_input)
        local lbl_addr_input = CCLabelTTF:create(params and params.sendto or "", "", 18)
        lbl_addr_input:setColor(ccc3(0x64, 0x30, 0x16))
        lbl_addr_input:setAnchorPoint(CCPoint(0, 0.5))
        lbl_addr_input:setPosition(CCPoint(17, sprite_addr_input:getContentSize().height/2))
        sprite_addr_input:addChild(lbl_addr_input)
        -- CONTENT
        local lbl_content = lbl.createFont1(18, i18n.global.mail_content.string, ccc3(0x64, 0x30, 0x16))
        lbl_content:setAnchorPoint(CCPoint(0, 0))
        lbl_content:setPosition(CCPoint(36, 235))
        new_bg:addChild(lbl_content)
        local sprite_content_input = img.createLogin9Sprite(img.login.input_border)
        sprite_content_input:setPreferredSize(CCSizeMake(636, 202))
        sprite_content_input:setPosition(CCPoint(new_bg_w/2, 130))
        new_bg:addChild(sprite_content_input)
        local lbl_content_input = CCLabelTTF:create(params and params.content or "", "", 18)
        lbl_content_input:setColor(ccc3(0x64, 0x30, 0x16))                                                                                      
        lbl_content_input:setHorizontalAlignment(kCCTextAlignmentLeft)                                                                  
        lbl_content_input:setDimensions(CCSizeMake(602, 168))                                                                            
        lbl_content_input:setAnchorPoint(CCPoint(0.5, 1))                                                                                
        lbl_content_input:setPosition(CCPoint(sprite_content_input:getContentSize().width/2, 185))                         
        sprite_content_input:addChild(lbl_content_input)
        --drawBoundingbox(sprite_content_input, lbl_content_input)
        local function onAddrClick(_str)
            local addr_str = _str or ""
            addr_str = string.trim(addr_str)
            if addr_str == "" then
            else
                -- check invalid chars
                if containsInvalidChar(addr_str) then
                    showToast(i18n.global.input_invalid_char.string)
                    return
                end
                lbl_addr_input:setString(addr_str)
            end
        end
        local function onContentClick(_str)
            local content_str = _str or ""
            content_str = string.trim(content_str)
            if content_str == "" then
            else
                -- check invalid chars
                if containsInvalidChar(content_str) then
                    showToast(i18n.global.input_invalid_char.string)
                    return
                end
                lbl_content_input:setString(content_str)
                input_content = content_str
            end
        end
        local touchInputBeginx, touchInputBeginy
        local isClickInput
        local function onTouchInputBegan(x, y)
            touchInputBeginx, touchInputBeginy = x, y
            isClickInput = true
            return true
        end
        local function onTouchInputMoved(x, y)
            if isClickInput and (math.abs(touchInputBeginx-x) > 10 or math.abs(touchInputBeginy-y) > 10) then
                isClickInput = false
            end
        end
        local function onTouchInputEnded(x, y)
            if isClickInput then
                local p0 = new_bg:convertToNodeSpace(ccp(x, y))
                if sprite_addr_input:boundingBox():containsPoint(p0) then
                    if true then --  不再需要编辑
                        return
                    elseif params and params.sendto and params.sendto == "@all" then
                        return
                    end
                    local inputlayer = require "ui.inputlayer"
                    layer:addChild(inputlayer.create(onAddrClick, lbl_addr_input:getString()), 10000)
                elseif sprite_content_input:boundingBox():containsPoint(p0) then
                    local inputlayer = require "ui.inputlayer"
                    layer:addChild(inputlayer.create(onContentClick, lbl_content_input:getString(), {maxLen=768}), 10000)
                end
            end
        end
        local function onTouchInput(eventType, x, y)
            if eventType == "began" then   
                return onTouchInputBegan(x, y)
            elseif eventType == "moved" then
                return onTouchInputMoved(x, y)
            else
                return onTouchInputEnded(x, y)
            end
        end
        new_bg:registerScriptTouchHandler(onTouchInput , false , -128 , false)
        new_bg:setTouchEnabled(true)
        ---- btn cancel
        --local btn_cancel0 = img.createLogin9Sprite(img.login.button_9_small_gold)
        --btn_cancel0:setPreferredSize(CCSizeMake(192, 46))
        --local lbl_cancel = lbl.createFont1(20, "CANCEL", ccc3(0x64, 0x30, 0x16))
        --lbl_cancel:setPosition(CCPoint(btn_cancel0:getContentSize().width/2, btn_cancel0:getContentSize().height/2))
        --btn_cancel0:addChild(lbl_cancel)
        --local btn_cancel = SpineMenuItem:create(json.ui.button, btn_cancel0)
        --btn_cancel:setPosition(CCPoint(container_w/2-132, 35))
        --local btn_cancel_menu = CCMenu:createWithItem(btn_cancel)
        --btn_cancel_menu:setPosition(CCPoint(0, 0))
        --container:addChild(btn_cancel_menu)
        -- btn send
        local btn_send0 = img.createLogin9Sprite(img.login.button_9_small_gold)
        btn_send0:setPreferredSize(CCSizeMake(192, 46))
        local lbl_send = lbl.createFont1(20, i18n.global.mail_btn_send.string, ccc3(0x64, 0x30, 0x16))
        lbl_send:setPosition(CCPoint(btn_send0:getContentSize().width/2, btn_send0:getContentSize().height/2))
        btn_send0:addChild(lbl_send)
        local btn_send = SpineMenuItem:create(json.ui.button, btn_send0)
        btn_send:setPosition(CCPoint(container_w/2, 25))
        local btn_send_menu = CCMenu:createWithItem(btn_send)
        btn_send_menu:setPosition(CCPoint(0, 0))
        container:addChild(btn_send_menu)
        btn_send:registerScriptTapHandler(function()
            audio.play(audio.button)
            if maildata.last_sent then
                if os.time() - maildata.last_sent < 30 then
                    showToast(string.format(i18n.global.mail_interval.string, 30-(os.time()-maildata.last_sent)))
                    return
                end
            end
            local mailto = string.trim(lbl_addr_input:getString())
            if not mailto or mailto == "" then
                showToast(i18n.global.mail_address_empty.string)
                return
            end
            -- 如果是"@all", 转换成0
            if mailto == "@all" then
                mailto = 0
            elseif string.len(mailto) ~= 8 then   -- uid固定长度8位
                showToast(i18n.global.mail_invalid_uid.string)
                return
            end
            if mailto ~= 0 then
                mailto = checkint(mailto)
                if mailto == 0 then
                    showToast(i18n.global.mail_invalid_uid.string)
                    return
                end
            end
            local mailcontent = string.trim(lbl_content_input:getString())
            if not mailcontent or mailcontent == "" then
                showToast(i18n.global.mail_content_empty.string)
                return
            end
            -- limit ban word
            if isBanWord(mailto) then
                showToast(i18n.global.input_invalid_char.string)
                return
            end
            if isBanWord(mailcontent) then
                showToast(i18n.global.input_invalid_char.string)
                return
            end
            addWaitNet()
            local mail_params = {
                sid = player.sid,
                uid = mailto,
                content = mailcontent,
                mid = params and params.mid or nil,
            }
            maildata.send(mail_params, function(__data)
                tbl2string(__data)
                delWaitNet()
                if __data.status ~= 0 then
                    if __data.status == -1 or __data.status == -2 then
                        showToast(i18n.global.permission_denied.string)
                        return
                    end
                    showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                    return
                end
                maildata.last_sent = os.time()
                showToast(i18n.global.mail_send_ok.string)
                input_content = nil
                if params and params.close then
                    current_tab = TAB.INB
                    layer:removeFromParentAndCleanup(true)
                else
                    onTabSel(TAB.INB)
                end
            end)
        end)
    end

    local tabs = {}
    tabs[TAB.INB] = {btn = tab_inb, hl = tab_inb_hl}
    tabs[TAB.SYS] = {btn = tab_sys, hl = tab_sys_hl}
    tabs[TAB.NEW] = {btn = tab_new, hl = tab_new_hl}
    tab_new:setVisible(false)
    tab_new_hl:setVisible(false)
    local function doTabSel(which)
        if not container or tolua.isnull(container) then return end
        container:removeAllChildrenWithCleanup(true)
        content_container:removeAllChildrenWithCleanup(true)
        container.list_scroll = nil
        for _, _obj in ipairs(tabs) do
            _obj.btn:setEnabled(true)
            _obj.hl:setVisible(false)
        end
        current_tab = which
        if which == TAB.INB then
            tab_inb:setEnabled(false)
            tab_inb_hl:setVisible(true)
            lbl_title:setString(titles[TAB.INB])
            createInb()
        elseif which == TAB.SYS then
            tab_sys:setEnabled(false)
            tab_sys_hl:setVisible(true)
            lbl_title:setString(titles[TAB.SYS])
            createSys()
        elseif which == TAB.NEW then
            tab_new:setVisible(false)
            tab_new_hl:setVisible(false)
            lbl_title:setString(titles[TAB.NEW])
            createNew()
        end
    end
    function onTabSel(which)
        if current_tab == TAB.NEW and which ~= TAB.NEW then
            dropConfirm(layer, function()
                doTabSel(which)
            end)
        else
            doTabSel(which)
        end
    end
    onTabSel(current_tab)

    if params and params.sendto and params.sendto == "@all" then
        tab_inb:setVisible(false)
        tab_sys:setVisible(false)
        tab_new:setVisible(false)
        tab_inb_hl:setVisible(false)
        tab_sys_hl:setVisible(false)
        tab_new_hl:setVisible(false)
        board:setPosition(view.midX, view.midY)
    elseif params and params.tab and params.tab == TAB.NEW then
        tab_inb:setVisible(false)
        tab_sys:setVisible(false)
        tab_new:setVisible(false)
        tab_inb_hl:setVisible(false)
        tab_sys_hl:setVisible(false)
        tab_new_hl:setVisible(false)
        board:setPosition(view.midX, view.midY)
    end

    tab_inb:registerScriptTapHandler(function()
        audio.play(audio.button)
        onTabSel(TAB.INB)
    end)
    tab_sys:registerScriptTapHandler(function()
        audio.play(audio.button)
        onTabSel(TAB.SYS)
    end)
    tab_new:registerScriptTapHandler(function()
        audio.play(audio.button)
        onTabSel(TAB.NEW)
    end)

    -- touch event
    local touchbeginx, touchbeginy
    local isclick
    local last_touch_sprite = nil
    local function onTouchBegan(x, y)
        touchbeginx, touchbeginy = x, y
        isclick = true
        if current_tab ~= TAB.NEW then
            if container.list_scroll and not tolua.isnull(container.list_scroll) then
                local obj = container.list_scroll.content_layer
                local p0 = obj:convertToNodeSpace(ccp(x, y))
                for ii=1,#items do
                    if items[ii]:boundingBox():containsPoint(p0) then
                        playAnimTouchBegin(items[ii])
                        last_touch_sprite = items[ii]
                    end
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
        if isclick and current_tab ~= TAB.NEW then
            if last_touch_sprite and not tolua.isnull(last_touch_sprite) then
                playAnimTouchEnd(last_touch_sprite)
                last_touch_sprite = nil
            end
            if container.list_scroll and not tolua.isnull(container.list_scroll) then
                local obj = container.list_scroll.content_layer
                local p0 = obj:convertToNodeSpace(ccp(x, y))
                for ii=1,#items do
                    if items[ii]:boundingBox():containsPoint(p0) then
                        if last_selet_item ~= items[ii] then
                            audio.play(audio.button)
                            if last_selet_item then
                                last_selet_item.focus:setVisible(false)
                            end
                            items[ii].focus:setVisible(true)
                            last_selet_item = items[ii]
                            showContent(items[ii].mailObj)
                            items[ii].setRead()
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
