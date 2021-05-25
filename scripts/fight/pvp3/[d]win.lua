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
local herosdata = require "data.heros"

function ui.create(video)
    local layer = require("fight.base.win").create()

    layer.addVsScores(video)

    local ok_str = nil
    if video.wins and #video.wins <= video.idx then
        ok_str = nil
    else
        ok_str = i18n.global.arena_video_next.string
    end
    layer.addOkButton(function()
        require("fight.pvp3.loading").backToUI(video, layer)
    end, ok_str)

    if video.hurts and #video.hurts > 0 then
        layer.addHurtsButton(video.atk.camp, video.def.camp, video.hurts, video)
    end

    -- 3v3 没有奖励, 仅有积分
    --if video.rewards and video.select then
    --    layer:addChild(require("fight.pvp.lucky").create(video.rewards, video.select), 10)
    --end
    
    -- 判断是不是最后一场战斗，如果是弹出总结算界面
    --if video.wins and #video.wins <= video.idx then
    --    layer:addChild((require"fight.pvp3.final").create(video), 1000)
    --end

    return layer
end

return ui
