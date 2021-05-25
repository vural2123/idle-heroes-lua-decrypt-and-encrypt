local ui = {}

require "common.func"
local view = require "common.view"
local i18n = require "res.i18n"
local lbl = require "res.lbl"
local img = require "res.img"
local audio = require "res.audio"
local json = require "res.json"
local player = require "data.player"
local activityData = require "data.activity"
local net = require "net.netClient"
local tipsequip = require "ui.tips.equip"
local tipsitem = require "ui.tips.item"
local bag = require "data.bag"
local crushbossfight = require "ui.activity.crushbossfight"

local IDS = activityData.IDS
local ItemType = {
    Item = 1,
    Equip = 2,
}

function ui.create(id)
    local layer = CCLayer:create()

    local board = CCSprite:create()
    board:setContentSize(CCSizeMake(570, 438))
    board:setScale(view.minScale)
    board:setAnchorPoint(CCPoint(0, 0))
    board:setPosition(scalep(352, 57))
    layer:addChild(board)
    --drawBoundingbox(layer, board)
    local board_w = board:getContentSize().width
    local board_h = board:getContentSize().height

    local IMG_PACK = { img.packedOthers.ui_activity_crushing_space1, img.packedOthers.ui_activity_crushing_space2, img.packedOthers.ui_activity_crushing_space3 }
    local IMG_PACK_CN = { img.packedOthers.ui_activity_crushing_space1_cn, img.packedOthers.ui_activity_crushing_space2_cn, img.packedOthers.ui_activity_crushing_space3_cn }
    local IMG = { img.ui.activity_crush_board1, img.ui.activity_crush_board2, img.ui.activity_crush_board3 }
    local IMG_KR = {"activity_crush_board1_kr.png", "activity_crush_board2_kr.png", "activity_crush_board3_kr.png"}
    local IMG_JP = {"activity_crush_board1_jp.png", "activity_crush_board2_jp.png", "activity_crush_board3_jp.png"}
    local IMG_TW = {"activity_crush_board1_tw.png", "activity_crush_board2_tw.png", "activity_crush_board3_tw.png"}
    local IMG_RU = {"activity_crush_board1_ru.png", "activity_crush_board2_ru.png", "activity_crush_board3_ru.png"}
    local pos = {board_w/2-185, board_w/2, board_w/2+185}
    local battleBtn = {}

    for i = 1,3 do
        img.unload(IMG_PACK[i])
        img.unload(IMG_PACK_CN[i])
        if i18n.getCurrentLanguage() == kLanguageChinese then
            img.load(IMG_PACK_CN[i])
        else
            img.load(IMG_PACK[i])
        end
        local banner
        if i18n.getCurrentLanguage() == kLanguageKorean then
            banner = img.createUISprite(IMG_KR[i])
        elseif i18n.getCurrentLanguage() == kLanguageJapanese then
            banner = img.createUISprite(IMG_JP[i])
        elseif i18n.getCurrentLanguage() == kLanguageChineseTW then
            banner = img.createUISprite(IMG_TW[i])
        elseif i18n.getCurrentLanguage() == kLanguageRussian then
            banner = img.createUISprite(IMG_RU[i])
        else
            banner = img.createUISprite(IMG[i])
        end
        banner:setAnchorPoint(CCPoint(0.5, 1))
        banner:setPosition(CCPoint(pos[i], board_h-55))
        board:addChild(banner)

        local battleSprite = img.createLogin9Sprite(img.login.button_9_small_gold)
        battleSprite:setPreferredSize(CCSizeMake(130, 50))

        local battlelab = lbl.createFont1(18, i18n.global.trial_stage_btn_battle.string, lbl.buttonColor)
        battlelab:setPosition(CCPoint(battleSprite:getContentSize().width/2,
                                        battleSprite:getContentSize().height/2))
        battleSprite:addChild(battlelab)

        battleBtn[i] = SpineMenuItem:create(json.ui.button, battleSprite)
        battleBtn[i]:setAnchorPoint(0.5, 0)
        battleBtn[i]:setPosition(CCPoint(pos[i], 70))
        local battleMenu = CCMenu:createWithItem(battleBtn[i])
        battleMenu:setPosition(0,0)
        board:addChild(battleMenu)
    end

    -- btn rank
    local btn_rank0 = img.createUISprite(img.ui.btn_rank)
    local btn_rank = SpineMenuItem:create(json.ui.button, btn_rank0)
    btn_rank:setPosition(CCPoint(482, board_h-30))
    local btn_rank_menu = CCMenu:createWithItem(btn_rank)
    btn_rank_menu:setPosition(CCPoint(0, 0))
    board:addChild(btn_rank_menu)
    btn_rank:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer:getParent():getParent():addChild((require"ui.activity.crushbossrank").create(), 1000)
    end)

    -- btn reward
    local btn_reward0 = img.createUISprite(img.ui.reward)
    local btn_reward = SpineMenuItem:create(json.ui.button, btn_reward0)
    btn_reward:setPosition(CCPoint(430, board_h-30))
    local btn_reward_menu = CCMenu:createWithItem(btn_reward)
    btn_reward_menu:setPosition(CCPoint(0, 0))
    board:addChild(btn_reward_menu)
    btn_reward:registerScriptTapHandler(function()
        audio.play(audio.button)
        local gParams = {
            sid = player.sid,
            id = 1,
        }
        addWaitNet()
        net:bboss_syn(gParams, function(__data)
            delWaitNet()
            tbl2string(__data)
            if __data.status ~= 0 then
                showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                return
            end
            layer:getParent():getParent():addChild((require"ui.activity.crushreward").create(__data.id), 1000)
        end)
    end)

    --json.load(json.ui.double_icon)
    --local animx2 = DHSkeletonAnimation:createWithKey(json.ui.double_icon)
    --animx2:scheduleUpdateLua()
    --animx2:playAnimation("animation", -1)
    --animx2:setPosition(410, board_h-15)
    --board:addChild(animx2)

    if player.isSeasonal() then
        json.load(json.ui.double_icon)
        local animx2 = DHSkeletonAnimation:createWithKey(json.ui.double_icon)
        animx2:scheduleUpdateLua()
        animx2:playAnimation("animation", -1)
        animx2:setPosition(410, board_h-15)
        board:addChild(animx2)
    end

    local btnInfoSprite = img.createUISprite(img.ui.btn_help)
    local btnInfo = SpineMenuItem:create(json.ui.button, btnInfoSprite)
    btnInfo:setPosition(534, board_h-30)
    local menuInfo = CCMenu:createWithItem(btnInfo)
    menuInfo:setPosition(0, 0)
    board:addChild(menuInfo, 100)
    btnInfo:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer:getParent():getParent():addChild(require("ui.help").create(i18n.global.broken_space_help1.string, i18n.global.help_title.string), 1000)
    end)

    local lbl_cd_des = lbl.createFont2(14, i18n.global.activity_to_end.string)
    lbl_cd_des:setAnchorPoint(CCPoint(0, 0.5))
    lbl_cd_des:setPosition(CCPoint(board_w/2+20, 28))
    board:addChild(lbl_cd_des)
    local lbl_cd = lbl.createFont2(14, "", ccc3(0xa5, 0xfd, 0x47))
    lbl_cd:setAnchorPoint(CCPoint(1, 0.5))
    lbl_cd:setPosition(CCPoint(lbl_cd_des:boundingBox():getMinX()-6, 28))
    board:addChild(lbl_cd)

    -- tick bg
    local tick_bg = img.createUI9Sprite(img.ui.main_coin_bg)
    tick_bg:setPreferredSize(CCSizeMake(145, 36))
    tick_bg:setPosition(CCPoint(90, board_h-30))
    board:addChild(tick_bg)
    local icon_tick = img.createItemIcon2(ITEM_ID_BROKEN)
    icon_tick:setPosition(CCPoint(5, tick_bg:getContentSize().height/2+2))
    tick_bg:addChild(icon_tick)
    local btn_tick0 = img.createUISprite(img.ui.main_icon_plus)
    local btn_tick = HHMenuItem:create(btn_tick0)
    btn_tick:setPosition(CCPoint(tick_bg:getContentSize().width-18, tick_bg:getContentSize().height/2+2))
    local btn_tick_menu = CCMenu:createWithItem(btn_tick)
    btn_tick_menu:setPosition(CCPoint(0, 0))
    tick_bg:addChild(btn_tick_menu)

    local tick_num = 0
    if bag.items.find(ITEM_ID_BROKEN) then
        tick_num = bag.items.find(ITEM_ID_BROKEN).num
    end
    local lbl_tick = lbl.createFont2(16, tick_num, ccc3(255, 246, 223))
    lbl_tick:setPosition(CCPoint(tick_bg:getContentSize().width/2-10, tick_bg:getContentSize().height/2+3))
    tick_bg:addChild(lbl_tick)
    lbl_tick.num = tick_num

    local function refreshTick(num)
        tick_num = tick_num + num
        lbl_tick:setString(tick_num)
    end

    btn_tick:registerScriptTapHandler(function()
        audio.play(audio.button)
        local buybroken = require "ui.activity.buybroken"
        local buybrokendlg = buybroken.create(refreshTick)
        layer:getParent():getParent():addChild(buybrokendlg, 1001)
    end)

    battleBtn[1]:registerScriptTapHandler(function()
        disableObjAWhile(battleBtn[1])
        audio.play(audio.button) 
        layer:getParent():getParent():addChild(crushbossfight.create(1, refreshTick), 1001) 
    end)

    battleBtn[2]:registerScriptTapHandler(function()
        disableObjAWhile(battleBtn[2])
        audio.play(audio.button) 
        layer:getParent():getParent():addChild(crushbossfight.create(2, refreshTick), 1001) 
    end)

    battleBtn[3]:registerScriptTapHandler(function()
        disableObjAWhile(battleBtn[3])
        audio.play(audio.button) 
        layer:getParent():getParent():addChild(crushbossfight.create(3, refreshTick), 1001) 
    end)

    local act_st = activityData.getStatusById(IDS.CRUSHING_SPACE_1.ID)

    local last_update = os.time() - 1
    local function onUpdate(ticks)
        if os.time() - last_update < 1 then return end
        last_update = os.time()
        local remain_cd = act_st.cd - (os.time() - activityData.pull_time)
        if remain_cd >= 0 then
            local time_str = time2string(remain_cd)
            lbl_cd:setString(time_str)
        else
        end
    end
    layer:scheduleUpdateWithPriorityLua(onUpdate, 0)

    layer:setTouchSwallowEnabled(false)
    layer:setTouchEnabled(true)
    return layer
end

return ui
