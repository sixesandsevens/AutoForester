
-- media/lua/client/AF_Worker.lua
-- Orchestrates: chop trees, sweep clutter, haul logs, for all squares in rect.
local AFCore = require "AF_Core"
local AF_Log = require "AF_Logger"
local AF_Sweeper = require "AF_Sweeper"
local AF_Hauler = require "AF_Hauler"

AF_Worker = {}

local function hasAxe(p)
    local inv = p:getInventory()
    return (inv:containsTypeRecurse("Base.Axe") or inv:containsTypeRecurse("Base.WoodAxe") or inv:containsTypeRecurse("Base.HandAxe") or inv:containsTypeRecurse("Base.AxeStone"))
end

local function chopTreeIfPresent(p, sq)
    local objs = sq:getObjects()
    local chopped = false
    for i=0, objs:size()-1 do
        local o = objs:get(i)
        if o and instanceof(o, "IsoTree") then
            ISTimedActionQueue.add(ISWalkToTimedAction:new(p, sq))
            if ISWorldObjectContextMenu and ISWorldObjectContextMenu.onChopTree then
                ISWorldObjectContextMenu.onChopTree(nil, p, o) -- usually enqueues the chop action(s)
            elseif ISChopTreeAction and ISChopTreeAction.new then
                -- Fallback to timed action if available
                ISTimedActionQueue.add(ISChopTreeAction:new(p, o, 150))
            else
                AF_Log.warn("No chop action available; skipping a tree.")
            end
            chopped = true
        end
    end
    return chopped
end

local function sweepAndHaul(p, sq)
    AF_Sweeper.enqueueSweep(sq, p)
    AF_Hauler.enqueueHaulSquare(p, sq)
end

function AF_Worker.start(p, rect, z)
    p = p or getSpecificPlayer(0) or getPlayer()
    if not p then AF_Log.err("No player to run AutoForester"); return end
    rect = AFCore.normalizeRect(rect)
    if not rect then AF_Log.err("Bad rect"); return end
    z = z or p:getZ() or 0

    AF_Log.info(string.format("Starting AutoForester on (%d,%d)-(%d,%d) z=%d", rect[1],rect[2],rect[3],rect[4], z))

    if not hasAxe(p) then
        AF_Log.warn("No axe detected in inventory; tree chopping may fail.")
    end

    local cell = getCell()
    for x=rect[1],rect[3] do
        for y=rect[2],rect[4] do
            local sq = cell:getGridSquare(x,y,z)
            if sq then
                chopTreeIfPresent(p, sq)
                sweepAndHaul(p, sq)
            end
        end
    end

    AF_Log.info("AutoForester actions enqueued. Monitor the timed action queue to track progress.")
end

return AF_Worker
