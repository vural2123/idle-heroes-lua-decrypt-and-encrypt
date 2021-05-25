-- manage spine json here

local json = {}

require "common.const"
require "common.func"
--local cfghero = require "config.hero"
--local cfgequip = require "config.equip"
--local cfgmons = require "config.monster"
--local cfgskill = require "config.skill"
--local cfgfx = require "config.fx"

local cache = DHSkeletonDataCache:getInstance()

json.fight = {
    shake = "spinejson/fight/shake.json", -- 抖屏效果
}

json.ui = {
    button = "spinejson/ui/btn.json", -- 按钮效果
    start = "spinejson/ui/homepage_new.json", -- home界面
    main_zhuchangjing = "spinejson/ui/main_zhuchangjing_summer.json",
    main_diaoqiao = "spinejson/ui/main_diaoqiao_summer.json",    -- 吊桥
    main_yuanzheng = "spinejson/ui/main_yuanzheng_summer.json",
    main_yun = "spinejson/ui/main_yun_summer.json",
    main_yun2 = "spinejson/ui/main_yun2_summer.json",
    yindao = "spinejson/ui/yindao_girl.json", -- 新手引导
    yd_hand = "spinejson/ui/yd_hand.json", -- 新手引导手指
    bt_numbers = "spinejson/ui/bt_numbers.json", -- 战斗中的伤害数字
    bt_tiao = "spinejson/ui/bt_tiao.json", -- 战斗中的能量条
    zhandou_win = "spinejson/ui/victory.json", -- 战斗胜利结算
    zhandou_lose = "spinejson/ui/defeat.json", -- 战斗失败结算
    main_zhanzhengzm = "spinejson/ui/main_zhanyi_summer.json",     -- 战争之门
    zhaohuan = "spinejson/ui/zhaohuan.json", --召唤
    toukui = "spinejson/ui/toukui.json", --召唤骷髅头
    nengliangxi = "spinejson/ui/toukui.json", -- 能量满之后的头盔状态
    zhaohuan_lizihua = "spinejson/ui/zhaohuan_lizihua.json", --召唤粒子
    zhaohuan_kuozhan = "spinejson/ui/zhaohuan_kuozhan.json", --扩展框
    zhaohuan_zhen = "spinejson/ui/zhaohuan_zhen.json", --召唤出英雄之前的动画
    zhaohuan_fazhen = "spinejson/ui/zhaohuan_fazhen.json", --新召唤出英雄之前的动画
    zhaohuan_fazhen_s = "spinejson/ui/zhaohuan_fazhen_s.json", 
    zhaohuan_nenglcao = "spinejson/ui/zhaohuan_nenglcao.json", --能量槽
    zhaohuan_toukuicx = "spinejson/ui/zhaohuan_toukuicx.json", --头盔持续发光
    blacksmith = "spinejson/ui/blacksmith.json", --铁匠铺
    blacksmith_hecheng = "spinejson/ui/blacksmith_hecheng.json", --铁匠铺合成
    reward = "spinejson/ui/reward.json", --奖励
    reward_particle = "spinejson/ui/reward_particle.json", --奖励标题粒子
    duchang = "spinejson/ui/duchang.json", --赌场
    chongwu = "spinejson/ui/chongwu.json", --赌场
    tunvlang = "spinejson/ui/tunvlang.json", --赌场
    duchang_new = "spinejson/ui/duchang_new.json", --高级赌场
    chongwu_new = "spinejson/ui/chongwu_new.json", --高级赌场
    tunvlang_new = "spinejson/ui/tunvlang_new.json", --高级赌场
    hook = "spinejson/ui/hook.json", --挂机入场
    hook_reward_01 = "spinejson/ui/hook_reward_01.json", --挂机经验
    hook_reward_02 = "spinejson/ui/hook_reward_02.json", --挂机经验
    hook_reward_03 = "spinejson/ui/hook_reward_03.json", --挂机经验
    hook_pariticle = "spinejson/ui/hook_pariticle.json", --挂机经验
    hook_baoxiang = "spinejson/ui/hook_baoxiang.json", --挂机物品
    guaji_xuanguan = "spinejson/ui/guaji_xuanguan.json", --挂机选关
    guaji_green_btn = "spinejson/ui/guaji_green_btn.json", --挂机get按钮
    guaji_red_btn = "spinejson/ui/guaji_red_btn.json", --挂机battle按钮
    guaji_yellow_btn = "spinejson/ui/guaji_yellow_btn.json", --挂机map按钮
    guild = "spinejson/ui/guild.json", --公会领地场景
    fuben = "spinejson/ui/fuben.json", --公会副本
    guildwar = "spinejson/ui/guildwar.json", --公会战
    keji = "spinejson/ui/keji.json", --公会科技
    bbq = "spinejson/ui/bbq.json", --公会
    mofang = "spinejson/ui/mofang.json", --公会
    shop = "spinejson/ui/shop.json", --公会
    radar = "spinejson/ui/radar.json", --挂机雷达
    equip_in = "spinejson/ui/equip_in.json", --奖励
    shengji = "spinejson/ui/shengji.json", -- 升级
    jiesuo = "spinejson/ui/jiesuo.json", -- 升级解锁功能
    devour = "spinejson/ui/devour.json",
    devour_fx = "spinejson/ui/devour_fx.json",
    devour_reward = "spinejson/ui/devour_reward.json",
    main_heishi = "spinejson/ui/main_heishi_summer.json", -- 黑市建筑
    main_jiuguan = "spinejson/ui/main_jiuguan_summer.json", -- 酒馆建筑
    main_tunshi = "spinejson/ui/main_tunshi_summer.json", -- 吞噬建筑
    main_zhaohuan = "spinejson/ui/main_zhaohuan_summer.json", -- 召唤建筑
    main_duchang = "spinejson/ui/main_duchang_summer.json", -- 赌场建筑
    main_tiejiangpu = "spinejson/ui/main_tiejiangpu_summer.json", -- 铁匠铺建筑
    main_jjc = "spinejson/ui/main_jjc_summer.json", -- 竞技场建筑
    main_huanjing = "spinejson/ui/main_chengbao_summer.json", -- 试炼建筑
    main_tree = "spinejson/ui/main_zhongjing_summer.json", -- 神树建筑
    main_summoning = "spinejson/ui/main_hecheng_summer.json", -- 英雄合成
    main_feiting = "spinejson/ui/main_feiting.json",    -- 远征入口
    main_hongshu = "spinejson/ui/main_hongshu_summer.json",    -- 红树装饰
    main_dilao = "spinejson/ui/main_dilao_summer.json",    -- 地牢
    main_bg = "spinejson/ui/main_bg.json", -- 主场景
    winter_main_snow = "spinejson/ui/winter_main_snow.json", -- 主场景下雪
    winter_main_snow2 = "spinejson/ui/winter_main_snow2.json", -- 主场景下雪
    huanjingta_floor1 = "spinejson/ui/huanjingta_floor1.json",
    huanjingta_floor2 = "spinejson/ui/huanjingta_floor2.json",
    huanjingta_mogu = "spinejson/ui/huanjingta_mogu.json",
    huanjingta = "spinejson/ui/huanjingta.json",
    dianjin = "spinejson/ui/dianjin.json", -- 点金
    dianjin2 = "spinejson/ui/dianjin2.json", -- 点金手人物
    heishishangren = "spinejson/ui/heishishangren.json", -- 黑市商人
    heishi = "spinejson/ui/heishi.json", -- 黑市
    gonghui_shengji = "spinejson/ui/gonghui_shengji.json", -- 公会技能升级
    gonghui_jiesuo = "spinejson/ui/gonghui_jiesuo.json", -- 公会技能解锁
    lag_loading = "spinejson/ui/lag_loading.json", -- 菊花动画
    mailbox = "spinejson/ui/mailbox.json",  -- 内容空时动画
    bt_1 = "spinejson/ui/bt_1.json",
    bt_2 = "spinejson/ui/bt_2.json",
    bt_3 = "spinejson/ui/bt_3.json",
    bt_4 = "spinejson/ui/bt_4.json",
    bt_5 = "spinejson/ui/bt_5.json",
    bt_6 = "spinejson/ui/bt_6.json",
    bt_7 = "spinejson/ui/bt_7.json",
    bt_8 = "spinejson/ui/bt_8.json",
    bt_9 = "spinejson/ui/bt_9.json",
    bt_10 = "spinejson/ui/bt_10.json",
    bt_11 = "spinejson/ui/bt_11.json",
    bt_12 = "spinejson/ui/bt_12.json",
    bt_diyu = "spinejson/ui/bt_diyu.json",
    bt_cloud_diyu = "spinejson/ui/bt_cloud_diyu.json",
    bt_lock_weizhi_diyu = "spinejson/ui/bt_lock_weizhi_diyu.json",
    bt_pubu = "spinejson/ui/bt_pubu.json",
    bt_pubu = "spinejson/ui/bt_pubu.json",
    bt_pubu = "spinejson/ui/bt_pubu.json",
    bt_all = "spinejson/ui/bt_all.json",
    bt_all_kunnan = "spinejson/ui/bt_all_kunnan.json",
    hero_up = "spinejson/ui/hero_up.json",
    hero_star = "spinejson/ui/hero_star.json",
    hero_et = "spinejson/ui/hero_up_new.json",
    hero_bg1 = "spinejson/ui/hero_bg1.json",
    hero_bg2 = "spinejson/ui/hero_bg2.json",
    hero_bg3 = "spinejson/ui/hero_bg3.json",
    hero_bg4 = "spinejson/ui/hero_bg4.json",
    hero_bg5 = "spinejson/ui/hero_bg5.json",
    hero_bg6 = "spinejson/ui/hero_bg6.json",
    clock = "spinejson/ui/clock.json",
    ic_refresh = "spinejson/ui/ic_refresh.json",
    ic_vip = "spinejson/ui/ic_vip.json",
    daojishi = "spinejson/ui/daojishi.json",
    jjc = "spinejson/ui/jjc.json",
    jg_btn = "spinejson/ui/jg_btn.json",
    bt_cloud = "spinejson/ui/bt_cloud.json",
    bt_cloud_kunnan = "spinejson/ui/bt_cloud_kunnan.json",
    bt_lock = "spinejson/ui/bt_lock.json",
    qianghua = "spinejson/ui/qianghua.json", --强化特效
    bt_lock_weizhi = "spinejson/ui/bt_lock_weizhi.json",
    bt_sword = "spinejson/ui/bt_sword.json",
    gh_chengbao_fx = "spinejson/ui/gh_chengbao_fx.json",  -- 公会领地
    zhaohuan_lizi = "spinejson/ui/zhaohuan_lizi.json",
    haoyou_heart = "spinejson/ui/haoyou_heart.json",
    hero_numbers = "spinejson/ui/hero_numbers.json", 
    campbuff = {
        "spinejson/ui/jjc_kulou.json",
        "spinejson/ui/jjc_baolei.json",
        "spinejson/ui/jjc_shenyuan.json",
        "spinejson/ui/jjc_senlin.json",
        "spinejson/ui/jjc_anying.json",
        "spinejson/ui/jjc_shengguang.json",
        "spinejson/ui/jjc_hunhe.json",
        "spinejson/ui/jjc_zhengxie.json",
        "spinejson/ui/jjc_huimie.json",
        "spinejson/ui/jjc_jiushu.json",
        "spinejson/ui/jjc_zhengyi.json",
        "spinejson/ui/jjc_xiee.json",
        "spinejson/ui/jjc_wuran.json",
        "spinejson/ui/jjc_shuhun.json",
        "spinejson/ui/jjc_shengyusi.json",
        "spinejson/ui/jjc_sudi.json",
    },
    tiejiangpu_shengji_fx = "spinejson/ui/tiejiangpu_shengji_fx.json",
    devour_fx_v2 = "spinejson/ui/devour_fx_v2.json",
    devour_in_animation = "spinejson/ui/devour_in_animation.json",
    devour_particle_animation = "spinejson/ui/devour_particle_animation.json",
    pvp_choujiang = "spinejson/ui/PVP_choujiang.json",
    yingxiong_hecheng = "spinejson/ui/yingxiong_hecheng.json",
    yingxiong_hecheng_shake = "spinejson/ui/yingxiong_hecheng_shake.json",
    yingxiong_hecheng2 = "spinejson/ui/yingxiong_hecheng2.json",
    yingxiong_hecheng_animation_in = "spinejson/ui/yingxiong_hecheng_animation_in.json",
    bt_lock_weizhi_kunnan = "spinejson/ui/bt_lock_weizhi_kunnan.json",
    haoyouzhuzhan = "spinejson/ui/haoyouzhuzhan.json",
    baoshi_hecheng = "spinejson/ui/baoshi_hecheng.json",
    yingxiongmianban = "spinejson/ui/yingxiongmianban.json",
    yingxiongmianban_weizhi = "spinejson/ui/yingxiongmianban_weizhi.json",
    yuanzheng_caozuojiemian = "spinejson/ui/yuanzheng_caozuojiemian.json",
    yuanzheng_fight = "spinejson/ui/yuanzheng_fight.json",
    yuanzheng_jiemian = "spinejson/ui/yuanzheng_jiemian.json",
    yuanzheng_path = "spinejson/ui/yuanzheng_path.json",
    yuanzheng = "spinejson/ui/yuanzheng.json",
    p3v3jiesuan = "spinejson/ui/3v3jiesuan.json",
    p3v3jiesuan_v = "spinejson/ui/3v3jiesuan_victory.json",
    p3v3jiesuan_d = "spinejson/ui/3v3jiesuan_defeat.json",
    jjc2 = "spinejson/ui/jjc2.json",
    zhuangbei_shengji = "spinejson/ui/zhuangbei_shengji.json",
    baowu_line = "spinejson/ui/baowu_line.json",
    baowu_upgrade = "spinejson/ui/baowu_upgrade.json",
    baowu_upgrade2 = "spinejson/ui/baowu_upgrade2.json",
    mofang_mofangline = "spinejson/ui/mofang_mofangline.json",
    mofang_smk = "spinejson/ui/mofang_smk.json",
    mofang_upgrade_down = "spinejson/ui/mofang_upgrade_down.json",
    mofang_upgrade_up = "spinejson/ui/mofang_upgrade_up.json",
    mofang_upgrade_huxi = "spinejson/ui/mofang_upgrade_huxi.json",
    mofang_upgrade_line = "spinejson/ui/mofang_upgrade_line.json",
    shengmingzhishu_1 = "spinejson/ui/shengmingzhishu_1.json",
    shengmingzhishu_2 = "spinejson/ui/shengmingzhishu_2.json",
    shengmingzhishu_3 = "spinejson/ui/shengmingzhishu_3.json",
    shengmingzhishu_4 = "spinejson/ui/shengmingzhishu_4.json",
    shengmingzhishu_5 = "spinejson/ui/shengmingzhishu_5.json",
    shengmingzhishu_animation = "spinejson/ui/shengmingzhishu_animation.json",
    shengmingzhishu_bottom = "spinejson/ui/shengmingzhishu_bottom.json",
    shengmingzhishu_light = "spinejson/ui/shengmingzhishu_light.json",
    shengmingzhishu_top = "spinejson/ui/shengmingzhishu_top.json",
    zhihuan = "spinejson/ui/zhihuan.json",
    yuanzheng_baoxiang = "spinejson/ui/yuanzheng_baoxiang.json",
    yuanzheng_baoxiang_gem = "spinejson/ui/yuanzheng_baoxiang_gem.json",
    sheng_xing1 = "spinejson/ui/sheng_xing1.json",
    sheng_xing2 = "spinejson/ui/sheng_xing2.json",
    praise = "spinejson/ui/praise.json",
    guildwar_ui = "spinejson/ui/guildwar_ui.json", 
    bt_dot_easy = "spinejson/ui/bt_dot_easy.json",
    bt_dot_hard = "spinejson/ui/bt_dot_hard.json",
    bt_dot_hell = "spinejson/ui/bt_dot_hell.json",
    jiuguan_refresh = "spinejson/ui/jiuguan_refresh.json",
    yindao_new = "spinejson/ui/yindao_girl.json", -- 新手引导new
    yindao_face = "spinejson/ui/yindao_face.json",
    frd_jjc = "spinejson/ui/3v3_jjc.json",
    pet_json = "spinejson/ui/zhanchong.json", --战宠
    pet2_json = "spinejson/ui/zhanchong_2.json", --战宠
    pet_play_json = "spinejson/ui/pet_play.json", --战宠
    exp_battle = "spinejson/ui/exp_battle.json", --战宠能量点
    exp_battle2 = "spinejson/ui/exp_battle2.json", --战宠能量点
    
    spine_dragon_1 = "spinejson/ui/dragon1.json",
    spine_dragon_2 = "spinejson/ui/dragon2.json",
    spine_dragon_3 = "spinejson/ui/dragon3.json",
    spine_dragon_4 = "spinejson/ui/dragon4.json",

    spine_fox_1 = "spinejson/ui/fox1.json",
    spine_fox_2 = "spinejson/ui/fox2.json",
    spine_fox_3 = "spinejson/ui/fox3.json",
    spine_fox_4 = "spinejson/ui/fox4.json",

    spine_deer_1 = "spinejson/ui/deer1.json",
    spine_deer_2 = "spinejson/ui/deer2.json",
    spine_deer_3 = "spinejson/ui/deer3.json",
    spine_deer_4 = "spinejson/ui/deer4.json",

    spine_eagle_1 = "spinejson/ui/griffin1.json",
    spine_eagle_2 = "spinejson/ui/griffin2.json",
    spine_eagle_3 = "spinejson/ui/griffin3.json",
    spine_eagle_4 = "spinejson/ui/griffin4.json",

    spine_wolf_1 = "spinejson/ui/wolf1.json",
    spine_wolf_2 = "spinejson/ui/wolf2.json",
    spine_wolf_3 = "spinejson/ui/wolf3.json",
    spine_wolf_4 = "spinejson/ui/wolf4.json",

    spine_stone_1 = "spinejson/ui/stone1.json",
    spine_stone_2 = "spinejson/ui/stone2.json",
    spine_stone_3 = "spinejson/ui/stone3.json",
    spine_stone_4 = "spinejson/ui/stone4.json",

    spine_viper_1 = "spinejson/ui/viper1.json",
    spine_viper_2 = "spinejson/ui/viper2.json",
    spine_viper_3 = "spinejson/ui/viper3.json",
    spine_viper_4 = "spinejson/ui/viper4.json",

    spine_ice_1 = "spinejson/ui/icesoul1.json",
    spine_ice_2 = "spinejson/ui/icesoul2.json",
    spine_ice_3 = "spinejson/ui/icesoul3.json",
    spine_ice_4 = "spinejson/ui/icesoul4.json",

    pet_fx = "spinejson/ui/pet_fx.json",

    touxiang = "spinejson/ui/touxiang.json", -- 特殊头像特效
    huodong = "spinejson/ui/huodong.json", -- 30天奖励
    solo = "spinejson/ui/1on1.json", --单挑赛
    solo_up = "spinejson/ui/1on1_up.json", --单挑赛上方条
    solo_down = "spinejson/ui/1on1_down.json", -- 单挑赛下方条
    solo_side = "spinejson/ui/1on1_side.json", -- 单挑赛左方条
    solo_btn = "spinejson/ui/dantiaosai.json", --单挑赛按钮
    solo_speed = "spinejson/ui/1on1_1speed_click_side.json", -- 速度药剂特效
    solo_power = "spinejson/ui/1on1_2power_click_side.json", -- 力量药剂特效
    solo_crit = "spinejson/ui/1on1_3cc_click_side.json", -- 暴击药剂特效
    solo_auto = "spinejson/ui/1on1_auto_fight_side.json", -- 单挑赛自动按钮的特效
    solo_lightA = "spinejson/ui/dantiaosai_zengjiaA.json", --单挑赛光效A
    solo_lightB = "spinejson/ui/dantiaosai_zengjiaB.json", --单挑赛光效B
    solo_sweep = "spinejson/ui/sweep_ui.json", --扫荡动画
    trader1 = "spinejson/ui/dts_shangren1.json", --商人1
    trader2 = "spinejson/ui/dts_shangren2.json", --商人2
    trader3 = "spinejson/ui/dts_shangren3.json", --商人3
    petHint = "spinejson/ui/pet_hint.json", --宠物伤害治疗头像
    bianshen = "spinejson/ui/bianshen.json", -- 十星觉醒
    lv10_framefx = "spinejson/ui/lv10_framefx.json",  --十星头像特效
    unlock = "spinejson/ui/unlock.json", --大关卡解锁
    kongzhan = "spinejson/ui/kongzhan.json", --空战岛
    kongzhan_xuanwo = "spinejson/ui/kongzhan_xuanwo.json",
    kongzhan_map = "spinejson/ui/kongzhan_map.json",
    kongzhan_map_yun = "spinejson/ui/kongzhan_map_yun.json",
    kongzhan_golem = "spinejson/ui/kongzhan_golem.json",
    kongzhan_dragon = "spinejson/ui/kongzhan_dragon.json",
    kongzhan_dao1 = "spinejson/ui/kongzhan_dao1.json",
    kongzhan_dao2 = "spinejson/ui/kongzhan_dao2.json",
    kongzhan_dao3 = "spinejson/ui/kongzhan_dao3.json",
    kongzhan_diaoluo = "spinejson/ui/kongzhan_diaoluo.json",
    kongzhan_rk1 = "spinejson/ui/kongzhan_rk1_summer.json",
    kongzhan_rk2 = "spinejson/ui/kongzhan_rk2_summer.json",
    kongzhan_rk3 = "spinejson/ui/kongzhan_rk3_summer.json",
    kongzhan_zhudao = "spinejson/ui/kongzhan_zhudao.json",
    kongzhan_feiting = "spinejson/ui/kongzhan_feiting.json",
    kongzhan_baojun = "spinejson/ui/kongzhan_baojun.json",
    kongzhan_chengbao = "spinejson/ui/kongzhan_chengbao.json",
    kongzhan_jifeng = "spinejson/ui/kongzhan_jifeng.json",
    kongzhan_jinkuang = "spinejson/ui/kongzhan_jinkuang.json",
    kongzhan_shuijing = "spinejson/ui/kongzhan_shuijing.json",
    kongzhan_xueyue = "spinejson/ui/kongzhan_xueyue.json",
    kongzhan_mofachen = "spinejson/ui/kongzhan_mofachen.json",
    kongzhan_huoli = "spinejson/ui/kongzhan_huoli.json",
    kongzhan_fengshou = "spinejson/ui/kongzhan_fengshou.json",
    kongzhan_dizuo = "spinejson/ui/kongzhan_dizuo.json",
    kongzhan_zhudao_chaichu = "spinejson/ui/kongzhan_zhudao_chaichu.json",
    kongzhan_zhudao_jianzao = "spinejson/ui/kongzhan_zhudao_jianzao.json",
    kongzhan_zhudao_shengji = "spinejson/ui/kongzhan_zhudao_shengji.json",
    kongzhan_tish = "spinejson/ui/kongzhan_tishi.json",
    zhihuan_icon = "spinejson/ui/zhihuan_icon.json",
    npc_order = "spinejson/ui/npc_order.json", --自动获取订单
    chinesenewyear = "spinejson/ui/chinesenewyear.json",
    gonghui_qidao = "spinejson/ui/gonghui_qidao.json", --公会副本延续
    gear_ui = "spinejson/ui/gear_ui.json",
    gear_ui2 = "spinejson/ui/gear_ui2.json", --暗影守卫活动
    double_icon = "spinejson/ui/double_icon.json", -- 活动bossx2
    lv10plus_hero = "spinejson/ui/lv10plus_hero.json", --赋能star
    cannon = "spinejson/ui/cannon.json", --空岛站扫荡按钮
}

