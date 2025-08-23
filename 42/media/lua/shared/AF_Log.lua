if not AF_Log then AF_Log = {} end

local PREFIX = "[AutoForester] "

local function _fmt(...)
    local t = {}
    for i,v in ipairs({...}) do t[#t+1] = tostring(v) end
    return table.concat(t, " ")
end

function AF_Log.info(...)
    print(PREFIX .. _fmt(...))
end

function AF_Log.err(where, ex)
    print(PREFIX .. "ERR in " .. tostring(where) .. " =>  " .. tostring(ex))
end

-- run fn() in pcall and log any error; returns ok, result
function AF_Log.safe(where, fn)
    local ok, res = pcall(fn)
    if not ok then AF_Log.err(where, res) end
    return ok, res
end
