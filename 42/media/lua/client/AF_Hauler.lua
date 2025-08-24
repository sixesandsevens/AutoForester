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

-- Queue up to maxCount log pickups found in rect/z.
-- Returns number of pickups queued.
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
                local n = (wobs and wobs:size() or 0)
                for i = 0, n - 1 do
                    local w = wobs:get(i)
                    if isLogWorldObj(w) then
                        -- walk to the square then grab the world item
                        ISTimedActionQueue.add(ISWalkToTimedAction:new(playerObj, sq))
                        local item = w:getItem()
                        ISTimedActionQueue.add(ISGrabItemAction:new(playerObj, item, 50))
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

    local toDrop = {}
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if it and it.getFullType and it:getFullType() == "Base.Log" then
            toDrop[#toDrop+1] = it
        end
    end
    if #toDrop == 0 then return 0 end

    ISTimedActionQueue.add(ISWalkToTimedAction:new(playerObj, pileSq))
    for i = 1, #toDrop do
        local it = toDrop[i]
        -- If your build doesn’t have ISDropWorldItemAction, we can switch to
        -- ISInventoryPaneContextMenu.dropItem(it, playerObj:getPlayerNum()) later.
        ISTimedActionQueue.add(ISDropWorldItemAction:new(
            playerObj, it, pileSq:getX(), pileSq:getY(), pileSq:getZ()))
    end
    AF_Log.info("AutoForester: dropped "..tostring(#toDrop).." logs to pile")
    return #toDrop
end

return AF_Hauler
