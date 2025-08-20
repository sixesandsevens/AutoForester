-- media/lua/client/AF_SelectArea.lua
require "ISCoordConversion"
require "AutoForester_Debug"

AF_SelectArea = AF_SelectArea or {}
local T = { active=false, tag="", p=nil, z=0, a=nil, b=nil, hi={} , cb=nil }

local function clearHi()
  for _,sq in ipairs(T.hi) do if sq.setHighlighted then sq:setHighlighted(false) end end
  T.hi = {}
end

local function toSq(mx,my,z)
  local wx = ISCoordConversion.ToWorldX(mx,my,z)
  local wy = ISCoordConversion.ToWorldY(mx,my,z)
  local cell = getCell(); if not cell then return nil, wx, wy end
  return cell:getGridSquare(math.floor(wx), math.floor(wy), z), wx, wy
end

local function toRect(a,b)
  local x1 = math.min(a[1],b[1]); local y1 = math.min(a[2],b[2])
  local x2 = math.max(a[1],b[1]); local y2 = math.max(a[2],b[2])
  return {x1,y1,x2,y2,T.z}
end

local function paintRect(rect)
  clearHi(); if not rect then return end
  local cell = getCell(); if not cell then return end
  for y=rect[2],rect[4] do
    for x=rect[1],rect[3] do
      local sq = cell:getGridSquare(x,y,rect[5] or 0)
      if sq and sq.setHighlighted then
        sq:setHighlighted(true); if sq.setHighlightColor then sq:setHighlightColor(0,1,0) end
        table.insert(T.hi, sq)
      end
    end
  end
end

function AF_SelectArea.start(tag, player, cb)
  clearHi()
  T.active = true
  T.tag = tag or ""
  T.p = player or getSpecificPlayer(0)
  T.z = (T.p and T.p:getZ()) or 0
  T.a, T.b, T.cb = nil, nil, (type(cb)=="function" and cb or function() end)
  Events.OnMouseDown.Add(AF_SelectArea.onMouseDown)
  Events.OnMouseUp.Add(AF_SelectArea.onMouseUp)
  Events.OnMouseMove.Add(AF_SelectArea.onMouseMove)
end

local function stop(andReturn)
  Events.OnMouseDown.Remove(AF_SelectArea.onMouseDown)
  Events.OnMouseUp.Remove(AF_SelectArea.onMouseUp)
  Events.OnMouseMove.Remove(AF_SelectArea.onMouseMove)
  local r = andReturn and toRect(T.a, T.b) or nil
  T.active=false; local cb=T.cb; T.cb=nil; paintRect(nil)
  if cb then cb(r) end
end

function AF_SelectArea.onMouseDown(x,y)
  if not T.active then return end
  local mx,my = getMouseXScaled(), getMouseYScaled()
  local sq,wx,wy = toSq(mx,my,T.z); if not sq then return end
  AFLOG("AREA","down",mx,my,"->",wx,wy,"z",T.z)
  T.a = {sq:getX(), sq:getY()}
  T.b = {sq:getX(), sq:getY()}
  paintRect(toRect(T.a, T.b))
end

function AF_SelectArea.onMouseMove(dx,dy)
  if not T.active or not T.a then return end
  local mx,my = getMouseXScaled(), getMouseYScaled()
  local sq,wx,wy = toSq(mx,my,T.z); if not sq then return end
  AFLOG("AREA","move",mx,my,"->",wx,wy,"z",T.z)
  T.b = {sq:getX(), sq:getY()}
  paintRect(toRect(T.a, T.b))
end

function AF_SelectArea.onMouseUp(x,y)
  if not T.active or not T.a then return end
  local mx,my = getMouseXScaled(), getMouseYScaled()
  local sq,wx,wy = toSq(mx,my,T.z)
  AFLOG("AREA","up",mx,my,"->",wx,wy,"z",T.z)
  -- ensure non-zero size (allow 1x1)
  stop(true)
end

