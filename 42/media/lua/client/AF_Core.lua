-- AF_Core.lua - core helpers (Build 42)
require "ISUI/ISCoordConversion"

local AF_Log = require "AF_Logger"

AFCore = AFCore or {}

-- mouse helpers (scaled if possible)
local function _mx() return (getMouseXScaled and getMouseXScaled()) or getMouseX() end
local function _my() return (getMouseYScaled and getMouseYScaled()) or getMouseY() end

-- square under mouse at the player's Z (no click needed)
function AFCore.getMouseSquare(p)
    local pl = p or getSpecificPlayer(0) or getPlayer()
    if not pl then return nil end
    local mx,my = _mx(), _my()
    local wx = ISCoordConversion.ToWorldX(mx, my, 0)
    local wy = ISCoordConversion.ToWorldY(mx, my, 0)
    local cell = getCell()
    if not cell then return nil end
    local z = pl:getZ() or 0
    return cell:getGridSquare(math.floor(wx), math.floor(wy), z)
end

-- world square under mouse at specific Z
function AFCore.worldSquareUnderMouse(z)
    local mx,my = _mx(), _my()
    local wx = ISCoordConversion.ToWorldX(mx, my, 0)
    local wy = ISCoordConversion.ToWorldY(mx, my, 0)
    local cell = getCell()
    if not cell then return nil end
    return cell:getGridSquare(math.floor(wx), math.floor(wy), z or 0)
end

-- normalize {x1,y1,x2,y2} so x1<=x2 and y1<=y2
function AFCore.normalizeRect(rect)
    if type(rect) ~= "table" then return nil end
    local x1,y1,x2,y2 = rect[1],rect[2],rect[3],rect[4]
    if not x1 or not y1 or not x2 or not y2 then return nil end
    if x1 > x2 then x1,x2 = x2,x1 end
    if y1 > y2 then y1,y2 = y2,y1 end
    return {x1,y1,x2,y2}
end

-- --- Stockpile square highlight handling
local _pileSq = nil
local function _clearPile()
    if _pileSq and _pileSq.setHighlighted then
        _pileSq:setHighlighted(false)
    end
    _pileSq = nil
end

function AFCore.setStockpile(sq)
    _clearPile()
    if not sq then return end
    _pileSq = sq
    if _pileSq.setHighlighted then
        _pileSq:setHighlighted(true, true)
        if _pileSq.setHighlightColor then _pileSq:setHighlightColor(0.2, 0.85, 0.2, 0.9) end
    end
    AF_Log.info(string.format("Wood pile set @ %d,%d,%d", sq:getX(), sq:getY(), sq:getZ()))
end

function AFCore.getStockpile()
    return _pileSq
end

return AFCore
