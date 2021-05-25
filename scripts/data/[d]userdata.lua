-- user local data

local userdata = {}

userdata.keys = {
    account = "aaAccount",
    accountFormal = "aaAccountFormal",
    password = "aaToken",
    version   = "aaVersion",
    language = "aaLanguage",
    musicBG = "aaMusicBG",
    musicFX = "aaMusicFX",
    gateServer = "aaGateServer",
    fightSpeed = "aaFightSpeed",
    notice = "aaNotice",
    txwhich = "txwhich",
    userid = "userid",
    arena_skip = "arena_skip",
    agree_user_protocol = "agree_user_protocol",
}

userdata.squadkeys = {
    normal_team         = "normal_team",
    trial_team          = "trial_team",
    arenaatk_team       = "arenaatk_team",
    arenadef_team       = "arenadef_team",
    frdarena_team       = "frdarena_team",
    guildboss_team      = "guildboss_team",
    guildgray_team      = "guildgray_team",
    dailyfight_team     = "dailyfight_team",
    airisland_team      = "airisland_team",
    friend_team         = "friend_team",
    arena3v3_team       = "arena3v3_team",
    arena3v3atk_team    = "arena3v3atk_team",
    guildmill_team      = "guildmill_team",
    guildmillatk_team   = "guildmillatk_team",
    guild_fight_team    = "guild_fight_team",
    frd_pk_team         = "frd_pk_team",
    brave_team          = "brave_team",
    broken_boss_team    = "broken_boss_team",
    sweepb_boss_team    = "sweepb_boss_team",
    sweepair_boss_team  = "sweepair_boss_team",
    sweepair_common_team  = "sweepair_common_team",
    sweepf_boss_team    = "sweepf_boss_team",
	frdarenac_team		= "frdarenac_team",
	arenabatk_team       = "arenabatk_team",
    arenabdef_team       = "arenabdef_team",
}

local CRYPTO_KEY = "da3o29lanxd"

local u = CCUserDefault:sharedUserDefault()

function userdata.getString(k, default) 
    default = default or ""
    return u:getStringForKey(k, default)
end

function userdata.setString(k, v)
    u:setStringForKey(k, v)
    u:flush()
end

function userdata.getEncryptString(k)
    return crypto.decryptXXTEA(crypto.decodeBase64(userdata.getString(k)), CRYPTO_KEY) or ""
end

function userdata.setEncryptString(k, v)
    userdata.setString(k, crypto.encodeBase64(crypto.encryptXXTEA(v, CRYPTO_KEY)))
end

function userdata.getBool(k, default)
    local s = userdata.getString(k)
    if s == "1" then
        return true
    elseif s == "0" then
        return false
    else
        return default or false
    end
end

function userdata.setBool(k, v)
    if v then
        userdata.setString(k, "1")
    else
        userdata.setString(k, "0")
    end
end

function userdata.getInt(k, default)
    return tonumber(userdata.getString(k), 10) or default or 0
end

function userdata.setInt(k, v)
    userdata.setString(k, tostring(v))
end

function userdata.setSquad(key, hids, num)
    local num = num or 6

    --如果是普通状态，第七位判断有无，兼容宠物-1
    if num == 6 then
        if not hids[7] then
            hids[7] = -1
        end
    end

    --如果是3V3状态，第19位到21位，兼容宠物-1
    if num == 18 then
        for i=19, 21 do
            if not hids[i] then
                hids[i] = -1
            end
        end   
    end

    --非宠物正常位
    for i=1, num do
        if not hids[i] then
            hids[i] = 0
        end
    end

    local str = table.concat(hids, ",")
    userdata.setString(key, str)
end

