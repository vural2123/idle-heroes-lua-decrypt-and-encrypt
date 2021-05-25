local ui = {}

require "common.func"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local i18n = require "res.i18n"
local audio = require "res.audio"
local net = require "net.netClient"
local cfghero = require "config.hero"
local heros = require "data.heros"
local cfgvip = require "config.vip"
local bag = require "data.bag"
local player = require "data.player"
local cfgherBag = require "config.herobag"
local cfgequip = require "config.equip"
local cfgitem = require "config.item"
local tipsitem = require "ui.tips.item"
local tipsequip = require "ui.tips.equip"
local tipsforge = require "ui.skin.forgetips"
local tipsskin = require "ui.tips.skin"

local function sortSkinGallery(a, b)
	local ashow = cfgequip[a.id].sortShowg or 0
	local bshow = cfgequip[b.id].sortShowg or 0
	return ashow > bshow
end

local function sortSkinBag(a, b)
	local ashow = cfgequip[a.id].sortShow or 0
	local bshow = cfgequip[b.id].sortShow or 0
	return ashow > bshow
end

local function createPopupPieceBatchSummonResult(id, count)
    local params = {}
    params.title = i18n.global.reward_will_get.string
    params.btn_count = 0

    local dialog = require("ui.dialog").create(params) 

    local back = img.createLogin9Sprite(img.login.button_9_small_gold)
    back:setPreferredSize(CCSize(153, 50))
    local comfirlab = lbl.createFont1(18, i18n.global.summon_comfirm.string, lbl.buttonColor)
    comfirlab:setPosition(CCPoint(back:getContentSize().width/2,
                                    back:getContentSize().height/2))
    back:addChild(comfirlab)
    local backBtn = SpineMenuItem:create(json.ui.button, back)
    backBtn:setPosition(CCPoint(dialog.board:getContentSize().width/2, 65))
    local menu = CCMenu:createWithItem(backBtn)
    menu:setPosition(0, 0)
    dialog.board:addChild(menu)

    dialog.board.tipsTag = false

    local x = dialog.board:getContentSize().width/2
    local y = 180
    local skinhead = img.createSkinIcon(id)
    local skinheadBtn = CCMenuItemSprite:create(skinhead, nil)
    skinheadBtn:setScale(0.7)
    skinheadBtn:setPosition(x, y)

    if cfgequip[id].powerful and cfgequip[id].powerful ~= 0 then
        local framBg = img.createUISprite(img.ui.skin_frame_sp)
        framBg:setScale(0.7)
        framBg:setPosition(x, y)
        dialog.board:addChild(framBg, 1)
    else
        local framBg = img.createUISprite(img.ui.skin_frame)
        framBg:setScale(0.7)
        framBg:setPosition(x, y)
        dialog.board:addChild(framBg, 1)
    end
    local groupBg = img.createUISprite(img.ui.skin_circle)
    groupBg:setPosition(x - 43, y + 61)
    dialog.board:addChild(groupBg, 1)
    local groupIcon = img.createUISprite(img.ui["herolist_group_" .. cfghero[cfgequip[id].heroId[1]].group])
    groupIcon:setScale(0.48)
    groupIcon:setPosition(x - 43, y + 61)
    dialog.board:addChild(groupIcon, 1)

    --local countLbl = lbl.createFont2(20, string.format("X%d", count), ccc3(255, 246, 223))
    --countLbl:setAnchorPoint(ccp(0, 0.5))
    --countLbl:setPosition(heroBtn:boundingBox():getMaxX()+10, 185)
    --dialog.board:addChild(countLbl)

    local iconMenu = CCMenu:createWithItem(skinheadBtn)
    iconMenu:setPosition(0, 0)
    dialog.board:addChild(iconMenu)
    skinheadBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        dialog:addChild(require("ui.skin.preview").create(id, i18n.equip[id].name), 10000)
    end)

    backBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        dialog:removeFromParentAndCleanup()
    end)

    return dialog
end

