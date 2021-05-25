local dhString = require("dhcomponents.tools.String")
local neverUpdateData = require("dhcomponents.NeverUpdateData")

local EditorComponent = {}

local filePath = "dhcomponents/data/NodeProperty.lua"
local modName = "dhcomponents.data.NodeProperty"

function EditorComponent:fullPathForSrcFilename(fileName)
    local userdata = require("dhcomponents.data.userdata")
    local filepath = userdata.path
    return filepath.."scripts_raw/"..fileName
end

function EditorComponent:writeStringToFile(text, path)
    local wfile = io.open(path, "wb")
    if not wfile then
        print("@@@@@create file failed:", path)
        return
    end
    wfile:write(text)
    wfile:flush()
    io.close(wfile)
end

function EditorComponent:init()
    local nativeUpdateComponent = require("dhcomponents.NativeUpdateComponent")
    local modifyFlag = nativeUpdateComponent:isModify()

    if modifyFlag and neverUpdateData.editorComponentCloneData then
        for key, value in pairs(neverUpdateData.editorComponentCloneData) do
            self[key] = value
        end
        return
    end

    local fileListPath = "dhcomponents/data/FileList.lua"
    local fileListMap = {}
    local fileListText = ""

    xpcall(function ()
        fileListMap = require("dhcomponents.data.FileList")

        if modifyFlag then
            fileListText = cc.FileUtils:sharedFileUtils():getStringFromFile(fileListPath)
        end
    end, function ()
        fileListMap = {}

        if modifyFlag then
            local fullPath = self:fullPathForSrcFilename(fileListPath)
            fileListText = "local FileList = {\n}\nreturn FileList\n"
            self:writeStringToFile(fileListText, fullPath)
        end
    end)

    if modifyFlag then
        local deviceId = DeviceUtil:getDeviceId()
        local deviceName = DeviceUtil:getDeviceName()
        self.deviceId = deviceId

        if not fileListMap[deviceId] then
            local luaTextArray = dhString.split(fileListText, '\n')
            local line = #luaTextArray
            table.insert(luaTextArray, line - 2, string.format('["%s"]="%s",', deviceId, deviceName))

            local text = ""
            local count = #luaTextArray
            for line, value in ipairs(luaTextArray) do
                text = text..value
                if line ~= count then
                    text = text.."\n"
                end
            end

            local fullPath = self:fullPathForSrcFilename(fileListPath)
            self:writeStringToFile(text, fullPath)

            fileListMap[deviceId] = deviceName
        end
    end

    self.nodeData = {}
    self.nodeInfoMap = {}
    self.keyLineMap = {}
    self.keyFileNameMap = {}
    self.luaTextMapArray = {}

    for fileName, _ in pairs(fileListMap) do
        local nodeData = {}
        local fileText = ""
        local filePath = "dhcomponents/data/"..fileName..".lua"
        xpcall(function ()
            local modName = "dhcomponents.data."..fileName
            nodeData = require(modName)

            if modifyFlag then
                fileText = cc.FileUtils:sharedFileUtils():getStringFromFile(filePath)
            end
        end, function ()
            nodeData = {}

            if modifyFlag then
                local fullPath = self:fullPathForSrcFilename(filePath)
                fileText = "local NodeProperty = {\n}\nreturn NodeProperty"
                self:writeStringToFile(fileText, fullPath)
            end
        end)
        
        if nodeData then
            for k, v in pairs(nodeData) do
                assert(self.nodeData[k] == nil, "key error")
                self.nodeData[k] = v
            end
        end

        local luaTextArray = {}
        luaTextArray = dhString.split(fileText, '\n')
        self.luaTextMapArray[fileName] = luaTextArray

        for line, text in ipairs(luaTextArray) do
            if string.find(text, "%['") == 1 then
                local nextPos = string.find(text, "%']")
                if nextPos then
                    local key = string.sub(text, 1 + 2, nextPos - 1)
                    self.keyLineMap[key] = line

                    self.keyFileNameMap[key] = fileName
                end
            end
        end
    end

    neverUpdateData.editorComponentCloneData = {
        deviceId = self.deviceId,
        nodeData = self.nodeData,
        nodeInfoMap = self.nodeInfoMap,
        keyLineMap = self.keyLineMap,
        keyFileNameMap = self.keyFileNameMap,
        luaTextMapArray = self.luaTextMapArray,
    }
end

