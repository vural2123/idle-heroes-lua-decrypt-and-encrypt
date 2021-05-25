-- video ad

local ui = {}

require "common.const"
require "common.func"
local view = require "common.view"
local i18n = require "res.i18n"
local img = require "res.img"
local lbl = require "res.lbl"
local audio = require "res.audio"
local json = require "res.json"
local net = require "net.netClient"
local playerdata = require "data.player"
local videoaddata = require "data.videoad"

local NUM_OF_GEM     = 20

function ui.create(onFinish)
    local layer = require("ui.dialog").create({
        title = i18n.global.video_ad_title.string,
        body = i18n.global.video_ad_text.string,
        btn_count = 2,
        btn_text = {
            [1] = i18n.global.dialog_button_cancel.string,
            [2] = i18n.global.dialog_button_confirm.string,
        },
        selected_btn = 0
    })

    local size = layer.board:getContentSize()
    layer.bodyLabel:setPosition(size.width/2, size.height-75)
    local icon = img.createItem(ITEM_ID_GEM, NUM_OF_GEM)
    local btn = SpineMenuItem:create(json.ui.button, icon)
    btn:setPosition(size.width/2, layer.bodyLabel:boundingBox():getMinY()-45)
    btn:setScale(0.8)
    local menu = CCMenu:createWithItem(btn)
    menu:setPosition(0, 0)
    layer.board:addChild(menu)
    btn:registerScriptTapHandler(function()
        layer:addChild(require("ui.tips.item").createForShow({
            id = ITEM_ID_GEM, num = NUM_OF_GEM
        }), 1000)
        audio.play(audio.button)
    end)

    -- 观看视频上报
    local function postWatch()
        addWaitNet()
        net:video_ad({ sid = playerdata.sid }, function(data)
            delWaitNet()
            if data.status ~= 0 then
                showToast(i18n.global.error_server_status_wrong.string .. data.status)
                return
            end
            local videoAdUID = tostring(playerdata.uid) .. "-" .. playerdata.sid
            if device.platform == "ios" then 
                videoAdUID = videoAdUID .. "-ios"
            end
            print("videoAdUID", videoAdUID)
            HHUtils:showVideoAd(videoAdUID)
            videoaddata.watch()
            layer:removeFromParent()
            if onFinish then onFinish() end
        end)
    end

    layer.setCallback(function(data)
        if data.selected_btn == 1 then
            layer.onAndroidBack()
        else
            postWatch()
        end
    end)

    function layer.onAndroidBack()
        layer:removeFromParent()
    end

    return layer
end

return ui