if APP_CHANNEL and APP_CHANNEL ~= "" then
    json.ui.start = "spinejson/ui/homepage_new.json" -- home界面
end

json.unit = {}

local helper = require "common.helper"
local jsonQueue = require("dhcomponents.tools.List").new()

-- 参数是img.initUnits()的返回值
function json.initUnits(ids)
    for _, d in ipairs(ids) do
        json.unit[d.id] = "spinejson/unit/cha_" .. d.str .. ".json"
    end
end

function json.createSpineHero(id)
    local cfghero = require "config.hero"
    json.loadUnit(cfghero[id].heroBody)
    local hero = DHSkeletonAnimation:createWithKey(json.unit[cfghero[id].heroBody])
    hero:scheduleUpdateLua()
    hero:playAnimation("stand", -1)

    if cfghero[id].anims then
        for i =1,#cfghero[id].anims do
            local jsonname = "spinejson/unit/" .. cfghero[id].anims[i] .. ".json"
            json.load(jsonname) 
            local heroloop = DHSkeletonAnimation:createWithKey(jsonname)
            heroloop:scheduleUpdateLua()
            heroloop:playAnimation("animation", -1)
            hero:addChildFollowSlot(cfghero[id].anims[i], heroloop)
        end
    end

    return hero
end

function json.createSpineHeroSkin(id)
    local cfgequip = require "config.equip"
    json.loadUnit(cfgequip[id].heroBody)
    local hero = DHSkeletonAnimation:createWithKey(json.unit[cfgequip[id].heroBody])
    hero:scheduleUpdateLua()
    hero:playAnimation("stand", -1)
    return hero
