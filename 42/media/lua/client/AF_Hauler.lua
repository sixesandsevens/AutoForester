AF_Hauler = AF_Hauler or {}

local okLog, AF_Log = pcall(require, "AF_Logger")
if not okLog or type(AF_Log) ~= "table" then
  AF_Log = {
    info  = function(...) print("[AutoForester][I]", ...) end,
    warn  = function(...) print("[AutoForester][W]", ...) end,
    error = function(...) print("[AutoForester][E]", ...) end,
  }
end

local pileSq = nil
function AF_Hauler.setWoodPileSquare(sq) pileSq = sq end

-- --- internal --------------------------------------------------------------

local function queueSize(p)
  if not p then return 0 end
  local q = ISTimedActionQueue.getTimedActionQueue(p:getPlayerNum())
  if not q or not q.queue then return 0 end
  local ok, n = pcall(function() return q.queue:size() end)
  if ok and type(n) == "number" then return n end
  local c = 0; for _ in pairs(q.queue) do c = c + 1 end
  return c
end

local function canCarryOneMoreLog(p)
  local inv = p and p:getInventory()
  if not inv then return false end
  local cap = p:getMaxWeight()
  local cur = inv:getCapacityWeight()
  return (cap - cur) >= 4.0
end

-- Enqueue a *single* grab for a Base.Log world object on this square.
local function enqueueOneGrabOnSquare(p, sq)
  if queueSize(p) > 0 then return false end                 -- don't spam the queue
  local wobs = sq:getWorldObjects()
  local n    = (wobs and wobs:size()) or 0
  for i = 0, n - 1 do
    local w = wobs:get(i)
    if w and instanceof(w, "IsoWorldInventoryObject") then
      local it = w:getItem()
      if it and it:getFullType() == "Base.Log" then
        ISTimedActionQueue.add(ISWalkToTimedAction:new(p, sq))
        -- IMPORTANT: pass the *world object* to ISGrabItemAction
        ISTimedActionQueue.add(ISGrabItemAction:new(p, w, 50))
        AF_Log.info("Haul actions queued (1)")
        return true
      end
    end
  end
  return false
end

local function dropAllLogsToPile(p)
  if not p or not pileSq then return 0 end
  local inv   = p:getInventory(); if not inv then return 0 end

  -- Walk to pile, then drop every log we carry.
  ISTimedActionQueue.add(ISWalkToTimedAction:new(p, pileSq))

  local items = inv:getItems()
  local dropped = 0
  for i = 0, items:size() - 1 do
    local it = items:get(i)
    if it and it.getFullType and it:getFullType() == "Base.Log" then
      ISTimedActionQueue.add(ISDropItemAction:new(p, it, 0))
      dropped = dropped + 1
    end
  end
  if dropped > 0 then
    AF_Log.info("AutoForester: queued "..tostring(dropped).." drop(s) to pile.")
  end
  return dropped
end

-- --- public ---------------------------------------------------------------

-- One-pass sweeper: visit the chop area until no logs remain.
function AF_Hauler.runSweepAndHaul(p, chopArea)
  if not p or not chopArea then return end

  local cell = getCell()
  local z    = chopArea.z or 0
  local x, y = chopArea.minx, chopArea.miny

  local function tick()
    -- If we’re carrying enough, go dump first.
    if not canCarryOneMoreLog(p) then
      if queueSize(p) == 0 then dropAllLogsToPile(p) end
      return -- wait for drop actions to run
    end

    -- If actions are running, don’t add more.
    if queueSize(p) > 0 then return end

    -- Walk the rectangle looking for a single log to grab.
    local grabbed = false
    for yy = y, chopArea.maxy do
      for xx = x, chopArea.maxx do
        local sq = cell:getGridSquare(xx, yy, z)
        if sq and enqueueOneGrabOnSquare(p, sq) then
          x = xx; y = yy  -- resume from here next time
          grabbed = true
          break
        end
      end
      if grabbed then break end
    end

    -- If we didn’t find any logs anywhere, finish by forcing one last drop (if any).
    if not grabbed then
      if queueSize(p) == 0 then dropAllLogsToPile(p) end
      Events.OnTick.Remove(tick)
      AF_Log.info("AutoForester: sweep complete.")
    end
  end

  Events.OnTick.Add(tick)
end

return AF_Hauler
