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
local bagdata = require "data.bag"
local taskdata = require "data.task"
local tipsequip = require "ui.tips.equip"
local tipsitem = require "ui.tips.item"
local rewards = require "ui.reward"

local gotoFunc = {
    [taskdata.TaskType.MIDAS] = function(layer)
        local parentObj = layer:getParent()
        layer:removeFromParentAndCleanup(true)
        parentObj:addChild((require"ui.midas.main").create({from_layer="task"}), 1000)
    end,
    [taskdata.TaskType.FRIEND_HEART] = function(layer)
        local parentObj = layer:getParent()
        layer:removeFromParentAndCleanup(true)
        parentObj:addChild((require"ui.friends.main").create({from_layer="task"}), 1000)
    end,
    [taskdata.TaskType.CASINO] = function(layer)
        local params = {
            sid = player.sid,
            type = 1,
        }
        addWaitNet()
        local casinodata = require"data.casino"
        casinodata.pull(params, function(__data)
            delWaitNet()
            tbl2string(__data)
            if __data.status ~= 0 then
                showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                return
            end
            casinodata.init(__data)
            replaceScene((require"ui.casino.main").create({from_layer="task"}))
        end)
    end,
    [taskdata.TaskType.HERO_TASK] = function(layer)
        replaceScene((require"ui.herotask.main").create({from_layer="task"}))
    end,
    [taskdata.TaskType.FORGE] = function(layer)
        replaceScene((require"ui.smith.main").create({from_layer="task"}))
    end,
    [taskdata.TaskType.BASIC_SUMMON] = function(layer)
        replaceScene((require"ui.summon.main").create({from_layer="task"}))
    end,
    [taskdata.TaskType.SENIOR_SUMMON] = function(layer)
        replaceScene((require"ui.summon.main").create({from_layer="task"}))
    end,
    [taskdata.TaskType.ARENA] = function(layer)
        local params = {
            sid = player.sid        
        }
        addWaitNet()
        netClient:pvp_sync(params, function(__data)
            delWaitNet()
            tbl2string(__data)
            if __data.infos[1].status == -1 then
                layer:addChild(require("ui.selecthero.main").create({ type = "ArenaDef" }), 1000)  
                layer:addChild(require("ui.selecthero.info").create(), 10000)
            elseif __data.infos[1].status == -2 then
                showToast(i18n.global.event_processing.string)
            else
                local arenaData = require "data.arena"
                arenaData.initTime(__data.infos[1])
                local param = {
                    sid = player.sid        
                }
                addWaitNet()
                netClient:joinpvp_sync(params, function(_data)
                    delWaitNet()
                    tbl2string(_data)
                    arenaData.init(_data)
                    replaceScene(require("ui.arena.main").create({from_layer="task"}))
                end)
            end
        end)
    end,
    [taskdata.TaskType.HOOK_GET] = function(layer)
        replaceScene((require"ui.hook.map").create({from_layer="task"}))
    end,
    --[taskdata.TaskType.GUILD_SIGN] = function(layer)
    --    -- check has guild
    --    local gdata = require "data.guild"
    --    if player.gid and player.gid > 0 and not gdata.IsInit() then
    --        print("guild id:" .. player.gid)
    --        local gparams = {
    --            sid = player.sid,
    --        }
    --        addWaitNet()
    --        netClient:guild_sync(gparams, function(__data)
    --            delWaitNet()
    --            tbl2string(__data)
    --            if __data .status ~= 0 then
    --                showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
    --                return
    --            end
    --            gdata.init(__data)
    --            replaceScene((require"ui.guild.main").create({from_layer="task"}))
    --        end)
    --    elseif player.gid and player.gid > 0 and gdata.IsInit() then
    --        replaceScene((require"ui.guild.main").create({from_layer="task"}))
    --    else
    --        layer:addChild((require"ui.guild.recommend").create(1, true), 1000)
    --    end
    --end,
    [taskdata.TaskType.CHALLENGE] = function(layer)
        local daredata = require "data.dare"
        local nParams = {
            sid = player.sid,
        }
        addWaitNet()
        netClient:dare_sync(nParams, function(__data)
            delWaitNet()
            tbl2string(__data)
            daredata.sync(__data)
            if layer and not tolua.isnull(layer) then
                local parentObj = layer:getParent()
                layer:removeFromParentAndCleanup(true)
                parentObj:addChild((require"ui.dare.main").create({_anim=true}), 1000)
            end
        end)
    end,
}