function ui.create(params)
    local layer = CCLayer:create()

    layer.needFresh = false
    local params = params or {}

    local bg = img.createUISprite(img.ui.bag_bg)
    bg:setScale(view.minScale)
    bg:setPosition(view.midX, view.midY)
    layer:addChild(bg)

    -- backBtn
    local btnBackSprite = img.createUISprite(img.ui.back)
    local btnBack = HHMenuItem:create(btnBackSprite)
    btnBack:setScale(view.minScale)
    btnBack:setPosition(scalep(35, 546))
    local menuBack = CCMenu:createWithItem(btnBack)
    menuBack:setPosition(0, 0)
    layer:addChild(menuBack, 1000)
    layer.back = btnBack
    btnBack:registerScriptTapHandler(function()
        audio.play(audio.button)
        if not params.back then
            replaceScene(require("ui.town.main").create())
        elseif params.back == "hook" then
            replaceScene(require("ui.hook.map").create())
        end
    end)

    autoLayoutShift(btnBack)

    local title = lbl.createFont2(30, i18n.global.main_skinlist_title.string, ccc3(0xfa, 0xd8, 0x69))
    title:setScale(view.minScale)
    title:setPosition(scalep(480, 545))
    layer:addChild(title, 100)
    
    local showHeroLayer
    local model = params.model or "Skin"
    local sortType
    local group = params.group

    local board = img.createUISprite(img.ui.herolist_bg)
    board:setScale(view.minScale)
    board:setPosition(scalep(467, 272))
    --board:setPosition(view.midX - 15, view.midY - 20)
    layer:addChild(board)

    local btnHeroSprite0 = img.createUISprite(img.ui.skin_select1)
    local btnHeroSprite1 = img.createUISprite(img.ui.skin_select0)
    local btnHero = CCMenuItemSprite:create(btnHeroSprite0, btnHeroSprite1, btnHeroSprite0)
    local btnHeroMenu = CCMenu:createWithItem(btnHero)
    btnHero:setPosition(847, 240+94)
    btnHeroMenu:setPosition(0, 0)
    board:addChild(btnHeroMenu, 10)

    local btnSkinpieceSprite0 = img.createUISprite(img.ui.skin_piece_select1)
    local btnSkinpieceSprite1 = img.createUISprite(img.ui.skin_piece_select0)
    local btnSkinpiece = CCMenuItemSprite:create(btnSkinpieceSprite0, btnSkinpieceSprite1, btnSkinpieceSprite0)
    local btnSkinpieceMenu = CCMenu:createWithItem(btnSkinpiece)
    btnSkinpiece:setPosition(847, 240)
    btnSkinpieceMenu:setPosition(0, 0)
    board:addChild(btnSkinpieceMenu, 10)

    local btnBookSprite0 = img.createUISprite(img.ui.skin_book_select1)
    local btnBookSprite1 = img.createUISprite(img.ui.skin_book_select0)
    local btnBook = CCMenuItemSprite:create(btnBookSprite0, btnBookSprite1, btnBookSprite0)
    local btnBookMenu = CCMenu:createWithItem(btnBook)
    btnBook:setPosition(847, 240-94)
    btnBookMenu:setPosition(0, 0)
    board:addChild(btnBookMenu, 10)

    local btnGroupList = {}
    local getDataAndCreateList
    if model == "Skin" then
        btnHero:selected()
    elseif model == "Piece" then
        btnSkinpiece:selected()
    else
        btnBook:selected()
    end

    btnHero:registerScriptTapHandler(function()
        audio.play(audio.button)
        if model ~= "Skin" then
            btnHero:setEnabled(false)
            btnSkinpiece:setEnabled(true)
            btnBook:setEnabled(true)
            title:setString(i18n.global.main_skinlist_title.string)
            btnHero:selected()
            btnSkinpiece:unselected()
            btnBook:unselected()
            model = "Skin"
            for i=1,6 do
                btnGroupList[i]:setVisible(true)
            end
            if group then
                btnGroupList[group]:unselected()
                group = nil
            end
            getDataAndCreateList()
        end
    end)

    btnSkinpiece:registerScriptTapHandler(function()
        audio.play(audio.button)
        if model ~= "Piece" then
            btnHero:setEnabled(true)
            btnBook:setEnabled(true)
            btnSkinpiece:setEnabled(false)
            title:setString(i18n.global.main_skinpiece_title.string)
            --title:setString("123444")
            btnHero:unselected()
            btnSkinpiece:selected()
            btnBook:unselected()
            model = "Piece"
            if group then
                btnGroupList[group]:unselected()
                group = nil
            end
            for i=1,6 do
                btnGroupList[i]:setVisible(false)
            end
            getDataAndCreateList()
        end
    end)

    btnBook:registerScriptTapHandler(function()
        audio.play(audio.button)
        if model ~= "Book" then
            btnHero:setEnabled(true)
            btnBook:setEnabled(false)
            btnSkinpiece:setEnabled(true)
            title:setString(i18n.global.main_skinbook_title.string)
            btnHero:unselected()
            btnSkinpiece:unselected()
            btnBook:selected()
            model = "Book"
            if group then
                btnGroupList[group]:unselected()
                group = nil
            end
            for i=1,6 do
                btnGroupList[i]:setVisible(true)
            end
            getDataAndCreateList()
        end
    end)

    for i=1, 6 do
        local btnGroupSpriteFg = img.createUISprite(img.ui["herolist_group_" .. i])
        local btnGroupSpriteBg = img.createUISprite(img.ui.herolist_group_bg)
        btnGroupSpriteFg:setPosition(btnGroupSpriteBg:getContentSize().width/2, btnGroupSpriteBg:getContentSize().height/2 + 2)
        btnGroupSpriteBg:addChild(btnGroupSpriteFg)
        btnGroupList[i] = HHMenuItem:createWithScale(btnGroupSpriteBg, 1)
        local btnGroupMenu = CCMenu:createWithItem(btnGroupList[i])
        btnGroupMenu:setPosition(0, 0)
        board:addChild(btnGroupMenu, 10)
        btnGroupList[i]:setPosition(183 + 66 * i, 460)
        
        local showSelect = img.createUISprite(img.ui.herolist_select_icon)
        showSelect:setPosition(btnGroupList[i]:getContentSize().width/2, btnGroupList[i]:getContentSize().height/2 + 2)
        btnGroupList[i]:addChild(showSelect)
        btnGroupList[i].showSelect = showSelect
        showSelect:setVisible(false)

        btnGroupList[i]:registerScriptTapHandler(function()
            audio.play(audio.button)
            for j=1, 6 do
                btnGroupList[j]:unselected()
                btnGroupList[j].showSelect:setVisible(false)
            end
            if not group or i ~= group then
                group = i
                btnGroupList[i]:selected()
                btnGroupList[i].showSelect:setVisible(true)
            else
                group = nil
            end

            getDataAndCreateList()
        end)
    end
    if group then
        btnGroupList[group]:selected()
        btnGroupList[group].showSelect:setVisible(true)
    end

    --local function viewSkin(skin)
    --end

    -- 合成皮肤
    local function onClickPieceForge(piece)
        if layer.tipsTag then
            layer.tips:removeFromParent()
            layer.tipsTag = false
        end
        if layer.tipssTag then
            if layer.tipss then
                layer.tipss:removeFromParent()
                layer.tipss = nil
            end
            layer.tipssTag = false
        end
        local costCount = cfgitem[piece.id].equip.count
        local forgeNum = math.floor(piece.num/costCount)
        local param = {}
        param.sid = player.sid
        param.item_id = piece.id
        param.num = forgeNum*costCount
        tbl2string(param)
        addWaitNet()
        net:hero_skin_mix(param, function(__data)
            delWaitNet()
            tbl2string(__data)
            if __data.status ~= 0 then
                showToast(i18n.global.error_server_status_wrong.string .. __data.status)
                return
            end
            for i = 1,#__data.skin do
                bag.equips.add(__data.skin[i])
            end
            bag.items.sub({id=piece.id, num=forgeNum*costCount})
            getDataAndCreateList()
            --if piece.id == ITEM_ID_PIECE_SKIN then
                if #__data.skin == 1 and __data.skin[1].num == 1 then
                    local pop = createPopupPieceBatchSummonResult(__data.skin[1].id, 1)
                    layer:addChild(pop, 1000)
                else
                    bg:getParent():addChild((require"ui.skin.skinshow").create(__data.skin, i18n.global.spesummon_gain.string), 1000)
                end
            --else
            --    if data.heroed[1].num == 1 then
            --    local pop = createPopupPieceBatchSummonResult(data.skin[1].id, #data.skin)
            --    layer:addChild(pop, 100)
            --end
        end)
    end

    local function onClickPieceFoegeShow(piece)
        if layer.tipsTag then
            layer.tips:removeFromParent()
            layer.tipsTag = false
        end
        layer.tipssTag = true
        layer.tipss = tipsforge.create("items", piece, onClickPieceForge)
        layer:addChild(layer.tipss, 1000)
    end

    local function createPieceList(pieces)
        local curlayer = CCLayer:create()
        local SCROLLVIEW_WIDTH = 710
        local SCROLLVIEW_HEIGHT = 411
        local SCROLLCONTENT_HEIGHT = 23 + 100 * math.ceil(#pieces/7)
        
        local scroll = CCScrollView:create()
        scroll:setDirection(kCCScrollViewDirectionVertical)
        scroll:setAnchorPoint(ccp(0, 0))
        scroll:setPosition(66, 29)
        scroll:setViewSize(CCSize(SCROLLVIEW_WIDTH, SCROLLVIEW_HEIGHT))
        scroll:setContentSize(CCSize(SCROLLVIEW_WIDTH, SCROLLCONTENT_HEIGHT))
        scroll:setContentOffset(ccp(0, SCROLLVIEW_HEIGHT - SCROLLCONTENT_HEIGHT))
        curlayer:addChild(scroll)

        --local groupBgBatch = img.createBatchNodeForUI(img.ui.herolist_group_bg)
        --scroll:getContainer():addChild(groupBgBatch , 3)

        local headIcons = {}
        local function createItem(i, v)
            local y, x = SCROLLCONTENT_HEIGHT - math.ceil( i / 7 ) * 118 + 55, ( i - math.ceil( i / 7 ) * 7 + 7 ) * 101 - 49

            --local headBg = img.createUISprite(img.ui.grid)
            --size = headBg:getContentSize()
            --headBg:setPosition(x, y)
            --scroll:getContainer():addChild(headBg)
            --local qlt = cfghero[herolist[i].id].maxStar
            headIcons[i] = img.createItem(pieces[i].id)
            headIcons[i]:setPosition(x, y)
            scroll:getContainer():addChild(headIcons[i])
            headIcons[i].data = pieces[i]

            --local groupBg = img.createUISprite(img.ui.herolist_group_bg)
            --groupBg:setScale(0.42)
            --groupBg:setPosition(x - 30, y + 29)
            --scroll:getContainer():addChild(groupBg)
    
            --if cfgequip[cfgitem[pieces[i].id].equip.id].heroId[1] then
            --    local piecegroup = cfghero[cfgequip[cfgitem[pieces[i].id].equip.id].heroId[1]].group 
            --    local groupIcon = img.createUISprite(img.ui["herolist_group_" .. piecegroup])
            --    groupIcon:setScale(0.42)
            --    groupIcon:setPosition(x - 30, y + 30)
            --    scroll:getContainer():addChild(groupIcon, 3)
            --end

            local progressBg = img.createUISprite(img.ui.bag_heropiece_progr)
            progressBg:setPosition(x, y-55)
            scroll:getContainer():addChild(progressBg)

            local progressFgSprite = nil 
            local costCount = cfgitem[pieces[i].id].equip.count
            if pieces[i].num < costCount then
                progressFgSprite = img.createUISprite(img.ui.bag_heropiece_progr_0)
            else
                progressFgSprite = img.createUISprite(img.ui.bag_heropiece_progr_1)
            end
            local progressFg = createProgressBar(progressFgSprite) 
            progressFg:setPosition(x, y-55)
            progressFg:setPercentage(pieces[i].num / costCount * 100)
            scroll:getContainer():addChild(progressFg)

            local str = string.format("%d/%d", pieces[i].num, costCount)
            local label = lbl.createFont2(14, str, ccc3(255, 246, 223))
            label:setPosition(x, y-55)
            scroll:getContainer():addChild(label)
        end

        for i, v in ipairs(pieces) do
            --if i > initShowCount then
            --    break
            --end

            createItem(i, v)
        end

        if #pieces == 0 then
            local empty = require("ui.empty").create({ text = i18n.global.skin_nopiece.string , color = ccc3(0xd9, 0xbb, 0x9d)})
            empty:setPosition(board:getContentSize().width/2, board:getContentSize().height/2)
            curlayer:addChild(empty)
        end

        local lasty
        local function onTouchBegin(x, y)
            lasty = y
            return true 
        end

        local function onTouchMoved(x, y)
            return true
        end

        local function onTouchEnd(x, y)
            local pointOnBoard = curlayer:convertToNodeSpace(ccp(x, y))
            if math.abs(y - lasty) > 10 or not scroll:boundingBox():containsPoint(pointOnBoard) then
                return true
            end

            local point = scroll:getContainer():convertToNodeSpace(ccp(x, y))
            for i, v in ipairs(headIcons) do
                if v:boundingBox():containsPoint(point) then
                    layer.tipsTag = true
                    audio.play(audio.button)

                    if v.data.id == ITEM_ID_PIECE_SKIN then
                        -- 万能皮肤碎片
                        local costCount = math.floor(v.data.num/cfgitem[v.data.id].equip.count)
                        if costCount == 0 then
                            layer.tips = tipsitem.createForShow(v.data)
                        elseif costCount <= 1 then
                            layer.tips = tipsitem.createForBag(v.data, onClickPieceForge)
                        else
                            layer.tips = tipsskin.create("items", v.data, onClickPieceForge)
                        end
                    else
                        local costCount = math.floor(v.data.num/cfgitem[v.data.id].equip.count)
                        if costCount <= 1 then
                            layer.tips = tipsitem.createForBag(v.data, onClickPieceForge)
                        else
                            layer.tips = tipsitem.createForBag(v.data, onClickPieceFoegeShow)
                        end
                    end
                    layer:addChild(layer.tips, 1000)
                    layer.tips.setClickBlankHandler(function()
                        layer.tips:removeFromParent()
                        layer.tipsTag = false
                    end)
                    break
                end
            end
            return true
        end

        local function onTouch(eventType, x, y)
            if eventType == "began" then
                return onTouchBegin(x, y)        
            elseif eventType == "moved" then
                return onTouchMoved(x, y)
            else
                return onTouchEnd(x, y)
            end
        end

        curlayer:registerScriptTouchHandler(onTouch)
        curlayer:setTouchEnabled(true)

        return curlayer
    end

    local function onClickSkinBreakdown(skin)
        audio.play(audio.button)
        if layer.tipsTag then
            layer.tips:removeFromParent()
            layer.tipsTag = false
        end
        if layer.tipssTag then
            if layer.tipss then
                layer.tipss:removeFromParent()
                layer.tipss = nil
            end
            layer.tipssTag = false
        end

        local params = {}
        params.btn_count = 0
        params.title = string.format(i18n.global.skinbreak_title.string, 20)
        --params.body = string.format(i18n.global.skinbreak_sure.string, 20)
        params.board_w = 504
        params.board_h = 350

        local dialoglayer = require("ui.dialog").create(params) 

        local lbl_body = lbl.createMix({
            font = 1, size = 18, text = string.format(i18n.global.skinbreak_sure.string, 20), color = ccc3(0x78, 0x46, 0x27),
            width = 400, align = kCCTextAlignmentLeftt
        })
        lbl_body:setAnchorPoint(CCPoint(0.5, 1))
        lbl_body:setPosition(CCPoint(params.board_w/2, params.board_h-85))
        dialoglayer.board:addChild(lbl_body)
		
		local onec = 5
		if cfgequip[skin.id].powerful and cfgequip[skin.id].powerful ~= 0 then onec = 15 end
		
		local item = img.createItem(ITEM_ID_PIECE_SKIN, onec)
        local btnItem = CCMenuItemSprite:create(item, nil)
        local menu = CCMenu:createWithItem(btnItem)
        menu:setPosition(0, 0)
        dialoglayer.board:addChild(menu)
        btnItem:setPosition(params.board_w/2, 162)
    
        btnItem:registerScriptTapHandler(function() 
            local tips = require("ui.tips.item").createForShow({id = ITEM_ID_PIECE_SKIN, num = onec})
            dialoglayer:addChild(tips, 100)
        end)

        local btnYesSprite = img.createLogin9Sprite(img.login.button_9_small_gold)
        btnYesSprite:setPreferredSize(CCSize(153, 50))
        local btnYes = SpineMenuItem:create(json.ui.button, btnYesSprite)
        btnYes:setPosition(params.board_w/2+95, 74)
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
        btnNo:setPosition(params.board_w/2-95, 74)
        local labNo = lbl.createFont1(18, i18n.global.board_confirm_no.string, ccc3(0x73, 0x3b, 0x05))
        labNo:setPosition(btnNo:getContentSize().width/2, btnNo:getContentSize().height/2)
        btnNoSprite:addChild(labNo)
        local menuNo = CCMenu:create()
        menuNo:setPosition(0, 0)
        menuNo:addChild(btnNo)
        dialoglayer.board:addChild(menuNo)

        btnYes:registerScriptTapHandler(function()
            dialoglayer:removeFromParentAndCleanup(true)
            audio.play(audio.button)
            local param = {}
            param.sid = player.sid
            param.skin_id = skin.id
            tbl2string(param)
            addWaitNet()
            net:hero_skin_breakdown(param, function(__data)
                delWaitNet()
                tbl2string(__data)
                if __data.status ~= 0 then
                    showToast(i18n.global.error_server_status_wrong.string .. __data.status)
                    return
                end
                bag.equips.sub({id=skin.id, num=1})
				local onec = 5
				if cfgequip[skin.id].powerful and cfgequip[skin.id].powerful ~= 0 then onec = 15 end
                bag.items.add({id=ITEM_ID_PIECE_SKIN, num=onec})
                getDataAndCreateList()

                local reward = {}
                reward.items = {}
                reward.items[#reward.items+1] = {id=ITEM_ID_PIECE_SKIN, num=onec}
                --layer:addChild(require("ui.tips.reward").create(reward), 1000)
				require("ui.custom").showFloatReward(reward)
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
	
	local function onClickSkinUpgrade(skin)
        audio.play(audio.button)
        if layer.tipsTag then
            layer.tips:removeFromParent()
            layer.tipsTag = false
        end
        if layer.tipssTag then
            if layer.tipss then
                layer.tipss:removeFromParent()
                layer.tipss = nil
            end
            layer.tipssTag = false
        end

        local params = {}
        params.btn_count = 0
        params.title = string.format(i18n.global.skinupgrade_title.string, 20)
        --params.body = string.format(i18n.global.skinupgrade_sure.string, 20)
        params.board_w = 504
        params.board_h = 350

        local dialoglayer = require("ui.dialog").create(params) 

        local lbl_body = lbl.createMix({
            font = 1, size = 18, text = string.format(i18n.global.skinupgrade_sure.string, 20), color = ccc3(0x78, 0x46, 0x27),
            width = 400, align = kCCTextAlignmentLeftt
        })
        lbl_body:setAnchorPoint(CCPoint(0.5, 1))
        lbl_body:setPosition(CCPoint(params.board_w/2, params.board_h-85))
        dialoglayer.board:addChild(lbl_body)

        local btnYesSprite = img.createLogin9Sprite(img.login.button_9_small_gold)
        btnYesSprite:setPreferredSize(CCSize(153, 50))
        local btnYes = SpineMenuItem:create(json.ui.button, btnYesSprite)
        btnYes:setPosition(params.board_w/2+95, 74)
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
        btnNo:setPosition(params.board_w/2-95, 74)
        local labNo = lbl.createFont1(18, i18n.global.board_confirm_no.string, ccc3(0x73, 0x3b, 0x05))
        labNo:setPosition(btnNo:getContentSize().width/2, btnNo:getContentSize().height/2)
        btnNoSprite:addChild(labNo)
        local menuNo = CCMenu:create()
        menuNo:setPosition(0, 0)
        menuNo:addChild(btnNo)
        dialoglayer.board:addChild(menuNo)

		btnYes:registerScriptTapHandler(function()
            dialoglayer:removeFromParentAndCleanup(true)
            audio.play(audio.button)
			if skin.num < 3 then
				showToast(i18n.global.empty_items.string)
				return
			end
            local param = {}
            param.sid = player.sid + 0x100
            param.skin_id = skin.id
            tbl2string(param)
            addWaitNet()
            net:hero_skin_breakdown(param, function(__data)
                delWaitNet()
                tbl2string(__data)
                if __data.status <= 0 then
                    showToast(i18n.global.error_server_status_wrong.string .. __data.status)
                    return
                end
                bag.equips.sub({id=skin.id, num=3})
				bag.equips.add({id=__data.status, num=1})
                getDataAndCreateList()

                --[[local reward = {}
                reward.items = {}
                reward.items[#reward.items+1] = {id=ITEM_ID_PIECE_SKIN, num=onec}
                --layer:addChild(require("ui.tips.reward").create(reward), 1000)
				require("ui.custom").showFloatReward(reward)--]]
				local pop = createPopupPieceBatchSummonResult(__data.status, 1)
                layer:addChild(pop, 1000)
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

    local function createHeroList(skinlist)
        local curlayer = CCLayer:create()

        local SCROLLVIEW_WIDTH = 710
        local SCROLLVIEW_HEIGHT = 411
        local SCROLLCONTENT_HEIGHT = 23 + 174 * math.ceil(#skinlist/5)
        
        local scroll = CCScrollView:create()
        scroll:setDirection(kCCScrollViewDirectionVertical)
        scroll:setAnchorPoint(ccp(0, 0))
        scroll:setPosition(66, 29)
        scroll:setViewSize(CCSize(SCROLLVIEW_WIDTH, SCROLLVIEW_HEIGHT))
        scroll:setContentSize(CCSize(SCROLLVIEW_WIDTH, SCROLLCONTENT_HEIGHT))
        scroll:setContentOffset(ccp(0, SCROLLVIEW_HEIGHT - SCROLLCONTENT_HEIGHT))
        curlayer:addChild(scroll)

        --local iconBgBatch = img.createBatchNodeForUI(img.ui.herolist_head_bg)
        --scroll:getContainer():addChild(iconBgBatch, 1)
        --local iconBgBatch1 = img.createBatchNodeForUI(img.ui.hero_star_ten_bg)
        --scroll:getContainer():addChild(iconBgBatch1, 1)
        --local groupBgBatch = img.createBatchNodeForUI(img.ui.herolist_group_bg)
        --scroll:getContainer():addChild(groupBgBatch , 3)
        --local starBatch = img.createBatchNodeForUI(img.ui.star_s)
        --scroll:getContainer():addChild(starBatch, 3)
        --local star1Batch = img.createBatchNodeForUI(img.ui.hero_star_orange)
        --scroll:getContainer():addChild(star1Batch, 3)
        --local star10Batch = img.createBatchNodeForUI(img.ui.hero_star_ten)
        --scroll:getContainer():addChild(star10Batch, 3)
        local blackBatch = img.createBatchNodeForUI(img.ui.skin_black)
        scroll:getContainer():addChild(blackBatch, 5)

        local headIcons = {}
        local function createItem(i, v)
            local y, x = SCROLLCONTENT_HEIGHT - math.ceil( i / 5 ) * 174 + 70, ( i - math.ceil( i / 5 ) * 5 + 5 ) * 140 - 65
            --local headBg = nil
            --local qlt = cfghero[herolist[i].id].maxStar
            headIcons[i] = img.createSkinIcon(skinlist[i].id)
            headIcons[i]:setPosition(x, y)
            headIcons[i]:setScale(0.7)
            scroll:getContainer():addChild(headIcons[i])
            headIcons[i].data = skinlist[i]
            local bgsize = headIcons[i]:getContentSize()
			
			if model == "Skin" then
				local restSkinBg = img.createUI9Sprite(img.ui.skin_restskinbg)
				restSkinBg:setPreferredSize(CCSize(152, 32)) -- 200, 32
				restSkinBg:setPosition(bgsize.width/2, 20)
				headIcons[i]:addChild(restSkinBg)

				local restSkin = lbl.createMixFont1(20, skinlist[i].num, ccc3(255, 246, 223))
				restSkin:setPosition(bgsize.width/2, 20)
				headIcons[i]:addChild(restSkin)
				--headIcons[i].restSkin = restSkin
			end

            local framBg = nil
            if cfgequip[skinlist[i].id].powerful and cfgequip[skinlist[i].id].powerful ~= 0 then
                framBg = img.createUISprite(img.ui.skin_frame_sp)
            else
                framBg = img.createUISprite(img.ui.skin_frame)
            end
            framBg:setPosition(bgsize.width/2, bgsize.height/2)
            headIcons[i]:addChild(framBg)
            local groupBg = img.createUISprite(img.ui.skin_circle)
            groupBg:setPosition(x - 43, y + 61)
            scroll:getContainer():addChild(groupBg)
            local groupIcon = img.createUISprite(img.ui["herolist_group_" .. cfghero[cfgequip[skinlist[i].id].heroId[1]].group])
            groupIcon:setScale(0.48)
            groupIcon:setPosition(x - 43, y + 61)
            scroll:getContainer():addChild(groupIcon, 1)

			if model == "Skin" then
				if skinlist[i].flag == false then
					local blackBoard = img.createUISprite(img.ui.skin_black)
					blackBoard:setScale(0.7)
					--blackBoard:setScale(90/94)
					blackBoard:setOpacity(120)
					blackBoard:setPosition(headIcons[i]:getPositionX(), headIcons[i]:getPositionY())
					scroll:getContainer():addChild(blackBoard, 0, i)
					
					local tickIcon = img.createUISprite(img.ui.login_month_finish)
					tickIcon:setPosition(x+35, y+52)
					scroll:getContainer():addChild(tickIcon, 2)
				else
					--local label = lbl.createFont2(28, skinlist[i].num, ccc3(255, 246, 223))
					--label:setPosition(140 / 2, 16)
					--headIcons[i]:addChild(label)
				end
            else
				local isHave = 0
				local vid = skinlist[i].id
				local vpow = cfgequip[vid].powerful
				if vpow and vpow ~= 0 then vid = vpow end
				if player.skinicons then isHave = player.skinicons[vid] end
				if not isHave or isHave == 0 then
					local blackBoard = img.createUISprite(img.ui.skin_black)
					blackBoard:setScale(0.7)
					blackBoard:setOpacity(120)
					blackBoard:setPosition(headIcons[i]:getPositionX(), headIcons[i]:getPositionY())
					blackBatch:addChild(blackBoard, 0, i)
				else
					local tickIcon = img.createUISprite(img.ui.login_month_finish)
					tickIcon:setPosition(x+35, y+52)
					scroll:getContainer():addChild(tickIcon, 2)
				end
            end
        end

        local initShowCount = 60
        for i, v in ipairs(skinlist) do
            if i > initShowCount then
                break
            end

            createItem(i, v)
        end

        local skinCount = #skinlist
        local function showAfter()
            if initShowCount < skinCount then
                initShowCount = initShowCount + 1
                createItem(initShowCount, skinlist[initShowCount])
                return true
            end
        end

        if skinCount == 0 then
            local empty = require("ui.empty").create({ text = i18n.global.skin_noskin.string , color = ccc3(0xd9, 0xbb, 0x9d)})
            empty:setPosition(board:getContentSize().width/2, board:getContentSize().height/2)
            curlayer:addChild(empty)
        elseif skinCount > initShowCount then
            curlayer:scheduleUpdateWithPriorityLua(function ( dt )
                if showAfter() then
                    if showAfter() then
                        showAfter()
                    end
                end
            end, 0)
        end

        local lasty
        local function onTouchBegin(x, y)
            lasty = y
            return true 
        end

        local function onTouchMoved(x, y)
            return true
        end

        local function onTouchEnd(x, y)
            local pointOnBoard = curlayer:convertToNodeSpace(ccp(x, y))
            if math.abs(y - lasty) > 10 or not scroll:boundingBox():containsPoint(pointOnBoard) then
                return true
            end

            local point = scroll:getContainer():convertToNodeSpace(ccp(x, y))
            for i, v in ipairs(headIcons) do
                if v:boundingBox():containsPoint(point) then
                    audio.play(audio.button)
                    layer.tipsTag = true
                    if model == "Skin" then
                        layer.tips = tipsequip.createForSkin(v.data, function()
                            if layer.tipsTag then
                                layer.tips:removeFromParent()
                                layer.tipsTag = false
                            end
                            bg:getParent():addChild(require("ui.skin.preview").create(v.data.id, i18n.equip[v.data.id].name), 10000)
                        end, function()
                            local sureBreakdown = onClickSkinBreakdown(v.data)
                            bg:getParent():addChild(sureBreakdown, 10000)
                        end, function()
							local sureUpgrade = onClickSkinUpgrade(v.data)
							bg:getParent():addChild(sureUpgrade, 10000)
						end)
                    else
                        layer.tips = tipsequip.createForSkin(v.data, function()
                            if layer.tipsTag then
                                layer.tips:removeFromParent()
                                layer.tipsTag = false
                            end
                            bg:getParent():addChild(require("ui.skin.preview").create(v.data.id, i18n.equip[v.data.id].name), 10000)
                        end)
                    end
                    layer:addChild(layer.tips, 1000)
                    layer.tips.setClickBlankHandler(function()
                        if layer.tipsTag then
                            layer.tips:removeFromParent()
                            layer.tipsTag = false
                        end
                    end)
                    break
                end
            end
            return true
        end

        local function onTouch(eventType, x, y)
            if eventType == "began" then
                return onTouchBegin(x, y)        
            elseif eventType == "moved" then
                return onTouchMoved(x, y)
            else
                return onTouchEnd(x, y)
            end
        end

        curlayer:registerScriptTouchHandler(onTouch)
        curlayer:setTouchEnabled(true)

        return curlayer
    end

    function getDataAndCreateList()
        local skinlist = {} 
        if model == "Skin" then
            skinlist = bag.equips.skin(group)
			if #skinlist > 1 then
				table.sort(skinlist, sortSkinBag)
			end
            for _, v in ipairs(heros) do
                if not group or cfghero[v.id].group == group then
                    for i, vv in ipairs(v.equips) do
                        if cfgequip[vv].pos == EQUIP_POS_SKIN then
                            skinlist[#skinlist+1] = {
                                id = vv,
                                num = 1,
                                -- 是否穿戴
                                flag = false
                            }
                        end
                    end
                end
            end
            
            if showHeroLayer then
                showHeroLayer:removeFromParentAndCleanup(true)
                showHeroLayer = nil
            end
            showHeroLayer = createHeroList(skinlist)
            board:addChild(showHeroLayer)
            --table.sort(herolist, compareHero)
        elseif model == "Piece" then
            local pieces = {}
            for _, v in ipairs(bag.items) do 
                if cfgitem[v.id].type == 9 then
                    pieces[#pieces+1] = v
                end
            end
            if showHeroLayer then
                showHeroLayer:removeFromParentAndCleanup(true)
                showHeroLayer = nil
            end
            showHeroLayer = createPieceList(pieces)
            board:addChild(showHeroLayer)
        else
            --if not group then
            --    group = 1
            --    btnGroupList[1]:selected()
            --    btnGroupList[1].showSelect:setVisible(true)
            --end
            for _, v in pairs(cfgequip) do
                if v.pos == EQUIP_POS_SKIN then
                    if not group or cfghero[v.heroId[1]].group == group then 
                        skinlist[#skinlist+1] = {
                            id = _,
                            num = 1
                        }
                    end
                end
            end
			table.sort(skinlist, sortSkinGallery)
            --local herobook = require "data.herobook"
            --for i=1, #herolist do
            --    herolist[i].isHave = false
            --    for j=1, #herobook do
            --        if herolist[i].id  == herobook[j] then
            --            herolist[i].isHave = true
            --        end
            --    end
            --end
            --
            if showHeroLayer then
                showHeroLayer:removeFromParentAndCleanup(true)
                showHeroLayer = nil
            end
            showHeroLayer = createHeroList(skinlist)
            board:addChild(showHeroLayer)
        end
    end
    getDataAndCreateList()

    layer:scheduleUpdateWithPriorityLua(function()
        if layer.needFresh == true then
            layer.needFresh = false
            getDataAndCreateList()
        end
    end)
    addBackEvent(layer)
    function layer.onAndroidBack()
        if not params.back then
            replaceScene(require("ui.town.main").create())
        elseif params.back == "hook" then
            replaceScene(require("ui.hook.map").create())
        end
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

    require("ui.tutorial").show("ui.hero.main", layer)

    return layer
end

return ui
