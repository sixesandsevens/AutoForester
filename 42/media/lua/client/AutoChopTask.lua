require "AutoForester_Core"
require "AF_SweepAndHaul"
require "AF_Instant"

AutoChopTask = AutoChopTask or { chopRect=nil, gatherRect=nil }

function AutoChopTask.startAreaJob(p)
  if not AutoChopTask.chopRect then p:Say("Set chop area first."); return end
  if not AFCore.getStockpile() then p:Say("Designate wood pile first."); return end
  local trees = AFCore.treesInRect(AutoChopTask.chopRect)
  if #trees == 0 then p:Say("No trees in chop area."); return end

  local n = AFCore.queueChops(p, trees)
  ISTimedActionQueue.add(AFInstant:new(p, function()
    AFCore.dropTreeLootNow(p)
  end))
  p:Say(("Queued %d tree(s)."):format(n))

  local rect = AutoChopTask.gatherRect or AutoChopTask.chopRect
  AFSweep.enqueueSweep(p, rect)
  AFSweep.enqueueHaulToPile(p, AFCore.getStockpile())
end
