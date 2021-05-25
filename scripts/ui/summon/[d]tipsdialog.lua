local heroDialog = {}

local i18n = require "res.i18n"
local img = require "res.img"
local lbl = require "res.lbl"
local audio = require "res.audio"
local json = require "res.json"

--[[
-- usage: just call the method 'show'
-- parent_obj: the node which is the parent of buyDialog
-- from_where: tell storelayer where go back
-- body_text:  dialog body text, if none, don't give
]]--
function heroDialog.show(parent_obj, from_where, body_text)

    if not body_text then
        body_text = i18n.global.summon_dialog_hero_full.string
    end

    local dialog = require "ui.dialog"
    local function process_dialog(data)
        if data.selected_btn == 1 then
            parent_obj:removeChildByTag(dialog.TAG)
            local herolistlayer = require("ui.herolist.main").create()
            replaceScene(herolistlayer)
        elseif data.selected_btn == 2 then
            parent_obj:removeChildByTag(dialog.TAG)
        end
    end
    local params = {
        title = "",
        body = body_text,
        btn_count = 1,
        btn_color = {
            [1] = dialog.COLOR_GOLD,
        },
        btn_text = {
            [1] = i18n.global.chip_btn_buy.string,
        },
        callback = process_dialog,
    }
    local dialog_ins = dialog.create(params, true)
    dialog_ins:setAnchorPoint(CCPoint(0,0))
    dialog_ins:setPosition(CCPoint(0,0))
    parent_obj:addChild(dialog_ins, 100000, dialog.TAG)
    
    -- close
    local closeBtn0 = img.createUISprite(img.ui.close)
    local closeBtn = SpineMenuItem:create(json.ui.button, closeBtn0)
    closeBtn:setPosition(CCPoint(dialog_ins.board:getContentSize().width-25, 
                    dialog_ins.board:getContentSize().height-28))
    local closeMenu = CCMenu:createWithItem(closeBtn)
    closeMenu:setPosition(0, 0)
    dialog_ins.board:addChild(closeMenu,1000000)
    closeBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        parent_obj:removeChildByTag(dialog.TAG)
    end)

end


return heroDialog
