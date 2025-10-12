-- AF_Selector.lua
AF = AF or {}
AF.Select = AF.Select or {}

AF.Select.active = false
AF.Select.which = nil
AF.Select.start = nil
AF.Select.playerIndex = 0

local function _say(p, msg) if p and p.Say then p:Say(msg) end end

function AF.Select.begin(which, playerIndex)
    AF.Select.active = true
    AF.Select.which = which -- "chop" or "pile"
    AF.Select.start = nil
    AF.Select.playerIndex = playerIndex or 0
    local p = getSpecificPlayer(AF.Select.playerIndex)
    _say(p, "Click first corner...")
end

local function _finish(sel)
    local p = getSpecificPlayer(AF.Select.playerIndex)
    if AF.Select.which == "chop" then
        if AF.Areas and AF.Areas.setChopArea then AF.Areas.setChopArea(sel) end
        _say(p, "Chop area set.")
    else
        if AF.Areas and AF.Areas.setPileArea then AF.Areas.setPileArea(sel) end
        _say(p, "Pile area set.")
    end
    AF.Select.active = false
    AF.Select.start = nil
    AF.Select.which = nil
end

local function onMouseDown(x, y)
    if not AF.Select.active then return false end
    local sq = getMouseSquare()
    local p = getSpecificPlayer(AF.Select.playerIndex)
    if not sq then _say(p, "No square under mouse."); return true end

    if not AF.Select.start then
        AF.Select.start = { x = sq:getX(), y = sq:getY(), z = sq:getZ() }
        _say(p, "Now click opposite corner...")
    else
        local s = AF.Select.start
        local e = { x = sq:getX(), y = sq:getY(), z = sq:getZ() }
        local minx = math.min(s.x, e.x)
        local miny = math.min(s.y, e.y)
        local maxx = math.max(s.x, e.x)
        local maxy = math.max(s.y, e.y)
        local squares = {}
        for xx = minx, maxx do
            for yy = miny, maxy do
                table.insert(squares, { x = xx, y = yy, z = s.z })
            end
        end
        _finish({ squares = squares })
    end
    return true
end

Events.OnMouseDown.Remove(onMouseDown)
Events.OnMouseDown.Add(onMouseDown)
