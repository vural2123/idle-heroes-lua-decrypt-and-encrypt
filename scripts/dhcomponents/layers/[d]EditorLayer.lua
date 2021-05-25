local editorComponent = require("dhcomponents.EditorComponent")
local UIHelper = require("dhcomponents.tools.UIHelper")

local EditorLayer = class("EditorLayer", function()
    return cc.Layer:create()
end)

EditorLayer.TouchNodeWidth = 65
EditorLayer.TouchNodeHeight = 65
EditorLayer.TouchNodeMaxRadius = 45
EditorLayer.TouchNodeMinRadius = 10
EditorLayer.OptMode = {
    POSITION = 1,
    ROTATE = 2,
    SCALE = 3,
    ATTRIBUTE = 4,
    SETTING = 5,
}
EditorLayer.SelectedMode = {
    BOTH = 1,
    VERTOCAL = 2,
    HORIZONTAL = 3,
}

function EditorLayer:ctor(keyCode)
    if keyCode == "KEY_Q" then
        self.mode = EditorLayer.OptMode.POSITION
    elseif keyCode == "KEY_W" then
        self.mode = EditorLayer.OptMode.ROTATE
    elseif keyCode == "KEY_E" then
        self.mode = EditorLayer.OptMode.SCALE
    elseif keyCode == "KEY_S" then
        self.mode = EditorLayer.OptMode.ATTRIBUTE
    elseif keyCode == "KEY_D" then
        self.mode = EditorLayer.OptMode.SETTING
    end

    self:updateModeState()

    self.nodeInfoMap = {}
    local nodeMap = editorComponent:getAllActiveNode()
    for node, info in pairs(nodeMap) do
        self.nodeInfoMap[node] = {info = clone(info)}
    end

    self:analyzeNodeOrder(cc.Director:sharedDirector():getRunningScene(), 0)

    self:initTouch()

    self:setKeypadEnabled(true)
    self:addNodeEventListener(cc.KEYPAD_EVENT, handler(self, self.onKeypadCallback))

    self:setKeypadEnabled(true)
    self:addNodeEventListener(cc.KEYPAD_EVENT, function(event)
        if event.key == "KEY_ESC" then
            editorComponent:endEditor()
        end
    end)

    if keyCode == "KEY_A" then
        self:showAllNodeBoundingBox()
    end

    self:registerScriptHandler(function(event)
        if event == "cleanup" then
            self:onCleanup()
        end
    end)

    self.keyPressedFlagMap = {}
end

function EditorLayer:updateModeState()
    if self.titleLabel then
        self.titleLabel:removeFromParent()
        self.titleLabel = nil
    end

    local text = ""
    if self.mode == EditorLayer.OptMode.POSITION then
        text = "移动模式"
    elseif self.mode == EditorLayer.OptMode.ROTATE then
        text = "旋转模式"
    elseif self.mode == EditorLayer.OptMode.SCALE then
        text = "缩放模式"
    elseif self.mode == EditorLayer.OptMode.ATTRIBUTE then
        text = "属性模式"
    elseif self.mode == EditorLayer.OptMode.SETTING then
        text = "设置模式"
    end

    local label = CCLabelTTF:create(text, "", 32)
    label:setColor(cc.c3b(255, 20, 20))
    label:setOpacity(200)
    self:addChild(label)

    local winSize = cc.Director:sharedDirector():getWinSize()
    label:setPosition(winSize.width * 0.5, winSize.height - 60)
    self.titleLabel = label

    self:recalculationSelectedNodeCenter()

    self:showSelectedNode()
end

