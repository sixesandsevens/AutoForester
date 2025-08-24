AF = AF or {}
AF.Run = AF.Run or {}

local okLog, AF_Log = pcall(require, "AF_Logger")
if not okLog or type(AF_Log) ~= "table" then
    AF_Log = {
        info  = function(...) print("[AutoForester][I]", ...) end,
        warn  = function(...) print("[AutoForester][W]", ...) end,
        error = function(...) print("[AutoForester][E]", ...) end
    }
end

local function getAreas()
    local md = ModData.getOrCreate("AutoForester")
    local a = md and md.areas or {}
    return a and a.chop, a and a.pile
end

function AF_Run.start(playerObj)
    local p = playerObj or getSpecificPlayer(0) or getPlayer()
    if not p then return end

    -- Safe-load the worker; bail nicely if it fails.
    local ok, AF_Worker = pcall(require, "AF_Worker")
    if not ok or type(AF_Worker) ~= "table" or type(AF_Worker.start) ~= "function" then
        if p.Say then p:Say("AutoForester: worker not loaded (see console).") end
        AF_Log.error("require('AF_Worker') failed: " .. tostring(AF_Worker))
        return
    end

    local chop, pile = getAreas()
    if not chop then p:Say("Set a Chop/Gather area first.") return end
    if not pile then p:Say("Set a Wood Pile area first.") return end

    AF_Log.info("AutoForester starting?")
    AF_Worker.start(p, chop, pile)
end

print("AutoForester: AF_Run loaded")
return AF.Run
