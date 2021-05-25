local img = require "res.img"

local lineCreate = {}

function lineCreate.create(vecArray, isWin)
	local lineName
	if isWin then
		lineName = "guildFight_line2"
	else
		lineName = "guildFight_line1"
	end

	local container = cc.Node:create()

	local count = #vecArray
	for i = 1, count - 1 do
		local p1 = vecArray[i]
		local p2 = vecArray[i + 1]
		local lineSp = img.createUISprite(img.ui[lineName])
		lineSp:setPosition((p1.x + p2.x) * 0.5, (p1.y + p2.y) * 0.5)
		if p1.x == p2.x then
			lineSp:setRotation(90)
			lineSp:setScaleX((math.abs((p2.y - p1.y)) + lineSp:getContentSize().height) / lineSp:getContentSize().width)
		else
			lineSp:setScaleX((math.abs((p2.x - p1.x)) + lineSp:getContentSize().height) / lineSp:getContentSize().width)
		end
		container:addChild(lineSp)
	end

	if isWin then
		container:setZOrder(1)
	end

	return container
end

return lineCreate