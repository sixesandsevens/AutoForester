-- AutoForester_Core.lua
require "AutoForester_Debug"

AFCore = AFCore or {}

-- Canonical: resolve a *player object* and its index from any input.
function AF_getPlayer(maybePi)
    local idx
    if type(maybePi) == "number" then
        idx = maybePi
    elseif type(maybePi) == "table" and maybePi.getPlayerNum then
        idx = maybePi:getPlayerNum()
    else
        idx = 0
    end
    local p = getSpecificPlayer(idx)
    if p and p:isAlive() then return p, idx end
    AFLOG("getPlayer", "failed, idx=", tostring(idx))
    return nil, idx
end

-- Robust square from worldobjects or mouse position (floored).
function AF_getContextSquare(worldobjects)
    if worldobjects then
        for i=1,#worldobjects do
            local o = worldobjects[i]
            if o and o.getSquare then
                local sq = o:getSquare()
                if sq then return sq end
            end
        end
    end
    local p = getSpecificPlayer(0)
    local z = (p and p:getZ()) or 0
    local mx, my = getMouseXScaled(), getMouseYScaled()
    local wx = ISCoordConversion.ToWorldX(mx, my, 0)
    local wy = ISCoordConversion.ToWorldY(mx, my, 0)
    local sq = getCell():getGridSquare(math.floor(wx), math.floor(wy), z)
    return sq
end

-- Stockpile marker (just store the square).
AFCore.pileSq = AFCore.pileSq or nil
function AFCore.setStockpile(sq)
    if not sq then AFLOG("pile", "no square") return end
    AFCore.pileSq = sq
    sq:setHighlighted(true); sq:setHighlightColor(0.9,0.8,0.2)
    AFLOG("pile", "set at ", sq:getX(), sq:getY(), sq:getZ())
end
function AFCore.clearStockpile()
    if AFCore.pileSq then AFCore.pileSq:setHighlighted(false) end
    AFCore.pileSq = nil
end

-- Rect utils
local function _norm(a,b)  -- returns x1,y1,x2,y2 (inclusive)
    local x1 = math.min(a[1], b[1]); local y1 = math.min(a[2], b[2])
    local x2 = math.max(a[1], b[1]); local y2 = math.max(a[2], b[2])
    return x1, y1, x2, y2
end

-- Build a list of IsoTree objects inside a rect {x1,y1,x2,y2,z}
function AFCore.findTreesInRect(rect)
    local res = {}
    if not rect then return res end
    local z = rect[5] or 0
    local x1,y1,x2,y2 = _norm({rect[1],rect[2]}, {rect[3],rect[4]})
    local cell = getCell()
    for x=x1,x2 do
        for y=y1,y2 do
            local sq = cell:getGridSquare(x,y,z)
            if sq then
                local objs = sq:getObjects()
                for i = 0, objs:size()-1 do
                    local o = objs:get(i)
                    if instanceof(o, "IsoTree") then
                        table.insert(res, {sq=sq, obj=o})
                    end
                end
            end
        end
    end
    AFLOG("trees", "found ", tostring(#res), " in rect")
    return res
end

-- Minimal job pipeline: chop → drop (immediate) → (later) gather/haul
AFCore.chopRect   = AFCore.chopRect   or nil
AFCore.gatherRect = AFCore.gatherRect or nil

function AFCore.startAreaJob(pi)
    local p = AF_getPlayer(pi)
    if not p then return end
    if not AFCore.chopRect then AFSAY(p,"Set chop area first.") return end
    if not AFCore.pileSq then  AFSAY(p,"Set wood pile first.") return end

    local list = AFCore.findTreesInRect(AFCore.chopRect)
    if #list == 0 then AFSAY(p,"No trees in chop area.") return end

    -- Queue: walk to each tree & swing. (Vanilla B42 uses TimedActions for swings;
    -- keep your existing ISWalkToTimedAction + chop action wiring here.)
    for i=1,#list do
        local sq  = list[i].sq
        ISTimedActionQueue.add(ISWalkToTimedAction:new(p, sq))
        -- Replace with your existing tree-chop TA, e.g. AF_ChopTreeAction or vanilla:
        ISTimedActionQueue.add(ISChopTreeAction:new(p, list[i].obj, 100))
    end

    -- Immediate-log-drop behavior (prevents overweight lock):
    ISTimedActionQueue.add(ISInventoryDropEverythingAction:new(p, "Base.Log"))  -- or your custom “drop logs on ground” loop

    AFSAY(p, "Queued "..tostring(#list).." tree(s).")
end
