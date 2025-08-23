-- AutoForester_Context.lua
local function normRect(rect)
  if not rect then return nil end
  if rect.x1 then
    local x1,y1 = rect.x1, rect.y1
    local x2,y2 = rect.x2 or x1, rect.y2 or y1
    if x2 < x1 then x1,x2 = x2,x1 end
    if y2 < y1 then y1,y2 = y2,y1 end
    return {x1,y1,x2,y2}
  end
  local x1,y1,x2,y2 = rect[1], rect[2], rect[3], rect[4]
  if not x1 or not y1 or not x2 or not y2 then return nil end
  if x2 < x1 then x1,x2 = x2,x1 end
  if y2 < y1 then y1,y2 = y2,y1 end
  return {x1,y1,x2,y2}
end

local function say(p, msg) if p and p.Say then p:Say(msg) end end

AutoChopTask = AutoChopTask or {}
function AutoChopTask.setChopRect(rect, area) AutoChopTask.__chop = {rect=rect, area=area} end
function AutoChopTask.setGatherRect(rect, area) AutoChopTask.__gather = {rect=rect, area=area} end
function AutoChopTask.getRects() return AutoChopTask.__chop, AutoChopTask.__gather end
function AutoChopTask.clearRects() AutoChopTask.__chop, AutoChopTask.__gather = nil,nil end

local AF_Select = AF_Select or require("AF_SelectAdapter")

local function addMenu(playerNum, context, worldObjects, test)
  if test then return end
  local playerObj = getSpecificPlayer and getSpecificPlayer(playerNum) or nil
  if not playerObj then return end

  local root = context:addOption("AutoForester")
  local sub = ISContextMenu:getNew(context)
  context:addSubMenu(root, sub)

  sub:addOption("Set Chop Area…", worldObjects, function()
    AF_Select.pickArea(worldObjects, playerObj, function(rect, area)
      rect = normRect(rect)
      if not rect then say(playerObj, "No area."); return end
      AutoChopTask.setChopRect(rect, area)
      local w = (area and area.areaWidth) or (rect[3]-rect[1]+1)
      local h = (area and area.areaHeight) or (rect[4]-rect[2]+1)
      say(playerObj, string.format("Chop area: %dx%d.", w, h))
    end, "chop")
  end)

  sub:addOption("Set Gather Area…", worldObjects, function()
    AF_Select.pickArea(worldObjects, playerObj, function(rect, area)
      rect = normRect(rect)
      if not rect then say(playerObj, "No area."); return end
      AutoChopTask.setGatherRect(rect, area)
      local w = (area and area.areaWidth) or (rect[3]-rect[1]+1)
      local h = (area and area.areaHeight) or (rect[4]-rect[2]+1)
      say(playerObj, string.format("Gather area: %dx%d.", w, h))
    end, "gather")
  end)

  sub:addOption("Start AutoForester", worldObjects, function()
    local chop, gather = AutoChopTask.getRects()
    if not chop or not chop.rect then say(playerObj, "Select chop area first."); return end
    if not gather or not gather.rect then say(playerObj, "Select gather area first."); return end
    say(playerObj, "Starting AutoForester…")
  end)

  sub:addOption("Clear Areas", worldObjects, function()
    AutoChopTask.clearRects()
    say(playerObj, "Cleared chop/gather areas.")
  end)
end

if not _G.__AF_Context_Added then
  Events.OnFillWorldObjectContextMenu.Add(addMenu)
  _G.__AF_Context_Added = true
end
