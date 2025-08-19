AF_SelectArea = AF_SelectArea or {}
local Tool = AF_SelectArea

local function getP()
    return getSpecificPlayer and getSpecificPlayer(0) or getPlayer()
end

local function safeMouseSquare()
    -- Robust against nils while opening menus / UI focus changes
    local mx, my = getMouseXScaled(), getMouseYScaled()
    if not mx or not my then return nil end
    local wx, wy = ISCoordConversion.ToWorld(mx, my, 0)
    if not wx or not wy then return nil end
    wx, wy = math.floor(wx), math.floor(wy)
    local z = (getP() and getP():getZ()) or 0
    local cell = getCell()
    return cell and cell:getGridSquare(wx, wy, z) or nil
end

Tool.active = false
Tool.kind = nil         -- "chop" | "gather"
Tool.startSq = nil
Tool.rect = nil
Tool.highlighted = {}

local function clearHighlight()
    for _, sq in ipairs(Tool.highlighted) do
        sq:setHighlighted(false)
    end
    Tool.highlighted = {}
end

local function addHighlight(rect)
    clearHighlight()
    if not rect then return end
    local x1,y1,x2,y2,z = table.unpack(rect)
    local cell = getCell()
    for x=x1,x2 do
        for y=y1,y2 do
            local sq = cell:getGridSquare(x,y,z)
            if sq then
                sq:setHighlighted(true)
                sq:setHighlightColor(0,1,0,0.6)
                table.insert(Tool.highlighted, sq)
            end
        end
    end
end

local function makeRect(a, b)
    if not a or not b then return nil end
    local z = a:getZ()
    local r = { math.min(a:getX(), b:getX()),
                math.min(a:getY(), b:getY()),
                math.max(a:getX(), b:getX()),
                math.max(a:getY(), b:getY()),
                z }
    return r
end

function Tool.begin(kind)
    Tool.active = true
    Tool.kind = kind
    Tool.startSq = nil
    Tool.rect = nil
    clearHighlight()
    getPlayer():Say("Drag to select "..kind.." area.")
end

function Tool.onMouseDown(x,y)
    if not Tool.active then return false end
    local sq = safeMouseSquare()
    if not sq then return false end
    Tool.startSq = sq
    return false
end

function Tool.onMouseMove(dx,dy)
    if not Tool.active or not Tool.startSq then return false end
    local cur = safeMouseSquare()
    if not cur then return false end
    local rect = makeRect(Tool.startSq, cur)
    Tool.rect = rect
    addHighlight(rect)
    return false
end

function Tool.onMouseUp(x,y)
    if not Tool.active or not Tool.startSq then return false end
    local cur = safeMouseSquare()
    if not cur then return false end
    Tool.rect = makeRect(Tool.startSq, cur)
    addHighlight(Tool.rect)
    if Tool.kind == "chop" then
        AutoChopTask.chopRect = Tool.rect
        getP():Say("Chop area set.")
    else
        AutoChopTask.gatherRect = Tool.rect
        getP():Say("Gather area set.")
    end
    Tool.active, Tool.kind, Tool.startSq = false, nil, nil
    return false
end

Events.OnMouseDown.Add(Tool.onMouseDown)
Events.OnMouseMove.Add(Tool.onMouseMove)
Events.OnMouseUp.Add(Tool.onMouseUp)
