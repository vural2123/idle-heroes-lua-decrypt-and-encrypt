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
local bag = require "data.bag"
local reward = require "ui.reward"
local databrave = require "data.brave"

local rewardlevel = {
    3,
    6,
    9,
    12,
    15
}

function ui.create(callback)
    local layer = CCLayerColor:create(ccc4(0,0,0,POPUP_DARK_OPACITY))
    -- board
    local board_w = 762
    local board_h = 375

    img.load(img.packedOthers.ui_brave)
    local board = img.createUI9Sprite(img.ui.dialog_1)
    board:setPreferredSize(CCSizeMake(board_w, board_h))
    board:setScale(view.minScale)
    board:setPosition(view.physical.w/2, view.physical.h/2)
    layer:addChild(board)

    -- title
    local title = lbl.createFont1(24, i18n.global.brave_lr_title.string, ccc3(0xe6, 0xd0, 0xae))
    title:setPosition(CCPoint(board_w/2, board_h-32))
    board:addChild(title, 1)
    local title_shadowD = lbl.createFont1(24, i18n.global.brave_lr_title.string, ccc3(0x59, 0x30, 0x1b))
    title_shadowD:setPosition(CCPoint(board_w/2, board_h-34))
    board:addChild(title_shadowD)

    -- anim
    board:setScale(0.5*view.minScale)
    board:runAction(CCScaleTo:create(0.15, 1*view.minScale, 1*view.minScale))

    local bottom = img.createUI9Sprite(img.ui.bag_btn_inner_bg)
    bottom:setPreferredSize(CCSizeMake(702, 242))
    bottom:setAnchorPoint(0, 0)
    bottom:setPosition(CCPoint(30, 58))
    board:addChild(bottom)

    local function judgeboxstatus(pos)
        if databrave.stage > rewardlevel[pos] then
            if databrave.nodes then
                for i = 1,#databrave.nodes do
                    if databrave.nodes[i] == rewardlevel[pos] then
                        return "3"
                    end
                end
                return "2"
            else
                return "2"
            end
        else
            return "1" 
        end
    end

    local sx = 180
    local dx = 118

    local itemBtn = {}
    local bravebox = {}
    local grid = {}
    --local boxcount = 0
    --for i=1,5 do
    --    if judgeboxstatus(i) == "2" then
    --        boxcount = boxcount + 1
    --    end
    --end
    
    local function showRewardItems(pos)
        pos = pos*3
        local tipslayer = CCLayer:create()
        tipslayer.tipsTag = false
        local tipsbg = img.createUI9Sprite(img.ui.tips_bg)
        tipsbg:setPreferredSize(CCSize(312, 206))
        tipsbg:setScale(view.minScale)
        tipsbg:setPosition(view.physical.w/2, view.physical.h/2)
        tipslayer:addChild(tipsbg)

        local tipstitle = lbl.createFont1(18, i18n.global.brave_baoxiang_tips.string, ccc3(0xff, 0xe4, 0x9c))
        tipstitle:setPosition(312/2, 174)
        tipsbg:addChild(tipstitle)

        local line = img.createUISprite(img.ui.help_line)
        line:setScaleX(242/line:getContentSize().width)
        line:setPosition(CCPoint(312/2, 150))
        tipsbg:addChild(line)

        local cfgnode = require "config.bravenode"
        for i=1,2 do
            local item = img.createItem(cfgnode[pos].rewards[i].id, cfgnode[pos].rewards[i].num)
            local itembtn = SpineMenuItem:create(json.ui.button, item)
            --itembtn:setScale(0.85)
            itembtn:setPosition(tipsbg:getContentSize().width/2-55+(i-1)*110, 78)
            local iconMenu = CCMenu:createWithItem(itembtn)
            iconMenu:setPosition(0, 0)
            tipsbg:addChild(iconMenu)
            
            itembtn:registerScriptTapHandler(function()
                audio.play(audio.button)
                if tipslayer.tipsTag == false then
                    tipslayer.tipsTag = true
                    local tipsitem = require "ui.tips.item"
                    tips = tipsitem.createForShow({id = cfgnode[pos].rewards[i].id, num = cfgnode[pos].rewards[i].num})
                    tipslayer:addChild(tips, 200)
                    tips.setClickBlankHandler(function()
                        tips:removeFromParent()
                        tipslayer.tipsTag = false
                    end)
                end
                
            end)
        end

        local clickBlankHandler
        function tipslayer.setClickBlankHandler(handler)
            clickBlankHandler = handler
        end
        tipslayer.setClickBlankHandler(function()
            itemBtn[pos/3].gridSelected:setVisible(false)
            tipslayer:removeFromParent()
        end)
        local function onTouch(eventType, x, y)
            if eventType == "began" then   
                return true
            elseif eventType == "moved" then
                return 
            else
                if not tipsbg:boundingBox():containsPoint(ccp(x, y)) then
                    tipslayer.onAndroidBack()
                end
            end
        end

        addBackEvent(tipslayer)

        function tipslayer.onAndroidBack()
            if clickBlankHandler then
                clickBlankHandler()
            else
                tipslayer:removeFromParent()
                itemBtn[i].gridSelected:setVisible(false)
            end
        end
        tipslayer:setTouchEnabled(true)
        tipslayer:setTouchSwallowEnabled(true)
        tipslayer:registerScriptTouchHandler(onTouch)
        return tipslayer 
    end

    for i=1,5 do
        local raw = img.createUISprite(img.ui.brave_level_raw)
        raw:setAnchorPoint(0.5, 0)
        raw:setPosition(sx+(i-1)*dx, 142)
        board:addChild(raw, 1)

        local numlab = lbl.createFont1(20, rewardlevel[i], ccc3(0x73, 0x3b, 0x05))
        numlab:setPosition(sx+(i-1)*dx, 100)
        board:addChild(numlab)

        grid[i] = img.createUISprite(img.ui.grid)
        local gridSelected = img.createUISprite(img.ui.bag_grid_selected)
        gridSelected:setAnchorPoint(ccp(0, 0))
        gridSelected:setVisible(false)
        grid[i]:addChild(gridSelected)
        itemBtn[i] = SpineMenuItem:create(json.ui.button, grid[i])
        itemBtn[i]:setPosition(sx+(i-1)*dx, 220)
        itemBtn[i].gridSelected = gridSelected
        local rewardMenu = CCMenu:createWithItem(itemBtn[i])
        rewardMenu:setPosition(0, 0)
        board:addChild(rewardMenu)

        if i < 4 then
            json.load(json.ui.yuanzheng_baoxiang)
            bravebox[i] = DHSkeletonAnimation:createWithKey(json.ui.yuanzheng_baoxiang)
        else
            json.load(json.ui.yuanzheng_baoxiang_gem)
            bravebox[i] = DHSkeletonAnimation:createWithKey(json.ui.yuanzheng_baoxiang_gem)
        end
        bravebox[i]:scheduleUpdateLua()
        if judgeboxstatus(i) == "2" then
            bravebox[i]:playAnimation("2", -1)
        elseif judgeboxstatus(i) == "3" then
            itemBtn[i]:setEnabled(false)
            bravebox[i]:playAnimation("1")
            local blackicon = img.createUISprite(img.ui.brave_rl_black)
            blackicon:setPosition(grid[i]:getContentSize().width/2, grid[i]:getContentSize().height/2)
            blackicon:setOpacity(85)
            itemBtn[i]:addChild(blackicon, 1001)

            local tickIcon = img.createUISprite(img.ui.hook_btn_sel)
            tickIcon:setPosition(grid[i]:getContentSize().width/2, grid[i]:getContentSize().height/2)
            itemBtn[i]:addChild(tickIcon, 1001)
        else
            --itemBtn[i]:setEnabled(false)
            bravebox[i]:playAnimation(judgeboxstatus(i))
        end
        bravebox[i]:setPosition(grid[i]:getContentSize().width/2, grid[i]:getContentSize().height/2)
        grid[i]:addChild(bravebox[i], 1000)

        itemBtn[i]:registerScriptTapHandler(function()
            audio.play(audio.button)
            if judgeboxstatus(i) == "1" then
                itemBtn[i].gridSelected:setVisible(true)
                local tipslayer = showRewardItems(i)
                layer:addChild(tipslayer)
                --showToast(i18n.global.brave_lr_noreceive.string)
                return 
            end
            
        end)
    end

    local function getRewards()
        local stageis = {}
        local stages = {}
        for i = 1,5 do
            if judgeboxstatus(i) == "2" then
                stageis[#stageis+1] = i
                stages[#stages+1] = rewardlevel[i]
            end
        end
        if #stageis < 1 then
            return
        end
        local param = {}
        param.sid = player.sid
        param.stage = stages
        addWaitNet()
        net:brave_node(param, function(__data)
            delWaitNet()
            tbl2string(__data)
            if __data.status ~= 0 then
                showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
                return
            end
            if databrave.nodes == nil then
                --local node = {rewardlevel[i]}
                local node = stages  
                databrave.nodes = node
            else
                for i = 1,#stages do 
                    databrave.nodes[#databrave.nodes+1] = stages[i]
                end
                --databrave.nodes[#databrave.nodes+1] = stages
            end
            --boxcount = boxcount - 1
            for i = 1,#stageis do
                bravebox[stageis[i]]:stopAnimation()
                bravebox[stageis[i]]:playAnimation("3") 
                itemBtn[stageis[i]]:setEnabled(false)
            end
            local ban = CCLayer:create()
            ban:setTouchEnabled(true)
            ban:setTouchSwallowEnabled(true)
            layer:addChild(ban, 1001)
            bag.addRewards(__data.reward)
            schedule(layer, 1, function()
                --if boxcount == 0 then
                    callback()
                --end
                for i = 1,#stageis do
                    bravebox[stageis[i]]:stopAnimation()
                    bravebox[stageis[i]]:playAnimation("1")
                    local blackicon = img.createUISprite(img.ui.brave_rl_black)
                    blackicon:setPosition(grid[stageis[i]]:getContentSize().width/2, grid[stageis[i]]:getContentSize().height/2)
                    blackicon:setOpacity(85)
                    itemBtn[stageis[i]]:addChild(blackicon, 1001)

                    local tickIcon = img.createUISprite(img.ui.hook_btn_sel)
                    tickIcon:setPosition(grid[stageis[i]]:getContentSize().width/2, grid[stageis[i]]:getContentSize().height/2)
                    itemBtn[stageis[i]]:addChild(tickIcon, 1001)
                end

                ban:removeFromParent()
                layer:addChild(reward.showRewardForbraveBox(__data.reward), 1002)
            end)

        end)
    end

    getRewards()
    -- exp bar
    local expreBar = img.createUI9Sprite(img.ui.brave_level_expbg)
    expreBar:setPreferredSize(CCSize(630, 26))
    expreBar:setPosition(board_w/2, 130)
    board:addChild(expreBar,1)

    local percel = (databrave.stage-1)*0.06
    if databrave.stage == 7 then
       percel = 0.368 
    elseif databrave.stage == 10 then
       percel = 0.555 
    elseif databrave.stage == 13 then
       percel = 0.742 
    elseif databrave.stage == 16 then
       percel = 1 
    end
    local progress0 = img.createUISprite(img.ui.brave_level_exppro)
    local powerProgress = createProgressBar(progress0)
    powerProgress:setPosition(expreBar:getContentSize().width/2, expreBar:getContentSize().height/2)
    powerProgress:setPercentage(percel*100)
    expreBar:addChild(powerProgress)
    
    local slicon = img.createUISprite(img.ui.brave_level_circle)
    slicon:setPosition(percel*630, 13)
    expreBar:addChild(slicon)
    local sllab = lbl.createFont1(16, databrave.stage-1, ccc3(0x1d, 0x67, 0x00))
    sllab:setPosition(slicon:getContentSize().width/2, slicon:getContentSize().height/2)
    slicon:addChild(sllab)
    if databrave.stage == 16 then
        slicon:setVisible(false)
    end

    local function backEvent()
        audio.play(audio.button)
        layer:removeFromParentAndCleanup()
    end

    -- close btn
    local close0 = img.createUISprite(img.ui.close)
    local closeBtn = SpineMenuItem:create(json.ui.button, close0)
    closeBtn:setPosition(CCPoint(board_w-22, board_h-26))
    local closeMenu = CCMenu:createWithItem(closeBtn)
    closeMenu:setPosition(CCPoint(0, 0))
    board:addChild(closeMenu)
    closeBtn:registerScriptTapHandler(function()     
        backEvent()
    end)

    --local function onUpdate(ticks)
    --end
    --layer:scheduleUpdateWithPriorityLua(onUpdate, 0)
    layer:setTouchEnabled(true)
    
    function layer.onAndroidBack()
        backEvent()
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

    return layer
end

return ui
