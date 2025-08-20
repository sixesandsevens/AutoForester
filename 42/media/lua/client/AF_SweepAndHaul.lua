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

AFSweep = {}

function AFSweep.enqueueSweep(player, rect)
  eachGroundItemInRect(rect, function(sq, it)
    ISTimedActionQueue.add(ISWalkToTimedAction:new(player, sq))
    ISTimedActionQueue.add(ISPickupWorldItemAction:new(player, it, sq:getX(), sq:getY(), sq:getZ()))
  end)
end

function AFSweep.enqueueHaulToPile(player, pileSq)
  ISTimedActionQueue.add(ISWalkToTimedAction:new(player, pileSq))
  -- drop *all* wood in inventory at the pile:
  ISTimedActionQueue.add(ISInventoryTransferAllToFloorAction:new(player, pileSq, function(item)
    return WOOD[item:getFullType()] or false
  end))
end

return AFSweep
