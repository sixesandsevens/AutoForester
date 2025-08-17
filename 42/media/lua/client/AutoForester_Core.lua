local Shared = require("AutoForester_Shared")
local Actions = require("AutoForester_Actions")

local AFCore = {}

AFCore.data = ModData.getOrCreate("AutoForester")
AFCore.data.stockpile = AFCore.data.stockpile or nil

-- runtime cfg
AFCore.cfg = {}
for k,v in pairs(Shared.DefaultCfg) do AFCore.cfg[k] = v end

-- simple sequential queue (one tree at a time)
AFCore._queue = nil
AFCore._index = 0
AFCore._busy = false
AFCore._lastPulse = 0

local function dbg(msg) print("[AutoForester] "..tostring(msg)) end

function AFCore.hasStockpile()
    return AFCore.data.stockpile ~= nil
end

function AFCore.setStockpile(square)
    AFCore.data.stockpile = { x=square:getX(), y=square:getY(), z=square:getZ() }
    dbg(string.format("Stockpile set at %d,%d,%d", square:getX(), square:getY(), square:getZ()))
    Shared.Say(getSpecificPlayer(0), "Wood pile set.")
end

function AFCore.clearStockpile()
    AFCore.data.stockpile = nil
    dbg("Stockpile cleared.")
    Shared.Say(getSpecificPlayer(0), "Wood pile cleared.")
end

local function getSquaresAround(originSq, radius)
    local cell = getCell()
    local z = originSq:getZ()
    local list = {}
    for dx=-radius, radius do
        for dy=-radius, radius do
            local sq = cell:getGridSquare(originSq:getX()+dx, originSq:getY()+dy, z)
            if sq then table.insert(list, sq) end
        end
    end
    return list
end

local function isTreeObject(obj) return instanceof(obj, "IsoTree") end

local function findTreesAround(originSq, radius)
    local trees = {}
    for _,sq in ipairs(getSquaresAround(originSq, radius)) do
        local objs = sq:getObjects()
        for i=0, objs:size()-1 do
            local o = objs:get(i)
            if isTreeObject(o) then table.insert(trees, { tree=o, square=sq }) end
        end
    end
    return trees
end

local function playerIsTooTired(player)
    if not Shared.DefaultCfg.stopWhenExerted then return false end
    return player:isExertion()
end

local function axeTooLow(player)
    local hand = player:getPrimaryHandItem()
    if not hand then return false end
    if not hand:isA("HandWeapon") then return false end
    if not hand:getCategories():contains("Axe") then return false end
    local cond = hand:getCondition() / math.max(1, hand:getConditionMax())
    return cond < AFCore.cfg.minAxeCondition
end

local function guardsFail(player)
    if playerIsTooTired(player) then
        Shared.Say(player, "Too exhausted—pausing.")
        return true
    end
    if axeTooLow(player) then
        Shared.Say(player, "Axe too damaged—pausing.")
        return true
    end
    if Shared.IsOverEncumbered(player) then
        Shared.Say(player, "Over-encumbered—pausing.")
        return true
    end
    return false
end

local function processNext(player)
    AFCore._lastPulse = getTimestampMs and getTimestampMs() or (AFCore._lastPulse + 1)
    if not AFCore._queue or AFCore._index > #AFCore._queue then
        AFCore._busy = false
        Shared.Say(player, "AutoForester job complete.")
        return
    end
    if guardsFail(player) then
        AFCore._busy = false
        return
    end
    local entry = AFCore._queue[AFCore._index]
    AFCore._index = AFCore._index + 1
    Actions.enqueueChopLootDeliver(player, entry.tree, entry.square, AFCore.data.stockpile, AFCore.cfg,
        function() processNext(player) end)
end

function AFCore.startJob(player)
    if not player then return end
    if AFCore._busy then
        Shared.Say(player, "Already working—please wait.")
        return
    end
    local originSq = player:getSquare()
    if not originSq then return end

    local trees = findTreesAround(originSq, AFCore.cfg.radius)
    if #trees == 0 then
        Shared.Say(player, "No trees nearby.")
        return
    end

    AFCore._queue = trees
    AFCore._index = 1
    AFCore._busy = true
    Shared.Say(player, "Queued "..tostring(#trees).." tree(s).")
    processNext(player)
end

-- Watchdog: if we're "busy" but the player's timed action queue is empty for too long, kick the next task.
local function watchdog()
    if not AFCore._busy then return end
    local p = getSpecificPlayer(0)
    if not p then return end
    local q = ISTimedActionQueue.getTimedActionQueue(p)
    local hasActions = q and q.queue and q.queue:size() > 0
    local now = getTimestampMs and getTimestampMs() or 0
    if not hasActions and now and AFCore._lastPulse and (now - AFCore._lastPulse) > 4000 then
        print("[AutoForester] Watchdog pulse: queue empty but busy=true; advancing…")
        processNext(p)
    end
end
Events.EveryOneSecond.Add(watchdog)

return AFCore
