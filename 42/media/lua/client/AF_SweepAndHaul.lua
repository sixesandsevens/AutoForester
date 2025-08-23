-- media/lua/client/AF_SweepAndHaul.lua
require "AutoForester_Debug"
local AFInstant = require "AF_Instant"

AFSweep = AFSweep or {}

local WOOD = { ["Base.Log"]=true, ["Base.TreeBranch"]=true, ["Base.LargeBranch"]=true, ["Base.Twigs"]=true, ["Base.Sapling"]=true }

local function eachGroundItemInRect(rect, fn)
  rect = AFCore and AFCore.normalizeRect(rect) or rect
  if not rect then return end
  local x1,y1,x2,y2,z = rect[1],rect[2],rect[3],rect[4],rect[5] or 0
  local cell = getCell(); if not cell then return end
  for y=y1,y2 do
    for x=x1,x2 do
      local sq = cell:getGridSquare(x,y,z)
      local wos = sq and sq:getWorldObjects()
      for i=0,(wos and wos:size() or 0)-1 do
        local it = wos:get(i):getItem()
        if it and WOOD[it:getFullType()] then fn(sq, it) end
      end
    end
  end
end

function AFSweep.enqueueSweep(p, rect)
  eachGroundItemInRect(rect, function(sq, it)
    ISTimedActionQueue.add(ISWalkToTimedAction:new(p, sq))
    ISTimedActionQueue.add(ISPickupWorldItemAction:new(p, it, sq:getX(), sq:getY(), sq:getZ()))
  end)
end

local function dropWoodInInventory(p, pileSq)
  if not pileSq then return end
  local inv = p:getInventory()
  local wanted = {}
  for full,_ in pairs(WOOD) do wanted[#wanted+1] = full end
  for _,full in ipairs(wanted) do
    local items = inv:getItemsFromFullType(full)
    if items then
      for i=0,items:size()-1 do
        ISTimedActionQueue.add(ISWalkToTimedAction:new(p, pileSq))
        ISTimedActionQueue.add(ISDropItemAction:new(p, items:get(i)))
      end
    end
  end
end

function AFSweep.enqueueHaulToPile(p, pileSq)
  if not pileSq then return end
  ISTimedActionQueue.add(AFInstant:new(p, function() dropWoodInInventory(p, pileSq) end))
end

return AFSweep
