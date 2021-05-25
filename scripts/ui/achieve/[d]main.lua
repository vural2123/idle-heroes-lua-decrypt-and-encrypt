local ui = {}

require "common.func"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local i18n = require "res.i18n"
local audio = require "res.audio"
local net = require "net.netClient"
local heros = require "data.heros"
local cfghero = require "config.hero"
local bag = require "data.bag"
local player = require "data.player"
local cfgachieve = require "config.achievement"
local achieveData = require "data.achieve"

function ui.create()
    local layer = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))

    local board = img.createLogin9Sprite(img.login.dialog)
    board:setPreferredSize(CCSize(732, 489))
    board:setScale(view.minScale)
    board:setPosition(view.midX, view.midY)
    layer:addChild(board)
 
    local btnCloseSp = img.createLoginSprite(img.login.button_close)
    local btnClose = SpineMenuItem:create(json.ui.button, btnCloseSp)
    btnClose:setPosition(708, 461)
    local menuClose = CCMenu:createWithItem(btnClose)
    menuClose:setPosition(0, 0)
    board:addChild(menuClose, 1000)
    btnClose:registerScriptTapHandler(function()
        layer:removeFromParentAndCleanup(true)
        audio.play(audio.button)
    end)

    local titleBgLef = img.createUISprite(img.ui.achieve_decoration)
    titleBgLef:setAnchorPoint(ccp(1, 0))
    titleBgLef:setPosition(board:getContentSize().width/2, 417)
    board:addChild(titleBgLef, 1)

    local titleBgRig = img.createUISprite(img.ui.achieve_decoration)
    titleBgRig:setFlipX(true)
    titleBgRig:setAnchorPoint(ccp(0, 0))
    titleBgRig:setPosition(board:getContentSize().width/2, 417)
    board:addChild(titleBgRig, 1)

    local title = lbl.createFont1(24, i18n.global.achieve_title.string, ccc3(0xfa, 0xd8, 0x69))
    title:setPosition(board:getContentSize().width/2, 460)
    board:addChild(title, 100)

    local showAchieveBg = img.createUI9Sprite(img.ui.inner_bg)
    showAchieveBg:setPreferredSize(CCSize(685, 393))
    showAchieveBg:setAnchorPoint(ccp(0.5, 0))
    showAchieveBg:setPosition(board:getContentSize().width/2, 28)
    board:addChild(showAchieveBg)

    local scroll = CCScrollView:create()
    scroll:setDirection(kCCScrollViewDirectionVertical)
    scroll:setAnchorPoint(ccp(0, 0))
    scroll:setPosition(11, 1)
    scroll:setViewSize(CCSize(666, 390))
    scroll:setContentSize(CCSizeMake(0, 0))
    showAchieveBg:addChild(scroll)

    local showItems = {}
    local function loadAchieve()
        local tasks = {}
        --tasks = clone(achieveData.achieveInfos)
        for i, v in ipairs(achieveData.achieveInfos) do
            if (cfgachieve[v.id].status and cfgachieve[v.id].status > 0) or cfgachieve[v.id].completeType == 2 then
                
            else
                tasks[#tasks + 1] = v
            end
        end

        for i=1, #tasks do
            for j=i + 1, #tasks do
                if tasks[i].isComplete ~= tasks[j].isComplete then
                    if tasks[i].isComplete == true then 
                        tasks[i], tasks[j] = tasks[j], tasks[i] 
                    end 
                elseif tasks[j].num >= cfgachieve[tasks[j].id].completeValue then
                    tasks[i], tasks[j] = tasks[j], tasks[i]
                elseif tasks[j].num > 0 and tasks[i].num == 0 then
                    tasks[i], tasks[j] = tasks[j], tasks[i]
                end
            end
        end

        scroll:getContainer():removeAllChildrenWithCleanup(true)
        local height = 6 + 87 * #tasks
        scroll:setContentSize(CCSize(666, height))
        scroll:setContentOffset(ccp(0, 390 - height))

        showItems = {}
        for i, v in ipairs(tasks) do
            local taskBg = img.createUI9Sprite(img.ui.bottom_border_2) 
            taskBg:setPreferredSize(CCSize(660, 85))
            taskBg:setAnchorPoint(ccp(0, 0))
            taskBg:setPosition(2, height - 8 - 87 * i)
            scroll:getContainer():addChild(taskBg)
            
            local showText = lbl.createMixFont1(12, i18n.achievement[v.id].achieveDesc, ccc3(0x5d, 0x2d, 0x12))
            showText:setAnchorPoint(ccp(0, 0))
            showText:setPosition(23, 45)
            taskBg:addChild(showText)

            local progressBg = img.createUI9Sprite(img.ui.playerInfo_process_bar_bg)
            progressBg:setPreferredSize(CCSize(248, 20))
            progressBg:setAnchorPoint(ccp(0, 0))
            progressBg:setPosition(23, 20)
            taskBg:addChild(progressBg)

            local progressFgSp = img.createUISprite(img.ui.achieve_progress_fg)
            local progressFg = createProgressBar(progressFgSp)
            progressFg:setAnchorPoint(ccp(0, 0.5))
            progressFg:setPosition(1, progressBg:getContentSize().height/2)
            progressFg:setPercentage(v.num/cfgachieve[v.id].completeValue*100)
            progressBg:addChild(progressFg)
        
            local showPercent = lbl.createFont2(16, v.num .. "/" .. cfgachieve[v.id].completeValue)
            showPercent:setPosition(progressBg:getContentSize().width/2, progressBg:getContentSize().height/2)
            progressBg:addChild(showPercent)
            
            for k, item in ipairs(cfgachieve[v.id].rewards) do
                local idx = #showItems + 1
                if item.type == 1 then
                    showItems[idx] = img.createItem(item.id, item.num)
                else
                    showItems[idx] = img.createEquip(item.id)
                end
                showItems[idx]:setAnchorPoint(ccp(0, 0.5))
                showItems[idx]:setScale(0.7)
                showItems[idx]:setPosition(taskBg:boundingBox():getMinX() + 272 + k * 67, taskBg:boundingBox():getMidY() + 1)
                scroll:getContainer():addChild(showItems[idx])
                showItems[idx].info = clone(item)
            end
            if v.isComplete == true then
                local showCalimed = img.createUISprite(img.ui.achieve_calim)
                showCalimed:setPosition(581, taskBg:getContentSize().height/2)
                taskBg:addChild(showCalimed)
            else
                local btnCalimSprite = img.createLogin9Sprite(img.login.button_9_small_gold)
                btnCalimSprite:setPreferredSize(CCSize(120, 50))
                local showLab = lbl.createFont1(16, i18n.global.achieve_btn_calim.string, ccc3(0x73, 0x3b, 0x05))
                showLab:setPosition(btnCalimSprite:getContentSize().width/2, btnCalimSprite:getContentSize().height/2 + 1)
                btnCalimSprite:addChild(showLab)
                
                local btnCalim = SpineMenuItem:create(json.ui.button, btnCalimSprite)
                local menuCalim = CCMenu:createWithItem(btnCalim)
                menuCalim:setPosition(0, 0)
                taskBg:addChild(menuCalim)
                btnCalim:setPosition(581, taskBg:getContentSize().height/2)

                btnCalim:registerScriptTapHandler(function()
                    audio.play(audio.button)
                    local params = {
                        sid = player.sid,
                        id = v.id,
                    }

                    addWaitNet()
                    net:achieve_claim(params, function(__data)
                        delWaitNet()

                        tbl2string(__data)
                        if __data.status < 0 then
                            showToast("status:" .. __data.status)
                            return 
                        end

                        achieveData.claim(v.id)
                        bag.addRewards(__data.reward)
                        --layer:addChild(require("ui.tips.reward").create(__data.reward), 1000)
						require("ui.custom").showFloatReward(__data.reward)
                        loadAchieve()
                    end)
                end)
                if v.num < cfgachieve[v.id].completeValue then
                    btnCalim:setEnabled(false)
                    setShader(btnCalim, SHADER_GRAY, true)
                end
            end
        end
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
        if math.abs(y - lasty) > 10 or not board:boundingBox():containsPoint(point) then
            return true
        end
        
        local pointOnScroll = scroll:getContainer():convertToNodeSpace(ccp(x, y))
        for i, v in ipairs(showItems) do
            if v:boundingBox():containsPoint(pointOnScroll) then
                audio.play(audio.button)
                if v.info.type == 1 then
                    local tips = require("ui.tips.item").createForShow(v.info)
                    layer:addChild(tips, 10000)
                else
                    local tips = require("ui.tips.equip").createById(v.info.id)
                    layer:addChild(tips, 10000)
                end               
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
        --if not achieveData.achieveInfos then
        --    local params = {
        --        sid = player.sid,
        --    }

        --    addWaitNet()
        --    net:achieve(params, function(__data)
        --        delWaitNet()

        --        tbl2string(__data)
        --        achieveData.init(__data)
        --        loadAchieve()
        --    end)
        --else
            loadAchieve()
        --end
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

    board:setScale(0.5*view.minScale)
    local anim_arr = CCArray:create()
    anim_arr:addObject(CCScaleTo:create(0.15, 1*view.minScale, 1*view.minScale))
    anim_arr:addObject(CCDelayTime:create(0.15))
    anim_arr:addObject(CCCallFunc:create(function()
    
    end))
    board:runAction(CCSequence:create(anim_arr))

    return layer
end

return ui

