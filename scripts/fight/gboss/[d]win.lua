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
local cfggboss = require "config.guildboss"

function ui.create(video)
    local layer = require("fight.base.win").create()

    local cfg = cfggboss[video.boss]

    layer.addOkButton(function()
        require("fight.gboss.loading").backToUI(video)
    end)

    if video.hurts and #video.hurts > 0 then
        local camp = {}
        for i, m in ipairs(cfg.monster) do
            camp[#camp+1] = { kind = "mons", id = m, pos = cfg.stand[i] }
        end
        layer.addHurtsButton(video.camp, camp, video.hurts, video)
        layer.addHurtsSum(video.hurts)
    end

    local equips, items = {}, {}
    for _, r in ipairs(cfg.reward) do
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
