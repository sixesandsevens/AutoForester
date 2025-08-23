-- AutoForester_Core.lua (shared shim)
AFCore = AFCore or {}

function AFCore.normalizeRect(rect)
  if not rect then return nil end
  local r = rect
  if r.x1 then r = { r.x1, r.y1, r.x2 or r.x1, r.y2 or r.y1 } end
  local x1,y1,x2,y2 = r[1], r[2], r[3], r[4]
  if not x1 or not y1 or not x2 or not y2 then return nil end
  if x2 < x1 then x1,x2 = x2,x1 end
  if y2 < y1 then y1,y2 = y2,y1 end
  return {x1,y1,x2,y2}
end

return AFCore
