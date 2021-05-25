local ui = {}

--获取配置信息
local function readData()

end

--初始化数据
function ui.initData()
	ui.data = {}
	ui.widget = {}
	ui.widget.cardNodeVec = {}
	--滚动容器
	ui.widget.Scroll = nil
	--元素数量
	ui.data.totalNum = 0
	--元素中心间距
	ui.data.spacing = 0
	--是否能够滚动
	ui.data.canScroll = true
end

function ui.create()
	ui.initData()

	local Scroll = CCScrollView:create()
	Scroll:setAnchorPoint(CCPoint(0.5,0.5))
	Scroll:setDirection(kCCScrollViewDirectionHorizontal)
	Scroll:setViewSize(CCSize(800,500))
	Scroll:setContentSize(CCSize(1640,500))
	Scroll:setTouchEnabled(false)
	Scroll:setCascadeOpacityEnabled(true)
	Scroll:getContainer():setCascadeOpacityEnabled(true)
    
    local itemLayer = CCLayer:create()
    itemLayer:setContentSize(800,400)
    itemLayer:setCascadeOpacityEnabled(true)
    Scroll:addChild(itemLayer)

	ui.widget.Scroll = Scroll
	ui.widget.itemLayer = itemLayer
	return Scroll
end

--添加卡牌
function ui.addCard(card,addNum)
	local size = card.widget.qualityBox:getContentSize()
	local width = size.width*0.8
	local height = size.height*0.8
	ui.data.spacing = width + 25
	ui.widget.itemLayer:addChild(card.widget.node,addNum)
	card.widget.node:setPositionX(ui.data.totalNum*ui.data.spacing + width/2 + 10)
	card.widget.node:setPositionY(270)
	ui.data.totalNum = ui.data.totalNum + 1

	--存储card节点
	table.insert(ui.widget.cardNodeVec,card.widget.node)
end

--检测卡牌位置隐藏card，用于解决底层滚动视图，将用于裁剪的滚动层滚动到屏幕外擅自取消裁剪的问题
function ui.checkCard()
	local posX = math.abs(ui.widget.itemLayer:getPositionX())
	for k,v in pairs(ui.widget.cardNodeVec) do
		if v:getPositionX() <=  posX then
			v:setVisible(false)
		else
			v:setVisible(true)
		end
	end
end

--设置滚动方向(参数:1--向右,-1--向左,第二参数为相关联的控件)
function ui.moveDir(dir,btn,time)
	time = time or 0.2
	if not ui.data.canScroll then
		return
	end
	btn:setEnabled(false)
	ui.data.canScroll = false
	local posX = ui.widget.itemLayer:getPositionX()
	local posY = ui.widget.itemLayer:getPositionY()
	local move = CCMoveTo:create(time,CCPoint(posX+dir*ui.data.spacing,0))
	local callfunc = CCCallFunc:create(function ()
		btn:setEnabled(true)
		ui.data.canScroll = true
	end)
	local actArray = CCArray:create()
	actArray:addObject(move)
	actArray:addObject(callfunc)
	local sequence = CCSequence:create(actArray)
	--ui.itemLayer:stopAllActions()
	ui.widget.itemLayer:runAction(sequence)
end

return ui