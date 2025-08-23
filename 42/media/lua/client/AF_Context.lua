-- media/lua/client/AF_Context.lua
require "ISUI/ISWorldObjectContextMenu"

local AF_Context = {}

function AF_Context.worldobjects(player, context, worldobjects, test)
    if test then return end
    local p = getSpecificPlayer(player) or getPlayer()
    if not p or p:isDead() then return end

    -- Designate pile (no click+drag, just uses the tile under the cursor right now)
    context:addOption("Designate Wood Pile Here", worldobjects, function()
        local sq = AFCore.getMouseSquare(p)
        if not sq then p:Say("No tile."); return end
        AFCore.setStockpile(sq)
        p:Say("Wood pile set.")
    end)

    -- Set Chop Area (two-click)
    context:addOption("Set Chop Area...", worldobjects, function()
        AF_Select.pickArea(worldobjects, player, function(rect)
            rect = AFCore.normalizeRect(rect)
            if not rect then p:Say("No area."); return end
            AFCore.setArea("chop", rect)
            local w = rect[3]-rect[1]+1
            local h = rect[4]-rect[2]+1
            p:Say(("Chop area: %dx%d"):format(w,h))
        end, "chop")
    end)

    -- Set Gather Area (two-click)
    context:addOption("Set Gather Area...", worldobjects, function()
        AF_Select.pickArea(worldobjects, player, function(rect)
            rect = AFCore.normalizeRect(rect)
            if not rect then p:Say("No area."); return end
            AFCore.setArea("gather", rect)
            local w = rect[3]-rect[1]+1
            local h = rect[4]-rect[2]+1
            p:Say(("Gather area: %dx%d"):format(w,h))
        end, "gather")
    end)
end

-- Register once (prevents duplicated menu entries even after /reloadlua)
local function registerOnce()
    if AF_Context.__added then return end
    Events.OnFillWorldObjectContextMenu.Add(AF_Context.worldobjects)
    AF_Context.__added = true
    print("[AutoForester] context menu registered")
end
Events.OnGameStart.Add(registerOnce)
Events.OnCreatePlayer.Add(registerOnce)
registerOnce()  -- helpful during dev reloads
