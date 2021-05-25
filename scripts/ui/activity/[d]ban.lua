-- 处理活动面板的触摸截断

local ui = {}

require "common.const"
require "common.func"

-- layer: 活动自己的layer
-- scroll: 活动自己的scroll 
function ui.addBan(layer, scroll, board)
    local ban = CCLayer:create()
    layer:addChild(ban, 1000)
    ban:setTouchEnabled(true)
    ban:registerScriptTouchHandler(function(eventType, x, y)
        if eventType == "began" then   
            local pscroll = layer:getParent():getParent().scroll
            local p0 = pscroll:getParent():convertToNodeSpace(ccp(x, y))
            local p1 = scroll:getParent():convertToNodeSpace(ccp(x, y))
            local p2 = nil
            if board then
                p2 = board:getParent():convertToNodeSpace(ccp(x, y))
            end
            if pscroll:boundingBox():containsPoint(p0) 
                or scroll:boundingBox():containsPoint(p1) 
                or (board and board:boundingBox():containsPoint(p2)) then
                ban:setTouchSwallowEnabled(false)
            else
                ban:setTouchSwallowEnabled(true)
            end
            return true
        end
    end)
end

return ui
