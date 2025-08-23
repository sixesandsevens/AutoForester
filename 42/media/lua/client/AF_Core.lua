-- media/lua/client/AF_Core.lua
require "ISUI/ISCoordConversion"
local AF_Log = require "AF_Log"

local AFCore = AFCore or {}

local function _mx() return getMouseXScaled and getMouseXScaled() or getMouseX() end
local function _my() return getMouseYScaled and getMouseYScaled() or getMouseY() end

function AFCore.getMouseSquare(p)
    p = p or getSpecificPlayer(0) or getPlayer()
    if not p or p:isAlive() == false then return nil end
    local mx, my = _mx(), _my()
    local wx = ISCoordConversion.ToWorldX(mx, my, 0)
    local wy = ISCoordConversion.ToWorldY(mx, my, 0)
    local z  = (p and p:getZ() and p:getZ()) or 0
    local cell = getCell()
    if not cell then return nil end
    return cell:getGridSquare(math.floor(wx), math.floor(wy), z)
end

function AFCore.normalizeRect(rect)
    if type(rect) ~= "table" then return nil end
    local x1 = rect[1] or rect.x1 or rect.x or rect.left or rect.minx
    local y1 = rect[2] or rect.y1 or rect.y or rect.top  or rect.miny
    local x2 = rect[3] or rect.x2 or rect.r or rect.right or rect.maxx
    local y2 = rect[4] or rect.y2 or rect.b or rect.bottom or rect.maxy
    if not x1 or not y1 or not x2 or not y2 then return nil end
    if x1 > x2 then x1, x2 = x2, x1 end
    if y1 > y2 then y1, y2 = y2, y1 end
    return { x1, y1, x2, y2 }
end

local _pileSq = nil
local function _clearPileHighlight()
    if _pileSq then _pileSq:setHighlighted(false) _pileSq = nil end
end

function AFCore.setStockpile(sq)
    _clearPileHighlight()
    if not sq then return end
    _pileSq = sq
    _pileSq:setHighlighted(true, true)
    _pileSq:setHighlightColor(0.2, 0.85, 0.2, 0.9)
    AF_Log.info("[PILE] set at", sq:getX(), sq:getY(), sq:getZ())
end

function AFCore.getStockpile()
    return _pileSq
end

return AFCore