function EditorComponent:syncTextState()
    for _, info in pairs(self.nodeInfoMap) do
        local key = info.key
        if not self.nodeData[key] then
            self.nodeData[key] = {orgInfo = {}}
        end
        local keyInfo = self.nodeData[key]
        local text = string.format("['%s']={", key)
        local line = self.keyLineMap[key]
        if info.pos then
            keyInfo.pos = clone(info.pos)
            text = text..string.format("pos={x=%.3f,y=%.3f}", info.pos.x, info.pos.y)
        end
        if info.angleX then
            keyInfo.angleX = info.angleX
            text = text..string.format(",angleX=%.3f", info.angleX)
        end
        if info.angleY then
            keyInfo.angleY = info.angleY
            text = text..string.format(",angleY=%.3f", info.angleY)
        end
        if info.scaleX then
            keyInfo.scaleX = info.scaleX
            text = text..string.format(",scaleX=%.3f", info.scaleX)
        end
        if info.scaleY then
            keyInfo.scaleY = info.scaleY
            text = text..string.format(",scaleY=%.3f", info.scaleY)
        end
        if info.anchor then
            keyInfo.anchor = clone(info.anchor)
            text = text..string.format(",anchor={x=%.3f,y=%.3f}", info.anchor.x, info.anchor.y)
        end
        if info.color then
            keyInfo.color = clone(info.color)
            text = text..string.format(",color={r=%d,g=%d,b=%d}", info.color.r, info.color.g, info.color.b)
        end
        if info.opacity then
            keyInfo.opacity = info.opacity
            keyInfo.orgInfo.opacity = info.opacity
            text = text..string.format(",opacity=%d", info.opacity)
        end
        text = text.."},"

        local fileName = self.keyFileNameMap[key]
        self.luaTextMapArray[fileName][line] = text

        for k, value in pairs(keyInfo) do
            if k ~= "orgInfo" then
                keyInfo.orgInfo[k] = clone(value)
            end
        end
    end
end

function EditorComponent:writeToFile()
    for fileName, luaTextArray in pairs(self.luaTextMapArray) do
        local text = ""
        local count = #luaTextArray
        for line, value in ipairs(luaTextArray) do
            text = text..value
            if line ~= count then
                text = text.."\n"
            end
        end

        local filePath = "dhcomponents/data/"..fileName..".lua"
        local fullPath = cc.FileUtils:sharedFileUtils():fullPathForFilename(filePath)
        if not fullPath or fullPath == "" then
            fullPath = self:fullPathForSrcFilename(filePath)
        end
        self:writeStringToFile(text, fullPath)
    end
end

function EditorComponent:resetNode(node, info)
    if info.pos then
        node:setPosition(info.pos)
    end
    if info.angleX then
        node:setRotationX(info.angleX)
    end
    if info.angleY then
        node:setRotationY(info.angleY)
    end
    if info.scaleX then
        node:setScaleX(info.scaleX)
    end
    if info.scaleY then
        node:setScaleY(info.scaleY)
    end
    if info.anchor then
        node:setAnchorPoint(cc.p(info.anchor.x, info.anchor.y))
    end
    if info.color then
        node:setColor(info.color)
    end
    if info.opacity then
        node:setOpacity(info.opacity)
    end
end

function EditorComponent:mandateNode(node, key, defaultPos)
    if type(key) == "number" then
        key = tostring(key)
    end

    local info = self.nodeData[key]
    if info then
        self:resetNode(node, info)
    else
        local luaTextArray = self.luaTextMapArray[self.deviceId]
        if not luaTextArray then
            return
        end
        local line = #luaTextArray
        local x, y
        if defaultPos then
            x, y = defaultPos.x, defaultPos.y
        else
            local rdMinX = 60
            local rdMaxX = 180
            local rdMinY = 60
            local rdMaxY = 150

            local contentSize = node:getContentSize()
            if node:getParent() then
                contentSize = node:getParent():getContentSize()
            end

            if contentSize.width > 0 then
               rdMaxX = math.max(rdMaxX, contentSize.width - rdMaxX + rdMinX)
            end
            if contentSize.height > 0 then
               rdMaxY = math.max(rdMaxY, contentSize.height - rdMaxY + rdMinY)
            end

            x, y = math.random(rdMinX, rdMaxX), math.random(rdMinY, rdMaxY)
        end

        info = {pos = cc.p(x, y)}
        
        local value = string.format("['%s']={pos={x=%d,y=%d}},", key, x, y)
        self.keyLineMap[key] = line - 1
        self.keyFileNameMap[key] = self.deviceId

        node:setPosition(x, y)
        
        table.insert(luaTextArray, line - 1, value)

        self:writeToFile()

        self.nodeData[key] = info
    end

    info.orgInfo = {
        pos = cc.p(node:getPosition()),
        angleX = node:getRotationX(),
        angleY = node:getRotationY(),
        scaleX = node:getScaleX(),
        scaleY = node:getScaleY(),
        anchor = node:getAnchorPoint(),
        color = node:getColor(),
        opacity = node:getOpacity(),
    }

    info.key = key
    self.nodeInfoMap[node] = info
