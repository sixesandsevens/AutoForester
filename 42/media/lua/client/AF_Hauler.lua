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

-- Identify "world log" safely.
local function isLogWorldObj(w)
    if not (w and instanceof(w, "IsoWorldInventoryObject")) then return false end
    local it = w:getItem()
    return it and it.getFullType and it:getFullType() == "Base.Log"
end

local function invNearlyFull(p, thresh)
    thresh = thresh or 0.85
    local inv = p and p.getInventory and p:getInventory() or nil
    if not inv then return false end
    local carried = inv:getCapacityWeight() or 0
    local maxW    = p.getMaxWeight and p:getMaxWeight() or 12
    return carried >= (maxW * thresh)
end

-- Pick a destination container with room (prefers equipped back item).
local function pickDestContainer(playerObj, unitWeight)
    unitWeight = unitWeight or 3.0
    -- prefer back item
    local back = playerObj.getClothingItem_Back and playerObj:getClothingItem_Back() or nil
    if back and back.getItemContainer then
        local c = back:getItemContainer()
        if c and c.hasRoomFor and c:hasRoomFor(playerObj, unitWeight) then return c end
    end
    -- any carried container
    local inv = playerObj:getInventory()
    local items = inv and inv:getItems()
    if items then
        for i = 0, items:size() - 1 do
            local it = items:get(i)
            if instanceof(it, "InventoryContainer") then
                local c = it:getItemContainer()
                if c and c.hasRoomFor and c:hasRoomFor(playerObj, unitWeight) then
                    return c
                end
            end
        end
    end
    return nil
end

-- Compute how many logs we can enqueue right now
local function logsThatFit(playerObj, destContainer, unitWeight)
    unitWeight = unitWeight or 3.0
    if destContainer and destContainer.hasRoomFor then
        local can = 0
        for _ = 1, 10 do -- hard cap probes
            if destContainer:hasRoomFor(playerObj, unitWeight) then
                can = can + 1
            else
                break
            end
        end
        return can
    else
        local maxW = playerObj.getMaxWeight and playerObj:getMaxWeight() or 12
        local curW = playerObj.getInventoryWeight and playerObj:getInventoryWeight() or 0
        local free = math.max(0, maxW - curW)
        return math.max(0, math.floor(free / unitWeight))
    end
end

-- Scan rect and enqueue walk+grab actions (up to maxCount) with capacity awareness.
function AF_Hauler.enqueueBatch(playerObj, rect, z, maxCount)
    local cell     = getWorld():getCell()
    local unitW    = 3.0 -- Base.Log typical weight
    local dest     = pickDestContainer(playerObj, unitW)

    local hardCap  = math.min(maxCount or 20, 20)
    local softCap  = math.max(1, logsThatFit(playerObj, dest, unitW))
    local toQueue  = math.max(1, math.min(hardCap, softCap))

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
                    local w = wobs:get(i)
                    if isLogWorldObj(w) then
                        if enqueued >= toQueue then
                            AF_Log.info("AutoForester: Haul actions queued ("..tostring(enqueued)..")")
                            return enqueued
                        end
                        -- walk to square
                        ISTimedActionQueue.add(ISWalkToTimedAction:new(playerObj, sq))
                        -- grab inventory item from world; prefer container destination
                        local item = w:getItem()
                        if dest then
                            ISTimedActionQueue.add(ISGrabItemAction:new(playerObj, item, 50, dest))
                        else
                            ISTimedActionQueue.add(ISGrabItemAction:new(playerObj, item, 50))
                        end
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

    -- walk to the pile once, then drop at feet (on the pile)
    ISTimedActionQueue.add(ISWalkToTimedAction:new(playerObj, pileSq))
    local DROP_TIME = 10 -- non-zero to avoid glitched progress bar
    for _, it in ipairs(toDrop) do
        ISTimedActionQueue.add(ISDropItemAction:new(playerObj, it, DROP_TIME))
    end

    AF_Log.info("AutoForester: queued "..tostring(#toDrop).." drop(s) to pile.")
    return #toDrop
end

return AF_Hauler