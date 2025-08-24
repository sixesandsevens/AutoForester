-- AutoForester - Worker: chops, then sweeps logs one-by-one and drops at pile

AF_Worker = AF_Worker or {}

-- --- logging ---------------------------------------------------------------
local okLog, AF_Log = pcall(require, "AF_Logger")
if not okLog or type(AF_Log) ~= "table" then
    AF_Log = {
        info  = function(...) print("[AutoForester][I]", ...) end,
        warn  = function(...) print("[AutoForester][W]", ...) end,
        error = function(...) print("[AutoForester][E]", ...) end,
    }
end

-- --- helpers ---------------------------------------------------------------

-- Count the player's timed actions safely (works for Lua tables or Java lists)
local function queueSize(p)
    if not p then return 0 end
    local q = ISTimedActionQueue.getTimedActionQueue(p:getPlayerNum())
    if not q then return 0 end
    local qq = q.queue

    -- Prefer treating it like a Lua table
    if type(qq) == "table" then
        local n = 0
        for _ in pairs(qq) do n = n + 1 end
        return n
    end

    -- Last resort: call Java .size() only if present
    local ok, n = pcall(function() return qq and qq.size and qq:size() end)
    if ok and type(n) == "number" then return n end
    return 0
end

-- Simple weight gate: do we have room for (about) one more log?
local function canCarryOneMoreLog(p)
    if not p then return false end
    local inv = p:getInventory()
    if not inv then return false end
    local cap = p:getMaxWeight()
    local cur = inv:getCapacityWeight()
    -- Logs are heavy; reserve ~4 units. Tweak to taste.
    return (cap - cur) >= 4.0
end

-- Pick a valid floor square inside the pile area (very forgiving).
local function choosePileSquare(pileArea, p)
    if not pileArea then return nil end
    local cell = getCell()
    local z    = pileArea.z or 0
    for y = pileArea.miny, pileArea.maxy do
        for x = pileArea.minx, pileArea.maxx do
            local sq = cell:getGridSquare(x, y, z)
            if sq and sq:getFloor() then
                return sq
            end
        end
    end
    return nil
end

-- Enqueue chop actions for every tree in the rectangle
local function enqueueChop(rect, z, p)
    local count = 0
    local cell  = getCell()
    z = rect.z or z or 0
    for y = rect.miny, rect.maxy do
        for x = rect.minx, rect.maxx do
            local sq = cell:getGridSquare(x, y, z)
            if sq and sq:HasTree() then
                local tree = sq:getTree()
                if tree then
                    -- queues vanilla chop timed action
                    ISWorldObjectContextMenu.doChopTree(p, tree)
                    count = count + 1
                end
            end
        end
    end
    AF_Log.info("AutoForester: Chop actions queued (" .. tostring(count) .. ").")
end

-- --- public tick -----------------------------------------------------------

function AF_Worker.onTick()
    local p = getSpecificPlayer(0) or getPlayer()
    if not p then return end
    local st = AF_Worker.state
    if not st then return end

    if st.phase == "chop" then
        -- Wait for all chop actions to drain, then enter sweep
        if queueSize(p) == 0 then
            st.phase = "sweep"
            st.sweepCursor = { x = st.rect.minx, y = st.rect.miny }
            AF_Log.info("AutoForester: entering sweep")
        end
        return
    end

    if st.phase == "sweep" then
        -- If anything is still running, let it finish
        if queueSize(p) > 0 then return end

        -- Too heavy? Go drop at pile first.
        if not canCarryOneMoreLog(p) then
            AF_Hauler.dropBatchToPile(p, 200)   -- queues walk + drops
            return
        end

        -- Find the next single log to pick up
        local sq, wob = AF_Hauler.findNextLog(st)
        if not sq then
            -- No more logs here -> do a final drop and finish
            AF_Hauler.dropBatchToPile(p, 200)
            st.phase = "finish"
            return
        end

        -- Queue exactly ONE grab (walk + grab)
        ISTimedActionQueue.add(ISWalkToTimedAction:new(p, sq))
        ISTimedActionQueue.add(ISGrabItemAction:new(p, wob, 50))
        return
    end

    if st.phase == "finish" then
        if queueSize(p) == 0 then
            AF_Log.info("AutoForester: done.")
            AF_Worker.state = nil
            Events.OnPlayerUpdate.Remove(AF_Worker.onTick)
        end
        return
    end
end

-- --- public start ----------------------------------------------------------

function AF_Worker.start(p, chopArea, pileArea)
    if not p or not chopArea or not pileArea then return end

    local rect = {
        minx = chopArea.minx, miny = chopArea.miny,
        maxx = chopArea.maxx, maxy = chopArea.maxy,
        z    = chopArea.z or 0
    }

    -- Choose a valid pile square and pass to the hauler
    local pileSq = choosePileSquare(pileArea, p)
    if not pileSq then
        AF_Log.warn("choosePileSquare() failed; pile area has no valid floor.")
        if p.Say then p:Say("AutoForester: wood pile area has no valid floor tiles.") end
        return
    end
    AF_Hauler.setWoodPileSquare(pileSq)

    -- Phase 1: chop
    enqueueChop(rect, rect.z, p)

    -- Save state and subscribe tick
    AF_Worker.state = { phase = "chop", rect = rect }
    Events.OnPlayerUpdate.Remove(AF_Worker.onTick)
    Events.OnPlayerUpdate.Add(AF_Worker.onTick)

    AF_Log.info("AutoForester: Worker started.")
end

return AF_Worker
