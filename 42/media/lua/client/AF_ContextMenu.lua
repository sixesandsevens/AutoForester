AF = AF or {}
require "AF_Areas"
require "AF_SelectAdapter"
local AF_Run = require "AF_Run"

local function AF_requireRun()
    if AF.Run and AF.Run.start then return true end
    local ok, err = pcall(require, "AF_Run")
    if not ok then
        print("AutoForester: require AF_Run failed: "..tostring(err))
        return false
    end
    return AF.Run and AF.Run.start
end

local function AF_ContextMenu(playerIndex, context, worldObjects, test)
    if test then
        if ISWorldObjectContextMenu.Test then return true end
        return ISWorldObjectContextMenu.setTest()
    end

    local playerObj = getSpecificPlayer(playerIndex)
    if not playerObj or playerObj:getVehicle() then return end

    local root = context:addOption("AutoForester", worldObjects, nil)
    local sub = ISContextMenu:getNew(context)
    context:addSubMenu(root, sub)

    sub:addOption("Designate Chop / Gather Area", worldObjects, function(wobjs)
        AF.Select.area(wobjs, playerObj, AF.Areas.setChopArea)
    end)

    sub:addOption("Designate Wood Pile (Area)", worldObjects, function(wobjs)
        AF.Select.area(wobjs, playerObj, AF.Areas.setPileArea)
    end)

    sub:addOption("Start AutoForester", worldObjects, function()
    local playerObj = getSpecificPlayer(0)
    if AF_requireRun() then
        AF.Run.start(playerObj)
    else
        playerObj:Say("AutoForester: couldn't load AF_Run (see console).")
    end
end)


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
