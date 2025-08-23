-- AFCore_overrides.lua
require "ISCoordConversion"

AFCore = AFCore or {}

-- Screen mouse (already scaled)
function AFCore.getMouseScaled()
    return getMouseXScaled(), getMouseYScaled()
end

-- Tile under mouse at the player's Z (no extra click)
function AFCore.getMouseSquare(p)
    local mx, my = AFCore.getMouseScaled()
    local wx = ISCoordConversion.ToWorldX(mx, my, 0)
    local wy = ISCoordConversion.ToWorldY(mx, my, 0)
    local z = (p and p:getZ()) or 0
    local cell = getCell()
    if not cell then return nil end
    return cell:getGridSquare(math.floor(wx), math.floor(wy), z)
end

-- Accept IsoRect-like or {x1,y1,x2,y2[,z]}
function AFCore.normalizeRect(rect)
    if not rect then return nil end
    local x1,y1,x2,y2,z
    if type(rect) == "table" and rect.getX then
        x1,y1,x2,y2 = rect:getX(), rect:getY(), rect:getX2(), rect:getY2()
        z = rect.z or 0
    else
        x1,y1,x2,y2 = tonumber(rect[1]), tonumber(rect[2]), tonumber(rect[3]), tonumber(rect[4])
        z = rect[5] or 0
    end
    if not x1 or not y1 or not x2 or not y2 then return nil end
    local rx1, ry1 = math.min(x1,x2), math.min(y1,y2)
    local rx2, ry2 = math.max(x1,x2), math.max(y1,y2)
    return {rx1, ry1, rx2, ry2, z}
end

function AFCore.rectWidth(rect)
    if type(rect) == "table" and rect.getX then
        return math.abs(rect:getX2() - rect:getX()) + 1
    end
    return math.abs(rect[3] - rect[1]) + 1
end

function AFCore.rectHeight(rect)
    if type(rect) == "table" and rect.getY then
        return math.abs(rect:getY2() - rect:getY()) + 1
    end
    return math.abs(rect[4] - rect[2]) + 1
end
