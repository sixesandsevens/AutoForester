-- AF_SelectAdapter.lua
local ok, ASS = pcall(require, "JB_ASSUtils")
local HAS_ASS = ok and type(ASS)=="table"

AF_Select = AF_Select or {}

-- Return a rect {x1,y1,x2,y2,z} and original 'area' (if any).
local function _rectFromASSArea(area, p)
  if not area then return nil end
  -- metadata might be at area[1] or area itself
  local meta = nil
  if type(area[1])=="table" and (area[1].minX or area[1].areaLeft) then
    meta = area[1]
  elseif area.minX or area.areaLeft then
    meta = area
  end
  local minX,minY,maxX,maxY
  if meta then
    minX = meta.minX or meta.areaLeft or meta[1]
    minY = meta.minY or meta.areaTop  or meta[2]
    maxX = meta.maxX or (meta.areaLeft and (meta.areaLeft + (meta.areaWidth or 1) - 1)) or meta[3]
    maxY = meta.maxY or (meta.areaTop  and (meta.areaTop  + (meta.areaHeight or 1) - 1)) or meta[4]
  end
  -- derive from squares if needed
  if not (minX and minY and maxX and maxY) and area.squares then
    for i=1,#area.squares do
      local sq = area.squares[i]
      if sq then
        local x,y = sq:getX(), sq:getY()
        minX = (minX and math.min(minX,x) or x)
        minY = (minY and math.min(minY,y) or y)
        maxX = (maxX and math.max(maxX,x) or x)
        maxY = (maxY and math.max(maxY,y) or y)
      end
    end
  end
  if not (minX and minY and maxX and maxY) then return nil end
  local z = area.z or (p and p:getZ()) or 0
  -- helpful standard fields
  area.areaWidth  = area.areaWidth  or ((maxX - minX) + 1)
  area.areaHeight = area.areaHeight or ((maxY - minY) + 1)
  return {minX, minY, maxX, maxY, z}, area
end

function AF_Select.pickArea(worldObjects, player, cb, tag)
  local p = player or getSpecificPlayer(0)
  if HAS_ASS and ASS.SelectArea then
    return ASS.SelectArea(worldObjects, p, function(playerObj, wos, area)
      local rect, a = _rectFromASSArea(area, p)
      cb(rect, a)
    end, tag or "area")
  end
  -- Fallback: center 13x13 around player's square
  local sq = p and p:getSquare() or nil
  if not sq then cb(nil); return end
  local cx,cy,cz = sq:getX(), sq:getY(), sq:getZ()
  cb({cx-6,cy-6,cx+6,cy+6,cz}, {areaWidth=13, areaHeight=13, minX=cx-6, minY=cy-6, maxX=cx+6, maxY=cy+6, z=cz})
end
