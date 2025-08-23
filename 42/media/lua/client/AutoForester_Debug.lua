-- media/lua/client/AutoForester_Debug.lua
AutoForester_Debug = AutoForester_Debug or { level = 2 } -- 0=silent,1=chat,2=chat+console

local function _say(p, ...) if p and AutoForester_Debug.level >= 1 then p:Say(table.concat({...}," ")) end end
local function _log(tag, ...) if AutoForester_Debug.level >= 2 then print("[AF]["..tag.."] "..table.concat({...}," ")) end end

function AFSAY(p, ...) _say(p, ...) end
function AFLOG(tag, ...) _log(tag, ...) end
