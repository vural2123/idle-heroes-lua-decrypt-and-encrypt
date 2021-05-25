local nativeUpdateComponent = require("dhcomponents.NativeUpdateComponent")

require("dhcomponents.ClassEx")

local DroidhangComponents = {}

function DroidhangComponents:onSceneInit(scene)
    if not nativeUpdateComponent:isModify() then
        return
    end

    local listenerLayerLayer = require("dhcomponents.layers.ListenerLayer")
    local layer = listenerLayerLayer.new()
    scene:addChild(layer, 10086)
end

function DroidhangComponents:mandateNode(node, key, defaultPos)
	local editorComponent = require("dhcomponents.EditorComponent")
    editorComponent:mandateNode(node, key, defaultPos)
end

return DroidhangComponents