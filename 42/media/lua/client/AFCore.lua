AFCore = AFCore or {}

-- Normalize rectangles {x1,y1,x2,y2[,z]} or IsoRect-like {getX1/getX2,...}
function AFCore.normalizeRect(rect)
    if not rect then return nil end
    if type(rect) == "table" and rect.getX1 then
        return { rect:getX1(), rect:getY1(), rect:getX2(), rect:getY2(), rect:getZ() or 0 }
    end
    if type(rect) == "table" then
        -- assume flat table {x1,y1,x2,y2[,z]}
        local x1,y1,x2,y2,z = rect[1],rect[2],rect[3],rect[4],rect[5] or 0
        if not x1 or not y1 or not x2 or not y2 then return nil end
        return { math.min(x1,x2), math.min(y1,y2), math.max(x1,x2), math.max(y1,y2), z }
    end
    return nil
end

function AFCore.rectWidth(r)   return (r and (math.abs(r[3]-r[1])+1)) or 0 end
function AFCore.rectHeight(r)  return (r and (math.abs(r[4]-r[2])+1)) or 0 end

-- Keep a highlighted pile square so users can see where it is
local _pileSq
local function _clearPileHighlight()
    if _pileSq then _pileSq:setHighlighted(false) end
    _pileSq = nil
end

function AFCore.setStockpile(sq)
    _clearPileHighlight()
    if not sq then return end
    _pileSq = sq
    sq:setHighlighted(true, true)
    sq:setHighlightColor(0.2, 0.85, 0.2, 0.9)
    AF_Log.info("[PILE] set", sq:getX(), sq:getY(), sq:getZ())
end

function AFCore.getStockpile()
    return _pileSq
end
