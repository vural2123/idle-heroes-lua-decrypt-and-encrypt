local UIButton = require("dhcomponents.ui.UIButton")

local EditorAttributeNode = class("EditorAttributeNode", function()
    return cc.Node:create()
end)

function EditorAttributeNode:ctor(parent, selectedInfo)
	self.parent = parent
	self.selectedInfo = selectedInfo
    self.lastUserOffsetPos = cc.p(0, 0)

    self:initTouch()

	self:initUI()
end

function EditorAttributeNode:initTouch()
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

function EditorAttributeNode:onTouchBegan(touch, event)
    local rect = self:getBoundingBox()
    if cc.rectContainsPoint(rect, touch:getLocation()) then
        return true
    end
    return false
end

function EditorAttributeNode:onTouchMoved(touch, event)
    self.userOffsetPos = cc.pAdd(self.lastUserOffsetPos, cc.pSub(touch:getLocation(), touch:getStartLocation()))
    self:fixBaseAttributeNodePos(true)
end

function EditorAttributeNode:onTouchEnded(touch, event)
    self.lastUserOffsetPos = self.userOffsetPos
end

function EditorAttributeNode:initUI()
    local width = 290
    local height = 200

    local container = self
    container:setContentSize(cc.size(width, height))

    local nodeInfoAry = self.selectedInfo.nodeInfoAry
    local specifyNode
    if #self.selectedInfo.nodeInfoAry == 1 then
        specifyNode = nodeInfoAry[1].node
    end

    self:fixBaseAttributeNodePos(true)

    local drawNodeBg = cc.DrawNode:create()
    drawNodeBg:drawSolidRect(cc.p(-width * 0.5, -height * 0.5), cc.p(width * 0.5, height * 0.5), cc.c4f(0.7, 0.7, 0.7, 0.99))
    drawNodeBg:setPosition(width * 0.5, height * 0.5)
    container:addChild(drawNodeBg)

    --pos
    local posNameLabel = cc.Label:createWithSystemFont("position", "", 14)
    posNameLabel:setAnchorPoint(cc.p(0, 0.5))
    posNameLabel:setPosition(10, height - 20)
    posNameLabel:setTextColor(cc.c4b(0, 0, 0, 255))
    container:addChild(posNameLabel)

    local posXLabel = cc.Label:createWithSystemFont("x", "", 14)
    posXLabel:setPosition(80, height - 20)
    posXLabel:setTextColor(cc.c4b(0, 0, 0, 255))
    container:addChild(posXLabel)

    local posEditSize = cc.size(70, 20)
    local posXEditDrawNode = cc.DrawNode:create()
    posXEditDrawNode:drawSolidRect(cc.p(0, 0), cc.p(posEditSize.width, posEditSize.height), cc.c4f(0.7, 0.7, 0.0, 0.99))

    local posXNormalSprite = ccui.Scale9Sprite:create()
    posXNormalSprite:addChild(posXEditDrawNode)

    local posXEditbox = ccui.EditBox:create(posEditSize, posXNormalSprite)
    posXEditbox:setAnchorPoint(cc.p(0, 0.5))
    posXEditbox:setPosition(95, height - 20)
    posXEditbox:setFontColor4b(cc.c4b(0, 0, 0, 255))
    posXEditbox:setPlaceholderFontColor4b(cc.c4b(0, 0, 0, 230))
    container:addChild(posXEditbox)

    local posYLabel = cc.Label:createWithSystemFont("y", "", 14)
    posYLabel:setPosition(180, height - 20)
    posYLabel:setTextColor(cc.c4b(0, 0, 0, 255))
    container:addChild(posYLabel)

    local posYEditDrawNode = cc.DrawNode:create()
    posYEditDrawNode:drawSolidRect(cc.p(0, 0), cc.p(posEditSize.width, posEditSize.height), cc.c4f(0.7, 0.7, 0.0, 0.99))

    local posYNormalSprite = ccui.Scale9Sprite:create()
    posYNormalSprite:addChild(posYEditDrawNode)

    local posYEditbox = ccui.EditBox:create(posEditSize, posYNormalSprite)
    posYEditbox:setAnchorPoint(cc.p(0, 0.5))
    posYEditbox:setPosition(195, height - 20)
    posYEditbox:setFontColor4b(cc.c4b(0, 0, 0, 255))
    posYEditbox:setPlaceholderFontColor4b(cc.c4b(0, 0, 0, 230))
    container:addChild(posYEditbox)

    --rotation
    local rotationNameLabel = cc.Label:createWithSystemFont("rotation", "", 14)
    rotationNameLabel:setAnchorPoint(cc.p(0, 0.5))
    rotationNameLabel:setPosition(10, height - 50)
    rotationNameLabel:setTextColor(cc.c4b(0, 0, 0, 255))
    container:addChild(rotationNameLabel)

    local rotationXLabel = cc.Label:createWithSystemFont("x", "", 14)
    rotationXLabel:setPosition(80, height - 50)
    rotationXLabel:setTextColor(cc.c4b(0, 0, 0, 255))
    container:addChild(rotationXLabel)

    local rotationEditSize = cc.size(60, 20)
    local rotationXEditDrawNode = cc.DrawNode:create()
    rotationXEditDrawNode:drawSolidRect(cc.p(0, 0), cc.p(rotationEditSize.width, rotationEditSize.height), cc.c4f(0.7, 0.7, 0.0, 0.99))

    local rotationXNormalSprite = ccui.Scale9Sprite:create()
    rotationXNormalSprite:addChild(rotationXEditDrawNode)

    local rotationXEditbox = ccui.EditBox:create(rotationEditSize, rotationXNormalSprite)
    rotationXEditbox:setAnchorPoint(cc.p(0, 0.5))
    rotationXEditbox:setPosition(95, height - 50)
    rotationXEditbox:setFontColor4b(cc.c4b(0, 0, 0, 255))
    rotationXEditbox:setPlaceholderFontColor4b(cc.c4b(0, 0, 0, 230))
    container:addChild(rotationXEditbox)

    local rotationYLabel = cc.Label:createWithSystemFont("y", "", 14)
    rotationYLabel:setPosition(170, height - 50)
    rotationYLabel:setTextColor(cc.c4b(0, 0, 0, 255))
    container:addChild(rotationYLabel)

    local rotationYEditDrawNode = cc.DrawNode:create()
    rotationYEditDrawNode:drawSolidRect(cc.p(0, 0), cc.p(rotationEditSize.width, rotationEditSize.height), cc.c4f(0.7, 0.7, 0.0, 0.99))

    local rotationYNormalSprite = ccui.Scale9Sprite:create()
    rotationYNormalSprite:addChild(rotationYEditDrawNode)

    local rotationYEditbox = ccui.EditBox:create(rotationEditSize, rotationYNormalSprite)
    rotationYEditbox:setAnchorPoint(cc.p(0, 0.5))
    rotationYEditbox:setPosition(185, height - 50)
    rotationYEditbox:setFontColor4b(cc.c4b(0, 0, 0, 255))
    rotationYEditbox:setPlaceholderFontColor4b(cc.c4b(0, 0, 0, 230))
    container:addChild(rotationYEditbox)

    local rotationBtnDrawNode = cc.DrawNode:create()
    rotationBtnDrawNode:drawSolidRect(cc.p(0, 0), cc.p(20, 20), cc.c4f(0.3, 0.7, 0.8, 1))    
    rotationBtnDrawNode:setContentSize(cc.size(20, 20))

    local rotationSameBtn = UIButton.new({normal = rotationBtnDrawNode}, function ( ... )
        -- body
        print("todo")
    end)
    rotationSameBtn:setPosition(270, height - 50)
    container:addChild(rotationSameBtn)

    --scale
    local scaleNameLabel = cc.Label:createWithSystemFont("scale", "", 14)
    scaleNameLabel:setAnchorPoint(cc.p(0, 0.5))
    scaleNameLabel:setPosition(10, height - 80)
    scaleNameLabel:setTextColor(cc.c4b(0, 0, 0, 255))
    container:addChild(scaleNameLabel)

    local scaleXLabel = cc.Label:createWithSystemFont("x", "", 14)
    scaleXLabel:setPosition(80, height - 80)
    scaleXLabel:setTextColor(cc.c4b(0, 0, 0, 255))
    container:addChild(scaleXLabel)

    local scaleEditSize = cc.size(60, 20)
    local scaleXEditDrawNode = cc.DrawNode:create()
    scaleXEditDrawNode:drawSolidRect(cc.p(0, 0), cc.p(scaleEditSize.width, scaleEditSize.height), cc.c4f(0.7, 0.7, 0.0, 0.99))

    local scaleXNormalSprite = ccui.Scale9Sprite:create()
    scaleXNormalSprite:addChild(scaleXEditDrawNode)

    local scaleXEditbox = ccui.EditBox:create(scaleEditSize, scaleXNormalSprite)
    scaleXEditbox:setAnchorPoint(cc.p(0, 0.5))
    scaleXEditbox:setPosition(95, height - 80)
    scaleXEditbox:setFontColor4b(cc.c4b(0, 0, 0, 255))
    scaleXEditbox:setPlaceholderFontColor4b(cc.c4b(0, 0, 0, 230))
    container:addChild(scaleXEditbox)

    local scaleYLabel = cc.Label:createWithSystemFont("y", "", 14)
    scaleYLabel:setPosition(170, height - 80)
    scaleYLabel:setTextColor(cc.c4b(0, 0, 0, 255))
    container:addChild(scaleYLabel)

    local scaleYEditDrawNode = cc.DrawNode:create()
    scaleYEditDrawNode:drawSolidRect(cc.p(0, 0), cc.p(scaleEditSize.width, scaleEditSize.height), cc.c4f(0.7, 0.7, 0.0, 0.99))

    local scaleYNormalSprite = ccui.Scale9Sprite:create()
    scaleYNormalSprite:addChild(scaleYEditDrawNode)

    local scaleYEditbox = ccui.EditBox:create(scaleEditSize, scaleYNormalSprite)
    scaleYEditbox:setAnchorPoint(cc.p(0, 0.5))
    scaleYEditbox:setPosition(185, height - 80)
    scaleYEditbox:setFontColor4b(cc.c4b(0, 0, 0, 255))
    scaleYEditbox:setPlaceholderFontColor4b(cc.c4b(0, 0, 0, 230))
    container:addChild(scaleYEditbox)

    --anchorPoint
    local anchorNameLabel = cc.Label:createWithSystemFont("anchor", "", 14)
    anchorNameLabel:setAnchorPoint(cc.p(0, 0.5))
    anchorNameLabel:setPosition(10, height - 110)
    anchorNameLabel:setTextColor(cc.c4b(0, 0, 0, 255))
    container:addChild(anchorNameLabel)

    local anchorXLabel = cc.Label:createWithSystemFont("x", "", 14)
    anchorXLabel:setPosition(80, height - 110)
    anchorXLabel:setTextColor(cc.c4b(0, 0, 0, 255))
    container:addChild(anchorXLabel)

    local anchorEditSize = cc.size(60, 20)
    local anchorXEditDrawNode = cc.DrawNode:create()
    anchorXEditDrawNode:drawSolidRect(cc.p(0, 0), cc.p(anchorEditSize.width, anchorEditSize.height), cc.c4f(0.7, 0.7, 0.0, 0.99))

    local anchorXNormalSprite = ccui.Scale9Sprite:create()
    anchorXNormalSprite:addChild(anchorXEditDrawNode)

    local anchorXEditbox = ccui.EditBox:create(anchorEditSize, anchorXNormalSprite)
    anchorXEditbox:setAnchorPoint(cc.p(0, 0.5))
    anchorXEditbox:setPosition(95, height - 110)
    anchorXEditbox:setFontColor4b(cc.c4b(0, 0, 0, 255))
    anchorXEditbox:setPlaceholderFontColor4b(cc.c4b(0, 0, 0, 230))
    container:addChild(anchorXEditbox)

    local anchorYLabel = cc.Label:createWithSystemFont("y", "", 14)
    anchorYLabel:setPosition(170, height - 110)
    anchorYLabel:setTextColor(cc.c4b(0, 0, 0, 255))
    container:addChild(anchorYLabel)

    local anchorYEditDrawNode = cc.DrawNode:create()
    anchorYEditDrawNode:drawSolidRect(cc.p(0, 0), cc.p(anchorEditSize.width, anchorEditSize.height), cc.c4f(0.7, 0.7, 0.0, 0.99))

    local anchorYNormalSprite = ccui.Scale9Sprite:create()
    anchorYNormalSprite:addChild(anchorYEditDrawNode)

    local anchorYEditbox = ccui.EditBox:create(anchorEditSize, anchorYNormalSprite)
    anchorYEditbox:setAnchorPoint(cc.p(0, 0.5))
    anchorYEditbox:setPosition(185, height - 110)
    anchorYEditbox:setFontColor4b(cc.c4b(0, 0, 0, 255))
    anchorYEditbox:setPlaceholderFontColor4b(cc.c4b(0, 0, 0, 230))
    container:addChild(anchorYEditbox)

    --color
    local colorNameLabel = cc.Label:createWithSystemFont("color", "", 14)
    colorNameLabel:setAnchorPoint(cc.p(0, 0.5))
    colorNameLabel:setPosition(10, height - 140)
    colorNameLabel:setTextColor(cc.c4b(0, 0, 0, 255))
    container:addChild(colorNameLabel)

    local colorRLabel = cc.Label:createWithSystemFont("r", "", 14)
    colorRLabel:setPosition(80, height - 140)
    colorRLabel:setTextColor(cc.c4b(0, 0, 0, 255))
    container:addChild(colorRLabel)

    local colorEditSize = cc.size(40, 20)
    local colorREditDrawNode = cc.DrawNode:create()
    colorREditDrawNode:drawSolidRect(cc.p(0, 0), cc.p(colorEditSize.width, colorEditSize.height), cc.c4f(0.7, 0.7, 0.0, 0.99))

    local colorRNormalSprite = ccui.Scale9Sprite:create()
    colorRNormalSprite:addChild(colorREditDrawNode)

    local colorREditbox = ccui.EditBox:create(colorEditSize, colorRNormalSprite)
    colorREditbox:setAnchorPoint(cc.p(0, 0.5))
    colorREditbox:setPosition(90, height - 140)
    colorREditbox:setFontColor4b(cc.c4b(0, 0, 0, 255))
    colorREditbox:setPlaceholderFontColor4b(cc.c4b(0, 0, 0, 230))
    container:addChild(colorREditbox)

    local colorGLabel = cc.Label:createWithSystemFont("g", "", 14)
    colorGLabel:setPosition(150, height - 140)
    colorGLabel:setTextColor(cc.c4b(0, 0, 0, 255))
    container:addChild(colorGLabel)

    local colorGEditDrawNode = cc.DrawNode:create()
    colorGEditDrawNode:drawSolidRect(cc.p(0, 0), cc.p(colorEditSize.width, colorEditSize.height), cc.c4f(0.7, 0.7, 0.0, 0.99))

    local colorGNormalSprite = ccui.Scale9Sprite:create()
    colorGNormalSprite:addChild(colorGEditDrawNode)

    local colorGEditbox = ccui.EditBox:create(colorEditSize, colorGNormalSprite)
    colorGEditbox:setAnchorPoint(cc.p(0, 0.5))
    colorGEditbox:setPosition(160, height - 140)
    colorGEditbox:setFontColor4b(cc.c4b(0, 0, 0, 255))
    colorGEditbox:setPlaceholderFontColor4b(cc.c4b(0, 0, 0, 230))
    container:addChild(colorGEditbox)

    local colorBLabel = cc.Label:createWithSystemFont("b", "", 14)
    colorBLabel:setPosition(220, height - 140)
    colorBLabel:setTextColor(cc.c4b(0, 0, 0, 255))
    container:addChild(colorBLabel)

    local colorBEditDrawNode = cc.DrawNode:create()
    colorBEditDrawNode:drawSolidRect(cc.p(0, 0), cc.p(colorEditSize.width, colorEditSize.height), cc.c4f(0.7, 0.7, 0.0, 0.99))

    local colorBNormalSprite = ccui.Scale9Sprite:create()
    colorBNormalSprite:addChild(colorBEditDrawNode)

    local colorBEditbox = ccui.EditBox:create(colorEditSize, colorBNormalSprite)
    colorBEditbox:setAnchorPoint(cc.p(0, 0.5))
    colorBEditbox:setPosition(230, height - 140)
    colorBEditbox:setFontColor4b(cc.c4b(0, 0, 0, 255))
    colorBEditbox:setPlaceholderFontColor4b(cc.c4b(0, 0, 0, 230))
    container:addChild(colorBEditbox)

    local colorALabel = cc.Label:createWithSystemFont("a", "", 14)
    colorALabel:setPosition(80, height - 170)
    colorALabel:setTextColor(cc.c4b(0, 0, 0, 255))
    container:addChild(colorALabel)

    local colorAEditDrawNode = cc.DrawNode:create()
    colorAEditDrawNode:drawSolidRect(cc.p(0, 0), cc.p(colorEditSize.width, colorEditSize.height), cc.c4f(0.7, 0.7, 0.0, 0.99))

    local colorANormalSprite = ccui.Scale9Sprite:create()
    colorANormalSprite:addChild(colorAEditDrawNode)

    local colorAEditbox = ccui.EditBox:create(colorEditSize, colorANormalSprite)
    colorAEditbox:setAnchorPoint(cc.p(0, 0.5))
    colorAEditbox:setPosition(90, height - 170)
    colorAEditbox:setFontColor4b(cc.c4b(0, 0, 0, 255))
    colorAEditbox:setPlaceholderFontColor4b(cc.c4b(0, 0, 0, 230))
    container:addChild(colorAEditbox)

    --setting
    if specifyNode then
        posXEditbox:setPlaceHolder(string.format("%.2f", specifyNode:getPositionX()))
        posYEditbox:setPlaceHolder(string.format("%.2f", specifyNode:getPositionY()))

        rotationXEditbox:setPlaceHolder(string.format("%.2f", specifyNode:getRotationX()))
        rotationYEditbox:setPlaceHolder(string.format("%.2f", specifyNode:getRotationY()))

        scaleXEditbox:setPlaceHolder(string.format("%.2f", specifyNode:getScaleX()))
        scaleYEditbox:setPlaceHolder(string.format("%.2f", specifyNode:getScaleY()))

        anchorXEditbox:setPlaceHolder(string.format("%.2f", specifyNode:getAnchorPoint().x))
        anchorYEditbox:setPlaceHolder(string.format("%.2f", specifyNode:getAnchorPoint().y))

        local color = specifyNode:getColor()
        colorREditbox:setPlaceHolder(string.format("%d", color.r))
        colorGEditbox:setPlaceHolder(string.format("%d", color.g))
        colorBEditbox:setPlaceHolder(string.format("%d", color.b))
        colorAEditbox:setPlaceHolder(string.format("%d", specifyNode:getOpacity()))
    end

    posXEditbox:registerScriptEditBoxHandler(function (eType)
        local changeFlag = false
        local returnFlag = eType == "ended"
        local text = posXEditbox:getText()
        if returnFlag or string.sub(text, string.len(text), string.len(text)) == '\n' then
            changeFlag = true
        end

        if changeFlag then
            local value = tonumber(text)
            if value then
                local winSize = cc.Director:sharedDirector():getWinSize()
                if value < -10 then
                    value = -10
                elseif value > winSize.width + 10 then
                    value = winSize.width + 10
                end

                for _, info in ipairs(nodeInfoAry) do
                    local node = info.node
                    node:setPositionX(value)
                    self:syncNodeState(node)
                end
                self:syncTextState()
                self:fixBaseAttributeNodePos()
            end
            if returnFlag then
                if specifyNode then
                    posXEditbox:setText(string.format("%.2f", specifyNode:getPositionX()))
                end
            end
        end
    end)

    posYEditbox:registerScriptEditBoxHandler(function (eType)
        local changeFlag = false
        local returnFlag = eType == "return"
        local text = posYEditbox:getText()
        if returnFlag or string.sub(text, string.len(text), string.len(text)) == '\n' then
            changeFlag = true
        end

        if changeFlag then
            local value = tonumber(text)
            if value then
                local winSize = cc.Director:sharedDirector():getWinSize()
                if value < -10 then
                    value = -10
                elseif value > winSize.height + 10 then
                    value = winSize.height + 10
                end

                for _, info in ipairs(nodeInfoAry) do
                    local node = info.node
                    node:setPositionY(value)
                    self:syncNodeState(node)
                end
                self:syncTextState()
                self:fixBaseAttributeNodePos()
            end
            if returnFlag then
                if specifyNode then
                    posYEditbox:setText(string.format("%.2f", specifyNode:getPositionY()))
                end
            end
        end
    end)

    rotationXEditbox:registerScriptEditBoxHandler(function (eType)
        local changeFlag = false
        local text = rotationXEditbox:getText()
        local returnFlag = eType == "return"
        if returnFlag or string.sub(text, string.len(text), string.len(text)) == '\n' then
            changeFlag = true
        end

        if changeFlag then
            local value = tonumber(text)
            if value then
                for _, info in ipairs(nodeInfoAry) do
                    local node = info.node
                    node:setRotationX(value)
                    self:syncNodeState(node)
                end
                self:syncTextState()
                self:fixBaseAttributeNodePos()
            end
            if returnFlag then
                if specifyNode then
                    rotationXEditbox:setText(string.format("%.2f", specifyNode:getRotationX()))
                end
            end
        end
    end)

    rotationYEditbox:registerScriptEditBoxHandler(function (eType)
        local changeFlag = false
        local returnFlag = eType == "return"
        local text = rotationYEditbox:getText()
        if returnFlag or string.sub(text, string.len(text), string.len(text)) == '\n' then
            changeFlag = true
        end

        if changeFlag then
            local value = tonumber(text)
            if value then
                for _, info in ipairs(nodeInfoAry) do
                    local node = info.node
                    node:setRotationY(value)
                    self:syncNodeState(node)
                end
                self:syncTextState()
                self:fixBaseAttributeNodePos()
            end
            if returnFlag then
                if specifyNode then
                    rotationYEditbox:setText(string.format("%.2f", specifyNode:getRotationY()))
                end
            end
        end
    end)

    scaleXEditbox:registerScriptEditBoxHandler(function (eType)
        local changeFlag = false
        local returnFlag = eType == "return"
        local text = scaleXEditbox:getText()
        if returnFlag or string.sub(text, string.len(text), string.len(text)) == '\n' then
            changeFlag = true
        end

        if changeFlag then
            local value = tonumber(text)
            if value then
                for _, info in ipairs(nodeInfoAry) do
                    local node = info.node
                    node:setScaleX(value)
                    self:syncNodeState(node)
                end
                self:syncTextState()
                self:fixBaseAttributeNodePos()
            end
            if returnFlag then
                if specifyNode then
                    scaleXEditbox:setText(string.format("%.2f", specifyNode:getScaleX()))
                end
            end
        end
    end)

    scaleYEditbox:registerScriptEditBoxHandler(function (eType)
        local changeFlag = false
        local returnFlag = eType == "return"
        local text = scaleYEditbox:getText()
        if returnFlag or string.sub(text, string.len(text), string.len(text)) == '\n' then
            changeFlag = true
        end

        if changeFlag then
            local value = tonumber(text)
            if value then
                for _, info in ipairs(nodeInfoAry) do
                    local node = info.node
                    node:setScaleY(value)
                    self:syncNodeState(node)
                end
                self:syncTextState()
                self:fixBaseAttributeNodePos()
            end
            if returnFlag then
                if specifyNode then
                    scaleYEditbox:setText(string.format("%.2f", specifyNode:getScaleY()))
                end
            end
        end
    end)

    anchorXEditbox:registerScriptEditBoxHandler(function (eType)
        local changeFlag = false
        local returnFlag = eType == "return"
        local text = anchorXEditbox:getText()
        if returnFlag or string.sub(text, string.len(text), string.len(text)) == '\n' then
            changeFlag = true
        end

        if changeFlag then
            local value = tonumber(text)
            if value then
                for _, info in ipairs(nodeInfoAry) do
                    local node = info.node
                    node:setAnchorPoint(cc.p(value, info.node:getAnchorPoint().y))
                    self:syncNodeState(node)
                end
                self:syncTextState()
                self:fixBaseAttributeNodePos()
            end
            if returnFlag then
                if specifyNode then
                    anchorXEditbox:setText(string.format("%.2f", specifyNode:getAnchorPoint().x))
                end
            end
        end
    end)

    anchorYEditbox:registerScriptEditBoxHandler(function (eType)
        local changeFlag = false
        local returnFlag = eType == "return"
        local text = anchorYEditbox:getText()
        if returnFlag or string.sub(text, string.len(text), string.len(text)) == '\n' then
            changeFlag = true
        end

        if changeFlag then
            local value = tonumber(text)
            if value then
                for _, info in ipairs(nodeInfoAry) do
                    local node = info.node
                    node:setAnchorPoint(cc.p(info.node:getAnchorPoint().x, value))
                    self:syncNodeState(node)
                end
                self:syncTextState()
                self:fixBaseAttributeNodePos()
            end
            if returnFlag then
                if specifyNode then
                    anchorYEditbox:setText(string.format("%.2f", specifyNode:getAnchorPoint().y))
                end
            end
        end
    end)

    colorREditbox:registerScriptEditBoxHandler(function (eType)
        local changeFlag = false
        local returnFlag = eType == "return"
        local text = colorREditbox:getText()
        if returnFlag or string.sub(text, string.len(text), string.len(text)) == '\n' then
            changeFlag = true
        end

        if changeFlag then
            local value = tonumber(text)
            if value then
                value = math.max(math.min(value, 255), 0)
                for _, info in ipairs(nodeInfoAry) do
                    local node = info.node
                    local color = node:getColor()
                    node:setColor(cc.c3b(value, color.g, color.b))
                    self:syncNodeState(node)
                end
                self:syncTextState()
            end
            if returnFlag then
                if specifyNode then
                    local color = specifyNode:getColor()
                    colorREditbox:setPlaceHolder(string.format("%d", color.r))
                end
            end
        end
    end)

    colorGEditbox:registerScriptEditBoxHandler(function (eType)
        local changeFlag = false
        local returnFlag = eType == "return"
        local text = colorGEditbox:getText()
        if returnFlag or string.sub(text, string.len(text), string.len(text)) == '\n' then
            changeFlag = true
        end

        if changeFlag then
            local value = tonumber(text)
            if value then
                value = math.max(math.min(value, 255), 0)
                for _, info in ipairs(nodeInfoAry) do
                    local node = info.node
                    local color = node:getColor()
                    node:setColor(cc.c3b(color.r, value, color.b))
                    self:syncNodeState(node)
                end
                self:syncTextState()
            end
            if returnFlag then
                if specifyNode then
                    local color = specifyNode:getColor()
                    colorGEditbox:setPlaceHolder(string.format("%d", color.g))
                end
            end
        end
    end)

    colorBEditbox:registerScriptEditBoxHandler(function (eType)
        local changeFlag = false
        local returnFlag = eType == "return"
        local text = colorBEditbox:getText()
        if returnFlag or string.sub(text, string.len(text), string.len(text)) == '\n' then
            changeFlag = true
        end

        if changeFlag then
            local value = tonumber(text)
            if value then
                value = math.max(math.min(value, 255), 0)
                for _, info in ipairs(nodeInfoAry) do
                    local node = info.node
                    local color = node:getColor()
                    node:setColor(cc.c3b(color.r, color.g, value))
                    self:syncNodeState(node)
                end
                self:syncTextState()
            end
            if returnFlag then
                if specifyNode then
                    local color = specifyNode:getColor()
                    colorBEditbox:setPlaceHolder(string.format("%d", color.b))
                end
            end
        end
    end)

    colorAEditbox:registerScriptEditBoxHandler(function (eType)
        local changeFlag = false
        local returnFlag = eType == "return"
        local text = colorAEditbox:getText()
        if returnFlag or string.sub(text, string.len(text), string.len(text)) == '\n' then
            changeFlag = true
        end

        if changeFlag then
            local value = tonumber(text)
            if value then
                value = math.max(math.min(value, 255), 0)
                for _, info in ipairs(nodeInfoAry) do
                    local node = info.node
                    node:setOpacity(value)
                    self:syncNodeState(node)
                end
                self:syncTextState()
            end
            if returnFlag then
                if specifyNode then
                    colorAEditbox:setPlaceHolder(string.format("%d", specifyNode:getOpacity()))
                end
            end
        end
    end)
