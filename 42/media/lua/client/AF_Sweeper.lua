
-- media/lua/client/AF_Sweeper.lua
-- Remove grass/bush using existing context actions when possible.
local AF_Log = require "AF_Logger"

AF_Sweeper = {}

local function squareHasClutter(sq)
    -- Heuristic: any 'isoObject' with sprite name containing 'grass' or 'bush'
    local objs = sq:getObjects()
    for i=0, objs:size()-1 do
        local o = objs:get(i)
        if o and o:getSprite() then
            local name = tostring(o:getSprite():getName() or "")
            if string.find(name, "grass") or string.find(name, "bush") then
                return true, o
            end
        end
    end
    return false, nil
end

function AF_Sweeper.enqueueSweep(sq, player)
    local has, obj = squareHasClutter(sq)
    if not has then return false end
    -- try to use Remove Bush if available; otherwise use ISShovelGround to clear
    local p = player or getSpecificPlayer(0) or getPlayer()
    if not p then return false end

    -- Walk to square
    ISTimedActionQueue.add(ISWalkToTimedAction:new(p, sq))

    -- Prefer vanilla remove-bush code if present
    if ISWorldObjectContextMenu and ISWorldObjectContextMenu.onRemoveBush then
        ISTimedActionQueue.add(ISWorldObjectContextMenu.onRemoveBush(nil, p, obj)) -- may enqueue actions inside
        return true
    end

    -- Fallback: shovel ground
    if ISShovelGround and ISShovelGround.new then
        ISTimedActionQueue.add(ISShovelGround:new(p, sq, 100))
        return true
    end

    AF_Log.warn("No sweep action available; skipping.")
    return false
end

return AF_Sweeper
