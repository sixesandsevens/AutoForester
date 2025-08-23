-- AFCore_overrides.lua (patch build)
-- Keeps your original AFCore but overrides specific helpers safely.

AFCore = AFCore or {}

function AFCore.getMouseSquare(p)
    local mx, my = getMouseScaled()
    local z = (p and p:getZ()) or 0
    local wx = ISCoordConversion.ToWorldX(mx, my, z)
    local wy = ISCoordConversion.ToWorldY(mx, my, z)
    local cell = getCell()
    if not cell then return nil end
    return cell:getGridSquare(math.floor(wx), math.floor(wy), z)
end

-- Accept either a Rect-like object (getX/getY/getX2/getY2) or an {x1,y1,x2,y2[,z]} array.
function AFCore.normalizeRect(r)
    if not r then return nil end
    if type(r) == "table" and r.getX then
        local x1, y1 = r:getX(), r:getY()
        local x2, y2 = r:getX2(), r:getY2()
        local z = r.getZ and r:getZ() or 0
        if x1 > x2 then x1, x2 = x2, x1 end
        if y1 > y2 then y1, y2 = y2, y1 end
        return {x1, y1, x2, y2, z}
    elseif type(r) == "table" then
        local x1, y1 = tonumber(r[1]), tonumber(r[2])
        local x2, y2 = tonumber(r[3]), tonumber(r[4])
        local z = tonumber(r[5]) or 0
        if not x1 or not y1 or not x2 or not y2 then return nil end
        if x1 > x2 then x1, x2 = x2, x1 end
        if y1 > y2 then y1, y2 = y2, y1 end
        return {x1, y1, x2, y2, z}
    end
    return nil
end

print("AutoForester (patch): AFCore overrides loaded")
