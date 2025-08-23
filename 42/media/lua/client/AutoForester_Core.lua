-- AutoForester_Core.lua (B42-safe helpers)
AFCore = AFCore or {}

-- normalize coordinate pair (x1,y1,x2,y2) so x1<=x2, y1<=y2
function AFCore.normalizeRect(r)
    if not r then return nil end
    local x1,y1,x2,y2 = tonumber(r[1]),tonumber(r[2]),tonumber(r[3]),tonumber(r[4])
    if not x1 or not y1 or not x2 or not y2 then return nil end
    if x2 < x1 then x1,x2 = x2,x1 end
    if y2 < y1 then y1,y2 = y2,y1 end
    return { math.floor(x1), math.floor(y1), math.floor(x2), math.floor(y2), (r[5] or 0) }
end

function AFCore.rectWidth(r)  return (r and (r[3] - r[1] + 1)) or 0 end
function AFCore.rectHeight(r) return (r and (r[4] - r[2] + 1)) or 0 end

-- Tile under the mouse (no extra click)
function AFCore.getMouseSquare(p)
    local mx = getMouseXScaled()
    local my = getMouseYScaled()
    -- Convert screen -> world
    local wx = ISCoordConversion.ToWorldX(mx, my, 0)
    local wy = ISCoordConversion.ToWorldY(mx, my, 0)
    local z  = (p and p.getZ and p:getZ()) or 0
    local cell = getCell()
    if not cell then return nil end
    return cell:getGridSquare(math.floor(wx), math.floor(wy), z)
end

-- Stockpile marker handling
AFCore._pileSq = AFCore._pileSq or nil
function AFCore.setStockpile(sq)
    if AFCore._pileSq and AFCore._pileSq.setHighlighted then AFCore._pileSq:setHighlighted(false) end
    AFCore._pileSq = sq
    if sq and sq.setHighlighted then sq:setHighlighted(true) end
end
function AFCore.getStockpile() return AFCore._pileSq end

-- Tree helpers
function AFCore.squareHasTree(sq)
    if not sq then return false end
    local objs = sq:getObjects()
    for i = 0, objs:size()-1 do
        local o = objs:get(i)
        if instanceof(o, "IsoTree") then return true end
    end
    return false
end

function AFCore.treesInRect(rect)
    rect = AFCore.normalizeRect(rect)
    if not rect then return {} end
    local x1,y1,x2,y2,z = rect[1],rect[2],rect[3],rect[4],rect[5] or 0
    local cell = getCell()
    if not cell then return {} end
    local out = {}
    for y=y1,y2 do
        for x=x1,x2 do
            local sq = cell:getGridSquare(x,y,z)
            if AFCore.squareHasTree(sq) then table.insert(out, sq) end
        end
    end
    return out
end

function AFCore.queueChops(p, squares)
    local n = 0
    for _,sq in ipairs(squares or {}) do
        ISWorldObjectContextMenu.onChopTree({ player=p, square=sq })
        n = n + 1
    end
    return n
end