function EditorLayer:onKeypadCallback(event)
    local keyCode = event.key
    local isPressed = event.isPressed

    if self.inTouchFlag then
        return
    end

    --KEY_HYPER  command
    if isPressed then
        self.keyPressedFlagMap[keyCode] = true

        if keyCode == "KEY_LEFT_ARROW" then
            self:onKeyboardMoved(-1, 0)
        elseif keyCode == "KEY_RIGHT_ARROW" then
            self:onKeyboardMoved(1, 0)
        elseif keyCode == "KEY_UP_ARROW" then
            self:onKeyboardMoved(0, 1)
        elseif keyCode == "KEY_DOWN_ARROW" then
            self:onKeyboardMoved(0, -1)
        end
    else
        self.keyPressedFlagMap[keyCode] = nil

        if keyCode == "KEY_Q" then
            self.mode = EditorLayer.OptMode.POSITION
        elseif keyCode == "KEY_W" then
            self.mode = EditorLayer.OptMode.ROTATE
        elseif keyCode == "KEY_E" then
            self.mode = EditorLayer.OptMode.SCALE
        elseif keyCode == "KEY_A" then
            self:showAllNodeBoundingBox()
        elseif keyCode == "KEY_S" then
            self.mode = EditorLayer.OptMode.ATTRIBUTE
        elseif keyCode =="KEY_D" then
            self.mode = EditorLayer.OptMode.SETTING
        elseif keyCode == "KEY_Z" then
            if self.keyPressedFlagMap["KEY_ALT"] then
                if self.keyPressedFlagMap["KEY_SHIFT"] then
                    editorComponent:redoOperation()
                else
                    editorComponent:undoOperation()
                end
            end
        end

        self:updateModeState()

        if keyCode == "KEY_LEFT_ARROW" or keyCode == "KEY_RIGHT_ARROW" or keyCode == "KEY_UP_ARROW" or keyCode == "KEY_DOWN_ARROW" then
            self:syncTextState()
        end
    end
end

function EditorLayer:showAllNodeBoundingBox()
    if self.showAllNodeFlag then
        self.showAllNodeFlag = nil
        for node, _ in pairs(self.nodeInfoMap) do
            if node.boundingBoxdrawNode then
                node.boundingBoxdrawNode:removeFromParent()
                node.boundingBoxdrawNode = nil
            end
        end
    else
        self.showAllNodeFlag = true
        for node, _ in pairs(self.nodeInfoMap) do
            local info = self.nodeInfoMap[node]
            if info then
                if tolua.type(node) ~= "CCLabelBMFont" then
                    local contentSize = node:getContentSize()
                    self:fixContentSize(contentSize)
                    local width = contentSize.width
                    local height = contentSize.height

                    local boundingBoxdrawNode = cc.DrawNode:create()
                    boundingBoxdrawNode:drawSolidRect(cc.p(0, 0), cc.p(width, height), cc.c4f(0, 1, 0, 0.4))
                    node:addChild(boundingBoxdrawNode)
                    node.boundingBoxdrawNode = boundingBoxdrawNode
                end
            end
        end
    end
end

function EditorLayer:analyzeNodeOrder(node, zorder)
    if node then
        node:sortAllChildren()
        local children = node:getChildren()
        if not children then
            if self.nodeInfoMap[node] then
                self.nodeInfoMap[node].zorder = zorder
            end
            return zorder + 1
        end

        local childCount = children:count()

        local i = 0
        while i < childCount do
            local child = tolua.cast(children:objectAtIndex(i), "CCNode")
            if child:getZOrder() >= 0 then
                break
            end
            i = i + 1
            zorder = self:analyzeNodeOrder(child, zorder)
        end

        if self.nodeInfoMap[node] then
            self.nodeInfoMap[node].zorder = zorder
        end

        zorder = zorder + 1

        while i < childCount do
            local child = tolua.cast(children:objectAtIndex(i), "CCNode")
            i = i + 1
            zorder = self:analyzeNodeOrder(child, zorder)
        end
    end

    return zorder
end

function EditorLayer:onCleanup()
    self:hideSelectedNode()

    if self.showAllNodeFlag then
        self:showAllNodeBoundingBox()
    end
end

function EditorLayer:initTouch()
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

function EditorLayer:onTouchBegan(touch, event)
    self.inTouchFlag = true

    local location = touch:getLocation()
    if self.selectedInfo and not self.keyPressedFlagMap["KEY_ALT"] then
        if self.mode == EditorLayer.OptMode.POSITION or self.mode == EditorLayer.OptMode.SCALE then
            if self.selectedInfo.touchRectVertical:containsPoint(location) then
                self.selectedMode = EditorLayer.SelectedMode.VERTOCAL
            elseif self.selectedInfo.touchRectHorizontal:containsPoint(location) then
                self.selectedMode = EditorLayer.SelectedMode.HORIZONTAL
            elseif self.selectedInfo.touchRect:containsPoint(location) then
                self.selectedMode = EditorLayer.SelectedMode.BOTH
            end
        elseif self.mode == EditorLayer.OptMode.ROTATE then
            local dist = location:getDistance(self.selectedInfo.pos)
            if dist <= EditorLayer.TouchNodeMaxRadius and dist >= EditorLayer.TouchNodeMinRadius then
                self.selectedMode = EditorLayer.SelectedMode.BOTH
            end
        end
    end
    return true
