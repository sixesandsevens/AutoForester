-- media/lua/shared/AF_Log.lua
AF_Log = AF_Log or {}

local function vcat(...)
    local t = {}
    for i=1,select('#', ...) do
        t[#t+1] = tostring(select(i, ...))
    end
    return table.concat(t, " ")
end

function AF_Log.info(...)
    print("[AutoForester][INFO] "..vcat(...))
end

function AF_Log.warn(...)
    print("[AutoForester][WARN] "..vcat(...))
end

function AF_Log.err(...)
    print("[AutoForester][ERR ] "..vcat(...))
end
