-- AutoForester_Core.lua: task orchestration for chopping and gathering wood

require "TimedActions/ISTimedActionQueue"
require "TimedActions/ISWalkToTimedAction"
require "TimedActions/ISChopTreeAction"
require "TimedActions/ISDropItemAction"
require "TimedActions/ISAIFinalizeAction"
require "TimedActions/ISPickupWorldItemAction"

local Shared = require "AutoForester_Shared"

local Core = {
  trees = {},
  phase = "IDLE",
  idleTicks = 0
}

-- ===== item helpers =====
local function isWood(it)
  if not it or not it.getFullType then return false end
  local ft = it:getFullType()
  return ft == "Base.Log" or ft == "Base.TreeBranch" or ft == "Base.Twigs" or ft == "Base.Stone"
end

local function queueDropOnGround(p)
  local inv = p and p:getInventory()
  if not inv then return end
  local items = inv:getItems()
  for i = items:size() - 1, 0, -1 do
    local it = items:get(i)
    if isWood(it) then
      ISTimedActionQueue.add(ISDropItemAction:new(p, it))
    end
  end
end

local function inRect(sq, rect)
  if not sq or not rect then return false end
  local x1, y1, x2, y2 = rect[1], rect[2], rect[3], rect[4]
  return sq:getX() >= x1 and sq:getX() <= x2 and sq:getY() >= y1 and sq:getY() <= y2
end

local function queueLootSweep(p, rect)
  if not p or not rect then return end
  ISTimedActionQueue.add(ISAIFinalizeAction:new(p, function()
    local cell = getCell()
    for x = rect[1], rect[3] do
      for y = rect[2], rect[4] do
        local sq = cell:getGridSquare(x, y, rect[5] or 0)
        if sq then
          local wios = sq:getWorldObjects()
          for i = 0, wios:size() - 1 do
            local wio = wios:get(i)
            local it = wio and wio:getItem()
            if it and isWood(it) then
              ISTimedActionQueue.add(ISPickupWorldItemAction:new(p, it, x, y, sq:getZ()))
            end
          end
        end
      end
    end
  end))
end

local function queueDropAtPile(p)
  local pileSq = Shared.getPileSquare()
  if not p or not pileSq then return end
  ISTimedActionQueue.add(ISWalkToTimedAction:new(p, pileSq))
  ISTimedActionQueue.add(ISAIFinalizeAction:new(p, function()
    local items = p:getInventory():getItems()
    for i = items:size() - 1, 0, -1 do
      local it = items:get(i)
      if isWood(it) then
        ISTimedActionQueue.add(ISWorldObjectContextMenu.dropItemAtSquare(p, it, pileSq))
      end
    end
  end))
end

local function startGatherPhase(p)
  if not AutoChopTask or not AutoChopTask.gatherRect then
    p:Say("No gather area. Use 'Gather Area: Set Corner'.")
    return
  end
  queueLootSweep(p, AutoChopTask.gatherRect)
  queueDropAtPile(p)
end

-- ===== tree helpers =====
local function squaresAround(sq, r)
  local out, cell, z = {}, getCell(), sq:getZ()
  for dx = -r, r do
    for dy = -r, r do
      local s = cell:getGridSquare(sq:getX() + dx, sq:getY() + dy, z)
      if s then out[#out + 1] = s end
    end
  end
  return out
end

local function findNearbyTrees(originSq, r)
  local trees = {}
  for _, s in ipairs(squaresAround(originSq, r)) do
    local objs = s:getObjects()
    if objs then
      for i = 0, objs:size() - 1 do
        local o = objs:get(i)
        if o and instanceof(o, "IsoTree") then
          trees[#trees + 1] = { tree = o, square = s }
        end
      end
    end
  end
  return trees
end

function Core.startJob_playerRadius(p, radius)
  if Core.phase ~= "IDLE" then p:Say("Already working… please wait."); return end
  local origin = p:getSquare(); if not origin then return end
  Core.trees = findNearbyTrees(origin, radius or 12)
  Core.phase = "CHOP"
  Core.idleTicks = 0
end

function Core.popNextTree()
  return table.remove(Core.trees, 1)
end

function Core.queueWalkTo(p, tree)
  if not tree then return end
  ISTimedActionQueue.add(ISWalkToTimedAction:new(p, tree.square))
end

function Core.queueChop(p, tree)
  if not tree then return end
  ISTimedActionQueue.add(ISChopTreeAction:new(p, tree.tree))
end

local function playerIdle(p)
  local q = ISTimedActionQueue.getTimedActionQueue(p)
  return not (q and q.queue and q.queue:size() > 0)
end

function Core.step()
  local p = getPlayer()
  if not p then return end
  if Core.phase == "CHOP" then
    if playerIdle(p) then
      local nextTree = Core.popNextTree()
      if nextTree then
        Core.queueWalkTo(p, nextTree)
        Core.queueChop(p, nextTree)
        queueDropOnGround(p)
      else
        Core.phase = "GATHER"
      end
    end
    if p:getInventory():getCapacityWeight() > p:getMaxWeight() then
      queueDropOnGround(p)
    end
  elseif Core.phase == "GATHER" then
    if playerIdle(p) then
      startGatherPhase(p)
      Core.phase = "DONE"
    end
  end
end

function Core.cancel()
  Core.trees = {}
  Core.phase = "IDLE"
  Core.idleTicks = 0
end

function Core.dumpState()
  print(string.format("[AutoForester] phase=%s trees=%d idle=%d", Core.phase, #Core.trees, Core.idleTicks))
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
  if Events and Events.OnPlayerUpdate and Events.OnPlayerUpdate.Add then
    Events.OnPlayerUpdate.Add(function() Core.step() end)
  end
end

return Core