end

function EditorLayer:onTouchMoved(touch, event)
    local location = touch:getLocation()
    local startLocation = touch:getStartLocation()

    local function createDrawNode()
        local drawNode = cc.DrawNode:create()
        drawNode:drawSolidRect(startLocation, location, cc.c4f(1, 1, 0, 0.7), 4)
        self:addChild(drawNode)
        return drawNode
    end

    if self.selectedMode then
        self:onSelectedMoved(touch)
    elseif self.checkBoxInfo then
        self.checkBoxInfo.drawNode:removeFromParent()
        self.checkBoxInfo.drawNode = createDrawNode()

        self:onCheckBoxOpt(touch)
    else
        if location:getDistance(startLocation) > 10 then
            self.checkBoxInfo = {drawNode = createDrawNode()}
            self:clearSelectedInfo()
        end
    end
end

function EditorLayer:onTouchEnded(touch, event)
    self.inTouchFlag = nil

    if self.checkBoxInfo then
        self.checkBoxInfo.drawNode:removeFromParent()
        self.checkBoxInfo = nil

        self:onCheckBoxOpt(touch)
    elseif not self.selectedMode then
        local resNodeAry = {}
        if self.keyPressedFlagMap["KEY_ALT"] and self.selectedInfo then
            for _, info in ipairs(self.selectedInfo.nodeInfoAry) do
                table.insert(resNodeAry, info.node)
            end
        end

        self:clearSelectedInfo()

        local resNode
        for node, _ in pairs(self.nodeInfoMap) do
            local info = self.nodeInfoMap[node]
            if info then
                local contentSize = node:getContentSize()
                self:fixContentSize(contentSize)
                local rect = cc.rect(0, 0, contentSize.width, contentSize.height)
                local point = node:convertToNodeSpace(touch:getLocation())
                if rect:containsPoint(point) and UIHelper.hasVisibleParents(node) then
                    if not resNode or info.zorder > self.nodeInfoMap[resNode].zorder then
                        resNode = node
                    end
                end
            end
        end

        local same = false
        for i, node in ipairs(resNodeAry) do
            if node == resNode then
                same = true
                table.remove(resNodeAry, i)
                break
            end
        end

        if not same then
            table.insert(resNodeAry, resNode)
        end

        self:onSelectedNode(resNodeAry)
        self:showSelectedNode()
    else
        self.selectedMode = nil
        self.selectedInfo.center = clone(self.selectedInfo.pos)

        for _, info in ipairs(self.selectedInfo.nodeInfoAry) do
            local node = info.node
            print("@@@ ", node, tolua.isnull(node))
            local anchorPoint = node:getAnchorPoint()
            local contentSize = node:getContentSize()
            info.pos = node:convertToWorldSpace(cc.p(contentSize.width * anchorPoint.x, contentSize.height * anchorPoint.y))
            info.angleX = node:getRotationX()
            info.angleY = node:getRotationY()
            info.scaleX = node:getScaleX()
            info.scaleY = node:getScaleY()

            self:syncNodeState(node)
        end

        local center = self.selectedInfo.center
        local width = EditorLayer.TouchNodeWidth
        local height = EditorLayer.TouchNodeHeight
        self.selectedInfo.touchRect = cc.rect(center.x - width * 0.5, center.y - height * 0.5, width, height)

        self:syncTextState()
    end
end

function EditorLayer:clearSelectedInfo()
    if self.selectedInfo then
        self:hideSelectedNode()
        self.selectedInfo = nil
    end
end

