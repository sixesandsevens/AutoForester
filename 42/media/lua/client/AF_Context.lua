-- AF_Context.lua - right-click menu entries
local AF_Log = require "AF_Logger"
local AFCore  = require "AF_Core"
local AF_Select = require "AF_TwoClickSelect"

local function addEntries(playerIndex, context, worldobjects, test)
    local p = getSpecificPlayer(playerIndex) or getPlayer()
    if not p or not p:isAlive() then return end

    -- Wood pile: take the tile under the mouse immediately
    context:addOption("Designate Wood Pile Here", worldobjects, function()
        AF_Log.safe("setStockpile", function()
            local sq = AFCore.getMouseSquare(p)
            if not sq then p:Say("No tile.") return end
            AFCore.setStockpile(sq); p:Say("Wood pile set.")
        end)
    end)

    -- Set Chop Area
    context:addOption("Set Chop Area...", worldobjects, function()
        AF_Log.safe("pickArea(chop)", function()
            AF_Select.pickArea(worldobjects, p, function(_, rect, size)
                if not rect then p:Say("No area.") return end
                _G.AF_LastChopRect = rect
                p:Say(("Chop area: %dx%d."):format(size.w, size.h))
            end, "chop")
        end)
    end)

    -- Set Gather Area
    context:addOption("Set Gather Area...", worldobjects, function()
        AF_Log.safe("pickArea(gather)", function()
            AF_Select.pickArea(worldobjects, p, function(_, rect, size)
                if not rect then p:Say("No area.") return end
                _G.AF_LastGatherRect = rect
                p:Say(("Gather area: %dx%d."):format(size.w, size.h))
            end, "gather")
        end)
    end)

    -- Start AutoForester (stub for now - prevents errors while we finish tasks)
    context:addOption("Start AutoForester", worldobjects, function()
        AF_Log.safe("start", function()
            if not AFCore.getStockpile() then p:Say("Set wood pile first.") return end
            if not _G.AF_LastChopRect then p:Say("Set chop area first.") return end
            if not _G.AF_LastGatherRect then p:Say("Set gather area first.") return end
            p:Say("AutoForester ready. (Tasks stubbed in this hotfix)")
        end)
    end)
end

Events.OnFillWorldObjectContextMenu.Add(addEntries)
