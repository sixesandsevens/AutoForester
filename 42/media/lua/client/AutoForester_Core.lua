-- AutoForester_Core.lua
AFCore = AFCore or {}

-- Remember the currently designated stockpile square so the UI can highlight it
AFCore._pileSq = AFCore._pileSq or nil

function AFCore.setStockpile(sq)
  if AFCore._pileSq and AFCore._pileSq.setHighlighted then AFCore._pileSq:setHighlighted(false) end
  AFCore._pileSq = sq
  if sq and sq.setHighlighted then sq:setHighlighted(true) end
end

function AFCore.getStockpile() return AFCore._pileSq end

-- Tile under mouse at player's z (kept as a utility; not used by the patched wood-pile flow)
function AFCore.getMouseSquare(p)
  local z = (p and p:getZ() and p:getZ()) or 0
  local cell = getCell(); if not cell then return nil end

  -- Guard ToWorldX/Y with pcall so "Break On Error" in the debugger won't stop the game if UI state is odd.
  local mx, my = getMouseXScaled(), getMouseYScaled()
  local okX, wx = pcall(ISCoordConversion.ToWorldX, mx, my, z)
  if not okX or type(wx) ~= "number" then return nil end
  local okY, wy = pcall(ISCoordConversion.ToWorldY, mx, my, z)
  if not okY or type(wy) ~= "number" then return nil end

  return cell:getGridSquare(math.floor(wx), math.floor(wy), z)
end

-- ----------- Rect helpers -----------
function AFCore.normalizeRect(rect)
  if not rect then return nil end
  if type(rect) ~= "table" or (not rect[1]) then return nil end
  local a,b,r1,r2 = rect[1], rect[2], rect[3], rect[4]
  if not a or not b then return nil end
  r1 = r1 or a; r2 = r2 or b
  local x1 = math.min(a, r1); local y1 = math.min(b, r2)
  local x2 = math.max(a, r1); local y2 = math.max(b, r2)
  return {x1, y1, x2, y2}
end
