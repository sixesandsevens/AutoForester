require "AutoForester_Core"
require "AF_SelectAdapter"
require "AutoChopTask"
require "AutoForester_Debug"

local function addMenu(playerIndex, context, worldObjects, test)
  if test then return end
  AFLOG("menu", "playerIndex=", tostring(playerIndex), "wos#=", tostring(worldObjects and #worldObjects or 0))
  local p = getSpecificPlayer(playerIndex or 0); if not p then return end

  context:addOption("Designate Wood Pile Here", worldObjects, function()
    AF_Select.pickSquare(worldObjects, p, function(sq)
      if not sq then p:Say("No tile."); return end
      AFCore.pileSq = sq
      if sq.setHighlighted then
        sq:setHighlighted(true)
        if sq.setHighlightColor then sq:setHighlightColor(0.95,0.85,0.2) end
      end
      p:Say("Wood pile set.")
      AFLOG("pile", "sq=", tostring(sq), sq and (sq:getX()..","..sq:getY()..","..sq:getZ()) or "nil")
    end)
  end)

  context:addOption("Chop Area: Drag & Release", worldObjects, function()
    AF_Select.pickArea(worldObjects, p, function(rect, area)
      if not rect then p:Say("No area."); return end
      AutoChopTask.chopRect = rect
      AFLOG("select", "rect=", rect and (rect[1]..","..rect[2].."->"..rect[3]..","..rect[4]) or "nil")
      p:Say(("Chop area: %dx%d"):format(area.areaWidth, area.areaHeight))
    end, "chop")
  end)

  context:addOption("Gather Area: Drag & Release", worldObjects, function()
    AF_Select.pickArea(worldObjects, p, function(rect, area)
      if not rect then p:Say("No area."); return end
      AutoChopTask.gatherRect = rect
      AFLOG("select", "rect=", rect and (rect[1]..","..rect[2].."->"..rect[3]..","..rect[4]) or "nil")
      p:Say(("Gather area: %dx%d"):format(area.areaWidth, area.areaHeight))
    end, "gather")
  end)

  context:addOption("Start AutoForester (Area)", worldObjects, function()
    AutoChopTask.startAreaJob(p)
  end)

  context:addOption("AF: Dump State (debug)", worldObjects, function()
    local c = AutoChopTask
    AFSAY(p, ("phase=area trees=%s chopRect=%s gatherRect=%s pile=%s"):format(
      "n/a",
      tostring(c and c.chopRect),
      tostring(c and c.gatherRect),
      tostring(AFCore.getStockpile())
    ))
  end)
end

Events.OnFillWorldObjectContextMenu.Add(addMenu)