function EditorLayer:onCheckBoxOpt(touch)
    local location = touch:getLocation()
    local startLocation = touch:getStartLocation()
    local minX = math.min(location.x, startLocation.x)
    local minY = math.min(location.y, startLocation.y)
    local maxX = math.max(location.x, startLocation.x)
    local maxY = math.max(location.y, startLocation.y)
    local touchRect = cc.rect(minX, minY, maxX - minX, maxY - minY)

    local resNodeAry = {}
    for node, _ in pairs(self.nodeInfoMap) do
        local info = self.nodeInfoMap[node]
        if info then
            local contentSize = node:getContentSize()
            self:fixContentSize(contentSize)

            local insideFlag = true
            local posAry = {cc.p(0, 0), cc.p(0, contentSize.height), cc.p(contentSize.width, 0), cc.p(contentSize.width, contentSize.height)}
            for _, pos in ipairs(posAry) do
                local worldPos = node:convertToWorldSpace(pos)
                if not touchRect:containsPoint(worldPos) or not UIHelper.hasVisibleParents(node) then
                    insideFlag = false
                    break
                end
            end
            if insideFlag then
                table.insert(resNodeAry, node)
            end
        end
    end

    local same = true
    if self.selectedInfo then
        if #resNodeAry == #self.selectedInfo.nodeInfoAry then
            for i, node in ipairs(resNodeAry) do
                if node ~= self.selectedInfo.nodeInfoAry[i].node then
                    same = false
                    break
                end
            end
        else
            same = false
        end
    else
        same = false
    end

    if not same then
        self:clearSelectedInfo()
        self:onSelectedNode(resNodeAry)
        self:showSelectedNode()
    end
end

function EditorLayer:syncNodeState(node)
    local info = self.nodeInfoMap[node].info
    local orgInfo = info.orgInfo

    info.pos = cc.p(node:getPosition())

    local angleX = node:getRotationX()
    if angleX ~= orgInfo.angleX then
        info.angleX = angleX
    end
    local angleY = node:getRotationY()
    if angleY ~= orgInfo.angleY then
        info.angleY = angleY
    end

    local scaleX = node:getScaleX()
    if scaleX ~= orgInfo.scaleX then
        info.scaleX = scaleX
    end
    local scaleY = node:getScaleY()
    if scaleY ~= orgInfo.scaleY then
        info.scaleY = scaleY
    end
    local anchor = node:getAnchorPoint()
    if anchor.x ~= orgInfo.anchor.x or anchor.y ~= orgInfo.anchor.y then
        info.anchor = anchor
        info.orgAnchor = clone(anchor)
    end
    local color = node:getColor()
    if color.r ~= orgInfo.color.r or color.g ~= orgInfo.color.g or color.b ~= orgInfo.color.b then
        info.color = color
        orgInfo.color = clone(color)
    end
    local opacity = node:getOpacity()
    if opacity ~= orgInfo.opacity then
        info.opacity = opacity
        orgInfo.opacity = opacity
    end
end

function EditorLayer:syncTextState()
    for _, info in ipairs(self.selectedInfo.nodeInfoAry) do
        self:syncNodeState(info.node)
    end

    editorComponent:pushOperation(self.nodeInfoMap)
end

function EditorLayer:onSelectedMoved(touch)
    local location = touch:getLocation()
    local startOffset = cc.pSub(touch:getStartLocation(), self.selectedInfo.center)

    if self.mode == EditorLayer.OptMode.POSITION then
        location = cc.pSub(location, startOffset)

        if self.selectedMode == EditorLayer.SelectedMode.VERTOCAL then
            location.x = self.selectedInfo.center.x
        elseif self.selectedMode == EditorLayer.SelectedMode.HORIZONTAL then
            location.y = self.selectedInfo.center.y
        end

        self.selectedInfo.pos = location
        self.selectedInfo.drawNode:setPosition(location)

        local diffPos = cc.pSub(location, self.selectedInfo.center)
        for _, info in ipairs(self.selectedInfo.nodeInfoAry) do
            local node = info.node
            local pos = info.pos
            pos = cc.pAdd(pos, diffPos)
            local finalPos = node:getParent():convertToNodeSpace(pos)
            node:setPosition(finalPos)
        end
    elseif self.mode == EditorLayer.OptMode.ROTATE then
        local diffPos = cc.pSub(location, self.selectedInfo.center)
        if diffPos.x ~= 0 or diffPos.y ~= 0 then
            local orgAngle = -cc.pToAngleSelf(startOffset) / math.pi * 180
            local curAngle = -cc.pToAngleSelf(diffPos) / math.pi * 180
            local diffAngle = curAngle - orgAngle

            for _, info in ipairs(self.selectedInfo.nodeInfoAry) do
                local node = info.node
                local angle = info.angleX
                local finalAngle = angle + diffAngle
                node:setRotation(finalAngle)
            end
        end
    else
        location = cc.pSub(location, startOffset)

        if self.selectedMode == EditorLayer.SelectedMode.VERTOCAL then
            location.x = self.selectedInfo.center.x
        elseif self.selectedMode == EditorLayer.SelectedMode.HORIZONTAL then
            location.y = self.selectedInfo.center.y
        end

        local diffPos = cc.pSub(location, self.selectedInfo.center)
        for _, info in ipairs(self.selectedInfo.nodeInfoAry) do
            local node = info.node
            if self.selectedMode == EditorLayer.SelectedMode.BOTH then
                local scale = (diffPos.x + diffPos.y) / 100

                node:setScaleX(info.scaleX + scale)
                node:setScaleY(info.scaleY + scale)
            else
                local scaleX = diffPos.x / 50
                local scaleY = diffPos.y / 50

                node:setScaleX(info.scaleX + scaleX)
                node:setScaleY(info.scaleY + scaleY)
            end

        end
    end
