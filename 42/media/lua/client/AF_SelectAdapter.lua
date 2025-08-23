-- AF_SelectAdapter.lua
local ok, ASS = pcall(require, "JB_ASSUtils")
local HAS_ASS = ok and type(ASS)=="table"
require "ISCoordConversion"
require "AutoForester_Debug"
require "AF_SelectArea"

AF_Select = AF_Select or {}

function AF_Select.pickSquare(worldObjects, p, cb)
  if HAS_ASS and ASS.SelectSingleSquare then
    return ASS.SelectSingleSquare(worldObjects, p, function(playerObj, wos, square) cb(square) end)
  else
    local mx,my = getMouseXScaled(), getMouseYScaled()
    local z = (p and p:getZ()) or 0
    local wx = ISCoordConversion.ToWorldX(mx,my,0)
    local wy = ISCoordConversion.ToWorldY(mx,my,0)
    local cell = getCell(); if not cell then cb(nil); return end
    cb(cell:getGridSquare(math.floor(wx), math.floor(wy), z))
  end
end

function AF_Select.pickArea(worldObjects, p, cb, tag)
  if HAS_ASS and ASS.SelectArea then
    return ASS.SelectArea(worldObjects, p, function(playerObj, wos, area)
      if not area or (area.numSquares or 0)==0 then cb(nil); return end
      local minX, minY = area.minX or area[1], area.minY or area[2]
      local maxX, maxY = area.maxX or area[3], area.maxY or area[4]
      local z = area.z or (p and p:getZ()) or 0
      local r = AFCore.normalizeRect({minX,minY,maxX,maxY,z})
      cb(r, { areaWidth = r and (r[3]-r[1]+1) or 0, areaHeight = r and (r[4]-r[2]+1) or 0 })
    end, tag)
  else
    return AF_SelectArea.start(tag, p, function(rect)
      local r = AFCore.normalizeRect(rect)
      if not r then cb(nil); return end
      cb(r, { areaWidth = (r[3]-r[1]+1), areaHeight = (r[4]-r[2]+1) })
    end)
  end
end
