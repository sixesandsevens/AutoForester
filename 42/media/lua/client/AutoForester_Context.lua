local function dbg(m) print("[AutoForester] "..tostring(m)) end
dbg("Context file loaded")

local function say(pi, txt)
  local p = getSpecificPlayer and getSpecificPlayer(pi or 0)
  if p and p.Say then p:Say(txt) end
end

local function getSafeSquare(pi, wos)
  -- 1) Mouse square (guarded)
  local ms = _G.getMouseSquare
  local sq = (type(ms)=="function") and ms() or nil
  if sq and sq.getX then return sq end

  -- 2) Worldobjects (ArrayList or Lua table)
  if wos then
    local first = (wos.get and wos:get(0)) or wos[1]
    if first and first.getSquare then
      local s = first:getSquare()
      if s then return s end
    end
  end

  -- 3) Player square
  local p = getSpecificPlayer and getSpecificPlayer(pi or 0)
  if p and p.getSquare then
    local ps = p:getSquare()
    if ps then return ps end
  end
  return nil
end

local function core()
  local ok, mod = pcall(require, "AutoForester_Core")
  if not ok or type(mod) ~= "table" then
    print("[AutoForester][ERROR] require Core failed: "..tostring(mod))
    return nil
  end
  return mod
end

local function addMenu(pi, context, wos, test)
  context:addOption("AutoForester: Debug (hook loaded)", nil, function() say(pi, "AF: hook OK") end)
  if test then return end

  local sq = getSafeSquare(pi, wos)

  context:addOption("Designate Wood Pile Here", sq, function(targetSq)
    local c = core(); if not c then say(pi,"Core missing"); return end
    targetSq = targetSq or getSafeSquare(pi, wos)
    if targetSq then c.setStockpile(targetSq); say(pi,"Wood pile set.") end
  end)

  context:addOption("Auto-Chop Nearby Trees", sq, function()
    local c = core(); if not c then say(pi,"Core missing"); return end
    local p = getSpecificPlayer(pi or 0); if not p then say(pi,"No player"); return end
    c.startJob(p)
  end)

  local c = core()
  if c and c.hasStockpile() then
    context:addOption("Clear Wood Pile Marker", nil, function() c.clearStockpile(); say(pi,"Wood pile cleared.") end)
  end
end

-- Safe, deferred registration
local function register()
  if Events and Events.OnFillWorldObjectContextMenu and Events.OnFillWorldObjectContextMenu.Add then
    Events.OnFillWorldObjectContextMenu.Add(addMenu)
    print("[AutoForester] Context hook registered")
  elseif Events and Events.OnCreatePlayer and Events.OnCreatePlayer.Add then
    Events.OnCreatePlayer.Add(function()
      if Events.OnFillWorldObjectContextMenu and Events.OnFillWorldObjectContextMenu.Add then
        Events.OnFillWorldObjectContextMenu.Add(addMenu)
        print("[AutoForester] Context hook registered (OnCreatePlayer)")
      end
    end)
  end
end
Events.OnGameStart.Add(register)
