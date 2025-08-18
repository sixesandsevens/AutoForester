
-- AutoChopContext.lua: right-click menu for AutoForester (B42)

require "AutoChopTask"

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

    -- Auto chop
    local txt = string.format("Auto-Chop Trees (radius %d)", AutoChopTask.RADIUS)
    local opt = context:addOption(txt, sq, function(targetSq)
        targetSq = targetSq or getSafeSquare(playerIndex, worldObjects)
        AutoChopTask.start(player, targetSq)
    end)
    if not (player and AutoChopTask and (AutoChopTask.getAxe and AutoChopTask.getAxe(player))) then
        opt.notAvailable = true
        local tip = ISToolTip:new()
        tip.description = "Equip an axe to use this."
        opt.toolTip = tip
    end
end

Events.OnFillWorldObjectContextMenu.Add(onFillWorld)
Events.OnTick.Add(function() 
    if AutoChopTask and AutoChopTask.update then AutoChopTask.update() end
end)
