-- midas infos

local midas = {}

require "common.const"
require "common.func"

-- param: pb_midas
function midas.init(midas_cd, midas_flag)
    local now = os.time()
    midas.cd = midas_cd + now
    --midas.crstcd = midas_crstcd + now
    midas.flag = midas_flag
    midas.kind = {}

    for i = 1,3 do
        midas.kind[i] = bit.band(0x01, midas.flag)
        midas.flag = bit.brshift(midas.flag, 1)
    end
    midas.flag = midas_flag
end

function midas.showRedDot()
    midas._cd = math.max(0, midas.cd - os.time())
    if midas._cd <= 0 then
        return true
    else
        return false
    end
end

function midas.print()
    print("--------- midas --------- {")
    print("cd:", midas.cd, midas.flag)
    print("--------- midas --------- }")
end

return midas
