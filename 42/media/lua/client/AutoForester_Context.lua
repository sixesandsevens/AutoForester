-- media/lua/client/AutoForester_Context.lua
require "AutoForester_Debug"
require "AF_SelectAdapter"
require "AutoChopTask"
require "AutoForester_Core"

local function dimsFrom(p, rect, area)
  local r = AFCore.normalizeRect(rect, (p and p:getZ()) or 0)
  if not r then return nil, nil end
  local w = (area and tonumber(area.areaWidth)) or (r[3] - r[1] + 1)
  local h = (area and tonumber(area.areaHeight)) or (r[4] - r[2] + 1)
  return w, h
end

local function addMenu(playerIndex, context, worldobjects, test)
  if test then return end
  local p = getSpecificPlayer(playerIndex or 0); if not p or not p:isAlive() then return end

  context:addOption("Designate Wood Pile Here", worldobjects, function()
    AF_Select.pickSquare(worldobjects, p, function(sq)
      if not sq then p:Say("No tile."); return end
      AFCore.setStockpile(sq); p:Say("Wood pile set.")
    end)
  end)

  context:addOption("Set Chop Area", worldobjects, function()
    AF_Select.pickArea(worldobjects, p, function(rect, area)
      if not rect then p:Say("No area."); return end
      AutoChopTask.setChopRect(rect, area)
      local w,h = dimsFrom(p, rect, area)
      if w and h then p:Say(("Chop area: %dx%d."):format(w,h)) else p:Say("Chop area set.") end
    end, "chop")
  end)

  context:addOption("Set Gather Area (optional)", worldobjects, function()
    AF_Select.pickArea(worldobjects, p, function(rect, area)
      if not rect then p:Say("No area."); return end
      AutoChopTask.setGatherRect(rect, area)
      local w,h = dimsFrom(p, rect, area)
      if w and h then p:Say(("Gather area: %dx%d."):format(w,h)) else p:Say("Gather area set.") end
    end, "gather")
  end)

  context:addOption("Start AutoForester (Area)", worldobjects, function()
    AutoChopTask.startAreaJob(p)
  end)
end

Events.OnFillWorldObjectContextMenu.Add(addMenu)
