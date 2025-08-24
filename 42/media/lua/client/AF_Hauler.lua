local okLog, AF_Log = pcall(require, "AF_Logger")
if not okLog or type(AF_Log) ~= "table" then
    AF_Log = {
        info  = function(...) print("[AutoForester][I]", ...) end,
        warn  = function(...) print("[AutoForester][W]", ...) end,
        error = function(...) print("[AutoForester][E]", ...) end,
    }
end

local AF_Hauler = {}
local pileSq -- where we drop

function AF_Hauler.setWoodPileSquare(sq)
    if sq and instanceof(sq, "IsoGridSquare") then
        pileSq = sq
        local msg = string.format("AutoForester: wood pile set to %d,%d,%d", sq:getX(), sq:getY(), sq:getZ())
        AF_Log.info(msg)
    else
        AF_Log.warn("AutoForester: setWoodPileSquare called with invalid sq")
        pileSq = nil
    end
end

local function invNearlyFull(p, thresh)
    thresh = thresh or 0.85
    local inv = p and p.getInventory and p:getInventory() or nil
    if not inv then return false end
    local carried = inv:getCapacityWeight() or 0
    local maxW    = p.getMaxWeight and p:getMaxWeight() or 12
    return carried >= (maxW * thresh)
end

-- Scan rect and enqueue walk+grab actions (up to maxCount).
-- IMPORTANT: pass the IsoWorldInventoryObject to ISGrabItemAction.
function AF_Hauler.enqueueBatch(playerObj, rect, z, maxCount)
    local cell     = getWorld():getCell()
    local toQueue  = maxCount or 20
    local enqueued = 0

    for y = rect[2], rect[4] do
        for x = rect[1], rect[3] do
            if enqueued >= toQueue then
                AF_Log.info("AutoForester: Haul actions queued ("..tostring(enqueued)..")")
                return enqueued
            end

            local sq = cell:getGridSquare(x, y, z)
            if sq then
                local wobs = sq:getWorldObjects()
                local n    = (wobs and wobs:size()) or 0
                for i = 0, n - 1 do
                    local w = wobs:get(i) -- IsoWorldInventoryObject
                    if w and instanceof(w, "IsoWorldInventoryObject") then
                        local it = w:getItem()
                        if it and it.getFullType and it:getFullType() == "Base.Log" then
                            -- walk to the square before grabbing
                            ISTimedActionQueue.add(ISWalkToTimedAction:new(playerObj, sq))
                            ISTimedActionQueue.add(ISGrabItemAction:new(playerObj, w, 50))
                            enqueued = enqueued + 1
                            if enqueued >= toQueue or invNearlyFull(playerObj) then
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

    local items = inv:getItems()
    if not items then return 0 end

    local toDrop, maxDrop = {}, math.min(limit or 200, items:size())
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if it and it.getFullType and it:getFullType() == "Base.Log" then
            toDrop[#toDrop + 1] = it
            if #toDrop >= maxDrop then break end
        end
    end
    if #toDrop == 0 then return 0 end

    -- walk to the pile once, then drop each at feet (which are on the pile)
    ISTimedActionQueue.add(ISWalkToTimedAction:new(playerObj, pileSq))
    local DROP_TIME = 10 -- non-zero to avoid the glitched progress bar
    for _, it in ipairs(toDrop) do
        ISTimedActionQueue.add(ISDropItemAction:new(playerObj, it, DROP_TIME))
    end

    AF_Log.info("AutoForester: queued "..tostring(#toDrop).." drop(s) to pile.")
    return #toDrop
end

return AF_Hauler
