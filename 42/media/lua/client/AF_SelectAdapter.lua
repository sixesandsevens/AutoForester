-- AF_SelectAdapter.lua
require "AutoForester_Debug"
require "ISCoordConversion"
local hasASS, ASS = pcall(require, "JB_ASSUtils")
AF_Select = AF_Select or {}

function AF_Select.pickSquare(worldObjects, p, cb)
  if hasASS and ASS.SelectSingleSquare then
    return ASS.SelectSingleSquare(worldObjects, p, cb)
  end
  local mx,my = getMouseXScaled(), getMouseYScaled()
  local z = p and p:getZ() or 0
  local wx = ISCoordConversion.ToWorldX(mx,my,0)
  local wy = ISCoordConversion.ToWorldY(mx,my,0)
  local sq = getCell():getGridSquare(math.floor(wx), math.floor(wy), z)
  AFLOG("select", "mouse=", mx, ",", my, " world=", wx, ",", wy, " z=", z, " sq=", tostring(sq))
  return cb(sq)
end

function AF_Select.pickArea(worldObjects, p, cb, tag)
  if hasASS and ASS.SelectSquareArea then
    return ASS.SelectSquareArea(worldObjects, p, function(area)
      if not area or not area.minX then cb(nil); return end
      cb({area.minX, area.minY, area.maxX, area.maxY, area.z or p:getZ()}, area)
    end, tag)
  end
  require "AF_SelectArea"
  AF_SelectArea.start(tag)
  AF_SelectArea.onDone = function(rect, area) cb(rect, area) end
end
