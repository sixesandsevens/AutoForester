-- AF_Worker.lua
local AF_Worker = {}

local function _normalizeRect(r)
    if not r then return nil end
    if r.minx then return r end
    return {
        minx = r.minX or r.minx,
        miny = r.minY or r.miny,
        maxx = r.maxX or r.maxx,
        maxy = r.maxY or r.maxy,
        z = r.z or 0
    }
end

local function queueSize(p)
    if ISTimedActionQueue and ISTimedActionQueue.queue then
        return #ISTimedActionQueue.queue
    end
    return 0
end

local function enqueueChop(area, p)
    local count = 0
    if not area then return 0 end
    for x = area.minx, area.maxx do
        for y = area.miny, area.maxy do
            local sq = getCell():getGridSquare(x, y, area.z or 0)
            if sq then
                local objs = sq:getObjects()
                if objs then
                    for i=0, objs:size()-1 do
                        local obj = objs:get(i)
                        if obj and obj:getSprite() and tostring(obj:getSprite():getName()):find("tree") then
                            if ISChopTreeAction then
                                ISTimedActionQueue.add(ISChopTreeAction:new(p, obj, 30))
                                count = count + 1
                            end
                        end
                    end
                end
            end
        end
    end
    return count
end

function AF_Worker.start(p, chopArea, pileArea)
    chopArea = _normalizeRect(chopArea)
    pileArea = _normalizeRect(pileArea)
    if not (chopArea and pileArea) then
        if p and p.Say then p:Say("Designate areas first.") end
        AF_Log.err("AutoForester: missing areas; chop="..tostring(chopArea).." pile="..tostring(pileArea))
        return
    end
    local chopped = enqueueChop(chopArea, p)
    if chopped == 0 and p and p.Say then p:Say("AutoForester: no trees to chop in area.") end
    AF_Log.info("AutoForester: worker started; chopJobs="..tostring(chopped).." queue="..tostring(queueSize(p)))
end

return AF_Worker
