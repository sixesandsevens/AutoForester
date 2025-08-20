-- AF_SelectArea.lua  (B42 safe)
local AutoChopTask = AutoChopTask or {} -- forward ref if file order loads this first
AF_SelectArea_EventsHooked = AF_SelectArea_EventsHooked or false

local Tool = {
  active      = false,
  kind        = nil,        -- "chop" | "gather"
  startSq     = nil,
  rect        = nil,        -- {x1,y1,x2,y2,z}
  highlighted = {}
}

local function getP(pi)
  if type(pi) == "number" then
    return getSpecificPlayer(pi)
  end
  return getSpecificPlayer and getSpecificPlayer(0) or getPlayer()
end

local function clearHighlight()
  for _,sq in ipairs(Tool.highlighted) do
    if sq and sq.setHighlighted then
      sq:setHighlighted(false)
    end
  end
  Tool.highlighted = {}
end

local function addHighlight(rect)
  clearHighlight()
  if not rect then return end
  local x1,y1,x2,y2,z = table.unpack(rect)
  local cell = getCell()
  for y = y1,y2 do
    for x = x1,x2 do
      local sq = cell:getGridSquare(x,y,z)
      if sq then
        sq:setHighlighted(true)
        sq:setHighlightColor(0,1,0,0.6)
        table.insert(Tool.highlighted, sq)
      end
    end
  end
end

local function makeRect(a, b)
  if not a or not b then return nil end
  local ax, ay, az = a:getX(), a:getY(), a:getZ()
  local bx, by, bz = b:getX(), b:getY(), b:getZ()
  if az ~= bz then bz = az end
  return {
    math.min(ax, bx),
    math.min(ay, by),
    math.max(ax, bx),
    math.max(ay, by),
    az,
  }
end

local function getMouseSquare()
  local p = getP()
  local z = p and p:getZ() or 0
  local wx, wy = ISCoordConversion.ToWorld(getMouseX(), getMouseY(), z)
  return getCell():getGridSquare(wx, wy, z)
end

function Tool.start(kind)
  Tool.active  = true
  Tool.kind    = kind
  Tool.startSq = getMouseSquare()
  Tool.rect    = nil
  clearHighlight()
  if not Tool.startSq then
    local p = getP()
    if p and p.Say then p:Say("No valid tile under cursor.") end
  end
end

function Tool.cancel()
  Tool.active = false
  Tool.kind   = nil
  Tool.startSq = nil
  Tool.rect   = nil
  clearHighlight()
end

-- Mouse hooks (called from your context menu entry)
function Tool.onMouseDown(x,y)
  if not Tool.active then return false end
  Tool.startSq = getMouseSquare()
  return true
end

function Tool.onMouseMove(dx,dy)
  if not Tool.active or not Tool.startSq then return false end
  local cur = getMouseSquare()
  if not cur then return false end
  Tool.rect = makeRect(Tool.startSq, cur)
  addHighlight(Tool.rect)
  return true
end

function Tool.onMouseUp(x,y)
  if not Tool.active or not Tool.startSq then return false end
  local cur = getMouseSquare()
  if not cur then
    Tool.cancel()
    return true
  end
  Tool.rect = makeRect(Tool.startSq, cur)
  addHighlight(Tool.rect)

  local p = getP()
  if Tool.rect then
    if Tool.kind == "chop" then
      AutoChopTask.chopRect = Tool.rect
      if p and p.Say then p:Say("Chop area set.") end
    else
      AutoChopTask.gatherRect = Tool.rect
      if p and p.Say then p:Say("Gather area set.") end
    end
    AF_DumpState("areaSet:"..Tool.kind)
  end
  Tool.cancel()
  return true
end

AF_SelectArea = Tool

if not AF_SelectArea_EventsHooked then
  Events.OnMouseDown.Add(AF_SelectArea.onMouseDown)
  Events.OnMouseMove.Add(AF_SelectArea.onMouseMove)
  Events.OnMouseUp.Add(AF_SelectArea.onMouseUp)
  AF_SelectArea_EventsHooked = true
  AFLOG("SelectArea: mouse events hooked")
end
return Tool

