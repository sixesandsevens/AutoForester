-- media/lua/client/AutoForester_Context.lua
require "AutoForester_Debug"
require "AF_SelectAdapter"
require "AutoChopTask"
require "AutoForester_Core"

local function addMenu(playerIndex, context, worldObjects, test)
  if test then return end
  local p = getSpecificPlayer(playerIndex or 0); if not p or not p:isAlive() then return end

  -- Wood pile
  context:addOption("Designate Wood Pile Here", worldObjects, function()
    AF_Select.pickSquare(worldObjects, p, function(sq)
      if not sq then p:Say("No tile."); return end
      AFCore.setStockpile(sq)
      p:Say("Wood pile set.")
    end)
  end)

  if AFCore.getStockpile() then
    context:addOption("Clear Wood Pile Marker", worldObjects, function()
      AFCore.clearStockpile()
      p:Say("Wood pile cleared.")
    end)
  end

  -- Area select (drag & release)
  context:addOption("Chop Area: Drag & Release", worldObjects, function()
    AF_Select.pickArea(worldObjects, p, function(rect, area)
      if not rect then p:Say("No area."); return end
      AutoChopTask.chopRect = rect
      local w = (area and area.areaWidth) or (rect[3]-rect[1]+1)
      local h = (area and area.areaHeight) or (rect[4]-rect[2]+1)
      p:Say(("Chop area: %dx%d."):format(w,h))
    end, "chop")
  end)

  context:addOption("Gather Area: Drag & Release", worldObjects, function()
    AF_Select.pickArea(worldObjects, p, function(rect, area)
      if not rect then p:Say("No area."); return end
      AutoChopTask.gatherRect = rect
      local w = (area and area.areaWidth) or (rect[3]-rect[1]+1)
      local h = (area and area.areaHeight) or (rect[4]-rect[2]+1)
      p:Say(("Gather area: %dx%d."):format(w,h))
    end, "gather")
  end)

  -- Start
  context:addOption("Start AutoForester (Area)", worldObjects, function()
    AutoChopTask.startAreaJob(p)
  end)
end

Events.OnFillWorldObjectContextMenu.Add(addMenu)  -- only once; remove any duplicates

