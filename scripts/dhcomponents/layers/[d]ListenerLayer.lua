local nativeUpdateComponent = require("dhcomponents.NativeUpdateComponent")
local editorComponent = require("dhcomponents.EditorComponent")

local ListenerLayer = class("ListenerLayer", function()
    return cc.Layer:create()
end)

function ListenerLayer:ctor()
    self:setKeypadEnabled(true)
    self:addNodeEventListener(cc.KEYPAD_EVENT, function(event)
        local keyCode = event.key
        local isPressed = event.isPressed

        if not isPressed then
            local director = cc.Director:sharedDirector()
            if keyCode == "KEY_P" then
                if director:isPaused() then
                    director:resume()
                else
                    director:pause()
                end
            elseif keyCode == "KEY_F" then
                nativeUpdateComponent:restart(false)
            elseif keyCode == "KEY_R" then
                nativeUpdateComponent:restart(true)
            elseif keyCode == "KEY_M" then
                print(string.format("纹理使用情况 "))
                CCTextureCache:sharedTextureCache():dumpCachedTextureInfo()
                print(string.format("lua内存使用情况: %.2f MB", collectgarbage("count") / 1024))
            elseif keyCode == "KEY_Q" or keyCode == "KEY_W" or keyCode == "KEY_E" or keyCode == "KEY_A" or keyCode == "KEY_S" or keyCode == "KEY_D" then
                editorComponent:startEditor(keyCode)
            end

            if keyCode ~= "KEY_P" and director:isPaused() then
                director:resume()
            end
        else
            if keyCode == "KEY_B" then
                editorComponent:generateNewKey(keyCode)
            end
        end
    end)
end

return ListenerLayer