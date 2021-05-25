local online = {}

local cfgonline = require "config.online"

online.pull_time = os.time()

function online.sync(data)
    online.pull_time = os.time()
    online.id = data.id or 0
    online.cd = data.cd or 0
end

function online.getRewardById(id)
    id = id or online.id
    return cfgonline[id].reward
end

return online
