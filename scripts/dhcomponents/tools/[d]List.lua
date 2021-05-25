local ListNode = class("ListNode")

function ListNode:ctor(value, next, prev)
    self.value = value
    self.next = next
    self.prev = prev
end

function ListNode:getNext()
    return self.next
end

function ListNode:getPrev()
    return self.prev
end

function ListNode:getValue()
    return self.value
end

--在指定listNode之前插入新结点 
function ListNode.insert(listNode, value)
    local newNode = ListNode.new(value, listNode, listNode.prev)

    listNode.prev.next = newNode
    listNode.prev = newNode

    return newNode
end

local List = class("List")

function List:ctor()
    self.node = ListNode.new()
    self.node.next = self.node
    self.node.prev = self.node
    self.length = 0
end

function List:getBegin()
    return self.node.next
end

function List:getEnd()
    return self.node
end

-- function List:getReBegin()
--     return self.node.prev
-- end

-- function List:getReEnd()
--     return self.node
-- end

function List:insert(listNode, value)
    ListNode.insert(listNode, value)
    self.length = self.length + 1
end

function List:pushFront(value)
    self:insert(self.node.next, value)
end

function List:pushBack(value)
    self:insert(self.node, value)
end

function List:popFront()
    self:erase(self.node.next)
end

function List:popBack()
    self:erase(self.node.prev)
end

function List:erase(listNode)
    listNode.prev.next = listNode.next
    listNode.next.prev = listNode.prev

    local nextNode = listNode.next

    --destroy
    listNode.value = nil
    listNode = nil

    self.length = math.max(self.length - 1, 0)

    return nextNode
end

function List:empty()
    return self.node.next == self.node
end

function List:front()
    return self.node.next.value
end

function List:back()
    return self.node.prev.value
end

function List:copy()
    local newList = List.new()
    local iter = self:getBegin()
    while iter ~= self:getEnd() do
        newList:pushBack(iter:getValue())
        iter = iter:getNext()
    end
    return newList
end

function List:clear()
    self.node.next = self.node
    self.node.prev = self.node
    self.length = 0
end

function List:size()
    return self.length
end

return List