AutoChopTask = AutoChopTask or {}
local T = AutoChopTask

T.chopRect   = T.chopRect   or nil
T.gatherRect = T.gatherRect or nil

function T.clear()
  T.chopRect, T.gatherRect = nil, nil
end

function T.startAreaJob(p)
  local Debug = AutoForester_Debug or { on=false, log=function() end }
  if Debug.on then
    Debug.log("startAreaJob chopRect=%s gatherRect=%s",
      tostring(T.chopRect and table.concat(T.chopRect, ",") or "nil"),
      tostring(T.gatherRect and table.concat(T.gatherRect, ",") or "nil"))
  end
  if not T.chopRect then p:Say("Set chop area first."); return end
  if not AutoForester_Core.hasWoodPile() then p:Say("Designate wood pile first."); return end
  AutoForester_Core.startJob_fromRects(p, T.chopRect, T.gatherRect)
end

return T
