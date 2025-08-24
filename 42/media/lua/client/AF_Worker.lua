-- AF_Worker.lua — orchestrates chop → haul
local okLog, AF_Log = pcall(require, "AF_Logger")
if not okLog or type(AF_Log) ~= "table" then
    AF_Log = {
        info  = function(...) print("[AutoForester][I]", ...) end,
        warn  = function(...) print("[AutoForester][W]", ...) end,
        error = function(...) print("[AutoForester][E]", ...) end,
    }
end

local okHauler, AF_Hauler = pcall(require, "AF_Hauler")
if not okHauler or type(AF_Hauler) ~= "table" then
    AF_Log.warn("AF_Hauler missing or invalid; will bail on start.")
    AF_Hauler = nil
end

local AF_Worker = {}

-- robust queue size (B41 vs B42) without throwing
local function queueSize(p)
    if not p then return 0 end
    local q = ISTimedActionQueue.getTimedActionQueue(p:getPlayerNum())
    if not q then return 0 end
    local list = q.actionQueue or q.queue
    if not list then return 0 end
    -- Java ArrayList exposes :size()
    if type(list) == "userdata" and list.size and type(list.size) == "function" then
        return list:size()
    end
    -- Lua table fallback
    if type(list) == "table" then
        local c = 0
        for _ in pairs(list) do c = c + 1 end
        return c
    end
    return 0
end

-- choose a pile square inside the pile-area that actually has a floor
local function choosePileSquare(pileArea, p)
    if not pileArea then return nil end
    local minX, minY, maxX, maxY = pileArea.minX, pileArea.minY, pileArea.maxX, pileArea.maxY
    if not (minX and minY and maxX and maxY) then return nil end

    local cell = getWorld() and getWorld():getCell()
    if not cell then return nil end

    local z = pileArea.z or 0
    local px, py = 0, 0
    if p and p.getX then px, py = p:getX(), p:getY() end

    local bestSq, bestD2 = nil, math.huge
    for y = minY, maxY do
        for x = minX, maxX do
            local sq = cell:getGridSquare(x, y, z)
            if sq and sq:getFloor() then
                local dx, dy = (x - px), (y - py)
                local d2 = dx*dx + dy*dy
                if d2 < bestD2 then bestD2, bestSq = d2, sq end
            end
        end
    end
    return bestSq
end

-- any trees left in chop rect?
local function rectHasTrees(rect, z)
    local cell = getWorld() and getWorld():getCell()
    if not cell then return false end
    for y = rect[2], rect[4] do
        for x = rect[1], rect[3] do
            local sq = cell:getGridSquare(x, y, z)
            if sq and sq:HasTree() then return true end
        end
    end
    return false
end

-- enqueue chops for all trees in rect
local function enqueueChop(rect, z, p)
    local cell = getWorld() and getWorld():getCell()
    if not cell then return 0 end
    local count = 0
    for y = rect[2], rect[4] do
        for x = rect[1], rect[3] do
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
    AF_Log.info("AutoForester: Chop actions queued ("..tostring(count)..")")
    return count
end

function AF_Worker.start(p, chopArea, pileArea)
    if not p then return end
    if not chopArea then if p.Say then p:Say("AutoForester: no chop area set.") end return end

    local z      = chopArea.z or 0
    local rect   = { chopArea.minX, chopArea.minY, chopArea.maxX, chopArea.maxY }
    local pileSq = choosePileSquare(pileArea, p)
    if not pileSq then
        AF_Log.warn("choosePileSquare() returned nil; check pile area bounds/floor.")
        if p.Say then p:Say("AutoForester: wood pile area has no valid floor tiles.") end
        return
    end

    if not AF_Hauler or type(AF_Hauler.setWoodPileSquare) ~= "function" then
        AF_Log.error("AF_Hauler not loaded; aborting start.")
        if p.Say then p:Say("AutoForester: hauler not loaded (see console).") end
        return
    end
    AF_Hauler.setWoodPileSquare(pileSq)

    -- Phase 1: chop
    enqueueChop(rect, z, p)
    local state = { phase = "chop" }

    local function onTick()
        if state.phase == "chop" then
            if rectHasTrees(rect, z) or queueSize(p) > 0 then return end
            state.phase = "haul"
            AF_Log.info("AutoForester: Haul phase!")
            return
        end

        if state.phase == "haul" then
            -- enqueue small batches only when queue is empty
            if queueSize(p) == 0 then
                local picked = AF_Hauler.enqueueBatch(p, rect, z, 20) -- up to 20 pickups
                if picked == 0 then
                    -- nothing more to pick up → if carrying, drop; otherwise done
                    AF_Hauler.dropBatchToPile(p, 200)
                    state.phase = "done"
                end
            end
            return
        end

        if state.phase == "done" and queueSize(p) == 0 then
            Events.OnTick.Remove(onTick)
            if p.Say then p:Say("AutoForester: done.") end
            AF_Log.info("AutoForester: done.")
        end
    end

    Events.OnTick.Remove(onTick)
    Events.OnTick.Add(onTick)
end

print("AutoForester: AF_Worker loaded")
return AF_Worker