local ui = {}

require "common.func"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local audio = require "res.audio"
local particle = require "res.particle"
local i18n = require "res.i18n"
local net = require "net.netClient"
local player = require "data.player"
local bagdata = require "data.bag"
local cfgitem = require "config.item"
local cfgequip = require "config.equip"
local tipsitem = require "ui.tips.item"
local tipsequip = require "ui.tips.equip"
local reward = require "ui.reward"
local selecthero = require "ui.selecthero.main"
local herosdata = require "data.heros"
local airData = require "data.airisland"
local cfgfloatland = require "config.floatland"

local function createPopupPieceBatchSummonResult(type, id, count)
    local params = {}
    params.title = i18n.global.reward_will_get.string
    params.btn_count = 0

    local dialog = require("ui.dialog").create(params) 

    local back = img.createLogin9Sprite(img.login.button_9_small_gold)
    back:setPreferredSize(CCSize(153, 50))
    local comfirlab = lbl.createFont1(22, i18n.global.summon_comfirm.string, lbl.buttonColor)
    comfirlab:setPosition(CCPoint(back:getContentSize().width/2,
                                    back:getContentSize().height/2))
    back:addChild(comfirlab)
    local backBtn = SpineMenuItem:create(json.ui.button, back)
    backBtn:setPosition(CCPoint(dialog.board:getContentSize().width/2, 80))
    local menu = CCMenu:createWithItem(backBtn)
    menu:setPosition(0, 0)
    dialog.board:addChild(menu)

    dialog.board.tipsTag = false
    if type == "item" then
        local item = img.createItem(id, count)
        itemBtn = SpineMenuItem:create(json.ui.button, item)
        itemBtn:setScale(0.85)
        itemBtn:setPosition(dialog.board:getContentSize().width/2, 185)
        local iconMenu = CCMenu:createWithItem(itemBtn)
        iconMenu:setPosition(0, 0)
        dialog.board:addChild(iconMenu)

        itemBtn:registerScriptTapHandler(function()
            audio.play(audio.button)
            if dialog.board.tipsTag == false then
                dialog.board.tipsTag = true
                tips = tipsitem.createForShow({id = id, num = count})
                dialog:addChild(tips, 200)
                tips.setClickBlankHandler(function()
                    tips:removeFromParent()
                    dialog.board.tipsTag = false
                end)
            end
        end)
    else
        local equip = img.createEquip(id)
        equipBtn = SpineMenuItem:create(json.ui.button, equip)
        equipBtn:setScale(0.85)
        equipBtn:setPosition(dialog.board:getContentSize().width/2, 185)
        local iconMenu = CCMenu:createWithItem(equipBtn)
        iconMenu:setPosition(0, 0)
        dialog.board:addChild(iconMenu)

        local countLbl = lbl.createFont2(20, string.format("X%d", count), ccc3(255, 246, 223))
        countLbl:setAnchorPoint(ccp(0, 0.5))
        countLbl:setPosition(equipBtn:boundingBox():getMaxX()+10, 185)
        dialog.board:addChild(countLbl)

        equipBtn:registerScriptTapHandler(function()
            audio.play(audio.button)
            if dialog.board.tipsTag == false then
                dialog.board.tipsTag = true
                tips = tipsequip.createForShow({id = id})
                dialog:addChild(tips, 200)
                tips.setClickBlankHandler(function()
                    tips:removeFromParent()
                    dialog.board.tipsTag = false
                end)
            end
        end)
    end
    backBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        dialog:removeFromParentAndCleanup()
    end)
    return dialog

end

