local Core = AutoForester_Core or {}
local Debug = AutoForester_Debug or { on=false, log=function() end }

require "TimedActions/ISTimedActionQueue"
require "TimedActions/ISWalkToTimedAction"
require "TimedActions/ISChopTreeAction"
require "TimedActions/ISDropItemAction"
require "TimedActions/ISPickupWorldItemAction"

local Shared = require "AutoForester_Shared"

local function isTree(o)
  -- B42-safe: accept IsoTree or anything with type name containing 'Tree'
  return (o and (instanceof and instanceof(o, "IsoTree"))) or
         (o and o.getType and tostring(o:getType()):lower():find("tree", 1, true))
end

local function squareHasTree(sq)
  if not sq then return false end
  local objs = sq:getObjects(); if not objs then return false end
  for i=0, objs:size()-1 do if isTree(objs:get(i)) then return true end end
  return false
end

local function buildTreeQueueFromRect(rect)
  local x1,y1,x2,y2,z = rect[1],rect[2],rect[3],rect[4],rect[5] or 0
  local cell = getCell(); if not cell then return {} end
  local q = {}
  for x=x1,x2 do
    for y=y1,y2 do
      local sq = cell:getGridSquare(x,y,z)
      if squareHasTree(sq) then table.insert(q, sq) end
    end
  end
  return q
end

local function queueWalkTo(p, sq)
  if p and sq then ISTimedActionQueue.add(ISWalkToTimedAction:new(p, sq)) end
end

local function queueDropTreeLootHere(p)
  -- Immediately drop heavy tree loot at player feet (the tree square)
  local inv = p:getInventory()
  local TYPES = { "Log","Twigs","TreeBranch","Plank" }
  for _,t in ipairs(TYPES) do
    local list = inv:getItemsFromType(t, true, true)
    for i=0,list:size()-1 do
      ISTimedActionQueue.add(ISDropItemAction:new(p, list:get(i)))
    end
  end
end

local function queueChopTreeOnSquare(p, sq)
  -- Walk then use the same action the vanilla context menu uses
  queueWalkTo(p, sq)
  -- B42 ships ISCutdownTreeAction; but call through the right-click command:
  ISTimedActionQueue.add(ISChopTreeAction:new(p, sq))  -- if your project uses another name, keep your working one
  -- After action, drop logs immediately:
  ISTimedActionQueue.add(AFInstant:new(p, function() queueDropTreeLootHere(p) end))
end

local function iterateWorldItems(rect, fn)
  local x1,y1,x2,y2,z = rect[1],rect[2],rect[3],rect[4],rect[5] or 0
  local cell = getCell(); if not cell then return end
  for x=x1,x2 do
    for y=y1,y2 do
      local sq = cell:getGridSquare(x,y,z)
      if sq then
        local wios = sq:getWorldObjects()
        for i=0,wios:size()-1 do
          local wio = wios:get(i); local it = wio and wio:getItem()
          if it then fn(sq, it) end
        end
      end
    end
  end
end

local function queueLootSweep(p, rect)
  iterateWorldItems(rect, function(sq, it)
    local name = it:getType() or ""
    if Shared.ITEM_TYPES[name] then
      queueWalkTo(p, sq)
      ISTimedActionQueue.add(ISPickupWorldItemAction:new(p, it, sq:getX(), sq:getY(), sq:getZ()))
    end
  end)
end

local function queueHaulToPile(p)
  local pileSq = Shared.getPileSquare(); if not pileSq then return end
  queueWalkTo(p, pileSq)
  ISTimedActionQueue.add(AFInstant:new(p, function()
    queueDropTreeLootHere(p)
    p:Say("Delivered to wood pile.")
  end))
end

function Core.startJob_fromRects(p, chopRect, gatherRect)
  local q = buildTreeQueueFromRect(chopRect)
  if Debug.on then Debug.log("startJob_fromRects trees=%d", #q) end
  if #q == 0 then p:Say("No trees in chop area."); return end

  -- Phase 1: chop & drop
  for _,sq in ipairs(q) do queueChopTreeOnSquare(p, sq) end

  -- Phase 2: gather (default to chopRect if gatherRect missing)
  local gRect = gatherRect or chopRect
  ISTimedActionQueue.add(AFInstant:new(p, function() p:Say("Gathering…") end))
  queueLootSweep(p, gRect)

  -- Phase 3: haul to pile
  queueHaulToPile(p)
end

function Core.hasWoodPile()
  return Shared.getPileSquare() ~= nil
end

AutoForester_Core = Core
return Core
