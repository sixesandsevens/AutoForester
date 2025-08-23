
-- media/lua/client/AF_Hauler.lua
-- Gather Base.Log items in area and drop at designated wood pile.
local AFCore = require "AF_Core"
local AF_Log = require "AF_Logger"

AF_Hauler = {}

local function countLogsInInv(p)
    local inv = p:getInventory()
    return inv and inv:getCountTypeRecurse("Base.Log") or 0
end

local function pickupLogsFromSquare(p, sq, maxTake)
    local items = sq:getWorldObjects()
    if not items then return 0 end
    local taken = 0
    for i=0, items:size()-1 do
        local wo = items:get(i)
        if wo and wo:getItem() and wo:getItem():getFullType() == "Base.Log" then
            ISTimedActionQueue.add(ISWalkToTimedAction:new(p, sq))
            ISTimedActionQueue.add(ISPickupWorldItemAction:new(p, wo, 0))
            taken = taken + 1
            if maxTake and taken >= maxTake then break end
        end
    end
    return taken
end

local function dropLogsAtWoodPile(p)
    local x,y,z = AFCore.getWoodPile()
    if not x then AF_Log.warn("No wood pile set; skipping haul drop."); return false end
    local sq = getCell():getGridSquare(x,y,z or 0)
    if not sq then return false end
    ISTimedActionQueue.add(ISWalkToTimedAction:new(p, sq))
    local inv = p:getInventory()
    local toDrop = {}
    local it = inv:FindAll("Base.Log")
    if it then
        for i=0, it:size()-1 do table.insert(toDrop, it:get(i)) end
    end
    for _,item in ipairs(toDrop) do
        ISTimedActionQueue.add(ISDropItemAction:new(p, item, 0))
    end
    return #toDrop > 0
end

function AF_Hauler.enqueueHaulSquare(p, sq)
    local took = pickupLogsFromSquare(p, sq, nil)
    if took > 0 then
        dropLogsAtWoodPile(p)
        return true
    end
    return false
end

return AF_Hauler
