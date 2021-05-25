-- 主城界面

local ui = {}

require "common.func"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local i18n = require "res.i18n"
local audio = require "res.audio"
local particle = require "res.particle"
local player = require "data.player"
local net = require "net.netClient"

local lastAllTime = 0

-- uiparams
--     .pop_layer:    layer to show
--     .from_layer:   from which layer, if no pop_layer then  pop from_layer
function ui.create(uiparams)
    local layer = CCLayer:create()
    function layer.onAndroidBack()
    end

    -- touch point
    local bg = CCNode:create()
    bg:setContentSize(CCSizeMake(view.logical.w, view.logical.h))
    bg:setScale(view.minScale)
    bg:setPosition(CCPoint(view.midX, view.midY))
    layer:addChild(bg)

    local main_ani = json.createWithoutSchedule(json.ui.main_zhuchangjing)
    main_ani:setScale(view.minScale)
    main_ani:setPosition(ccp(view.midX, view.midY))
    layer:addChild(main_ani)
    main_ani:playAnimation("animation", -1)
    main_ani:registerAnimation("slide", -1)
    local diaoqiao_ani = json.createWithoutSchedule(json.ui.main_diaoqiao)
    --diaoqiao_ani:scheduleUpdateLua()
    diaoqiao_ani:playAnimation("animation", -1)
    main_ani:addChildFollowSlot("code_diaoqiao", diaoqiao_ani)
    local yun_ani = json.create(json.ui.main_yun)
    yun_ani:playAnimation("animation", -1)
    main_ani:addChildFollowSlot("code_yun", yun_ani)
    local yun_ani2 = json.create(json.ui.main_yun2)
    yun_ani2:playAnimation("animation", -1)
    main_ani:addChildFollowSlot("code_yun2", yun_ani2)

    -- 吊桥动画
    local dq_time = 0.0
    local function playDq(ticks)
        if dq_time > 0 then
            diaoqiao_ani:update(ticks)
            dq_time = dq_time - ticks
        end
    end


    local timeUp = CCDelayTime:create(0.01)
	local callBack = CCCallFunc:create(function() main_ani:update(0.01,0) end)
	local seq = CCSequence:createWithTwoActions(timeUp, callBack)
    layer:runAction(CCRepeat:create(seq, -1))
	main_ani:update(0, 0)

    local last_selected_sprite = 0
    local function onTavernClicked(clickedObj)
        audio.play(audio.town_entry_tavern)
        last_selected_sprite = 0
        if clickedObj and not tolua.isnull(clickedObj) then
            clearShader(clickedObj, true)
        end
        if BUILD_ENTRIES_ENABLE and player.lv() < UNLOCK_TAVERN_LEVEL then
            showToast(string.format(i18n.global.func_need_lv.string, UNLOCK_TAVERN_LEVEL))
            return
        end
        replaceScene(require("ui.herotask.main").create())
    end
    local function onMarketClicked(clickedObj)
        audio.play(audio.town_entry_blackmarket)
        last_selected_sprite = 0
        if clickedObj and not tolua.isnull(clickedObj) then
            clearShader(clickedObj, true)
        end
        if BUILD_ENTRIES_ENABLE and player.lv() < UNLOCK_BLACKMARKET_LEVEL then
            showToast(string.format(i18n.global.func_need_lv.string, UNLOCK_BLACKMARKET_LEVEL))
            return
        end
        replaceScene(require("ui.blackmarket.main").create())
    end
    local function onAltarClicked(clickedObj)
        audio.play(audio.town_entry_devour)
        last_selected_sprite = 0
        if clickedObj and not tolua.isnull(clickedObj) then
            clearShader(clickedObj, true)
        end
        replaceScene(require("ui.devour.main").create())
    end
    local function onHforgeClicked(clickedObj)
        audio.play(audio.town_entry_heroforge)
        last_selected_sprite = 0
        if clickedObj and not tolua.isnull(clickedObj) then
            clearShader(clickedObj, true)
        end
        replaceScene(require("ui.heroforge.main").create())
    end
    local function onSummonClicked(clickedObj)
        audio.play(audio.town_entry_summon)
        last_selected_sprite = 0
        if clickedObj and not tolua.isnull(clickedObj) then
            clearShader(clickedObj, true)
        end
        replaceScene(require("ui.summon.main").create())
    end
    local function onStageClicked(clickedObj)
        audio.play(audio.town_entry_worldmap)
        last_selected_sprite = 0
        if clickedObj and not tolua.isnull(clickedObj) then
            clearShader(clickedObj, true)
        end
        replaceScene(require("ui.hook.main").create())
    end
    local function onBraveClicked(clickedObj)
        audio.play(audio.town_entry_airship)
        last_selected_sprite = 0
        if clickedObj and not tolua.isnull(clickedObj) then
            clearShader(clickedObj, true)
        end
        if BUILD_ENTRIES_ENABLE and player.lv() < UNLOCK_HERO_BRAVE then
            showToast(string.format(i18n.global.func_need_lv.string, UNLOCK_HERO_BRAVE))
            return
        end
        local databrave = require "data.brave"
        if (not databrave.isPull) or databrave.cd < os.time() then
            local params = {
                sid = player.sid,
            }
            addWaitNet()
            netClient:sync_brave(params, function(__data)
                delWaitNet()
        
                tbl2string(__data)
                databrave.init(__data)
                if layer and not tolua.isnull(layer) then
                    layer:addChild(require("ui.brave.main").create(), 1000)
                end
            end)
        else
            layer:addChild(require("ui.brave.main").create(), 1000)
        end
    end
    local function onCasinoClicked(clickedObj)
        audio.play(audio.town_entry_casino)
        last_selected_sprite = 0
        if clickedObj and not tolua.isnull(clickedObj) then
            clearShader(clickedObj, true)
        end
        layer:addChild((require"ui.casino.selectcasino").create(), 1000)
        --if BUILD_ENTRIES_ENABLE and player.lv() < UNLOCK_CASINO_LEVEL then
        --    showToast(string.format(i18n.global.func_need_lv.string, UNLOCK_CASINO_LEVEL))
        --    return
        --end
        --local params = {
        --    sid = player.sid,
        --    type = 1,
        --}
        --addWaitNet()
        --local casinodata = require"data.casino"
        --casinodata.pull(params, function(__data)
        --    delWaitNet()
        --    tbl2string(__data)
        --    if __data.status ~= 0 then
        --        showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
        --        return
        --    end
        --    casinodata.init(__data)
        --    replaceScene(require("ui.casino.main").create())
        --end)
    end
    local function onSmithClicked(clickedObj) 
        audio.play(audio.town_entry_smith)
        last_selected_sprite = 0
        if clickedObj and not tolua.isnull(clickedObj) then
            clearShader(clickedObj, true)
        end
        replaceScene(require("ui.smith.main").create())
    end
    local function onArenaClicked(clickedObj)
        audio.play(audio.town_entry_arena)
        last_selected_sprite = 0
        if clickedObj and not tolua.isnull(clickedObj) then
            clearShader(clickedObj, true)
        end
        if BUILD_ENTRIES_ENABLE and player.lv() < UNLOCK_ARENA_LEVEL then
            showToast(string.format(i18n.global.func_need_lv.string, UNLOCK_ARENA_LEVEL))
            return
        end
        
        layer:addChild((require"ui.arena.entrance").create(), 1000)
    end
    local function onOblivionClicked(clickedObj)
        audio.play(audio.town_entry_trial)
        last_selected_sprite = 0
        if clickedObj and not tolua.isnull(clickedObj) then
            clearShader(clickedObj, true)
        end
        if BUILD_ENTRIES_ENABLE and player.lv() < UNLOCK_TRIAL_LEVEL then
            showToast(string.format(i18n.global.func_need_lv.string, UNLOCK_TRIAL_LEVEL))
            return
        end
        replaceScene(require("ui.trial.main").create())
    end
    local function onGodTreeClicked(clickedObj)
        audio.play(audio.town_entry_trial)
        last_selected_sprite = 0
        if clickedObj and not tolua.isnull(clickedObj) then
            clearShader(clickedObj, true)
        end
        if BUILD_ENTRIES_ENABLE and player.lv() < UNLOCK_GTREE_LEVEL then
            showToast(string.format(i18n.global.func_need_lv.string, UNLOCK_GTREE_LEVEL))
            return
        end

        layer.mainuiLayer:addChild((require"ui.summonspe.main").create(), 1000)
    end
    local function onDilaoClicked(clickedObj)
        audio.play(audio.town_entry_trial)
        --showToast(i18n.global.not_opened_yet.string)
        --if true then return end
        last_selected_sprite = 0
        if clickedObj and not tolua.isnull(clickedObj) then
            clearShader(clickedObj, true)
        end
        if BUILD_ENTRIES_ENABLE and player.lv() < UNLOCK_SOLO_LEVEL then
            showToast(string.format(i18n.global.func_need_lv.string, UNLOCK_SOLO_LEVEL))
            return
        end
        -- 单挑赛界面数据
        addWaitNet()
        local params = {sid = player.sid}
        net:spk_sync(params, function (data) 
            delWaitNet()
            print("时间为"..data.cd)
            print("返回数据")
            tablePrint(data)
            tbl2string(data)
            local soloData = require("data.solo")
            soloData.init()
            if data.status == 1 or data.status == 2 then      --进入单挑赛界面
                if soloData.getStatus() == 0 then
                    soloData.setSelectOrder(nil)
                end
                soloData.setMainData(data)
                replaceScene(require("ui.solo.main").create())    
            elseif data.status == 0 then  --不能进入
                soloData.setSelectOrder(nil)
                soloData.setMainData(data)
                replaceScene(require("ui.solo.noStartUI").create())
            end
                --     soloData.setSelectOrder(nil)
        
                -- soloData.setMainData(data)
                -- replaceScene(require("ui.solo.main").create())    
        end)
        -- -- 进入的测试数据
        -- local data  = {}
        -- data.status = 0
        -- data.cd     = 100
        -- print("时间为"..data.cd)
        -- data.camp = {{base = {hid = 8 , id = 4306 ,lv = 1, star = 0 ,energy = 50 , hpp = 60}, buf = {{id = 1,num = 20},{id = 2,num = 15},{id = 3,num = 20}}},
        --              {base = {hid = 37 ,id = 4402 ,lv = 1, star = 0 ,energy = 100, hpp = 80}, buf = {{id = 1,num = 11},{id = 2,num = 16},{id = 3,num = 19}}},
        --              {base = {hid = 43 ,id = 4403 ,lv = 1, star = 0 ,energy = 1  , hpp = 10}, buf = {{id = 1,num = 12},{id = 2,num = 17},{id = 3,num = 18}}},
        --              {base = {hid = 34 ,id = 4403 ,lv = 1, star = 0 ,energy = 40 , hpp = 20},buf = {{id = 1,num = 13},{id = 2,num = 18},{id = 3,num = 17}}},
        --              {base = {hid = 12 ,id = 4502 ,lv = 1, star = 0 ,energy = 30 , hpp = 0},buf = {{id = 1,num = 14},{id = 2,num = 19},{id = 3,num = 16}}},
        --              -- {base = {hid = 8 , id = 4306 ,lv = 1, star = 0 ,energy = 100, hpp = 100}},
        --              -- {base = {hid = 37 ,id = 4402 ,lv = 1, star = 0 ,energy = 100, hpp = 100}},
        --              -- {base = {hid = 43 ,id = 4403 ,lv = 1, star = 0 ,energy = 100, hpp = 100}}, 
        --              -- {base = {hid = 34 ,id = 4403 ,lv = 1, star = 0 ,energy = 100, hpp = 100}},
        --             }      
        -- data.estage = 1
        -- data.ehpp   = {[1] = 100 , [2] = 20, [3] = 50, [4] = 0 }
        -- data.buf    = nil
        -- data.seller = nil
        -- data.wave   = 1    
        -- local soloData = require("data.solo")
        -- soloData.init()
        -- soloData.setMainData(data)
        -- replaceScene(require("ui.solo.main").create())
    end

    local function onKongdaoClicked(clickedObj)
         --if true then
         --    showToast(i18n.global.guild_func_waiting.string) 
         --    return
         --end
        last_selected_sprite = 0
        if clickedObj and not tolua.isnull(clickedObj) then
            clearShader(clickedObj, true)
        end
        if BUILD_ENTRIES_ENABLE and player.lv() < UNLOCK_AIRISLAND_LEVEL then
            showToast(string.format(i18n.global.func_need_lv.string, UNLOCK_AIRISLAND_LEVEL))
            return
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

    local buildings = {
        [1] = {
            name = "tarven",
            jsonName = json.ui.main_jiuguan,
            code_name = "code_jiuguan",
            lbl = i18n.global.town_building_tavern.string,
            lbl_lv = UNLOCK_TAVERN_LEVEL,
            size = CCSizeMake(100, 200),
            tapFunc = onTavernClicked,
        },
        [2] = {
            name = "blackmarket",
            jsonName = json.ui.main_heishi,
            lbl = i18n.global.town_building_bm.string,
            lbl_lv = UNLOCK_BLACKMARKET_LEVEL,
            code_name = "code_heishi",
            size = CCSizeMake(100, 200),
            tapFunc = onMarketClicked,
        },
        [3] = {
            name = "altar",
            jsonName = json.ui.main_tunshi,
            lbl = i18n.global.town_building_altar.string,
            lbl_lv = 0,
            code_name = "code_tunshi",
            size = CCSizeMake(100, 200),
            tapFunc = onAltarClicked,
        },
        [4] = {
            name = "summon",
            jsonName = json.ui.main_zhaohuan,
            lbl = i18n.global.town_building_summon.string,
            lbl_lv = 0,
            code_name = "code_zhaohuan",
            size = CCSizeMake(100, 200),
            tapFunc = onSummonClicked,
        },
        [5] = {
            name = "stage",
            jsonName = json.ui.main_zhanzhengzm,
            lbl = i18n.global.town_building_stage.string,
            lbl_lv = 0,
            lbl_min_w = 160,
            code_name = "code_zhanyi",
            size = CCSizeMake(100, 200),
            tapFunc = onStageClicked,
        },
        [6] = {
            name = "casino",
            jsonName = json.ui.main_duchang,
            lbl = i18n.global.town_building_casino.string,
            lbl_lv = UNLOCK_CASINO_LEVEL,
            code_name = "code_duchang",
            size = CCSizeMake(100, 200),
            tapFunc = onCasinoClicked,
        },
        [7] = {
            name = "smith",
            jsonName = json.ui.main_tiejiangpu,
            lbl = i18n.global.town_building_smith.string,
            lbl_lv = 0,
            code_name = "code_tiejiangpu",
            size = CCSizeMake(100, 200),
            tapFunc = onSmithClicked,
        },
        [8] = {
            name = "trial",
            jsonName = json.ui.main_huanjing,
            lbl = i18n.global.town_building_oblivion.string,
            lbl_lv = UNLOCK_TRIAL_LEVEL,
            code_name = "code_chengbao",
            size = CCSizeMake(100, 200),
            tapFunc = onOblivionClicked,
        },
        [9] = {
            name = "arena",
            jsonName = json.ui.main_jjc,
            lbl = i18n.global.town_building_arena.string,
            lbl_lv = UNLOCK_ARENA_LEVEL,
            code_name = "code_jjc",
            size = CCSizeMake(100, 200),
            tapFunc = onArenaClicked,
        },
        [10] = {
            name = "hforge",
            jsonName = json.ui.main_summoning,
            lbl = i18n.global.town_building_hforge.string,
            lbl_lv = 0,
            code_name = "code_hecheng",
            size = CCSizeMake(100, 200),
            tapFunc = onHforgeClicked,
        },
        [11] = {
            name = "yuanzheng",
            jsonName = json.ui.main_yuanzheng,
            lbl = i18n.global.town_building_brave.string,
            lbl_lv = UNLOCK_HERO_BRAVE,
            code_name = "code_yuanzheng",
            size = CCSizeMake(100, 200),
            tapFunc = onBraveClicked,
        },
        [12] = {
            name = "gtree",
            jsonName = json.ui.main_tree,
            lbl = i18n.global.town_building_gtree.string,
            lbl_lv = UNLOCK_GTREE_LEVEL,
            code_name = "code_zhongjing",
            size = CCSizeMake(100, 200),
            tapFunc = onGodTreeClicked,
        },
        [13] = {
            name = "dilao",
            jsonName = json.ui.main_dilao,
            lbl = i18n.global.town_building_dungeon.string,
            lbl_lv = UNLOCK_SOLO_LEVEL,
            lbl_hide = false,
            code_name = "code_dilao",
            size = CCSizeMake(100, 200),
            tapFunc = onDilaoClicked,
        },
        [14] = {
            name = "redtree",
            jsonName = json.ui.main_hongshu,
            lbl = i18n.global.town_building_gtree.string,
            lbl_lv = 0,
            lbl_hide = true,
            code_name = "code_hongshu",
            size = CCSizeMake(100, 200),
        },
        [15] = {
            name = "kongzhan",
            jsonName = json.ui.kongzhan_rk1,
            lbl = i18n.global.town_building_airisland.string,
            lbl_lv = UNLOCK_AIRISLAND_LEVEL,
            lbl_hide = false,
            code_name = "code_kongzhan_rk1",
            size = CCSizeMake(100, 200),
            tapFunc = onKongdaoClicked,
        },
        [16] = {
            name = "rk2",
            jsonName = json.ui.kongzhan_rk2,
            lbl = i18n.global.town_building_gtree.string,
            lbl_lv = 0,
            lbl_hide = true,
            code_name = "code_kongzhan_rk2",
            size = CCSizeMake(100, 200),
        },
        [17] = {
            name = "rk3",
            jsonName = json.ui.kongzhan_rk3,
            lbl = i18n.global.town_building_gtree.string,
            lbl_lv = 0,
            lbl_hide = true,
            code_name = "code_kongzhan_rk3",
            size = CCSizeMake(100, 200),
        },
    }
    
    local buildingObjs = {}
    local lbl_buildings = {}  -- for red dot
    local lbl_spaces = 76
    local building_lbl_color = ccc3(0xfb, 0xe6, 0x7e)
    local function createBuildings()
        lbl_buildings = {}
        buildingObjs = {}
        for ii=1,#buildings do
            local to = buildings[ii]
            local bo = json.create(to.jsonName)
            bo.data = to
            buildingObjs[ii] = bo
            bo:playAnimation("animation", -1)
            main_ani:addChildFollowSlot(to.code_name, bo)
            local lbl_xxx= lbl.createFont2(18, to.lbl, building_lbl_color)
            local building_lbl_xxx = img.createUI9Sprite(img.ui.main_building_lbl)
            lbl_buildings[ii] = building_lbl_xxx
            local bd_size = lbl_xxx:boundingBox().size
            if to.lbl_min_w then
                if bd_size.width < to.lbl_min_w then
                    bd_size.width = to.lbl_min_w
                end
            end
            building_lbl_xxx:setPreferredSize(CCSizeMake(bd_size.width+lbl_spaces, 40))
            lbl_xxx:setPosition(CCPoint(building_lbl_xxx:getContentSize().width/2, building_lbl_xxx:getContentSize().height/2))
            building_lbl_xxx:addChild(lbl_xxx)
            main_ani:addChildFollowSlot(to.code_name .. "_lbl", building_lbl_xxx)
            if to.lbl_hide then
                building_lbl_xxx:setVisible(false)
            end
            if to.lbl then
                if to.lbl_lv and to.lbl_lv > player.lv() then
                    building_lbl_xxx:setVisible(false)
                end
            end
        end
    end

    createBuildings()
    
    --local particle_scale = view.minScale
    --local shine_particle = particle.create("zhuchangjing_winter")
    --shine_particle:setStartSize(particle_scale * (shine_particle:getStartSize()))
    --shine_particle:setStartSizeVar(particle_scale * shine_particle:getStartSizeVar())
    --shine_particle:setEndSize(particle_scale * shine_particle:getEndSize())
    --shine_particle:setEndSizeVar(particle_scale * shine_particle:getEndSizeVar())
    --layer:addChild(shine_particle, 110)
    --shine_particle:setPosition(scalep(480, 576))

    -- testBtn
    if TEST_ENTRY_ENABLE then
        local testBtn = CCMenuItemFont:create("TEST")
        testBtn:setScale(view.minScale)
        testBtn:setColor(ccc3(0xff, 0x00, 0x00))
        testBtn:setPosition(scalep(600, 490))
        local testMenu = CCMenu:createWithItem(testBtn)
        testMenu:setPosition(0, 0)
        layer:addChild(testMenu)
        testBtn:registerScriptTapHandler(function()
            replaceScene(require("ui.test.main").create())
        end)
    end

    local mainui = require "ui.town.mainui"
    local mainuiLayer = mainui.create(uiparams)
    layer:addChild(mainuiLayer, 100)
    layer.mainuiLayer = mainuiLayer


    local beginX = 0
    local beginY = 0
    local isClick = false
    local currenX = 0
    local allTime = lastAllTime or 0
    local function slideUpdate(x, uT)
        local real_uT = uT
        if real_uT < 0 then
            real_uT = real_uT + 4
        end
        main_ani:update(0, real_uT)
        if not require("data.tutorial").exists() then
            allTime = allTime + uT
            lastAllTime = allTime
            if allTime >= 1 then
                allTime = 1
            elseif allTime <= -1 then
                allTime = -1
            end
        else
        end
        currenX = x
    end

    local function onTouchBegan(x, y)
        local po = bg:convertToNodeSpace(CCPoint(x, y))
        dq_time = 3.0
        beginX = po.x
        beginY = po.y
        isClick = true
        currenX = po.x
        for ii=1,#buildingObjs do
            local tObj = buildingObjs[ii]
            if tObj.data.tapFunc and tObj:getAabbBoundingBox():containsPoint(CCPoint(x, y)) then
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
            isClick = false
            if last_selected_sprite ~= 0 then
                clearShader(last_selected_sprite, true)
                last_selected_sprite = 0
            end
        end
        local deltaX = po.x - currenX 
        local uT = deltaX/300.0
        if allTime + uT <= 1 and allTime + uT >= -1 then
            slideUpdate(po.x, uT)
        else
            currenX = po.x
        end
    end
    local function onTouchEnded(x, y)
        if not isClick then return end
        for ii=1,#buildingObjs do
            local tObj = buildingObjs[ii]
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

    addBackEvent(layer, function()
        print("townlayer back event")
    end)

    local function onEnter()
        layer.name = "townlayer"
        -- set layer position
        if lastAllTime and lastAllTime ~= 0 then
            if not require("data.tutorial").exists() then
                allTime = 0
                layer.setOffsetTime(lastAllTime)
            end
        else
        end
    end
    layer:registerScriptHandler(function(event)
        if event == "enter" then
            onEnter()
        elseif event == "exit" then
        end
    end)
    
    function layer.setOffsetTime(_t)
        main_ani:unregisterAnimation("slide")
        main_ani:registerAnimation("slide", -1)
        slideUpdate(0, _t)
    end
    function layer.setOffsetX(_xPos)
        lastAllTime = 0
        allTime = 0
        local uT = (_xPos)/-480.0
        print("------------_xPos,uT:", _xPos, uT)
        --slideUpdate(0, 0-allTime+uT)
        layer.setOffsetTime(uT)
    end

    local tutorialData = require("data.tutorial")
    local tutorialUI = require("ui.tutorial")
    if tutorialData.getVersion() == 1 and tutorialData.is("rename") then 
        layer:addChild(require("ui.player.changename").create(true), 10000)
    end

    if tutorialData.getVersion() == 2 then 
        tutorialUI.setTownMainUILayer(mainuiLayer)
    end

    tutorialUI.show("ui.town.main", layer)

    local function onUpdate(ticks)
        if main_ani and not tolua.isnull(main_ani) then
            main_ani:update(ticks, 0)
        end
        playDq(ticks)
        -- check reddot
        local gachaData = require "data.gacha"
        if gachaData.showRedDot() then
            addRedDot(lbl_buildings[4], {
                px=lbl_buildings[4]:getContentSize().width-10,
                py=lbl_buildings[4]:getContentSize().height-5,
            })
        else
            delRedDot(lbl_buildings[4])
        end

        local herotaskData = require "data.herotask"
        if herotaskData.showRedDot() then
            addRedDot(lbl_buildings[1], {
                px=lbl_buildings[1]:getContentSize().width-10,
                py=lbl_buildings[1]:getContentSize().height-5,
            })
        else
            delRedDot(lbl_buildings[1])
        end

        local braveData = require "data.brave"
        if braveData.showRedDot() then
            addRedDot(lbl_buildings[11], {
                px=lbl_buildings[11]:getContentSize().width-10,
                py=lbl_buildings[11]:getContentSize().height-5,
            })
            local userdata = require "data.userdata"
            local hids = { 0, 0, 0, 0, 0, 0 ,-1}
            userdata.setSquadBrave(hids)
        else
            delRedDot(lbl_buildings[11])
        end

        -- 单挑赛
        local soloData = require "data.solo"
        if soloData.showRedDot() then
            addRedDot(lbl_buildings[13], {
                px=lbl_buildings[13]:getContentSize().width-10,
                py=lbl_buildings[13]:getContentSize().height-5,
            })
        else
            delRedDot(lbl_buildings[13])
        end

        -- 空岛
        local airData = require "data.airisland"
        if airData.showRedDot() then
            addRedDot(lbl_buildings[15], {
                px=lbl_buildings[15]:getContentSize().width-10,
                py=lbl_buildings[15]:getContentSize().height-5,
            })
        else
            delRedDot(lbl_buildings[15])
        end
    end
    layer:scheduleUpdateWithPriorityLua(onUpdate, 0)

    -- sdk 上报创建角色信息
    if not tutorialData.isFinished("rename") then 
        gSubmitRoleData({roleLevel=1, stype="enterServer"})
    elseif isChannel() then 
        local cfg = require"common.sdkcfg"
        if cfg[APP_CHANNEL] and cfg[APP_CHANNEL].need_submit then
            cfg[APP_CHANNEL].need_submit = nil
            gSubmitRoleData({roleLevel = player.lv(), stype="enterServer"})
        end
        if cfg[APP_CHANNEL] and cfg[APP_CHANNEL].checkRts then
            cfg[APP_CHANNEL].checkRts()
        end
        if APP_CHANNEL == "WUFAN" then
            cfg[APP_CHANNEL].init()
        end
    end

    -- appsflyer report self install event
    if reportInstall then
        reportInstall()
    end

    require("data.gvar").checkAppStore()

    --防沉迷
    local prevent_addiction = require "data.preventaddiction"
    if tutorialData.isComplete() and prevent_addiction.shouldShowDialog() and
            prevent_addiction.needPreventAddiction() then
        layer:addChild(require("ui.town.PreventAddictionDialog").create(layer), 1000)
    end

    return layer
end

return ui
