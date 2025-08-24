-- 42/media/lua/client/AF_Run.lua
-- Minimal, robust runner for AutoForester.

-- Make sure the global AF namespace is a table.
if type(AF) ~= "table" then AF = {} end
AF.Run = AF.Run or {}

-- Small safe require helper.
local function safeRequire(name)
    local ok, mod = pcall(require, name)
    if not ok then return false, mod end
    return true, mod
end

-- Logger (optional module). Fallback to print() if missing.
local okLog, AF_Log = safeRequire("AF_Logger")
if not okLog or type(AF_Log) ~= "table" then
    AF_Log = {
        info  = function(...) print("[AutoForester][I]", ...) end,
        warn  = function(...) print("[AutoForester][W]", ...) end,
        error = function(...) print("[AutoForester][E]", ...) end,
    }
end

-- Read the saved areas from ModData.
local function getAreas()
    local md = ModData.getOrCreate("AutoForester")
    md.areas = md.areas or {}
    return md.areas.chop, md.areas.pile
end

-- Public: start the job (called from the context menu).
function AF.Run.start(playerObj)
    local p = playerObj or getSpecificPlayer(0) or getPlayer()
    if not p then return end

    local chop, pile = getAreas()
    if not chop then if p.Say then p:Say("Set a Chop/Gather area first.") end; return end
    if not pile then if p.Say then p:Say("Set a Wood Pile area first.") end;   return end

    -- Load the worker on demand, so AF_Run itself can load cleanly.
    local okW, AF_WorkerOrErr = safeRequire("AF_Worker")
    local AF_Worker = okW and AF_WorkerOrErr or nil
    if type(AF_Worker) ~= "table" or type(AF_Worker.start) ~= "function" then
        AF_Log.error("AF_Worker not loaded: " .. tostring(AF_WorkerOrErr))
        if p.Say then p:Say("AutoForester: worker not loaded (see console).") end
        return
    end

    AF_Log.info("AutoForester: starting")
    AF_Worker.start(p, chop, pile)
end

return AF.Run
