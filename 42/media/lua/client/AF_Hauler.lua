local okLog, AF_Log = pcall(require, "AF_Logger")
if not okLog or type(AF_Log) ~= "table" then
    AF_Log = {
        info  = function(...) print("[AutoForester][I]", ...) end,
        warn  = function(...) print("[AutoForester][W]", ...) end,
        error = function(...) print("[AutoForester][E]", ...) end
    }
end

AF_Hauler = {}

local pileSq -- IsoGridSquare where we drop logs

function AF_Hauler.setWoodPileSquare(sq)
    if sq and instanceof(sq, "IsoGridSquare") then
        pileSq = sq
        AF_Log.info(string.format("AutoForester: wood pile set at (%d,%d,%d)",
                         sq:getX(), sq:getY(), sq:getZ()))
    else
        pileSq = nil
        AF_Log.warn("AutoForester: wood pile square cleared (invalid square)")
    end
end

local function isLogWorldObj(wobj)
    if not (wobj and instanceof(wobj, "IsoWorldInventoryObject")) then return false end
    local it = wobj:getItem()
    return it and it.getFullType and it:getFullType() == "Base.Log"
end

local function invNearlyFull(p)
    local inv = p and p:getInventory()
    if not inv then return false end
    local cur = inv:getCapacityWeight()
    local max = inv:getMaxWeight()
    return cur >= (max - 2) -- keep ~2 units headroom
end

-- Scan rect for log world-objects and enqueue walk+grab actions.
-- Returns how many pickups we enqueued (capped by maxPickups).
function AF_Hauler.enqueueBatch(playerObj, rect, z, maxPickups)
    if not playerObj then return 0 end
    local cell = getCell()
    if not cell then return 0 end

    local toQueue  = math.max(1, maxPickups or 12)
    local enqueued = 0

    -- simple weight gate so we don't over-enqueue when nearly full
    local function invNearlyFull()
        local inv = playerObj:getInventory()
        return inv and (inv:getCapacityWeight() >= playerObj:getMaxWeight() * 0.9)
    end

    for y = rect[2], rect[4] do
        for x = rect[1], rect[3] do
            if enqueued >= toQueue then
                AF_Log.info("AutoForester: Haul actions queued ("..tostring(enqueued)..")")
                return enqueued
            end

            if invNearlyFull() then
                AF_Log.info("AutoForester: inventory almost full while enqueueing haul; stopping batch.")
                AF_Log.info("AutoForester: Haul actions queued ("..tostring(enqueued)..")")
                return enqueued
            end

            local sq = cell:getGridSquare(x, y, z)
            if sq then
                local wobs = sq:getWorldObjects()
                local n = (wobs and wobs:size()) or 0
                for i = 0, n - 1 do
                    local w = wobs:get(i)
                    -- we must pass the WORLD OBJECT to ISGrabItemAction (not w:getItem())
                    if w and instanceof(w, "IsoWorldInventoryObject") then
                        local it = w:getItem()
                        if it and it.getFullType and it:getFullType() == "Base.Log" then
                            ISTimedActionQueue.add(ISWalkToTimedAction:new(playerObj, sq))
                            ISTimedActionQueue.add(ISGrabItemAction:new(playerObj, w, 50))  -- <-- key change
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
    end

    AF_Log.info("AutoForester: Haul actions queued ("..tostring(enqueued)..")")
    return enqueued
end


-- Drop up to `limit` logs from the player's inventory at the pile square.
function AF_Hauler.dropBatchToPile(playerObj, limit)
    if not pileSq or not playerObj then return 0 end

    local inv = playerObj:getInventory()
    if not inv then return 0 end

    -- Collect up to `limit` logs from the *root* inventory (safe across B42).
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

    -- Walk to the pile first, then drop at feet (which will be on the pile).
    ISTimedActionQueue.add(ISWalkToTimedAction:new(playerObj, pileSq))

    for _, it in ipairs(toDrop) do
        -- vanilla action; drops on the square the player is standing on
        ISTimedActionQueue.add(ISDropItemAction:new(playerObj, it, 0))
    end

    AF_Log.info("AutoForester: queued " .. tostring(#toDrop) .. " drop(s) to pile.")
    return #toDrop
end

return AF_Hauler
