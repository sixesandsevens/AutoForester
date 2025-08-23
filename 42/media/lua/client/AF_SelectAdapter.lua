-- AF_SelectAdapter.lua
local ok, ASS = pcall(require, "JB_ASSUtils"); local HAS_ASS = ok and type(ASS)=="table"
AF_Select = AF_Select or {}; AF_Select.DEFAULT_SIZE = AF_Select.DEFAULT_SIZE or 13

local function firstSq(worldobjects)
  if type(worldobjects)=="table" then
    for i=1,#worldobjects do local o=worldobjects[i]; if o and o.getSquare and o:getSquare() then return o:getSquare() end end
  end
  return nil
end

-- Pick one square
function AF_Select.pickSquare(worldobjects, playerObjOrIndex, cb)
  local p = type(playerObjOrIndex)=="number" and getSpecificPlayer(playerObjOrIndex) or playerObjOrIndex
  local sq = firstSq(worldobjects) or (p and p:getSquare()) or nil
  if cb then cb(sq) end
end

-- Pick a rectangle; if ASS is present, use it; otherwise provide a centered default box or use drag fallback
function AF_Select.pickArea(worldobjects, playerObjOrIndex, cb, tag)
  local p = type(playerObjOrIndex)=="number" and getSpecificPlayer(playerObjOrIndex) or playerObjOrIndex
  if HAS_ASS and ASS.SelectArea then
    return ASS.SelectArea(worldobjects, p, function(playerObj, wos, area)
      if not area then cb(nil); return end
      local x1 = tonumber(area.minX or area[1]); local y1 = tonumber(area.minY or area[2])
      local x2 = tonumber(area.maxX or area[3]); local y2 = tonumber(area.maxY or area[4])
      local z  = tonumber(area.z or p:getZ() or 0)
      if not (x1 and y1 and x2 and y2) then cb(nil); return end
      cb({x1,y1,x2,y2,z}, area)
    end, tag)
  end

  -- Prefer drag tool; if not available, return a fixed-size rect around clicked/player square
  if AF_SelectArea and AF_SelectArea.start then
    AF_SelectArea.start(tag, p, function(rect)
      if rect then cb(rect) else
        local sq = firstSq(worldobjects) or (p and p:getSquare())
        if not sq then cb(nil); return end
        local half = math.floor(AF_Select.DEFAULT_SIZE/2)
        cb({sq:getX()-half, sq:getY()-half, sq:getX()+half, sq:getY()+half, sq:getZ()})
      end
    end)
  else
    local sq = firstSq(worldobjects) or (p and p:getSquare())
    if not sq then cb(nil); return end
    local half = math.floor(AF_Select.DEFAULT_SIZE/2)
    cb({sq:getX()-half, sq:getY()-half, sq:getX()+half, sq:getY()+half, sq:getZ()})
  end
end
