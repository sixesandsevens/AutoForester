-- AF_SelectArea.lua (standalone area drag selector for B42)
require "ISCoordConversion"

AF_SelectArea = AF_SelectArea or {}

local T = {
  active = false,
  tag = "",
  p = nil,
  z = 0,
  a = nil, -- {x,y}
  b = nil, -- {x,y}
  hi = {}, -- highlighted squares
  cb = nil,
}

local function clearHi()
  for _,sq in ipairs(T.hi) do
    if sq and sq.setHighlighted then sq:setHighlighted(false) end
  end
  T.hi = {}
end

local function toWorldXY(mx, my)
  local wx = ISCoordConversion.ToWorldX(mx, my, 0)
  local wy = ISCoordConversion.ToWorldY(mx, my, 0)
  return math.floor(wx), math.floor(wy)
end

local function mouseSquare()
  local mx,my = getMouseXScaled(), getMouseYScaled()
  local x,y = toWorldXY(mx,my)
  local z = T.z or 0
  local cell = getCell()
  return cell and cell:getGridSquare(x, y, z) or nil
end

local function rectFromPoints(a, b)
  if not a or not b then return nil end
  local x1 = math.min(a[1], b[1])
  local y1 = math.min(a[2], b[2])
  local x2 = math.max(a[1], b[1])
  local y2 = math.max(a[2], b[2])
  return {x1, y1, x2, y2, T.z or 0}
end

local function paintRect(rect)
  clearHi()
  if not rect then return end
  local x1,y1,x2,y2,z = rect[1],rect[2],rect[3],rect[4],rect[5] or 0
  local cell = getCell(); if not cell then return end
  for y=y1,y2 do
    for x=x1,x2 do
      local sq = cell:getGridSquare(x,y,z)
      if sq and sq.setHighlighted then sq:setHighlighted(true) end
      table.insert(T.hi, sq)
    end
  end
end

local function stop(commit)
  if not T.active then return end
  local cb = T.cb
  paintRect(nil)
  clearHi()
  T.active=false; T.cb=nil; T.a=nil; T.b=nil
  Events.OnMouseDown.Remove(AF_SelectArea.onMouseDown)
  Events.OnMouseMove.Remove(AF_SelectArea.onMouseMove)
  Events.OnMouseUp.Remove(AF_SelectArea.onMouseUp)
  Events.OnKeyStartPressed.Remove(AF_SelectArea.onKey)
  if commit and cb and T.lastRect then
    local rect = T.lastRect
    local area = {
      tag = T.tag,
      minX = rect[0] or rect[1],
      minY = rect[1] or rect[2],
      maxX = rect[2] or rect[3],
      maxY = rect[3] or rect[4],
      z = rect[4] or rect[5] or 0,
      areaWidth = (rect[3]-rect[1])+1,
      areaHeight = (rect[4]-rect[2])+1,
    }
    cb(rect, area)
  elseif cb then
    cb(nil)
  end
end

function AF_SelectArea.onKey(key)
  if not T.active then return end
  -- ESC or right mouse cancel
  if key == Keyboard.KEY_ESCAPE then
    stop(false)
  end
end

function AF_SelectArea.onMouseDown(x,y)
  if not T.active then return end
  if not isMouseButtonDown(0) then return end -- left button only
  local sq = mouseSquare()
  if not sq then return end
  T.a = { sq:getX(), sq:getY() }
  T.b = T.a
  T.lastRect = rectFromPoints(T.a, T.b)
  paintRect(T.lastRect)
end

function AF_SelectArea.onMouseMove(x,y)
  if not T.active or not T.a then return end
  local sq = mouseSquare(); if not sq then return end
  T.b = { sq:getX(), sq:getY() }
  T.lastRect = rectFromPoints(T.a, T.b)
  paintRect(T.lastRect)
end

function AF_SelectArea.onMouseUp(x,y)
  if not T.active or not T.a then return end
  local sq = mouseSquare(); if not sq then return end
  T.b = { sq:getX(), sq:getY() }
  T.lastRect = rectFromPoints(T.a, T.b)
  stop(true)
end

function AF_SelectArea.start(tag, p, cb)
  if T.active then stop(false) end
  T.active=true; T.tag=tag or "area"; T.p=p; T.z=(p and p:getZ()) or 0; T.cb=cb; T.a=nil; T.b=nil; T.lastRect=nil
  Events.OnMouseDown.Add(AF_SelectArea.onMouseDown)
  Events.OnMouseMove.Add(AF_SelectArea.onMouseMove)
  Events.OnMouseUp.Add(AF_SelectArea.onMouseUp)
  Events.OnKeyStartPressed.Add(AF_SelectArea.onKey)
  if p and p.Say then p:Say("Drag to select "..T.tag.." area. ESC to cancel.") end
end

return AF_SelectArea
