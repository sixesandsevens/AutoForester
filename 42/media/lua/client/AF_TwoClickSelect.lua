-- AF_TwoClickSelect.lua - dead simple two-click area selection
local AF_Log = require "AF_Logger"
local AFCore = require "AF_Core"

AF_Select = AF_Select or {}

local function say(p, s) if p and p.Say then p:Say(tostring(s)) end end

function AF_Select.stopPicker()
    local Pick = AF_Select._picker
    if not Pick then return end
    Events.OnMouseDown.Remove(Pick.onMouseDown)
    Events.OnKeyPressed.Remove(Pick.onKeyPressed)
    AF_Select._picker = nil
    AF_Log.info("Picker stopped.")
end

function AF_Select.pickArea(worldobjects, p, callback, reasonTag)
    local Picker = { stage = 0, p = p, cb = callback, z = (p and p:getZ() or 0), tag = reasonTag }
    local function worldSquare() return AFCore.worldSquareUnderMouse(Picker.z) end

    function Picker.onMouseDown(x, y)
        local sq = worldSquare()
        if not sq then return end
        if Picker.stage == 0 then
            Picker.x1, Picker.y1 = sq:getX(), sq:getY()
            Picker.stage = 1
            say(p, "First corner picked.")
        else
            local x2, y2 = sq:getX(), sq:getY()
            local rect = AFCore.normalizeRect({Picker.x1, Picker.y1, x2, y2})
            local cb = Picker.cb
            AF_Select.stopPicker()
            if cb then cb(p, rect, { w = rect[3]-rect[1]+1, h = rect[4]-rect[2]+1 }, Picker.tag) end
        end
    end

    function Picker.onKeyPressed(key)
        -- ESC to cancel
        if key == 1 then
            say(p, "Selection cancelled.")
            AF_Select.stopPicker()
        end
    end

    AF_Select._picker = Picker
    Events.OnMouseDown.Add(Picker.onMouseDown)
    Events.OnKeyPressed.Add(Picker.onKeyPressed)
    say(p, "Pick 2 corners.")
    AF_Log.info("Two-click area picker ready.")
end

return AF_Select
