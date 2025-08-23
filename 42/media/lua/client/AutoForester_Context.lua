-- AutoForester_Context.lua
require "AutoForester_Core"
require "AF_SelectAdapter"
require "AutoChopTask"

local function addMenu(playerIndex, context, worldobjects, test)
    if test then return end
    local p = getSpecificPlayer(playerIndex or 0) or getPlayer()
    if not p or not p:isAlive() then return end

    -- Wood pile: take the tile under the mouse immediately
    context:addOption("Designate Wood Pile Here", worldobjects, function()
        local sq = AFCore.getMouseSquare(p)
        if not sq then p:Say("No tile."); return end
        AFCore.setStockpile(sq); p:Say("Wood pile set.")
    end)

    -- Set Chop Area
    context:addOption("Set Chop Area…", worldobjects, function()
        AF_Select.pickArea(worldobjects, p, function(rect, area)
            if not rect or rect == 0 then p:Say("No area."); return end
            rect = AFCore.normalizeRect(rect)
            if not rect then p:Say("No area."); return end
            AutoChopTask.setChopRect(rect, area)
            local w = (area and area.areaWidth) or AFCore.rectWidth(rect)
            local h = (area and area.areaHeight) or AFCore.rectHeight(rect)
            p:Say(("Chop area: %dx%d."):format(w, h))
        end, "chop")
    end)

    -- Set Gather Area
    context:addOption("Set Gather Area…", worldobjects, function()
        AF_Select.pickArea(worldobjects, p, function(rect, area)
            if not rect or rect == 0 then p:Say("No area."); return end
            rect = AFCore.normalizeRect(rect)
            if not rect then p:Say("No area."); return end
            AutoChopTask.setGatherRect(rect, area)
            local w = (area and area.areaWidth) or AFCore.rectWidth(rect)
            local h = (area and area.areaHeight) or AFCore.rectHeight(rect)
            p:Say(("Gather area: %dx%d."):format(w, h))
        end, "gather")
    end)

    context:addOption("Start AutoForester (Area)", worldobjects, function()
        AutoChopTask.startAreaJob(p)
    end)
end

Events.OnFillWorldObjectContextMenu.RemoveByName("AutoForester-Context")
Events.OnFillWorldObjectContextMenu.Add(addMenu)