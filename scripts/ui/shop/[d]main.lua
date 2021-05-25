
local ui = {}

require "common.func"
require "common.const"

local view = require "common.view"
local img = require "res.img"
local json = require "res.json"
local lbl = require "res.lbl"
local audio = require "res.audio"
local i18n = require "res.i18n"
local player = require "data.player"
local bag = require "data.bag"
local cfgstore = require "config.store"
local cfgvip = require "config.vip"
local cfgitem = require "config.item"
local tipsitem = require "ui.tips.item"
local tipsequip = require "ui.tips.equip"
local net = require "net.netClient"
local shop = require "data.shop"
local reward = require "ui.reward"

function ui.create(gata)
    local layer = CCLayer:create()
    local shopType = "gem"
    if gata then
        shopType = gata
    end

    --dark bg
    local darkbg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    layer:addChild(darkbg)
   
    local board = img.createUISprite(img.ui.gemstore_bg)
    board:setScale(view.minScale)
    board:setPosition(view.midX, view.midY)
    layer:addChild(board)
        
    -- board anim
    board:setScale(0.1 * view.minScale)
    board:runAction(CCEaseBackOut:create(CCScaleTo:create(0.3, view.minScale)))

    local board_w = board:getContentSize().width
    local board_h = board:getContentSize().height
    
    local specialLayer = CCLayer:create()
    board:addChild(specialLayer)

    local vip_a ={1,1,1,2,2,2,3,3,3,4,4,4,4,4,4,4,4,4,4,4,4,4}  --图标等级
    vip_a[0] = 1
    local vip_c1 = ccc3(0xff, 0xd1, 0x79)
    local vip_c2 = ccc3(0xe8, 0xfb, 0xff)
    local vip_c3 = ccc3(0xff, 0xf4, 0x78)
    local vip_c4 = ccc3(0x8a, 0xf8, 0xff)
    local vip_c = {vip_c1, vip_c1, vip_c1, 
                   vip_c2, vip_c2, vip_c2, 
                   vip_c3, vip_c3, vip_c3, 
                   vip_c4, vip_c4, vip_c4, vip_c4, vip_c4, vip_c4, vip_c4, vip_c4, vip_c4, vip_c4, vip_c4, vip_c4, }
    vip_c[0] = vip_c1

    local function createSpecial()
        local storeVip = player.vipLv() or player.maxVipLv()

        local vipExpBg = img.createUI9Sprite(img.ui.gemstore_vip_bg)
        vipExpBg:setPreferredSize(CCSize(242, 26))
        vipExpBg:setAnchorPoint(CCPoint(0, 0.5))
        vipExpBg:setPosition(CCPoint(110, 540-107))
        specialLayer:addChild(vipExpBg)


        local expNow,needExp = 1,1

        if storeVip ~= player.maxVipLv() then
            expNow = bag.items.find(ITEM_ID_VIP_EXP).num
            needExp = cfgvip[player.vipLv()+1].exp
        end
        
        local vipExpFgSprite = img.createUISprite(img.ui.gemstore_vip_fg)
        local vipExpFg = createProgressBar(vipExpFgSprite)
        vipExpFg:setAnchorPoint(ccp(0,0.5))
        vipExpFg:setPosition(4, vipExpBg:getContentSize().height/2)
        vipExpFg:setPercentage(expNow/needExp*100)
        vipExpBg:addChild(vipExpFg,1)

        local ExpInfo = expNow .. " / " .. needExp
        if expNow == 1 and needExp == 1 then 
            ExpInfo = bag.items.find(ITEM_ID_VIP_EXP).num 
        end

        local showVipExp = lbl.createFont2(16, ExpInfo, ccc3(255, 246, 223))
        showVipExp:setPosition(vipExpBg:getContentSize().width/2,
                                vipExpBg:getContentSize().height/2) 
        vipExpBg:addChild(showVipExp,2)

        --local vipIcon1 = img.createUISprite(img.ui.main_vip_bg)
        --vipIcon1:setPosition(CCPoint(120 - 50, 540-107))
        --board:addChild(vipIcon1)
        --local viplvLab1 = lbl.createFont2(16, "VIP" .. storeVip, ccc3(0xff, 0xdc, 0x82))
        --viplvLab1:setPosition(CCPoint(vipIcon1:getContentSize().width/2,
        --                                vipIcon1:getContentSize().height/2))
        --vipIcon1:addChild(viplvLab1)

        local vip_bg1 = CCSprite:create()
        vip_bg1:setContentSize(CCSizeMake(58, 58))
        vip_bg1:setPosition(CCPoint(120 - 50, 540-107))
        specialLayer:addChild(vip_bg1)
        local ic_vip1 = DHSkeletonAnimation:createWithKey(json.ui.ic_vip)
        ic_vip1:scheduleUpdateLua()
        ic_vip1:playAnimation("" .. vip_a[storeVip], -1)
        ic_vip1:setPosition(CCPoint(29, 29))
        vip_bg1:addChild(ic_vip1)
        local lbl_player_vip1 = lbl.createFont2(18, storeVip, ccc3(0xff, 0xdc, 0x82))
        lbl_player_vip1:setColor(vip_c[storeVip])
        --lbl_player_vip1:setPosition(CCPoint(vip_bg1:getContentSize().width/2, vip_bg1:getContentSize().height/2))
        --vip_bg1:addChild(lbl_player_vip1)
        ic_vip1:addChildFollowSlot("code_num", lbl_player_vip1)

        local buyLab = lbl.createFont2(18, i18n.global.shop_gem_buy.string)
        buyLab:setAnchorPoint(0, 0.5)
        buyLab:setPosition(CCPoint(360, 540-107))
        specialLayer:addChild(buyLab)

        local vipfullLab = lbl.createFont2(18, i18n.global.shop_vipexp_full.string, ccc3(255, 246, 223))
        vipfullLab:setAnchorPoint(0, 0.5)
        vipfullLab:setPosition(CCPoint(360, 540-107))
        vipfullLab:setVisible(false)
        specialLayer:addChild(vipfullLab)

        local gemIcon = img.createItemIcon2(ITEM_ID_GEM)
        gemIcon:setScale(0.9)
        gemIcon:setAnchorPoint(ccp(0, 0.5))
        gemIcon:setPosition(CCPoint(buyLab:boundingBox():getMaxX()+6, 540-107))
        specialLayer:addChild(gemIcon)

        local needDiamond = lbl.createFont2(18, needExp - expNow, ccc3(0xff, 0xf7, 0x84))
        needDiamond:setAnchorPoint(ccp(0, 0.5))
        needDiamond:setPosition(gemIcon:boundingBox():getMaxX()+5, 540 - 107)
        specialLayer:addChild(needDiamond)        

        local turntoLab = lbl.createFont2(18, i18n.global.shop_next_vip.string)
        turntoLab:setAnchorPoint(ccp(0, 0.5))
        turntoLab:setPosition(CCPoint(needDiamond:boundingBox():getMaxX()+6, 540-107))
        specialLayer:addChild(turntoLab)

        --local vipIcon2 = img.createUISprite(img.ui.main_vip_bg)
        --vipIcon2:setAnchorPoint(ccp(0, 0.5))
        --vipIcon2:setPosition(CCPoint(turntoLab:boundingBox():getMaxX()+8, 540-107))
        --specialLayer:addChild(vipIcon2)
        --local viplvLab2 = lbl.createFont2(16, "VIP" .. storeVip+1, ccc3(0xff, 0xdc, 0x82))
        --viplvLab2:setPosition(CCPoint(vipIcon2:getContentSize().width/2,
        --                                vipIcon2:getContentSize().height/2))
        --vipIcon2:addChild(viplvLab2)

        json.load(json.ui.ic_vip)
        local vip_bg2 = CCSprite:create()
        vip_bg2:setContentSize(CCSizeMake(58, 58))
        vip_bg2:setAnchorPoint(ccp(0, 0.5))
        vip_bg2:setPosition(CCPoint(turntoLab:boundingBox():getMaxX()+8, 540-107))
        specialLayer:addChild(vip_bg2)
        local ic_vip = DHSkeletonAnimation:createWithKey(json.ui.ic_vip)
        ic_vip:scheduleUpdateLua()
        ic_vip:playAnimation("" .. vip_a[storeVip+1], -1)
        ic_vip:setPosition(CCPoint(29, 29))
        vip_bg2:addChild(ic_vip)
        local useless_node = CCNode:create()
        local lbl_player_vip = lbl.createFont2(18, storeVip+1, ccc3(0xff, 0xdc, 0x82))
        lbl_player_vip:setColor(vip_c[storeVip+1])
        useless_node:addChild(lbl_player_vip)
        ic_vip:addChildFollowSlot("code_num", useless_node)

        if storeVip == player.maxVipLv() then
            gemIcon:setVisible(false)
            needDiamond:setVisible(false)
            vip_bg2:setVisible(false)
            
            buyLab:setVisible(false)
            turntoLab:setVisible(false)
            vipfullLab:setVisible(true)
        end
    end

    createSpecial()
    
    -- 订阅状态
    local subTitle = nil
    local storeBuyLayer = CCLayer:create()
    board:addChild(storeBuyLayer)
    storeBuyLayer:setVisible(shopType == "gem")

    local propertyLayer = CCLayer:create()
    board:addChild(propertyLayer)
    propertyLayer:setVisible(shopType == "vip")

    local menuPay = CCMenu:create()
    menuPay:setPosition(0,0)
    board:addChild(menuPay)
    local btnPaySprite = img.createLogin9Sprite(img.login.button_9_small_gold)
    btnPaySprite:setPreferredSize(CCSize(128, 48))
    local btnPay = SpineMenuItem:create(json.ui.button, btnPaySprite)
    local labPay = lbl.createFont1(18, i18n.global.shop_privilege.string, ccc3(0x73, 0x3b, 0x05))
    labPay:setPosition(btnPaySprite:getContentSize().width/2,
                        btnPaySprite:getContentSize().height/2)
    btnPaySprite:addChild(labPay)
    btnPay:setPosition(760, 435)
    menuPay:addChild(btnPay)

    --createbuylayer
    local function createBuyLayer()
        local itemNum = 7
        if shop.showSub() then
            itemNum = 8
        end
        local SCROLL_CONTAINER_SIZE = math.max(itemNum * 220 + 30,930)        
        
        local Scroll = CCScrollView:create()
        Scroll:setDirection(kCCScrollViewDirectionHorizontal)
        --Scroll:setAnchorPoint(ccp(0, 0))
        Scroll:setPosition(72-50, 545-505)
        Scroll:setViewSize(CCSize(820,338))
        Scroll:setContentSize(CCSize(SCROLL_CONTAINER_SIZE+20,400))
        storeBuyLayer:addChild(Scroll)

        local itemBg = {}
        local function createItem(pos)
            itemBg[pos] = img.createUISprite(img.ui.gemstore_item_bg)
            --itemBg[pos]:setAnchorPoint(ccp(1, 1))
            if itemNum == 8 then
                itemBg[pos]:setPosition(-190 + 224 * cfgstore[pos].rank+itemBg[pos]:getContentSize().width/2,
                                        25+itemBg[pos]:getContentSize().height/2)
            else
                itemBg[pos]:setPosition(-190 + 224 * (cfgstore[pos].rank-1)+itemBg[pos]:getContentSize().width/2,
                                        25+itemBg[pos]:getContentSize().height/2)
            end
            Scroll:getContainer():addChild(itemBg[pos])
            
            if shop.pay[pos] == 0 then
                local doubleValue = nil
                if isAmazon() then
                    doubleValue = img.createUISprite(img.ui.gemstore_double_icon)
                elseif isOnestore() then
                    doubleValue = img.createUISprite(img.ui.gemstore_double_icon_kr)
                elseif APP_CHANNEL and APP_CHANNEL ~= "" then
                    doubleValue = img.createUISprite(img.ui.gemstore_double_icon_cn)
                elseif i18n.getCurrentLanguage() == kLanguageChinese then
                    doubleValue = img.createUISprite(img.ui.gemstore_double_icon_cn)
                elseif i18n.getCurrentLanguage() == kLanguageChineseTW then
                    doubleValue = img.createUISprite(img.ui.gemstore_double_icon_tw)
                elseif i18n.getCurrentLanguage() == kLanguageJapanese then
                    doubleValue = img.createUISprite(img.ui.gemstore_double_icon_jp)
                elseif i18n.getCurrentLanguage() == kLanguageKorean then
                    doubleValue = img.createUISprite(img.ui.gemstore_double_icon_kr)
                elseif i18n.getCurrentLanguage() == kLanguageRussian then
                    doubleValue = img.createUISprite(img.ui.gemstore_double_icon_ru)
                elseif i18n.getCurrentLanguage() == kLanguageSpanish then
                    doubleValue = img.createUISprite(img.ui.gemstore_double_icon_sp)
                elseif i18n.getCurrentLanguage() == kLanguagePortuguese then
                    doubleValue = img.createUISprite(img.ui.gemstore_double_icon_pt)
                elseif i18n.getCurrentLanguage() == kLanguageTurkish then
                    doubleValue = img.createUISprite(img.ui.gemstore_double_icon_tr)
                else
                    doubleValue = img.createUISprite(img.ui.gemstore_double_icon)
                end
                doubleValue:setAnchorPoint(ccp(0,0))
                doubleValue:setPosition(-1,45)
                itemBg[pos]:addChild(doubleValue,10000,101)
            end

            local Icon = img.createUISprite(img.ui["gemstore_item" .. cfgstore[pos].iconId-1])
            Icon:setPosition(itemBg[pos]:getContentSize().width/2, itemBg[pos]:getContentSize().height/2 + 30)
            itemBg[pos]:addChild(Icon)

            if pos == 3 then
                Icon:setScale(0.95)
                Icon:setPosition(itemBg[pos]:getContentSize().width/2+5, itemBg[pos]:getContentSize().height/2 + 30)
            elseif pos == 4 then
                Icon:setPosition(itemBg[pos]:getContentSize().width/2, itemBg[pos]:getContentSize().height/2 + 27)
            elseif pos == 5 then
                Icon:setPosition(itemBg[pos]:getContentSize().width/2, itemBg[pos]:getContentSize().height/2 + 25)
            end

            local showDesc = lbl.createFont2(26, cfgstore[pos].diamonds, ccc3(255, 246, 223))
            showDesc:setPosition(itemBg[pos]:getContentSize().width/2, itemBg[pos]:getContentSize().height/2-34)
            itemBg[pos]:addChild(showDesc)

            if cfgstore[pos].extra then
                local extraBg = img.createUISprite(img.ui.gemstore_extra_icon)
                extraBg:setPosition(173, 268)
                itemBg[pos]:addChild(extraBg)

                local showName = lbl.createFont1(14, i18n.global.shop_extra.string, ccc3(0xae, 0x49, 0x21))
                showName:setPosition(extraBg:getContentSize().width/2,55)
                extraBg:addChild(showName)

                local showNum = lbl.createFont1(24, cfgstore[pos].extra, ccc3(0xae, 0x49, 0x21))
                showNum:setScaleX(0.7)
                showNum:setPosition(extraBg:getContentSize().width/2, 31)
                extraBg:addChild(showNum)
            end

            local item_price = cfgstore[pos].priceStr 
            if isAmazon() then
            elseif APP_CHANNEL and APP_CHANNEL ~= "" then
                item_price = cfgstore[pos].priceCnStr
            elseif i18n.getCurrentLanguage() == kLanguageChinese then
                item_price = cfgstore[pos].priceCnStr
            end
            item_price = shop.getPrice(pos, item_price)
            local costLab = lbl.createFontTTF(18, item_price, ccc3(0x73, 0x3b, 0x05))
            costLab:setAnchorPoint(ccp(1, 0.5))
            costLab:setPosition(182, 30)
            itemBg[pos]:addChild(costLab)
            
            local curpos = pos
            if itemNum == 8 then
                curpos = curpos+1
            end
            if shop.pay[6] ~= 0 and shop.pay[32] ~= 0 then
                itemBg[pos]:setPosition(-190 + 224 * (curpos)+itemBg[pos]:getContentSize().width/2,
                                        25+itemBg[pos]:getContentSize().height/2)
            end
            if shop.pay[6] ~= 0 and shop.pay[32] == 0 then
                itemBg[pos]:setPosition(-190 + 224 * (curpos+1)+itemBg[pos]:getContentSize().width/2,
                                        25+itemBg[pos]:getContentSize().height/2)
            end
            if shop.pay[6] == 0 and shop.pay[32] ~= 0  then
                itemBg[pos]:setPosition(-190 + 224 * (curpos+1)+itemBg[pos]:getContentSize().width/2,
                                        25+itemBg[pos]:getContentSize().height/2)
            end
        end

        local function createMonth(pos)
            local id = pos 
            local Icon = nil
            local titlename = nil
            local totallab = nil
            local font = 16
            local scores = 250
            if pos == 8 then
                id = 33
                Icon = img.createUISprite(img.ui["gemstore_item" .. cfgstore[id].iconId-2])
                titlename = i18n.global.activity_des_sub.string
                totallab = i18n.global.shop_vip_loot.string
                scores = 0
                font = 14
            elseif pos == 7 then
                id = 32
                Icon = img.createUISprite(img.ui["gemstore_item" .. cfgstore[id].iconId-2])
                titlename = i18n.global.activity_des_mini.string
                totallab = i18n.global.shop_vip_total.string
                font = 14
            else
                Icon = img.createUISprite(img.ui["gemstore_item" .. cfgstore[id].iconId-7])
                titlename = i18n.global.shop_vip_title.string
                totallab = i18n.global.shop_vip_total.string
                scores = 750
            end

            itemBg[pos] = img.createUISprite(img.ui.gemstore_item_bg)
            itemBg[pos]:setPosition(-190 + 224 * cfgstore[id].rank+itemBg[pos]:getContentSize().width/2,
                                    25+itemBg[pos]:getContentSize().height/2)
            Scroll:getContainer():addChild(itemBg[pos])
             
            local curpos = pos
            if itemNum == 8 then
                curpos = pos+1
            end
            if pos == 7 and shop.pay[6] ~= 0 then
                itemBg[pos]:setPosition(-190 + 224 * (cfgstore[id].rank-1)+itemBg[pos]:getContentSize().width/2,
                                        25+itemBg[pos]:getContentSize().height/2)
            end

            if pos == 8 and shop.pay[32] ~= 0 and shop.pay[6] ~= 0 then
                itemBg[pos]:setPosition(-190 + 224 * (cfgstore[id].rank-2)+itemBg[pos]:getContentSize().width/2,
                                        25+itemBg[pos]:getContentSize().height/2)
            end
            if pos == 8 and shop.pay[32] == 0 and shop.pay[6] ~= 0 then
                itemBg[pos]:setPosition(-190 + 224 * (cfgstore[id].rank-1)+itemBg[pos]:getContentSize().width/2,
                                        25+itemBg[pos]:getContentSize().height/2)
            end
            if pos == 8 and shop.pay[32] ~= 0 and shop.pay[6] == 0 then
                itemBg[pos]:setPosition(-190 + 224 * (cfgstore[id].rank-1)+itemBg[pos]:getContentSize().width/2,
                                        25+itemBg[pos]:getContentSize().height/2)
            end

            Icon:setPosition(itemBg[pos]:getContentSize().width/2,itemBg[pos]:getContentSize().height/2 + 10)
            itemBg[pos]:addChild(Icon)
            
            local detailSprite = img.createUISprite(img.ui.btn_detail)
            local detailBtn = SpineMenuItem:create(json.ui.button, detailSprite)
            detailBtn:setPosition(172, 482-213)

            local detailMenu = CCMenu:create()
            detailMenu:setPosition(0, 0)
            itemBg[pos]:addChild(detailMenu)
            detailMenu:addChild(detailBtn)

            detailBtn:registerScriptTapHandler(function()
                audio.play(audio.button)
                if pos == 8 then
                    layer:addChild(require("ui.help").create(string.format(i18n.global.help_sub_card.string, cfgstore[id].priceStr)), 1000)
                elseif pos == 7 then
                    layer:addChild(require("ui.help").create(i18n.global.help_mini_card.string), 1000)
                else
                    layer:addChild(require("ui.help").create(i18n.global.help_month_card.string), 1000)
                end
            end)

            local totalValue = img.createUISprite(img.ui.gemstore_blue_icon)
            totalValue:setAnchorPoint(ccp(0,0))
            totalValue:setPosition(-2, 45)
            itemBg[pos]:addChild(totalValue, 10000)

            local showTitle = lbl.createFont1(font, titlename, ccc3(0x73, 0x3b, 0x05))
            showTitle:setPosition(itemBg[pos]:getContentSize().width/2 - 25, 270)
            itemBg[pos]:addChild(showTitle)

            if pos == 8 then
                subTitle = showTitle
                local vipgemIcon = img.createItemIcon(ITEM_ID_COIN)
                vipgemIcon:setScale(0.6)
                vipgemIcon:setPosition(35, 42)
                totalValue:addChild(vipgemIcon)
                local vipgemLab = lbl.createFont2(24, string.format("%d%%", cfgstore[id].outputPercent), ccc3(255, 246, 223))
                vipgemLab:setPosition(90, 42)
                totalValue:addChild(vipgemLab)
            else
                local vipgemIcon = img.createItemIcon(ITEM_ID_GEM)
                vipgemIcon:setScale(0.6)
                vipgemIcon:setPosition(35, 42)
                totalValue:addChild(vipgemIcon)
                local vipgemLab = lbl.createFont2(24, cfgstore[id].diamonds+cfgstore[id].dailyGems*cfgstore[id].days, ccc3(255, 246, 223))
                vipgemLab:setPosition(90, 42)
                totalValue:addChild(vipgemLab)
            end

            local totalLab = lbl.createMixFont1(14, totallab, ccc3(0x2a, 0x49, 0x96))
            totalLab:setAnchorPoint(ccp(1, 0))
            totalLab:setPosition(170, 26)
            totalValue:addChild(totalLab)

            local lbl_vip_exp = lbl.createFont1(14, "+" .. scores, ccc3(0x2a, 0x49, 0x96))
            lbl_vip_exp:setAnchorPoint(ccp(1, 0.5))
            lbl_vip_exp:setPosition(CCPoint(170, 20))
            totalValue:addChild(lbl_vip_exp)
            local lbl_vip_des = lbl.createFont1(14, "VIP EXP", ccc3(0x2a, 0x49, 0x96))
            lbl_vip_des:setAnchorPoint(ccp(1,0.5))
            lbl_vip_des:setPosition(CCPoint(lbl_vip_exp:boundingBox():getMidX()-20, 20))
            totalValue:addChild(lbl_vip_des)

            local item_price = cfgstore[id].priceStr 
            if isAmazon() then
            elseif APP_CHANNEL and APP_CHANNEL ~= "" then
                item_price = cfgstore[id].priceCnStr
            elseif i18n.getCurrentLanguage() == kLanguageChinese then
                item_price = cfgstore[id].priceCnStr
            end
            item_price = shop.getPrice(id, item_price)
            local costLab = lbl.createFontTTF(18, item_price, ccc3(0x73, 0x3b, 0x05))
            costLab:setAnchorPoint(ccp(1, 0.5))
            costLab:setPosition(182, 30)
            itemBg[pos]:addChild(costLab)
            --CostLab:setPosition(btnBuySprite:getContentSize().width/2, 
            --                    btnBuySprite:getContentSize().height/2-2)
            --btnBuySprite:addChild(CostLab)
            --btnBuy:setPosition(-160 + btnBuy:getContentSize().width/2 + 224 * cfgstore[pos].rank, btnBuy:getContentSize().height/2+5)
            --btnMenu:addChild(btnBuy)

            --btnBuy:registerScriptTapHandler(function()
            --    audio.play(audio.button)
            --    local cfg = cfgstore[pos]

            --    -- payment
            --    local waitnet = addWaitNet()
            --    waitnet.setTimeout(60)
            --    local iap = require "common.iap"
            --    iap.pay(cfg.payId, function(conquest)
            --        delWaitNet()
            --        if conquest then
            --        tbl2string(conquest)
            --            bag.addGem(conquest.items[2].num)
            --            bag.items.add(conquest.items[1])
                        
            --            if itemBg[pos]:getChildByTag(101) then
            --                itemBg[pos]:removeChildByTag(101)
            --            end
            --            shop.pay[pos] = shop.pay[pos] + 1
            --            specialLayer:removeAllChildrenWithCleanup(true)
            --            createSpecial()
            --            storeBuyLayer:removeAllChildrenWithCleanup()
            --            createBuyLayer()
            --        end
            --    end)
            --end)
            if shop.pay[id] ~= 0 then
                --setShader(itemBg[pos], SHADER_GRAY, true)
                if id ~= 33 then
                    local monblack = img.createUISprite(img.ui.gemstore_monblack)
                    monblack:setAnchorPoint(CCPoint(0, 0))
                    monblack:setPosition(-4, 0)
                    itemBg[pos]:addChild(monblack, 10001)
                    local lbllef1 = lbl.createMixFont1(14, i18n.global.monthcard_left1.string, ccc3(255, 246, 223)) 
                    lbllef1:setAnchorPoint(CCPoint(0, 0.5))
                    lbllef1:setPosition(10, -12)
                    itemBg[pos]:addChild(lbllef1)
                    local lbllef2 = lbl.createMixFont1(14, string.format(i18n.global.monthcard_left2.string, shop.pay[id]), ccc3(0xa5, 0xfd, 0x47)) 
                    lbllef2:setAnchorPoint(CCPoint(0, 0.5))
                    lbllef2:setPosition(lbllef1:boundingBox():getMaxX()+4, -12)
                    itemBg[pos]:addChild(lbllef2)
                else
                    showTitle:setString(i18n.global.activity_des_subed.string) 
                end
                if pos ~= 8 then  
                    if pos == 6 then
                        if shop.pay[32] ~= 0 then
                            itemBg[pos]:setPosition(-190 + 224 * curpos + itemBg[pos]:getContentSize().width/2,
                                                25+itemBg[pos]:getContentSize().height/2)
                        else
                            itemBg[pos]:setPosition(-190 + 224 * (curpos+1) + itemBg[pos]:getContentSize().width/2,
                                                25+itemBg[pos]:getContentSize().height/2)
                        end
                    else
                        itemBg[pos]:setPosition(-190 + 224 * curpos + itemBg[pos]:getContentSize().width/2,
                                             25+itemBg[pos]:getContentSize().height/2)
                    end
                end
            end
        end

        for i=1,itemNum do
            if itemNum == 8 then
                if i ~= itemNum and i ~= itemNum -1 and i ~= itemNum - 2 then
                    createItem(i)
                else
                    createMonth(i)  
                end
            else
                if i ~= itemNum and i ~= itemNum -1 then
                    createItem(i)
                else
                    createMonth(i)  
                end
            end
        end


        --handler
        local clickHandler
        function storeBuyLayer.setClickHandler(h)
            clickHandler = h
        end

        --touch 
        local touchbeginx, touchbeginy
        local isclick
      
        
        --touch 
        local touchbeginx, touchbeginy
        local isclick
        local last_touch_sprite = nil

        local function onTouchBegan(x, y)
            touchbeginx, touchbeginy = x, y
            isclick = true
            local p0 = Scroll:getContainer():convertToNodeSpace(ccp(x, y))
            for _, bg in ipairs(itemBg) do
                local id = _
                if _ == 7 then
                    id = 32
                end
                if _ == 8 then
                    id = 33
                end
                if p0 and bg:boundingBox():containsPoint(p0) then 
                    if itemNum == 8 then
                        if (_ == itemNum-2 or _ == itemNum-1) and shop.pay[id] ~= 0 then
                            isclick = false
                            return true
                        end
                    else
                        if (_ == itemNum-1 or _ == itemNum) and shop.pay[id] ~= 0 then
                            isclick = false
                            return true
                        end
                    end
                    playAnimTouchBegin(itemBg[_])
                    last_touch_sprite = itemBg[_]
                end
            end
            return true
        end

        local function onTouchMoved(x, y)
            local p0 = Scroll:getContainer():convertToNodeSpace(ccp(touchbeginx, y))
            local p1 = Scroll:getContainer():convertToNodeSpace(ccp(x, y))
            if isclick and math.abs(p1.x-p0.x) > 25  then
                isclick = false
                if last_touch_sprite and not tolua.isnull(last_touch_sprite) then
                    playAnimTouchEnd(last_touch_sprite)
                    last_touch_sprite = nil
                end
            end
        end
        
        local function onTouchEnded(x, y)
            if isclick then
                if last_touch_sprite and not tolua.isnull(last_touch_sprite) then
                    playAnimTouchEnd(last_touch_sprite)
                    last_touch_sprite = nil
                end 
                
                local p0 = Scroll:getContainer():convertToNodeSpace(ccp(x,y))
                for ii=1,#itemBg do
                    if itemBg[ii]:boundingBox():containsPoint(p0) then
                        --if clickHandler then
                        --    clickHandler(itemBg[(ii-1)*4+1])
                        --end
                        audio.play(audio.button) 
                        local id = ii
                        if ii == 7 then
                            id = 32
                        end
                        if ii == 8 then
                            id = 33
                        end
                        if itemNum == 8 then
                            if ii == itemNum and shop.pay[id] ~= 0 then
                                showToast(i18n.global.activity_des_subed.string)
                                return true
                            end
                        end
                        local cfg = cfgstore[id]

                        -- payment
                        local function payFunc()
                        local waitnet = addWaitNet()
                        waitnet.setTimeout(60)
                        local iap = require "common.iap"
                        iap.pay(cfg.payId, function(conquest)
                            delWaitNet()

                            local pbbag = {}
                            pbbag.items = {}

                            if conquest then
                                tbl2string(conquest)
                                if conquest.items then
                                    for i = 1,#conquest.items do
                                        if conquest.items[i].id == 2 then
                                            bag.addGem(conquest.items[i].num)
                                            pbbag.items[#pbbag.items+1] = conquest.items[i]
                                        else        
                                            bag.items.add(conquest.items[i])
                                        end
                                    end
                                end
                                if itemBg[ii] and not tolua.isnull(itemBg[ii]) and itemBg[ii]:getChildByTag(101) then
                                    itemBg[ii]:removeChildByTag(101)
                                end
                                if id == 6 or id == 32 or id == 33 then
                                    shop.pay[id] = 29
                                else
                                    shop.pay[id] = shop.pay[id] + 1
                                end
                                if #itemBg == 8 and (ii == #itemBg or ii == #itemBg-1 or ii == #itemBg-2) then
                                    --setShader(itemBg[ii], SHADER_GRAY, true)
                                    if id ~= 33 then
                                        local monblack = img.createUISprite(img.ui.gemstore_monblack)
                                        monblack:setAnchorPoint(CCPoint(0, 0))
                                        monblack:setPosition(-4, 0)
                                        itemBg[ii]:addChild(monblack, 10001)
                                        local lbllef1 = lbl.createMixFont1(14, i18n.global.monthcard_left1.string, ccc3(255, 246, 223)) 
                                        lbllef1:setAnchorPoint(CCPoint(0, 0.5))
                                        lbllef1:setPosition(10, -12)
                                        itemBg[ii]:addChild(lbllef1)
                                        local lbllef2 = lbl.createMixFont1(14, string.format(i18n.global.monthcard_left2.string, shop.pay[id]), ccc3(0xa5, 0xfd, 0x47)) 
                                        lbllef2:setAnchorPoint(CCPoint(0, 0.5))
                                        lbllef2:setPosition(lbllef1:boundingBox():getMaxX()+4, -12)
                                        itemBg[ii]:addChild(lbllef2)
                                    else
                                        shop.addSubHead()
                                        subTitle:setString(i18n.global.activity_des_subed.string) 
                                    end
                                end
                                if #itemBg == 7 and (ii == #itemBg or ii == #itemBg-1) then
                                    local monblack = img.createUISprite(img.ui.gemstore_monblack)
                                    monblack:setAnchorPoint(CCPoint(0, 0))
                                    monblack:setPosition(-4, 0)
                                    itemBg[ii]:addChild(monblack, 10001)
                                    local lbllef1 = lbl.createMixFont1(14, i18n.global.monthcard_left1.string, ccc3(255, 246, 223)) 
                                    lbllef1:setAnchorPoint(CCPoint(0, 0.5))
                                    lbllef1:setPosition(10, -12)
                                    itemBg[ii]:addChild(lbllef1)
                                    local lbllef2 = lbl.createMixFont1(14, string.format(i18n.global.monthcard_left2.string, shop.pay[id]), ccc3(0xa5, 0xfd, 0x47)) 
                                    lbllef2:setAnchorPoint(CCPoint(0, 0.5))
                                    lbllef2:setPosition(lbllef1:boundingBox():getMaxX()+4, -12)
                                    itemBg[ii]:addChild(lbllef2)
                                end
                                specialLayer:removeAllChildrenWithCleanup(true)
                                createSpecial()
                                local curpos = 0
                                if itemNum == 8 then
                                    curpos = 1
                                end
                                if id == 6 or id == 32 then
                                    if shop.pay[6] ~= 0 and shop.pay[32] ~= 0 then
                                        for i = 1,#itemBg do
                                            if i == 8 then 
                                                itemBg[i]:setPosition(-190 + 224+itemBg[i]:getContentSize().width/2,
                                                                        25+itemBg[i]:getContentSize().height/2)
                                            else
                                                itemBg[i]:setPosition(-190 + 224*(i+curpos)+itemBg[i]:getContentSize().width/2,
                                                                        25+itemBg[i]:getContentSize().height/2)
                                            end
                                        end
                                    end
                                    if shop.pay[6] == 0 and shop.pay[32] ~= 0 then
                                        for i = 1,#itemBg do
                                            if i == 6 then
                                                itemBg[i]:setPosition(-190 + 224 + itemBg[i]:getContentSize().width/2,
                                                                        25+itemBg[i]:getContentSize().height/2)
                                            elseif i == 7 then
                                                itemBg[i]:setPosition(-190 + 224*(7+curpos) + itemBg[i]:getContentSize().width/2,
                                                                        25+itemBg[i]:getContentSize().height/2)
                                            elseif i == 8 then
                                                itemBg[i]:setPosition(-190 + 224*2 + itemBg[i]:getContentSize().width/2,
                                                                        25+itemBg[i]:getContentSize().height/2)
                                            else
                                                itemBg[i]:setPosition(-190 + 224 * (i+1+curpos) +itemBg[i]:getContentSize().width/2,
                                                                        25+itemBg[i]:getContentSize().height/2)
                                            end
                                        end
                                    end
                                    if shop.pay[6] ~= 0 and shop.pay[32] == 0 then
                                        for i = 1,#itemBg do
                                            if i == 7 then
                                                itemBg[i]:setPosition(-190 + 224 + itemBg[i]:getContentSize().width/2,
                                                                        25+itemBg[i]:getContentSize().height/2)
                                            elseif i == 6 then
                                                itemBg[i]:setPosition(-190 + 224*(7+curpos) + itemBg[i]:getContentSize().width/2,
                                                                        25+itemBg[i]:getContentSize().height/2)
                                            elseif i == 8 then
                                                itemBg[i]:setPosition(-190 + 224*2 + itemBg[i]:getContentSize().width/2,
                                                                        25+itemBg[i]:getContentSize().height/2)
                                            else
                                                itemBg[i]:setPosition(-190 + 224 * (i+1+curpos) +itemBg[i]:getContentSize().width/2,
                                                                        25+itemBg[i]:getContentSize().height/2)
                                            end
                                        end
                                    end
                                end
                            end
                            local rewardlayer = reward.createFloating(pbbag, 1000)
                            if layer and not tolua.isnull(layer) then
                                layer:addChild(rewardlayer, 1000)
                            end
                        end)
                        end
                        if id ~= 33 then
                            payFunc()
                        elseif device.platform == "ios" then
                            --local payConfirm = require"ui.payConfirm"
                            --layer:addChild(payConfirm.create(string.format(i18n.global.help_sub_card.string, cfg.priceStr), i18n.global.activity_des_sub.string, payFunc), 1000)
                            local subscribe = require"ui.shop.subscribe"
                            layer:addChild(subscribe.create(), 1000)
                        else
                            --local payConfirm = require"ui.payConfirm"
                            --layer:addChild(payConfirm.create(string.format(i18n.global.help_sub_card.string, cfg.priceStr), i18n.global.activity_des_sub.string, payFunc), 1000)
                            payFunc()
                        end
                        break
                    end
                end
            end
        end

        local function onTouch(eventType, x, y)
            if eventType == "began" then
                return onTouchBegan(x, y)
            elseif eventType == "moved" then
                return onTouchMoved(x, y)
            else
                return onTouchEnded(x, y)
            end
        end
       
        storeBuyLayer:registerScriptTouchHandler(onTouch , false , -128 , false)
        storeBuyLayer:setTouchEnabled(true)
    end

    --VIP PREROGATIVE
    local function createPropertyLayer()
        local infoVipLv = player.vipLv()
        local createVIPinfo = nil

        if infoVipLv == 0 then
            infoVipLv = 1
        end

        local leftDecorBg = img.createUISprite(img.ui.gemstore_decoration)
        leftDecorBg:setAnchorPoint(ccp(0, 1))
        leftDecorBg:setPosition(16, 547-157)
        propertyLayer:addChild(leftDecorBg)

        local rightDecorBg = img.createUISprite(img.ui.gemstore_decoration)
        rightDecorBg:setAnchorPoint(ccp(1, 1))
        rightDecorBg:setPosition(896-50, 547-157)
        rightDecorBg:setFlipX(true)
        propertyLayer:addChild(rightDecorBg)

        local propertyBg = img.createUI9Sprite(img.ui.vip_paper)
        propertyBg:setPreferredSize(CCSize(580, 345))
        propertyBg:setPosition(board:getContentSize().width/2,202)
        propertyLayer:addChild(propertyBg)

        local lefMenu = CCMenu:create()
        lefMenu:setPosition(0,0)
        propertyLayer:addChild(lefMenu)

        local lefBtnSprite = img.createUISprite(img.ui.gemstore_next_icon1)
        local lefBtn = HHMenuItem:create(lefBtnSprite)
        lefBtn:setScale(-1)
        lefBtn:setPosition(85,215)
        lefMenu:addChild(lefBtn)
        lefBtn:registerScriptTapHandler(function()
            if infoVipLv > 1 then
                infoVipLv = infoVipLv - 1
            end
            createVIPinfo(infoVipLv)
            audio.play(audio.button)
        end)

        local rigMenu = CCMenu:create()
        rigMenu:setPosition(0,0)
        propertyLayer:addChild(rigMenu)
        local rigBtnSprite = img.createUISprite(img.ui.gemstore_next_icon1)
        local rigBtn = HHMenuItem:create(rigBtnSprite)
        rigBtn:setPosition(780,215)
        rigMenu:addChild(rigBtn)
        rigBtn:registerScriptTapHandler(function()
            if infoVipLv < #cfgvip then
                infoVipLv = infoVipLv + 1
            end
            createVIPinfo(infoVipLv)
            audio.play(audio.button)
        end)

        --local titleBg = img.createUISprite(img.ui.arena_titlebg)

        --local vipIcon = img.createUISprite(img.ui.main_vip_bg)
        --vipIcon:setPosition(CCPoint(propertyBg:getContentSize().width/2 - 50, 
        --                            propertyBg:getContentSize().height - 30))
        --propertyBg:addChild(vipIcon)
        
        --local vipLvLab = lbl.createFont2(16, "VIP8", ccc3(0xff, 0xdc, 0x82))
        --vipLvLab:setPosition(vipIcon:getContentSize().width/2,
        --                        vipIcon:getContentSize().height/2)
        --vipIcon:addChild(vipLvLab)
        json.load(json.ui.ic_vip)
        local vip_bg = CCSprite:create()
        vip_bg:setContentSize(CCSizeMake(58, 58))
        vip_bg:setScale(0.7)
        --vip_bg:setAnchorPoint(ccp(0, 0.5))
        vip_bg:setPosition(CCPoint(propertyBg:getContentSize().width/2 - 50, 
                            propertyBg:getContentSize().height - 33))
        propertyBg:addChild(vip_bg)
        local ic_vip = DHSkeletonAnimation:createWithKey(json.ui.ic_vip)
        ic_vip:scheduleUpdateLua()
        ic_vip:playAnimation("" .. vip_a[8], -1)
        ic_vip:setPosition(CCPoint(29, 29))
        vip_bg:addChild(ic_vip)
        local useless_node = CCNode:create()
        local lbl_player_vip = lbl.createFont2(18, 8, ccc3(0xff, 0xdc, 0x82))
        lbl_player_vip:setColor(vip_c[8])
        useless_node:addChild(lbl_player_vip)
        ic_vip:addChildFollowSlot("code_num", useless_node)

        local  provilegeLab = lbl.createFont1(22, i18n.global.shop_privilege.string, ccc3(0x51, 0x27 , 0x12))
        provilegeLab:setAnchorPoint(0, 0.5)
        provilegeLab:setPosition(vip_bg:boundingBox():getMaxX()+5,
                                    propertyBg:getContentSize().height - 33)
        propertyBg:addChild(provilegeLab)

        local line = img.createUI9Sprite(img.ui.gemstore_fgline)
        line:setPreferredSize(CCSize(530, 2))
        line:setPosition(CCPoint(propertyBg:getContentSize().width/2, 
                                    propertyBg:getContentSize().height - 60))
        propertyBg:addChild(line)
            
        local KSCROLL_CONTAINER_SIZE = math.max(10 * 33 + 15,280)

        local Kscroll = CCScrollView:create()
        Kscroll:setDirection(kCCScrollViewDirectionVertical)
        Kscroll:setAnchorPoint(ccp(0, 0))
        Kscroll:setPosition(40,18)
        Kscroll:setViewSize(CCSize(650,260))
        Kscroll:setContentSize(CCSize(650,KSCROLL_CONTAINER_SIZE))
        propertyBg:addChild(Kscroll)
        local function onKScroll()
            if Kscroll:getContainer():getPositionY() > 0 then
                 Kscroll:getContainer():setPositionY(0)
            end
            if Kscroll:getContainer():getPositionY() < 300 - KSCROLL_CONTAINER_SIZE then
                Kscroll:getContainer():setPositionY(300 - KSCROLL_CONTAINER_SIZE )
            end
        end
        Kscroll:registerScriptHandler(onKScroll, CCScrollView.kScrollViewScroll)
        Kscroll:setContentOffset(ccp(0,300 - KSCROLL_CONTAINER_SIZE))

        function createVIPinfo(viplv)
            Kscroll:getContainer():removeAllChildrenWithCleanup(true)
            ic_vip:stopAnimation()
            ic_vip:playAnimation("" .. vip_a[viplv], -1)
            lbl_player_vip:setString(viplv)
            lbl_player_vip:setColor(vip_c[viplv])

            if viplv <= 1 then
                lefBtn:setVisible(false)
            else
                lefBtn:setVisible(true)
            end

            if viplv == #cfgvip then
                rigBtn:setVisible(false)
            else
                rigBtn:setVisible(true)
            end
            
            local prolab = {}
            local idx = 1
            local offsetY = 30 

            if cfgvip[viplv].speed and cfgvip[viplv].speed > 1 then
                local circle = img.createUISprite(img.ui.gemstore_point)
                circle:setAnchorPoint(ccp(0, 0))
                circle:setPosition(5, offsetY+6)
                Kscroll:addChild(circle)

                local str = i18n.vipdes.dareTime.string1 .. " "
                --prolab[idx] = lbl.createMixFont1(18, str, ccc3(0x51, 0x27 , 0x12))
                prolab[idx] = lbl.createMix({
                    font = 1, size = 18, text = str, color = ccc3(0x51, 0x27 , 0x12),
                    fr = { size = 14}, es = { size = 14 }, pt = { size = 14 }, jp = {size = 14}
                })
                prolab[idx]:setPosition(20,offsetY)
                prolab[idx]:setAnchorPoint(ccp(0,0))
                Kscroll:addChild(prolab[idx])
                local contentlab = lbl.createMixFont1(18, string.format(i18n.vipdes.dareTime.string2, cfgvip[viplv].dareTime), ccc3(0xae, 0x49, 0x21))
                contentlab:setAnchorPoint(ccp(0,0.5))
                contentlab:setPosition(prolab[idx]:boundingBox():getMaxX(),prolab[idx]:getPositionY())
                Kscroll:addChild(contentlab)
                idx = idx + 1
                offsetY = offsetY + 30
            end
            
            if cfgvip[viplv].speed and cfgvip[viplv].speed > 1 then
                local circle = img.createUISprite(img.ui.gemstore_point)
                circle:setAnchorPoint(ccp(0, 0))
                circle:setPosition(5, offsetY+6)
                Kscroll:addChild(circle)

                local str = i18n.vipdes.speed2.string1 .. ""
                --prolab[idx] = lbl.createMixFont1(18, str, ccc3(0x51, 0x27 , 0x12))
                prolab[idx] = lbl.createMix({
                    font = 1, size = 18, text = str, color = ccc3(0x51, 0x27 , 0x12),
                    fr = { size = 14}, es = { size = 14 }, pt = { size = 14 }, jp = {size = 14}
                })
                prolab[idx]:setPosition(20,offsetY)
                prolab[idx]:setAnchorPoint(ccp(0,0))
                Kscroll:addChild(prolab[idx])
                idx = idx + 1
                offsetY = offsetY + 30
            end

            if cfgvip[viplv].heroTask and cfgvip[viplv].heroTask > 0 then
                local circle = img.createUISprite(img.ui.gemstore_point)
                circle:setAnchorPoint(ccp(0, 0))
                circle:setPosition(5, offsetY+6)
                Kscroll:addChild(circle)
                local str = i18n.vipdes.heroTaskMax.string1 .. " "
                --prolab[idx] = lbl.createMixFont1(18, str, ccc3(0x51, 0x27 , 0x12))
                prolab[idx] = lbl.createMix({
                    font = 1, size = 18, text = str, color = ccc3(0x51, 0x27 , 0x12),
                    fr = { size = 14}, es = { size = 14 }, pt = { size = 14 }, jp = {size = 14}
                })
                prolab[idx]:setPosition(20,offsetY)
                prolab[idx]:setAnchorPoint(ccp(0,0))
                Kscroll:addChild(prolab[idx])
                local contentlab = lbl.createMixFont1(18, string.format(i18n.vipdes.heroTaskMax.string2, cfgvip[viplv].heroTask), ccc3(0xae, 0x49, 0x21))
                contentlab:setAnchorPoint(ccp(0,0.5))
                contentlab:setPosition(prolab[idx]:boundingBox():getMaxX(),prolab[idx]:getPositionY())
                Kscroll:addChild(contentlab)
                idx = idx + 1
                offsetY = offsetY + 30
            end

            if cfgvip[viplv].hook and cfgvip[viplv].hook > 0 then
                --local circle = lbl.createFont1(18, "●", ccc3(0x51, 0x27 , 0x12))
                --circle:setAnchorPoint(ccp(0,0))
                --circle:setPosition(20, offsetY)
                --Kscroll:addChild(circle)
                local circle = img.createUISprite(img.ui.gemstore_point)
                circle:setAnchorPoint(ccp(0, 0))
                circle:setPosition(5, offsetY+6)
                Kscroll:addChild(circle)
                local str = i18n.vipdes.hookVip.string1 .. " "
                --prolab[idx] = lbl.createMixFont1(18, str, ccc3(0x51, 0x27 , 0x12))
                prolab[idx] = lbl.createMix({
                    font = 1, size = 18, text = str, color = ccc3(0x51, 0x27 , 0x12),
                    fr = { size = 14}, es = { size = 14 }, pt = { size = 14 }, jp = {size = 14}
                })
                prolab[idx]:setPosition(20, offsetY)
                prolab[idx]:setAnchorPoint(ccp(0,0))
                Kscroll:addChild(prolab[idx])
                local contentlab = lbl.createMixFont1(18, string.format(i18n.vipdes.hookVip.string2 .. "%%", cfgvip[viplv].hook*100), ccc3(0xae, 0x49, 0x21))
                contentlab:setAnchorPoint(ccp(0,0.5))
                contentlab:setPosition(prolab[idx]:boundingBox():getMaxX(), offsetY)
                Kscroll:addChild(contentlab)
                idx = idx + 1
                offsetY = offsetY + 30
            end

            if cfgvip[viplv].midas and cfgvip[viplv].midas > 0 then
                local circle = img.createUISprite(img.ui.gemstore_point)
                circle:setAnchorPoint(ccp(0, 0))
                circle:setPosition(5, offsetY+6)
                Kscroll:addChild(circle)
                local str = i18n.vipdes.midasVip.string1 .. " "
                --prolab[idx] = lbl.createMixFont1(18, str, ccc3(0x51, 0x27 , 0x12))
                prolab[idx] = lbl.createMix({
                    font = 1, size = 18, text = str, color = ccc3(0x51, 0x27 , 0x12),
                    fr = { size = 14}, es = { size = 14 }, pt = { size = 14 }, jp = {size = 14}
                })
                prolab[idx]:setPosition(20, offsetY)
                prolab[idx]:setAnchorPoint(ccp(0,0))
                Kscroll:addChild(prolab[idx])
                local contentlab = lbl.createMixFont1(18, string.format(i18n.vipdes.midasVip.string2 .. "%%", cfgvip[viplv].midas*100), ccc3(0xae, 0x49, 0x21))
                contentlab:setPosition(prolab[idx]:boundingBox():getMaxX(), offsetY)
                contentlab:setAnchorPoint(ccp(0,0))
                Kscroll:addChild(contentlab)
                idx = idx + 1
                offsetY = offsetY + 30
            end

            if cfgvip[viplv].heroes and cfgvip[viplv].heroes > 0 then
                --local circle = lbl.createFont1(18, "●", ccc3(0x51, 0x27 , 0x12))
                --circle:setAnchorPoint(ccp(0,0))
                --circle:setPosition(20, offsetY)
                --Kscroll:addChild(circle)
                local circle = img.createUISprite(img.ui.gemstore_point)
                circle:setAnchorPoint(ccp(0, 0))
                circle:setPosition(5, offsetY+6)
                Kscroll:addChild(circle)
                local str = i18n.vipdes.heroLimit.string1 .. " "
                --prolab[idx] = lbl.createMixFont1(18, str, ccc3(0x51, 0x27 , 0x12))
                prolab[idx] = lbl.createMix({
                    font = 1, size = 18, text = str, color = ccc3(0x51, 0x27 , 0x12),
                    fr = { size = 14}, es = { size = 14 }, pt = { size = 14 }, jp = {size = 14}
                })
                prolab[idx]:setPosition(20,offsetY)
                prolab[idx]:setAnchorPoint(ccp(0,0))
                Kscroll:addChild(prolab[idx])
                local contentlab = lbl.createMixFont1(18, string.format(i18n.vipdes.heroLimit.string2, cfgvip[viplv].heroes-cfgvip[viplv-1].heroes), ccc3(0xae, 0x49 , 0x21))
                contentlab:setAnchorPoint(ccp(0,0.5))
                contentlab:setPosition(prolab[idx]:boundingBox():getMaxX(),prolab[idx]:getPositionY())
                Kscroll:addChild(contentlab)
                idx = idx + 1
                offsetY = offsetY + 30
            end

            if cfgvip[viplv].gamble and cfgvip[viplv].gamble > 0 then
                local circle = img.createUISprite(img.ui.gemstore_point)
                circle:setAnchorPoint(ccp(0, 0))
                circle:setPosition(5, offsetY+6)
                Kscroll:addChild(circle)
                local str = i18n.vipdes.gamble10.string1 .. ""
                --prolab[idx] = lbl.createMixFont1(18, str, ccc3(0x51, 0x27 , 0x12))
                prolab[idx] = lbl.createMix({
                    font = 1, size = 18, text = str, color = ccc3(0x51, 0x27 , 0x12),
                    fr = { size = 14}, es = { size = 14 }, pt = { size = 14 }, jp = {size = 14}
                })
                prolab[idx]:setPosition(20,offsetY)
                prolab[idx]:setAnchorPoint(ccp(0,0))
                Kscroll:addChild(prolab[idx])
                idx = idx + 1
                offsetY = offsetY + 30
            end

            if cfgvip[viplv].gacha and cfgvip[viplv].gacha > 0 then
                local circle = img.createUISprite(img.ui.gemstore_point)
                circle:setAnchorPoint(ccp(0, 0))
                circle:setPosition(5, offsetY+6)
                Kscroll:addChild(circle)
                local str = i18n.vipdes.gachaPower.string1 .. ""
                --prolab[idx] = lbl.createMixFont1(18, str, ccc3(0x51, 0x27 , 0x12))
                prolab[idx] = lbl.createMix({
                    font = 1, size = 18, text = str, color = ccc3(0x51, 0x27 , 0x12),
                    fr = { size = 14}, es = { size = 14 }, pt = { size = 14 }, jp = {size = 14}
                })
                prolab[idx]:setPosition(20,offsetY)
                prolab[idx]:setAnchorPoint(ccp(0,0))
                Kscroll:addChild(prolab[idx])
                idx = idx + 1
                offsetY = offsetY + 30
            end

            if cfgvip[viplv].monthCard then
                if cfgvip[viplv].monthCard[1] then
                    local iconId = cfgvip[viplv].monthCard[1].id
                    local iconNum = cfgvip[viplv].monthCard[1].num
                    local icon = nil
                    if cfgvip[viplv].monthCard[1].type == 1 then
                        icon = img.createItem(iconId, iconNum)
                    else
                        icon = img.createEquip(iconId, iconNum)
                    end

                    local monthCardIcon = CCMenuItemSprite:create(icon, nil)
                    monthCardIcon:setScale(0.7)
                    monthCardIcon:setAnchorPoint(ccp(0,0))
                    monthCardIcon:setPosition(20, offsetY)
                    local monthCardmenu = CCMenu:createWithItem(monthCardIcon)
                    monthCardmenu:setPosition(0,0)
                    Kscroll:addChild(monthCardmenu)

                    monthCardIcon:registerScriptTapHandler(function()
                        audio.play(audio.button)
                        if not layer.tipsTag then
                            layer.tipsTag = true
                            if cfgvip[viplv].monthCard[1].type == 1 then
                                layer.tips = tipsitem.createForShow({id = iconId})
                            else
                                layer.tips = tipsequip.createForShow({id = iconId})
                            end
                            layer:addChild(layer.tips, 100)
                            layer.tips.setClickBlankHandler(function()
                                layer.tipsTag = false
                                layer.tips:removeFromParent()
                            end)
                        end
                    end)
                end

                if cfgvip[viplv].monthCard[2] then
                    local iconId = cfgvip[viplv].monthCard[2].id
                    local iconNum = cfgvip[viplv].monthCard[2].num
                    local icon = nil
                    if cfgvip[viplv].monthCard[2].type == 1 then
                        icon = img.createItem(iconId, iconNum)
                    else
                        icon = img.createEquip(iconId, iconNum)
                    end

                    local monthCardIcon = CCMenuItemSprite:create(icon, nil)
                    monthCardIcon:setScale(0.7)
                    monthCardIcon:setAnchorPoint(ccp(0,0))
                    monthCardIcon:setPosition(90, offsetY)
                    local monthCardmenu = CCMenu:createWithItem(monthCardIcon)
                    monthCardmenu:setPosition(0,0)
                    Kscroll:addChild(monthCardmenu)

                    monthCardIcon:registerScriptTapHandler(function()
                        audio.play(audio.button)
                        if not layer.tipsTag then
                            layer.tipsTag = true
                            if cfgvip[viplv].monthCard[2].type == 1 then
                                layer.tips = tipsitem.createForShow({id = iconId})
                            else
                                layer.tips = tipsequip.createForShow({id = iconId})
                            end
                            layer:addChild(layer.tips, 100)
                            layer.tips.setClickBlankHandler(function()
                                layer.tipsTag = false
                                layer.tips:removeFromParent()
                            end)
                        end
                    end)
                end
                if cfgvip[viplv].monthCard[3] then
                    local iconId = cfgvip[viplv].monthCard[3].id
                    local iconNum = cfgvip[viplv].monthCard[3].num
                    local icon = nil
                    if cfgvip[viplv].monthCard[3].type == 1 then
                        icon = img.createItem(iconId, iconNum)
                    else
                        icon = img.createEquip(iconId, iconNum)
                    end

                    local monthCardIcon = CCMenuItemSprite:create(icon, nil)
                    monthCardIcon:setScale(0.7)
                    monthCardIcon:setAnchorPoint(ccp(0,0))
                    monthCardIcon:setPosition(160, offsetY)
                    local monthCardmenu = CCMenu:createWithItem(monthCardIcon)
                    monthCardmenu:setPosition(0,0)
                    Kscroll:addChild(monthCardmenu)

                    monthCardIcon:registerScriptTapHandler(function()
                        audio.play(audio.button)
                        if not layer.tipsTag then
                            layer.tipsTag = true
                            if cfgvip[viplv].monthCard[3].type == 1 then
                                layer.tips = tipsitem.createForShow({id = iconId})
                            else
                                layer.tips = tipsequip.createForShow({id = iconId})
                            end
                            layer:addChild(layer.tips, 100)
                            layer.tips.setClickBlankHandler(function()
                                layer.tipsTag = false
                                layer.tips:removeFromParent()
                            end)
                        end
                    end)
                end
                idx = idx + 2
                offsetY = offsetY + 60
                local circle = img.createUISprite(img.ui.gemstore_point)
                circle:setAnchorPoint(ccp(0, 0))
                circle:setPosition(5, offsetY+6)
                Kscroll:addChild(circle)
                local str = i18n.vipdes.vipMouth.string1 .. " "
                --prolab[idx] = lbl.createMixFont1(18, str, ccc3(0x51, 0x27 , 0x12))
                prolab[idx] = lbl.createMix({
                    font = 1, size = 18, text = str, color = ccc3(0x51, 0x27 , 0x12),
                    fr = { size = 14}, es = { size = 14 }, pt = { size = 14 }, jp = {size = 14}
                })
                prolab[idx]:setPosition(20,offsetY)
                prolab[idx]:setAnchorPoint(ccp(0,0))
                Kscroll:addChild(prolab[idx])

                idx = idx + 1
                offsetY = offsetY + 30
            end

            if false then
                if cfgvip[viplv].vipRewards[1] then
                    local iconId = cfgvip[viplv].vipRewards[1].id
                    local iconNum = cfgvip[viplv].vipRewards[1].num
                    local icon = nil
                    if cfgvip[viplv].vipRewards[1].type == 1 then
                        icon = img.createItem(iconId, iconNum)
                    else
                        icon = img.createEquip(iconId, iconNum)
                    end

                    local rewardIcon = CCMenuItemSprite:create(icon, nil)
                    rewardIcon:setScale(0.7)
                    rewardIcon:setAnchorPoint(ccp(0,0))
                    rewardIcon:setPosition(20, offsetY)
                    local rewardmenu = CCMenu:createWithItem(rewardIcon)
                    rewardmenu:setPosition(0,0)
                    Kscroll:addChild(rewardmenu)

                    rewardIcon:registerScriptTapHandler(function()
                        audio.play(audio.button)
                        if not layer.tipsTag then
                            layer.tipsTag = true
                            if cfgvip[viplv].vipRewards[1].type == 1 then
                                layer.tips = tipsitem.createForShow({id = iconId})
                            else
                                layer.tips = tipsequip.createForShow({id = iconId})
                            end
                            layer:addChild(layer.tips, 100)
                            layer.tips.setClickBlankHandler(function()
                                layer.tipsTag = false
                                layer.tips:removeFromParent()
                            end)
                        end
                    end)
                end
                if cfgvip[viplv].vipRewards[2] then
                    local iconId = cfgvip[viplv].vipRewards[2].id
                    local iconNum = cfgvip[viplv].vipRewards[2].num
                    local icon = nil
                    if cfgvip[viplv].vipRewards[2].type == 1 then
                        icon = img.createItem(iconId, iconNum)
                    else
                        icon = img.createEquip(iconId, iconNum)
                    end

                    local rewardIcon = CCMenuItemSprite:create(icon, nil)
                    rewardIcon:setScale(0.7)
                    rewardIcon:setAnchorPoint(ccp(0,0))
                    rewardIcon:setPosition(90, offsetY)
                    local rewardmenu = CCMenu:createWithItem(rewardIcon)
                    rewardmenu:setPosition(0,0)
                    Kscroll:addChild(rewardmenu)

                    rewardIcon:registerScriptTapHandler(function()
                        audio.play(audio.button)
                        if not layer.tipsTag then
                            layer.tipsTag = true
                            if cfgvip[viplv].vipRewards[2].type == 1 then
                                layer.tips = tipsitem.createForShow({id = iconId})
                            else
                                layer.tips = tipsequip.createForShow({id = iconId})
                            end
                            layer:addChild(layer.tips, 100)
                            layer.tips.setClickBlankHandler(function()
                                layer.tipsTag = false
                                layer.tips:removeFromParent()
                            end)
                        end
                    end)
                end
                idx = idx + 2
                offsetY = offsetY + 60
                local circle = img.createUISprite(img.ui.gemstore_point)
                circle:setAnchorPoint(ccp(0, 0))
                circle:setPosition(5, offsetY+6)
                Kscroll:addChild(circle)
                
                local str = i18n.vipdes.vipRewards.string1 .. " "
                --prolab[idx] = lbl.createMixFont1(18, str, ccc3(0x51, 0x27 , 0x12))
                prolab[idx] = lbl.createMix({
                    font = 1, size = 18, text = str, color = ccc3(0x51, 0x27 , 0x12),
                    fr = { size = 14}, es = { size = 14 }, pt = { size = 14 }, jp = {size = 14}
                })
                prolab[idx]:setPosition(20,offsetY)
                prolab[idx]:setAnchorPoint(ccp(0,0))
                Kscroll:addChild(prolab[idx])

                idx = idx + 1
                offsetY = offsetY + 30
            end

            KSCROLL_CONTAINER_SIZE = idx * 33

            if idx == 14 then
                KSCROLL_CONTAINER_SIZE = idx * 33 + 3
            end
            if idx == 11 then
                KSCROLL_CONTAINER_SIZE = idx * 33 + 9
            end
            if idx == 10 then
                KSCROLL_CONTAINER_SIZE = idx * 33 + 15
            end
            if idx == 2 then
                KSCROLL_CONTAINER_SIZE = idx * 33 + 36
            end
            Kscroll:setContentSize(CCSize(650, KSCROLL_CONTAINER_SIZE))
            Kscroll:setContentOffset(ccp(0, 300 - KSCROLL_CONTAINER_SIZE))
        end
        createVIPinfo(infoVipLv)
    end

    --createBuyLayer()
    createPropertyLayer()
    local show = 1 -- store 1 property 2
    btnPay:registerScriptTapHandler(function()
        audio.play(audio.button)
        if show == 1 then
            storeBuyLayer:setVisible(false)
            --storeBuyLayer = nil
            propertyLayer:setVisible(true)
            --board:addChild(propertyLayer)
            --createPropertyLayer()
            labPay:setString(i18n.global.shop_enter.string)
            show = 2
            shopType = "vip"
        else
            propertyLayer:setVisible(false)
            --propertyLayer = nil
            storeBuyLayer:setVisible(true)
            --board:addChild(storeBuyLayer)
            --createBuyLayer()
            labPay:setString(i18n.global.shop_privilege.string)
            show = 1
            shopType = "gem"
        end
    end)
    -- close btn
    local close0 = img.createUISprite(img.ui.close)
    local closeBtn = SpineMenuItem:create(json.ui.button, close0)
    closeBtn:setPosition(CCPoint(880 - 40, 545 - 60))
    local closeMenu = CCMenu:createWithItem(closeBtn)
    closeMenu:setPosition(CCPoint(0, 0))
    board:addChild(closeMenu)
    closeBtn:registerScriptTapHandler(function()     
        audio.play(audio.button)
        layer:removeFromParentAndCleanup(true)
    end)

    function layer.onAndroidBack()
        audio.play(audio.button)
        layer:removeFromParentAndCleanup(true)
    end

    addBackEvent(layer)

    local function onEnter()
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

    layer:setTouchEnabled(true)

    return layer
end

return ui
