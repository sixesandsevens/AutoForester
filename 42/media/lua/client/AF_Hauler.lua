local okLog, AF_Log = pcall(require, "AF_Logger")
if not okLog or type(AF_Log) ~= "table" then
    AF_Log = {
        info  = function(...) print("[AutoForester][I]", ...) end,
        warn  = function(...) print("[AutoForester][W]", ...) end,
        error = function(...) print("[AutoForester][E]", ...) end,
    }
end

AF_Hauler = {}

-- Where we drop logs
local pileSq ---@type IsoGridSquare|nil

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

-- light weight-gate so we don’t spam actions when nearly full
local function invNearlyFull(p)
    local inv = p and p:getInventory()
    if not inv then return false end
    local cur = inv:getCapacityWeight()
    local max = p:getMaxWeight() or inv:getMaxWeight()
    return cur >= (max - 2)
end

---------------------------------------------------------------------------
-- Pickups
-- Scan rect for log world-objects and enqueue walk+grab actions.
-- Returns number of grab actions enqueued (capped by maxPickups).
---------------------------------------------------------------------------
function AF_Hauler.enqueueBatch(playerObj, rect, z, maxPickups)
    if not playerObj then return 0 end
    local cell = getCell()
    if not cell then return 0 end

    local toQueue  = math.max(1, maxPickups or 12)
    local enqueued = 0
    z = z or 0

    for y = rect[2], rect[4] do
        for x = rect[1], rect[3] do
            if enqueued >= toQueue then
                AF_Log.info("AutoForester: Haul actions queued ("..tostring(enqueued)..")")
                return enqueued
            end

            if invNearlyFull(playerObj) then
                AF_Log.info("AutoForester: inventory almost full while enqueueing haul; stopping batch.")
                AF_Log.info("AutoForester: Haul actions queued ("..tostring(enqueued)..")")
                return enqueued
            end

            local sq = cell:getGridSquare(x, y, z)
            if sq then
                local wobs = sq:getWorldObjects()
                local n = (wobs and wobs:size()) or 0
                for i = 0, n - 1 do
                    local w = wobs:get(i) -- *** world object ***
                    if isLogWorldObj(w) then
                        -- walk there, then GRAB THE WORLD OBJECT (not the inventory item)
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

---------------------------------------------------------------------------
-- Drops
-- Drop up to `limit` logs from the player's inventory at the pile square.
---------------------------------------------------------------------------
function AF_Hauler.dropBatchToPile(playerObj, limit)
    if not pileSq or not playerObj then return 0 end

    local inv = playerObj:getInventory()
    if not inv then return 0 end

    -- Gather logs from *root* inventory (B42-safe)
    local items = inv:getItems()
    if not items then return 0 end

    local toDrop = {}
    local maxDrop = math.min(limit or 50, items:size())
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if it and it.getFullType and it:getFullType() == "Base.Log" then
            toDrop[#toDrop + 1] = it
            if #toDrop >= maxDrop then break end
        end
    end
    if #toDrop == 0 then return 0 end

    -- Walk to the pile first
    ISTimedActionQueue.add(ISWalkToTimedAction:new(playerObj, pileSq))

    -- Prefer exact-tile world drop; fall back to timed feet drop; last resort instant drop.
    local x, y, z = pileSq:getX(), pileSq:getY(), pileSq:getZ()
    for i = 1, #toDrop do
        local it = toDrop[i]
        if ISDropWorldItemAction and ISDropWorldItemAction.new then
            ISTimedActionQueue.add(ISDropWorldItemAction:new(playerObj, it, x, y, z))
        elseif ISDropItemAction and ISDropItemAction.new then
            ISTimedActionQueue.add(ISDropItemAction:new(playerObj, it, 0))
        else
            inv:DoRemoveItem(it)
            pileSq:AddWorldInventoryItem(it, 0.5, 0.5, 0)
        end
    end

    AF_Log.info("AutoForester: queued " .. tostring(#toDrop) .. " drop(s) to pile.")
    return #toDrop
end

return AF_Hauler
