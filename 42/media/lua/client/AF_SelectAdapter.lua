-- media/lua/client/AF_SelectAdapter.lua
require "ISCoordConversion"

AF_Select = AF_Select or {}
AF_Select.DEFAULT_SIZE = AF_Select.DEFAULT_SIZE or 13

local function _firstSquareFromWorldObjects(worldobjects)
    if not worldobjects or type(worldobjects) ~= "table" then return nil end
    for i=1,#worldobjects do
        local o = worldobjects[i]
        if o then
            if o.getSquare and o:getSquare() then return o:getSquare() end
            if o.square then return o.square end
        end
    end
    return nil
end

-- Convert mouse -> square
local function _mouseSquare(p)
    local mx,my = getMouseXScaled(), getMouseYScaled()
    local wx = ISCoordConversion.ToWorldX(mx,my,0)
    local wy = ISCoordConversion.ToWorldY(mx,my,0)
    local z = (p and p.getZ and p:getZ()) or 0
    local cell = getCell(); if not cell then return nil end
    return cell:getGridSquare(math.floor(wx), math.floor(wy), z)
end

local function _rectAroundSquare(sq, size)
    local half = math.floor((size or AF_Select.DEFAULT_SIZE)/2)
    local x, y, z = sq:getX(), sq:getY(), sq:getZ()
    return { x-half, y-half, x+half, y+half, z }
end

-- Always returns a square (best-effort)
function AF_Select.pickSquare(worldobjects, playerObjOrIndex, callback)
    local p = playerObjOrIndex; if type(p) == "number" then p = getSpecificPlayer(p) end
    local sq = _firstSquareFromWorldObjects(worldobjects) or _mouseSquare(p) or (p and p.getSquare and p:getSquare()) or nil
    if callback then callback(sq) end
end

-- For now we use click-to-center rectangle (no drag). Guarantees a rect.
function AF_Select.pickArea(worldobjects, playerObjOrIndex, callback, tag)
    local p = playerObjOrIndex; if type(p) == "number" then p = getSpecificPlayer(p) end
    local sq = _firstSquareFromWorldObjects(worldobjects) or _mouseSquare(p) or (p and p.getSquare and p:getSquare()) or nil
    if not sq then if callback then callback(nil) end; return end
    local rect = _rectAroundSquare(sq, AF_Select.DEFAULT_SIZE)
    if p and p.Say then
        local w = rect[3]-rect[1]+1; local h = rect[4]-rect[2]+1
        p:Say(string.format("[%s] Area set %dx%d @ %d,%d", tag or "AF", w, h, rect[1], rect[2]))
    end
    if callback then callback(rect) end
end
