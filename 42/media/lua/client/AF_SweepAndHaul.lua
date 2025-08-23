-- media/lua/client/AF_SweepAndHaul.lua
require "AutoForester_Debug"

AFSweep = AFSweep or {}

local WOOD = { ["Base.Log"]=true, ["Base.TreeBranch"]=true, ["Base.LargeBranch"]=true, ["Base.Twigs"]=true, ["Base.Sapling"]=true }

local function eachGroundItemInRect(rect, fn)
  if not rect then return end
  local x1 = tonumber(rect[1]); local y1 = tonumber(rect[2])
  local x2 = tonumber(rect[3]); local y2 = tonumber(rect[4])
  local z  = tonumber(rect[5]) or 0
  if not (x1 and y1 and x2 and y2) then return end
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
  local function dropType(full)
    local items = inv:getItemsFromFullType(full)
    if not items then return end
    for i=0, items:size()-1 do
      ISTimedActionQueue.add(ISWalkToTimedAction:new(p, pileSq))
      ISTimedActionQueue.add(ISDropItemAction:new(p, items:get(i)))
    end
  end
  for full,_ in pairs(WOOD) do dropType(full) end
end

function AFSweep.enqueueHaulToPile(p, pileSq)
  ISTimedActionQueue.add(ISWalkToTimedAction:new(p, pileSq))
  ISTimedActionQueue.add(AFInstant:new(p, function() dropWoodInInventory(p, pileSq) end))
end

return AFSweep
