local schedulerUtil = require("dhcomponents.tools.SchedulerUtil")
local TAG_BUTTON_SCALE = 1032808

local UIButton = class("UIButton", function()
    return display.newNode()
end)

UIButton.noShaderTag = 96421
UIButton.selectedBtnMap = {}

--images 有三个可选参数分别是images.normal  images.selected  images.disabled
--onClick  是按钮被点击之后的回调函数
--extends 是扩展参数{selectedHandler 开始触摸按钮时的回调,unselectedHandler结束按钮触摸的回调,cancelledHandler取消按钮点击的回调}
--selectedProgram 点击按钮时的shader效果    disabledProgram禁用按钮时的shader效果
--selectedScale 点击按钮时的缩放系数    lockDuration按钮被触发后的锁定时间
function UIButton:ctor(images, onClick, extends)
    --显示层
    self.images = images

	--监听按钮
	self.onClick = onClick

	--扩展参数
	if extends then
        self.selectedHandler = extends.selectedHandler
        self.unselectedHandler = extends.unselectedHandler
        self.cancelledHandler = extends.cancelledHandler
        self.selectedProgram = extends.selectedProgram
        self.disabledProgram = extends.disabledProgram
        self.selectedScale = extends.selectedScale
        self.lockDuration = extends.lockDuration
    end

    if not self.selectedProgram and not self.selectedScale then
       self.selectedScale = 0.85
    end

	self.touchEnable = true
    self.pressed = false
    self.glProgramMap = {}

    self:setAnchorPoint(cc.p(0.5, 0.5))

	--设置显示图片
    if self.images.normal then
        self:setContentSize(self.images.normal:getContentSize())
        self:addChild(self.images.normal)
        self.images.normal:setAnchorPoint(cc.p(0, 0))
    end
    if self.images.selected then
        self.images.selected:setVisible(false)
        self:addChild(self.images.selected)
        self.images.selected:setAnchorPoint(cc.p(0, 0))
    end
    if self.images.disabled then
        self.images.disabled:setVisible(false)
        self:addChild(self.images.disabled)
        self.images.disabled:setAnchorPoint(cc.p(0, 0))
    end

	if self.onClick then
		self:onTouch()
	end

    self:registerScriptHandler(function(event)
        if event == "cleanup" then
            self:onCleanup()
        end
    end)
end

function UIButton:onCleanup()
    UIButton.selectedBtnMap[self] = nil
end

function UIButton:drawTouchRect()
    if self.drawNode then
        self.drawNode:removeFromParent()
    end
    local contentSize = self:getContentSize()
    self.drawNode = cc.DrawNode:create()
    self.drawNode:drawRect(cc.p(0, 0), cc.p(contentSize.width, 0), cc.p(contentSize.width, contentSize.height), cc.p(0, contentSize.height), cc.c4f(1, 0, 0, 1))
    self:addChild(self.drawNode)
end

function UIButton:setContentSize(contentSize)
    cc.Node.setContentSize(self, contentSize)

    --debug
    --self:drawTouchRect()
end

function UIButton:setInterceptEnabled(enabled)
    self.interceptEnabled = enabled
end

function UIButton:setTouchHandler(handler)
    self.onClick = handler

    if self.onClick then
        self:onTouch()
    end
end

--触摸方法
function UIButton:onTouch()
    self.touchEnable = true
    self.pressed = false

    local function onTouch(eventType, x, y)
        local touch = {}
        touch.getLocation = function ()
            return cc.p(x, y)
        end
        touch.getStartLocation = function ()
            return self.touchStartLocation
        end

        if eventType == "began" then
            self.touchStartLocation = cc.p(x, y)
            return self:onTouchBegan(touch)        
        elseif eventType == "moved" then
            return self:onTouchMoved(touch)    
        else
            return self:onTouchEnded(touch)    
        end
    end

    self:registerScriptTouchHandler(onTouch)
    self:setTouchEnabled(true)
end

function UIButton:onTouchBegan(touch, event)
    local point = touch:getLocation()
    if not self:contains(point) or not self.touchEnable or not self:isVisible() or not self:hasVisibleParents() then
        return false
    end
    if not self:propagateTouchEvent("began", self,touch, event) then 
        return false
    end
    if self.onClick then
        self:selected()
        return true
    else
        return false
    end
end

function UIButton:onCancelled()
    if self.cancelledHandler then
        self.cancelledHandler(self)
    end
end

function UIButton:onTouchMoved(touch, event)
    local point = touch:getLocation()
    self:propagateTouchEvent("moved", self,touch, event)
    if not self.pressed or not self.touchEnable then 
        return 
    end
    
    if not self:contains(point) then
        self:unselected()
        self:onCancelled()
    end
end

function UIButton:setLockDuration(lockDuration)
    self.lockDuration = lockDuration
end

function UIButton:getLockDuration()
    return self.lockDuration or 0.1
end

