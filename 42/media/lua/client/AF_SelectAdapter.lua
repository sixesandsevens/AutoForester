-- AF_SelectAdapter.lua
AF_Select = AF_Select or {}
local _firstCorner = nil

-- Immediate square under mouse
function AF_Select.pickSquare(worldObjects, p, cb)
    local sq = AFCore.getMouseSquare(p)
    if cb then cb(sq) end
end

-- Fallback two-click area picker; works without external libs
function AF_Select.pickArea(worldObjects, p, cb, tag)
    if not _firstCorner then
        local sq = AFCore.getMouseSquare(p)
        if not sq then if p then p:Say("No tile.") end; return end
        _firstCorner = { sq:getX(), sq:getY(), sq:getZ() or 0 }
        if p then p:Say("First corner set. Pick opposite corner.") end
        return
    end
    local sq = AFCore.getMouseSquare(p)
    if not sq then if p then p:Say("No tile.") end; return end
    local rect = { _firstCorner[1], _firstCorner[2], sq:getX(), sq:getY(), _firstCorner[3] }
    _firstCorner = nil
    if cb then cb(rect, nil) end
end
