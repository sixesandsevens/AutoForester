-- media/lua/client/AF_TwoClickSelect.lua
require "ISUI/ISCoordConversion"

local Picker = nil

local function stopPicker()
    if not Picker then return end
    if Picker.onMouseDown then Events.OnMouseDown.Remove(Picker.onMouseDown) end
    if Picker.onRightMouseDown then Events.OnRightMouseDown.Remove(Picker.onRightMouseDown) end
    if Picker.onKeyPressed then Events.OnKeyPressed.Remove(Picker.onKeyPressed) end
    if Picker.onMouseMove then Events.OnMouseMove.Remove(Picker.onMouseMove) end
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

local function commit()
    local r = AFCore.normalizeRect(Picker)
    local ok, err = true, nil
    if Picker.cb and r then ok, err = pcall(Picker.cb, r) end
    if not ok then AF_Log.err("Callback error:", err or "unknown") end
    stopPicker()
end

local function cancel() stopPicker() end

local function onMouseDown(x, y)
    if not Picker then return end
    local sq = worldSquareUnderMouse(Picker.z)
    if not sq then return end
    if Picker.stage == 0 then
        Picker.stage = 1
        Picker.x1, Picker.y1 = sq:getX(), sq:getY()
    else
        Picker.x2, Picker.y2 = sq:getX(), sq:getY()
        commit()
    end
end

local function onRightMouseDown(x,y) cancel() end
local function onKeyPressed(key) if key == 27 then cancel() end end -- ESC

local function onMouseMove(dx,dy)
    if not Picker or Picker.stage ~= 1 then return end
    local sq = worldSquareUnderMouse(Picker.z)
    if not sq then return end
    Picker.x2, Picker.y2 = sq:getX(), sq:getY()
end

AF_Select = AF_Select or {}

function AF_Select.pickArea(worldobjects, player, callback, reason)
    stopPicker()
    local p = player or getSpecificPlayer(0) or getPlayer()
    local z = (p and p:getZ()) or 0
    Picker = {stage=0,x1=0,y1=0,x2=0,y2=0,z=z,p=p,cb=callback,reason=reason}
    Picker.onMouseDown = onMouseDown
    Picker.onRightMouseDown = onRightMouseDown
    Picker.onKeyPressed = onKeyPressed
    Picker.onMouseMove = onMouseMove
    Events.OnMouseDown.Add(onMouseDown)
    Events.OnRightMouseDown.Add(onRightMouseDown)
    Events.OnKeyPressed.Add(onKeyPressed)
    Events.OnMouseMove.Add(onMouseMove)
    if p and p.Say then
        p:Say((reason and ("Select "..tostring(reason)) or "Select area")..": click two opposite corners")
    end
end
