-- AF_Hauler.lua
local AF_Hauler = {}

local okLog, AF_Log = pcall(require, "AF_Logger")
if not okLog or type(AF_Log) ~= "table" then
    AF_Log = {
        info  = function(...) print("[AutoForester][I]", ...) end,
        warn  = function(...) print("[AutoForester][W]", ...) end,
        error = function(...) print("[AutoForester][E]", ...) end,
    }
end

local function clampRect(area)
    if not area then return nil end
    local minx = math.floor(math.min(area.minx, area.maxx))
    local maxx = math.floor(math.max(area.minx, area.maxx))
    local miny = math.floor(math.min(area.miny, area.maxy))
    local maxy = math.floor(math.max(area.miny, area.maxy))
    return minx, miny, maxx, maxy
end

local function insideArea(x, y, area)
    if not area then return false end
    return x >= math.min(area.minx, area.maxx)
       and x <= math.max(area.minx, area.maxx)
       and y >= math.min(area.miny, area.maxy)
       and y <= math.max(area.miny, area.maxy)
end

-- Find nearest valid square inside an area (player's Z, prefer floor; else any square).
local function nearestSquareInArea(area, p)
    if not area or not p then return nil end
    local z  = p.getZ and p:getZ() or 0
    local px = p.getX and p:getX() or 0
    local py = p.getY and p:getY() or 0

    local minx, miny, maxx, maxy = clampRect(area)
    if not minx then return nil end

    local cell = getCell()
    local best, bestD2, fallback = nil, 1e20, nil

    -- if already in the area and on a valid square, use that right away
    local here = p.getSquare and p:getSquare() or nil
    if here and insideArea(here:getX(), here:getY(), area) then
        if here.getFloor and here:getFloor() then return here end
        fallback = fallback or here
    end

    for y = miny, maxy do
        for x = minx, maxx do
            local sq = cell:getGridSquare(x, y, z)
            if sq then
                local dx, dy = (x - px), (y - py)
                local d2 = dx*dx + dy*dy
                if sq.getFloor and sq:getFloor() then
                    if d2 < bestD2 then best, bestD2 = sq, d2 end
                else
                    fallback = fallback or sq
                end
            end
        end
    end
    return best or fallback
end

local function canCarryOneMoreLog(p)
    if not p then return false end
    local inv = p:getInventory()
    if not inv then return false end
    local cur = inv:getCapacityWeight()
    local cap = p:getMaxWeight()
    return (cap - cur) >= 4.0 -- logs are ~4 units
end

local function queueSize(p)
    if not p then return 0 end
    local q = ISTimedActionQueue.getTimedActionQueue(p:getPlayerNum())
    if not q or not q.queue then return 0 end
    local ok, n = pcall(function() return q.queue:size() end)
    if ok and type(n) == "number" then return n end
    local c = 0; for _ in pairs(q.queue) do c = c + 1 end
    return c
end

-- Find a single ground log (IsoWorldInventoryObject) in chop area, nearest to player.
local function findNearestGroundLog(p, chopArea)
    if not p or not chopArea then return nil end
    local z  = p:getZ() or 0
    local px = p:getX() or 0
    local py = p:getY() or 0

    local minx, miny, maxx, maxy = clampRect(chopArea)
    if not minx then return nil end

    local cell = getCell()
    local best, bestD2 = nil, 1e20

    for y = miny, maxy do
        for x = minx, maxx do
            local sq = cell:getGridSquare(x, y, z)
            if sq then
                local wobs = sq.getWorldObjects and sq:getWorldObjects() or nil
                if wobs then
                    for i = 0, wobs:size() - 1 do
                        local wio = wobs:get(i)
                        local it  = wio and wio.getItem and wio:getItem() or nil
                        if it and it.getFullType and it:getFullType() == "Base.Log" then
                            local dx, dy = (x - px), (y - py)
                            local d2 = dx*dx + dy*dy
                            if d2 < bestD2 then best, bestD2 = wio, d2 end
                        end
                    end
                end
            end
        end
    end

    return best
end

-- Public: enqueue exactly ONE grab if possible.
function AF_Hauler.enqueueOneGrab(p, chopArea)
    if not p or not chopArea then return false end
    if queueSize(p) > 0 then return false end
    if not canCarryOneMoreLog(p) then return false end

    local wio = findNearestGroundLog(p, chopArea)
    if not wio then return false end

    ISTimedActionQueue.add(ISGrabItemAction:new(p, wio, 50))
    AF_Log.info("AutoForester: enqueued 1 grab")
    return true
end

-- Public: dump all carried logs anywhere inside the pile AREA (dynamic target tile).
function AF_Hauler.enqueueDumpToArea(p, pileArea)
    if not p or not pileArea then return false end
    if queueSize(p) > 0 then return false end

    local sq = nearestSquareInArea(pileArea, p) or (p.getSquare and p:getSquare()) or nil
    if not sq then
        AF_Log.warn("AutoForester: no valid square in pile area; skipping dump")
        return false
    end

    if ISWalkToTimedAction then
        ISTimedActionQueue.add(ISWalkToTimedAction:new(p, sq))
    end

    local logs = p:getInventory():getItemsFromType("Log", true)
    local count = logs and logs:size() or 0
    if count == 0 then return false end

    for i = 0, count - 1 do
        local it = logs:get(i)
        ISTimedActionQueue.add(ISDropItemAction:new(p, it))
    end

    AF_Log.info("AutoForester: enqueued dump of "..tostring(count).." log(s)")
    return true
end

return AF_Hauler
