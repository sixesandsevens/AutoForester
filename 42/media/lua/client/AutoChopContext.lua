require "AutoForester_Debug"
local AFCore = require "AutoForester_Core"
require "AF_SelectArea"

local function addMenu(pi, context, wos, test)
  if test then return end

  local p = AF_getPlayer(pi)
  if not p then AFLOG("addMenu: no player"); return end

  context:addOption("AF: Dump State (debug)", nil, function()
    AF_DUMP("menu")
  end)

  context:addOption("Chop Area: Set Corner", nil, function()
    AF_SelectArea.start("chop")
    AFSAY(p, "Chop area: first corner set. Drag and release.")
  end)

  context:addOption("Gather Area: Set Corner", nil, function()
    AF_SelectArea.start("gather")
    AFSAY(p, "Gather area: first corner set. Drag and release.")
  end)

  local enabled = true -- you can gate on axe later
  context:addOption("Auto-Chop Trees (radius 12)", nil, function()
    if not enabled then AFSAY(p, "Equip an axe."); return end
    AFCore.startJob_playerRadius(pi, 12)
  end)

  context:addOption("Designate Wood Pile Here", nil, function()
    local sq = getSpecificPlayer(pi):getSquare()
    if not sq then return end
    AFCore.SetStockpile(sq)
    AFSAY(p, "Wood pile set "..sq:getX()..","..sq:getY())
  end)

  context:addOption("Cancel AutoForester Job", nil, function()
    AFCore.cancel()
    AFSAY(p, "Canceled.")
  end)
end

Events.OnFillWorldObjectContextMenu.Add(addMenu)
