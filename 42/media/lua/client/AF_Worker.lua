-- AF_Worker.lua
local AF_Worker = {}

local okLog, AF_Log = pcall(require, "AF_Logger")
if not okLog or type(AF_Log) ~= "table" then
    AF_Log = {
        info  = function(...) print("[AutoForester][I]", ...) end,
        warn  = function(...) print("[AutoForester][W]", ...) end,
        error = function(...) print("[AutoForester][E]", ...) end,
    }
end

local AF_Hauler = require("AF_Hauler")

-- ---------- Chop helpers ----------

local function queueSize(p)
    if not p then return 0 end
    local q = ISTimedActionQueue.getTimedActionQueue(p:getPlayerNum())
    if not q or not q.queue then return 0 end
    local ok, n = pcall(function() return q.queue:size() end)
    if ok and type(n) == "number" then return n end
    local c = 0; for _ in pairs(q.queue) do c = c + 1 end
    return c
end

local function rectHasTrees(rect, z)
    local cell = getCell()
    for y = rect.miny, rect.maxy do
        for x = rect.minx, rect.maxx do
            local sq = cell:getGridSquare(x, y, z)
            if sq and sq.HasTree and sq:HasTree() then
                return true
            end
        end
    end
    return false
end

local function enqueueChop(rect, z, p)
    local cell = getCell()
    local count = 0
    for y = rect.miny, rect.maxy do
        for x = rect.minx, rect.maxx do
            local sq = cell:getGridSquare(x, y, z)
            if sq and sq.HasTree and sq:HasTree() then
                local tree = sq:getTree()
                if tree then
                    ISWorldObjectContextMenu.doChopTree(p, tree)
                    count = count + 1
                end
            end
        end
    end
    if count > 0 then
        AF_Log.info("AutoForester: Chop actions queued ("..tostring(count)..")")
    end
end

-- ---------- Public: job entry ----------

function AF_Worker.start(p, chopArea, pileArea)
    if not p or not chopArea or not pileArea then return end

    -- Normalize rect and z
    local z = p:getZ() or 0
    local rect = {
        minx = math.floor(math.min(chopArea.minx, chopArea.maxx)),
        maxx = math.floor(math.max(chopArea.minx, chopArea.maxx)),
        miny = math.floor(math.min(chopArea.miny, chopArea.maxy)),
        maxy = math.floor(math.max(chopArea.miny, chopArea.maxy)),
    }

    -- Phase 1: enqueue chop once
    enqueueChop(rect, z, p)

    local state = "CHOP"

    local function tick()
        if state == "CHOP" then
            -- Wait until the chop queue drains and area has no trees left
            if rectHasTrees(rect, z) or queueSize(p) > 0 then
                return
            end
            AF_Log.info("AutoForester: moving to GATHER")
            state = "GATHER"
            return
        end

        if state == "GATHER" then
            -- Try to add a single grab; if not possible, either dump or finish
            if AF_Hauler.enqueueOneGrab(p, rect) then
                return
            end

            -- Not able to enqueue: either full or no logs → decide what to do
            local inv = p:getInventory()
            local carryingAny = inv and inv:containsTypeRecurse("Log") or false
            if carryingAny then
                if AF_Hauler.enqueueDumpToArea(p, pileArea) then
                    state = "DUMP"
                end
            else
                -- No logs to pick and none carried → done
                state = "DONE"
            end
            return
        end

        if state == "DUMP" then
            -- Wait for dump to complete; then return to GATHER to look for more
            if queueSize(p) == 0 then
                state = "GATHER"
            end
            return
        end

        -- DONE: remove our tick
        Events.OnPlayerUpdate.Remove(tick)
        AF_Log.info("AutoForester: job complete")
    end

    -- Drive the simple state machine
    Events.OnPlayerUpdate.Add(tick)
end

return AF_Worker
