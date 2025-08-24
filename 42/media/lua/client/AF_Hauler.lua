-- AutoForester - Hauler: finds logs and drops them at the wood pile

AF_Hauler = AF_Hauler or {}

-- --- logging ---------------------------------------------------------------
local okLog, AF_Log = pcall(require, "AF_Logger")
if not okLog or type(AF_Log) ~= "table" then
    AF_Log = {
        info  = function(...) print("[AutoForester][I]", ...) end,
        warn  = function(...) print("[AutoForester][W]", ...) end,
        error = function(...) print("[AutoForester][E]", ...) end,
    }
end

-- --- configuration ---------------------------------------------------------
AF_Hauler.pileSq = AF_Hauler.pileSq or nil

function AF_Hauler.setWoodPileSquare(pileSq)
    if pileSq and pileSq.getX then
        AF_Hauler.pileSq = pileSq
        AF_Log.info("AutoForester: wood pile set to ("..pileSq:getX()..","..pileSq:getY()..")")
    else
        AF_Hauler.pileSq = nil
        AF_Log.warn("AutoForester: setWoodPileSquare called with invalid sq; cleared.")
    end
end

-- Scan the sweep rectangle for the next Base.Log world object
function AF_Hauler.findNextLog(st)
    if not st or not st.rect then return nil, nil end
    local cell = getCell()
    for y = st.rect.miny, st.rect.maxy do
        for x = st.rect.minx, st.rect.maxx do
            local sq = cell:getGridSquare(x, y, st.rect.z or 0)
            if sq then
                local wobs = sq:getWorldObjects()
                local n = (wobs and wobs:size()) or 0
                for i = 0, n - 1 do
                    local w = wobs:get(i)
                    if w and instanceof(w, "IsoWorldInventoryObject") then
                        local it = w:getItem()
                        if it and it.getFullType and it:getFullType() == "Base.Log" then
                            return sq, w
                        end
                    end
                end
            end
        end
    end
    return nil, nil
end

-- Walk to the pile and drop up to `limit` logs from inventory
function AF_Hauler.dropBatchToPile(playerObj, limit)
    if not AF_Hauler.pileSq or not playerObj then return 0 end

    local inv = playerObj:getInventory()
    if not inv then return 0 end

    local items = inv:getItems()
    if not items then return 0 end

    local toDrop, cap = {}, math.min(limit or 200, items:size())
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if it and it.getFullType and it:getFullType() == "Base.Log" then
            toDrop[#toDrop + 1] = it
            if #toDrop >= cap then break end
        end
    end
    if #toDrop == 0 then return 0 end

    -- Walk to the pile square, then drop each at feet (which is the pile)
    ISTimedActionQueue.add(ISWalkToTimedAction:new(playerObj, AF_Hauler.pileSq))
    for _, it in ipairs(toDrop) do
        ISTimedActionQueue.add(ISDropItemAction:new(playerObj, it, 0))
    end

    AF_Log.info("AutoForester: queued " .. tostring(#toDrop) .. " drop(s) to pile.")
    return #toDrop
end

return AF_Hauler
