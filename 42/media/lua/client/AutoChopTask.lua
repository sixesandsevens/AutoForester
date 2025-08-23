-- AutoChopTask.lua
AutoChopTask = AutoChopTask or {}

AutoChopTask._chopRect = nil
AutoChopTask._gatherRect = nil

function AutoChopTask.setChopRect(rect, area)   AutoChopTask._chopRect = AFCore.normalizeRect(rect) end
function AutoChopTask.setGatherRect(rect, area) AutoChopTask._gatherRect = AFCore.normalizeRect(rect) end

function AutoChopTask.startAreaJob(p)
    if not AutoChopTask._chopRect then if p then p:Say("Set chop area first.") end return end
    local trees = AFCore.treesInRect(AutoChopTask._chopRect)
    if p then p:Say(string.format("Found %d trees in chop area.", #trees)) end
    -- Hook into your timed actions here later.
end