local UIButton = require("dhcomponents.ui.UIButton")

local EditorAttributeNode = require("dhcomponents.layers.EditorAttributeNode")
local EditorSettingNode = class("EditorSettingNode", EditorAttributeNode)

function EditorSettingNode:ctor(parent, selectedInfo)
	EditorSettingNode.super.ctor(self, parent, selectedInfo)
end

function EditorSettingNode:initUI()
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

	--posX
    local posXNameLabel = cc.Label:createWithSystemFont("positionX", "", 14)
    posXNameLabel:setAnchorPoint(cc.p(0, 0.5))
    posXNameLabel:setPosition(10, height - 20)
    posXNameLabel:setTextColor(cc.c4b(0, 0, 0, 255))
    container:addChild(posXNameLabel)

	local posXJustifyLeftBtnDrawNode = cc.DrawNode:create()
    posXJustifyLeftBtnDrawNode:drawSolidRect(cc.p(0, 0), cc.p(20, 20), cc.c4f(0.3, 0.7, 0.8, 1))    
    posXJustifyLeftBtnDrawNode:setContentSize(cc.size(20, 20))

    local posXJustifyLeftBtn = UIButton.new({normal = posXJustifyLeftBtnDrawNode}, function ( ... )
        for _, info in ipairs(nodeInfoAry) do
            local node = info.node
            node:setPositionX(0)
            self:syncNodeState(node)
        end
        self:syncTextState()
        self:fixBaseAttributeNodePos()
    end)
    posXJustifyLeftBtn:setPosition(100, height - 20)
    container:addChild(posXJustifyLeftBtn)

    local posXJustifyMidBtnDrawNode = cc.DrawNode:create()
    posXJustifyMidBtnDrawNode:drawSolidRect(cc.p(0, 0), cc.p(20, 20), cc.c4f(0.3, 0.7, 0.8, 1))    
    posXJustifyMidBtnDrawNode:setContentSize(cc.size(20, 20))

    local posXJustifyMidBtn = UIButton.new({normal = posXJustifyMidBtnDrawNode}, function ( ... )
        for _, info in ipairs(nodeInfoAry) do
            local node = info.node
            local parent = node:getParent()
            node:setPositionX(parent:getContentSize().width * 0.5)
            self:syncNodeState(node)
        end
        self:syncTextState()
        self:fixBaseAttributeNodePos()
    end)
    posXJustifyMidBtn:setPosition(150, height - 20)
    container:addChild(posXJustifyMidBtn)

	local posXJustifyRightBtnDrawNode = cc.DrawNode:create()
    posXJustifyRightBtnDrawNode:drawSolidRect(cc.p(0, 0), cc.p(20, 20), cc.c4f(0.3, 0.7, 0.8, 1))    
    posXJustifyRightBtnDrawNode:setContentSize(cc.size(20, 20))

    local posXJustifyRightBtn = UIButton.new({normal = posXJustifyRightBtnDrawNode}, function ( ... )
        for _, info in ipairs(nodeInfoAry) do
            local node = info.node
            local parent = node:getParent()
            node:setPositionX(parent:getContentSize().width)
            self:syncNodeState(node)
        end
        self:syncTextState()
        self:fixBaseAttributeNodePos()
    end)
    posXJustifyRightBtn:setPosition(200, height - 20)
    container:addChild(posXJustifyRightBtn)

	--posY
	local posYNameLabel = cc.Label:createWithSystemFont("positionY", "", 14)
    posYNameLabel:setAnchorPoint(cc.p(0, 0.5))
    posYNameLabel:setPosition(10, height - 60)
    posYNameLabel:setTextColor(cc.c4b(0, 0, 0, 255))
    container:addChild(posYNameLabel)

	local posYJustifyLeftBtnDrawNode = cc.DrawNode:create()
    posYJustifyLeftBtnDrawNode:drawSolidRect(cc.p(0, 0), cc.p(20, 20), cc.c4f(0.3, 0.7, 0.8, 1))    
    posYJustifyLeftBtnDrawNode:setContentSize(cc.size(20, 20))

    local posYJustifyLeftBtn = UIButton.new({normal = posYJustifyLeftBtnDrawNode}, function ( ... )
        for _, info in ipairs(nodeInfoAry) do
            local node = info.node
            node:setPositionY(0)
            self:syncNodeState(node)
        end
        self:syncTextState()
        self:fixBaseAttributeNodePos()
    end)
    posYJustifyLeftBtn:setPosition(100, height - 60)
    container:addChild(posYJustifyLeftBtn)

    local posYJustifyMidBtnDrawNode = cc.DrawNode:create()
    posYJustifyMidBtnDrawNode:drawSolidRect(cc.p(0, 0), cc.p(20, 20), cc.c4f(0.3, 0.7, 0.8, 1))    
    posYJustifyMidBtnDrawNode:setContentSize(cc.size(20, 20))

    local posYJustifyMidBtn = UIButton.new({normal = posYJustifyMidBtnDrawNode}, function ( ... )
        for _, info in ipairs(nodeInfoAry) do
            local node = info.node
            local parent = node:getParent()
            node:setPositionY(parent:getContentSize().height * 0.5)
            self:syncNodeState(node)
        end
        self:syncTextState()
        self:fixBaseAttributeNodePos()
    end)
    posYJustifyMidBtn:setPosition(150, height - 60)
    container:addChild(posYJustifyMidBtn)

	local posYJustifyRightBtnDrawNode = cc.DrawNode:create()
    posYJustifyRightBtnDrawNode:drawSolidRect(cc.p(0, 0), cc.p(20, 20), cc.c4f(0.3, 0.7, 0.8, 1))    
    posYJustifyRightBtnDrawNode:setContentSize(cc.size(20, 20))

    local posYJustifyRightBtn = UIButton.new({normal = posYJustifyRightBtnDrawNode}, function ( ... )
        for _, info in ipairs(nodeInfoAry) do
            local node = info.node
            local parent = node:getParent()
            node:setPositionY(parent:getContentSize().height)
            self:syncNodeState(node)
        end
        self:syncTextState()
        self:fixBaseAttributeNodePos()
    end)
    posYJustifyRightBtn:setPosition(200, height - 60)
    container:addChild(posYJustifyRightBtn)
end

return EditorSettingNode