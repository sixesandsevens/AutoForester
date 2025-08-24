-- AF_Worker.lua – orchestrates chop → haul → sweep over an area
local AF_Log    = require "AF_Logger"
local AF_Hauler = require "AF_Hauler"
local AF_Sweeper= require "AF_Sweeper"

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
    -- pick first valid tile inside area; simple and robust
    for y = area.minY, area.maxY do
        for x = area.minX, area.maxX do
            local sq = cell:getGridSquare(x, y, z)
            if sq and (z == 0 or sq:getFloor()) then
                return sq
            end
        end
    end
    -- fallback: center
    local cx = math.floor((area.minX + area.maxX) / 2)
    local cy = math.floor((area.minY + area.maxY) / 2)
    return cell:getGridSquare(cx, cy, z)
end

local function enqueueChop(rect, z, p)
    local cell = getWorld():getCell()
    for x = rect[1], rect[3] do
        for y = rect[2], rect[4] do
            local sq = cell:getGridSquare(x, y, z)
            if sq and sq:HasTree() then
                local tree = sq:getTree()
                if tree then
                    ISWorldObjectContextMenu.doChopTree(p, tree) -- queues timed actions
                end
            end
        end
    end
end

local function enqueueHaul(rect, z, p)
    local cell = getWorld():getCell()
    for x = rect[1], rect[3] do
        for y = rect[2], rect[4] do
            local sq = cell:getGridSquare(x, y, z)
            if sq then AF_Hauler.enqueueHaulSquare(p, sq) end
        end
    end
end

local function enqueueSweep(rect, z, p)
    local cell = getWorld():getCell()
    for x = rect[1], rect[3] do
        for y = rect[2], rect[4] do
            local sq = cell:getGridSquare(x, y, z)
            if sq then AF_Sweeper.trySweep(p, sq) end
        end
    end
end

-- Public: start the job
function AF_Worker.start(p, chopArea, pileArea)
    local z    = chopArea.z or 0
    local rect = { chopArea.minX, chopArea.minY, chopArea.maxX, chopArea.maxY }
    AF_Hauler.setWoodPileSquare( choosePileSquare(pileArea) )

    -- Phase 1: chop
    enqueueChop(rect, z, p)
    AF_Log.info("Chop actions queued.")

    -- Tick driver: when no trees remain, haul; when no logs remain (and none in inv), sweep; then done.
    local state = { phase = "chop" }

    local function onTick()
        if state.phase == "chop" then
            if rectHasTrees(rect, z) then return end
            state.phase = "haul"
            enqueueHaul(rect, z, p)
            AF_Log.info("Haul actions queued.")
            return
        end

        if state.phase == "haul" then
            local logsInInv = p:getInventory():getCountTypeRecurse("Base.Log")
            if rectHasLogs(rect, z) or logsInInv > 0 then return end
            state.phase = "sweep"
            enqueueSweep(rect, z, p)
            AF_Log.info("Sweep actions queued.")
            return
        end

        -- sweep is fire-and-forget; stop driving
        Events.OnTick.Remove(onTick)
        if p.Say then p:Say("AutoForester: done.") end
    end

    Events.OnTick.Remove(onTick)
    Events.OnTick.Add(onTick)
end

return AF_Worker
