-- media/lua/client/AF_Core.lua
require "ISUI/ISCoordConversion"

AFCore = AFCore or {}

local function _mx() return getMouseXScaled and getMouseXScaled() or getMouseX() end
local function _my() return getMouseYScaled and getMouseYScaled() or getMouseY() end

---@param p IsoPlayer|nil
---@return IsoGridSquare|nil
function AFCore.getMouseSquare(p)
    local mx, my = _mx(), _my()
    local wx = ISCoordConversion.ToWorldX(mx, my, 0)
    local wy = ISCoordConversion.ToWorldY(mx, my, 0)
    local z = (p and p:getZ()) or 0
    local cell = getCell()
    if not cell then return nil end
    return cell:getGridSquare(math.floor(wx), math.floor(wy), z)
end

---@param r table {x1,y1,x2,y2,z?}
function AFCore.normalizeRect(r)
    if not r or type(r) ~= "table" then return nil end
    local x1 = (r.x1 or r[1] or 0)
    local y1 = (r.y1 or r[2] or 0)
    local x2 = (r.x2 or r[3] or 0)
    local y2 = (r.y2 or r[4] or 0)
    local z  =  r.z or r[5] or 0
    if x2 < x1 then x1, x2 = x2, x1 end
    if y2 < y1 then y1, y2 = y2, y1 end
    return {x1=x1,y1=y1,x2=x2,y2=y2,z=z}
end

local _pileSq = nil

function AFCore.getStockpile()
    return _pileSq
end

---@param sq IsoGridSquare|nil
function AFCore.setStockpile(sq)
    if _pileSq and _pileSq.setHighlighted then
        _pileSq:setHighlighted(false)
    end
    if not sq or not sq.getX then
        AF_Log.warn("setStockpile: nil/invalid square")
        return
    end
    _pileSq = sq
    if _pileSq.setHighlighted then
        _pileSq:setHighlighted(true, true)
        if _pileSq.setHighlightColor then
            _pileSq:setHighlightColor(0.2, 0.85, 0.2, 0.9)
        end
    end
    AF_Log.info("PILE set @", _pileSq:getX(), _pileSq:getY(), "z:", _pileSq:getZ())
end
