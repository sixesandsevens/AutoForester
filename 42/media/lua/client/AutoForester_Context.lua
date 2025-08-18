-- AutoForester context menu (robust + loud)
local function dbg(msg) print("[AutoForester] "..tostring(msg)) end
dbg("Context file loaded")

local function say(playerIndex, text)
    local p = getSpecificPlayer and getSpecificPlayer(playerIndex or 0)
    if p and p.Say then p:Say(text) end
end

local function getSafeSquare(playerIndex, worldobjects)
    local sq = getMouseSquare and getMouseSquare() or nil
    if sq then return sq end
    if worldobjects then
        local first = worldobjects.get and worldobjects:get(0) or worldobjects[1]
        if first and first.getSquare then
            local s = first:getSquare()
            if s then return s end
        end
    end
    local p = getSpecificPlayer and getSpecificPlayer(playerIndex or 0)
    if p and p.getSquare then return p:getSquare() end
    return nil
end

local function lazyCore(playerIndex)
    local ok, mod = pcall(require, "AutoForester_Core")
    if not ok or type(mod) ~= "table" then
        local err = (not ok) and tostring(mod) or "module returned "..type(mod)
        print("[AutoForester][ERROR] require('AutoForester_Core') failed: "..err)
        say(playerIndex, "AutoForester core missing/failed. See console.")
        return nil
    end
    return mod
end

local function addContextMenuOptions(playerIndex, context, worldobjects, test)
    -- Heartbeat entry to prove the hook is alive
    context:addOption("AutoForester: Debug (hook loaded)", nil, function()
        say(playerIndex, "AF: hook OK")
    end)

    -- Always-on test button to prove callbacks execute
    context:addOption("AutoForester: Test Hello", nil, function()
        print("[AutoForester] Test Hello clicked")
        say(playerIndex, "Hello from AutoForester")
    end)

    if test then return end

    local sq = getSafeSquare(playerIndex, worldobjects)

    context:addOption("Designate Wood Pile Here", sq, function(targetSq)
        print("[AutoForester] Designate clicked")
        local core = lazyCore(playerIndex); if not core then return end
        targetSq = targetSq or getSafeSquare(playerIndex, worldobjects)
        if not targetSq then say(playerIndex, "No square"); return end
        core.setStockpile(targetSq)
        say(playerIndex, "Stockpile set.")
    end)

    context:addOption("Auto-Chop Nearby Trees", sq, function()
        print("[AutoForester] Auto-Chop clicked")
        local core = lazyCore(playerIndex); if not core then return end
        local p = getSpecificPlayer(playerIndex or 0)
        if not p then say(playerIndex, "No player"); return end
        core.startJob(p)
    end)

    -- Only show if a pile exists
    local core = lazyCore(playerIndex)
    if core and core.hasStockpile() then
        context:addOption("Clear Wood Pile Marker", nil, function()
            print("[AutoForester] Clear Stockpile clicked")
            local c = lazyCore(playerIndex); if not c then return end
            c.clearStockpile()
            say(playerIndex, "Stockpile cleared.")
        end)
    end
end

-- Safe, deferred registration to avoid nil Events during load
local function registerAFContext()
    if Events and Events.OnFillWorldObjectContextMenu and Events.OnFillWorldObjectContextMenu.Add then
        Events.OnFillWorldObjectContextMenu.Add(addContextMenuOptions)
        print("[AutoForester] Context hook registered")
    elseif Events and Events.OnCreatePlayer and Events.OnCreatePlayer.Add then
        Events.OnCreatePlayer.Add(function()
            if Events.OnFillWorldObjectContextMenu and Events.OnFillWorldObjectContextMenu.Add then
                Events.OnFillWorldObjectContextMenu.Add(addContextMenuOptions)
                print("[AutoForester] Context hook registered (OnCreatePlayer)")
            else
                print("[AutoForester][WARN] Context event unavailable; skipping")
            end
        end)
    end
end
Events.OnGameStart.Add(registerAFContext)
