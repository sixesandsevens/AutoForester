local Shared = require("AutoForester_Shared")
local Actions = require("AutoForester_Actions")

local AFCore = {}
AFCore.data = ModData.getOrCreate("AutoForester")
AFCore.data.stockpile = AFCore.data.stockpile or nil
AFCore.cfg = {}
for k,v in pairs(Shared.DefaultCfg) do AFCore.cfg[k] = v end

local function dbg(msg) print("[AutoForester] "..tostring(msg)) end

function AFCore.hasStockpile()
    return AFCore.data.stockpile ~= nil
end

function AFCore.setStockpile(square)
    AFCore.data.stockpile = { x = square:getX(), y = square:getY(), z = square:getZ() }
    dbg("Stockpile set at "..square:getX()..","..square:getY()..","..square:getZ())
    Shared.Say(getSpecificPlayer(0), "Wood pile set.")
end

function AFCore.clearStockpile()
    AFCore.data.stockpile = nil
    dbg("Stockpile cleared.")
    Shared.Say(getSpecificPlayer(0), "Wood pile cleared.")
end

local function getSquaresAround(originSq, radius)
    local cell = getCell()
    local z = originSq:getZ()
    local list = {}
    for dx=-radius, radius do
        for dy=-radius, radius do
            local sq = cell:getGridSquare(originSq:getX()+dx, originSq:getY()+dy, z)
            if sq then table.insert(list, sq) end
        end
    end
    return list
end

local function isTreeObject(obj) return instanceof(obj, "IsoTree") end

local function findTreesAround(originSq, radius)
    local trees = {}
    for _,sq in ipairs(getSquaresAround(originSq, radius)) do
        local objs = sq:getObjects()
        for i=0, objs:size()-1 do
            local o = objs:get(i)
            if isTreeObject(o) then table.insert(trees, { tree=o, square=sq }) end
        end
    end
    return trees
end

local function playerIsTooTired(player)
    if not Shared.DefaultCfg.stopWhenExerted then return false end
    return player:isExertion()
end

local function axeTooLow(player)
    local hand = player:getPrimaryHandItem()
    if not hand then return false end
    if not hand:isA("HandWeapon") then return false end
    if not hand:getCategories():contains("Axe") then return false end
    local cond = hand:getCondition() / math.max(1, hand:getConditionMax())
    return cond < AFCore.cfg.minAxeCondition
end

function AFCore.startJob(player)
    if not player then return end
    local originSq = player:getSquare()
    if not originSq then return end

    if playerIsTooTired(player) then Shared.Say(player, "Too exhausted.") return end
    if axeTooLow(player) then Shared.Say(player, "Axe too damaged.") return end

    local trees = findTreesAround(originSq, AFCore.cfg.radius)
    dbg("Found "..#trees.." trees")
    if #trees == 0 then Shared.Say(player, "No trees nearby.") return end

    for _,t in ipairs(trees) do
        Actions.enqueueChopLootDeliver(player, t.tree, t.square, AFCore.data.stockpile)
    end
    Shared.Say(player, "Queued "..#trees.." trees.")
end

return AFCore
