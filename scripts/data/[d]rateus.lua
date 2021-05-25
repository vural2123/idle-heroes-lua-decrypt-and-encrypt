local rateus = {}

function rateus.init(status)
    rateus.status = status
end

function rateus.isAvailable()
    if isOnestore() then
    elseif APP_CHANNEL and APP_CHANNEL ~= "" then
        return false
    end
    return false
end

function rateus.close()
    rateus.status = nil
end

function rateus.print()
    print("--------- rate us -------- {")
    print("status:", rateus.status)
    print("--------- rate us -------- }")
end

return rateus
