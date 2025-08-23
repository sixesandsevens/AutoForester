-- media/lua/client/AutoForester_Context.lua
require "AF_Log"
require "AF_TwoClickSelect"
require "AutoForester_Core"
require "AutoChopTask"

local function addMenu(playerIndex, context, worldObjects, test)
    if test then return end
    local p = getSpecificPlayer(playerIndex) or getPlayer()
    if not p or not p:isAlive() then return end

    -- Designate wood pile immediately (no extra click)
    context:addOption("Designate Wood Pile Here", worldObjects, function()
        AF_Log.safe("setStockpile", function()
            local sq = AFCore.getMouseSquare(p)
            if not sq then 
                p:Say("No tile.") 
                return 
            end
            AFCore.setStockpile(sq)
            p:Say("Wood pile set.")
        end)
    end)

    -- Set Chop Area (two-click selector; confirm in a later context open)
    context:addOption("Set Chop Area…", worldObjects, function()
        AF_Select.pickArea(worldObjects, p, function(rect, area)
            if not rect then 
                p:Say("No area.") 
                return 
            end
            rect = AFCore.normalizeRect(rect)
            if not rect then 
                p:Say("No area.") 
                return 
            end
            AutoChopTask.setChopRect(rect, area)
            local w = area and area.areaWidth or AFCore.rectWidth(rect)
            local h = area and area.areaHeight or AFCore.rectHeight(rect)
            p:Say(string.format("Chop area: %dx%d.", w, h))
        end, "chop")
    end)

    -- Set Gather Area (optional two-click selector)
    context:addOption("Set Gather Area…", worldObjects, function()
        AF_Select.pickArea(worldObjects, p, function(rect, area)
            if not rect then 
                p:Say("No area.") 
                return 
            end
            rect = AFCore.normalizeRect(rect)
            if not rect then 
                p:Say("No area.") 
                return 
            end
            AutoChopTask.setGatherRect(rect, area)
            local w = area and area.areaWidth or AFCore.rectWidth(rect)
            local h = area and area.areaHeight or AFCore.rectHeight(rect)
            p:Say(string.format("Gather area: %dx%d.", w, h))
        end, "gather")
    end)

    -- If we are between first and second click, offer a confirm option
    if AF_Select.hasPending() then
        context:addOption("Confirm Area Corner", worldObjects, function()
            AF_Select.confirmPending(worldObjects, p)
        end)
    end

    -- Start AutoForester job
    context:addOption("Start AutoForester (Area)", worldObjects, function()
        AF_Log.safe("startAreaJob", function()
            AutoChopTask.startAreaJob(p)
        end)
    end)
end

-- Avoid duplicate additions and register the context menu filler
Events.OnFillWorldObjectContextMenu.RemoveByName("AutoForester-Context")
Events.OnFillWorldObjectContextMenu.Add(addMenu)