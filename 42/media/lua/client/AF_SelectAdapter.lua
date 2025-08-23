-- AF_SelectAdapter.lua
-- Provide AF_Select.* even if JBASS/Utils isn't present.
AF_Select = AF_Select or {}

local function say(p, msg) if p and p.Say then p:Say(tostring(msg)) end end

-- Click current mouse tile and return it via cb(square)
function AF_Select.pickSquare(worldobjects, p, cb)
    local sq = AFCore and AFCore.getMouseSquare and AFCore.getMouseSquare(p) or nil
    if cb then cb(sq) end
end

-- Two-click fallback area: first click sets corner A, second click sets B and returns rect
AF_Select._state = AF_Select._state or {}

local function _keyForPlayer(p, purpose)
    purpose = purpose or "default"
    local pid = (p and p:getOnlineID()) or 0
    return tostring(pid) .. "::" .. purpose
end

function AF_Select.pickArea(worldobjects, p, cb, purpose)
    local key = _keyForPlayer(p, purpose)
    local sq = AFCore.getMouseSquare(p)
    if not sq then if p then say(p, "No tile.") end if cb then cb(nil) end return end

    local st = AF_Select._state[key]
    if not st then
        AF_Select._state[key] = { x = sq:getX(), y = sq:getY(), z = sq:getZ() }
        say(p, "First corner set. Pick opposite corner.")
        return
    end

    local rect = { st.x, st.y, sq:getX(), sq:getY() }
    rect = AFCore.normalizeRect(rect)
    AF_Select._state[key] = nil

    local area = { areaWidth = AFCore.rectWidth(rect), areaHeight = AFCore.rectHeight(rect) }
    if cb then cb(rect, area) end
end