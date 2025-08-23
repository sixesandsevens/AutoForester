require "ISUI/ISCoordConversion"

AFCore = AFCore or {}

local function _mx() return getMouseXScaled and getMouseXScaled() or getMouseX() end
local function _my() return getMouseYScaled and getMouseYScaled() or getMouseY() end

-- Grid square under the mouse at the player's Z (no clicks needed)
function AFCore.getMouseSquare(p)
    p = p or getSpecificPlayer(0) or getPlayer()
    if not p then return nil end
    local mx, my = _mx(), _my()
    local wx = ISCoordConversion.ToWorldX(mx, my, 0)
    local wy = ISCoordConversion.ToWorldY(mx, my, 0)
    local z  = (p and p:getZ()) or 0
    local cell = getCell()
    if not cell then return nil end
    return cell:getGridSquare(math.floor(wx), math.floor(wy), z)
end

-- Normalize {x1,y1,x2,y2} so x1<=x2, y1<=y2
function AFCore.normalizeRect(r)
    if not r or type(r) ~= "table" then return nil end
    local x1,y1,x2,y2 = r[1],r[2],r[3],r[4]
    if not x1 or not y1 or not x2 or not y2 then return nil end
    if x2 < x1 then x1,x2 = x2,x1 end
    if y2 < y1 then y1,y2 = y2,y1 end
    return {x1,y1,x2,y2}
end

-- Lightly remember areas/pile in-core (keeps UI glue simple)
AFCore.state = AFCore.state or { pileSq = nil, chop = nil, gather = nil }

function AFCore.setStockpile(sq)
    AFCore.state.pileSq = sq
    -- Highlight if this build supports it (avoid "Object tried to call nil in setStockpile")
    if sq and sq.setHighlighted then sq:setHighlighted(true) end
    if sq and sq.setHighlightColor then sq:setHighlightColor(0.2, 0.85, 0.2, 0.9) end
end

function AFCore.getStockpile() return AFCore.state.pileSq end
function AFCore.setArea(kind, rect) AFCore.state[kind] = rect end
function AFCore.getArea(kind) return AFCore.state[kind] end