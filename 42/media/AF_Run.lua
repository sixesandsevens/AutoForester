-- AF_Run.lua – entry point that sequences chop → haul → sweep
local AF_Log    = require "AF_Logger"
local AF_Worker = require "AF_Worker"

AF       = AF or {}
AF.Run   = AF.Run or {}

local function getAreas()
    local md = ModData.getOrCreate("AutoForester")
    local a  = md and md.areas or {}
    return a and a.chop, a and a.pile
end

function AF.Run.start(playerObj)
    local p = playerObj or getSpecificPlayer(0) or getPlayer()
    if not p then return end

    local chop, pile = getAreas()
    if not chop then p:Say("Set a Chop/Gather area first.") return end
    if not pile then p:Say("Set a Wood Pile area first.")   return end

    AF_Worker.start(p, chop, pile)
end

return AF.Run
