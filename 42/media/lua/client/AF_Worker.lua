-- AF_Worker.lua

local okLog, AF_Log = pcall(require, "AF_Logger")
if not okLog or type(AF_Log) ~= "table" then
    AF_Log = {
        info  = function(...) print("[AutoForester][I]", ...) end,
        warn  = function(...) print("[AutoForester][W]", ...) end,
        error = function(...) print("[AutoForester][E]", ...) end
    }
end

local AF_Hauler  = require "AF_Hauler"
local AF_Sweeper = require "AF_Sweeper"

AF_Worker = {}

-- Choose a solid floor square inside the pile area (closest to player).
local function choosePileSquare(area, p)
    if not area then return nil end
    local minX, minY, maxX, maxY = area.minX, area.minY, area.maxX, area.maxY
    if not (minX and minY and maxX and maxY) then return nil end

    local world = getWorld()
    local cell  = world and world:getCell()
    if not cell then return nil end

    local z  = area.z or 0
    local px, py = 0, 0
    if p and p.getX then px, py = p:getX(), p:getY() end

    local bestSq, bestD2 = nil, math.huge
    for y = minY, maxY do
        for x = minX, maxX do
            local sq = cell:getGridSquare(x, y, z)
            if sq and sq:getFloor() then
                local dx, dy = (x + 0.5) - px, (y + 0.5) - py
                local d2 = dx*dx + dy*dy
                if d2 < bestD2 then
                    bestD2, bestSq = d2, sq
                end
            end
        end
    end
    return bestSq
end

local function rectHasTrees(rect, z)
    local cell = getWorld() and getWorld():getCell()
    if not cell then return false end
    for x = rect[1], rect[3] do
        for y = rect[2], rect[4] do
            local sq = cell:getGridSquare(x, y, z)
            if sq and sq:HasTree() then return true end
        end
    end
    return false
end

local function rectHasLogs(rect, z)
    local cell = getWorld() and getWorld():getCell()
    if not cell then return false end
    for x = rect[1], rect[3] do
        for y = rect[2], rect[4] do
            local sq = cell:getGridSquare(x, y, z)
            if sq then
                local wobs = sq:getWorldObjects()
                for i = 0, (wobs and wobs:size() or 0) - 1 do
                    local o = wobs:get(i)
                    if instanceof(o, "IsoWorldInventoryObject") then
                        local item = o:getItem()
                        if item and item:getFullType() == "Base.Log" then
                            return true
                        end
                    end
                end
            end
        end
    end
    return false
end

local function enqueueChop(rect, z, p)
    local cell = getWorld() and getWorld():getCell()
    if not cell then return end
    local count = 0
    for x = rect[1], rect[3] do
        for y = rect[2], rect[4] do
            local sq = cell:getGridSquare(x, y, z)
            if sq and sq:HasTree() then
                local tree = sq:getTree()
                if tree then
                    ISWorldObjectContextMenu.doChopTree(p, tree) -- queues timed actions
                    count = count + 1
                end
            end
        end
    end
    AF_Log.info("AutoForester: Chop actions queued ("..tostring(count)..")")
end

local function queueSize(p)
    if not p then return 0 end
    local q = ISTimedActionQueue.getTimedActionQueue(p:getPlayerNum())
    return (q and q.queue and q.queue:size()) or 0
end

-- Public: start the job (chop → haul → sweep)
function AF_Worker.start(p, chopArea, pileArea)
    if not p then return end
    if not chopArea then
        if p.Say then p:Say("AutoForester: no chop area set.") end
        return
    end

    local z    = chopArea.z or 0
    local rect = { chopArea.minX, chopArea.minY, chopArea.maxX, chopArea.maxY }

    -- Choose and set a valid pile square (guard against nil)
    local pileSq = choosePileSquare(pileArea, p)
    if not pileSq then
        AF_Log.warn("choosePileSquare() returned nil; check pile area bounds/floor.")
        if p and p.Say then p:Say("AutoForester: wood pile area has no valid floor tiles.") end
        return
    end

    -- Make sure the hauler module actually loaded
    if type(AF_Hauler) ~= "table" or type(AF_Hauler.setWoodPileSquare) ~= "function" then
        if p and p.Say then p:Say("AutoForester: hauler not loaded (see console).") end
        AF_Log.error("AF_Hauler not loaded; aborting start.")
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
            AF_Log.info("AutoForester: Haul phase…")
            return
        end

        if state.phase == "haul" then
            -- enqueue pickup only when queue is empty
            if queueSize(p) == 0 then
                local picked = AF_Hauler.enqueueBatch(p, rect, z, 20) -- up to 20 pickups
                if picked == 0 then
                    -- drop whatever we’re carrying and see if area is clear
                    AF_Hauler.dropBatchToPile(p, 200)
                    local logsInInv = p:getInventory():getCountTypeRecurse("Base.Log")
                    if not rectHasLogs(rect, z) and logsInInv == 0 and queueSize(p) == 0 then
                        state.phase = "sweep"
                        AF_Log.info("AutoForester: Sweep phase…")
                    end
                else
                    -- after a pickup batch, also queue a drop batch
                    AF_Hauler.dropBatchToPile(p, 200)
                end
            end
            return
        end

        if state.phase == "sweep" then
            if queueSize(p) == 0 then
                local cell = getWorld():getCell()
                local added = 0
                for x = rect[1], rect[3] do
                    for y = rect[2], rect[4] do
                        local sq = cell:getGridSquare(x, y, z)
                        if sq then
                            local did = AF_Sweeper.trySweep(p, sq)
                            if did then added = added + 1 end
                        end
                    end
                end
                AF_Log.info("AutoForester: Sweep actions queued ("..tostring(added)..")")
                state.phase = "done"
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

return AF_Worker
