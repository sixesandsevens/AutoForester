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
function AF_Hauler.enqueueBatch(playerObj, rect, z, maxPerBatch)
    maxPerBatch = maxPerBatch or 8
    local enqueued = 0
    local inv = playerObj:getInventory()

    -- current carried weight
    local function curW() return inv.getCapacityWeight and inv:getCapacityWeight() or 0 end
    -- effective capacity
    local function maxW()
        if inv.getEffectiveCapacity then return inv:getEffectiveCapacity(playerObj) end
        if inv.getCapacity then return inv:getCapacity() end
        return 50
    end
    -- item weight helper
    local function itemW(it)
        return (it.getUnequippedWeight and it:getUnequippedWeight())
            or (it.getActualWeight and it:getActualWeight())
            or (it.getWeight and it:getWeight())
            or 1
    end
    -- keep a little headroom so the next action won’t bug out
    local headroom = 0.5

    for y = rect[2], rect[4] do
        for x = rect[1], rect[3] do
            if enqueued >= maxPerBatch then break end
            local sq = getCell():getGridSquare(x, y, z)
            if sq then
                local wobs = sq:getWorldObjects()
                for i = 0, (wobs and wobs:size() or 0) - 1 do
                    if enqueued >= maxPerBatch then break end
                    local w = wobs:get(i)
                    if w and instanceof(w, "IsoWorldInventoryObject") then
                        local it = w:getItem()
                        if it and it.getFullType and it:getFullType() == "Base.Log" then
                            -- **DO NOT** enqueue a pickup if it would overweight us.
                            if (curW() + itemW(it)) > (maxW() - headroom) then
                                -- Stop here; onTick will switch to drop at the pile.
                                return enqueued
                            end
                            -- Walk to the square (so pickup succeeds), then grab.
                            ISTimedActionQueue.add(ISWalkToTimedAction:new(playerObj, sq))
                            ISTimedActionQueue.add(ISGrabItemAction:new(playerObj, it, 50))
                            enqueued = enqueued + 1
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

    -- Scan the root inventory and pick only Base.Log items.
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

    -- Walk to the pile, then drop logs at our feet (onto the pile square).
    ISTimedActionQueue.add(ISWalkToTimedAction:new(playerObj, pileSq))

    -- Use a small but non-zero drop time to avoid UI/progress glitches.
    local DROP_TIME = 10
    for _, it in ipairs(toDrop) do
        ISTimedActionQueue.add(ISDropItemAction:new(playerObj, it, DROP_TIME))
    end

    AF_Log.info("AutoForester: queued " .. tostring(#toDrop) .. " drop(s) to pile.")
    return #toDrop
end

return AF_Hauler