end

function json.createSpineMons(id)
    local cfgmons = require "config.monster"
    return json.createSpineHero(cfgmons[id].heroLink)
end

function json.create(key)
    json.load(key)
    local anim = DHSkeletonAnimation:createWithKey(key)
    anim:scheduleUpdateLua()
    return anim
end

function json.createWithoutSchedule(key)
    json.load(key)
    local anim = DHSkeletonAnimation:createWithKey(key)
    return anim
end

-- 单纯加载json，用于texture已经加载好的情况
-- eg: json.load(json.ui.chuansongmen)
function json.load(key, groupFlag)
    if not cache:getSkeletonData(key) then
        if not groupFlag then
            while jsonQueue:size() > helper.getJsonCacheCount() do
                local valueKey = jsonQueue:front()
                json.unload(valueKey, true)
                jsonQueue:popFront()
            end
        end

        cache:loadSkeletonData(key, key)
        jsonQueue:pushBack(key)
    end
end

-- 单纯卸载json
-- eg: json.unload(json.ui.chuansongmen)
function json.unload(key, skipCheck)
    cache:removeSkeletonData(key)

    if not skipCheck then
        local iter = jsonQueue:getBegin()
        while iter ~= jsonQueue:getEnd() do
            local valueKey = iter:getValue()
            if valueKey == key then
                iter = jsonQueue:erase(iter)
                break
            else
                iter = iter:getNext()
            end
        end
    end
