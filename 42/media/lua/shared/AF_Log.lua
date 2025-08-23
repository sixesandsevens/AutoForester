-- AutoForester simple logger (shared)
local AF_Log = {}

local function _emit(level, ...)
    local parts = {"[AutoForester]", level}
    for i=1,select("#", ...) do
        local v = select(i, ...)
        parts[#parts+1] = tostring(v)
    end
    print(table.concat(parts, " "))
end

function AF_Log.info(...)  _emit("INFO",  ...) end
function AF_Log.warn(...)  _emit("WARN",  ...) end
function AF_Log.err(...)   _emit("ERROR", ...) end

function AF_Log.safe(tag, fn, ...)
    local ok, res1, res2 = pcall(fn, ...)
    if not ok then
        AF_Log.err(tag, res1)
        return nil
    end
    return res1, res2
end

return AF_Log
