require "AutoForester_Core"
require "AF_SweepAndHaul"
require "AF_Instant"

AutoChopTask = AutoChopTask or { chopRect=nil, gatherRect=nil }

function AutoChopTask.startAreaJob(player)
  if not AutoChopTask.chopRect then player:Say("Set chop area first."); return end
  if not AFCore.getStockpile() then player:Say("Designate wood pile first."); return end

  local trees = AFCore.treesInRect(AutoChopTask.chopRect)
  if #trees == 0 then player:Say("No trees in chop area."); return end

  -- 1) Chop & drop heavy loot immediately after each chop batch
  local n = AFCore.queueChops(player, trees)
  ISTimedActionQueue.add(ISBaseTimedAction:new(player)) -- tiny yield
  ISTimedActionQueue.add(AFInstant:new(player, function() AFCore.dropTreeLootNow(player) end))
  player:Say(("Queued %d tree(s)."):format(n))

  -- 2) Sweep → haul (use gatherRect if set, else chopRect)
  local rect = AutoChopTask.gatherRect or AutoChopTask.chopRect
  ISTimedActionQueue.add(AFInstant:new(player, function() player:Say("Gathering wood…") end))
  AFSweep.enqueueSweep(player, rect)
  AFSweep.enqueueHaulToPile(player, AFCore.getStockpile())
end
