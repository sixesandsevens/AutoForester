
-- AutoChopTask.lua: Core logic for automated tree chopping & hauling (B42 singleplayer)

AutoChopTask = AutoChopTask or {}

-- ===== CONFIG =====
AutoChopTask.RADIUS = 12                -- tiles around center to search for trees
AutoChopTask.PICKUP_ADJ_RADIUS = 1      -- sweep 3x3 around stump to find logs
AutoChopTask.HAUL_ITEM_TYPES = { Log=true, TreeBranch=true, Twigs=true } -- which items to haul
AutoChopTask.MAX_TREES_PER_RUN = 25     -- safety cap per run to avoid 100+ action spam
AutoChopTask.chopRect = nil   -- {x1,y1,x2,y2,z}
AutoChopTask.gatherRect = nil -- optional {x1,y1,x2,y2,z}
AutoChopTask.WEIGHT_FULL_FRACTION = 0.9  -- deliver when >= 90% capacity

-- ===== STATE =====
AutoChopTask.player = nil
AutoChopTask.centerSq = nil
AutoChopTask.trees = {}
AutoChopTask.currentTree = nil
AutoChopTask.dropSquare = nil     -- IsoGridSquare
AutoChopTask.dropContainer = nil  -- ItemContainer (crate/vehicle) if set
AutoChopTask.active = false
AutoChopTask.phase = "idle"       -- "idle" | "moveAndChop" | "haul"
AutoChopTask.idleTicks = 0       -- counts empty-queue ticks while active
AutoChopTask.IDLE_TICK_LIMIT = 120  -- ~2 seconds at 60 FPS; adjust if needed

local function dbg(msg)
    print("[AutoForester] " .. tostring(msg))
end

local function say(p, txt)
    if p and p.Say then p:Say(txt) end
end

local function getAxe(player)
    if not player then return nil end
    local hand = player:getPrimaryHandItem()
    if not hand then return nil end
    -- Prefer category check, fallback to name contains "axe"
    local cats = hand.getCategories and hand:getCategories() or nil
    if cats and cats:contains("Axe") then return hand end
    local dn = string.lower(hand:getDisplayName() or "")
    if dn:find("axe") then return hand end
    return nil
end

