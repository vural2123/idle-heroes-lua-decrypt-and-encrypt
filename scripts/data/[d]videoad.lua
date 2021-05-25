local videoad = {}

function videoad.init(num)
    videoad.num = num
end

function videoad.isAvailable()
    if isOnestore() then
        return false
    end
    return videoad.num and videoad.num > 0 
               --and HHUtils:isReleaseMode() 
               and HHUtils:isVideoAdReady()
end

function videoad.watch()
    if videoad.num > 0 then
        videoad.num = videoad.num - 1
    end
    print("videoad num:", videoad.num)
end

function videoad.print()
    print("--------- video ad -------- {")
    print("num:", videoad.num)
    print("--------- video ad -------- }")
end

return videoad
