-- AutoForester_Context.lua
require "AF_SelectAdapter"
require "AutoChopTask"
require "AutoForester_Core"

local function rectDims(rect, area)
  rect = AFCore.normalizeRect(rect)
  if not rect then return nil,nil end
  local w = (area and area.areaWidth)  or (rect[3]-rect[1]+1)
  local h = (area and area.areaHeight) or (rect[4]-rect[2]+1)
  return w,h
end

local function addMenu(playerIndex, context, worldObjects, test)
  if test then return end
  local p = getSpecificPlayer(playerIndex or 0); if not p or not p:isAlive() then return end

  -- Wood pile: take the tile under the mouse immediately
  context:addOption("Designate Wood Pile Here", worldObjects, function()
    local sq = AFCore.getMouseSquare(p)
    if not sq then p:Say("No tile."); return end
    AFCore.setStockpile(sq); p:Say("Wood pile set.")
  end)

  -- Set Chop Area
  context:addOption("Set Chop Area...", worldObjects, function()
    AF_Select.pickArea(worldObjects, p, function(rect, area)
      rect = AFCore.normalizeRect(rect)
      if not rect then p:Say("No area."); return end
      AutoChopTask.setChopRect(rect, area)
      local w,h = rectDims(rect, area)
      p:Say(("Chop area: %dx%d."):format(w,h))
    end, "chop")
  end)

  -- Set Gather Area
  context:addOption("Set Gather Area...", worldObjects, function()
    AF_Select.pickArea(worldObjects, p, function(rect, area)
      rect = AFCore.normalizeRect(rect)
      if not rect then p:Say("No area."); return end
      AutoChopTask.setGatherRect(rect, area)
      local w,h = rectDims(rect, area)
      p:Say(("Gather area: %dx%d."):format(w,h))
    end, "gather")
  end)

  context:addOption("Start AutoForester (Area)", worldObjects, function()
    AutoChopTask.startAreaJob(p)
  end)
end

Events.OnFillWorldObjectContextMenu.Add(addMenu)
