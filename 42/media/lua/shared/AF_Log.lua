AF = AF or {}
local TAG = "[AutoForester]"

local function tostr(...)
    local t = {}
    for i = 1, select("#", ...) do t[#t+1] = tostring(select(i, ...)) end
    return table.concat(t, " ")
end

function AF.log(...)               print(TAG .. " " .. tostr(...)) end
function AF.say(p, ...)            local s=tostr(...); if p and p.Say then p:Say(s) end; print(TAG.." "..s) end
function AF.safe(where, fn)
    local ok, err = pcall(fn)
    if not ok then AF.log("ERR in", where, "=>", err) end
    return ok
end
