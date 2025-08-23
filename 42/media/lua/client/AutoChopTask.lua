-- media/lua/client/AutoChopTask.lua
require "AutoForester_Core"
require "AF_SweepAndHaul"
require "AF_Instant"

AutoChopTask = AutoChopTask or { chopRect=nil, gatherRect=nil }

function AutoChopTask.setChopRect(rect, area)
  AutoChopTask.chopRect = {
    tonumber(rect[1]), tonumber(rect[2]),
    tonumber(rect[3]), tonumber(rect[4]),
    tonumber((area and area.z) or rect[5] or 0)
  }
end

function AutoChopTask.setGatherRect(rect, area)
  AutoChopTask.gatherRect = {
    tonumber(rect[1]), tonumber(rect[2]),
    tonumber(rect[3]), tonumber(rect[4]),
    tonumber((area and area.z) or rect[5] or 0)
  }
end

local function dropTreeLootNow(p)
  -- no-op for now; loot will be swept & hauled
end

function AutoChopTask.startAreaJob(p)
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
