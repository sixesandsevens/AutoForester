AF = AF or {}
AF.Worker = AF.Worker or {}

local Log = AF_Log or { info=print, warn=print, error=print }

-- --- Area utils ---
local function areaCenterRect(a)
    -- center, floored to ints
    local cx = math.floor((a.minx + a.maxx) / 2)
    local cy = math.floor((a.miny + a.maxy) / 2)
    local cz = a.z or 0
    return cx, cy, cz
end

local function isInArea(a, x, y, z)
    if not a then return false end
    z = z or 0
    return z == (a.z or 0)
       and x >= a.minx and x <= a.maxx
       and y >= a.miny and y <= a.maxy
end

-- --- Queue helpers ---
local function queueLen(p)
    local q = ISTimedActionQueue.getQueueForCharacter(p)
    return q and #q.queue or 0
end

local function topUp(maxToHave, addFn)
    -- Fill the queue up to maxToHave by repeatedly calling addFn()
    -- addFn must return true if it actually enqueued something.
    local added = 0
    while queueLen(addFn.player) < maxToHave do
        if not addFn() then break end
        added = added + 1
        if added > 12 then break end  -- hard safety
    end
    return added
end

-- --- Movement actions (lazy area resolution) ---
local function enqueueWalkToAreaCenter(p, area)
    local x, y, z = areaCenterRect(area)
    -- Let the game figure path; this also ensures chunks are loaded on arrival.
    ISTimedActionQueue.add(ISWalkToTimedAction:new(p, x, y, z))
    return true
end

-- --- Chopping batch (very simple & robust) ---
local function findNextTreeSquareInArea(area)
    -- Scan a small ring around center; once we stand inside the area we can expand to full rect
    local cx, cy, cz = areaCenterRect(area)
    local cell = getCell()
    -- Tight search first; you can widen this as needed
    for dy = -8, 8 do
        for dx = -8, 8 do
            local x, y = cx + dx, cy + dy
            if isInArea(area, x, y, cz) then
                local sq = cell:getGridSquare(x, y, cz)
                if sq then
                    for i=0, sq:getObjects():size()-1 do
                        local o = sq:getObjects():get(i)
                        if o and instanceof(o, "IsoTree") then
                            return sq
                        end
                    end
                end
            end
        end
    end
    return nil
end

local function enqueueChopOne(p, area)
    -- Only call this when we are already inside the chop area
    local sq = findNextTreeSquareInArea(area)
    if not sq then return false end
    ISTimedActionQueue.add(ISChopTreeAction:new(p, sq))
    return true
end

-- --- Haul/drop batch (area, not square) ---
local function canCarryOneMoreLog(p)
    local inv = p:getInventory()
    if not inv then return false end
    local cap  = p:getMaxWeight()
    local cur  = inv:getCapacityWeight()
    -- logs are heavy; keep ~4 units spare so we don’t redline
    return (cap - cur) > 4.0
end

local function insideOrWalkToPile(p, pileArea)
    if isInArea(pileArea, p:getX(), p:getY(), p:getZ()) then
        return true
    end
    enqueueWalkToAreaCenter(p, pileArea)
    return false
end

local function enqueueDropLogsHere(p)
    -- Drop whatever logs we have on the square we’re currently standing on.
    local inv = p:getInventory()
    if not inv then return false end
    local items = inv:getItems()
    local added = false
    for i = items:size()-1, 0, -1 do
        local it = items:get(i)
        -- Adjust the type check to your log fulltype(s)
        if it and it:getFullType() == "Base.Log" then
            ISTimedActionQueue.add(ISDropItemAction:new(p, it))
            added = true
        end
    end
    return added
end

-- --- Public entry ---
function AF.Worker.start(p, chopArea, pileArea)
    Log.info("[AF] start; walking to chop area")
    enqueueWalkToAreaCenter(p, chopArea)

    -- Main lightweight driver: run a small top-up each tick.
    Events.OnPlayerUpdate.Add(function(player)
        if player ~= p then return end

        -- If we’re not in chop area yet, do nothing (the walk action is in the queue).
        local px, py, pz = p:getX(), p:getY(), p:getZ()
        local inChop = isInArea(chopArea, px, py, pz)
        local inPile = isInArea(pileArea, px, py, pz)

        -- If inventory is getting full, ensure we’re headed to the pile & drop there.
        if not canCarryOneMoreLog(p) or inPile then
            if insideOrWalkToPile(p, pileArea) then
                -- We are inside pile; top up a few drop actions
                topUp(6, function()
                    return enqueueDropLogsHere(p)
                end)
                -- After we’ve queued drops, once the queue drains we’ll walk back to chop
                if queueLen(p) <= 1 then
                    enqueueWalkToAreaCenter(p, chopArea)
                end
            end
            return
        end

        -- We have room to chop:
        if inChop then
            topUp(6, function()
                return enqueueChopOne(p, chopArea)
            end)
        else
            -- not there yet → keep/let the walk action run
        end
    end)
end

return AF.Worker
