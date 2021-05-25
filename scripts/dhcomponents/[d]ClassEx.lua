local DrawNode = cc.DrawNode

function DrawNode:drawSolidRect(origin, destination, color, radius, fill)
    local points = {
        {origin.x, origin.y},
        {origin.x, destination.y},
        {destination.x, destination.y},
        {destination.x, origin.y},
    }
    self:drawPolygon(points, { fillColor = color, borderColor = color, borderWidth = 1 })
end

function DrawNode:drawTriangle(p1, p2, p3, color, radius)
	radius = radius or 1
    self:drawSegment(p1, p2, radius, color)
    self:drawSegment(p2, p3, radius, color)
    self:drawSegment(p3, p1, radius, color)
end

function DrawNode:drawRect(origin, destination, color)
	radius = radius or 1
    self:drawSegment(cc.p(origin.x, origin.y), cc.p(origin.x, destination.y), radius, color)
    self:drawSegment(cc.p(origin.x, destination.y), cc.p(destination.x, destination.y), radius, color)
    self:drawSegment(cc.p(destination.x, destination.y), cc.p(destination.x, origin.y), radius, color)
    self:drawSegment(cc.p(destination.x, origin.y), cc.p(origin.x, origin.y), radius, color)
end

function DrawNode:drawSolidCircle(center, radius, angle, segments, color)
	self:drawDot(center, radius, color)
end

cc.pSub = function (p1, p2)
	return cc.p(p1.x - p2.x, p1.y - p2.y)
end

cc.pAdd = function (p1, p2)
	return cc.p(p1.x + p2.x, p1.y + p2.y)
end

cc.pToAngleSelf = function (self)
	return math.atan2(self.y, self.x)
end

cc.Label = CCLabelTTF
local Label = cc.Label

Label.createWithSystemFont = function (_, text, fontName, size)
	return Label:create(text, fontName, size)
end

function Label:setTextColor(color)
	local color3b = cc.c3b(color.r, color.g, color.b)
	self:setColor(color3b)
	self:setOpacity(color.a)
end

ccui = cc

cc.EditBox = CCEditBox

local EditBox = cc.EditBox

function EditBox:setFontColor4b(color)
	if color.a then
		local color3b = cc.c3b(color.r, color.g, color.b)
		self:setColor(color3b)
		self:setOpacity(color.a)
	else
		self:setFontColor(color)
	end
end

function EditBox:setPlaceholderFontColor4b(color)
	if color.a then
		local color3b = cc.c3b(color.r, color.g, color.b)
		self:setColor(color3b)
		self:setOpacity(color.a)
	else
		self:setPlaceholderFontColor(color)
	end
end