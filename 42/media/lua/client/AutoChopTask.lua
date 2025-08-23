
require "AutoForester_Core"

AutoChopTask = AutoChopTask or {}
AutoChopTask.state = AutoChopTask.state or {}
AutoChopTask.state.chopRect = nil
AutoChopTask.state.gatherRect = nil

local function say(p, msg) if p then p:Say(tostring(msg)) end end

function AutoChopTask.setChopRect(rect, area) AutoChopTask.state.chopRect = rect end
function AutoChopTask.setGatherRect(rect, area) AutoChopTask.state.gatherRect = rect end

local function gatherRectOrChop()
    return AutoChopTask.state.gatherRect or AutoChopTask.state.chopRect
end

local function queueSweepAndHaul(p)
    local gres = gatherRectOrChop()
    local logs = AFCore.logsInRect(gres)
    if #logs == 0 then return 0 end
    local moved = 0
    for _,wio in ipairs(logs) do
        local sq = wio:getSquare()
        ISTimedActionQueue.add(ISWalkToAction:new(p, sq))
        ISTimedActionQueue.add(ISPickupWorldItemAction:new(p, wio, 30))
        ISTimedActionQueue.add(ISWalkToAction:new(p, AFCore.pileSq))
        -- try to find the picked Log in inventory and drop it to the pile sq
        local inv = p:getInventory()
        local item = inv:FindAndReturn("Base.Log")
        if item then
            ISTimedActionQueue.add(ISDropWorldItemAction:new(p, item, AFCore.pileSq:getX(), AFCore.pileSq:getY(), AFCore.pileSq:getZ()))
            moved = moved + 1
        end
    end
    return moved
end

function AutoChopTask.startAreaJob(p)
    p = p or getSpecificPlayer(0)
    if not p or p:isDead() then return end
    local rect = AutoChopTask.state.chopRect
    if not rect then say(p, "Set chop area first."); return end
    if not AFCore.pileSq then say(p, "Set a wood pile first."); return end

    local trees = AFCore.treesInRect(rect)
    local n = AFCore.queueChops(p, trees)
    say(p, string.format("Queued %d chops.", n))

    -- After chop queue, enqueue sweep & haul for the gather/chop rect
    local moved = queueSweepAndHaul(p)
    if moved > 0 then
        say(p, string.format("Queued sweep/haul for %d logs.", moved))
    else
        say(p, "No logs to haul (yet).")
    end
end
