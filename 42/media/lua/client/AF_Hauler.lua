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

-- Where logs will be dropped.
local pileSq -- IsoGridSquare

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

local function isLogItem(item)
    if not item then return false end
    -- Works on B42: both vanilla and mods still call these "Log"
    local t = item.getFullType and item:getFullType() or item:getType()
    return t == "Base.Log" or t == "Log" or t == "Base.LogStacks" -- futureproof-ish
end

local function isLogWorldObj(wobj)
    -- World object holding an InventoryItem
    if not wobj or not instanceof(wobj, "IsoWorldInventoryObject") then return false end
    return isLogItem(wobj:getItem())
end

local function canCarryAnotherLog(p)
    -- Super simple weight gate so we don't queue infinite grabs
    local inv = p:getInventory()
    local cap = p:getMaxWeight()
    local cur = inv:getCapacityWeight()
    -- Logs are heavy (~3.0), leave a little headroom for pathing/equipped stuff
    return (cap - cur) > 3.2
end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

function AF_Hauler.setWoodPileSquare(sq)
    if sq and instanceof(sq, "IsoGridSquare") then
        pileSq = sq
        AF_Log.info("AutoForester: wood pile set to "..sq:getX()..","..sq:getY()..","..sq:getZ())
    else
        AF_Log.warn("AutoForester: setWoodPileSquare called with invalid square.")
        pileSq = nil
    end
end

-- Scan rect for log world-objects and enqueue walk+grab actions.
-- Returns how many pickups we enqueued (capped by maxPickups).
function AF_Hauler.enqueueBatch(p, rect, z, maxPickups)
    if not p then return 0 end
    maxPickups = math.max(1, maxPickups or 12)
    local cell = getCell()
    local enqueued = 0

    for y = rect.minY, rect.maxY do
        for x = rect.minX, rect.maxX do
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

                    if isLogWorldObj(w) and canCarryAnotherLog(p) then
                        -- IMPORTANT: pass the WORLD OBJECT to ISGrabItemAction
                        ISTimedActionQueue.add(ISWalkToTimedAction:new(p, sq))
                        ISTimedActionQueue.add(ISGrabItemAction:new(p, w, 50))
                        enqueued = enqueued + 1
                        if enqueued >= maxPickups then
                            AF_Log.info("AutoForester: Haul actions queued ("..tostring(enqueued)..")")
                            return enqueued
                        end
                    end
                end
            end
        end
    end

    if enqueued > 0 then
        AF_Log.info("AutoForester: Haul actions queued ("..tostring(enqueued)..")")
    end
    return enqueued
end

-- Walk to the pile and drop up to `limit` logs currently carried.
-- Returns how many we scheduled to drop.
function AF_Hauler.dropBatchToPile(p, limit)
    if not p or not pileSq then return 0 end
    limit = limit or 200

    local inv = p:getInventory()
    local toDrop = {}
    local items = inv:getItems()

    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if isLogItem(it) then
            toDrop[#toDrop+1] = it
            if #toDrop >= limit then break end
        end
    end

    if #toDrop == 0 then return 0 end

    ISTimedActionQueue.add(ISWalkToTimedAction:new(p, pileSq))
    for i = 1, #toDrop do
        local it = toDrop[i]
        -- Drop at the pile square coordinates (works in B42).
        ISTimedActionQueue.add(ISDropWorldItemAction:new(
            p, it, pileSq:getX(), pileSq:getY(), pileSq:getZ()))
    end

    AF_Log.info("AutoForester: dropped "..tostring(#toDrop).." logs to pile")
    return #toDrop
end

return AF_Hauler
