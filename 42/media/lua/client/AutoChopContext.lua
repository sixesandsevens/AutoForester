-- AutoChopContext.lua: right-click menu for AutoForester (B42)

local AFCore = require "AutoForester_Core"
require "AF_SelectArea"

local function itemIsAxe(it)
  if not it then return false end
  -- B42 weapons have tags; vanilla axes have Tag "Axe"
  if it.hasTag and it:hasTag("Axe") then return true end
  -- fallback heuristics
  local t = it.getType and it:getType() or ""
  if t:lower():find("axe") then return true end
  return false
end

local function hasAnyAxe(p)
  return itemIsAxe(p:getPrimaryHandItem()) or itemIsAxe(p:getSecondaryHandItem())
end

local function getSafeSquare(playerIndex, worldObjects)
  local ms = _G.getMouseSquare
  local sq = (type(ms) == "function") and ms() or nil
  if sq and sq.getX then return sq end

  if worldObjects then
    local first = (worldObjects.get and worldObjects:get(0)) or worldObjects[1]
    if first then
      if first.getSquare then
        local s = first:getSquare()
        if s then return s end
      elseif first.getX then
        return first
      end
    end
  end

  local p = getSpecificPlayer and getSpecificPlayer(playerIndex or 0)
  return p and p:getCurrentSquare() or nil
end

local function onFillWorld(playerIndex, context, worldObjects, test)
  if test then return end
  local player = getSpecificPlayer(playerIndex or 0)
  if not player or player:isDead() then return end

  local sq = getSafeSquare(playerIndex, worldObjects)

  context:addOption("Designate Log Stockpile Here", sq, function(targetSq)
    targetSq = targetSq or getSafeSquare(playerIndex, worldObjects)
    if targetSq then
      AFCore.setStockpile(targetSq)
      player:Say("Stockpile set.")
    end
  end)

  context:addOption("Cancel AutoForester Job", nil, function()
    AF_SelectArea.cancel()
    AFCore.cancel()
    player:Say("Canceled.")
  end)

  context:addOption("AF: Dump State (debug)", nil, function()
    player:Say(string.format("AF phase=%s trees=%d idle=%d", tostring(AFCore.phase), #(AFCore.trees or {}), AFCore.idleTicks or 0))
  end)

  context:addOption("Chop Area: Set Corner", nil, function()
    AF_SelectArea.start("chop")
  end)

  context:addOption("Gather Area: Set Corner", nil, function()
    AF_SelectArea.start("gather")
  end)

  local enabled = hasAnyAxe(player)
  context:addOption("Auto-Chop Trees (radius 12)", nil, function()
    if enabled then
      AFCore.startJob_playerRadius(player, 12)
    else
      player:Say("Equip an axe to use this.")
    end
  end).notAvailable = not enabled
end

Events.OnFillWorldObjectContextMenu.Add(onFillWorld)

