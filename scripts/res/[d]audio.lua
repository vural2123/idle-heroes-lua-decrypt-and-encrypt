-- manage music here
-- eg: audio.play(audio.button)

local audio = {}

require "common.const"
require "common.func"
local userdata = require "data.userdata"

-- 音乐文件存放的地方
local baseDir = "music/"

-- 音乐文件扩展名
local ext = ".mp3"

-- 所有音乐文件
audio.arena_bg = "arena_bg" -- 竞技场背景音乐
audio.fight_bg = { "fight_bg1", "fight_bg2" } -- 其他战斗背景音乐
audio.ui_bg = "ui_bg" -- ui界面的背景音乐
audio.bag_sell_things = "ui/bag_sell_things" -- 背包卖东西时的声音
audio.button = "ui/button" -- 普通按钮的声音（特殊按钮有自己的声音）
audio.casino_1 = "ui/casino_1" -- 赌场单抽
audio.casino_10 = "ui/casino_10" -- 赌场10连
audio.casino_get_common = "ui/casino_get_common" -- 赌场获得一般物品
audio.casino_get_nb = "ui/casino_get_nb" -- 赌场获得牛逼物品
audio.click_exp = "ui/click_exp" -- 挂击点击获取经验
audio.devour = "ui/devour" -- 吞噬
audio.equip_forge = "ui/equip_forge" -- 合成装备
audio.fight_lose = "ui/fight_lose" -- 战斗失败
audio.fight_start_button = "ui/fight_start_button" -- 战斗开始按钮
audio.fight_win = "ui/fight_win" -- 战斗胜利
audio.hero_advance = "ui/hero_advance" -- 英雄进阶
audio.hero_equip_off = "ui/hero_equip_off" -- 脱下装备
audio.hero_equip_on = "ui/hero_equip_on" -- 穿上装备
audio.hero_lv_up = "ui/hero_lv_up" -- 英雄等级升级
audio.midas = "ui/midas" -- 点金手
audio.orange_merge = "ui/orange_merge" -- 橙卡合成音效
audio.player_lv_up = "ui/player_lv_up" -- 玩家等级升级
audio.summon = "ui/summon" -- 召唤时的音效
audio.summon_get_common = "ui/summon_get_common" -- 召唤获得普通时的音效
audio.summon_get_nb = "ui/summon_get_nb" -- 召唤获得牛逼时的音效
audio.town_entry_arena = "ui/town_entry_arena" -- 点击主城竞技场
audio.town_entry_blackmarket = "ui/town_entry_blackmarket" -- 点击主城黑市
audio.town_entry_casino = "ui/town_entry_casino" -- 点击主城赌场
audio.town_entry_devour = "ui/town_entry_devour" -- 点击主城吞噬祭坛
audio.town_entry_smith = "ui/town_entry_smith" -- 点击主城铁匠铺
audio.town_entry_summon = "ui/town_entry_summon" -- 点击主城召唤法阵
audio.town_entry_tavern = "ui/town_entry_tavern" -- 点击主城酒馆
audio.town_entry_trial = "ui/town_entry_trial" -- 点击主城试炼入口
audio.town_entry_worldmap = "ui/town_entry_worldmap" -- 世界地图入口
audio.town_entry_heroforge = "ui/town_entry_heroforge" -- 英雄合成入口
audio.town_entry_airship = "ui/town_entry_airship" -- 勇者试炼入口
audio.hero_forge = "ui/hero_forge" -- 英雄合成
audio.trial_chain = "ui/trial_chain" -- 进试炼铁链子声音
audio.get_gold_exp = "ui/get_gold_exp" -- 挂机领取金币和经验
audio.summon_reward = "ui/summon_reward" -- 召唤时飞粒子
audio.get_heart = "ui/get_heart" -- 领取好友爱心
audio.map_unlock = "ui/map_unlock" -- 地图解锁
audio.smith_forge = "ui/smith_forge" -- 装备合成
audio.guild_skill_upgrade = "ui/guild_skill_upgrade" -- 公会技能升级
audio.battle_card_reward = "ui/battle_card_reward" -- pvp战斗结算抽奖
audio.fire_1 = "ui/fire_1"
audio.fire_10 = "ui/fire_10"  -- 年兽活动

-- 音乐引擎
local engine = SimpleAudioEngine:sharedEngine()

-- 背景音乐是否生效
local backgroundEnabled = userdata.getBool(userdata.keys.musicBG, true)
function audio.isBackgroundMusicEnabled()
    return backgroundEnabled
end

-- 设置背景音乐是否生效
function audio.setBackgroundMusicEnabled(b)
    if backgroundEnabled ~= b then
        backgroundEnabled = b
        userdata.setBool(userdata.keys.musicBG, backgroundEnabled)
        if backgroundEnabled and not audio.isBackgroundMusicPlaying() then
            audio.playBackgroundMusic(audio.ui_bg)
        elseif not backgroundEnabled and audio.isBackgroundMusicPlaying() then
            audio.stopBackgroundMusic()
        end
    end
end

-- 音效是否生效
local effectEnabled = userdata.getBool(userdata.keys.musicFX, true)
function audio.isEffectEnabled()
    return effectEnabled
end

-- 设置音效是否生效
function audio.setEffectEnabled(b)
    if effectEnabled ~= b then
        effectEnabled = b
        userdata.setBool(userdata.keys.musicFX, effectEnabled)
    end
end

-- 播放一个音效
function audio.play(name)
    if effectEnabled then
        local fullname = baseDir .. name .. ext
        engine:playEffect(fullname)
    end
end

-- 播放普攻音效, name为hero表或monster表中的配置项atkSound
function audio.playAttack(name)
    if effectEnabled then
        local fullname = baseDir .. "ui/" .. name .. ext
        engine:playEffect(fullname)
    end
end

-- 播放技能音效, name为hero表或monster表中的配置项sound
function audio.playSkill(name)
    if effectEnabled then
        local fullname = baseDir .. "skill/" .. name .. ext
        engine:playEffect(fullname)
    end
end

-- 播放英雄talk
function audio.playHeroTalk(name)
    if effectEnabled then
        local lggStr = "us/"
        local lgg = (require"res.i18n").getLanguageShortName()
        if lgg == "cn" or lgg == "tw" then
            lggStr = "cn/"
        end
        local fullname = baseDir .. "hero/" .. lggStr .. name
        --audio.pauseBackgroundMusic()
        audio.stopAllEffects()
        engine:playEffect(fullname)
        --audio.resumeBackgroundMusic()
    end
end

-- 播放背景音乐
function audio.playBackgroundMusic(name)
    if backgroundEnabled then
        if audio.isBackgroundMusicPlaying() then
            audio.stopBackgroundMusic()
        end
        local fullname = baseDir .. name .. ext
        engine:playBackgroundMusic(fullname, true)
    end
end

-- 停止所有音效
function audio.stopAllEffects()
    if effectEnabled then
        engine:stopAllEffects()
    end
end

-- 停止背景音乐
function audio.stopBackgroundMusic()
    engine:stopBackgroundMusic()
end

-- 暂停背景音乐
function audio.pauseBackgroundMusic()
    if not backgroundEnabled then return end
    if audio.isBackgroundMusicPlaying() then
        engine:pauseBackgroundMusic()
    end
end

-- 继续背景音乐
function audio.resumeBackgroundMusic()
    if not backgroundEnabled then return end
    engine:resumeBackgroundMusic()
end

-- 背景音乐在播放吗
function audio.isBackgroundMusicPlaying()
    return engine:isBackgroundMusicPlaying()
end

return audio
