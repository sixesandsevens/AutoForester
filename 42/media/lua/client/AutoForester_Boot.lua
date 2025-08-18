-- Loads Core safely when the game has fully started.
local function bootCore()
    local ok, Core = pcall(require, "AutoForester_Core")
    if not ok or type(Core) ~= "table" then
        print("[AutoForester][BOOT][ERROR] require Core failed: "..tostring(Core))
        return
    end
    if Core.register then
        pcall(Core.register) -- registers watchdog etc.
        print("[AutoForester][BOOT] Core.register done")
    else
        print("[AutoForester][BOOT][WARN] Core.register missing")
    end
end

-- Prefer OnGameStart for SP; OnCreatePlayer is our fallback if needed.
if Events and Events.OnGameStart and Events.OnGameStart.Add then
    Events.OnGameStart.Add(bootCore)
elseif Events and Events.OnCreatePlayer and Events.OnCreatePlayer.Add then
    Events.OnCreatePlayer.Add(function() bootCore() end)
else
    -- absolute worst-case fallback: try again once a second until Events exist
    local function retry()
        if Events and Events.OnGameStart and Events.OnGameStart.Add then
            Events.OnGameStart.Add(bootCore)
            print("[AutoForester][BOOT] Registered via delayed retry")
        end
    end
    if Events and Events.EveryOneSecond and Events.EveryOneSecond.Add then
        Events.EveryOneSecond.Add(retry)
    end
end
