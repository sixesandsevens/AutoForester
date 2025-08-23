-- media/lua/shared/AF_Log.lua
AF_Log = AF_Log or {}
local PFX = "[AutoForester]"

-- Helper to safely stringify values
local function j(s) return tostring(s or "") end

-- Info-level log (prints a message to console with mod prefix)
function AF_Log.info(...)
    local parts = { ... }
    local msg = ""
    for i = 1, #parts do
        msg = msg .. j(parts[i]) .. (i < #parts and " " or "")
    end
    print(PFX .. " " .. msg)
end

-- Error-level log (prints an error message with mod prefix)
function AF_Log.error(...)
    local parts = { ... }
    local msg = ""
    for i = 1, #parts do
        msg = msg .. j(parts[i]) .. (i < #parts and " " or "")
    end
    print(PFX .. " ERROR: " .. msg)
end

-- Safe wrapper: executes function `fn` with protected call. Logs an error if it fails.
-- Usage: AF_Log.safe("label", function() ... end)
function AF_Log.safe(label, fn, ...)
    if type(fn) ~= "function" then
        AF_Log.error("SAFE called with non-function for label:", label)
        return false, "non-function"
    end
    local ok, a, b, c, d, e = pcall(fn, ...)
    if not ok then
        AF_Log.error("SAFE FAIL [", label, "]:", a)
    end
    return ok, a, b, c, d, e
end
