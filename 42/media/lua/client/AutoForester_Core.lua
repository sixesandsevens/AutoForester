-- AutoForester_Core.lua
-- Revised core logic with explicit phases for chopping, gathering, and hauling

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

-- Drop everything wooden at the player's feet (fast)
function dropWoodNow(p)
  if not assertPlayer(p, "dropWoodNow") then return end
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

local function queueWalkTo(p, sq)
  if not assertPlayer(p, "queueWalkTo") or not sq then return end
  ISTimedActionQueue.add(ISWalkToTimedAction:new(p, sq))
end

-- after chopping a tree at sq
local function queueChopTree(p, sq)
  if not assertPlayer(p, "queueChopTree") or not sq then return end
  queueWalkTo(p, sq)
  ISTimedActionQueue.add(ISChopTreeAction:new(p, sq))
  -- Immediately drop wood to the ground to avoid overweight
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

local function refillChopQueueFromRect(rect, originSq)
  Core.queue = {}
  if not rect then return end
  local x1,y1,x2,y2,z = table.unpack(rect)
  local cell = getCell()
  for y=y1,y2 do
    for x=x1,x2 do
      local sq = cell:getGridSquare(x,y,z)
      if sq then
        local objs = sq:getObjects()
        if objs then
          for i=0,objs:size()-1 do
            local o = objs:get(i)
            if o and instanceof(o, "IsoTree") then table.insert(Core.queue, sq) break end
          end
        end
      end
    end
  end
end

function Core.startChop(originSq)
  refillChopQueueFromRect(Core.chopRect, originSq)
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
  queueChopTree(p, sq)
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

local function queueLootSweep(p, areaRect)
  if not assertPlayer(p, "queueLootSweep") then return end
  -- walk every square, pick all wood from ground containers to inventory
  ISTimedActionQueue.add(AF_SweepWoodAction:new(p, areaRect))
end

local function queueHaulToPile(p, pileSq)
  if not assertPlayer(p, "queueHaulToPile") then return end
  ISTimedActionQueue.add(AF_HaulWoodToPileAction:new(p, pileSq))
end

local function stepGather(p)
  Core.busy = true
  queueLootSweep(p, Core.gatherRect or Core.chopRect)
end

local function stepHaul(p)
  Core.busy = true
  local pileSq = Shared.getPileSquare()
  if not pileSq then
    setPhase("idle")
    if p and p.Say then p:Say("No log stockpile set.") end
    return
  end
  queueHaulToPile(p, pileSq)
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

function Core.startJob_playerRadius(playerOrIndex, radius)
  local p = getP(playerOrIndex)
  if not assertPlayer(p, "startJob_playerRadius") then return end
  Core.player = p
  local sq = p:getSquare(); if not sq then return end
  radius = radius or 12
  Core.chopRect = {sq:getX()-radius, sq:getY()-radius, sq:getX()+radius, sq:getY()+radius, sq:getZ()}
  Core.startChop(sq)
end

function Core.cancel()
  Core.queue = {}
  setPhase("idle")
end

function Core.hasStockpile()
  return Shared.getPileSquare() ~= nil
end

function Core.setStockpile(sq)
  if sq then Shared.setPile(sq) end
end

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