end

function EditorLayer:onKeyboardMoved(x, y)
    if not self.selectedInfo then
        return
    end

    if self.mode == EditorLayer.OptMode.POSITION then
        for _, info in ipairs(self.selectedInfo.nodeInfoAry) do
            local node = info.node
            node:setPositionX(node:getPositionX() + x)
            node:setPositionY(node:getPositionY() + y)

            info.pos = cc.p(node:getPosition())
        end

        self.selectedInfo.pos.x = self.selectedInfo.pos.x + x
        self.selectedInfo.pos.y = self.selectedInfo.pos.y + y
        self.selectedInfo.center = clone(self.selectedInfo.pos)
    elseif self.mode == EditorLayer.OptMode.ROTATE then
        for _, info in ipairs(self.selectedInfo.nodeInfoAry) do
            local node = info.node
            local angle = info.angleX + x + y * 0.1
            node:setRotation(angle)

            info.angleX = node:getRotation()
            info.angleY = node:getRotation()
        end
    elseif self.mode == EditorLayer.OptMode.SCALE then
        for _, info in ipairs(self.selectedInfo.nodeInfoAry) do
            local node = info.node
            node:setScaleX(node:getScaleX() + x * 0.1)
            node:setScaleY(node:getScaleY() + y * 0.1)

            info.scaleX = node:getScaleX()
            info.scaleY = node:getScaleY()
        end
    end

    self:showSelectedNode()
end

function EditorLayer:hideSelectedNode()
    if self.selectedInfo then
        if self.selectedInfo.drawNode then
            self.selectedInfo.drawNode :removeFromParent()
            self.selectedInfo.drawNode = nil
        end

        local nodeInfoAry = self.selectedInfo.nodeInfoAry
        for _, info in ipairs(nodeInfoAry) do
            if info.drawNode then
                info.drawNode:removeFromParent()
                info.drawNode = nil
            end
        end
    end
end

function EditorLayer:fixContentSize(contentSize)
    if contentSize.width == 0 then
        contentSize.width = 60
    end
    if contentSize.height == 0 then
        contentSize.height = 60
    end
    if contentSize.width <= 8 and contentSize.height <= 8 then
        contentSize.width = 12
        contentSize.height = 12
    end
end

