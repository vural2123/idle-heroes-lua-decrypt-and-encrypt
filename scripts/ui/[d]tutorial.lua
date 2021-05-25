-- tutorial, 新手引导

local ui = {}

require "common.const"
require "common.func"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local i18n = require "res.i18n"
local tutorial = require "data.tutorial"
local cfgtutorial = tutorial.getConfig()

-- girl大小
local GIRL_BIG   = 1
local GIRL_SMALL = 2

-- girl位置
local GIRL_LEFT  = 1
local GIRL_RIGHT = 2

-- 箭头指向
local DIRECTION_UP    = 1
local DIRECTION_DOWN  = 2
local DIRECTION_LEFT  = 3
local DIRECTION_RIGHT = 4

local function fixPosition(cfg, center)
    if cfg.fixType then
        if string.sub(cfg.fixType, 1, 1) == "1" then
            center.y = center.y + view.minY
        end
        if string.sub(cfg.fixType, 2, 2) == "1" then
            center.y = center.y - view.minY
        end
        if string.sub(cfg.fixType, 3, 3) == "1" then
            center.x = center.x - view.minX + view.safeOffset
        end
        if string.sub(cfg.fixType, 4, 4) == "1" then
            center.x = center.x + view.minX - view.safeOffset
        end
    end

    return center
end

-- 显示新手引导，eg: tutorial.show("townlayer")
-- layername: 参见config.tutorial的layer项
-- layer: 对应的界面CCLayer
-- 在该页面如果需要新手引导将给传进来layer添加一个新手引导layer
-- 如果不需要新手引导则该函数不做任何事
function ui.show(layername, layer)
    if not TUTORIAL_ENABLE then return end

    cfgtutorial = tutorial.getConfig()

    local id = tutorial.getExecuteId(layername)
    if id then
        if tolua.isnull(layer) then
            return
        end
        if layer.tutocallBack then
            layer.tutocallBack()
        end

        print("tutorial execute id:", id)
        -- 渠道包 去掉绑定账号新手引导
        if isChannel() and cfgtutorial[id].name == "register" then
            return
        end
        -- 设置偏移
        if layername == "ui.town.main" and cfgtutorial[id].townOffsetX then
            layer.setOffsetX(cfgtutorial[id].townOffsetX)
        elseif layername == "ui.hook.map" and cfgtutorial[id].worldOffsetX then
            layer.setOffsetX(cfgtutorial[id].worldOffsetX)
        end

        --特殊弹窗
        local dlgName = cfgtutorial[id].showDlg
        if dlgName then
            if dlgName == "renameDlg" then
               layer:addChild(require("ui.player.changename").create(true), 10000)
            end
            if dlgName == "showHint"then
                layer.showHint()
            end
        end

        -- 创建新手引导layer
        local tlayer = ui.create(id, function()
            tutorial.goNext(cfgtutorial[id].name, cfgtutorial[id].step)
        end)
        tutorial.setNextCallback(function()
            if not tolua.isnull(tlayer) then
                tlayer:removeFromParent()
            end
            ui.show(layername, layer)
        end)
        layer:addChild(tlayer, 100000)
    end
end

local fightLayer

function ui.setFightLayer(layer)
    fightLayer = layer
end

local townMainUILayer

function ui.setTownMainUILayer(layer)
    townMainUILayer = layer
end

