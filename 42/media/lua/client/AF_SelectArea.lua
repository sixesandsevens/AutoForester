-- AF_SelectArea.lua (fallback click-drag rectangle)
require "ISCoordConversion"
require "AutoForester_Debug"
AF_SelectArea = AF_SelectArea or {}
local T = { active=false, tag="", p=nil, z=0, a=nil, b=nil, hi={}, cb=nil }

local function clearHi()
  for _,sq in ipairs(T.hi) do if sq and sq.setHighlighted then sq:setHighlighted(false) end end
  T.hi = {}
end

local function toSq(mx,my,z)
  local wx = ISCoordConversion.ToWorldX(mx,my,0)
  local wy = ISCoordConversion.ToWorldY(mx,my,0)
  local cell = getCell(); if not cell then return nil end
  return cell:getGridSquare(math.floor(wx), math.floor(wy), z)
end

local function toRect(a,b)
  if not a or not b then return nil end
  local x1 = math.min(a[1], b[1]); local y1 = math.min(a[2], b[2])
  local x2 = math.max(a[1], b[1]); local y2 = math.max(a[2], b[2])
  return {x1,y1,x2,y2,T.z}
end

local function paintRect(rect)
  clearHi(); if not rect then return end
  local x1,y1,x2,y2,z = rect[1],rect[2],rect[3],rect[4],rect[5] or 0
  local cell = getCell(); if not cell then return end
  for y=y1,y2 do for x=x1,x2 do
    local sq = cell:getGridSquare(x,y,z)
    if sq and sq.setHighlighted then
      sq:setHighlighted(true); if sq.setHighlightColor then sq:setHighlightColor(0.2,0.8,1.0) end
      table.insert(T.hi, sq)
    end
  end end
end

function AF_SelectArea.start(tag, p, cb)
  if T.active then return end
  T.active, T.tag, T.p, T.z, T.cb = true, (tag or ""), p, (p and p:getZ()) or 0, cb
  T.a, T.b = nil, nil
  AFLOG("AREA","start",T.tag,"z",T.z)
  Events.OnMouseDown.Add(AF_SelectArea.onMouseDown)
  Events.OnMouseUp.Add(AF_SelectArea.onMouseUp)
  Events.OnMouseMove.Add(AF_SelectArea.onMouseMove)
end

local function stop(andReturn)
  Events.OnMouseDown.Remove(AF_SelectArea.onMouseDown)
  Events.OnMouseUp.Remove(AF_SelectArea.onMouseUp)
  Events.OnMouseMove.Remove(AF_SelectArea.onMouseMove)
  local cb = T.cb; local r = toRect(T.a,T.b)
  T.active, T.p, T.cb = false, nil, nil
  clearHi(); if andReturn and cb then cb(r) end
end

function AF_SelectArea.onMouseDown()
  if not T.active then return end
  local mx,my = getMouseXScaled(), getMouseYScaled()
  local sq = toSq(mx,my,T.z); if not sq then return end
  T.a = { sq:getX(), sq:getY() }
end

function AF_SelectArea.onMouseMove()
  if not T.active or not T.a then return end
  local mx,my = getMouseXScaled(), getMouseYScaled()
  local sq = toSq(mx,my,T.z); if not sq then return end
  T.b = { sq:getX(), sq:getY() }
  paintRect(toRect(T.a,T.b))
end

function AF_SelectArea.onMouseUp()
  if not T.active or not T.a then return end
  local mx,my = getMouseXScaled(), getMouseYScaled()
  local sq = toSq(mx,my,T.z); if not sq then return end
  T.b = { sq:getX(), sq:getY() }
  stop(true)
end