function EditorLayer:showSelectedNode()
    self:hideSelectedNode()

    if self.selectedInfo then
        local curPos = self.selectedInfo.pos
        self.selectedInfo.drawNodeAry = {}

        local drawNode = cc.Node:create()
        self.selectedInfo.drawNode = drawNode
        self:addChild(drawNode)
        drawNode:setPosition(curPos)

        local width = EditorLayer.TouchNodeWidth
        local height = EditorLayer.TouchNodeHeight
        self.selectedInfo.touchRect = cc.rect(curPos.x - width * 0.5, curPos.y - height * 0.5, width, height)

        if self.mode == EditorLayer.OptMode.POSITION then
            local drawNodeCenter = cc.DrawNode:create()
            drawNodeCenter:drawSolidRect(cc.p(-width * 0.5, -height * 0.5), cc.p(width * 0.5, height * 0.5), cc.c4f(1, 0, 0, 0.2))
            drawNode:addChild(drawNodeCenter)
            table.insert(self.selectedInfo.drawNodeAry, drawNodeCenter)

            local length = height + 10
            local upDrawNode = cc.DrawNode:create()
            upDrawNode:drawSolidRect(cc.p(-3, 0), cc.p(3, length), cc.c4f(1, 0, 0, 0.4))
            drawNode:addChild(upDrawNode)
            table.insert(self.selectedInfo.drawNodeAry, upDrawNode)

            local upTopDrawNode = cc.DrawNode:create()
            upTopDrawNode:drawTriangle(cc.p(-10, length), cc.p(10, length), cc.p(0, length + 10), cc.c4f(1, 0, 0, 0.4))
            drawNode:addChild(upTopDrawNode)
            table.insert(self.selectedInfo.drawNodeAry, upTopDrawNode)

            local rightDrawNode = cc.DrawNode:create()
            rightDrawNode:drawSolidRect(cc.p(0, -3), cc.p(length, 3), cc.c4f(1, 0, 0, 0.4))
            drawNode:addChild(rightDrawNode)
            table.insert(self.selectedInfo.drawNodeAry, rightDrawNode)

            local rightTopDrawNode = cc.DrawNode:create()
            rightTopDrawNode:drawTriangle(cc.p(length, -10), cc.p(length, 10), cc.p(length + 10, 0), cc.c4f(1, 0, 0, 0.4))
            drawNode:addChild(rightTopDrawNode)
            table.insert(self.selectedInfo.drawNodeAry, rightTopDrawNode)

            local basePos = self.selectedInfo.pos
            self.selectedInfo.touchRectVertical = cc.rect(basePos.x - 3, basePos.y, 6, length + 10)
            self.selectedInfo.touchRectHorizontal = cc.rect(basePos.x, basePos.y - 3, length + 10, 6)
        elseif self.mode == EditorLayer.OptMode.ROTATE then
            local drawNodeMax = cc.DrawNode:create()
            drawNodeMax:drawSolidCircle(cc.p(0, 0), EditorLayer.TouchNodeMaxRadius, 0, 100, cc.c4f(1, 0, 0, 0.2))
            drawNode:addChild(drawNodeMax)
            table.insert(self.selectedInfo.drawNodeAry, drawNodeMax)

            local drawNodeMin = cc.DrawNode:create()
            drawNodeMin:drawSolidCircle(cc.p(0, 0), EditorLayer.TouchNodeMinRadius, 0, 100, cc.c4f(0, 0, 1, 0.2))
            drawNode:addChild(drawNodeMin)
            table.insert(self.selectedInfo.drawNodeAry, drawNodeMin)
        elseif self.mode == EditorLayer.OptMode.SCALE then
            local drawNodeCenter = cc.DrawNode:create()
            drawNodeCenter:drawSolidRect(cc.p(-width * 0.5, -height * 0.5), cc.p(width * 0.5, height * 0.5), cc.c4f(1, 0, 1, 0.2))
            drawNode:addChild(drawNodeCenter)
            table.insert(self.selectedInfo.drawNodeAry, drawNodeCenter)

            local length = height + 10
            local upDrawNode = cc.DrawNode:create()
            upDrawNode:drawSolidRect(cc.p(-3, 0), cc.p(3, length), cc.c4f(1, 0, 1, 0.4))
            drawNode:addChild(upDrawNode)
            table.insert(self.selectedInfo.drawNodeAry, upDrawNode)

            local upTopDrawNode = cc.DrawNode:create()
            upTopDrawNode:drawTriangle(cc.p(-10, length), cc.p(10, length), cc.p(0, length + 10), cc.c4f(1, 0, 1, 0.4))
            drawNode:addChild(upTopDrawNode)
            table.insert(self.selectedInfo.drawNodeAry, upTopDrawNode)

            local rightDrawNode = cc.DrawNode:create()
            rightDrawNode:drawSolidRect(cc.p(0, -3), cc.p(length, 3), cc.c4f(1, 0, 1, 0.4))
            drawNode:addChild(rightDrawNode)
            table.insert(self.selectedInfo.drawNodeAry, rightDrawNode)

            local rightTopDrawNode = cc.DrawNode:create()
            rightTopDrawNode:drawTriangle(cc.p(length, -10), cc.p(length, 10), cc.p(length + 10, 0), cc.c4f(1, 0, 1, 0.4))
            drawNode:addChild(rightTopDrawNode)
            table.insert(self.selectedInfo.drawNodeAry, rightTopDrawNode)

            local basePos = self.selectedInfo.pos
            self.selectedInfo.touchRectVertical = cc.rect(basePos.x - 3, basePos.y, 6, length + 10)
            self.selectedInfo.touchRectHorizontal = cc.rect(basePos.x, basePos.y - 3, length + 10, 6)
        elseif self.mode == EditorLayer.OptMode.ATTRIBUTE then
            self:showBaseAttributeNode()
        elseif self.mode == EditorLayer.OptMode.SETTING then
            self:showSettingNode()
        end

        local nodeInfoAry = self.selectedInfo.nodeInfoAry
        for _, info in ipairs(nodeInfoAry) do
            local node = info.node
            local contentSize = node:getContentSize()
            self:fixContentSize(contentSize)

            if tolua.type(node) ~= "CCLabelBMFont" then
                local drawNode = cc.DrawNode:create()
                drawNode:drawRect(cc.p(0, 0), cc.p(contentSize.width, contentSize.height), cc.c4f(1, 0, 1, 0.3))
                node:addChild(drawNode)
                info.drawNode = drawNode
            end
        end
    end
