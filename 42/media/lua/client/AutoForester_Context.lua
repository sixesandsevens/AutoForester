-- AutoForester_Context.lua
require "AutoForester_Core"
require "AF_SelectAdapter"

local function addMenu(playerIndex, context, worldObjects, test)
  if test then return end
  local p = getSpecificPlayer(playerIndex or 0); if not p then return end

  -- Designate wood pile (uses selection adapter for a single square)
  context:addOption("Designate Wood Pile Here", worldObjects, function(wos, pObj)
    local pp = pObj or p
    AF_Select.pickSquare(wos, pp, function(sq)
      if not sq then SAY(pp,"No tile."); return end
      AFCore.setStockpile(sq)
      SAY(pp,"Wood pile set.")
    end)
  end, p)

  -- Drag & release areas
  context:addOption("Chop Area: Drag & Release", worldObjects, function(wos, pObj)
    local pp = pObj or p
    AF_Select.pickArea(wos, pp, function(rect, area)
      if not rect then SAY(pp,"No area."); return end
      AFCore.chopRect = rect
      SAY(pp, ("Chop area: %dx%d"):format(area.areaWidth, area.areaHeight))
    end, "chop")
  end, p)

  context:addOption("Gather Area: Drag & Release", worldObjects, function(wos, pObj)
    local pp = pObj or p
    AF_Select.pickArea(wos, pp, function(rect, area)
      if not rect then SAY(pp,"No area."); return end
      AFCore.gatherRect = rect
      SAY(pp, ("Gather area: %dx%d"):format(area.areaWidth, area.areaHeight))
    end, "gather")
  end, p)

  context:addOption("Start AutoForester (Area)", worldObjects, function(wos, pObj)
    local pp = pObj or p
    AFCore.startAreaJob(pp, AFCore.chopRect, AFCore.gatherRect)
  end, p)
end

-- Make sure we only ever have one hook alive
Events.OnFillWorldObjectContextMenu.Remove(addMenu)
Events.OnFillWorldObjectContextMenu.Add(addMenu)
