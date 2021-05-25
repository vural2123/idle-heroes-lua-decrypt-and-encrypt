local hook = {}

local scheduler = require("framework.scheduler")
local i18n = require "res.i18n"
local cfgstage = require "config.stage"
local cfgfort = require "config.fort"
local cfghooklock = require "config.hooklock"
local cfgvip = require "config.vip"
local player = require "data.player"
local herodata = require "data.heros"
local NetClient = require "net.netClient"
local netClient = NetClient:getInstance()

hook.OUTPUT_INTERVAL = 5

function hook.getHookStage()
    return hook.hook_stage or 0
end

function hook.getFortIdByStageId(_id)
    if _id <= 0 then
        _id = 1 
    end
    return cfgstage[_id].fortId
end

function hook.lastStage()
    return #cfgstage
end

function hook.getStageLv(_stage_id)
    return cfgstage[_stage_id].lv
end

function hook.getFortName(_stage_id)
    _stage_id = _stage_id or hook.getHookStage()
    return i18n.fort[hook.getFortIdByStageId(_stage_id)].fortName
end

function hook.getStageBossCD()
    return cfgstage[hook.hook_stage].battleTime
end

function hook.getFortByStageId(_id)
    if not _id or _id <= 0 then
        _id = 1 
    end
    return cfgfort[cfgstage[_id].fortId]
end

function hook.getPveStageId()
    return hook.pve_stage or 1
end

function hook.getBossCD()
    return hook.boss_cd
end

function hook.getIDS()
    return hook.ids or {}
end

function hook.getSubRate()
    local shop = require"data.shop"
    if not shop or not shop.pay or not shop.pay[33] then
        return 0
    end
    if shop.pay[33] > 0 then
        return 1
    end
    return 0
end

-- every 5 sec
function hook.output()
    local subRate = hook.getSubRate()
    hook.coins = (hook.coins or 0) + math.floor(cfgstage[hook.hook_stage].gold*(1+cfgvip[player.vipLv()].hook+subRate))
    hook.pxps = (hook.pxps or 0) + math.floor(cfgstage[hook.hook_stage].expP*(1+cfgvip[player.vipLv()].hook))
    hook.hxps = (hook.hxps or 0) + math.floor(cfgstage[hook.hook_stage].expH*(1+cfgvip[player.vipLv()].hook))
end

function hook.startOutput()
    hook.tickScheduler = scheduler.scheduleGlobal(hook.output, hook.OUTPUT_INTERVAL)
end

function hook.resetOutput()
    hook.coins = 0
    hook.pxps = 0
    hook.hxps = 0
end

function hook.init(data)
    if hook.tickScheduler then
        scheduler.unscheduleGlobal(hook.tickScheduler)
        hook.tickScheduler = nil
    end
    if not data or data.status ~= 0 then
        hook.status = -1
        hook.hook_stage = 0
        hook.pve_stage = 1
        hook.hids = {}
        hook.ids = {}
        hook.resetOutput()
        print("hook not init")
        return 
    end
    hook.init_time = os.time()
    hook.status = data.status
    hook.hook_stage = data.hook_stage
    hook.pve_stage = data.pve_stage
    hook.boss_cd = data.boss_cd
    hook.poker_cd = data.poker_cd
    if not hook.status or hook.status ~= 0 then
        return
    end
    hook.hids = {}
    if data.hids and #data.hids>0 then
        for ii=1,#data.hids do
            hook.hids[ii] = data.hids[ii]
        end
    end
    hook.ids = {}
    if data.ids and #data.ids>0 then
        for ii=1,#data.ids do
            hook.ids[ii] = data.ids[ii]
        end
    end
    hook.reward = clone(data.reward)
    --hook.coins = 0
    --hook.pxps = 0
    --hook.hxps = 0
    --if hook.reward and hook.reward.items then
    --    local tmp_items = hook.reward.items
    --    for ii=1,#tmp_items do
    --        if tmp_items[ii].id == ITEM_ID_COIN then
    --            hook.coins = tmp_items[ii].num
    --        elseif tmp_items[ii].id == ITEM_ID_PLAYER_EXP then
    --            hook.pxps = tmp_items[ii].num
    --        elseif tmp_items[ii].id == ITEM_ID_HERO_EXP then
    --            hook.hxps = tmp_items[ii].num
    --        end
    --    end
    --end
    hook.coins, hook.pxps, hook.hxps = coinAndExp(hook.reward, true)
    hook.startOutput()
end

function hook.pveWin()
    local tmp_stage
    local tmp_pve_stage_id = hook.getPveStageId()
    if tmp_pve_stage_id > hook.lastStage() then
        tmp_stage = cfgstage[#cfgstage].next
    else
        tmp_stage = cfgstage[tmp_pve_stage_id].next
    end
    local achieveData = require "data.achieve"
    local fort = 0
    if tmp_stage > #cfgstage then
        fort = cfgstage[#cfgstage].fortId
    else
        fort = cfgstage[tmp_stage].fortId - 1
    end
    achieveData.set(ACHIEVE_TYPE_PASS_FORT, fort)

    local limitData = require "data.activitylimit"
    limitData.LevelNotice(tmp_pve_stage_id)
    
    --if tmp_stage > #cfgstage then
    --    tmp_stage = #cfgstage
    --end
    hook.pve_stage = tmp_stage
    hook.fort_hint_flag = true
    --hook.boss_cd = cfgstage[hook.getPveStageId()].battleTime + os.time() - hook.init_time
end

function hook.set_reward(_reward)
    hook.reward = clone(_reward)
end

function hook.stage_power(_stage_id)
    return cfgstage[_stage_id].power
end

function hook.getAllPower(_hids)
    local tmp_hids = _hids or hook.hids
    if not tmp_hids or #tmp_hids == 0 then return 0 end
    local power = 0
    for ii=1,#tmp_hids do
        local h = herodata.find(tmp_hids[ii])
        if h then
            power = power + herodata.power(tmp_hids[ii])
        end
    end
    return power
end

function hook.getMaxHookStage()
    local _pve = hook.getPveStageId()
    if _pve > hook.lastStage() then
        return hook.lastStage()
    end
    if hook.getAllPower() > hook.stage_power(_pve) and cfgstage[_pve] and cfgstage[_pve].lv <= player.lv() then
        return _pve
    else
        return _pve - 1
    end
    return 1
end

function hook.getFortStageByStageId(_stage_id)
    local tmp_fort = hook.getFortIdByStageId(_stage_id)
    local fortInfo = hook.getFortByStageId(_stage_id)
    local tmp_stage = _stage_id - fortInfo.stageId[1] + 1
    return tmp_fort, tmp_stage
end

function hook.hook_init(params, callback)
    netClient:hook_init(params, callback)
end

function hook.hook_heroes(params, callback)
    netClient:hook_heroes(params, callback)
end

function hook.hook_reward(params, callback)
    netClient:hook_reward(params, callback)
end

function hook.hook_ask(params, callback)
    netClient:hook_ask(params, callback)
end

function hook.change(params, callback)
    netClient:hook_change(params, callback)
end

function hook.getMaxHeroes()
    return cfghooklock[player.lv()].unlock
end

function hook.checkTeamChange()
    if not hook.hids then return false end
    for ii=1,#hook.hids do
        if not herodata.find(hook.hids[ii]) then
            return true
        end
    end
    return false
end

return hook
