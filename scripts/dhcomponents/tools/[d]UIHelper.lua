local UIHelper = {}

function UIHelper.hasVisibleParents(node)
    while node do
        if not node:isVisible() then
            return false
        end
        node = node:getParent()
    end
    return true
end

return UIHelper