-- manage particles here

local particle = {}

require "common.const"
require "common.func"
local view = require "common.view"

local path = "particles/"

function particle.create(name)
    local p = CCParticleSystemQuad:create(string.format("%s%s.plist", path, name))
    return p
end

--function particle.create(name, minScale)
--    local p = CCParticleSystemQuad:create(string.format("%s%s.plist", path, name))
--    if minScale then
--        p:setStartSize(view.minScale * p:getStartSize())
--        p:setStartSizeVar(view.minScale * p:getStartSizeVar())
--        p:setEndSize(view.minScale * p:getEndSize())
--        p:setEndSizeVar(view.minScale * p:getEndSizeVar())
--    end
--    return p
--end

return particle
