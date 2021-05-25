local ui = {}

require "common.func"

local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local audio = require "res.audio"
local i18n = require "res.i18n"
local player = require "data.player"
local net = require "net.netClient"
local bag = require "data.bag"
local cfgguildfire = require "config.guildfire"

local MAXFIRE = 360

function ui.create(dataInfo)
    local layer = CCLayerColor:create(ccc4(0,0,0,POPUP_DARK_OPACITY))

    img.load(img.packedOthers.spine_ui_gonghui_qidao)

    -- board
    local board_w = 708
    local board_h = 524

    local board = img.createUI9Sprite(img.ui.dialog_1)
    board:setPreferredSize(CCSizeMake(board_w, board_h))
    board:setScale(view.minScale)
    board:setPosition(view.physical.w/2, view.physical.h/2)
    layer:addChild(board)

    -- anim
    board:setScale(0.5*view.minScale)
    board:runAction(CCScaleTo:create(0.15, 1*view.minScale, 1*view.minScale))

    -- title
    local title = lbl.createFont1(24, i18n.global.pray_title.string, ccc3(0xe6, 0xd0, 0xae))
    title:setPosition(CCPoint(board_w/2, board_h-28))
    board:addChild(title, 1)
    local title_shadowD = lbl.createFont1(24, i18n.global.pray_title.string, ccc3(0x59, 0x30, 0x1b))
    title_shadowD:setPosition(CCPoint(board_w/2, board_h-30))
    board:addChild(title_shadowD)

    -- btn_help
    local btn_help0 = img.createUISprite(img.ui.btn_help)
    local btn_help = SpineMenuItem:create(json.ui.button, btn_help0)
    btn_help:setPosition(CCPoint(board_w - 68, board_h - 116))
    local btn_help_menu = CCMenu:createWithItem(btn_help)
    btn_help_menu:setPosition(CCPoint(0, 0))
    board:addChild(btn_help_menu, 100)
    btn_help:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer:addChild((require"ui.help").create(i18n.global.pray_help.string), 1000)
    end)

    -- btn_reward
    local btn_reward0 = img.createUISprite(img.ui.guildvice_icon_drop)
    local btn_reward = SpineMenuItem:create(json.ui.button, btn_reward0)
    btn_reward:setPosition(CCPoint(board_w - 68, board_h - 166))
    local btn_reward_menu = CCMenu:createWithItem(btn_reward)
    btn_reward_menu:setPosition(CCPoint(0, 0))
    board:addChild(btn_reward_menu, 100)
    btn_reward:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer:addChild((require"ui.guildVice.graydrop").create({bossid = dataInfo.id}), 1000)
    end)

    -- btn_rank
    local btn_rank0 = img.createUISprite(img.ui.btn_rank)
    local btn_rank = SpineMenuItem:create(json.ui.button, btn_rank0)
    btn_rank:setPosition(CCPoint(board_w - 68, board_h - 216))
    local btn_rank_menu = CCMenu:createWithItem(btn_rank)
    btn_rank_menu:setPosition(CCPoint(0, 0))
    board:addChild(btn_rank_menu, 100)
    btn_rank:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer:addChild((require"ui.guildVice.grayrank").create(), 1000)
    end)

    local qidao = json.create(json.ui.gonghui_qidao)
    --qidao:playAnimation("loop", -1)
    qidao:setPosition(board_w/2, board_h/2)
    board:addChild(qidao)

    local grayLayer = nil
    local function initLayer()
        grayLayer:removeFromParentAndCleanup(true)
        grayLayer = nil
    end

    local function showGray()
        local graylayer = CCLayer:create()
        if dataInfo.id == 0 then
            btn_reward:setVisible(false)
            btn_rank:setVisible(false)
            qidao:playAnimation("jindutiao", -1)

            -- 进度相关
            local progressLabel = lbl.createFont2(18,  string.format("%d", dataInfo.num) .. "\/360", ccc3(255, 246, 223))
            progressLabel:setPosition(board_w/2, 232)
            graylayer:addChild(progressLabel)

            local progress0 = img.createUISprite(img.ui.guildvice_firebar)
            fireProgress = createProgressVerticalBar(progress0)
            fireProgress:setPercentage(dataInfo.num/MAXFIRE*100)
            qidao:addChildFollowSlot("code_jindutiao", fireProgress)

            -- 叠加效果
            local progress01 = img.createUISprite(img.ui.guildvice_firebar)
            fireProgress1 = createProgressVerticalBar(progress0)
            fireProgress1:setPercentage(dataInfo.num/MAXFIRE*100)
            qidao:addChildFollowSlot("code_jindutiao2", fireProgress1)

            local gray0 = img.createLogin9Sprite(img.login.button_9_gold)
            gray0:setPreferredSize(CCSizeMake(204, 60))
            local grayGem = img.createItemIcon2(ITEM_ID_GEM)
            grayGem:setScale(0.9)
            grayGem:setPosition(50, gray0:getContentSize().height/2+3)
            gray0:addChild(grayGem)
            local grayGemlab = lbl.createFont2(16, string.format("%d", (dataInfo.count)*40), ccc3(255, 246, 223))
            grayGemlab:setPosition(grayGem:getContentSize().width/2, 0) 
            grayGem:addChild(grayGemlab)
            
            local lbl_gray = lbl.createFont1(16, i18n.global.pray_title.string, ccc3(0x73, 0x3b, 0x05))
            lbl_gray:setPosition(125, 30)
            gray0:addChild(lbl_gray)
            local grayBtn = SpineMenuItem:create(json.ui.button, gray0)
            grayBtn:setPosition(CCPoint(board_w/2, 83))
            local grayMenu = CCMenu:createWithItem(grayBtn)
            grayMenu:setPosition(CCPoint(0, 0))
            graylayer:addChild(grayMenu)
            if dataInfo.count > 2 then
                setShader(grayBtn, SHADER_GRAY, true)
                grayBtn:setEnabled(false)     
                grayGem:setVisible(false)
                lbl_gray:setPosition(102, 30)
            end

            grayBtn:registerScriptTapHandler(function()     
                disableObjAWhile(grayBtn)
                audio.play(audio.button)
                local param = {
                    sid = player.sid,
                }
                addWaitNet()
                netClient:gfire_pray(param, function(__data)
                    delWaitNet()
                    tbl2string(__data)
                    if __data.status == -1 then
                        showToast(i18n.global.gboss_fight_st1.string)
                        return
                    end
                    if __data.status == -2 then
                        showToast(i18n.global.gray_toast_todaylimit.string)
                        return
                    end
                    if __data.status == -3 then
                        showToast(i18n.global.gboss_fight_st6.string)
                        return
                    end
                    --if __data.status == -4 then
                    --    showToast(i18n.global.gray_toast_noguildfire.string)
                    --    return
                    --end
					if __data.status == -5 then
                        showToast(i18n.global.guildfire_changed.string)
                        return
                    end
                    if __data.status ~= 0 then
                        showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                        return
                    end
                    progressLabel:setString(string.format("%d", __data.num) .. "\/360")
                    fireProgress:setPercentage(__data.num/MAXFIRE*100)
                    fireProgress1:setPercentage(__data.num/MAXFIRE*100)
                    grayGemlab:setString(string.format("%d", __data.count*40))
                    if __data.count > 2 then
                        setShader(grayBtn, SHADER_GRAY, true)
                        grayBtn:setEnabled(false)     
                        grayGem:setVisible(false)
                        lbl_gray:setPosition(102, 30)
                    end
                    if __data.reward then
                        local tmp_bag = {
                            items = {},
                            equips = {},
                        }
                        if __data.reward.items then
                            for ii=1,#__data.reward.items do
                                local tbl_p = tmp_bag.items
                                tbl_p[#tbl_p+1] = {id=__data.reward.items[ii].id, num=__data.reward.items[ii].num}
                            end
                        elseif __data.reward.equips then
                            for ii=1,#__data.reward.equips do
                                local tbl_p = tmp_bag.equips
                                tbl_p[#tbl_p+1] = {id=__data.reward.equips[ii].id, num=__data.reward.equips[ii].num}
                            end
                        end
                        bag.addRewards(__data.reward)
                        local rewardsKit = require "ui.reward"
                        if __data.id ~= 0 and dataInfo.id == 0 then
                            layer:runAction(createSequence({
                                CCDelayTime:create(1.5),CCCallFunc:create(function()
                                    CCDirector:sharedDirector():getRunningScene():addChild(rewardsKit.showReward(tmp_bag), 100000)
                                end)
                            }))
                        else
                            CCDirector:sharedDirector():getRunningScene():addChild(rewardsKit.showReward(tmp_bag), 100000)
                        end
                    end
                    if __data.del then
                        bag.subGem(__data.del.num)
                    end
                    if __data.id ~= 0 and dataInfo.id == 0 then
                        progressLabel:setVisible(false)
                        qidao:playAnimation("open")
                        local ban = CCLayer:create()
                        ban:setTouchEnabled(true)
                        ban:setTouchSwallowEnabled(true)
                        layer:addChild(ban, 1000)

                        layer:runAction(createSequence({
                            CCDelayTime:create(1.5),CCCallFunc:create(function()
                                ban:removeFromParent()
                                initLayer()
                                grayLayer = showGray() 
                                board:addChild(grayLayer)
                            end)
                        }))
                    end
                    dataInfo = {
                        id = __data.id,
                        num = __data.num,
                        count = __data.count,
                    }
                end)
            end)
        else
            btn_reward:setVisible(true)
            btn_rank:setVisible(true)
            qidao:playAnimation("loop", -1)

            -- hp bar
            local hpBar = img.createUISprite(img.ui.guildvice_hpbarbg)
            --hpBar:setPreferredSize(CCSize(322, 24))
            hpBar:setPosition(board_w/2, 420)
            board:addChild(hpBar)

            local progress0 = img.createUISprite(img.ui.guildvice_hpbar)
            local hpProgress = createProgressBar(progress0)
            hpProgress:setPosition(hpBar:getContentSize().width/2, hpBar:getContentSize().height/2)
            hpProgress:setPercentage(dataInfo.num/100*100)
            hpBar:addChild(hpProgress)

            local progressStr = string.format("%d%%", dataInfo.num)
            local progressLabel = lbl.createFont2(16, progressStr, ccc3(255, 246, 223))
            progressLabel:setPosition(CCPoint(hpBar:getContentSize().width/2,
                                            hpBar:getContentSize().height/2+5))
            hpBar:addChild(progressLabel)

            local card_boss = json.createSpineMons(cfgguildfire[dataInfo.id].monster[1])
            card_boss:setScale(0.62)
            qidao:addChildFollowSlot("code_hero", card_boss)

            local fight0 = img.createLogin9Sprite(img.login.button_9_gold)
            fight0:setPreferredSize(CCSizeMake(204, 60))

            --local fightCount = img.createItemIcon2(ITEM_ID_GEM)
            --grayGem:setScale(0.9)
            --grayGem:setPosition(50, gray0:getContentSize().height/2+3)
            --gray0:addChild(grayGem)
            local fightCountLab = lbl.createFont2(16, string.format("%d\/", 4-dataInfo.count) .. "4", ccc3(0xb5, 0xff, 0x5e))
            fightCountLab:setPosition(50, fight0:getContentSize().height/2) 
            fight0:addChild(fightCountLab)

            local lbl_fight = lbl.createFont1(16, i18n.global.brave_btn_battle.string, ccc3(0x73, 0x3b, 0x05))
            lbl_fight:setPosition(125, fight0:getContentSize().height/2)
            fight0:addChild(lbl_fight)
            local fightBtn = SpineMenuItem:create(json.ui.button, fight0)
            fightBtn:setPosition(CCPoint(board_w/2, 83))
            local fightMenu = CCMenu:createWithItem(fightBtn)
            fightMenu:setPosition(CCPoint(0, 0))
            graylayer:addChild(fightMenu)

            if dataInfo.count >= 4 then
                setShader(fightBtn, SHADER_GRAY, true)
                fightBtn:setEnabled(false)     
            end

            fightBtn:registerScriptTapHandler(function()     
                disableObjAWhile(grayBtn)
                audio.play(audio.button)
                layer:addChild(require("ui.selecthero.main").create({type = "guildGray", id = dataInfo.id}))
            end)
        end
        return graylayer
    end

    grayLayer = showGray() 
    board:addChild(grayLayer)

    local function backEvent()
        audio.play(audio.button)
        layer:removeFromParentAndCleanup()
    end

    -- close btn
    local close0 = img.createUISprite(img.ui.close)
    local closeBtn = SpineMenuItem:create(json.ui.button, close0)
    closeBtn:setPosition(CCPoint(746+56-120, 545-50))
    local closeMenu = CCMenu:createWithItem(closeBtn)
    closeMenu:setPosition(CCPoint(0, 0))
    board:addChild(closeMenu)
    closeBtn:registerScriptTapHandler(function()     
        backEvent()
    end)

    layer:setTouchEnabled(true)
    
    function layer.onAndroidBack()
        backEvent()
    end

    addBackEvent(layer) 
    
    local function onEnter()
        layer.notifyParentLock()
        --showGray()
    end

    local function onExit()
        layer.notifyParentUnlock()
    end
    
    layer:registerScriptHandler(function(event)
        if event == "enter" then 
            onEnter()
        elseif event == "exit" then
            onExit()
        elseif event == "cleanup" then
            img.unload(img.packedOthers.spine_ui_gonghui_qidao)
        end
    end)

    return layer 
end

return ui
