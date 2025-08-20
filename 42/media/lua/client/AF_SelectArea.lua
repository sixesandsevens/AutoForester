AutoChopTask = AutoChopTask or {}

local Tool = {
  active = false,
  startSq = nil,
  rect = nil,
  highlighted = {},
  kind = "chop" -- or "gather", set by caller
}

local function clearHighlight()
  for _, sq in ipairs(Tool.highlighted) do
    if sq and sq.setHighlighted then sq:setHighlighted(false) end
  end
  Tool.highlighted = {}
end

local function addHighlight(rect)
  clearHighlight()
  if not rect then return end
  local x1, y1, x2, y2 = table.unpack(rect)
  local cell = getCell()
  for x = x1, x2 do
    for y = y1, y2 do
      local sq = cell:getGridSquare(x, y, 0)
      if sq and sq.setHighlighted then
        sq:setHighlighted(true)
        -- B42 NOTE: setHighlightColor is not guaranteed; do NOT call it.
        table.insert(Tool.highlighted, sq)
      end
    end
  end
end

local function makeRect(a, b)
  if not a or not b then return nil end
  local z = a:getZ()
  return { math.min(a:getX(), b:getX()), math.min(a:getY(), b:getY()),
           math.max(a:getX(), b:getX()), math.max(a:getY(), b:getY()), z }
end

function Tool.onMouseDown(x, y)
  if not Tool.active then return false end
  Tool.startSq = getMouseSquare()
  return false
end

function Tool.onMouseMove(dx, dy)
  if not Tool.active or not Tool.startSq then return false end
  local cur = getMouseSquare()
  if not cur then return false end
  Tool.rect = makeRect(Tool.startSq, cur)
  addHighlight(Tool.rect)
  return false
end

function Tool.onMouseUp(x, y)
  if not Tool.active then return false end
  local cur = getMouseSquare()
  if not cur then return false end
  Tool.rect = makeRect(Tool.startSq, cur)
  addHighlight(Tool.rect) -- final preview once more (safe)
  if Tool.kind == "chop" then
    AutoChopTask.chopRect = Tool.rect
    getPlayer():Say("Chop area set.")
  else
    AutoChopTask.gatherRect = Tool.rect
    getPlayer():Say("Gather area set.")
  end
  Tool.active = false
  return false
end

AF_SelectArea = {
  Start = function(kind)
    Tool.kind = kind or "chop"
    Tool.active = true
    Tool.startSq = nil
    Tool.rect = nil
    clearHighlight()
  end,
  Clear = clearHighlight
}

Events.OnMouseDown.Add(Tool.onMouseDown)
Events.OnMouseMove.Add(Tool.onMouseMove)
Events.OnMouseUp.Add(Tool.onMouseUp)