function UIButton:lockDelay()
    if UIButton.lockId == nil then
        UIButton.lockId = schedulerUtil:performWithDelayGlobal(function ()
            schedulerUtil:unscheduleGlobal(UIButton.lockId)
            UIButton.lockId = nil
        end, self:getLockDuration())
    end
end

function UIButton.isLock()
    return UIButton.lockId ~= nil
end

function UIButton:setSoundEffect(effName)
    self.soundEffectName = effName
end

function UIButton:setSoundWorking(working)
    self.soundWorking = working
end

--业务相关逻辑
function UIButton:handleOperation()
    --sound
    --local effectName = self.soundEffectName or "UI/btn"
end

function UIButton.unselectedAll()
    for btn, _ in pairs(UIButton.selectedBtnMap) do
        btn:unselected()
    end
end

function UIButton:handleClick()
    if UIButton.isLock() then
        return
    end

    self:lockDelay()

    self:handleOperation()

    self.onClick(self)

    UIButton.unselectedAll()
end

function UIButton:onTouchEnded(touch, event)
    local point = touch:getLocation()
    self:propagateTouchEvent("ended", self, touch, event)
    if not self.pressed or not self.touchEnable then 
        return 
    end

    self:unselected()
    
    if self:contains(point) and self.onClick and self:hasVisibleParents() then
        self:handleClick()
    end
end

function UIButton:onTouchCancelled(touch, event)
    self:unselected()
    self:onCancelled()
end

function UIButton:setEnabled(enable)
    if self.touchEnable ~= enable then
        self.touchEnable = enable
        self:updateImagesVisibility()

        if not enable then
            self:unselected()
        end
    end
end

function UIButton:isEnabled()
    return self.touchEnable
end

function UIButton:setOriginGLProgram(node) --设置本源颜色
    local program = self.glProgramMap[node]
    if program then
        node:setGLProgram(program)
    end

    local childArray = node:getChildren()
    for _, child in ipairs(childArray) do
        self:setOriginGLProgram(child)
    end
end

function UIButton:resetOriginGLProgram()
    self:setOriginGLProgram(self)
end

function UIButton:setDisplayGLProgram(program, record)
    if self.glCascadeEnabled == nil or self.glCascadeEnabled == true then
        self:setCascadeGLProgram(self, program, record)
    else
        if self.images.normal then
            self:setCascadeGLProgram(self.images.normal, program, record)
        end
    end
end

function UIButton:setCascadeGLProgram(node, program, record) --递归设置
    if node then
        if node:getTag() ~= UIButton.noShaderTag then
            if record then
                self.glProgramMap[node] = node:getGLProgram()
            end

            node:setGLProgram(program)
        end

        local childArray = node:getChildren()
        for _, child in ipairs(childArray) do
            self:setCascadeGLProgram(child, program, record)
        end
    end
end

function UIButton:setGLCascadeEnabled(enabled)
    self.glCascadeEnabled = enabled
end

function UIButton:updateImagesVisibility()
    if self.touchEnable then
        if self.images.disabled then
            if self.images.normal then
                self.images.normal:setVisible(true)
            end
            if self.images.selected then
                self.images.disabled:setVisible(false)
            end
            self.images.disabled:setVisible(false)
        else
            if self.images.normal then
                self.images.normal:setVisible(true)
                self:resetOriginGLProgram()
            end
            if self.images.selected then
                self.images.disabled:setVisible(false)
            end
        end
    else
        if self.images.disabled then
            if self.images.normal then
                self.images.normal:setVisible(false)
            end
            if self.images.selected then
                self.images.disabled:setVisible(false)
            end
            self.images.disabled:setVisible(true)
        else
            if self.images.normal then
                self.images.normal:setVisible(true)
                if self.disabledProgram then
                    self:setDisplayGLProgram(self.disabledProgram, true)
                end
            end
            if self.images.selected then
                self.images.disabled:setVisible(false)
            end
        end
    end
end

function UIButton:setNormalImage(image)
    if image ~= self.images.normal then
        if self.images.normal then
            self.images.normal:removeFromParent()
            self.images.normal = nil
        end

        self.images.normal = image

        if self.images.normal then
            self:setContentSize(self.images.normal:getContentSize())
            self:addChild(self.images.normal)
            self.images.normal:setAnchorPoint(cc.p(0, 0))
            self:updateImagesVisibility()

            if self.pressed then
                if self.images.selected then
                    self.images.normal:setVisible(false)
                else
                    if self.selectedProgram then
                        self:setDisplayGLProgram(self.selectedProgram, true)
                    end
                end
            end
        end
    end
end

function UIButton:contains(point)
    local location
    if self.backupScaleX then
        local backupScaleX = self:getScaleX()
        local backupScaleY = self:getScaleY()
        self:setScaleX(self.backupScaleX)
        self:setScaleY(self.backupScaleY)

        location = self:convertToNodeSpace(point)

        self:setScaleX(backupScaleX)
        self:setScaleY(backupScaleY)
    else
        location = self:convertToNodeSpace(point)
    end

    local contentSize = self:getContentSize()
    local rect = cc.rect(0, 0, contentSize.width, contentSize.height)
    return cc.rectContainsPoint(rect, location)
