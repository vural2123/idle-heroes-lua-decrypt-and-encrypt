-- 胜利结算

local ui = {}

require "common.const"
require "common.func"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local i18n = require "res.i18n"
local audio = require "res.audio"

function ui.create(video)
    local layer = require("fight.base.win").create()

    layer.addOkButton(function()
        require("fight.brave.loading").backToUI(video)
    end)

    if video.hurts and #video.hurts > 0 then
        layer.addHurtsButton(video.atk.camp, video.def.camp, video.hurts, video)
    end

    if video.rewards and video.select then
        layer:addChild(require("fight.pvp.lucky").create(video.rewards, video.select), 10)
    end

    local equips, items = {}, {}
    for _, r in ipairs(video.reward) do
        if r.type == 1 then
            items[#items+1] = { id = r.id, num = r.num }
        else
            equips[#equips+1] = { id = r.id, num = r.num }
        end
    end
    layer.addRewardIcons({equips = equips, items = items})

    return layer
end

return ui
