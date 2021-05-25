local ui = {}

require "common.func"
require "common.const"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local audio = require "res.audio"
local cfgitem = require "config.item"
local cfgequip = require "config.equip"
local player = require "data.player"
local i18n = require "res.i18n"
local tipsequip = require "ui.tips.equip"
local tipsitem = require "ui.tips.item"
local dialog = require "ui.dialog"
local net = require "net.netClient"
local arena = require "data.arena"
local arenab = require "data.arenab"
local arena33 = require "data.3v3arena"
local frdarenaData = require "data.frdarena"
local cfgarena = require "config.arena"
local bag = require "data.bag"

local function getItems()
    return {
        [1] = {
            id = 1,
            icon = img.ui.friend_pvp_icon_putong,
            description = i18n.arena[1].name,
        },
        [2] = {
            id = 2,
            icon = img.ui.friend_pvp_icon,
            description = i18n.arena[2].name,
        },
        [3] = {
            id = 4,
            icon = img.ui.friend_pvp_icon_zudui,
            description = i18n.arena[4].name,
        }
		,[4] = {
            id = 5,
            icon = img.ui.friend_pvp_icon_zudui,
            description = i18n.arena[5].name,
        }
    }
end

function ui.create(ckind)
    local layer = CCLayer:create()
    -- dark bg
    local darkbg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    layer:addChild(darkbg)

    local kind = ckind or 1

    local all_items = getItems()
    local activity_items = {}
    local touch_items = {}
    local item_count = 0
    local padding = 5
    local item_width = 290
    local item_height = 70
	
	if player.iron and os.time() >= player.iron then
		player.iron = nil
	end

    local function init()
        local groups = {}
        for _, tmp_item in pairs(all_items) do
            --if tmp_item.group then
            --    if groups[tmp_item.group] then  -- 属于group组的活动，已经添加过了
            --    else
                    --local item_status = activityData.getStatusById(tmp_item.id)
            --        if item_status and item_status.status == 0  and item_status.cd and
            --                item_status.cd > os.time() - activityData.pull_time then
            --            item_count = item_count + 1
            --            activity_items[item_count] = tmp_item
            --            activity_items[item_count].status = item_status
            --            groups[tmp_item.group] = tmp_item.group
            --        elseif item_status and item_status.status == 0  and tmp_item.nocd then  -- 没有cd
            --            item_count = item_count + 1
            --            activity_items[item_count] = tmp_item
            --            activity_items[item_count].status = item_status
            --            groups[tmp_item.group] = tmp_item.group
            --        else
            --            print("======================================if 3")
            --        end
            --    end
            --end
        end
        --local function sortValue(_obj)
        --    if _obj.id == IDS.MONTH_LOGIN.ID then
        --        return 10000
        --    elseif _obj.id == IDS.MONTH_CARD.ID then
        --        return 9999
        --    elseif _obj.id == IDS.MINI_CARD.ID then
        --        return 9998
        --    else
        --        return _obj.id
        --    end
        --end
        --table.sort(activity_items, function(a, b)
        --    return sortValue(a) > sortValue(b)
        --end)
    end
    init()
    local bg = img.createUI9Sprite(img.ui.dialog_2)
    bg:setPreferredSize(CCSizeMake(905, 462))
    bg:setScale(view.minScale)
    bg:setPosition(CCPoint(view.midX, view.midY-20*view.minScale))
    layer:addChild(bg)
    local bg_w = bg:getContentSize().width
    local bg_h = bg:getContentSize().height

    local ltitle = img.createUISprite(img.ui.friend_pvp_biaotiban)
    ltitle:setAnchorPoint(1, 0)
    ltitle:setPosition(bg_w/2, bg_h-5)
    bg:addChild(ltitle)
    local rtitle = img.createUISprite(img.ui.friend_pvp_biaotiban)
    rtitle:setFlipX(true)
    rtitle:setAnchorPoint(0, 0)
    rtitle:setPosition(bg_w/2, bg_h-5)
    bg:addChild(rtitle)

    local lblTitil = lbl.createFont1(24, i18n.global.town_building_arena.string, ccc3(0xfa, 0xd8, 0x69))
    lblTitil:setPosition(bg_w/2, bg_h+20)
    bg:addChild(lblTitil)

    local scroll_bg = img.createUI9Sprite(img.ui.inner_bg)
    scroll_bg:setPreferredSize(CCSizeMake(302, 398))
    scroll_bg:setAnchorPoint(CCPoint(0, 0))
    scroll_bg:setPosition(CCPoint(28, 36))
    bg:addChild(scroll_bg)

    local lineScroll = require "ui.lineScroll"
    local scroll_params = {
        width = 290,
        height = 390,
    }
    local scroll = lineScroll.create(scroll_params)
    scroll:setAnchorPoint(CCPoint(0, 0))
    scroll:setPosition(CCPoint(5, 0))
    scroll_bg:addChild(scroll)
    layer.scroll = scroll
    --drawBoundingbox(scroll_bg, scroll)

    local function createItem(item_obj)
        local tmp_item = img.createUISprite(img.ui.activity_item_bg)
        local tmp_item_w = tmp_item:getContentSize().width
        local tmp_item_h = tmp_item:getContentSize().height
        local tmp_item_sel = img.createUISprite(img.ui.activity_item_bg_sel)
        tmp_item_sel:setPosition(CCPoint(tmp_item_w/2, tmp_item_h/2))
        tmp_item:addChild(tmp_item_sel)
        tmp_item.sel = tmp_item_sel
        tmp_item_sel:setVisible(false)
        local item_icon = img.createUISprite(item_obj.icon)
        item_icon:setPosition(CCPoint(40, tmp_item_h/2))
        tmp_item:addChild(item_icon, 10)
        local lbl_description = lbl.create({
            font = 1, size = 16, text = item_obj.description, color = ccc3(0x73, 0x3b, 0x05),
            width = 200
        })
        --if item_obj.nocd then
            lbl_description:setAnchorPoint(CCPoint(0, 0.5))
            lbl_description:setPosition(CCPoint(88, tmp_item_h/2))
        --else
        --    lbl_description:setAnchorPoint(CCPoint(0, 0))
        --    lbl_description:setPosition(CCPoint(90, tmp_item_h/2))
        --end
        tmp_item:addChild(lbl_description, 2)
        --local lbl_cd = lbl.createFont2(14, "")
        --lbl_cd:setColor(ccc3(0xb5, 0xf4, 0x3b))
        --lbl_cd:setAnchorPoint(CCPoint(0, 1))
        --lbl_cd:setPosition(CCPoint(94, tmp_item_h/2-2))
        --tmp_item:addChild(lbl_cd)
        --tmp_item.lbl_cd = lbl_cd

        return tmp_item
    end

    local function showList(listObjs)
        for ii=1,#listObjs do
            local tmp_item = createItem(listObjs[ii])
            touch_items[#touch_items+1] = tmp_item
            tmp_item.obj = listObjs[ii]
            tmp_item.ax = 0.5
            tmp_item.px = 145
            scroll.addItem(tmp_item)
            if ii ~= item_count then
                scroll.addSpace(padding-3)
            end
        end
    end
    showList(all_items)


    bg:setScale(0.5*view.minScale)
    local anim_arr = CCArray:create()
    anim_arr:addObject(CCScaleTo:create(0.15, 1*view.minScale, 1*view.minScale))
    -- anim
    bg:runAction(CCSequence:create(anim_arr))

    local function backEvent()
        audio.play(audio.button)
        layer:removeFromParentAndCleanup(true)
    end

    -- btn_close
    local btn_close0 = img.createUISprite(img.ui.close)
    local btn_close = SpineMenuItem:create(json.ui.button, btn_close0)
    btn_close:setPosition(CCPoint(bg_w-25, bg_h-20))
    local btn_close_menu = CCMenu:createWithItem(btn_close)
    btn_close_menu:setPosition(CCPoint(0, 0))
    bg:addChild(btn_close_menu, 100)
    btn_close:registerScriptTapHandler(function()
        backEvent()
    end)

    local nodeNormal = cc.Node:create()
    nodeNormal:setPosition(CCPoint(0, 0))
    nodeNormal:setVisible(false)
    bg:addChild(nodeNormal, 1)

    local node3v3 = cc.Node:create()
    node3v3:setPosition(CCPoint(0, 0))
    node3v3:setVisible(false)
    bg:addChild(node3v3, 1)

    local nodeFriends = cc.Node:create()
    nodeFriends:setPosition(CCPoint(0, 0))
    nodeFriends:setVisible(false)
    bg:addChild(nodeFriends, 1)
	
	local nodeIron = cc.Node:create()
	nodeIron:setPosition(CCPoint(0, 0))
    nodeIron:setVisible(false)
    bg:addChild(nodeIron, 1)

    local barBg = img.createUI9Sprite(img.ui.botton_fram_2)
    barBg:setPreferredSize(CCSizeMake(535, 155))
    barBg:setPosition(344+267, 32+78)
    bg:addChild(barBg)

    local upboard = img.createUI9Sprite(img.ui.hero_up_bottom)
    upboard:setPreferredSize(CCSize(550, 240))
    upboard:setPosition(344+267, 315)
    bg:addChild(upboard)

    local function onShop()
        -- body
        local shop = require "ui.arena.shop"
        layer:addChild(shop.create(), 1000)
    end
    
    --normal node init
    if nodeNormal then
        local nodeBg = img.createUI9Sprite(img.ui.anrea_entrance_bg2)
        nodeBg:setPosition(CCPoint(344+267, 315))
        nodeNormal:addChild(nodeBg)

        local lblDes = lbl.createMix({size = 16, text = i18n.arena[1].des, color = ccc3(0x73, 0x3b, 0x05), width = 450})
        lblDes:setPosition(CCPoint(344+267, 150))
        nodeNormal:addChild(lblDes)

        -- btn_join
        local btn_join0 = img.createLogin9Sprite(img.login.button_9_small_mwhite)
        btn_join0:setPreferredSize(CCSizeMake(176, 48))
        local btn_join_sel = img.createLogin9Sprite(img.login.button_9_small_gold)
        btn_join_sel:setPreferredSize(CCSizeMake(176, 48))
        btn_join_sel:setPosition(CCPoint(btn_join0:getContentSize().width/2, btn_join0:getContentSize().height/2))
        btn_join0:addChild(btn_join_sel)
        local lbl_join = lbl.createFont1(18, i18n.global.arena_btn_join.string, ccc3(0x73, 0x3b, 0x05))
        lbl_join:setPosition(CCPoint(btn_join0:getContentSize().width/2, btn_join0:getContentSize().height/2))
        btn_join0:addChild(lbl_join)
        local btn_join = SpineMenuItem:create(json.ui.button, btn_join0)
        btn_join:setPosition(CCPoint(344+267, 83))
        local btn_join_menu = CCMenu:createWithItem(btn_join)
        btn_join_menu:setPosition(CCPoint(0, 0))
        nodeNormal:addChild(btn_join_menu)

        btn_join:registerScriptTapHandler(function()
            disableObjAWhile(btn_join)
            audio.play(audio.button)

            local params = {
                sid = player.sid        
            }
            addWaitNet()
            net:joinpvp_sync(params, function(__data)
                delWaitNet()
                tbl2string(__data)
                if __data.status == -1 then
                    layer:addChild(require("ui.selecthero.main").create({ type = "ArenaDef" }), 1000)  
                    layer:addChild(require("ui.selecthero.info").create(), 10000)
                elseif __data.status == -2 then
                    showToast(i18n.global.event_processing.string)
                else
                    local arenaData = require "data.arena"
                    arenaData.init(__data)
                    replaceScene(require("ui.arena.main").create())
                end
            end)
        end)
    end

    --3v3 node init
    if node3v3 then
        local nodeBg = img.createUI9Sprite(img.ui.anrea_entrance_bg1)
        nodeBg:setPosition(CCPoint(344+267, 315))
        node3v3:addChild(nodeBg)

        local lblDes = lbl.createMix({size = 16, text = i18n.arena[2].des, color = ccc3(0x73, 0x3b, 0x05), width = 520})
        lblDes:setPosition(CCPoint(344+267, 150))
        node3v3:addChild(lblDes)

        --shopbg
        local shopBg = img.createUI9Sprite(img.ui.friend_pvp_shopbg)
        shopBg:setAnchorPoint(1, 0)
        shopBg:setPosition(872, 201)
        node3v3:addChild(shopBg)

        --shop
        local btn_shop0 = img.createUI9Sprite(img.ui.friend_pvp_shop)
        local btn_shop = SpineMenuItem:create(json.ui.button, btn_shop0)
        btn_shop:setPosition(CCPoint(838, 236))
        local btn_shop_menu = CCMenu:createWithItem(btn_shop)
        btn_shop_menu:setPosition(CCPoint(0, 0))
        node3v3:addChild(btn_shop_menu)

        btn_shop:registerScriptTapHandler(function()
            audio.play(audio.button)

            onShop()
        end)

        -- btn_join
        local btn_join0 = img.createLogin9Sprite(img.login.button_9_small_mwhite)
        btn_join0:setPreferredSize(CCSizeMake(176, 48))
        local btn_join_sel = img.createLogin9Sprite(img.login.button_9_small_gold)
        btn_join_sel:setPreferredSize(CCSizeMake(176, 48))
        btn_join_sel:setPosition(CCPoint(btn_join0:getContentSize().width/2, btn_join0:getContentSize().height/2))
        btn_join0:addChild(btn_join_sel)
        local lbl_join = lbl.createFont1(18, i18n.global.arena_btn_join.string, ccc3(0x73, 0x3b, 0x05))
        lbl_join:setPosition(CCPoint(btn_join0:getContentSize().width/2, btn_join0:getContentSize().height/2))
        btn_join0:addChild(lbl_join)
        local btn_join = SpineMenuItem:create(json.ui.button, btn_join0)
        btn_join:setPosition(CCPoint(344+267, 83))
        local btn_join_menu = CCMenu:createWithItem(btn_join)
        btn_join_menu:setPosition(CCPoint(0, 0))
        node3v3:addChild(btn_join_menu)

        btn_join:registerScriptTapHandler(function()
            disableObjAWhile(btn_join)
            audio.play(audio.button)

            if BUILD_ENTRIES_ENABLE and player.lv() < UNLOCK_ARENA_3v3_LEVEL then
                showToast(string.format(i18n.global.func_need_lv.string, UNLOCK_ARENA_3v3_LEVEL))
                return
            end

            local params = {
                sid = player.sid        
            }
            addWaitNet()
            net:joinp3p_sync(params, function(__data)
                delWaitNet()

                --print("打印3v3竞技场的防守数据，为了宠物数据测试----begin5")
                --tablePrint(__data)
                --print("打印3v3竞技场的防守数据，为了宠物数据测试----end")

                tbl2string(__data)

                if __data.status == -1 then--开始了，未参加
                    layer:addChild(require("ui.3v3arena.select").create({ type = "3v3arenaDef" }), 1000)
                    --设置阵容
                elseif __data.status == 0 then--已经开始
                    local arena3v3Data = require "data.3v3arena"
                    arena3v3Data.init(__data)
                    replaceScene(require("ui.3v3arena.main").create())
                else
                    local btn = layer.btnJoin3v3
                    btn:setEnabled(false)
                    setShader(btn, SHADER_GRAY, true)
                end
            end)
        end)

        btn_join:setEnabled(false)
        layer.btnJoin3v3 = btn_join
        setShader(btn_join, SHADER_GRAY, true)

        local refreshTime = lbl.createFont2(16, "00:00:00", ccc3(0xa5, 0xfd, 0x47))
        refreshTime:setAnchorPoint(0, 0.5)
        refreshTime:setPosition(355+268, 230)
        node3v3:addChild(refreshTime)
        layer.refreshTime = refreshTime

        local desLabel = lbl.createFont2(16, "", ccc3(0xff, 0xf6, 0xd8))
        desLabel:setAnchorPoint(1, 0.5)
        desLabel:setPosition(355+268, 230)
        node3v3:addChild(desLabel)
        layer.desLabel = desLabel

        -- btn rank
        local btn_rank0 = img.createUISprite(img.ui.btn_rank)
        local btn_rank = SpineMenuItem:create(json.ui.button, btn_rank0)
        btn_rank:setPosition(255+130, 230)
        local btn_rank_menu = CCMenu:createWithItem(btn_rank)
        btn_rank_menu:setPosition(CCPoint(0, 0))
        node3v3:addChild(btn_rank_menu)
        btn_rank:registerScriptTapHandler(function()
            audio.play(audio.button)
            layer:addChild((require"ui.3v3arena.rank").create(), 1000)
        end)
        layer.btn_rank = btn_rank
        --layer.btn_rank:setVisible(false)
    end

    if nodeFriends then
        local nodeBg = img.createUI9Sprite(img.ui.anrea_entrance_bg3)
        nodeBg:setPosition(CCPoint(344+267, 315))
        nodeFriends:addChild(nodeBg)

        local lblDes = lbl.createMix({size = 16, text = i18n.arena[4].des, color = ccc3(0x73, 0x3b, 0x05), width = 520})
        lblDes:setPosition(CCPoint(344+267, 150))
        nodeFriends:addChild(lblDes)

        -- btn_join
        local btn_join0 = img.createLogin9Sprite(img.login.button_9_small_mwhite)
        btn_join0:setPreferredSize(CCSizeMake(176, 48))
        local btn_join_sel = img.createLogin9Sprite(img.login.button_9_small_gold)
        btn_join_sel:setPreferredSize(CCSizeMake(176, 48))
        btn_join_sel:setPosition(CCPoint(btn_join0:getContentSize().width/2, btn_join0:getContentSize().height/2))
        btn_join0:addChild(btn_join_sel)
        local lbl_join = lbl.createFont1(18, i18n.global.arena_btn_join.string, ccc3(0x73, 0x3b, 0x05))
        lbl_join:setPosition(CCPoint(btn_join0:getContentSize().width/2, btn_join0:getContentSize().height/2))
        btn_join0:addChild(lbl_join)
        local btn_join = SpineMenuItem:create(json.ui.button, btn_join0)
        btn_join:setPosition(CCPoint(344+267, 83))
        local btn_join_menu = CCMenu:createWithItem(btn_join)
        btn_join_menu:setPosition(CCPoint(0, 0))
        nodeFriends:addChild(btn_join_menu)

        btn_join:registerScriptTapHandler(function()
            disableObjAWhile(btn_join)
            audio.play(audio.button)

            if BUILD_ENTRIES_ENABLE and player.lv() < UNLOCK_ARENA_FRIEND_LEVEL then
                showToast(string.format(i18n.global.func_need_lv.string, UNLOCK_ARENA_FRIEND_LEVEL))
                return
            end

            local params = {
                sid = player.sid        
            }
            addWaitNet()
            net:gpvp_sync(params, function(__data)
                delWaitNet()
                tbl2string(__data)
                --local __data = layer.__data
                frdarenaData.init(__data)
                if __data.camp == nil then
                    layer:addChild(require("ui.selecthero.main").create({ type = "FrdArena" }), 1000)  
                    layer:addChild(require("ui.selecthero.info").create(), 10000)
                else
                    replaceScene(require("ui.frdarena.main").create())
                end
            end)

        end)

        btn_join:setEnabled(false)
        layer.btnJoinFriend = btn_join
        setShader(btn_join, SHADER_GRAY, true)

        local refreshTime1 = lbl.createFont2(16, "00:00:00", ccc3(0xa5, 0xfd, 0x47))
        refreshTime1:setAnchorPoint(0, 0.5)
        refreshTime1:setPosition(355+268, 230)
        nodeFriends:addChild(refreshTime1)
        layer.refreshTime1 = refreshTime1

        local desLabel1 = lbl.createFont2(16, "", ccc3(0xff, 0xf6, 0xd8))
        desLabel1:setAnchorPoint(1, 0.5)
        desLabel1:setPosition(355+268, 230)
        nodeFriends:addChild(desLabel1)
        layer.desLabel1 = desLabel1

        -- btn rank
        local btn_rank0 = img.createUISprite(img.ui.btn_rank)
        local btn_rank = SpineMenuItem:create(json.ui.button, btn_rank0)
        btn_rank:setPosition(255+130, 230)
        local btn_rank_menu = CCMenu:createWithItem(btn_rank)
        btn_rank_menu:setPosition(CCPoint(0, 0))
        nodeFriends:addChild(btn_rank_menu)
        btn_rank:registerScriptTapHandler(function()
            audio.play(audio.button)
            layer:addChild((require"ui.frdarena.rank").create(), 1000)
        end)
        layer.btn_rank1 = btn_rank
        --layer.btn_rank:setVisible(false)
    end
	
	--iron node init
    if nodeIron then
        local nodeBg = img.createUI9Sprite(img.ui.anrea_entrance_bg1)
        nodeBg:setPosition(CCPoint(344+267, 315))
        nodeIron:addChild(nodeBg)

        local lblDes = lbl.createMix({size = 16, text = i18n.arena[5].des, color = ccc3(0x73, 0x3b, 0x05), width = 520})
        lblDes:setPosition(CCPoint(344+267, 150))
        nodeIron:addChild(lblDes)

        -- btn_join
        local btn_join0 = img.createLogin9Sprite(img.login.button_9_small_mwhite)
        btn_join0:setPreferredSize(CCSizeMake(176, 48))
        local btn_join_sel = img.createLogin9Sprite(img.login.button_9_small_gold)
        btn_join_sel:setPreferredSize(CCSizeMake(176, 48))
        btn_join_sel:setPosition(CCPoint(btn_join0:getContentSize().width/2, btn_join0:getContentSize().height/2))
        btn_join0:addChild(btn_join_sel)
        local lbl_join = lbl.createFont1(18, i18n.global.arena_btn_join.string, ccc3(0x73, 0x3b, 0x05))
		local extrapush = 20
		if player.iron then extrapush = 0 end
        lbl_join:setPosition(CCPoint(btn_join0:getContentSize().width/2 + extrapush, btn_join0:getContentSize().height/2))
        btn_join0:addChild(lbl_join)
        local btn_join = SpineMenuItem:create(json.ui.button, btn_join0)
        btn_join:setPosition(CCPoint(344+267, 83))
        local btn_join_menu = CCMenu:createWithItem(btn_join)
        btn_join_menu:setPosition(CCPoint(0, 0))
        nodeIron:addChild(btn_join_menu)
		
		local ticketCost = 20
		if cfgarena[5].cost and #cfgarena[5].cost >= 1 then
			ticketCost = cfgarena[5].cost[1]
		end
		
		if not player.iron then
			local ticketIcon = img.createItemIcon(ITEM_ID_ARENA)
			ticketIcon:setScale(0.5)
			ticketIcon:setPosition(34, btn_join0:getContentSize().height/2)
			btn_join0:addChild(ticketIcon)
	   
			local showCost = lbl.createFont2(14, ticketCost)
			showCost:setPosition(34, btn_join0:getContentSize().height/2 - 10)
			btn_join0:addChild(showCost)
		end

        btn_join:registerScriptTapHandler(function()
            disableObjAWhile(btn_join)
            audio.play(audio.button)

			local needLv = 70
            if BUILD_ENTRIES_ENABLE and player.lv() < needLv then
                showToast(string.format(i18n.global.func_need_lv.string, needLv))
                return
            end
			
			if not player.iron then
				local tick_num = 0
				if bag.items.find(ITEM_ID_ARENA) then
					tick_num = bag.items.find(ITEM_ID_ARENA).num
				end
				if tick_num < ticketCost then
					--showToast(i18n.global.tips_act_ticket_lack.string)
					layer:addChild(require("ui.arena.buy").create()) 
					return 
				end
			end
			
			local params = { sid = player.sid + 0x200 }
            addWaitNet()
            net:joinpvp_sync(params, function(__data)
                delWaitNet()
                tbl2string(__data)
                if __data.status == -1 then
                    layer:addChild(require("ui.selecthero.main").create({ type = "ArenabDef" }), 1000)
                    --layer:addChild(require("ui.selecthero.info").create(), 10000)
                elseif __data.status == -2 then
                    showToast(i18n.global.event_processing.string)
                elseif __data.status >= 0 then
                    local arenaData = require "data.arenab"
                    arenaData.init(__data)
                    replaceScene(require("ui.arenab.main").create())
                end
            end)
        end)

        btn_join:setEnabled(false)
        layer.btnJoinIron = btn_join
        setShader(btn_join, SHADER_GRAY, true)

        local refreshTime = lbl.createFont2(16, "00:00:00", ccc3(0xa5, 0xfd, 0x47))
        refreshTime:setAnchorPoint(0, 0.5)
        refreshTime:setPosition(355+268, 230)
        nodeIron:addChild(refreshTime)
        layer.refreshTime2 = refreshTime

        local desLabel = lbl.createFont2(16, "", ccc3(0xff, 0xf6, 0xd8))
        desLabel:setAnchorPoint(1, 0.5)
        desLabel:setPosition(355+268, 230)
        nodeIron:addChild(desLabel)
        layer.desLabel2 = desLabel

        -- btn rank
        --[[local btn_rank0 = img.createUISprite(img.ui.btn_rank)
        local btn_rank = SpineMenuItem:create(json.ui.button, btn_rank0)
        btn_rank:setPosition(255+130, 230)
        local btn_rank_menu = CCMenu:createWithItem(btn_rank)
        btn_rank_menu:setPosition(CCPoint(0, 0))
        nodeIron:addChild(btn_rank_menu)
        btn_rank:registerScriptTapHandler(function()
            audio.play(audio.button)
            layer:addChild((require"ui.arenab.rank").create(), 1000)
        end)
        layer.btn_rank2 = btn_rank--]]
    end

    local function onNormal()
        nodeNormal:setVisible(true)
        nodeFriends:setVisible(false)
        node3v3:setVisible(false)
		nodeIron:setVisible(false)
    end

    local function on3V3()
        nodeNormal:setVisible(false)
        nodeFriends:setVisible(false)
        node3v3:setVisible(true)
		nodeIron:setVisible(false)
    end

    local function onFriends()
        nodeNormal:setVisible(false)
        node3v3:setVisible(false)
        nodeFriends:setVisible(true)
		nodeIron:setVisible(false)
    end
	
	local function onIron()
        nodeNormal:setVisible(false)
        node3v3:setVisible(false)
        nodeFriends:setVisible(false)
		nodeIron:setVisible(true)
    end

    onNormal()

    addBackEvent(layer)
    function layer.onAndroidBack()
        backEvent()
    end
    local function onEnter()
        print("onEnter")
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
    layer:setTouchSwallowEnabled(true)

    --init net data
    local function initData()
        local params = {
            sid = player.sid
        }
        addWaitNet()
        net:pvp_sync(params, function(__data)
            delWaitNet()

            tbl2string(__data)

            layer.__data = __data
            layer.startTime = os.time()
			
			local abdata = layer.__data.infos[4]

            arena.initTime(layer.__data.infos[1])
            arena33.initTime(layer.__data.infos[2])
            frdarenaData.initTime(layer.__data.infos[3])
			if abdata then
				arenab.initTime(abdata)
			end
            if not layer.isUpdateingFlag then
                layer.isUpdateingFlag = true
                
                if not layer or tolua.isnull(layer) then return end
                layer:scheduleUpdateWithPriorityLua(function ()
                    local __data = layer.__data
                    local startTime = layer.startTime
                    local passTime = os.time() - startTime
                    local remainCd = math.max(0, __data.infos[2].season_cd - passTime)
                    layer.refreshTime:setString(time2string(remainCd))

                    local remainCd1 = math.max(0, __data.infos[3].season_cd - passTime)
                    layer.refreshTime1:setString(time2string(remainCd1))
					
					local remainCd2 = 0
					if abdata then
						remainCd2 = math.max(0, abdata.season_cd - passTime)
					end
					layer.refreshTime2:setString(time2string(remainCd2))

                    if remainCd <= 0 then
                        layer:unscheduleUpdate()
                        local anim_arr = CCArray:create()
                        anim_arr:addObject(CCDelayTime:create(1))
                        anim_arr:addObject(CCCallFunc:create(function()
                            initData()
                        end))
                        layer:runAction(CCSequence:create(anim_arr))
                        return
                    end

                    local desc
                    if __data.infos[2].status == 0 then--还没开始
                        desc = i18n.global.arena3v3_open_cd.string
                        layer.btn_rank:setVisible(true)
                    else
                        desc = i18n.global.arena3v3_end_cd.string
                        layer.btn_rank:setVisible(false)
                    end
                    if layer.desLabel:getString() ~= desc then
                        layer.desLabel:setString(desc)
                    end

                    local btn = layer.btnJoin3v3
                    if btn:isEnabled() then
                        if __data.infos[2].status == 0 then--还没开始
                            btn:setEnabled(false)
                            setShader(btn, SHADER_GRAY, true)
                        end
                    else
                        if __data.infos[2].status ~= 0 then--已经开始
                            btn:setEnabled(true)
                            clearShader(btn, true)
                        end
                    end

                    if remainCd1 <= 0 then
                        layer:unscheduleUpdate()
                        local anim_arr = CCArray:create()
                        anim_arr:addObject(CCDelayTime:create(1))
                        anim_arr:addObject(CCCallFunc:create(function()
                            initData()
                        end))
                        layer:runAction(CCSequence:create(anim_arr))
                        return
                    end

                    local desc
                    if __data.infos[3].status == 0 then--还没开始
                        desc = i18n.global.arena3v3_open_cd.string
                        layer.btn_rank1:setVisible(true)
                    else
                        desc = i18n.global.arena3v3_end_cd.string
                        layer.btn_rank1:setVisible(false)
                    end
                    if layer.desLabel1:getString() ~= desc then
                        layer.desLabel1:setString(desc)
                    end

                    local btn = layer.btnJoinFriend
                    if btn:isEnabled() then
                        if __data.infos[3].status == 0 then--还没开始
                            btn:setEnabled(false)
                            setShader(btn, SHADER_GRAY, true)
                        end
                    else
                        if __data.infos[3].status ~= 0 then--已经开始
                            btn:setEnabled(true)
                            clearShader(btn, true)
                        end
                    end
					
					local desc
                    if abdata and abdata.status ~= 0 then
                        desc = i18n.global.arena3v3_open_cd.string
						if layer.btn_rank2 then
							layer.btn_rank2:setVisible(true)
						end
                    else
                        desc = i18n.global.arena3v3_end_cd.string
						if layer.btn_rank2 then
							layer.btn_rank2:setVisible(false)
						end
                    end
                    if layer.desLabel2:getString() ~= desc then
                        layer.desLabel2:setString(desc)
                    end

                    local btn = layer.btnJoinIron
                    if btn:isEnabled() then
                        if not abdata or abdata.status ~= 0 then
                            btn:setEnabled(false)
                            setShader(btn, SHADER_GRAY, true)
                        end
                    else
                        if abdata and abdata.status == 0 then
                            btn:setEnabled(true)
                            clearShader(btn, true)
                        end
                    end
                end)
            else
                layer:scheduleUpdate()
            end
        end)
    end

    initData()

    local touchbeginx, touchbeginy
    local isclick
    local function onTouchBegan(x, y)
        touchbeginx, touchbeginy = x, y
        isclick = true
        if not scroll or tolua.isnull(scroll) then return true end
        local p1 = scroll.content_layer:convertToNodeSpace(ccp(x, y))
        for ii=1,#touch_items do
            if touch_items[ii]:boundingBox():containsPoint(p1) then
                playAnimTouchBegin(touch_items[ii])
                last_touch_sprite = touch_items[ii]
            end
        end
        return true
    end

    local function onTouchMoved(x, y)
        if isclick and (math.abs(touchbeginx-x) > 10 or math.abs(touchbeginy-y) > 10) then
            isclick = false
            if last_touch_sprite and not tolua.isnull(last_touch_sprite) then
                playAnimTouchEnd(last_touch_sprite)
                last_touch_sprite = nil
            end
        end
    end

    local function onTouchEnded(x, y)
        if last_touch_sprite and not tolua.isnull(last_touch_sprite) then
            playAnimTouchEnd(last_touch_sprite)
            last_touch_sprite = nil
        end
        local p0 = layer:convertToNodeSpace(ccp(x, y))
        if isclick and not bg:boundingBox():containsPoint(p0) then
            backEvent()
        elseif isclick then
            local p1 = scroll.content_layer:convertToNodeSpace(ccp(x, y))
            for ii=1,#touch_items do
                if touch_items[ii]:boundingBox():containsPoint(p1) then
                    if last_sel_sprite and last_sel_sprite == touch_items[ii] then
                        return 
                    elseif last_sel_sprite and not tolua.isnull(last_sel_sprite) then
                        if last_sel_sprite.sel and not tolua.isnull(last_sel_sprite.sel) then
                            last_sel_sprite.sel:setVisible(false)
                        end
                    end
                    audio.play(audio.button)
                    touch_items[ii].sel:setVisible(true)
                    if ii == 1 then 
                        onNormal()
                    elseif ii == 2 then
                        on3V3()
					elseif ii == 3 then
						onFriends()
                    else
                        onIron()
                    end
                    last_sel_sprite = touch_items[ii]
                    -- set read
                    --if touch_items[ii].obj.status then
                    --    touch_items[ii].obj.status.read = 1
                    --end
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

    layer:registerScriptTouchHandler(onTouch, false, -128, false)

    -- show firt
    if #touch_items > 0 then
        if touch_items[kind].sel and not tolua.isnull(touch_items[kind].sel) then
            touch_items[kind].sel:setVisible(true)
        end
        --onNormal()
        last_sel_sprite = touch_items[kind]
        if kind == 2 then
            on3V3()
        else
            onNormal()
        end
        -- set read
        --if touch_items[1].obj.status then
        --    touch_items[1].obj.status.read = 1
        --end
    end

    return layer
end

return ui
