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
    local cell = getWorld():getCell()
    for x = rect[1], rect[3] do
        for y = rect[2], rect[4] do
            local sq = cell:getGridSquare(x, y, z)
            if sq and sq:HasTree() then return true end
        end
    end
    return false
end

local function rectHasLogs(rect, z)
    local cell = getWorld():getCell()
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

local function choosePileSquare(area)
    local cell = getWorld():getCell()
    local z    = area.z or 0
    for y = area.minY, area.maxY do
        for x = area.minX, area.maxX do
            local sq = cell:getGridSquare(x, y, z)
            if sq and (z == 0 or sq:getFloor()) then
                return sq
            end
        end
    end
    local cx = math.floor((area.minX + area.maxX) / 2)
    local cy = math.floor((area.minY + area.maxY) / 2)
    return cell:getGridSquare(cx, cy, z)
end

local function enqueueChop(rect, z, p)
    local cell = getWorld():getCell()
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

local function queueSize(p)
    local q = ISTimedActionQueue.getTimedActionQueue(p:getPlayerNum())
    return (q and q.queue and q.queue:size()) or 0
end

-- Public: start the job
function AF_Worker.start(p, chopArea, pileArea)
    local z    = chopArea.z or 0
    local rect = { chopArea.minX, chopArea.minY, chopArea.maxX, chopArea.maxY }
    AF_Hauler.setWoodPileSquare( choosePileSquare(pileArea) )

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
                local picked = AF_Hauler.enqueueBatch(p, rect, z, 20) -- up to 20 pickups
                if picked == 0 then
                    AF_Hauler.dropBatchToPile(p, 200) -- drop whatever is left
                    local logsInInv = p:getInventory():getCountTypeRecurse("Base.Log")
                    if not rectHasLogs(rect, z) and logsInInv == 0 and queueSize(p) == 0 then
                        state.phase = "sweep"
                        AF_Log.info("AutoForester: Sweep phase…")
                    end
                else
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
