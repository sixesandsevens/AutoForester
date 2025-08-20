-- AutoForester_Context.lua
require "AutoForester_Debug"
require "AutoForester_Core"
require "AF_SelectArea"

local function addMenu(pi, context, worldobjects, test)
    if test then return end

    local p = AF_getPlayer(pi)
    if not p then AFLOG("addMenu","no player"); return end

    context:addOption("Chop Area: Set Corner", nil, function()
        AF_SelectArea.start("chop")
        AFSAY(p,"Chop area: drag and release.")
    end)

    context:addOption("Gather Area: Set Corner", nil, function()
        AF_SelectArea.start("gather")
        AFSAY(p,"Gather area: drag and release.")
    end)

    context:addOption("Designate Wood Pile Here", nil, function()
        local sq = AF_getContextSquare(worldobjects)
        AFCore.setStockpile(sq)
        if sq then AFSAY(p,"Wood pile set.") end
    end)

    context:addOption("Start AutoForester (Area)", nil, function()
        AFCore.startAreaJob(pi)
    end)

    if AFCore.pileSq then
        context:addOption("Clear Wood Pile Marker", nil, function() AFCore.clearStockpile() end)
    end
end

local function register()
    -- Correct hook: passes playerIndex, context, worldobjects, test.
    Events.OnFillWorldObjectContextMenu.Add(addMenu)
end
register()
