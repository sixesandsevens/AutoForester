-- AF_Logger.lua - tiny logger + safe wrapper
local M = {}

local function _t(x) return tostring(x) end

function M.info(msg) print("[AutoForester] ".._t(msg)) end
function M.warn(msg) print("[AutoForester][warn] ".._t(msg)) end
function M.err(msg) print("[AutoForester][error] ".._t(msg)) end

-- pcall wrapper so Break On Error doesn't explode everywhere
function M.safe(label, fn, ...)
    local ok, res = pcall(fn, ...)
    if not ok then
        print("[AutoForester][ERROR] ".._t(label).." -> ".._t(res))
        -- also surface on-screen if possible
        local p = getSpecificPlayer(0) or getPlayer()
        if p and p.Say then p:Say("AutoForester error: ".._t(label)) end
    end
    return ok, res
end

return M
