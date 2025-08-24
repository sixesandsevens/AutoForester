AF = AF or {}
AF.Run = AF.Run or {}

local okLog, AF_Log = pcall(require, "AF_Logger")
if not okLog or type(AF_Log) ~= "table" then
    AF_Log = {
        info  = function(...) print("[AutoForester][I]", ...) end,
        warn  = function(...) print("[AutoForester][W]", ...) end,
        error = function(...) print("[AutoForester][E]", ...) end,
    }
end

-- Safe-require helper so we can show a friendly on-screen message.
local function safeRequire(name)
    local ok, modOrErr = pcall(require, name)
    if not ok then return false, modOrErr end
    return true, modOrErr
end

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

    -- Load the worker on demand so AF_Run itself can load cleanly.
    local okW, AF_WorkerOrErr = safeRequire("AF_Worker")
    local AF_Worker = okW and AF_WorkerOrErr or nil
    if type(AF_Worker) ~= "table" or type(AF_Worker.start) ~= "function" then
        AF_Log.error("AF_Worker not loaded: "..tostring(AF_WorkerOrErr))
        if p.Say then p:Say("AutoForester: worker not loaded (see console).") end
        return
    end

    AF_Log.info("AutoForester: starting")
    AF_Worker.start(p, chop, pile)
end

print("AutoForester: AF_Run loaded")
return AF.Run