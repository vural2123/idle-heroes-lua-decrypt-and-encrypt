local gitem = {}

require "common.func"
require "common.const"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local audio = require "res.audio"
local cfgitem = require "config.item"
local cfgequip = require "config.equip"
local cfgguildexp = require "config.guildexp"
local player = require "data.player"
local gdata = require "data.guild"
local i18n = require "res.i18n"
local tipsequip = require "ui.tips.equip"
local tipsitem = require "ui.tips.item"
local dialog = require "ui.dialog"
local NetClient = require "net.netClient"
local netClient = NetClient:getInstance()

local itembg = {
    [0] = img.ui.botton_fram_3,
    [1] = img.ui.botton_fram_2,
}

function gitem.createItem(guildObj, _idx)
    _idx = _idx or 1
    local item = img.createUI9Sprite(itembg[_idx%2])
    item:setPreferredSize(CCSizeMake(575, 88))
    local item_w = item:getContentSize().width
    local item_h = item:getContentSize().height

    -- flag
    local flag = img.createGFlag(guildObj.logo)
    flag:setScale(0.7)
    flag:setPosition(CCPoint(48, item_h/2))
    item:addChild(flag)

    -- name
    local lbl_name = lbl.createFontTTF(20, guildObj.name, ccc3(0x51, 0x27, 0x12))
    lbl_name:setAnchorPoint(CCPoint(0, 0))
    lbl_name:setPosition(CCPoint(91, 46))
    item:addChild(lbl_name)

    -- members
    local icon_mem = img.createUISprite(img.ui.guild_icon_mem)
    icon_mem:setAnchorPoint(CCPoint(0, 0))
    icon_mem:setPosition(CCPoint(94, 22))
    item:addChild(icon_mem)
    local lbl_num = lbl.createFont1(16, guildObj.members .. "/" .. gdata.maxMember(guildObj.exp), ccc3(0x7a, 0x53, 0x34))
    lbl_num:setAnchorPoint(CCPoint(0, 0))
    lbl_num:setPosition(CCPoint(120, 19))
    item:addChild(lbl_num)

    -- lv
    local lbl_lv_des = lbl.createFont1(14, i18n.global.guild_col_level.string, ccc3(0xa0, 0x7c, 0x60))
    lbl_lv_des:setPosition(CCPoint(322, 56))
    item:addChild(lbl_lv_des)
    local lbl_lv = lbl.createFont1(24, "" .. gdata.Lv(guildObj.exp), ccc3(0x7a, 0x53, 0x34))
    lbl_lv:setPosition(CCPoint(322, 34))
    item:addChild(lbl_lv)

    -- btn_apply
    local btn_apply0 = img.createLogin9Sprite(img.login.button_9_small_gold)
    btn_apply0:setPreferredSize(CCSizeMake(140, 45))
    local lbl_apply = lbl.createFont1(18, i18n.global.guild_btn_apply.string, ccc3(0x73, 0x3b, 0x05))
    lbl_apply:setPosition(CCPoint(btn_apply0:getContentSize().width/2, btn_apply0:getContentSize().height/2))
    btn_apply0:addChild(lbl_apply)
    local btn_apply = SpineMenuItem:create(json.ui.button, btn_apply0)
    btn_apply:setPosition(CCPoint(487, item_h/2))
    local btn_apply_menu = CCMenu:createWithItem(btn_apply)
    btn_apply_menu:setPosition(CCPoint(0, 0))
    item:addChild(btn_apply_menu)

    btn_apply:registerScriptTapHandler(function()
        audio.play(audio.button)
        local params = {
            sid = player.sid,
            gid = guildObj.id,
        }
        addWaitNet()
        netClient:guild_apply(params, function(__data)
            delWaitNet()
            tbl2string(__data)
            if __data.status ~= 0 then
                showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                return
            end
            btn_apply:setEnabled(false)
            lbl_apply:setString(i18n.global.guild_applied.string)
            setShader(btn_apply, SHADER_GRAY, true)
        end)
    end)

    return item
end

return gitem
