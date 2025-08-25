AF = AF or {}
require "AF_Areas"
require "AF_SelectAdapter"

-- Load AF_Run in a tolerant way:
--  - supports modules that return a table (return M)
--  - or set a global AF_Run = M
--  - or set AF.Run = M
local function AF_requireRun()
    -- First try the normal require path
    local ok, modOrErr = pcall(require, "AF_Run")
    if ok and type(modOrErr) == "table" and type(modOrErr.start) == "function" then
        return modOrErr
    end

    -- Accept global-style modules too
    if _G.AF_Run and type(_G.AF_Run.start) == "function" then
        return _G.AF_Run
    end
    if AF and AF.Run and type(AF.Run.start) == "function" then
        return AF.Run
    end

    print("AutoForester: require('AF_Run') failed: " .. tostring(modOrErr))
    return nil
end

local function AF_ContextMenu(playerIndex, context, worldObjects, test)
    -- vanilla "test" hook handling mirrors base game behavior
    if test then
        if ISWorldObjectContextMenu.Test then return true end
        return ISWorldObjectContextMenu.setTest()
    end

    local playerObj = getSpecificPlayer(playerIndex)
    if not playerObj or playerObj:getVehicle() then return end

    -- Root menu
    local root = context:addOption("AutoForester", worldObjects, nil)
    local sub = ISContextMenu:getNew(context)
    context:addSubMenu(root, sub)

    -- Designation helpers
    sub:addOption("Designate Chop / Gather Area", worldObjects, function(wobjs)
        AF.Select.area(wobjs, playerObj, AF.Areas.setChopArea)
    end)

    sub:addOption("Designate Wood Pile (Area)", worldObjects, function(wobjs)
        AF.Select.area(wobjs, playerObj, AF.Areas.setPileArea)
    end)

    -- Start the worker
    sub:addOption("Start AutoForester", worldObjects, function()
        local runMod = AF_requireRun()
        if runMod and type(runMod.start) == "function" then
            runMod.start(playerObj)
        else
            playerObj:Say("AutoForester: couldn't load AF_Run (see console).")
        end
    end)

    -- Clear
    local md = ModData.getOrCreate("AutoForester")
    if md.areas and (md.areas.chop or md.areas.pile) then
        sub:addOption("Clear Designations", worldObjects, function()
            md.areas = {}
            ModData.transmit("AutoForester")
            playerObj:Say("Cleared AutoForester designations.")
        end)
    end
end

Events.OnFillWorldObjectContextMenu.Remove(AF_ContextMenu)
Events.OnFillWorldObjectContextMenu.Add(AF_ContextMenu)
