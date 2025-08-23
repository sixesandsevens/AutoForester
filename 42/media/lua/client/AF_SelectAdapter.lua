-- Idempotent, deterministic adapter. This file may be loaded multiple times.
require "AF_Log"

AF_Select = AF_Select or {}
if AF_Select.__inited then return AF_Select end
AF_Select.__inited = true

-- Tiny shim: delegate to the game’s rectangle picker we hook once.
-- We expose a single, stable API: AF_Select.pickArea(worldobjects, playerObj, onPicked)
-- onPicked(rect, area) is called with either a 4-number rect or nil.
local _ctx = {}

-- install hook once; we do NOT nil or override vanilla functions
if not _ctx.hooked then
    _ctx.hooked = true
    -- If you use a custom drag selector, initialise it here once, not per-click.
    -- (If you previously patched ISObjectClickHandler / ISContextMenu, remove those overrides.)
end

function AF_Select.pickArea(worldobjects, p, onPicked)
    -- Defensive: these callbacks fire later; don’t keep brittle upvalues around.
    local pid = p and p:getPlayerNum() or 0
    AF.log("pickArea begin (pid=", pid, ")")

    -- Your existing selector start code goes here. Example pattern:
    -- Start a rectangle selection UI, and in its OnFinished do:
    local function done(rect, area)
        local playerNow = getSpecificPlayer(pid) or getPlayer()
        AF.safe("AF_Select.done", function()
            if onPicked then onPicked(rect, area, playerNow) end
        end)
    end

    -- If you had a working implementation already, call into it here.
    -- e.g., startYourRectPicker(worldobjects, p, done)

    -- TEMP: as a guard while we stabilise selection, immediately fail gracefully
    -- if no picker is currently wired (prevents 'call nil' crashes).
    if not startYourRectPicker then
        AF.log("No rect picker wired; returning nil to caller safely.")
        done(nil, nil)
    end
end

return AF_Select
