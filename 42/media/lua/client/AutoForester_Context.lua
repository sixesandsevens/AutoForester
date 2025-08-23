-- AutoForester_Context.lua
require "AF_SelectAdapter"
require "AutoChopTask"
require "AutoForester_Core"  -- brings AFCore into scope

local MOD_EVENT_KEY = "AutoForester-Context"

local function addMenu(playerIndex, context, worldObjects, test)
    if test then return end
    local p = getSpecificPlayer(playerIndex) or getPlayer()
    if not p or not p:isAlive() then return end

    -- Wood pile: take the tile under the mouse immediately
    context:addOption("Designate Wood Pile Here", worldObjects, function()
        local sq = AFCore.getMouseSquare(p)
        if not sq then p:Say("No tile."); return end
        AFCore.setStockpile(sq)
        p:Say("Wood pile set.")
    end)

    -- Set chop area
    context:addOption("Set Chop Area…", worldObjects, function()
        AF_Select.pickArea(worldObjects, p, function(rect, area)
            if not rect or rect == 0 then p:Say("No area."); return end
            rect = AFCore.normalizeRect(rect)           -- normalize first
            if not rect then p:Say("No area."); return end
            AutoChopTask.setChopRect(rect, area)        -- then store
            local w = (area and area.areaWidth) or (rect[3]-rect[1]+1)
            local h = (area and area.areaHeight) or (rect[4]-rect[2]+1)
            p:Say(("Chop area: %dx%d."):format(w, h))
        end, "chop")
    end)

    -- Set gather area
    context:addOption("Set Gather Area…", worldObjects, function()
        AF_Select.pickArea(worldObjects, p, function(rect, area)
            if not rect or rect == 0 then p:Say("No area."); return end
            rect = AFCore.normalizeRect(rect)
            if not rect then p:Say("No area."); return end
            AutoChopTask.setGatherRect(rect, area)
            local w = (area and area.areaWidth) or (rect[3]-rect[1]+1)
            local h = (area and area.areaHeight) or (rect[4]-rect[2]+1)
            p:Say(("Gather area: %dx%d."):format(w, h))
        end, "gather")
    end)

    context:addOption("Start AutoForester (Area)", worldObjects, function()
        AutoChopTask.startAreaJob(p)
    end)
end

-- Register once; RemoveByName isn't available on this event in all builds
if not _G.__AF_CTX_REGISTERED then
    if Events and Events.OnFillWorldObjectContextMenu then
        -- Removing a non-existent function is safe in this environment
        pcall(function() Events.OnFillWorldObjectContextMenu.Remove(addMenu) end)
        Events.OnFillWorldObjectContextMenu.Add(addMenu)
        _G.__AF_CTX_REGISTERED = true
    end
end
