-- media/lua/client/AF_TwoClickSelect.lua
require "ISUI/ISCoordConversion"

local Picker = nil

local function stopPicker()
    if not Picker then return end
    Events.OnMouseDown.Remove(Picker.onMouseDown)
    Events.OnKeyPressed.Remove(Picker.onKeyPressed)
    Picker = nil
end

local function worldSquareUnderMouse(p)
    return AFCore.getMouseSquare(p)
end

-- Public: AF_Select.pickArea(worldobjects, playerIndex, callback(rect), reasonTag)
AF_Select = AF_Select or {}
function AF_Select.pickArea(_, player, callback, reasonTag)
    stopPicker()
    local p = getSpecificPlayer(player) or getPlayer()
    if not p then return end
    local z = p:getZ() or 0
    Picker = { stage=0, x1=nil, y1=nil, z=z, p=p, cb=callback, tag=reasonTag }

    function Picker.onMouseDown()
        local sq = worldSquareUnderMouse(Picker.p)
        if not sq then return end
        local x, y = sq:getX(), sq:getY()
        if Picker.stage == 0 then
            Picker.stage = 1
            Picker.x1, Picker.y1 = x, y
            Picker.p:Say("Corner A")
        else
            stopPicker()
            local rect = { Picker.x1, Picker.y1, x, y }
            if Picker.cb then pcall(Picker.cb, rect, {x1=Picker.x1,y1=Picker.y1,x2=x,y2=y}, Picker.tag) end
        end
    end

    function Picker.onKeyPressed(key)
        if key == Keyboard.KEY_ESCAPE or key == Keyboard.KEY_RBUTTON then
            stopPicker()
            Picker.p:Say("Selection cancelled.")
        end
    end

    Events.OnMouseDown.Add(Picker.onMouseDown)
    Events.OnKeyPressed.Add(Picker.onKeyPressed)
    p:Say("Select two corners.")
end
