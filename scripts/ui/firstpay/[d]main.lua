local ui = {}

require "common.func"
local view = require "common.view"
local i18n = require "res.i18n"
local lbl = require "res.lbl"
local img = require "res.img"
local audio = require "res.audio"
local json = require "res.json"
local cfgactivity = require "config.activity"
local player = require "data.player"
local bagdata = require "data.bag"
local activityData = require "data.activity"
local tipsequip = require "ui.tips.equip"
local tipsitem = require "ui.tips.item"
local NetClient = require "net.netClient"
local netClient = NetClient:getInstance()

local IDS = activityData.IDS

function ui.create()
    local layer = CCLayer:create()

    local status = activityData.getStatusById(IDS.FIRST_PAY.ID)
    if not status then return end  -- error
    
    ---- dark bg
    --local darkbg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY*0.8))
    --layer:addChild(darkbg)

    img.unload(img.packedOthers.ui_firstpay)
    img.unload(img.packedOthers.ui_firstpay_cn)
    if i18n.getCurrentLanguage() == kLanguageChinese 
        or i18n.getCurrentLanguage() == kLanguageChineseTW then
        img.load(img.packedOthers.ui_firstpay_cn)
    else
        img.load(img.packedOthers.ui_firstpay)
    end
    local board = img.createUISprite(img.ui.firstpay_board)
    board:setScale(view.minScale)
    board:setAnchorPoint(CCPoint(0, 0))
    board:setPosition(scalep(342, 38))
    layer:addChild(board)
    local board_w = board:getContentSize().width
    local board_h = board:getContentSize().height

    --board:setScale(0.1 * view.minScale)
    --board:runAction(CCEaseBackOut:create(CCScaleTo:create(0.3, view.minScale)))

    --local function backEvent()
    --    layer:removeFromParent()
    --end
    -- btn_close
    --local btn_close0 = img.createUISprite(img.ui.close)
    --local btn_close = SpineMenuItem:create(json.ui.button, btn_close0)
    --btn_close:setPosition(CCPoint(board_w-24, board_h-58))
    --local btn_close_menu = CCMenu:createWithItem(btn_close)
    --btn_close_menu:setPosition(CCPoint(0, 0))
    --board:addChild(btn_close_menu, 100)
    --btn_close:registerScriptTapHandler(function()
    --    audio.play(audio.button)
    --    backEvent()
    --end)

    -- lable
    local lable_des
    local lable
    if i18n.getCurrentLanguage() == kLanguageChinese then
          lable = img.createUISprite("limit_first_label_cn.png")  
          lable_des = img.createUISprite("limit_first_label_des_cn.png")  
    elseif i18n.getCurrentLanguage() == kLanguageChineseTW then
          lable = img.createUISprite("limit_first_label_tw.png")  
          lable_des = img.createUISprite("limit_first_label_des_tw.png")  
    elseif i18n.getCurrentLanguage() == kLanguageRussian then
          lable = img.createUISprite("limit_first_label_ru.png")  
          lable_des = img.createUISprite("limit_first_label_des_ru.png")  
    elseif i18n.getCurrentLanguage() == kLanguageJapanese then
          lable = img.createUISprite("limit_first_label_jp.png")  
          lable_des = img.createUISprite("limit_first_label_des_jp.png")  
    elseif i18n.getCurrentLanguage() == kLanguageKorean then
          lable = img.createUISprite("limit_first_label_kr.png")  
          lable_des = img.createUISprite("limit_first_label_des_kr.png")  
    elseif i18n.getCurrentLanguage() == kLanguagePortuguese then
          lable = img.createUISprite("limit_first_label_kp.png")  
          lable_des = img.createUISprite("limit_first_label_des_kp.png")  
    elseif i18n.getCurrentLanguage() == kLanguageSpanish then
          lable = img.createUISprite("limit_first_label_ks.png")  
          lable_des = img.createUISprite("limit_first_label_des_ks.png")  
    elseif i18n.getCurrentLanguage() == kLanguageTurkish then
          lable = img.createUISprite("limit_first_label_tr.png")  
          lable_des = img.createUISprite("limit_first_label_des_tr.png")  
    else
          lable = img.createUISprite("limit_first_label.png")  
          lable_des = img.createUISprite("limit_first_label_des.png")  
    end
    lable:setPosition(CCPoint(371, 315))
    board:addChild(lable)
    lable_des:setPosition(CCPoint(371, 370))
    board:addChild(lable_des)

    local rewards = cfgactivity[IDS.FIRST_PAY.ID].rewards
    local function createSpineItem(itemObj)
        local tmp_item
        if itemObj.type == 1 then  -- item
            local tmp_item0 = img.createItem(itemObj.id, itemObj.num)
            tmp_item = SpineMenuItem:create(json.ui.button, tmp_item0)
        elseif itemObj.type == 2 then  -- equip
            local tmp_item0 = img.createEquip(itemObj.id, itemObj.num)
            tmp_item = SpineMenuItem:create(json.ui.button, tmp_item0)
        end
        tmp_item:registerScriptTapHandler(function()
            audio.play(audio.button)
            local tmp_tip
            if itemObj.type == 1 then  -- item
                tmp_tip = tipsitem.createForShow({id=itemObj.id})
                layer:getParent():getParent():addChild(tmp_tip, 1000)
            elseif itemObj.type == 2 then  -- equip
                tmp_tip = tipsequip.createById(itemObj.id)
                layer:addChild(tmp_tip, 100)
            end
            tmp_tip.setClickBlankHandler(function()
                tmp_tip:removeFromParentAndCleanup(true)
            end)
        end)
        return tmp_item
    end

    local pos_y = 218
    local offset_x = 159 + 177
    local step_x = 72
    local first_item = createSpineItem(rewards[1])
    first_item:setPosition(CCPoint(253, pos_y))
    local first_item_menu = CCMenu:createWithItem(first_item)
    first_item_menu:setPosition(CCPoint(0, 0))
    board:addChild(first_item_menu)

    for ii=2, #rewards do
        local tmp_item = createSpineItem(rewards[ii])
        tmp_item:setScale(0.8)
        tmp_item:setPosition(CCPoint(offset_x+(ii-2)*step_x, pos_y-7))
        local tmp_item_menu = CCMenu:createWithItem(tmp_item)
        tmp_item_menu:setPosition(CCPoint(0, 0))
        board:addChild(tmp_item_menu)
    end

    local btn_get0 = img.createLogin9Sprite(img.login.button_9_small_gold)
    btn_get0:setPreferredSize(CCSizeMake(140, 52))
    local lbl_get = lbl.createFontTTF(18, i18n.global.chip_btn_buy.string, ccc3(0x49, 0x26, 0x04))
    lbl_get:setPosition(CCPoint(70, 26))
    btn_get0:addChild(lbl_get)
    local btn_get = SpineMenuItem:create(json.ui.button, btn_get0)
    btn_get:setPosition(CCPoint(371, 115))
    local btn_get_menu = CCMenu:createWithItem(btn_get)
    btn_get_menu:setPosition(CCPoint(0, 0))
    board:addChild(btn_get_menu)
    btn_get:registerScriptTapHandler(function()
        audio.play(audio.button)
        local gemShop = require "ui.shop.main"
        layer:getParent():getParent():addChild(gemShop.create(), 1001)
    end)

    local btn_claim0 = img.createLogin9Sprite(img.login.button_9_small_green)
    btn_claim0:setPreferredSize(CCSizeMake(140, 52))
    local lbl_claim = lbl.createFont1(18, i18n.global.mail_btn_get.string, ccc3(0x1d, 0x67, 0x00))
    lbl_claim:setPosition(CCPoint(70, 26))
    btn_claim0:addChild(lbl_claim)
    local btn_claim = SpineMenuItem:create(json.ui.button, btn_claim0)
    btn_claim:setPosition(CCPoint(371, 115))
    if status.status == 2 then
        setShader(btn_claim, SHADER_GRAY, true)
        btn_claim:setEnabled(false)
    end
    local btn_claim_menu = CCMenu:createWithItem(btn_claim)
    btn_claim_menu:setPosition(CCPoint(0, 0))
    board:addChild(btn_claim_menu)
    btn_claim:registerScriptTapHandler(function()
        audio.play(audio.button)
        local params = {
            sid = player.sid,
        }
        addWaitNet()
        netClient:fpay(params, function(__data)
            delWaitNet()
            if __data.status ~=0 then
                showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                return
            end
            status.status = 2  -- 设置为已领取
            local tmp_bag = {
                items = {},
                equips = {},
            }
            for ii=1,#rewards do
                if rewards[ii].type == 1 then  -- item
                    local tbl_p = tmp_bag.items
                    tbl_p[#tbl_p+1] = {id=rewards[ii].id, num=rewards[ii].num}
                elseif rewards[ii].type == 2 then  -- equip
                    local tbl_p = tmp_bag.equips
                    tbl_p[#tbl_p+1] = {id=rewards[ii].id, num=rewards[ii].num}
                end
            end
            bagdata.addRewards(tmp_bag)
            --showToast(i18n.global.hook_get_ok.string)
            local rewardsKit = require "ui.reward"
            CCDirector:sharedDirector():getRunningScene():addChild(rewardsKit.showReward(tmp_bag), 100000)
            setShader(btn_claim, SHADER_GRAY, true)
            btn_claim:setEnabled(false)
            --layer:removeFromParentAndCleanup(true)
        end)
    end)

    local function checkStatus()
        if status.status == 0 then
            btn_get:setVisible(true)
            btn_claim:setVisible(false)
        elseif status.status == 1 then
            btn_get:setVisible(false)
            btn_claim:setVisible(true)
        else
            btn_get:setVisible(false)
            btn_claim:setVisible(true)
        end
    end
    checkStatus()

    --function layer.onAndroidBack()
    --    backEvent()
    --end

    --layer:setTouchEnabled(true)
    --layer:setTouchSwallowEnabled(true)
        
    --addBackEvent(layer)
    
    --local function onEnter()
    --    print("onEnter")
    --    layer.notifyParentLock()
    --end
    --local function onExit()
    --    layer.notifyParentUnlock()
    --end
    --layer:registerScriptHandler(function(event)
    --    if event == "enter" then
    --        onEnter()
    --    elseif event == "exit" then
    --        onExit()
    --    end
    --end)

    local function onUpdate(ticks)
        checkStatus()
    end

    layer:scheduleUpdateWithPriorityLua(onUpdate, 0)

    return layer
end

return ui
