-- media/lua/client/AF_SelectAdapter.lua
local ok, ASS = pcall(require, "JB_ASSUtils")
local HAS_ASS = ok and type(ASS)=="table"

AF_Select = AF_Select or {}

-- Call: AF_Select.pickSquare(worldObjects, player, cb)
function AF_Select.pickSquare(wos, p, cb)
  if HAS_ASS and ASS.SelectSingleSquare then
    return ASS.SelectSingleSquare(wos, p, function(sq) cb(sq) end)
  else
    -- fallback: mouse position now
    local mx,my = getMouseXScaled(), getMouseYScaled()
    local z = (p and p:getZ()) or 0
    local wx = ISCoordConversion.ToWorldX(mx,my,z)
    local wy = ISCoordConversion.ToWorldY(mx,my,z)
    local cell = getCell(); if not cell then return cb(nil) end
    return cb(cell:getGridSquare(math.floor(wx), math.floor(wy), z))
  end
end

-- Call: AF_Select.pickArea(worldObjects, player, cb, tag)
function AF_Select.pickArea(wos, p, cb, tag)
  if HAS_ASS and ASS.SelectArea then
    return ASS.SelectArea(wos, p, function(area)
      if not area or not area.squares or area.numSquares==0 then cb(nil); return end
      cb({area.minX, area.minY, area.maxX, area.maxY, area.z or (p and p:getZ()) or 0}, area)
    end, tag)
  else
    -- fallback tool
    if not AF_SelectArea or not AF_SelectArea.start then
      getPlayer():Say("Area tool not loaded."); cb(nil); return
    end
    AF_SelectArea.start(tag, p, cb) -- see next section
  end
end

