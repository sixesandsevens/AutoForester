-- media/lua/client/AF_Context.lua
local AF_Log = require "AF_Log"
local AFCore = require "AF_Core"
local AF_Select = require "AF_TwoClickSelect"

AutoChopTask = AutoChopTask or { chopRect = nil, gatherRect = nil }

function AutoChopTask.setChopRect(rect, area)   AutoChopTask.chopRect = rect end
function AutoChopTask.setGatherRect(rect, area) AutoChopTask.gatherRect = rect end

local function addMenu(playerIndex, context, worldobjects, test)
    if test then return end
    local p = getSpecificPlayer(playerIndex) or getPlayer()
    if not p or p:isAlive() == false then return end

    context:addOption("Designate Wood Pile Here", worldobjects, function()
        local sq = AFCore.getMouseSquare(p)
        if not sq then p:Say("No tile."); return end
        AFCore.setStockpile(sq); p:Say("Wood pile set.")
    end)

    context:addOption("Set Chop Area...", worldobjects, function()
        AF_Select.pickArea(worldobjects, p, function(rect, area)
            if not rect then p:Say("No area."); return end
            rect = AFCore.normalizeRect(rect)
            if not rect then p:Say("No area."); return end
            AutoChopTask.setChopRect(rect, area)
            local w = (area and area.areaWidth) or (rect[3]-rect[1]+1)
            local h = (area and area.areaHeight) or (rect[4]-rect[2]+1)
            p:Say(("Chop area: %dx%d."):format(w, h))
        end, "chop")
    end)

    context:addOption("Set Gather Area...", worldobjects, function()
        AF_Select.pickArea(worldobjects, p, function(rect, area)
            if not rect then p:Say("No area."); return end
            rect = AFCore.normalizeRect(rect)
            if not rect then p:Say("No area."); return end
            AutoChopTask.setGatherRect(rect, area)
            local w = (area and area.areaWidth) or (rect[3]-rect[1]+1)
            local h = (area and area.areaHeight) or (rect[4]-rect[2]+1)
            p:Say(("Gather area: %dx%d."):format(w, h))
        end, "gather")
    end)

    context:addOption("Start AutoForester (Area)", worldobjects, function()
        if not AutoChopTask.chopRect then p:Say("Set chop area first."); return end
        if not AFCore.getStockpile() and not AutoChopTask.gatherRect then
            p:Say("Set pile or gather area first."); return end
        p:Say("AutoForester would start now (placeholder).")
        AF_Log.info("Start requested. ChopRect:", table.concat(AutoChopTask.chopRect, ","))
    end)
end

-- Try to keep only one copy of our context adder active
pcall(function() Events.OnFillWorldObjectContextMenu.RemoveByName("AutoForester-Context") end)
Events.OnFillWorldObjectContextMenu.Add(addMenu)
