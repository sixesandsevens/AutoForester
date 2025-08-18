local function dbg(m) print("[AutoForester] "..tostring(m)) end
dbg("Context file loaded")

local function say(pi, txt) local p=getSpecificPlayer(pi or 0); if p and p.Say then p:Say(txt) end end

local function getSafeSquare(pi, wos)
  local sq = getMouseSquare and getMouseSquare() or nil
  if sq then return sq end
  if wos then
    local first = wos.get and wos:get(0) or wos[1]
    if first and first.getSquare then local s=first:getSquare(); if s then return s end end
  end
  local p=getSpecificPlayer and getSpecificPlayer(pi or 0)
  if p and p.getSquare then return p:getSquare() end
  return nil
end

local function core()
  local ok, mod = pcall(require, "AutoForester_Core")
  if not ok or type(mod)~="table" then
    print("[AutoForester][ERROR] require Core failed: "..tostring(mod))
    return nil
  end
  return mod
end

local function addMenu(pi, context, wos, test)
  -- heartbeat
  context:addOption("AutoForester: Debug (hook loaded)", nil, function() say(pi,"AF: hook OK") end)
  if test then return end

  local sq = getSafeSquare(pi, wos)

  context:addOption("Designate Wood Pile Here", sq, function(targetSq)
    local C = core()
    if not C then
      local p = getSpecificPlayer and getSpecificPlayer(pi or 0)
      if p and p.Say then p:Say("AutoForester core didn't load. Check console.") end
      return
    end
    C.setStockpile(targetSq or getSafeSquare(pi, wos))
  end)

  context:addOption("Auto-Chop Nearby Trees", sq, function()
    local C = core()
    if not C then
      local p = getSpecificPlayer and getSpecificPlayer(pi or 0)
      if p and p.Say then p:Say("AutoForester core didn't load. Check console.") end
      return
    end
    local p = getSpecificPlayer(pi or 0); if not p then say(pi,"No player"); return end
    C.startJob(p)
  end)

  local c=core()
  if c and c.hasStockpile() then
    context:addOption("Clear Wood Pile Marker", nil, function() c.clearStockpile() end)
  end
end

local function register()
  if Events and Events.OnFillWorldObjectContextMenu and Events.OnFillWorldObjectContextMenu.Add then
    Events.OnFillWorldObjectContextMenu.Add(addMenu)
    print("[AutoForester] Context hook registered")
  elseif Events and Events.OnCreatePlayer and Events.OnCreatePlayer.Add then
    Events.OnCreatePlayer.Add(function()
      if Events.OnFillWorldObjectContextMenu and Events.OnFillWorldObjectContextMenu.Add then
        Events.OnFillWorldObjectContextMenu.Add(addMenu)
        print("[AutoForester] Context hook registered (OnCreatePlayer)")
      else
        print("[AutoForester][WARN] Context event unavailable; skipping")
      end
    end)
  end
end
Events.OnGameStart.Add(register)
