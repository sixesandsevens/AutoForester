AF_Worker = AF_Worker or {}

-- === tiny logger (safe if AF_Logger missing) ===
local okLog, AF_Log = pcall(require, "AF_Logger")
if not okLog or type(AF_Log) ~= "table" then
  AF_Log = {
    info  = function(...) print("[AutoForester][I]", ...) end,
    warn  = function(...) print("[AutoForester][W]", ...) end,
    error = function(...) print("[AutoForester][E]", ...) end,
  }
end

-- === helpers ===============================================================

local function queueSize(p)
  if not p then return 0 end
  local q = ISTimedActionQueue.getTimedActionQueue(p:getPlayerNum())
  if not q or not q.queue then return 0 end
  -- B42: q.queue is a Java ArrayList; size() can throw if something mutates mid-tick.
  local ok, n = pcall(function() return q.queue:size() end)
  if ok and type(n) == "number" then return n end
  -- fallback (Lua-side count)
  local c = 0; for _ in pairs(q.queue) do c = c + 1 end
  return c
end

local function canCarryOneMoreLog(p)
  if not p then return false end
  local inv  = p:getInventory();    if not inv then return false end
  local cap  = p:getMaxWeight()
  local cur  = inv:getCapacityWeight()
  -- Logs are ~4 units; tweak if you like.
  return (cap - cur) >= 4.0
end

-- Pick a valid square inside the pile area (floor preferred, grass OK).
local function choosePileSquare(pileArea, p)
  if not pileArea then return nil end
  local cell = getCell()
  local z    = pileArea.z or 0
  local fallback = nil
  for y = pileArea.miny, pileArea.maxy do
    for x = pileArea.minx, pileArea.maxx do
      local sq = cell:getGridSquare(x, y, z)
      if sq then
        if sq:getFloor() then return sq end
        fallback = fallback or sq
      end
    end
  end
  return fallback
end

-- === public entry ==========================================================

function AF_Worker.start(p, chopArea, pileArea)
  if not p then return end
  if not chopArea then if p.Say then p:Say("AutoForester: no chop area set.") end; return end
  if not pileArea then if p.Say then p:Say("AutoForester: no wood pile set.") end; return end

  local pileSq = choosePileSquare(pileArea, p)
  if not pileSq then
    if p.Say then p:Say("AutoForester: no valid pile square.") end
    return
  end

  -- Phase 1: enqueue chops (one pass, no spamming every tick)
  local cell = getCell()
  local count = 0
  for y = chopArea.miny, chopArea.maxy do
    for x = chopArea.minx, chopArea.maxx do
      local sq = cell:getGridSquare(x, y, chopArea.z or 0)
      if sq and sq:HasTree() then
        local tree = sq:getTree()
        if tree then
          ISWorldObjectContextMenu.doChopTree(p, tree) -- vanilla adds move+chop timed actions
          count = count + 1
        end
      end
    end
  end
  AF_Log.info("AutoForester: Chop actions queued ("..tostring(count)..").")

  -- Phase 2 begins after chops drain: we’ll poll until the queue is empty, then sweep+haul.
  local function tryStartSweep()
    if queueSize(p) > 0 then return end
    AF_Log.info("AutoForester: starting sweep/gather.")
    AF_Hauler.setWoodPileSquare(pileSq)
    AF_Hauler.runSweepAndHaul(p, chopArea)
    Events.OnTick.Remove(tryStartSweep)
  end
  Events.OnTick.Add(tryStartSweep)
end

return AF_Worker
