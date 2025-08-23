-- media/lua/client/AF_SelectAdapter.lua
require "AutoForester_Core"
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
    -- Fallback: use the square currently under the mouse at player's Z
    local sq = AFCore.squareUnderMouse(p)
    cb(sq)
  end
end

-- Rectangle (x1,y1,x2,y2,z)
function AF_Select.pickArea(worldObjects, p, cb, tag)
  if HAS_ASS and ASS.SelectArea then
    return ASS.SelectArea(worldObjects, p, function(playerObj, wos, area)
      -- JB_ASSUtils returns an object with minX/minY/maxX/maxY and numSquares
      if not area or not area.squares or area.numSquares == 0 then cb(nil); return end
      local minX = tonumber(area.minX or area[1])
      local minY = tonumber(area.minY or area[2])
      local maxX = tonumber(area.maxX or area[3])
      local maxY = tonumber(area.maxY or area[4])
      local z = tonumber(area.z or (p and p:getZ()) or 0) or 0
      if not (minX and minY and maxX and maxY) then cb(nil); return end
      -- Normalize
      if maxX < minX then minX, maxX = maxX, minX end
      if maxY < minY then minY, maxY = maxY, minY end
      cb({minX, minY, maxX, maxY, z}, area)
    end, tag)
  else
    if not AF_SelectArea or not AF_SelectArea.start then getPlayer():Say("Area tool not loaded."); cb(nil); return end
    AF_SelectArea.start(tag, p, function(rect, area)
      -- Ensure rect is normalized and numeric
      if rect and type(rect)=="table" then
        local r = { tonumber(rect[1]), tonumber(rect[2]), tonumber(rect[3]), tonumber(rect[4]), tonumber(rect[5] or (p and p:getZ()) or 0)}
        if r[1] and r[2] and r[3] and r[4] then
          if r[3] < r[1] then r[1], r[3] = r[3], r[1] end
          if r[4] < r[2] then r[2], r[4] = r[4], r[2] end
          cb(r, area); return
        end
      end
      cb(nil)
    end)
  end
end
