require "AutoForester_Debug"
local Tool = Tool or {}
AF_SelectArea = Tool

local function getMouseSq()
  local p = AF_getPlayer()
  if not p then return nil end
  local z = p:getZ()
  local wx, wy = ISCoordConversion.ToWorld(getMouseX(), getMouseY(), z)
  return getCell():getGridSquare(wx, wy, z)
end

local function makeRect(aSq, bSq)
  if not aSq or not bSq then return nil end
  local ax,ay,az = aSq:getX(), aSq:getY(), aSq:getZ()
  local bx,by,bz = bSq:getX(), bSq:getY(), bSq:getZ()
  local x1,x2 = math.min(ax,bx), math.max(ax,bx)
  local y1,y2 = math.min(ay,by), math.max(ay,by)
  return {x1, y1, x2, y2, az}
end

local highlighted = {}
local function clearHighlight()
  for _,sq in ipairs(highlighted) do if sq then sq:setHighlighted(false) end end
  highlighted = {}
end
local function addHighlight(rect)
  clearHighlight()
  if not rect then return end
  local x1,y1,x2,y2,z = rect[1],rect[2],rect[3],rect[4],rect[5] or 0
  local cell = getCell()
  for y=y1,y2 do
    for x=x1,x2 do
      local sq = cell:getGridSquare(x,y,z)
      if sq then
        sq:setHighlighted(true); sq:setHighlightColor(0,1,0,0.6)
        table.insert(highlighted, sq)
      end
    end
  end
end

function Tool.start(kind)
  Tool.active  = true
  Tool.kind    = kind
  Tool.startSq = getMouseSq()
  Tool.rect    = nil
  clearHighlight()
  if not Tool.startSq then AFLOG("SelectArea.start: startSq=nil") end
end

function Tool.cancel()
  Tool.active, Tool.kind, Tool.startSq, Tool.rect = false, nil, nil, nil
  clearHighlight()
end

function Tool.onMouseMove(dx,dy)
  if not Tool.active or not Tool.startSq then return false end
  local cur = getMouseSq()
  if not cur then return false end
  Tool.rect = makeRect(Tool.startSq, cur)
  addHighlight(Tool.rect)
  return true
end

function Tool.onMouseUp(x,y)
  if not Tool.active or not Tool.startSq then return false end
  local cur = getMouseSq()
  if not cur then Tool.cancel(); return true end
  Tool.rect = makeRect(Tool.startSq, cur)
  addHighlight(Tool.rect)
  local p = AF_getPlayer()
  if Tool.rect then
    if Tool.kind == "chop" then
      AutoChopTask = AutoChopTask or {}
      AutoChopTask.chopRect = Tool.rect
      AFSAY(p, "Chop area set.")
    else
      AutoChopTask = AutoChopTask or {}
      AutoChopTask.gatherRect = Tool.rect
      AFSAY(p, "Gather area set.")
    end
    AF_DUMP("areaSet:"..Tool.kind)
  end
  Tool.cancel()
  return true
end

if not _AF_SA_HOOKED then
  Events.OnMouseMove.Add(Tool.onMouseMove)
  Events.OnMouseUp.Add(Tool.onMouseUp)
  _AF_SA_HOOKED = true
  AFLOG("SelectArea: mouse hooks registered")
end
