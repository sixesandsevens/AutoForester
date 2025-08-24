-- 42/media/lua/client/AF_Worker.lua
-- AutoForester - Worker: chops trees, then sweeps logs one-by-one and drops at pile.

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

-- How many timed actions are queued for this player? (robust across B42 variants)
local function queueSize(p)
    if not p then return 0 end
    local q = ISTimedActionQueue.getTimedActionQueue(p:getPlayerNum())
    if not q or not q.queue then return 0 end

    -- Primary: Java ArrayList has :size()
    local ok, n = pcall(function() return q.queue:size() end)
    if ok and type(n) == "number" then return n end

    -- Fallback: treat it like a Lua table
    local c = 0
    for _ in pairs(q.queue) do c = c + 1 end
    return c
end

-- Do we have room to carry roughly one more log?
local function canCarryOneMoreLog(p)
    if not p then return false end
    local inv = p:getInventory()
    if not inv then return false end
    local cap = p:getMaxWeight()
    local cur = inv:getCapacityWeight()
    -- Logs are heavy; reserve ~4 units (tweak if you like).
    return (cap - cur) >= 4.0
end

-- Pick a valid square inside the pile area (floor preferred, grass OK).
local function choosePileSquare(pileArea, p)
    if not pileArea then return nil end

    local cell = getCell()
    local z    = pileArea.z or 0
    local fallback -- first valid (grass) square

    for y = pileArea.miny, pileArea.maxy do
        for x = pileArea.minx, pileArea.maxx do
            local sq = cell:getGridSquare(x, y, z)
            if sq then
                -- Prefer an actual floor if present
                if sq:getFloor() then return sq end
                -- Otherwise remember the first valid square
                fallback = fallback or sq
            end
        end
    end

    -- Final fallback: player's current square so we never abort
    return fallback or (p and p:getSquare()) or nil
end

-- Enqueue chop actions for every tree in the rectangle.
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
                    -- queues vanilla chop tree timed action
                    ISWorldObjectContextMenu.doChopTree(p, tree)
                    count = count + 1
                end
            end
        end
    end

    AF_Log.info("AutoForester: Chop actions queued (" .. tostring(count) .. ").")
end

-- --- tick logic ------------------------------------------------------------

function AF_Worker.onTick()
    local p = getSpecificPlayer(0) or getPlayer()
    if not p then return end
    local st = AF_Worker.state
    if not st then return end

    if st.phase == "chop" then
        -- Wait for all chop actions to drain, then enter sweep.
        if queueSize(p) == 0 then
            st.phase = "sweep"
            AF_Log.info("AutoForester: entering sweep")
        end
        return
    end

    if st.phase == "sweep" then
        -- Let any running action complete.
        if queueSize(p) > 0 then return end

        -- Too heavy? Go drop at pile first.
        if not canCarryOneMoreLog(p) then
            if AF_Hauler and AF_Hauler.dropBatchToPile then
                AF_Hauler.dropBatchToPile(p, 200)   -- queues walk + drops
            end
            return
        end

        -- Find the next single log to pick up.
        local sq, wob = nil, nil
        if AF_Hauler and AF_Hauler.findNextLog then
            sq, wob = AF_Hauler.findNextLog(st)
        end

        if not sq then
            -- No more logs: do a final drop and finish.
            if AF_Hauler and AF_Hauler.dropBatchToPile then
                AF_Hauler.dropBatchToPile(p, 200)
            end
            st.phase = "finish"
            return
        end

        -- Queue exactly ONE grab (walk + grab).
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

    -- Choose and set a valid pile square.
    local pileSq = choosePileSquare(pileArea, p)
    if not pileSq then
        AF_Log.warn("choosePileSquare() failed; pile area has no valid tiles.")
        if p.Say then p:Say("AutoForester: wood pile area invalid.") end
        return
    end

    if not (AF_Hauler and AF_Hauler.setWoodPileSquare) then
        AF_Log.error("AF_Hauler not loaded; aborting.")
        if p.Say then p:Say("AutoForester: hauler not loaded (see console).") end
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
