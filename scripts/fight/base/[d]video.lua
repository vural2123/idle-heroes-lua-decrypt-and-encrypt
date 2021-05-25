-- 战斗video基础layer，实现了video的播放流程
-- 具体的video界面请重载必须的函数

local ui = {}

require "common.const"
require "common.func"
local view = require "common.view"
local audio = require "res.audio"
local cfghero = require "config.hero"
local cfgbuff = require "config.buff"
local cfgskill = require "config.skill"
local fHelper = require "fight.helper.fx"
local hHelper = require "fight.helper.hero"
local bHelper = require "fight.helper.buff"
local userdata = require "data.userdata"
local fxfix = require "fight.helper.fxfix"
local player = require "data.player"

local TYPE_NORMAL = 1    -- 无暴击
local TYPE_CRIT   = 2    -- 暴击
local TYPE_MISS   = 3    -- miss

local BUFF_ON          = 1   -- 会使得该buff添加到单位上，影响buff图标
local BUFF_OFF         = 2   -- 会使得从单位上清除掉所有该种buff，影响buff图标
local BUFF_WORK        = 3   -- 会使得播放buff特效
local BUFF_ON_WORK     = 0   -- on, work结合

local EP_SELF = 50 -- 出手能量
local EP_HURT = 10 -- 受伤能量
local EP_CRIT = 20 -- 暴击能量

local REVIVE_ID = bHelper.id(BUFF_REVIVE)
local REVIVE_DEAD_ID = 2030
local REVIVE_DEAD_ID2 = 2033
local ENERGY_ID = bHelper.id(BUFF_ENERGY)

local director = CCDirector:sharedDirector()
local function addResumeBtn(scene)
    print("-------------addResumeBtn----------")
    local is_resume = director:getRunningScene():getChildByTag(TAG_RESUME_BTN)
    if is_resume then return end
    local img = require "res.img"
    local json = require "res.json"
    local layer = CCLayer:create()
    -- dark bg
    local darkbg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    layer:addChild(darkbg)

    local textureCache = CCTextureCache:sharedTextureCache()
    local spriteframeCache = CCSpriteFrameCache:sharedSpriteFrameCache()
    local prename = "images/ui_no_compress"
    spriteframeCache:addSpriteFramesWithFile(prename..".plist")

    local btn_resume0 = CCSprite:createWithSpriteFrameName("ui/btn_resume.png")
    local btn_resume = CCMenuItemSprite:create(btn_resume0, nil)
    btn_resume:setScale(view.minScale)
    btn_resume:setPosition(CCPoint(view.midX, view.midY))
    local btn_resume_menu = CCMenu:createWithItem(btn_resume)
    btn_resume_menu:setPosition(CCPoint(0, 0))
    layer:addChild(btn_resume_menu)
    local function backEvent()
        layer:removeFromParentAndCleanup(true)
        resumeSchedulerAndActions(scene)
        require("res.audio").resumeBackgroundMusic()
    end
    btn_resume:registerScriptTapHandler(function()
        backEvent()
    end)
    layer.resumeBtn = true
    layer:setTouchEnabled(true)
    layer:setTouchSwallowEnabled(true)
    addBackEvent(layer)
    function layer.onAndroidBack()
        backEvent()
    end
    layer:setTag(TAG_RESUME_BTN)
    scene:addChild(layer, 10000000000)
end

local function backgroundListener(node)
    --if not node or tolua.isnull(node) then return end
    if require("data.tutorial").exists() then
        --认为有教程进行中
        return
    end
    if APP_CHANNEL and APP_CHANNEL ~= "" then return end
    if device.platform == "android" then -- gp
        require("res.audio").pauseBackgroundMusic()
        pauseSchedulerAndActions(director:getRunningScene())
    end
end

local function foregroundListener(node)
    --if not node or tolua.isnull(node) then return end
    if not package.loaded["res.img"] then return end -- 库未加载
    if require("data.tutorial").exists() then
        --认为有教程进行中
        return
    end
    if APP_CHANNEL and APP_CHANNEL ~= "" then return end
    if device.platform == "android" then -- gp
        require("res.audio").pauseBackgroundMusic()
        addResumeBtn(director:getRunningScene())
    end
