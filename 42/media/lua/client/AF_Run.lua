AF = AF or {}
AF.Run = AF.Run or {}

local okLog, AF_Log = pcall(require, "AF_Logger")
if not okLog or type(AF_Log) ~= "table" then
    AF_Log = { info=function(...) print("[AutoForester][I]", ...) end,
               warn=function(...) print("[AutoForester][W]", ...) end,
               error=function(...) print("[AutoForester][E]", ...) end }
end

local AF_Worker = require "AF_Worker"

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

    AF_Log.info("AutoForester starting…")
    AF_Worker.start(p, chop, pile)
end

print("AutoForester: AF_Run loaded")
return AF.Run
