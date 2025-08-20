-- AF_SelectArea.lua  (fallback tool used when JB_ASSUtils isn't present)
require "ISCoordConversion"

AF_SelectArea = AF_SelectArea or {}
local Tool = { active=false, kind=nil, startSq=nil, rect=nil, hi={} }
local function clear()
  for _,sq in ipairs(Tool.hi) do if sq.setHighlighted then sq:setHighlighted(false) end end
  Tool.hi = {}
end
local function getMouseSq()
  local p = getSpecificPlayer(0); if not p then return nil end
  local mx,my = getMouseXScaled(), getMouseYScaled()
  local wx = ISCoordConversion.ToWorldX(mx,my,0)
  local wy = ISCoordConversion.ToWorldY(mx,my,0)
  local cell = getCell(); if not cell then return nil end
  return cell:getGridSquare(math.floor(wx), math.floor(wy), p:getZ() or 0)
end
local function norm(a,b)
  local x1 = math.min(a:getX(), b:getX()); local y1 = math.min(a:getY(), b:getY())
  local x2 = math.max(a:getX(), b:getX()); local y2 = math.max(a:getY(), b:getY())
  local z = a:getZ()
  return {x1,y1,x2,y2,z}
end
local function hiRect(r)
  clear(); if not r then return end
  local cell = getCell(); if not cell then return end
  local x1,y1,x2,y2,z = r[1],r[2],r[3],r[4],r[5] or 0
  for y=y1,y2 do for x=x1,x2 do
    local sq = cell:getGridSquare(x,y,z)
    if sq and sq.setHighlighted then
      sq:setHighlighted(true)
      if sq.setHighlightColor then sq:setHighlightColor(0,1,0,0.6) end
      table.insert(Tool.hi, sq)
    end
  end end
end

function AF_SelectArea.start(kind, onDone)
  Tool.active = true; Tool.kind = kind; Tool.startSq = getMouseSq(); Tool.rect=nil
  Tool._cb = onDone
  Events.OnMouseMoveDel.Add(AF_SelectArea.onMouseMove)
  Events.OnMouseUp.Add(AF_SelectArea.onMouseUp)
end

function AF_SelectArea.onMouseMove(dx,dy)
  if not Tool.active or not Tool.startSq then return end
  local cur = getMouseSq(); if not cur then return end
  Tool.rect = norm(Tool.startSq, cur)
  hiRect(Tool.rect)
end

function AF_SelectArea.onMouseUp(x,y)
  if not Tool.active then return end
  local cur = getMouseSq()
  Events.OnMouseMoveDel.Remove(AF_SelectArea.onMouseMove)
  Events.OnMouseUp.Remove(AF_SelectArea.onMouseUp)
  Tool.active=false
  if not cur or not Tool.startSq then clear(); if Tool._cb then Tool._cb(nil) end; return end
  Tool.rect = norm(Tool.startSq, cur)
  hiRect(Tool.rect)
  if Tool._cb then
    local r = Tool.rect
    local area = { minX=r[1], maxX=r[3], minY=r[2], maxY=r[4], z=r[5] or 0,
                   areaWidth=r[3]-r[1]+1, areaHeight=r[4]-r[2]+1, numSquares=(r[3]-r[1]+1)*(r[4]-r[2]+1) }
    Tool._cb(r, area)
  end
end
