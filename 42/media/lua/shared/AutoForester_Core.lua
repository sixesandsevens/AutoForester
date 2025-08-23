-- media/lua/shared/AutoForester_Core.lua
require "AF_Log"

AFCore = AFCore or {}

-- Convert mouse screen coords to world square at player's z
function AFCore.getMouseSquare(p)
    local mx = getMouseXScaled() or getMouseX()
    local my = getMouseYScaled() or getMouseY()
    local z  = (p and p:getZ()) or 0
    local wx = ISCoordConversion.ToWorldX(mx, my, z)
    local wy = ISCoordConversion.ToWorldY(mx, my, z)
    local cell = getCell()
    if not cell then return nil end
    return cell:getGridSquare(math.floor(wx), math.floor(wy), z)
end

function AFCore.normalizeRect(r)
    if not r then return nil end
    local x1,y1,x2,y2 = r[1],r[2],r[3],r[4]
    if not (x1 and y1 and x2 and y2) then return nil end
    if x2 < x1 then x1, x2 = x2, x1 end
    if y2 < y1 then y1, y2 = y2, y1 end
    return {x1, y1, x2, y2}
end

function AFCore.rectWidth(r)
    if not r then return nil end
    return (r[3] - r[1] + 1)
end

function AFCore.rectHeight(r)
    if not r then return nil end
    return (r[4] - r[2] + 1)
end

-- simple stockpile memory
function AFCore.setStockpile(sq)
    AFCore._pileSq = sq
    return true
end

function AFCore.getStockpile() return AFCore._pileSq end

-- tree helpers
function AFCore.squareHasTree(sq)
    if not sq then return false end
    local objs = sq:getObjects()
    for i=0, objs:size()-1 do
        local o = objs:get(i)
        if instanceof(o, "IsoTree") then return true end
    end
    return false
end

function AFCore.treesInRect(rect, z)
    if not rect then return {} end
    local cell = getCell()
    if not cell then return {} end
    local x1,y1,x2,y2 = rect[1], rect[2], rect[3], rect[4]
    local out = {}
    z = z or 0
    for y=y1, y2 do
        for x=x1, x2 do
            local sq = cell:getGridSquare(x, y, z)
            if AFCore.squareHasTree(sq) then table.insert(out, sq) end
        end
    end
    return out
end
