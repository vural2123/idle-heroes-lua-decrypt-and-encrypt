-- heartBeat
--
--  exports:
--  call heart.run(sid) to start heartBeat
--  call heart.stop() to stop heartBeat
--
--

local heart = {}

local NetClient = require "net.netClient"
netClient = NetClient:getInstance()
local scheduler = require("framework.scheduler")

heart.is_running = false
local HEARTBEAT_INTERVAL = 60

function heart.run(sid)
    heart.sid = sid
    if heart.is_running then
        return 
    end
    heart.is_running = true
    heart.schedule()
end

function heart.stop()
    if heart.schedule_handler then
        scheduler.unscheduleGlobal(heart.schedule_handler)
    end
    heart.schedule_handler = nil
    heart.is_running = false
end

function heart.heart()
    netClient:heart_beat({sid = heart.sid, echo = 12344321})
    print("heart beat ----------- I'm alive.")
end

function heart.schedule()
    if not heart.schedule_handler then
        heart.schedule_handler = scheduler.scheduleGlobal(heart.heart, HEARTBEAT_INTERVAL)
    end
end


return heart
