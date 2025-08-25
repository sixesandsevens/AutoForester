-- 42/media/lua/client/AF_Worker.lua
local AF_Worker = {}

-- very light logger to avoid require failures
local okLog, AF_Log = pcall(require, "AF_Logger")
if not okLog or type(AF_Log) ~= "table" then
    AF_Log = {
        info  = function(...) print("[AutoForester][I]", ...) end,
        warn  = function(...) print("[AutoForester][W]", ...) end,
        error = function(...) print("[AutoForester][E]", ...) end,
    }
end

-- ---------- helpers ----------

local function canCarryOneMoreLog(p)
    if not p then return false end
    local inv = p:getInventory()
    if not inv then return false end
    local cap = p:getMaxWeight()
    local cur = inv:getCapacityWeight()
    -- logs are heavy (~4), tweak if needed
    return (cap - cur) >= 4.0
end

-- Choose a single square *inside* the user pile area (prefer floor).
-- pileArea = {minx,miny,maxx,maxy}
local function choosePileSquare(pileArea, p)
    if not pileArea then return nil end
    local cell = getCell()
    local z = pileArea.z or 0
    local fallback = nil

    for y = pileArea.miny, pileArea.maxy do
        for x = pileArea.minx, pileArea.maxx do
            local sq = cell:getGridSquare(x, y, z)
            if sq then
                if sq:getFloor() then
                    return sq -- stand on a proper floor if possible
                end
                fallback = fallback or sq
            end
        end
    end
    return fallback
end

-- Enqueue chop actions for each tree in rectangle
local function enqueueChop(rect, p)
    if not rect or not p then return 0 end
    local cell = getCell()
    local z = rect.z or 0
    local count = 0

    for y = rect.miny, rect.maxy do
        for x = rect.minx, rect.maxx do
            local sq = cell:getGridSquare(x, y, z)
            if sq and sq:HasTree() then
                local tree = sq:getTree()
                if tree then
                    ISWorldObjectContextMenu.doChopTree(p, tree)
                    count = count + 1
                end
            end
        end
    end
    AF_Log.info("AutoForester: Chop actions queued (" .. tostring(count) .. ").")
    return count
end

-- Timed-action queue size that won't explode on B41/B42 hybrids
local function queueSize(p)
    if not p then return 0 end
    local q = ISTimedActionQueue.getTimedActionQueue(p:getPlayerNum())
    if not q or not q.queue then return 0 end

    -- q.queue is usually a Java ArrayList
    local ok, n = pcall(function() return q.queue:size() end)
    if ok and type(n) == "number" then return n end

    -- fallback: try Lua-style count if it ever became a table
    local c = 0
    for _ in pairs(q.queue) do c = c + 1 end
    return c
end

-- ---------- public API ----------

-- rects are {minx,miny,maxx,maxy,z?}
function AF_Worker.start(p, chopArea, pileArea)
    p = p or getSpecificPlayer(0) or getPlayer()
    if not p then return end

    if not chopArea then
        if p.Say then p:Say("AutoForester: no chop area set.") end
        return
    end
    if not pileArea then
        if p.Say then p:Say("AutoForester: no pile area set.") end
        return
    end

    -- Pick a concrete square inside the pile rectangle (for walk/drop later)
    local pileSq = choosePileSquare(pileArea, p)
    if not pileSq then
        if p.Say then p:Say("AutoForester: pile area has no valid square.") end
        return
    end

    -- Phase 1: chop
    local chopped = enqueueChop(chopArea, p)
    if chopped == 0 and p.Say then
        p:Say("AutoForester: no trees to chop in area.")
    end

    -- (Phase 2/3 sweep & haul come next; keeping them disabled
    --   until chopping is stable in your build.)
    AF_Log.info("AutoForester: worker started; queue=" .. tostring(queueSize(p)))
end

return AF_Worker
