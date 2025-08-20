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
  local z = a:getZ()
  return {
    math.min(a:getX(), b:getX()),
    math.min(a:getY(), b:getY()),
    math.max(a:getX(), b:getX()),
    math.max(a:getY(), b:getY()),
    z
  }
end

local function getMouseSquare()
  local mx,my = ISCoordConversion.ToWorld(getMouseX(), getMouseY(), 0)
  local p = getP()
  return getCell():getGridSquare(mx, my, p and p:getZ() or 0)
end

function Tool.start(kind)
  Tool.active  = true
  Tool.kind    = kind
  Tool.startSq = getMouseSquare()
  Tool.rect    = nil
  clearHighlight()
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
  local rect = makeRect(Tool.startSq, cur)
  Tool.rect = rect
  addHighlight(rect)
  return true
end

function Tool.onMouseUp(x,y)
  if not Tool.active then return false end
  local cur = getMouseSquare()
  Tool.rect = makeRect(Tool.startSq, cur)
  addHighlight(Tool.rect)

  local p = getP()
  if Tool.kind == "chop" then
    AutoChopTask.chopRect = Tool.rect
    if p and p.Say then p:Say("Chop area set.") end
  else
    AutoChopTask.gatherRect = Tool.rect
    if p and p.Say then p:Say("Gather area set.") end
  end
  AF_DumpState("areaSet:"..Tool.kind)
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

