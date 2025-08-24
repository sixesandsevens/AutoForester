-- AF_Hauler.lua
local AF_Hauler = {}

local okLog, AF_Log = pcall(require, "AF_Logger")
if not okLog or type(AF_Log) ~= "table" then
    AF_Log = {
        info  = function(...) print("[AutoForester][I]", ...) end,
        warn  = function(...) print("[AutoForester][W]", ...) end,
        error = function(...) print("[AutoForester][E]", ...) end
    }
end

local pileSq = nil

function AF_Hauler.setWoodPileSquare(sq)
    if sq and sq.getX then
        pileSq = sq
        AF_Log.info(("AutoForester: wood pile set to %d,%d,%d")
            :format(sq:getX(), sq:getY(), sq:getZ()))
    else
        AF_Log.warn("AutoForester: setWoodPileSquare called with invalid sq")
        pileSq = nil
    end
end

local function invNearlyFull(p)
    -- Conservative: stop queuing grabs when near max carry.
    local inv   = p and p:getInventory()
    local wt    = inv and inv:getCapacityWeight() or 0
    local maxWt = p and p:getMaxWeight() or 8
    return wt >= (maxWt * 0.9)
end

-- Scan rect for world-log objects and enqueue walk+grab actions.
-- Returns how many pickups we enqueued (capped by maxPickups).
function AF_Hauler.enqueueBatch(p, rect, z, maxPickups)
    if not p then return 0 end
    maxPickups = math.max(1, maxPickups or 12)
    local cell = getCell()
    local enqueued = 0

    for y = rect[2], rect[4] do
        for x = rect[1], rect[3] do
            if enqueued >= maxPickups then
                AF_Log.info("AutoForester: Haul actions queued ("..tostring(enqueued)..")")
                return enqueued
            end

            local sq = cell:getGridSquare(x, y, z)
            if sq then
                local wobs = sq:getWorldObjects()
                local n = (wobs and wobs:size() or 0)
                for i = 0, n - 1 do
                    local w = wobs:get(i)
                    if w and instanceof(w, "IsoWorldInventoryObject") then
                        local it = w:getItem()
                        if it and it:getFullType() == "Base.Log" then
                            -- Walk to world object, then grab it.
                            ISTimedActionQueue.add(ISWalkToTimedAction:new(p, sq))
                            ISTimedActionQueue.add(ISGrabItemAction:new(p, w, 50))
                            enqueued = enqueued + 1
                            if invNearlyFull(p) then
                                AF_Log.info("AutoForester: inventory almost full while enqueuing haul; stopping batch.")
                                AF_Log.info("AutoForester: Haul actions queued ("..tostring(enqueued)..")")
                                return enqueued
                            end
                            if enqueued >= maxPickups then
                                AF_Log.info("AutoForester: Haul actions queued ("..tostring(enqueued)..")")
                                return enqueued
                            end
                        end
                    end
                end
            end
        end
    end

    AF_Log.info("AutoForester: Haul actions queued ("..tostring(enqueued)..")")
    return enqueued
end

-- Drop up to `limit` logs from inventory at the pile square.
function AF_Hauler.dropBatchToPile(playerObj, limit)
    if not pileSq or not playerObj then return 0 end

    local inv = playerObj:getInventory()
    if not inv then return 0 end

    -- Collect up to `limit` logs from the *root* inventory.
    local items = inv:getItems()
    if not items then return 0 end

    local toDrop = {}
    local maxDrop = math.min(limit or 200, items:size())
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if it and it.getFullType and it:getFullType() == "Base.Log" then
            toDrop[#toDrop + 1] = it
            if #toDrop >= maxDrop then break end
        end
    end
    if #toDrop == 0 then return 0 end

    -- Walk to the pile first.
    ISTimedActionQueue.add(ISWalkToTimedAction:new(playerObj, pileSq))

    -- Timed, reliable drop (world coords) if available; else vanilla drop-at-feet.
    for i = 1, #toDrop do
        local it = toDrop[i]
        if ISDropWorldItemAction and ISDropWorldItemAction.new then
            ISTimedActionQueue.add(ISDropWorldItemAction:new(
                playerObj, it, pileSq:getX(), pileSq:getY(), pileSq:getZ()))
        else
            ISTimedActionQueue.add(ISDropItemAction:new(playerObj, it, 0))
        end
    end

    AF_Log.info("AutoForester: queued " .. tostring(#toDrop) .. " drop(s) to pile.")
    return #toDrop
end

return AF_Hauler
