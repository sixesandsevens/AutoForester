-- AutoForester_Context.lua (patch build)
-- Registers context menu AFTER the game starts, to avoid nil calls in main menu.
-- Safe to drop into: Zomboid/mods/AutoForester/media/lua/client/

require "AF_SelectAdapter"      -- your existing adapter
require "AutoChopTask"          -- your existing task logic
require "AutoForester_Core"     -- AFCore helpers

local function addMenu(playerIndex, context, worldobjects, test)
    if test then return end
    local p = getSpecificPlayer(playerIndex) or getPlayer()
    if not p or not p:isAlive() then return end

    -- Designate stockpile (use tile under the mouse right now; no extra click)
    context:addOption("Designate Wood Pile Here", worldobjects, function()
        local sq = AFCore.getMouseSquare(p)
        if not sq then p:Say("No tile."); return end
        AFCore.setStockpile(sq); p:Say("Wood pile set.")
    end)

    -- Set chop area
    context:addOption("Set Chop Area…", worldobjects, function()
        AF_Select.pickArea(worldobjects, p, function(rect, area)
            if not rect or rect == 0 then p:Say("No area."); return end
            rect = AFCore.normalizeRect(rect)
            if not rect then p:Say("No area."); return end
            AutoChopTask.setChopRect(rect, area)
            local w = (area and area.areaWidth) or (rect[3]-rect[1]+1)
            local h = (area and area.areaHeight) or (rect[4]-rect[2]+1)
            p:Say(("Chop area: %dx%d."):format(w,h))
        end, "chop")
    end)

    -- Set gather area
    context:addOption("Set Gather Area…", worldobjects, function()
        AF_Select.pickArea(worldobjects, p, function(rect, area)
            if not rect or rect == 0 then p:Say("No area."); return end
            rect = AFCore.normalizeRect(rect)
            if not rect then p:Say("No area."); return end
            AutoChopTask.setGatherRect(rect, area)
            local w = (area and area.areaWidth) or (rect[3]-rect[1]+1)
            local h = (area and area.areaHeight) or (rect[4]-rect[2]+1)
            p:Say(("Gather area: %dx%d."):format(w,h))
        end, "gather")
    end)

    context:addOption("Start AutoForester (Area)", worldobjects, function()
        AutoChopTask.startAreaJob(p)
    end)
end

local function registerContextMenu()
    if not Events or not Events.OnFillWorldObjectContextMenu then return end
    if Events.OnFillWorldObjectContextMenu.RemoveByName then
        Events.OnFillWorldObjectContextMenu.RemoveByName("AutoForester-Context")
    end
    Events.OnFillWorldObjectContextMenu.Add(addMenu)
    print("AutoForester (patch): context menu registered")
end

-- Defer registration until a save is loaded (fixes main-menu nil call).
Events.OnGameStart.Add(registerContextMenu)
