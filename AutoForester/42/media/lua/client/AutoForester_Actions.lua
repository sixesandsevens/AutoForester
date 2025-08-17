local Shared = require("AutoForester_Shared")
local Actions = {}
local function dbg(msg) print("[AutoForester] "..tostring(msg)) end

local AFInstantAction = ISBaseTimedAction:derive("AFInstantAction")
function AFInstantAction:isValid() return true end
function AFInstantAction:waitToStart() return false end
function AFInstantAction:update() end
function AFInstantAction:start() end
function AFInstantAction:stop() ISBaseTimedAction.stop(self) end
function AFInstantAction:perform()
    if self.func then pcall(self.func) end
    ISBaseTimedAction.perform(self)
end
function AFInstantAction:new(player, func)
    local o = ISBaseTimedAction.new(self, player)
    o.func = func
    o.maxTime = 1
    return o
end

local function getStockpileSquare(sp)
    if not sp then return nil end
    return getCell():getGridSquare(sp.x, sp.y, sp.z)
end

local function findWoodOnSquare(sq)
    local out = {}
    if not sq then return out end
    local wios = sq:getWorldObjects()
    if not wios then return out end
    for i=0, wios:size()-1 do
        local wio = wios:get(i)
        local item = wio and wio:getItem()
        if item and Shared.ITEM_TYPES[item:getType()] then
            table.insert(out, wio)
        end
    end
    return out
end

local function dropAllWood(player)
    local items = player:getInventory():getItems()
    for i=items:size()-1,0,-1 do
        local it = items:get(i)
        if it and Shared.ITEM_TYPES[it:getType()] then
            ISTimedActionQueue.add(ISDropItemAction:new(player, it))
        end
    end
end

function Actions.enqueueChopLootDeliver(player, tree, treeSq, stockpile)
    if not player or not tree then return end
    ISTimedActionQueue.add(ISChopTreeAction:new(player, tree))
    ISTimedActionQueue.add(AFInstantAction:new(player, function()
        local drops = findWoodOnSquare(treeSq)
        dbg("Found "..#drops.." wood items")
        for _,wio in ipairs(drops) do
            ISTimedActionQueue.add(ISGrabItemAction:new(player, wio, 5))
        end
    end))
    if stockpile then
        local pileSq = getStockpileSquare(stockpile)
        if pileSq then
            ISTimedActionQueue.add(ISWalkToAction:new(player, pileSq))
            ISTimedActionQueue.add(AFInstantAction:new(player, function()
                dropAllWood(player)
                Shared.Say(player, "Delivered wood.")
            end))
        end
    end
end

return Actions
