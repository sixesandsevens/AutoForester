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
  -- Prefer JB_ASSUtils if present
  if HAS_ASS and ASS.SelectArea then
    return ASS.SelectArea(worldObjects, p, function(playerObj, wos, area)
      -- Validate selection
      if not area or not area.squares or #area.squares == 0 then cb(nil); return end

      -- JB_ASSUtils puts metadata in area[1]; fall back to scanning if needed
      local meta = nil
      if type(area[1]) == "table" then
        meta = area[1]
      elseif area.minX and area.maxX and area.minY and area.maxY then
        meta = area
      end

      local minX, minY, maxX, maxY
      if meta then
        minX = meta.minX or meta[1]
        minY = meta.minY or meta[2]
        maxX = meta.maxX or meta[3]
        maxY = meta.maxY or meta[4]
      end

      -- If still missing, derive from squares
      if not (minX and minY and maxX and maxY) then
        for i=1,#area.squares do
          local sq = area.squares[i]
          if sq then
            local x, y = sq:getX(), sq:getY()
            if not minX or x < minX then minX = x end
            if not minY or y < minY then minY = y end
            if not maxX or x > maxX then maxX = x end
            if not maxY or y > maxY then maxY = y end
          end
        end
      end

      if not (minX and minY and maxX and maxY) then cb(nil); return end

      local z = (area.z) or (meta and meta.z) or ((p and p.getZ and p:getZ()) or 0)
      -- Normalize helpful fields onto the 'area' object for downstream consumers
      area.minX, area.minY, area.maxX, area.maxY = minX, minY, maxX, maxY
      area.areaWidth  = area.areaWidth  or ((maxX - minX) + 1)
      area.areaHeight = area.areaHeight or ((maxY - minY) + 1)

      cb({ minX, minY, maxX, maxY, z }, area)
    end, tag)
  else
    -- Fallback to lightweight selector
    if not AF_SelectArea or not AF_SelectArea.start then
      getPlayer():Say("Area tool not loaded."); cb(nil); return
    end
    AF_SelectArea.start(tag, p, cb)
  end
end

      local minX, minY = area.minX or area[1] or area.minX, area.minY or area[2] or area.minY
      local maxX, maxY = area.maxX or area[3] or area.maxX, area.maxY or area[4] or area.maxY
      local z = area.z or (p and p:getZ()) or 0
      cb({minX, minY, maxX, maxY, z}, area)
    end, tag)
  else
    if not AF_SelectArea or not AF_SelectArea.start then getPlayer():Say("Area tool not loaded."); cb(nil); return end
    AF_SelectArea.start(tag, p, cb)
  end
end
