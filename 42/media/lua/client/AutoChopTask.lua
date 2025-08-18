
-- AutoChopTask.lua: Core logic for automated tree chopping & hauling (B42 singleplayer)

AutoChopTask = AutoChopTask or {}

-- ===== CONFIG =====
AutoChopTask.RADIUS = 12                -- tiles around center to search for trees
AutoChopTask.PICKUP_ADJ_RADIUS = 1      -- sweep 3x3 around stump to find logs
AutoChopTask.HAUL_ITEM_TYPES = { Log=true, TreeBranch=true, Twigs=true } -- which items to haul
AutoChopTask.MAX_TREES_PER_RUN = 25     -- safety cap per run to avoid 100+ action spam

-- ===== STATE =====
AutoChopTask.player = nil
AutoChopTask.centerSq = nil
AutoChopTask.trees = {}
AutoChopTask.currentTree = nil
AutoChopTask.dropSquare = nil     -- IsoGridSquare
AutoChopTask.dropContainer = nil  -- ItemContainer (crate/vehicle) if set
AutoChopTask.active = false
AutoChopTask.phase = "idle"       -- "idle" | "moveAndChop" | "haul"

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

local function findTrees(centerSq, radius)
    local list = {}
    if not centerSq then return list end
    local seen = {}
    for _, s in ipairs(squaresAround(centerSq, radius)) do
        local objs = s:getObjects()
        if objs then
            for i=0, objs:size()-1 do
                local o = objs:get(i)
                if o and (instanceof(o,"IsoTree") or o:getObjectName()=="Tree") then
                    local key = tostring(o) -- unique-ish
                    if not seen[key] then
                        list[#list+1] = o
                        seen[key] = true
                    end
                end
            end
        end
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

function AutoChopTask.start(playerObj, centerSquare)
    if AutoChopTask.active then
        say(playerObj, "Already working…")
        return
    end
    if not getAxe(playerObj) then
        say(playerObj, "Equip an axe first.")
        return
    end
    AutoChopTask.player = playerObj
    AutoChopTask.centerSq = centerSquare or playerObj:getCurrentSquare()
    AutoChopTask.trees = findTrees(AutoChopTask.centerSq, AutoChopTask.RADIUS) or {}
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
        ISTimedActionQueue.add(ISWalkToTimedAction:new(p, AutoChopTask.dropSquare))
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
    if not q:isEmpty() then return end -- busy with actions

    -- If idle between phases, advance
    if AutoChopTask.phase == "moveAndChop" then
        if AutoChopTask.currentTree == nil then
            -- get next
            local tree = table.remove(AutoChopTask.trees, 1)
            if not tree then
                say(p, "All done!")
                dbg("All trees processed.")
                AutoChopTask.active = false
                AutoChopTask.phase = "idle"
                AutoChopTask.player = nil
                return
            end
            AutoChopTask.currentTree = tree
            local tsq = tree:getSquare()
            if not tsq then
                dbg("Tree has no square; skipping")
                AutoChopTask.currentTree = nil
                return
            end
            dbg(string.format("Walking to & chopping tree @ %d,%d", tsq:getX(), tsq:getY()))
            ISTimedActionQueue.add(ISWalkToTimedAction:new(p, tsq))
            -- Chop (B42 signature is (player, tree))
            ISTimedActionQueue.add(ISChopTreeAction:new(p, tree))
            -- Next tick when queue empty, we will haul
        else
            -- Chop finished (since queue is now empty)
            local tsq = AutoChopTask.currentTree and AutoChopTask.currentTree:getSquare()
            AutoChopTask.phase = "haul"
            -- Plan hauling: pick items around stump then deliver
            local items = tsq and collectNearbyItems(tsq) or {}
            dbg("Found ".. tostring(#items) .." item(s) to haul.")
            if #items > 0 then
                queuePickupItems(p, items)
                ISTimedActionQueue.add(ISWalkToTimedAction:new(p, AutoChopTask.dropSquare))
                queueDeliver(p, items)
            end
            -- After haul queue done, we'll clear currentTree in the next phase
        end
    elseif AutoChopTask.phase == "haul" then
        -- Haul queue completed
        AutoChopTask.currentTree = nil
        AutoChopTask.phase = "moveAndChop"
    end
end
