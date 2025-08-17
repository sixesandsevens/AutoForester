local AFCore = require("AutoForester_Core")

local function getClickedSquare(worldobjects)
    local sq = getMouseSquare()
    if sq then return sq end
    if worldobjects and worldobjects[1] then
        return worldobjects[1]:getSquare()
    end
    return nil
end

local function addMenu(playerNum, context, worldobjects, test)
    if test then return end

    local sq = getClickedSquare(worldobjects)
    if not sq then return end

    context:addOption("Designate Wood Pile Here", sq, function(targetSq)
        AFCore.setStockpile(targetSq)
    end)

    if AFCore.hasStockpile() then
        context:addOption("Clear Wood Pile Marker", nil, function()
            AFCore.clearStockpile()
        end)
    end

    context:addOption("Auto-Chop Nearby Trees", sq, function()
        local player = getSpecificPlayer(playerNum)
        AFCore.startJob(player)
    end)
end

Events.OnFillWorldObjectContextMenu.Add(addMenu)