end

-- 创建
function ui.create(kind)
    local layer = CCLayer:create()
    fHelper.addBox(layer)
    fHelper.addBackgroundListner(layer, backgroundListener)
    fHelper.addForegroundListner(layer, foregroundListener)
    local function onExit()
        fHelper.removeBackAndForegroundListener(layer)
    end

    layer:registerScriptHandler(function(event)
        if event == "enter" then
            --onEnter()
        elseif event == "exit" then
            onExit()
        end
    end)

    -- 返回video,attackers,defenders，请重写该方法
    function layer.getVideoAndUnits()
        assert(false, "Must override function getVideoAndUnits()")
    end

    -- 开始战斗
    local video, attackers, defenders, units
    function layer.startFight()
        video, attackers, defenders = layer.getVideoAndUnits()
        video = ui.decodeVideo(video)
        fHelper.addCampBuff(layer, attackers, defenders)

        -- 进攻方
        table.sort(attackers, function(a, b)
            return a.pos < b.pos
        end)

        -- 防守方
        table.sort(defenders, function(a, b)
            return a.pos < b.pos
        end)

        -- 所有单位
        units = arraymerge(attackers, defenders)
        for _, unit in ipairs(units) do
            fHelper.addUnit(layer, unit)
        end
        -- pet
        if video.atk and video.atk.pet then
            fHelper.addPet(layer, video.atk.pet, "attacker")
        end
        if video.def and video.def.pet then
            fHelper.addPet(layer, video.def.pet, "defender")
        end

        -- 战斗单位进场
        layer.showAllUnits()
    end

    -- 所有战斗单位进场
    function layer.showAllUnits()
        for i, unit in ipairs(units) do
            local t = fHelper.playUnitComeIn(unit)
            if i == #units then
                schedule(layer, t, function()
                    layer.nextFrame()
                end)
            end
        end
    end

    local function processSpecialEp(frame)
        -- 特殊的能量处理
        for pos, ep in pairs(frame.ep) do
            local unit = layer.findByPos(units, pos)
            if unit then
                unit.ep = ep
                unit.epFg.scalePercentageOnly(unit.ep)
                unit.epFg:setVisible(unit.ep < 100)
                unit.epFull:setVisible(unit.ep >= 100)
            end
        end
    end

    -- 进行video中的下一个frame
    local index = 0
    function layer.nextFrame()
        index = index + 1
        ui.printVideo(video, index, index)
        local frame = video.frames[index]
        layer.onVideoFrame(frame)
        -- 回合间的效果处理
        if frame.pos == 0 or frame.pos == 15 then
            if frame.pos == 0 then fHelper.addPetEpDelta(layer, 20) end
            local anyDead = false
            local anyRevive = layer.anyRevive(frame)
            local tDead, tRevive = 0.3, 0.8
            --if anyRevive then
                --schedule(layer, op3(anyDead, tDead, 0), function()
                --layer.processRevive(frame)
                --end)
            --end
            anyDead = layer.processActionBuffs(frame)
            processSpecialEp(frame)
            local tCheck = op3(anyRevive, op3(anyDead, tDead+tRevive, tRevive), 0)
            -- 等宠物能量条满
            tCheck = tCheck + 0.5
            schedule(layer, tCheck, layer.checkWin)
            return
        end
        -- pet 出场时间
        local tPet = 0
        -- 行动方
        local actor
        if frame.pos == 13 then
            actor = clone(layer.findAnyUnit(units, "attacker"))  -- 无出手特效，以第一个体拷贝代替
            actor.pet = true
            actor.skin = nil
            tPet = fHelper.playPetAppearance(layer, "attacker")
            --tPet = tPet - 0.35
        elseif frame.pos == 14 then
            actor = clone(layer.findAnyUnit(units, "defender"))
            actor.pet = true
            actor.skin = nil
            tPet = fHelper.playPetAppearance(layer, "defender")
            --tPet = tPet - 0.35
        else
            actor = layer.findByPos(units, frame.pos)
        end
        tPet = tPet or 0
        -- 行动目标
        local actees1 = {}
        local actees2 = {}
        for _, pos in ipairs(frame.targets) do
            local actee = layer.findByPos(units, pos)
            actees1[#actees1+1] = actee
        end
        for _, pos in ipairs(frame.targets2) do
            local actee = layer.findByPos(units, pos)
            actees2[#actees2+1] = actee
        end
        -- 行动方能量处理
        if fxfix.isAttack(actor.id, frame.action) and not frame.triggered then
            local miss = true
            for _, b in ipairs(frame.buffs) do
                if b.pos ~= frame.pos and b.hp and b.value and b.value < 0 then
                    miss = false
                    break
                end
            end
            if not miss then
                actor.ep = actor.ep + EP_SELF
            end
        elseif fxfix.isSkill(actor.id, frame.action) and not frame.triggered then
            actor.ep = 0
            actor.epFg.setPercentageOnly(0)
            actor.epFg:setVisible(true)
            actor.epFull:setVisible(false)
        end
        -- 行动特效
        local tActor, tNext, tFxHurt = 0, 0, 0
        schedule(layer, tPet, function()
            tActor, tNext, tFxHurt = fHelper.playActor(layer, actor, frame.action, actees1, actees2)
            tActor = tActor + tPet
            tNext = tNext + tPet
            schedule(layer, tActor, function()
                if frame.pos < 13 then
                    actor.epFg.scalePercentageOnly(actor.ep)
                    actor.epFg:setVisible(actor.ep < 100)
                    actor.epFull:setVisible(actor.ep >= 100)
                    if frame.action == cfghero[actor.heroId].actSkillId then
                        if frame.pos < 7 then
                            fHelper.addPetEpDelta(layer, 10)
                        end
                    end
                elseif frame.pos == 13 then
                    fHelper.updatePetEp(layer, 0)
                end
                -- 特殊的能量处理
                processSpecialEp(frame)
                --for pos, ep in pairs(frame.ep) do
                --    local unit = layer.findByPos(units, pos)
                --    if unit then
                --        unit.ep = ep
                --        unit.epFg.scalePercentageOnly(unit.ep)
                --        unit.epFg:setVisible(unit.ep < 100)
                --        unit.epFull:setVisible(unit.ep >= 100)
                --    end
                --end
                -- 开始结算各个buffs
                layer.processActionBuffs(frame)
                schedule(layer, tNext, layer.checkWin)
            end)
        end)
    end

    -- 播放到proto_pvp_ans中的每一个frame，可按需要重写该方法
    function layer.onVideoFrame(frame)
    end

    -- 处理frame里的buffs
    function layer.processActionBuffs(frame)
        local anyDead = false
        local actor
        if frame.pos == 13 then
            actor = clone(layer.findAnyUnit(units, "attacker"))  -- 无出手特效，以第一个体拷贝代替
            actor.pet = true
            actor.skin = nil
        elseif frame.pos == 14 then
            actor = clone(layer.findAnyUnit(units, "defender"))
            actor.pet = true
            actor.skin = nil
        else
            actor = layer.findByPos(units, frame.pos)
        end
        for _, b in ipairs(frame.buffs) do
            if b.buff ~= REVIVE_ID then
                -- 数据分析
                local result = {}
                result.value = b.value
                if b.buffon == BUFF_ON then
                    result.on = true
                elseif b.buffon == BUFF_OFF then
                    result.off = true
                elseif b.buffon == BUFF_WORK then
                    result.work = true
                elseif b.buffon == BUFF_ON_WORK then
                    result.onwork = true
                end
                if b.type == TYPE_CRIT then
                    result.crit = true
                elseif b.type == TYPE_MISS then
                    result.miss = true
                end
                local actee = layer.findByPos(units, b.pos)
                -- 伤害的阵营相克
                local isDmg = bHelper.isDmgId(b.buff)
                local isDot = bHelper.isDotId(b.buff)
                local isHeal = bHelper.isHealId(b.buff)
                if actor and not actor.pet and isDmg and hHelper.groupRestraint(actor, actee) then
                    result.groupRestraint = true
                end
                -- 击中特效
                if ((isDmg or isHeal) and b.hp and (not b.value or b.value ~= 0)) or result.miss then
                    if frame.action then   -- 有action才有出手动作
                        fHelper.playActee(layer, actor, actee, frame.action, b.buff, result.miss)
                    end
                end
                -- buff加减
                if result.on or result.onwork then
                    bHelper.add(actee, b.buff, result.value)
                elseif result.off then
                    bHelper.del(actee, b.buff, result.value)
                    -- 印记类buff需要播放移除特效
                    if bHelper.isImpressId(b.buff) then
                        local _b_id = bHelper.id(cfgbuff[b.buff].name .. "B")
                        if _b_id then
                            fHelper.playBuffWork(layer, _b_id, actee)
                        end
                    end
                end
                -- buff特效
                if (result.work or result.onwork or isDot) and (not isHeal or not result.value or result.value ~= 0) then
                    fHelper.playBuffWork(layer, b.buff, actee)
                end
                -- 冒数字or miss
                if (b.hp and b.value and b.value ~= 0) or result.miss then
                    fHelper.recordDamageNumber(actee, result)
                end
                -- 血条变化
                if b.hp then
                    actee.hp = b.hp
                    actee.hpFx.scalePercentageOnly(b.hp)
                    if b.value and b.value > 0 then
                        actee.hpFg.scalePercentageOnly(b.hp)
                    else
                        actee.hpFg.setPercentageOnly(b.hp)
                    end
                end
                -- 能量变化
                if isDmg and b.hp and b.value and not result.miss and not frame.ep[b.pos] and frame.pos ~= 15 and frame.pos ~= 0 and not frame.triggered then
                    if result.crit then
                        actee.ep = actee.ep + EP_CRIT
                    else
                        actee.ep = actee.ep + EP_HURT
                    end
                    actee.epFg.scalePercentageOnly(actee.ep)
                    actee.epFg:setVisible(actee.ep < 100)
                    actee.epFull:setVisible(actee.ep >= 100)
                end
                -- 死亡动画
                if b.hp == 0 then
                    anyDead = true
                    bHelper.clear(actee)
                    fHelper.playDead(actee, layer.keepCorpse(b.pos))
                    -- 复活buff，播放死亡特效
                    if layer.keepCorpse(b.pos) then
                        local r_d_id = REVIVE_DEAD_ID
                        if actee and actee.id and (actee.id == 5603 or  actee.id == 65613) then
                            r_d_id = REVIVE_DEAD_ID        -- 暂时一样
                        end
                        local fx, tDead = fHelper.play(layer, r_d_id, actee)
                        actee.revive_fx = fx
                    end
                end
            elseif b.buff == REVIVE_ID and b.buffon == BUFF_WORK then
                local actee = layer.findByPos(units, b.pos)
                bHelper.del(actee, REVIVE_ID)
                fHelper.playRevive(layer, actee)
                actee.hp = b.hp
                actee.ep = 0
                actee.hpFg.setPercentageOnly(b.hp)
                actee.hpFx.setPercentageOnly(b.hp)
                actee.epFg.setPercentageOnly(0)
                actee.epFg:setVisible(true)
                actee.epFull:setVisible(false)
            end
        end
        -- 清除数字记录
        for _, u in ipairs(units) do
            fHelper.playAllDamageNumbers(layer, u)
        end
        -- 刷新buff图标，清除失效的buff特效
        for _, u in ipairs(units) do
            fHelper.refreshBuffIcons(u)
            fHelper.clearBuffOff(u)
        end
        return anyDead
    end

    -- 复活，返回时间
    function layer.processRevive(frame)
        for _, b in ipairs(frame.buffs) do
            if b.buff == REVIVE_ID and b.buffon == BUFF_WORK then
                local actee = layer.findByPos(units, b.pos)
                bHelper.del(actee, REVIVE_ID)
                fHelper.playRevive(layer, actee)
                actee.hp = b.hp
                actee.ep = 0
                actee.hpFg.setPercentageOnly(b.hp)
                actee.hpFx.setPercentageOnly(b.hp)
                actee.epFg.setPercentageOnly(0)
                actee.epFg:setVisible(true)
                actee.epFull:setVisible(false)
            end
        end
    end

    -- 有没有任何能复活的人
    function layer.anyRevive(frame)
        for _, b in ipairs(frame.buffs) do
            if b.buff == REVIVE_ID and (b.buffon == BUFF_WORK or b.buffon == BUFF_ON_WORK) then
                return true
            end
        end
        return false
    end

    -- 死亡后是不是保留尸体
    function layer.keepCorpse(pos)
        if index < #video.frames then
            for idx = index + 1, #video.frames do
                local frame = video.frames[idx]
                if frame.pos == pos and frame.action then
                    -- 死了还能行动的
                    return true
                end
                for _, b in ipairs(frame.buffs) do
                    -- 死了能复活的
                    if pos == b.pos and b.buff == REVIVE_ID 
                        and (b.buffon == BUFF_WORK or b.buffon == BUFF_ON_WORK) then
                        return true
                    end
                end
            end
        end
        return false
    end

    -- 进攻方有人没死且录像播完则为进攻超时
    function layer.isTimeout()
        if index >= #video.frames then
            for _, attacker in ipairs(attackers) do
                if attacker.hp > 0 then
                    return true
                end
            end
        end
        return false
    end

    -- 检查是否已经播完所有frames
    function layer.checkWin(delay)
        delay = delay or 1
        if index >= #video.frames then
            layer.isEnd = true
            if (type(video.win) == "boolean" and video.win)
                or (type(video.win) == "number" and video.win > 0) then
                schedule(layer:getParent(), delay, function()
                    audio.stopBackgroundMusic()
                    pauseSchedulerAndActions(layer)
                    CCDirector:sharedDirector():getScheduler():setTimeScale(1)
                    layer.onWin()
                end)
            else
                schedule(layer:getParent(), delay, function()
                    audio.stopBackgroundMusic()
                    pauseSchedulerAndActions(layer)
                    CCDirector:sharedDirector():getScheduler():setTimeScale(1)
                    layer.onLose(layer.isTimeout())
                end)
            end
        elseif not layer.isTestMode then
            layer.nextFrame()
        end
    end

    -- 录像播完，胜利时的回调，可按需要重写该方法
    function layer.onWin()
        layer:addChild(require("fight." .. kind .. ".win").create(video), 1000)
    end

    -- 录像播完，失败时的回调，可按需要重写该方法
    function layer.onLose(isTimeout)
        layer:addChild(require("fight." .. kind .. ".lose").create(video), 1000)
    end

    -- 判断玩家等级是否满足跳过战斗
    function layer.canSkip()
        if player.vipLv() and player.vipLv() > 3 then
            return true
        elseif kind and string.endwith(kind, "rep") then
            return true
        elseif kind ~= "pve" and kind ~= "brave" then
            if player.lv() < UNLOCK_FIGHT_SKIP_LEVEL then
                return false
            end
        end
        return true
    end

    -- 跳过战斗 直接结算
    function layer.onSkip()
        index = #video.frames
        layer.checkWin(0.1)
    end

    -- 按站位查找单位，可按需要重写该方法
    function layer.findByPos(units, pos)
        for _, u in ipairs(units) do  
            if u.pos == pos then
                return u
            end 
        end 
    end 

    -- 按攻防查找单位，查找进攻方或防守方第一个单元
    function layer.findAnyUnit(units, side)
        for _, u in ipairs(units) do  
            if side == "attacker" and u.pos < 7 then
                return u
            elseif side == "defender" and u.pos > 6 then
                return u
            end 
        end 
    end 

    -- 播背景音乐
    function layer.playBGM(music)
        schedule(layer, function()
            audio.playBackgroundMusic(music)
        end)
    end

    -- test mode
    local testBtn = CCMenuItemFont:create("GO")
    testBtn:setScale(view.minScale)
    testBtn:setPosition(scalep(930, 100))
    testBtn:setVisible(false)
    local testMenu = CCMenu:createWithItem(testBtn)
    testMenu:setPosition(0, 0)
    layer:addChild(testMenu)
    layer.isTestMode = testBtn:isVisible()
    testBtn:registerScriptTapHandler(function()
        layer.nextFrame()
    end)

    CCDirector:sharedDirector():getScheduler():setTimeScale(fHelper.getCurFightSpeed())

    return layer
end

-- 解码video
function ui.decodeVideo(video)
    local v = clone(video)
    local bytesArray = v.frames or {}
    v.frames = {}
    for _, bytes in ipairs(bytesArray) do
        v.frames[#v.frames+1] = ui.decodeVideoFrame({string.byte(bytes, 1, #bytes)})
    end
    ui.processVideoEnergy(v)
    --ui.printVideo(v)
    return v
end

-- 解码video中的frame
function ui.decodeVideoFrame(bytes)
    local frame = { buffs = {}, targets = {}, targets2 = {} }
    -- 第一字节前4位是tid，后4位是pos
    frame.tid = bit.band(0x0f, bit.brshift(bytes[1], 4))
    frame.pos = bit.band(0x0f, bytes[1])
    local i = 2
    -- pos不为0时, 有2个字节表示action, 2个字节表示targets
    if frame.pos ~= 0 and frame.pos ~= 15 then
        frame.action = bytes[2] * 256 + bytes[3]
        if frame.action >= 32768 and frame.pos < 13 then
            frame.action = frame.action - 32768
            frame.triggered = true
        end
        frame.targets, frame.targets2 = ui.decodeVideoTargets(bytes, 4, frame.pos, frame.action)
        i = 6
    end
    -- 后续为buffs数组，1个字节中存4个buff的长度(每2bit表一个长度)，再紧跟4个buff，以此循环
    while i < #bytes do
        local lens = {}
        local map = { 1, 2, 3, 6 } -- 0,1,2,3分别对应长度1,2,3,6个字节
        for _, n in ipairs({ 6, 4, 2, 0 }) do
            lens[#lens+1] = map[bit.band(0x3, bit.brshift(bytes[i], n)) + 1]
        end
        i = i + 1
        for _, len in ipairs(lens) do
            if i + len - 1 <= #bytes then
                frame.buffs[#frame.buffs+1] = ui.decodeVideoBuffs(bytes, i, len)
            end
            i = i + len
        end
    end
    return frame
end

-- 解码video中的targets
function ui.decodeVideoTargets(bytes, i, pos, action)
    local code = bytes[i] * 256 + bytes[i+1]
    local attackers, defenders = {}, {}
    for i = 0, 11 do
        if bit.band(2^i, code) > 0 then
            if i + 1 <= 6 then
                attackers[#attackers+1] = i + 1
            else
                defenders[#defenders+1] = i + 1
            end
        end
    end
    if pos <= 6 or pos == 13 then  -- 13 战宠位置
        return defenders, attackers
    else
        return attackers, defenders
    end
end

--[[local function decodeBigNum(b1, b2, b3)
	local low = b1 + b2 * 256 + bit.band(0xf, b3) * 65536
	local high = bit.brshift(b3, 4)
	return bit.blshift(low, high)
end--]]

local function decodeBigNum(b1, b2, b3)
	local low = b1 + b2 * 256 + bit.band(0xf, b3) * 65536
	local high = bit.brshift(b3, 4)
	while high > 0 do
		low = low * 10
		high = high - 1
	end
	return low
end

-- 解码video中的buffs
function ui.decodeVideoBuffs(bytes, i, len)
    local rt = {}
    if len == 1 then -- 长度为一个字节是闪避的情况
        -- 第一字节前4位是pos，后4位是type
        rt.pos = bit.band(0x0f, bit.brshift(bytes[i], 4))
        rt.type = bit.band(0x0f, bytes[i])
    elseif len == 2 then -- 长度为两个字节是buff类情况
        -- 第一字节前4位是pos，后4位是value
        rt.pos = bit.band(0x0f, bit.brshift(bytes[i], 4))
        local value = bit.band(0x0f, bytes[i])
        if value == 0 then
            -- 第一字节后4位是0，非属性类buff
        elseif value == 1 then
            -- 第一字节后4位是1，正向的属性类buff
            rt.value = 1
        elseif value == 2 then
            -- 第一字节后4位是2，负向的属性类buff
            rt.value = -1
        else 
            assert(false, "Fatal: decodeVideoBuffs invalid value " .. value)
            return
        end
        -- 第二字节前6位是buff，后2位是buffon
        rt.buff = bit.band(0x3f, bit.brshift(bytes[i+1], 2))
        rt.buffon = bit.band(0x03, bytes[i+1])
    elseif len == 3 then -- 长度为三个字节是复活或能量
        -- 第一字节前4位是pos，后4位无用
        rt.pos = bit.band(0x0f, bit.brshift(bytes[i], 4))
        -- 第二个字节是hp或ep
        local value = bytes[i+1]
        -- 第三字节前6位是buff，后2位是buffon
        rt.buff = bit.band(0x3f, bit.brshift(bytes[i+2], 2))
        rt.buffon = bit.band(0x03, bytes[i+2])
        if rt.buff == ENERGY_ID then
            rt.ep = value
        else
            rt.hp = value
        end
    elseif len == 6 then -- 长度为六个字节是伤害或治疗的情况
        -- 第一字节前4位是pos，后4位是type
        rt.pos = bit.band(0x0f, bit.brshift(bytes[i], 4))
        rt.type = bit.band(0x0f, bytes[i])
        -- 第二、三、四字节整体构成value
        --local b_shift = bit.band(0x0f, bit.brshift(bytes[i+3], 4))
        --local b_current = bit.band(0xfffff, bytes[i+1] + bytes[i+2] * 256 + bit.band(0x0f, bytes[i+3])*65536)
        --local value = bit.blshift(b_current, b_shift)
		local value = decodeBigNum(bytes[i + 1], bytes[i + 2], bytes[i + 3])

        -- 第五字节是hp
        rt.hp = bytes[i+4]
        -- 第六字节前6位是buff，后2位是buffon
        rt.buff = bit.band(0x3f, bit.brshift(bytes[i+5], 2))
        rt.buffon = bit.band(0x03, bytes[i+5])
        -- 根据buff类型决定value的正负
        rt.value = value
        local bname = bHelper.name(rt.buff)
        if bHelper.isDmg(bname) or bHelper.isDot(bname) or bname == BUFF_BRIER or bHelper.isImpress(bname) then
            rt.value = -value
        elseif bHelper.isImpressB(bname) then
            rt.value = -value
        end
    else
        assert(false, "Fatal: decodeVideoBuffs invalid len " .. len)
        return
    end
    return rt
end

-- 将video中的能量预处理
function ui.processVideoEnergy(video)
    for _, frame in ipairs(video.frames) do
        frame.ep = {}
        arrayfilter(frame.buffs, function(b)
            if b.buff == ENERGY_ID then
                frame.ep[b.pos] = b.ep
                return false
            end
            return true
        end)
    end
    return video
end

-- 打印proto video的内容
function ui.printVideo(video, from, to)
    from = from or 1
    to = to or #video.frames
    cclog("video = {")
    cclog("    video_id:%s win:%s", tostring(video.video_id), tostring(video.win))
    cclog("    frames = {")
    for i = from, to do
        local frame = video.frames[i]
        if not frame then return end
        cclog("        frames[%d] = {", i)
        cclog("            tid:%s pos:%s action:%s targets:{%s} targets2:{%s} ep:{%s}", 
            tostring(frame.tid), tostring(frame.pos), tostring(frame.action),
            table.concat(frame.targets, ","), table.concat(frame.targets2, ","),
            ui.getVideoEpString(frame))
        cclog("            buffs = {")
        for j, b in ipairs(frame.buffs) do
            cclog("                [%d] = pos:%s type:%s value:%s hp:%s buff:%s buffon:%s",
                j, tostring(b.pos), tostring(b.type), tostring(b.value), 
                tostring(b.hp), tostring(b.buff), tostring(b.buffon))
        end
        cclog("            }")
        cclog("        }")
    end
    cclog("    }")
    cclog("}")
end

-- 拼接ep的字符串
function ui.getVideoEpString(frame)
    local s = {}
    for pos, ep in pairs(frame.ep) do
        s[#s+1] = pos .. ":" .. ep
    end
    return table.concat(s, ", ")
end

return ui
