-- 网关信息

local gate = {}

require "common.const"
require "common.func"
local userdata = require "data.userdata"

local LIST = { { host = "62.210.83.89", port = 5000 } }

local PING_TIMEOUT = 20          -- ping 1次的超时时间（单位：秒）
local PING_REFRESH = 7*24*3600  -- 重新计算最快网关的时间间隔（单位：秒）

-- handler(status, server) status="ok"|"error"
function gate.init(handler)
    gate.info = nil
    local info = gate.getInfo()
    if info.best and info.timestamp and os.time() - info.timestamp < PING_REFRESH then
        gate.ping(info.best, 1, function(ping)
            if ping ~= -1 then
                gate.info = info
                gate.print("in gate.init")
                handler("ok", info.best)
            else
                gate.pingBest(info, handler)
            end
        end)
    else
        gate.pingBest(info, handler)
    end
end

-- 返回最好网关
function gate.get()
    gate.update()
    if gate.info and gate.info.best then
        return gate.info.best
    end
end

-- ping出最快的网关服务器
-- handler(status, server) status="ok"|"error"
function gate.pingBest(info, handler)
    local list = info.list
    local minPing, index
    local function pingRecursively(i)
        if i > #list then
            if index == nil then
                print("gate.pingBest: no gate available!")
                handler("error")
                return
            end
            info.best = list[index]
            info.timestamp = os.time()
            gate.info = info
            gate.save(info)
            gate.print("in gate.pingBest")
            handler("ok", info.best)
            return
        end
        gate.ping(list[i], 1, function(ping)
            print("gate.pingBest: host", list[i].host, "port", list[i].port, "ping", ping)
            if ping ~= -1 and (minPing == nil or ping < minPing) then
                minPing, index = ping, i
            end
            pingRecursively(i + 1)
        end)
    end
    pingRecursively(1)
end

-- 获得某台网关服务器的ping值
-- server: { host = "..", port = .. }
-- num: echo几次
-- handler(millisecond)
function gate.ping(server, num, handler)
    local isDone = false
    local startTime = getMilliSecond()
    local net = require "net.netClient"
    net:connect({ host = server.host, port = server.port }, function()
        local function echoGate(i)
            net:echo({ sid = 0, echo = i }, function()
                if not isDone then
                    if i == num then
                        isDone = true
                        net:close(function()
                            handler(getMilliSecond() - startTime)
                        end)
                        return
                    end
                    echoGate(i + 1)
                end
            end)
        end
        echoGate(1)
    end)
    -- 超时处理
    local scene = CCDirector:sharedDirector():getRunningScene()
    schedule(scene, PING_TIMEOUT, function()
        if not isDone then
            isDone = true
            net:close(function()
                handler(-1)
            end)
        end
    end)
end

-- info = {
--     list = { {host, port}, {host, port} .. },
--     best = {host, port},
--     timestamp = ..,
-- }
function gate.getInfo()
    local info = gate.getLocalInfo()
    if info then
        for _, s in ipairs(LIST) do
            if not gate.contains(info.list, s) then
                info.list[#info.list+1] = { host = s.host, port = s.port }
            end
        end
        if not gate.contains(info.list, info.best) then
            info.best = nil
        end
        return info
    end
    return { list = LIST }
end

-- 获得本地存档中的网关信息
-- 类似: "host1:port1,host2:port2,host3:port3|host2:port2|timestamp"
--    即: "网关列表|最佳网关|时间戳"
function gate.getLocalInfo()
    local info = { list = {} }
    local infoStr = string.split(userdata.getString(userdata.keys.gateServer), "|")
    if #infoStr ~= 3 then return end
    for _, serverStr in ipairs(string.split(infoStr[1], ",")) do
        local host, port = gate.getHostAndPort(serverStr)
        if host == nil or port == nil then return end
        info.list[#info.list+1] = { host = host, port = port }
    end
    local bestHost, bestPort = gate.getHostAndPort(infoStr[2])
    if bestHost == nil or bestPort == nil then return end
    info.best = { host = bestHost, port = bestPort }
    local timestamp = tonumber(infoStr[3], 10)
    if timestamp == nil or timestamp < 0 then return end
    info.timestamp = timestamp
    return info
end

-- serverStr形式为 host:port
function gate.getHostAndPort(serverStr)
    local server = string.split(serverStr, ":")
    if #server ~= 2 then return end
    local host = string.trim(server[1])
    if host == "" then return end
    local port = tonumber(server[2], 10)
    if port == nil or port < 0 then return end
    return host, port
end

function gate.contains(list, server)
    for _, serv in ipairs(list) do
        if serv.host == server.host and serv.port == server.port then
            return true
        end
    end
    return false
end

function gate.isSameList(list1, list2)
    if #list1 == #list2 then
        for _, s in ipairs(list1) do
            if not gate.contains(list2, s) then
                return false
            end
        end
        return true
    end
    return false
end

function gate.update()
    if gate.info == nil then
        gate.info = gate.getLocalInfo()
    end
    if not gate.isSameList(gate.info.list, LIST) then
        gate.print("in gate.update modify userdata")
        gate.save({ list = LIST, best = gate.info.best, timestamp = 0 })
    end
end

function gate.save(info)
    local serverStr = {}
    for _, s in ipairs(info.list) do
        serverStr[#serverStr+1] = s.host .. ":" .. s.port
    end
    local bestStr = info.best.host .. ":" .. info.best.port
    local str = table.concat(serverStr, ",") .. "|" .. bestStr .. "|" .. info.timestamp
    userdata.setString(userdata.keys.gateServer, str)
end

function gate.print(title)
    print("------ gate ------ {")
    if title then
        print(title)
    end
    if gate.info then
        if gate.info.list then
            for _, s in ipairs(gate.info.list) do
                print("list:", s.host, s.port)
            end
        end
        if gate.info.best then
            print("best:", gate.info.best.host, gate.info.best.port)
        end
        if gate.info.timestamp then
            print("timestamp:", gate.info.timestamp)
        end
    end
    print("------ gate ------ }")
end

return gate
