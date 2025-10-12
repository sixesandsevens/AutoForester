-- AF_Areas.lua
AF = AF or {}
AF.Areas = AF.Areas or {}

local function _getMD()
    local md = ModData.getOrCreate("AutoForester")
    md.areas = md.areas or {}
    return md
end

-- Accept a selection (a.squares) or rect-like table; output lower-case keys.
function AF.Areas.packArea(a)
    if not a then return nil end
    local z = 0
    local minx, miny, maxx, maxy

    if a.squares and #a.squares > 0 then
        local first = a.squares[1]
        if first and first.z then z = first.z
        elseif first and first.getZ then z = first:getZ() end
        for _, pt in ipairs(a.squares) do
            local x = pt.x or (pt.getX and pt:getX()) or nil
            local y = pt.y or (pt.getY and pt:getY()) or nil
            if x and y then
                minx = (minx and math.min(minx, x)) or x
                miny = (miny and math.min(miny, y)) or y
                maxx = (maxx and math.max(maxx, x)) or x
                maxy = (maxy and math.max(maxy, y)) or y
            end
        end
    else
        minx = a.minx or a.minX
        miny = a.miny or a.minY
        maxx = a.maxx or a.maxX
        maxy = a.maxy or a.maxY
        z    = a.z or 0
    end

    if not (minx and miny and maxx and maxy) then return nil end
    return { z = z, minx = minx, miny = miny, maxx = maxx, maxy = maxy }
end

function AF.Areas.setChopArea(a)
    local md = _getMD()
    md.areas.chop = AF.Areas.packArea(a)
    ModData.transmit("AutoForester")
    if md.areas.chop then
        AF_Log.info(string.format("AutoForester: chop set min(%s,%s) max(%s,%s) z=%s",
            tostring(md.areas.chop.minx), tostring(md.areas.chop.miny),
            tostring(md.areas.chop.maxx), tostring(md.areas.chop.maxy),
            tostring(md.areas.chop.z or 0)))
    else
        AF_Log.err("AutoForester: chop set failed (nil)")
    end
end

function AF.Areas.setPileArea(a)
    local md = _getMD()
    md.areas.pile = AF.Areas.packArea(a)
    ModData.transmit("AutoForester")
    if md.areas.pile then
        AF_Log.info(string.format("AutoForester: pile set min(%s,%s) max(%s,%s) z=%s",
            tostring(md.areas.pile.minx), tostring(md.areas.pile.miny),
            tostring(md.areas.pile.maxx), tostring(md.areas.pile.maxy),
            tostring(md.areas.pile.z or 0)))
    else
        AF_Log.err("AutoForester: pile set failed (nil)")
    end
end

function AF.Areas.clear()
    local md = _getMD()
    md.areas = {}
    ModData.transmit("AutoForester")
    AF_Log.info("AutoForester: areas cleared")
end

function AF.Areas.getAreas()
    local md = _getMD()
    return (md and md.areas) or {}
end

-- Optional overlay (guarded & throttled)
local function _drawOverlay()
    if type(addAreaHighlight) ~= "function" then return end
    _G.__AF_overlayTick = (_G.__AF_overlayTick or 0) + 1
    if _G.__AF_overlayTick % 10 ~= 0 then return end

    local md = _getMD()
    if not md or not md.areas then return end

    local function box(a, r,g,b)
        if not a or not a.minx or not a.miny or not a.maxx or not a.maxy then return end
        local x1,y1,x2,y2 = a.minx, a.miny, a.maxx + 1, a.maxy + 1
        local z = a.z or 0
        pcall(function()
            addAreaHighlight(x1, y1, x2, y2, z, r or 0.7, g or 0.9, b or 0.0, 0.0)
        end)
    end

    box(md.areas.chop, 0.2, 0.8, 0.2)
    box(md.areas.pile, 0.9, 0.9, 0.2)
end

Events.OnTick.Remove(_drawOverlay)
Events.OnTick.Add(_drawOverlay)
