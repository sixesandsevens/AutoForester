
-- media/lua/client/AF_TwoClickSelect.lua
local AFCore = require "AF_Core"
local AF_Log = require "AF_Logger"

AF_Select = AF_Select or {}

local Picker = nil

local function stopPicker()
    if not Picker then return end
    Events.OnMouseDown.Remove(Picker.onMouseDown)
    Events.OnKeyPressed.Remove(Picker.onKeyPressed)
    Picker = nil
end

function AF_Select.worldSquareUnderMouse(z)
    local mx = getMouseXScaled()
    local my = getMouseYScaled()
    local wx = ISCoordConversion.ToWorldX(mx, my, 0)
    local wy = ISCoordConversion.ToWorldY(mx, my, 0)
    local cell = getCell(); if not cell then return nil end
    return cell:getGridSquare(math.floor(wx), math.floor(wy), z or 0)
end

function AF_Select.pickArea(worldobjects, player, callback, reasonTag)
    stopPicker()
    local p = player or getSpecificPlayer(0) or getPlayer()
    if not p then AF_Log.err("No player for picker"); return end

    local z = p:getZ() or 0
    Picker = { stage = 0, p = p, z = z, cb = callback, tag = reasonTag }

    function Picker.onKeyPressed(key)
        -- ESC to cancel
        if key == Keyboard.KEY_ESCAPE then
            AF_Log.warn("Area selection cancelled.")
            stopPicker()
        end
    end

    function Picker.onMouseDown(x,y)
        local sq = AF_Select.worldSquareUnderMouse(Picker.z)
        if not sq then return end
        if Picker.stage == 0 then
            Picker.x1, Picker.y1 = sq:getX(), sq:getY()
            Picker.stage = 1
            AF_Log.info("First corner: "..Picker.x1..","..Picker.y1)
        else
            local x2,y2 = sq:getX(), sq:getY()
            local rect = AFCore.normalizeRect({Picker.x1,Picker.y1,x2,y2})
            AF_Log.info(string.format("Area picked: (%d,%d) to (%d,%d)", rect[1],rect[2],rect[3],rect[4]))
            local cb = Picker.cb
            stopPicker()
            if cb then cb(Picker.p, rect, Picker.z, Picker.tag) end
        end
    end

    Events.OnMouseDown.Add(Picker.onMouseDown)
    Events.OnKeyPressed.Add(Picker.onKeyPressed)
    AF_Log.info("Two-click area picker ready (ESC to cancel).")
end

return AF_Select
