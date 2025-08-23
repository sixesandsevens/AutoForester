-- AutoForester_Core.lua
-- Keep a GLOBAL table; don't make it local, so requires can see it.
AFCore = AFCore or {}

local function _tonum(x)  return x and tonumber(x) or 0 end

-- Normalize "rect": {x1,y1,x2,y2} => sorted + integers
function AFCore.normalizeRect(r)
    if not r or type(r) ~= "table" then return nil end
    local x1 = math.floor(math.min(_tonum(r[1]), _tonum(r[3])))
    local y1 = math.floor(math.min(_tonum(r[2]), _tonum(r[4])))
    local x2 = math.floor(math.max(_tonum(r[1]), _tonum(r[3])))
    local y2 = math.floor(math.max(_tonum(r[2]), _tonum(r[4])))
    if x1 > x2 or y1 > y2 then return nil end
    return {x1,y1,x2,y2}
end

function AFCore.rectWidth(r)  return (r and (r[3]-r[1]+1)) or 0 end
function AFCore.rectHeight(r) return (r and (r[4]-r[2]+1)) or 0 end

-- Mouse -> square under cursor, at player's Z. No click needed.
function AFCore.getMouseSquare(p)
    local mx = getMouseXScaled and getMouseXScaled() or getMouseX()
    local my = getMouseYScaled and getMouseYScaled() or getMouseY()
    local wx = ISCoordConversion.ToWorldX(mx, my, 0)
    local wy = ISCoordConversion.ToWorldY(mx, my, 0)
    local z  = (p and p.getZ and p:getZ()) or 0
    local cell = getCell()
    if not cell then return nil end
    return cell:getGridSquare(math.floor(wx), math.floor(wy), z)
end

-- Simple "is there a tree" test for a square
function AFCore.squareHasTree(sq)
    if not sq then return false end
    local objs = sq:getObjects()
    for i=0, objs:size()-1 do
        local o = objs:get(i)
        if o and instanceof(o, "IsoTree") then return true end
    end
    return false
end

-- Collect all squares within a rect that contain trees
function AFCore.treesInRect(rect)
    rect = AFCore.normalizeRect(rect)
    if not rect then return {} end
    local x1,y1,x2,y2 = rect[1],rect[2],rect[3],rect[4]
    local cell = getCell()
    if not cell then return {} end
    local out = {}
    local z = getPlayer() and getPlayer():getZ() or 0
    for y=y1,y2 do
        for x=x1,x2 do
            local sq = cell:getGridSquare(x,y,z)
            if sq and AFCore.squareHasTree(sq) then table.insert(out, sq) end
        end
    end
    return out
end

-- Stockpile marker (the square where logs should be hauled)
AFCore._pileSq = AFCore._pileSq or nil

function AFCore.setStockpile(sq)
    AFCore._pileSq = sq or nil
    if sq and sq.setHighlighted then sq:setHighlighted(true) end
    if getPlayer() then
        if sq then getPlayer():Say(string.format("Wood pile set: %d,%d,%d", sq:getX(), sq:getY(), sq:getZ()))
        else getPlayer():Say("Wood pile cleared.") end
    end
end