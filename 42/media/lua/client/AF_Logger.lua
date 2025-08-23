
-- media/lua/client/AF_Logger.lua
AF_Log = {}
local function ts() return os.date("%H:%M:%S") end
function AF_Log.info(msg)  print(string.format("[AF %s] %s", ts(), tostring(msg))) end
function AF_Log.warn(msg)  print(string.format("[AF %s][WARN] %s", ts(), tostring(msg))) end
function AF_Log.err(msg)   print(string.format("[AF %s][ERR] %s", ts(), tostring(msg))) end
return AF_Log
