-- AF_ContextMenu.lua (menu-driven two-step selector)
require "ISUI/ISContextMenu"
AF = AF or {}
AF.Select = AF.Select or { start=nil, which=nil, playerIndex=0 }

local function _mouseXY()
    local sq = getMouseSquare()
    if not sq then return nil end
    return sq:getX(), sq:getY(), sq:getZ()
end

local function _setFirst(which, player)
    local x,y,z = _mouseXY()
    if not x then return end
    AF.Select.start = { x=x, y=y, z=z }
    AF.Select.which = which
    AF.Select.playerIndex = player or 0
    local p = getSpecificPlayer(AF.Select.playerIndex)
    if p and p.Say then p:Say("First corner set ("..x..","..y.."). Now choose 'Finalize "..which.." selection here'.") end
end

local function _finalize(which, player)
    if not (AF.Select.start and AF.Select.which == which) then
        local p = getSpecificPlayer(player or 0)
        if p and p.Say then p:Say("Set the first corner for "..which.." first.") end
        return
    end
    local x2,y2,z2 = _mouseXY()
    if not x2 then return end
    local s = AF.Select.start
    local minx = math.min(s.x, x2); local miny = math.min(s.y, y2)
    local maxx = math.max(s.x, x2); local maxy = math.max(s.y, y2)
    local squares = {}
    for xx=minx,maxx do for yy=miny,maxy do table.insert(squares, {x=xx,y=yy,z=s.z}) end end
    local sel = { squares = squares }
    if which == "chop" then
        if AF.Areas and AF.Areas.setChopArea then AF.Areas.setChopArea(sel) end
    else
        if AF.Areas and AF.Areas.setPileArea then AF.Areas.setPileArea(sel) end
    end
    AF.Select.start=nil; AF.Select.which=nil
end

local function AF_ContextMenu(player, context, worldobjects)
    local sub = ISContextMenu:getNew(context)
    context:addSubMenu(context:addOption("AutoForester", worldobjects, nil), sub)

    sub:addOption("Set FIRST Chop Corner (here)", worldobjects, function() _setFirst("chop", player) end)
    sub:addOption("Finalize Chop Selection (here)", worldobjects, function() _finalize("chop", player) end)

    sub:addOption("Set FIRST Pile Corner (here)", worldobjects, function() _setFirst("pile", player) end)
    sub:addOption("Finalize Pile Selection (here)", worldobjects, function() _finalize("pile", player) end)

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
