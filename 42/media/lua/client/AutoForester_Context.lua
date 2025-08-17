-- AutoForester context menu hook (robust & B42-safe)
-- Fixes: wrong parameter order, nil getSquare(), missing fallbacks, no debug signal

local ok, AFCore = pcall(require, "AutoForester_Core")
if not ok then
    print("[AutoForester][ERROR] Failed to require AutoForester_Core: "..tostring(AFCore))
    AFCore = nil
end

local function dbg(msg) print("[AutoForester] "..tostring(msg)) end
dbg("Context file loaded")

-- Safely resolve a square for context actions:
-- 1) under-mouse tile
-- 2) any worldobject's square (if present and has getSquare)
-- 3) the player's current square
local function getSafeSquare(playerIndex, worldobjects)
    -- (1) under-mouse
    local sq = getMouseSquare()
    if sq then return sq end

    -- (2) try worldobjects
    if worldobjects then
        -- worldobjects is an ArrayList; use 0-based access via get()
        local size = worldobjects.size and worldobjects:size() or (#worldobjects or 0)
        if size and size > 0 then
            -- prefer index 0 if it's an ArrayList
            local first = worldobjects.get and worldobjects:get(0) or worldobjects[1]
            if first and first.getSquare then
                local wosq = first:getSquare()
                if wosq then return wosq end
            end
        end
    end

    -- (3) fallback to player's square
    local player = getSpecificPlayer(playerIndex or 0)
    if player and player.getSquare then
        return player:getSquare()
    end
    return nil
end

local function addContextMenuOptions(playerIndex, context, worldobjects, test)
    -- PZ probes with test=true; never mutate state during test pass.
    if test then return end

    -- Always show a tiny debug entry so we know the hook ran
    context:addOption("AutoForester: Debug (hook loaded)", nil, function()
        dbg("Debug context clicked")
        local p = getSpecificPlayer(playerIndex or 0)
        if p and p.Say then p:Say("AutoForester hook OK") end
    end)

    if not AFCore then
        dbg("AFCore unavailable; skipping menu items")
        return
    end

    -- Resolve a safe square to act on
    local sq = getSafeSquare(playerIndex, worldobjects)
    if not sq then
        dbg("No valid square resolved for context")
        return
    end

    -- Add our actions
    context:addOption("Designate Wood Pile Here", sq, function(targetSq)
        AFCore.setStockpile(targetSq)
    end)

    if AFCore.hasStockpile() then
        context:addOption("Clear Wood Pile Marker", nil, function()
            AFCore.clearStockpile()
        end)
    end

    context:addOption("Auto-Chop Nearby Trees", sq, function()
        local player = getSpecificPlayer(playerIndex or 0)
        if not player then
            dbg("No player resolved for Auto-Chop")
            return
        end
        AFCore.startJob(player)
    end)
end

-- Ensure we’re actually hooked
Events.OnFillWorldObjectContextMenu.Remove(addContextMenuOptions) -- idempotent safety
Events.OnFillWorldObjectContextMenu.Add(addContextMenuOptions)

