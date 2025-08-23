-- AutoForester_Context.lua
-- Context-menu entries for AutoForester (patched)
require "AF_SelectAdapter"
require "AutoChopTask"
require "AutoForester_Core"

local function addMenu(playerIndex, context, worldObjects, test)
  if test then return end
  local p = getSpecificPlayer(playerIndex or 0); if not p or not p:isAlive() then return end

  -- Designate Wood Pile by picking a single tile (uses the same, working area-picker path)
  context:addOption("Designate Wood Pile Here…", worldObjects, function()
    AF_Select.pickArea(worldObjects, p, function(rect, area)
      if not rect then p:Say("No tile."); return end
      -- Reduce to the top-left tile of the picked rect; this makes it robust even if the user drags more than 1x1
      local x = rect[1]; local y = rect[2]; local z = p:getZ() or 0
      local cell = getCell(); if not cell then p:Say("No cell."); return end
      local sq = cell:getGridSquare(x, y, z)
      if not sq then p:Say("No tile."); return end
      AFCore.setStockpile(sq); p:Say("Wood pile set.")
    end, "stockpile", {forceSquare = true})
  end)

  context:addOption("Set Chop Area…", worldObjects, function()
    AF_Select.pickArea(worldObjects, p, function(rect, area)
      if not rect then p:Say("No area."); return end
      AutoChopTask.setChopRect(rect, area)
      rect = AFCore.normalizeRect(rect)
      if not rect then p:Say("No area."); return end
      local w = (area and area.areaWidth) or (rect[3] - rect[1] + 1)
      local h = (area and area.areaHeight) or (rect[4] - rect[2] + 1)
      p:Say(("Chop area: %dx%d."):format(w, h))
    end, "chop")
  end)

  context:addOption("Set Gather Area…", worldObjects, function()
    AF_Select.pickArea(worldObjects, p, function(rect, area)
      if not rect then p:Say("No area."); return end
      AutoChopTask.setGatherRect(rect, area)
      rect = AFCore.normalizeRect(rect)
      if not rect then p:Say("No area."); return end
      local w = (area and area.areaWidth) or (rect[3] - rect[1] + 1)
      local h = (area and area.areaHeight) or (rect[4] - rect[2] + 1)
      p:Say(("Gather area: %dx%d."):format(w, h))
    end, "gather")
  end)
end

Events.OnFillWorldObjectContextMenu.RemoveByName("AutoForester-Context") -- clear previous (if hot-reloading)
Events.OnFillWorldObjectContextMenu.Add(addMenu, "AutoForester-Context")