function ui.create(_anim)
    local layer = CCLayer:create()
    -- dark bg
    local darkbg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    layer:addChild(darkbg)
    -- board
    local board= img.createUI9Sprite(img.ui.dialog_1)
    board:setPreferredSize(CCSizeMake(736, 502))
    board:setScale(view.minScale)
    board:setPosition(view.midX-5*view.minScale, view.midY)
    layer:addChild(board)
    layer.board = board
    local board_w = board:getContentSize().width
    local board_h = board:getContentSize().height

    -- bar
    local bar_l = img.createUISprite(img.ui.task_top)
    bar_l:setAnchorPoint(CCPoint(1, 1))
    bar_l:setPosition(CCPoint(368, board_h+5))
    board:addChild(bar_l)
    local bar_r = img.createUISprite(img.ui.task_top)
    bar_r:setFlipX(true)
    bar_r:setAnchorPoint(CCPoint(0, 1))
    bar_r:setPosition(CCPoint(367, board_h+5))
    board:addChild(bar_r)

    -- title
    local lbl_title = lbl.createFont1(24, i18n.global.task_board_title.string, ccc3(0xfa, 0xd8, 0x69))
    lbl_title:setPosition(CCPoint(board_w/2, board_h-29))
    board:addChild(lbl_title, 2)

    local function backEvent()
        audio.play(audio.button)
        layer:removeFromParentAndCleanup(true)
    end
    -- btn_close
    local btn_close0 = img.createUISprite(img.ui.close)
    local btn_close = SpineMenuItem:create(json.ui.button, btn_close0)
    btn_close:setPosition(CCPoint(board_w-25, board_h-28))
    local btn_close_menu = CCMenu:createWithItem(btn_close)
    btn_close_menu:setPosition(CCPoint(0, 0))
    board:addChild(btn_close_menu, 100)
    layer.btn_close = btn_close
    btn_close:registerScriptTapHandler(function()
        backEvent()
    end)

    local lbl_cd_des = lbl.createFont1(16, i18n.global.task_refresh.string, ccc3(0x7d, 0x58, 0x46))
    lbl_cd_des:setAnchorPoint(CCPoint(1, 0))
    lbl_cd_des:setPosition(CCPoint(board_w/2-2, 414))
    board:addChild(lbl_cd_des)
    local lbl_cd = lbl.createFont2(16, "00:00:00", ccc3(0xc3, 0xff, 0x42))
    lbl_cd:setAnchorPoint(CCPoint(0, 0))
    lbl_cd:setPosition(CCPoint(board_w/2+2, 414))
    board:addChild(lbl_cd)

    local function createItem(itemObj, isAll)
        local item = img.createUI9Sprite(img.ui.botton_fram_2)
        item:setPreferredSize(CCSizeMake(662, 88))
        local item_w = item:getContentSize().width
        local item_h = item:getContentSize().height
        if isAll then
            local all_bg = img.createUI9Sprite(img.ui.task_all_bg)
            all_bg:setPreferredSize(CCSizeMake(662, 88))
            all_bg:setAnchorPoint(CCPoint(0.5, 0.5))
            all_bg:setPosition(CCPoint(item_w/2, item_h/2))
            item:addChild(all_bg)
        end
        -- pgb
        local pgb_bg = img.createUI9Sprite(img.ui.playerInfo_process_bar_bg)
        pgb_bg:setPreferredSize(CCSizeMake(333, 22))
        pgb_bg:setPosition(CCPoint(190, 30))
        item:addChild(pgb_bg)
        local pgb_fg = img.createUISprite(img.ui.task_pgb_fg)
        local pgb = createProgressBar(pgb_fg)
        pgb:setPosition(CCPoint(pgb_bg:getContentSize().width/2, pgb_bg:getContentSize().height/2))
        pgb_bg:addChild(pgb)
        pgb:setPercentage(itemObj.count*100/itemObj.total)
        local lbl_percent = lbl.createFont2(16, itemObj.count .. "/" .. itemObj.total, ccc3(0xf8, 0xf2, 0xe2))
        lbl_percent:setPosition(CCPoint(pgb_bg:getContentSize().width/2, pgb_bg:getContentSize().height))
        pgb_bg:addChild(lbl_percent)
        -- task des
        local lbl_task_des = lbl.createMixFont1(14, i18n.dailytask[itemObj.id].taskDes, ccc3(0x7d, 0x58, 0x46))
        lbl_task_des:setAnchorPoint(CCPoint(0, 0.5))
        lbl_task_des:setPosition(CCPoint(22, 60))
        item:addChild(lbl_task_des)
        -- reward
        local reward_num = itemObj.reward[1].num
        if itemObj.lv and itemObj.lv == 1 then
            reward_num = reward_num+(player.lv()-1)*500
        elseif itemObj.lv and itemObj.lv == 2 then
            reward_num = reward_num+(player.lv()-1)*300
        end
        if itemObj.reward[1].type == 1 then
            local reward0 = img.createItem(itemObj.reward[1].id, reward_num) 
            local reward = CCMenuItemSprite:create(reward0, nil)
            reward:setScale(0.6)
            reward:setPosition(CCPoint(443, item_h/2))
            local reward_menu = CCMenu:createWithItem(reward)
            reward_menu:setPosition(CCPoint(0, 0))
            item:addChild(reward_menu)
            reward:registerScriptTapHandler(function()
                audio.play(audio.button)
                tmp_tip = tipsitem.createForShow({id=itemObj.reward[1].id})
                layer:addChild(tmp_tip, 100)
            end)
        elseif itemObj.reward[1].type == 2 then
            local reward0 = img.createEquip(itemObj.reward[1].id, reward_num)
            local reward = CCMenuItemSprite:create(reward0, nil)
            reward:setScale(0.6)
            reward:setPosition(CCPoint(443, item_h/2))
            local reward_menu = CCMenu:createWithItem(reward)
            reward_menu:setPosition(CCPoint(0, 0))
            item:addChild(reward_menu)
            reward:registerScriptTapHandler(function()
                audio.play(audio.button)
                tmp_tip = tipsequip.createById(itemObj.reward[1].id)
                layer:addChild(tmp_tip, 100)
            end)
        end
        -- button
        local button
        local button_str
        if itemObj.is_claim == 1 then
            local button0 = img.createLogin9Sprite(img.login.button_9_small_gold)
            button0:setPreferredSize(CCSizeMake(118, 45))
            button_str = i18n.global.task_btn_claim.string
            lbl_btn = lbl.createFont1(18, button_str, ccc3(0x82, 0x47, 0x23))
            lbl_btn:setPosition(CCPoint(button0:getContentSize().width/2, button0:getContentSize().height/2))
            button0:addChild(lbl_btn)
            setShader(button0, SHADER_GRAY, true)
            button0:setPosition(CCPoint(581, item_h/2))
            item:addChild(button0)
        elseif itemObj.count >= itemObj.total then
            local button0 = img.createLogin9Sprite(img.login.button_9_small_gold)
            button0:setPreferredSize(CCSizeMake(118, 45))
            button_str = i18n.global.task_btn_claim.string
            lbl_btn = lbl.createFont1(18, button_str, ccc3(0x82, 0x47, 0x23))
            lbl_btn:setPosition(CCPoint(button0:getContentSize().width/2, button0:getContentSize().height/2))
            button0:addChild(lbl_btn)
            button = SpineMenuItem:create(json.ui.button, button0)
            button:setPosition(CCPoint(581, item_h/2))
            local button_menu = CCMenu:createWithItem(button)
            button_menu:setPosition(CCPoint(0, 0))
            item:addChild(button_menu)
            button:registerScriptTapHandler(function()
                audio.play(audio.button)
                disableObjAWhile(button)
                local params = {
                    sid = player.sid,
                    id = itemObj.id,
                }
                addWaitNet()
                taskdata.claim(params, function(__data)
                    tbl2string(__data)
                    delWaitNet()
                    if __data.status ~= 0 then
                        showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                        return
                    end
                    if button and not tolua.isnull(button) then
                        button:setEnabled(false)
                    end
                    itemObj.is_claim = 1
                    local tmp_reward = itemObj.reward
                    tmp_reward[1].num = reward_num
                    local tmp_bag = reward2Pbbag(tmp_reward)
                    bagdata.addRewards(tmp_bag)
                    CCDirector:sharedDirector():getRunningScene():addChild(rewards.createFloating(tmp_bag), 100000)
                    if layer and not tolua.isnull(layer) then
                        schedule(layer, 0.5, function()
                            --replaceScene(require("ui.town.main").create({from_layer="task"}))  
                            local parentObj = layer:getParent()
                            layer:removeFromParentAndCleanup(true)
                            parentObj:addChild(require("ui.task.main").create(), 1000)
                        end)
                    end
                end)
            end)
        elseif isAll then
            local button0 = img.createLogin9Sprite(img.login.button_9_small_gold)
            button0:setPreferredSize(CCSizeMake(118, 45))
            button_str = i18n.global.task_btn_claim.string
            lbl_btn = lbl.createFont1(18, button_str, ccc3(0x82, 0x47, 0x23))
            lbl_btn:setPosition(CCPoint(button0:getContentSize().width/2, button0:getContentSize().height/2))
            button0:addChild(lbl_btn)
            setShader(button0, SHADER_GRAY, true)
            button0:setPosition(CCPoint(581, item_h/2))
            item:addChild(button0)
        else
            local button0 = img.createLogin9Sprite(img.login.button_9_small_green)
            button0:setPreferredSize(CCSizeMake(118, 45))
            button_str = i18n.global.task_btn_goto.string
            lbl_btn = lbl.createFont1(18, button_str, ccc3(0x1d, 0x67, 0x00))
            lbl_btn:setPosition(CCPoint(button0:getContentSize().width/2, button0:getContentSize().height/2))
            button0:addChild(lbl_btn)
            button = SpineMenuItem:create(json.ui.button, button0)
            button:setPosition(CCPoint(581, item_h/2))
            local button_menu = CCMenu:createWithItem(button)
            button_menu:setPosition(CCPoint(0, 0))
            item:addChild(button_menu)
            button:registerScriptTapHandler(function()
                disableObjAWhile(button)
                if gotoFunc[itemObj.id] then
                    audio.play(audio.button)
                    gotoFunc[itemObj.id](layer)
                end
            end)
        end
        return item
    end

    local tasks = taskdata.getTask()

    local inner_bg_h
    if tasks[taskdata.TaskType.ALL] then
        inner_bg_h = 278
        local item_all = createItem(tasks[taskdata.TaskType.ALL], true)
        item_all:setPosition(CCPoint(board_w/2, 365))
        board:addChild(item_all)
    else
        inner_bg_h = 373
    end

    -- inner_board
    local inner_board = img.createUI9Sprite(img.ui.inner_bg)
    inner_board:setPreferredSize(CCSizeMake(684, inner_bg_h))
    inner_board:setAnchorPoint(CCPoint(0.5, 0))
    inner_board:setPosition(CCPoint(board_w/2, 31))
    board:addChild(inner_board)
    layer.inner_board = inner_board
    local inner_board_w = inner_board:getContentSize().width
    local inner_board_h = inner_board:getContentSize().height

    local function createScroll()
        local scroll_params = {
            width = 684,
            height = inner_bg_h,
        }
        local lineScroll = require "ui.lineScroll"
        return lineScroll.create(scroll_params)
    end

    local function showList()
        local show_task = {}
        for _, taskObj in pairs(tasks) do
            show_task[#show_task+1] = taskObj
        end
        table.sort(show_task, taskdata.sort)
        local scroll = createScroll()
        scroll:setAnchorPoint(CCPoint(0, 0))
        scroll:setPosition(CCPoint(0, 0))
        inner_board:addChild(scroll)
        scroll.addSpace(12)
        for ii=1,#show_task do
            local taskObj = show_task[ii]
            if taskObj.id ~= taskdata.TaskType.ALL then
                local tmp_item = createItem(taskObj)
                tmp_item.ax = 0.5
                tmp_item.px = 342
                scroll.addItem(tmp_item)
                scroll.addSpace(2)
            end
        end
        scroll.setOffsetBegin()
    end
    showList()

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

    if _anim then
        board:setScale(0.5*view.minScale)
        local anim_arr = CCArray:create()
        anim_arr:addObject(CCScaleTo:create(0.15, 1*view.minScale, 1*view.minScale))
        anim_arr:addObject(CCDelayTime:create(0.15))
        anim_arr:addObject(CCCallFunc:create(function()

        end))
        board:runAction(CCSequence:create(anim_arr))
    end

    local last_update = os.time()
    local function onUpdate(ticks)
        if os.time() - last_update < 1 then return end
        last_update = os.time()
        local remain_cd = taskdata.getCD() - (os.time() - taskdata.pull_time)
        if remain_cd >= 0 then
            local time_str = time2string(remain_cd)
            lbl_cd:setString(time_str)
        else
            taskdata.refresh()
            replaceScene(require("ui.town.main").create({from_layer="task"}))
        end
    end
    layer:scheduleUpdateWithPriorityLua(onUpdate, 0)

    return layer
end

return ui
