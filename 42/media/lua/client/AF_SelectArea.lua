-- 42/media/lua/client/AF_SelectArea.lua
local Debug = AutoForester_Debug or { on=false, log=function() end }
local Tool = { active=false, startSq=nil, rect=nil, kind="chop", highlighted={} }

local function getP()
  local p = getSpecificPlayer(0)
  if not p then return nil end
  return p
end

local function getMouseSq()
  local p = getP(); if not p then return nil end
  local z = p:getZ() or 0
  local mx, my = getMouseXScaled(), getMouseYScaled()
  local wx = ISCoordConversion.ToWorldX(mx, my, z)
  local wy = ISCoordConversion.ToWorldY(mx, my, z)
  local cell = getCell(); if not cell then return nil end
  return cell:getGridSquare(math.floor(wx), math.floor(wy), z)
end

local function clearHighlight()
  for _, sq in ipairs(Tool.highlighted) do
    if sq and sq.setHighlighted then sq:setHighlighted(false) end
  end
  Tool.highlighted = {}
end

local function addHighlight(rect)
  clearHighlight()
  if not rect then return end
  local x1,y1,x2,y2,z = rect[1],rect[2],rect[3],rect[4],rect[5] or 0
  local cell = getCell(); if not cell then return end
  for x=x1,x2 do
    for y=y1,y2 do
      local sq = cell:getGridSquare(x,y,z)
      if sq then
        if sq.setHighlighted then sq:setHighlighted(true) end
        -- setHighlightColor is not always present on B42 → guard it.
        if sq.setHighlightColor then
          -- some builds reject 4 args; try 4 then 3 quietly
          local ok = pcall(function() sq:setHighlightColor(0,1,0,0.6) end)
          if not ok then pcall(function() sq:setHighlightColor(0,1,0) end) end
        end
        table.insert(Tool.highlighted, sq)
      end
    end
  end
end

local function makeRect(a, b)
  if not a or not b then return nil end
  local z = a:getZ()
  local x1 = math.min(a:getX(), b:getX())
  local y1 = math.min(a:getY(), b:getY())
  local x2 = math.max(a:getX(), b:getX())
  local y2 = math.max(a:getY(), b:getY())
  return { x1,y1,x2,y2,z }
end

function Tool.start(kind)
  Tool.active = true
  Tool.kind   = kind
  Tool.startSq = getMouseSq()
  Tool.rect = nil
  clearHighlight()
  if Debug.on then Debug.log("AF_SelectArea.start kind=%s startSq=%s",
    tostring(kind), tostring(Tool.startSq and (Tool.startSq:getX()..","..Tool.startSq:getY()) or "nil")) end
end

function Tool.cancel()
  Tool.active = false
  Tool.kind, Tool.startSq, Tool.rect = nil, nil, nil
  clearHighlight()
end

function Tool.onMouseMove(dx,dy)
  if not Tool.active or not Tool.startSq then return false end
  local cur = getMouseSq(); if not cur then return false end
  Tool.rect = makeRect(Tool.startSq, cur)
  addHighlight(Tool.rect)
  return true
end

function Tool.onMouseUp(x,y)
  if not Tool.active or not Tool.startSq then return false end
  local cur = getMouseSq(); if not cur then return false end
  Tool.rect = makeRect(Tool.startSq, cur)
  addHighlight(Tool.rect)

  local p = getP(); if not p then Tool.cancel(); return true end
  if Tool.kind == "chop" then
    AutoChopTask.chopRect = Tool.rect
    p:Say("Chop area set.")
  else
    AutoChopTask.gatherRect = Tool.rect
    p:Say("Gather area set.")
  end
  Tool.cancel()
  return true
end

-- hook UI events
Events.OnMouseMove.Remove(Tool.onMouseMove); Events.OnMouseMove.Add(Tool.onMouseMove)
Events.OnMouseUp.Remove(Tool.onMouseUp);     Events.OnMouseUp.Add(Tool.onMouseUp)

AF_SelectArea = Tool
return Tool
