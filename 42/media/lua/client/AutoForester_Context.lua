require "AF_Log"
require "AutoForester_Core"
require "AF_SelectAdapter"

local function getP(playerIndex)
    return getSpecificPlayer and getSpecificPlayer(playerIndex) or getPlayer()
end

local function addMenu(playerIndex, context, worldobjects)
    local p = getP(playerIndex)
    if not p or not p:isAlive() then return end

    -- Wood pile: take the tile under the mouse now
    context:addOption("Designate Wood Pile Here", worldobjects, function()
        AF.safe("setStockpile", function()
            local sq = AFCore.getMouseSquare(p)
            if not sq then AF.say(p, "No tile."); return end
            AFCore.setStockpile(sq); AF.say(p, "Wood pile set.")
        end)
    end)

    -- Set Chop Area
    context:addOption("Set Chop Area...", worldobjects, function()
        AF_Select.pickArea(worldobjects, p, function(rect, area)
            AF.safe("SetChopArea", function()
                rect = AFCore.normalizeRect(rect)
                if not rect then AF.say(p, "No area."); return end
                AutoChopTask.setChopRect(rect, area)
                local w = (area and area.areaWidth) or (rect[3]-rect[1]+1)
                local h = (area and area.areaHeight) or (rect[4]-rect[2]+1)
                AF.say(p, ("Chop area: %dx%d."):format(w,h))
            end)
        end)
    end)

    -- Set Gather Area (same pattern)
    context:addOption("Set Gather Area...", worldobjects, function()
        AF_Select.pickArea(worldobjects, p, function(rect, area)
            AF.safe("SetGatherArea", function()
                rect = AFCore.normalizeRect(rect)
                if not rect then AF.say(p, "No area."); return end
                AutoChopTask.setGatherRect(rect, area)
                local w = (area and area.areaWidth) or (rect[3]-rect[1]+1)
                local h = (area and area.areaHeight) or (rect[4]-rect[2]+1)
                AF.say(p, ("Gather area: %dx%d."):format(w,h))
            end)
        end)
    end)
end

Events.OnFillWorldObjectContextMenu.Add(addMenu)
