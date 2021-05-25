local ui = {}

require "common.func"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local i18n = require "res.i18n"
local player = require "data.player"
local net = require "net.netClient"
local oheadData = require "data.head"
local cfghead = require "config.head"
local audio = require "res.audio"

function ui.create(curIcon, callback)
    local layer = CCLayerColor:create(ccc4(0, 0, 0, 210))

    local headData = oheadData
    -- 处理特殊头像，奇葩逻辑
    local bagdata = require "data.bag"
    local itemHead = headData.getItemhead()
    for i,v in pairs (itemHead) do  
        if not bagdata.items.find(i) then
            headData[v].hide = true
        else
            headData[v].hide = nil
        end
    end
	headData.forceRed = nil
    --if not bagdata.items.find(ITEM_ID_SP_SUB) then
    --    headData[95].hide = true
    --else
    --    headData[95].hide = nil
    --end
    local function hidePetHead()
        local cfgpet = require"config.pet"
        for k,v in pairs(cfgpet) do
            for ii=1,#v.petIcon do
                if headData[v.petIcon[ii]] then
                    headData[v.petIcon[ii]].hide = true
                end
            end
        end
    end
    hidePetHead()
	
	for i, v in ipairs(cfghead) do
		if v.type then
			if v.type == 10 then
				headData[i].hide = true
			elseif v.type == 2 then
				if v.reqSkin and v.reqSkin > 0 and player.skinicons and player.skinicons[v.reqSkin] then
					headData[i].hide = nil
					if player.skinicons[v.reqSkin] == 2 then
						player.skinicons[v.reqSkin] = 1
						headData[i].isNew = true
					end
				else
					headData[i].hide = true
				end
			end
		end
	end
	
    --headData[69].hide = true
    --headData[70].hide = true
    --headData[71].hide = true
    --headData[72].hide = true
    --headData[73].hide = true
    --for i = 1,15 do
    --    headData[i+76].hide = true
    --end

    --for hidx=ITEM_ID_SP_F3V3_HEAD_1, ITEM_ID_SP_F3V3_HEAD_5 do
    --    local head_id = 55 + ITEM_ID_SP_F3V3_HEAD_5 - hidx
    --    if not bagdata.items.find(hidx) then
    --        headData[head_id].hide = true
    --    else
    --        headData[head_id].hide = nil
    --    end
    --end

    local board = img.createUI9Sprite(img.ui.tips_bg)
    board:setPreferredSize(CCSize(662, 420))
    board:setScale(view.minScale)
    board:setPosition(view.midX, view.midY)
    layer:addChild(board)

    -- closeBtn
    local closeBtn0 = img.createUISprite(img.ui.close)
    local closeBtn = SpineMenuItem:create(json.ui.button, closeBtn0)
    closeBtn:setPosition(board:getContentSize().width-20, board:getContentSize().height-24)
    local closeMenu = CCMenu:createWithItem(closeBtn)
    closeMenu:setPosition(0, 0)
    board:addChild(closeMenu)
    closeBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer.onAndroidBack()
    end)

    local showTitle = lbl.createFont1(24, i18n.global.player_change_head_title.string, ccc3(0xff, 0xe3, 0x86))
    showTitle:setPosition(331 , 385)
    board:addChild(showTitle)

    local showFgline = img.createUI9Sprite(img.ui.hero_enchant_info_fgline)
    showFgline:setPreferredSize(CCSize(606, 1))
    showFgline:setPosition(331, 357)
    board:addChild(showFgline)

    local headnum = 0
    for i, v in ipairs(headData) do
        if not headData[i].hide then
            headnum = headnum + 1
        end
    end
    local height = 101 * math.ceil(headnum/6) 
    local scroll = CCScrollView:create()
    scroll:setDirection(kCCScrollViewDirectionVertical)
    scroll:setAnchorPoint(ccp(0, 0))
    scroll:setPosition(-2, 6)
    scroll:setViewSize(CCSize(660, 350))
    scroll:setContentSize(CCSize(662, height))
    board:addChild(scroll)

    local function addSel(hnode)
        local icon_sel = img.createUISprite(img.ui.hook_btn_sel)
        icon_sel:setScale(0.65)
        icon_sel:setAnchorPoint(CCPoint(1, 0))
        icon_sel:setPosition(CCPoint(hnode:getContentSize().width, 0))
        hnode:addChild(icon_sel)
    end
	
	local function isSel(logo)
		if curIcon then
			if curIcon == logo then return true end
		else
			if player.logo == logo then return true end
		end
		return false
	end

    local showHeads = {}
    local count = 1
    for i, v in ipairs(headData) do
        if not headData[i].hide then
            local x = math.ceil(count/6) 
            local y = count - (x - 1) * 6
            count = count + 1
            if i <= #cfghead then
                showHeads[i] = img.createPlayerHead(i)
                if isSel(i) then
                    addSel(showHeads[i])
                end
            else
                showHeads[i] = img.createPlayerHead(v.iconId)
                if isSel(v.iconId) then
                    addSel(showHeads[i])
                end
            end
            if headData[i].isNew then
                print("isNew", i, headData[i].isNew)
            end
            if not curIcon and headData[i].isNew and headData[i].isNew == true then
                addRedDot(showHeads[i], {
                    px = showHeads[i]:getContentSize().width - 10,
                    py = showHeads[i]:getContentSize().height - 10,
                })
            end
            showHeads[i]:setAnchorPoint(ccp(0, 0))
            showHeads[i]:setPosition(40 + 101 * (y - 1), height - 99 * x - 5)
            scroll:getContainer():addChild(showHeads[i])
        else
            if i <= #cfghead then
                showHeads[i] = img.createPlayerHead(i)
            else
                showHeads[i] = img.createPlayerHead(v.iconId)
            end
            showHeads[i]:setAnchorPoint(ccp(0, 0))
            showHeads[i]:setPosition(-1000, 1000)
            showHeads[i]:setVisible(false)
            scroll:getContainer():addChild(showHeads[i])
        end
    end
    for i=1, #headData do
        if headData[i] and headData[i].isNew then
            headData[i].isNew = false
        end
    end
    scroll:setContentOffset(ccp(0, 350 - height))

    local function onSelect(idx)
        audio.play(audio.button)
        local params = {
            sid = player.sid,
            logo = idx,
        }
        if idx > #cfghead then
            params.logo = headData[idx].iconId
        end
		
		if callback then
			callback(params.logo)
			if layer and not tolua.isnull(layer) then
                layer:removeFromParentAndCleanup(true)
            end
			return
		end

        addWaitNet()
        net:change_logo(params, function(__data)
            delWaitNet()

            tbl2string(__data)
            if __data.status ~= 0 then
                showToast("server status:" .. __data.status)
                return
            end
        
            player.logo = params.logo
            if layer and not tolua.isnull(layer) then
                layer:removeFromParentAndCleanup(true)
            end
        end)
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
        local point = layer:convertToNodeSpace(ccp(x, y))
        local pointOnScroll = scroll:getContainer():convertToNodeSpace(ccp(x, y))

        if math.abs(y - lasty) > 10 then
            return
        end

        if not board:boundingBox():containsPoint(point) then
            layer:removeFromParentAndCleanup(true)
            return
        end

        for i, v in ipairs(showHeads) do
            if v:boundingBox():containsPoint(pointOnScroll) then
                onSelect(i) 
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

    layer:registerScriptTouchHandler(onTouch)
    layer:setTouchEnabled(true)

    addBackEvent(layer)
    function layer.onAndroidBack()
        layer:removeFromParentAndCleanup(true)
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

    return layer
end

return ui

