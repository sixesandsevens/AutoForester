-- AF_SelectAdapter.lua
local ok, ASS = pcall(require, "JB_ASSUtils")
local HAS_ASS = ok and type(ASS)=="table"

AF_Select = AF_Select or {}
require "ISUI/ISCoordConversion"

-- One tile: choose the tile under the cursor immediately
function AF_Select.pickSquare(worldObjects, p, cb)
  if HAS_ASS and ASS.SelectSingleSquare then
    -- Use ASS if present
    return ASS.SelectSingleSquare(worldObjects, p, function(playerObj, wos, square)
      cb(square)
    end)
  end
  -- Fallback: get the current mouse square right away
  local cell = getCell(); if not cell then cb(nil); return end
  local mx,my = getMouseXScaled(), getMouseYScaled()
  local z = (p and p.getZ and p:getZ()) or 0
  local wx = ISCoordConversion.ToWorldX(mx,my,z)
  local wy = ISCoordConversion.ToWorldY(mx,my,z)
  local sq = cell:getGridSquare(math.floor(wx), math.floor(wy), z)
  cb(sq)
end

-- Drag-select an area; callback receives (rectTable, areaTable)
function AF_Select.pickArea(worldObjects, p, cb, tag)
  if HAS_ASS and ASS.SelectArea then
    return ASS.SelectArea(worldObjects, p, function(playerObj, wos, area)
      if not area then cb(nil); return end
      local minX = area.minX or area[1]
      local minY = area.minY or area[2]
      local maxX = area.maxX or area[3]
      local maxY = area.maxY or area[4]
      local z = area.z or (p and p.getZ and p:getZ()) or 0
      cb({minX, minY, maxX, maxY, z}, area)
    end, tag or "area")
  end
  if not AF_SelectArea or not AF_SelectArea.start then
    if p and p.Say then p:Say("Area tool not loaded.") end
    cb(nil)
    return
  end
  AF_SelectArea.start(tag or "area", p, cb)
end

return AF_Select
