-- media/lua/client/AF_Run.lua
-- Small wrapper that loads the worker, validates areas, and kicks off the job.

local M = {}          -- module table
_G.AF_Run = M         -- also expose globally for older call sites

-- lightweight logger fallback
local okLog, AF_Log = pcall(require, "AF_Logger")
if not okLog or type(AF_Log) ~= "table" then
  AF_Log = {
    info  = function(...) print("[AutoForester][I]", ...) end,
    warn  = function(...) print("[AutoForester][W]", ...) end,
    error = function(...) print("[AutoForester][E]", ...) end,
  }
end

local function say(p, msg) if p and p.Say then p:Say(msg) end end

local function getAreas()
  local md = ModData.getOrCreate("AutoForester")
  local a  = md and md.areas or {}
  return a and a.chop, a and a.pile
end

function M.start(playerObj)
  local p = playerObj or getSpecificPlayer(0) or getPlayer()
  if not p then AF_Log.error("AF_Run.start: no player") return end

  -- read areas from ModData (set by your area-select UI)
  local chopArea, pileArea = getAreas()
  if not chopArea then say(p, "Set a Chop/Gather area first.") return end
  if not pileArea then say(p, "Set a Wood Pile area first.")  return end

  -- (optional while developing) force a fresh load of the worker
  if package and package.loaded then
    package.loaded["AF_Worker"] = nil
  end

  -- load the worker module
  local okW, modOrErr = pcall(require, "AF_Worker")
  local Worker = okW and modOrErr or _G.AF_Worker
  if not okW then
    AF_Log.warn("require('AF_Worker') failed: " .. tostring(modOrErr))
  end
  if type(Worker) ~= "table" or type(Worker.start) ~= "function" then
    AF_Log.error("AF_Worker not loaded: " .. tostring(modOrErr))
    say(p, "AutoForester: worker not loaded (see console).")
    return
  end

  AF_Log.info("AutoForester: starting")
  Worker.start(p, chopArea, pileArea)
end

print("AutoForester: AF_Run loaded")
return M