end

function EditorLayer:recalculationSelectedNodeCenter()
    if self.selectedInfo then
        local count = 0
        local center = cc.p(0, 0)
        for _, info in ipairs(self.selectedInfo.nodeInfoAry) do
            local node = info.node
            local contentSize = node:getContentSize()
            local anchorPoint = node:getAnchorPoint()
            local pos = node:convertToWorldSpace(cc.p(contentSize.width * anchorPoint.x, contentSize.height * anchorPoint.y))
            center.x = center.x + pos.x
            center.y = center.y + pos.y
            count = count + 1

            info.pos = pos
            info.angleX = node:getRotationX()
            info.angleY = node:getRotationY()
            info.scaleX = node:getScaleX()
            info.scaleY = node:getScaleY()
        end

        center.x = center.x / count
        center.y = center.y / count

        self.selectedInfo.pos = center
        self.selectedInfo.center = center
    end
end

function EditorLayer:onSelectedNode(nodeAry)
    local count = #nodeAry
    if count <= 0 then
        return
    end

    local newNodeAry = {}
    for _, selNode in ipairs(nodeAry) do
        table.insert(newNodeAry, selNode)
        local selInfo = self.nodeInfoMap[selNode]
        local selKey = selInfo.info.key
        if selInfo and selKey then
            for node, info in pairs(self.nodeInfoMap) do
                if info.info.key == selKey and node ~= selNode then
                    table.insert(newNodeAry, node)
                end
            end
        end
    end
    nodeAry = newNodeAry
    count = #nodeAry

    self.selectedInfo = {nodeInfoAry = {}}
    local center = cc.p(0, 0)
    for _, node in ipairs(nodeAry) do
        local contentSize = node:getContentSize()
        local anchorPoint = node:getAnchorPoint()
        local pos = node:convertToWorldSpace(cc.p(contentSize.width * anchorPoint.x, contentSize.height * anchorPoint.y))
        center.x = center.x + pos.x
        center.y = center.y + pos.y

        local info = {node = node, pos = pos, angleX = node:getRotationX(), angleY = node:getRotationY(), scaleX = node:getScaleX(),
        scaleY = node:getScaleY()}
        table.insert(self.selectedInfo.nodeInfoAry, info)
    end
    center.x = center.x / count
    center.y = center.y / count

    self.selectedInfo.pos = center
    self.selectedInfo.center = center
end

function EditorLayer:showBaseAttributeNode()
    if not self.selectedInfo then
        return
    end
    if #self.selectedInfo.nodeInfoAry <= 0 then
        return
    end

    local EditorAttributeNode = require("dhcomponents.layers.EditorAttributeNode")
    local node = EditorAttributeNode.new(self, self.selectedInfo)
    self:addChild(node)
    self.selectedInfo.drawNode = node
end

function EditorLayer:showSettingNode()
    if not self.selectedInfo then
        return
    end
    if #self.selectedInfo.nodeInfoAry <= 0 then
        return
    end

    local EditorAttributeNode = require("dhcomponents.layers.EditorSettingNode")
    local node = EditorAttributeNode.new(self, self.selectedInfo)
    self:addChild(node)
    self.selectedInfo.drawNode = node
end

return EditorLayer
