AFDBG = { on = true, chat = true }

function AFLOG(tag, ...)
  if not AFDBG.on then return end
  local parts = {}
  for i=1,select("#", ...) do parts[i] = tostring(select(i, ...)) end
  print(("[AF] %s: %s"):format(tag, table.concat(parts, " ")))
end

function AFSAY(p, msg)
  if AFDBG.chat and p then p:Say(tostring(msg)) end
end
