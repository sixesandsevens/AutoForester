AF = AF or {}
require "AF_Areas"
require "AF_SelectAdapter"

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
        if AF.Run and AF.Run.start then
            AF.Run.start(playerObj)
        else
            playerObj:Say("AutoForester: sweep/haul not wired yet.")
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
