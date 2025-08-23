-- Minimal two-click area picker that doesn't depend on the debug overlay.
-- Left click first corner, left click second corner -> callback(rect, area)
if not AF_Select then AF_Select = {} end

require "ISUI/ISCoordConversion"

local Picker = nil

local function stopPicker()
    if not Picker then return end
    if Picker.onMouseDown then Events.OnMouseDown.Remove(Picker.onMouseDown) end
    if Picker.onRightMouseDown then Events.OnRightMouseDown.Remove(Picker.onRightMouseDown) end
    if Picker.onKeyPressed then Events.OnKeyPressed.Remove(Picker.onKeyPressed) end
    Picker = nil
end

local function worldSquareUnderMouse(z)
    local mx = getMouseXScaled and getMouseXScaled() or getMouseX()
    local my = getMouseYScaled and getMouseYScaled() or getMouseY()
    local wx = ISCoordConversion.ToWorldX(mx, my, 0)
    local wy = ISCoordConversion.ToWorldY(mx, my, 0)
    local cell = getCell()
    if not cell then return nil end
    return cell:getGridSquare(math.floor(wx), math.floor(wy), z or 0)
end

function AF_Select.pickArea(worldobjects, player, callback, reasonTag)
    stopPicker()
    local p = player or getSpecificPlayer(0) or getPlayer()
    local z = p and p:getZ() or 0
    Picker = { stage = 0, x1=0, y1=0, z=z, p=p, cb=callback }

    local function done(rect)
        local r = AFCore.normalizeRect(rect)
        local area = r and ((r[3]-r[1]+1) * (r[4]-r[2]+1)) or 0
        stopPicker()
        if Picker.cb then Picker.cb(r, area) end
    end

    Picker.onMouseDown = function(x, y)
        local sq = worldSquareUnderMouse(Picker.z)
        if not sq then return end
        local xw, yw = sq:getX(), sq:getY()
        if Picker.stage == 0 then
            Picker.x1, Picker.y1 = xw, yw
            Picker.stage = 1
            if Picker.p and Picker.p.Say then Picker.p:Say("Second corner...") end
        else
            local rect = { Picker.x1, Picker.y1, xw, yw, Picker.z }
            done(rect)
        end
    end

    -- allow cancelling with right click or ESC
    Picker.onRightMouseDown = function() stopPicker() end
    Picker.onKeyPressed = function(key) if key == Keyboard.KEY_ESCAPE then stopPicker() end end

    Events.OnMouseDown.Add(Picker.onMouseDown)
    Events.OnRightMouseDown.Add(Picker.onRightMouseDown)
    Events.OnKeyPressed.Add(Picker.onKeyPressed)

    if p and p.Say then p:Say("Pick two corners...") end
end
