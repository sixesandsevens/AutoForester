-- AutoChopContext.lua: right-click menu for AutoForester (B42)

local AFCore = require "AutoForester_Core"
require "AF_SelectArea"

local function hasAxe(p)
  local function isAxeItem(it)
    if not it then return false end
    local ft = it:getFullType()
    return ft == "Base.Axe" or ft == "Base.HandAxe" or ft == "Base.StoneAxe" or it:hasTag("Axe")
  end
  local prim, sec = p:getPrimaryHandItem(), p:getSecondaryHandItem()
  return isAxeItem(prim) or isAxeItem(sec)
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
    AF_SelectArea.Clear()
    AFCore.cancel()
    player:Say("Canceled.")
  end)

  context:addOption("AF: Dump State (debug)", nil, function()
    player:Say(string.format("AF phase=%s trees=%d idle=%d", tostring(AFCore.phase), #(AFCore.trees or {}), AFCore.idleTicks or 0))
  end)

  context:addOption("Chop Area: Set Corner", nil, function()
    AF_SelectArea.Start("chop")
  end)

  context:addOption("Gather Area: Set Corner", nil, function()
    AF_SelectArea.Start("gather")
  end)

  if not hasAxe(player) then
    context:addOption("Auto-Chop Trees (radius 12)", nil, function()
      player:Say("Equip an axe to use this.")
    end):setTooltip(getText("Tooltip_RequireAxe"))
  else
    context:addOption("Auto-Chop Trees (radius 12)", nil, function()
      AFCore.startJob_playerRadius(player, 12)
    end)
  end
end

Events.OnFillWorldObjectContextMenu.Add(onFillWorld)

