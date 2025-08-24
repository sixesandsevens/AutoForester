local okLog, AF_Log = pcall(require, "AF_Logger")
if not okLog or type(AF_Log) ~= "table" then
    AF_Log = { info=function(...) print("[AutoForester][I]", ...) end,
               warn=function(...) print("[AutoForester][W]", ...) end,
               error=function(...) print("[AutoForester][E]", ...) end }
end

AF_Sweeper = {}

local function squareHasCuttableObject(sq)
    local objs = sq:getObjects()
    for i = 0, objs:size() - 1 do
        local o = objs:get(i)
        if o and o:getSprite() then
            local props = o:getSprite():getProperties()
            if props and (props:Is(IsoFlagType.canBeRemoved) or props:Is(IsoFlagType.canBeCut)) then
                return true
            end
        end
    end
    return false
end

function AF_Sweeper.trySweep(p, sq)
    if not squareHasCuttableObject(sq) then return false end

    if ISWorldObjectContextMenu.doRemovePlant then
        ISWorldObjectContextMenu.doRemovePlant(p, sq, false)
        return true
    end

    if ISShovelGround and ISShovelGround.new then
        ISTimedActionQueue.add(ISShovelGround:new(p, sq, 100))
        return true
    end

    AF_Log.warn("No sweep action available on this tile.")
    return false
end

return AF_Sweeper
