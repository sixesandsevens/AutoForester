-- media/lua/client/AutoForester_Context.lua
require "AutoForester_Debug"
require "AF_SelectAdapter"
require "AutoChopTask"
require "AutoForester_Core"

local function rectDims(rect, area)
  if not rect then return end
  local x1 = tonumber(rect[1]); local y1 = tonumber(rect[2])
  local x2 = tonumber(rect[3]); local y2 = tonumber(rect[4])
  if not (x1 and y1 and x2 and y2) then return end
  local w = (area and tonumber(area.areaWidth)) or (x2 - x1 + 1)
  local h = (area and tonumber(area.areaHeight)) or (y2 - y1 + 1)
  return w, h
end

local function addMenu(playerIndex, context, worldObjects, test)
  if test then return end
  local p = getSpecificPlayer(playerIndex or 0); if not p or not p:isAlive() then return end

  context:addOption("Designate Wood Pile Here", worldObjects, function()
    AF_Select.pickSquare(worldObjects, p, function(sq)
      if not sq then p:Say("No tile."); return end
      AFCore.setStockpile(sq); p:Say("Wood pile set.")
    end)
  end)

  context:addOption("Set Chop Area", worldObjects, function()
    AF_Select.pickArea(worldObjects, p, function(rect, area)
      if not rect then p:Say("No area."); return end
      AutoChopTask.setChopRect(rect, area)
      local w,h = rectDims(rect, area)
      if not w then p:Say("Area invalid."); return end
      p:Say(("Chop area: %dx%d."):format(w,h))
    end, "chop")
  end)

  context:addOption("Set Gather Area (optional)", worldObjects, function()
    AF_Select.pickArea(worldObjects, p, function(rect, area)
      if not rect then p:Say("No area."); return end
      AutoChopTask.setGatherRect(rect, area)
      local w,h = rectDims(rect, area)
      if not w then p:Say("Area invalid."); return end
      p:Say(("Gather area: %dx%d."):format(w,h))
    end, "gather")
  end)

  context:addOption("Start AutoForester (Area)", worldObjects, function()
    AutoChopTask.startAreaJob(p)
  end)
end

local function __af_hookContext()
  Events.OnFillWorldObjectContextMenu.Remove(addMenu)
  Events.OnFillWorldObjectContextMenu.Add(addMenu)
end
Events.OnGameStart.Add(__af_hookContext)
Events.OnInitWorld.Add(__af_hookContext)
