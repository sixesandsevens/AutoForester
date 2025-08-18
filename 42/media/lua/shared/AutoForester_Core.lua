print("[AutoForester] Core file loading")

local Shared = require("AutoForester_Shared")
local Core = { _queue=nil, _i=0, _busy=false, _lastPulse=0 }

local function dbg(m) print("[AutoForester] "..tostring(m)) end
local function say(p, m) if p and p.Say then p:Say(m) end

function Core.hasStockpile() return Shared and Shared.Stockpile ~= nil end
function Core.setStockpile(sq)
  if not (Shared and sq) then return end
  Shared.setPile(sq)
  dbg(("Stockpile set at %d,%d,%d"):format(sq:getX(), sq:getY(), sq:getZ()))
end
function Core.clearStockpile() Shared.clearPile(); dbg("Stockpile cleared") end

local function squaresAround(sq, r)
  local out, cell, z = {}, getCell(), sq:getZ()
  for dx=-r,r do for dy=-r,r do
    local s = cell:getGridSquare(sq:getX()+dx, sq:getY()+dy, z)
    if s then out[#out+1] = s end
  end end
  return out
end

local function findNearbyTrees(originSq, r)
  local trees = {}
  for _, s in ipairs(squaresAround(originSq, r)) do
    local objs = s:getObjects()
    if objs then
      for i=0, objs:size()-1 do
        local o = objs:get(i)
        if o and instanceof(o, "IsoTree") then trees[#trees+1] = {tree=o, square=s} end
      end
    end
  end
  return trees
end

-- Mini action for inline callbacks in queue
local AFInstant = ISBaseTimedAction:derive("AFInstant")
function AFInstant:isValid() return true end
function AFInstant:waitToStart() return false end
function AFInstant:perform() if self.func then pcall(self.func) end ISBaseTimedAction.perform(self) end
function AFInstant:new(p, fn) local o=ISBaseTimedAction.new(self, p); o.func=fn; o.maxTime=1; return o end

local function queueWalkTo(p, sq)
  if p and sq then ISTimedActionQueue.add(ISWalkToAction:new(p, sq)) end
end

local function queueLootSweep(p, stumpSq, r)
  ISTimedActionQueue.add(AFInstant:new(p, function()
    local cell = getCell()
    for dx=-r,r do for dy=-r,r do
      local s = cell:getGridSquare(stumpSq:getX()+dx, stumpSq:getY()+dy, stumpSq:getZ())
      local wios = s and s:getWorldObjects()
      if wios then
        for i=0, wios:size()-1 do
          local wio = wios:get(i); local it = wio and wio:getItem()
          if it and Shared.ITEM_TYPES[it:getType()] then
            ISTimedActionQueue.add(ISGrabItemAction:new(p, wio, 5))
          end
        end
      end
    end end
  end))
end

local function queueDropAtPile(p)
  local pile = Shared.getPileSquare()
  if not pile then return end
  queueWalkTo(p, pile)
  ISTimedActionQueue.add(AFInstant:new(p, function()
    local items = p:getInventory():getItems()
    for i=items:size()-1,0,-1 do
      local it = items:get(i)
      if it and Shared.ITEM_TYPES[it:getType()] then
        ISTimedActionQueue.add(ISDropItemAction:new(p, it))
      end
    end
    Shared.say(p, "Delivered to wood pile.")
  end))
end

local function step(p)
  Core._lastPulse = (type(getTimestampMs)=="function") and getTimestampMs() or (Core._lastPulse + 1)
  if not Core._queue or Core._i > #Core._queue then
    Core._busy=false; Shared.say(p,"AutoForester complete."); dbg("Job complete"); return
  end
  local job = Core._queue[Core._i]; Core._i = Core._i + 1
  if not (job and job.tree and job.square) then return step(p) end

  dbg(("Step walk→chop @ %d,%d"):format(job.square:getX(), job.square:getY()))
  queueWalkTo(p, job.square)
  ISTimedActionQueue.add(ISChopTreeAction:new(p, job.tree))
  queueLootSweep(p, job.square, Shared.cfg.sweepRadius or 1)
  queueDropAtPile(p)
  ISTimedActionQueue.add(AFInstant:new(p, function() step(p) end))
end

function Core.startJob(p)
  if Core._busy then Shared.say(p,"Already working…"); return end
  if not p then return end
  local origin = p:getSquare(); if not origin then return end
  local trees = findNearbyTrees(origin, Shared.cfg.radius or 12)

  -- cap to avoid 80+ actions on first test
  local cap = 25
  if #trees > cap then
    local t = {}; for i=1,cap do t[i]=trees[i] end; trees=t
  end

  Core._queue, Core._i, Core._busy = trees, 1, true
  Shared.say(p, ("Queued %d tree(s)."):format(#trees)); dbg(("Queued %d tree(s)"):format(#trees))
  local ok, err = pcall(function() step(p) end)
  if not ok then
    Core._busy=false; Core._queue=nil
    print("[AutoForester][ERROR] "..tostring(err)); Shared.say(p, "Error; queue cleared")
  end
end

-- Register watchdog ONLY when Events is ready (fixes 'Add of non-table: null')
local function watchdog()
  if not Core._busy then return end
  local p = getSpecificPlayer and getSpecificPlayer(0)
  if not p then return end
  local q = ISTimedActionQueue.getTimedActionQueue(p)
  local empty = not (q and q.queue and q.queue:size() > 0)
  local now = (type(getTimestampMs)=="function") and getTimestampMs() or 0
  if empty and now and (now - (Core._lastPulse or now)) > 4000 then
    print("[AutoForester] Watchdog: nudging step")
    step(p)
  end
end

local function registerWatchdog()
  if Events and Events.EveryOneSecond and Events.EveryOneSecond.Add then
    Events.EveryOneSecond.Add(watchdog)
    print("[AutoForester] Watchdog registered")
  elseif Events and Events.OnGameStart and Events.OnGameStart.Add then
    Events.OnGameStart.Add(function()
      if Events.EveryOneSecond and Events.EveryOneSecond.Add then
        Events.EveryOneSecond.Add(watchdog)
        print("[AutoForester] Watchdog registered (OnGameStart)")
      end
    end)
  end
end
registerWatchdog()

print("[AutoForester] Core file loaded OK")
return Core
