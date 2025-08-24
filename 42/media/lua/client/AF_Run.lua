-- media/lua/client/AF_Run.lua

-- Keep a global namespace but don't depend on it.
AF = AF or {}

-- --- logger (soft-require) ---------------------------------------------------
local AF_Log
do
    local ok, mod = pcall(require, "AF_Logger")
    if ok and type(mod) == "table" then
        AF_Log = mod
    else
        -- tiny fallback so we still see messages in console
        AF_Log = {
            info  = function(...) print("[AutoForester][I]", ...) end,
            warn  = function(...) print("[AutoForester][W]", ...) end,
            error = function(...) print("[AutoForester][E]", ...) end,
        }
    end
end

-- --- worker (hard-require) ---------------------------------------------------
local okWorker, AF_Worker = pcall(require, "AF_Worker")
if not okWorker or type(AF_Worker) ~= "table" or type(AF_Worker.start) ~= "function" then
    AF_Log.error("AF_Worker not loaded (see console).")
    -- still return a module so require(...) is not nil
    local AF_Run = { start = function() end }
    print("AutoForester: AF_Run loaded (worker missing)")
    return AF_Run
end

-- --- helpers -----------------------------------------------------------------
local function getAreas()
    local md = ModData.getOrCreate("AutoForester")
    local a  = (md and md.areas) or {}
    return a.chop, a.pile
end

-- --- public API --------------------------------------------------------------
local AF_Run = {}

function AF_Run.start(playerObj)
    local p = playerObj or getSpecificPlayer(0) or getPlayer()
    if not p then return end

    local chop, pile = getAreas()
    if not chop then if p.Say then p:Say("Set a Chop/Gather area first.") end; return end
    if not pile then if p.Say then p:Say("Set a Wood Pile area first.") end;   return end

    AF_Log.info("AutoForester starting")
    AF_Worker.start(p, chop, pile)
end

print("AutoForester: AF_Run loaded")
return AF_Run
