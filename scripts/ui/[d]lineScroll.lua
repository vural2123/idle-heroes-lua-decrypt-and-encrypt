local lineScroll = {}

lineScroll.TAG_CONTENT_LAYER = 1117

function lineScroll.create(params)
    local scroll_w = params.width or 0
    local scroll_h = params.height or 0
    local scroll = CCScrollView:create()
    scroll:setDirection(kCCScrollViewDirectionVertical)
    scroll:setViewSize(CCSize(scroll_w, scroll_h))
    scroll:setContentSize(CCSize(scroll_w, scroll_h))
    scroll.height = scroll_h
    scroll.width = scroll_w
    scroll.cur_height = 0
    -- content_layer
    local content_layer = CCLayer:create()
    content_layer:setAnchorPoint(CCPoint(0,1))
    content_layer:setPosition(CCPoint(0, scroll_h))
    scroll:getContainer():addChild(content_layer, 1, lineScroll.TAG_CONTENT_LAYER)
    scroll.content_layer = content_layer

    local allItems = {}
    function scroll.addItem(itemObj)
        itemObj.ax = itemObj.ax or 0
        itemObj.ay = itemObj.ay or 0
        itemObj.px = itemObj.px or 0
        local cur_height = scroll.cur_height or 0
        local obj_height = itemObj.height
        if not obj_height then
            obj_height = itemObj:getContentSize().height
        end
        local cur_height = cur_height + obj_height
        itemObj:setAnchorPoint(CCPoint(itemObj.ax, itemObj.ay))
        if itemObj.ay == 0.5 then
            itemObj:setPosition(CCPoint(itemObj.px, 0-cur_height+obj_height/2))
        else
            itemObj:setPosition(CCPoint(itemObj.px, 0-cur_height))
        end
        scroll.content_layer:addChild(itemObj)
        allItems[#allItems+1] = itemObj
        scroll.cur_height = cur_height
        if cur_height > scroll.height then
            scroll:setContentSize(CCSizeMake(scroll.width, cur_height))
            scroll.content_layer:setPosition(CCPoint(0, cur_height))
        else
            scroll:setContentSize(CCSizeMake(scroll.width, scroll.height))
            scroll.content_layer:setPosition(CCPoint(0, scroll.height))
        end
    end

    function scroll.validUI(itemObj, deltaH)
        local findItem = nil
        for ii=1,#allItems do
            if findItem then
                allItems[ii]:setPositionY(allItems[ii]:getPositionY()-deltaH)
            end
            if allItems[ii] == itemObj then
                findItem = true
            end
        end
        scroll.cur_height = scroll.cur_height + deltaH
        scroll.addSpace(0)
    end

    function scroll.addSpace(space_height)
        local cur_height = scroll.cur_height or 0
        cur_height = cur_height + space_height
        if cur_height > scroll.height then
            scroll:setContentSize(CCSizeMake(scroll.width, cur_height))
            scroll.content_layer:setPosition(CCPoint(0, cur_height))
        else
            scroll:setContentSize(CCSizeMake(scroll.width, scroll.height))
            scroll.content_layer:setPosition(CCPoint(0, scroll.height))
        end
        scroll.cur_height = cur_height
    end

    function scroll.setOffset(where)
        local cur_height = scroll.cur_height or 0
        if where == "begin" then
            if cur_height > scroll.height then
                scroll:setContentOffset(CCPoint(0, scroll.height - cur_height))
            else
                scroll:setContentOffset(CCPoint(0, 0))
            end
        elseif where == "end" then
            scroll:setContentOffset(CCPoint(0, 0))
        end
    end

    function scroll.setOffsetBegin()
        scroll.setOffset("begin")
    end

    function scroll.setOffsetEnd()
        scroll.setOffset("end")
    end

    function scroll.updateOffsetEnd(objHeight)
        local offset_y = scroll:getContentOffset().y
        if offset_y > 0 then
            scroll.setOffsetBegin()
        elseif offset_y > -10 then
            scroll.setOffsetEnd()
        end
    end

    return scroll
end


return lineScroll
