-- AF_SelectAdapter.lua
AF_Select = AF_Select or {}

local function mouseSquareOrNil(p)
  local z = p:getZ() or 0
  local mx,my = getMouseXScaled(), getMouseYScaled()
  local wx = ISCoordConversion.ToWorldX(mx,my,z)
  local wy = ISCoordConversion.ToWorldY(mx,my,z)
  return getCell():getGridSquare(math.floor(wx), math.floor(wy), z)
end

-- Normalize JB_ASSUtils selectedArea to our rect record
local function areaToRect(a)
  -- JB returns: { squares={}, minX, maxX, minY, maxY, z, ... }
  if not a or not a.minX then return nil end
  return { a.minX, a.minY, a.maxX, a.maxY, a.z or 0 }
end

-- === Public: pick one square (for wood pile) ================================
function AF_Select.pickSquare(worldObjects, playerObj, callback)
  if JB_ASSUtils then
    -- args: (worldObjects, playerObj, callback, ...optionalArgs)
    return JB_ASSUtils.SelectSingleSquare(worldObjects, playerObj, function(selectedSquare)
      if callback then callback(selectedSquare) end
    end)
  end
  -- Fallback: immediate mouse square
  local sq = mouseSquareOrNil(playerObj)
  if callback then callback(sq) end
end

-- === Public: drag area for "chop" / "gather" =============================
function AF_Select.pickArea(worldObjects, playerObj, callback, kindLabel)
  if JB_ASSUtils then
    return JB_ASSUtils.SelectArea(worldObjects, playerObj, function(selectedArea)
      if callback then callback(areaToRect(selectedArea), selectedArea) end
    end)
  end
  -- Fallback: single click → tiny 1x1 rect
  local sq = mouseSquareOrNil(playerObj)
  local rect = sq and {sq:getX(), sq:getY(), sq:getX(), sq:getY(), sq:getZ()} or nil
  if callback then callback(rect, { squares = sq and {sq} or {}, z = sq and sq:getZ() or 0 }) end
end

return AF_Select
