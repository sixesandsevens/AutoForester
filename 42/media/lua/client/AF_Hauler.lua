-- 42/media/lua/client/AF_Hauler.lua
local okLog, AF_Log = pcall(require, "AF_Logger")
if not okLog or type(AF_Log) ~= "table" then
    AF_Log = {
        info  = function(...) print("[AutoForester][I]", ...) end,
        warn  = function(...) print("[AutoForester][W]", ...) end,
        error = function(...) print("[AutoForester][E]", ...) end,
    }
end

AF_Hauler = {}

-- Destination square for dropping logs.
local pileSq = nil

function AF_Hauler.setWoodPileSquare(sq)
    if sq and instanceof(sq, "IsoGridSquare") then
        pileSq = sq
        local sx, sy, sz = sq:getX(), sq:getY(), sq:getZ()
        AF_Log.info(string.format("AutoForester: wood pile set to (%d,%d,%d)", sx, sy, sz))
    else
        AF_Log.warn("AutoForester: setWoodPileSquare called with invalid sq; clearing.")
        pileSq = nil
    end
end

local function isWorldLog(wobj)
    if not wobj or not instanceof(wobj, "IsoWorldInventoryObject") then return false end
    local it = wobj:getItem()
    return it and it.getFullType and it:getFullType() == "Base.Log"
end

-- Scan rect for log world-objects and enqueue walk+grab actions.
-- Returns how many pickups we enqueued (capped by maxPickups).
function AF_Hauler.enqueueBatch(playerObj, rect, z, maxPickups)
    if not playerObj then return 0 end
    local cell = getCell()
    if not cell then return 0 end

    local toQueue  = math.max(1, maxPickups or 12)
    local enqueued = 0

    for y = rect[2], rect[4] do
        for x = rect[1], rect[3] do
            if enqueued >= toQueue then
                AF_Log.info("AutoForester: Haul actions queued (" .. tostring(enqueued) .. ")")
                return enqueued
            end

            local sq = cell:getGridSquare(x, y, z)
            if sq then
                -- If we’re close to full, stop adding more pickups.
                local inv = playerObj:getInventory()
                if inv and (inv:getCapacityWeight() >= playerObj:getMaxWeight() * 0.9) then
                    AF_Log.info("AutoForester: inventory almost full while enqueueing haul; stopping batch.")
                    AF_Log.info("AutoForester: Haul actions queued ("..tostring(enqueued)..")")
                    return enqueued
                end

                local wobs = sq:getWorldObjects()
                local n = (wobs and wobs:size()) or 0
                for i = 0, n - 1 do
                    local w = wobs:get(i)
                    if isWorldLog(w) then
                        -- IMPORTANT: pass the IsoWorldInventoryObject to ISGrabItemAction.
                        ISTimedActionQueue.add(ISWalkToTimedAction:new(playerObj, sq))
                        ISTimedActionQueue.add(ISGrabItemAction:new(playerObj, w, 50))
                        enqueued = enqueued + 1
                        if enqueued >= toQueue then
                            AF_Log.info("AutoForester: Haul actions queued ("..tostring(enqueued)..")")
                            return enqueued
                        end
                    end
                end
            end
        end
    end

    AF_Log.info("AutoForester: Haul actions queued ("..tostring(enqueued)..")")
    return enqueued
end

-- Drop any logs currently carried onto the pile square.
-- Returns number of logs we tried to drop.
function AF_Hauler.dropBatchToPile(playerObj, _maxWalk)
    if not (pileSq and instanceof(pileSq, "IsoGridSquare")) then return 0 end

    local inv   = playerObj:getInventory()
    local items = inv and inv:getItems()
    if not items or items:size() == 0 then return 0 end

    -- collect logs from top-level inventory (ISGrabItemAction puts logs here)
    local toDrop = {}
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if it and it.getFullType and it:getFullType() == "Base.Log" then
            toDrop[#toDrop+1] = it
        end
    end
    if #toDrop == 0 then return 0 end

    -- walk to the pile and drop them
    ISTimedActionQueue.add(ISWalkToTimedAction:new(playerObj, pileSq))
    for i = 1, #toDrop do
        local it = toDrop[i]
        ISTimedActionQueue.add(ISDropWorldItemAction:new(
            playerObj, it, pileSq:getX(), pileSq:getY(), pileSq:getZ()))
    end
    AF_Log.info("AutoForester: dropped " .. tostring(#toDrop) .. " logs to pile")
    return #toDrop
end
