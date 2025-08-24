local okLog, AF_Log = pcall(require, "AF_Logger")
if not okLog or type(AF_Log) ~= "table" then
    AF_Log = { info=function(...) print("[AutoForester][I]", ...) end,
               warn=function(...) print("[AutoForester][W]", ...) end,
               error=function(...) print("[AutoForester][E]", ...) end }
end

local AF_Hauler  = require "AF_Hauler"
local AF_Sweeper = require "AF_Sweeper"

AF_Worker = {}

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
                local n = (wobs and wobs:size()) or 0
                for i = 0, n - 1 do
                    local w = wobs:get(i)
                    if instanceof(w, "IsoWorldInventoryObject") then
                        local item = w:getItem()
                        if item and item.getFullType and item:getFullType() == "Base.Log" then
                            return true
                        end
                    end
                end
            end
        end
    end
    return false
end

local function choosePileSquare(area, p)
    if not area then return nil end
    local cell = getWorld() and getWorld():getCell()
    if not cell then return nil end
    local z = area.z or 0

    -- Prefer any valid floor tile in the area (esp. for z>0)
    for y = area.minY, area.maxY do
        for x = area.minX, area.maxX do
            local sq = cell:getGridSquare(x, y, z)
            if sq and (z == 0 or sq:getFloor()) then
                return sq
            end
        end
    end
    -- Fallback center
    local cx = math.floor((area.minX + area.maxX) / 2)
    local cy = math.floor((area.minY + area.maxY) / 2)
    return cell:getGridSquare(cx, cy, z)
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
                    ISWorldObjectContextMenu.doChopTree(p, tree)
                    count = count + 1
                end
            end
        end
    end
    AF_Log.info("AutoForester: Chop actions queued ("..tostring(count)..")")
end

-- Safe across builds (queue is sometimes a Java list, sometimes a Lua table)
local function queueSize(p)
    if not p or not ISTimedActionQueue or not ISTimedActionQueue.getTimedActionQueue then
        return 0
    end
    local q = ISTimedActionQueue.getTimedActionQueue(p:getPlayerNum())
    if not q then return 0 end

    local list = q.queue or (type(q.getQueue) == "function" and q:getQueue()) or q.actions or q.list or q
    if list and list.size then
        local ok, n = pcall(function() return list:size() end)
        if ok and type(n) == "number" then return n end
    end
    if type(list) == "table" then
        local n = 0; for _ in pairs(list) do n = n + 1 end; return n
    end
    return 0
end

---------------------------------------------------------------------------
-- Public: start the job (chop → haul → sweep)
---------------------------------------------------------------------------
function AF_Worker.start(p, chopArea, pileArea)
    if not p then return end
    if not chopArea then if p.Say then p:Say("AutoForester: no chop area set.") end; return end

    local z    = chopArea.z or 0
    local rect = { chopArea.minX, chopArea.minY, chopArea.maxX, chopArea.maxY }

    -- Choose pile square and hand it to the hauler
    local pileSq = choosePileSquare(pileArea, p)
    if not pileSq then
        AF_Log.warn("choosePileSquare() returned nil; check pile area bounds/floor.")
        if p.Say then p:Say("AutoForester: wood pile area has no valid floor tiles.") end
        return
    end
    if type(AF_Hauler) ~= "table" or type(AF_Hauler.setWoodPileSquare) ~= "function" then
        if p.Say then p:Say("AutoForester: hauler not loaded (see console).") end
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
            if queueSize(p) == 0 then
                local picked = AF_Hauler.enqueueBatch(p, rect, z, 20)
                if picked == 0 then
                    -- No more to pick up; dump what we carry and decide next
                    AF_Hauler.dropBatchToPile(p, 200)
                    local inv = p:getInventory()
                    local logsInInv = inv and inv:getCountTypeRecurse and inv:getCountTypeRecurse("Base.Log") or 0
                    if not rectHasLogs(rect, z) and logsInInv == 0 and queueSize(p) == 0 then
                        state.phase = "sweep"
                        AF_Log.info("AutoForester: Sweep phase…")
                    end
                else
                    -- After each pickup batch, also enqueue a drop batch
                    AF_Hauler.dropBatchToPile(p, 200)
                end
            end
            return
        end

        if state.phase == "sweep" then
            if queueSize(p) == 0 then
                local cell = getWorld() and getWorld():getCell()
                local added = 0
                if cell then
                    for x = rect[1], rect[3] do
                        for y = rect[2], rect[4] do
                            local sq = cell:getGridSquare(x, y, z)
                            if sq and AF_Sweeper.trySweep(p, sq) then
                                added = added + 1
                            end
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
