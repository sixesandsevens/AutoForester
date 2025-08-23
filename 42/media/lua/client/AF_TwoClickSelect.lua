-- media/lua/client/AF_TwoClickSelect.lua
require "AF_Log"
require "AutoForester_Core"

AF_Select = AF_Select or {}
local _pending = nil

-- immediate: tile under mouse right now
function AF_Select.pickSquare(worldObjects, p, cb)
    local sq = AFCore.getMouseSquare(p)
    if cb then cb(sq) end
end

-- two-click area: first call stores corner A; a later confirm picks corner B
function AF_Select.pickArea(worldObjects, p, cb, label)
    local a = AFCore.getMouseSquare(p)
    if not a then if p then p:Say("No tile.") end return end
    _pending = { p = p, cb = cb, x1 = a:getX(), y1 = a:getY(), z = a:getZ(), label = label }
    if p then p:Say("Click second corner (right-click → Confirm Area Corner).") end
end

function AF_Select.hasPending()
    return _pending ~= nil
end

function AF_Select.confirmPending(worldObjects, p)
    if not _pending then if p then p:Say("No area.") end return end
    local b = AFCore.getMouseSquare(p)
    if not b then if p then p:Say("No tile.") end return end

    local rect = { _pending.x1, _pending.y1, b:getX(), b:getY() }
    rect = AFCore.normalizeRect(rect)
    local area = { areaWidth = AFCore.rectWidth(rect), areaHeight = AFCore.rectHeight(rect) }

    local cb = _pending.cb
    _pending = nil
    if cb then cb(rect, area) end
end
