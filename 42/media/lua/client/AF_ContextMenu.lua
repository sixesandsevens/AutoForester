-- AF_ContextMenu.lua
require "ISUI/ISContextMenu"
require "AF_Selector"

AF = AF or {}

local function AF_ContextMenu(player, context, worldobjects)
    local sub = ISContextMenu:getNew(context)
    context:addSubMenu(context:addOption("AutoForester", worldobjects, nil), sub)

    sub:addOption("Select Chop Area (two clicks)", worldobjects, function()
        AF.Select.begin("chop", player)
    end)

    sub:addOption("Select Pile Area (two clicks)", worldobjects, function()
        AF.Select.begin("pile", player)
    end)

    sub:addOption("Mark Chop Area (player tile)", worldobjects, function()
        local p = getSpecificPlayer(player)
        local sq = p and p:getSquare() or nil
        if not sq then return end
        AF.Areas.setChopArea({ squares = { { x = sq:getX(), y = sq:getY(), z = sq:getZ() } } })
    end)

    sub:addOption("Mark Pile Area (player tile)", worldobjects, function()
        local p = getSpecificPlayer(player)
        local sq = p and p:getSquare() or nil
        if not sq then return end
        AF.Areas.setPileArea({ squares = { { x = sq:getX(), y = sq:getY(), z = sq:getZ() } } })
    end)

    sub:addOption("Start AutoForester", worldobjects, function()
        local p = getSpecificPlayer(player)
        if AF and AF.Run and AF.Run.start then AF.Run.start(p) end
    end)

    local md = ModData.getOrCreate("AutoForester")
    if md.areas and (md.areas.chop or md.areas.pile) then
        sub:addOption("Clear Designations", worldobjects, function()
            AF.Areas.clear()
        end)
    end
end

Events.OnFillWorldObjectContextMenu.Remove(AF_ContextMenu)
Events.OnFillWorldObjectContextMenu.Add(AF_ContextMenu)
