require "AF_Log"

AFCore = AFCore or {}

-- normalize rect {x1,y1,x2,y2} so x1<=x2, y1<=y2, return nil if bad
function AFCore.normalizeRect(r)
    if not r or not r[1] or not r[2] or not r[3] or not r[4] then return nil end
    local x1,y1,x2,y2 = r[1],r[2],r[3],r[4]
    if x2 < x1 then x1,x2 = x2,x1 end
    if y2 < y1 then y1,y2 = y2,y1 end
    return {x1,y1,x2,y2}
end

-- correct mouse->world square at player's Z (UI scaling safe)
function AFCore.getMouseSquare(p)
    local mx = getMouseXScaled and getMouseXScaled() or getMouseX()
    local my = getMouseYScaled and getMouseYScaled() or getMouseY()
    local wx = ISCoordConversion.ToWorldX(mx, my, 0)
    local wy = ISCoordConversion.ToWorldY(mx, my, 0)
    local z  = (p and p:getZ()) or 0
    local cell = getCell()
    if not cell or wx ~= wx or wy ~= wy then return nil end -- NaN guard
    return cell:getGridSquare(math.floor(wx), math.floor(wy), z)
end

-- (your existing highlight/stockpile helpers live here)
-- AFCore.setStockpile(sq) ... etc.
return AFCore
