-- media/lua/client/AF_SweepAndHaul.lua
AFSweep = AFSweep or {}

local WOOD = { ["Base.Log"]=true, ["Base.TreeBranch"]=true, ["Base.LargeBranch"]=true, ["Base.Twigs"]=true, ["Base.Sapling"]=true }

local function eachGroundItemInRect(rect, fn)
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


function AFSweep.enqueueHaulToPile(p, pileSq)
  if not pileSq then return end
  ISTimedActionQueue.add(ISWalkToTimedAction:new(p, pileSq))
  -- Drop all carried wood items on the pile square, one by one (compatible with B42)
  ISTimedActionQueue.add(AFInstant:new(p, function()
    local inv = p:getInventory()
    if not inv then return end
    local items = inv:getItems()
    -- Iterate backwards because the list is modified as items are dropped
    for i = items:size()-1, 0, -1 do
      local it = items:get(i)
      if it and WOOD[it:getFullType()] then
        ISTimedActionQueue.add(ISDropItemAction:new(p, it)) -- drop to current square (pile)
      end
    end
  end))
end

return AFSweep

