
-- AutoChopContext.lua: right-click menu for AutoForester (B42)

require "AutoChopTask"
require "AF_SelectArea"

local function getSafeSquare(playerIndex, worldObjects)
    local ms = _G.getMouseSquare
    local sq = (type(ms)=="function") and ms() or nil
    if sq and sq.getX then return sq end

    if worldObjects then
        local first = (worldObjects.get and worldObjects:get(0)) or worldObjects[1]
        if first then
            if first.getSquare then
                local s = first:getSquare()
                if s then return s end
            elseif first.getX then
                return first -- it's already a square
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

    context:addOption("AutoForester: Debug (hook loaded)", nil, function()
        player:Say("Hook OK")
    end)

    local sq = getSafeSquare(playerIndex, worldObjects)

    -- Set stockpile
    context:addOption("Designate Log Stockpile Here", sq, function(targetSq)
        targetSq = targetSq or getSafeSquare(playerIndex, worldObjects)
        local container = nil
        if targetSq then
            local objs = targetSq:getObjects()
            if objs then
                for i=0, objs:size()-1 do
                    local obj = objs:get(i)
                    if obj and obj.getContainer and obj:getContainer() then
                        container = obj:getContainer()
                        break
                    end
                end
            end
            AutoChopTask.setDropAt(targetSq, container)
            if container then player:Say("Stockpile set (container).") else player:Say("Stockpile set (ground).") end
        end
    end)

    context:addOption("Cancel AutoForester Job", nil, function()
        if AutoChopTask and AutoChopTask.cancel then AutoChopTask.cancel("user cancel") end
        player:Say("Canceled.")
    end)

    context:addOption("AF: Dump State (debug)", nil, function()
        local p = getSpecificPlayer(playerIndex)
        local q = ISTimedActionQueue.getTimedActionQueue(p)
        p:Say(string.format("AF phase=%s active=%s queue=%d trees=%d idle=%d",
            tostring(AutoChopTask.phase),
            tostring(AutoChopTask.active),
            (q and q:size() or 0),
            (AutoChopTask.trees and #AutoChopTask.trees or 0),
            AutoChopTask.idleTicks))
    end)

    context:addOption("Select Chop Area (drag)", nil, function()
        AF_SelectArea.begin("chop")
    end)

    context:addOption("Select Gather Area (drag)", nil, function()
        AF_SelectArea.begin("gather")
    end)

    -- Auto chop
    local txt = string.format("Auto-Chop Trees (radius %d)", AutoChopTask.RADIUS)
    context:addOption(txt, sq, function(targetSq)
        targetSq = targetSq or getSafeSquare(playerIndex, worldObjects)
        local p = getSpecificPlayer(playerIndex)
        if not AutoChopTask.ensureAxeEquipped(p) then
            p:Say("I need an axe.")
            return
        end
        AutoChopTask.start(p, targetSq)
    end)
end

Events.OnFillWorldObjectContextMenu.Add(onFillWorld)
Events.OnTick.Add(function() 
    if AutoChopTask and AutoChopTask.update then AutoChopTask.update() end
end)
