-- AutoForester_Debug.lua
AFLOG_ENABLED = true
local function t2s(t)
  if type(t)~="table" then return tostring(t) end
  local out = {}
  for k,v in pairs(t) do table.insert(out, tostring(k).."="..tostring(v)) end
  table.sort(out)
  return "{"..table.concat(out,", ").."}"
end
function AFLOG(...)
  if not AFLOG_ENABLED then return end
  local parts = {}
  for i=1,select("#", ...) do parts[i] = tostring(select(i, ...)) end
  print("[AF] "..table.concat(parts," "))
end
