local UICreate = {}

--创建一个多元素node
--subNodeList = {{node, disX, disY}, ...}
--disX为其距左边元素的距离
--将依次从左至右放置所有node
--disY为其y坐标的调整值
--alignType:
--1 or nil:所有元素的y为最高元素的高度的一半
--2:下对齐
--3:上对齐
function UICreater.createContainerNode(subNodeList, alignType)
	local node = cc.Node:create()
	for i,v in ipairs(subNodeList) do
		node:addChild(v.node)
	end
	node:setAnchorPoint(0.5, 0.5)
	node:setCascadeOpacityEnabled(true)

	node.updateInfo = function( )
		local x = 0
		local maxHeight = 0
		for i,v in ipairs(subNodeList) do
			if v.disX then
				x = x + v.disX
			end
			v.node:setPosition(x+v.node:getContentSize().width/2*v.node:getScale(), 0)

			x = x + v.node:getContentSize().width*v.node:getScale()
			local height = v.node:getContentSize().height*v.node:getScale()
			if height > maxHeight then
				maxHeight = height
			end
		end
		alignType = alignType or 1
		local yList = {maxHeight / 2, 0, maxHeight}
		local anchorList = {cc.p(0.5, 0.5), cc.p(0.5, 0), cc.p(0.5, 1)}
		local y = yList[alignType]
		local anchor = anchorList[alignType]
		for i,v in ipairs(subNodeList) do
			local disY = v.disY or 0
			v.node:setAnchorPoint(anchor)
			v.node:setPositionY(y+disY)
		end
		node:setContentSize(x, maxHeight)
	end

	node:updateInfo()

	return node
end

return UICreate