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

-- Rectangle (returns rect table {x1,y1,x2,y2,z} and the raw area table if available)
function AF_Select.pickArea(worldObjects, p, cb, tag)
  if HAS_ASS and ASS.SelectArea then
    return ASS.SelectArea(worldObjects, p, function(playerObj, wos, area)
      if not area then cb(nil); return end

      local meta = nil
      -- JB_ASSUtils returns: area.squares = {...}; and also appends a metadata table at area[#area]
      if type(area[#area]) == "table" and (area[#area].minX or area[#area][1]) then
        meta = area[#area]
      elseif area.minX and area.maxX and area.minY and area.maxY then
        -- Some versions may set fields directly on area
        meta = area
      end

      local minX, minY, maxX, maxY, z
      if meta then
        minX = meta.minX or meta[1]
        minY = meta.minY or meta[2]
        maxX = meta.maxX or meta[3]
        maxY = meta.maxY or meta[4]
        z    = meta.z    or (p and p:getZ()) or 0
      else
        -- Fallback: derive bounds from squares
        local squares = area.squares or area
        if not squares or #squares == 0 then cb(nil); return end
        minX, minY =  1/0,  1/0
        maxX, maxY = -1/0, -1/0
        z = (p and p:getZ()) or 0
        for i=1,#squares do
          local sq = squares[i]
          if sq and sq.getX then
            local x,y = sq:getX(), sq:getY()
            if x < minX then minX = x end
            if y < minY then minY = y end
            if x > maxX then maxX = x end
            if y > maxY then maxY = y end
            if sq.getZ then z = sq:getZ() end
          end
        end
      end

      cb({minX, minY, maxX, maxY, z}, area)
    end, tag)
  else
    -- Fallback to our built-in drag-rectangle tool
    if not AF_SelectArea or not AF_SelectArea.start then getPlayer():Say("Area tool not loaded."); cb(nil); return end
    AF_SelectArea.start(tag, p, cb)
  end
end
