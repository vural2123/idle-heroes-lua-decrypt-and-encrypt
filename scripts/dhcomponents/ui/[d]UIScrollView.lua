local UIScrollView = class("UIScrollView", function ()
	local scroll = cc.ScrollView:create()
	scroll._onTouchBegan = scroll.onTouchBegan
	scroll._onTouchMoved = scroll.onTouchMoved
	scroll._onTouchEnded = scroll.onTouchEnded
	scroll._onTouchCancelled = scroll.onTouchCancelled
	return scroll
end)

cc.SCROLLVIEW_DIRECTION_NONE = -1
cc.SCROLLVIEW_DIRECTION_HORIZONTAL = 0
cc.SCROLLVIEW_DIRECTION_VERTICAL = 1
cc.SCROLLVIEW_DIRECTION_BOTH  = 2

function UIScrollView.create(params)  --{direction, container, containerSize, }
	local scroll = UIScrollView.new(params)

	return scroll
end

function UIScrollView:ctor(params)	
	params = params or {}

	if params.container then 
		self:setContainer(params.container)
	end

	self:setViewSize(params.viewSize or cc.size(0,0))
	self:setContentSize(params.contentSize or params.viewSize or cc.size(0,0))
	self:setContentOffset(cc.p(0, 0))
	self:setDirection(params.direction or cc.SCROLLVIEW_DIRECTION_HORIZONTAL)
   	self:setClippingToBounds((params.clipping == nil) and true or false)
   	self:setBounceable((params.bounceable == nil) and true or false)
    self:setDelegate()
    self:setTouchEnabled(false)

    -- 移动监听回调
    self.moveCallback = params.moveCallback

    local listener = cc.EventListenerTouchOneByOne:create()
    listener:setSwallowTouches(true)
	--注册触摸事件
    listener:registerScriptHandler(handler(self, self.onTouchBegan), cc.Handler.EVENT_TOUCH_BEGAN)
    listener:registerScriptHandler(handler(self, self.onTouchMoved), cc.Handler.EVENT_TOUCH_MOVED)
    listener:registerScriptHandler(handler(self, self.onTouchEnded), cc.Handler.EVENT_TOUCH_ENDED)
    listener:registerScriptHandler(handler(self, self.onTouchCancelled), cc.Handler.EVENT_TOUCH_CANCELLED)
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)

    self.touchEnable = true

	--register lock msg
	local lockListener = cc.EventListenerCustom:create("dh_lock_ui", function(eventCustom)
		self:setEnabled(false)
	end)
	eventDispatcher:addEventListenerWithSceneGraphPriority(lockListener, self)
end

function UIScrollView:setEnabled(enable)
    if enable ~= self.touchEnable then
        self.touchEnable = enable
    end
end

function UIScrollView:isEnabled()
    return self.touchEnable
end

function UIScrollView:interceptTouchEventCheck(type, sender, touch, event)
	local touchPoint = touch:getLocation()

	if not self:isVisible() or not self:hasVisibleParents() then
		return false
	end

	if type == "began" then
		local touchIn = self:_onTouchBegan(touch, event)
		if touchIn then
			self.isGetIntercept = true
		end
		return touchIn
	elseif type == "moved" then
		if self:isEnabled() then
			local startPoint = touch:getStartLocation()
			local offset = cc.pGetDistance(startPoint,touchPoint)

			if self.moveCallback and offset > UIScrollView.getChildFocusCancelOffset()then
				self.moveCallback()
			end

			if offset > UIScrollView.getChildFocusCancelOffset() then 
				self:_onTouchMoved(touch, event)
	            sender:unselected()
			end
		end
	elseif type == "ended" then
		self:_onTouchEnded(touch, event)

		if sender:isSwallowTouches() then 
			self.isGetIntercept = false
		end
	end
end

function UIScrollView:onTouchBegan(touch, event)
	if not self.isGetIntercept and self:isEnabled() then
		local ret = self:_onTouchBegan(touch, event)
		return ret
	end
	return false
end

function UIScrollView:onTouchMoved(touch, event)
	if not self.isGetIntercept and self:isEnabled() then
		self:_onTouchMoved(touch, event)
	end
end

function UIScrollView:onTouchEnded(touch, event)
	if not self.isGetIntercept and self:isEnabled() then
		self:_onTouchEnded(touch, event)
	end

	self.isGetIntercept = false
end

function UIScrollView:onTouchCancelled(touch, event)
	if not self.isGetIntercept and self:isEnabled() then
		self:_onTouchCancelled(touch, event)
	end

	self.isGetIntercept = false
end

function UIScrollView:hasVisibleParents()
    local  parent = self:getParent()

    while parent ~= nil do
        if not parent:isVisible() then 
            return false
        end

        parent = parent:getParent()
    end  

    return true
end


function UIScrollView.getChildFocusCancelOffset()
	return 15
end

return UIScrollView