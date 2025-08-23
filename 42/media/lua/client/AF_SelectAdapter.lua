-- media/lua/client/AF_SelectAdapter.lua
local ok, ASS = pcall(require, "JB_ASSUtils")
local HAS_ASS = ok and type(ASS)=="table"

AF_Select = AF_Select or {}

-- One tile
function AF_Select.pickSquare(worldObjects, p, cb)
  if HAS_ASS and ASS.SelectSingleSquare then
    return ASS.SelectSingleSquare(worldObjects, p, function(playerObj, wos, square)
      cb(square)
    end)
  else
    local mx,my = getMouseXScaled(), getMouseYScaled()
    local z = (p and p:getZ()) or 0
    local wx = ISCoordConversion.ToWorldX(mx,my,0)
    local wy = ISCoordConversion.ToWorldY(mx,my,0)
    local cell = getCell(); if not cell then cb(nil); return end
    cb(cell:getGridSquare(math.floor(wx), math.floor(wy), z))
  end
end

-- Rectangle
function AF_Select.pickArea(worldObjects, p, cb, tag)
  if HAS_ASS and ASS.SelectArea then
    return ASS.SelectArea(worldObjects, p, function(playerObj, wos, area)
      if not area then cb(nil); return end
      -- Normalize to {x1,y1,x2,y2,z}
      local x1 = tonumber(area.minX or area[1])
      local y1 = tonumber(area.minY or area[2])
      local x2 = tonumber(area.maxX or area[3])
      local y2 = tonumber(area.maxY or area[4])
      local z  = tonumber(area.z or (p and p:getZ()) or 0)
      if not (x1 and y1 and x2 and y2) then cb(nil); return end
      cb({x1,y1,x2,y2,z}, area)
    end, tag)
  else
    if not AF_SelectArea or not AF_SelectArea.start then if p then p:Say("Area tool missing.") end; cb(nil); return end
    AF_SelectArea.start(tag, p, cb)
  end
end
