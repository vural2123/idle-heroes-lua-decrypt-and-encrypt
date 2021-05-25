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
local NetClient = require "net.netClient"
local netClient = NetClient:getInstance()
local tipsequip = require "ui.tips.equip"
local tipsitem = require "ui.tips.item"
local bag = require "data.bag"

function ui.create()
	local IDS = activityData.IDS
	local ItemType = {
		Item = 1,
		Equip = 2,
	}

	local dwarf1 = IDS.DWARF_1.ID
	local dwarfmaxcount = 5

    local layer = CCLayer:create()

    local acts = {}
    for i=1, dwarfmaxcount do
        local tmp_status = activityData.getStatusById(dwarf1 + i - 1)
		if tmp_status then
			acts[#acts+1] = tmp_status
		else
			break
		end
    end

    local board = CCSprite:create()
    board:setContentSize(CCSizeMake(570, 438))
    board:setScale(view.minScale)
    board:setAnchorPoint(CCPoint(0, 0))
    board:setPosition(scalep(352, 57))
    layer:addChild(board)
    --drawBoundingbox(layer, board)
    local board_w = board:getContentSize().width
    local board_h = board:getContentSize().height

    img.load(img.packedOthers.ui_activity_dwarf)
    --img.unload(img.packedOthers.ui_activity_dwarf)
    --if i18n.getCurrentLanguage() == kLanguageChinese then
    --    img.load(img.packedOthers.ui_activity_forge_cn)
    --else
    --    img.load(img.packedOthers.ui_activity_forge)
    --end
    local banner = img.createUISprite("activity_dwarves_board.png")
    banner:setAnchorPoint(CCPoint(0.5, 1))
    banner:setPosition(CCPoint(board_w/2, board_h-18))
    board:addChild(banner)

    local bannerLabel
    if i18n.getCurrentLanguage() == kLanguageKorean then
        bannerLabel = img.createUISprite("activity_dwarves_kr.png")
    elseif i18n.getCurrentLanguage() == kLanguageChineseTW then
        bannerLabel = img.createUISprite("activity_dwarves_tw.png")
    elseif i18n.getCurrentLanguage() == kLanguageJapanese then
        bannerLabel = img.createUISprite("activity_dwarves_jp.png")
    elseif i18n.getCurrentLanguage() == kLanguageRussian then
        bannerLabel = img.createUISprite("activity_dwarves_ru.png")
    elseif i18n.getCurrentLanguage() == kLanguagePortuguese then
        bannerLabel = img.createUISprite("activity_dwarves_pt.png")
    elseif i18n.getCurrentLanguage() == kLanguageChinese then
        bannerLabel = img.createUISprite("activity_dwarves_cn.png")
    else
        bannerLabel = img.createUISprite("activity_dwarves_en.png")
    end
    bannerLabel:setAnchorPoint(CCPoint(0.5, 1))
    bannerLabel:setPosition(CCPoint(375, 408))
    board:addChild(bannerLabel)

    local lbl_cd_des = lbl.createFont2(14, i18n.global.activity_to_end.string)
    lbl_cd_des:setAnchorPoint(CCPoint(0, 0.5))
    lbl_cd_des:setPosition(CCPoint(352, 20))
    banner:addChild(lbl_cd_des)
    local lbl_cd = lbl.createFont2(14, "", ccc3(0xa5, 0xfd, 0x47))
    lbl_cd:setAnchorPoint(CCPoint(1, 0.5))
    lbl_cd:setPosition(CCPoint(lbl_cd_des:boundingBox():getMinX()-6, 20))
    banner:addChild(lbl_cd)

    if i18n.getCurrentLanguage() == kLanguageRussian then
        lbl_cd_des:setPosition(CCPoint(352-76, 20))
        lbl_cd:setAnchorPoint(CCPoint(0, 0.5))
        lbl_cd:setPosition(CCPoint(lbl_cd_des:boundingBox():getMaxX()+10, 20))
    end

    local itemParams = {}
    local showGem = {}
    local showCoin = {}
    local coinNum = {}
    local gemNum = {}
    local function updateCallback(pos, limitLabel)
        limitLabel:setString(i18n.global.limitact_limit.string .. acts[pos].limits)
        if acts[pos].limits < 1 then
            setShader(itemParams[pos].btnMake, SHADER_GRAY, true)
            itemParams[pos].btnMake:setEnabled(false)
        end
        for posi = pos,#itemParams do
            for i=1, #itemParams[posi]._equipsLabel do
                itemParams[posi]._equipsLabel[i]:setString(itemParams[posi].equipNum[i] .. "/1")
                if itemParams[posi].equipNum[i] < 1 then
                    itemParams[posi]._equipsLabel[i]:setColor(ccc3(0xfa, 0x35, 0x35))
                else
                    itemParams[posi]._equipsLabel[i]:setColor(ccc3(0xc3, 0xff, 0x42))
                end
            end
            local flagbtn = true

            for i=1, #itemParams[posi]._equipsLabel do
                if itemParams[posi].equipNum[i] < 1 then
                    setShader(itemParams[posi].btnMake, SHADER_GRAY, true)
                    itemParams[posi].btnMake:setEnabled(false)
                    flagbtn = false
                    break
                end
            end
            if flagbtn and acts[posi].limits > 0 and coinNum[posi] <= bag.coin() and gemNum[posi] <= bag.gem() then
                --setShader(itemParams[posi].btnMake, SHADER_GRAY, true)
                clearShader(itemParams[posi].btnMake, true)
                itemParams[posi].btnMake:setEnabled(true)
            end
        end
    end

    local function createSurebuy(vpObj, cfg, pos, limitLabel)
        local params = {}
        params.btn_count = 0
        params.body = string.format(i18n.global.dwarf_sure.string, 20)
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

        btnYes:registerScriptTapHandler(function()
            dialoglayer:removeFromParentAndCleanup(true)
            --if acts[i].limits < 1 then
            --    showToast(i18n.global.pet_smaterial_not_enough.string)
            --    return
            --end
            if gemNum[pos] > bag.gem() then
                showToast(i18n.global.gboss_fight_st6.string)
                return
            end
            if coinNum[pos] > bag.coin() then
                showToast(i18n.global.crystal_toast_coin.string)
                return
            end
            local param = {
                sid = player.sid,
                id = vpObj.id,
            } 
            tbl2string(param)
            addWaitNet()
            netClient:dwarf(param, function(__data)
                delWaitNet()
                tbl2string(__data)
                if __data.status < 0 then
                    --showToast("status:" .. __data.status)
                    showToast(i18n.global.pet_smaterial_not_enough.string)
                    return
                end
                for ii = 1,#cfg.extra do
                    local _obj = cfg.extra[ii]
                    if _obj.type == ItemType.Equip then  -- equip
                        bag.equips.sub({id = _obj.id, num = _obj.num})
                    else
                        bag.items.sub({id = _obj.id, num = _obj.num})
                    end
                end
                local reward = {items = {}, equips = {}}
                for ii = 1,#cfg.rewards do
                    local _obj = cfg.rewards[ii]
                    bag.equips.add({id = _obj.id, num = _obj.num})
                    table.insert(reward.equips, {id = _obj.id, num = _obj.num})
                end
                acts[pos].limits = acts[pos].limits - 1
                for ii=1,#itemParams[pos].equipNum do
                    itemParams[pos].equipNum[ii] = itemParams[pos].equipNum[ii] - 1
                end
                if pos < #itemParams then
                    for ii=1,#itemParams[pos+1].equipNum do
                        itemParams[pos+1].equipNum[ii] = itemParams[pos+1].equipNum[ii] + 1
                    end
                end
                updateCallback(pos, limitLabel)
                layer:getParent():getParent():addChild((require"ui.hook.drops").create(reward, i18n.global.reward_will_get.string, true), 1000)
            end)
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

    local function createItem(vpObj, i)
        local temp_item = img.createUI9Sprite(img.ui.bottom_border_2)
        temp_item:setPreferredSize(CCSizeMake(550, 205))
        local item_w = temp_item:getContentSize().width
        local item_h = temp_item:getContentSize().height

        local cfg = vpObj.cfg
        local sx, dx = 60, 72
        local equipNum = {}
        local _equipsLabel = {}
        for ii = 3,#cfg.extra do
            local _obj = cfg.extra[ii]
            if _obj.type == ItemType.Equip then  -- equip
                local _item0 = img.createEquip(_obj.id)
                local _item = CCMenuItemSprite:create(_item0, nil)
                _item:setScale(0.7)
                _item:setPosition(CCPoint(sx+(ii-3)*dx, 145))
                equipNum[ii-2] = 0
                if bag.equips.find(_obj.id) then
                    equipNum[ii-2] = bag.equips.find(_obj.id).num
                end
                _equipsLabel[ii-2] = lbl.createFont2(14, equipNum[ii-2] .. "/1", ccc3(0xc3, 0xff, 0x42))
                _equipsLabel[ii-2]:setAnchorPoint(ccp(1, 0))
                _equipsLabel[ii-2]:setPosition(70, 10)
                _item:addChild(_equipsLabel[ii-2])
                if equipNum[ii-2] < 1 then
                    _equipsLabel[ii-2]:setColor(ccc3(0xfa, 0x35, 0x35))
                end
                itemParams[i] = {}
                itemParams[i].equipNum = equipNum
                itemParams[i]._equipsLabel = _equipsLabel
                local _item_menu = CCMenu:createWithItem(_item)
                _item_menu:setPosition(CCPoint(0, 0))
                temp_item:addChild(_item_menu)
                _item:registerScriptTapHandler(function()
                    audio.play(audio.button)
                    layer:getParent():getParent():addChild(tipsequip.createById(_obj.id), 1000)
                end)
            elseif _obj.type == ItemType.Item then
                --local _item0 = img.createItem(_obj.id, _obj.num)
                --local _item = CCMenuItemSprite:create(_item0, nil)
                --_item:setScale(0.7)
                --_item:setPosition(CCPoint(sx+(ii-3)*dx, 145))
                ----if acts[i].limits == 0 then
                ----    setShader(_item, SHADER_GRAY, true)
                ----end
                --local _item_menu = CCMenu:createWithItem(_item)
                --_item_menu:setPosition(CCPoint(0, 0))
                --temp_item:addChild(_item_menu)
                --_item:registerScriptTapHandler(function()
                --    audio.play(audio.button)
                --    layer:getParent():getParent():addChild(tipsitem.createForShow({id=_obj.id}), 1000)
                --end)
            end
             
            local raw = img.createUISprite(img.ui.activity_dwarf_raw)
            --head:setScale(0.85)
            raw:setPosition(CCPoint(sx+(ii-3)*dx, item_h/2))
            temp_item:addChild(raw)
        end

        for ii = 1,#cfg.rewards do
            local _obj = cfg.rewards[ii]
            if _obj.type == ItemType.Equip then  -- equip
                local _item0 = img.createEquip(_obj.id, 1)
                local _item = CCMenuItemSprite:create(_item0, nil)
                _item:setScale(0.7)
                _item:setPosition(CCPoint(sx+(ii-1)*dx, 60))

                --local itemLabel = lbl.createMixFont1()
                local _item_menu = CCMenu:createWithItem(_item)
                _item_menu:setPosition(CCPoint(0, 0))
                temp_item:addChild(_item_menu)
                _item:registerScriptTapHandler(function()
                    audio.play(audio.button)
                    layer:getParent():getParent():addChild(tipsequip.createById(_obj.id), 1000)
                end)
            elseif _obj.type == ItemType.Item then
                local _item0 = img.createItem(_obj.id, 1)
                local _item = CCMenuItemSprite:create(_item0, nil)
                _item:setScale(0.7)
                _item:setPosition(CCPoint(sx+(ii-1)*dx, 60))
                --if acts[i].limits == 0 then
                --    setShader(_item, SHADER_GRAY, true)
                --end
                local _item_menu = CCMenu:createWithItem(_item)
                _item_menu:setPosition(CCPoint(0, 0))
                temp_item:addChild(_item_menu)
                _item:registerScriptTapHandler(function()
                    audio.play(audio.button)
                    layer:getParent():getParent():addChild(tipsitem.createForShow({id=_obj.id}), 1000)
                end)
            end
        end

        -- 金币钻石
        local coincostbg = img.createUI9Sprite(img.ui.hero_evolve_cost_bg)
        coincostbg:setPreferredSize(CCSize(138, 32))
        coincostbg:setPosition(442, 155)
        temp_item:addChild(coincostbg)
        local coinIcon = img.createItemIcon2(ITEM_ID_COIN)
        coinIcon:setScale(0.8)
        coinIcon:setPosition(7, coincostbg:getContentSize().height/2)
        coincostbg:addChild(coinIcon)
        
        coinNum[i] = cfg.extra[1].num

        showCoin[i] = lbl.createFont2(16, num2KM(cfg.extra[1].num), ccc3(0xff, 0xf7, 0xe5))
        showCoin[i]:setPosition(coincostbg:getContentSize().width/2 + 5, coincostbg:getContentSize().height/2)
        coincostbg:addChild(showCoin[i])

        local gemcostbg = img.createUI9Sprite(img.ui.hero_evolve_cost_bg)
        gemcostbg:setPreferredSize(CCSize(138, 32))
        gemcostbg:setPosition(442, 115)
        temp_item:addChild(gemcostbg)
        local gemIcon = img.createItemIcon2(ITEM_ID_GEM)
        gemIcon:setScale(0.8)
        gemIcon:setPosition(7, gemcostbg:getContentSize().height/2)
        gemcostbg:addChild(gemIcon)

        gemNum[i] = cfg.extra[2].num
        showGem[i] = lbl.createFont2(16, num2KM(cfg.extra[2].num), ccc3(0xff, 0xf7, 0xe5))
        showGem[i]:setPosition(gemcostbg:getContentSize().width/2 + 5, gemcostbg:getContentSize().height/2)
        gemcostbg:addChild(showGem[i])

        local limitLabel = lbl.createFont1(14, i18n.global.limitact_limit.string .. acts[i].limits, ccc3(0x73, 0x3b, 0x05))
        limitLabel:setPosition(CCPoint(442, 82))
        temp_item:addChild(limitLabel)

        local makeSprite = img.createLogin9Sprite(img.login.button_9_small_gold)
        makeSprite:setPreferredSize(CCSize(145, 45))
        local btnMake = SpineMenuItem:create(json.ui.button, makeSprite)
        btnMake:setPosition(442, 50)
        local labMake = lbl.createFont1(18, i18n.global.activity_dwarf_btn.string, ccc3(0x73, 0x3b, 0x05))
        labMake:setPosition(btnMake:getContentSize().width/2, btnMake:getContentSize().height/2)
        makeSprite:addChild(labMake)
        local menuMake = CCMenu:create()
        menuMake:setPosition(0, 0)
        menuMake:addChild(btnMake)
        temp_item:addChild(menuMake)

        itemParams[i].btnMake = btnMake
        if acts[i].limits < 1 then
            setShader(btnMake, SHADER_GRAY, true)
            btnMake:setEnabled(false)
        end

        for ii=1,#equipNum do
            if equipNum[ii] < 1 then
                setShader(btnMake, SHADER_GRAY, true)
                btnMake:setEnabled(false)
                break 
            end
        end

        btnMake:registerScriptTapHandler(function()
            audio.play(audio.button)
            local surebuy = createSurebuy(vpObj, cfg, i, limitLabel, itemParams)
            layer:addChild(surebuy, 300)
        end)

        return temp_item
    end

    local lineScroll = require "ui.lineScroll"
    local scroll_params = {
        width = 550,
        height = 235,
    }
    local scroll = lineScroll.create(scroll_params)
    scroll:setAnchorPoint(CCPoint(0, 0))
    scroll:setPosition(CCPoint(10, 6))
    board:addChild(scroll)
    layer.scroll = scroll

    --local function sortValue(_obj)
    --    return _obj.id
    --end
    --table.sort(acts, function(a, b)
    --    return sortValue(a) < sortValue(b)
    --end)
    
    local function showList(listObjs)
        for ii=1,#listObjs do
            if ii == 1 then
                scroll.addSpace(3)
            end
            local tmp_item = createItem(listObjs[ii], ii)
            tmp_item.obj = listObjs[ii]
            tmp_item.ax = 0.5
            tmp_item.px = scroll_params.width/2
            scroll.addItem(tmp_item)
            if ii ~= item_count then
                scroll.addSpace(0)
            end
        end
        scroll.setOffsetBegin()
    end
	
	for i=1, #acts do
		local v = acts[i]
		if not v.icon then
			if i % 2 == 1 then
				v.icon = img.ui.activity_forge_head_icon1
			else
				v.icon = img.ui.activity_forge_head_icon2
			end
		end
		if not v.des then
			v.des = i18n.global.act_forge_task_6.string
		end
	end
    showList(acts)

    local act_st = activityData.getStatusById(dwarf1)

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

        if #coinNum >= 3 then 
            for ii = 1, #coinNum do
                if coinNum[ii] > bag.coin() then
                    showCoin[ii]:setColor(ccc3(0xfa, 0x35, 0x35))
                else
                    showCoin[ii]:setColor(ccc3(0xff, 0xf7, 0xe5))
                end
            end
        end
        if #gemNum >= 3 then   
            for ii = 1, #gemNum do
                if gemNum[ii] > bag.gem() then
                    showGem[ii]:setColor(ccc3(0xfa, 0x35, 0x35))
                else
                    showGem[ii]:setColor(ccc3(0xff, 0xf7, 0xe5))
                end
            end
        end
    end
    layer:scheduleUpdateWithPriorityLua(onUpdate, 0)

    --img.unload(img.packedOthers.ui_activity_summon)
    require("ui.activity.ban").addBan(layer, scroll)
    layer:setTouchSwallowEnabled(false)
    layer:setTouchEnabled(true)
    return layer
end

return ui
