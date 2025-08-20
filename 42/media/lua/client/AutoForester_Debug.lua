AutoForester_Debug = AutoForester_Debug or { on=true } -- flip to false to silence
function AutoForester_Debug.log(fmt, ...)
  if not AutoForester_Debug.on then return end
  local msg = string.format(fmt, ...)
  print("[AF] "..msg)
  local p = getSpecificPlayer(0); if p and p.Say then p:Say(msg) end
end
return AutoForester_Debug
