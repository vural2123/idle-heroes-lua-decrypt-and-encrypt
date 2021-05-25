
-- monthlogin infos

local monthlogin = {}

function monthlogin.init(__data)
    monthlogin.flag = __data.flag
    monthlogin.cd = __data.cd  + os.time()
    monthlogin.idx = __data.idx or 1

    monthlogin.daily = {}
    monthlogin.recvdays = 0
    local flagLen = #monthlogin.flag-1
    local j = flagLen
    for i=1,30 do
        if j < 0 then
            monthlogin.daily[i] = 0
        else
            monthlogin.daily[i] = 2*checkint(string.sub(monthlogin.flag,j,j))+checkint(string.sub(monthlogin.flag,j+1,j+1))
            if monthlogin.daily[i] == 3 then
                monthlogin.recvdays = monthlogin.recvdays + 1
            end
            j = j-2
        end
    end
end

function monthlogin.isEnd()
    if monthlogin.recvdays == 30 then
        return true
    end
    return false
end

function monthlogin.showRedDot()
    for i=1,30 do
        if monthlogin.daily and monthlogin.daily[i] == 1 then
            return true
        end
    end
    return false
end

function monthlogin.print()
    print("--------- monthlogin --------- {")
    print("flag:", monthlogin.flag, "cd:", monthlogin.cd, " idx:", monthlogin.idx)
    print("--------- monthlogin --------- }")
end

return monthlogin
