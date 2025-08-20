-- AF_SelectArea.lua (fallback selector)
require "ISCoordConversion"
require "AutoForester_Debug"

AF_SelectArea = AF_SelectArea or {}
local Tool = { tag=nil, dragging=false, ax=0, ay=0, z=0, rect=nil, hi={} }

local function clear()
  for _,sq in ipairs(Tool.hi) do if sq.setHighlighted then sq:setHighlighted(false) end end
  Tool.hi = {}
end

local function mouseSq()
  local mx,my = getMouseXScaled(), getMouseYScaled()
  local wx = ISCoordConversion.ToWorldX(mx,my,0)
  local wy = ISCoordConversion.ToWorldY(mx,my,0)
  local p = getSpecificPlayer(0)
  local z = (p and p:getZ()) or 0
  local sq = getCell():getGridSquare(math.floor(wx), math.floor(wy), z)
  AFLOG("select", "mouse=", mx, ",", my, " world=", wx, ",", wy, " z=", z, " sq=", tostring(sq))
  return sq
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

function AF_SelectArea.start(tag)
  Tool.tag = tag; Tool.dragging=false; Tool.rect=nil
  Events.OnMouseDown.Add(AF_SelectArea.onMouseDown)
  Events.OnMouseMove.Add(AF_SelectArea.onMouseMove)
  Events.OnMouseUp.Add(AF_SelectArea.onMouseUp)
end

function AF_SelectArea.stop()
  Events.OnMouseDown.Remove(AF_SelectArea.onMouseDown)
  Events.OnMouseMove.Remove(AF_SelectArea.onMouseMove)
  Events.OnMouseUp.Remove(AF_SelectArea.onMouseUp)
  Tool.dragging=false; Tool.rect=nil; clear()
end

function AF_SelectArea.onMouseDown(x,y)
  local sq = mouseSq()
  if not sq then return end
  Tool.ax,Tool.ay,Tool.z = sq:getX(), sq:getY(), sq:getZ()
  Tool.dragging=true
end

function AF_SelectArea.onMouseMove(dx,dy)
  if not Tool.dragging then return end
  local sq = mouseSq(); if not sq then return end
  local bx,by = sq:getX(), sq:getY()
  local x1 = math.min(Tool.ax,bx)
  local y1 = math.min(Tool.ay,by)
  local x2 = math.max(Tool.ax,bx)
  local y2 = math.max(Tool.ay,by)
  Tool.rect = {x1,y1,x2,y2,Tool.z}
  hiRect(Tool.rect)
end

function AF_SelectArea.onMouseUp(x,y)
  AF_SelectArea.stop()
  local r = Tool.rect
  if AF_SelectArea.onDone then
    if not r or r[3] < r[1] or r[4] < r[2] then
      AF_SelectArea.onDone(nil)
    else
      local area = { minX=r[1], minY=r[2], maxX=r[3], maxY=r[4], z=r[5] or 0,
                     areaWidth=r[3]-r[1]+1, areaHeight=r[4]-r[2]+1,
                     numSquares=(r[3]-r[1]+1)*(r[4]-r[2]+1) }
      AF_SelectArea.onDone(r, area)
    end
  end
end
