-- AF_Log.lua
AF_Log = AF_Log or {}
function AF_Log.info(msg) print(tostring(msg)) end
function AF_Log.err(msg) print("ERROR: " .. tostring(msg)) end