end

function UIButton:isSwallowTouches()
    return true
end

function UIButton:propagateTouchEvent(type, sender, touch, event)
    if self.interceptEnabled == false then
        return true
    end

    return self:interceptTouchEventCheck(type, sender, touch, event)
end

function UIButton:interceptTouchEventCheck(type, sender, touch, event)
    local parent = self:getParent()

    while parent ~= nil do
        if parent.interceptTouchEventCheck then 
            return parent:interceptTouchEventCheck(type, sender, touch, event)
        end

         parent = parent:getParent()
    end 

    return true       
end

function UIButton:hasVisibleParents()
    local  parent = self:getParent()

    while parent ~= nil do
        if not parent:isVisible() then 
            return false
        end

        parent = parent:getParent()
    end  

    return true
end

function UIButton:selected()
    if self.pressed then
        return
    end

    UIButton.selectedBtnMap[self] = true

    --debug
    -- local pos = self:convertToWorldSpace(cc.p(0, 0))
    -- local contentSize = self:getContentSize()
    -- print("@@@@@@  touchPos: ", pos.x + contentSize.width * 0.5, " , ", pos.y + 
    --     contentSize.height * 0.5, "  size: ", contentSize.width, " , ", contentSize.height)

    if self.selectedHandler then
        self.selectedHandler(self)
    end

    self.pressed = true
    if self.images.selected then
        self.images.selected:setVisible(true)
        if self.images.normal then
            self.images.normal:setVisible(false)
        end
    else
        if self.selectedProgram and self.images.normal then
            self:setDisplayGLProgram(self.selectedProgram, true)
        end

        if self.selectedScale then
            if self.backupScaleX == nil then
                self.backupScaleX = self:getScaleX()
                self.backupScaleY = self:getScaleY()
            end

            self:stopActionByTag(TAG_BUTTON_SCALE)
            local action = cc.ScaleTo:create(0.03, self.backupScaleX * self.selectedScale, self.backupScaleY * self.selectedScale)
            action:setTag(TAG_BUTTON_SCALE)
            self:runAction(action)
        end
    end

    if self.longPressInfo then
        self.longPressInfo.timeCount = -self.longPressInfo.delayTime + (self.longPressInfo.interval or 0)
        self:scheduleUpdate(function (dt)
            local interval = self.longPressInfo.interval
            self.longPressInfo.timeCount = self.longPressInfo.timeCount + dt
            if interval then
                if self.longPressInfo.timeCount >= interval then
                    self.longPressInfo.timeCount = self.longPressInfo.timeCount - interval
                    self.longPressInfo.callBack(self)
                end
            else
                if self.longPressInfo.timeCount >= 0 then
                    self.longPressInfo.timeCount = 0
                    self:unscheduleUpdate()
                    self.longPressInfo.callBack(self)
                end
            end
        end)
    end
end

function UIButton:unselected()
    if not self.pressed then
        return
    end

    UIButton.selectedBtnMap[self] = nil

    if self.unselectedHandler then
        self.unselectedHandler(self)
    end

    self.pressed = false
    if self.images.selected then
        self.images.selected:setVisible(false)
        if self.images.normal then
            self.images.normal:setVisible(true)
        end
    else
        if self.selectedProgram and self.images.normal then
            self:resetOriginGLProgram()
        end

        if self.selectedScale then
            self:stopActionByTag(TAG_BUTTON_SCALE)
            local action1 = cc.ScaleTo:create(0.04, self.backupScaleX * 1.05, self.backupScaleY * 1.05)
            local action2 = cc.ScaleTo:create(0.04, 0.5 * self.backupScaleX * (self.selectedScale + 1), 0.5 * self.backupScaleY * (self.selectedScale + 1))
            local action3 = cc.ScaleTo:create(0.06, self.backupScaleX, self.backupScaleY)
            local array = CCArray:create()
            array:addObject(action1)
            array:addObject(action2)
            array:addObject(action3)
            local actionAll = cc.Sequence:create(array)
            actionAll:setTag(TAG_BUTTON_SCALE)
            self:runAction(actionAll)
        end
    end

    if self.longPressInfo and self.longPressInfo.timeCount then
        self.longPressInfo.timeCount = nil
        self:unscheduleUpdate()
    end
end

function UIButton:setLongPressCallback(callBack, delayTime ,interval)
    self.longPressInfo = {callBack = callBack, delayTime = delayTime, interval = interval}
end

function UIButton:removeAllChildren()
    local childArray = self:getChildren()
    for _, child in ipairs(childArray) do
        if child ~= self.images.normal and child ~= self.images.selected and child ~= self.images.disabled then
            self:removeChild(child)
        end
    end
end

return UIButton