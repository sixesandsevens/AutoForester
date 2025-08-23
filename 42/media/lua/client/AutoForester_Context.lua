-- AutoForester_Context.lua
require "AF_SelectAdapter"
require "AutoChopTask"
local ok = pcall(function() require "AutoForester_Core" end)
if not ok then print("AF: failed to require core") end

local function addMenu(playerIndex, context, worldObjects, test)
    if test then return end
    local p = getSpecificPlayer(playerIndex or 0)
    if not p or not p:isAlive() then return end

    -- Wood pile: take the tile under the cursor (or from worldObjects) immediately
    context:addOption("Designate Wood Pile Here", worldObjects, function()
        local sq = AF_Select.getMenuSquare(worldObjects) or (AFCore and AFCore.getMouseSquare and AFCore.getMouseSquare(p)) or nil
        if not sq then p:Say("No tile."); return end
        AFCore.setStockpile(sq); p:Say("Wood pile set.")
    end)

    -- Set Chop Area
    context:addOption("Set Chop Area…", worldObjects, function()
        AF_Select.pickArea(worldObjects, p, function(rect, area)
            rect = AFCore and AFCore.normalizeRect and AFCore.normalizeRect(rect) or rect
            if not rect then p:Say("No area."); return end
            AutoChopTask.setChopRect(rect, area)
            local w = (area and area.areaWidth) or (rect[3]-rect[1]+1)
            local h = (area and area.areaHeight) or (rect[4]-rect[2]+1)
            p:Say(string.format("Chop area: %dx%d.", w, h))
        end, "chop")
    end)

    -- Set Gather Area (optional)
    context:addOption("Set Gather Area…", worldObjects, function()
        AF_Select.pickArea(worldObjects, p, function(rect, area)
            rect = AFCore and AFCore.normalizeRect and AFCore.normalizeRect(rect) or rect
            if not rect then p:Say("No area."); return end
            AutoChopTask.setGatherRect(rect, area)
            local w = (area and area.areaWidth) or (rect[3]-rect[1]+1)
            local h = (area and area.areaHeight) or (rect[4]-rect[2]+1)
            p:Say(string.format("Gather area: %dx%d.", w, h))
        end, "gather")
    end)

    context:addOption("Start AutoForester (Area)", worldObjects, function()
        AutoChopTask.startAreaJob(p)
    end)
end

Events.OnFillWorldObjectContextMenu.RemoveByName("AutoForester-Context")
Events.OnFillWorldObjectContextMenu.Add(addMenu)