end

-- 加载单位，会先加载texture，再加载json
-- 注意参数id为美术资源序号，不是英雄id或怪物id
function json.loadUnit(id)
    local img = require "res.img"
    img.loadUnit(id)
    json.load(json.unit[id])
end

-- 会卸载所有单位的json和对应的texture
function json.unloadAllUnits()
    for _, name in pairs(json.unit) do
        json.unload(name)
    end
    local img = require "res.img"
    img.unloadAllUnits()
end

-- 加载召唤动画的texture和json
function json.loadSummon()
    local img = require "res.img"
    for _, name in pairs(img.packedOthers.spine_ui_summon) do
        img.load(name)
    end
    json.load(json.ui.summon)
    json.load(json.ui.summon_avatar)
end

-- 卸载召唤动画的texture和json
function json.unloadSummon()
    json.unload(json.ui.summon)
    local img = require "res.img"
    for _, name in pairs(img.packedOthers.spine_ui_summon) do
        img.unload(name)
    end
end

-- 加载吞噬动画的texture和json
function json.loadDevour()
    local img = require "res.img"
    for _, name in pairs(img.packedOthers.spine_ui_devour) do
        img.load(name)
    end
    for _, name in pairs(json.ui.devour) do
        json.load(name)
    end
end

-- 卸载吞噬动画的texture和json
function json.unloadDevour()
    for _, name in pairs(json.ui.devour) do
        json.unload(name)
    end
    local img = require "res.img"
    for _, name in pairs(img.packedOthers.spine_ui_devour) do
        img.unload(name)
    end
