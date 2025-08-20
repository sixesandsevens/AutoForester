require "AF_SelectAdapter"
require "AutoForester_Core"
require "AutoChopTask"
require "AutoForester_Debug"

local function addMenu(playerIndex, context, worldObjects, test)
  if test then return end
  local p = getSpecificPlayer(playerIndex or 0); if not p then return end

  context:addOption("Designate Wood Pile Here", worldObjects, function()
    AF_Select.pickSquare(worldObjects, p, function(sq)
      if not sq then p:Say("No tile."); return end
      AFCore.setStockpile(sq)
      p:Say("Wood pile set.")
    end)
  end)

  context:addOption("Chop Area: Drag & Release", worldObjects, function()
    AF_Select.pickArea(worldObjects, p, function(rect, area)
      if not rect then p:Say("No area."); return end
      AutoChopTask.chopRect = rect
      p:Say(("Chop area: %dx%d tiles."):format(area.areaWidth or (rect[3]-rect[1]+1), area.areaHeight or (rect[4]-rect[2]+1)))
    end, "chop")
  end)

  context:addOption("Gather Area: Drag & Release", worldObjects, function()
    AF_Select.pickArea(worldObjects, p, function(rect, area)
      if not rect then p:Say("No area."); return end
      AutoChopTask.gatherRect = rect
      p:Say(("Gather area: %dx%d tiles."):format(area.areaWidth or (rect[3]-rect[1]+1), area.areaHeight or (rect[4]-rect[2]+1)))
    end, "gather")
  end)

  context:addOption("Start AutoForester (Area)", worldObjects, function()
    AutoChopTask.startAreaJob(p)
  end)
end

Events.OnFillWorldObjectContextMenu.Add(addMenu)
