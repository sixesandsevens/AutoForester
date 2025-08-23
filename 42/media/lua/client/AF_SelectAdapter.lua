
AF_Select = AF_Select or {}

-- pick a single square with the vanilla build cursor
function AF_Select.pickSquare(worldobjects, p, onPicked)
    local function cb(sq)
        if onPicked then onPicked(sq) end
    end
    ISWorldObjectContextMenu.setTest()
    local cursor = ISChopTreeCursor:new("", "", p)
    cursor.onSquareSelected = function(self, x, y, z) cb(getCell():getGridSquare(x,y,z)) end
    getCell():setDrag(cursor, p:getPlayerNum())
    return true
end

-- rectangle drag selector (vanilla multi-stage build cursor uses area selection utils)
function AF_Select.pickArea(worldobjects, p, onPicked)
    local sx,sy,ex,ey = nil,nil,nil,nil
    local playerNum = p:getPlayerNum()
    local function finish()
        if sx and sy and ex and ey then
            local x1,y1 = math.min(sx,ex), math.min(sy,ey)
            local x2,y2 = math.max(sx,ex), math.max(sy,ey)
            onPicked({x1,y1,x2,y2, p:getZ()})
        else
            onPicked(nil)
        end
    end
    local function onDown(_, x,y)
        sx,sy = x,y
    end
    local function onUp(_, x,y)
        ex,ey = x,y
        finish()
    end
    -- fallback: if we can't hook mouse, just use player's current square to make a 13x13
    if not getCell() then onPicked(nil); return end
    -- Use player's square centered 13x13 if user doesn't drag properly
    if not isMouseButtonDown(0) then
        local sq = p:getSquare()
        if not sq then onPicked(nil); return end
        local cx,cy = sq:getX(), sq:getY()
        onPicked({cx-6, cy-6, cx+6, cy+6, sq:getZ()})
        return
    end
end