end

-- 进UI时要加载的json资源
-- 返回loadlist为json路径数组
function json.getLoadListForUI()
    local loadlist = {}
    return loadlist
end

-- 缓存到DHSkeletonDataCache时战斗特效的key 
-- 这些key没有像json.unit和json.ui那样罗列是因为战斗中特效太多，组织太复杂
function json.keyForFight(fxName)
    return "spinejson/fight/" .. fxName .. ".json"
end

-- 进战斗时要加载的json资源
-- 返回loadlist为json路径数组
function json.getLoadListForFight(heroIds, hook, extraSkills)
    return require("res.imgc").getLoadListForFightJson(heroIds, hook, extraSkills, json.unit, json.fight)
end

function json.getLoadListForPet(pets)
    local cfgskill = require "config.skill"
    local cfgfx = require "config.fx"
    local loadlist = {}
    if not pets or #pets <= 0 then return loadlist end
    local cfgpet = require "config.pet"
    local pngNames = {}
    for ii=1,#pets do
        local petid = pets[ii].id
        -- body
        --local petName = string.format("%s%s", cfgpet[petid].petBody, pets[ii].star+1)
        --loadlist[#loadlist+1] = json.keyForFight(petName)
        -- skill
        local skills = {}
        local actSkillId = cfgpet[petid].actSkillId + pets[ii].lv - 1
        skills[#skills+1] = actSkillId
        -- pet 被动技能不产生特效
        -- 所有特效名字
        local fxNames = {}
        for _, sk in ipairs(skills) do
            if sk then
                for _, f in ipairs({"fxSelf","fxMain1","fxMain2","fxHurt1","fxHurt2"}) do
                    local fxes = cfgskill[sk][f]
                    if fxes then
                        for _, fx in ipairs(fxes) do
                            fxNames[#fxNames+1] = cfgfx[fx].name
                        end
                    end
                end
            end
        end
        for ii=1, #fxNames do
            loadlist[#loadlist+1] = json.keyForFight(fxNames[ii])
        end
    end
    return loadlist
end

function json.getLoadListForSkin(skins)
    local cfgequip = require "config.equip"
    local cfgfx = require "config.fx"
    local loadlist = {}
    -- 所有特效名字
    local fxNames = {}
    -- 单位资源
    for ii=1, #skins do
        local unitResId = cfgequip[skins[ii]].heroBody
        loadlist[#loadlist+1] = json.unit[unitResId]
        local cfg = cfgequip[skins[ii]]
        for _, f in ipairs({"fxSelf","fxMain1","fxMain2","fxHurt1","fxHurt2"}) do
            local fxes = cfg[f]
            if fxes then
                for _, fx in ipairs(fxes) do
                    fxNames[#fxNames+1] = cfgfx[fx].name
                end
            end
        end
    end
    for ii=1, #fxNames do
        loadlist[#loadlist+1] = json.keyForFight(fxNames[ii])
    end
    return loadlist
end

-- loadlist: 参见json.getLoadListFor...
function json.loadAll(loadlist)
    for _, name in ipairs(loadlist) do
        json.load(name, true)
    end
end

-- loadlist: 参见json.getLoadListFor...
function json.unloadAll(loadlist)
    for _, name in ipairs(loadlist) do
        json.unload(name, true)
    end
end

return json
