require "AutoForester_Debug"

function AF_getPlayer(pi)
  if type(pi)=="number" then return getSpecificPlayer(pi) end
  return (getSpecificPlayer and getSpecificPlayer(0)) or getPlayer()
end

require "TimedActions/ISTimedActionQueue"
require "TimedActions/ISWalkToTimedAction"
require "TimedActions/ISChopTreeAction"
require "TimedActions/ISDropItemAction"
require "TimedActions/ISPickupWorldItemAction"

require "AF_DropNowAction"
require "AF_SweepWoodAction"
require "AF_HaulWoodToPileAction"

local Shared = require "AutoForester_Shared"

local Core = AutoChopTask or {}
Core.phase = Core.phase or "idle"  -- "idle" | "chop" | "gather" | "haul"
Core.queue = Core.queue or {}
Core.busy  = false
Core.lastPulseAt = 0

-- Always resolve a valid player object
local function getP(pi)
  if type(pi) == "number" then
    return getSpecificPlayer(pi)
  elseif pi then
    return pi
  end
  return getSpecificPlayer and getSpecificPlayer(0) or getPlayer()
end

local function assertPlayer(p, where)
  if p then return true end
  print(("[AF] %s: player is nil"):format(where or "queue"))
  return false
end

-- Tags for wood-y things (adjust as you like)
local WOOD_TAGS = {
  Log = true, Plank = true, Twig = true, Stick = true, Branch = true, TreeBranch = true
}

function isWood(it)
  if not it then return false end
  if it.hasTag then
    for tag,_ in pairs(WOOD_TAGS) do
      if it:hasTag(tag) then return true end
    end
  end
  local n = (it.getType and it:getType() or ""):lower()
  return n:find("log") or n:find("branch") or n:find("twig") or n:find("plank")
end
Core.isWood = isWood

local function AF_isTreeObject(obj)
  if not obj then return false end
  if instanceof and instanceof(obj, "IsoTree") then return true end
  local spr = obj.getSprite and obj:getSprite() or nil
  local name = spr and spr:getName() or ""
  if name == "" then return false end
  name = name:lower()
  return name:find("tree_") or name:find("f_tr") or name:find("vegetation_tree")
end

local function AF_squareHasTree(sq)
  if not sq then return false end
  local objs = sq:getObjects()
  if not objs then return false end
  for i=0, objs:size()-1 do
    local o = objs:get(i)
    if AF_isTreeObject(o) then return true end
  end
  return false
end

local function AF_findNearbyTrees(originSq, radius)
  local out = {}
  if not originSq then AFLOG("findNearbyTrees: origin=nil"); return out end
  local r = tonumber(radius) or 12
  local ox,oy,oz = originSq:getX(), originSq:getY(), originSq:getZ()
  local cell = getCell()
  local countSq, countHit = 0,0

  for y=oy-r, oy+r do
    for x=ox-r, ox+r do
      local sq = cell:getGridSquare(x,y,oz)
      countSq = countSq + 1
      if sq and AF_squareHasTree(sq) then
        table.insert(out, sq)
        countHit = countHit + 1
        if AF_DEBUG and countHit <= 6 then AF_LIST_SQ_OBJS(sq, "nearby-hit") end
      end
    end
  end
  AFLOG("findNearbyTrees:", "visited", countSq, "hit", countHit, "radius", r)
  return out
end

local function AF_buildTreeQueueFromRect(rect)
  local list = {}
  if not rect then AFLOG("buildFromRect: rect=nil"); return list end
  local x1,y1,x2,y2,z = rect[1],rect[2],rect[3],rect[4],rect[5] or 0
  if not x1 or not y1 or not x2 or not y2 then
    AFLOG("buildFromRect: bad bounds", tostring(rect))
    return list
  end
  local cell = getCell()
  local hits=0
  for y=y1,y2 do
    for x=x1,x2 do
      local sq = cell:getGridSquare(x,y,z)
      if sq and AF_squareHasTree(sq) then
        table.insert(list, sq)
        hits = hits + 1
        if AF_DEBUG and hits <= 6 then AF_LIST_SQ_OBJS(sq, "rect-hit") end
      end
    end
  end
  AFLOG("buildFromRect:", x1,y1,"→",x2,y2,"hits", hits)
  return list
end

-- Drop everything wooden at the player's feet (fast)
function dropWoodNow()
  local p = AutoChopTask and AutoChopTask.player or AF_getPlayer()
  if not p then AFLOG("TA queue: no player"); return end
  local inv = p:getInventory()
  local items = inv:getItems()
  for i = items:size()-1, 0, -1 do
    local it = items:get(i)
    if isWood(it) then
      ISTimedActionQueue.add(ISDropItemAction:new(p, it)) -- drop at feet
    end
  end
end
Core.dropWoodNow = dropWoodNow

local function queueWalkTo(sq)
  local p = AutoChopTask and AutoChopTask.player or AF_getPlayer()
  if not p then AFLOG("TA queue: no player"); return end
  if not sq then return end
  ISTimedActionQueue.add(ISWalkToTimedAction:new(p, sq))
end

