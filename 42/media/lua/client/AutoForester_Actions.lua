local Shared = require("AutoForester_Shared")

local Actions = {}

local function dbg(msg) print("[AutoForester] "..tostring(msg)) end

-- Tiny instant action so we can run a function inside ISTimedActionQueue
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

local function forEachSquareInSweep(centerSq, r, cb)
    if not centerSq then return end
    local cell = getCell()
    local z = centerSq:getZ()
    for dx=-r, r do
        for dy=-r, r do
            local sq = cell:getGridSquare(centerSq:getX()+dx, centerSq:getY()+dy, z)
            if sq then cb(sq) end
        end
    end
end

local function collectWoodWIOs(sq, out)
    local wios = sq and sq:getWorldObjects()
    if not wios then return end
    for i=0, wios:size()-1 do
        local wio = wios:get(i)
        local item = wio and wio:getItem()
        if item then
            local t = item:getType()
            if Shared.ITEM_TYPES[t] then table.insert(out, wio) end
        end
    end
end

local function dropAllWood(player)
    local items = player:getInventory():getItems()
    for i = items:size()-1, 0, -1 do
        local it = items:get(i)
        if it and Shared.ITEM_TYPES[it:getType()] then
            ISTimedActionQueue.add(ISDropItemAction:new(player, it))
        end
    end
end

-- Enqueue one tree cycle. When done, calls onDone() to trigger next.
function Actions.enqueueChopLootDeliver(player, tree, treeSq, stockpile, cfg, onDone)
    if not player or not tree then
        if onDone then onDone() end
        return
    end

    -- 1) Chop
    ISTimedActionQueue.add(ISChopTreeAction:new(player, tree))
    dbg("Queued chop")

    -- 2) Sweep around stump and pick up wood
    ISTimedActionQueue.add(AFInstantAction:new(player, function()
        local drops = {}
        local r = cfg and cfg.sweepRadius or 1
        forEachSquareInSweep(treeSq, r, function(sq) collectWoodWIOs(sq, drops) end)
        dbg("Found "..tostring(#drops).." wood item(s) to grab")
        for _, wio in ipairs(drops) do
            ISTimedActionQueue.add(ISGrabItemAction:new(player, wio, 5))
        end
    end))

    -- 3) Walk to stockpile and drop if set
    if stockpile then
        local pileSq = getStockpileSquare(stockpile)
        if pileSq then
            ISTimedActionQueue.add(ISWalkToAction:new(player, pileSq))
            ISTimedActionQueue.add(AFInstantAction:new(player, function()
                dropAllWood(player)
                Shared.Say(player, "Delivered to wood pile.")
            end))
        end
    end

    -- 4) Continue queue
    ISTimedActionQueue.add(AFInstantAction:new(player, function()
        if onDone then onDone() end
    end))
end

return Actions
