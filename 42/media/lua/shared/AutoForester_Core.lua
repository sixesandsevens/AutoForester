-- AutoForester Core (B42) – shared so client/server can see it
local Shared = require("AutoForester_Shared")

local AFCore = {
  _queue = nil,
  _index = 0,
  _busy  = false,
  _lastPulse = 0,
}

local function dbg(msg) print("[AutoForester] "..tostring(msg)) end

-- Public API
function AFCore.hasStockpile()
  return Shared and Shared.Stockpile ~= nil
end

function AFCore.setStockpile(square)
  if not Shared then return end
  if not square then return end
  Shared.Stockpile = { x = square:getX(), y = square:getY(), z = square:getZ() }
  dbg(("Stockpile set at %d,%d,%d"):format(Shared.Stockpile.x, Shared.Stockpile.y, Shared.Stockpile.z))
end

function AFCore.clearStockpile()
  if not Shared then return end
  Shared.Stockpile = nil
  dbg("Stockpile cleared")
end

-- Collect nearby trees (simple sweep; we can tune later)
local function findNearbyTrees(player, radius)
  local out = {}
  if not player then return out end
  local cell = getCell()
  local sq = player:getSquare()
  if not sq then return out end
  local z = sq:getZ()
  for dx = -radius, radius do
    for dy = -radius, radius do
      local gs = cell:getGridSquare(sq:getX()+dx, sq:getY()+dy, z)
      if gs then
        local objs = gs:getObjects()
        if objs then
          for i=0, objs:size()-1 do
            local o = objs:get(i)
            if o and instanceof(o, "IsoTree") then table.insert(out, { tree=o, square=gs }) end
          end
        end
      end
    end
  end
  return out
end

-- Tiny instant action to chain logic inside the queue
local AFInstantAction = ISBaseTimedAction:derive("AFInstantAction")
function AFInstantAction:isValid() return true end
function AFInstantAction:waitToStart() return false end
function AFInstantAction:update() end
function AFInstantAction:start() end
function AFInstantAction:stop() ISBaseTimedAction.stop(self) end
function AFInstantAction:perform()
  if self.func then pcall(self.func) end
  ISBaseTimedAction.perform(self)
end
function AFInstantAction:new(player, func)
  local o = ISBaseTimedAction.new(self, player)
  o.func = func
  o.maxTime = 1
  return o
end

local function queueWalkTo(player, targetSq)
  if not player or not targetSq then return end
  ISTimedActionQueue.add(ISWalkToAction:new(player, targetSq))
end

local function dropAllWood(player)
  local inv = player and player:getInventory()
  if not inv then return end
  local items = inv:getItems()
  for i = items:size()-1, 0, -1 do
    local it = items:get(i)
    if it and Shared.ITEM_TYPES[it:getType()] then
      ISTimedActionQueue.add(ISDropItemAction:new(player, it))
    end
  end
end

local function getStockpileSquare()
  local sp = Shared and Shared.Stockpile
  if not sp then return nil end
  return getCell():getGridSquare(sp.x, sp.y, sp.z)
end

local function step(player)
  AFCore._lastPulse = getTimestampMs and getTimestampMs() or (AFCore._lastPulse + 1)
  if not AFCore._queue or AFCore._index > #AFCore._queue then
    AFCore._busy = false
    if player and player.Say then player:Say("AutoForester job complete.") end
    return
  end

  local job = AFCore._queue[AFCore._index]
  AFCore._index = AFCore._index + 1

  if not job or not job.tree or not job.square then
    step(player)
    return
  end

  -- Walk → Chop → Pickup → Deliver → Continue
  queueWalkTo(player, job.square)
  ISTimedActionQueue.add(ISChopTreeAction:new(player, job.tree))

  local radius = 1
  ISTimedActionQueue.add(AFInstantAction:new(player, function()
    local drops = {}
    local cell = getCell()
    for dx=-radius,radius do
      for dy=-radius,radius do
        local s = cell:getGridSquare(job.square:getX()+dx, job.square:getY()+dy, job.square:getZ())
        local wios = s and s:getWorldObjects()
        if wios then
          for i=0,wios:size()-1 do
            local wio = wios:get(i)
            local item = wio and wio:getItem()
            if item and Shared.ITEM_TYPES[item:getType()] then
              ISTimedActionQueue.add(ISGrabItemAction:new(player, wio, 5))
            end
          end
        end
      end
    end
  end))

  local pile = getStockpileSquare()
  if pile then
    queueWalkTo(player, pile)
    ISTimedActionQueue.add(AFInstantAction:new(player, function() dropAllWood(player) end))
  end

  ISTimedActionQueue.add(AFInstantAction:new(player, function() step(player) end))
end

function AFCore.startJob(player)
  if not player then return end
  if AFCore._busy then
    if player.Say then player:Say("Already working, please wait.") end
    return
  end
  local trees = findNearbyTrees(player, 8) -- radius; can be made configurable
  AFCore._queue = trees
  AFCore._index = 1
  AFCore._busy = true
  if player.Say then player:Say(("Queued %d tree(s)."):format(#trees)) end
  local ok, err = pcall(function() step(player) end)
  if not ok then
    AFCore._busy = false
    AFCore._queue = nil
    print("[AutoForester][ERROR] "..tostring(err))
    if player.Say then player:Say("AutoForester error; queue cleared.") end
  end
end

-- Watchdog to prevent “busy but idle” dead-locks
local function watchdog()
  if not AFCore._busy then return end
  local p = getSpecificPlayer(0)
  if not p then return end
  local q = ISTimedActionQueue.getTimedActionQueue(p)
  local empty = not (q and q.queue and q.queue:size() > 0)
  local now = getTimestampMs and getTimestampMs() or 0
  if empty and now and (now - (AFCore._lastPulse or now)) > 4000 then
    print("[AutoForester] Watchdog pulse: advancing")
    step(p)
  end
end
Events.EveryOneSecond.Add(watchdog)

return AFCore