-- after chopping a tree at sq
local function queueChopTree(sq)
  local p = AutoChopTask and AutoChopTask.player or AF_getPlayer()
  if not p then AFLOG("TA queue: no player"); return end
  if not sq then return end
  queueWalkTo(sq)
  ISTimedActionQueue.add(ISChopTreeAction:new(p, sq))
  ISTimedActionQueue.add(AF_DropNowAction:new(p))
end

local function playerQueueEmpty(p)
  if not assertPlayer(p, "playerQueueEmpty") then return true end
  return ISTimedActionQueue.getTimedActionQueue(p) == nil
end

local function setPhase(ph)
  Core.phase = ph
  Core.busy = false
  if ph == "idle" then Core.player = nil end
end

function Core.startChop(originSq)
  Core.queue = AF_buildTreeQueueFromRect(Core.chopRect)
  AFLOG(("ChopQueue size = %d"):format(#Core.queue))
  if #Core.queue == 0 then
    local p = Core.player or getP()
    if p and p.Say then p:Say("No trees in chop area.") end
    return
  end
  setPhase("chop")
end

local function stepChop(p)
  if #Core.queue == 0 then
    setPhase("gather")
    return
  end
  local sq = table.remove(Core.queue, 1)
  Core.busy = true
  queueChopTree(sq)
end

local function refillGatherQueueFromRect(rect)
  Core.queue = {}
  if not rect then return end
  local x1,y1,x2,y2,z = table.unpack(rect)
  local cell = getCell()
  for y=y1,y2 do
    for x=x1,x2 do
      local sq = cell:getGridSquare(x,y,z)
      if sq then table.insert(Core.queue, sq) end
    end
  end
end

local function queueLootSweep(areaRect)
  local p = AutoChopTask and AutoChopTask.player or AF_getPlayer()
  if not p then AFLOG("TA queue: no player"); return end
  ISTimedActionQueue.add(AF_SweepWoodAction:new(p, areaRect))
end

local function queueHaulToPile(pileSq)
  local p = AutoChopTask and AutoChopTask.player or AF_getPlayer()
  if not p then AFLOG("TA queue: no player"); return end
  ISTimedActionQueue.add(AF_HaulWoodToPileAction:new(p, pileSq))
end

local function stepGather(p)
  Core.busy = true
  queueLootSweep(Core.gatherRect or Core.chopRect)
end

local function stepHaul(p)
  Core.busy = true
  local pileSq = Shared.getPileSquare()
  if not pileSq then
    setPhase("idle")
    if p and p.Say then p:Say("No log stockpile set.") end
    return
  end
  queueHaulToPile(pileSq)
end

function Core.pulse()
  local p = Core.player or getP()
  if not assertPlayer(p, "pulse") then return end
  if not playerQueueEmpty(p) then return end

  Core.busy = false
  if Core.phase == "chop"   then stepChop(p)
  elseif Core.phase == "gather" then stepGather(p); setPhase("haul")
  elseif Core.phase == "haul"   then stepHaul(p);   setPhase("idle")
  else
    -- idle
  end
end

function Core.startJob_playerRadius(pi, radius)
  local p = AF_getPlayer(pi)
  if not p then AFLOG("startJob_playerRadius: no player"); return end
  local sq = p:getSquare()
  if not sq then AFLOG("startJob_playerRadius: player sq=nil"); return end

  AutoChopTask = AutoChopTask or {}
  AutoChopTask.player = p
  AutoChopTask.phase  = "chop"
  AutoChopTask.queue  = AF_findNearbyTrees(sq, radius)

  AFSAY(p, string.format("Found %d tree(s).", #AutoChopTask.queue))
  AF_DUMP("start:nearby")
  Core.pulse()
end

function Core.startChopFromRect(pi)
  local p = AF_getPlayer(pi)
  if not p then AFLOG("startChopFromRect: no player"); return end
  if not (AutoChopTask and AutoChopTask.chopRect) then
    AFLOG("startChopFromRect: rect=nil"); return
  end
  AutoChopTask.player = p
  AutoChopTask.phase  = "chop"
  AutoChopTask.queue  = AF_buildTreeQueueFromRect(AutoChopTask.chopRect)
  AFSAY(p, string.format("Chop area: %d tree(s).", #AutoChopTask.queue))
  AF_DUMP("start:rect")
  Core.pulse()
end

function Core.startJob(pOrIndex)
  local p = type(pOrIndex)=="number" and getP(pOrIndex) or pOrIndex or getP()
  if not p then AFLOG("startJob: NO PLAYER"); return end

  AutoChopTask = AutoChopTask or {}
  AutoChopTask.player = p
  AutoChopTask.phase  = "chop"
  AF_DUMP("startJob")
  Core.startChop(p:getSquare())
  Core.pulse()
end

function Core.cancel()
  Core.queue = {}
  setPhase("idle")
end

function Core.hasStockpile()
  return Shared.getPileSquare() ~= nil
end

function Core.SetStockpile(sq)
  if sq then Shared.setPile(sq) end
end

Core.setStockpile = Core.SetStockpile

function Core.clearStockpile()
  Shared.clearPile()
end

function Core.register()
  if Events and Events.EveryFewSeconds and Events.EveryFewSeconds.Add then
    Events.EveryFewSeconds.Add(function() Core.pulse() end)
  end
end

AutoChopTask = Core
Core.getP = getP
return Core

