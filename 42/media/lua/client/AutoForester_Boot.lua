local function bootCore()
  local ok, Core = pcall(require, "AutoForester_Core")
  if not ok or type(Core) ~= "table" then
    print("[AutoForester][BOOT][ERROR] require Core failed: "..tostring(Core))
    return
  end
  if Core.register then
    local ok2, err = pcall(Core.register)
    if not ok2 then print("[AutoForester][BOOT][ERROR] Core.register: "..tostring(err)) end
    print("[AutoForester][BOOT] Core.register done")
  end
end

if Events and Events.OnGameStart and Events.OnGameStart.Add then
  Events.OnGameStart.Add(bootCore)
elseif Events and Events.OnCreatePlayer and Events.OnCreatePlayer.Add then
  Events.OnCreatePlayer.Add(function() bootCore() end)
else
  -- last-resort retry
  if Events and Events.EveryOneSecond and Events.EveryOneSecond.Add then
    Events.EveryOneSecond.Add(function()
      if Events.OnGameStart and Events.OnGameStart.Add then
        Events.OnGameStart.Add(bootCore)
      end
    end)
  end
end
