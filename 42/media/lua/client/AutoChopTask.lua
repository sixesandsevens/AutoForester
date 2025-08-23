-- media/lua/client/AutoChopTask.lua
require "AutoForester_Core"
require "AF_SweepAndHaul"
local AFInstant = require "AF_Instant"

AutoChopTask = AutoChopTask or { chopRect=nil, gatherRect=nil }

local function storeRect(dstKey, rect, area)
  local r = AFCore.normalizeRect(rect or area or {})
  AutoChopTask[dstKey] = r
end

function AutoChopTask.setChopRect(rect, area)   storeRect("chopRect", rect, area) end
function AutoChopTask.setGatherRect(rect, area) storeRect("gatherRect", rect, area) end

function AutoChopTask.startAreaJob(p)
  if not AutoChopTask.chopRect then p:Say("Set chop area first."); return end
  if not AFCore.getStockpile() then p:Say("Designate wood pile first."); return end

  local trees = AFCore.treesInRect(AutoChopTask.chopRect)
  if #trees == 0 then p:Say("No trees in chop area."); return end

  local n = AFCore.queueChops(p, trees)
  p:Say(("Queued %d tree(s)."):format(n))

  local rect = AutoChopTask.gatherRect or AutoChopTask.chopRect
  ISTimedActionQueue.add(AFInstant:new(p, function() p:Say("Sweeping and hauling…") end))
  AFSweep.enqueueSweep(p, rect)
  AFSweep.enqueueHaulToPile(p, AFCore.getStockpile())
end
