-- media/lua/client/AF_TwoClickSelect.lua
require "ISUI/ISCoordConversion"
local AF_Log = require "AF_Log"
local AFCore = require "AF_Core"

local AF_Select = AF_Select or {}

local Picker = nil

local function stopPicker()
    if not Picker then return end
    Events.OnMouseDown.Remove(Picker.onMouseDown)
    Events.OnKeyPressed.Remove(Picker.onKeyPressed)
    Picker = nil
end

local function worldSquareUnderMouse(z)
    local mx = getMouseXScaled and getMouseXScaled() or getMouseX()
    local my = getMouseYScaled and getMouseYScaled() or getMouseY()
    local wx = ISCoordConversion.ToWorldX(mx, my, 0)
    local wy = ISCoordConversion.ToWorldY(mx, my, 0)
    local cell = getCell(); if not cell then return nil end
    return cell:getGridSquare(math.floor(wx), math.floor(wy), z or 0)
end

function AF_Select.pickArea(worldobjects, p, callback, reasonTag)
    stopPicker()
    local player = p or getSpecificPlayer(0) or getPlayer()
    if not player then return end
    local z = player:getZ() or 0
    Picker = { stage = 0, p = player, z = z, cb = callback }

    function Picker.onKeyPressed(key)
        if key == Keyboard.KEY_ESCAPE then
            AF_Log.warn("Selection cancelled")
            player:Say("No area.")
            stopPicker()
        end
    end

    function Picker.onMouseDown(x, y)
        if not Picker then return end
        local sq = worldSquareUnderMouse(Picker.z)
        if not sq then player:Say("No tile."); stopPicker(); return end
        if Picker.stage == 0 then
            Picker.sx, Picker.sy = sq:getX(), sq:getY()
            Picker.stage = 1
            player:Say("First corner set.")
            return
        end
        local x1, y1 = Picker.sx, Picker.sy
        local x2, y2 = sq:getX(), sq:getY()
        local rect = AFCore.normalizeRect({x1, y1, x2, y2})
        stopPicker()
        if not rect then player:Say("No area."); return end
        AF_Log.info("Rect picked:", rect[1], rect[2], rect[3], rect[4])
        if Picker.cb then Picker.cb(rect, { areaWidth = rect[3]-rect[1]+1, areaHeight = rect[4]-rect[2]+1 }) end
    end

    Events.OnMouseDown.Add(Picker.onMouseDown)
    Events.OnKeyPressed.Add(Picker.onKeyPressed)
    player:Say("Pick two corners (ESC to cancel).")
end

return AF_Select