function userdata.getSquad(key)
    local hids = {}
    local str = userdata.getString(key)
    local h = string.split(str, ",")
    for i, v in ipairs(h) do
        hids[#hids + 1] = tonumber(v) or 0
    end

    --还原所有的值为0，修复部分线上玩家错误的老数据
    for k,v in pairs(hids) do
        if hids[k] == -1 then
            hids[k] = 0
        end 
    end

    --兼容普通模式的战宠
    if #hids <= 7 then
        if hids[7] == 0 then
            hids[7] = -1
        end
    else
    --兼容3v3模式的战宠
        for i=19,21 do
            if hids[i] == 0 then
                hids[i] = -1
            end
        end
    end

    return hids
end

function userdata.setSquadNormal(hids)
    userdata.setSquad(userdata.squadkeys.normal_team, hids)
end

function userdata.getSquadNormal()
    local hids = userdata.getSquad(userdata.squadkeys.normal_team)
    return hids
end

function userdata.setSquadGuildBoss(hids)
    userdata.setSquad(userdata.squadkeys.guildboss_team, hids)
end

function userdata.getSquadGuildBoss()
    local hids = userdata.getSquad(userdata.squadkeys.guildboss_team)
    return hids
end

function userdata.setSquadGuildGray(hids)
    userdata.setSquad(userdata.squadkeys.guildgray_team, hids)
end

function userdata.getSquadGuildGray()
    local hids = userdata.getSquad(userdata.squadkeys.guildgray_team)
    return hids
end

function userdata.setSquadTrial(hids)
    userdata.setSquad(userdata.squadkeys.trial_team, hids)
end

function userdata.getSquadTrial()
    local hids = userdata.getSquad(userdata.squadkeys.trial_team)
    return hids
end

function userdata.setSquadArenaatk(hids)
    userdata.setSquad(userdata.squadkeys.arenaatk_team, hids)
end

function userdata.getSquadArenaatk()
    local hids = userdata.getSquad(userdata.squadkeys.arenaatk_team)
    return hids
end

function userdata.setSquadArenabatk(hids)
    userdata.setSquad(userdata.squadkeys.arenabatk_team, hids)
end

function userdata.getSquadArenabatk()
    local hids = userdata.getSquad(userdata.squadkeys.arenabatk_team)
    return hids
end

function userdata.setSquadFrdpk(hids)
    userdata.setSquad(userdata.squadkeys.frd_pk_team, hids)
end

function userdata.getSquadFrdpk()
    local hids = userdata.getSquad(userdata.squadkeys.frd_pk_team)
    return hids
end

function userdata.setSquadBrave(hids)
    userdata.setSquad(userdata.squadkeys.brave_team, hids)
end

function userdata.getSquadBrave()
    local hids = userdata.getSquad(userdata.squadkeys.brave_team)
    return hids
end

function userdata.setSquadArenadef(hids)
    userdata.setSquad(userdata.squadkeys.arenadef_team, hids)
end

function userdata.getSquadArenadef()
    local hids = userdata.getSquad(userdata.squadkeys.arenadef_team)
    return hids
end

function userdata.setSquadArenabdef(hids)
    userdata.setSquad(userdata.squadkeys.arenabdef_team, hids)
end

function userdata.getSquadArenabdef()
    local hids = userdata.getSquad(userdata.squadkeys.arenabdef_team)
    return hids
end

function userdata.setSquadFrdArena(hids)
    userdata.setSquad(userdata.squadkeys.frdarena_team, hids)
end

function userdata.getSquadFrdArena()
    local hids = userdata.getSquad(userdata.squadkeys.frdarena_team)
    return hids
end

function userdata.setSquadFrdArenac(hids)
    userdata.setSquad(userdata.squadkeys.frdarenac_team, hids)
end

function userdata.getSquadFrdArenac()
    local hids = userdata.getSquad(userdata.squadkeys.frdarenac_team)
    return hids
end

function userdata.setSquadDailyFight(hids)
    userdata.setSquad(userdata.squadkeys.dailyfight_team, hids)
end

function userdata.getSquadDailyFight()
    local hids = userdata.getSquad(userdata.squadkeys.dailyfight_team)
    return hids
end

function userdata.setSquadAirisland(hids)
    userdata.setSquad(userdata.squadkeys.airisland_team, hids)
end

function userdata.getSquadAirisland()
    local hids = userdata.getSquad(userdata.squadkeys.airisland_team)
    return hids
end

function userdata.setSquadFriend(hids)
    userdata.setSquad(userdata.squadkeys.friend_team, hids)
end

function userdata.getSquadFriend()
    local hids = userdata.getSquad(userdata.squadkeys.friend_team)
    return hids
end

function userdata.setSquadArena3v3Def(hids)
    userdata.setSquad(userdata.squadkeys.arena3v3_team, hids, 18)
end

function userdata.getSquadArena3v3Def()
    local hids = userdata.getSquad(userdata.squadkeys.arena3v3_team)
    return hids
end

function userdata.setSquadArena3v3Atk(hids)
    userdata.setSquad(userdata.squadkeys.arena3v3atk_team, hids, 18)
end

function userdata.getSquadArena3v3Atk()
    local hids = userdata.getSquad(userdata.squadkeys.arena3v3atk_team)
    return hids
end

function userdata.setSquadguildmill(hids)
    userdata.setSquad(userdata.squadkeys.guildmillatk_team, hids)
end

function userdata.getSquadguildmill()
    local hids = userdata.getSquad(userdata.squadkeys.guildmillatk_team)
    return hids
end

function userdata.setSquadguildmilldef(hids)
    userdata.setSquad(userdata.squadkeys.guildmill_team, hids)
end

function userdata.getSquadguildmilldef()
    local hids = userdata.getSquad(userdata.squadkeys.guildmill_team)
    return hids
end

function userdata.setGuildFight(hids)
    userdata.setSquad(userdata.squadkeys.guild_fight_team, hids)
end

function userdata.getGuildFight()
    local hids = userdata.getSquad(userdata.squadkeys.guild_fight_team)
    return hids
end

function userdata.setSquadBrokenboss(hids)
    userdata.setSquad(userdata.squadkeys.broken_boss_team, hids)
end

function userdata.getSquadBrokenboss()
    local hids = userdata.getSquad(userdata.squadkeys.broken_boss_team)
    return hids
end

function userdata.setSquadSweepforbrokenboss(hids)
    userdata.setSquad(userdata.squadkeys.sweepb_boss_team, hids)
end

function userdata.getSquadSweepforbrokenboss()
    local hids = userdata.getSquad(userdata.squadkeys.sweepb_boss_team)
    return hids
end

function userdata.setSquadSweepforairisland(hids)
    userdata.setSquad(userdata.squadkeys.sweepair_boss_team, hids)
end

function userdata.getSquadSweepforairisland()
    local hids = userdata.getSquad(userdata.squadkeys.sweepair_boss_team)
    return hids
end

function userdata.setSquadSweepforcomisland(hids)
    userdata.setSquad(userdata.squadkeys.sweepair_common_team, hids)
end

function userdata.getSquadSweepforcomisland()
    local hids = userdata.getSquad(userdata.squadkeys.sweepair_common_team)
    return hids
end

function userdata.setSquadSweepforfboss(hids)
    userdata.setSquad(userdata.squadkeys.sweepf_boss_team, hids)
end

function userdata.getSquadSweepforfboss()
    local hids = userdata.getSquad(userdata.squadkeys.sweepf_boss_team)
    return hids
end

function userdata.clearWhenSwitchAccount()
    print("我要清理，我要切服务器")
    local hids = { 0, 0, 0, 0, 0, 0 ,-1}
    
    userdata.setSquadNormal(hids)
    userdata.setSquadTrial(hids)
    userdata.setSquadArenaatk(hids)
    userdata.setSquadArenadef(hids)
    userdata.setSquadGuildBoss(hids)
    userdata.setSquadGuildGray(hids)
    userdata.setSquadDailyFight(hids)
    userdata.setSquadAirisland(hids)
    userdata.setSquadFriend(hids)
    userdata.setSquadguildmill(hids)
    userdata.setSquadguildmilldef(hids)
    userdata.setSquadFrdArena(hids)
    userdata.setGuildFight(hids)
    userdata.setSquadFrdpk(hids)
    userdata.setSquadBrave(hids)
    userdata.setSquadBrokenboss(hids)
    userdata.setSquadSweepforbrokenboss(hids)
    userdata.setSquadSweepforairisland(hids)
    userdata.setSquadSweepforcomisland(hids)
    userdata.setSquadSweepforfboss(hids)
	userdata.setSquadFrdArenac(hids)
	userdata.setSquadArenabatk(hids)
    userdata.setSquadArenabdef(hids)
    --userdata.setInt(userdata.keys.fightSpeed, 1)

    for i = 1, 18 do
        hids[i] = 0
    end
    for i = 19, 21 do 
        hids[i] = -1
    end
    print("清空防御整容")
    userdata.setSquadArena3v3Def(hids)
    userdata.setSquadArena3v3Atk(hids)

    --清理缓存中的pet变量
    local petData = require("data.pet")
    petData.sele = nil
end

return userdata