-- 创建tutorial的layer
-- id: 对应config.tutorial中的id
-- handler: 当点击之后调用handler
function ui.create(id, handler)
    local layer = CCLayer:create()

    img.load(img.packedOthers.spine_ui_yindao_girl)
    img.load(img.packedUI.ui_tutorial)

    if tutorial.getVersion() ~= 1 then
        img.load(img.packedOthers.spine_ui_yindao_girl)
    end
    

    -- config项
    local cfg = cfgtutorial[id]
    local girl

    -- 将各项东西都放入container，以便于container延迟显示
    local container = CCLayer:create()
    layer:addChild(container)

    local function initGirl()
        if cfg.girl then
            if tutorial.getVersion() == 1 then
                girl = json.create(json.ui.yindao)
            else
                girl = json.create(json.ui.yindao_new)
            end

            if cfg.girlEnter then
                girl:playAnimation("enter")
                girl:appendNextAnimation("stand01")
            else
                girl:playAnimation("stand01")
            end

            if not cfg.girlFace or cfg.girlFace == 1 then
                girl:appendNextAnimation("stand02", -1)
            elseif cfg.girlFace == 2 then
                girl:appendNextAnimation("stand03", -1)
            elseif cfg.girlFace == 3 then
                girl:appendNextAnimation("stand04", -1)
            elseif cfg.girlFace == 4 then
                girl:appendNextAnimation("stand05", -1)
            end

            girl:setScale(view.minScale)
            if cfg.girlSide == GIRL_LEFT then
                girl:setPosition(scalep(95, -58))
            else
                girl:setFlipX(true)
                girl:setPosition(scalep(865, -58))
            end
            container:addChild(girl, 1)
        end
    end

    local delay = cfg.delay or 0.01

    if delay > 0 then
        container:setVisible(false)
        container:runAction(createSequence({
            CCDelayTime:create(delay),
            CCShow:create(),
            CCCallFunc:create(function ( ... )
                initGirl()
            end),
        }))
    else
        initGirl()
    end
    

    -- 变黑
    if cfg.blackSize then
        local render = cc.RenderTexture:create(view.physical.w, view.physical.h)
        render:setPosition(ccp(view.physical.w / 2, view.physical.h / 2))

        local center
        if cfg.touchArea and cfg.touchArea[3] then
            center = ccp(cfg.touchArea[3], cfg.touchArea[4])
        else
            center = ccp(cfg.arrowXY[1], cfg.arrowXY[2])
        end

        center = fixPosition(cfg, scalep(center.x, center.y))

        local renderSprite = render:getSprite()
        renderSprite:setOpacityModifyRGB(true)
        renderSprite:setOpacity(0)
        renderSprite:runAction(cc.FadeIn:create(0.3))
        local renderSprite = render:getSprite()
        local renderTexture = renderSprite:getTexture()
        renderTexture:setAntiAliasTexParameters()

        render:beginWithClear(0, 0, 0, 0)

        local sizeBlack = cfg.blackSize
        local mask = cc.Sprite:create("images/tutorial/tutorial_mask.png")
        local maskSize = mask:getContentSize()
        mask:setScale(math.min(sizeBlack / maskSize.width, sizeBlack / maskSize.height) * view.minScale)
        mask:setPosition(center)
        mask:visit()

        local blackLayer = cc.LayerColor:create(cc.c4b(0, 0, 0, 120))
        local blend = ccBlendFunc:new()
        blend.src = GL_ONE_MINUS_DST_ALPHA
        blend.dst = GL_ZERO
        blackLayer:setBlendFunc(blend)
        blackLayer:visit()

        render:endToLua()

        container:addChild(render)
    end

    -- 是否是自动移除
    local isAutoRemove = (cfg.duration ~= nil)
    if isAutoRemove then
        local delay = cfg.delay or 0.01
        layer:runAction(createSequence({
            CCDelayTime:create(delay + cfg.duration),
            CCRemoveSelf:create(),
            CCCallFunc:create(handler)
        })) 
    end

    -- 大底边banner
    if cfg.girl == GIRL_BIG then
        local banner = img.createUI9Sprite(img.ui.tutorial_text_bg)
        banner:setPreferredSize(CCSize(950, 135))
        banner:setScale(view.minScale)
        banner:setAnchorPoint(ccp(0.5, 0))
        banner:setPosition(scalep(480, 2))
        container:addChild(banner)

        autoLayoutShift(banner, false, true, false, false)

        -- text
        local label = lbl.createMix({
            font = 1, size = 18, text = i18n.global[cfg.text].string,
            color = ccc3(0x72, 0x48, 0x35), width = 640, align = kCCTextAlignmentLeft
        })
        label:setAnchorPoint(ccp(0, 0.5))
        if cfg.girlSide == GIRL_LEFT then
            label:setPosition(230, 70)
        else
            label:setPosition(92, 70)
        end
        banner:addChild(label)
        --drawBoundingbox(container, label)

        if not isAutoRemove and not cfg.arrowXY then
            local posX
            if cfg.girlSide == GIRL_LEFT then
                -- posX = 640 + 230
                posX = 920
            else
                posX = 660 + 95
                -- posX = 30
            end

            local hintIcon = cc.Sprite:create("images/tutorial/tutorial_hint.png")
            hintIcon:setPosition(posX, 42)
            local action = createSequence({
                CCMoveTo:create(0.4, ccp(posX, 22)),
                CCMoveTo:create(0.4, ccp(posX, 32)),
            })
            hintIcon:runAction(CCRepeatForever:create(action))
            banner:addChild(hintIcon)
        end
    end

    if cfg.bubbleBlack then
        local blackLayer = cc.LayerColor:create(cc.c4b(0, 0, 0, 80))
        container:addChild(blackLayer, -1)
    end

    -- 气泡
    if cfg.bubbleXY then
        local bubble = img.createUI9Sprite(img.ui.tutorial_bubble)
        local bubbleMinWidth, bubbleMinHeight = 208, 82
        bubble:setScale(view.minScale)
        if cfg.girlSide == GIRL_LEFT then
            bubble:setAnchorPoint(ccp(0, 0.5))
        else
            bubble:setAnchorPoint(ccp(1, 0.5))
        end
        bubble:setPosition(scalep(cfg.bubbleXY[1], cfg.bubbleXY[2]))
        container:addChild(bubble, 1000)
        -- text
        local label = lbl.createMix({
            font = 1, size = 18, text = i18n.global[cfg.text].string,
            color = ccc3(0x72, 0x48, 0x35), width = 250, align = kCCTextAlignmentLeft
        })
        local labelSize = label:boundingBox().size
        label:setAnchorPoint(ccp(0, 1))
        bubble:addChild(label)
        -- 大小调整
        local bubbleWidth = labelSize.width + 36
        if bubbleWidth < bubbleMinWidth then
            bubbleWidth = bubbleMinWidth
        end
        local bubbleHeight = labelSize.height + 36
        if bubbleHeight < bubbleMinHeight then
            bubbleHeight = bubbleMinHeight
        end
        bubble:setPreferredSize(CCSize(bubbleWidth, bubbleHeight))
        label:setPosition(18, bubbleHeight-18)
        --drawBoundingbox(container, label)
        -- bubble arrow
        local bubbleArrow = img.createUISprite(img.ui.tutorial_bubble_arrow)
        if cfg.girlSide == GIRL_LEFT then
            bubbleArrow:setAnchorPoint(ccp(1, 0.5))
            bubbleArrow:setPosition(3, bubbleHeight/2)
        else
            bubbleArrow:setFlipX(true)
            bubbleArrow:setAnchorPoint(ccp(0, 0.5))
            bubbleArrow:setPosition(bubbleWidth-3, bubbleHeight/2)
        end
        bubble:addChild(bubbleArrow)

        if not isAutoRemove and not cfg.arrowXY then
            local hintIcon = cc.Sprite:create("images/tutorial/tutorial_hint.png")
            hintIcon:setScale(0.5)
            hintIcon:setPosition(bubbleWidth - 16, 22)
            local action = createSequence({
                CCMoveTo:create(0.4, ccp(bubbleWidth - 16, 12)),
                CCMoveTo:create(0.4, ccp(bubbleWidth - 16, 22)),
            })
            hintIcon:runAction(CCRepeatForever:create(action))
            bubble:addChild(hintIcon)
        end
    end

    -- 绘制点击区域
    local clickArea
    if cfg.arrowXY then
        clickArea = CCLayerColor:create(ccc4(0, 0, 0, 150))
        clickArea:setScale(view.maxScale)
        clickArea:ignoreAnchorPointForPosition(false)
        clickArea:setAnchorPoint(ccp(0.5, 0.5))
        if cfg.touchArea then
            clickArea:setContentSize(CCSize(cfg.touchArea[1], cfg.touchArea[2]))
            if cfg.touchArea[3] then
                clickArea:setPosition(scalep(cfg.touchArea[3], cfg.touchArea[4]))
            else
                clickArea:setPosition(scalep(cfg.arrowXY[1], cfg.arrowXY[2]))
            end
        else
            clickArea:setPosition(scalep(cfg.arrowXY[1], cfg.arrowXY[2]))
            clickArea:setContentSize(CCSize(80, 80))
        end
        local center = fixPosition(cfg, ccp(clickArea:getPosition()))
        clickArea:setPosition(center)

        clickArea:setVisible(false)
        container:addChild(clickArea)
        --drawBoundingbox(container, clickArea)
    end

    local moveArea
    if cfg.clickMove then
        moveArea = CCLayerColor:create(ccc4(255, 0, 0, 150))
        moveArea:setScale(view.maxScale)
        moveArea:ignoreAnchorPointForPosition(false)
        moveArea:setAnchorPoint(ccp(0.5, 0.5))
        moveArea:setPosition(scalep(cfg.clickMove[1], cfg.clickMove[2]))
        moveArea:setContentSize(CCSize(cfg.clickMove[3], cfg.clickMove[4]))
        moveArea:setVisible(false)
        container:addChild(moveArea)
    end

    -- arrow
    if cfg.arrowDirection then
        local arrow = json.create(json.ui.yd_hand)
        arrow:setScale(view.minScale)
        arrow:setPosition(scalep(cfg.arrowXY[1], cfg.arrowXY[2]))
        arrow:playAnimation("animation", -1)
        container:addChild(arrow)

        local center = fixPosition(cfg, ccp(arrow:getPosition()))
        arrow:setPosition(center)

        if moveArea then
            arrow:stopAnimation()
            arrow:setPosition(scalep(cfg.arrowXY[1] - 15, cfg.arrowXY[2] + 6))

            local center = fixPosition(cfg, ccp(arrow:getPosition()))
            arrow:setPosition(center)

            local action = createSequence({
                cc.DelayTime:create(0.1),
                cc.MoveTo:create(0.6, fixPosition(cfg, scalep(cfg.clickMove[1] - 30, cfg.clickMove[2] + 6))),
                cc.DelayTime:create(0.2),
                cc.Hide:create(),
                cc.DelayTime:create(0.8),
                cc.CallFunc:create(function ()
                    arrow:setVisible(true)
                    arrow:setPosition(fixPosition(cfg, scalep(cfg.arrowXY[1] - 15, cfg.arrowXY[2] + 6)))
                end),
            })
            arrow:runAction(cc.RepeatForever:create(action))
        end
    end

    --是否暂停
    if cfg.pause and fightLayer and not tolua.isnull(fightLayer) then
        if cfg.pause[1] <= 0.01 then
            fightLayer.isPaused = false
            resumeSchedulerAndActions(fightLayer)
        else
            if cfg.pause[2] then
                layer:runAction(createSequence({
                    CCDelayTime:create(cfg.pause[2]),
                    CCCallFunc:create(function ()
                        fightLayer.isPaused = true
                        pauseSchedulerAndActions(fightLayer)
                    end),
                }))
            else
                fightLayer.isPaused = true
                pauseSchedulerAndActions(fightLayer)
            end
        end
    end

    if cfg.sayGodby then
        if girl then
            girl:clearNextAnimation()
            girl:playAnimation("stand02", 1, 0)

            girl:runAction(createSequence({
                cc.MoveTo:create(0.2, scalep(53,86)),
                CCCallFunc:create(function ( ... )
                    girl:playAnimation("exit", 1)
                end)
            })) 
        end

        if townMainUILayer and not tolua.isnull(townMainUILayer) then
            townMainUILayer.initHelperUI(false)
        end
    end

    -- for touch
    local touchbeginx, touchbeginy

    local function onTouchBegan(x, y)
        touchbeginx, touchbeginy = x, y
        if clickArea and clickArea:boundingBox():containsPoint(ccp(x, y)) then
            layer:setVisible(false)--隐藏是很重要的，阻止再次接受touch事件
            HHUtils:sendTouchBegan(clickArea:getPositionX(), clickArea:getPositionY())
        end
        return true
    end

    local moveX, moveY = -1000, -1000
    local function onTouchMoved(x, y)
        if math.abs(moveX - x) < 0.001 and math.abs(moveY - y) < 0.001 then
            return
        end
        moveX, moveY = x, y

        if moveArea then
            HHUtils:sendTouchMoved(x, y)
        end
    end

    local function onTouchEnded(x, y)
        if moveArea then
            moveX, moveY = -1000, -1000

            local removeSelf, sendTouch = false, false
            if clickArea:boundingBox():containsPoint(ccp(touchbeginx, touchbeginy)) and moveArea:boundingBox():containsPoint(ccp(x, y)) then
                removeSelf = true
                sendTouch = true
            else
                local scene = CCDirector:sharedDirector():getRunningScene()
                scene:runAction(CCCallFunc:create(function()
                    HHUtils:sendTouchEnded(clickArea:getPositionX() + 11, clickArea:getPositionY())
                    layer:setVisible(true)
                end))
            end
            if removeSelf then
                layer:removeFromParent()
                if sendTouch then
                    local scene = CCDirector:sharedDirector():getRunningScene()
                    scene:runAction(CCCallFunc:create(function()
                        HHUtils:sendTouchEnded(moveArea:getPositionX(), moveArea:getPositionY())
                    end))
                end
                handler()
            end

            return
        end

        local removeSelf, sendTouch = false, false
        if clickArea then
            if clickArea:boundingBox():containsPoint(ccp(touchbeginx, touchbeginy)) then
                removeSelf = true
                sendTouch = true
            end
        elseif not isAutoRemove and cfg.girl then
            removeSelf = true
        end
        if removeSelf then
            layer:removeFromParent()
            if sendTouch then
                local scene = CCDirector:sharedDirector():getRunningScene()
                scene:runAction(CCCallFunc:create(function()
                    HHUtils:sendTouchEnded(clickArea:getPositionX(), clickArea:getPositionY())
                end))
            end
            handler()
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

    layer:registerScriptTouchHandler(onTouch, false, -128, true)
    layer:setTouchEnabled(true)

    if cfg.girl or cfg.arrowXY or isAutoRemove then
        layer:setTouchSwallowEnabled(true)
    else
        layer:setTouchSwallowEnabled(false)
    end

    layer:setKeypadEnabled(true)
    layer:addNodeEventListener(cc.KEYPAD_EVENT, function(event)
        if event.key == "back" then
            if layer._exit_flag then
                layer._exit_flag = nil
                layer:removeChildByTag(require("ui.dialog").TAG)
            else
                layer._exit_flag = true
                exitGame(layer)
            end
        end
    end)

    return layer
end

return ui
