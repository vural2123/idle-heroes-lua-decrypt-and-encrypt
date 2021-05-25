-- show this when waiting network

local waitnet = {}

require "common.func"
local view = require "common.view"
local img = require "res.img"
local json = require "res.json"
local particle = require "res.particle"

-- onTimeout: timeout callback, can be nil
-- time: timeout duration, can be nil, default NET_TIMEOUT
function waitnet.create(onTimeout, time)
    local layer = CCLayer:create()

    -- dark bg
    local darkbg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    darkbg:setVisible(false)
    layer:addChild(darkbg)

    -- detect timeout
    local startTime = os.time()
    local timeout = time or NET_TIMEOUT
    function layer.setTimeout(t)
        timeout = t
    end
 
    -- icon
    json.load(json.ui.lag_loading)
    local icon = DHSkeletonAnimation:createWithKey(json.ui.lag_loading)
    icon:setScale(view.minScale)
    icon:scheduleUpdateLua()
    icon:playAnimation("animation", -1)
    icon:setPosition(view.physical.w/2, view.physical.h/2)
    --local icon = img.createLoginSprite(img.login.wait_net)
    --icon:setScale(view.minScale)
    --icon:setPosition(view.physical.w/2, view.physical.h/2)
    --icon:runAction(CCRepeatForever:create(CCRotateBy:create(0.3, 180)))
    icon:setVisible(false)
    layer:addChild(icon)

    -- particle
    local picon = particle.create("lag_loading")
    picon:setScale(view.minScale)
    picon:setPosition(view.physical.w/2, view.physical.h/2)
    picon:setVisible(false)
    layer:addChild(picon)

    local arr = CCArray:create()
    arr:addObject(CCDelayTime:create(1))
    arr:addObject(CCCallFunc:create(function()
        darkbg:setVisible(true)
        icon:setVisible(true)
        picon:setVisible(true)
    end))
    layer:runAction(CCSequence:create(arr))

    -- 超时处理
    layer:scheduleUpdateWithPriorityLua(function()
        local now = os.time()
        if now - startTime > timeout then
            layer:removeFromParent()
            if onTimeout then 
                onTimeout()
            else
                popReconnectDialog()
            end
        end
    end, 0)

    layer:setTouchEnabled(true)
    layer:setTouchSwallowEnabled(true)

    return layer
end

return waitnet
