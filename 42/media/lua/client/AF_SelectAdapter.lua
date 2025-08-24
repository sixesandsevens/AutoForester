AF = AF or {}
AF.Select = AF.Select or {}

local JB_ASSUtils = nil
local ok, mod = pcall(require, "JB_ASSUtils")
if ok then JB_ASSUtils = mod end

--- Unified area selector. Falls back to 1x1 area if JB_ASSUtils is missing.
-- callback(playerObj, worldObjects, selectedArea)
function AF.Select.area(worldObjects, playerObj, callbackFunc, ...)
    local args = { ... }
    if JB_ASSUtils and JB_ASSUtils.SelectArea then
        return JB_ASSUtils.SelectArea(worldObjects, playerObj, callbackFunc, table.unpack(args))
    end

    -- Fallback: single-click 1x1 "area"
    local mouseUpOne, onTickEvent
    local z = playerObj and playerObj:getZ() or 0

    mouseUpOne = function()
        Events.OnMouseUp.Remove(mouseUpOne)
        Events.OnTick.Remove(onTickEvent)
        local wx, wy = ISCoordConversion.ToWorld(getMouseXScaled(), getMouseYScaled(), z)
        wx, wy = math.floor(wx), math.floor(wy)
        local sq = getSquare(wx, wy, z)
        local selected = { squares = {}, [1] = { minX = wx, minY = wy, maxX = wx, maxY = wy, areaX = wx, areaY = wy, areaZ = z, areaWidth = 1, areaHeight = 1 } }
        if sq and not (z > 0 and not sq:getFloor()) then table.insert(selected.squares, sq) end
        if callbackFunc then return callbackFunc(playerObj, worldObjects, selected, table.unpack(args)) end
    end

    onTickEvent = function()
        local wx, wy = ISCoordConversion.ToWorld(getMouseXScaled(), getMouseYScaled(), z)
        wx, wy = math.floor(wx), math.floor(wy)
        addAreaHighlight(wx, wy, wx + 1, wy + 1, z, 0.4, 0.8, 1.0, 0)
    end

    Events.OnMouseUp.Add(mouseUpOne)
    Events.OnTick.Add(onTickEvent)
end
