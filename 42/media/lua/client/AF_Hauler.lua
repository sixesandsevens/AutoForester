-- AF_Hauler.lua – pick up Base.Log in an area and drop at the wood pile
local AF_Log = require "AF_Logger"

AF_Hauler = {}
local PILE_SQ = nil

function AF_Hauler.setWoodPileSquare(sq) PILE_SQ = sq end

local function walkAdj(p, sq)
    return luautils.walkAdj(p, sq, true)
end

local function pickupLogsFromSquare(p, sq)
    local wobs = sq:getWorldObjects()
    if not wobs or wobs:size() == 0 then return 0 end

    local took = 0
    for i = 0, wobs:size() - 1 do
        local o = wobs:get(i)
        if instanceof(o, "IsoWorldInventoryObject") then
            local item = o:getItem()
            if item and item:getFullType() == "Base.Log" then
                local time = ISWorldObjectContextMenu.grabItemTime(p, o)
                if walkAdj(p, sq) then
                    ISTimedActionQueue.add(ISGrabItemAction:new(p, o, time))
                    took = took + 1
                end
            end
        end
    end
    return took
end

local function dropLogsAtPile(p)
    if not PILE_SQ then return false end

    local inv = p:getInventory()
    local logs = inv:getItemsFromFullType("Base.Log")
    if not logs or logs:size() == 0 then return false end

    if walkAdj(p, PILE_SQ) then
        for i = 0, logs:size() - 1 do
            local log = logs:get(i)
            local dx, dy, dz = ISTransferAction.GetDropItemOffset(p, PILE_SQ, log)
            local worldItem   = p:getCurrentSquare():AddWorldInventoryItem(log, dx, dy, dz)
            worldItem:getWorldItem():transmitCompleteItemToClients()
            inv:Remove(log)
        end
        ISInventoryPage.renderDirty = true
        return true
    end

    return false
end

-- Public: queue pickup (if any) on this square, then a drop at pile
function AF_Hauler.enqueueHaulSquare(p, sq)
    local took = pickupLogsFromSquare(p, sq)
    if took > 0 then dropLogsAtPile(p) end
    return took > 0
end

return AF_Hauler
