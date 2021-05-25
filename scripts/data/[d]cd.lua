local cd = {}

function cd.initCDS(cds)
    if not cds or #cds <= 0 then return end
    for ii=1,#cds do
        if cds[ii].id == 1 then
            if cds[ii].cd >= 0 then
                (require "data.guildmill").setOrdercd(cds[ii].cd)
            end
        end
    end
end

return cd