end

function EditorAttributeNode:syncNodeState(node)
	self.parent:syncNodeState(node)
end

function EditorAttributeNode:syncTextState()
	self.parent:syncTextState()
end

function EditorAttributeNode:fixBaseAttributeNodePos(hold)
    if not hold then
        self:runAction(cc.Sequence:create(cc.DelayTime:create(0.3), cc.CallFunc:create(function ( ... )
            self.parent:showSelectedNode()
        end)))
        return
    end

    local container = self
    local width = container:getContentSize().width
    local height = container:getContentSize().height

    local nodeInfoAry = self.selectedInfo.nodeInfoAry
    local specifyNode
    if #self.selectedInfo.nodeInfoAry == 1 then
        specifyNode = nodeInfoAry[1].node

        local contentSize = specifyNode:getContentSize()
        local pos1 = specifyNode:convertToWorldSpace(cc.p(0, 0))
        local pos2 = specifyNode:convertToWorldSpace(cc.p(contentSize.width, 0))
        local pos3 = specifyNode:convertToWorldSpace(cc.p(0, contentSize.height))
        local pos4 = specifyNode:convertToWorldSpace(cc.p(contentSize.width, contentSize.height))
        local minX = math.min(math.min(math.min(pos1.x, pos2.x), pos3.x), pos4.x)
        local minY = math.min(math.min(math.min(pos1.y, pos2.y), pos3.y), pos4.y)
        local maxX = math.max(math.max(math.max(pos1.x, pos2.x), pos3.x), pos4.x)
        local maxY = math.max(math.max(math.max(pos1.y, pos2.y), pos3.y), pos4.y)

        local winSize = cc.Director:sharedDirector():getWinSize()
        local valueRight = winSize.width - maxX - width
        local valueLeft = minX - width
        local midY = (minY + maxY - height) * 0.5
        if valueRight >= 0 and midY >= 0 and midY + height <= winSize.height then
            container:setPosition(maxX + 2, midY)
        elseif valueLeft >= 0 and midY >= 0 and midY + height <= winSize.height then
            container:setPosition(minX - width - 2, midY)
        else
            local valueUp = winSize.height - maxY - height
            local valueDown = minY - height
            local midX = (minX + maxX - width) * 0.5
            if valueUp >= 0 and midX >= 0 and  midX + width <= winSize.width then
                container:setPosition((minX + maxX - width) * 0.5, maxY + 2)
            elseif valueDown >= 0 and midX >= 0 and  midX + width <= winSize.width then
                container:setPosition((minX + maxX - width) * 0.5, minY - height - 2)
            else
                if minX - width >= 0 and minX - width <= winSize.width and minY - height >= 0 and minY - height <= winSize.height then
                    container:setPosition(minX - width, minY - height)
                elseif maxX >= 0 and maxX <= winSize.width and minY - height >= 0 and minY - height <= winSize.height then
                    container:setPosition(maxX, minY - height)
                elseif maxX >= 0 and maxX + width <= winSize.width and maxY >= 0 and maxY + height <= winSize.height then
                    container:setPosition(maxX, maxY)
                elseif minX - width >= 0 and minX - width <= winSize.width and maxY >= 0 and maxY <= winSize.height then
                    container:setPosition(minX - width, maxY)
                else
                    container:setPosition(150, 100) 
                end
            end
        end
    else
        container:setPosition(self.selectedInfo.center)
    end

    if self.userOffsetPos then
        local pos = cc.p(self:getPosition())
        self:setPosition(cc.pAdd(pos, self.userOffsetPos))
    end
end

return EditorAttributeNode
