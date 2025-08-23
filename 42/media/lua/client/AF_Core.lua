
-- media/lua/client/AF_Core.lua
require "ISUI/ISCoordConversion"

AFCore = AFCore or {}
local AF_Log = require "AF_Logger"

-- Simple persistent store
local function _store()
    ModData.create("AutoForester")
    return ModData.get("AutoForester")
end

function AFCore.getStore() return _store() end

function AFCore.setWoodPile(x,y,z)
    local s = _store()
    s.wood = {x=x,y=y,z=z or getPlayer():getZ()}
    ModData.transmit("AutoForester")
    AF_Log.info("Wood pile set at "..x..","..y..","..(z or 0))
end

function AFCore.getWoodPile()
    local s = _store()
    if s and s.wood then return s.wood.x, s.wood.y, s.wood.z or 0 end
    return nil
end

-- World square under mouse at a given z (player z by default).
local function _mx() return getMouseXScaled() end
local function _my() return getMouseYScaled() end

function AFCore.worldSquareUnderMouse(z)
    local p = getSpecificPlayer(0) or getPlayer()
    if not p then return nil end
    local mx,my = _mx(), _my()
    local wx = ISCoordConversion.ToWorldX(mx, my, 0)
    local wy = ISCoordConversion.ToWorldY(mx, my, 0)
    local cell = getCell()
    if not cell then return nil end
    z = z or p:getZ() or 0
    return cell:getGridSquare(math.floor(wx), math.floor(wy), z)
end

-- Normalize rectangle {x1,y1,x2,y2} -> {x1<=x2, y1<=y2}
function AFCore.normalizeRect(rect)
    if type(rect) ~= "table" then return nil end
    local x1,y1,x2,y2 = rect[1],rect[2],rect[3],rect[4]
    if not (x1 and y1 and x2 and y2) then return nil end
    if x1 > x2 then x1, x2 = x2, x1 end
    if y1 > y2 then y1, y2 = y2, y1 end
    return {x1,y1,x2,y2}
end

-- Iterate squares inside an inclusive rectangle
function AFCore.eachSquare(rect, z, fn)
    rect = AFCore.normalizeRect(rect)
    if not rect then return end
    local x1,y1,x2,y2 = rect[1],rect[2],rect[3],rect[4]
    z = z or (getPlayer() and getPlayer():getZ()) or 0
    local cell = getCell()
    for x=x1,x2 do
        for y=y1,y2 do
            local sq = cell:getGridSquare(x,y,z)
            if sq then fn(sq,x,y,z) end
        end
    end
end

-- Detect if JB_ASSUtils has a live selection to reuse.
function AFCore.readJBSelectionRect()
    if JB and JB.ASSUtils and JB.ASSUtils.selection then
        local sel = JB.ASSUtils.selection
        if sel.rect then
            -- Expecting sel.rect: {x1,y1,x2,y2}
            return AFCore.normalizeRect(sel.rect)
        end
    end
    return nil
end

Events.OnGameStart.Add(function()
    _store() -- ensure exists
end)
return AFCore