function ui.create()
    local layer = CCLayer:create()
    
    airData.count = airData.count + 1
    -- touch point
    local bg = CCNode:create()
    bg:setContentSize(CCSizeMake(view.logical.w, view.logical.h))
    bg:setScale(view.minScale)
    --bg:setScaleX(view.xScale)
    --bg:setScaleY(view.yScale)
    bg:setPosition(CCPoint(view.midX, view.midY))
    layer:addChild(bg)

    -- itembar
    local itembar = require "ui.airisland.itembar"
    layer:addChild(itembar.create(), 1000)

    img.load(img.packedOthers.ui_airisland)
    --img.load(img.packedOthers.spine_ui_kongzhan_1)
    local animBg = json.create(json.ui.kongzhan_map)
    animBg:setScale(view.minScale)
    --animBg:setScaleX(view.xScale)
    --animBg:setScaleY(view.yScale)
    animBg:setPosition(view.midX, view.midY)
    animBg:playAnimation("animation", -1)
    if airData.count == 1 then
        --animBg:playAnimation("in")
        local animYun = json.create(json.ui.kongzhan_map_yun)
        animYun:setScale(view.minScale)
        animYun:setPosition(view.midX, view.midY)
        animYun:playAnimation("in")
        layer:addChild(animYun, 1020)

        local aniban = CCLayer:create()
        aniban:setTouchEnabled(true)
        aniban:setTouchSwallowEnabled(true)
        layer:addChild(aniban, 1000)
        schedule(layer, 1.5, function()
            aniban:removeFromParent()
        end)
    end
    layer:addChild(animBg)


    local boLand = {}
    local iconCd = {}
    local flagRefresh = {}
    local buildingObjs = {}
    local buildingType = {}
    local last_selected_sprite = 0

    local function bossChage(pos)
        if pos ~= 0 and airData.data.land.land[pos] then
            airData.data.land.land[pos].cd = os.time() - 1
        end
    end


    local function onSelfClicked(clickedObj)
        audio.play(audio.button)
        last_selected_sprite = 0
        if clickedObj and not tolua.isnull(clickedObj) then
            clearShader(clickedObj, true)
        end
        local params = {
            sid = player.sid,
        }
        addWaitNet()
        net:island_sync(params, function(__data)
            delWaitNet()
            tbl2string(__data)
            local airData = require "data.airisland"
            airData.setData(__data)
            replaceScene(require("ui.airisland.main1").create(__data))
        end)
    end

    local function onBossClicked(clickedObj)
        audio.play(audio.button)
        last_selected_sprite = 0
        if clickedObj and not tolua.isnull(clickedObj) then
            clearShader(clickedObj, true)
            local bossline = require "ui.airisland.bossline"
            layer:addChild(bossline.create(bossChage), 1000)
        end
        --local params = {
        --    sid = player.sid,
        --}
        --addWaitNet()
        --net:island_boss(params, function(__data)
        --    delWaitNet()
    
        --    tbl2string(__data)
        --end)
    end

    local function onSkinIslandClicked(clickedObj)
        audio.play(audio.button)
        last_selected_sprite = 0
        if clickedObj and not tolua.isnull(clickedObj) then
            clearShader(clickedObj, true)
            local npcline = require "ui.airisland.npcline"
            layer:addChild(npcline.create(clickedObj.pos, clickedObj.cdk, bossChage), 1000)
        end
    end

    local function onIslandClicked(clickedObj)
        audio.play(audio.button)
        last_selected_sprite = 0
        if clickedObj and not tolua.isnull(clickedObj) then
            clearShader(clickedObj, true)
            local npcline = require "ui.airisland.npcline"
            layer:addChild(npcline.create(clickedObj.pos, clickedObj.cdk, bossChage), 1000)
        end
    end

    local function onBoxClicked(clickedObj)
        audio.play(audio.button)
        last_selected_sprite = 0
        if clickedObj and not tolua.isnull(clickedObj) then
            clearShader(clickedObj, true)
            local params = {
                sid = player.sid,
                pos = clickedObj.pos
            }
            addWaitNet()
            net:island_box(params, function(__data)
                delWaitNet()
                tbl2string(__data)
                
                if __data.status ~= 0 then
                    showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                    return
                end

                if __data.land then
                    boLand[__data.land.pos]:stopAnimation()
                    boLand[__data.land.pos]:playAnimation("open")
                end
                local ban = CCLayer:create()
                ban:setTouchEnabled(true)
                ban:setTouchSwallowEnabled(true)
                layer:addChild(ban, 1000)
                schedule(layer, 1, function()
                    local to = buildingType[cfgfloatland[__data.land.id].type+1]
                    boLand[__data.land.pos]:removeChildFollowSlot("code_label")
                    animBg:removeChildFollowSlot(to.code_name .. __data.land.pos)
                    iconCd[__data.land.pos] = nil
                    boLand[__data.land.pos] = nil

                    airData.data.land.land[__data.land.pos] = __data.land
                    airData.data.land.land[__data.land.pos].cd = __data.land.cd + os.time()
                    local cd = math.max(0, __data.land.cd - os.time())
                    local timeLab = string.format("%02d:%02d:%02d (%d)",math.floor(cd/3600),math.floor((cd%3600)/60),math.floor(cd%60), __data.land.tier)

                    boLand[__data.land.pos] = json.create(to.jsonName)
                    boLand[__data.land.pos].data = to
                    buildingObjs[__data.land.pos+2] = boLand[__data.land.pos]
                    if __data.land.dead and __data.land.dead == true then
                        if __data.land.pos == 0 then
                            boLand[__data.land.pos]:playAnimation("animation2", -1)
                        else
                            boLand[__data.land.pos]:playAnimation("loop", -1)
                        end
                    else
                        boLand[__data.land.pos]:playAnimation("animation", -1)
                    end

                    animBg:addChildFollowSlot(to.code_name .. __data.land.pos, boLand[__data.land.pos])

                    iconCd[__data.land.pos] = lbl.createFont2(16, timeLab, ccc3(0xa5, 0xfd, 0x47))
                    boLand[__data.land.pos]:addChildFollowSlot("code_label", iconCd[__data.land.pos])

					--require("ui.custom").showFloatReward(__data.reward)
					-- nobody manually hits island anyway and it shows an ugly reappearance suddenly of island
                    if __data.reward.equips then
                        bagdata.equips.add(__data.reward.equips[1])
                        local pop = createPopupPieceBatchSummonResult("equip", __data.reward.equips[1].id, __data.reward.equips[1].num)
                        layer:addChild(pop, 1000)
                    else
                        bagdata.items.add(__data.reward.items[1])
                        local pop = createPopupPieceBatchSummonResult("item", __data.reward.items[1].id, __data.reward.items[1].num)
                        layer:addChild(pop, 1000)
                    end
                    ban:removeFromParent()
                end)
            end)
        end
    end

    local building_lbl_color = ccc3(0xfb, 0xe6, 0x7e)
    buildingType = {
        [1] = {
            name = "self",
            jsonName = json.ui.kongzhan_dao1,
            code_name = "code_position_self",
            lbl = i18n.global.floatland_maintown_name.string,
            tapFunc = onSelfClicked,
        },
        [2] = {
            name = "boss",
            jsonName = json.ui.kongzhan_dragon,
            code_name = "code_position_boss",
            lbl = i18n.global.floatland_boss_name.string,
            tapFunc = onBossClicked,
        },
        [3] = {
            name = "island",
            jsonName = json.ui.kongzhan_golem,
            code_name = "code_position",
            tapFunc = onIslandClicked,
        },
        [4] = {
            name = "box",
            jsonName = json.ui.kongzhan_dao3,
            code_name = "code_position",
            tapFunc = onBoxClicked,
        },
        [5] = {
            name = "diaoluo",
            jsonName = json.ui.kongzhan_diaoluo,
            code_name = "code_position",
            tapFunc = onSkinIslandClicked,
        },
        [6] = {
            name = "xuanwo",
            jsonName = json.ui.kongzhan_xuanwo,
            code_name = "code_position",
        },
    }

    local function createBuildings()
        buildingObjs = {}
        for i=1,2 do
            local to = buildingType[i]
            local bo = json.create(to.jsonName)
            bo.data = to
            buildingObjs[i] = bo
            local info = airData.data.land
            if i == 2 and info.dead and info.dead == true then
                bo:playAnimation("animation2", -1)
            else
                bo:playAnimation("animation", -1)
            end
            animBg:addChildFollowSlot(to.code_name, bo)

            local lbl_xxx= lbl.createFont2(18, to.lbl, building_lbl_color)
            local building_lbl_xxx = img.createUI9Sprite(img.ui.main_building_lbl)
            --lbl_buildings[ii] = building_lbl_xxx
            local bd_size = lbl_xxx:boundingBox().size
            if bd_size.width < 160 then
                bd_size.width = 160
            end
            building_lbl_xxx:setPreferredSize(CCSizeMake(bd_size.width, 40))
            lbl_xxx:setPosition(CCPoint(building_lbl_xxx:getContentSize().width/2, building_lbl_xxx:getContentSize().height/2))
            building_lbl_xxx:addChild(lbl_xxx)
            --local iconTitle = lbl.createFont2(16, "", ccc3(0xa5, 0xfd, 0x47))
            bo:addChildFollowSlot("code_label", building_lbl_xxx)
        end

        -- 岛屿
        for i = 1, #airData.data.land.land do
            flagRefresh[i] = false
            local info = airData.data.land
            local to = buildingType[cfgfloatland[info.land[i].id].type+1]
            boLand[i] = json.create(to.jsonName)
            boLand[i].data = to
            buildingObjs[i+2] = boLand[i]
            if info.land[i].dead then
                boLand[i]:playAnimation("loop", -1)
            else
                boLand[i]:playAnimation("animation", -1)
            end
            animBg:addChildFollowSlot(to.code_name .. info.land[i].pos, boLand[i])
            if info.land[i].cd then
                iconCd[i] = lbl.createFont2(16, "", ccc3(0xa5, 0xfd, 0x47))
                boLand[i]:addChildFollowSlot("code_label", iconCd[i])
            end
        end

        -- 旋涡
        for i = 1, 27 - #airData.data.land.land do
            local to = buildingType[6]
            local bo = json.create(json.ui.kongzhan_xuanwo)
            bo.data = to
            buildingObjs[i+2+#airData.data.land.land] = bo
            bo:playAnimation("animation", -1)
            animBg:addChildFollowSlot(to.code_name .. i+#airData.data.land.land, bo)
        end
    end

    createBuildings()

    -- help
    local help = img.createUISprite(img.ui.btn_help)
    local helpBtn = SpineMenuItem:create(json.ui.button, help)
    helpBtn:setScale(view.minScale)
    helpBtn:setPosition(scalep(926, 546))
    local helpMenu = CCMenu:createWithItem(helpBtn)
    helpMenu:setPosition(ccp(0, 0))
    layer:addChild(helpMenu,10) 
    helpBtn:registerScriptTapHandler(function ()
        audio.play(audio.button)
        local helpLayer = require("ui.help").create(i18n.global.floatland_help.string)
        layer:addChild(helpLayer, 1000)
    end)

    -- back
    local btnBackSprite = img.createUISprite(img.ui.back)
    local btnBack = SpineMenuItem:create(json.ui.button, btnBackSprite)
    btnBack:setScale(view.minScale)
    btnBack:setPosition(scalep(35, 546))
    local menuBack = CCMenu:createWithItem(btnBack)
    menuBack:setPosition(0, 0)
    layer:addChild(menuBack, 10)
    btnBack:registerScriptTapHandler(function()
        --replaceScene(require("ui.town.main").create())
        local params = {
            sid = player.sid,
        }
        addWaitNet()
        net:island_sync(params, function(__data)
            delWaitNet()
            tbl2string(__data)
            local airData = require "data.airisland"
            airData.setData(__data)
            replaceScene(require("ui.airisland.main1").create(__data))
        end)
    end)


    local function npcChanges(poss)
        for i=1,#poss do
            if poss[i] < 0 then
                buildingObjs[i+2]:playAnimation("loop", -1)
                if airData.data.land.land[i] then
                    airData.data.land.land[i].tier = -poss[i]
                end
            else
                if airData.data.land.land[i] then
                    airData.data.land.land[i].tier = poss[i]
                end
            end
        end
    end

    local function createSurebuy()
        local params = {}
        params.btn_count = 0
        params.body = string.format(i18n.global.island_sweep_sure.string, 20)
        local board_w = 474

        local dialoglayer = require("ui.dialog").create(params) 

        local btnYesSprite = img.createLogin9Sprite(img.login.button_9_small_gold)
        btnYesSprite:setPreferredSize(CCSize(153, 50))
        local btnYes = SpineMenuItem:create(json.ui.button, btnYesSprite)
        btnYes:setPosition(board_w/2+95, 100)
        local labYes = lbl.createFont1(18, i18n.global.board_confirm_yes.string, ccc3(0x73, 0x3b, 0x05))
        labYes:setPosition(btnYes:getContentSize().width/2, btnYes:getContentSize().height/2)
        btnYesSprite:addChild(labYes)
        local menuYes = CCMenu:create()
        menuYes:setPosition(0, 0)
        menuYes:addChild(btnYes)
        dialoglayer.board:addChild(menuYes)

        local btnNoSprite = img.createLogin9Sprite(img.login.button_9_small_gold)
        btnNoSprite:setPreferredSize(CCSize(153, 50))
        local btnNo = SpineMenuItem:create(json.ui.button, btnNoSprite)
        btnNo:setPosition(board_w/2-95, 100)
        local labNo = lbl.createFont1(18, i18n.global.board_confirm_no.string, ccc3(0x73, 0x3b, 0x05))
        labNo:setPosition(btnNo:getContentSize().width/2, btnNo:getContentSize().height/2)
        btnNoSprite:addChild(labNo)
        local menuNo = CCMenu:create()
        menuNo:setPosition(0, 0)
        menuNo:addChild(btnNo)
        dialoglayer.board:addChild(menuNo)

        local function showRewardlayer(reward, num)
            if reward then
                layer:getParent():addChild((require"ui.hook.drops").create(reward, i18n.global.mail_rewards.string), 1000)
            end
            --layer:removeFromParent()
            dialoglayer:removeFromParentAndCleanup(true)
        end

        btnYes:registerScriptTapHandler(function()
            audio.play(audio.button)
            dialoglayer:addChild(selecthero.create({type = "sweepforcomisland", callback = showRewardlayer, callback2 = npcChanges}), 1000)
            --dialoglayer:removeFromParentAndCleanup(true)
        end)

        btnNo:registerScriptTapHandler(function()
            dialoglayer:removeFromParentAndCleanup(true)
            audio.play(audio.button)
        end)

        local function diabackEvent()
            dialoglayer:removeFromParentAndCleanup(true)
        end

        function dialoglayer.onAndroidBack()
            diabackEvent()
        end

        addBackEvent(dialoglayer)
        
        local function onEnter()
            dialoglayer.notifyParentLock()
        end

        local function onExit()
            dialoglayer.notifyParentUnlock()
        end

        dialoglayer:registerScriptHandler(function(event) 
            if event == "enter" then 
                onEnter()
            elseif event == "exit" then
                onExit()
            end
        end)
        return dialoglayer
    end

    -- sweep
    local sweep = img.createUISprite(img.ui.airisland_sweep_bg)
    local sweepBtn = SpineMenuItem:create(json.ui.button, sweep)
    sweepBtn:setScale(view.minScale)
    sweepBtn:setPosition(scalep(895, 65))
    local sweepMenu = CCMenu:createWithItem(sweepBtn)
    sweepMenu:setPosition(ccp(0, 0))
    layer:addChild(sweepMenu,10) 

    json.load(json.ui.cannon)
    local animSweep = DHSkeletonAnimation:createWithKey(json.ui.cannon)
    animSweep:scheduleUpdateLua()
    animSweep:playAnimation("animation", -1)
    animSweep:setPosition(sweep:getContentSize().width/2, sweep:getContentSize().height/2)
    sweep:addChild(animSweep)

    local sweepLbl = lbl.createFont2(20, i18n.global.act_bboss_sweep.string, ccc3(255, 246, 223))
    sweepLbl:setPosition(sweep:getContentSize().width/2, 5)
    sweep:addChild(sweepLbl)

    sweepBtn:registerScriptTapHandler(function ()
        disableObjAWhile(sweepBtn)
        audio.play(audio.button)
        if airData.data.vit.vit <= 0 then
            showToast(i18n.global.airisland_toast_noflr.string)
            return
        end
        animSweep:playAnimation("animation2")
        schedule(layer, 0.5, function()
            local surebuy = createSurebuy()
            layer:addChild(surebuy, 1001)
        end)
    end)

    autoLayoutShift(btnBack)
    autoLayoutShift(helpBtn)
    autoLayoutShift(sweepBtn)

    local beginX = 0
    local beginY = 0
    local isClick = false
    local currenX = 0
    local currenY = 0
    local speed = 2
    -- local minPosx = 212
    -- local maxPosx = 745
    -- local minPosy = 12
    -- local maxPosy = 560
    local minPosx = view.physical.w * 0.5 - (748 * view.minScale - view.physical.w * 0.5)
    local maxPosx = view.physical.w * 0.5 + (748 * view.minScale - view.physical.w * 0.5)
    local minPosy = view.physical.h * 0.5 - (564 * view.minScale - view.physical.h * 0.5)
    local maxPosy = view.physical.h * 0.5 + (564 * view.minScale - view.physical.h * 0.5)
    
    -- x:745-214 y:45-590
    --local function inRange(x, y)
    --    if x < minPosx * view.xScale or x > maxPosx * view.xScale or
    --        y < minPosy * view.yScale or y > maxPosy * view.yScale then    
    --        return false
    --    end
    --    return true
    --end
    local function inRange(x, y)
        if x < (minPosx) or x > (maxPosx) or
            y < (minPosy) or y > (maxPosy) then    
            return false
        end
        return true
    end


    local function onTouchBegan(x, y)
        local po = bg:convertToNodeSpace(CCPoint(x, y))
        beginX = po.x
        beginY = po.y
        isClick = true
        currenX = po.x
        currenY = po.y
        for ii=1,#buildingObjs do
            local tObj = buildingObjs[ii]
            if tObj and tObj.data.tapFunc and tObj:getAabbBoundingBox():containsPoint(CCPoint(x, y)) then
                setShader(tObj, SHADER_HIGHLIGHT, true)
                last_selected_sprite = tObj
                break
            end
        end
        return true
    end

    local function onTouchMoved(x, y)
        local po = bg:convertToNodeSpace(CCPoint(x, y))
        if isClick and (math.abs(po.x-beginX) > 15 or math.abs(po.y-beginY) > 15) then
            if last_selected_sprite ~= 0 then
                clearShader(last_selected_sprite, true)
                last_selected_sprite = 0
                isClick = false
                --return 
            end
        end
        local px,py = animBg:getPosition()
        local deltaX = (po.x - currenX)*speed 
        local deltaY = (po.y - currenY)*speed 
        currenY = po.y
        currenX = po.x
        if px + deltaX < (minPosx) or px + deltaX > (maxPosx) then
            if py + deltaY >= (minPosy) and py + deltaY <= (maxPosy) then
                animBg:setPosition(px, py + deltaY)
                return 
            end
        end

        if py + deltaY < (minPosy) or py + deltaY > (maxPosy) then
            if px + deltaX >= (minPosx) and px + deltaX <=(maxPosx) then
                animBg:setPosition(px + deltaX, py)
                return 
            end
        end

        if inRange(px + deltaX, py + deltaY) == true then
            animBg:setPosition(px + deltaX, py + deltaY)
        end
    end

    local function onTouchEnded(x, y)
        if not isClick then return end
        if last_selected_sprite == 0 then return end
        for ii=1, 2+#airData.data.land.land do
            local tObj = buildingObjs[ii]
            tObj.pos = ii-2 
            if tObj.pos >= 1 and airData.data.land.land[tObj.pos].cdk then
                tObj.cdk = airData.data.land.land[tObj.pos].cdk 
            end
            if tObj:getAabbBoundingBox():containsPoint(CCPoint(x, y)) then
                print("you clicked " .. tObj.data.name)
                if tObj.data.tapFunc then
                    tObj.data.tapFunc(tObj)
                end
                break
            end
        end
        if last_selected_sprite ~= 0 then
            last_selected_sprite = 0
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
    layer:registerScriptTouchHandler(onTouch)
	layer:setTouchEnabled(true)

    addBackEvent(layer)
    function layer.onAndroidBack()
        replaceScene(require("ui.town.main").create())
    end

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
            -- img.unload(img.packedOthers.ui_airisland)
            -- img.unload(img.packedOthers.spine_ui_kongzhan_1)
            -- img.unload(img.packedOthers.spine_ui_kongzhan_2)
            -- img.unload(img.packedOthers.spine_ui_kongzhan_3)
            -- img.unload(img.packedOthers.spine_ui_kongzhan_4)
        elseif event == "cleanup" then
            -- img.unload(img.packedOthers.ui_airisland)
            -- img.unload(img.packedOthers.spine_ui_kongzhan_1)
            -- img.unload(img.packedOthers.spine_ui_kongzhan_2)
            -- img.unload(img.packedOthers.spine_ui_kongzhan_3)
            -- img.unload(img.packedOthers.spine_ui_kongzhan_4)
        end
    end)

    local function onUpdate(ticks)
        for i = 1,27 do
            if airData.data.land.land[i] then
                if airData.data.land.land[i].cd then
                    local cd = math.max(0, airData.data.land.land[i].cd - os.time())
                    if cd > 0 then
                        local timeLab = string.format("%02d:%02d:%02d (%d)",math.floor(cd/3600),math.floor((cd%3600)/60),math.floor(cd%60), airData.data.land.land[i].tier)
                        if iconCd[i] then
                            iconCd[i]:setString(timeLab)
                        end
                    else
                        if flagRefresh[i] == false then
                            flagRefresh[i] = true
                            iconCd[i]:setVisible(false)
                            local params = {
                                sid = player.sid,
                                pos = airData.data.land.land[i].pos,
                            }
                            tbl2string(params)
                            addWaitNet()
                            net:island_land(params, function(__data)
                                delWaitNet()
                                tbl2string(__data)
                                if boLand[i] then
                                    local to = buildingType[cfgfloatland[__data.land[1].id].type+1]
                                    boLand[__data.land[1].pos]:removeChildFollowSlot("code_label")
                                    animBg:removeChildFollowSlot(to.code_name .. __data.land[1].pos)
                                    iconCd[__data.land[1].pos] = nil
                                    boLand[__data.land[1].pos] = nil

                                    airData.data.land.land[__data.land[1].pos] = __data.land[1]
                                    airData.data.land.land[__data.land[1].pos].cd = __data.land[1].cd + os.time()
                                    cd = math.max(0, __data.land[1].cd - os.time())
                                    local timeLab = string.format("%02d:%02d:%02d (%d)",math.floor(cd/3600),math.floor((cd%3600)/60),math.floor(cd%60), __data.land[1].tier)
                                    --iconCd[__data.land[1].pos]:setString(timeLab)
                                    --iconCd[__data.land[1].pos]:setVisible(true)
                                    flagRefresh[__data.land[1].pos] = false

                                    boLand[__data.land[1].pos] = json.create(to.jsonName)
                                    boLand[__data.land[1].pos].data = to
                                    buildingObjs[__data.land[1].pos+2] = boLand[__data.land[1].pos]
                                    if __data.land[1].dead and __data.land[1].dead == true then
                                        if __data.land[1].pos == 0 then
                                            boLand[__data.land[1].pos]:playAnimation("animation2", -1)
                                        else
                                            boLand[__data.land[1].pos]:playAnimation("loop", -1)
                                        end
                                    else
                                        boLand[__data.land[1].pos]:playAnimation("animation", -1)
                                    end

                                    animBg:addChildFollowSlot(to.code_name .. __data.land[1].pos, boLand[__data.land[1].pos])

                                    iconCd[__data.land[1].pos] = lbl.createFont2(16, timeLab, ccc3(0xa5, 0xfd, 0x47))
                                    boLand[__data.land[1].pos]:addChildFollowSlot("code_label", iconCd[__data.land[1].pos])
                                end
                            end)
                        end
                    end
                end
            end
        end
    end

    layer:scheduleUpdateWithPriorityLua(onUpdate, 0)

    return layer
end

return ui
