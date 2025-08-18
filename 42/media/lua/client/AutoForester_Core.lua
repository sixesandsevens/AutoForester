-- B42 TimedAction classes (explicit requires to guarantee globals exist here)
require "TimedActions/ISBaseTimedAction"
require "TimedActions/ISTimedActionQueue"
require "TimedActions/ISWalkToTimedAction"
require "TimedActions/ISChopTreeAction"     -- we use this later after walking
require "TimedActions/ISGrabItemAction"
require "TimedActions/ISDropItemAction"

print("[AutoForester] Core file loading")

local Shared = require "AutoForester_Shared"
local Core = { _queue=nil, _i=0, _busy=false, _lastPulse=0 }

local function dbg(m) print("[AutoForester] "..tostring(m)) end

local AFInstant = ISBaseTimedAction:derive("AFInstant")
function AFInstant:isValid() return true end
function AFInstant:waitToStart() return false end
function AFInstant:perform() if self.func then pcall(self.func) end ISBaseTimedAction.perform(self) end
function AFInstant:new(p, fn) local o=ISBaseTimedAction.new(self, p); o.func=fn; o.maxTime=1; return o end

local function squaresAround(sq, r)
  local out, cell, z = {}, getCell(), sq:getZ()
  for dx=-r,r do for dy=-r,r do
    local s = cell:getGridSquare(sq:getX()+dx, sq:getY()+dy, z)
    if s then out[#out+1]=s end
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

-- Walk the player to a square; returns true if we queued a walk
local function queueWalkTo(p, sq)
    if not p or not sq then return false end

    -- Safety: make sure class globals are really present
    if not ISTimedActionQueue or not ISWalkToTimedAction then
        print("[AutoForester][ERROR] TimedAction classes not loaded (ISTimedActionQueue/ISWalkToTimedAction nil)")
        return false
    end

    -- B42 accepts the square directly
    local ok, err = pcall(function()
        ISTimedActionQueue.add(ISWalkToTimedAction:new(p, sq))
    end)

    if not ok then
        print("[AutoForester][ERROR] queueWalkTo failed: "..tostring(err))
        return false
    end
    return true
end

local function queueChop(p, tree)
    if not p or not tree then return false end
    if not ISTimedActionQueue or not ISChopTreeAction then
        print("[AutoForester][ERROR] TimedAction classes not loaded (ISTimedActionQueue/ISChopTreeAction nil)")
        return false
    end

    local ok, err = pcall(function()
        -- ISChopTreeAction:new(character, tree) in B42 (no time arg needed; engine sets it)
        ISTimedActionQueue.add(ISChopTreeAction:new(p, tree))
    end)

    if not ok then
        print("[AutoForester][ERROR] queueChop failed: "..tostring(err))
        return false
    end
    return true
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
  local pile = Shared.getPileSquare(); if not pile then return end
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
  if not queueWalkTo(p, job.square) then
    p:Say("Could not start walk; actions unavailable.")
    Core._queue, Core._busy = nil, false
    return
  end
  if not queueChop(p, job.tree) then
    p:Say("Could not start chop; actions unavailable.")
    Core._queue, Core._busy = nil, false
    return
  end
  queueLootSweep(p, job.square, Shared.cfg.sweepRadius or 1)
  queueDropAtPile(p)
  ISTimedActionQueue.add(AFInstant:new(p, function() step(p) end))
end

function Core.hasStockpile() return Shared.Stockpile ~= nil end
function Core.setStockpile(sq) if sq then Shared.setPile(sq); print("[AutoForester] pile set") end end
function Core.clearStockpile() Shared.clearPile(); print("[AutoForester] pile cleared") end

function Core.startJob(p)
  if Core._busy then Shared.say(p,"Already working…"); return end
  if not p then return end
  local origin = p:getSquare(); if not origin then return end
  local trees = findNearbyTrees(origin, Shared.cfg.radius or 12)
  local cap = 25; if #trees > cap then local t={}; for i=1,cap do t[i]=trees[i] end; trees=t end
  Core._queue, Core._i, Core._busy = trees, 1, true
  Shared.say(p, ("Queued %d tree(s)."):format(#trees)); print("[AutoForester] queued "..#trees)
  local ok, err = pcall(function() step(p) end)
  if not ok then Core._busy=false; Core._queue=nil; print("[AutoForester][ERROR] "..tostring(err)); Shared.say(p, "Error; queue cleared") end
end

-- Watchdog – registered by Boot when Events exists
local function watchdog()
  if not Core._busy then return end
  local p = getSpecificPlayer and getSpecificPlayer(0); if not p then return end
  local q = ISTimedActionQueue.getTimedActionQueue(p)
  local empty = not (q and q.queue and q.queue:size() > 0)
  local now = (type(getTimestampMs)=="function") and getTimestampMs() or 0
  if empty and now and (now - (Core._lastPulse or now)) > 4000 then
    print("[AutoForester] Watchdog nudged")
    step(p)
  end
end

function Core.register()
  if Events and Events.EveryOneSecond and Events.EveryOneSecond.Add then
    Events.EveryOneSecond.Add(watchdog)
    print("[AutoForester] Watchdog registered")
  else
    print("[AutoForester][WARN] EveryOneSecond not ready; deferring to OnGameStart")
    if Events and Events.OnGameStart and Events.OnGameStart.Add then
      Events.OnGameStart.Add(function()
        if Events.EveryOneSecond and Events.EveryOneSecond.Add then
          Events.EveryOneSecond.Add(watchdog)
          print("[AutoForester] Watchdog registered (deferred)")
        end
      end)
    end
  end
end

print("[AutoForester] Core file loaded OK")
return Core
