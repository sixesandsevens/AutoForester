local okLog, AF_Log = pcall(require, "AF_Logger")
if not okLog or type(AF_Log) ~= "table" then
    AF_Log = { info=function(...) print("[AutoForester][I]", ...) end,
               warn=function(...) print("[AutoForester][W]", ...) end,
               error=function(...) print("[AutoForester][E]", ...) end }
end

AF_Hauler = {}
local PILE_SQ = nil

function AF_Hauler.setWoodPileSquare(sq) PILE_SQ = sq end

local function itemWeight(inv, item)
    local w = nil
    if item.getUnequippedWeight then w = item:getUnequippedWeight() end
    if not w and item.getActualWeight then w = item:getActualWeight() end
    if not w then w = item:getWeight() end
    return w or 0.5
end

local function invCapacity(inv)
    if inv.getEffectiveCapacity then return inv:getEffectiveCapacity(nil) end
    return inv:getCapacity()
end

local function invUsed(inv)
    if inv.getCapacityWeight then return inv:getCapacityWeight() end
    return inv:getContentsWeight()
end

local function overweightAfter(inv, item, frac)
    frac = frac or 0.95
    return invUsed(inv) + itemWeight(inv, item) > invCapacity(inv) * frac
end

function AF_Hauler.isHaulItem(item)
    local t = item and item.getFullType and item:getFullType() or ""
    return t == "Base.Log" or t == "Base.TreeBranch" or t == "Base.Twigs" or t == "Base.UnusableWood"
end

local function floorContainer(square)
    if not square then return nil end
    if square.getWorldInventory then return square:getWorldInventory() end
    return nil
end

local function walkAdj(p, sq)
    return luautils.walkAdj(p, sq, true)
end

-- Enqueue pickup transfers from ground -> player inv on this square (up to 'limit' items)
function AF_Hauler.queuePickupOnSquare(p, sq, limit)
    local wobs = sq and sq:getWorldObjects()
    if not wobs or wobs:size() == 0 then return 0 end

    local inv  = p:getInventory()
    local added = 0
    for i = wobs:size()-1, 0, -1 do
        local o = wobs:get(i)
        if instanceof(o, "IsoWorldInventoryObject") then
            local it = o:getItem()
            if it and AF_Hauler.isHaulItem(it) then
                local src = it:getContainer()
                if not src then
                    AF_Log.warn("Skip ghost item (no container) at "..sq:getX()..","..sq:getY())
                    goto continue
                end
                if overweightAfter(inv, it) then break end
                if walkAdj(p, sq) then
                    ISTimedActionQueue.add(ISInventoryTransferAction:new(p, it, src, inv))
                    added = added + 1
                    if limit and added >= limit then break end
                end
            end
        end
        ::continue::
    end
    return added
end

-- Scan the rect and enqueue up to maxPickups pickup actions total
function AF_Hauler.enqueueBatch(p, rect, z, maxPickups)
    local cell = getWorld():getCell()
    local remaining = maxPickups or 20
    for x = rect[1], rect[3] do
        for y = rect[2], rect[4] do
            local sq = cell:getGridSquare(x, y, z)
            if sq then
                local took = AF_Hauler.queuePickupOnSquare(p, sq, remaining)
                remaining = remaining - took
                if remaining <= 0 then
                    return (maxPickups or 20) - remaining
                end
            end
        end
    end
    return (maxPickups or 20) - remaining
end

-- Drop up to 'limit' haul items from inventory to the pile square
function AF_Hauler.dropBatchToPile(p, limit)
    if not PILE_SQ then return 0 end
    local to = floorContainer(PILE_SQ)
    local inv = p:getInventory()
    if not to then
        if not walkAdj(p, PILE_SQ) then return 0 end
    end

    local moved = 0
    local items = inv:getItems()
    for i = items:size()-1, 0, -1 do
        local it = items:get(i)
        if AF_Hauler.isHaulItem(it) then
            if to then
                ISTimedActionQueue.add(ISInventoryTransferAction:new(p, it, inv, to))
            else
                p:dropItem(it)
            end
            moved = moved + 1
            if limit and moved >= limit then break end
        end
    end
    return moved
end

return AF_Hauler
