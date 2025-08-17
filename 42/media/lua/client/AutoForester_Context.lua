-- AutoForester context menu hook (ultra-defensive)

local ok, AFCore = pcall(require, "AutoForester_Core")
if not ok then
    print("[AutoForester][ERROR] Failed to require AutoForester_Core: " .. tostring(AFCore))
    AFCore = nil
end

local function getClickedSquare()
    -- Always safe-guard: sometimes vanilla passes us an empty worldobjects list
    local sq = getMouseSquare and getMouseSquare() or nil
    if sq and sq.getX then return sq end
    return nil
end

local function getSafeSquare(playerIndex, context, worldobjects, test)
    -- 1) Under the mouse
    local sq = getClickedSquare()
    if sq then return sq end

    -- 2) From the worldobjects list (may be {}, or contain non-IsoObjects)
    if worldobjects then
        -- worldobjects can be a Lua table or a Kahlua list; use length + iteration
        local first = worldobjects[1]
        if not first then
            -- try a generic iteration in case it's a Kahlua table
            for _, obj in pairs(worldobjects) do first = obj; break end
        end
        if first and first.getSquare then
            local s = first:getSquare()
            if s then return s end
        end
    end

    -- 3) From the player
    local p = getSpecificPlayer and getSpecificPlayer(playerIndex or 0) or nil
    if p and p.getSquare then
        local s = p:getSquare()
        if s then return s end
    end

    return nil
end

local function addContextMenuOptions(playerIndex, context, worldobjects, test)
    -- Always add a tiny debug entry so we know the hook ran
    context:addOption("AutoForester: Debug (hook loaded)", nil, function()
        local p = getSpecificPlayer and getSpecificPlayer(playerIndex or 0)
        if p and p.Say then p:Say("AutoForester hook OK") end
    end)

    if test then return end  -- the engine calls us once with test=true; don't do real work

    -- Now resolve a safe square; if we still don't have one, bail quietly.
    local sq = getSafeSquare(playerIndex, context, worldobjects, test)
    if not sq then return end

    local AFCore_ok = type(AFCore) == "table"
    if not AFCore_ok then return end

    context:addOption("Designate Wood Pile Here", sq, function(targetSq)
        AFCore.setStockpile(targetSq)
    end)

    if AFCore.hasStockpile and AFCore.hasStockpile() then
        context:addOption("Clear Wood Pile Marker", nil, function()
            AFCore.clearStockpile()
        end)
    end

    context:addOption("Auto-Chop Nearby Trees", sq, function()
        local player = getSpecificPlayer and getSpecificPlayer(playerIndex or 0)
        if not player then return end
        AFCore.startJob(player)
    end)
end

Events.OnFillWorldObjectContextMenu.Add(addContextMenuOptions)

print("[AutoForester] Context file loaded")