end

function EditorComponent:endEditor()
    if self.editorLayer then
        self.editorLayer:runAction(cc.RemoveSelf:create())
        self.editorLayer = nil
    end
end

function EditorComponent:startEditor(keyCode)
    if tolua.isnull(self.editorLayer) then
        self.editorLayer = nil
    end
    if not self.editorLayer then
        self.editorLayer = require("dhcomponents.layers.EditorLayer").new(keyCode)
        cc.Director:sharedDirector():getRunningScene():addChild(self.editorLayer, 10086)

        self:initOperation()
    end
end

function EditorComponent:switchEditorMode()
    if self.editorLayer and not tolua.isnull(self.editorLayer) then
        self.editorLayer:removeFromParent()
        self.editorLayer = nil
    else
        self.editorLayer = require("dhcomponents.layers.EditorLayer").new()
        cc.Director:sharedDirector():getRunningScene():addChild(self.editorLayer, 10086)
    end
end

function EditorComponent:getAllActiveNode()
    for node, _ in pairs(self.nodeInfoMap) do
        if tolua.isnull(node) then
            self.nodeInfoMap[node] = nil
        end
    end
    return self.nodeInfoMap
end

function EditorComponent:generateNewKey()
    if not EditorComponent.recordKeyMap then
        EditorComponent.recordKeyCount = 0
        EditorComponent.recordKeyMap = {}
    end
    local prevKey = ""
    for i = 1, 4 do
        local rdNum = math.random(1, 7)
        if rdNum == 1 or rdNum == 2 or rdNum == 3 then
            prevKey = prevKey..string.char(string.byte('a') + math.random(0, 25))
        elseif rdNum == 4 or rdNum == 5 or rdNum == 6 then
            prevKey = prevKey..string.char(string.byte('A') + math.random(0, 25))
        else
            prevKey = prevKey..string.char(string.byte('0') + math.random(0, 9))
        end
    end
    print("-----------new key-----------")
    for i = 1, 6 do
        local resKey
        while true do
            local key = prevKey.."_"
            for j = 1, 6 do
                local rdNum = math.random(1, 7)
                if rdNum == 1 or rdNum == 2 or rdNum == 3 then
                    key = key..string.char(string.byte('a') + math.random(0, 25))
                elseif rdNum == 4 or rdNum == 5 or rdNum == 6 then
                    key = key..string.char(string.byte('A') + math.random(0, 25))
                else
                    key = key..string.char(string.byte('0') + math.random(0, 9))
                end
            end
            if not self.keyLineMap[key] and not EditorComponent.recordKeyMap[key] then
                resKey = key
                EditorComponent.recordKeyMap[key] = true
                EditorComponent.recordKeyCount = EditorComponent.recordKeyCount + 1
                break
            end
        end
        print(string.format("key(%d) : ", EditorComponent.recordKeyCount), resKey)
    end
end

function EditorComponent:initOperation()
    self.optIndex = 1
    self.optDataArray = {}

    local cloneNodeInfoMap = {}
    for node, info in pairs(self.nodeInfoMap) do
        cloneNodeInfoMap[node] = clone(info)
    end
    table.insert(self.optDataArray, cloneNodeInfoMap)
end

function EditorComponent:pushOperation(nodeInfoMap)
    for i = self.optIndex + 1, #self.optDataArray do
        self.optDataArray[i] = nil
    end

    local cloneNodeInfoMap = {}
    for node, info in pairs(nodeInfoMap) do
        cloneNodeInfoMap[node] = clone(info.info)
    end

    table.insert(self.optDataArray, cloneNodeInfoMap)
    self.optIndex = #self.optDataArray

    for node, info in pairs(nodeInfoMap) do
        self.nodeInfoMap[node] = info.info
    end

    self:syncTextState()
    self:writeToFile()
end

function EditorComponent:resumeOperation()
    local nodeInfoMap = self.optDataArray[self.optIndex]

    for node, info in pairs(nodeInfoMap) do
        self.nodeInfoMap[node] = info
    end

    for node, info in pairs(self.nodeInfoMap) do
        if tolua.isnull(node) then
            self.nodeInfoMap[node] = nil
        else
            self:resetNode(node, info)
        end
    end

    self:syncTextState()
    self:writeToFile()
end

function EditorComponent:undoOperation()
    if self.optIndex <= 1 then
        return
    end
    self.optIndex = self.optIndex - 1

    self:resumeOperation()
end

function EditorComponent:redoOperation()
    if self.optIndex >= #self.optDataArray then
        return
    end
    self.optIndex = self.optIndex + 1

    self:resumeOperation()
end

EditorComponent:init()

return EditorComponent
