-- AutoChopTask.lua
require "AutoForester_Core"
require "AF_SweepAndHaul"
require "AF_Instant"

AutoChopTask = AutoChopTask or { chopRect=nil, gatherRect=nil }

local function dropTreeLootNow(p)
  local inv = p:getInventory()
  for _,full in ipairs({ "Base.Log","Base.TreeBranch","Base.LargeBranch","Base.Twigs","Base.Sapling" }) do
    local items = inv:getItemsFromFullType(full)
    if items then
      for i=0, items:size()-1 do
        ISTimedActionQueue.add(ISDropItemAction:new(p, items:get(i)))
      end
    end
  end
end

function AutoChopTask.setChopRect(rect, area)
  AutoChopTask.chopRect = AFCore.normalizeRect(rect or {})
  AFLOG("RECT","chop", AutoChopTask.chopRect and (AutoChopTask.chopRect[1]..","..AutoChopTask.chopRect[2].." "..AutoChopTask.chopRect[3]..","..AutoChopTask.chopRect[4]) or "nil")
end

function AutoChopTask.setGatherRect(rect, area)
  AutoChopTask.gatherRect = AFCore.normalizeRect(rect or {})
  AFLOG("RECT","gather", AutoChopTask.gatherRect and (AutoChopTask.gatherRect[1]..","..AutoChopTask.gatherRect[2].." "..AutoChopTask.gatherRect[3]..","..AutoChopTask.gatherRect[4]) or "nil")
end

function AutoChopTask.startAreaJob(p)
  p = AFCore.getPlayer(p)
  if not AutoChopTask.chopRect then p:Say("Set chop area first."); return end
  if not AFCore.getStockpile() then p:Say("Designate wood pile first."); return end
  local trees = AFCore.treesInRect(AutoChopTask.chopRect)
  if #trees == 0 then p:Say("No trees in chop area."); return end

  local n = AFCore.queueChops(p, trees)
  ISTimedActionQueue.add(AFInstant:new(p, function() dropTreeLootNow(p) end))
  p:Say(("Queued %d tree(s)."):format(n))

  local rect = AutoChopTask.gatherRect or AutoChopTask.chopRect
  ISTimedActionQueue.add(AFInstant:new(p, function() p:Say("Sweeping and hauling…") end))
  AFSweep.enqueueSweep(p, rect)
  AFSweep.enqueueHaulToPile(p, AFCore.getStockpile())
end
