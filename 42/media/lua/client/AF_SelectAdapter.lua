-- AF_SelectAdapter.lua
-- Minimal, dependency-free area/tile selection helpers used by AutoForester.
-- If the JBASS/Utils library is present and exposes `AF_Select`, we noop and defer to it.

if AF_Select and AF_Select.__providedByJBASS then
    return -- External implementation present.
end

AF_Select = AF_Select or {}
AF_Select.__providedByJBASS = false

local function say(p, msg) if p and msg then p:Say(msg) end end

local function keyFor(p, purpose)
    return string.format("p%s:%s", tostring(p and p:getPlayerNum() or 0), tostring(purpose or "generic"))
end

AF_Select._state = AF_Select._state or {}

-- Pick a single square (tile) under the mouse at the moment the option is clicked.
function AF_Select.pickSquare(worldobjects, p, cb)
    local sq = AFCore.getMouseSquare(p)
    if not sq then say(p, "No tile."); if cb then cb(nil) end; return end
    if cb then cb(sq) end
end

-- Fallback two-click rectangle picker.
-- First invocation stores corner 1 at the mouse. Second invocation returns rect+area.
function AF_Select.pickArea(worldobjects, p, cb, purpose)
    local sq = AFCore.getMouseSquare(p)
    if not sq then say(p, "No tile."); if cb then cb(nil, nil) end; return end

    local k = keyFor(p, purpose)
    local st = AF_Select._state[k]
    if not st then
        AF_Select._state[k] = { x = sq:getX(), y = sq:getY(), z = sq:getZ() }
        say(p, "First corner set. Pick opposite corner.")
        return
    end

    local rect = { st.x, st.y, sq:getX(), sq:getY(), st.z or sq:getZ() }
    AF_Select._state[k] = nil

    rect = AFCore.normalizeRect(rect)
    if not rect then say(p, "No area."); if cb then cb(nil, nil) end; return end

    local area = { areaWidth = AFCore.rectWidth(rect), areaHeight = AFCore.rectHeight(rect) }
    if cb then cb(rect, area) end
end
