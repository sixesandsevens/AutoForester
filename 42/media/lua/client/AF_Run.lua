-- AF_Run.lua
local Worker = require("AF_Worker")

AF = AF or {}
AF.Run = AF.Run or {}

function AF.Run.start(playerObj)
    local areas = AF.Areas and AF.Areas.getAreas() or {}
    local chop = areas and areas.chop or nil
    local pile = areas and areas.pile or nil
    if not (chop and pile) then
        if playerObj and playerObj.Say then playerObj:Say("Designate areas first.") end
        AF_Log.err("AutoForester: start aborted; areas missing")
        return
    end
    if Worker and Worker.start then
        Worker.start(playerObj, chop, pile)
    else
        AF_Log.err("AutoForester: Worker module not available")
    end
end

return AF.Run
