local ui = {}

require "common.func"
local view = require "common.view"
local i18n = require "res.i18n"
local lbl = require "res.lbl"
local img = require "res.img"
local audio = require "res.audio"
local json = require "res.json"
local cfglimitgift = require "config.limitgift"
local cfgstore = require "config.store"
local player = require "data.player"
local bagdata = require "data.bag"
local activitylimitData = require "data.activitylimit"
local tipsequip = require "ui.tips.equip"
local tipsitem = require "ui.tips.item"
local NetClient = require "net.netClient"
local netClient = NetClient:getInstance()

local IDS = activitylimitData.IDS

function ui.create(grade)
    local layer = CCLayer:create()

    --local status = activitylimitData.getStatusById(IDS.FIRST_PAY.ID)
    --if not status then return end  -- eritem_status
    img.unload(img.packedOthers.ui_limit_level)
    img.unload(img.packedOthers.ui_limit_level_cn)
    if i18n.getCurrentLanguage() == kLanguageChinese 
        or i18n.getCurrentLanguage() == kLanguageChineseTW then
        img.load(img.packedOthers.ui_limit_level_cn)
    else
        img.load(img.packedOthers.ui_limit_level)
    end

    local board = img.createUISprite(img.ui.limit_level_gift)
    board:setScale(view.minScale)
    board:setAnchorPoint(CCPoint(0, 0))
    board:setPosition(scalep(342, 38))
    layer:addChild(board)
    local board_w = board:getContentSize().width
    local board_h = board:getContentSize().height

    json.load(json.ui.clock)
    local clockIcon = DHSkeletonAnimation:createWithKey(json.ui.clock)
    clockIcon:scheduleUpdateLua()
    clockIcon:playAnimation("animation", -1)
    clockIcon:setPosition(326, 380)
    board:addChild(clockIcon, 100)

    local showTimeLab = lbl.createFont2(18, "", ccc3(0xa5, 0xfd, 0x47))
    showTimeLab:setPosition(344, 380)
    showTimeLab:setColor(ccc3(0xa5, 0xfd, 0x47))
    showTimeLab:setAnchorPoint(0, 0.5)
    board:addChild(showTimeLab)

    -- lable
    local lable
    if i18n.getCurrentLanguage() == kLanguageChinese then
          lable = img.createUISprite("limit_level_label_cn.png")  
    elseif i18n.getCurrentLanguage() == kLanguageChineseTW then
          lable = img.createUISprite("limit_level_label_tw.png")  
    elseif i18n.getCurrentLanguage() == kLanguageRussian then
          lable = img.createUISprite("limit_level_label_ru.png")  
    elseif i18n.getCurrentLanguage() == kLanguageJapanese then
          lable = img.createUISprite("limit_level_label_jp.png")  
    elseif i18n.getCurrentLanguage() == kLanguageKorean then
          lable = img.createUISprite("limit_level_label_kr.png")  
    elseif i18n.getCurrentLanguage() == kLanguageSpanish then
          lable = img.createUISprite("limit_level_label_sp.png")  
    elseif i18n.getCurrentLanguage() == kLanguagePortuguese then
          lable = img.createUISprite("limit_level_label_pt.png")  
    else
          lable = img.createUISprite("limit_level_label.png")  
    end
    lable:setPosition(CCPoint(371, 330))
    board:addChild(lable)

    local rewards
    local storeID
    local ids
    if grade == cfglimitgift[IDS.LEVEL_3_15.ID].parameter then
        rewards = cfglimitgift[IDS.LEVEL_3_15.ID].rewards
        storeID = cfglimitgift[IDS.LEVEL_3_15.ID].storeId
        ids = IDS.LEVEL_3_15.ID
    end

    local cfg = cfgstore[storeID]
    local vipLab = lbl.createFont1(16, string.format("+%d VIP EXP", cfg.vipExp), ccc3(0xff, 0xf3, 0xa3))
    vipLab:setPosition(371, 285)
    board:addChild(vipLab, 100)

    local item_status = activitylimitData.getStatusById(ids)

    local limitNumLab = string.format(i18n.global.limitact_limit.string .. item_status.limits)
    local limitLbl = lbl.createFont1(16, limitNumLab, ccc3(255, 246, 223))
    limitLbl:setPosition(370, 155)
    board:addChild(limitLbl)

    local function onUpdate()
        cd = math.max(0, item_status.cd + activitylimitData.pull_time - os.time())
        if cd > 0 then
            local timeLab = string.format("%02d:%02d:%02d",math.floor(cd/3600),math.floor((cd%3600)/60),math.floor(cd%60))
            showTimeLab:setString(timeLab)
        else
            layer:removeFromParentAndCleanup(true)
        end
    end

    layer:scheduleUpdateWithPriorityLua(onUpdate, 0)

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
                layer:getParent():getParent():addChild(tmp_tip, 100)
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
    
    local pos_y = 240
    local offset_x = 185 + 187
    local step_x = 82
    --local first_item = createSpineItem(rewards[1])
    --first_item:setPosition(CCPoint(333, pos_y))
    --local first_item_menu = CCMenu:createWithItem(first_item)
    --first_item_menu:setPosition(CCPoint(0, 0))
    --board:addChild(first_item_menu)
    if #rewards == 2 then
        offset_x = 265 + 97 + 44
    end

    for ii=1, #rewards do
        local tmp_item = createSpineItem(rewards[ii])
        tmp_item:setScale(0.9)
        tmp_item:setPosition(CCPoint(offset_x+(ii-2)*step_x, pos_y-12))
        local tmp_item_menu = CCMenu:createWithItem(tmp_item)
        tmp_item_menu:setPosition(CCPoint(0, 0))
        board:addChild(tmp_item_menu)
    end

    local btn_get0 = img.createLogin9Sprite(img.login.button_9_small_gold)
    btn_get0:setPreferredSize(CCSizeMake(140, 52))
    --local lbl_get = lbl.createFont1(18, i18n.global.chip_btn_buy.string, ccc3(0x49, 0x26, 0x04))
    local item_price = cfgstore[storeID].priceStr 
    if isAmazon() then
    elseif APP_CHANNEL and APP_CHANNEL ~= "" then
        item_price = cfgstore[storeID].priceCnStr
    elseif i18n.getCurrentLanguage() == kLanguageChinese then
        item_price = cfgstore[storeID].priceCnStr
    end
    local shopData = require"data.shop"
    item_price = shopData.getPrice(storeID, item_price)
    local lbl_get = lbl.createFontTTF(18, item_price, ccc3(0x73, 0x3b, 0x05))
    lbl_get:setPosition(CCPoint(70, 26))
    btn_get0:addChild(lbl_get)
    local btn_get = SpineMenuItem:create(json.ui.button, btn_get0)
    btn_get:setPosition(CCPoint(371, 110))
    if item_status.status == 1 then
        setShader(btn_get, SHADER_GRAY, true)
        btn_get:setEnabled(false)
    end
    local btn_get_menu = CCMenu:createWithItem(btn_get)
    btn_get_menu:setPosition(CCPoint(0, 0))
    board:addChild(btn_get_menu)
    btn_get:registerScriptTapHandler(function()
        audio.play(audio.button)
        --local gemShop = require "ui.shop.main"
        --layer:getParent():getParent():addChild(gemShop.create(), 1001)
        --local cfg = cfgstore[storeID]

        local waitnet = addWaitNet()
        waitnet.setTimeout(60)
        local iap = require "common.iap"
        iap.pay(cfg.payId, function(conquest)
            delWaitNet()
        
            local tmp_bag = {
                items = {},
                equips = {},
            }

            if conquest then
                tbl2string(conquest)
                for ii=1,#rewards do
                    if rewards[ii].type == 1 then  -- item
                        local tbl_p = tmp_bag.items
                        tbl_p[#tbl_p+1] = {id=rewards[ii].id, num=rewards[ii].num}
                    elseif rewards[ii].type == 2 then  -- equip
                        local tbl_p = tmp_bag.equips
                        tbl_p[#tbl_p+1] = {id=rewards[ii].id, num=rewards[ii].num}
                    end
                end
                --tmp_bag.items[#tmp_bag.items+1] = {id = ITEM_ID_VIP_EXP, num = cfg.vipExp}
                bagdata.items.add({id = ITEM_ID_VIP_EXP, num = cfg.vipExp})
                bagdata.addRewards(tmp_bag)

                local rewardsKit = require "ui.reward"
                CCDirector:sharedDirector():getRunningScene():addChild(rewardsKit.showReward(tmp_bag), 100000)
                item_status.limits = item_status.limits - 1
                limitNumLab = string.format(i18n.global.limitact_limit.string .. item_status.limits)
                limitLbl:setString(limitNumLab)
                if item_status.limits == 0 then
                    item_status.status = 1
                    setShader(btn_get, SHADER_GRAY, true)
                    btn_get:setEnabled(false)
                end
                --layer:removeFromParentAndCleanup(true)
            end
        end)
    end)

    return layer
end

return ui
