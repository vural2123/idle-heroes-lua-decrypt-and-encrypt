local ui = {}

require "common.func"

local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local audio = require "res.audio"
local i18n = require "res.i18n"
local bag = require "data.bag"
local net = require "net.netClient"
local player = require "data.player"
local guildmill = require "data.guildmill"
local cfgmilllv = require "config.milllv"

local DONATECOIN = 100000

function ui.create()
    local layer = CCLayer:create()
    
    -- title
    local title = lbl.createFont1(24, i18n.global.gmill_upmill_title.string, ccc3(0xe6, 0xd0, 0xae))
    title:setPosition(CCPoint(360, 492))
    layer:addChild(title, 1)
    local title_shadowD = lbl.createFont1(24, i18n.global.gmill_upmill_title.string, ccc3(0x59, 0x30, 0x1b))
    title_shadowD:setPosition(CCPoint(360, 490))
    layer:addChild(title_shadowD)

    --local donateInfo = img.createUISprite(img.ui.guild_mill_btn_record)
    --local donateInfoBtn = SpineMenuItem:create(json.ui.button, donateInfo)
    --donateInfoBtn:setPosition(CCPoint(642, 404))
    --local donateInfoMenu = CCMenu:createWithItem(donateInfoBtn)
    --donateInfoMenu:setPosition(0,0)
    --layer:addChild(donateInfoMenu)

    --donateInfoBtn:registerScriptTapHandler(function()
    --    audio.play(audio.button) 
    --    local drecord = require "ui.guildmill.drecord"
    --    layer:getParent():getParent():addChild(drecord.create(), 10000)
    --end)

    local coinprobg = img.createUI9Sprite(img.ui.guild_mill_coinprobg)
    coinprobg:setPreferredSize(CCSizeMake(440, 22))
    coinprobg:setPosition(360, 414)
    layer:addChild(coinprobg)

    local progress0 = img.createUISprite(img.ui.guild_mill_coinpro)
    local coinProgress = createProgressBar(progress0)
    coinProgress:setPosition(coinprobg:getContentSize().width/2, coinprobg:getContentSize().height/2+1)
    coinProgress:setPercentage(0)
    coinprobg:addChild(coinProgress)
    
    local mcIcon = img.createItemIcon2(ITEM_ID_COIN)
    mcIcon:setScale(0.9)
    mcIcon:setPosition(CCPoint(coinprobg:getContentSize().width/2-40, coinprobg:getContentSize().height/2+7))
    coinprobg:addChild(mcIcon)

    local progressLabel = lbl.createFont2(15, i18n.global.gmill_mill_leveltop.string, ccc3(255, 246, 223))
    progressLabel:setAnchorPoint(0, 0.5)
    progressLabel:setPosition(CCPoint(mcIcon:boundingBox():getMaxX()+5,
                                    coinprobg:getContentSize().height/2+7))
    coinprobg:addChild(progressLabel)


    local milllayer = nil
    local donateBtn1 = nil
    local donateBtn10 = nil

    local function createmill(level, coin)
        local curlayer = CCLayer:create()
    
        if level == #cfgmilllv and coin + 1000000 > cfgmilllv[#cfgmilllv].gold then
            donateBtn10:setEnabled(false)
            setShader(donateBtn10, SHADER_GRAY, true)
        end

        if level ~= #cfgmilllv then 
            progressLabel:setString(num2KM(coin).. "/" .. num2KM(cfgmilllv[level+1].gold))
            coinProgress:setPercentage(coin/cfgmilllv[level+1].gold*100)
            local lnpcboard = img.createUI9Sprite(img.ui.botton_fram_4)
            lnpcboard:setPreferredSize(CCSizeMake(285, 202))
            lnpcboard:setAnchorPoint(CCPoint(0, 0))
            lnpcboard:setPosition(50, 188)
            curlayer:addChild(lnpcboard)

            local rnpcboard = img.createUI9Sprite(img.ui.botton_fram_2)
            rnpcboard:setPreferredSize(CCSizeMake(285, 202))
            rnpcboard:setAnchorPoint(CCPoint(0, 0))
            rnpcboard:setPosition(54+328, 188)
            curlayer:addChild(rnpcboard)
        else
            progressLabel:setString(num2KM(cfgmilllv[level].gold).. "/" .. num2KM(cfgmilllv[level].gold))
            coinProgress:setPercentage(100)
            local npcboard = img.createUI9Sprite(img.ui.botton_fram_2)
            npcboard:setPreferredSize(CCSizeMake(614, 192))
            npcboard:setAnchorPoint(CCPoint(0, 0))
            npcboard:setPosition(50, 188)
            curlayer:addChild(npcboard)

            local lbranch = img.createUISprite(img.ui.guild_mill_branch)
            lbranch:setPosition(358-95, 300)
            curlayer:addChild(lbranch)
            local rbranch = img.createUISprite(img.ui.guild_mill_branch)
            rbranch:setFlipX(true)
            rbranch:setPosition(358+95, 300)
            curlayer:addChild(rbranch)
        end
        
        -- millicon
        local lowmillicon = img.createUISprite(img.ui["guild_mill_" .. cfgmilllv[level].resId])
        --lowmillicon:setAnchorPoint(0.5, 0)
        lowmillicon:setPosition(198, 323)
        curlayer:addChild(lowmillicon)
        local lowlvlab = lbl.createFont1(14, "Lv:" .. level, ccc3(255, 246, 223))
        lowlvlab:setPosition(CCPoint(lowmillicon:getContentSize().width/2, 14))
        lowmillicon:addChild(lowlvlab)
        local lowprolab = lbl.createMixFont1(15, "+" .. cfgmilllv[level].effec*100-100 .. "% " .. i18n.global.gmill_order_pro.string, ccc3(0x6f, 0x4c, 0x38))
        lowprolab:setAnchorPoint(0, 0.5)
        lowprolab:setPosition(CCPoint(78, 239))
        curlayer:addChild(lowprolab)
        local lowpronumlab = lbl.createMixFont1(15, cfgmilllv[level].millCount .. " " .. i18n.global.gmill_order_pronum.string, ccc3(0x6f, 0x4c, 0x38))
        lowpronumlab:setAnchorPoint(0, 0.5)
        lowpronumlab:setPosition(CCPoint(78, 219))
        curlayer:addChild(lowpronumlab)

        local line1 = img.createUI9Sprite(img.ui.gemstore_fgline)
        line1:setPreferredSize(CCSize(238, 2))
        line1:setPosition(CCPoint(198, 255))
        curlayer:addChild(line1)
        
        if level ~= #cfgmilllv then
            local row = img.createUISprite(img.ui.arrow)
            row:setPosition(358, 285)
            curlayer:addChild(row)

            local highmillicon = img.createUISprite(img.ui["guild_mill_" .. cfgmilllv[level+1].resId])
            --highmillicon:setAnchorPoint(0.5, 0)
            highmillicon:setPosition(524, 323)
            curlayer:addChild(highmillicon)
            local highlvlab = lbl.createFont1(14, "Lv:" .. level+1, ccc3(255, 246, 223))
            highlvlab:setPosition(CCPoint(highmillicon:getContentSize().width/2, 14))
            highmillicon:addChild(highlvlab)
            local highprolab = lbl.createMixFont1(15, "+" .. cfgmilllv[level+1].effec*100-100 .. "% " .. i18n.global.gmill_order_pro.string, ccc3(0x6f, 0x4c, 0x38))
            highprolab:setAnchorPoint(0, 0.5)
            highprolab:setPosition(CCPoint(408, 239))
            curlayer:addChild(highprolab)
            local highpronumlab = lbl.createMixFont1(15, cfgmilllv[level+1].millCount .. " " .. i18n.global.gmill_order_pronum.string, ccc3(0x6f, 0x4c, 0x38))
            highpronumlab:setAnchorPoint(0, 0.5)
            highpronumlab:setPosition(CCPoint(408, 219))
            curlayer:addChild(highpronumlab)
            local line2 = img.createUI9Sprite(img.ui.gemstore_fgline)
            line2:setPreferredSize(CCSize(238, 2))
            line2:setPosition(CCPoint(524, 255))
            curlayer:addChild(line2)
        else
            line1:setVisible(false)
            donateBtn1:setEnabled(false)
            setShader(donateBtn1, SHADER_GRAY, true)
            donateBtn10:setEnabled(false)
            setShader(donateBtn10, SHADER_GRAY, true)

            local line = img.createUI9Sprite(img.ui.gemstore_fgline)
            line:setPreferredSize(CCSize(554, 2))
            line:setPosition(CCPoint(358, 240))
            curlayer:addChild(line)
            lowmillicon:setPosition(358, 303)
            lowprolab:setAnchorPoint(0.5, 0.5)
            lowprolab:setPosition(CCPoint(358, 226))
            lowpronumlab:setAnchorPoint(0.5, 0.5)
            lowpronumlab:setPosition(CCPoint(358, 206))
        end

        return curlayer
    end


    local function init()
        local param = {}
        param.sid = player.sid

        addWaitNet()
        net:donate_sync(param, function(__data)
            delWaitNet()
            tbl2string(__data)
            guildmill.initupgrade(__data)
            milllayer = createmill(guildmill.lv, guildmill.coin)
            layer:addChild(milllayer, 100)
        end)
    end
    init()

    local declab1 = lbl.createFont1(18, i18n.global.gmill_once_donate.string, ccc3(0x48, 0x26, 0x1e))
    declab1:setAnchorPoint(1, 0.5)
    declab1:setPosition(CCPoint(222, 140))
    layer:addChild(declab1)
    local declab2 = lbl.createFont1(18, i18n.global.gmill_yourgold.string, ccc3(0x48, 0x26, 0x1e))
    declab2:setAnchorPoint(1, 0.5)
    declab2:setPosition(CCPoint(222, 80))
    layer:addChild(declab2)

    local needcoinbg = img.createUI9Sprite(img.ui.guild_mill_coinbg)
    needcoinbg:setPreferredSize(CCSizeMake(172, 34))
    needcoinbg:setPosition(CCPoint(342, 140))
    layer:addChild(needcoinbg)
    local icon_coin = img.createItemIcon2(ITEM_ID_COIN)
    icon_coin:setPosition(CCPoint(5, needcoinbg:getContentSize().height/2))
    needcoinbg:addChild(icon_coin)

    local lbl_coin = lbl.createFont2(16, "100K", ccc3(0xff, 0xf7, 0xe5))
    lbl_coin:setPosition(CCPoint(needcoinbg:getContentSize().width/2, needcoinbg:getContentSize().height/2))
    needcoinbg:addChild(lbl_coin)

    local coinbg = img.createUI9Sprite(img.ui.main_coin_bg)
    coinbg:setPreferredSize(CCSizeMake(172, 42))
    coinbg:setPosition(CCPoint(342, 80))
    layer:addChild(coinbg)

    local icon_coin = img.createItemIcon2(ITEM_ID_COIN)
    icon_coin:setPosition(CCPoint(5, coinbg:getContentSize().height/2+1))
    coinbg:addChild(icon_coin)

    local coin_num = bag.coin()
    local lbl_coin = lbl.createFont2(16, num2KM(coin_num), ccc3(255, 246, 223))
    lbl_coin:setPosition(CCPoint(coinbg:getContentSize().width/2, coinbg:getContentSize().height/2+3))
    coinbg:addChild(lbl_coin)
    lbl_coin.num = coin_num

    local donateSprite1 = img.createLogin9Sprite(img.login.button_9_small_gold)
    donateSprite1:setPreferredSize(CCSizeMake(160, 52))

    local donatelab1 = lbl.createFont1(18, i18n.global.gmill_donate1.string, lbl.buttonColor)
    donatelab1:setPosition(CCPoint(donateSprite1:getContentSize().width/2,
                                    donateSprite1:getContentSize().height/2))
    donateSprite1:addChild(donatelab1)

    donateBtn1 = SpineMenuItem:create(json.ui.button, donateSprite1)
    donateBtn1:setAnchorPoint(0.5, 0)
    donateBtn1:setPosition(CCPoint(558, 115))
    local donateMenu1 = CCMenu:createWithItem(donateBtn1)
    donateMenu1:setPosition(0,0)
    layer:addChild(donateMenu1)

    donateBtn1:registerScriptTapHandler(function()
        audio.play(audio.button) 
        if bag.coin() < DONATECOIN then
            showToast(i18n.global.blackmarket_coin_lack.string)
            return 
        end
        local param = {}
        param.sid = player.sid
        param.type = 1

        addWaitNet()
        net:donate_up(param, function(__data)
            delWaitNet()
            tbl2string(__data)
            if __data.status == -2 then
                showToast(i18n.global.gmill_mill_leveltop.string)
                return
            end
            if __data.status ~= 0 then
                showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                return
            end

            showToast(i18n.global.gmill_donate_success.string)
            local milllevel = guildmill.lv 
            guildmill.donatecoin(1)
            bag.subCoin(DONATECOIN)           
            lbl_coin:setString(num2KM(bag.coin()))
            if milllevel < guildmill.lv then
                json.load(json.ui.mofang_smk)
                local anismk = DHSkeletonAnimation:createWithKey(json.ui.mofang_smk)
                anismk:scheduleUpdateLua()
                anismk:playAnimation("animation")
                anismk:setPosition(198, 320)
                layer:addChild(anismk, 10000)

                schedule(layer, 1, function()
                    milllayer:removeFromParentAndCleanup(true)
                    milllayer = nil
                    milllayer = createmill(guildmill.lv, guildmill.coin)
                    layer:addChild(milllayer, 100)

                    json.load(json.ui.mofang_mofangline)
                    local animillline = DHSkeletonAnimation:createWithKey(json.ui.mofang_mofangline)
                    animillline:scheduleUpdateLua()
                    animillline:playAnimation("animation")
                    animillline:setPosition(360, 414)
                    layer:addChild(animillline, 100)
                end)
            else
                milllayer:removeFromParentAndCleanup(true)
                milllayer = nil
                milllayer = createmill(guildmill.lv, guildmill.coin)
                layer:addChild(milllayer, 100)
            end
        end)
    end)

    local donateSprite10 = img.createLogin9Sprite(img.login.button_9_small_gold)
    donateSprite10:setPreferredSize(CCSizeMake(160, 52))

    local donatelab10 = lbl.createFont1(18, i18n.global.gmill_donate10.string, lbl.buttonColor)
    donatelab10:setPosition(CCPoint(donateSprite10:getContentSize().width/2,
                                    donateSprite10:getContentSize().height/2))
    donateSprite10:addChild(donatelab10)

    donateBtn10 = SpineMenuItem:create(json.ui.button, donateSprite10)
    donateBtn10:setAnchorPoint(0.5, 0)
    donateBtn10:setPosition(CCPoint(558, 55))
    local donateMenu10 = CCMenu:createWithItem(donateBtn10)
    donateMenu10:setPosition(0,0)
    layer:addChild(donateMenu10)

    donateBtn10:registerScriptTapHandler(function()
        audio.play(audio.button) 
        if bag.coin() < DONATECOIN*10 then
            showToast(i18n.global.blackmarket_coin_lack.string)
            return 
        end
        if guildmill.coin + DONATECOIN*10 > cfgmilllv[guildmill.lv+1].gold then
            showToast(i18n.global.gmill_mill_full.string)
            return 
        end
        local param = {}
        param.sid = player.sid
        param.type = 2

        addWaitNet()
        net:donate_up(param, function(__data)
            delWaitNet()
            tbl2string(__data)
            if __data.status == -2 then
                showToast(i18n.global.gmill_mill_leveltop.string)
                return
            end
            if __data.status ~= 0 then
                showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                return
            end

            showToast(i18n.global.gmill_donate_success.string)
            local milllevel = guildmill.lv
            guildmill.donatecoin(2)
            bag.subCoin(DONATECOIN*10)           
            lbl_coin:setString(num2KM(bag.coin()))
            milllayer:removeFromParentAndCleanup(true)
            milllayer = nil
            milllayer = createmill(guildmill.lv, guildmill.coin)
            layer:addChild(milllayer, 100)
            if milllevel < guildmill.lv then
                json.load(json.ui.mofang_smk)
                local anismk = DHSkeletonAnimation:createWithKey(json.ui.mofang_smk)
                anismk:scheduleUpdateLua()
                anismk:playAnimation("animation")
                anismk:setPosition(198, 310)
                layer:addChild(anismk, 10000)

                json.load(json.ui.mofang_mofangline)
                local animillline = DHSkeletonAnimation:createWithKey(json.ui.mofang_mofangline)
                animillline:scheduleUpdateLua()
                animillline:playAnimation("animation")
                animillline:setPosition(360, 414)
                layer:addChild(animillline, 100)
            end
        end)
    end)

    return layer
end

return ui
