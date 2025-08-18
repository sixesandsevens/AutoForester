-- AutoForester Core (B42) – must return a table
print("[AutoForester] Core file loading")

local Shared = require("AutoForester_Shared")
local AFCore = {
  _queue = nil, _index = 0, _busy = false, _lastPulse = 0
}

local function dbg(msg) print("[AutoForester] "..tostring(msg)) end
local function say(p, s) if p and p.Say then p:Say(s) end end

function AFCore.hasStockpile() return Shared and Shared.Stockpile ~= nil end
function AFCore.setStockpile(square)
  if not (Shared and square) then return end
  Shared.Stockpile = { x = square:getX(), y = square:getY(), z = square:getZ() }
  dbg(("Stockpile set @ %d,%d,%d"):format(Shared.Stockpile.x, Shared.Stockpile.y, Shared.Stockpile.z))
end
function AFCore.clearStockpile() if Shared then Shared.Stockpile = nil end dbg("Stockpile cleared") end

local function findNearbyTrees(player, r)
  local out = {}
  if not (player and player.getSquare) then return out end
  local sq = player:getSquare(); if not sq then return out end
  local cell, z = getCell(), sq:getZ()
  for dx=-r,r do for dy=-r,r do
    local gs = cell:getGridSquare(sq:getX()+dx, sq:getY()+dy, z)
    if gs then
      local objs = gs:getObjects()
      if objs then
        for i=0, objs:size()-1 do
          local o = objs:get(i)
          if o and instanceof(o, "IsoTree") then table.insert(out, {tree=o, square=gs}) end
        end
      end
    end
  end end
  return out
end

local AFInstantAction = ISBaseTimedAction:derive("AFInstantAction")
function AFInstantAction:isValid() return true end
function AFInstantAction:waitToStart() return false end
function AFInstantAction:perform() if self.func then pcall(self.func) end ISBaseTimedAction.perform(self) end
function AFInstantAction:new(player, func) local o=ISBaseTimedAction.new(self, player); o.func=func; o.maxTime=1; return o end

local function queueWalkTo(p, sq) if p and sq then ISTimedActionQueue.add(ISWalkToAction:new(p, sq)) end end
local function dropAllWood(p)
  local inv = p and p:getInventory(); if not inv then return end
  local items = inv:getItems()
  for i=items:size()-1,0,-1 do
    local it = items:get(i)
    if it and Shared.ITEM_TYPES[it:getType()] then ISTimedActionQueue.add(ISDropItemAction:new(p, it)) end
  end
end
local function pileSquare()
  local sp = Shared and Shared.Stockpile; if not sp then return nil end
  return getCell():getGridSquare(sp.x, sp.y, sp.z)
end

local function step(p)
  AFCore._lastPulse = getTimestampMs and getTimestampMs() or (AFCore._lastPulse + 1)
  if not AFCore._queue or AFCore._index > #AFCore._queue then
    AFCore._busy=false; say(p,"AutoForester complete."); dbg("Job complete"); return
  end
  local job = AFCore._queue[AFCore._index]; AFCore._index = AFCore._index + 1
  if not (job and job.tree and job.square) then dbg("Skip invalid job"); return step(p) end

  dbg(("Step: walk→chop @ %d,%d"):format(job.square:getX(), job.square:getY()))
  queueWalkTo(p, job.square)
  ISTimedActionQueue.add(ISChopTreeAction:new(p, job.tree))

  local r=1
  ISTimedActionQueue.add(AFInstantAction:new(p, function()
    dbg("Sweep for drops")
    local cell = getCell()
    for dx=-r,r do for dy=-r,r do
      local s = cell:getGridSquare(job.square:getX()+dx, job.square:getY()+dy, job.square:getZ())
      local wios = s and s:getWorldObjects()
      if wios then
        for i=0,wios:size()-1 do
          local wio = wios:get(i); local item = wio and wio:getItem()
          if item and Shared.ITEM_TYPES[item:getType()] then
            ISTimedActionQueue.add(ISGrabItemAction:new(p, wio, 5))
          end
        end
      end
    end end
  end))

  local pile = pileSquare()
  if pile then
    dbg("Walk to pile & drop")
    queueWalkTo(p, pile)
    ISTimedActionQueue.add(AFInstantAction:new(p, function() dropAllWood(p) end))
  end

  ISTimedActionQueue.add(AFInstantAction:new(p, function() step(p) end))
end

function AFCore.startJob(p)
  if AFCore._busy then say(p,"Already working…"); dbg("Start blocked: busy"); return end
  if not p then dbg("No player"); return end
  local list = findNearbyTrees(p, 8)
  AFCore._queue, AFCore._index, AFCore._busy = list, 1, true
  say(p, ("Queued %d tree(s)."):format(#list))
  dbg(("Queued %d tree(s)"):format(#list))
  local ok, err = pcall(function() step(p) end)
  if not ok then
    AFCore._busy=false; AFCore._queue=nil; print("[AutoForester][ERROR] "..tostring(err)); say(p, "Error; queue cleared")
  end
end

local function watchdog()
  if not AFCore._busy then return end
  local p = getSpecificPlayer(0); if not p then return end
  local q = ISTimedActionQueue.getTimedActionQueue(p)
  local empty = not (q and q.queue and q.queue:size()>0)
  local now = getTimestampMs and getTimestampMs() or 0
  if empty and now and (now - (AFCore._lastPulse or now)) > 4000 then
    print("[AutoForester] Watchdog: nudging step")
    step(p)
  end
end
Events.EveryOneSecond.Add(watchdog)

print("[AutoForester] Core file loaded OK")
return AFCore
