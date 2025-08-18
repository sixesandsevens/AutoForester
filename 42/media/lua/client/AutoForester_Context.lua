local AFCore = require("AutoForester_Core")

local function say(pi, txt)
  local p = getSpecificPlayer and getSpecificPlayer(pi or 0)
  if p and p.Say then p:Say(txt) end
end

local function getSafeSquare(pi, wos)
  local ms = _G.getMouseSquare
  local sq = (type(ms)=="function") and ms() or nil
  if sq and sq.getX then return sq end
  if wos then
    local first = (wos.get and wos:get(0)) or wos[1]
    if first and first.getSquare then
      local s = first:getSquare(); if s then return s end
    end
  end
  local p = getSpecificPlayer and getSpecificPlayer(pi or 0)
  return p and p:getSquare() or nil
end

local function addMenu(pi, context, wos, test)
  context:addOption("AutoForester: Debug (hook loaded)", nil, function() say(pi,"AF: hook OK") end)
  if test then return end
  local sq = getSafeSquare(pi, wos)

  context:addOption("Designate Wood Pile Here", sq, function(targetSq)
    local c = AFCore; if not c then say(pi,"AutoForester core didn’t load. Check console."); return end
    targetSq = targetSq or getSafeSquare(pi, wos)
    if targetSq then c.setStockpile(targetSq); say(pi,"Wood pile set.") end
  end)

  context:addOption("Auto-Chop Nearby Trees", sq, function()
    local c = AFCore; if not c then say(pi,"AutoForester core didn’t load. Check console."); return end
    local p = getSpecificPlayer(pi or 0); if not p then say(pi,"No player"); return end
    c.startJob(p)
  end)

  local c = AFCore
  if c and c.hasStockpile() then
    context:addOption("Clear Wood Pile Marker", nil, function() c.clearStockpile(); say(pi,"Wood pile cleared.") end)
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
      end
    end)
  end
end
Events.OnGameStart.Add(register)
