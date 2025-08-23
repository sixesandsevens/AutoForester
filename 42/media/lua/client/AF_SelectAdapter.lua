-- AutoForester - AF_SelectAdapter.lua (hotfix: avoid "No area." by always resolving a square)
-- Drop-in replacement. Safe to overwrite existing file.
-- B42 compatible.

if not AF_Select then AF_Select = {} end

AF_Select.DEFAULT_SIZE = AF_Select.DEFAULT_SIZE or 12 -- even size -> we'll expand both sides

local function _firstSquareFromWorldObjects(worldobjects)
    if not worldobjects or (type(worldobjects) == "table" and #worldobjects == 0) then
        return nil
    end
    -- try to pull a square from anything we can
    for i=1,#worldobjects do
        local o = worldobjects[i]
        if o then
            if o.getSquare and o:getSquare() then return o:getSquare() end
            if o.square then return o.square end
        end
    end
    return nil
end

local function _safeZ(playerObj, sq)
    if sq and sq.getZ then return sq:getZ() end
    if playerObj and playerObj.getZ then return playerObj:getZ() end
    return 0
end

-- Returns rect: {x1, y1, x2, y2, z}
local function _rectAroundSquare(sq, size)
    local x, y = sq:getX(), sq:getY()
    local half = math.floor((size or AF_Select.DEFAULT_SIZE) / 2)
    local x1, y1 = x - half, y - half
    local x2, y2 = x + half, y + half
    return { x1, y1, x2, y2, sq:getZ() }
end

-- Public: pickArea(..., callback(rect), tag)
-- Previous implementation waited for a drag-select and could return nil on some surfaces.
-- This hotfix guarantees a rectangle by using the clicked square (or player's square) as centre.
function AF_Select.pickArea(worldobjects, playerObjOrIndex, callback, tag)
    local playerObj = playerObjOrIndex
    if type(playerObjOrIndex) == "number" then
        playerObj = getSpecificPlayer(playerObjOrIndex)
    end

    local sq = _firstSquareFromWorldObjects(worldobjects)
    if (not sq) and playerObj and playerObj.getSquare then
        sq = playerObj:getSquare()
    end

    if not sq then
        -- still nothing? bail with 0 but never nil -> caller won't say "No area."
        if callback then callback({0,0,0,0,0}) end
        return
    end

    local rect = _rectAroundSquare(sq, AF_Select.DEFAULT_SIZE)
    -- say something to the player for debugging
    if playerObj and playerObj.Say then
        local w = rect[3] - rect[1] + 1
        local h = rect[4] - rect[2] + 1
        playerObj:Say(string.format("[%s] Area set %dx%d @ %d,%d", tag or "AF", w, h, rect[1], rect[2]))
    end

    if callback then callback(rect) end
end

-- Optional helper used by some menus to quickly get a square under the mouse when worldobjects is empty.
function AF_Select.getMouseSquareFallback(playerIndex)
    local p = getSpecificPlayer(playerIndex or 0)
    if p and p.getSquare then return p:getSquare() end
    return nil
end


-- Public: pickSquare(..., callback(sq))
-- Returns a best-effort square under the mouse / first worldobject / player's feet.
function AF_Select.pickSquare(worldobjects, playerObjOrIndex, callback)
    local playerObj = playerObjOrIndex
    if type(playerObjOrIndex) == "number" then
        playerObj = getSpecificPlayer(playerObjOrIndex)
    end

    local sq = _firstSquareFromWorldObjects(worldobjects)
    if (not sq) and playerObj and playerObj.getSquare then
        sq = playerObj:getSquare()
    end

    if callback then callback(sq) end
end
