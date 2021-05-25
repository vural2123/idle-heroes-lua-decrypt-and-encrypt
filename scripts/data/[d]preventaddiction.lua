local preventAddiction = {}

require "common.const"
require "common.func"
local i18n = require "res.i18n"

preventAddiction.THREE_HOUR = 3600 * 3
preventAddiction.FIVE_HOUR = 3600 * 5
preventAddiction.MAX_HOUR = 3600 * 100

local onlineTime = 0
local adult = 0
local dialogShowTime = preventAddiction.THREE_HOUR
local startTime = 0

function preventAddiction.init(serverOnlineTime, adultCode)
    onlineTime = serverOnlineTime or 0
    --0:未进行身份验证;1:是成年人(大于等于18岁算成年人);2:不是成年人
    adult = adultCode or 0

    startTime = os.time()

    preventAddiction.print()
end

function preventAddiction.getTotalTime()
    local currentTime = os.time();
    return onlineTime + (currentTime - startTime)
end

function preventAddiction.getDialogShowTime()
    return dialogShowTime
end

function preventAddiction.setDialogShowTime(time)
    dialogShowTime = time
end

function preventAddiction.shouldShowDialog()

    return false
end

function preventAddiction.needPreventAddiction()
return false

end

function preventAddiction.getAdult()
    return adult;
end

function preventAddiction.setAdult(adultCode)
    adult = adultCode;
end

function preventAddiction.print()
    print("--------------- prevent addiction --------------- {")
    print("onlineTime:", onlineTime)
    print("dialogShowTime:", dialogShowTime)
    print("adult:", adult)
    print("--------------- prevent addictions --------------- }")
end

return preventAddiction

