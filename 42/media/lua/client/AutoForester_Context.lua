-- Context menu hook (robust + lazy-require)
local function dbg(msg) print("[AutoForester] "..tostring(msg)) end
dbg("Context file loaded")

local function getSafeSquare(playerIndex, worldobjects)
  -- mouse
  local sq = getMouseSquare and getMouseSquare() or nil
  if sq then return sq end
  -- worldobjects
  if worldobjects then
    local first = worldobjects.get and worldobjects:get(0) or worldobjects[1]
    if first and first.getSquare then
      local s = first:getSquare()
      if s then return s end
    end
  end
  -- player
  local p = getSpecificPlayer and getSpecificPlayer(playerIndex or 0)
  if p and p.getSquare then return p:getSquare() end
  return nil
end

local function lazyCore()
  local ok, mod = pcall(require, "AutoForester_Core")
  if not ok then
    print("[AutoForester][WARN] Core not available: "..tostring(mod))
    return nil
  end
  return mod
end

local function addContextMenuOptions(playerIndex, context, worldobjects, test)
  -- Prove hook is alive (always add)
  context:addOption("AutoForester: Debug (hook loaded)", nil, function()
    local p = getSpecificPlayer(playerIndex or 0)
    if p and p.Say then p:Say("AF: hook OK") end
  end)

  if test then return end

  local sq = getSafeSquare(playerIndex, worldobjects)
  -- show options even if we couldn't resolve a square yet; the callbacks re-resolve
  context:addOption("Designate Wood Pile Here", sq, function(targetSq)
    local core = lazyCore(); if not core then return end
    targetSq = targetSq or getSafeSquare(playerIndex, worldobjects)
    if targetSq then core.setStockpile(targetSq) end
  end)

  context:addOption("Auto-Chop Nearby Trees", sq, function()
    local core = lazyCore(); if not core then return end
    local p = getSpecificPlayer(playerIndex or 0)
    if p then core.startJob(p) end
  end)

  local core = lazyCore()
  if core and core.hasStockpile() then
    context:addOption("Clear Wood Pile Marker", nil, function()
      core.clearStockpile()
    end)
  end
end

-- Safe, deferred registration (handles load order)
local function registerAFContext()
  if Events and Events.OnFillWorldObjectContextMenu and Events.OnFillWorldObjectContextMenu.Add then
    Events.OnFillWorldObjectContextMenu.Add(addContextMenuOptions)
    print("[AutoForester] Context hook registered")
  else
    if Events and Events.OnCreatePlayer and Events.OnCreatePlayer.Add then
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
end
Events.OnGameStart.Add(registerAFContext)