local function squaresAround(sq, r)
    local out, cell, z = {}, getCell(), sq:getZ()
    for dx=-r,r do for dy=-r,r do
        local s = cell:getGridSquare(sq:getX()+dx, sq:getY()+dy, z)
        if s then out[#out+1] = s end
    end end
    return out
end

local function makeRect(a, b)
    if not a or not b then return nil end
    local z = a:getZ()
    return { math.min(a:getX(), b:getX()), math.min(a:getY(), b:getY()),
             math.max(a:getX(), b:getX()), math.max(a:getY(), b:getY()), z }
end

function AutoChopTask.setChopRect(corner1, corner2)
    AutoChopTask.chopRect = makeRect(corner1, corner2)
    print("[AutoForester] Chop area set:", AutoChopTask.chopRect and table.concat(AutoChopTask.chopRect, ",") or "nil")
end

function AutoChopTask.setGatherRect(corner1, corner2)
    AutoChopTask.gatherRect = makeRect(corner1, corner2)
    print("[AutoForester] Gather area set:", AutoChopTask.gatherRect and table.concat(AutoChopTask.gatherRect, ",") or "nil")
end

local function squaresInRect(rect)
    local list = {}
    if not rect then return list end
    local x1,y1,x2,y2,z = table.unpack(rect)
    local cell = getCell()
    for x=x1,x2 do
        for y=y1,y2 do
            local s = cell:getGridSquare(x,y,z)
            if s then list[#list+1] = s end
        end
    end
    return list
end

local function findTreesFromAreas(centerSq, radius)
    local list, seen = {}, {}
    local function pushTreesOnSquare(sq)
        local objs = sq and sq:getObjects()
        if not objs then return end
        for i=0, objs:size()-1 do
            local o = objs:get(i)
            if o and (instanceof(o,"IsoTree") or o:getObjectName()=="Tree") then
                local key = tostring(o)
                if not seen[key] then list[#list+1]=o; seen[key]=true end
            end
        end
    end

    if AutoChopTask.chopRect then
        for _, s in ipairs(squaresInRect(AutoChopTask.chopRect)) do pushTreesOnSquare(s) end
    else
        for _, s in ipairs(squaresAround(centerSq, radius)) do pushTreesOnSquare(s) end
    end
    return list
end

-- Timed Actions (hard require to ensure symbols exist at parse time)
require "TimedActions/ISWalkToTimedAction"
require "TimedActions/ISChopTreeAction"
require "TimedActions/ISGrabItemAction"
require "TimedActions/ISInventoryTransferAction"

-- ===== Public API =====

function AutoChopTask.setDropAt(square, containerOrNil)
    AutoChopTask.dropSquare = square
    AutoChopTask.dropContainer = containerOrNil or nil
    if containerOrNil then
        dbg(string.format("Drop-off set to CONTAINER @ %d,%d", square:getX(), square:getY()))
    else
        dbg(string.format("Drop-off set to GROUND @ %d,%d", square:getX(), square:getY()))
    end
end

function AutoChopTask.cancel(reason)
    print("[AutoForester] Job canceled: " .. tostring(reason or ""))
    AutoChopTask.active = false
    AutoChopTask.phase = "idle"
    AutoChopTask.player = nil
    AutoChopTask.currentTree = nil
    AutoChopTask.trees = {}
    AutoChopTask.idleTicks = 0
end

function AutoChopTask.start(playerObj, centerSquare)
    if AutoChopTask.active then
        local q = ISTimedActionQueue.getTimedActionQueue(playerObj)
        if q and not q:isEmpty() then
            playerObj:Say("Already chopping…")
            return
        else
            AutoChopTask.cancel("stale-active before start")
        end
    end
    if not getAxe(playerObj) then
        say(playerObj, "Equip an axe first.")
        return
    end
    AutoChopTask.player = playerObj
    AutoChopTask.centerSq = centerSquare or playerObj:getCurrentSquare()
    AutoChopTask.trees = findTreesFromAreas(AutoChopTask.centerSq, AutoChopTask.RADIUS) or {}
    -- cap list
    if #AutoChopTask.trees > AutoChopTask.MAX_TREES_PER_RUN then
        local t = {}
        for i=1,AutoChopTask.MAX_TREES_PER_RUN do t[i] = AutoChopTask.trees[i] end
        AutoChopTask.trees = t
    end
    if #AutoChopTask.trees == 0 then
        say(playerObj, "No trees found here.")
        return
    end
    if not AutoChopTask.dropSquare then
        AutoChopTask.dropSquare = playerObj:getCurrentSquare()
        AutoChopTask.dropContainer = nil
        dbg("No drop-off set; using player's square")
    end
    AutoChopTask.active = true
    AutoChopTask.phase = "moveAndChop"
    AutoChopTask.currentTree = nil
    AutoChopTask.idleTicks = 0
    say(playerObj, string.format("Queued %d tree(s).", #AutoChopTask.trees))
    dbg(string.format("Queued %d tree(s) around %d,%d", #AutoChopTask.trees, AutoChopTask.centerSq:getX(), AutoChopTask.centerSq:getY()))
end

-- ===== Hauling helpers =====

local function collectNearbyItems(sq)
    local items = {}
    -- include 3x3 sweep
    for _, s in ipairs(squaresAround(sq, AutoChopTask.PICKUP_ADJ_RADIUS)) do
        local wios = s:getWorldObjects()
        if wios then
            for i=0, wios:size()-1 do
                local wio = wios:get(i)
                local it = wio and wio:getItem()
                if it and AutoChopTask.HAUL_ITEM_TYPES[it:getType()] then
                    items[#items+1] = it
                end
            end
        end
    end
    return items
end

local function collectHaulablesFromRect(rect)
    local items = {}
    for _, s in ipairs(squaresInRect(rect)) do
        local wios = s:getWorldObjects()
        if wios then
            for i=0, wios:size()-1 do
                local it = wios:get(i):getItem()
                if it and AutoChopTask.HAUL_ITEM_TYPES[it:getType()] then
                    items[#items+1] = it
                end
            end
        end
    end
    return items
end

local function queuePickupItems(p, itemList)
    for _, it in ipairs(itemList) do
        ISTimedActionQueue.add(ISGrabItemAction:new(p, it, 0))
    end
end

local function queueDeliver(p, items)
    if AutoChopTask.dropContainer then
        -- transfer into container
        for _, it in ipairs(items) do
            ISTimedActionQueue.add(ISInventoryTransferAction:new(p, it, p:getInventory(), AutoChopTask.dropContainer))
        end
    else
        -- drop to ground square (instant)
        ISTimedActionQueue.add(ISWalkToTimedAction:new(p,
            AutoChopTask.dropSquare:getX(),
            AutoChopTask.dropSquare:getY(),
            AutoChopTask.dropSquare:getZ()))
        for _, it in ipairs(items) do
            -- remove then add to ground
            p:getInventory():Remove(it)
            AutoChopTask.dropSquare:AddWorldInventoryItem(it, 0, 0, 0)
        end
    end
end

-- ===== Tick-driven state machine =====
function AutoChopTask.update()
    if not AutoChopTask.active or not AutoChopTask.player then return end
    local p = AutoChopTask.player
    local q = ISTimedActionQueue.getTimedActionQueue(p)
    if not q:isEmpty() then
        AutoChopTask.idleTicks = 0
        return
    end

    AutoChopTask.idleTicks = AutoChopTask.idleTicks + 1
    if AutoChopTask.idleTicks > AutoChopTask.IDLE_TICK_LIMIT then
        p:Say("AutoForester timed out; resetting.")
        AutoChopTask.cancel("idle watchdog")
        return
    end

    if AutoChopTask.phase == "moveAndChop" then
        if AutoChopTask.currentTree == nil then
            local tree = table.remove(AutoChopTask.trees, 1)
            if not tree then
                say(p, "All done!")
                dbg("All trees processed.")
                AutoChopTask.active = false
                AutoChopTask.phase = "idle"
                AutoChopTask.player = nil
                AutoChopTask.idleTicks = 0
                return
            end
            AutoChopTask.currentTree = tree
            local tsq = tree:getSquare()
            if not tsq then
                dbg("Tree has no square; skipping")
                AutoChopTask.currentTree = nil
                AutoChopTask.idleTicks = 0
                return
            end
            dbg(string.format("Walking to & chopping tree @ %d,%d", tsq:getX(), tsq:getY()))
            ISTimedActionQueue.add(ISWalkToTimedAction:new(p,
                tsq:getX(), tsq:getY(), tsq:getZ()))
            ISTimedActionQueue.add(ISChopTreeAction:new(p, tree))
            AutoChopTask.idleTicks = 0
        else
            local tsq = AutoChopTask.currentTree and AutoChopTask.currentTree:getSquare()
            AutoChopTask.phase = "haul"
            local items
            if AutoChopTask.gatherRect then
                items = collectHaulablesFromRect(AutoChopTask.gatherRect)
            else
                items = tsq and collectNearbyItems(tsq) or {}
            end
            dbg("Found ".. tostring(#items) .." item(s) to haul.")
            if #items > 0 then
                queuePickupItems(p, items)
                local inv = p:getInventory()
                local cur = inv:getCapacityWeight()
                local max = inv:getMaxWeight()
                local heavy = (cur >= max * AutoChopTask.WEIGHT_FULL_FRACTION)
                if heavy then
                    ISTimedActionQueue.add(ISWalkToTimedAction:new(p,
                        AutoChopTask.dropSquare:getX(),
                        AutoChopTask.dropSquare:getY(),
                        AutoChopTask.dropSquare:getZ()))
                    queueDeliver(p, items)
                else
                    ISTimedActionQueue.add(ISWalkToTimedAction:new(p,
                        AutoChopTask.dropSquare:getX(),
                        AutoChopTask.dropSquare:getY(),
                        AutoChopTask.dropSquare:getZ()))
                    queueDeliver(p, items)
                end
            else
                AutoChopTask.currentTree = nil
                AutoChopTask.phase = "moveAndChop"
            end
            AutoChopTask.idleTicks = 0
        end
    elseif AutoChopTask.phase == "haul" then
        AutoChopTask.currentTree = nil
        AutoChopTask.phase = "moveAndChop"
        AutoChopTask.idleTicks = 0
    end
end
