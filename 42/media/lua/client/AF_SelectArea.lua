-- AF_SelectArea.lua
require "AutoForester_Debug"
require "AutoForester_Core"

AF_SelectArea = AF_SelectArea or {}
local Tool = {
    active=false, kind=nil, startSq=nil, rect=nil, z=0, highlighted={}
}

local function clearHighlight()
    for i=1,#Tool.highlighted do
        local sq = Tool.highlighted[i]
        if sq and sq.setHighlighted then sq:setHighlighted(false) end
    end
    Tool.highlighted = {}
end

local function addHighlight(rect)
    clearHighlight()
    if not rect then return end
    local z = rect[5] or 0
    local x1,y1,x2,y2 = rect[1],rect[2],rect[3],rect[4]
    local cell = getCell(); if not cell then return end
    for x=x1,x2 do
        for y=y1,y2 do
            local sq = cell:getGridSquare(x,y,z)
            if sq then
                sq:setHighlighted(true); sq:setHighlightColor(0.1,1.0,0.6)
                table.insert(Tool.highlighted, sq)
            end
        end
    end
end

local function getMouseSq()
    local p = getSpecificPlayer(0)
    local z = (p and p:getZ()) or 0
    local mx,my = getMouseXScaled(), getMouseYScaled()
    local wx = ISCoordConversion.ToWorldX(mx,my,0)
    local wy = ISCoordConversion.ToWorldY(mx,my,0)
    return getCell():getGridSquare(math.floor(wx), math.floor(wy), z)
end

local function makeRect(aSq, bSq)
    if not aSq or not bSq then return nil end
    local x1 = math.min(aSq:getX(), bSq:getX())
    local y1 = math.min(aSq:getY(), bSq:getY())
    local x2 = math.max(aSq:getX(), bSq:getX())
    local y2 = math.max(aSq:getY(), bSq:getY())
    local z  = aSq:getZ()
    return {x1,y1,x2,y2,z}
end

function AF_SelectArea.start(kind)
    Tool.active = true
    Tool.kind   = kind  -- "chop" or "gather"
    Tool.startSq = getMouseSq()
    Tool.rect   = nil
    clearHighlight()
    if not Tool.startSq then AFLOG("SelectArea.start","startSq=nil") end
end

function AF_SelectArea.cancel()
    Tool.active = false; Tool.kind=nil; Tool.startSq=nil; Tool.rect=nil
    clearHighlight()
end

local function onMouseMove(dx,dy)
    if not Tool.active or not Tool.startSq then return false end
    local cur = getMouseSq(); if not cur then return false end
    Tool.rect = makeRect(Tool.startSq, cur)
    addHighlight(Tool.rect)
    return true
end

local function onMouseDown(x,y)  -- start held-drag
    if not Tool.active then return false end
    Tool.startSq = getMouseSq()
    Tool.rect = nil
    return false
end

local function onMouseUp(x,y)    -- release → commit
    if not Tool.active or not Tool.startSq then return false end
    local cur = getMouseSq(); if not cur then AF_SelectArea.cancel(); return false end
    Tool.rect = makeRect(Tool.startSq, cur)
    addHighlight(Tool.rect)
    local p = getSpecificPlayer(0)

    if Tool.kind == "chop" then
        AFCore.chopRect = Tool.rect
        AFSAY(p,"Chop area set.")
    else
        AFCore.gatherRect = Tool.rect
        AFSAY(p,"Gather area set.")
    end
    AF_SelectArea.cancel()
    return true
end

-- register to vanilla mouse events (same hooks husbandry uses)
Events.OnMouseMove.Add(onMouseMove)
Events.OnMouseDown.Add(onMouseDown)
Events.OnMouseUp.Add(onMouseUp)
