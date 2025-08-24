AF = AF or {}
AF.Areas = AF.Areas or {}

local function _getMD()
    local md = ModData.getOrCreate("AutoForester")
    md.areas = md.areas or {}
    return md
end

function AF.Areas.packArea(a)
    if not a or not a.squares or #a.squares == 0 then return nil end
    local b = a[1] or {}
    local res = {
        z = b.areaZ or (a.squares[1] and a.squares[1]:getZ()) or 0,
        minX = b.minX, minY = b.minY, maxX = b.maxX, maxY = b.maxY
    }
    res.squares = {}
    for _, sq in ipairs(a.squares) do
        table.insert(res.squares, { x = sq:getX(), y = sq:getY() })
    end
    res.numSquares = #res.squares
    res.centerX = math.floor((res.minX + res.maxX) / 2)
    res.centerY = math.floor((res.minY + res.maxY) / 2)
    return res
end

function AF.Areas.set(name, areaPacked)
    if not areaPacked then return end
    local md = _getMD()
    md.areas[name] = areaPacked
    ModData.transmit("AutoForester")
end

function AF.Areas.get(name)
    local md = _getMD()
    return md.areas and md.areas[name] or nil
end

function AF.Areas.setPileArea(playerObj, worldObjects, selectedArea)
    local info = AF.Areas.packArea(selectedArea)
    if info then
        AF.Areas.set("pile", info)
        if playerObj then playerObj:Say(getText("IGUI_AF_PileAreaSet") or "Wood pile area set.") end
    end
end

function AF.Areas.setChopArea(playerObj, worldObjects, selectedArea)
    local info = AF.Areas.packArea(selectedArea)
    if info then
        AF.Areas.set("chop", info)
        if playerObj then playerObj:Say(getText("IGUI_AF_ChopAreaSet") or "Chop/gather area set.") end
    end
end

function AF.Areas.toSquares(areaPacked)
    local squares = {}
    if not areaPacked then return squares end
    local z = areaPacked.z or 0
    for _, pt in ipairs(areaPacked.squares or {}) do
        local sq = getSquare(pt.x, pt.y, z)
        if sq then table.insert(squares, sq) end
    end
    return squares
end

-- Optional: draw saved areas every tick so it's obvious what is set
local function _drawOverlay()
    local md = ModData.getOrCreate("AutoForester")
    if not md or not md.areas then return end
    for name, a in pairs(md.areas) do
        if a and a.squares then
            for _, pt in ipairs(a.squares) do
                addAreaHighlight(pt.x, pt.y, pt.x + 1, pt.y + 1, a.z or 0, 0.3, 0.8, 0.3, 0)
            end
        end
    end
end

Events.OnTick.Remove(_drawOverlay)
Events.OnTick.Add(_drawOverlay)
