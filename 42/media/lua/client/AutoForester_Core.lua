
AFCore = AFCore or {}

local function say(p, msg) if p then p:Say(tostring(msg)) end end

-- Convert any rect shape to {x1,y1,x2,y2,z}
function AFCore.normalizeRect(r)
    if not r then return nil end
    -- case: {sqA, sqB}
    if type(r[1])=="table" and r[1].getX then
        local a,b=r[1],r[2]; if not a or not b then return nil end
        local x1,y1,z=a:getX(),a:getY(),a:getZ() or 0
        local x2,y2=b:getX(),b:getY()
        if x2<x1 then x1,x2=x2,x1 end
        if y2<y1 then y1,y2=y2,y1 end
        return {x1,y1,x2,y2,z}
    end
    -- case: fields or numeric array
    local x1=tonumber(r.x1 or r.minX or r[1]); if not x1 then return nil end
    local y1=tonumber(r.y1 or r.minY or r[2]); if not y1 then return nil end
    local x2=tonumber(r.x2 or r.maxX or r[3] or x1)
    local y2=tonumber(r.y2 or r.maxY or r[4] or y1)
    local z =tonumber(r.z  or r[5]) or 0
    if x2<x1 then x1,x2=x2,x1 end
    if y2<y1 then y1,y2=y2,y1 end
    return {x1,y1,x2,y2,z}
end

-- Tile under mouse (no extra click)
function AFCore.getMouseSquare(p)
    local mx,my = getMouseXScaled(), getMouseYScaled()
    local wx = ISCoordConversion.ToWorldX(mx,my,0)
    local wy = ISCoordConversion.ToWorldY(mx,my,0)
    local z = (p and p.getZ and p:getZ()) or 0
    local cell = getCell(); if not cell then return nil end
    return cell:getGridSquare(math.floor(wx), math.floor(wy), z)
end

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
