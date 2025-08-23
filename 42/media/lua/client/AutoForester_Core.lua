
AFCore = AFCore or {}

local function say(p, msg) if p then p:Say(tostring(msg)) end end

function AFCore.squareHasTree(sq)
    if not sq then return false end
    local objs = sq:getObjects()
    for i=0,objs:size()-1 do
        local o = objs:get(i)
        if instanceof(o, "IsoTree") then return true end
    end
    return false
end

function AFCore.getTreeFromSquare(sq)
    if not sq then return nil end
    local objs = sq:getObjects()
    for i=0,objs:size()-1 do
        local o = objs:get(i)
        if instanceof(o, "IsoTree") then return o end
    end
    return nil
end

function AFCore.treesInRect(rect)
    if not rect then return {} end
    local x1,y1,x2,y2,z = rect[1],rect[2],rect[3],rect[4],rect[5] or 0
    local out = {}
    local cell = getCell(); if not cell then return out end
    for y=y1,y2 do
        for x=x1,x2 do
            local sq = cell:getGridSquare(x,y,z)
            if AFCore.squareHasTree(sq) then table.insert(out, sq) end
        end
    end
    return out
end

-- Find world-inventory logs on the ground in rect
function AFCore.logsInRect(rect)
    local res = {}
    if not rect then return res end
    local x1,y1,x2,y2,z = rect[1],rect[2],rect[3],rect[4],rect[5] or 0
    local cell = getCell(); if not cell then return res end
    for y=y1,y2 do
        for x=x1,x2 do
            local sq = cell:getGridSquare(x,y,z)
            if sq then
                local w = sq:getWorldObjects()
                for i=0,w:size()-1 do
                    local o = w:get(i)
                    local it = o and o:getItem() or nil
                    if it and it:getFullType() == "Base.Log" then
                        table.insert(res, o)
                    end
                end
            end
        end
    end
    return res
end

-- simple highlight helper for the stockpile square
function AFCore.setStockpile(sq)
    AFCore.pileSq = sq
    local p = getSpecificPlayer(0)
    if sq then
        say(p, "[PILE] set @ "..tostring(sq:getX()).."x"..tostring(sq:getY()))
        if sq.setHighlighted then sq:setHighlighted(true) end
    else
        say(p, "[PILE] cleared")
    end
end

-- queue chops for each tree square
function AFCore.queueChops(p, squares)
    local n = 0
    for _,sq in ipairs(squares or {}) do
        local tree = AFCore.getTreeFromSquare(sq)
        if tree then
            ISTimedActionQueue.add(ISChopTreeAction:new(p, tree))
            n = n + 1
        end
    end
    return n
end
