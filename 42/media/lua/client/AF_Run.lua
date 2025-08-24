-- AutoForester / AF_Run.lua  (B42-safe)
-- Minimal runner that validates dependencies and starts the Worker.

-- Always export a table from this module
local AF_Run = {}

-- ----------------------------------------------------------------------
-- Logging (safe fallback if AF_Logger isn't available)
local okLog, AF_Log = pcall(require, "AF_Logger")
if not okLog or type(AF_Log) ~= "table" then
    AF_Log = {
        info  = function(...) print("[AutoForester][I]", ...) end,
        warn  = function(...) print("[AutoForester][W]", ...) end,
        error = function(...) print("[AutoForester][E]", ...) end,
    }
end

-- Worker (load defensively so AF_Run still loads even if Worker has an error)
local okWorker, AF_Worker = pcall(require, "AF_Worker")
if not okWorker or type(AF_Worker) ~= "table" then
    AF_Log.error("AF_Worker failed to load: " .. tostring(AF_Worker))
    -- Keep module alive so context menu can show a friendly message.
    function AF_Run.start(playerObj)
        local p = playerObj or getSpecificPlayer(0) or getPlayer()
        if p and p.Say then p:Say("AutoForester: worker not loaded (see console).") end
    end
    print("AutoForester: AF_Run loaded (worker missing)")
    return AF_Run
end

-- ----------------------------------------------------------------------
-- Helper: fetch saved areas
local function getAreas()
    local md = ModData.getOrCreate("AutoForester")
    local a  = (md and md.areas) or {}
    return a.chop, a.pile
end

-- ----------------------------------------------------------------------
-- Public: entrypoint from the context menu
function AF_Run.start(playerObj)
    local p = playerObj or getSpecificPlayer(0) or getPlayer()
    if not p then return end

    local chopArea, pileArea = getAreas()
    if not chopArea then
        if p.Say then p:Say("AutoForester: set a Chop/Gather area first.") end
        return
    end
    if not pileArea then
        if p.Say then p:Say("AutoForester: set a Wood Pile area first.") end
        return
    end

    AF_Log.info("AutoForester starting…")
    AF_Worker.start(p, chopArea, pileArea)
end

print("AutoForester: AF_Run loaded")
return AF_Run
