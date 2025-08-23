
require "AutoForester_Core"
require "AF_SelectAdapter"
require "AutoChopTask"

local function rectDims(rect, area)
    local x1,y1,x2,y2 = tonumber(rect[1]), tonumber(rect[2]), tonumber(rect[3]), tonumber(rect[4])
    local w = (x2 - x1 + 1)
    local h = (y2 - y1 + 1)
    return w,h
end

local function addMenu(playerIndex, context, worldobjects, test)
    if test then return end
    local p = getSpecificPlayer(playerIndex or 0); if not p or p:isDead() then return end

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
            local w,h = rectDims(rect, area)
            p:Say(("[chop] Area set %dx%d @ %d,%d"):format(w,h, rect[1],rect[2]))
            p:Say(("Chop area: %dx%d."):format(w,h))
        end, "chop")
    end)

    context:addOption("Set Gather Area (optional)", worldobjects, function()
        AF_Select.pickArea(worldobjects, p, function(rect, area)
            if not rect then p:Say("No area."); return end
            AutoChopTask.setGatherRect(rect, area)
            local w,h = rectDims(rect, area)
            p:Say(("[gather] Area set %dx%d @ %d,%d"):format(w,h, rect[1],rect[2]))
            p:Say(("Gather area: %dx%d."):format(w,h))
        end, "gather")
    end)

    context:addOption("Start AutoForester (Area)", worldobjects, function()
        AutoChopTask.startAreaJob(p)
    end)
end

Events.OnFillWorldObjectContextMenu.Add(addMenu)
